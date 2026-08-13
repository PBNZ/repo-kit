# ADR-0011: Early licence — LICENSE (+ NOTICE) at Core when promotion is planned

- **Status:** accepted
- **Date:** 2026-08-13

## Context

Field report #32: the promotion path (private now → public later, "nothing to scrub") is core
RepoKit philosophy, but `LICENSE` ships only at the +Public tier. Two cases want it at commit
one: the public release is already planned, so the licence choice is made and stamping it later
adds a promotion step without adding safety; and third-party licensed material incorporated
while still private, whose attribution belongs in `NOTICE` from the moment the material arrives,
not from the go-public commit. Doing this before required a declared variance (START-HERE row +
ADR) — following the standard's own promotion philosophy required declaring an exception to the
standard.

## Decision

An opt-in interview question in `/new-repo`, offered to private repos only: "Is a public release
already planned?" — yes stamps `LICENSE` from the existing Public-tier template, and a follow-up
("third-party material expected?") additionally stamps a minimal `NOTICE` (name, copyright,
placeholder for attributions; content specified inline in `references/file-set-resolution.md`
rather than as a template, so the Public tier's default file set is unchanged). The choice is
recorded in ADR-0001 automatically. **No variance row**: the standard's *Promotion path* now
states that an early licence on a promotion-planned repo is the promotion path itself, not a
deviation from the Core file set. The default stays **no**, so forever-private repos keep zero
ceremony.

## Consequences

Promotion-planned repos carry their licence from commit #1 and third-party attribution from the
moment it is owed, with one less step (and nothing to scrub) at flip time. The tier model gains
one named, documented exception — a Public-tier template shipping at Core — alongside the
existing living-docs `docs.yml` exception (ADR-0006), both stated in
`references/file-set-resolution.md`. Repos that opt in and then never go public carry a harmless
LICENSE; nothing else changes for them.
