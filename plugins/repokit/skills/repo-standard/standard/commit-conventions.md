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
