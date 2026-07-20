# ADR-0008: Board-commissioning batch — adopt all three field-report findings

- **Status:** accepted
- **Date:** 2026-07-20

## Context

An agent-run project-board commissioning (private repo, 2026-07-20) produced three field
reports against the standard (issues #21–#23): a documented landmine that was overstated and
therefore blocked a safe operation, a correct rule that was buried inside one pattern and so
fired only there, and a gap — the standard said nothing about what an agent owes the human when
commissioning leaves steps only a human can perform. As with the retrospective batch (ADR-0007),
the triage options per issue were accept, adapt, or decline.

## Decision

Accept all three, landed as one batch (one commit per issue, `Refs #NN`):

- **#23** The org-migration checklist's status-options landmine is corrected: the failure is
  specific to an **id-less replacement**, not to any API edit.
  `ProjectV2SingleSelectFieldOptionInput` accepts an optional `id` (re-verified against the
  live GraphQL schema at adoption time, on top of the issue's 75-item live-board evidence);
  echoing ids for kept/renamed options preserves built-in workflows and item values. Rewritten
  in the checklist's symptom → cause → fix form with the verification step included.
- **#22** The links-not-code-formatting rule moves from an Option B aside in
  `agent-collaboration.md` to a deterministic **Links** section in `doc-style.md`: the
  paste-this/go-here test, scope explicitly including the agent's own chat output, and a
  construction table for the chat/cross-repo cases where `#NN` and relative links silently
  fail. `agent-collaboration.md` references it, the pre-PR checklist gains a links-resolve
  item, and the scaffolded `AGENTS.md` names the chat-output half — a behaviour an agent must
  be told, not a file it can lint.
- **#21** `agent-collaboration.md` gains a **Commissioning handoff** section: when an agent
  commissions shared infrastructure, exactly one assigned, checkboxed issue in the
  review/verify column owns the manual residue, opened before the work is reported done; each
  step names why it is manual (*no API*, *permission/scope withheld*, *plan-gated*,
  *interactive auth*, *deliberately human*) because the reason expires and must be
  re-evaluable. The session-end checklist gains the matching tripwire, and the org-migration
  board-rebuild checklist routes its click-through to the handoff issue. The known
  project-board residue is listed in the section so the handoff issue is generated, not
  remembered.

Issues are **not** auto-closed — the human verifies each after merge (#14's rule).

## Consequences

The standard now permits an operation it previously forbade in effect (API edits to a
Project's status options), with the safety condition stated instead of the operation banned.
Two behavioural rules bind agent chat output — linking and residue handoff — which no linter
can enforce; they live in the docs an agent loads (`doc-style.md`, `agent-collaboration.md`,
the scaffolded `AGENTS.md`) and in the session-end/pre-PR tripwires. No new required
artifacts; the reference set grows by zero docs.
