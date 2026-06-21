# Contributing to repo-kit

Thanks for your interest in contributing. This repository houses **RepoKit** — a reusable
repository standard plus the `/new-repo` scaffolder, packaged as a Claude Code plugin.
Contributions are welcome, especially bug reports, portability fixes, new repo-type templates,
and improvements to the standard or the scaffolding skill.

Please read this guide before opening an issue or pull request.

## Ground rules

- **Be kind.** All interactions are governed by the [Code of Conduct](CODE_OF_CONDUCT.md).
- **Small, focused changes.** One concern per PR. If a change mixes standard edits with template
  or tooling changes, split it.
- **Match existing style.** Follow the structure of the existing skills and standard docs.
  Prose over bullets where prose works; specifics over generalities.
- **No surprise scope.** If your PR adds a dependency, a new workflow, or changes the marketplace
  manifest beyond what the issue describes, flag it in the PR description.
- **RepoKit dogfoods its own standard.** Changes here should keep this repo compliant with
  `plugins/repokit/skills/repo-standard/standard/the-standard.md`.

## Ways to contribute

### Report a bug

Open an issue using the **Bug report** template. Include the Claude Code version, the exact
invocation (e.g. the `/repokit:new-repo …` you ran), what you expected, what happened, and a
minimal reproduction if possible.

### Suggest an improvement

Open an issue using the **Feature request** template. Say what problem the change solves and for
whom, why it belongs in RepoKit, and a rough sketch of which files it would touch.

### Submit a pull request

1. Fork the repo and create a feature branch off `main`.
2. Make your change.
3. Ensure the validation workflow would pass locally (see **Validation** below).
4. Update [`CHANGELOG.md`](CHANGELOG.md) under the `## [Unreleased]` section.
5. Open a PR against `main` using the pull request template.

## Where changes go

- **The standard** (required files, tiers, where-things-live, checklists) lives under
  `plugins/repokit/skills/repo-standard/standard/`. `the-standard.md` is the canonical reference.
- **The `repo-standard` skill** (the in-session router to the standard) is
  `plugins/repokit/skills/repo-standard/SKILL.md`.
- **The `new-repo` scaffolding skill** is `plugins/repokit/skills/new-repo/SKILL.md`, with its
  methodology references under `plugins/repokit/skills/new-repo/references/`.
- **Templates** (stamped into new repos) live under `plugins/repokit/skills/new-repo/templates/`,
  organised as `core/`, `public/`, `published/`, and `types/<type>/{core,public,published}/`.
- **Plugin manifest:** `plugins/repokit/.claude-plugin/plugin.json`.
- **Marketplace manifest:** `.claude-plugin/marketplace.json`.
- **Validation scripts:** `scripts/`.

Match the `name` field in each `SKILL.md`'s YAML frontmatter to its skill directory name. Keep
each description specific enough that it triggers cleanly on relevant requests and doesn't fire on
general-purpose ones.

## Validation

The repository has a validation workflow that runs on every PR (`.github/workflows/validate.yml`).
It checks:

- `.claude-plugin/marketplace.json` is valid JSON and conforms to the marketplace schema.
- `plugins/repokit/.claude-plugin/plugin.json` is valid JSON and conforms to the plugin schema.
- Every `SKILL.md` has valid YAML frontmatter with the required fields.
- No email addresses or other private contact info are committed anywhere in the tree.
- No `SKILL.md` body contains invisible/bidi Unicode, imperative prompt-injection phrases, or URLs
  outside the allowlist at `.github/skill-url-allowlist.txt`.

Run the same checks locally before pushing — each is a `python scripts/<name>.py` invocation; see
`.github/workflows/validate.yml` for the exact list.

## Security review of contributed skill content

`SKILL.md` files are prompt content: whatever lands in a `SKILL.md` body is read by Claude as
instructions when the skill activates. PRs that add or modify skill content are reviewed for this
explicitly, not just for style or correctness.

Before opening a PR that touches a `SKILL.md`:

- **Write in plain prose.** No zero-width, bidi, or steganographic Unicode anywhere in the body.
- **No prompt-injection phrases.** Avoid paraphrases of "ignore previous instructions" and the
  like — even inside quoted examples or code fences.
- **No instructions to override safety, exfiltrate data, or reveal system prompts.**
- **Only link to allowlisted hosts.** New trusted hosts can be added to
  `.github/skill-url-allowlist.txt` in the same PR, with a short comment explaining why.
- **Keep email addresses out.** Use GitHub-native flows — issues, pull requests, or a private
  security advisory.

## Licence

By contributing, you agree your contributions will be licensed under the [Apache-2.0 licence](LICENSE).
