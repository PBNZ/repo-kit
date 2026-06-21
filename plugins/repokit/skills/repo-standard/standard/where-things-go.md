# Where things go — a placement guide

Use this when you're about to add something to a RepoKit repo and aren't sure where it belongs —
or when there's no folder for it yet and you need to know where, and how, to create one (and why).

## The rule of thumb (when something isn't listed below)

1. If a tool or platform **reads** the path, use the location it requires (e.g. `.github/workflows/`,
   `release-please-config.json`).
2. Otherwise, follow the **language / ecosystem idiom** (e.g. `src/`, `tests/`).
3. **Don't invent a new top-level directory** when a conventional one already exists.
4. When you do create a new conventional location, capture *why* (and the source) so the next
   person knows it wasn't arbitrary — an ADR in `docs/adr/` is the right home for a structural one.

## The guide

| You have… | It goes in… | If that location doesn't exist yet | Based on |
|-----------|-------------|------------------------------------|----------|
| An architecture / design decision ("why did we do it this way") | `docs/adr/NNNN-title.md` — copy `docs/adr/0000-template.md`, next zero-padded number | create `docs/adr/` | ADR convention (Michael Nygard; adr-tools) |
| Prose documentation — a guide, an explanation, reference material | `docs/` | create `docs/`; split it once it grows (next row) | single `docs/` umbrella |
| …and once the docs grow substantial | the four Diátaxis buckets: `docs/tutorials/`, `docs/how-to/`, `docs/reference/`, `docs/explanation/` | create the relevant subdir | Diátaxis (diataxis.fr) |
| A docs landing page / table of contents | `docs/README.md` | — | GitHub renders `docs/README.md` |
| Images / diagrams used by the docs | `docs/assets/` | create `docs/assets/` | common convention |
| An exported PowerShell function | `Public/<Verb-Noun>.ps1` — one function per file, file name == function name | create `Public/` | Microsoft module layout |
| An internal PowerShell helper (not exported) | `Private/<name>.ps1` | create `Private/` | Microsoft module layout |
| A test | the type's test dir — `Tests/` (Pester), `tests/` (pytest), `__tests__/` or `*.test.ts` (JS/TS) | create per the language's test-runner convention | `testing-matrix.md` |
| A CI / automation workflow | `.github/workflows/<name>.yml` | create `.github/workflows/` | GitHub Actions (required path) |
| An issue or PR template | `.github/ISSUE_TEMPLATE/<name>.md`; `.github/PULL_REQUEST_TEMPLATE.md` | create `.github/ISSUE_TEMPLATE/` | GitHub (required path + case) |
| A reusable helper script (build, release, dev tooling) | `scripts/` | create `scripts/` | common convention |
| Application / library source code | the language idiom — `src/` (TS/JS, Python package), the module root for a PowerShell module | per language | language idiom |
| Tool configuration | the exact path the tool requires (`.editorconfig`, `.gitignore`, `release-please-config.json`, `pyproject.toml`, …) | at that exact path | the tool's docs |
| A user-visible change to record | `CHANGELOG.md` under `## [Unreleased]` | — | Keep a Changelog |
| Secrets / API keys / credentials | **Never in the repo.** Use a gated GitHub Environment secret, or a secrets manager. | n/a | security |
| (RepoKit dev) a new repo-type's scaffolding | `templates/types/<type>/{core,public,published}/` | create the type overlay | the RepoKit standard |

If what you're adding isn't here, apply the rule of thumb above, tell the user the source of your
suggestion, and offer to add a row here (or write an ADR) so the decision is captured for next time.
