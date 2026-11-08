# ops-brief

Action-first output mode for operations: every reply ordered so the next
action is the first thing on screen and nothing important is buried below it.
Not shorter for its own sake — restructured so an operator can act. Stays on
for the whole session. Ships as `srepowers-core:ops-brief`. (`SKILL.md` is
the agent-facing trigger doc; this file is for humans.)

## Use cases

- Mid-incident: get the next command immediately, not a preamble
- Long change windows: keep every response act-on-able, not just one terse message
- Cut hedging, recaps, and "let me know if" closers from operational output
- Keep brevity from eating a mandatory gate's required sections

## How-to

Say "ops-brief", "action-first", "adhd mode", or "stop burying the answer" —
or invoke the `srepowers-core:ops-brief` command. It persists across turns
until "stop ops-brief" or "normal mode".

Brevity has six overrides (see SKILL.md). Three matter most mid-change:
mandatory gates (`srepowers-core:evidence-first-reporting`,
`srepowers-core:verification-before-completion`,
`srepowers-core:safety-validator`) keep their full output contracts; a
mutating next step puts blast radius and rollback before the command; three
"still broken" turns in a row stop the command loop for one diagnostic question.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — mode contract: persistence, the six overrides, the pre-send
  deletion checklist, on/off phrases
- `references/rules.md` — the ten rules, each as a bad/good pair; loaded once
  at invocation, before the mode does anything

Adapted for operations from [i-have-adhd](https://github.com/ayghri/i-have-adhd)
by Ayoub G. (MIT).

---
Last Updated: 2026-09-14
