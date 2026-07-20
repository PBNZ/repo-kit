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

## Links — code formatting means "paste this", a link means "go here"

Code-format only genuine paste-material (commands, literal values, identifiers with no
destination — an ARN, a hash, an option id). Everything navigable — repos, boards, issues, PRs,
files, milestones, releases, workflow runs — is a markdown link. Anything the reader might want
to open, they should be able to click.

**Scope:** docs, issue and PR bodies, review comments, ADRs, release notes — **and the agent's
own chat/session output to the human**. A closing report that names a board, six issues, and
five changed files as code-formatted text forces the human to copy-paste identifiers into a
browser to reach their own artifacts.

The correct construction depends on where the text will be read:

| Referring to | In a repo-hosted file or issue body | In chat output, or cross-repo |
|---|---|---|
| An issue or PR | `#12` (autolinks) | `[owner/repo#12](https://github.com/owner/repo/issues/12)` |
| A file in this repo | relative link: `[docs/RUNBOOK.md](docs/RUNBOOK.md)` | blob URL pinned to a ref |
| A board, milestone, release, workflow run | markdown link (full URL) | markdown link (full URL) |
| A command, literal value, or destination-less identifier | code formatting | code formatting |

Why the split matters: `#12` autolinks only inside its own repo — it is dead text in a chat
transcript and ambiguous cross-repo. A relative link resolves in a repo-hosted markdown file and
in an issue body, but not in chat, a release note, or an email. A file link that must keep
meaning after the branch moves needs a ref-pinned blob URL.

- A path that is both openable and paste-material is a link whose text is the code-formatted
  path: `` [`docs/RUNBOOK.md`](docs/RUNBOOK.md) ``.
- Counter-case — this is not a link-spam mandate: first mention in a section wins; don't
  re-link the same artifact on every mention.

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
