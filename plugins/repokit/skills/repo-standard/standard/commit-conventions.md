# Commit, changelog & version conventions

## Conventional Commits

Format: `type(optional scope): summary`. Common types:

| Type | Use for | SemVer effect |
|------|---------|---------------|
| `feat` | a new user-visible capability | minor |
| `fix` | a bug fix | patch |
| `docs` | documentation only | — |
| `refactor` | code change that neither fixes a bug nor adds a feature | — |
| `test` | adding or fixing tests | — |
| `perf` | a performance improvement | patch |
| `build` | build system / dependencies | — |
| `ci` | CI configuration | — |
| `chore` | maintenance, scaffolding, releases | — |

Examples:

```text
feat(new-repo): add the powershell-module type overlay
fix: stop the self-check flagging GitHub Actions ${{ }} expressions
docs: explain the type x tier model in the standard
chore: scaffold my-tool via RepoKit
```

**Breaking changes:** append `!` after the type/scope (`feat!: …`) or add a `BREAKING CHANGE:`
footer. A breaking change bumps the **major** version.

## SemVer

`MAJOR.MINOR.PATCH` per [semver.org](https://semver.org/spec/v2.0.0.html): breaking → MAJOR,
new feature → MINOR, fix → PATCH.

## Keep a Changelog

Maintain `CHANGELOG.md` in the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.
Add user-visible changes under `## [Unreleased]` as you go; on release, rename that section to the
new version with the date and start a fresh `## [Unreleased]`.

## When to cut a release

`[Unreleased]` is a staging area, not a terminal state — a changelog whose entire history sits
there stops answering "what's new". Cut a version the **first** time any of these happens:

1. **An artifact leaves the repo** — deployed, published, installed on a second machine, or
   handed to anyone else.
2. **A version number is stamped into any output** (a manifest, a UI footer, a generated file).
3. **A tag pipeline exists and has never fired** — release machinery you built but never
   triggered is the strongest signal you're overdue.

The pre-PR checklist carries the tripwire: if `[Unreleased]` describes more than one shippable
unit, cut before it grows further.

**Declared variant — never-versioned repos** (internal ops repos with nothing to version): use
**dated entries** instead of versions — `## 2026-07-19` sections in Keep-a-Changelog style —
and declare the variant in the START-HERE map so it reads as a choice, not neglect.

Optional CI nudge (warn, not fail — copy into any workflow):

```yaml
- name: Warn when [Unreleased] gets fat
  shell: bash
  run: |
    n=$(awk '/^## \[Unreleased\]/{f=1;next} /^## /{f=0} f&&/^- /{c++} END{print c+0}' CHANGELOG.md)
    if [ "$n" -gt 10 ]; then
      echo "::warning::CHANGELOG.md [Unreleased] holds $n entries - time to cut a release?"
    fi
```

## Releasing

- **Registry-backed repos** (PSGallery, npm): `release-please` reads your Conventional Commits,
  opens a **release PR** that bumps the version and updates the changelog. You approve it; it tags
  and triggers the gated publish workflow. The version line in the manifest carries a
  `# x-release-please-version` annotation so release-please can bump it.
- **Marketplace-only plugins:** there's no separate registry step, so release automation is
  optional. Bump the version in the manifest(s) + `CHANGELOG.md` by hand, tag, and push.

## Commit identity

Commits use the GitHub **noreply** email (`<id>+<login>@users.noreply.github.com`), set
**repo-locally**, so a repo that goes public never exposes a personal address. Use a real
name/email only when the user explicitly wants it. `/new-repo` sets this on the scaffold commit; keep
it for later commits too.
