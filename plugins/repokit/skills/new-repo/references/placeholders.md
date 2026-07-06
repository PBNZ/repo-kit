# Placeholders and the post-scaffold self-check

## Placeholders

**Interview placeholders** (from the user, with defaults):

| Token | Meaning |
|-------|---------|
| `{{name}}` | repo / directory name (kebab-case) |
| `{{description}}` | one-line description |
| `{{author}}` | author name (default `Peter Braun`) |
| `{{license}}` | SPDX licence id (default `Apache-2.0`) |
| `{{type}}` | the chosen repo type |
| `{{tier}}` | resolved tier label (`Core`, `Core + Public`, or `Core + Public + Published`) |
| `{{ModuleName}}` | **powershell-module only** — PascalCase module name (e.g. `MyModule`) |

**Computed placeholders** (you derive these — they must never be left literal in a template):

| Token | How to compute |
|-------|----------------|
| `{{year}}` | the current year |
| `{{Guid}}` | a **fresh** GUID per repo — use whatever the host offers: `uuidgen` (Linux/macOS), `[guid]::NewGuid()` (pwsh), or `python3 -c "import uuid; print(uuid.uuid4())"`. Never reuse a literal GUID; a hardcoded one would collide across every scaffolded module. |
| `{{START_HERE_MAP}}` | the where-things-live table you build in step 4 from the resolved file set |

## Post-scaffold self-check

Run both checks against the **new repo directory**. Both must pass before you print the success
summary.

### 1. No leftover placeholders — enumerated tokens only

Do **not** grep for a bare `{{` — GitHub Actions expressions like `${{ secrets.FOO }}` in the
workflow templates are legitimate and must not be flagged. Grep only for the known tokens:

```
rg -n '\{\{(name|description|author|year|license|type|tier|ModuleName|Guid|START_HERE_MAP)\}\}' <new-repo-dir>
```

Any hit is a failure — report the file and line, fix the substitution, and re-run.

### 2. Expected file set exists

Recompute the resolved target paths (post-substitution) and assert each one exists, and that **no
`.tmpl` suffix survived** anywhere in the tree. A missing file means a template was skipped; a
surviving `.tmpl` means a filename placeholder wasn't substituted.

### Limits

These checks catch *missing* / *empty* substitutions and skipped files. They do **not** catch a
*wrong-but-present* value (right token, wrong content) or a mangled verbatim copy. So phrase the
success summary honestly — the checks confirm completeness, not correctness; the human's review is
still the final gate.
