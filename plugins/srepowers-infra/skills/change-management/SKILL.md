---
name: change-management
description: Use when authoring Change Control Board (CCB) documents, assessing risk and impact of infrastructure changes, creating implementation plans with rollback procedures, or managing the change approval workflow. Also use for "CCB", "change request", "risk assessment", "rollback plan", "impact analysis", "change record", "implementation plan", "CCB template", "approval workflow", "change window", or any formal change management documentation task.
---

# Change Management

Author CCB documents, assess risk and impact, and manage the change approval workflow for infrastructure changes. Provides structured templates and guidance for every phase of a formal change record.

**Core principle:** Every change has a rollback. Every rollback is tested before the change starts.

**Announce at start:** "I'm using the change-management skill to [author/review/assess] a change record."

## When to Use

**Use when:**
- Creating a new CCB document for an infrastructure change
- Assessing risk and blast radius before a change
- Writing implementation and rollback procedures
- Preparing a change for review and approval
- Reviewing an existing CCB document for completeness

**Exceptions:**
- Emergency/unplanned changes during active incidents — use `incident-commander` first, document retroactively
- Low-risk, routine operations that don't require CCB approval

## CCB Document Structure

Every CCB document must contain these sections. If any section is missing or incomplete, the change is not ready for review.

```markdown
# CCB: [Ticket ID] — [Short Title]

## Description
What is being changed and why. One paragraph.

## Rationale
Why this change is necessary. Business or technical justification.

## Impact Assessment
### Affected Systems
| System | Component | Impact if successful | Impact if rollback needed |
|--------|-----------|---------------------|-------------------------|
| ... | ... | ... | ... |

### Blast Radius
- Users affected: [number or group]
- Services affected: [list]
- Estimated downtime: [duration or "none"]

## Risk Assessment
| Factor | Rating | Justification |
|--------|--------|---------------|
| Change complexity | Low/Medium/High | [why] |
| Reversibility | Easy/Medium/Hard | [why] |
| Data impact | None/Read/Write | [why] |
| Production impact | None/Partial/Full | [why] |

**Overall risk level:** Low / Medium / High

## Implementation Procedure
### Prerequisites
- [ ] Prerequisite 1
- [ ] Prerequisite 2

### Steps
1. [Step 1 — include exact commands]
2. [Step 2 — include verification after each step]
3. ...

### Estimated Duration
[Total time estimate]

## Rollback Procedure
### Rollback Trigger
[What conditions trigger rollback — be specific]

### Rollback Steps
1. [Step 1 — include exact commands]
2. [Step 2]

### Rollback Time Estimate
[How long rollback takes]

## Verification
### Pre-change Baseline
[Commands to capture current state]

### Post-change Verification
[Commands to verify the change succeeded]

### Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Approval
- Requested by: [name]
- Target date: [date]
- Change window: [time range]
- Approved by: [pending]
```

## Risk Assessment Guide

### Risk Level Determination

| Level | Criteria | Example |
|-------|----------|---------|
| **Low** | Single system, fully reversible, no data impact, no downtime | Adding a monitoring check, updating documentation |
| **Medium** | Multiple systems, reversible with effort, read-only data access, brief downtime window | Upgrading a service, modifying firewall rules, DNS changes |
| **High** | Fleet-wide, difficult to reverse, data writes involved, extended downtime possible | Database migration, OS upgrades, network architecture changes, Puppet module changes affecting all hosts |

### Blast Radius Assessment

Consider these dimensions for every change:

| Dimension | Questions to ask |
|-----------|-----------------|
| **Scope** | How many hosts/services/users are affected? |
| **Duration** | How long will the change take? How long is the impact window? |
| **Data** | Is data being created, modified, or deleted? Is it reversible? |
| **Dependencies** | What upstream/downstream services depend on the affected system? |
| **Timing** | Is this during a change window? During business hours? Peak traffic? |
| **Reversibility** | Can you undo it in one command? Does rollback require manual steps? |

## Rollback Plan Requirements

A rollback plan must be:

1. **Specific** — exact commands, not "reverse the change"
2. **Tested** — the rollback commands should be verified in a non-production environment when possible
3. **Timed** — estimate how long rollback takes
4. **Triggered** — clear criteria for when to abort and roll back vs. push through

### Rollback Template

```markdown
### Rollback Procedure
**Trigger:** Abort and execute rollback if [specific condition, e.g., "error rate exceeds 5% for 3 minutes"]

**Rollback steps:**
1. `ssh host 'sudo ppr --environment <previous_env>'` (revert Puppet state)
2. `ssh host 'sudo systemctl restart <service>'` (restart affected service)
3. Verify: `curl -sf http://host/health` (check health endpoint)

**Rollback time:** ~5 minutes

**If rollback fails:** Escalate to [team/person], begin manual restoration from [backup/snapshot]
```

## Implementation Plan Requirements

### Pre-change Baseline

Always capture the current state before starting:

```bash
# Service health
ssh host 'systemctl is-active <service>'

# Configuration state
ssh host 'cat /etc/app/config.yaml' | tee /tmp/pre-change-config.yaml

# Performance baseline
ssh host 'curl -o /dev/null -s -w "%{http_code} %{time_total}" http://localhost/health'
```

### Step-by-step Format

Each step must include:
1. **What** — the exact command or action
2. **Verification** — how to confirm the step succeeded
3. **Failure action** — what to do if the step fails (continue, stop, rollback)

Example:
```markdown
### Step 1: Deploy updated configuration
**Command:**
```bash
scp /tmp/new-config.yaml host:/etc/app/config.yaml
```

**Verify:**
```bash
ssh host 'diff /etc/app/config.yaml /etc/app/config.yaml.bak'
ssh host 'sudo app --validate-config'
```

**If fails:** Do not proceed. Restore backup: `ssh host 'cp /etc/app/config.yaml.bak /etc/app/config.yaml'`
```

## Anti-Patterns

| Anti-pattern | Why | Do instead |
|-------------|-----|-----------|
| Vague rollback ("undo the change") | Impossible to execute under pressure | Write exact commands with verification |
| No rollback trigger defined | Team argues about whether to roll back during an incident | Define specific abort criteria before starting |
| Missing blast radius | Stakeholders surprised by unexpected impact | Enumerate every affected system and user group |
| Copy-paste from previous CCB without updating | Wrong commands, wrong hosts, wrong risk assessment | Review and update every field for the current change |
| "No downtime expected" without evidence | Unsupported claim creates false confidence | Test in non-prod, measure actual impact |

## Integration

**Called by:**
- `srepowers:writing-operation-plans` — for structured operation planning
- `srepowers:puppet-deploy` — for changes requiring formal CCB approval
- `srepowers:pve-admin` — for Proxmox changes requiring CCB records

**Pairs with:**
- `srepowers:safety-validator` — for risk assessment validation
- `srepowers:evidence-first-reporting` — for change result reporting
- `srepowers:verification-before-completion` — for post-change verification

## SRE Principles

### Safety First
- Every change has a rollback — if you can't write one, the change is too big
- Baseline before change, verify after change — no exceptions
- Rollback triggers must be agreed upon before starting, not debated during failure

### Structured Output
- Use the CCB template consistently — same sections, same order
- Tables for risk assessment, impact assessment, and affected systems

### Evidence-Driven
- Capture baseline state before any change
- Show verification output after each step
- Include timestamps for all operations

### Audit-Ready
- CCB documents are the permanent record — they must be self-contained
- Include enough detail that someone else could execute the change without context

### Communication
- Write CCBs for the reviewer, not for yourself — explain context and impact clearly
- Surface risk early: "this is a high-risk change because..." rather than burying it in the document
