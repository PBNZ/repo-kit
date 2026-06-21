# RepoKit

**One reusable repo standard + a `/new-repo` scaffolder, packaged as a Claude Code plugin.**

Every repo you build with an agent tends to reinvent its own rules — what to read first, the
coding style, the pre-commit/PR steps, the commit format, where learnings live. RepoKit fixes
that: it stamps a consistent, navigable repository from commit #1, organised by **type × tier**,
so a forever-private script bin stays effortless and a published module gets the full governance —
from the *same* standard.

## The idea in one picture — type × tier

Every repo gets a light **Core** baseline. **Visibility** decides how many layers switch on;
**type** adds its own structure-specific files on top. Promotion (private → public → published)
just switches on the next layer — a copy, not a rewrite.

```mermaid
flowchart TD
    Vis{"Pick VISIBILITY"} -->|private| P1["Core only"]
    Vis -->|public| P2["Core + Public"]
    Vis -->|published| P3["Core + Public + Published"]
    P1 --> Plus["then add your TYPE overlay<br/>(powershell-module, skill-plugin, ...)"]
    P2 --> Plus
    P3 --> Plus
    Plus --> Repo["= STAMPED REPO<br/>promotion later just switches on the next layer — copy, not rewrite"]

    subgraph Legend["What each layer adds"]
      L1["Core: AGENTS.md, thin CLAUDE.md, START-HERE map, ADR log, conventions, .gitignore"]
      L2["Public: LICENSE, SECURITY, CoC, PR/issue templates, CI"]
      L3["Published: release automation + publish workflow"]
    end
```

## What `/repokit:new-repo` does

It interviews you, stamps the right files for your chosen type × tier, checks its own work, makes
the first commit — then **stops** so you review and publish when you're ready.

```mermaid
flowchart TD
    Start(["You run /repokit:new-repo"]) --> Inp["Interview: name, description, type, visibility, author, license"]
    Inp --> S1["1. Resolve file set (active tiers + type overlay)"]
    S1 --> S2["2. Read each template, fill in placeholders, write files"]
    S2 --> S3["3. Write ADR-0001 (records your choices)"]
    S3 --> S4["4. Generate START-HERE map into AGENTS.md"]
    S4 --> Chk{"Self-check: no unfilled placeholders? all expected files present?"}
    Chk -->|fail| S2
    Chk -->|pass| S5["5. git init + first Conventional commit"]
    S5 --> S6{"6. Opt in to a private GitHub repo?"}
    S6 -->|yes| GH["gh repo create --private"]
    S6 -->|no| Skip["stay local-only"]
    GH --> S7["7. Print summary + START-HERE map"]
    Skip --> S7
    S7 --> Stop["STOP — you review locally and publish when ready"]
```

## How the pieces fit

RepoKit is one plugin you install once. It carries two skills: **new-repo** *makes* a repo;
**repo-standard** *guides you while you work in* any repo it made.

```mermaid
flowchart LR
    subgraph RK["RepoKit plugin — PBNZ/repo-kit (install once)"]
      MP["marketplace.json"] --> PL["repokit plugin"]
      PL --> S1["skill: new-repo<br/>(+ bundled templates)"]
      PL --> S2["skill: repo-standard<br/>(+ standard docs / checklists)"]
    end
    S1 ==>|"stamps"| NR["Your scaffolded repo<br/>files at your chosen tier x type"]
    NR -.->|"its AGENTS.md points to"| S2
    S2 -.->|"supplies live conventions + pre-commit / pre-PR checklists"| NR
```

## Install

```text
/plugin marketplace add PBNZ/repo-kit
/plugin install repokit@repo-kit
/reload-plugins
```

Then scaffold a repo:

```text
/repokit:new-repo my-new-repo "One-line description of what it does"
```

It will interview you for the type and visibility if you don't give them, stamp the files, and
make the first commit. Nothing is pushed or published — you do that when you're ready.

## Profiles

- **Type — what the repo *is*:** `powershell-module` (built out), plus `skill-plugin`,
  `collection`, `mcp-server`, `app-ts`, `app-python`, `script-collection` (stubs, filled as needed).
- **Tier — ceremony, set by visibility:** **Core** (every repo), **+Public**, **+Published**.

See [`the standard`](plugins/repokit/skills/repo-standard/standard/the-standard.md) for the full
model, the per-tier file lists, and the where-things-live map.

## Repository layout

This repo dogfoods its own standard. See [`AGENTS.md`](AGENTS.md) for the START-HERE map.

## Contributing & licence

- Contributions: see [`CONTRIBUTING.md`](CONTRIBUTING.md).
- Security: see [`SECURITY.md`](SECURITY.md).
- Licence: [Apache-2.0](LICENSE).
