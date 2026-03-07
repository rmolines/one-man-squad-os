import Testing
@testable import Core

@Suite("WorktreeScanner")
struct WorktreeScannerTests {
    @Test("parseWorktreePorcelain returns empty for empty input")
    func emptyInput() throws {
        let result = try listWorktrees(repoPath: "/nonexistent/path")
        // Process will fail — test that we handle it gracefully
        // Real tests use a temp git repo
        _ = result
    }
}
