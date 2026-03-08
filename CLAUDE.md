# CLAUDE.md — One Man Squad OS

## Visão geral

**One Man Squad OS** — cockpit para PM-fundador solo que usa Claude Code como squad de engenharia.

**WHY:** O gargalo do founder solo com AI não é capacidade de build — é atenção e julgamento humano.
Re-entry de contexto frio ao alternar entre hipóteses custa minutos. Nenhuma ferramenta foi
desenhada para essa nova escassez.

**WHAT:** Um leitor de filesystem que detecta worktrees git como hipóteses de produto, mostra
portfolio em um relance, e entrega cada decisão pendente como um Decision Brief estruturado (SBAR)
processável em <60 segundos.

**HOW:** macOS-native (SwiftUI + SwiftData + FSEvents). Local-first puro. Worktree = Hipótese (1:1).
V1 é leitor puro — sem PTY, sem lançar sessões, sem IPC.

**Regra de ouro (v1):** Se o código interage com PTY, spawna Claude Code, ou abre sockets IPC,
está no backlog — não no código agora.

## Critical rules — NEVER do without explicit approval

- Never commit tokens, keys, or passwords — use environment variables or secret managers
- Never force-push to main — always use PRs with CI passing
- Never skip pre-commit hooks (--no-verify) — fix the underlying issue
- Never delete data without a dry-run step first
- Never add PTY/socket IPC code in v1 — it is explicitly out of scope

## Skill priority — superpowers vs project skills

Project skills override superpowers skills when both could apply:

| Superpowers skill | Overridden by | Reason |
|---|---|---|
| `brainstorming` | `/start-feature --discover` (Phase A) | Project skill has full discovery + research cycle |
| `writing-plans` | `/start-feature` Phase B → `plan.md` | Project skill produces plan scoped to sprint + hot files |
| `using-git-worktrees` | Worktree convention below | Project has fixed naming convention |
| `finishing-a-development-branch` | `/ship-feature` + `/close-feature` | Project skills include CI, notarization, docs |

Superpowers skills that are **additive** (use freely, no conflict):

- `systematic-debugging` — before `/debug`, as the HOW methodology
- `test-driven-development` — during Phase C execution
- `verification-before-completion` — before any `/ship-feature`
- `requesting-code-review` / `receiving-code-review` — alongside PR workflow
- `subagent-driven-development` — for parallel tasks during Phase C
- `swiftui-expert-skill` — durante Fase C quando plan.md toca Views; durante ship-feature quando diff contém Views (substitui `swiftui-pro`)
- `swift-concurrency` — quando Fase C ou /fix envolve actor, async, Task, @MainActor

## Feature workflow — complete cycle

Use the skills below for any non-trivial feature (>2-3 files or with architectural decisions):

1. `/start-milestone` — decompose milestone from roadmap.md into scoped features → generates `sprint.md`
2. `/start-feature` — intake + research (Phase A) → `/clear` → planning (Phase B) → `/clear` → worktree + execution (Phase C)
3. Build and iterate in the worktree
4. `/ship-feature` — commit + rebase + PR + CI + smoke test
5. `/close-feature` — documentation (HANDOVER, MEMORY, LEARNINGS, CLAUDE.md) + cleanup

**Orientation (any time):** `/project-compass` — "where are we?", "what's left?", "next feature?"

## Hot files — always read before editing

- `Sources/Core/HypothesisModel.swift` — enums de status, protocolo HypothesisCard
- `Sources/OneManSquadOS/Stores/PortfolioStore.swift` — @Observable @MainActor; ponto central de estado
- `Sources/OneManSquadOS/App/CockpitApp.swift` — configuração de scenes, activationPolicy pattern
- `Sources/OneManSquadOS/Models/BacklogHypothesis.swift` — SwiftData @Model; schema V2 (slug identifier)
- `Sources/Core/FeaturePlanScanner.swift` — listFeaturePlans; source of truth para hipóteses
- `Package.swift` — targets e dependências SPM
- `CLAUDE.md`
- `.github/workflows/ci.yml`
- `.github/workflows/release.yml`

## Known pitfalls

| Component | Pitfall | Fix |
|---|---|---|
| `MenuBarExtra` + `WindowGroup` + `activationPolicy` | Ao alternar janela principal / menu bar | Gerenciar `NSApp.setActivationPolicy` manualmente; ver CockpitApp.swift |
| `openSettings` dentro de MenuBarExtra | Qualquer SettingsLink no menu | Usar `orchetect/SettingsAccess`; não chamar `openSettings` direto |
| SwiftData sem VersionedSchema | Adicionar campo novo a @Model | SEMPRE via CockpitSchemaV3 (próximo) com migration stage; nunca editar V2 direto |
| SwiftData `VersionedSchema` com tipo repetido | Dois schemas com `models: [MesmoTipo.self]` causam `fatalError: "current model reference == next model reference"` em runtime | Classe V1 deve ser aninhada como tipo separado dentro do enum `CockpitSchemaV1`; ou renomear o store se dados V1 não têm valor |
| `FeaturePlanInfo` computed properties com disk I/O | `status`/`hasPendingBrief` como computed → O(N log N) reads no sort, I/O por frame no render SwiftUI | Eager-load `ArtifactSet` na construção e armazenar como `let` stored property |
| FSEvents fora do container | Watch de paths fora do ~/Documents | App não-sandboxed; sem Security-Scoped Bookmarks; `NSOpenPanel` + `UserDefaults` |
| Subprocess git com string concatenada | Qualquer chamada a git | SEMPRE array de argumentos; NUNCA interpolar path em string de comando |
| Path traversal em writes `.claude/decisions/` | Ao gravar decisão | Validar que path final tem como prefixo o worktree aprovado pelo usuário |
| PTY/HITL scope creep | "Só adiciona um botão pra..." | Regra explícita: PTY/socket IPC é backlog v2; feature request → issue, não código |
| swift-markdown sem frontmatter | SBAR files com `--- ... ---` no topo | Dois estágios: strip frontmatter com SwiftToolkit/frontmatter, depois swift-markdown |
| template-sync.yml | Runs on template repo itself → no-op | Guard: `!github.event.repository.is_template` |
| bootstrap.yml | Only fires on first push (run_number == 1) | Don't re-run manually |
| `EonilFSEvents` (`eonil/FSEvents`) | Repo removido do GitHub — `xcodebuild -resolvePackageDependencies` falha com "Repository not found" | Removido de `project.yml`; FSEvents é M2 — encontrar alternativa antes de M2 (`eonil/FileSystemEvents` é candidato) |
| `xcodegen` + worktrees | xcodeproj commitado tem package cache paths da máquina original — Xcode abre com "Missing package product" | Rodar `xcodegen generate` dentro da worktree antes de abrir no Xcode |
| `MarkdownView` / new Swift files fora do Xcode | Arquivo criado via Write tool não aparece no target do Xcode — Preview falha com "Active scheme does not build this file" | Rodar `xcodegen generate` no repo root para regenerar o xcodeproj |
| `xcodegen generate` antes do rebase | `xcodegen` atualiza `Package.resolved` como side effect — rebase falha com "unstaged changes" | `git stash` antes do rebase, `git stash pop` depois; ou commitar `Package.resolved` antes de rebaser |
| activationPolicy `.accessory` parece crash | Dock icon desaparece quando `applicationDidFinishLaunching` chama `setActivationPolicy(.accessory)` — parece crash silencioso | É comportamento esperado — o ícone migra para a menu bar; verificar canto superior direito (pode estar atrás de `>>`) |
| SwiftUI `.frame()` — overloads exclusivos | `frame(width: 380, minHeight: 200)` → "Extra argument 'width' in call" — não há overload misto | Usar o overload completo: `.frame(minWidth: 380, maxWidth: 380, minHeight: 200, maxHeight: 560)` |
| Double sort em `PortfolioStore.reload()` | `listFeaturePlans` já retorna ordenado por `statusOrder` + `lastArtifactDate`; aplicar `.sorted` depois destrói a priority ordering | Não re-sortear o resultado de `listFeaturePlans` — confiar no sort do scanner |
| SwiftUI spin animation com dois drivers | `withAnimation(.repeatForever)` no button action + `.animation(.repeatForever, value:)` no modifier criam dois drivers concorrentes; SwiftUI abandona o primeiro mid-frame com jump visível | Usar um único `@State private var isSpinning: Bool` + único `.animation` modifier + `.onChange(of: isLoading)` para sincronizar |
| `@Observable` + `let` em `init` | Computed `let` em `init` lê `store.X` fora da janela de rastreamento do SwiftUI — view nunca re-renderiza quando `store.X` muda. Parece otimização válida ("evitar I/O em body") mas quebra reatividade. | Usar `var` computed property dentro do `body` ou como `private var` na view — acessos em `body` são rastreados; acessos em `init` não são. |
| `isMilestoneDir` — exclusão silenciosa de slugs `M\d+` | Qualquer feature-plan cujo slug coincida com o padrão `M\d+` (ex: `M10`, `M2-migration`) é silenciosamente excluída do portfolio grid e nunca aparece como hipótese — sem erro, sem log | Slugs de features devem usar nomes descritivos (kebab-case); nunca criar pasta `.claude/feature-plans/M<número>-...`; o filtro está em `isMilestoneDir()` em `FeaturePlanScanner.swift` |
| `parseFeatureSlugs` — coluna Slug hardcoded em índice 3 | O parser assume que a coluna Slug é a 3ª coluna de dados (índice 3 após split por `\|`); reordenar colunas no template do sprint.md resulta em lista de slugs vazia sem erro | Coluna order canônica: `\| # \| Feature \| Slug \| Deps \| Esforço \| Status \|`; não reordenar colunas no sprint.md |
| `Task.detached` dentro de `@MainActor` class sem re-hop explícito | `reload()` cria `Task { }` que escreve em `self.hypotheses` e `self.milestones` — propriedades `@MainActor` — de dentro de um closure que não está marcado como `@MainActor`; passa hoje em Swift 5.x mas `-strict-concurrency=complete` (Swift 6) flageia como data race | Anotar o closure interno: `Task { @MainActor in self.hypotheses = await plans; ... }` |

## Worktree convention

- Path: `.claude/worktrees/<feature-name>`
- Branch: `feat/<feature-name>` (kebab-case)
- Always rebase before starting: `git fetch origin && git rebase origin/main`

## Daily commands

```bash
swift build          # Build Core + App
swift test           # Run CoreTests
make help            # List all available commands
make check           # Run lint + validate
```

## Secrets

Para desenvolvimento local: não há variáveis de ambiente — app é local-only.

Para release (CI notarization):

- `APPLE_DEVELOPER_CERT_BASE64` — certificado Developer ID Application em base64
- `APPLE_DEVELOPER_CERT_PASSWORD` — senha do .p12
- `APPLE_TEAM_ID` — Team ID da Apple Developer account
- `APPLE_NOTARIZE_APPLE_ID` — Apple ID para notarytool
- `APPLE_NOTARIZE_APP_PASSWORD` — App-specific password para notarytool
- `KEYCHAIN_PASSWORD` — senha temporária do keychain no CI
