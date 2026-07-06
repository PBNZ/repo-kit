# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- A cross-platform smoke test for the `powershell-module` templates
  (`scripts/smoke_test_powershell_module.ps1`): stamps the core-tier templates with dummy values
  and verifies the result parses (`Test-ModuleManifest`), imports, lints clean (PSScriptAnalyzer),
  and passes its Pester scaffold. CI runs it with pwsh on `ubuntu-latest`, so the templates are now
  exercised on Linux for every push/PR (ADR-0005).

### Changed

- The `{{Guid}}` placeholder instruction in `/new-repo` is now shell-agnostic (`uuidgen`, pwsh, or
  python) instead of assuming PowerShell is available on the scaffolding host.
- GitHub Actions pinned in this repo's CI and in the bundled workflow templates are bumped off the
  deprecated Node 20 runtime to their latest majors: `actions/checkout@v7`,
  `actions/setup-python@v6`, and `googleapis/release-please-action@v5` (whose only breaking change
  is the Node 24 move — no input changes).

## [0.2.0] - 2026-07-06

### Added

- A `docker-compose` repo type for `/new-repo`: a minimal `compose.yaml` (named volumes for data,
  committed config, `.env` secrets), `.env.example`, `.dockerignore`, a README with a workflow
  diagram, and a `docker compose config -q` validation CI (Public tier).
- A `power-platform-connectors` repo type for `/new-repo`: turns a committed Postman collection
  into **OpenAPI 2.0** custom-connector definitions for Microsoft Power Platform. A pinned-Docker
  generator (`postman-to-openapi` + `api-spec-converter`, normalised to valid Swagger 2.0) splits
  per top-level folder **only when a single definition would exceed the 1 MB limit**, self-validates
  every output, and a scheduled sync workflow opens a PR when the upstream collection changes. The
  collection is committed, so the repo builds with just Docker — no Postman account.
- The `repo-standard` skill now tells agents to check the remote after a push/PR — CI/Actions status and GitHub Copilot / reviewer feedback — before calling work done.
- A `where-things-go.md` placement guide in the `repo-standard` skill: "I have X — where does it
  go, how do I create the place if it's missing, and on what convention?"
- A naming-conventions section in the standard: which casing each convention-bearing file and
  directory follows, and why (match the ecosystem that owns the name).
- `README.md` documents the [`PBNZ/pbnz-skills`](https://github.com/PBNZ/pbnz-skills) marketplace
  listing as an alternative install channel; this repo remains the canonical home (ADR-0004).

### Changed

- The plugin now displays as `repo-kit` in the `/plugin` UI (via `displayName`), matching the marketplace name.
- `/new-repo` now sets a repo-local commit identity using the GitHub noreply email by default (so a new repo doesn't leak a personal address) and initialises the default branch as `main`.
- `category` moved from `plugin.json` to the marketplace entry — Claude Code reads it from the
  marketplace manifest, not the plugin manifest (flagged by `claude plugin validate`).

### Fixed

- Two bundled template files existed only in the author's working tree — a global gitignore
  (`*private*` and env patterns) had silently kept them out of git, so fresh clones and installed
  copies scaffolded incomplete repos: `powershell-module/core/Private/.gitkeep` (#2) and
  `docker-compose/core/.env.example`. Both are now tracked, and the repo's `.gitignore` un-ignores
  everything under the bundled `templates/` tree so this cannot recur.
- The `powershell-module` manifest template now matches the type's modern-PowerShell-only tooling
  (pwsh CI, `Publish-PSResource`): `PowerShellVersion = '7.0'`, `CompatiblePSEditions = @('Core')`,
  plus a hint to add the Gallery's compatibility tags (`PSEdition_Core` + OS tags) before
  publishing (#3).

## [0.1.0] - 2026-06-21

### Added

- Initial RepoKit plugin: the `repokit` plugin shipping the `/new-repo` scaffolder and the
  `repo-standard` skill, in a self-contained marketplace.
- The repo standard (`the-standard.md`) and its commit conventions, pre-commit / pre-PR
  checklists, and testing matrix.
- Templates for the **Core**, **Public**, and **Published** tiers, plus the
  **powershell-module** type overlay. The other types ship as stubs.

[Unreleased]: https://github.com/PBNZ/repo-kit/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/PBNZ/repo-kit/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/PBNZ/repo-kit/releases/tag/v0.1.0
