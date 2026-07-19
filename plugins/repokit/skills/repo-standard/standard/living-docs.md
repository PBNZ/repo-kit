# Living docs — current-state documentation without drift

An **opt-in** pattern for repos whose docs track live operational state: deployed resources,
running jobs, migration progress, milestone status. `/new-repo` offers it as the *living-docs
add-on*; an existing repo can adopt it with the recipe at the bottom.

## The failure modes it prevents

Docs that describe a changing system, edited across many sessions and models, reliably develop:

- **Cross-file drift** — the runbook is updated, the README's status table isn't. Prose rules
  ("update both in the same commit") don't hold: they depend on every session's judgment.
- **State accretion** — superseded content is annotated ("superseded by v2") instead of deleted,
  until three versions of reality coexist and the reader can't tell which is current.
- **Contradictions** — the same count or size appears in several places with different values,
  because each was updated at a different time.
- **Stale checkpoints** — "checked this morning, due later today" prose that is wrong the day
  after it's written.

The fix is structural, not disciplinary: **every volatile fact lives in exactly one place**, docs
render it from there, and a deterministic script — not model judgment — enforces it.

## The pattern, in three parts

1. **`docs/STATE.json`** — the single source of truth for volatile shared facts.
2. **State blocks** — marker-delimited regions in `README.md` and `docs/**/*.md` whose contents
   are machine-rendered from `STATE.json`.
3. **`scripts/check-docs.ps1`** — renders the blocks (`-Update`) and verifies everything
   (default mode); a `docs.yml` workflow runs the check in CI.

## `docs/STATE.json`

```json
{
  "stale_after_days": 14,
  "facts": {
    "overall_status": {
      "value": "PLANNED",
      "as_of": "2026-07-13",
      "note": "Overall project status"
    },
    "live_resources": {
      "value": "none yet",
      "as_of": "2026-07-13",
      "note": "Deployed resources",
      "stale_after_days": 0
    }
  }
}
```

Rules:

- A **fact** is anything two docs might both state, or that changes as the system changes:
  statuses, live resources, counts, sizes, wave/task tallies. If you'd have to update it in two
  places — or re-check it to trust it — it belongs here.
- `value` is a **string** (put units inside it: `"3.2 GB"`, `"43,229 folders"`). Strings keep
  rendering byte-deterministic across platforms and locales.
- `as_of` is the `YYYY-MM-DD` date the value was last confirmed true. Updating a value means
  updating its `as_of`.
- `stale_after_days` at the top level is the repo default; a per-fact `stale_after_days`
  overrides it, and `0` means the fact is never considered stale (for genuinely fixed facts,
  e.g. a region or an account id).
- `note` is the human label a rendered table shows; keep it short.

## State blocks

Two forms, both closed by `<!-- state:end -->`, markers each on their own line:

**Table block** — renders the listed facts as a table:

```markdown
<!-- state:begin keys=overall_status,live_resources -->
| Fact | Value | As of |
|---|---|---|
| Overall project status | PLANNED | 2026-07-13 |
| Deployed resources | none yet | 2026-07-13 |
<!-- state:end -->
```

**Inline block** — renders one fact as `value (as of date)` on a single line:

```markdown
<!-- state:begin key=overall_status -->
PLANNED (as of 2026-07-13)
<!-- state:end -->
```

The table's *Fact* column shows the fact's `note` (falling back to the key). Never edit the
content between markers by hand — edit `STATE.json` and run the script with `-Update`.

## `scripts/check-docs.ps1`

Requires pwsh 7. Scans `README.md` and `docs/**/*.md`; no configuration.

- `pwsh scripts/check-docs.ps1` — **check mode** (CI runs this). Exit 1 if any of:
  1. a state block's content doesn't match what `STATE.json` renders, or references an unknown key;
  2. a fact's `as_of` is in the future, or older than its effective `stale_after_days`;
  3. `docs/RUNBOOK.md` contains a superseded-content marker (`superseded`, `obsolete`,
     `no longer current`) — superseded content must be deleted, not annotated;
  4. a markdown table separator row doesn't start and end with `|` (the doc-style table rule).
- `pwsh scripts/check-docs.ps1 -Update` — rewrites every state block from `STATE.json`, then
  runs the same checks (staleness etc. still fail; only block content is auto-fixed).

## Runbook rules (`docs/RUNBOOK.md`)

- **Current state only.** The runbook answers "how does it work *now* and how do I operate it" —
  never "how did we get here".
- **Delete superseded content** — git keeps history. No "superseded by v2" sections, no
  before/after duplicates.
- **Dated journal entries go to `CHANGELOG.md`** (or stay in commit messages), never the runbook.
  At most one as-of date per section — and prefer a state block over a hand-written date.
- **Structure changes are their own commit** (see [`doc-style.md`](doc-style.md)).
- Follow [`doc-style.md`](doc-style.md) throughout — one table style, fixed status words,
  ISO dates.

## When a freshness gate goes red, fix the doc — never widen the gate

A failing staleness check means a fact is no longer confirmed true — the correct response is to
re-confirm the fact and update its `as_of` (or its value). Raising `stale_after_days`, setting it
to `0`, or loosening any check to make CI green converts the failure into permanent silent
drift — the exact failure mode this pattern exists to prevent. Widen a gate only when the *fact's
nature* changed (it became genuinely fixed, e.g. a region id), and say so in the commit message.

## Docs move together

If a commit changes anything a doc states — status, resources, counts, dates — update
`docs/STATE.json` **in the same commit**, run `pwsh scripts/check-docs.ps1 -Update`, and commit
the re-rendered blocks with it. The pre-commit checklist has this as a step; CI enforces it.

## Adopting in an existing repo

1. Copy in the three add-on files from RepoKit
   (`plugins/repokit/skills/new-repo/templates/addons/living-docs/core/`):
   `scripts/check-docs.ps1`, `.github/workflows/docs.yml`, and a seed `docs/STATE.json`
   (drop the `.tmpl` suffix and fill the placeholders).
2. **Inventory the volatile facts** across README and every doc: statuses, live resources,
   counts, sizes, dates. Where two docs disagree, determine the current true value (say from
   which source) and record it once in `STATE.json` with today's `as_of`.
3. **Rewrite the runbook to current-state-only**: delete superseded versions and before/after
   duplicates, move dated journal prose to `CHANGELOG.md` or delete it, normalise tables to
   [`doc-style.md`](doc-style.md), and replace inline volatile facts with state blocks.
4. Add a state block to the README's status section; add the living-docs ground rules to
   `AGENTS.md` (see the add-on's `references/living-docs-rules.md` for the canonical wording).
5. Run `pwsh scripts/check-docs.ps1 -Update`, then the plain check — it must pass.
6. Keep the restructure commit separate from fact-correction commits.
