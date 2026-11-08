# The Fix Loop

Part of `srepowers-core:subagent-driven-operation`. Read this before every
fix round — even if you read it earlier in this session: it holds the round
cap, the breaker, and the ledger line each round writes, and your memory of
it does not survive compaction.

The loop triggers when the review reports spec ❌, any Critical or Important
finding, or a ⚠️ item you confirmed as a real gap.

Before the loop starts, two routes leave it immediately:

- Record Minor findings in the ledger as you go
  (`Task <N>: minor (deferred): <one-liner>`), and point the final
  whole-operation review at that list so it can triage which must be fixed
  before merge. A roll-up nobody reads is a silent discard. Minor findings
  never enter the loop.
- A finding labeled plan-mandated — or any finding that conflicts with
  what the plan's text requires — is yours to rule on: weigh the finding
  against the plan text, decide with the spec as the binding authority, and
  ledger the ruling before you act on it. Do not dismiss the finding because
  the plan mandates it, and do not dispatch a fix that contradicts the plan
  without a recorded ruling. If the ruling would change blast radius, the
  rollback path, or a verification gate, it is stop class 6 — present it
  instead.

Everything else enters the loop. A fix round is one fix dispatch plus one
scoped re-review. **Five rounds maximum per task.**

**Rounds 1-3 — resume the original operator.** Send it the open findings
verbatim. Its context is intact: it knows the task, the live system state
it observed, and its own choices. If your harness cannot send another
message to a live subagent, dispatch a fresh operator carrying the brief
path, the report-file path, and the findings — the report file is the
persistent memory either way.

**Rounds 4-5 — dispatch a fresh operator on a more capable model** (per
Model Selection), with the brief path, the report-file path, the open
findings, and this framing: "A prior operator attempted this task [N]
times; you own it now. Read the report file for what was tried." A loop
that survives three resumes usually means the operator cannot see its own
problem — fresh eyes and a capability bump in one move.

**Every round, either way:** the operator fixes, re-runs the verification
commands covering the amended resources, appends its fix report to the same
report file, and returns the short contract. Before re-dispatching the
reviewer, confirm the fix report contains the covering verification
commands, the command run, and the output; dispatch the re-review once all
three are present. Name the covering verifications in the fix message — a
one-line fix does not need the whole suite.

**The re-review is scoped.** Run
`bash /absolute/skill/scripts/review-package PLAN_FILE FIX_BASE HEAD` from the
execution working tree, not the installed skill directory, where FIX_BASE is the head the previous review saw, and dispatch
[../re-review-prompt.md](../re-review-prompt.md) with the findings list,
the brief, the report file, and the printed diff path. The re-reviewer
verdicts each finding ADDRESSED or NOT ADDRESSED and flags new breakage in
the fix diff only. New Critical/Important breakage in the fix diff joins
the open findings list. Out-of-scope observations go to the ledger as
deferred minors — they never extend the loop.

**After each round,** append to the ledger:
`Task <N>: fix round <R>/5 (<X> addressed, <Y> open — <finding one-liners>; commits <a7>..<b7>)`

Never fix findings yourself in the controller session — your context stays
clean for coordination, and controller fixes skip review.

**The breaker.** When round 5's re-review still leaves findings open, stop
dispatching. Adjudicate each open finding yourself — you hold the plan and
the cross-task context the reviewer lacks:

- **The reviewer is wrong, or the point is contestable:** park it —
  `Task <N>: parked — <finding> — Ruling: <why the change stands>`. The final
  review sees both sides.
- **Real, but nothing downstream builds on it:** park it the same way, with
  a ruling that says it's real and deferred.
- **Real and load-bearing** — a later task builds on it, or it reveals a
  plan defect: rule on the smallest change that unblocks the dependent work,
  ledger it as `Task <N>: Ruling: <finding> — <what you decided and why>`,
  and carry it into the next task's dispatch. Parking a structural failure
  silently lets every dependent task build on it and hands the final review
  a problem it cannot fix either. Stop only when the defect trips a stop
  class, or leaves every path forward a guess — then append
  `Task <N>: BLOCKED — <reason>` and report with the finding, the plan text
  it collides with, and the fix history.

Adjudicate only at the cap. Adjudicating earlier to end a loop is
pre-judging with a different name. Every adjudication is a ledger entry —
a silent discard is forbidden.

**Completing the task.** When the review comes back clean — or every open
finding is parked with a ruling at the cap — append the completion line to
the ledger in the same message as your other bookkeeping:

- `Task <N>: complete (commits <base7>..<head7>, review clean)`
- `Task <N>: complete (commits <base7>..<head7>, <K> parked)` after a tripped breaker

Never move to the next task while the review has open Critical/Important
issues that are neither fixed nor parked-with-ruling at the cap.
