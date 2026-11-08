# executing-operation-plans

Execute a written infrastructure operation plan in a separate session:
in batches, with verification after each batch and a human approval
checkpoint between batches. Supports resuming an interrupted plan and
enforces hard stop/rollback rules. Ships as
`srepowers-core:executing-operation-plans`. (`SKILL.md` is the
agent-facing trigger doc; this file is for humans.)

## Use cases

- Long-running, multi-environment operations needing review between batches
- High-risk changes that require explicit approval checkpoints
- Resuming a partially executed plan (frontmatter `status` + `[x]` checkboxes)
- sit → uat → prod promotion with an explicit prod confirmation gate

## How-to

Say "execute this plan" or "continue the operation" — or invoke the
`srepowers-core:executing-operation-plans` skill on a plan produced by
`srepowers-core:writing-operation-plans`. Flow: isolated worktree
(`srepowers-core:using-git-worktrees-sre`) → critical review of the plan →
pre-execution safety check → batches of ~3 tasks run with
`srepowers-core:test-driven-operation` → batch verification → checkpoint
report; you say "continue" or "rollback". Completes with
`srepowers-core:finishing-operation-branch`.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo: run a two-task plan and confirm it checks the worktree,
verifies each batch, and pauses for approval before the next one.

## Reference

| Rule | Deviation type | Action |
|------|----------------|--------|
| R1 | Minor bug | auto-fix, re-verify, continue (3 retries max) |
| R2 | Missing info | read adjacent files, infer, continue (3 retries max) |
| R3 | Verification drift | adjust expected output, re-verify (3 retries max) |
| R4 | Scope/arch change | STOP — present to a human, await approval |

`SKILL.md` holds the batch/checkpoint process, environment promotion
table, and stop/rollback triggers.

## Provenance

Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT, © Jesse Vincent) `executing-plans`, recast from software development to
infrastructure operations. Deliberate divergences are recorded in
the `RELEASE-NOTES.md` sync sections.

---
Last Updated: 2026-09-14
