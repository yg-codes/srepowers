---
name: writing-operation-plans
description: Use when you have a design for a multi-step infrastructure operation, before executing
---

# Writing Infrastructure Operation Plans

## Overview

Write comprehensive infrastructure operation plans assuming the operator has zero context for your infrastructure and limited SRE experience. Document everything they need: exact commands, verification, rollback steps. Give them the whole plan as bite-sized tasks.

**Announce at start:** "I'm using the writing-operation-plans skill to create the infrastructure operation plan."

**Context:** This should be run after brainstorming-operations has created a design.

**Save plans to:** `docs/plans/YYYY-MM-DD-<operation-name>.md`

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Operation Name] Execution Plan

> **For Claude:** REQUIRED SUB-SKILL: Use srepowers:subagent-driven-operation to implement this plan task-by-task.

**Goal:** [One sentence describing what this achieves]
**Risk Level:** [Low/Medium/High with rationale]
**Rollback Plan:** [Brief rollback strategy]
**Stakeholder Notification:** [Who to inform before/during/after]

---

## Prerequisites

- Tools required (kubectl version, API access, etc.)
- Information to gather first (current pod counts, existing configs)
- Access requirements (cluster access, API keys, SSH access)

## Tasks
```

## Task Structure

**Each step is one action (2-5 minutes). Infrastructure adds dry-run and side-effect verification:**

```markdown
### Task N: [Component/Operation Name]

**Goal:** [One sentence]
**Files/Resources:** Create/Modify `exact/resource/name.yaml`, Namespace: `namespace-name`

**Step 1: RED - Write failing verification**

```bash
kubectl get [resource] -n [namespace] [name] -o jsonpath='{.status.field}'
```
**Expected:** [What failure looks like - e.g., "Error: not found"]

**Step 2: Verify RED - Run verification, watch it fail**

Run: [verification command]
Expected: [exact failure message]

**Step 3: Dry-run (validate before live)**

```bash
kubectl apply -f [filename].yaml --dry-run=client
```
**Expected:** "configured" or "created" (dry-run)

**Step 4: GREEN - Execute minimal operation**

```yaml
[Complete YAML - no placeholders, no "..."]
```

Apply: `kubectl apply -f [filename].yaml`

**Step 5: Verify GREEN - Run verification, confirm it passes**

Run: [verification command]
Expected: [exact output that proves success]

**Step 6: Verify no side effects**

```bash
kubectl get pods -n namespace -l app=other-app
```

**Step 7: Commit**

```bash
git add [files] && git commit -m "[commit message]"
```

**Rollback:**
```bash
kubectl delete -f [filename].yaml
# OR
git revert HEAD
```
```

## Key Principles

| Principle | What It Means |
|-----------|---------------|
| **Exact commands** | No "check the pods" → `kubectl get pods -n namespace` |
| **Complete YAML** | No "add labels" → full YAML with all fields |
| **Expected outputs** | Show what success looks like for every command |
| **Rollback per task** | Each task must be reversible |
| **Dry-run first** | Validate with `--dry-run=client` before live |
| **Side-effect check** | Verify adjacent systems weren't affected |
| **TDO discipline** | RED → Verify RED → Dry-run → GREEN → Verify GREEN → Side effects → Commit |

## Final Verification Section

After all tasks:

```markdown
## Final Verification

After completing all tasks, run these commands to verify overall success:

1. [Verification command 1]
2. [Verification command 2]
3. [Smoke test command]

Expected outputs:
- [Expected output 1]
- [Expected output 2]

If any verification fails:
- Run rollback for affected tasks
- Re-run failed verification to confirm rollback
```

## Execution Handoff

After saving the plan:

**"Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Manual execution** - You execute each task manually following the plan

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use srepowers:subagent-driven-operation
- Stay in this session
- Fresh subagent per task + two-stage review
