# toil-analysis

Measure the manual, repetitive work (toil) eating your team's capacity,
project when it will crowd out engineering work, and rank what to automate
first — then prove the automation worked by re-measuring. Ships as
`srepowers-core:toil-analysis`. (`SKILL.md` is the agent-facing trigger doc;
this file is for humans.)

## Use cases

- Build a ranked toil inventory from 1–2 weeks of time logs, before an automation or headcount ask
- Model quarter-by-quarter when toil crosses the 50%-of-capacity threshold
- Score automation candidates on Impact × Ease × Risk instead of gut feel
- Re-measure 4–6 weeks after each automation ships to show the reduction stuck

## How-to

Ask — "measure our toil", "which manual tasks should we automate first",
"when does toil crowd out engineering work" — and the skill triggers. Or
invoke `srepowers-core:toil-analysis` directly.

The skill walks four phases: toil inventory (log → aggregate → classify toil
vs engineering work), capacity planning (a Python growth model), automation
prioritization (scored matrix), and reduction tracking. It pairs with
`srepowers-core:sre-engineer` (SLO context), `srepowers-core:brainstorming-operations`
(designing the replacement automation), and `srepowers-core:sre-runbook`
(document the procedure before automating it).

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — the full method: toil-log and inventory templates, the
  capacity-projection script, the prioritization matrix, the reduction
  tracker, and common measurement mistakes

---
Last Updated: 2026-09-14
