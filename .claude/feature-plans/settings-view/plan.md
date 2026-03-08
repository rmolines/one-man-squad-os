# Plan: settings-view

## Problema
Não há janela de Settings dedicada. As preferências (`rootRepoPath`) estão embutidas
em `PortfolioView`, sem acesso via ⌘,, menu bar ou botão de settings no toolbar.

## Assunções
- [verified][blocking] `SettingsAccess` (orchetect) já está em `project.yml` from: 2.0.0
- [verified][blocking] `CockpitSchema.container` pode ser reutilizado na Settings scene
- [verified] macOS 14+ — Settings scene e @Environment(\.openSettings) disponíveis

## Deliverables

### Deliverable 1 — SettingsView + Settings scene
**O que faz:** Cria janela de Settings acessível via ⌘,
**Critério de done:** ⌘, abre janela com tab "General" e campo rootRepoPath funcional
**Valida:** SettingsAccess integra corretamente; SwiftData singleton funciona em Settings scene

### Deliverable 2 — Acesso via menu bar e toolbar
**O que faz:** Botão "Settings…" no MenuBarView e gear no toolbar do PortfolioView
**Critério de done:** Todos os 3 pontos de acesso (⌘,, menu bar, toolbar) abrem a mesma janela

## Arquivos a modificar
- `Sources/OneManSquadOS/Views/SettingsView.swift` — criar (novo)
- `Sources/OneManSquadOS/App/CockpitApp.swift` — adicionar Settings scene
- `Sources/OneManSquadOS/Views/MenuBarView.swift` — botão "Settings…"
- `Sources/OneManSquadOS/Views/PortfolioView.swift` — substituir "Change Folder" por gear; mover pickFolder

## Passos de execução
1. Criar SettingsView.swift com GeneralSettingsTab (TabView + Form + pickFolder)
2. Adicionar Settings scene em CockpitApp.swift com .openSettingsAccess() + .modelContainer
3. Adicionar botão "Settings…" em MenuBarView usando @Environment(\.openSettings)
4. Atualizar PortfolioView: substituir "Change Folder" por gear, onboarding → openSettings, remover pickFolder()

## Checklist de infraestrutura
- [ ] Novo Secret: não
- [ ] Script de setup: não
- [ ] CI/CD: não muda
- [ ] Config principal: não muda
- [ ] Novas dependências: não (SettingsAccess já está no projeto)

## Rollback
`git revert HEAD` após commit, ou `git checkout -- <arquivo>` por arquivo.
