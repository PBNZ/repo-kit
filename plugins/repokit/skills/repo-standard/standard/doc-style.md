# Documentation style — one voice across sessions and models

A repo's docs accumulate edits from different agents, sessions, and models. Left to taste, each
author formats slightly differently and the file degrades into a patchwork (two table styles, three
date formats, ad-hoc status labels). These rules are deliberately **deterministic** — given the
same content, any author produces the same bytes — so formatting stops drifting and diffs stay
about content.

## Tables — one style

- Every row **starts and ends with `|`**, including the separator row.
- Separator cells are dashes only, three or more: `|---|---|`. Add `:` only when you genuinely
  need alignment.
- Single space padding inside cells: `| like this |`.
- **Do not pad cells to visually align columns.** Alignment padding forces whole-table rewrites on
  every edit, and each model re-aligns differently — it is the single biggest source of table
  churn.
- No blank lines inside a table.

## Dates

- Data values (tables, status lines, "as of" stamps) are always ISO **`YYYY-MM-DD`**.
- Never write relative dates into a doc ("yesterday", "later today") — they are wrong by the time
  they are read.

## Status vocabulary — fixed words

Use exactly these words, uppercase; don't invent synonyms ("WIP", "pending", "live") and don't
substitute emoji for them:

| Status | Use for |
|---|---|
| `PLANNED` / `IN PROGRESS` / `BLOCKED` / `DONE` | work items, milestones |
| `OK` / `DEGRADED` / `DOWN` | operational health of a running thing |

## Headings

- One `#` title per file; sections are `##`, subsections `###`; never skip a level.
- Sentence case ("## Where things live", not "## Where Things Live").

## Structure changes are their own commit

Never restructure or reformat a doc as a side effect of a content change. If a doc has outgrown
its structure, do the restructure in a dedicated `docs:` commit that changes **no facts** — a
reviewer must be able to trust that a structure diff contains no content edits, and vice versa.

## Prose

- Docs describe **current state in present tense**. History belongs in `CHANGELOG.md` and git —
  see [`living-docs.md`](living-docs.md) for the full current-state-only discipline.
