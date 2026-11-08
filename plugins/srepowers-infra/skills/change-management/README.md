# change-management

Author CCB (Change Control Board) documents and manage the approval workflow
for infrastructure changes: description, rationale, impact and risk
assessment, implementation procedure, rollback plan, verification, and
approval record. Enforced rule: every change has a rollback, tested before
the change starts. Ships as `srepowers-infra:change-management`.
(`SKILL.md` is the agent-facing trigger doc; this file is for humans.)

## Use cases

- Write a new CCB document for an infrastructure change
- Assess risk level and blast radius before proposing a change
- Draft implementation steps with a pre-change baseline and post-change
  verification, plus a rollback plan with explicit triggers
- Prepare a change record for review, approval, and a change window

## How-to

In Claude Code or Codex, just ask — "CCB", "change request", "risk
assessment", "rollback plan", "impact analysis", "implementation plan",
"change window" — the skill triggers automatically, or invoke it directly
as the `srepowers-infra:change-management` command.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — the mandatory CCB document structure (full template);
  risk-level determination and blast-radius assessment guides; rollback
  template and requirements; implementation-plan requirements (pre-change
  baseline, step-by-step format with a fully worked example); anti-patterns

---
Last Updated: 2026-09-14
