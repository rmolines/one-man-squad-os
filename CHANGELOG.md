# Changelog

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
