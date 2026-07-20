# Org-migration & board-rebuild checklist

For moving repos from a personal account into an organization and rebuilding a project board.
Every item below cost a debugging loop in a live migration; run the checklist cold and each one
is a non-event. Format: symptom → cause → fix. Plan-dependent limits carry a GitHub-docs link —
**re-verify against current docs before relying on them**, plans change.

## Before transfer

- [ ] **Transfer first, create Actions secrets and Environments after.** Sequencing the
  transfer first means there is nothing sensitive to lose or leak in the move. GitHub keeps
  issues, PRs, labels, stars and webhooks, and redirects old URLs for web and git — but see the
  Projects-API caveat below, and note that creating a new repo (or fork) at the old
  owner/name **permanently deletes** the redirects.
  ([Transferring a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/transferring-a-repository))
- [ ] **Plan the human deploy gate around your plan.** Environment configuration on **private**
  repos needs GitHub Pro (personal) or Team (org); on a Free org the "required reviewer"
  protection rule silently doesn't exist for private repos — design the human gate around
  something else (e.g. the release-publish act) until the plan changes. Converting a repo
  public → private drops existing protection rules and environment secrets.
  ([Managing environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments))

## After transfer

- [ ] **First CI run dies with `startup_failure`, no logs?** → A fresh org's Actions policy may
  not allow external actions, so `actions/checkout` etc. are org-blocked ("Organization actions
  only" blocks all GitHub-authored actions). → Org Settings → Actions → allow GitHub-authored
  actions (the tightest sufficient option).
  ([Actions policies for an organization](https://docs.github.com/en/organizations/managing-organization-settings/disabling-or-limiting-github-actions-for-your-organization))
- [ ] **A startup-failed run cannot be re-run** — trigger a fresh run (push, or
  `gh workflow run`) instead of hunting for a re-run button.
- [ ] **Projects API calls with old issue URLs fail "resource not found"** even though the same
  URLs redirect fine in a browser → the Projects API does not follow repo-transfer redirects
  (observed platform behaviour) → rewrite URLs to the new owner/name before scripting board
  adds/moves.

## Board rebuild

- [ ] **Status options replaced via API, and now the built-in workflows dangle?** → The option
  list was sent *without* ids, so GitHub minted new option ids and every default workflow
  ("item closed → status X", "auto-close", "PR merged") — and every item's stored value — still
  refers to the old, now-deleted options. → `ProjectV2SingleSelectFieldOptionInput` accepts an
  optional `id`: read the current options first
  (`field(name: "Status") { ... on ProjectV2SingleSelectField { options { id name } } }`), echo
  the id back for every option you keep **or rename**, and omit `id` only for genuinely new
  options. Options render in array order, so mid-list inserts and automation-preserving renames
  work in one mutation. Then verify — `workflows(first: 20) { nodes { name enabled } }` plus a
  re-read of item values — before trusting it. Only a full id-less replacement needs the manual
  UI click-through.
- [ ] **Auto-add is per-repo and plan-capped:** each auto-add workflow targets a single
  repository, with a maximum of **1 workflow on Free, 5 on Pro/Team, 20 on Enterprise** — a
  multi-repo board on Free gets exactly one auto-added repo; the rest is manual/agent adds or
  per-repo Actions workflows.
  ([Adding items automatically](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/adding-items-automatically))
- [ ] **Re-enable and re-check board automations against the agent rules** — if "status = Done
  auto-closes" is on, the closing-force rules apply (see
  [`agent-collaboration.md`](agent-collaboration.md)).
- [ ] **Views and auto-add are UI-only residue.** Project views have no create API, and
  auto-add is plan-capped (above) — an agent-built board still needs human clicks to be usable.
  That click-through gets written down as a commissioning-handoff issue on the board itself,
  assigned and checkboxed (see [`agent-collaboration.md`](agent-collaboration.md),
  *Commissioning handoff*) — never delivered only as chat prose.
