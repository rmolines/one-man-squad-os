# HANDOVER.md — Session history

Newest entries at the top.

---

## write-infrastructure — 2026-03-08

**PR:** #20 — feat(core): FileWriter service — path traversal validation + atomic write
**Commit:** 66d8808

### O que foi feito

- Criado `Sources/Core/FileWriter.swift` no target Core (Foundation puro, sem SwiftUI)
- API pública: `previewWrite(content:to:rootRepoPath:) -> Result<WritePreview, FileWriterError>` e `commitWrite(_:) throws`
- `previewWrite` valida: rejeita paths absolutos (com `/` no início), rejeita traversal `..` via `URL.standardized` + verificação de prefixo, escopo restrito a `.claude/feature-plans/`
- `commitWrite`: escrita atômica via arquivo temporário + `FM.replaceItem` (arquivo existente) ou `FM.moveItem` (arquivo novo)
- Criado `Tests/CoreTests/FileWriterTests.swift` com 8 testes: happy path novo arquivo, captura conteúdo existente, rejeita traversal `..`, rejeita path absoluto, rejeita traversal aninhado, cria dirs intermediários, sem temp files residuais, sobrescreve existente
- Todos os 23 testes passam

### Decisões tomadas

- `FileWriterError` usa `@unchecked Sendable` porque wrapa `Error` (Swift 6 strict concurrency)
- `WritePreview` é value type (struct) com `existingContent: String?` para dry-run display
- `FM.replaceItem` para arquivos existentes (atomic swap) e `FM.moveItem` para arquivos novos

### Armadilhas encontradas

- `gh pr create` em worktree com remote `upstream` configurado detecta o repo errado (`claude-kickstart` em vez de `one-man-squad-os`) — corrigido com flag `-R rmolines/one-man-squad-os` explícita

### Próximos passos

- `artifact-editor`: editor markdown inline na UI que chama `FileWriter` + `PortfolioStore.reload()`

### Arquivos-chave

- `Sources/Core/FileWriter.swift`
- `Tests/CoreTests/FileWriterTests.swift`

---

## project-hierarchy-view — 2026-03-08

**O que foi feito:** Implementado painel de documentos navegáveis que abre ao clicar em um hypothesis card. `FeatureDocumentsView.swift` é um overlay sheet com tab picker (Explore / Discovery / Research / Plan) e `MarkdownView` para renderizar o conteúdo. `HypothesisCardView.swift` recebeu callback `onSelect` delegando a apresentação ao pai. `PortfolioView.swift` passou a gerenciar `selectedHypothesis: FeaturePlanInfo?` em estado local com ZStack overlay, backdrop escuro e light-dismiss ao clicar fora. `HypothesisStatus+UI.swift` consolidou o `StatusChip` que estava duplicado em dois arquivos.

**Decisões tomadas:**
- ZStack overlay com backdrop `Color.black.opacity(0.25)` — `.sheet` não fecha com clique fora no macOS; `.popover` ancora com seta indesejada; overlay ZStack + tap-to-dismiss foi a solução limpa
- `.windowBackgroundColor` no painel em vez de `.regularMaterial` — `.regularMaterial` gerava cinza fosco não desejado; `windowBackgroundColor` entrega o branco/escuro do sistema corretamente
- `onSelect` callback em `HypothesisCardView` — delegação ao pai mantém o card sem estado de apresentação; PortfolioView é o coordenador de navegação
- `import Core` necessário em `PortfolioView.swift` — `FeaturePlanInfo` vive no módulo Core; sem o import o compilador não encontra o tipo

**Armadilhas encontradas:**
- `.sheet` no macOS não fecha ao clicar fora da sheet — comportamento diferente do iOS; requer dismiss explícito ou solução alternativa
- `.popover` ancora com seta visual que não é adequada para painel de documentos grandes
- `Color.black.opacity(0.001)` como backdrop transparente captura taps mas não bloqueia visualmente o fundo — opacidade mínima necessária para hit-testing; usar `0.25` para feedback visual de "modal"

**Próximos passos:**
- `agent-tasks-view` — próxima feature do M4 (deps: markdown-renderer já disponível)

**Arquivos-chave:**
- `Sources/OneManSquadOS/Views/FeatureDocumentsView.swift` — novo; tab picker + MarkdownView para artefatos da feature
- `Sources/OneManSquadOS/Views/HypothesisCardView.swift` — callback `onSelect` adicionado; apresentação delegada ao pai
- `Sources/OneManSquadOS/Views/PortfolioView.swift` — ZStack overlay + `selectedHypothesis` state + backdrop com light-dismiss
- `Sources/OneManSquadOS/Views/HypothesisStatus+UI.swift` — `StatusChip` consolidado (era duplicado em 2 arquivos)

---

## milestone-kanban — 2026-03-08

**PR:** #17

### O que foi feito

- Criado `MilestoneKanbanView.swift` — view SwiftUI que agrupa hipóteses em linhas por `MilestoneInfo` × colunas por `HypothesisStatus`. Features sem milestone aparecem em seção "Outros". `rows` implementado como computed var (não `let` no init) para que o `@Observable` tracking de `store.milestones` e `store.hypotheses` funcione corretamente após reloads do FSEvents.
- Criado `HypothesisStatus+UI.swift` — extension compartilhada com `label` e `color` por status, eliminando a duplicação entre `HypothesisCardView` e `MilestoneKanbanView`.
- Atualizado `PortfolioView.swift` — toggle "Grid | Kanban" na toolbar com estado persistido via `@AppStorage` usando enum `ViewMode` tipado (conformância `RawRepresentable` disponível macOS 11+, sem `String` rawValue manual).
- Atualizado `HypothesisCardView.swift` — extensão privada de label/color removida (movida para `HypothesisStatus+UI.swift`).

### Decisões tomadas

- `rows` como computed var (não `let` no init) — correção crítica de reatividade `@Observable`: se calculado no `init`, SwiftUI nunca registra `store.milestones`/`store.hypotheses` como dependências e o kanban mostra dados stale após FSEvents reload.
- `HypothesisStatus+UI.swift` em `Sources/OneManSquadOS/Views/` — lógica de apresentação, não de domínio; segue separação de camadas.
- `@AppStorage` com enum `ViewMode` diretamente via `RawRepresentable` — mais type-safe que guardar `String` rawValue explicitamente.
- Features sem milestone agrupadas em "Outros" — sem crash silencioso para hipóteses órfãs de sprint.md.

### Armadilhas encontradas

- `@Observable` + propriedade computada no `init`: SwiftUI só rastreia acesso a `store.milestones`/`store.hypotheses` se eles forem lidos durante o body render — não durante o `init` da struct. Propriedade `rows` como computed var garante que o acesso ocorre no render path, habilitando o tracking automático.

### Próximos passos

- `artifact-reader` e `agent-tasks-view` são as próximas features do M4 — `MarkdownView` já disponível para renderizar artefatos.
- Kanban não mostra status do milestone (active/done/pending) — considerar badge de status na row header em iteração futura.

### Arquivos-chave

- `Sources/OneManSquadOS/Views/MilestoneKanbanView.swift` — novo; kanban por milestone × status
- `Sources/OneManSquadOS/Views/HypothesisStatus+UI.swift` — novo; label/color compartilhados por status
- `Sources/OneManSquadOS/Views/HypothesisCardView.swift` — extensão privada de status UI removida
- `Sources/OneManSquadOS/Views/PortfolioView.swift` — toggle Grid/Kanban + `@AppStorage ViewMode`

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

---

## 2026-03-08 — agent-tasks-view

**What was done:**

- Added `TaskItem` struct (`Sendable`, `Identifiable` with sequential `Int` id) to `Sources/Core/MarkdownRenderer.swift`
- Added `parseTaskItems(_ raw: String) -> [TaskItem]` to `MarkdownRenderer.swift` — strips frontmatter, then extracts `- [x]` / `- [ ]` lines into `TaskItem` values
- Added `taskItems: [TaskItem]` as `let` stored property to `ArtifactSet` in `Sources/Core/ArtifactReader.swift` — computed once at construction via `planMd.map { parseTaskItems($0) } ?? []`
- Added `TaskSummaryView` + `TaskRowView` private structs to `Sources/OneManSquadOS/Views/HypothesisCardView.swift` — shows up to 3 tasks + "X/Y done" counter + "+N more" overflow label
- Refactored: initially implemented `tasks` as a computed var in `HypothesisCardView` (re-parsed plan.md on every SwiftUI render including hover); moved to `ArtifactSet.taskItems` as eager-loaded stored property

**Architectural decisions:**

- Task parsing lives in Core (not UI) — `ArtifactSet` is the single owner; follows the same eager-load pattern established for `inferredStatus` and `hasPendingBrief`
- Sequential `Int` IDs for `TaskItem.id` — safe for static plan.md lists; documented as unsafe if list changes dynamically (V2 concern)
- No PR — direct push to main (fast path); commits: 40e45eb (feat), f3203aa (docs plan.md), 5cd537c (refactor: move parseTaskItems to ArtifactSet)

**Pitfalls hit:**

- Computed `var tasks` in `HypothesisCardView.init` re-parsed plan.md on every hover event — high-frequency SwiftUI renders make disk I/O on this path expensive; fixed by moving parsing to `ArtifactSet` at construction time (same pitfall documented in CLAUDE.md under `FeaturePlanInfo computed properties with disk I/O`)

**Files created/modified:**

- `Sources/Core/MarkdownRenderer.swift` — `TaskItem` struct + `parseTaskItems` function added
- `Sources/Core/ArtifactReader.swift` — `ArtifactSet.taskItems` eager-loaded stored property added
- `Sources/OneManSquadOS/Views/HypothesisCardView.swift` — `TaskSummaryView` + `TaskRowView` private structs added

**Open threads:**

- V2: dynamic task IDs (content-hash or UUID) when tasks can be added or removed at runtime
- Consider surfacing task completion count in milestone overview row headers (kanban)

---

## philosophy-driven-ux — 2026-03-09

**PR:** #22 + #23
**Branch:** feat/philosophy-driven-ux (merged + deleted)

### O que foi feito

- Replaced flat `[FeaturePlanInfo]` model with `ProjectNode` typed tree: `RepoNode → GroupNode → FeatureNode`
- Added `Phase` enum (`discovery`/`planning`/`delivery`), `Gate` struct with `evaluateGate()`, `ConfidenceParser` (reads `confiança:` as bare line in markdown body)
- `ArtifactSet` now eager-loads `inferredPhase`, `confidenceT`, `taskItems` at construction — zero I/O per render
- `PortfolioStore` replaced `hypotheses`/`milestones` with `repoTree: RepoNode?` via `buildProjectTree()`
- `NavigationSplitView` 3-panel layout: sidebar of groups, feature list, detail pane with `.prominentDetail`
- `HillChartView`: Canvas + cubic bezier, `HillItem` with `t: CGFloat` derived from `confidenceT`
- `ClarifyDetailView` / `ExploreDetailView`: H2 section parser, headline extraction (tensão cristalizada / hipótese)
- `GateIndicatorView`: lock icon + missing artifact names when `gate.canAdvance == false`
- `HealthBadgeView`: staleness dot + relative date via `RelativeDateTimeFormatter`
- Added shared `parseMarkdownH2Sections` helper; promoted `PhaseChip`/`StatusChip` to internal; `sections` as `let`; removed duplicate `parseTaskItems` call
- Deleted `MilestoneKanbanView` (replaced by `NavigationSplitView`)
- Cleaned up 5 dead worktrees whose content had already been merged

### Decisões tomadas

- `confiança:` parsed as bare markdown line (not YAML frontmatter) — line scan with `hasPrefix("confiança:")`
- `Phase` chips and `Status` chips extracted to internal (not private) to enable reuse across views
- `Task @MainActor` annotation added to `PortfolioStore.reload()` closure for Swift 6 strict concurrency compliance
- `MilestoneKanbanView` deleted outright — `NavigationSplitView` with group sidebar supersedes the kanban layout

### Armadilhas encontradas

- `GateEvaluator.swift` was initially written to `.claire/` (typo) instead of `.claude/` — wrong directory was deleted and file re-created in the correct path
- `.build/` accidentally staged and committed — removed with `git rm -r --cached .build` + follow-up cleanup commit
- HTTP 400 on `git push` resolved by increasing `http.postBuffer` to 524288000
- `gh pr merge --repo` flag is not valid on the `gh repo view` subcommand — use `gh api` for branch deletion after merge

### Próximos passos

- MilestoneScanner feature (upcoming milestone)
- Hill Chart could display milestone-level rollup as a future enhancement

### Arquivos-chave

- `Sources/Core/Phase.swift`
- `Sources/Core/ProjectNode.swift`
- `Sources/Core/GateEvaluator.swift`
- `Sources/Core/ConfidenceParser.swift`
- `Sources/Core/ArtifactReader.swift`
- `Sources/Core/FeaturePlanScanner.swift`
- `Sources/OneManSquadOS/Stores/PortfolioStore.swift`
- `Sources/OneManSquadOS/Views/PortfolioView.swift`
- `Sources/OneManSquadOS/Views/HillChartView.swift`
- `Sources/OneManSquadOS/Views/ClarifyDetailView.swift`
- `Sources/OneManSquadOS/Views/ExploreDetailView.swift`
- `Sources/OneManSquadOS/Views/MarkdownSectionParser.swift`

---
