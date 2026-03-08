# Plan: agent-tasks-view

## Problema
O founder não consegue ver o progresso de execução de uma feature sem abrir o plan.md.
As tasks `- [ ]` / `- [x]` do plan.md são invisíveis no portfolio grid.

## Assunções
- [verified][blocking] `ArtifactSet.planMd` já está eager-loaded em `FeaturePlanInfo`
- [verified][background] `parseMarkdown()` em Core trata `- [ ]` como bulletItem — precisamos parser separado
- [assumed][background] Cards no grid têm espaço suficiente para 2-3 tasks inline sem quebrar o layout

## Deliverables

### Deliverable 1 — parseTaskItems() + TaskItem no Core
**O que faz:** Função `parseTaskItems(_ raw: String) -> [TaskItem]` em `MarkdownRenderer.swift` extrai linhas `- [x]` / `- [ ]` do plan.md
**Critério de done:** `parseTaskItems` retorna lista correta para um plan.md com checkboxes

### Deliverable 2 — Task list inline no HypothesisCardView
**O que faz:** Seção de tasks abaixo do status chip no card: até 3 items + contador "X/Y done"
**Critério de done:** Cards com plan.md mostram tasks; cards sem plan.md não mudam

## Arquivos a modificar
- `Sources/Core/MarkdownRenderer.swift` — adicionar `TaskItem` struct + `parseTaskItems()`
- `Sources/OneManSquadOS/Views/HypothesisCardView.swift` — adicionar `TaskSummaryView` inline

## Passos de execução
1. `MarkdownRenderer.swift` — adicionar `TaskItem: Sendable, Identifiable` + `parseTaskItems()`
2. `HypothesisCardView.swift` — computed var `tasks` + `TaskSummaryView` subview inline no card
3. Build (`swift build`) — verificar zero erros

## Checklist de infraestrutura
- [ ] Novo Secret: não
- [ ] Script de setup: não
- [ ] CI/CD: não muda
- [ ] Novas dependências: não

## Rollback
`git worktree remove .claude/worktrees/agent-tasks-view && git branch -D worktree-agent-tasks-view`
