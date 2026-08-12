#!/usr/bin/env pwsh
#Requires -Version 7.0
# repokit-check.ps1 — RepoKit compliance self-check.
#
# Verifies the repo's *declared* structure actually exists (see the RepoKit standard,
# "Variance declarations"):
#   1. AGENTS.md (canonical agent file) exists; CLAUDE.md (loader shim) exists and imports it.
#   2. Every path named in the START-HERE map resolves to an existing file or directory.
#   3. A changelog exists at the default location or a declared one.
#   4. An ADR directory (or declared substitute) exists.
#   5. A resume-state row exists in the START-HERE map (docs/CHECKPOINT.md or a declared
#      substitute) — the row is mandatory.
#   6. The commit identity is the GitHub handle + noreply email (see the standard, "Author
#      identity") — repo-local config and history since the adoption marker — unless the
#      START-HERE map declares an author-identity variance.
#
# Usage: pwsh scripts/repokit-check.ps1 [-RepoRoot <path>]
# Exit code: 0 = compliant, 1 = one or more failures.

[CmdletBinding()]
param([string]$RepoRoot = '.')

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$script:failures = 0

function Pass([string]$msg) { Write-Host "  OK   $msg" }
function Warn([string]$msg) { Write-Host "  WARN $msg" }
function Fail([string]$msg) { Write-Host "  FAIL $msg"; $script:failures++ }

Write-Host "repokit-check: $RepoRoot"

# --- 1. Canonical agent file + loader shim -------------------------------------------------
$agentsPath = Join-Path $RepoRoot 'AGENTS.md'
$claudePath = Join-Path $RepoRoot 'CLAUDE.md'

if (Test-Path -LiteralPath $agentsPath -PathType Leaf) {
    Pass 'AGENTS.md (canonical agent file) exists'
} else {
    Fail 'AGENTS.md (canonical agent file) missing'
}

if (Test-Path -LiteralPath $claudePath -PathType Leaf) {
    if ((Get-Content -LiteralPath $claudePath -Raw) -match '(?m)^\s*@AGENTS\.md\s*$') {
        Pass 'CLAUDE.md shim imports AGENTS.md'
    } else {
        Fail 'CLAUDE.md exists but has no "@AGENTS.md" line - the canonical file never loads'
    }
} else {
    Fail 'CLAUDE.md (loader shim) missing - the canonical file never loads'
}

# --- 2. START-HERE map: every declared path resolves ---------------------------------------
# A cell may hold several backtick tokens; a token is treated as a repo path when it contains
# a "/" and only path-safe characters (bare filenames and slash-commands are skipped).
$dataRows = @()
if (Test-Path -LiteralPath $agentsPath -PathType Leaf) {
    $inMap = $false
    $tableRows = @()
    foreach ($line in (Get-Content -LiteralPath $agentsPath)) {
        if ($line -match '^#{1,6}\s.*START-HERE') { $inMap = $true; continue }
        if ($inMap -and $line -match '^#{1,6}\s') { break }
        if ($inMap -and $line -match '^\s*\|') { $tableRows += $line }
    }
    $dataRows = @($tableRows |
        Where-Object { $_ -notmatch '^\s*\|(\s*:?-{3,}:?\s*\|)+\s*$' } |
        Select-Object -Skip 1)
}

if ($dataRows.Count -eq 0) {
    Fail 'No START-HERE map table found in AGENTS.md'
} else {
    Pass "START-HERE map found ($($dataRows.Count) rows)"
    foreach ($row in $dataRows) {
        $tokens = [regex]::Matches($row, '`([^`]+)`') | ForEach-Object { $_.Groups[1].Value }
        foreach ($tok in $tokens) {
            if ($tok.Contains('/') -and $tok -match '^[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)*/?$') {
                if (Test-Path -LiteralPath (Join-Path $RepoRoot $tok.TrimEnd('/'))) {
                    Pass "START-HERE path resolves: $tok"
                } else {
                    Fail "START-HERE path does not resolve: $tok"
                }
            }
        }
    }
}

function Get-MapRows([string]$pattern) { @($dataRows | Where-Object { $_ -match $pattern }) }

# --- 3. Changelog --------------------------------------------------------------------------
if (Test-Path -LiteralPath (Join-Path $RepoRoot 'CHANGELOG.md') -PathType Leaf) {
    Pass 'CHANGELOG.md exists at the default location'
} elseif ((Get-MapRows '(?i)changelog').Count -gt 0) {
    Pass 'Changelog substitute declared in the START-HERE map (its path is checked above)'
} else {
    Fail 'No CHANGELOG.md and no changelog row in the START-HERE map'
}

# --- 4. ADR directory ----------------------------------------------------------------------
if (Test-Path -LiteralPath (Join-Path $RepoRoot 'docs/adr') -PathType Container) {
    Pass 'docs/adr/ exists'
} elseif ((Get-MapRows '(?i)\badr\b|decision').Count -gt 0) {
    Pass 'ADR substitute declared in the START-HERE map (its path is checked above)'
} else {
    Fail 'No docs/adr/ and no decisions row in the START-HERE map'
}

# --- 5. Resume-state row (mandatory) -------------------------------------------------------
$resumeRows = Get-MapRows '(?i)resume|checkpoint|\bstate\b'
if ($resumeRows.Count -gt 0) {
    Pass 'Resume-state row present in the START-HERE map (its path is checked above)'
    $hasPathToken = $false
    foreach ($row in $resumeRows) {
        foreach ($m in [regex]::Matches($row, '`([^`]+)`')) {
            if ($m.Groups[1].Value.Contains('/')) { $hasPathToken = $true }
        }
    }
    if (-not $hasPathToken) {
        Warn 'Resume-state row names no repo path - a declared substitute this check cannot verify'
    }
} else {
    Fail 'No resume-state row in the START-HERE map (docs/CHECKPOINT.md or a declared substitute is required at Core)'
}

# --- 6. Author identity (privacy default) ---------------------------------------------------
# The standard ("Author identity"): the author is the GitHub handle + noreply email in both
# identity fields. A declared variance row switches the check off; the adoption marker bounds
# the history scan; repos without git (or with no commits yet) skip cleanly.
function Test-AnonymousIdentity([string]$Name, [string]$Email) {
    # GitHub's own web-flow identity is exactly "GitHub <noreply@github.com>" — a real name
    # paired with that email must not slip through.
    if ($Email -eq 'noreply@github.com') { return ($Name -eq 'GitHub') }
    if ($Email -match '^(\d+\+)?(?<login>[^@]+)@users\.noreply\.github\.com$') {
        return ($Name -eq $Matches['login'])                # the handle, nothing else
    }
    return $false
}

if ((Get-MapRows '(?i)author\s+identity').Count -gt 0) {
    Pass 'Author-identity variance declared in the START-HERE map - identity check skipped'
} elseif (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Warn 'git not available - author-identity check skipped'
} else {
    git -C $RepoRoot rev-parse --git-dir *> $null
    if ($LASTEXITCODE -ne 0) {
        Warn 'Not a git repository - author-identity check skipped'
    } else {
        # 6a. The configured repo-local identity — what the *next* commit will use.
        $cfgName  = git -C $RepoRoot config --local --get user.name
        $cfgEmail = git -C $RepoRoot config --local --get user.email
        if ($cfgName -or $cfgEmail) {
            if (Test-AnonymousIdentity $cfgName $cfgEmail) {
                Pass "Repo-local git identity is handle + noreply ($cfgName)"
            } else {
                Fail "Repo-local git identity is not handle + noreply: $cfgName <$cfgEmail> - fix it, or declare an author-identity variance row"
            }
        }
        # 6b. Identities already in history, bounded by the adoption marker when one exists.
        $range = 'HEAD'
        $agentsRaw = ''
        if (Test-Path -LiteralPath $agentsPath -PathType Leaf) {
            $agentsRaw = Get-Content -LiteralPath $agentsPath -Raw
        }
        if ($agentsRaw -match 'RepoKit adopted:[^\r\n]*?`([0-9a-fA-F]{7,40})`') {
            $adoptSha = $Matches[1]
            git -C $RepoRoot rev-parse --verify --quiet "$adoptSha^{commit}" *> $null
            if ($LASTEXITCODE -eq 0) {
                $range = "$adoptSha..HEAD"
            } else {
                Warn "Adoption marker commit $adoptSha not in this clone (shallow?) - scanning the history that is available"
            }
        }
        $idLines = @(git -C $RepoRoot log $range --format='%an%x09%ae%x09%cn%x09%ce' 2>$null)
        if ($LASTEXITCODE -ne 0) {
            Warn 'No commits yet - history identity check skipped'
        } else {
            $bad = [System.Collections.Generic.HashSet[string]]::new()
            foreach ($line in $idLines) {
                $an, $ae, $cn, $ce = $line -split "`t"
                if (-not (Test-AnonymousIdentity $an $ae)) { [void]$bad.Add("$an <$ae>") }
                if (-not (Test-AnonymousIdentity $cn $ce)) { [void]$bad.Add("$cn <$ce>") }
            }
            if ($bad.Count -eq 0) {
                Pass "Commit identities are handle + noreply ($($idLines.Count) commit(s) scanned)"
            } else {
                foreach ($id in $bad) {
                    Fail "Commit identity is not handle + noreply: $id - see the standard, 'Author identity' (a real identity needs a declared variance row)"
                }
            }
        }
    }
}

# --- Summary -------------------------------------------------------------------------------
if ($script:failures -gt 0) {
    Write-Host "repokit-check: $($script:failures) failure(s)"
    exit 1
}
Write-Host 'repokit-check: all checks passed'
