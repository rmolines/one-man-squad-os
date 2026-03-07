# /polish

Você é um assistente de desenvolvimento executando o skill `/polish`.

Este skill é uma "sessão de polish": abre uma branch única, itera por uma lista de pequenas
melhorias (bugs conhecidos, UX tweaks, refactors) fazendo um micro-commit por item, e abre
um único PR ao final com todos os commits preservados.

Use quando você tem N itens de baixo risco que já sabe como resolver — sem overhead de
feature completa por item, sem perder rastreabilidade por commit.

---

## Deteccao de flag

Se `$ARGUMENTS` comeca com `--close`:

```bash
BRANCH=$(git branch --show-current)
if [[ "$BRANCH" != chore/polish-* ]]; then
  echo "Branch atual nao e de polish: $BRANCH"
  exit 1
fi
REPO_ROOT=$(git worktree list | head -1 | awk '{print $1}')
if [ -z "$REPO_ROOT" ] || [ ! -d "$REPO_ROOT" ]; then
  echo "ERRO: nao foi possivel determinar REPO_ROOT. Abortando."
  exit 1
fi
```

**Fluxo `--close`:**

**Passo A** — Atualizar `backlog.json`: `status: "merged"` para o registro cujo `branch` bate com o atual:

```bash
BACKLOG="$REPO_ROOT/.claude/backlog.json"
if [ -f "$BACKLOG" ] && command -v jq >/dev/null; then
  jq --arg branch "$BRANCH" \
     '.chores |= map(if .branch == $branch then . + {status: "merged"} else . end)' \
     "$BACKLOG" > "$BACKLOG.tmp" && mv "$BACKLOG.tmp" "$BACKLOG"
fi
```

**Passo B** — Deletar branch local: `git branch -D "$BRANCH"`

**Passo C** — Deletar branch remota via `gh`:

```bash
REMOTE_URL=$(git remote get-url origin)
OWNER=$(echo "$REMOTE_URL" | sed -E 's|.*[:/]([^/]+)/[^/]+\.git|\1|')
REPO=$(echo "$REMOTE_URL" | sed -E 's|.*[:/][^/]+/([^/]+)(\.git)?$|\1|')
gh api -X DELETE "repos/$OWNER/$REPO/git/refs/heads/$BRANCH"
```

**Passo D** — Confirmar:

```text
Sessao de polish fechada.
Branch $BRANCH removida (local + remota).
backlog.json atualizado: status = merged.
```

**Encerrar aqui — nao continuar para o fluxo normal.**

Se `$ARGUMENTS` nao comeca com `--close`: prosseguir para o Passo 1 normalmente.

---

## Quando usar vs. alternativas

| Situação | Skill certa |
|---|---|
| N itens pequenos e conhecidos, baixo risco | `/polish` |
| Bug com causa raiz incerta | `/fix --investigate` |
| Feature nova com escopo não definido | `/start-feature --discover` |
| Um bug isolado com causa conhecida | `/fix --fast` |

---

## Passo 1 — Coletar a lista de tarefas

Se o usuário passou tarefas como argumento (`$ARGUMENTS`): usar como lista inicial.

Se não passou: perguntar:

```text
Quais itens estão na sessão de polish?
Liste em qualquer formato — vou estruturar a checklist.
(Um por linha, ou separados por vírgula)
```

Aguardar e estruturar em numeração:

```text
Checklist desta sessão:
1. <tarefa 1>
2. <tarefa 2>
3. <tarefa N>

Confirma? (pode adicionar, remover ou reordenar antes de começar)
```

Aguardar confirmação final antes de criar a branch.

---

## Passo 2 — Criar ou retomar a branch de polish

Verificar se já existe uma branch de polish ativa:

```bash
git branch --list "chore/polish-*"
```

**Se não existe:** criar nova branch:

```bash
DATE=$(date +%Y-%m-%d)
git checkout -b "chore/polish-$DATE"
```

**Se existe uma branch `chore/polish-<data>`:** perguntar:

```text
Encontrei uma branch de polish existente: chore/polish-<data>
Retomar ela ou criar nova sessão de hoje?
1. Retomar — continuar de onde parou
2. Nova — criar chore/polish-<hoje>
```

Aguardar escolha antes de prosseguir.

---

## Passo 3 — Loop de execução por tarefa

Para cada item da checklist (na ordem):

### 3a — Anunciar a tarefa

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Item <N>/<Total>: <descrição da tarefa>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 3b — Implementar

Regras de execução:

- Ler o estado atual de cada arquivo antes de editar — nunca editar às cegas
- Aplicar a menor mudança possível que resolve o item
- Não refatorar código vizinho não relacionado
- Se durante a execução o item revelar complexidade inesperada: **parar e reportar**

```text
⚠️  Item <N> é mais complexo do que esperado.
<descrição do que foi encontrado>

Opções:
1. Simplificar escopo — resolver só o que é trivial agora
2. Pular — marcar para /fix separado depois
3. Continuar mesmo assim (pode demorar mais)
```

Aguardar orientação antes de continuar.

### 3c — Micro-commit

Após implementar o item:

```bash
git add -A
git commit -m "<type>(<scope>): <descrição do item>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

Onde `<type>` é: `fix`, `chore`, `refactor`, `style`, `docs` — escolher o mais preciso.

Confirmar:

```text
✅ Item <N>/<Total> concluído — commit criado.
```

### 3d — Próximo item

Continuar automaticamente para o item seguinte sem parar.

---

## Passo 4 — Resumo da sessão

Após todos os itens:

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Sessão de polish concluída
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Itens concluídos (<N>/<Total>):
✅ 1. <tarefa 1>
✅ 2. <tarefa 2>
⏭️  3. <tarefa pulada — razão>

Branch: chore/polish-<data>
Commits: <N> micro-commits criados

Próximo passo: /ship-polish para abrir o PR
```

Se algum item foi pulado: listar separadamente com razão.

---

## Passo 5 — Build + testes

Extrair o comando de build do `CLAUDE.md` do projeto (campo `Comando de build`).

Rodar em background (`run_in_background=true`):

```bash
swift build
```

Rodar também em background:

```bash
swift test --filter CoreTests
```

Enquanto aguarda: exibir resumo de arquivos modificados.

- ✅: prosseguir para Passo 5b
- ❌: exibir erro completo, corrigir, repetir — nao avançar com build quebrado

### Passo 5b — Checklist de testes manuais (UI)

Se algum item da sessao tocou arquivos de view ou mencionou mudancas de interface:

Usar ferramenta de preview do projeto (ex: `RenderPreview` do Xcode MCP, Storybook, etc.) para
cada view modificada:

- Se preview disponivel: renderizar e confirmar layout antes de abrir PR
- Se nao disponivel: exibir aviso e listar checklist manual:

```text
[Preview nao disponivel] Confirmar manualmente antes de abrir PR:
- [ ] <view modificada> — aparencia correta
- [ ] Dark mode / tema alternativo sem quebras de layout
```

Aguardar confirmacao do usuario antes de prosseguir para o Passo 6.

---

## Passo 6 — Abrir PR

Push e criação de PR:

```bash
git push -u origin <branch-atual>
```

Usar `mcp__plugin_github_github__create_pull_request` com:

- `owner`: dono do repo (extrair de `git remote get-url origin`)
- `repo`: nome do repo
- `title`: `chore(polish): <data> — <N> melhorias`
- `head`: branch atual
- `base`: `"main"`
- `body`: template abaixo

Template para `body`:

```text
## Sessão de polish — <data>

### Itens resolvidos
- <item 1>
- <item 2>
- <item N>

### Itens pulados (se houver)
- <item> — <razão>

### Como revisar
Cada commit corresponde a um item da lista — use "Commits" no PR para revisar item a item.

### Merge
Usar **merge commit** (não squash) para preservar os micro-commits individuais no histórico.
```

Exibir URL do PR ao criar.

**Importante:** Ao mergear, usar `mergeMethod: "merge"` (não `"squash"`) para preservar
os micro-commits individuais no histórico do main.

### Passo 6b — Registrar no backlog.json

Apos criar o PR, capturar `number` e `html_url` do response de `create_pull_request`.

```bash
REPO_ROOT=$(git worktree list | head -1 | awk '{print $1}')
BACKLOG="$REPO_ROOT/.claude/backlog.json"
DATE=$(date +%Y-%m-%d)
BRANCH=$(git branch --show-current)
# PR_NUMBER e PR_URL: capturar do response do MCP create_pull_request
# ITEMS_JSON e SKIPPED_JSON: arrays JSON construidos a partir dos itens do Passo 4
# Exemplo: ITEMS_JSON='["Fix X","Refactor Y"]'  SKIPPED_JSON='[]'
if [ -f "$BACKLOG" ] && command -v jq >/dev/null; then
  ENTRY=$(jq -n \
    --arg id      "polish-$DATE-$BRANCH" \
    --arg type    "polish" \
    --arg date    "$DATE" \
    --arg branch  "$BRANCH" \
    --argjson pr  "$PR_NUMBER" \
    --arg url     "$PR_URL" \
    --arg status  "open" \
    --argjson items   "$ITEMS_JSON" \
    --argjson skipped "$SKIPPED_JSON" \
    '{id:$id, type:$type, date:$date, branch:$branch, prNumber:$pr, prUrl:$url,
      status:$status, items:$items, skipped:$skipped}')
  jq --argjson entry "$ENTRY" \
     '. + {chores: ((.chores // []) + [$entry])}' \
     "$BACKLOG" > "$BACKLOG.tmp" && mv "$BACKLOG.tmp" "$BACKLOG"
fi
```

`(.chores // [])` e null-safe — funciona mesmo antes da key existir no backlog.
Se `jq` nao estiver disponivel, pular silenciosamente (nao bloquear o fluxo).

---

## Regras gerais

- Nunca editar arquivos sem lê-los primeiro
- Micro-commit após cada item — nunca acumular múltiplos itens num commit só
- Se um item revelar complexidade inesperada: parar e reportar (ver 3b)
- **Loop de execução (Passo 3) é autônomo** — não parar entre itens pedindo confirmação
- **Build deve estar verde antes de abrir PR** — nunca abrir com build quebrado
- PR usa `mergeMethod: "merge"` — squash destrói a rastreabilidade por item que é o valor desta skill
- Itens pulados não são perdidos — listar no resumo e no corpo do PR para acompanhamento
