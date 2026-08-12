# Checkpoint — repo-kit

Resume state: what a fresh session needs to pick this repo up. Keep every line current — the
pre-commit checklist has the tripwire, and stale entries are worse than none.

- Last updated: 2026-08-13
- Status: IN PROGRESS
- In progress: standards batch in review — [PR #29](https://github.com/PBNZ/repo-kit/pull/29)
  (#25 + #26, ADR-0009: handle-over-real-name defaults, repokit-check identity check) and
  [PR #30](https://github.com/PBNZ/repo-kit/pull/30) (#28: content-based branch-landed check);
  CI green, Copilot review addressed on both
- Next step: owner merges #29 and #30 and closes #25/#26/#28 after verifying; then cut 0.6.0 —
  rename `[Unreleased]`, bump `plugin.json` + `marketplace.json`, tag `v0.6.0`, push

One line per fact, current state only — history lives in `CHANGELOG.md` and git.
