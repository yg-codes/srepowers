---
name: executing-operation-plans
description: Use when you have a written infrastructure operation plan to execute in a separate session with review checkpoints - for long-running operations requiring human review between steps
---

# Executing Operation Plans

## Overview

Load infrastructure operation plan, review critically, execute tasks in batches with verification at each step, report for review between batches.

**Core principle:** Batch execution with checkpoints for safety verification and human review.

**Announce at start:** "I'm using the executing-operation-plans skill to execute this infrastructure operation plan."

## When to Use

**Use this skill when:**
- Operation plan requires execution in a separate session
- Long-running operations need human review between steps
- Operations span multiple environments (sit → uat → prod)
- High-risk changes need approval checkpoints
- Operations need to be resumed after interruption

**vs. subagent-driven-operation:**
- Separate session (can pause and resume)
- Human-in-the-loop between batches
- Better for complex multi-environment operations
- More deliberate pace for high-risk changes

## The Process

### Step 1: Load and Review Plan

1. Read operation plan file
2. Review critically:
   - Are verification commands clear?
   - Are rollback steps documented?
   - Are environment boundaries respected?
   - Are there any safety concerns?
3. If concerns: Raise them before starting
4. If no concerns: Create TodoWrite and proceed

### Step 2: Pre-Execution Safety Check

Before executing any operations:

```bash
# Verify current environment
git branch --show-current
kubectl config current-context

# Check for any ongoing incidents
kubectl get events --all-namespaces --field-selector type=Warning | head -10
```

**If incidents in progress:**
- STOP
- Report: "Active incidents detected. Defer operation until resolved."
- List: Incident details

### Step 3: Execute Batch

**Default: First 3 tasks or first environment**

For each task:
1. Mark as in_progress
2. Follow **test-driven-operation** discipline:
   - RED: Write failing verification
   - Verify RED: Run and watch it fail
   - GREEN: Execute minimal operation
   - Verify GREEN: Confirm success
   - REFACTOR: Document
3. Mark as completed

**Between tasks:**
- Verify infrastructure state is healthy
- Check for unexpected side effects
- Document actual outputs

### Step 4: Batch Verification

After completing batch:

```bash
# Verify all changes from this batch
kubectl get <resources> -n <namespace>

# Check for errors in affected components
kubectl logs -n <namespace> -l <label> --tail=20

# Verify dependent services still healthy
kubectl get pods --all-namespaces | grep -v Running
```

### Step 5: Report and Checkpoint

When batch complete, report:

```
Batch X Complete

Tasks Completed:
- Task N: [Brief description] ✅
- Task N+1: [Brief description] ✅
- Task N+2: [Brief description] ✅

Infrastructure State:
- Environment: <env>
- Components: <status summary>
- No errors: <verification output>

Ready for:
1. Review current state
2. Approve next batch
3. Modify plan if needed
4. Rollback if issues found

Say "continue" to proceed with next batch.
Say "review" to examine specific resources.
Say "rollback" to revert this batch.
```

### Step 6: Continue or Complete

**If more tasks:**
- Wait for explicit approval
- Execute next batch (return to Step 3)

**If all tasks complete:**
- Final verification across all environments
- Document final state
- Use `finishing-operation-branch` to complete

## Environment Promotion Workflow

For multi-environment operations:

```
Batch 1: SIT environment
  ↓
Checkpoint: Review in SIT
  ↓
Batch 2: UAT environment
  ↓
Checkpoint: Review in UAT
  ↓
Batch 3: PROD environment (requires explicit approval)
  ↓
Complete
```

**Promotion requirements:**
| From | To | Required Verification | Approval |
|------|-----|----------------------|----------|
| sit | uat | All checks pass in sit | Standard |
| uat | prod | All checks pass in uat | Explicit |

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Verification fails after operation
- Unexpected side effects detected
- Plan has critical gaps
- Infrastructure state becomes unhealthy
- You don't understand an instruction
- Active incident detected

**Never guess on infrastructure operations.**

## When to Rollback

**Rollback immediately when:**
- Service becomes unavailable
- Error rates increase
- Data integrity issues detected
- Verification fails and can't be fixed quickly

**Rollback procedure:**
1. Stop current batch
2. Execute rollback commands from plan
3. Verify rollback success
4. Document what happened
5. Resume only after root cause understood

## SRE Principles

### Safety First
- Verify environment before each batch
- Check for active incidents before starting
- Require explicit approval for production batches
- Document rollback procedure before executing

### Structured Output
- Report batch completion with clear status
- Show infrastructure state in tables
- Include verification command outputs
- Present clear next-step options

### Evidence-Driven
- Include actual verification outputs in reports
- Reference specific resource states
- Document any deviations from plan
- Preserve evidence for audit trail

### Audit-Ready
- Record batch execution timestamps
- Document approval decisions
- Preserve verification outputs
- Track environment promotion path

### Communication
- Lead with safety status
- Report business impact (services affected)
- Provide clear escalation context
- Explain technical state in business terms

## Integration

**Required workflow skills:**
- **using-git-worktrees-sre** - Set up isolated workspace
- **writing-operation-plans** - Creates the plan this skill executes
- **test-driven-operation** - Execute each operation with verification
- **finishing-operation-branch** - Complete after all batches

**Called by:**
- Planning skills when execution spans sessions
- Any operation requiring checkpoint reviews

## Differences from Software Plan Execution

| Aspect | Software (Superpowers) | Infrastructure (SREPowers) |
|--------|------------------------|---------------------------|
| **Verification** | Unit tests | Infrastructure state (kubectl, API) |
| **Checkpoints** | Code review | Safety verification + human approval |
| **Environments** | Local/test | sit/uat/prod promotion |
| **Rollback** | Git revert | Infrastructure rollback commands |
| **Risk** | Bugs | Production incidents |
| **Batch size** | 3 tasks | 3 tasks or per-environment |
