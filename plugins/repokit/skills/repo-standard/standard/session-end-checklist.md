# Session-end checklist

Run through this before ending a working session. Every item is mechanically checkable in under
a minute; a session doesn't end "clean" with any box undecided.

- [ ] **No undecided branches** — `git branch -a --no-merged`: for each hit, merge it, delete
  it, or open an issue that owns it. No silent survivors.
- [ ] **Straight-to-main commits are one concern each** — if a commit subject needs an "and",
  split before pushing (the no-PR formulation of "one concern per PR").
- [ ] **Resume-state updated** — `docs/CHECKPOINT.md` (or the declared substitute) carries
  today's date and an explicit next step, even `paused — nothing pending`.
- [ ] **No prepend churn** — scan the resume-state doc for duplicated headings or sections left
  by repeated session edits.
- [ ] **Working tree clean** — `git status --short` shows nothing stranded.
- [ ] **(Board repos) cards match reality** — positions and assignees reflect actual state (see
  `agent-collaboration.md`).
