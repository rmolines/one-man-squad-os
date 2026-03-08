# HANDOVER.md — Session history

Newest entries at the top.

---

## 2026-03-08 — status-inference — WorktreeStatus inferido de artefatos

**O que foi feito:**
`ArtifactSet.inferredStatus` adicionado com prioridade: `pendingDecision` (brief SBAR válido presente) > `building` (sprint.md ou plan.md) > `exploring` (explore.md) > `idle`. `WorktreeInfo.status` deixou de retornar `.idle` hardcoded e passa a chamar `readArtifacts(worktreePath:).inferredStatus`. UI não mudou — `StatusChip` já renderizava todos os casos.

**Decisões:**
- Inferência colocada em `ArtifactSet` (Core), não na view — lógica de domínio, não de apresentação.
- Arquivos tocados: `ArtifactReader.swift`, `HypothesisModel.swift` (2 arquivos, sem migration SwiftData).

**Armadilha encontrada:**
Nenhuma nova — fluxo direto.

**Contexto importante para próxima sessão:**
Após esta feature foi feito um `/explore` que identificou um erro de categoria no modelo do app: worktree ≠ hipótese. Worktree é execution context; a aposta vive em `.claude/feature-plans/`. O explore está em `.claude/feature-plans/cockpit-model/explore.md` e o intent é um **roadmap resteer** antes de continuar M3. Próximo passo: `/clear` → `/start-feature --discover cockpit-model`.

**Arquivos-chave:**
- `Sources/Core/ArtifactReader.swift` — `inferredStatus` em `ArtifactSet`
- `Sources/Core/Models/HypothesisModel.swift` — `WorktreeInfo.status`

---

## 2026-03-08 — sbar-detail-view — Popover SBAR ao clicar no badge

**What was done:**
`PendingBriefBadge` virou `Button` com `.popover(arrowEdge: .bottom)` — clicar no badge abre `SBARDetailView`, um painel com as 4 seções SBAR em ScrollView. Recommendation é visualmente destacada (fundo accent color). Fecha o loop de valor do M2: vê badge → clica → lê → decide em <60s.

**Key decisions:**
- `pendingBrief: SBARBrief?` é computed var no card — chama `readArtifacts` + `parseSBAR` diretamente, sem mudar o protocolo `HypothesisCard`. Simples e suficiente para V1.
- `.popover` com `arrowEdge: .bottom` testado em `LazyVGrid` — âncora limpa sem corte pela borda da janela (ao menos com 1 card na grid).
- `.frame(minWidth:maxWidth:minHeight:maxHeight:)` — overload completo obrigatório; `width:` e `idealHeight:` sozinhos não compilam em SwiftUI.

**Pitfalls encountered:**
- `.frame(width: 380, idealHeight: 460)` → erro "Extra argument 'idealHeight' in call" — `idealHeight` não existe no overload `(width:height:alignment:)`.
- `.frame(width: 380, minHeight: 200, maxHeight: 560)` → erro "Extra argument 'width' in call" — SwiftUI tem dois overloads mutuamente exclusivos; não há mix. Usar `(minWidth:maxWidth:minHeight:maxHeight:)`.

**Key files:**
- `Sources/OneManSquadOS/Views/SBARDetailView.swift` — novo; layout das 4 seções SBAR
- `Sources/OneManSquadOS/Views/HypothesisCardView.swift` — badge vira Button com popover

**Next steps (M3):**
- UI polish do popover (tipografia, espaçamento, dark mode)
- `status-inference` — status real via presença de `explore.md`, `plan.md`, `sprint.md`
- `settings-view` — painel de preferências para trocar repo root sem toolbar

---

## 2026-03-07 — fsevents-watch — RepoWatcher + reactive PortfolioStore

**What was done:**
Created `RepoWatcher.swift` — a thin `FSEventStreamRef` wrapper that watches a repo root recursively and fires an `onChange` closure on the main thread (scheduled on `CFRunLoopGetMain`). Updated `PortfolioStore` to hold a `watcher: RepoWatcher?` and `watchedPath: String`, extracted `reload()` as a private method, and wired `refresh(repoPath:)` to create/reuse the watcher when the path changes. Portfolio now auto-refreshes whenever the filesystem under the repo root changes — no manual pull-to-refresh required.

**Key decisions:**
- `RepoWatcher` owns the `FSEventStreamRef` and stops/invalidates/releases it in `deinit` — no manual lifecycle management needed at call site.
- Latency defaults to 1.0 s to coalesce rapid bursts (e.g. worktree creation creates multiple events).
- `CallbackBox` bridges the Swift closure through the C API via opaque pointer + `Unmanaged` — avoids unsafe casts.
- Watcher is recreated only when `repoPath` changes, so rapid `refresh()` calls don't spawn multiple streams.
- Strict concurrency: `RepoWatcher` is `final class` (not `Sendable`) but lives entirely in the `@MainActor` context via the callback being delivered on the main thread.

**Pitfalls encountered:**
- None new beyond those already documented (FSEvents.framework available without extra SPM deps — confirmed).

**Key files:**
- `Sources/OneManSquadOS/Stores/RepoWatcher.swift` — new; FSEvents wrapper
- `Sources/OneManSquadOS/Stores/PortfolioStore.swift` — watcher integration + reload() extraction

**Next steps (M2):**
- Use the same FSEvents infra to invalidate `hasPendingBrief` caches when `.claude/decisions/` changes (currently computed on every card render)
- Add `kFSEventStreamCreateFlagNoDefer` flag if 1 s latency feels sluggish in practice

---

## 2026-03-08 — sbar-detection — hasPendingBrief + lastArtifactDate + PendingBriefBadge

**What was done:**
Implemented `hasPendingBrief` and `lastArtifactDate` in the `WorktreeInfo: HypothesisCard` extension. The two protocol stubs were hardcoded `false`/`nil` — now they call `readArtifacts()` + `parseSBAR()` (both already in Core) on demand. Added `PendingBriefBadge` in `HypothesisCardView` — a red `exclamationmark.circle.fill` icon with tooltip "Pending decision brief" that renders when `hasPendingBrief == true`.

**Key decisions:**
- `hasPendingBrief` is a computed property on the extension — reads `.claude/decisions/*.md` on every access. Acceptable for V1 (called when card renders, not in a tight loop).
- "Pending" = ≥1 file in `.claude/decisions/` that parses as valid SBAR (has all 4 sections). No "resolved" state in V1.
- `lastArtifactDate` uses `FileManager` directly (not `readArtifacts` which only returns content) to get `contentModificationDate` of the brief files.
- Badge is `iconOnly` label style — compact, tooltip carries the semantic meaning.

**Pitfalls encountered:**
- `git ls-remote` showed empty because branch was never pushed to remote yet — the stale `origin/feat/portfolio-view` reference was from a previous push that the `--force-with-lease` failed on. Resolved by fetching first.
- `Package.resolved` was modified by `xcodegen generate` — caused rebase to refuse. Stash before rebase.

**Key files:**
- `Sources/Core/Models/HypothesisModel.swift` — `hasPendingBrief` + `lastArtifactDate` implementation
- `Sources/OneManSquadOS/Views/HypothesisCardView.swift` — `PendingBriefBadge` component

**Next steps (M2):**
- FSEvents watch so `hasPendingBrief` refreshes automatically when a new brief is dropped in `.claude/decisions/`
- `status` inference from git log / presence of plan.md / sprint.md

---

## 2026-03-08 — portfolio-view — listWorktrees() → PortfolioStore → hypothesis cards

**What was done:**
Connected `listWorktrees()` from Core to `PortfolioStore` and rendered worktrees as hypothesis cards in `PortfolioView`. Full walking skeleton: onboarding → folder picker → grid of cards.

**Key decisions:**
- `WorktreeInfo: HypothesisCard` conformance added via extension in `HypothesisModel.swift` (same Core target — no new file needed). `status = .idle` hardcoded for V1; real status via git parsing is M2.
- `PortfolioStore.refresh()` is synchronous on MainActor — `git worktree list` is sub-100ms locally, acceptable for V1. Async dispatch deferred to M2.
- `CockpitSettings.rootRepoPath` (already in SwiftData V1 schema) stores the user-selected repo root — no schema migration needed.
- `NSOpenPanel` used directly without Security-Scoped Bookmarks (app is non-sandboxed per CLAUDE.md).
- `settings` computed var in `PortfolioView` does a lazy `modelContext.insert(CockpitSettings())` on first access — avoids crash if SwiftData store is empty.
- `isMain` worktrees are filtered out from the cards — only feature worktrees show.

**Pitfalls encountered:**
- None new. EnterWorktree created branch as `worktree-portfolio-view` — manually renamed to `feat/portfolio-view` to match CLAUDE.md convention.

**Key files:**
- `Sources/Core/Models/HypothesisModel.swift` — `WorktreeInfo: HypothesisCard` extension
- `Sources/OneManSquadOS/Stores/PortfolioStore.swift` — `refresh(repoPath:)`, `hypotheses`, `loadError`
- `Sources/OneManSquadOS/Views/PortfolioView.swift` — onboarding + grid + toolbar
- `Sources/OneManSquadOS/Views/HypothesisCardView.swift` — card UI (new file)

**Next steps (M2):**
- FSEvents watch for auto-refresh without manual button
- Real status detection via `git status` / branch state parsing
- `hasPendingBrief` detection by reading `.claude/decisions/` SBAR files

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
