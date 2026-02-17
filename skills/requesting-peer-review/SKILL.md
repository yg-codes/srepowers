---
name: requesting-peer-review
description: Use when infrastructure changes are complete and need human peer review before merging to control repo - especially for production-bound changes, high-risk operations, or compliance requirements
---

# Requesting Peer Review for Infrastructure Changes

## Overview

Infrastructure changes affect production systems. Peer review catches issues that automated verification might miss: logic errors, security gaps, missing edge cases, and compliance violations.

**Core principle:** Human review for infrastructure changes reduces incidents and ensures knowledge sharing.

**Announce at start:** "I'm using the requesting-peer-review skill to prepare this infrastructure change for peer review."

## When to Request Peer Review

**Mandatory for:**
- Production-bound changes (uat → prod promotion)
- High-risk operations (database migrations, network changes)
- Security-related changes (RBAC, certificates, secrets)
- Changes affecting multiple services
- First-time changes to a system

**Recommended for:**
- Any change to critical infrastructure
- Complex multi-step operations
- Changes without automated verification
- Compliance-audited environments

**Can skip when:**
- Emergency fix with post-hoc review scheduled
- Pre-approved maintenance window changes
- Automated rollbacks of failed changes

## The Review Request Process

### Step 1: Prepare Change Summary

Document what was changed and why:

```bash
# Get change summary
git diff --stat HEAD~1

# Get detailed changes
git diff HEAD~1
```

**Summary format:**
```markdown
## Change Summary

**What**: Brief description of infrastructure change
**Why**: Business/technical justification
**Risk Level**: Low/Medium/High
**Environments Affected**: sit/uat/prod
**Rollback Time**: X minutes
```

### Step 2: Verify Pre-Review Checklist

Before requesting review, ensure:

- [ ] All verification commands pass
- [ ] Rollback procedure is documented
- [ ] Change is tested in non-production environment
- [ ] No sensitive data in commits (passwords, tokens)
- [ ] YAML/JSON syntax is valid
- [ ] Resource limits are specified (if applicable)

### Step 3: Create Merge Request with Review Template

```bash
# Push branch
git push -u origin <branch-name>

# Create MR using glab or gh
glab mr create --title "[<ENV>] <brief description>" --description "$(cat <<'EOF'
## Summary
[2-3 sentences describing the change]

## Changes
- [ ] Change 1
- [ ] Change 2

## Risk Assessment
| Factor | Level | Notes |
|--------|-------|-------|
| Blast Radius | Low/Med/High | [Services affected] |
| Rollback Complexity | Low/Med/High | [Steps required] |
| Testing Confidence | Low/Med/High | [Test coverage] |

## Verification Steps
```bash
# Command 1: Verify X
kubectl get ...

# Command 2: Verify Y
curl ...
```

## Rollback Procedure
```bash
# Step 1: Rollback X
kubectl ...

# Step 2: Verify rollback
kubectl ...
```

## Pre-Review Checklist
- [ ] Tested in sit/uat
- [ ] Verification commands documented
- [ ] Rollback procedure tested
- [ ] No sensitive data exposed
- [ ] Resource limits specified

## Review Focus Areas
Please pay special attention to:
1. [Specific area 1]
2. [Specific area 2]
EOF
)"
```

### Step 4: Assign Reviewers

**Reviewer selection by change type:**

| Change Type | Primary Reviewer | Secondary Reviewer |
|-------------|------------------|-------------------|
| Kubernetes manifests | Platform team | Service owner |
| Terraform/IaC | Infrastructure team | Security team |
| Security (RBAC/certs) | Security team | Platform team |
| Database changes | DBA team | Application team |
| Network changes | Network team | Platform team |

### Step 5: Respond to Review Feedback

**Feedback categories:**

| Severity | Action Required | Timeline |
|----------|-----------------|----------|
| **Blocker** | Must fix before merge | Immediate |
| **Critical** | Fix or provide justification | Before merge |
| **Important** | Fix in this MR or follow-up ticket | Next sprint |
| **Minor** | Address when convenient | Future MR |

**Response template:**
```markdown
## Review Response

### Blockers (0/0 resolved)
- [ ] None

### Critical (2/2 resolved)
- [x] Fixed missing resource limits in deployment.yaml
- [x] Added health check endpoint verification

### Important (1/2 resolved)
- [x] Added monitoring alert for new metric
- [ ] Created follow-up ticket PROJ-123 for documentation update

### Minor (0/1 resolved)
- [ ] Noted for next refactoring pass
```

## Review Criteria for Infrastructure Changes

### Security
- [ ] No hardcoded secrets
- [ ] Principle of least privilege (RBAC)
- [ ] Network policies appropriate
- [ ] Resource limits prevent DoS

### Reliability
- [ ] Health checks configured
- [ ] Graceful shutdown handling
- [ ] Retry/backoff logic present
- [ ] Circuit breakers where needed

### Observability
- [ ] Metrics exposed
- [ ] Logging appropriate
- [ ] Alerts configured
- [ ] Runbook updated

### Operability
- [ ] Rollback procedure clear
- [ ] Documentation updated
- [ ] No single points of failure
- [ ] Resource requests/limits set

## SRE Principles

### Safety First
- Require explicit approval for production changes
- Block merges with failing verification
- Enforce two-person rule for high-risk changes

### Structured Output
- Use MR templates with mandatory sections
- Include risk assessment table
- Document verification commands

### Evidence-Driven
- Include actual verification output in MR
- Reference test results, not just "tested"
- Show metric baselines and expected changes

### Audit-Ready
- Preserve review comments and responses
- Link to change tickets
- Document approval chain

### Communication
- Lead with risk level and blast radius
- Explain business impact
- Provide escalation context

## Integration

**Called by:**
- `finishing-operation-branch` (Option 2: Create MR)
- `subagent-driven-operation` (for high-risk operations)
- Any infrastructure change requiring human approval

**Pairs with:**
- `code-reviewer` - Automated code quality review
- `verification-before-completion` - Pre-review verification
- `sre-runbook` - Operational documentation

## Differences from Software Code Review

| Aspect | Software (Superpowers) | Infrastructure (SREPowers) |
|--------|------------------------|---------------------------|
| **Focus** | Code quality, tests | Safety, blast radius, rollback |
| **Verification** | Unit tests pass | Infrastructure state verified |
| **Risk assessment** | Bug impact | Production outage potential |
| **Approval** | LGTM | Explicit environment-based approval |
| **Rollback** | Revert commit | Infrastructure rollback procedure |
