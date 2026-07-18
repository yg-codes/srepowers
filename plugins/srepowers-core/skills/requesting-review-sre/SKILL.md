---
name: requesting-review-sre
description: Use when completing an infrastructure task, finishing a change to manifests or control-repo code, or before merging to an environment branch, to verify the work meets requirements and is safe to apply. Also use for "request a review", "get this reviewed", "review before merge", "who should check this change".
---

# Requesting Review (SRE)

Dispatch a reviewer subagent to catch issues before they reach an environment.
The reviewer gets precisely crafted context for evaluation — never your
session's history. This keeps the reviewer focused on the work product, not your
thought process, and preserves your own context for continued work.

**Core principle:** Review early, review often. A review costs minutes; a bad
apply costs an incident.

This is the **request** side of the review loop. The other two sides:
- `srepowers-core:code-reviewer` — the reviewer persona and checklists
- `srepowers-core:receiving-code-review-sre` — evaluating the feedback you get back

## When to Request Review

**Mandatory:**
- After each task in `srepowers-core:subagent-driven-operation` (use that
  skill's `task-reviewer-prompt.md`, which is task-scoped)
- After completing a whole operation, before merging — this is the broad
  whole-operation review, and it uses **this** skill's template
- Before any merge toward an environment branch (sit → uat → prod)
- Before any change to a production control repo

**Optional but valuable:**
- When stuck (fresh perspective)
- Before a large refactor of shared Hiera data or modules
- After fixing a subtle failure whose root cause you are not fully sure of

## Task Review vs Whole-Operation Review

| | Task review | Whole-operation review |
|---|---|---|
| **Scope** | One task's diff | The entire branch |
| **Template** | `subagent-driven-operation/task-reviewer-prompt.md` | [code-reviewer.md](code-reviewer.md) |
| **Verdicts** | Spec compliance + artifact quality (+ ⚠️ cannot-verify) | Production readiness |
| **Model** | Scaled to the diff | The most capable available — do not inherit the session default by omitting it |

Do not substitute one for the other. A clean run of per-task reviews does not
mean the operation as a whole is safe to apply; cross-task interactions are
exactly what the final review exists to catch.

## How to Request

**1. Get the git range:**

```bash
BASE_SHA=$(git merge-base HEAD origin/main)   # or the branch point / prior task SHA
HEAD_SHA=$(git rev-parse HEAD)
```

Never use `HEAD~1` for a multi-commit range — it silently drops everything but
the last commit.

**2. Dispatch the reviewer subagent:**

Dispatch a `general-purpose` subagent, filling the template at
[code-reviewer.md](code-reviewer.md).

**Placeholders:**
- `[DESCRIPTION]` — brief summary of what you changed
- `[PLAN_OR_REQUIREMENTS]` — the plan file path, task text, or ticket requirements
- `[TARGET_ENVIRONMENT]` — where this is destined to be applied, and whether it
  has been applied anywhere yet
- `[BASE_SHA]` / `[HEAD_SHA]` — the range

**Always specify the model explicitly.** An omitted model silently inherits your
session's — usually the most expensive one.

**3. Act on the feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if the reviewer is wrong — with technical reasoning and evidence,
  not assertion (see `srepowers-core:receiving-code-review-sre`)

## What Makes an SRE Review Different

Give the reviewer what a code reviewer would not think to ask for:

- **Target environment and blast radius** — the same manifest is a different
  risk in sit than in prod
- **Rollback path** — state it in `[DESCRIPTION]` so the reviewer can judge
  whether the change preserves it
- **Verification evidence** — the noop/dry-run/plan output you already
  collected, so the reviewer verifies rather than re-runs
- **Applied-anywhere-yet status** — a reviewer treats "not yet applied"
  and "already live in uat" very differently

## Integration with Workflows

| Workflow | When to review |
|---|---|
| `subagent-driven-operation` | Per task (task-reviewer), then once at the end (this skill) |
| `executing-operation-plans` | After each task or at natural checkpoints |
| Ad-hoc change | Before merge, and whenever you are stuck |
| Incident hotfix | After the incident is mitigated — never let review block mitigation, but never skip it afterward either |

## Red Flags

**Never:**
- Skip review because "it's a one-line Hiera change"
- Skip review because the noop was clean — a noop proves effect, not intent
- Ignore Critical issues
- Proceed with unfixed Important issues
- Tell the reviewer what not to flag, or pre-rate a finding's severity
- Dispatch a reviewer without the range and the requirements
- Argue with valid technical feedback

**If the reviewer is wrong:**
- Push back with technical reasoning
- Show the command output or manifest that proves it
- Request clarification rather than silently overriding

See the template at [code-reviewer.md](code-reviewer.md).
