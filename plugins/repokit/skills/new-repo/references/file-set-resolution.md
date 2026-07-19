# File-set resolution

How `/new-repo` decides exactly which templates to stamp for a given **type × visibility**.

## The rule

```
active_tiers = [core]
             + ([public]    if visibility in {public, published})
             + ([published] if visibility == published)

file_set = ⋃ over t in active_tiers of:
             templates/<t>/**                       (base tier)
           ⋃ templates/types/<type>/<t>/**          (type overlay for that tier)
```

So visibility decides **how many tiers** turn on; the type contributes an overlay **at each
active tier**. A `private` repo gets only `core` (base + type-core). A `published` repo gets all
three base tiers plus all three type-overlay tiers.

## Add-ons — orthogonal to type and tier

An **add-on** is an opt-in overlay chosen in the interview (currently only `living-docs`). For
each chosen add-on:

```
file_set ∪= templates/addons/<addon>/<t>/**   for each active tier t
```

Add-ons **only add files** — an add-on template must never produce a target path that a base or
type template also produces, so add-ons need no precedence rule. (If you ever author one that
collides, that's a bug in the add-on, not a resolution question.)

Deliberate exception to "CI ships at the Public tier": the `living-docs` add-on ships its
`docs.yml` check workflow at **core**, because deterministic doc-consistency enforcement is the
add-on's entire point — including, especially, in a private repo (see ADR-0006).

## Precedence — higher tier wins, then type overlay wins

If the same target path is produced by more than one template, pick a single winner (you never
merge two templates by hand):

1. **Higher tier wins:** `published` > `public` > `core`. So the Public-tier `CONTRIBUTING.md`
   overrides the Core-tier one when a repo is public.
2. **Within the same tier, the type overlay wins** over the base. So
   `types/powershell-module/core/README.md` overrides `core/README.md`, and the type's Public-tier
   CI overrides any base Public-tier CI.

## Naming conventions

- `.tmpl` suffix → the file contains `{{placeholders}}`; **drop the suffix** on write and
  substitute the contents.
- No `.tmpl` suffix → copy **verbatim** (e.g. `.gitignore`, `.editorconfig`, a PR template).
- A placeholder in a **filename** (e.g. `{{ModuleName}}.psd1.tmpl`) is substituted in the **target
  path** (→ `MyModule.psd1`).
- Directory structure under a tier is preserved relative to the new repo root (e.g.
  `public/.github/workflows/ci.yml.tmpl` → `.github/workflows/ci.yml`).

## Worked example — `published` + `powershell-module`, ModuleName `MyModule`

`active_tiers = [core, public, published]`. Union of:

- `templates/core/**` → `AGENTS.md`, `CLAUDE.md`, `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`,
  `.gitignore`, `.editorconfig`, `.gitattributes`, `docs/adr/0000-template.md`,
  `docs/CHECKPOINT.md`, `scripts/repokit-check.ps1`
- `templates/types/powershell-module/core/**` → `MyModule.psd1`, `MyModule.psm1`,
  `Public/.gitkeep`, `Private/.gitkeep`, `Tests/MyModule.Tests.ps1`, **`README.md`** *(overrides
  the base README — type wins)*
- `templates/public/**` → `LICENSE`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`
  *(external variant — overrides core's, higher tier wins)*, `.github/PULL_REQUEST_TEMPLATE.md`,
  `.github/ISSUE_TEMPLATE/*`. (No base CI — CI ships in the type overlay.)
- `templates/types/powershell-module/public/**` → `.github/workflows/ci.yml` *(the
  PSScriptAnalyzer + Pester workflow)*
- `templates/published/**` → `release-please-config.json`, `.release-please-manifest.json`,
  `.github/workflows/release.yml`, `.github/workflows/publish.yml`
- `templates/types/powershell-module/published/**` → `release-please-config.json` *(overrides — has
  the `.psd1` in `extra-files`)*, `.github/workflows/publish.yml` *(overrides — `Publish-PSResource`)*

A `private` + `script-collection` repo, by contrast, resolves to just `templates/core/**`
(plus the `script-collection` core overlay once that stub is filled in) — genuinely lightweight.
