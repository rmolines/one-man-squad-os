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

## Feature workflow — complete cycle

Use the skills below for any non-trivial feature (>2-3 files or with architectural decisions):

1. `/start-milestone` — decompose milestone from roadmap.md into scoped features → generates `sprint.md`
2. `/start-feature` — intake + research (Phase A) → `/clear` → planning (Phase B) → `/clear` → worktree + execution (Phase C)
3. Build and iterate in the worktree
4. `/validate` — direction check: verify implementation still solves the original problem
5. `/ship-feature` — commit + rebase + PR + CI + smoke test
6. `/close-feature` — documentation (HANDOVER, MEMORY, LEARNINGS, CLAUDE.md) + cleanup

**Orientation (any time):** `/project-compass` — "where are we?", "what's left?", "next feature?"

## Hot files — always read before editing

- `Sources/Core/HypothesisModel.swift` — enums de status, protocolo HypothesisCard
- `Sources/OneManSquadOS/Stores/PortfolioStore.swift` — @Observable @MainActor; ponto central de estado
- `Sources/OneManSquadOS/App/CockpitApp.swift` — configuração de scenes, activationPolicy pattern
- `Sources/OneManSquadOS/Models/BacklogHypothesis.swift` — SwiftData @Model; schema V1
- `Package.swift` — targets e dependências SPM
- `CLAUDE.md`
- `.github/workflows/ci.yml`
- `.github/workflows/release.yml`

## Known pitfalls

| Component | Pitfall | Fix |
|---|---|---|
| `MenuBarExtra` + `WindowGroup` + `activationPolicy` | Ao alternar janela principal / menu bar | Gerenciar `NSApp.setActivationPolicy` manualmente; ver CockpitApp.swift |
| `openSettings` dentro de MenuBarExtra | Qualquer SettingsLink no menu | Usar `orchetect/SettingsAccess`; não chamar `openSettings` direto |
| SwiftData sem VersionedSchema | Adicionar campo novo a @Model | SEMPRE via CockpitSchemaV2 com migration stage; nunca editar V1 direto |
| FSEvents fora do container | Watch de paths fora do ~/Documents | App não-sandboxed; sem Security-Scoped Bookmarks; `NSOpenPanel` + `UserDefaults` |
| Subprocess git com string concatenada | Qualquer chamada a git | SEMPRE array de argumentos; NUNCA interpolar path em string de comando |
| Path traversal em writes `.claude/decisions/` | Ao gravar decisão | Validar que path final tem como prefixo o worktree aprovado pelo usuário |
| PTY/HITL scope creep | "Só adiciona um botão pra..." | Regra explícita: PTY/socket IPC é backlog v2; feature request → issue, não código |
| swift-markdown sem frontmatter | SBAR files com `--- ... ---` no topo | Dois estágios: strip frontmatter com SwiftToolkit/frontmatter, depois swift-markdown |
| template-sync.yml | Runs on template repo itself → no-op | Guard: `!github.event.repository.is_template` |
| bootstrap.yml | Only fires on first push (run_number == 1) | Don't re-run manually |
| `EonilFSEvents` (`eonil/FSEvents`) | Repo removido do GitHub — `xcodebuild -resolvePackageDependencies` falha com "Repository not found" | Removido de `project.yml`; FSEvents é M2 — encontrar alternativa antes de M2 (`eonil/FileSystemEvents` é candidato) |
| `xcodegen` + worktrees | xcodeproj commitado tem package cache paths da máquina original — Xcode abre com "Missing package product" | Rodar `xcodegen generate` dentro da worktree antes de abrir no Xcode |
| `xcodegen generate` antes do rebase | `xcodegen` atualiza `Package.resolved` como side effect — rebase falha com "unstaged changes" | `git stash` antes do rebase, `git stash pop` depois; ou commitar `Package.resolved` antes de rebaser |
| activationPolicy `.accessory` parece crash | Dock icon desaparece quando `applicationDidFinishLaunching` chama `setActivationPolicy(.accessory)` — parece crash silencioso | É comportamento esperado — o ícone migra para a menu bar; verificar canto superior direito (pode estar atrás de `>>`) |
| SwiftUI `.frame()` — overloads exclusivos | `frame(width: 380, minHeight: 200)` → "Extra argument 'width' in call" — não há overload misto | Usar o overload completo: `.frame(minWidth: 380, maxWidth: 380, minHeight: 200, maxHeight: 560)` |

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
