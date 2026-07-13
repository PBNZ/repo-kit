# living-docs add-on — AGENTS.md rules block and README snippet

Used by `/new-repo` when the **living-docs add-on** is selected. Two verbatim snippets:

1. Substitute the rules block below into the `{{LIVING_DOCS_RULES}}` placeholder in the stamped
   `AGENTS.md`. When the add-on is **not** selected, delete the placeholder line entirely.
2. Append the `## Status` snippet to the stamped `README.md` (before any final "see AGENTS.md"
   pointer), so the README and the runbook dashboard render from the same facts.

The same wording is what an existing repo adds when adopting the pattern by hand — see the
`repo-standard` skill's `standard/living-docs.md`, "Adopting in an existing repo".

## The `{{LIVING_DOCS_RULES}}` block

```markdown
- **Docs move together (living docs).** `docs/STATE.json` is the single source for volatile
  shared facts (statuses, live resources, counts, as-of dates). A commit that changes anything a
  doc states updates `docs/STATE.json` in the same commit; run
  `pwsh scripts/check-docs.ps1 -Update` and include the re-rendered blocks. CI (`docs.yml`)
  fails otherwise.
- **`docs/RUNBOOK.md` is current-state-only.** Replace outdated text instead of annotating it —
  git keeps the history. Dated journal entries go to `CHANGELOG.md`, never the runbook. See the
  `repo-standard` skill: `standard/living-docs.md` and `standard/doc-style.md`.
```

## The README `## Status` snippet

````markdown
## Status

<!-- state:begin keys=overall_status,live_resources -->
<!-- state:end -->
````

## After stamping

Run `pwsh scripts/check-docs.ps1 -Update` inside the new repo to render the empty state blocks,
then the plain check — it must pass before the scaffold commit. If pwsh 7 is not available on the
scaffolding host, leave the blocks empty and tell the user in the summary that running it is
their first task.
