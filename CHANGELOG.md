# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

### Changed

- The plugin now displays as `repo-kit` in the `/plugin` UI (via `displayName`), matching the marketplace name.
- `/new-repo` now sets a repo-local commit identity using the GitHub noreply email by default (so a new repo doesn't leak a personal address) and initialises the default branch as `main`.

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

[Unreleased]: https://github.com/PBNZ/repo-kit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/PBNZ/repo-kit/releases/tag/v0.1.0
