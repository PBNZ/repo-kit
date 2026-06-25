# ADR-0002: a `docker-compose` type for /new-repo

- **Status:** accepted
- **Date:** 2026-06-26

## Context

`/new-repo` could scaffold the standard shell for any repo, but had no real overlay for a
multi-container Docker Compose project — the `app-*` types were stubs. A concrete need came up
(a local-first private stack of prebuilt-image services), so a reusable `docker-compose` type is
worth adding rather than hand-rolling the boilerplate each time.

## Decision

Add a minimal, generic `docker-compose` type (`templates/types/docker-compose/`):

- **core:** `compose.yaml` (no obsolete `version:`; two example `image:` services; a named volume
  for persistent data; commented config-bind-mount and `build:` patterns), `.env.example`,
  `.dockerignore`, and a README with a workflow diagram.
- **public:** a CI workflow that runs `docker compose config -q` to validate the file.
- **Conventions:** config is committed; persistent data uses **named volumes** (outside the repo)
  or a gitignored local dir if bind-mounted; secrets live in `.env` (gitignored), with
  `.env.example` committed. The type adds no `.gitignore` of its own (that would replace the base);
  `.env` handling is added to the base `core/.gitignore` instead.
- Modern Compose facts (verified at docs.docker.com): canonical file name `compose.yaml`; the
  top-level `version:` is obsolete; `docker compose config -q` validates.

## Consequences

- `new-repo type=docker-compose` produces a valid, runnable compose skeleton at Core/private (the
  common case); the example `app`/`db` services are replaced per project.
- **No `published/` overlay:** a compose app has no generic registry-publish step. A `published`-tier
  docker-compose repo would inherit the base published release-please files, which don't fit — revisit
  only if a real need appears.
