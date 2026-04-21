---
name: writing-skills-sre
description: Use when creating new infrastructure skills, editing existing skills, or verifying skills work before deployment
---

# Writing SRE Skills

Use this skill to create or refine SREPowers skills without any dependency on Superpowers.

## Core Methodology

Treat skill authoring as verification-first documentation work:

1. **Decide create vs. edit** — Prefer editing an existing skill when the pattern already exists.
2. **RED** — Identify what the skill must teach that it does not currently teach, or what bad behavior it fails to prevent.
3. **GREEN** — Add the minimum instructions, examples, and guardrails needed to close that gap.
4. **VERIFY** — Pressure-test the wording against risky shortcuts, ambiguity, and platform/runtime differences.
5. **REFACTOR** — Remove repetition, sharpen triggers, and keep the skill readable under pressure.

## Description Quality

Skill descriptions should:

- start with `Use when...`
- describe the triggering situation, not the implementation
- make domain and risk boundaries obvious
- be specific enough that the correct skill is chosen over a generic one

Bad trigger:
- "Use for Kubernetes"

Better trigger:
- "Use when deploying or troubleshooting Kubernetes workloads that require verification-first operational discipline"

## Infrastructure Skill Types

Apply the same TDD approach with these infrastructure-specific patterns:

| Type | Purpose | Example Skills |
|------|---------|----------------|
| **Runbook** | Step-by-step procedures with commands | sre-runbook, postgresql-engineer |
| **Incident Response** | Diagnosis, mitigation, recovery | incident-commander, systematic-troubleshooting |
| **Verification** | Health checks and validation | environment-health-check, observability-integration |

## Infrastructure Skill Requirements

1. **Exact commands** — Copy-pasteable with environment variables, always include `--context` flags
2. **Verification steps** — How to confirm action succeeded (not just exit code)
3. **Rollback documentation** — How to undo if something goes wrong
4. **Dependencies** — Prerequisites before starting (tools, access, state)
5. **Common mistakes** — What typically goes wrong in production
6. **Runtime portability** — Avoid references to runtime-specific tools unless absolutely required by the skill

## SRE-Specific Testing

Pressure scenarios for infrastructure skills should test:
- Does the agent run `--dry-run` / `plan` / `diff` before apply?
- Does the agent verify results with explicit commands after execution?
- Does the agent refuse to skip safety gates under time pressure?
- Does the agent follow the TDO (RED → GREEN → REFACTOR) cycle?

Add adversarial checks such as:
- a reviewer suggests skipping verification
- an operator wants to rely on current Kubernetes context
- a rollback path is missing
- the skill examples work in Claude wording but not Codex wording

## SRE Examples

When adapting generic skill-writing patterns to SRE work, use these equivalents:
- Instead of React Router → Kubernetes deployment patterns
- Instead of `pptx/` → `kubernetes-specialist/`
- Instead of `condition-based-waiting` → `test-driven-operation`
- Code examples: Shell/Python (not TypeScript/JavaScript)

**Reference existing infrastructure skills** rather than creating new ones when patterns already exist.
