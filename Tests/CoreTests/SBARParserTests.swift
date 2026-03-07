import Testing
@testable import Core

@Suite("SBARParser")
struct SBARParserTests {
    @Test("Parses valid SBAR sections")
    func validSBAR() {
        let markdown = """
        ## Situation
        The portfolio view is empty.

        ## Background
        No worktrees detected in the selected repo.

        ## Assessment
        The repo path is invalid or has no linked worktrees.

        ## Recommendation
        Prompt user to select a valid repo with at least one worktree.
        """
        let result = parseSBAR(from: markdown)
        #expect(result != nil)
        #expect(result?.situation == "The portfolio view is empty.")
    }

    @Test("Returns nil for missing sections")
    func missingSection() {
        let markdown = "## Situation\nSomething.\n\n## Background\nContext."
        let result = parseSBAR(from: markdown)
        #expect(result == nil)
    }

    @Test("Strips frontmatter before parsing")
    func withFrontmatter() {
        let markdown = """
        ---
        date: 2026-03-07
        ---
        ## Situation
        S.

        ## Background
        B.

        ## Assessment
        A.

        ## Recommendation
        R.
        """
        let result = parseSBAR(from: markdown)
        #expect(result != nil)
    }
}
