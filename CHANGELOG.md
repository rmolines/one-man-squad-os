# Changelog

## markdown-renderer — PR #15 — 2026-03-08

**Tipo:** feat
**Commit:** `git show <SHA>` para diff completo
**Decisões e armadilhas:** ver LEARNINGS.md#markdown-renderer

---

## [improvement] Polish — hover, títulos humanizados, animações, ⌘R — 2026-03-08

**Tipo:** improvement
**Tags:** polish, ux, swiftui, animations, accessibility
**PR:** [#14](https://github.com/rmolines/one-man-squad-os/pull/14) · **Complexidade:** simples

### O que mudou
Cards agora mostram "Cockpit Model" (não "cockpit-model"), escurecem ao hover, e o botão refresh gira enquanto carrega. ⌘R dispara refresh via teclado.

### Detalhes técnicos
- `FeaturePlanInfo.title` humaniza slug (kebab-case → Title Case) no modelo — consistente em todas as views
- Hover effect em `HypothesisCardView` com fundo + borda animados (150ms easeInOut)
- Animação de refresh: `isSpinning: Bool` + `.onChange(of: store.isLoading)` — padrão correto sem acumulação de estado
- `.keyboardShortcut("r", modifiers: .command)` no botão refresh
- Transição `.opacity.combined(with: .scale(0.95))` nos cards do grid

### Impacto
- **Breaking:** Não

### Arquivos-chave
- `Sources/Core/Models/HypothesisModel.swift` — `title` humaniza slug
- `Sources/OneManSquadOS/Views/HypothesisCardView.swift` — hover effect
- `Sources/OneManSquadOS/Views/PortfolioView.swift` — animação refresh + ⌘R + grid transitions

---

## [feat] Cockpit Model — feature-plans/ como source of truth — 2026-03-08

**Tipo:** feat
**Tags:** cockpit-model, hypothesis-cards, portfolio, core, swiftdata
**PR:** [#11](https://github.com/rmolines/one-man-squad-os/pull/11) · **Complexidade:** alta

### O que mudou
O cockpit agora indexa `.claude/feature-plans/<slug>/` como source of truth para hipóteses, em vez de worktrees. Cards mostram slugs reais com status correto (`discovered` para features em pesquisa, `building` para features com plan). Reload do portfolio roda off-main-thread.

### Detalhes técnicos
- `FeaturePlanInfo` substitui `WorktreeInfo` como `HypothesisCard`; `ArtifactSet` cacheado na construção (zero disk I/O no sort e no render)
- `listFeaturePlans(repoPath:)` indexa slugs de `feature-plans/` com JOIN a worktrees por naming convention
- `PortfolioStore`: dual watchers FSEvents (`feature-plans/` + `.git/worktrees/`); `reload()` usa `Task.detached`
- `HypothesisStatus.discovered` adicionado para discovery.md/research.md presentes
- `BacklogHypothesis` migrado para V2 com `slug: String` como `@Attribute(.unique)`; store renomeado para `CockpitStoreV2`
- `FSEventStreamScheduleWithRunLoop` → `FSEventStreamSetDispatchQueue` (deprecated macOS 13)

### Impacto
- **Breaking:** Não — dados V1 de `BacklogHypothesis` não eram usados na UI; store resetado harmoniosamente

### Arquivos-chave
- `Sources/Core/FeaturePlanScanner.swift` — novo
- `Sources/Core/Models/HypothesisModel.swift` — `FeaturePlanInfo` + `.discovered`
- `Sources/OneManSquadOS/Stores/PortfolioStore.swift` — dual watchers, async reload
- `Sources/OneManSquadOS/Models/CockpitSchema.swift` — `CockpitSchemaV2`

---

## [feat] Status Inference — chips dos cards mostram status real do worktree — 2026-03-08

**Tipo:** feat
**Tags:** status-inference, hypothesis-cards, portfolio, core
**PR:** [#10](https://github.com/rmolines/one-man-squad-os/pull/10) · **Complexidade:** simples

### O que mudou
Cards do portfolio agora mostram status inferido automaticamente: "Exploring" se há `explore.md`, "Building" se há `plan.md`/`sprint.md`, "Decision" se há brief SBAR válido, "Idle" se nenhum artefato. Antes todos os cards mostravam "Idle" hardcoded.

### Detalhes técnicos
- `ArtifactSet.inferredStatus: HypothesisStatus` — nova propriedade computada com prioridade `pendingDecision > building > exploring > idle`
- `WorktreeInfo.status` deixou de retornar `.idle` hardcoded; agora usa `readArtifacts(worktreePath:).inferredStatus`

### Impacto
- **Breaking:** Não

### Arquivos-chave
- `Sources/Core/ArtifactReader.swift` — `inferredStatus` em `ArtifactSet`
- `Sources/Core/Models/HypothesisModel.swift` — `WorktreeInfo.status`

---

## [feat] SBAR Detail View — clicar no badge abre painel com o brief completo — 2026-03-08

**Tipo:** feat
**Tags:** sbar, hypothesis-cards, decision-brief, portfolio
**PR:** [#9](https://github.com/rmolines/one-man-squad-os/pull/9) · **Complexidade:** simples

### O que mudou

Badge vermelho (!) no card agora é clicável: abre um popover com as 4 seções do SBAR (Situation, Background, Assessment, Recommendation). Fecha o loop de valor do M2 — decisão processável em <60s sem sair do app.

### Detalhes técnicos

- `SBARDetailView`: ScrollView com 4 `SBARSection`; Recommendation destacada com fundo accent color
- `HypothesisCardView`: `pendingBrief: SBARBrief?` computed via `readArtifacts` + `parseSBAR`; badge vira `Button` com `.popover(arrowEdge: .bottom)`

### Impacto

- **Breaking:** Não

### Arquivos-chave

- `Sources/OneManSquadOS/Views/SBARDetailView.swift` — novo
- `Sources/OneManSquadOS/Views/HypothesisCardView.swift` — badge clicável

---

## [feat] FSEvents Watch — portfolio auto-recarrega ao detectar mudanças no filesystem — 2026-03-07

**Tipo:** feat
**Tags:** fsevents, portfolio, reactive, worktree
**Commit:** [7961883](https://github.com/rmolines/one-man-squad-os/commit/7961883) · **Complexidade:** simples

### O que mudou

PortfolioView agora atualiza automaticamente quando worktrees são criadas ou removidas — sem precisar de refresh manual. O watcher usa FSEvents nativo do macOS e dispara no máximo uma vez por segundo para coalescer bursts.

### Detalhes técnicos

- `RepoWatcher.swift`: wrapper `FSEventStreamRef` com latência 1 s, callback na main thread via `CFRunLoopGetMain`
- `PortfolioStore`: extrai `reload()` como método privado; watcher criado/reutilizado em `refresh(repoPath:)` somente quando o path muda

### Impacto

- **Breaking:** Não

### Arquivos-chave

- `Sources/OneManSquadOS/Stores/RepoWatcher.swift` — novo; wrapper FSEvents
- `Sources/OneManSquadOS/Stores/PortfolioStore.swift` — integração do watcher + extração de reload()

---

## [feat] SBAR Detection — card acende quando há Decision Brief pendente — 2026-03-08

**Tipo:** feat
**Tags:** sbar, hypothesis-cards, decision-brief, portfolio
**PR:** [#8](https://github.com/rmolines/one-man-squad-os/pull/8) · **Complexidade:** simples

### O que mudou

Cards de hipótese agora mostram um badge vermelho (!) quando a worktree tem um arquivo SBAR válido em `.claude/decisions/`. Sem briefs, sem badge — sem ruído.

### Detalhes técnicos

- `hasPendingBrief`: chama `readArtifacts()` + `parseSBAR()` — verdadeiro quando ≥1 arquivo em `.claude/decisions/*.md` tem as 4 seções SBAR
- `lastArtifactDate`: retorna `max(mtime)` dos arquivos de brief via `FileManager`
- `PendingBriefBadge`: ícone `exclamationmark.circle.fill` com tooltip "Pending decision brief"

### Impacto

- **Breaking:** Não

### Arquivos-chave

- `Sources/Core/Models/HypothesisModel.swift` — `hasPendingBrief` + `lastArtifactDate`
- `Sources/OneManSquadOS/Views/HypothesisCardView.swift` — `PendingBriefBadge`

---

## [feat] Portfolio View — worktrees exibidos como hypothesis cards — 2026-03-08

**Tipo:** feat
**Tags:** swiftui, portfolio, worktrees, hypothesis-cards
**PR:** [#7](https://github.com/rmolines/one-man-squad-os/pull/7) · **Complexidade:** média

### O que mudou

Abrir a janela Portfolio agora exibe as worktrees git como cards de hipótese. Primeira abertura mostra onboarding com folder picker; path persiste entre sessões via SwiftData.

### Detalhes técnicos

- `WorktreeInfo: HypothesisCard` conformance adicionada via extensão no Core
- `PortfolioStore` expandido: `hypotheses: [WorktreeInfo]`, `loadError`, `refresh(repoPath:)` síncrono
- `HypothesisCardView` criado: branch title, path caption, status chip colorido (`.idle` para todos em V1)
- `PortfolioView` refatorada: onboarding → `NSOpenPanel` → `LazyVGrid`; toolbar com Refresh + Change Folder
- `rootRepoPath` persiste via `CockpitSettings` SwiftData (campo já existia em V1 — sem migration)

### Impacto

- **Breaking:** Não
- Status sempre `idle` em V1 — FSEvents e git status parsing são M2

### Arquivos-chave

- `Sources/Core/Models/HypothesisModel.swift` — extensão `WorktreeInfo: HypothesisCard`
- `Sources/OneManSquadOS/Stores/PortfolioStore.swift` — implementação real
- `Sources/OneManSquadOS/Views/PortfolioView.swift` — refatorada
- `Sources/OneManSquadOS/Views/HypothesisCardView.swift` — novo

---

## [feat] App Foundation — SwiftUI skeleton + SwiftData schema V1 — 2026-03-07

**Tipo:** feat
**Tags:** swiftui, swiftdata, menubar, foundation
**PR:** [#6](https://github.com/rmolines/one-man-squad-os/pull/6) · **Complexidade:** média

### O que mudou

App macOS agora existe: ícone na menu bar, janela portfolio placeholder, e schema SwiftData V1
com VersionedSchema pronto para evoluir sem migrations manuais.

### Detalhes técnicos

- `CockpitApp`: `@main` com `MenuBarExtra(.window)` + `WindowGroup("portfolio")` e `AppDelegate` para `activationPolicy`
- `CockpitSchemaV1`: VersionedSchema com `BacklogHypothesis` e `CockpitSettings` `@Model`
- `CockpitSchema.container`: `ModelContainer` com `CockpitSchemaMigrationPlan` (sem stages, V1 inicial)
- `PortfolioStore`: `@Observable @MainActor` placeholder — implementação real em portfolio-view
- `project.yml`: removido `EonilFSEvents` (repo gone; FSEvents é M2)

### Impacto

- **Breaking:** Não

### Arquivos-chave

- `Sources/OneManSquadOS/App/CockpitApp.swift` — entry point, scenes
- `Sources/OneManSquadOS/Models/CockpitSchema.swift` — VersionedSchema V1 + container
- `project.yml` — removido EonilFSEvents

---
