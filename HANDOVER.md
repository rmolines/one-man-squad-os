# HANDOVER.md — Session history

Newest entries at the top.

---

## 2026-03-07 — app-foundation — SwiftUI skeleton + SwiftData V1

**What was done:**

- Created entire `Sources/OneManSquadOS/` app layer (was empty before this feature)
- `CockpitApp`: `MenuBarExtra(.window)` + `WindowGroup("portfolio")` + `AppDelegate` for `activationPolicy`
- SwiftData schema V1: `CockpitSchemaV1` (VersionedSchema), `BacklogHypothesis` @Model, `CockpitSettings` @Model
- `CockpitSchema.container` with `CockpitSchemaMigrationPlan` (no stages — V1 baseline)
- `PortfolioStore`: `@Observable @MainActor` placeholder
- `MenuBarView` / `PortfolioView`: placeholders

**Architectural decisions:**

- `MenuBarExtra(.window)` style — enables `@Environment(\.openWindow)` in children (`.menu` style doesn't)
- `activationPolicy` managed via `AppDelegate`: `.accessory` on launch, `.regular` when portfolio window opens
- `VersionedSchema` from day 1 — never edit V1 directly; always add `CockpitSchemaV2` with migration stage
- `PortfolioStore` as placeholder to decouple foundation from view logic (portfolio-view feature)
- `EonilFSEvents` removed from `project.yml` — `eonil/FSEvents` repo is gone from GitHub; FSEvents is M2 scope

**Pitfalls hit:**

- App "crashed silently" was actually activationPolicy change — Dock icon disappears, menu bar icon appears (expected)
- `eonil/FSEvents` repo no longer exists on GitHub — removed from `project.yml`
- Committed xcodeproj had machine-specific package cache paths — must run `xcodegen generate` in each worktree

**Files created:**

- `Sources/OneManSquadOS/App/CockpitApp.swift`, `AppDelegate.swift`
- `Sources/OneManSquadOS/Models/BacklogHypothesis.swift`, `CockpitSettings.swift`, `CockpitSchema.swift`
- `Sources/OneManSquadOS/Stores/PortfolioStore.swift`
- `Sources/OneManSquadOS/Views/MenuBarView.swift`, `PortfolioView.swift`

**Open threads:**

- `EonilFSEvents` alternative needed for M2 — `eonil/FileSystemEvents` is a candidate
- `PortfolioStore` real implementation → `portfolio-view` feature

---

## 2026-02-27 — Bootstrap via /start-project

**What was done:**

- Executed Fase 3 (Bootstrap) of `/start-project` for the `claude-kickstart` template repository
- Created GitHub repo `rmolines/claude-kickstart` (public)
- Wrote all project files: CLAUDE.md, Makefile, CI workflows, skills, hooks, rules, memory files

**Architectural decisions:**

- GitHub Template Repository format (not CLI) — zero friction
- Hooks in `.claude/hooks/` external scripts (not inline `settings.json`) — auditable, CVE-2025-59536 compliant
- Static CI only (lint + JSON + structure) — no runtime to test
- `bootstrap.yml` with `run_number == 1` guard — auto-applies branch protection on first fork push

**Files created:**

- `CLAUDE.md`, `README.md`, `LEARNINGS.md`, `HANDOVER.md`, `Makefile`
- `.claude/settings.json`, `.claude/settings.md`
- `.claude/hooks/pre-tool-use.sh`
- `.claude/scripts/validate-structure.sh`
- `.claude/rules/git-workflow.md`, `coding-style.md`, `security.md`
- `.claude/commands/start-feature.md`, `ship-feature.md`, `close-feature.md`, `handover.md`, `sync-skills.md`
- `.claude/commands/SYNC_VERSION`
- `.github/workflows/ci.yml`, `bootstrap.yml`, `template-sync.yml`
- `.github/dependabot.yml`, `CODEOWNERS`, `SECURITY.md`
- `memory/MEMORY.md`

**Open threads:**

- Demo GIF/video for README (identified as high-risk if not done before launch)
- CONTRIBUTING.md for community contributors
- Mark repo as Template in GitHub Settings (done via API in bootstrap sequence)
