# subagent-driven-operation

Execute an infrastructure operation plan in the current session by
dispatching a fresh subagent per task, then one task reviewer per task
returning two verdicts from a single diff read: spec compliance first, then
artifact quality. The controller never fixes findings itself — it dispatches,
reviews, rules, and ledgers. Ships as
`srepowers-core:subagent-driven-operation`. (`SKILL.md` is the agent-facing
trigger doc; this file is for humans.)

## Use cases

- Execute a plan written with `srepowers-core:writing-operation-plans`, task by task, without a context switch
- Keep your own context clean for coordination while operator subagents do the work
- Resume a partially executed plan from its ledger and Execution Status section
- Run high-risk plans with a mandatory review gate after every task

## How-to

Have a written plan, then say "execute this plan with subagents" — or invoke
`srepowers-core:subagent-driven-operation`. The controller picks a pattern,
then loops per task: dispatch operator → review → fix loop (max 5 rounds) →
ledger. Six stop classes — irreversible ops, security actions, side effects
outside the worktree, guesswork plans, unapproved mutating steps, changes to
blast radius/rollback/verification gates — always go back to the human.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo (a 2-3 task plan; confirm briefs, review packages, and the
ledger appear under `.srepowers/sdd/<plan-basename>/`).

## Reference

| Pattern | When |
|---------|------|
| Inline | ≤2 tasks and not `risk_level: high` |
| Segmented | 3-6 tasks, batched 2-3 per operator subagent |
| Full subagent | 7+ tasks, `risk_level: high`, or any task lacking rollback |

- `operator-prompt.md` / `task-reviewer-prompt.md` / `re-review-prompt.md` — dispatch templates for the three subagent roles
- `references/` — point-of-need procedures read at the moment, not from
  memory: preflight scan, fix loop (re-read before every round), operator
  status handling, cannot-verify items, batching limits, ledger resuming,
  final review and finish

Run helpers through `bash` using their absolute installed paths, from the
execution working tree — not the skill directory. Alternatively pass
`-C /absolute/worktree` before the plan argument. The plan's location does not
select the repository (a linked worktree may use a plan in the main checkout).

- `bash /absolute/skill/scripts/task-brief [-C DIR] PLAN_FILE N` — extract one task's full text to a brief file
- `bash /absolute/skill/scripts/review-package [-C DIR] PLAN_FILE BASE HEAD` — write commit list + stat + diff to a review-package file
- `bash /absolute/skill/scripts/sdd-workspace [-C DIR] PLAN_FILE` — resolve the plan's `.srepowers/sdd/<plan-basename>/` artifact directory

## Provenance

Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT, © Jesse Vincent) `subagent-driven-development`, recast from software development to
infrastructure operations. Deliberate divergences are recorded in
the `RELEASE-NOTES.md` sync sections.

---
Last Updated: 2026-11-06
