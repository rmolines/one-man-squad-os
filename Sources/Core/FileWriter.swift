import Foundation

// MARK: - Public API

public enum FileWriterError: Error, @unchecked Sendable {
    case pathTraversal(attempted: String)
    case outsideFeaturePlans(path: String)
    case ioError(Error)
}

public struct WritePreview: Sendable {
    public let url: URL
    public let newContent: String
    /// `nil` when the file does not yet exist.
    public let existingContent: String?
}

/// Validates `relativePath` against the allowed root and returns a preview for user inspection.
///
/// - Parameters:
///   - content: The new content to write.
///   - relativePath: Path relative to `<rootRepoPath>/.claude/feature-plans/`
///     (e.g. `"my-feature/plan.md"`). Must not be absolute or contain `..`.
///   - rootRepoPath: Absolute path to the repository root as approved by the user.
/// - Returns: A `WritePreview` on success, or a `FileWriterError` on validation failure.
public func previewWrite(
    content: String,
    to relativePath: String,
    rootRepoPath: String
) -> Result<WritePreview, FileWriterError> {
    // Reject absolute paths — they bypass the allowed root entirely.
    guard !relativePath.hasPrefix("/") else {
        return .failure(.pathTraversal(attempted: relativePath))
    }

    let featurePlansRoot = URL(fileURLWithPath: rootRepoPath)
        .appendingPathComponent(".claude/feature-plans")
        .standardized

    let targetURL = featurePlansRoot
        .appendingPathComponent(relativePath)
        .standardized

    // `standardized` resolves ".." lexically — so traversal attempts escape the prefix.
    let allowedPrefix = featurePlansRoot.path
    let targetPath = targetURL.path

    guard targetPath.hasPrefix(allowedPrefix + "/") || targetPath == allowedPrefix else {
        if relativePath.contains("..") {
            return .failure(.pathTraversal(attempted: relativePath))
        }
        return .failure(.outsideFeaturePlans(path: targetPath))
    }

    let existing = try? String(contentsOf: targetURL, encoding: .utf8)
    return .success(WritePreview(url: targetURL, newContent: content, existingContent: existing))
}

/// Performs an atomic write: writes to a temp file in the same directory, then renames.
///
/// Only call this with a `WritePreview` returned by `previewWrite(_:to:rootRepoPath:)`.
/// The caller is responsible for obtaining user confirmation of the preview before committing.
public func commitWrite(_ preview: WritePreview) throws {
    let fm = FileManager.default
    let dir = preview.url.deletingLastPathComponent()

    do {
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    } catch {
        throw FileWriterError.ioError(error)
    }

    let tmpURL = dir.appendingPathComponent(".\(UUID().uuidString).tmp")
    do {
        try preview.newContent.write(to: tmpURL, atomically: false, encoding: .utf8)
        if fm.fileExists(atPath: preview.url.path) {
            _ = try fm.replaceItem(
                at: preview.url,
                withItemAt: tmpURL,
                backupItemName: nil,
                options: [],
                resultingItemURL: nil
            )
        } else {
            try fm.moveItem(at: tmpURL, to: preview.url)
        }
    } catch let err as FileWriterError {
        try? fm.removeItem(at: tmpURL)
        throw err
    } catch {
        try? fm.removeItem(at: tmpURL)
        throw FileWriterError.ioError(error)
    }
}
