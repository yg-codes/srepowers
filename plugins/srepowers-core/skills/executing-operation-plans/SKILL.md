---
name: executing-operation-plans
description: Use when you have a written infrastructure operation plan to execute in a separate session with review checkpoints - for long-running operations requiring human review between steps
---

# Executing Infrastructure Operation Plans

## Overview

Load infrastructure operation plan, review critically, execute tasks in batches with verification at each step, report for review between batches.

**Core principle:** Batch execution with checkpoints for safety verification and human review.

**Announce at start:** "I'm using the executing-operation-plans skill to execute this infrastructure operation plan."

## When to Use

| Use This When | vs. subagent-driven-operation |
|---------------|------------------------------|
| Separate session (can pause/resume) | Same session |
| Human-in-the-loop between batches | Subagent executes autonomously |
| Complex multi-environment operations | Single environment |
| High-risk changes need approval checkpoints | Lower risk, faster iteration |

## The Process

### Step 0: Set Up Isolated Workspace

Before loading the plan:

```bash
git branch --show-current
kubectl config get-contexts -o name
```

**REQUIRED:** Use srepowers-core:using-git-worktrees-sre to create an isolated worktree for this operation. Do not execute on the main branch without explicit user consent.

### Step 1: Load and Review Plan

1. Read operation plan file
2. Parse YAML frontmatter: extract `risk_level`, `environment`, `tasks_count`, `status`
3. **Check for resume state:**
   - If `status: "in_progress"` or `status: "completed"` in frontmatter, read `## Execution Status` section
   - Identify completed tasks (marked `[x]`) and pending tasks (marked `[ ]`)
   - Announce: "Resuming operation. Tasks 1-[N-1] completed. Starting from Task [N]."
4. Review critically:
   - Are verification commands clear?
   - Are rollback steps documented?
   - Are environment boundaries respected?
5. If concerns: Raise them before starting
6. If no concerns: Record the execution state and proceed

### Step 2: Pre-Execution Safety Check

Before executing any operations:

```bash
# Verify current environment
git branch --show-current
kubectl config get-contexts -o name

# Check for active incidents
kubectl --context <context> get events --all-namespaces --field-selector type=Warning | head -10
```

**If incidents in progress:** STOP. Report and defer operation.

### Step 3: Execute Batch

**Default: First 3 tasks or first environment**

For each task, follow **test-driven-operation** discipline:
1. RED: Define verification or baseline before execution
2. Verify RED or baseline: Run and watch it fail when target state is absent/broken, or capture baseline when failure is not meaningful
3. GREEN: Execute minimal operation
4. Verify GREEN: Confirm success
5. Check side effects

### Step 4: Batch Verification

After completing batch:

```bash
# Verify changes from this batch
kubectl --context <context> get <resources> -n <namespace>

# Check for errors in affected components
kubectl --context <context> logs -n <namespace> -l <label> --tail=20

# Verify dependent services still healthy
kubectl --context <context> get pods --all-namespaces | grep -v Running
```

**Update execution state in plan file:**
- Mark completed tasks as `[x] completed (commit SHA)`
- Update frontmatter `status: "in_progress"`

### Step 5: Report and Checkpoint

```
Batch X Complete

Tasks: Task N ✅, Task N+1 ✅, Task N+2 ✅

Infrastructure State:
- Environment: <env>
- Components: <status>
- No errors: <verification>

Ready for:
1. Review current state
2. Approve next batch
3. Rollback if issues

Say "continue" to proceed.
Say "rollback" to revert this batch.
```

### Step 6: Continue or Complete

**If more tasks:** Wait for approval, execute next batch

**If all complete:** Final verification, update frontmatter `status: "completed"`, update Requirements Traceability status, use `finishing-operation-branch`

## Deviation Handling

When unexpected situations arise during task execution:

| Rule | Type | Action | Max Retries |
|------|------|--------|-------------|
| **R1 - Minor bug** | Auto-fix | Fix, re-verify, continue | 3 |
| **R2 - Missing info** | Auto-resolve | Read adjacent files, infer, continue | 3 |
| **R3 - Verification drift** | Auto-adapt | Adjust expected output, re-verify | 3 |
| **R4 - Scope/arch change** | **STOP** | Present to human, await approval | N/A |

**After 3 failed R1-R3 retries:** Escalate to R4. Report what was tried and what's needed.

**Scope boundary:** Do not auto-fix pre-existing issues unrelated to the current task.

## Environment Promotion

For multi-environment operations (sit → uat → prod):

| From | To | Verification Required | Approval |
|------|-----|----------------------|----------|
| sit | uat | All checks pass in sit | Standard |
| uat | prod | All checks pass in uat | **Explicit required** — ask user directly: "All UAT checks passed. Confirm promotion to prod?" |

## Stop and Rollback

**STOP immediately when:**
- Verification fails after operation
- Unexpected side effects detected
- Infrastructure becomes unhealthy
- Active incident detected
- Instruction unclear

**Rollback immediately when:**
- Service unavailable
- Error rates increase
- Data integrity issues

**Rollback procedure:**
1. Stop current batch
2. Execute rollback commands from plan
3. Verify rollback success
4. Document what happened
5. Resume only after root cause understood

## Integration

**Required workflow skills:**
- **using-git-worktrees-sre** - Set up isolated workspace
- **writing-operation-plans** - Creates the plan this skill executes
- **test-driven-operation** - Execute each operation with verification
- **finishing-operation-branch** - Complete after all batches
