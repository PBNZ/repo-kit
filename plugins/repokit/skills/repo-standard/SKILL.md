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
- `standard/where-things-go.md` — a placement guide: "I have X — where does it go, how do I create
  the place if it doesn't exist yet, and on what convention?" Use this for any "where does this go"
  question.
- `standard/commit-conventions.md` — Conventional Commits, SemVer, Keep a Changelog, and how
  release-please fits in at the Published tier.
- `standard/pre-commit-checklist.md` — run through this before every commit.
- `standard/pre-pr-checklist.md` — run through this before opening a PR.
- `standard/session-end-checklist.md` — run through this before ending a working session:
  unmerged-branch decisions, one-concern commits, resume-state currency.
- `standard/testing-matrix.md` — what to test, per repo type.
- `standard/doc-style.md` — deterministic formatting rules for docs (one table style, ISO dates,
  fixed status words) so many sessions/models write like one author.
- `standard/living-docs.md` — the living-docs add-on: `docs/STATE.json` as the single source for
  volatile facts, state blocks, `scripts/check-docs.ps1`, and the current-state-only runbook rules.
- `standard/labels.md` — the layered issue/PR label scheme: GitHub defaults as the base, opt-in
  namespaces (`area:`, `agent:`, `campaign:`), workflow-verdict labels, and the bootstrap commands.
- `standard/agent-collaboration.md` — humans + agents on a shared board: the real-time board
  rule, the pickup/handoff loop, closing-force gestures, agent-output signatures, and the
  session preflight.
- `standard/fleet.md` — multi-repo projects (hub-and-spoke): the hub as router, the scope test,
  sibling clones, three-line spoke inheritance, and docs-move-with-stub.

## The core, inline

- **`AGENTS.md` is canonical; `CLAUDE.md` is a thin `@AGENTS.md` import.** Don't put conventions in
  a plugin-root `CLAUDE.md` — it isn't loaded as context.
- **Read the START-HERE map in `AGENTS.md` first.** It tells you where rules, decisions,
  checklists, CI, and tests live in *this* repo.
- **Record notable decisions as ADRs** in `docs/adr/` (copy `0000-template.md`).
- **"Where does X go?"** — consult `standard/where-things-go.md`. Give the location, how to create
  the place if it doesn't exist yet, and the convention it's based on (name the source). If the
  thing isn't listed, apply the rule of thumb there, say where your suggestion comes from, and
  offer to add a row (or write an ADR) so it's captured.
- **Conventional Commits**, one concern per PR. Update `CHANGELOG.md` under `## [Unreleased]` for
  user-visible changes.
- **Living-docs repos** (the repo has `docs/STATE.json`): volatile facts live there and *only*
  there — docs move together in the same commit, and `pwsh scripts/check-docs.ps1` must pass.
- **Ceremony scales by visibility** (Core → +Public → +Published). Don't add public/published
  governance to a private repo.
- Before committing or opening a PR, run the relevant checklist above. Before ending a working
  session, run `standard/session-end-checklist.md`.
- **After a push or PR, check the remote** — confirm CI/Actions are green and address any GitHub Copilot / reviewer feedback before calling the work done (see `pre-pr-checklist.md`).
