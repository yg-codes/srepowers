---
name: writing-skills-sre
description: Use when creating new infrastructure skills, editing existing skills, or verifying skills work before deployment
---

# Writing SRE Skills

**REQUIRED BACKGROUND:** You MUST invoke `superpowers:writing-skills` first. That skill defines the full methodology — TDD applied to skill documentation, CSO descriptions, pressure testing, rationalization tables, and the complete RED-GREEN-REFACTOR cycle. This skill adds only SRE-specific guidance.

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

## SRE-Specific Testing

Pressure scenarios for infrastructure skills should test:
- Does the agent run `--dry-run` / `plan` / `diff` before apply?
- Does the agent verify results with explicit commands after execution?
- Does the agent refuse to skip safety gates under time pressure?
- Does the agent follow the TDO (RED → GREEN → REFACTOR) cycle?

## SRE Examples for Upstream Patterns

When `superpowers:writing-skills` references examples, use these SRE equivalents:
- Instead of React Router → Kubernetes deployment patterns
- Instead of `pptx/` → `kubernetes-specialist/`
- Instead of `condition-based-waiting` → `test-driven-operation`
- Code examples: Shell/Python (not TypeScript/JavaScript)

**Reference existing infrastructure skills** rather than creating new ones when patterns already exist.
