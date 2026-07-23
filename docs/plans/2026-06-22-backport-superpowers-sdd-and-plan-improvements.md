---
ticket: ""
ticket_url: ""
risk_level: "low"
risk_rationale: "Markdown skill content + two new portable bash scripts in a personal GitHub plugin repo; no remote infra, no production state. Worst case is a malformed skill or failing repo-validation, both caught locally before commit and fully revertable via git."
environment: "mgmt"
rollback_plan: "git restore the touched skill/test/script files (or git revert the branch commits); no external state is mutated. Per-task rollback is the inverse git restore of that task's files."
stakeholders: "Repo owner (yg) only — personal GitHub mirror, no other consumers."
tasks_count: 9
status: "completed"
---

# Backport superpowers v6.0.x SDD + Plan Improvements into srepowers Execution Plan

> **For Claude:** REQUIRED SUB-SKILL: Use srepowers-core:subagent-driven-operation to implement this plan task-by-task.

**Goal:** Backport the superpowers v6.0.0 subagent-driven-development context/token-discipline system (file handoffs, durable progress ledger, reviewer-prompt discipline, turn-aware model selection) into `srepowers-core:subagent-driven-operation`, and the `writing-plans` Global Constraints + per-task Interfaces blocks into `srepowers-core:writing-operation-plans` — adapted to srepowers's two-stage review model, four-plugin namespace, and Claude Code + Codex runtimes.
**Risk Level:** Low — see frontmatter rationale.
**Rollback Plan:** `git restore`/`git revert` touched files; no external state mutated.
**Stakeholder Notification:** Repo owner only.

> **Status note (2026-07-23):** This plan was merged (PR #4). Marked
> `completed`. The 29th core skill `requesting-review-sre` was out of scope
> here and added subsequently.

---

## Context

**Why this change:** superpowers is at v6.0.3 (last change 2026-06-18); srepowers is at v5.3.2 (last change 2026-06-19). srepowers is methodologically inspired by superpowers but operationally autonomous (no runtime dependency; dangling `superpowers:` refs already removed). Since srepowers last diverged, superpowers shipped its **v6.0.0 SDD overhaul** — the single largest workflow-spine improvement upstream — and srepowers's parallel skills never absorbed it.

**What prompted it:** A coupling review (2026-06-22) comparing every srepowers↔superpowers parallel skill. The headline gap: `subagent-driven-operation` currently instructs the *opposite* of the new upstream discipline — it tells the controller to **paste full task text into prompts** (operator-prompt.md:13, SKILL.md:81,272), which is exactly the controller-context blowup the v6.0.0 file-handoff system was built to stop (a real upstream session hit 42k chars of pasted history). `writing-operation-plans` is also missing the Global Constraints and per-task Interfaces blocks that make file-handoff safe (subagents see only their own task).

**Intended outcome:** srepowers's subagent execution path stops pasting bulk artifacts through the controller's context: task briefs, review packages, and reports move as **files**; a **durable ledger** survives compaction; reviewer prompts gain anti-pre-judging and global-constraints-lens discipline; the plan format carries Global Constraints + Interfaces. The change preserves srepowers's distinctive elements (two-stage spec→quality review, execution-pattern selection, 7-dimension plan quality gate, Execution-Order ASCII diagram) and stays portable across Claude Code + Codex (no Antigravity/Pi/Copilot/Gemini scope added, per owner decision).

**Scope decided with owner:** SDD + plans pair only. Out of scope: writing-skills-sre "Match the Form" backport, brainstorming visual-companion, platform tool-mappings, requesting-code-review skill creation.

## Prerequisites

- **Tools (all present on this workstation; confirmed):** `bash`, `git`, `awk`, `wc`, `python3` (for `scripts/validate-repo.py`), `fd`, `rg`. No new dependencies.
- **`claude` CLI is NOT required to verify this plan.** The repo's `tests/claude-code/*.sh` invoke a live `claude -p` (test-helpers.sh:19) and are slow/non-deterministic; this plan does **not** run them as gates. Verification uses static checks (grep/script-execution/validate-repo) only. Author confirms the `claude`-driven suite is explicitly excluded from this plan's gates to avoid non-determinism.
- **Source of truth to copy from (read-only):**
  - `/home/yg/src/github/superpowers/skills/subagent-driven-development/SKILL.md`
  - `/home/yg/src/github/superpowers/skills/subagent-driven-development/scripts/{review-package,task-brief,sdd-workspace}`
  - `/home/yg/src/github/superpowers/skills/writing-plans/SKILL.md` (Global Constraints §69-77, Interfaces §89-93)
- **Target repo:** `/home/yg/src/github/srepowers` — work on a feature branch off `main` (GitHub flow; no protected merge sequence per `~/src/github/CLAUDE.md`).
- **Current versions to bump (5 manifest/marketplace files — all currently `5.3.2`):**
  - `.claude-plugin/marketplace.json`
  - `.agents/plugins/marketplace.json`
  - `plugins/srepowers-core/.claude-plugin/plugin.json`
  - `plugins/srepowers-core/.codex-plugin/plugin.json`
  - `.codex-plugin/plugin.json`
  - (and the other three plugins' `.claude-plugin/plugin.json` + `.codex-plugin/plugin.json` — domain/infra/private — all four plugins share one version per CLAUDE.md "All 4 plugin versions must stay in sync". Confirm full set in Task 8.)

## Requirements Traceability

| Requirement (from coupling review) | Task(s) | Status |
|-----------------------------------|---------|--------|
| File-handoff scripts exist, srepowers-namespaced (`.srepowers/sdd/`) | Task 1 | pending |
| SDD SKILL.md: file handoffs replace pasted task text | Task 3 | pending |
| SDD SKILL.md: durable progress ledger (survives compaction) | Task 3 | pending |
| SDD SKILL.md: Pre-Flight Plan Review | Task 3 | pending |
| SDD SKILL.md: Continuous execution | Task 3 | pending |
| SDD SKILL.md: Handling Reviewer ⚠️ items | Task 3 | pending |
| SDD SKILL.md: Constructing Reviewer Prompts (no pre-judging, constraints lens, BASE not HEAD~1) | Task 3 | pending |
| SDD SKILL.md: turn-aware model selection + explicit model per dispatch | Task 3 | pending |
| operator-prompt.md: read brief file + write report file | Task 2 | pending |
| spec + artifact reviewer prompts: consume brief/report/package files | Task 2 | pending |
| Migrate test-subagent-driven-operation.sh Test 7 (file-handoff inverts old assertion) | Task 4 | pending |
| writing-operation-plans: Global Constraints block | Task 5 | pending |
| writing-operation-plans: per-task Interfaces block | Task 5 | pending |
| writing-operation-plans: REQUIRED SUB-SKILL handoff stays consistent | Task 5 | pending |
| README/AGENTS/CLAUDE doc references updated where they describe SDD behavior | Task 7 | pending |
| Cross-platform: scripts degrade gracefully without bash (Codex) | Task 3 (prose) | pending |
| Version bump across all 4 plugins + marketplace | Task 8 | pending |
| Repo validation passes (validate-repo.py + symlink integrity) | Task 9 | pending |

## Execution Order

```
        ┌──────────── ARTIFACTS (one branch, no remote action) ────────────┐
        │  Task 1  add 3 SDD scripts (.srepowers/sdd path)                  │
        │              ▼ (scripts must exist before SKILL/prompts cite them)│
        │  Task 2  rewrite 3 prompt templates (brief/report/package files)  │
        │  Task 3  rewrite SDD SKILL.md (handoffs, ledger, reviewer rules)  │
        │              (Task 2 & 3 both cite Task 1 paths; do 2→3 in order) │
        └───────────────────────────────┬─────────────────────────────────┘
                                        ▼
        Task 4  migrate test-subagent-driven-operation.sh (invert Test 7)
                                        ▼
        ┌──────────── PLAN-SKILL (independent of SDD tasks) ───────────────┐
        │  Task 5  writing-operation-plans: Global Constraints + Interfaces │
        │  Task 6  migrate/extend test-writing-operation-plans.sh          │
        └───────────────────────────────┬─────────────────────────────────┘
                                        ▼
        Task 7  docs sync (README / AGENTS.md / CLAUDE.md SDD descriptions)
                                        ▼
        Task 8  version bump (all 4 plugins + 2 marketplaces, in sync)
                                        ▼
        Task 9  repo validation gate (validate-repo.py + symlinks + script smoke)

Legend:  ▼ sequential   [box] = same-phase group (order inside box as noted)
         No ◆ approval gates, no ║ ║ hard gates — low-risk local repo work,
         no environment crossing, no irreversible step.
```

## Tasks

### Task 1: Add srepowers-namespaced SDD handoff scripts

**Goal:** Create the three file-handoff scripts under the SDD skill, rewritten to use `.srepowers/sdd/` (not `.superpowers/sdd/`).
**Files/Resources:** Create `plugins/srepowers-core/skills/subagent-driven-operation/scripts/sdd-workspace`, `.../scripts/task-brief`, `.../scripts/review-package` (all `chmod +x`).
**Verification:** `bash -n` on each script, then a live smoke run in a throwaway git repo.
**Expected (Before):** `test -d plugins/srepowers-core/skills/subagent-driven-operation/scripts` → fails (dir absent).
**Expected (GREEN):** all three scripts exist, pass `bash -n`, and `sdd-workspace` prints a path ending in `.srepowers/sdd`.
**Rollback:** `git restore --staged --worktree plugins/srepowers-core/skills/subagent-driven-operation/scripts/ && rm -rf plugins/srepowers-core/skills/subagent-driven-operation/scripts`
**Side Effects Check:** `git status --short` shows only the new scripts; no other file touched.

**Step 1: RED - confirm scripts absent**
```bash
test -d plugins/srepowers-core/skills/subagent-driven-operation/scripts && echo PRESENT || echo ABSENT
```
**Expected:** `ABSENT`

**Step 2: Verify RED**
Run the command above. Expected: `ABSENT`.

**Step 3: Dry-run (no live mutation — static authoring)**
Not applicable: file creation in a git working tree is reversible via `git restore`/`rm`; the RED check + git index are the safety net. (Per the skill: dry-run is for live infra mutations.)

**Step 4: GREEN - create the three scripts**

`sdd-workspace` (adapt superpowers `sdd-workspace` — change only the path and the explanatory comment):
```bash
#!/usr/bin/env bash
# Resolve and ensure the working-tree directory srepowers SDD uses for its
# short-lived artifacts: task briefs, operator reports, review packages, and
# the progress ledger. Print the directory's absolute path.
#
# Lives in the working tree (not under .git/) because Claude Code treats .git/
# as a protected path and denies agent writes there — which would block an
# operator subagent from writing its report file. A self-ignoring .gitignore
# keeps the workspace out of `git status` and out of accidental commits.
#
# Single source of truth for the workspace location, so task-brief and
# review-package cannot drift to different directories.
#
# Usage: sdd-workspace
set -euo pipefail

root=$(git rev-parse --show-toplevel)
dir="$root/.srepowers/sdd"
mkdir -p "$dir"
printf '*\n' > "$dir/.gitignore"
cd "$dir" && pwd
```

`task-brief` (adapt superpowers `task-brief` verbatim except: default OUTFILE comment says `.srepowers/sdd`, and it resolves the dir via the local `sdd-workspace`). The awk task-extraction logic is unchanged — it already matches `^#+[ \t]+Task[ \t]+N` which covers srepowers's `### Task N:` headings:
```bash
#!/usr/bin/env bash
# Extract one task's full text from an operation plan into a file the operator
# reads in one call, so the task text never has to be pasted through the
# controller's context.
#
# Usage: task-brief PLAN_FILE TASK_NUMBER [OUTFILE]
# Default OUTFILE: <repo-root>/.srepowers/sdd/task-<N>-brief.md
set -euo pipefail

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "usage: task-brief PLAN_FILE TASK_NUMBER [OUTFILE]" >&2
  exit 2
fi

plan=$1
n=$2
[ -f "$plan" ] || { echo "no such plan file: $plan" >&2; exit 2; }

if [ $# -eq 3 ]; then
  out=$3
else
  dir=$("$(cd "$(dirname "$0")" && pwd)/sdd-workspace")
  out="$dir/task-${n}-brief.md"
fi

awk -v n="$n" '
  /^```/ { infence = !infence }
  !infence && /^#+[ \t]+Task[ \t]+[0-9]+/ {
    intask = ($0 ~ ("^#+[ \t]+Task[ \t]+" n "([^0-9]|$)"))
  }
  intask { print }
' "$plan" > "$out"

if [ ! -s "$out" ]; then
  echo "task ${n} not found in ${plan} (no heading matching 'Task ${n}')" >&2
  exit 3
fi

echo "wrote ${out}: $(wc -l < "$out" | tr -d ' ') lines"
```

`review-package` (adapt superpowers `review-package` verbatim except default-OUTFILE comment path `.srepowers/sdd`):
```bash
#!/usr/bin/env bash
# Generate a review package: commit list, stat summary, and the net diff with
# extended context, written to a file the reviewer reads in one call. Using the
# recorded per-task BASE (not HEAD~1) keeps multi-commit tasks intact.
#
# Usage: review-package BASE HEAD [OUTFILE]
# Default OUTFILE: <repo-root>/.srepowers/sdd/review-<base7>..<head7>.diff
set -euo pipefail

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "usage: review-package BASE HEAD [OUTFILE]" >&2
  exit 2
fi

base=$1
head=$2

git rev-parse --verify --quiet "$base" >/dev/null || { echo "bad BASE: $base" >&2; exit 2; }
git rev-parse --verify --quiet "$head" >/dev/null || { echo "bad HEAD: $head" >&2; exit 2; }

if [ $# -eq 3 ]; then
  out=$3
else
  dir=$("$(cd "$(dirname "$0")" && pwd)/sdd-workspace")
  out="$dir/review-$(git rev-parse --short "$base")..$(git rev-parse --short "$head").diff"
fi

{
  echo "# Review package: ${base}..${head}"
  echo
  echo "## Commits"
  git log --oneline "${base}..${head}"
  echo
  echo "## Files changed"
  git diff --stat "${base}..${head}"
  echo
  echo "## Diff"
  git diff -U10 "${base}..${head}"
} > "$out"

commits=$(git rev-list --count "${base}..${head}")
echo "wrote ${out}: ${commits} commit(s), $(wc -c < "$out" | tr -d ' ') bytes"
```

Then: `chmod +x plugins/srepowers-core/skills/subagent-driven-operation/scripts/{sdd-workspace,task-brief,review-package}`

**Step 5: Verify GREEN — syntax + live smoke test**
```bash
cd plugins/srepowers-core/skills/subagent-driven-operation/scripts
for s in sdd-workspace task-brief review-package; do bash -n "$s" && echo "ok: $s"; done
# Live smoke in a throwaway repo (proves scripts run end-to-end):
TMP=$(mktemp -d); ( cd "$TMP" && git init -q && git commit -q --allow-empty -m base
  WS=$("$OLDPWD"/sdd-workspace 2>/dev/null) ; OLDPWD2=$PWD
  printf '### Task 1: Demo\n\nbody line\n\n### Task 2: Other\n' > plan.md
  "$OLDPWD"/task-brief plan.md 1 >/dev/null && echo "task-brief ok"
  git commit -q --allow-empty -m second
  "$OLDPWD"/review-package HEAD~1 HEAD >/dev/null && echo "review-package ok"
  echo "workspace: $WS" ); rm -rf "$TMP"
cd "$OLDPWD"  # back to repo root
```
**Expected:** `ok: sdd-workspace`, `ok: task-brief`, `ok: review-package`, `task-brief ok`, `review-package ok`, and `workspace:` line ending in `/.srepowers/sdd`.

**Step 6: Verify no side effects**
```bash
cd /home/yg/src/github/srepowers && git status --short
```
**Expected:** only the three new `scripts/*` paths under `subagent-driven-operation/` appear (untracked). Nothing else.

**Step 7: Commit**
```bash
git add plugins/srepowers-core/skills/subagent-driven-operation/scripts/
git commit -m "feat(subagent-driven-operation): add file-handoff scripts (task-brief, review-package, sdd-workspace)"
```

---

### Task 2: Rewrite the three prompt templates for file handoffs

**Goal:** Convert operator-prompt.md, spec-reviewer-prompt.md, artifact-quality-reviewer-prompt.md from "paste full task text" to "read your brief file / write your report file / read the review package", mirroring superpowers' implementer + task-reviewer prompts but preserving srepowers's **two separate reviewer prompts** and TDO/deviation content.
**Files/Resources:** Modify `plugins/srepowers-core/skills/subagent-driven-operation/operator-prompt.md`, `.../spec-reviewer-prompt.md`, `.../artifact-quality-reviewer-prompt.md`.
**Verification:** grep that each prompt now references a brief/report/package file path and no longer instructs pasting the full task text as the source of requirements.
**Expected (Before):** `rg -c 'FULL TEXT of task' operator-prompt.md` → `1` (the paste instruction is present).
**Expected (GREEN):** operator-prompt.md references reading a brief file and writing a report file; reviewer prompts reference the brief/report/review-package paths; the `[FULL TEXT of task ...]` paste-as-requirements instruction is gone.
**Rollback:** `git restore plugins/srepowers-core/skills/subagent-driven-operation/{operator,spec-reviewer,artifact-quality-reviewer}-prompt.md`
**Side Effects Check:** `git diff --stat` shows only these three prompt files changed.

**Step 1: RED - confirm paste instruction present**
```bash
cd plugins/srepowers-core/skills/subagent-driven-operation
rg -n 'FULL TEXT of task|paste it here|don.t make subagent read file' operator-prompt.md
```
**Expected:** matches at operator-prompt.md (the current paste-based contract).

**Step 2: Verify RED**
Run above; confirm the paste instructions exist (baseline).

**Step 3: Dry-run** — N/A (reversible markdown edit; git index is the safety net).

**Step 4: GREEN - edit the three prompts**

Edit `operator-prompt.md` — replace the "## Task Description / [FULL TEXT ...]" block and the "Input artifacts: [Task text]" lines with a file-handoff contract modeled on superpowers `implementer-prompt.md`:
- Dispatch carries: (1) one line on where the task fits; (2) **brief file path**, introduced as "read this first — it is your requirements, with exact values to use verbatim"; (3) interfaces/decisions from earlier tasks the brief can't know; (4) controller's resolution of any ambiguity; (5) **report file path** + report contract.
- Operator writes its full report to the report file; returns only status, commits, one-line verification summary, concerns.
- Keep ALL existing srepowers-specific sections verbatim: TDO Guidelines, Deviation Handling R1–R4, Self-Review, the four statuses. Only the *how requirements arrive* and *where the report goes* change.

Edit `spec-reviewer-prompt.md` and `artifact-quality-reviewer-prompt.md` — replace "[FULL TEXT of task requirements]" / "[From operator's report]" / "BASE_SHA…HEAD_SHA / git diff BASE_SHA HEAD_SHA" with three file paths: **brief file**, **report file**, **review-package file** (the package already contains commit list + stat + `-U10` diff, so the reviewer reads one file instead of running git). Add the global-constraints lens line: "Copy the plan's binding requirements verbatim; that block is your attention lens." Keep the skeptical-reviewer stance, two-stage ordering, and report formats.

**Step 5: Verify GREEN**
```bash
rg -n 'brief|report file|review package|review-package' operator-prompt.md spec-reviewer-prompt.md artifact-quality-reviewer-prompt.md
rg -c 'FULL TEXT of task' operator-prompt.md   # expect 0
```
**Expected:** each file references the brief/report/package files; `FULL TEXT of task` count is `0`.

**Step 6: Verify no side effects**
```bash
cd /home/yg/src/github/srepowers && git diff --stat
```
**Expected:** only the three prompt files under `subagent-driven-operation/`.

**Step 7: Commit**
```bash
git add plugins/srepowers-core/skills/subagent-driven-operation/operator-prompt.md \
        plugins/srepowers-core/skills/subagent-driven-operation/spec-reviewer-prompt.md \
        plugins/srepowers-core/skills/subagent-driven-operation/artifact-quality-reviewer-prompt.md
git commit -m "feat(subagent-driven-operation): prompt templates consume brief/report/review-package files"
```

---

### Task 3: Rewrite subagent-driven-operation SKILL.md with the v6.0.x discipline

**Goal:** Add the file-handoff system, durable progress ledger, Pre-Flight Plan Review, Continuous execution, Handling Reviewer ⚠️ items, Constructing Reviewer Prompts, and turn-aware model selection — while keeping srepowers's two-stage spec→quality review, execution-pattern selection (inline/segmented/full), and infra examples.
**Files/Resources:** Modify `plugins/srepowers-core/skills/subagent-driven-operation/SKILL.md`.
**Verification:** grep for each new section heading/marker AND for removal of the contradicting "paste full text" guidance; cross-references use `<plugin>:<skill>` namespace.
**Expected (Before):** `rg -c 'provide full text instead|Paste the relevant task text' SKILL.md` → ≥1 (old guidance present); `rg -c 'Durable Progress|review-package|Pre-Flight' SKILL.md` → 0.
**Expected (GREEN):** new sections present (Durable Progress / ledger, Pre-Flight Plan Review, Continuous execution, Handling Reviewer ⚠️ Items, Constructing Reviewer Prompts, File Handoffs, turn-aware model note); the "paste full text / provide full text instead" Red Flag is replaced by the "hand it its task brief" form; the script paths are cited; a "without bash (Codex)" fallback is documented.
**Rollback:** `git restore plugins/srepowers-core/skills/subagent-driven-operation/SKILL.md`
**Side Effects Check:** `git diff --stat` shows only SKILL.md; command-wrapper and symlinks untouched.

**Step 1: RED - confirm old guidance present, new sections absent**
```bash
cd plugins/srepowers-core/skills/subagent-driven-operation
rg -n 'provide full text instead|Paste the relevant task text directly' SKILL.md
rg -c 'Durable Progress|Pre-Flight Plan Review|review-package' SKILL.md   # expect 0
```
**Expected:** old paste guidance matches; new-section count `0`.

**Step 2: Verify RED**
Run above; confirm baseline.

**Step 3: Dry-run** — N/A (reversible markdown edit).

**Step 4: GREEN - edit SKILL.md**
Port these superpowers sections, adapted to srepowers (two-stage review, `.srepowers/sdd/` paths, `srepowers-core:` namespace, infra framing):
- **Narration** + **Continuous execution** (don't pause between tasks).
- **Pre-Flight Plan Review** (scan for plan/Global-Constraints conflicts; batch as one question before Task 1).
- **Model Selection** — add the turn-count cost note + "always specify the model explicitly when dispatching" (keep srepowers's haiku/sonnet/opus infra table).
- **Handling Operator Status → DONE** now generates the review package (`scripts/review-package BASE HEAD`, BASE = recorded pre-dispatch commit, **never `HEAD~1`**) before dispatching the spec reviewer.
- **Handling Reviewer ⚠️ items** (cannot-verify-from-diff → controller resolves; real gap = failed spec review).
- **Constructing Reviewer Prompts** (no open-ended directives; **never pre-judge / "do not flag" / pre-rate severity**; global-constraints block is the lens; hand the diff as a file via review-package; one fix subagent for the final review's findings list).
- **File Handoffs** (task-brief → brief file; report file named after brief; reviewer inputs = brief + report + package paths).
- **Durable Progress** (ledger at `.srepowers/sdd/progress.md`; append one line per clean task; trust ledger + `git log` after compaction; `git clean -fdx` destroys it → recover from `git log`).
- **Prompt Templates** list: keep the three srepowers prompts; update the process flowchart so per-task flow is "operator → (review-package) → spec reviewer → artifact reviewer", and update DONE/ledger bookkeeping.
- **Cross-platform note (NEW):** scripts are the bash fast path; without bash (e.g. some Codex setups), the controller produces the same artifacts manually (`git log --oneline`, `git diff --stat`, `git diff -U10 BASE..HEAD` redirected to one uniquely named file under `.srepowers/sdd/`; write the brief/report files by hand). Functionality, not the script, is the requirement.
- **Red Flags:** replace "Make subagent read plan file (provide full text instead)" with "Make a subagent read the whole plan file (hand it its task brief — `scripts/task-brief` — instead)"; add "Dispatch a reviewer without a review-package file"; add "Re-dispatch a task the progress ledger already marks complete"; add "Tell a reviewer what not to flag / pre-rate severity".
- Preserve: When-to-Use, Execution Pattern Selection table, Subagent Contract, Why Review Order Matters, Infrastructure Operation Examples, Integration.

**Step 5: Verify GREEN**
```bash
rg -n 'Durable Progress|Pre-Flight Plan Review|Handling Reviewer|Constructing Reviewer Prompts|File Handoffs|review-package|task-brief|\.srepowers/sdd' SKILL.md
rg -c 'provide full text instead' SKILL.md   # expect 0
rg -n 'srepowers-core:' SKILL.md             # cross-refs namespaced
rg -n 'HEAD~1' SKILL.md                       # must appear only in the "never HEAD~1" warning
```
**Expected:** all new sections present; old paste guidance count `0`; cross-references namespaced; `HEAD~1` only in the cautionary context.

**Step 6: Verify no side effects**
```bash
cd /home/yg/src/github/srepowers && git diff --stat
ls -la plugins/srepowers-core/commands/subagent-driven-operation.md   # wrapper unchanged
```
**Expected:** only SKILL.md changed; command wrapper file still present and unmodified.

**Step 7: Commit**
```bash
git add plugins/srepowers-core/skills/subagent-driven-operation/SKILL.md
git commit -m "feat(subagent-driven-operation): file handoffs, durable ledger, reviewer-prompt discipline, turn-aware models"
```

---

### Task 4: Migrate test-subagent-driven-operation.sh (invert the file-handoff assertion)

**Goal:** Test 7 currently asserts the skill says "provide directly / paste" and `assert_not_contains` "read.*file" — the exact opposite of the new behavior. Rewrite Test 7 to assert the file-handoff model; leave Tests 1–6, 8–10 intact (they still hold).
**Files/Resources:** Modify `tests/claude-code/test-subagent-driven-operation.sh`.
**Verification:** `bash -n` the test; static-grep that Test 7's assertions now target brief/report files and no longer forbid "read file".
**Expected (Before):** `rg -n 'Doesn.t make subagent read file|Provides text directly' test-subagent-driven-operation.sh` → matches (old Test 7).
**Expected (GREEN):** Test 7 asserts the controller hands the subagent a **brief file** (and writes a **report file**); the old `assert_not_contains ... "read.*file"` assertion is gone or inverted.
**Rollback:** `git restore tests/claude-code/test-subagent-driven-operation.sh`
**Side Effects Check:** `git diff --stat` shows only this test file.

**Step 1: RED - confirm contradicting assertions present**
```bash
cd tests/claude-code
rg -n "Provides text directly|Doesn.t make subagent read file|provide.\*directly" test-subagent-driven-operation.sh
```
**Expected:** the old Test 7 assertions appear (lines ~125 and ~131).

**Step 2: Verify RED**
Run above; confirm baseline.

**Step 3: Dry-run** — N/A.

**Step 4: GREEN - rewrite Test 7**
Replace the Test 7 block. New prompt + assertions (use existing `assert_contains` helper):
- Prompt: "In subagent-driven-operation, how does the controller give a subagent its task — does it paste the full task text, or hand over a file the subagent reads?"
- `assert_contains "$output" "brief\|file\|task-brief" "Hands over a brief file"`
- `assert_contains "$output" "report file\|report\|review.package\|review-package" "Artifacts move as files"`
- Remove the `assert_not_contains ... "read.*file"` assertion (it now contradicts intended behavior).
Keep the surrounding `echo`/exit structure identical to the other tests.

**Step 5: Verify GREEN**
```bash
bash -n test-subagent-driven-operation.sh && echo "syntax ok"
rg -n "brief|report file|review-package" test-subagent-driven-operation.sh
rg -c "Doesn.t make subagent read file" test-subagent-driven-operation.sh   # expect 0
```
**Expected:** `syntax ok`; new assertions present; old anti-file assertion count `0`.

**Step 6: Verify no side effects**
```bash
cd /home/yg/src/github/srepowers && git diff --stat
```
**Expected:** only `tests/claude-code/test-subagent-driven-operation.sh`.

**Step 7: Commit**
```bash
git add tests/claude-code/test-subagent-driven-operation.sh
git commit -m "test(subagent-driven-operation): assert file-handoff model in Test 7"
```

---

### Task 5: Add Global Constraints + Interfaces to writing-operation-plans

**Goal:** Add the superpowers `writing-plans` **Global Constraints** header block and per-task **Interfaces (Consumes/Produces)** block to the srepowers plan format, without disturbing the existing frontmatter, Execution-Order diagram, Output Contract, or 7-dimension quality gate.
**Files/Resources:** Modify `plugins/srepowers-core/skills/writing-operation-plans/SKILL.md`.
**Verification:** grep that both new blocks are documented in the plan-document template and the task-structure template.
**Expected (Before):** `rg -c 'Global Constraints|Interfaces' SKILL.md` → `0`.
**Expected (GREEN):** the plan header template includes a `## Global Constraints` block (verbatim project-wide rules every task inherits); the Task Structure includes an **Interfaces** block (Consumes / Produces with exact signatures); a one-line rationale ties Interfaces to subagent isolation.
**Rollback:** `git restore plugins/srepowers-core/skills/writing-operation-plans/SKILL.md`
**Side Effects Check:** `git diff --stat` shows only this SKILL.md; `plan-checker-prompt.md` untouched (quality-gate dimensions unchanged — Global Constraints/Interfaces are additive, not new gate dimensions).

**Step 1: RED**
```bash
rg -c 'Global Constraints|Interfaces' plugins/srepowers-core/skills/writing-operation-plans/SKILL.md
```
**Expected:** `0`.

**Step 2: Verify RED** — run above; confirm `0`.

**Step 3: Dry-run** — N/A.

**Step 4: GREEN - edit SKILL.md**
- In the **Plan Document Format** block, after the `**Goal/Risk/Rollback/Stakeholder**` lines and before `## Prerequisites`, add:
  ```markdown
  ## Global Constraints

  [Project-wide requirements every task implicitly inherits — version floors,
  naming/label conventions, namespace rules, tool-flag standards — one line
  each, exact values copied verbatim from the spec or ticket.]
  ```
- In the **Task Structure** template, after the `**Side Effects Check:**` header field, add an **Interfaces** block:
  ```markdown
  **Interfaces:**
  - Consumes: [what this task uses from earlier tasks — exact resource names, output values, file paths]
  - Produces: [what later tasks rely on — exact names/values a subagent must reuse verbatim; this block is how an isolated subagent learns neighboring tasks' identifiers]
  ```
- Add one sentence under Task Structure explaining: because subagent-driven-operation hands each operator only its own brief, the Interfaces block is the contract across task boundaries.
- Leave Execution Order, Output Contract, Frontmatter Rules, Plan Quality Gate, anti-patterns, handoff unchanged.

**Step 5: Verify GREEN**
```bash
rg -n '## Global Constraints|\*\*Interfaces:\*\*|Consumes:|Produces:' plugins/srepowers-core/skills/writing-operation-plans/SKILL.md
```
**Expected:** Global Constraints heading + Interfaces/Consumes/Produces lines present.

**Step 6: Verify no side effects**
```bash
cd /home/yg/src/github/srepowers && git diff --stat
git diff --stat plugins/srepowers-core/skills/writing-operation-plans/plan-checker-prompt.md   # expect no output
```
**Expected:** only writing-operation-plans/SKILL.md changed.

**Step 7: Commit**
```bash
git add plugins/srepowers-core/skills/writing-operation-plans/SKILL.md
git commit -m "feat(writing-operation-plans): add Global Constraints and per-task Interfaces blocks"
```

---

### Task 6: Extend test-writing-operation-plans.sh for the new blocks

**Goal:** Add a test asserting the skill documents Global Constraints + Interfaces, consistent with the existing 4-test style.
**Files/Resources:** Modify `tests/claude-code/test-writing-operation-plans.sh`.
**Verification:** `bash -n`; grep that a new test references Global Constraints / Interfaces.
**Expected (Before):** `rg -c 'Global Constraints|Interfaces' tests/claude-code/test-writing-operation-plans.sh` → `0`.
**Expected (GREEN):** a new Test 5 asserts the skill mentions Global Constraints and per-task Interfaces; file passes `bash -n`.
**Rollback:** `git restore tests/claude-code/test-writing-operation-plans.sh`
**Side Effects Check:** `git diff --stat` shows only this test file.

**Step 1: RED**
```bash
rg -c 'Global Constraints|Interfaces' tests/claude-code/test-writing-operation-plans.sh
```
**Expected:** `0`.

**Step 2: Verify RED** — run above.

**Step 3: Dry-run** — N/A.

**Step 4: GREEN - add Test 5**
Before the final `echo "=== All writing-operation-plans skill tests passed ==="`, append:
```bash
# Test 5: Global Constraints and Interfaces blocks
echo "Test 5: Global Constraints and Interfaces..."

output=$(run_claude "In writing-operation-plans, does the plan format include a Global Constraints block and per-task Interfaces (Consumes/Produces)? Why do they matter for subagent execution?" 30)

if assert_contains "$output" "Global Constraints\|global constraint" "Mentions Global Constraints"; then : ; else exit 1; fi
if assert_contains "$output" "Interfaces\|Consumes\|Produces" "Mentions Interfaces block"; then : ; else exit 1; fi

echo ""
```

**Step 5: Verify GREEN**
```bash
bash -n tests/claude-code/test-writing-operation-plans.sh && echo "syntax ok"
rg -n 'Global Constraints|Interfaces' tests/claude-code/test-writing-operation-plans.sh
```
**Expected:** `syntax ok`; new Test 5 references present.

**Step 6: Verify no side effects**
```bash
cd /home/yg/src/github/srepowers && git diff --stat
```
**Expected:** only `tests/claude-code/test-writing-operation-plans.sh`.

**Step 7: Commit**
```bash
git add tests/claude-code/test-writing-operation-plans.sh
git commit -m "test(writing-operation-plans): assert Global Constraints and Interfaces blocks"
```

---

### Task 7: Sync documentation that describes SDD behavior

**Goal:** Update any prose in README.md / AGENTS.md / CLAUDE.md (and `docs/`) that describes subagent-driven-operation as pasting task text, so docs match the new file-handoff model. Touch only statements that are now inaccurate.
**Files/Resources:** Modify (only where inaccurate) `README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/comparison-claude.md`.
**Verification:** grep that no doc still claims the controller pastes full task text into subagent prompts as the mechanism.
**Expected (Before):** `rg -rn 'paste.*task text|provide full text|read the plan file' README.md AGENTS.md CLAUDE.md docs/ 2>/dev/null` → list candidate lines to review (may be empty; if empty, this task is a no-op confirmation).
**Expected (GREEN):** no doc describes the old paste mechanism as current; if nothing referenced it, task is a verified no-op.
**Rollback:** `git restore README.md AGENTS.md CLAUDE.md docs/comparison-claude.md`
**Side Effects Check:** `git diff --stat` shows only doc files (or nothing).

**Step 1: RED - find stale doc claims**
```bash
cd /home/yg/src/github/srepowers
rg -rn 'paste.*task text|provide full text|make.*subagent read|reads? the plan file' README.md AGENTS.md CLAUDE.md docs/ 2>/dev/null || echo "NO STALE REFERENCES"
```
**Expected:** either a small candidate list, or `NO STALE REFERENCES`.

**Step 2: Verify RED**
Review each hit in context (Read the surrounding lines). If `NO STALE REFERENCES`, record that this task is a no-op and skip to Step 6.

**Step 3: Dry-run** — N/A.

**Step 4: GREEN - targeted edits**
For each genuinely stale line, edit to describe the file-handoff model (brief/report/package files, durable ledger). Do **not** rewrite unrelated doc prose. Note: `AGENTS.md`/`CLAUDE.md` are local-context files; per `~/src/github/CLAUDE.md` they may be gitignored symlinks — if `git status` shows them ignored, edit the underlying file but expect no commit entry for them.

**Step 5: Verify GREEN**
```bash
rg -rn 'paste.*task text|provide full text' README.md AGENTS.md docs/ 2>/dev/null || echo "CLEAN"
```
**Expected:** `CLEAN` (or only intentional historical-plan references under `docs/plans/` remain, which are dated records and must NOT be edited).

**Step 6: Verify no side effects**
```bash
git diff --stat
```
**Expected:** only doc files changed (or empty if no-op).

**Step 7: Commit** (skip if no-op)
```bash
git add README.md docs/comparison-claude.md   # add AGENTS.md/CLAUDE.md only if tracked
git commit -m "docs: describe subagent-driven-operation file-handoff model"
```

---

### Task 8: Version bump across all 4 plugins + 2 marketplaces

**Goal:** Bump the shared version from `5.3.2` to `5.4.0` (MINOR — additive workflow features) in every manifest and marketplace, keeping all four plugins in sync per CLAUDE.md.
**Files/Resources:** Modify version in: `.claude-plugin/marketplace.json`, `.agents/plugins/marketplace.json`, and each plugin's `.claude-plugin/plugin.json` + `.codex-plugin/plugin.json` (core, domain, infra, private), plus top-level `.codex-plugin/plugin.json`.
**Verification:** grep that no manifest still reads `5.3.2` and all read `5.4.0`.
**Expected (Before):** `rg -rl '"5\.3\.2"' --glob '*.json' .` lists the manifest/marketplace files.
**Expected (GREEN):** `rg -rn '"5\.3\.2"' --glob '*.json' .` → no output; `rg -rl '"5\.4\.0"'` lists exactly the manifest/marketplace files.
**Rollback:** `git restore` the listed JSON files.
**Side Effects Check:** `git diff` shows only `version` lines changed in JSON (no structural edits).

**Step 1: RED - enumerate current version files**
```bash
cd /home/yg/src/github/srepowers
rg -rln '"version"\s*:\s*"5\.3\.2"' --glob '*.json' .
```
**Expected:** the full set of plugin.json + marketplace.json files (record this list — Step 5 checks the same set flips).

**Step 2: Verify RED**
Run above; confirm the complete set (cross-check against CLAUDE.md's "all 4 plugins + marketplace").

**Step 3: Dry-run** — N/A (JSON field edit; verified by diff).

**Step 4: GREEN - bump each file**
For each file from Step 1, change only the `"version": "5.3.2"` line to `"version": "5.4.0"` (use targeted edits per file; do not reformat JSON). marketplace.json may carry a top-level version AND per-plugin versions — update all occurrences of `5.3.2` within it.

**Step 5: Verify GREEN**
```bash
rg -rn '"5\.3\.2"' --glob '*.json' . && echo "STILL HAS OLD" || echo "no 5.3.2 remaining"
rg -rln '"5\.4\.0"' --glob '*.json' .
```
**Expected:** `no 5.3.2 remaining`; the `5.4.0` file list equals the Step 1 set.

**Step 6: Verify no side effects**
```bash
git diff --stat
# Confirm only version lines changed (no accidental structural diff):
git diff --glob '*.json' | rg '^[+-]' | rg -v '^[+-]{3}' | rg -v '"version"' || echo "only version lines changed"
```
**Expected:** `only version lines changed`.

**Step 7: Commit**
```bash
git add -- $(rg -rl '"5\.4\.0"' --glob '*.json' .)
git commit -m "chore: bump all plugins and marketplace to 5.4.0"
```

---

### Task 9: Repo validation gate

**Goal:** Confirm the repository is structurally valid after all changes — validator passes, symlinks resolve, scripts are executable and syntactically valid, skill/command parity holds.
**Files/Resources:** No edits — verification only (read-only over the whole repo).
**Verification:** `python3 scripts/validate-repo.py` exits 0; symlink + script checks pass.
**Expected (Before):** N/A (this is the final gate; "before" = after Task 8 commit).
**Expected (GREEN):** validator exits 0 with no errors; all `.codex/skills` + `.agents/skills` symlinks resolve; the three new scripts are `-x` and pass `bash -n`.
**Rollback:** N/A (no mutation). If validation fails, fix forward in the responsible task or `git revert` the offending commit.
**Side Effects Check:** `git status --short` clean (everything committed); no untracked artifacts (especially no `.srepowers/` leaking — it is git-ignored by sdd-workspace, but confirm it is not staged).

**Step 1: RED/Baseline - run validator**
```bash
cd /home/yg/src/github/srepowers
python3 scripts/validate-repo.py; echo "validator exit: $?"
```
**Expected:** exit `0`. (If the validator counts skills/commands, parity is unchanged — no skills added/removed, only edited — so it should pass.)

**Step 2: Verify - symlink integrity**
```bash
# every skill symlink resolves
for d in .codex/skills .agents/skills; do
  find "$d" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null
done; echo "broken-symlink scan done (no paths above = all resolve)"
```
**Expected:** no broken-symlink paths printed. (No new skills were added, so no new symlinks are required — confirm the existing set is intact.)

**Step 3: Verify - scripts executable + valid**
```bash
cd plugins/srepowers-core/skills/subagent-driven-operation/scripts
for s in sdd-workspace task-brief review-package; do
  test -x "$s" && bash -n "$s" && echo "ok: $s" || echo "FAIL: $s"
done
cd /home/yg/src/github/srepowers
```
**Expected:** `ok:` for all three.

**Step 4: Verify - no stray workspace committed**
```bash
git status --short
git ls-files .srepowers 2>/dev/null && echo "LEAK: .srepowers tracked" || echo ".srepowers not tracked (correct)"
```
**Expected:** clean working tree; `.srepowers not tracked (correct)`.

**Step 5: GREEN - whole-suite static recheck**
```bash
# Static re-greps proving every requirement landed (no claude CLI):
rg -c 'review-package|task-brief|Durable Progress|Pre-Flight Plan Review' plugins/srepowers-core/skills/subagent-driven-operation/SKILL.md
rg -c '## Global Constraints|\*\*Interfaces:\*\*' plugins/srepowers-core/skills/writing-operation-plans/SKILL.md
rg -c 'brief|report file' plugins/srepowers-core/skills/subagent-driven-operation/operator-prompt.md
```
**Expected:** all counts ≥1.

**Step 6: Side-effect / completion check**
```bash
git log --oneline -9   # the 8 implementation commits (Task 7 may be no-op)
```
**Expected:** commits for Tasks 1–6, 8 present (Task 7 only if docs changed); tree clean.

**Step 7: Commit** — N/A (verification only; no changes to commit).

---

## Final Verification

After completing all tasks, run these to verify overall success:

1. `python3 scripts/validate-repo.py; echo "exit: $?"`
2. `for s in plugins/srepowers-core/skills/subagent-driven-operation/scripts/*; do bash -n "$s" && echo "ok: $s"; done`
3. `rg -c 'review-package|Durable Progress|File Handoffs' plugins/srepowers-core/skills/subagent-driven-operation/SKILL.md`
4. `rg -c '## Global Constraints|\*\*Interfaces:\*\*' plugins/srepowers-core/skills/writing-operation-plans/SKILL.md`
5. `rg -c 'FULL TEXT of task' plugins/srepowers-core/skills/subagent-driven-operation/operator-prompt.md` (expect `0`)
6. `git status --short` (expect clean)

Expected outputs:
- validator exit `0`
- `ok:` for all three scripts
- counts ≥1 for items 3–4
- `0` for item 5 (paste instruction fully removed)
- clean working tree

If any verification fails:
- Run rollback (`git restore` / `git revert`) for the affected task's files
- Re-run that task's GREEN steps
- Re-run this Final Verification

## Plan Quality Gate (author self-check completed)

- **Rollback coverage:** every task has a concrete `git restore`/`git revert` rollback. ✓
- **Verification concreteness:** every task has exact grep/script commands with expected output. ✓
- **Environment boundary:** all work is local repo edits; no task touches any remote/infra environment (declared `mgmt` only as a formality; truly local). ✓
- **Pre-mutation safety gate:** changes are reversible markdown/script/JSON edits; the RED checks + git index are the safety net (dry-run N/A for non-infra file edits, stated explicitly per task). ✓
- **Side-effect checks:** every task ends with a `git diff --stat`/`git status` scope check. ✓
- **Risk consistency:** low risk matches blast radius (personal plugin repo, no consumers but owner, fully revertable). ✓
- **Command correctness:** verification uses `rg`/`bash -n`/`python3`/`git` — all confirmed present; **the `claude`-driven test suite is explicitly excluded** as a gate (non-deterministic, needs live model) and replaced by static greps; the **known test/skill conflict (Test 7) is owned by Task 4**; script awk pattern confirmed to match srepowers `### Task N:` headings. ✓
