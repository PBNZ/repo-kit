# ADR-0004: Going public, and distribution via two marketplaces

- **Status:** accepted
- **Date:** 2026-07-06

## Context

RepoKit was built private-first (ADR-0001) and has reached the point of being useful beyond its
author: three built-out types, a dogfooded standard, green CI, and a first real-world scaffold
test behind it. Going public raised two distribution questions:

1. **Where do people install from?** RepoKit ships its own self-contained marketplace
   (ADR-0001 D1) — but PBNZ also operates [`pbnz-skills`](https://github.com/PBNZ/pbnz-skills),
   a public marketplace repo that currently lists nothing (its only plugin, Newton, moved to a
   dedicated repo, and its README declared "one repo per plugin, not back here").
2. **What does "ready to be public" require?** The repo already dogfoods the Public tier
   (LICENSE, SECURITY, CoC, PR/issue templates, CI), so the gap was release hygiene (#4) and the
   GitHub-side settings (topics, branch rules, security features).

## Decision

- **Go public with release 0.2.0**, clearing the release-hygiene backlog (#4): retroactive tag
  `v0.1.0` on the commit that declared 0.1.0, `v0.2.0` on the release commit, matching GitHub
  releases, and versions bumped in `plugin.json` + `marketplace.json`.
- **This repo stays the canonical home and marketplace.** The primary install is
  `/plugin marketplace add PBNZ/repo-kit`.
- **Also list the plugin in `PBNZ/pbnz-skills` as a reference**, using a `git-subdir` marketplace
  source pointing at `plugins/repokit` in this repo. This is a listing, not a copy: no plugin
  content is duplicated into pbnz-skills, so the maintained-in-two-places failure that prompted
  pbnz-skills' one-repo-per-plugin rule cannot recur. pbnz-skills becomes a directory of PBNZ
  plugins whose canonical homes are their own repos.

## Consequences

- "Publish" remains bump + tag + push (ADR-0001 D1). The pbnz-skills listing is a second
  discovery channel that needs **no per-release maintenance** — the reference entry carries no
  version pin, so installs always fetch the current tagged content from this repo.
- pbnz-skills' README/policy is amended in that repo (reference listings welcome;
  content-carrying plugins still live in their own repos).
- This repo must remain public for either channel to work; flipping visibility is the release
  act, done by the maintainer.
