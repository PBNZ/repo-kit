# ADR-0006: Living docs — a state file, rendered blocks, and a deterministic check

- **Status:** accepted
- **Date:** 2026-07-13

## Context

A RepoKit-scaffolded ops repo (44 commits in) showed what happens to docs that track live
operational state when the only defence is prose rules. Its `AGENTS.md` explicitly mandated
"update the README in the same commit as any state change" — yet the runbook was touched in 31
commits and the README in 18, with 15 runbook-only commits. The 1,271-line runbook accreted
history instead of state: three policy versions coexisting under "superseded by v2" annotations,
a "checked <date>, due later today" note contradicting a "PASSED" record three days younger, and
the same counts appearing with different values in different places (43,228 vs 43,229; 42 vs 43).
Two table styles alternated through the file, and it was wholesale-restructured three times in a
week. The symptoms were worse under some models than others — a rule that depends on per-session
model judgment doesn't hold.

RepoKit had nothing to prevent any of this: no runbook concept, no doc-sync rule, no doc
formatting standard, and no doc-consistency step in either checklist.

Rejected alternatives:

- **A hand-maintained standalone HTML runbook** (with a design system): the failures are content
  problems, not rendering problems — they would exist identically in HTML, but harder to diff,
  review, and edit reliably; formatting drift would move from table styles to diverging markup.
- **Generated HTML from markdown/state**: solves nothing the state file doesn't already solve,
  and adds a render pipeline to every stamped repo.
- **Prose-only strengthening of the checklists**: that is the mechanism that already failed.
- **`STATE.yml`**: pwsh 7 has no built-in YAML parser; YAML would force a module dependency (or a
  hand-rolled parser) into every stamped repo. JSON parses natively in pwsh, Python, node, `jq`.

## Decision

1. **Volatile shared facts live once, in `docs/STATE.json`** — statuses, live resources, counts,
   sizes, each with an `as_of` date. Values are strings, so rendering is byte-deterministic.
2. **Docs render facts via marker-delimited state blocks** (`<!-- state:begin keys=... -->` /
   `<!-- state:end -->`) in `README.md` and `docs/**/*.md`, rewritten only by
   `scripts/check-docs.ps1 -Update` — never by hand.
3. **A deterministic pwsh 7 check script enforces it** (per ADR-0005's cross-platform pwsh rule
   for stamped executable content): blocks match the state file, no stale or future `as_of`
   (default 14 days, per-fact override, `0` = never stale), no superseded-content markers in the
   runbook, one table-separator style. A `docs.yml` workflow runs it in CI.
4. **The runbook is current-state-only**: replaced content is deleted (git keeps history), dated
   journal prose goes to `CHANGELOG.md`, and formatting follows the new `doc-style.md` (which
   applies to all repos, not just living-docs ones).
5. **Packaged as an opt-in `/new-repo` add-on** (`templates/addons/living-docs/core/**`) — a
   third, orthogonal axis beside type and tier, because operational state is independent of both.
   Add-ons only add files, so the type-x-tier collision rules are untouched. Deliberate
   exception: the add-on ships its CI workflow at the **core** tier even though CI is normally
   Public-tier ceremony — deterministic enforcement is the add-on's entire point, especially in
   private repos, where the motivating failure happened.

## Consequences

- Cross-file drift becomes structurally impossible for facts in the state file: they render from
  one source, and CI fails when a block is out of date, a fact goes stale, or superseded prose
  survives — independent of which model or session made the change.
- Stamped living-docs repos carry a small tooling footprint (one script, one workflow, one JSON
  file) and require pwsh 7 to refresh blocks; the staleness check deliberately fails CI until a
  human re-confirms an aged fact — a forcing function, not a bug.
- Facts not lifted into `STATE.json` are still unguarded; the checklists and `living-docs.md`
  push toward lifting anything two docs both state.
- `scripts/smoke_test_living_docs.ps1` proves the enforcement in this repo's CI, negative tests
  included (drifted block, stale date, superseded marker, malformed separator must each fail).
