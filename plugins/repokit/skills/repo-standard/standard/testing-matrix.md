# Testing matrix

What to test, per repo type. (Core / private repos: tests are optional but encouraged — at
minimum, whatever proves the code runs.)

| Type | Test / check |
|------|--------------|
| `powershell-module` | `Test-ModuleManifest` parses the `.psd1`; **Pester** for behaviour; **PSScriptAnalyzer** (`Invoke-ScriptAnalyzer -Recurse`, fail on `Error` severity). CI runs on `ubuntu-latest` with `shell: pwsh`. |
| `skill-plugin` | TBD when the overlay is built — validate `plugin.json` / `marketplace.json` / `SKILL.md` frontmatter (reuse `scripts/validate_*.py`) and scan SKILL bodies for safety. |
| `collection` | TBD when the overlay is built. |
| `mcp-server` | TBD when the overlay is built. |
| `app-ts` / `app-python` | TBD when the overlay is built — the language's standard test runner. |
| `script-collection` | TBD when the overlay is built — at minimum a smoke run of each script. |

When you fill in a stub type overlay, add its row here and ship a CI workflow in the type's
`public/` overlay.
