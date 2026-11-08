---
name: skill-iterate
description: Use when a skill fails its test fixture and you want it fixed automatically — runs skill-test-runner, spawns a fix-agent to propose one surgical SKILL.md edit on failure, re-runs, up to 5 cycles. Restores the original if no cycle passes. Also use for "iterate until it passes", "make this skill green", "auto-fix this skill".
---

# Skill Iterate

An iterate-until-green loop for a skill. On each test failure, propose a
targeted edit to the skill's `SKILL.md` and retry, up to 5 cycles.

**Announce at start:** "I'm using the skill-iterate skill — up to 5 cycles
against `<fixture>`."

## Read this before running it

This skill **edits a skill file automatically** based on a sub-agent's
proposal. That is a mutation, and it carries the failure mode that makes
auto-fix loops dangerous: an agent optimizing against a rubric can make the
test pass by weakening what the skill says, not by fixing it.

The guards below exist for that reason and are not optional:

- **Snapshot first, restore on failure** — the original is written back unless
  a cycle genuinely passes.
- **Regression revert** — an edit that drops the score by more than 10 points
  is undone, judged in **2d** on the cycle *after* it, because that is the
  first run that measures it.
- **No-progress detection** — an identical *proposal* (`old_string` +
  `new_string`) ends the loop.
- **One surgical edit per cycle** — never a rewrite.
- **No nested dispatch** — you run the test inline; only the runner's single
  test agent is spawned.

**Run it on a clean working tree** so `git diff` shows exactly what it changed,
and **read the final diff before keeping the result.** A passing test is the
loop's exit condition, not evidence the skill got better.

## Invocation

```text
skill-iterate <skill-name> <fixture-path>
```

## Steps

### Step 1 — Snapshot the original

Read `plugins/*/skills/<skill-name>/SKILL.md` and hold its full content as
`original_skill_content`. Read the fixture.

**Refuse raw dumps** — filename matching `_raw\.(json|yaml)$` or content with a
`RAW DUMP` marker:

> Refusing: `<fixture-path>` looks like an uncurated raw dump, not a curated
> test fixture. See fixture-lint's `uncurated-raw-dump` rule.

Do not start the loop.

### Step 2 — Iterate (max 5 cycles)

Initialize `cycle = 1`, `best_score = -1`, `best_cycle = 0`,
`pre_edit_content = null`, `last_edit = null`, `all_results = []`.

`best_score`/`best_cycle` are **reporting only** — they tell the operator which
cycle came closest. They never select what stays on disk: a run that never
passes restores the original (2e), because a higher score on a still-failing
skill is not evidence the edits were improvements.

> **You run the test yourself — do not delegate the loop.** A dispatched
> subagent cannot dispatch further subagents
> (`srepowers-core:subagent-driven-operation`: *"a dispatched subagent never
> dispatches subagents"*), and in Claude Code it has no Task tool at all. So
> **you** — the orchestrator — execute [[skill-test-runner]]'s steps inline,
> spawning only the single test agent its Step 4 calls for. Handing the whole
> runner to a subagent makes the loop unable to reach its first verdict, and
> tempts that subagent into playing the test subject itself, which destroys
> the fresh-context isolation the runner exists to provide.

**2a — Run the test.** Follow [[skill-test-runner]]'s Steps 1–6 yourself
against `<skill-name>` and `<fixture-path>`. The one dispatch is its Step 4
test agent. Capture `passed`, `score`, `failure_summary`, `captured_output`.

**2b — Record.** Append to `all_results`:
`Cycle <N>: score=<score> status=<PASS|FAIL>` plus the failures.

**2c — Check for PASS.** If passed: report "PASS on cycle `<N>`. Skill is
green.", show `all_results`, exit the loop. **Do not restore** — leave the
modified file in place.

**2d — Judge the edit that produced this score.** `score` measures the content
as it stood entering this cycle — i.e. the result of the *previous* cycle's
edit, held in `last_edit`. Resolve it before proposing anything new:

- If `cycle == 1` (no prior edit), set `best_score = score`, `best_cycle = 1`,
  and continue.
- Else if `score < best_score - 0.1`: the previous cycle's edit regressed the
  skill. **Restore `pre_edit_content`** (the content that edit was applied to),
  log "Regression detected: cycle `<cycle-1>`'s edit dropped the score from
  `<best_score>` to `<score>`. Reverted." Do not update `best_*`.
- Else if `score > best_score`: set `best_score = score`, `best_cycle = cycle`.

This is the whole reward-hacking guard, and it must sit **after** the run that
measures the edit — never before it. Judging an edit that has not been scored
yet reverts the wrong one: the regression stays on disk while an innocent later
edit is undone.

**2e — Cycle limit.** If `cycle == 5` and still failing: write
`original_skill_content` back, report "Max cycles reached. Best was cycle
`<best_cycle>` with score `<best_score>`. Restored original.", show
`all_results`, exit.

**2f — Spawn the fix-agent** with this prompt:

```text
You are a skill improvement agent. A skill has failed its test. Propose a
minimal, targeted edit to its SKILL.md that addresses the specific failures.

## Current SKILL.md
<full current content>

## Test Fixture
<full fixture content>

## Failure Summary from this cycle
<failure_summary>

## Captured Output (what the skill actually produced)
<captured_output>

## Your task
Identify the root cause, then propose ONE targeted change:
- Do not rewrite the whole skill
- Do not add content unrelated to the failures
- Focus on the specific instruction, format spec, or missing step that caused it
- Be surgical: the smallest change that fixes the failures
- Do NOT weaken or delete an instruction merely to make an assertion pass —
  if the fixture is wrong, say so instead of proposing an edit

Output in this exact format:

### Root Cause
<1-2 sentences>

### Proposed Edit
old_string:
```
<exact text to replace — must be unique in the file>
```
new_string:
```
<replacement text>
```

### Reasoning
<why this addresses the failures without breaking what passed>
```

**2g — Parse** `old_string` and `new_string` from the response.

**2h — No-progress check.** If `(old_string, new_string)` equals `last_edit`,
the fix-agent has proposed the same change twice: restore
`original_skill_content`, report "Fix-agent proposed identical change on cycle
`<cycle>`. No progress detected. Restoring original.", exit. Comparing the
*proposal* rather than the resulting text is what makes this check fire — an
edit whose `old_string` was not found leaves the file byte-identical, so
comparing file contents cannot tell a repeat proposal from a failed apply.

**2i — Snapshot, then apply.** Set `pre_edit_content = <current file content>`
and `last_edit = (old_string, new_string)` **before** editing — 2d on the next
cycle needs both to judge and, if necessary, revert this edit. Then apply with
the Edit tool. If `old_string` is not found, log "WARNING: proposed old_string
not found in SKILL.md — skipping edit for cycle `<cycle>`" and leave
`pre_edit_content` set (the file is unchanged, so the next cycle's score
measures the same content again — which 2h will catch as no progress).

**2j** — `cycle += 1`, back to 2a.

> **Why the order changed.** An earlier draft judged the regression at this
> point, before the edit had ever been scored. That reverts the wrong edit: a
> regression introduced in cycle N is only measurable in cycle N+1, so checking
> here undoes N+1's fresh, unmeasured change while the actual regression stays
> on disk. The judgment lives in **2d**, immediately after the run that
> measures it.

### Step 3 — Final report

Always produce one:

```text
## Skill Iterate Report: <skill-name>
**Fixture:** <fixture-path>
**Cycles run:** <N>
**Final status:** <PASS|FAIL|RESTORED>

### Cycle History
<all_results>

### Skill State
- **Current SKILL.md:** <MODIFIED / RESTORED to original>
- **Net change:** <lines added/removed vs original, or "none">
```

State the final file state explicitly. "Cycles run: 5" with no `Skill State`
line leaves the reader unable to tell whether the file on disk is the original
or a mutation.

## When NOT to use this

- **When the fixture is the thing that is wrong.** If the skill is right and
  the assertion is bad, fix the fixture — auto-iterating will "fix" the skill
  into satisfying a wrong assertion.
- **On a skill that encodes a safety gate.** A loop optimizing for a passing
  assertion is the wrong tool for text whose job is to refuse. Edit those by
  hand.
- **On a dirty working tree**, where the loop's changes cannot be isolated in a
  diff.

## Limits

Five cycles is a budget, not a guarantee. A `RESTORED` outcome means the loop
could not find a fix, which is information — usually that the failure is in the
fixture, the mocks, or the skill's design rather than its wording.

Related: [[skill-test-runner]] (the runner it loops), [[fixture-lint]]
(validate the fixture first), `srepowers-core:writing-skills-sre` (authoring).
