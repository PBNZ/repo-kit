# Pre-commit checklist

Run through this before every commit.

- [ ] **Builds / lints clean** for this repo type (see `testing-matrix.md`).
- [ ] **Tests pass** for the code you touched.
- [ ] **Every changed line traces to the task.** No drive-by edits; surgical changes only.
- [ ] **No secrets, tokens, or private contact info** (no email addresses) in the diff.
- [ ] **`CHANGELOG.md` updated** under `## [Unreleased]` if the change is user-visible.
- [ ] **Docs move together** *(living-docs repos)* — if the change alters anything a doc states
  (status, resources, counts, dates), update `docs/STATE.json` in the same commit, run
  `pwsh scripts/check-docs.ps1 -Update`, and include the re-rendered blocks; the plain check must
  pass (see `living-docs.md`).
- [ ] **Conventional Commit message** (see `commit-conventions.md`), one concern per commit.

> Enforcement note: Claude Code hooks only catch commands run *in-session*; a native `git commit`
> from your terminal bypasses them. For out-of-session safety, lean on git hooks + CI — that's why
> the Public tier ships a validation workflow.
