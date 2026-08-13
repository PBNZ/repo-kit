#!/usr/bin/env pwsh
#Requires -Version 7.0
# Smoke test for the bundled install-privacy-guard.ps1 template (refs #34).
#
# Proves, end-to-end through real `git commit` invocations (so the sh shim, line endings, and
# the executable bit are exercised, not just the guard logic): the installer succeeds and
# self-tests, a staged content leak and a staged filename leak are blocked, a clean commit
# passes, a real-name identity is blocked unless -SkipIdentityCheck, a foreign pre-commit hook
# is refused without -Force, and a configured core.hooksPath refuses the install outright.

$ErrorActionPreference = 'Stop'

$installer = Resolve-Path (Join-Path $PSScriptRoot '..' `
    'plugins/repokit/skills/new-repo/templates/core/scripts/install-privacy-guard.ps1')

function New-Fixture {
    $d = Join-Path ([IO.Path]::GetTempPath()) ("privacy-guard-smoke-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $d | Out-Null
    git -C $d init -q -b main 2>$null
    if ($LASTEXITCODE -ne 0) { git -C $d init -q; git -C $d branch -m main }   # git < 2.28
    git -C $d config core.autocrlf false
    git -C $d config commit.gpgsign false
    git -C $d config user.name  'octocat'
    git -C $d config user.email 'octocat@users.noreply.github.com'
    Set-Content -LiteralPath (Join-Path $d 'README.md') -Value '# fixture'
    git -C $d add -A
    git -C $d commit -q -m 'chore: fixture' | Out-Null
    return $d
}

$script:failed = 0
function Assert([bool]$Cond, [string]$Name) {
    if ($Cond) { Write-Host "PASS: $Name" } else { Write-Host "FAIL: $Name"; $script:failed++ }
}

# 1. Install with -Pattern (non-interactive): exits 0 — which also means the installer's own
#    internal negative test passed — and both hook files exist.
$d = New-Fixture
& pwsh -NoProfile -File $installer -RepoRoot $d -Pattern 'Ann,Example' > $null
Assert ($LASTEXITCODE -eq 0) 'installer succeeds with -Pattern (internal negative test passed)'
Assert (Test-Path (Join-Path $d '.git/hooks/pre-commit')) 'pre-commit shim written'
Assert (Test-Path (Join-Path $d '.git/hooks/pre-commit-privacy-guard.ps1')) 'guard script written'

# 2. A commit with a staged content leak is blocked, end-to-end through git.
Set-Content -LiteralPath (Join-Path $d 'notes.txt') -Value 'ask Ann about the release'
git -C $d add -A
git -C $d commit -q -m 'chore: leak' 2>$null
Assert ($LASTEXITCODE -ne 0) 'commit with a staged content leak is blocked'
git -C $d rm -q --cached notes.txt
Remove-Item -LiteralPath (Join-Path $d 'notes.txt')

# 3. A commit whose staged FILENAME leaks is blocked (content is clean).
Set-Content -LiteralPath (Join-Path $d 'for-Example.txt') -Value 'clean content'
git -C $d add -A
git -C $d commit -q -m 'chore: filename leak' 2>$null
Assert ($LASTEXITCODE -ne 0) 'commit with a leaking staged filename is blocked'
git -C $d rm -q --cached -- for-Example.txt
Remove-Item -LiteralPath (Join-Path $d 'for-Example.txt')

# 4. Matching is case-insensitive.
Set-Content -LiteralPath (Join-Path $d 'shout.txt') -Value 'ANN was here'
git -C $d add -A
git -C $d commit -q -m 'chore: case leak' 2>$null
Assert ($LASTEXITCODE -ne 0) 'case-insensitive match is blocked'
git -C $d rm -q --cached shout.txt
Remove-Item -LiteralPath (Join-Path $d 'shout.txt')

# 5. A clean commit passes — the guard blocks leaks, not work.
Set-Content -LiteralPath (Join-Path $d 'work.txt') -Value 'ordinary change'
git -C $d add -A
git -C $d commit -q -m 'chore: clean' 2>$null
Assert ($LASTEXITCODE -eq 0) 'clean commit passes'

# 6. A real-name commit identity is blocked even with a clean diff.
git -C $d config user.name 'Octo Cat'
Set-Content -LiteralPath (Join-Path $d 'more.txt') -Value 'another ordinary change'
git -C $d add -A
git -C $d commit -q -m 'chore: identity' 2>$null
Assert ($LASTEXITCODE -ne 0) 'real-name commit identity is blocked'
git -C $d config user.name 'octocat'
Remove-Item -Recurse -Force $d

# 7. -SkipIdentityCheck: the same real-name identity commits fine, content is still guarded.
$d = New-Fixture
& pwsh -NoProfile -File $installer -RepoRoot $d -Pattern 'Ann' -SkipIdentityCheck > $null
Assert ($LASTEXITCODE -eq 0) 'installer succeeds with -SkipIdentityCheck'
git -C $d config user.name 'Octo Cat'
Set-Content -LiteralPath (Join-Path $d 'work.txt') -Value 'ordinary change'
git -C $d add -A
git -C $d commit -q -m 'chore: variance identity' 2>$null
Assert ($LASTEXITCODE -eq 0) 'declared-variance identity passes with -SkipIdentityCheck'
Set-Content -LiteralPath (Join-Path $d 'leak.txt') -Value 'Ann appears'
git -C $d add -A
git -C $d commit -q -m 'chore: leak' 2>$null
Assert ($LASTEXITCODE -ne 0) 'content leak still blocked with -SkipIdentityCheck'
Remove-Item -Recurse -Force $d

# 8. A foreign pre-commit hook is refused without -Force and left untouched; -Force replaces it.
$d = New-Fixture
$foreign = Join-Path $d '.git/hooks/pre-commit'
[IO.File]::WriteAllText($foreign, "#!/bin/sh`necho someone else's hook`n")
& pwsh -NoProfile -File $installer -RepoRoot $d -Pattern 'Ann' > $null
Assert ($LASTEXITCODE -ne 0) 'foreign pre-commit hook refuses the install without -Force'
Assert ((Get-Content -LiteralPath $foreign -Raw) -match 'someone') 'foreign hook left untouched on refusal'
& pwsh -NoProfile -File $installer -RepoRoot $d -Pattern 'Ann' -Force > $null
Assert ($LASTEXITCODE -eq 0) '-Force replaces the foreign hook'
Assert ((Get-Content -LiteralPath $foreign -Raw) -match 'privacy-guard') '-Force wrote the guard shim'
Remove-Item -Recurse -Force $d

# 9. A configured core.hooksPath refuses the install (the patterns could land in the tree).
$d = New-Fixture
git -C $d config core.hooksPath .husky
& pwsh -NoProfile -File $installer -RepoRoot $d -Pattern 'Ann' > $null
Assert ($LASTEXITCODE -ne 0) 'configured core.hooksPath refuses the install'
Remove-Item -Recurse -Force $d

if ($script:failed -gt 0) { Write-Host "smoke_test_privacy_guard: $script:failed failure(s)"; exit 1 }
Write-Host 'smoke_test_privacy_guard: all cases passed'
# Explicit success exit: the last Assert may leave $LASTEXITCODE nonzero from a git call, and
# GitHub's pwsh shell wrapper would otherwise propagate it as the job's exit code.
exit 0
