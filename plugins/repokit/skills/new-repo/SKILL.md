---
name: new-repo
description: Use when you want to scaffold, create, or start a new repository to the RepoKit standard — "/new-repo", "scaffold a new repo", "set up a new module / plugin / project repo". Stamps a type x tier-compliant repo from bundled templates, then stops at local review.
disable-model-invocation: true
argument-hint: "[name and/or brief, e.g. my-tool \"does X\" — or blank to be interviewed]"
---

# new-repo — scaffold a RepoKit-standard repository

You scaffold a new repository by copying bundled templates and filling in their `{{placeholders}}`
(copy-and-fill — there is no separate templating engine). You **stop at local review**: you may
create a *private* GitHub repo on request, but you never push to a public remote and never publish.

**Your templates live under this skill's own directory.** At load you were given a line
`Base directory for this skill: <ABS>`. Read every template as `<ABS>/templates/<...>`. Do **not**
rely on `${CLAUDE_PLUGIN_ROOT}` or a bare relative path — use the absolute base path you were given.

Two reference files (read them from the same base dir as you need them):

- `references/file-set-resolution.md` — exactly which templates apply for a given type × tier.
- `references/placeholders.md` — the placeholder list and the post-scaffold self-check.

## Inputs

Gather these from the user's arguments / message, else ask — keep it to load-bearing questions:

- **name** — the repo / directory name (kebab-case).
- **description** — one line.
- **type** — one of: `powershell-module`, `docker-compose`, `skill-plugin`, `collection`, `mcp-server`, `app-ts`,
  `app-python`, `script-collection`.
- **visibility** — `private` (= Core tier), `public` (= +Public), or `published` (= +Published).
- **author** — default `Peter Braun` (`PBNZ`).
- **license** — default `Apache-2.0`.
- For `powershell-module` only: **ModuleName** (PascalCase, e.g. `MyModule`).

If the chosen type is a **stub** (anything other than `powershell-module` or `docker-compose`), tell the user so: the
Core/Public/Published files get stamped, but there's no type-specific structure yet. Confirm they
want to continue.

## Steps

1. **Resolve the file set** (see `references/file-set-resolution.md`).
   `active_tiers = [core] + ([public] if visibility in {public, published}) + ([published] if visibility == published)`.
   The file set is the union, over each active tier `t`, of everything under `templates/<t>/` and
   everything under `templates/types/<type>/<t>/`. On a path collision pick one winner: **higher
   tier wins (`published` > `public` > `core`), then within a tier the type overlay wins**.
   Produce an explicit list of `(template path → target path)` pairs: drop any trailing `.tmpl`,
   and substitute filename placeholders (e.g. `{{ModuleName}}.psd1.tmpl` → `MyModule.psd1`).

2. **Stamp each file.** For each pair: read the template from `<base>/templates/…`, replace every
   placeholder (see `references/placeholders.md`), and write it to the target path under the new
   repo directory. Files with no `.tmpl` suffix are copied verbatim. Create directories as needed
   (`docs/adr/`, `.github/…`, any type-specific dirs).

3. **Write `docs/adr/0001-initial-decisions.md`** from the `docs/adr/0000-template.md` you just
   stamped, recording the name, type, visibility/tier, licence, author, and any notable interview
   choices.

4. **Generate the START-HERE map.** From the resolved file set, build a short "where things live"
   table (rules → `AGENTS.md`; decisions → `docs/adr/`; conventions & checklists → the
   `repo-standard` skill; CI → `.github/workflows/`; tests → the type's test dir) and substitute it
   into the `{{START_HERE_MAP}}` placeholder in the stamped `AGENTS.md`. Add a one-line pointer in
   the README.

   **Self-check (gate — both must pass before you continue).** See `references/placeholders.md`:
   (a) no enumerated placeholder tokens remain anywhere in the output; (b) every expected target
   file exists and no `.tmpl` suffix survived. If either fails, fix and re-check.

5. **Initialise git** in the new repo directory:
   - **Default branch `main`, never `master`:** `git init -b main` (`-b` needs git >= 2.28; if it
     errors, run `git init` then `git branch -m main`).
   - **Commit identity -- anonymous by default.** So a repo that later goes public never leaks a
     personal email, set a **repo-local** (not `--global`) identity using the GitHub *noreply*
     address. Resolve it for the gh-authenticated user and apply it locally:
     ```
     gh api user --jq '"\(.name // .login)\t\(.id)+\(.login)@users.noreply.github.com"'
     git config user.name  "<name-or-login>"
     git config user.email "<id>+<login>@users.noreply.github.com"
     ```
     Use a **real** name/email only if the user explicitly asked (you may ask, but the default is the
     noreply address). No `gh` available? Fall back to `<login>@users.noreply.github.com`, or ask.
   - **Stage + commit:** `git add -A -f` -- the `-f` force-adds the stamped files past any global
     gitignore (e.g. a `*private*` rule that would silently drop a `Private/` dir; safe here, the tree
     holds only what you stamped, and the repo's own `.gitignore` governs later additions) -- then one
     Conventional commit: `chore: scaffold <name> via RepoKit`.
   - **Confirm:** `git status --short` is clean, `git rev-parse --abbrev-ref HEAD` prints `main`, and
     note the commit identity you used in the final summary.

6. **Offer a private remote — opt-in only.** Ask whether to create a private GitHub repo. Only if
   the user says yes: `gh repo create <name> --private --source . --remote origin`. Never public,
   never push to a public remote, never publish.

7. **Print the summary:** the resolved tier × type, the file tree, the START-HERE map, and next
   steps — "review locally; you publish when ready."

## Boundaries

- Stop at local review. Do not push to a public remote and do not publish.
- Do not invent files outside the resolved set.
- Diagrams embedded in templates are **static** — substitute `{{name}}` inside them, but never
  redraw or regenerate a diagram.
