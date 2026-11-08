# finishing-operation-branch

Close out verified infrastructure work. It re-verifies the
infrastructure state, detects whether you're in a normal repo or a
worktree, then presents an environment-aware menu — merge and deploy,
merge request for peer review, promote to the next environment, keep
as-is, or discard — and documents the rollback before any cleanup.
Ships as `srepowers-core:finishing-operation-branch`. (`SKILL.md` is the
agent-facing trigger doc; this file is for humans.)

## Use cases

- Work is done and verified: merge to the control repo and deploy
- Open a merge request for peer review (worktree stays alive for feedback)
- Promote a change along sit → uat → prod — never sit → prod
- Discard or park a branch, with typed confirmation before deletion

## How-to

Say "merge this branch", "create a PR", "wrap up this operation", or
"ready to merge" — or invoke the
`srepowers-core:finishing-operation-branch` skill. It refuses to offer
options while verification fails; production merges require a typed
confirmation, and the MR and promote options keep the worktree so you can
iterate on feedback or run the next promotion step.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo: finish a throwaway branch in a test worktree and confirm it
verifies first, detects the workspace shape, and asks before any
destructive cleanup.

## Reference

| Option | Merge | Push | Keep worktree | Rollback doc |
|--------|-------|------|---------------|--------------|
| 1 Merge & deploy | ✓ | ✓ | – | ✓ |
| 2 Create MR | – | ✓ | ✓ | ✓ |
| 3 Promote | ✓ | ✓ | ✓ | ✓ |
| 4 Keep as-is | – | – | ✓ | – |
| 5 Discard | – | – | – | – |

`SKILL.md` carries the workspace-state detection, production-confirmation
gate, worktree provenance rules, and red flags (never `--force` a refused
worktree removal).

## Provenance

Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT, © Jesse Vincent) `finishing-a-development-branch`, recast from software development to
infrastructure operations. Deliberate divergences are recorded in
the `RELEASE-NOTES.md` sync sections.

---
Last Updated: 2026-09-14
