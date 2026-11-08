# requesting-review-sre

Dispatch a reviewer subagent over precisely crafted context — diff range,
requirements, target environment, rollback path — to catch issues before
they reach an environment. A review costs minutes; a bad apply costs an
incident. Ships as `srepowers-core:requesting-review-sre`. (`SKILL.md` is
the agent-facing trigger doc; this file is for humans.)

## Use cases

- Whole-operation branch review before merging toward an environment branch
- Mandatory end-of-operation review in `subagent-driven-operation`
- Fresh perspective when stuck or after a fix with an uncertain root cause

## How-to

Just ask — "request a review", "get this reviewed", "review before merge" —
or invoke the `srepowers-core:requesting-review-sre` command. Get the range,
fill the template:

```bash
BASE_SHA=$(git merge-base HEAD origin/main)
HEAD_SHA=$(git rev-parse HEAD)
```

Never `HEAD~1` for a multi-commit range — it silently drops everything but
the last commit. Always set the subagent model explicitly. Request side of
the review loop: `srepowers-core:code-reviewer` is the reviewer persona;
`srepowers-core:receiving-code-review-sre` handles the feedback.

Task review vs whole-operation review are not interchangeable: per-task
reviews inside `subagent-driven-operation` use its `task-reviewer-prompt.md`;
this skill's whole-operation review uses `code-reviewer.md` on the entire branch.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — task vs whole-operation reviews, dispatch steps, SRE-specific
  reviewer inputs (blast radius, rollback, evidence), red flags list
- `code-reviewer.md` — the whole-operation reviewer prompt template with
  placeholders: `[DESCRIPTION]`, `[PLAN_OR_REQUIREMENTS]`,
  `[TARGET_ENVIRONMENT]`, `[BASE_SHA]`/`[HEAD_SHA]`, `[MODEL]`

## Provenance

Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT, © Jesse Vincent) `requesting-code-review`, recast from software development to
infrastructure operations. The SRE reviewer template (blast radius, rollback preservation, least privilege) is original. Deliberate divergences are recorded in
the `RELEASE-NOTES.md` sync sections.

---
Last Updated: 2026-09-14
