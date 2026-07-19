# Labels — a layered scheme for issues and PRs

Cross-repo boards need a consistent label vocabulary; repos that barely use issues need zero
ceremony. The scheme is **layered and opt-in**: every repo keeps the base layer, and adopts a
namespace only when it needs it. A solo private repo running GitHub defaults untouched is fully
compliant.

## Layer 0 — GitHub defaults (every repo)

Keep the stock labels (`bug`, `enhancement`, `documentation`, `question`, `duplicate`,
`good first issue`, `help wanted`, `invalid`, `wontfix`). They cost nothing and external
contributors already know them. Don't delete or recolour them.

## Namespaces (adopt only what the repo needs)

The **namespace** is standard; the values after the `:` are local to the repo. Fixed colour per
namespace so labels read the same on every board.

| Namespace | Colour | Meaning |
|---|---|---|
| `area:<topic>` | `#1d76db` (blue) | repo-defined functional area (`area:scaffold`, `area:ci`) |
| `agent:<name>` | `#8250df` (purple) | work authored or currently held by an AI agent (`agent:claude`) |
| `campaign:<name>` | `#fbca04` (yellow) | a time-boxed cross-cutting effort (an audit's follow-up batch) — sweepable in one filter |

## Workflow verdicts (board-driven repos)

Flat labels, defined **here and only here** — board/collaboration docs reference these semantics
rather than redefining them (see [`agent-collaboration.md`](agent-collaboration.md)):

| Label | Colour | Meaning |
|---|---|---|
| `rework` | `#d93f0b` (orange) | implementation failed review — back to the implementer, spec stands |
| `needs-respec` | `#e99695` (rose) | the spec itself was wrong — back to the backlog for re-specification |
| `blocked` | `#b60205` (red) | cannot proceed; the blocking dependency is named in a comment |

## Bootstrap

Apply to a new or existing repo (idempotent — `--force` updates colour/description on existing
labels; defaults are left untouched):

```bash
gh label create "rework"      --color d93f0b --description "Implementation failed review; spec stands" --force
gh label create "needs-respec" --color e99695 --description "Spec was wrong; back to backlog" --force
gh label create "blocked"     --color b60205 --description "Cannot proceed; blocker named in a comment" --force
# per adopted namespace, create the values the repo needs, e.g.:
gh label create "area:scaffold" --color 1d76db --force
gh label create "agent:claude"  --color 8250df --force
```

To copy a repo's full label set into another repo instead: `gh label clone <source-repo>`.

`/new-repo` offers the workflow-verdict set when it creates a remote; a repo that never runs a
board simply skips it.
