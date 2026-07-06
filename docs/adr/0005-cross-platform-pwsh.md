# ADR-0005: RepoKit runs from any host OS; PowerShell templates are Linux-tested

- **Status:** accepted
- **Date:** 2026-07-07

## Context

RepoKit's plugin is prose and templates — it ships no scripts that run on the user's machine.
A scaffolding session shells out in whatever shell the host provides, so on Windows the author's
sessions ran PowerShell, which raised the question: does any of this work on Linux/macOS?

An audit found the moving parts were already cross-platform by design: skill instructions use
`git`, `gh`, and `rg`; the repo's own validation is Python on `ubuntu-latest`; and the
`powershell-module` templates target pwsh 7 (`PowerShellVersion = '7.0'`,
`CompatiblePSEditions = @('Core')`, forward-slash paths) with CI on `ubuntu-latest` +
`shell: pwsh`. But two gaps remained: nothing in *this* repo ever executed the stamped templates
(only a scaffolded repo's own CI would, after the fact), and one skill instruction assumed
PowerShell on the scaffolding host (`{{Guid}}` via `[guid]::NewGuid()`).

## Decision

1. **Skill instructions must not assume a host shell.** Use cross-platform CLIs (`git`, `gh`,
   `rg`) or list per-OS equivalents (as the `{{Guid}}` row now does).
2. **PowerShell templates target pwsh 7+ / PSEdition Core only** — no Windows PowerShell 5.1
   compatibility, no Windows-only cmdlets or path assumptions.
3. **This repo's CI proves it on Linux:** `scripts/smoke_test_powershell_module.ps1` stamps the
   `powershell-module` core templates with dummy values and verifies the result parses, imports,
   lints clean, and passes its Pester scaffold. `validate.yml` runs it with pwsh on
   `ubuntu-latest` for every push/PR.

## Consequences

- A template regression that breaks on Linux now fails PR CI here, instead of surfacing in the
  first repo someone scaffolds.
- macOS is not in the CI matrix; pwsh Core is the same engine there, and the Linux run already
  catches case-sensitivity and path-separator mistakes — acceptable until proven otherwise.
- A future repo type that ships *executable* templates should add a matching smoke job; the
  script's stamp-then-verify shape is the pattern to copy.
