# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- A `docker-compose` repo type for `/new-repo`: a minimal `compose.yaml` (named volumes for data,
  committed config, `.env` secrets), `.env.example`, `.dockerignore`, a README with a workflow
  diagram, and a `docker compose config -q` validation CI (Public tier).

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
