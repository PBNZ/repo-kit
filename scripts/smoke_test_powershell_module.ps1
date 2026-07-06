#!/usr/bin/env pwsh
#Requires -Version 7.0
# Smoke-test for the powershell-module type templates. Stamps the core-tier
# templates with dummy values into a temp directory, then proves the result is a
# working module: manifest parses, module imports, PSScriptAnalyzer is clean, and
# the scaffolded Pester test passes. Runs on any pwsh 7 platform; CI runs it on
# ubuntu-latest so the templates are exercised on Linux for every push/PR.

$ErrorActionPreference = 'Stop'

$repoRoot     = Split-Path -Parent $PSScriptRoot
$templateRoot = Join-Path $repoRoot 'plugins/repokit/skills/new-repo/templates/types/powershell-module/core'
$moduleName   = 'RepoKitSmoke'
$stageDir     = Join-Path ([IO.Path]::GetTempPath()) "repokit-template-smoke/$moduleName"

if (-not (Test-Path $templateRoot)) { throw "Template root not found: $templateRoot" }
if (Test-Path $stageDir) { Remove-Item $stageDir -Recurse -Force }
New-Item -ItemType Directory -Path $stageDir -Force | Out-Null

# Dummy values for every placeholder the templates can contain
# (see skills/new-repo/references/placeholders.md).
$values = @{
    ModuleName  = $moduleName
    Guid        = [guid]::NewGuid().ToString()
    name        = 'repokit-smoke'
    description = 'RepoKit powershell-module template smoke test.'
    author      = 'RepoKit CI'
    license     = 'Apache-2.0'
    type        = 'powershell-module'
    tier        = 'Core'
    year        = (Get-Date).Year
}

Write-Host "Stamping templates from $templateRoot"
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

Write-Host "`nCheck 1: no leftover placeholder tokens"
$tokenPattern = '\{\{(name|description|author|year|license|type|tier|ModuleName|Guid|START_HERE_MAP)\}\}'
$leftovers = Get-ChildItem -Path $stageDir -Recurse -File | Select-String -Pattern $tokenPattern
if ($leftovers) {
    $leftovers | ForEach-Object { Write-Host "  LEFTOVER: $_" }
    throw "Placeholder tokens survived stamping."
}

Write-Host "Check 2: Test-ModuleManifest"
$manifest = Join-Path $stageDir "$moduleName.psd1"
Test-ModuleManifest -Path $manifest | Out-Null

Write-Host "Check 3: Import-Module"
Import-Module $manifest -Force
Remove-Module $moduleName -Force

Write-Host "Check 4: PSScriptAnalyzer (Error severity)"
if (Get-Module -ListAvailable PSScriptAnalyzer) {
    $issues = Invoke-ScriptAnalyzer -Path $stageDir -Recurse -Severity Error
    if ($issues) {
        $issues | Format-Table -AutoSize | Out-String | Write-Host
        throw "PSScriptAnalyzer found $($issues.Count) error-severity issue(s)."
    }
} else {
    Write-Warning 'PSScriptAnalyzer not installed - lint check skipped (CI installs it).'
}

Write-Host "Check 5: Pester scaffold test"
Import-Module Pester -MinimumVersion 5.0 -Force
$result = Invoke-Pester -Path (Join-Path $stageDir 'Tests') -PassThru
if ($result.TotalCount -eq 0) { throw 'No Pester tests were discovered in the stamped Tests/ directory.' }
if ($result.FailedCount -gt 0) { throw "$($result.FailedCount) Pester test(s) failed." }

Write-Host "`nSmoke test passed: templates stamp into a working module on $($PSVersionTable.Platform ?? 'Windows') / pwsh $($PSVersionTable.PSVersion)."
