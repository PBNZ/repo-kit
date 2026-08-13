# ADR-0012: A shipped, self-testing privacy-guard pre-commit hook

- **Status:** accepted
- **Date:** 2026-08-13

## Context

Field report #34: the standard's *Author identity* section explains why personal-name guard
patterns must stay out of the tree, but left the actual guard for each repo to hand-roll — and
hand-rolled guards fail silently. The real case: a pre-commit hook filtered diff noise with
`grep -v '^\+\+\+'` without `-E`; in GNU BRE `\+` is a quantifier, so the filter matched every
added line and `-v` discarded them all — the guard passed everything, including a staged test
leak. Only a deliberate negative test caught it.

## Decision

Core ships `scripts/install-privacy-guard.ps1` — an installer, not a hook — with four design
choices:

- **Patterns are case-insensitive literals, not regexes.** The failure that motivated this ADR
  was a regex quoting subtlety; a literal cannot fail that way, and a literal is exactly what a
  name is. Comma-separated on the CLI (so the flag survives every calling shell), prompted
  interactively otherwise.
- **The installer is tracked; the guard is not.** The patterns are written only into
  `.git/hooks/` (an sh shim exec-ing a generated pwsh guard), which git never commits and never
  clones. A configured `core.hooksPath` refuses the install outright — it could point at a
  tracked directory, which would commit the very patterns the guard exists to keep out. Block
  messages name patterns by index only, so a pasted transcript never spells the secret.
- **Every install ends with a mandatory negative test**, run in a throwaway fixture repo so the
  user's index is never touched: a clean stage must pass, and a synthetic content leak, filename
  leak, and real-name commit identity must each be blocked. Any failed assertion removes the
  hook again and exits nonzero — a guard that has never failed a negative test is not yet a
  guard. The fixture starts on an unborn branch, so the first-commit diff base is exercised on
  every install.
- **Scope: staged additions, staged filenames, and the commit identity** (handle + noreply, the
  same rule `repokit-check.ps1` enforces; `-SkipIdentityCheck` for repos with a declared
  identity variance).

CI proves the template end-to-end (`scripts/smoke_test_privacy_guard.ps1`): real `git commit`
invocations through the sh shim on Linux, covering every block class, the clean-commit path,
`-SkipIdentityCheck`, foreign-hook refusal, `-Force`, and the `core.hooksPath` refusal.

## Consequences

Repos get a tested guard for the price of one command per clone, and the pre-commit checklist's
"no private identity" item gains a mechanical backstop. The known limits are stated where the
guard is documented: `git commit --no-verify` bypasses any pre-commit hook, the hook does not
travel with clones (re-install per machine), and a pattern containing a comma cannot be
expressed on the CLI (use the interactive prompt). The guard scans staged additions only — a
pattern already committed before install is out of scope; that remains the audit's job.
