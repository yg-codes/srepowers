# Final Review and Finish

Part of `srepowers-core:subagent-driven-operation`. Every task in the plan
is complete. Read this once, here — do not carry it from memory.

## The final whole-operation review

The final whole-operation review uses a different template from the per-task
ones: fill `srepowers-core:requesting-review-sre`'s `code-reviewer.md`, which
judges production readiness across the whole branch. It gets a package too:
run `bash /absolute/skill/scripts/review-package PLAN_FILE MERGE_BASE HEAD`
from the execution working tree, not the installed skill directory (MERGE_BASE = the
commit the branch started from, e.g. `git merge-base main HEAD`) and include
the printed path, so the final reviewer reads one file instead of re-deriving
the branch diff with git commands. Dispatch it on the most capable available
model (see SKILL.md's Model Selection). Point it at the ledger's
deferred-minor and parked lines so it can triage which must be fixed before
merge.

If the final whole-operation review returns findings, dispatch **ONE** fix
subagent with the complete findings list — not one fixer per finding
(per-finding fixers each rebuild context and re-run checks). Then run
exactly one scoped re-review of the fix wave
(`bash /absolute/skill/scripts/review-package PLAN_FILE FIX_BASE HEAD` from
the execution working tree over the fix range,
[../re-review-prompt.md](../re-review-prompt.md)).

**An unresolved Critical or Important finding after that re-review is a
stop, not a parking decision.** This is merge/deployment authorization, not
execution: the six running-plan stop classes govern rulings *inside* the
approved envelope, and a known production-readiness defect sitting in the
branch at merge time is outside it (stop class 3 already names a merge).
Present it to the operator yourself — the finding, its impact, its failure
mode, and what fixing it would take — and record their call in the ledger:
`Final: <finding> — operator accepted for merge: <their reason>` or
`Final: <finding> — fix dispatched (second wave, operator-approved)`. A
controller ruling never accepts a Critical/Important defect into a merge;
only the operator's explicit word does. Minor findings park with rulings as
in the fix loop's breaker ([fix-loop.md](fix-loop.md)).

## Finish

**Before you delete anything, surface every ruling.** Collect every ledger
line containing `Ruling:` — preflight rulings, parked findings, breaker
adjudications, all of them — into your final message under "Rulings I
made", in the order you made them, each with what it costs if wrong. The
list is exhaustive: if the ledger holds a ruling, the list holds it. That
list is the only place the decisions you took on the operator's behalf
reach them — they read it and rework whatever you got wrong. A ruling that
dies with the workspace was a decision made in secret, and in an ops
context it is also an audit-trail gap: the plan file and the ticket are
where the record belongs, not a deleted scratch directory. Append the
ruling list to the plan file's evidence section before the workspace goes.

When the final whole-operation review is clean and its fixes are merged,
delete this plan's workspace — git history is the durable record, and a
workspace that outlives its plan is the stale-ledger hazard in waiting.
Sibling directories belong to other plans; leave them alone.

Then use `srepowers-core:finishing-operation-branch`.
