# LEARNINGS.md — Technical learnings

Gotchas, limitations, and non-obvious behaviors discovered while working on this project.

---

## GitHub Actions

### `bootstrap.yml`: `run_number == 1` guard

`github.run_number` starts at 1 for the first run of any workflow in a repo. Using this as a
guard ensures branch protection is only applied once. **Do not re-run this workflow manually** —
it will attempt to apply protection again (which is usually fine but clutters logs).

### `template-sync.yml`: must guard with `!is_template`

Without the `!github.event.repository.is_template` guard, the sync workflow would run on the
template repo itself and open PRs against its own `main`. The guard makes it a no-op on the
template and active only on forks.

### Action SHA pinning

Always pin to full commit SHA, not tag:
```yaml
# Good
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
# Bad (tag can be hijacked)
uses: actions/checkout@v4
```

---

## Claude Code hooks (CVE-2025-59536)

Hooks in `.claude/settings.json` execute shell commands **without user confirmation**.
This was documented in CVE-2025-59536. Mitigation: keep hook logic in external scripts
(`.claude/hooks/`) so they're visible, auditable, and can be reviewed in PRs.

---

## SwiftUI macOS — MenuBarExtra + activationPolicy

### Dock icon briefly appears on launch — expected behavior

With `LSUIElement = false` in Info.plist, the app shows a Dock icon on launch.
When `applicationDidFinishLaunching` calls `NSApp.setActivationPolicy(.accessory)`,
the icon disappears. This is correct — it looks like a crash but it is not.
The menu bar icon appears in the top-right corner after the Dock icon vanishes.

If the menu bar is full, the icon may be hidden behind the `>>` overflow indicator.

### EonilFSEvents (`eonil/FSEvents`) is no longer available on GitHub

As of 2026-03, `https://github.com/eonil/FSEvents` returns "Repository not found".
Removed from `project.yml` — FSEvents watch is M2 scope. Find an alternative before M2.
Candidates: `eonil/FileSystemEvents`, or roll a thin `FSEvents` C wrapper directly.

### xcodegen + worktrees: always regenerate xcodeproj in the worktree

The committed `OneManSquadOS.xcodeproj` may have absolute paths from the original machine.
After creating a worktree, run `xcodegen generate` inside it before opening in Xcode.

---

## markdownlint

- Use `npx --yes markdownlint-cli2` to avoid requiring global install
- `MD013` (line length) needs `tables: false` and `code_blocks: false` to avoid false positives
- `MD024` (duplicate headings) should be disabled for `HANDOVER.md` — entries often have similar structure
- `MD041` (first heading must be h1) breaks templates with frontmatter or `<!-- TODO -->` comments
