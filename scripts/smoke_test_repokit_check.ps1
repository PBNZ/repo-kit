#!/usr/bin/env pwsh
#Requires -Version 7.0
# Smoke test for the bundled repokit-check.ps1 self-check template.
#
# Builds a minimal compliant fixture repo and asserts the check passes, then proves the check
# FAILS on each drift case from the retrospective (refs #16): missing shim, non-importing shim,
# broken START-HERE path, missing changelog, missing ADR dir, missing resume-state row.

$ErrorActionPreference = 'Stop'

$check = Resolve-Path (Join-Path $PSScriptRoot '..' `
    'plugins/repokit/skills/new-repo/templates/core/scripts/repokit-check.ps1')

$agentsTemplate = @'
# AGENTS.md — fixture

## START-HERE map — where things live

| You want… | Look in |
|---|---|
| Decisions & rationale | `docs/adr/` |
| Where work was left (resume state / checkpoint) | `docs/CHECKPOINT.md` |
| A helper script | `scripts/noop.ps1` |
'@

function New-Fixture {
    $dir = Join-Path ([IO.Path]::GetTempPath()) ("repokit-check-smoke-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path (Join-Path $dir 'docs/adr'), (Join-Path $dir 'scripts') -Force | Out-Null
    Set-Content -Path (Join-Path $dir 'AGENTS.md') -Value $agentsTemplate
    Set-Content -Path (Join-Path $dir 'CLAUDE.md') -Value @('# CLAUDE.md', '', '@AGENTS.md')
    Set-Content -Path (Join-Path $dir 'CHANGELOG.md') -Value "# Changelog`n`n## [Unreleased]"
    Set-Content -Path (Join-Path $dir 'docs/CHECKPOINT.md') -Value "# Checkpoint`n`n- Last updated: 2026-07-19`n- Next step: paused - nothing pending"
    Set-Content -Path (Join-Path $dir 'docs/adr/0000-template.md') -Value '# ADR template'
    Set-Content -Path (Join-Path $dir 'scripts/noop.ps1') -Value '# noop'
    return $dir
}

$script:failed = 0
function Assert-Check {
    param([string]$Name, [string]$Dir, [int]$ExpectedExit)
    & pwsh -NoProfile -File $check -RepoRoot $Dir > $null
    $actual = $LASTEXITCODE
    if (($ExpectedExit -eq 0 -and $actual -eq 0) -or ($ExpectedExit -ne 0 -and $actual -ne 0)) {
        Write-Host "PASS: $Name"
    } else {
        Write-Host "FAIL: $Name (exit $actual, expected $ExpectedExit)"
        $script:failed++
    }
    Remove-Item -Recurse -Force $Dir
}

# 1. A compliant fixture passes.
Assert-Check 'compliant fixture passes' (New-Fixture) 0

# 2. Loader shim missing — canonical file present but functionally dead.
$d = New-Fixture; Remove-Item (Join-Path $d 'CLAUDE.md')
Assert-Check 'missing CLAUDE.md shim fails' $d 1

# 3. Shim exists but does not import the canonical file.
$d = New-Fixture; Set-Content (Join-Path $d 'CLAUDE.md') '# CLAUDE.md with no import'
Assert-Check 'non-importing shim fails' $d 1

# 4. A START-HERE path that does not resolve (declared structure drifted).
$d = New-Fixture; Remove-Item (Join-Path $d 'scripts/noop.ps1')
Assert-Check 'broken START-HERE path fails' $d 1

# 5. Changelog gone, with no declared substitute.
$d = New-Fixture; Remove-Item (Join-Path $d 'CHANGELOG.md')
Assert-Check 'missing changelog fails' $d 1

# 6. ADR directory replaced by nothing — the row now points at a void.
$d = New-Fixture; Remove-Item -Recurse (Join-Path $d 'docs/adr')
Assert-Check 'missing ADR dir fails' $d 1

# 7. Resume-state row removed from the map (artifact file still present — the row is mandatory).
$d = New-Fixture
Set-Content (Join-Path $d 'AGENTS.md') (($agentsTemplate -split "`n") -notmatch 'resume state' -join "`n")
Assert-Check 'missing resume-state row fails' $d 1

if ($script:failed -gt 0) { Write-Host "smoke_test_repokit_check: $script:failed failure(s)"; exit 1 }
Write-Host 'smoke_test_repokit_check: all cases passed'
# Explicit success exit: the last negative case leaves $LASTEXITCODE = 1, and GitHub's pwsh
# shell wrapper would otherwise propagate it as the job's exit code.
exit 0
