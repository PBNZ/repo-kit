# Agent collaboration — humans and agents on a shared board

Rules for any repo where humans pair with AI agents on shared issues and a project board. Every
rule here was invented mid-project *after* its failure mode occurred somewhere; adopting them up
front is the point. Verdict-label semantics (`rework`, `needs-respec`, `blocked`) are defined in
[`labels.md`](labels.md) — this doc uses them, it doesn't redefine them.

## The real-time board rule

**A card moves at the moment the work state changes — never at session end.** Batching board
moves to wrap-up is a named anti-pattern: it makes a live board lie for hours while work is
actually in progress, and everyone reading the board plans against the lie. Treat a card move
like a lock acquisition, not like paperwork.

## The pickup/handoff loop

The default protocol for working a card:

1. **Pickup** — assign yourself the moment you take the card. An unassigned In-Progress card is
   a protocol violation.
2. **Start** — move it to *In Progress* when work actually starts, not when you plan to start.
3. **Complete** — on the completing commit/PR: move the card to the review column and
   **unassign yourself**.
4. Semantics that follow: **unassigned in review = shipped, awaiting human verification.** The
   verifier closes (see the closing-keyword rule in
   [`commit-conventions.md`](commit-conventions.md)) or applies `rework` / `needs-respec` and
   sends it back.

## Signatures on agent output

Agent-authored issues, comments, and reviews end with a signature so provenance is never
ambiguous:

```text
— 🤖 <agent>, on behalf of @<human-handle>
```

**Documented limitation:** timeline events (card moves, label changes, assignments) can't carry
a signature — they appear as the human whose token acted. The eventual fix is a dedicated
machine account; until then, accept the gap knowingly.

## Session preflight

Before any board-driven work — 30 seconds that prevents a session dying at its final step:

- [ ] **Auth + scopes:** the CLI token covers everything this session will write — issues,
  project/board mutations, labels (`gh auth status`; a project-board session needs the
  `project` scope, not just `repo`).
- [ ] **Agent files load:** the canonical agent file exists *and* the thin shim the tooling
  actually reads exists and imports it (`CLAUDE.md` containing `@AGENTS.md`) — structurally
  present but functionally dead files are a known failure. `scripts/repokit-check.ps1` verifies
  this mechanically.
- [ ] **Board matches reality** for the cards you're about to touch.

Only then pick up a card.
