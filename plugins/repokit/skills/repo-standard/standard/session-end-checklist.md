# Session-end checklist

Run through this before ending a working session. Every item is mechanically checkable in under
a minute; a session doesn't end "clean" with any box undecided.

- [ ] **No undecided branches** — `git branch -a --no-merged`: for each hit, merge it, delete
  it, or open an issue that owns it. No silent survivors.
  **`--no-merged` over-reports on rebase- and squash-merging repos** (both on by default on
  GitHub): it tests ancestry ("is this tip reachable from HEAD"), not content ("did this change
  land"), and both merge methods rewrite the commit — so a landed branch is reported unmerged
  forever, and `git branch -d` refuses it by the same test. That is the one case where `-D` is
  the correct tool, *after* confirming the change landed:
  - the branch had a PR: `gh pr list --state merged --head <branch>` lists it → landed;
  - no PR: `git log --oneline --cherry main...<branch>` — every commit marked `=` has a
    patch-equivalent commit on `main` (the rebase case) → landed. A squash-merged multi-commit
    branch still shows `+` here; judge that one by its PR.
  Then `git branch -D <branch>`. Never `-D` a branch that fails both checks.
  Kill the remote half of the noise once per repo: `gh repo edit --delete-branch-on-merge`
  auto-deletes merged PR branches, and `git fetch --prune` then clears the local `[gone]`
  tracking stubs.
- [ ] **Straight-to-main commits are one concern each** — if a commit subject needs an "and",
  split before pushing (the no-PR formulation of "one concern per PR").
- [ ] **Resume-state updated** — `docs/CHECKPOINT.md` (or the declared substitute) carries
  today's date and an explicit next step, even `paused — nothing pending`.
- [ ] **No prepend churn** — scan the resume-state doc for duplicated headings or sections left
  by repeated session edits.
- [ ] **Working tree clean** — `git status --short` shows nothing stranded.
- [ ] **(Board repos) cards match reality** — positions and assignees reflect actual state (see
  `agent-collaboration.md`).
- [ ] **No manual residue delivered only in chat** — every step the human still has to perform
  is owned by an assigned, checkboxed issue (see `agent-collaboration.md`, *Commissioning
  handoff*).
