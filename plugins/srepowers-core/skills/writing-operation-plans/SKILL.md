---
name: writing-operation-plans
description: Use when you have a design for a multi-step infrastructure operation, before executing
---

# Writing Infrastructure Operation Plans

## Overview

Write comprehensive infrastructure operation plans assuming the operator has zero context for your infrastructure and limited SRE experience. Document everything they need: exact commands, verification, rollback steps. Give them the whole plan as bite-sized tasks.

**Announce at start:** "I'm using the writing-operation-plans skill to create the infrastructure operation plan."

**Context:** This should be run after brainstorming-operations has created a design.

**Do not use for fast-path work:** If the task is low-risk, read-only, or a single-file/local-only change with exact local validation, skip this skill and go straight to `test-driven-operation` or the relevant domain skill.

**Save plans to:** `docs/plans/YYYY-MM-DD-<operation-name>.md`

## Plan Document Format

**Every plan MUST use this structured format with YAML frontmatter and task sections:**

```markdown
---
# Plan Frontmatter (machine-parseable, used by execution skills)
ticket: "[TICKET-ID or empty]"  # Issue tracker ID (e.g., INFRA-1234, PROJ-456)
ticket_url: "[URL or empty]"    # Full tracker URL
risk_level: "[low|medium|high]"
risk_rationale: "[Why this risk level]"
environment: "[sit|uat|prod|mgmt]"
rollback_plan: "[Brief rollback strategy for the entire operation]"
stakeholders: "[Who to inform before/during/after]"
tasks_count: [N]
status: "pending"               # pending | in_progress | completed | rolled_back
---

# [Operation Name] Execution Plan

> **For Claude:** REQUIRED SUB-SKILL: Use srepowers:subagent-driven-operation to implement this plan task-by-task.

**Goal:** [One sentence describing what this achieves]
**Risk Level:** [Low/Medium/High] — [rationale]
**Rollback Plan:** [Brief rollback strategy]
**Stakeholder Notification:** [Who to inform before/during/after]

---

## Prerequisites

- Tools required (kubectl version, API access, etc.)
- Information to gather first (current pod counts, existing configs)
- Access requirements (cluster access, API keys, SSH access)

## Requirements Traceability

<!-- Map issue tracker acceptance criteria to plan tasks -->
| Requirement | Task(s) | Status |
|-------------|---------|--------|
| [Acceptance criterion 1] | Task N | pending |
| [Acceptance criterion 2] | Task N, Task M | pending |

## Tasks

## Execution Status

<!-- Auto-updated during execution. Used for resume after interruption. -->
- Task 1: [ ] pending
- Task 2: [ ] pending
- Task N: [ ] pending
```

## Output Contract

Every plan must make these sections obvious and complete:

- **Pre-checks** — prerequisites, current-state capture, and target confirmation
- **Execution** — exact step sequence with one action per task
- **Verification** — exact RED and GREEN commands with expected outputs
- **Rollback** — exact undo path per task and for the operation overall
- **Risk** — declared environment, blast radius, and rationale for risk level

### Frontmatter Rules

| Field | Required | Notes |
|-------|----------|-------|
| `ticket` | No | Issue tracker ticket ID (Jira, ClickUp, Linear, etc.) |
| `ticket_url` | No | Full URL for subagent access |
| `risk_level` | **Yes** | Must be `low`, `medium`, or `high` |
| `risk_rationale` | **Yes** | One sentence justifying the risk level |
| `environment` | **Yes** | Target environment: `sit`, `uat`, `prod`, or `mgmt` |
| `rollback_plan` | **Yes** | High-level rollback for the entire operation |
| `stakeholders` | No | Who to notify |
| `tasks_count` | **Yes** | Must match actual number of tasks |
| `status` | **Yes** | Updated during execution |

### Requirements Traceability Rules

- When a ticket exists in the issue tracker, extract acceptance criteria and map each to one or more plan tasks
- Every acceptance criterion MUST map to at least one task
- If a criterion cannot be mapped, add a task for it or explicitly flag it as out-of-scope
- Status column updated during execution: `pending` → `done` | `skipped` | `failed`

## Task Structure

**Each step is one action (2-5 minutes). Every task follows TDO discipline with structured fields:**

```markdown
### Task N: [Component/Operation Name]

**Goal:** [One sentence]
**Files/Resources:** Create/Modify `exact/resource/name.yaml`, Namespace: `namespace-name`
**Verification:** `[exact verification command]`
**Expected (Before):** `[exact failure output OR baseline output before the change]`
**Expected (GREEN):** `[exact success output]`
**Rollback:** `[exact rollback command]`
**Side Effects Check:** `[command to verify adjacent systems]`

**Step 1: RED - Define verification or baseline**

```bash
kubectl get [resource] -n [namespace] [name] -o jsonpath='{.status.field}'
```
**Expected:** [What failure looks like when target state is absent, or current baseline when failure is not meaningful]

**Step 2: Verify RED or capture baseline**

Run: [verification command]
Expected: [exact failure message OR exact baseline output]

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
```

### Task Header Fields (Required)

Each task MUST include these fields in its header for machine-parseable extraction:

| Field | Required | Purpose |
|-------|----------|---------|
| **Goal** | **Yes** | One-sentence objective |
| **Files/Resources** | **Yes** | Exact paths and namespaces |
| **Verification** | **Yes** | Exact command to prove success/failure |
| **Expected (Before)** | **Yes** | What the verification command outputs before the change: expected failure for absent/broken target state, or baseline output when current state is valid |
| **Expected (GREEN)** | **Yes** | What the verification command outputs after the change |
| **Rollback** | **Yes** | Exact command to undo this task |
| **Side Effects Check** | **Yes** | Command to verify adjacent systems unaffected |

## Key Principles

| Principle | What It Means |
|-----------|---------------|
| **Exact commands** | No "check the pods" → `kubectl get pods -n namespace` |
| **Complete YAML** | No "add labels" → full YAML with all fields |
| **Expected outputs** | Show what success looks like for every command |
| **Rollback per task** | Each task must be reversible |
| **Dry-run first** | Validate with `--dry-run=client` before live |
| **Side-effect check** | Verify adjacent systems weren't affected |
| **TDO discipline** | Define verification/baseline → Verify RED or capture baseline → Dry-run → GREEN → Verify GREEN → Side effects → Commit |
| **Template-first** | If an existing plan template exists in the project, populate it rather than generating a new structure |

## Template-First Planning

Before generating a plan from the standard format above, check whether the project already has a plan template:

1. **Search for existing templates** in `docs/plans/`, looking for files named `*-template.md` or `*-template*.md`
2. **If a template exists:** Populate it with the operation's specific values rather than creating a new structure. Templates encode domain-specific safety gates, conditional sections, and lessons learned that the generic format doesn't cover.
3. **If no template exists:** Use the standard format in this skill.

Existing templates are authoritative for their domain — they may include sections (replication pre-sync, quorum gates, pool conditionals) that are essential for that specific operation type.

## Planning Anti-Patterns

Never:

- Write a task without rollback
- Use placeholders like "check the pods" instead of exact commands
- Mix multiple risky changes into one task
- Omit environment or blast-radius context
- Create a full plan for a trivial fast-path task just to satisfy process

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

## Plan Quality Gate

After generating the plan and before presenting execution options, dispatch a plan-checker subagent to validate the plan against these 6 dimensions:

1. **Rollback coverage** — Every task has a rollback command (not just "git revert")
2. **Verification concreteness** — All verification commands are exact (no "check that X works", no placeholders)
3. **Environment boundary** — No task touches an environment outside the declared `environment` field
4. **Dry-run presence** — Every kubectl/terraform apply includes a `--dry-run` step
5. **Side-effect checks** — Every task specifies how to verify no collateral damage
6. **Risk consistency** — Risk level matches actual blast radius (e.g., cluster-wide changes = high, not medium)

**Checker workflow:**
1. Dispatch plan-checker subagent using `./plan-checker-prompt.md` with precisely crafted review context — never your session history. This keeps the checker focused on the plan, not your thought process, and preserves your own context.
2. If issues found: fix the plan, re-run checker (max 2 iterations)
3. If still issues after 2 iterations: surface to human for review
4. If passes: proceed to execution handoff

## Execution Handoff

After saving the plan:

**"Plan complete and saved to `docs/plans/<filename>.md`. Three execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Separate session** - Open new session with executing-operation-plans, batch execution with human checkpoints — good for high-risk or multi-environment operations

**3. Manual execution** - You execute each task manually following the plan

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use srepowers:subagent-driven-operation
- Stay in this session
- Fresh subagent per task + two-stage review

**If Separate session chosen:**
- Guide user to open new session in git worktree
- **REQUIRED SUB-SKILL:** New session uses srepowers:executing-operation-plans
