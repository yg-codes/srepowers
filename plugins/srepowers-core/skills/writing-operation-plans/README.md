# writing-operation-plans

Turn an approved design into an execution plan an operator with zero context
can follow: exact commands, expected outputs, rollback per task, and an
execution-order diagram showing parallel groups, STOP gates, and
environment boundaries. Ships as `srepowers-core:writing-operation-plans`.
(`SKILL.md` is the agent-facing trigger doc; this file is for humans.)

## Use cases

- Plan a multi-environment rollout (module → sit → uat → prod) with approval gates before irreversible steps
- Map issue-tracker acceptance criteria to plan tasks in a requirements-traceability table
- Hand the same plan to subagents, a separate session, or a human without losing the cross-task contract (`Interfaces`: consumes/produces)
- Decide honestly whether a plan is needed at all — fast-path work should skip this skill

## How-to

After `srepowers-core:brainstorming-operations` produces a design, say —
"write the operation plan for this" — or invoke
`srepowers-core:writing-operation-plans`. Plans are saved to
`docs/plans/YYYY-MM-DD-<operation-name>.md`.

At the end you get an execution handoff: subagent-driven (this session),
separate session with checkpoints, or manual. Before dispatch, a
plan-checker subagent grades the plan on seven dimensions.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

| File | Purpose |
|------|---------|
| `SKILL.md` | Plan format (frontmatter rules, Global Constraints, task header fields), execution-order diagram syntax, TDO task structure, key principles, anti-patterns |
| `plan-checker-prompt.md` | Prompt template for the plan-checker subagent; validates 7 dimensions — rollback coverage, verification concreteness, environment boundary, pre-mutation safety gate, side-effect checks, risk consistency, command correctness |

## Provenance

Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT, © Jesse Vincent) `writing-plans`, recast from software development to
infrastructure operations. Deliberate divergences are recorded in
the `RELEASE-NOTES.md` sync sections.

---
Last Updated: 2026-09-14
