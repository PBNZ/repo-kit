# ADR-0010: "(planned)" START-HERE paths — declare layout before it exists

- **Status:** accepted
- **Date:** 2026-08-13

## Context

Field report #31: `the-standard.md` prescribes not pre-creating empty directories ("directories
are created when first populated"), but `repokit-check.ps1` asserts that every path-like token
in the START-HERE map resolves. A row declaring a monorepo's planned component layout
(`firmware/`, `app/`) therefore failed the self-check — following one rule broke the other. The
observed workaround (rewording the row to avoid path-like tokens) hid useful, greppable path
names from the map.

## Decision

A per-token marker, not a per-row or label-allowlist rule: a backticked token immediately
followed by `(planned)` is skipped by the self-check's existence assertion. Chosen over the
issue's alternative (only asserting rows whose label is in the known required set) because that
would silently stop checking *every* documentation row — the existence check on declared paths
is most of the self-check's value, and the marker keeps it on by default with an explicit,
visible opt-out per token. The marker covers only the token it follows, so one planned entry
cannot mask an unrelated broken path in the same row. Documented in the standard's *Variance
declarations* (as *Planned paths*), covered by two smoke cases (pass without the directory;
unmarked broken path beside a planned one still fails).

## Consequences

Planned layout is declarable in the map with real path tokens, and the check stays honest: an
existing-path claim is still verified everywhere the marker is absent. The marker is trust-based
— nothing forces its removal when the path becomes real; a stale `(planned)` on an existing path
merely skips a check that would pass, so the failure mode is benign.
