# Pre-PR checklist

Run through this before opening a pull request.

- [ ] **On a feature branch**, not `main`.
- [ ] **CI would pass locally** — run the repo's checks / tests (see `testing-matrix.md`).
- [ ] **An ADR added or updated** in `docs/adr/` for any notable decision.
- [ ] **The PR template is filled in** (what & why + the checklist).
- [ ] **Driving issue referenced** as `Refs #NN` — no closing keywords where a human verifies
  after merge (see `commit-conventions.md`, *Issue traceability*).
- [ ] **One concern per PR** — split unrelated changes.
- [ ] **`CHANGELOG.md`** has the user-visible changes under `## [Unreleased]`.
- [ ] **Release due?** — if `[Unreleased]` describes more than one shippable unit, cut a version
  (see `commit-conventions.md`, *When to cut a release*).
- [ ] **Doc consistency** *(living-docs repos)* — `pwsh scripts/check-docs.ps1` passes, and the
  runbook is current-state-only: no superseded sections, no dated journal prose (see
  `living-docs.md`).

## After a push or PR — check the remote

A push or PR isn't "done": the remote runs checks and may post automated feedback. Before calling
the work complete, look:

- [ ] **CI / Actions are green** — watch them (`gh run watch`, or `gh pr checks <n> --watch`). If a
  check is red, read the failed log (`gh run view <id> --log-failed`), fix the cause, and push again.
- [ ] **Automated review addressed** — read any **GitHub Copilot** code-review comments and reviewer
  feedback on the PR (or, on a direct push to `main`, the commit's checks); fix or reply to each.
> Autonomy: an agent stops at **ready-for-local-review**. You open the PR and you publish — the
> agent does not push to a public remote or publish on its own.
