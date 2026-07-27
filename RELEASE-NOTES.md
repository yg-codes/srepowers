# Release Notes

Newest first.

## 5.9.2 — superpowers v6.2.0 bug-fix parity

Ports the two defect fixes from
[superpowers v6.2.0](https://github.com/obra/superpowers) that apply to
SREPowers, plus a duplicate-section cleanup found while cross-checking. No
behavior redesign — the SDD plan-scoped workspace and resume-based fix loop
from the same upstream release are tracked separately.

### Fixed

- **`find-polluter.sh` found nothing and reported "Found 1".** Two defects in
  one line ([upstream #2008](https://github.com/obra/superpowers/issues/2008),
  [#2011](https://github.com/obra/superpowers/issues/2011)): `find .` emits
  `./`-prefixed paths, so the skill's own documented glob `'checks/**/*.sh'`
  matched zero files; and `wc -l` on empty input returns 1, so a zero-match run
  announced "Found 1 check scripts" before reporting the suite clean. The glob
  now accepts an optional leading `./`, is also matched with `**/` collapsed so
  scripts directly under the base directory aren't skipped, and an empty result
  counts as 0. New deterministic suite:
  `tests/claude-code/test-find-polluter.sh` (5 assertions, all four failure
  modes reproduced RED first).
- **`git-guardrails` blocked ordinary pushes.** The short-flag rules matched
  `.*(-[[:alnum:]]*f)` with no trailing token boundary, so any hyphenated word
  ending in the flag letter matched anywhere on the line: `git push -u origin
  fix/superpowers-v620-bugfix-parity` was refused as a force-push because
  `-bugf` matched. The `clean -f` and `branch -D` rules had the same shape
  (`git clean -d my-stuff`, `git branch -d feat/backup-D`). Flag clusters are
  now whitespace-delimited alphanumeric tokens, with the flag letter allowed
  anywhere in the cluster so `-fd`, `-dfx`, `-fu`, and `-Dr` still block.
  Found when the guard blocked this release's own push; the existing allow-case
  tests used short branch names (`feat/x`) that happened to dodge it.
- **`finishing-operation-branch` cleanup could never match.** Step 6 recomputed
  `WORKTREE_PATH=$(git rev-parse --show-toplevel)` *after* Option 1
  (`git checkout <target-env>`) and Option 5 (`git checkout <base-branch>`) had
  already moved off the operation branch, so the provenance check compared the
  main repo root against itself, cleanup silently no-oped, and the worktree
  stayed attached. `WORKTREE_PATH` and `MAIN_ROOT` are now captured in Step 2
  while still inside the workspace, and Step 6 consumes them instead of
  recomputing. Mirrors upstream `0b47219`.

### Changed

- **Removed a duplicate section in `subagent-driven-operation`.** "Handling
  Reviewer ⚠️ Items" appeared twice — a generic copy left over from the v5.4.0
  SDD backport and the SRE-specific version that supersedes it. The generic one
  is gone; the version naming unchanged config, live cluster/host state, and
  cross-task requirements remains.

## 5.7.0 — superpowers v6.1.1 parity

Brings SREPowers to functional parity with
[superpowers v6.1.1](https://github.com/obra/superpowers) while preserving the
SRE-specific content and the CI/test coverage where SREPowers is ahead.

### Fixed

- **SessionStart hook hangs on bash 5.3+.** The hook emitted its JSON through a
  `cat <<EOF` heredoc, which hangs on bash 5.3 and later
  ([upstream #571](https://github.com/obra/superpowers/issues/571)). It now uses
  `printf`. `tests/hooks/test-session-start.sh` guards against reintroduction.
- **No Windows/Git-Bash bootstrap.** Added the polyglot `run-hook.cmd` wrapper
  (a file that is simultaneously a valid cmd.exe batch script and a bash
  script), and renamed `session-start.sh` to extensionless `session-start` so
  Claude Code's Windows `.sh` detection does not double-wrap it with `bash`.
  All three `hooks.json` files route through the wrapper. See
  [docs/windows/polyglot-hooks.md](docs/windows/polyglot-hooks.md).
- **Unquoted command substitution** in `pve-admin/scripts/check-pve-cluster.sh`
  and five `local x=$(...)` exit-status maskings in
  `tests/claude-code/test-helpers.sh`, found by the new shell linter.

### Changed

- **Reviewer consolidation (subagent-driven-operation).** The two sequential
  per-task reviewers are replaced by a single `task-reviewer-prompt.md` that
  reads the review package once and returns both verdicts — spec compliance and
  artifact quality — plus a ⚠️ "cannot verify from diff" class the controller
  resolves. `spec-reviewer-prompt.md` and `artifact-quality-reviewer-prompt.md`
  are removed. Matches upstream v6.0.0's model: a second reviewer re-reading the
  same diff doubles turns and splits one fix loop into two.
- **`writing-skills-sre` rebuilt** from 76 lines to full depth: the Iron Law,
  RED-GREEN-REFACTOR for skills (with wording micro-tests), Skill Discovery
  Optimization, Match the Form to the Failure, Bulletproofing Against
  Rationalization, testing guidance per skill type, anti-patterns, and a
  creation checklist that includes the repo's own wiring invariants.
- **`.srepowers/` is now gitignored** — the SDD ledger, briefs, review packages,
  and brainstorm session files are scratch, and the skills already described
  them as such.

### Added

- **`requesting-review-sre` skill** (srepowers-core, 28 → 29 skills) — the
  request side of the review loop, with an SRE reviewer template that judges
  blast radius, rollback preservation, least privilege, and whether verification
  checks real state. `subagent-driven-operation`'s final whole-operation review
  now points at it.
- **Brainstorm visual companion** (opt-in, Node) — browser-based topology
  diagrams and side-by-side architecture comparisons during design. The v6.0.0
  per-session-key security model is preserved intact: URL key → tab-scoped
  cookie, required on every HTTP and WebSocket request, with symlink/dotfile/
  path-escape refusal and owner-only key files. The core brainstorming workflow
  remains dependency-free.
- **`condition-based-waiting`** guidance and helpers in
  `systematic-troubleshooting`, recast for pod readiness, service health, DNS
  propagation, and Puppet apply settling. Plus `find-polluter.sh`.
- **Restored prose sections**: "Why This Matters" and "The Bottom Line" in
  `verification-before-completion`; "This Is Too Simple To Need A Design" and
  the checklist in `brainstorming-operations`.
- **`scripts/lint-shell.sh`** — shellcheck + shfmt + `bash -n`/`sh -n` across
  changed, requested, or all tracked shell files, with a `--strict` mode. All 66
  shell files in the repo pass. Tested by `tests/shell-lint/`.
- **Atomic version bumping** — `scripts/validate-repo.py` gained `--bump` and
  `--show-versions`. It discovers all 18 version sites structurally from the
  existing manifest list rather than duplicating it in a `.version-bump.json`,
  and substitutes at the text level so hand-formatting and non-ASCII punctuation
  survive.
- **Companion files for `writing-skills-sre`**: `anthropic-best-practices.md`,
  `persuasion-principles.md`, `graphviz-conventions.dot`, `render-graphs.js`.
- **Maintainer scaffolding**: `CONTRIBUTING.md`, this file,
  `.github/ISSUE_TEMPLATE/`, `.github/PULL_REQUEST_TEMPLATE.md`,
  `docs/testing.md`, `docs/windows/polyglot-hooks.md`.
- **CI steps** for the hook test and the shell linter.

### Deliberately not changed

SREPowers is ahead of upstream in these areas and they were preserved:

- `.github/workflows/validate.yml` CI (upstream has none)
- The ~60-test per-skill `tests/claude-code/` suite
- `validate-repo.py` metadata and mirror validation
- The Codex `SessionStart` matcher `startup|clear|compact` (no `resume`)
- The `"hooks": {}` invariant in every packaged Codex plugin manifest
- SRE-specific expansions throughout the workflow-spine skills

## 5.6.1 — Codex SessionStart hooks hygiene

Parity with superpowers v6.1.1 (`7d8d3d4`): every packaged Codex plugin manifest
declares `"hooks": {}` so Codex does not auto-discover and register the Claude
Code hook file. Locked in by `tests/codex/run-skill-tests.sh`.

## 5.6.0 and earlier

See `git log` and `docs/plans/` for the history prior to this file.
