# ADR-0003: `power-platform-connectors` repo type

- **Status:** accepted
- **Date:** 2026-07-04

## Context

We needed a repo **type** that turns a Postman collection into OpenAPI definitions ready to import
as **Microsoft Power Platform custom connectors**. Verified hard constraints from Microsoft Learn
(*Create a custom connector from an OpenAPI definition*): the definition must be **OpenAPI 2.0 /
Swagger** ("OpenAPI 3.0 format is not supported") and **< 1 MB**, `.json` or `.yaml`, with a single
top security definition (client-credentials OAuth is rejected).

## Decision

- **Converter (free, pinned in Docker):** `postman-to-openapi@3.0.1` outputs OpenAPI **3.0** only,
  so we downconvert with `api-spec-converter@2.12.0` (`--from=openapi_3 --to=swagger_2`). Both are
  unmaintained (2023 / 2021; the latter depends on the deprecated `request`) and do **not** run on
  current Node — the image is pinned to **Node 18**. Do not bump without re-testing. APIMatic (paid,
  direct Postman→2.0) is the documented escape hatch, not built.
- **The downconvert is lossy, so `generate.mjs` normalises the output to valid Swagger 2.0** — this
  was proven empirically (a real public collection failed validation four different ways before the
  fixups): (1) **pre-resolve collection `{{variables}}`** so `host`/`basePath`/`schemes` are real
  instead of `%7B%7Bbaseurl%7D%7D`; (2) **derive `securityDefinitions` from the Postman `auth`**
  block (p2o mis-maps apikey to an invalid `type:http` and drops the header name); (3) **backfill a
  `description` on every response** (required in 2.0; p2o only sets it from the Postman `status`);
  (4) **add missing path parameters and leading `/`** on path keys. The generator then
  **self-validates** each output with `swagger-cli` and asserts **< 1 MB**, exiting non-zero on any
  failure.
- **Split policy:** convert the whole collection to one definition; ship one file if it's < 1 MB;
  otherwise split **per top-level folder** (each carrying the collection `variable`/`auth`); if a
  single folder is still ≥ 1 MB after stripping example fields, **flag it** rather than ship an
  un-importable file.
- **Self-containment / source:** the collection is **committed** (`source/collection.json`), so the
  repo builds with just Docker — no Postman account. **Sync** fetches a **configurable `sourceUrl`**:
  a public URL (GitHub raw / vendor site) is **account-free**; a Postman-platform-only collection
  needs the maintainer's optional `POSTMAN_API_KEY` secret (never needed by cloners). Postman has no
  reliable anonymous fetch for a collection you don't own (public JSON links are deprecated).
- **Change detection = scheduled workflow + hash:** `sync.yml` (daily cron + dispatch) canonicalises
  the fetched collection, SHA-256s it, compares to `.postman/manifest.json`, and on a change updates
  the snapshot, regenerates, **validates inline**, and opens a PR. Validation is inline because a PR
  opened by the default `GITHUB_TOKEN` does not trigger `ci.yml`. This needs
  `permissions: pull-requests: write` and the repo setting *Allow GitHub Actions to create and
  approve pull requests*.
- **Tier: Core + Public, no Published** (like `docker-compose`) — "publishing" is manually importing
  a definition into Power Platform; there is no registry step to automate.

## Consequences

- The conversion is lossy — the pipeline validates and opens a **PR to review**; it never
  auto-imports. Richer collections (saved example responses, one clear auth scheme) produce better
  connectors.
- The toolchain is stale but pinned in Docker; if a future Node breaks it, the pin holds.
- Auto-sync is account-free for public-URL sources; Postman-platform-only collections need the
  maintainer's optional key.
