# ADR-0009: Author identity — the GitHub handle everywhere, a real name only as a declared variance

- **Status:** accepted
- **Date:** 2026-08-12

## Context

Auditing a public `/new-repo`-scaffolded repo against 0.5.0 produced two field reports (#25,
#26): the standard's anonymity story was half-built. The commit *email* was anonymised (the
GitHub noreply address), but the recipe under the heading "Commit identity -- anonymous by
default" resolved the commit *name* as `.name // .login` — the real profile name, on any
account that has one. The `{{author}}` interview default was a real personal name, the licence
template hardcoded one specific handle, and nothing — self-check or CI — caught a real name
reintroduced later. The name is the expensive half: file contents can be edited, but a commit
identity leaves history only via a rewrite and force-push, which defeats RepoKit's
private-now/public-later promotion path.

## Decision

Privacy-first identity by default; a real name is a per-repo, user-explicit opt-in recorded as
a declared variance. Both issues accepted, landed as one batch (one commit per issue,
`Refs #NN`), with the guard adapted:

- **The stated convention** — `the-standard.md` gains an *Author identity* section: the GitHub
  handle identifies the author everywhere an author/owner/copyright value is written (commit
  identity, module metadata, copyright lines, ADRs, docs). The opt-in path reuses the existing
  variance mechanism — an ADR records the choice and a START-HERE row declares it — so a real
  name reads as a decision, not a leak. `commit-conventions.md` now covers both identity
  fields; the pre-commit checklist's contact-info item extends to names.
- **The recipe** — `/new-repo` step 5 prefers `.login` for `user.name` (was `.name // .login`),
  and the `{{author}}` interview default is the handle, not a personal name. The licence
  copyright line is stamped from `{{year}}`/`{{author}}` instead of a hardcoded value. The
  scaffolded `AGENTS.md` tells later sessions to leave the configured identity alone — a
  behaviour an agent must be told, not a file it can lint.
- **The guard** — `repokit-check.ps1` gains check 6: the repo-local git identity and every
  commit identity since the adoption marker must be handle + noreply (GitHub's own web-flow
  identity allowed); the declared variance row switches the check off. This runs wherever the
  self-check already runs (locally and via the one-line CI step), so reintroduction no longer
  relies on a human spotting it in review.
- **Adapted, not adopted:** #26's tree-grep CI guard (bracketed patterns for a specific name)
  is documented in *Author identity* as an optional per-repo recipe rather than stamped into
  scaffolds — the bracket defeats the grep, not a reader, so stamping the pattern into every
  potentially-public repo would leak by default the very thing it guards. The trade-off and
  the secret-based alternative are stated where the recipe is offered.

Issues are **not** auto-closed — the human verifies each after merge.

## Consequences

Scaffolds carry no real personal name in any tier's output, and the commit identity is
anonymous in both fields from commit #1. The self-check grows its first git-history check;
repos without git, with no commits yet, or running from a shallow clone degrade to a warning
rather than a failure. A repo that genuinely wants real-name attribution pays one ADR and one
START-HERE row — the same price as any other declared variance. What remains uncatchable by
machinery is a real name in file contents on a repo that never opted in and never added the
tree guard; that stays with the pre-commit checklist and review.
