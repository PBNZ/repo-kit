# Testing matrix

What to test, per repo type. (Core / private repos: tests are optional but encouraged — at
minimum, whatever proves the code runs.)

| Type | Test / check |
|------|--------------|
| `powershell-module` | `Test-ModuleManifest` parses the `.psd1`; **Pester** for behaviour; **PSScriptAnalyzer** (`Invoke-ScriptAnalyzer -Recurse`, fail on `Error` severity). CI runs on `ubuntu-latest` with `shell: pwsh`. |
| `docker-compose` | `docker compose config -q` validates the compose file. CI runs it on `ubuntu-latest` (Public tier). |
| `power-platform-connectors` | `docker build` then `node scripts/generate.mjs` in the pinned image: every generated `connectors/*.swagger.json` must be **valid Swagger 2.0** (self-validated via `swagger-cli`) and **< 1 MB** — the generator exits non-zero otherwise. CI runs it on `ubuntu-latest` (Public tier). |
| `skill-plugin` | TBD when the overlay is built — validate `plugin.json` / `marketplace.json` / `SKILL.md` frontmatter (reuse `scripts/validate_*.py`) and scan SKILL bodies for safety. |
| `collection` | TBD when the overlay is built. |
| `mcp-server` | TBD when the overlay is built. |
| `app-ts` / `app-python` | TBD when the overlay is built — the language's standard test runner. |
| `script-collection` | TBD when the overlay is built — at minimum a smoke run of each script. |

When you fill in a stub type overlay, add its row here and ship a CI workflow in the type's
`public/` overlay.

Regardless of type: a repo with the **living-docs add-on** additionally runs
`pwsh scripts/check-docs.ps1` locally (pre-commit) and in CI via its `docs.yml` workflow — this
ships at the Core tier, because doc-consistency enforcement is the add-on's whole point even in a
private repo (see `living-docs.md`).
