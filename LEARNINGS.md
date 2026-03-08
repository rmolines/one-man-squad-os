# LEARNINGS.md — Technical learnings

Gotchas, limitations, and non-obvious behaviors discovered while working on this project.

---

## 2026-03-08 — SwiftUI spin animation: dois drivers concorrentes causam jump visível

`withAnimation(.linear.repeatForever) { rotation += 360 }` no button action +
`.animation(.linear.repeatForever, value: isLoading)` no modifier criam dois drivers
independentes na mesma propriedade. SwiftUI resolve para o segundo quando `isLoading` muda,
abandonando o primeiro mid-frame com um jump visível.

Padrão correto: um único `@State private var isSpinning: Bool`, um único `.animation` modifier,
e `.onChange(of: store.isLoading) { isSpinning = $0 }` para sincronizar. Sem `withAnimation` imperativo.

## 2026-03-08 — Double sort destroça ordering do FeaturePlanScanner

`listFeaturePlans` já retorna ordenado por `statusOrder` (pendingDecision → building → ... → killed)
com `lastArtifactDate` como tiebreaker. Aplicar `.sorted { by: lastArtifactDate }` no `PortfolioStore.reload()`
depois destrói a ordering de status priority — um item `killed` modificado hoje aparece antes de um
`pendingDecision` modificado ontem. Regra: não re-sortear o resultado de `listFeaturePlans`.

## 2026-03-08 — SwiftData: dois VersionedSchema apontando para o mesmo tipo causam fatalError

`CockpitSchemaV1` e `CockpitSchemaV2` com `models: [BacklogHypothesis.self, ...]` (mesmo tipo)
causam `fatalError: "The current model reference and the next model reference cannot be equal"` em runtime.
SwiftData não consegue diferenciar V1 de V2 se a referência de tipo for idêntica.

Para migration real: a classe V1 precisa ser aninhada como tipo separado dentro do enum do schema
(ex: `CockpitSchemaV1.BacklogHypothesis` com as propriedades antigas). Para dados descartáveis
(não usados na UI), o caminho pragmático é renomear o store (`ModelConfiguration("CockpitStoreV2", ...)`).

## 2026-03-08 — FeaturePlanInfo: computed properties com disk I/O causam hot path O(N log N)

Computed properties em structs Swift não têm cache. Se `status` e `lastArtifactDate` chamam
`FileManager` internamente e o sort de `listFeaturePlans` acessa essas propriedades por comparação,
o resultado é O(N log N) × número de arquivos lidos por chamada — tudo no main thread.

Fix: eager-load `ArtifactSet` e `lastArtifactDate` na construção da struct e armazenar como
`let` stored properties. Computed properties derivam de valores já em memória.

---

## 2026-03-08 — SwiftUI `.frame()` tem dois overloads mutuamente exclusivos

`.frame()` em SwiftUI tem exatamente dois overloads: `(width:height:alignment:)` e
`(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:alignment:)`.
Não há forma mista — `frame(width: 380, minHeight: 200)` não compila ("Extra argument 'width' in call").
Use o overload completo quando precisar de dimensões mínimas/máximas:

```swift
.frame(minWidth: 380, maxWidth: 380, minHeight: 200, maxHeight: 560)
```

---

## 2026-03-08 — xcodegen modifica Package.resolved e bloqueia rebase

`xcodegen generate` atualiza `Package.resolved` como side effect. Se rodado antes do `/ship-feature`,
o rebase falha com "You have unstaged changes". Fix: `git stash` antes do rebase, `git stash pop` depois.
Alternativa: commitar o `Package.resolved` modificado antes de fazer rebase.

---

## GitHub Actions

### `bootstrap.yml`: `run_number == 1` guard

`github.run_number` starts at 1 for the first run of any workflow in a repo. Using this as a
guard ensures branch protection is only applied once. **Do not re-run this workflow manually** —
it will attempt to apply protection again (which is usually fine but clutters logs).

### `template-sync.yml`: must guard with `!is_template`

Without the `!github.event.repository.is_template` guard, the sync workflow would run on the
template repo itself and open PRs against its own `main`. The guard makes it a no-op on the
template and active only on forks.

### Action SHA pinning

Always pin to full commit SHA, not tag:
```yaml
# Good
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
# Bad (tag can be hijacked)
uses: actions/checkout@v4
```

---

## Claude Code hooks (CVE-2025-59536)

Hooks in `.claude/settings.json` execute shell commands **without user confirmation**.
This was documented in CVE-2025-59536. Mitigation: keep hook logic in external scripts
(`.claude/hooks/`) so they're visible, auditable, and can be reviewed in PRs.

---

## SwiftUI macOS — MenuBarExtra + activationPolicy

### Dock icon briefly appears on launch — expected behavior

With `LSUIElement = false` in Info.plist, the app shows a Dock icon on launch.
When `applicationDidFinishLaunching` calls `NSApp.setActivationPolicy(.accessory)`,
the icon disappears. This is correct — it looks like a crash but it is not.
The menu bar icon appears in the top-right corner after the Dock icon vanishes.

If the menu bar is full, the icon may be hidden behind the `>>` overflow indicator.

### EonilFSEvents (`eonil/FSEvents`) is no longer available on GitHub

As of 2026-03, `https://github.com/eonil/FSEvents` returns "Repository not found".
Removed from `project.yml` — FSEvents watch is M2 scope. Find an alternative before M2.
Candidates: `eonil/FileSystemEvents`, or roll a thin `FSEvents` C wrapper directly.

### xcodegen + worktrees: always regenerate xcodeproj in the worktree

The committed `OneManSquadOS.xcodeproj` may have absolute paths from the original machine.
After creating a worktree, run `xcodegen generate` inside it before opening in Xcode.

### EnterWorktree creates branch as `worktree-<name>`, not `feat/<name>`

`EnterWorktree name=<nome>` creates a branch named `worktree-<nome>`, not `feat/<nome>`.
After entering the worktree, rename immediately to follow the project convention:

```bash
git branch -m worktree-<nome> feat/<nome>
```

Otherwise the PR title and remote branch will use the wrong prefix.

---

## SwiftData + SwiftUI — @Query patterns

### Lazy insert for optional singleton records

When a view uses `@Query` to fetch a settings record that may not exist yet (e.g., `CockpitSettings`),
use a computed property with lazy insert to avoid crashes:

```swift
@Query private var settingsList: [CockpitSettings]
@Environment(\.modelContext) private var modelContext

private var settings: CockpitSettings {
    if let existing = settingsList.first { return existing }
    let fresh = CockpitSettings()
    modelContext.insert(fresh)
    return fresh
}
```

This avoids force-unwrapping `settingsList.first!` and eliminates a crash on first launch.
The inserted record persists automatically via SwiftData's auto-save.

---

## markdownlint

- Use `npx --yes markdownlint-cli2` to avoid requiring global install
- `MD013` (line length) needs `tables: false` and `code_blocks: false` to avoid false positives
- `MD024` (duplicate headings) should be disabled for `HANDOVER.md` — entries often have similar structure
- `MD041` (first heading must be h1) breaks templates with frontmatter or `<!-- TODO -->` comments
