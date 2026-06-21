# Pre-PR checklist

Run through this before opening a pull request.

- [ ] **On a feature branch**, not `main`.
- [ ] **CI would pass locally** — run the repo's checks / tests (see `testing-matrix.md`).
- [ ] **An ADR added or updated** in `docs/adr/` for any notable decision.
- [ ] **The PR template is filled in** (what & why + the checklist).
- [ ] **One concern per PR** — split unrelated changes.
- [ ] **`CHANGELOG.md`** has the user-visible changes under `## [Unreleased]`.

> Autonomy: an agent stops at **ready-for-local-review**. You open the PR and you publish — the
> agent does not push to a public remote or publish on its own.
