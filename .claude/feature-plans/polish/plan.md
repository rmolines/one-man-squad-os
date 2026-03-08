# Plan: polish

## Problema
Cards mostram o slug bruto ("cockpit-model"), sem hover feedback, sem animação de refresh, sem ⌘R, e as hipóteses aparecem sem ordem definida. UX rough para uso diário.

## Deliverables

### Deliverable 1 — Visual polish rápido
**O que faz:** Humanizar título, hover em cards, sort por data, ⌘R

**Arquivos:** `HypothesisCardView.swift`, `PortfolioView.swift`, `PortfolioStore.swift`

**Critério de done:** Títulos mostram "Cockpit Model" (não "cockpit-model"), card escurece ao hover, ⌘R dispara refresh, cards ordenados por `lastArtifactDate` desc.

### Deliverable 2 — Animações
**O que faz:** Botão de refresh gira durante loading; cards aparecem com transição suave

**Arquivos:** `PortfolioView.swift`, `HypothesisCardView.swift`

**Critério de done:** Ícone de refresh roda enquanto `isLoading = true`; cards entram com `.opacity + .scale` ao carregar lista.

## Passos de execução
1. `PortfolioStore.swift` — sort `hypotheses` por `lastArtifactDate` desc (nil por último) em `reload()`
2. `HypothesisCardView.swift` — humanizar título (kebab-case → Title Case); adicionar `@State private var isHovered` + `.onHover` + background animado
3. `PortfolioView.swift` — adicionar `.keyboardShortcut("r", modifiers: .command)` no botão refresh + `.rotationEffect` animado no ícone durante loading
4. `PortfolioView.swift` — adicionar `.animation(.easeOut(duration: 0.2), value:)` no grid + `.transition(.opacity.combined(with: .scale(scale: 0.95)))` em cada card

## Checklist de infraestrutura
- Novo Secret: não
- Script de setup: não
- CI/CD: não muda
- Novas dependências: não

## Rollback
`git revert HEAD` — todas as mudanças são aditivas e reversíveis.
