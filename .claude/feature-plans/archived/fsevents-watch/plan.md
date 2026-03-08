# Plan: fsevents-watch

## Problema
PortfolioView requer refresh manual para detectar worktrees criadas/removidas.
A infra reativa deve observar o repo root via FSEvents e acionar PortfolioStore.reload()
automaticamente quando o filesystem muda.

## Assunções
- [verified][blocking] FSEvents.framework disponível no Xcode app target sem deps SPM adicionais
- [verified][background] Callbacks agendados em CFRunLoopGetMain() chegam na main thread
- [assumed][background] App target não tem strict concurrency mode habilitado (Package.swift usa v6 mas só para Core SPM target)

## Deliverables

### Deliverable 1 — RepoWatcher + PortfolioStore reativo
**O que faz:** Cria RepoWatcher (wrapper FSEvents) e integra ao PortfolioStore
**Critério de done:** `swift build` verde; watcher instanciado ao chamar refresh() com path não-vazio
**Valida:** assunção de que FSEvents.framework não requer deps extras

## Arquivos a modificar
- `Sources/OneManSquadOS/Stores/RepoWatcher.swift` — criar (novo)
- `Sources/OneManSquadOS/Stores/PortfolioStore.swift` — adicionar watcher + reload()

## Passos de execução
1. Criar RepoWatcher.swift com wrapper FSEvents
2. Modificar PortfolioStore: adicionar watcher/watchedPath, extrair reload(), iniciar watcher em refresh()

## Checklist de infraestrutura
- [ ] Novo Secret: não
- [ ] Script de setup: não
- [ ] CI/CD: não muda
- [ ] Config principal: não muda
- [ ] Novas dependências: não (FSEvents.framework é sistema)

## Rollback
`git revert HEAD` ou deletar RepoWatcher.swift e restaurar PortfolioStore.swift via `git checkout`
