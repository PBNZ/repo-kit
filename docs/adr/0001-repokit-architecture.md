# ADR-0001: RepoKit architecture and build decisions

- **Status:** accepted
- **Date:** 2026-06-21

## Context

RepoKit is a reusable repo standard + a `/new-repo` scaffolder, shipped as a Claude Code plugin.
It is built from an approved handover spec; this ADR records the architecture decisions and the
resolutions made during the build (where they go beyond, or clarify, the spec).

## Decision

### Shape

- Its own **private-first** repo + a **self-contained marketplace** + one `repokit` plugin
  (the newton-skill pattern). Installed via `/plugin marketplace add PBNZ/repo-kit`.
- `AGENTS.md` is the canonical agent file; a thin `CLAUDE.md` imports it with `@AGENTS.md`
  (Claude Code loads `CLAUDE.md`, not `AGENTS.md`).
- **No cross-tool rule generators** (Claude-Code-only). Conventional Commits + Keep a Changelog +
  SemVer. Default licence **Apache-2.0**.

### Profiles = type × tier

One standard, applied at the right tier. **Core** (every repo) + **Public** + **Published**
layers switch on by visibility; **type** overlays add structure-specific files. Promotion adds
the next layer over the same structure.

### D1 — RepoKit publishes to its own marketplace; release automation is optional

The standard's *Published* layer means "the publish step + version automation appropriate to the
target registry." For a **marketplace-only plugin** the registry *is* the git repo, so "publish"
= bump versions + tag + push, with no upload step, and `release-please` is optional — it can't
cleanly annotate the JSON manifests anyway. RepoKit therefore bumps `plugin.json` /
`marketplace.json` / `CHANGELOG.md` by hand and tags manually — **compliant with its own
standard, not a carve-out**. `release-please` + a registry publish workflow ship only inside the
*published* templates, for targets with an annotatable version line (`.psd1`, npm).

### D2 — Type overlays are themselves tiered

Each type is laid out as `types/<type>/{core,public,published}/`, mirroring the base tiers. The
scaffolder resolves the file set as a mechanical directory union of the active tiers; on a path
collision, the **type overlay wins** (it ships the complete file). This removes per-file merge
judgement from the agent.

### D3 — `gh repo create` is opt-in, private-only

`/new-repo` defaults to local-only (`git init` + first commit). It offers
`gh repo create <name> --private` only on explicit opt-in. It never creates a public repo and
never publishes (stop-at-local-review).

### D4 — Plugin runtime mechanics (verified empirically with a walking skeleton)

- Commands and skills are merged: the plugin skill `skills/new-repo/SKILL.md` is invocable as
  `/repokit:new-repo`, so there is **no separate command file**. `new-repo` carries
  `disable-model-invocation: true` (user-invoked — it writes files and runs `git init`);
  `repo-standard` stays default model-invocable so it auto-triggers when working in a compliant
  repo.
- A skill is handed its **absolute base directory** at load time ("Base directory for this
  skill: …"). It reads its bundled templates as `<base>/templates/…`. `${CLAUDE_PLUGIN_ROOT}`
  does **not** resolve inside a skill's `Read` calls at execution time, so templates and standard
  docs are bundled **inside their skill's directory** and read via the injected base path — not
  from a plugin-root `templates/`.

### D5 — End-user visualisation (Mermaid diagrams baked into outputs)

RepoKit and the repos it stamps must be visually self-explanatory for non-expert end-users.
Diagrams are **pre-authored static template content** (deterministic, reviewed) — the scaffolder
substitutes `{{placeholders}}` *inside* them but never draws diagrams per scaffold. RepoKit's own
`README.md` and `the-standard.md` embed the explainer diagrams; the Core README template carries
a "where things live" diagram; each type overlay ships a "how to ship a change" pipeline diagram
(authored for `powershell-module`).

## Consequences

- The scaffolder is agent-driven copy-and-fill (no Copier/Python engine), made reliable by a
  post-scaffold self-check (enumerated-token grep + expected-file-set existence). The self-check
  catches missing/empty substitutions and skipped files, not wrong-but-present values — so the
  dev-test eyeball still matters.
- Reuse source is `PBNZ/newton-skill` (governance docs, validation scripts, plugin mechanics).
  RepoKit omits newton's tool-rules generator, sync-rules workflow, Pages site, and `NOTICE.md`
  (no third-party material to attribute).
- Six of the seven type overlays ship as stubs; `powershell-module` is built out as the first
  real target.
