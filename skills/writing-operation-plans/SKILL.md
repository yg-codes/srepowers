---
name: writing-operation-plans
description: Use when you have a design for a multi-step infrastructure operation, before executing
---

# Writing Infrastructure Operation Plans

## Overview

Write comprehensive infrastructure operation plans assuming the operator has zero context for your infrastructure and limited SRE experience. Document everything they need to know: which resources to touch for each step, exact commands to run, verification commands, how to confirm success, and rollback steps. Give them the whole plan as bite-sized tasks.

Assume they are a skilled operator, but know almost nothing about your infrastructure, tooling, or problem domain. Assume they don't know what "verification" means or how to write good tests.

**Announce at start:** "I'm using the writing-operation-plans skill to create the infrastructure operation plan."

**Context:** This should be run after brainstorming-operations has created a design.

**Save plans to:** `docs/plans/YYYY-MM-DD-<operation-name>.md`

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the verification command" - step
- "Run it to make sure it fails" - step
- "Execute minimal operation" - step
- "Run verification to confirm it passes" - step
- "Document in runbook/commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Operation Name] Execution Plan

> **For Claude:** REQUIRED SUB-SKILL: Use srepowers:subagent-driven-operation to implement this plan task-by-task.

**Goal:** [One sentence describing what this achieves]

**Risk Level:** [Low/Medium/High with rationale]

**Rollback Plan:** [Brief rollback strategy - what command or action reverts the operation]

**Verification Commands:** [List of commands that prove success]

---

## Context

[Brief description of current infrastructure state and why this operation is needed]

## Prerequisites

- Tools required (kubectl version, API access, etc.)
- Information to gather first (current pod counts, existing configs)
- Access requirements (cluster access, API keys, SSH access)

## Tasks
```

## Task Structure

```markdown
### Task N: [Component/Operation Name]

**Goal:** [One sentence describing what this task achieves]

**Files/Resources:**
- Create/Modify: `exact/resource/name.yaml`
- Namespace: `namespace-name`
- Related resources: [list related infrastructure]

**Step 1: RED - Write failing verification**

[EXACT verification command - copy-pasteable]

```bash
kubectl get [resource] -n [namespace] [name] -o jsonpath='{.status.field}'
```
**Expected:** [What failure looks like - e.g., "Error: not found"]

**Step 2: Verify RED - Run verification, watch it fail**

Run: [verification command]
Expected: [exact failure message or output]

**Step 3: GREEN - Execute minimal operation**

```yaml
apiVersion: [api-version]
kind: [kind]
metadata:
  name: [name]
  namespace: [namespace]
  [labels/annotations]
spec:
  [exact spec - complete, no "..."]
```

Apply command:
```bash
kubectl apply -f [filename].yaml
```

**Step 4: Verify GREEN - Run verification, confirm it passes**

Run: [verification command]
Expected: [exact output that proves success - e.g., "Running", "true", "3"]

**Step 5: Verify no side effects**

[Commands to check other resources weren't affected]
```bash
kubectl get pods -n namespace -l app=other-app
```

**Step 6: Commit to control repo (if applicable)**

```bash
git add [files]
git commit -m "[commit message]"
git push
```

**Rollback for this task:**
```bash
kubectl delete -f [filename].yaml
# OR
git revert HEAD
```
```

## Example Task

```markdown
### Task 1: Create ConfigMap for application configuration

**Goal:** Add ConfigMap with DATABASE_URL and LOG_LEVEL for app-v1

**Files/Resources:**
- Create: `manifests/production/app-config-v1.yaml`
- Namespace: `production`
- Related resources: Deployment `app-deployment` (will reference this ConfigMap)

**Step 1: RED - Write failing verification**

```bash
kubectl get configmap -n production app-config-v1 -o jsonpath='{.data.DATABASE_URL}'
```
**Expected:** Error: not found

**Step 2: Verify RED - Run verification, watch it fail**

Run: `kubectl get configmap -n production app-config-v1 -o jsonpath='{.data.DATABASE_URL}'`
Expected: "Error from server (NotFound)" or similar

**Step 3: GREEN - Execute minimal operation**

Create `manifests/production/app-config-v1.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-v1
  namespace: production
  labels:
    app: myapp
    version: v1
data:
  DATABASE_URL: postgresql://prod-db.example.com:5432/app
  LOG_LEVEL: info
  MAX_CONNECTIONS: "20"
```

Apply command:
```bash
kubectl apply -f manifests/production/app-config-v1.yaml
```

**Step 4: Verify GREEN - Run verification, confirm it passes**

Run: `kubectl get configmap -n production app-config-v1 -o jsonpath='{.data.DATABASE_URL}'`
Expected: "postgresql://prod-db.example.com:5432/app"

Verify all data:
```bash
kubectl get configmap -n production app-config-v1 -o yaml
```

**Step 5: Verify no side effects**

Check existing ConfigMaps weren't affected:
```bash
kubectl get configmap -n production
```

**Step 6: Commit to control repo**

```bash
git add manifests/production/app-config-v1.yaml
git commit -m "Add production ConfigMap for app-v1"
git push origin cu_add_app_config_v1
```

**Rollback for this task:**
```bash
kubectl delete configmap app-config-v1 -n production
git revert HEAD
```
```

## Final Verification Section

After all tasks, add:

```markdown
## Final Verification

After completing all tasks, run these commands to verify overall success:

1. [Verification command 1]
2. [Verification command 2]
3. [Smoke test command]

Expected outputs:
- [Expected output 1]
- [Expected output 2]
- [Expected smoke test result]

If any verification fails:
- Check task-specific rollbacks
- Run rollback for affected tasks
- Re-run failed verification to confirm rollback
```

## Remember

- **Exact commands always** - no "check the pods", use "kubectl get pods -n namespace"
- **Complete YAML in plan** - not "add labels", include full YAML
- **Expected outputs** - show what success looks like
- **Rollback per task** - each task must be reversible
- **Verification before operation** - always RED step first
- **No placeholders** - complete, copy-pasteable content
- **TDO discipline** - RED → Verify RED → GREEN → Verify GREEN → REFACTOR
- **Safety first** - rollback plans, verification commands, risk assessment

## Common Mistakes

**❌ Vague instructions:**
"Update the deployment with the new ConfigMap"

**✅ Exact, complete:**
"Patch the deployment to add envFrom reference to ConfigMap app-config-v1:
```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        envFrom:
        - configMapRef:
            name: app-config-v1
```"

**❌ Missing verification:**
"Apply the manifest"

**✅ Full TDO cycle:**
"Step 1: RED - Write verification (kubectl get deployment -n production app -o jsonpath='{.spec.replicas}')
Step 2: Verify RED - Run, expect 'Error: not found'
Step 3: GREEN - Apply manifest
Step 4: Verify GREEN - Run verification, expect '3'"

**❌ No rollback:**
"Delete the old resources"

**✅ Rollback plan:**
"Rollback: kubectl apply -f backup/app-v1-old.yaml
Verify: kubectl get pods -n production -l app=app,version=v1"

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Manual execution** - You execute each task manually following the plan

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use srepowers:subagent-driven-operation
- Stay in this session
- Fresh subagent per task + two-stage review
