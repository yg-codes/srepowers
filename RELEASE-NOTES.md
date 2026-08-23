# Release Notes

Newest first.

## 5.14.0 — upstream sync: superpowers v6.3.0

Adopts the portable skill changes from [superpowers
v6.3.0](https://github.com/obra/superpowers/releases). No new skills; no count
changes. Upstream's harness work (Devin/Hermes plugin manifests, the
`render-graphs.js` ESM rewrite, `bump-version.sh` rework) is deliberately not
ported — srepowers has no equivalent targets.

Surveyed alongside it: **mattpocock/skills** and **i-have-adhd**. Neither
contributed a change this release. Details under "Surveyed, not adopted".

### Added

- **`brainstorming-operations` now classifies before it designs.** A
  three-path router — **probe** (read-only investigation), **bounded** (one
  mutating change to existing infrastructure, rollback statable in one
  command, blast radius of one host or namespace), **architectural**
  (everything else) — replaces the single heavyweight path. Ceremony scales
  with the operation; the approval gate never does, and a bounded design still
  states its rollback and verification explicitly.

  Two ops-specific forced upgrades that have no upstream equivalent: **any
  multi-host change or shared dependency** (quorum, VIP, shared Hiera key) is
  architectural regardless of how small the edit looks, because correctness
  lives between the hosts; and **a rollback you cannot state in one or two
  commands** is architectural, because a rollback you cannot write in ten
  seconds means the blast radius is not understood yet. The ratchet is one-way
  — a probe whose next step would mutate is re-classified, never continued.

- **`subagent-driven-operation`: rulings instead of stalls, inside a
  six-class stop list.** The controller now decides plan-vs-finding conflicts,
  self-contradicting plan text, and cap overruns itself, recording each as
  `Ruling: <decision> — <why> — <cost if wrong>` in the ledger, rather than
  parking the session on a question.

  Upstream's four stop classes (irreversible, security-sensitive, side effects
  outside the worktree, unresolvably broken plan) are **widened by two** for
  infrastructure, where a wrong ruling is not always recoverable rework:
  **(5)** any mutating step whose approval is not already held — a subagent
  cannot ask mid-flight, and an apply approval never carries to a reboot; and
  **(6)** any ruling that would change blast radius, the rollback path, or a
  verification gate. Rule freely on *how* to satisfy the plan; never on *how
  much* it may touch or *whether* the undo survives.

- **The no-subagents contract, in all four dispatch templates**
  (`operator-prompt`, `task-reviewer-prompt`, `re-review-prompt`, and
  `requesting-review-sre`'s `code-reviewer`). A dispatched agent never
  dispatches: every reviewer a worker spawns duplicates the review the
  controller dispatches anyway, at full cost, and its verdict counts for
  nothing. The ops-specific half of the argument is containment — the approval
  and the forbidden list bind the agent you dispatched, not one it spawns, so a
  sub-subagent can reach a host or a mutation the prompt forbade.

- **Batching, bounded waiting, and N-in/N-out reconciliation** in
  `subagent-driven-operation`. Same-shape small changes go out as one batched
  dispatch reviewed as one unit; wait interfaces are never short-polled;
  dispatched count must reconcile against verdict count before any summary,
  since subagents share one token budget and therefore die together rather
  than independently. Two ops carve-outs: hosts sharing a quorum, VIP, or
  service pairing are never batched or parallelised, and the same command
  across N hosts with no per-host judgment is `parallel-ssh` work, not subagent
  work.

- **A `Rulings I made` handoff at finish.** Every ledger line containing
  `Ruling:` is collected into the final message and appended to the plan file
  before the workspace is deleted. Upstream's reason is that a ruling dying
  with the workspace is a decision made in secret; the ops reason is
  additionally that it is an audit-trail gap, and the plan file is where the
  record belongs.

- **`writing-operation-plans` plans now carry a `spec:` pointer** in
  frontmatter and in the prose header. The plan argues from the design, so the
  design travels with it — `subagent-driven-operation` reads both, and resolves
  intra-plan conflicts against the spec. A plan with no reachable spec gets a
  ledger note saying its rulings are provisional.

- **The pre-flight plan scan now produces a table, not a verdict.** One row
  per pair of tasks sharing a host, resource, repo path, or interface; one row
  per task for self-consistency (its verification against its change, its
  rollback against its change). "The scan is clean" without those rows is not a
  scan that was run. Findings that trip a stop class are batched to the
  operator before Task 1 rather than ruled on.

- **`task-reviewer-prompt`: illegible evidence is a gap to report, not
  grounds to re-run.** Re-read the file at its stated path first; regenerating
  evidence you failed to read is not verification. The ops rider is that the
  "re-run" reached for reflexively may not be the read-only command assumed.
  The same prompt now checks a batched dispatch target-by-target — a listed
  host or file with no hunk and no evidence row is a Missing finding, because
  that is exactly the silent partial that makes a batch summary read as full
  coverage.

### Changed

- **`finishing-operation-branch`: a refused worktree removal is a question,
  never a `--force`.** The refusal means files exist nowhere else — and in an
  ops context those are frequently evidence captures, ledger entries, or host
  output that git cannot reconstruct. The skill now prints
  `git status --porcelain -uall` and offers commit / move / delete, with a
  matching Red Flag.

### Surveyed, not adopted

- **mattpocock/skills** — the deltas touching skills srepowers carries are
  cosmetic (an em-dash sweep, YAML description quoting). Two upstream fixes
  were checked against this repo and found not to apply: no srepowers skill has
  an unquoted-colon `description:` (all parse), and none instructs the agent to
  call the Skill tool on a user-invoked skill — srepowers already phrases those
  as "run `srepowers-swe:project-onboarding`". The `grilling` HR round-separator
  fix does not apply either: srepowers' `grilling` asks one question at a time
  rather than in rounds, so there is no multi-question round to separate.
  `implement-spec` is upstream `in-progress`, 35 lines, and overlaps
  `subagent-driven-operation` — not adopted.

- **i-have-adhd** — changes since the `ops-brief` port are hook plumbing for
  that project's own distribution (SessionStart timeout, Codex launcher
  hardening) plus contributing docs. The rule content `ops-brief` carries is
  unchanged upstream.

## 5.13.1 — validate the skill catalog

### Fixed

- **`skill-catalog.md` was never machine-validated.** `using-srepowers` loads
  it to route work, so a missing row makes a skill invisible to the router and
  a stale row advertises one that does not exist — but `validate-repo.py`
  checked skill dirs, command wrappers, mirrors, versions and the README counts
  while never opening the catalog. Confirmed by inserting a row for a
  nonexistent skill and watching the validator pass.

  New `validate_catalog()` asserts row membership in both directions (no
  missing rows, no rows for skills that do not exist, no duplicates) and that
  every `## Plugin: <name> (N skills)` header matches disk. It caught real
  drift on its first run: the core header read `33 skills` while carrying 34.

  All four failure modes were adversarially verified to fail — nonexistent row,
  deleted row, wrong header count, missing header.

- Docs claimed **18 version sites across 11 manifests**; the real figure is
  **22 across 13**, per the validator's own `--show-versions`. Corrected in
  `CONTRIBUTING.md` (twice) and `docs/testing.md`.
- `CONTRIBUTING.md` said adding a skill touches five places, then named the
  catalog separately in prose. It is six places, now listed in the block.

## 5.13.0 — verification-guardrails: mechanical enforcement for lying gates

New `srepowers-core:verification-guardrails` skill (core 33 → 34) and two hooks.
The advisory layer already existed; the record showed it did not self-apply —
the `PIPESTATUS` rule was written into a runbook template's own conventions
section and violated three steps later in the same file.

### Added

- **`block-lying-gates` (PreToolUse/Bash, active on install).** Blocks seven
  shell idioms that make a verification gate lie, in both directions — gates
  that **cannot fail** (`comm … && echo PASS`, `$?` read after a pipe, an
  unprivileged glob handed to a privileged reader, a `grep -v`-on-errors
  denylist) and gates that **cannot pass** (a trailing-slash pointer grep, an
  exact-string grep on column-aligned output, `is-active | grep active`
  matching `activating`). Each denial names the fix, not just the ban. Fails
  open on malformed input or missing `jq`.

- **`block-unsourced-claims` (Stop) — shipped but wired into no hooks.json.**
  Blocks a final message that asserts system state when the turn contains no
  tool call that could have established it, covering both negative claims
  ("the apply never ran") and perfect-tense mutations ("I committed"). Enable
  it yourself via the snippet in the skill.

  This is a deliberate departure from the `git-guardrails` precedent, not an
  oversight: a denied Bash call costs one retry, while a Stop false positive
  stops the turn from finishing at all. The blast radius is asymmetric, so the
  consent model is too.

### Fixed

- **`tests/hooks/test-block-dangerous-git.sh` never ran in CI.** The workflow
  named `test-session-start.sh` explicitly with no glob, so the git guard's
  41-case matrix had been dead since 5.8.0. CI now globs
  `tests/hooks/test-*.sh`, with a separate step for the Python suite.
- `CLAUDE.md` was stale — it advertised v5.9.0 / 32 core skills and omitted
  `ops-brief`. Corrected and reconciled against disk.

## 5.12.1 — puppet-fact-query accuracy fixes

Version-only bump for the other four plugins; the change is in
`srepowers-infra`.

### Fixed

- `srepowers-infra:puppet-fact-query` — four defects, each found producing a
  wrong answer during live fleet use, not by inspection.

  - **The parser emitted raw JSON blobs as fact values.** Puppetboard returns
    the value cell as a JSON-*encoded string*, `'["<href>", "<value>"]'`, so
    the `isinstance(raw, list)` test never fired and the fallback printed the
    whole blob. Measured **285/285 rows malformed**; every `--values` count was
    therefore wrong. Added `parse_value()`, which decodes the string before
    falling back to tag-stripping.
  - **Summary output went to stdout**, contaminating any redirected data file —
    downstream `sort`/`comm` ingested the `--- N hosts ---` footer and the value
    counts as data rows. Summaries now go to stderr, and the record separator
    is a **tab** rather than two spaces so `cut -f2` works.
  - **Environment was derived from the hostname prefix.** The skill actively
    instructed this. Nine hosts using a different naming scheme matched no
    pattern, fell into a silent catch-all, and were dropped from a 168-host
    upgrade worklist — three of them needed a full OS upgrade rather than the
    z-stream bump their group received. Correct scope was 177. PuppetDB carries
    an authoritative `facts_environment` on the `nodes` endpoint; the skill now
    requires reading it, ships a join script, and demotes hostname derivation
    to an explicitly-labelled fallback that **must** report unmatched hosts.
  - **No guidance on result validity.** PuppetDB answers "what did agents last
    report", not "what is true now" and not "what hosts exist" — and both gaps
    are invisible in the output. Added a report-age bucketer, a comparison
    against the master's configured `runinterval`, and an explicit statement of
    what the query structurally cannot see (powered-off hosts, hosts with no
    agent, hosts reporting to a different PuppetDB).

### Added

- `puppet-fact-query`: a `recordsTotal` truncation guard in the parser, and an
  accuracy checklist to run before presenting any fleet-wide result.

All three Python blocks in the skill are syntax-checked and were functionally
tested against a live 285-node instance.

## 5.12.0 — ops-brief output mode

### Added

- `srepowers-core:ops-brief` — a persistent action-first output mode for
  operations. Leads with the next command, numbers multi-step work, restates
  progress every turn, reports exit codes instead of vibes, and drops preamble,
  recaps, and closing pleasantries. Stays on for the session until "stop
  ops-brief" or "normal mode".

  Adapted from [i-have-adhd](https://github.com/ayghri/i-have-adhd) by Ayoub G.
  (MIT). Two deliberate divergences from upstream for ops use:

  - **Safety outranks brevity.** The overrides section sits *before* the rules,
    not after. When the next step mutates, blast radius and rollback come first
    and the command second — a mutating command is never the first thing on
    screen.
  - **Mandatory gates own their output whole.** When
    `evidence-first-reporting`, `verification-before-completion`, or
    `safety-validator` fires, its contract wins intact; ops-brief then applies
    only inside those sections and never deletes one to save lines. Without
    this, terse mode silently eats the `Unknowns` section that
    `evidence-first-reporting` exists to force.

  No SessionStart hook: `srepowers-core` already injects `using-srepowers` at
  session start, and a second always-on injector would reshape output during
  unrelated infra work. Invoke it when you want it.

## 5.10.0 — plan-scoped SDD workspace and resume-based fix loop

Completes [superpowers v6.2.0](https://github.com/obra/superpowers) parity for
`subagent-driven-operation`. The v5.9.2 release took the bug fixes; this one
takes the two design changes.

### Changed

- **The SDD workspace is plan-scoped.** `.srepowers/sdd/` had no plan identity
  and no end-of-life, so a follow-up plan in the same working tree could read
  the previous plan's ledger as its own progress — a controller that believes
  tasks are already complete skips them silently. `sdd-workspace` now requires
  the plan file and resolves `<repo-root>/.srepowers/sdd/<plan-basename>/`;
  `task-brief` and `review-package` write into their plan's directory
  (`review-package` gains the plan file as its first argument); the ledger
  names its plan on its first line (`# SDO ledger — plan: <path>`); the
  self-ignoring `.gitignore` moves to the `.srepowers/sdd/` parent so it covers
  every plan; and the workspace is deleted once the final review is clean —
  git history is the durable record.

  **Breaking for direct script callers:** `sdd-workspace PLAN_FILE` and
  `review-package PLAN_FILE BASE HEAD` both take the plan file now. A ledger at
  the old flat path `.srepowers/sdd/progress.md` is explicitly treated as
  another plan's progress: left in place, not adopted.

- **The review-fix loop resumes the operator.** Fix rounds now resume the
  original operator (rounds 1-3) rather than dispatching fresh each time — its
  context already holds the task, the live system state it observed, and its
  own choices. Rounds 4-5 dispatch a fresh operator on a more capable model.
  A five-round circuit breaker caps the loop, after which the controller
  adjudicates each open finding as parked-with-ruling or BLOCKED; adjudicating
  before the cap is pre-judging. Minor findings and out-of-scope observations
  are ledgered as deferred and never extend the loop.

- **New scoped re-review template.** `re-review-prompt.md` checks the fixes
  rather than re-reading the whole task: the re-reviewer verdicts each finding
  ADDRESSED / NOT ADDRESSED and inspects only the fix diff for new breakage.
  Adapted for infrastructure — the read-only constraint covers live
  cluster/host state, not just the working tree.

### Tests

`tests/claude-code/test-sdd-workspace.sh` gains plan-scoping coverage: a second
plan resolves a distinct workspace, the `.gitignore` sits at the `sdd/` parent,
and a missing plan file or absent argument exits 2 instead of silently creating
a workspace. 11 assertions, RED-verified before the change.

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
