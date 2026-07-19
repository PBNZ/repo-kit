# Fleet — conventions for multi-repo projects (hub-and-spoke)

Everything else in this standard lives and terminates inside one repository. The moment a
product spans a second repo, the cross-repo layer needs conventions of its own — this reference
defines them. A *fleet* is the set of repos serving one venture; it has exactly one **hub** and
any number of **spokes**.

## When to split

A repo earns its existence by having its **own deployable or its own audience** (an app that
ships separately, an infra repo with different access, a public component of a private product).
Don't split for tidiness — every extra repo costs a clone, a board column filter, and a
placement decision forever after.

## The hub

One coordination repo owns everything that spans repos:

- the working agreement and fleet-level agent file,
- cross-cutting ADRs and venture-level documents,
- cross-repo issues,
- the fleet's project board (org-owned; items from personal-account repos sit on an org project
  fine).

The hub's `AGENTS.md` **declares itself the router**: any placement or lookup question a spoke
can't answer resolves at the hub. Structurally the hub is the **fleet-hub profile** of the
`collection` type — a docs-only collection plus the router role.

## The scope test (verbatim in every fleet)

> **Would this still matter if the repo you're sitting in didn't exist? Yes → hub; no → stays
> here.**

One sentence, written into every spoke's `AGENTS.md`, settling every placement question for
docs *and* issues.

## Sibling clones

All fleet repos clone as sibling directories, so the hub is always at a fixed relative path
(`../<hub-name>/`) from any spoke — agents know where to look on disk, and clone it there if
it's missing.

## Spoke inheritance — three lines

A spoke joins the fleet by adding three lines to its `AGENTS.md` ground rules (no other ongoing
cost):

```markdown
- **Fleet:** this repo is a spoke of `<owner>/<hub-name>` — placement/lookup questions this
  repo can't answer resolve there. Clone it as a sibling: `../<hub-name>/`.
- **Scope test:** would this still matter if the repo you're sitting in didn't exist?
  Yes → hub; no → stays here.
- **Board:** fleet work runs on the hub's project board — see the hub's `AGENTS.md` and the
  `repo-standard` skill's `standard/agent-collaboration.md`.
```

## Docs follow ownership, with pointer stubs

When a doc turns out to be venture-level, it **moves to the hub**, and a short stub stays at
the old path so existing links (issues, commits) keep resolving:

```markdown
# <Title> — moved

This document is venture-level and now lives in the hub:
<link to the hub copy>. Pre-move git history stays in this repo.
```

## Fleet-wide consistency

- **Labels:** every fleet repo carries the identical label set, so the shared board filters
  uniformly — bootstrap per [`labels.md`](labels.md) (`gh label clone <hub>` from each spoke).
- **Board discipline:** one board, fleet-wide pickup/handoff loop — see
  [`agent-collaboration.md`](agent-collaboration.md).
- **Compliance:** each fleet repo passes its own `scripts/repokit-check.ps1`; the fleet rows
  above are ordinary START-HERE/ground-rule content, nothing new to check.
