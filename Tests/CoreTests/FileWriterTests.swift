import Testing
import Foundation
@testable import Core

@Suite("FileWriter")
struct FileWriterTests {

    // MARK: - Helpers

    private func makeTempRepo() throws -> URL {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let featurePlans = tmp.appendingPathComponent(".claude/feature-plans")
        try FileManager.default.createDirectory(at: featurePlans, withIntermediateDirectories: true)
        return tmp
    }

    // MARK: - previewWrite — happy path

    @Test("previewWrite returns preview for valid new file")
    func previewNewFile() throws {
        let repo = try makeTempRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        let result = previewWrite(content: "# Hello", to: "my-feature/plan.md", rootRepoPath: repo.path)
        guard case .success(let preview) = result else {
            Issue.record("Expected success, got \(result)")
            return
        }
        #expect(preview.newContent == "# Hello")
        #expect(preview.existingContent == nil)
        #expect(preview.url.path.hasSuffix("my-feature/plan.md"))
    }

    @Test("previewWrite captures existing content")
    func previewExistingFile() throws {
        let repo = try makeTempRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        let dir = repo.appendingPathComponent(".claude/feature-plans/my-feature")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try "# Old".write(to: dir.appendingPathComponent("plan.md"), atomically: true, encoding: .utf8)

        let result = previewWrite(content: "# New", to: "my-feature/plan.md", rootRepoPath: repo.path)
        guard case .success(let preview) = result else {
            Issue.record("Expected success")
            return
        }
        #expect(preview.existingContent == "# Old")
        #expect(preview.newContent == "# New")
    }

    // MARK: - previewWrite — path validation

    @Test("previewWrite rejects path with .. traversal")
    func rejectsPathTraversal() throws {
        let repo = try makeTempRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        let result = previewWrite(content: "evil", to: "../evil.md", rootRepoPath: repo.path)
        guard case .failure(let err) = result else {
            Issue.record("Expected failure for path traversal")
            return
        }
        if case .pathTraversal = err { } else {
            Issue.record("Expected pathTraversal error, got \(err)")
        }
    }

    @Test("previewWrite rejects absolute relativePath")
    func rejectsAbsolutePath() throws {
        let repo = try makeTempRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        let result = previewWrite(content: "evil", to: "/etc/passwd", rootRepoPath: repo.path)
        guard case .failure(let err) = result else {
            Issue.record("Expected failure for absolute path")
            return
        }
        if case .pathTraversal = err { } else {
            Issue.record("Expected pathTraversal error, got \(err)")
        }
    }

    @Test("previewWrite rejects deeply nested traversal")
    func rejectsDeeplyNestedTraversal() throws {
        let repo = try makeTempRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        let result = previewWrite(
            content: "evil",
            to: "my-feature/../../.ssh/authorized_keys",
            rootRepoPath: repo.path
        )
        guard case .failure = result else {
            Issue.record("Expected failure for nested traversal")
            return
        }
    }

    // MARK: - commitWrite

    @Test("commitWrite creates new file with correct content")
    func commitNewFile() throws {
        let repo = try makeTempRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        let result = previewWrite(content: "# Plan", to: "my-feature/plan.md", rootRepoPath: repo.path)
        guard case .success(let preview) = result else {
            Issue.record("Preview failed")
            return
        }
        try commitWrite(preview)
        let written = try String(contentsOf: preview.url, encoding: .utf8)
        #expect(written == "# Plan")
    }

    @Test("commitWrite creates intermediate directories")
    func commitCreatesDirectories() throws {
        let repo = try makeTempRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        let result = previewWrite(
            content: "hello",
            to: "new-feature/nested/file.md",
            rootRepoPath: repo.path
        )
        guard case .success(let preview) = result else {
            Issue.record("Preview failed")
            return
        }
        try commitWrite(preview)
        #expect(FileManager.default.fileExists(atPath: preview.url.path))
    }

    @Test("commitWrite overwrites existing file")
    func commitOverwritesExisting() throws {
        let repo = try makeTempRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        let r1 = previewWrite(content: "v1", to: "feat/plan.md", rootRepoPath: repo.path)
        guard case .success(let p1) = r1 else { Issue.record("Preview 1 failed"); return }
        try commitWrite(p1)

        let r2 = previewWrite(content: "v2", to: "feat/plan.md", rootRepoPath: repo.path)
        guard case .success(let p2) = r2 else { Issue.record("Preview 2 failed"); return }
        #expect(p2.existingContent == "v1")
        try commitWrite(p2)

        let written = try String(contentsOf: p2.url, encoding: .utf8)
        #expect(written == "v2")
    }

    @Test("commitWrite leaves no temp files on disk")
    func noTempFilesLeft() throws {
        let repo = try makeTempRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        let result = previewWrite(content: "data", to: "feat/plan.md", rootRepoPath: repo.path)
        guard case .success(let preview) = result else {
            Issue.record("Preview failed")
            return
        }
        try commitWrite(preview)

        let dir = preview.url.deletingLastPathComponent()
        let items = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        let tmpFiles = items.filter { $0.hasSuffix(".tmp") }
        #expect(tmpFiles.isEmpty)
    }
}
