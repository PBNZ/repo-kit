#!/usr/bin/env pwsh
#Requires -Version 7.0
# Smoke-test for the living-docs add-on templates. Stamps the add-on core-tier
# templates with dummy values into a temp directory, renders the state blocks via
# check-docs.ps1 -Update, and proves the check passes when the docs are consistent
# and FAILS for every enforced problem class: empty/drifted state block, stale
# as_of date, superseded-content marker, malformed table separator. The negative
# tests are the point - they prove the enforcement actually enforces.
# Runs on any pwsh 7 platform; CI runs it on ubuntu-latest.

$ErrorActionPreference = 'Stop'

$repoRoot     = Split-Path -Parent $PSScriptRoot
$templateRoot = Join-Path $repoRoot 'plugins/repokit/skills/new-repo/templates/addons/living-docs/core'
$stageDir     = Join-Path ([IO.Path]::GetTempPath()) 'repokit-living-docs-smoke'

if (-not (Test-Path $templateRoot)) { throw "Template root not found: $templateRoot" }
if (Test-Path $stageDir) { Remove-Item $stageDir -Recurse -Force }
New-Item -ItemType Directory -Path $stageDir -Force | Out-Null

# Dummy values for every placeholder the templates can contain
# (see skills/new-repo/references/placeholders.md).
$values = @{
    name        = 'repokit-living-docs-smoke'
    description = 'RepoKit living-docs add-on smoke test.'
    author      = 'RepoKit CI'
    license     = 'Apache-2.0'
    type        = 'script-collection'
    tier        = 'Core'
    year        = (Get-Date).Year
    today       = (Get-Date).ToString('yyyy-MM-dd')
}

Write-Host "Stamping add-on templates from $templateRoot"
Get-ChildItem -Path $templateRoot -Recurse -File | ForEach-Object {
    $rel = [IO.Path]::GetRelativePath($templateRoot, $_.FullName) -replace '\.tmpl$', ''
    foreach ($k in $values.Keys) { $rel = $rel.Replace("{{$k}}", [string]$values[$k]) }
    $target = Join-Path $stageDir $rel
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    $content = Get-Content -Path $_.FullName -Raw
    if ($null -eq $content) { $content = '' }
    foreach ($k in $values.Keys) { $content = $content.Replace("{{$k}}", [string]$values[$k]) }
    Set-Content -Path $target -Value $content -NoNewline
    Write-Host "  $rel"
}

# The scaffolder appends the README Status snippet (the add-on itself ships no README);
# recreate that here so the block-rendering path is exercised in two files.
$readmeLines = @(
    "# $($values.name)"
    ''
    '## Status'
    ''
    '<!-- state:begin keys=overall_status,live_resources -->'
    '<!-- state:end -->'
)
Set-Content -Path (Join-Path $stageDir 'README.md') -Value ($readmeLines -join "`n")

Write-Host "`nCheck 1: no leftover placeholder tokens"
$tokenPattern = '\{\{(name|description|author|year|today|license|type|tier|ModuleName|Guid|START_HERE_MAP|LIVING_DOCS_RULES)\}\}'
$leftovers = Get-ChildItem -Path $stageDir -Recurse -File | Select-String -Pattern $tokenPattern
if ($leftovers) {
    $leftovers | ForEach-Object { Write-Host "  LEFTOVER: $_" }
    throw 'Placeholder tokens survived stamping.'
}

$checkScript = Join-Path $stageDir 'scripts/check-docs.ps1'

function Invoke-CheckDocs {
    param([switch]$Update)
    $pwshArgs = @('-NoProfile', '-File', $checkScript)
    if ($Update) { $pwshArgs += '-Update' }
    & pwsh @pwshArgs 2>&1 | ForEach-Object { Write-Host "    $_" }
    return $LASTEXITCODE
}

function Assert-ExitCode {
    param([int]$Expected, [string]$Label, [switch]$Update)
    Write-Host "  $Label (expect exit $Expected)"
    $code = Invoke-CheckDocs -Update:$Update
    if ($code -ne $Expected) { throw "$Label - expected exit $Expected, got $code." }
}

Write-Host "`nCheck 2: empty state blocks are detected, -Update renders them, then the check passes"
Assert-ExitCode -Expected 1 -Label 'fresh stamp, blocks still empty'
Assert-ExitCode -Expected 0 -Label 'render blocks with -Update' -Update
Assert-ExitCode -Expected 0 -Label 'plain check after render'

$runbookPath = Join-Path $stageDir 'docs/RUNBOOK.md'
$statePath   = Join-Path $stageDir 'docs/STATE.json'
$readmePath  = Join-Path $stageDir 'README.md'
if ((Get-Content $readmePath -Raw) -notmatch [regex]::Escape('| Overall project status | PLANNED |')) {
    throw 'Rendered README Status block does not contain the expected table row.'
}

Write-Host "`nCheck 3: a STATE.json change without re-rendering fails the check"
$state = Get-Content $statePath -Raw | ConvertFrom-Json -AsHashtable
$state['facts']['overall_status']['value'] = 'IN PROGRESS'
$state | ConvertTo-Json -Depth 5 | Set-Content -Path $statePath
Assert-ExitCode -Expected 1 -Label 'fact changed, blocks not re-rendered'
Assert-ExitCode -Expected 0 -Label 're-render fixes it' -Update

Write-Host "`nCheck 4: a stale as_of fails even with -Update (staleness is not auto-fixable)"
$state = Get-Content $statePath -Raw | ConvertFrom-Json -AsHashtable
$state['facts']['overall_status']['as_of'] = (Get-Date).AddDays(-30).ToString('yyyy-MM-dd')
$state | ConvertTo-Json -Depth 5 | Set-Content -Path $statePath
Assert-ExitCode -Expected 1 -Label 'as_of 30 days old (limit 14)' -Update
$state['facts']['overall_status']['as_of'] = $values.today
$state | ConvertTo-Json -Depth 5 | Set-Content -Path $statePath
Assert-ExitCode -Expected 0 -Label 'as_of restored' -Update

Write-Host "`nCheck 5: a superseded-content marker in the runbook fails the check"
$runbookRaw = Get-Content $runbookPath -Raw
Add-Content -Path $runbookPath -Value "`nThis section is superseded by policy v2."
Assert-ExitCode -Expected 1 -Label 'runbook contains a superseded marker'
Set-Content -Path $runbookPath -Value $runbookRaw -NoNewline
Assert-ExitCode -Expected 0 -Label 'marker removed'

Write-Host "`nCheck 6: a malformed table separator row fails the check"
Add-Content -Path $runbookPath -Value "`nCol A | Col B`n--- | ---`nx | y"
Assert-ExitCode -Expected 1 -Label 'separator row without leading/trailing pipes'
Set-Content -Path $runbookPath -Value $runbookRaw -NoNewline
Assert-ExitCode -Expected 0 -Label 'final state is clean'

Write-Host "`nSmoke test passed: living-docs templates stamp, render, and enforce on $($PSVersionTable.Platform ?? 'Windows') / pwsh $($PSVersionTable.PSVersion)."
