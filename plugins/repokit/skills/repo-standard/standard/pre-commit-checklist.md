# Pre-commit checklist

Run through this before every commit.

- [ ] **Builds / lints clean** for this repo type (see `testing-matrix.md`).
- [ ] **Tests pass** for the code you touched.
- [ ] **Every changed line traces to the task.** No drive-by edits; surgical changes only.
- [ ] **No secrets, tokens, or private identity** in the diff — no email addresses, no real
  personal names: the author is the GitHub handle unless this repo declares otherwise (see
  `the-standard.md`, *Author identity*). Core ships `scripts/install-privacy-guard.ps1` to
  enforce this locally with an untracked hook — and a guard that has never failed a negative
  test is not yet a guard, which is why the installer runs one on every install.
- [ ] **`CHANGELOG.md` updated** under `## [Unreleased]` if the change is user-visible.
- [ ] **Docs move together** *(living-docs repos)* — if the change alters anything a doc states
  (status, resources, counts, dates), update `docs/STATE.json` in the same commit, run
  `pwsh scripts/check-docs.ps1 -Update`, and include the re-rendered blocks; the plain check must
  pass (see `living-docs.md`).
- [ ] **Resume-state updated** — the repo's resume-state artifact (`docs/CHECKPOINT.md` or its
  declared substitute) reflects this commit, **or** the commit doesn't change the repo's state —
  say which.
- [ ] **Conventional Commit message** (see `commit-conventions.md`), one concern per commit.

> Enforcement note: Claude Code hooks only catch commands run *in-session*; a native `git commit`
> from your terminal bypasses them. For out-of-session safety, lean on git hooks + CI — that's why
> the Public tier ships a validation workflow, and why Core ships the privacy-guard installer
> (re-run it per clone; `.git/hooks/` does not travel).
