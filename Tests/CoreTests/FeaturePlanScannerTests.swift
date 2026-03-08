import Testing
import Foundation
@testable import Core

@Suite("FeaturePlanScanner")
struct FeaturePlanScannerTests {

    // MARK: - Helpers

    private func makeTempRepo(slugs: [String], filesPerSlug: [String: [String]] = [:]) throws -> URL {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let featurePlans = tmp.appendingPathComponent(".claude/feature-plans")
        try FileManager.default.createDirectory(at: featurePlans, withIntermediateDirectories: true)

        for slug in slugs {
            let slugDir = featurePlans.appendingPathComponent(slug)
            try FileManager.default.createDirectory(at: slugDir, withIntermediateDirectories: true)
            for file in filesPerSlug[slug, default: []] {
                try "content".write(to: slugDir.appendingPathComponent(file), atomically: true, encoding: .utf8)
            }
        }
        return tmp
    }

    // MARK: - Tests

    @Test("returns empty when feature-plans directory does not exist")
    func missingDirectory() {
        let result = listFeaturePlans(repoPath: "/nonexistent/\(UUID().uuidString)")
        #expect(result.isEmpty)
    }

    @Test("returns one entry per slug directory")
    func basicSlugIndexing() throws {
        let repo = try makeTempRepo(slugs: ["alpha", "beta", "gamma"])
        defer { try? FileManager.default.removeItem(at: repo) }

        let result = listFeaturePlans(repoPath: repo.path)
        #expect(result.count == 3)
        let slugs = Set(result.map(\.slug))
        #expect(slugs == ["alpha", "beta", "gamma"])
    }

    @Test("skips hidden entries (dot-prefixed)")
    func skipsHiddenEntries() throws {
        let repo = try makeTempRepo(slugs: ["visible", ".hidden"])
        defer { try? FileManager.default.removeItem(at: repo) }

        let result = listFeaturePlans(repoPath: repo.path)
        #expect(result.count == 1)
        #expect(result[0].slug == "visible")
    }

    @Test("skips files at feature-plans root (only directories become slugs)")
    func skipsFiles() throws {
        let repo = try makeTempRepo(slugs: ["real-slug"])
        // Place a stray file at feature-plans root
        let stray = repo.appendingPathComponent(".claude/feature-plans/stray.md")
        try "hello".write(to: stray, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: repo) }

        let result = listFeaturePlans(repoPath: repo.path)
        #expect(result.count == 1)
        #expect(result[0].slug == "real-slug")
    }

    @Test("status is .building when plan.md exists")
    func statusBuilding() throws {
        let repo = try makeTempRepo(slugs: ["my-feature"], filesPerSlug: ["my-feature": ["plan.md"]])
        defer { try? FileManager.default.removeItem(at: repo) }

        let result = listFeaturePlans(repoPath: repo.path)
        #expect(result.count == 1)
        #expect(result[0].status == .building)
    }

    @Test("status is .discovered when only discovery.md or research.md exists")
    func statusDiscovered() throws {
        let repo = try makeTempRepo(
            slugs: ["disc", "res"],
            filesPerSlug: ["disc": ["discovery.md"], "res": ["research.md"]]
        )
        defer { try? FileManager.default.removeItem(at: repo) }

        let result = listFeaturePlans(repoPath: repo.path)
        for item in result {
            #expect(item.status == .discovered)
        }
    }

    @Test("status is .exploring when only explore.md exists")
    func statusExploring() throws {
        let repo = try makeTempRepo(slugs: ["exp"], filesPerSlug: ["exp": ["explore.md"]])
        defer { try? FileManager.default.removeItem(at: repo) }

        let result = listFeaturePlans(repoPath: repo.path)
        #expect(result[0].status == .exploring)
    }

    @Test("status is .idle when no known artifacts exist")
    func statusIdle() throws {
        let repo = try makeTempRepo(slugs: ["empty"])
        defer { try? FileManager.default.removeItem(at: repo) }

        let result = listFeaturePlans(repoPath: repo.path)
        #expect(result[0].status == .idle)
    }

    @Test("building entries sort before discovered entries")
    func sortOrder() throws {
        let repo = try makeTempRepo(
            slugs: ["disc-feature", "build-feature"],
            filesPerSlug: [
                "disc-feature": ["discovery.md"],
                "build-feature": ["plan.md"],
            ]
        )
        defer { try? FileManager.default.removeItem(at: repo) }

        let result = listFeaturePlans(repoPath: repo.path)
        #expect(result.count == 2)
        #expect(result[0].slug == "build-feature")
        #expect(result[1].slug == "disc-feature")
    }

    @Test("attachedWorktree is nil when no worktrees match")
    func noAttachedWorktree() throws {
        let repo = try makeTempRepo(slugs: ["my-feature"])
        defer { try? FileManager.default.removeItem(at: repo) }

        let result = listFeaturePlans(repoPath: repo.path)
        #expect(result[0].attachedWorktree == nil)
    }
}
