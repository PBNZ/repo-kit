---
name: repo-standard
description: Use when working in a RepoKit-compliant repo — about to commit or open a PR, adding a learning / ADR, or asking "where does X go" or "what's the convention here". Loads the RepoKit conventions and the pre-commit / pre-PR checklists.
---

# repo-standard — conventions for a RepoKit repo

You are working in a repository scaffolded to the RepoKit standard. This skill is the router to
the conventions. The full references live next to this skill; read the one you need from this
skill's base directory (you were given `Base directory for this skill: <ABS>` at load — read
`<ABS>/standard/<doc>.md`):

- `standard/the-standard.md` — the type × tier model, per-tier file lists, the where-things-live
  map, the promotion path, and the do/don't list.
- `standard/commit-conventions.md` — Conventional Commits, SemVer, Keep a Changelog, and how
  release-please fits in at the Published tier.
- `standard/pre-commit-checklist.md` — run through this before every commit.
- `standard/pre-pr-checklist.md` — run through this before opening a PR.
- `standard/testing-matrix.md` — what to test, per repo type.

## The core, inline

- **`AGENTS.md` is canonical; `CLAUDE.md` is a thin `@AGENTS.md` import.** Don't put conventions in
  a plugin-root `CLAUDE.md` — it isn't loaded as context.
- **Read the START-HERE map in `AGENTS.md` first.** It tells you where rules, decisions,
  checklists, CI, and tests live in *this* repo.
- **Record notable decisions as ADRs** in `doc/adr/` (copy `0000-template.md`).
- **Conventional Commits**, one concern per PR. Update `CHANGELOG.md` under `## [Unreleased]` for
  user-visible changes.
- **Ceremony scales by visibility** (Core → +Public → +Published). Don't add public/published
  governance to a private repo.
- Before committing or opening a PR, run the relevant checklist above.
