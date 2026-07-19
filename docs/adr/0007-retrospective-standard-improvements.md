# ADR-0007: Retrospective batch — adopt all seven workflow findings into the standard

- **Status:** accepted
- **Date:** 2026-07-19

## Context

A nine-repo retrospective (issue #10) found six recurring breakdown patterns: resume-state docs
decay or never exist, releases are never cut, commit↔issue traceability is near zero, human↔agent
collaboration rules get invented after each failure, repos drift from the standard file set
silently, and there is no labelling standard. Seven improvement issues (#11–#17) were spawned,
each with a concrete proposal. The triage options per issue were accept, adapt, or decline.

## Decision

Accept all seven, landed as one batch (one commit per issue, `Refs #NN`):

- **#11** `standard/labels.md` — layered, opt-in label scheme; defaults-only repos stay
  compliant; workflow-verdict semantics defined there once.
- **#12** Resume state becomes a **required Core artifact** (`docs/CHECKPOINT.md` or a declared
  substitute) with a mandatory START-HERE row, a pre-commit tripwire, and an opt-in CI nudge;
  living-docs gains "fix the doc, never widen the gate".
- **#13** Release-cut triggers in `commit-conventions.md` plus a pre-PR tripwire and a declared
  dated-entries variant for never-versioned repos.
- **#14** `Refs #NN` traceability convention; closing keywords only where merge == done; the
  auto-close CI guard ships as a copy-paste snippet; both PR templates prompt for the ref.
- **#15** `standard/agent-collaboration.md` — real-time board rule, pickup/handoff loop,
  signatures, session preflight; scaffolded `AGENTS.md` references it.
- **#16** Variance declarations (undeclared deviation = non-compliance) + a mechanical
  self-check: `scripts/repokit-check.ps1` stamped at Core, dogfooded by this repo's CI, smoke
  test proving it fails on each observed drift case; adoption marker for retro-adopted repos.
- **#17** `standard/session-end-checklist.md` — six mechanically checkable wrap-up items.

Day-2 addenda, accepted on the same PR:

- **#15 (addenda)** `agent-collaboration.md` gains *Closing force — enumerate the gestures*
  (agents never set a card to Done; gestures with closing/destructive force are listed and
  reserved for humans) and the *three-audience task instructions* pattern.
- **#19** `standard/fleet.md` — hub-and-spoke conventions for multi-repo projects: hub as
  router, the verbatim scope test, sibling clones, three-line spoke inheritance,
  docs-move-with-stub; the hub defined as the fleet-hub profile of the `collection` type.
- **#20** `standard/org-migration-checklist.md` — the six verified platform landmines of a
  personal-account → org migration, phased, with GitHub-docs citations for the plan-dependent
  limits (re-verified 2026-07-20).

Adaptations: the optional CI checks in #12/#13 ship as documented opt-in snippets rather than
scaffold defaults (warn-level noise shouldn't be mandatory at Core), #11's bootstrap hooks
into the existing opt-in remote-creation step (labels need a remote), and #19's hub scaffolding
waits for the `collection` type stub to be filled in — the profile is documented so `/new-repo`
can offer it then.

Issues are **not** auto-closed — the human verifies each after merge (#14's own rule).

## Consequences

Core gains two required artifacts (`docs/CHECKPOINT.md`, `scripts/repokit-check.ps1`), which is
a deliberate ceremony increase at the lightest tier — justified because the failure it prevents
(unresumable, silently-drifted repos) hits private repos hardest. Existing RepoKit repos are
non-compliant until they add a checkpoint + resume-state row or run the adoption marker;
`repokit-check.ps1` makes the gap visible in seconds. The standard's reference set grows by
three docs; the router (`SKILL.md`) stays the single entry point.
