# Changelog

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
