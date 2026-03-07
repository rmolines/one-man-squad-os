# Plan: app-foundation

## Problema
O app SwiftUI não existe — Sources/OneManSquadOS/ estava vazio.
O Xcode project (via xcodegen) já referenciava esse path e as deps
(EonilFSEvents, SettingsAccess, Core). Precisamos criar o esqueleto
compilável: SwiftData container com VersionedSchema V1, dois @Model,
PortfolioStore placeholder, scenes (MenuBarExtra + WindowGroup) e
AppDelegate para activationPolicy.

## Assunções
<!-- status: [assumed] = não verificada | [verified] = confirmada | [invalidated] = refutada -->
<!-- risco:   [blocking] = falsa bloqueia a implementação | [background] = emerge naturalmente -->
- [assumed][blocking] SwiftData @Model funciona sem @unchecked Sendable em Swift 6 com o macrocompiler do Xcode 16
- [assumed][background] MenuBarExtra(.window) permite @Environment(\.openWindow) nos filhos

## Deliverables

### Deliverable 1 — Walking Skeleton
**O que faz:** App compila e abre no Xcode. MenuBarExtra aparece,
clique abre popover placeholder. WindowGroup existe mas não é aberta.
SwiftData container inicializa sem crash.
**Critério de done:** `swift build` no Core passa; app target abre no Xcode Run.
**Valida:** assunção SwiftData + Swift 6, estrutura de diretórios correta

## Arquivos criados
- `Sources/OneManSquadOS/Resources/Info.plist` — existia, sem ajustes
- `Sources/OneManSquadOS/Models/BacklogHypothesis.swift` — @Model V1
- `Sources/OneManSquadOS/Models/CockpitSettings.swift` — @Model V1
- `Sources/OneManSquadOS/Models/CockpitSchema.swift` — VersionedSchema V1 + container
- `Sources/OneManSquadOS/Stores/PortfolioStore.swift` — placeholder @Observable
- `Sources/OneManSquadOS/App/AppDelegate.swift` — activationPolicy
- `Sources/OneManSquadOS/App/CockpitApp.swift` — @main, scenes
- `Sources/OneManSquadOS/Views/MenuBarView.swift` — placeholder popover
- `Sources/OneManSquadOS/Views/PortfolioView.swift` — placeholder janela

## Checklist de infraestrutura
- [ ] Novo Secret: não
- [ ] CI/CD: não muda
- [ ] Novas dependências: não (EonilFSEvents + SettingsAccess já em project.yml)
- [ ] SwiftData migration: VersionedSchema V1 — sem migration stage (V1 inicial)

## Rollback
`git checkout main -- Sources/OneManSquadOS/` ou deletar worktree e branch
