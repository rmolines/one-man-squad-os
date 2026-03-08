# HANDOVER.md — Session history

Newest entries at the top.

---

## milestone-scanner — 2026-03-08

### O que foi feito

- Adicionado filtro em `FeaturePlanScanner.swift` para excluir slugs que batem com `M\d+` (M1, M2, M3, M4…), impedindo que diretórios de milestone apareçam como hypothesis cards no portfolio grid.
- Criado `Sources/Core/MilestoneScanner.swift` com `MilestoneInfo` struct e função `listMilestones(featurePlansPath:)` que varre os diretórios M* e parseia o `sprint.md` de cada um para extrair os feature slugs (coluna 3 da tabela, backtick-quoted).
- Atualizado `PortfolioStore.swift` com propriedade `milestones: [MilestoneInfo]` e chamada a `listMilestones()` no `reload()`, expondo a lista de milestones para uso futuro pelo `milestone-kanban`.
- Executado `xcodegen generate` para registrar `MilestoneScanner.swift` no xcodeproj.
- Build `swift build` verde após todas as mudanças.

### Decisões tomadas

- Filtro de M* implementado em `FeaturePlanScanner.swift` via regex `M\d+` aplicado ao slug — mínima intrusão, sem mudar a assinatura de `listFeaturePlans`.
- `MilestoneInfo` eager-loads `featureSlugs` na construção (stored property `let`) — evita o padrão de computed property com disk I/O que foi pitfall em `FeaturePlanInfo`.
- Parser de `sprint.md` é line-level: detecta linhas de tabela (pipe-separated), extrai coluna 3 e faz unquoting de backticks — suficiente para o formato atual do sprint.md gerado por `/start-milestone`.
- `MilestoneScanner` fica em `Sources/Core` (não em App) — lógica de domínio, segue a separação de camadas do projeto.

### Armadilhas encontradas

- Novo arquivo Swift criado fora do Xcode não é automaticamente incluído no xcodeproj — necessário rodar `xcodegen generate` após criar `MilestoneScanner.swift` (pitfall já documentado em CLAUDE.md).
- `MilestoneInfo` como struct com computed properties que fazem disk I/O causaria O(N log N) reads no sort — resolvido com eager-load de `featureSlugs` na construção (mesma solução aplicada em `FeaturePlanInfo`).

### Próximos passos

- `milestone-kanban` (próxima feature do M4) pode consumir `PortfolioStore.milestones` diretamente para renderizar o kanban por milestone.
- Parser de `sprint.md` assume formato de tabela com slug na coluna 3 — se o formato mudar, atualizar `MilestoneScanner.parseSprint`.
- `listMilestones` não detecta status do milestone (active/done/pending) — considerar adicionar leitura de campo de status do sprint.md em iteração futura.

### Arquivos-chave

- `Sources/Core/FeaturePlanScanner.swift` — filtro de slugs M\d+ adicionado
- `Sources/Core/MilestoneScanner.swift` — novo; `MilestoneInfo` struct + `listMilestones()` + parser sprint.md
- `Sources/OneManSquadOS/Stores/PortfolioStore.swift` — `var milestones: [MilestoneInfo]` + chamada no `reload()`

---

## markdown-renderer — 2026-03-08

**O que foi feito:** Implementado componente de rendering de markdown para o app. `MarkdownRenderer.swift` (Core) expõe `parseMarkdown(_ raw: String) -> [MarkdownBlock]` com parser line-level suportando H1–H3, parágrafos, bullet lists, fenced code blocks, dividers e linhas vazias. `MarkdownView.swift` (App) é um componente SwiftUI reutilizável com subviews `MarkdownHeadingView` e `MarkdownCodeBlockView`; blocks parsed uma única vez no `init` e armazenados como `let`. `stripFrontmatter` em `SBARParser.swift` promovido de `private` para `public`. xcodeproj regenerado via xcodegen para incluir `MarkdownView.swift` no target. PR #15 merged 2026-03-08.

**Decisões tomadas:**
- Parser line-level (não AST completo) — suficiente para os artefatos do projeto (plan.md, explore.md, discovery.md); evita dependência externa de swift-markdown
- Parsing em Core, rendering em App — separação de camadas mantida
- `MarkdownBlock: Hashable` permite `ForEach(id: \.self)` com identidade estável no SwiftUI

**Arquivos-chave:**
- `Sources/Core/MarkdownRenderer.swift` — novo; `parseMarkdown`, enum `MarkdownBlock: Sendable, Hashable`
- `Sources/OneManSquadOS/Views/MarkdownView.swift` — novo; `MarkdownView`, `MarkdownHeadingView`, `MarkdownCodeBlockView`
- `Sources/Core/SBARParser.swift` — `stripFrontmatter` promovido a `public`

**Próximos passos:** As 3 outras features do M4 (project-hierarchy-view, milestone-kanban, artifact-reader, agent-tasks-view) dependem deste componente — `MarkdownView` pode ser usado diretamente para renderizar artefatos em qualquer nova view.

---

## 2026-03-08 — polish — UX polish: hover, títulos humanizados, animações, ⌘R

**O que foi feito:**
Polish geral da UI do cockpit. `FeaturePlanInfo.title` agora humaniza o slug (kebab-case → Title Case) no modelo em vez da view, garantindo consistência em qualquer view futura. Cards têm hover effect com fundo + borda animados (150ms easeInOut). Animação de refresh corrigida: usa `isSpinning: Bool` + `.onChange(of: store.isLoading)` em vez do padrão `withAnimation + refreshRotation += 360` que acumulava estado indefinidamente. ⌘R atalho no botão refresh. Cards aparecem com `.opacity + .scale(0.95)` ao carregar o grid.

**Decisões tomadas:**
- `humanizedTitle` movido de `HypothesisCardView` para `FeaturePlanInfo.title` (sugerido pelo simplify review)
- Sort por `lastArtifactDate` removido do `PortfolioStore.reload()` — `listFeaturePlans` já retorna ordenado por status priority + data; o double sort destruía a ordem
- Animação de spin implementada como `@State private var isSpinning: Bool` com único `.animation` modifier, sem imperative `withAnimation` no button action

**Armadilhas encontradas:**
- Double sort: `listFeaturePlans` já ordena por `statusOrder` + `lastArtifactDate`; adicionar `.sorted` no `reload()` destruía a ordering de status priority
- `withAnimation(.repeatForever)` no button action + `.animation(..., value: isLoading)` no modifier cria dois drivers concorrentes; SwiftUI resolve para o segundo, causando jump

**Próximos passos:**
- M3 concluído — próximo milestone é M4 (project-hierarchy-view, milestone-kanban, artifact-reader, agent-tasks-view)

**Arquivos-chave:**
- `Sources/Core/Models/HypothesisModel.swift` — `title` humaniza slug
- `Sources/OneManSquadOS/Views/HypothesisCardView.swift` — hover effect
- `Sources/OneManSquadOS/Views/PortfolioView.swift` — animação refresh + ⌘R + grid transitions

---

## 2026-03-08 — cockpit-model — feature-plans/ como source of truth

**O que foi feito:**
Trocou a unidade de identidade do cockpit de `worktree path` para `slug`. O `PortfolioStore` agora chama `listFeaturePlans(repoPath:)` que indexa `.claude/feature-plans/<slug>/` diretamente. Worktrees são attachadas como execution context via JOIN por naming convention (`feat/<slug>`). Status inference passou a ler do lugar certo (main repo, não worktree). Novo status `.discovered` adicionado (discovery.md ou research.md presente). `BacklogHypothesis` migrado para V2 com `slug` como `@Attribute(.unique)`.

**Decisões tomadas:**
- `ArtifactSet` cacheado em `FeaturePlanInfo` como stored property — elimina I/O O(N log N) no sort e disk I/O por frame no SwiftUI render
- `reload()` usa `Task.detached` para não bloquear main thread (git subprocess `waitUntilExit` era chamado no main actor)
- SwiftData migration V1→V2 feita por rename do store (`CockpitStoreV2`) em vez de `SchemaMigrationPlan` — ambos os schemas apontavam para o mesmo `BacklogHypothesis.self`, causando "current model reference == next model reference"
- `FSEventStreamScheduleWithRunLoop` substituído por `FSEventStreamSetDispatchQueue` (deprecated macOS 13)
- `archived` filtrado do scanner via `organisationalContainers: Set<String>`

**Armadilhas encontradas:**
- `CockpitSchemaV1` e `CockpitSchemaV2` com `models` apontando para o mesmo tipo causam fatalError em runtime; solução: rename do store ou classe V1 separada aninhada no enum do schema
- `FeaturePlanInfo` como struct com computed properties que fazem disk I/O causa O(N log N) reads no sort — sempre eager-load `ArtifactSet` na construção

**Próximos passos:**
- `BacklogHypothesis` ainda não é usado na UI — gap conceitual entre SwiftData model e `FeaturePlanInfo` in-memory. Próximo milestone pode resolver.
- Worktree JOIN com detached HEAD retorna `nil` branch — silently unattached. Issue conhecida.
- `archived` como exclusion hardcoded — considerar marker file (`.noindex`) para ser data-driven.

**Arquivos-chave:**
- `Sources/Core/FeaturePlanScanner.swift` — novo; `listFeaturePlans`
- `Sources/Core/Models/HypothesisModel.swift` — `FeaturePlanInfo` + `.discovered`
- `Sources/Core/ArtifactReader.swift` — `readArtifacts(featurePlansPath:)`
- `Sources/OneManSquadOS/Stores/PortfolioStore.swift` — dual watchers, async reload
- `Sources/OneManSquadOS/Models/CockpitSchema.swift` — `CockpitSchemaV2`

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
