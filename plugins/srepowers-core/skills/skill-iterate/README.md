# skill-iterate

An iterate-until-green loop for a skill that fails its test fixture: run the
test, have a fix-agent propose one surgical `SKILL.md` edit per failure,
re-test — up to 5 cycles. If no cycle passes, the original file is restored.
Ships as `srepowers-core:skill-iterate`. (`SKILL.md` is the agent-facing
trigger doc; this file is for humans.)

## Use cases

- Auto-fix a skill whose fixture started failing after an edit
- Keep authoring test-driven: loop the runner until the fixture passes
- Learn when to stop: a `RESTORED` result means the failure is in the fixture, the mocks, or the skill design — not its wording

## How-to

Say "iterate until it passes", "make this skill green", or "auto-fix this
skill", or invoke directly:

```text
skill-iterate <skill-name> <fixture-path>
```

Run it on a clean working tree so `git diff` isolates what it changed — and
read that diff before keeping the result. A passing test is the exit
condition, not evidence the skill got better.

### Verify

Fixture: `evals/fixtures/skill-iterate/fixture-regression-revert.yaml` — run
it with the `srepowers-core:skill-test-runner` skill.

## Reference

| Guard | Behavior |
|-------|----------|
| Snapshot/restore | Original written back unless a cycle genuinely passes |
| Regression revert | An edit dropping the score by >10 points is undone (judged the cycle after it) |
| No-progress detection | An identical proposed edit ends the loop |
| One edit per cycle | Surgical change only, never a rewrite |
| 5-cycle budget | Hard cap; best-scoring cycle reported |

Do NOT use it when the fixture itself is wrong (fix the fixture), on a skill
that encodes a safety gate (edit by hand), or on a dirty working tree.

- `SKILL.md` — loop steps, fix-agent prompt, final report format

---
Last Updated: 2026-09-14
