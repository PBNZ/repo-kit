# AGENTS.md — RepoKit

**RepoKit** is a reusable GitHub-repository standard plus a `/new-repo` scaffolder, packaged as a
Claude Code plugin. It stamps consistent, navigable repos from commit #1, organised by
**type × tier** so private repos stay light and public/published ones get the right ceremony.

This repo **dogfoods its own standard** (Core + Public tier).

## START-HERE map — where things live

| You want… | Look in |
|-----------|---------|
| What RepoKit is / how to install | `README.md` |
| The standard itself (tiers, where-things-live, do/don't) | `plugins/repokit/skills/repo-standard/standard/the-standard.md` |
| Commit / changelog / version conventions | `plugins/repokit/skills/repo-standard/standard/commit-conventions.md` |
| Pre-commit / pre-PR checklists | `plugins/repokit/skills/repo-standard/standard/pre-commit-checklist.md`, `pre-pr-checklist.md` |
| Doc formatting & the living-docs pattern | `plugins/repokit/skills/repo-standard/standard/doc-style.md`, `living-docs.md` |
| What to test per repo type | `plugins/repokit/skills/repo-standard/standard/testing-matrix.md` |
| The scaffolding methodology (`/new-repo`) | `plugins/repokit/skills/new-repo/SKILL.md` |
| Templates stamped into new repos | `plugins/repokit/skills/new-repo/templates/` |
| Decisions & rationale (learnings log) | `docs/adr/` |
| Validation scripts (run before committing) | `scripts/` + `.github/workflows/validate.yml` |

## Ground rules

- `AGENTS.md` is the canonical agent file; `CLAUDE.md` is a thin `@AGENTS.md` import (Claude Code
  reads `CLAUDE.md`, not `AGENTS.md`).
- Default to verified, simple, proven practices. Conventional Commits; one concern per PR.
- When working in this repo, the **`repo-standard`** skill auto-loads the conventions and the
  pre-commit / pre-PR checklists — follow them before committing or opening a PR.
- Templates and `SKILL.md` files are **prompt content** — keep them plain prose, no secrets, no
  email addresses (CI enforces this via `scripts/check_*.py`).
- RepoKit publishes to its own marketplace; "publish" = bump versions in `plugin.json` /
  `marketplace.json` / `CHANGELOG.md`, then tag and push. See `docs/adr/0001-repokit-architecture.md`.
