# Release Notes

Newest first.

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
