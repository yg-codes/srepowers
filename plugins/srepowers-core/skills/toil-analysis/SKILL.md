---
name: toil-analysis
description: Use when identifying, measuring, and reducing operational toil or when prioritizing automation of repetitive manual tasks
---

# Toil Analysis

## Overview

Identify manual, repetitive, automatable work (toil) and prioritize elimination. Includes capacity planning to project when toil will crowd out engineering work.

**Core principle:** Measure before you automate. What you don't measure, you can't reduce.

**Announce at start:** "I'm using the toil-analysis skill to measure and prioritize toil reduction."

## When to Use

**Use this skill when:**
- On-call engineers spending > 25% of time on manual tasks
- Recurring incidents from the same manual procedures
- Planning headcount or automation investment decisions
- SRE team velocity is declining despite stable incident rate
- Preparing quarterly reliability reviews

**Pairs with:**
- `sre-engineer` — SLO/error budget context for toil impact
- `brainstorming-operations` — Designing automation to replace toil
- `sre-runbook` — Documenting procedures before automating them

## Phase 1: Toil Inventory

### Step 1: Data Collection (1-2 weeks)

Ask each SRE/ops engineer to log every manual task for 1-2 weeks:

```markdown
## Toil Log Template (per engineer, per week)

| Date | Task | Trigger | Duration (min) | Frequency/Week | Automatable? | Notes |
|------|------|---------|----------------|----------------|--------------|-------|
| 2026-02-10 | Restart stuck worker pods | Alert | 10 | 3x | Yes | Same pods, same namespace |
| 2026-02-11 | Rotate expired TLS cert | Ticket | 45 | 0.5x | Yes | Has runbook, no automation |
| 2026-02-12 | Manually scale DB read replicas | Slack message | 20 | 2x | Partial | Needs HPA tuning |
```

**Minimum viable data collection:**
- Task name (specific, not "misc ops")
- Time per occurrence (in minutes)
- Frequency per week
- Is this automatable? (Yes / Partial / No)

### Step 2: Aggregate into Toil Inventory

```markdown
## Toil Inventory — [Team Name] — [Date Range]

| Rank | Task | Freq/Week | Duration (min) | Hours/Week | Automatable | Priority |
|------|------|-----------|----------------|------------|-------------|----------|
| 1 | Restart stuck worker pods | 15 | 10 | 2.5h | Yes | 🔴 High |
| 2 | Manual DB failover verification | 4 | 30 | 2.0h | Partial | 🔴 High |
| 3 | Rotate TLS certs | 0.5 | 45 | 0.4h | Yes | 🟠 Medium |
| 4 | Investigate noisy alerts | 20 | 5 | 1.7h | No | 🟡 Low (fix alerts) |
| 5 | Provision dev environments | 2 | 60 | 2.0h | Yes | 🔴 High |
| **Total** | | | | **8.6h/week** | | |

**Team capacity:** [N] engineers × 40h/week = [total]h/week
**Toil percentage:** 8.6h × [N engineers] / [total capacity] = [X]%
**SRE book threshold:** 50% toil → engineering work crowded out
```

### Step 3: Classify Toil vs. Engineering Work

**Toil characteristics (if most are true, it's toil):**
- Manual (human required, not automated)
- Repetitive (same steps each time)
- No enduring value (fixing the same problem again)
- O(n) with service growth (more services = proportionally more work)
- Interruptive (breaks engineering focus)

**Not toil (still necessary):**
- Novel incident response (each unique)
- Design/architecture decisions
- Mentoring and knowledge sharing
- First-time setup (has enduring value)

## Phase 2: Capacity Planning

Model when toil will consume engineering capacity.

### Toil Growth Model

```python
#!/usr/bin/env python3
"""Toil capacity planning model."""

# Current state
toil_hours_per_week = 8.6       # from inventory
engineers = 4
total_capacity_hours = engineers * 40
toil_percentage = (toil_hours_per_week / total_capacity_hours) * 100

# Growth assumptions
toil_growth_rate = 0.10         # toil grows 10% per quarter (some automation planned)
planned_hires = [0, 0, 1, 0]   # headcount plan per quarter

print(f"Current toil: {toil_percentage:.1f}% of capacity")
print(f"\nProjection:")
print(f"{'Quarter':<10} {'Engineers':<12} {'Toil h/w':<12} {'Toil %':<10} {'Status'}")
print("-" * 55)

for q in range(1, 6):
    engineers += planned_hires[q-1] if q <= len(planned_hires) else 0
    toil_hours_per_week *= (1 + toil_growth_rate)
    total_capacity_hours = engineers * 40
    toil_pct = (toil_hours_per_week / total_capacity_hours) * 100
    status = "🔴 CROWDED" if toil_pct > 50 else ("⚠️ WARNING" if toil_pct > 35 else "✅ OK")
    print(f"Q+{q:<9} {engineers:<12} {toil_hours_per_week:<12.1f} {toil_pct:<10.1f} {status}")
```

Save the script above to `/tmp/toil-model.py`, then run it and present the output as the projection table:

```bash
python3 /tmp/toil-model.py
```

**Interpretation:**
- < 35%: Healthy, continue automation investments
- 35–50%: Warning, accelerate automation roadmap
- > 50%: Critical, freeze feature work, automate or hire

### Capacity Planning Output Template

```markdown
## Capacity Planning Summary — [Date]

**Current State:**
- Team size: N engineers
- Total capacity: N × 40h = Xh/week
- Total toil: Xh/week (X%)
- Engineering work capacity: Xh/week (X%)

**Projection (5 quarters):**
| Quarter | Team Size | Toil h/w | Toil % | Status |
|---------|-----------|----------|--------|--------|
| Now | N | X | X% | ✅ |
| Q+1 | N | X | X% | ✅ |
| Q+2 | N | X | X% | ⚠️ |
| Q+3 | N+1 | X | X% | ✅ |
| Q+4 | N+1 | X | X% | ✅ |

**Key inflection point:** Without automation or hiring, toil exceeds 50% in [Quarter].

**Recommendation:** Prioritize automating [Top 3 tasks] to reduce toil by ~Xh/week, pushing inflection point to Q+N.
```

## Phase 3: Automation Prioritization

### Prioritization Matrix

Score each toil item on three dimensions (1-5 scale):

| Dimension | 1 (Low) | 3 (Medium) | 5 (High) |
|-----------|---------|------------|----------|
| **Impact** | < 0.5h/week saved | 1-2h/week saved | > 3h/week saved |
| **Ease** | Months of engineering | Weeks of engineering | Days of engineering |
| **Risk** | High blast radius | Moderate | Low/isolated |

**Priority score = Impact × Ease × Risk**

```markdown
## Automation Prioritization Matrix

| Task | Impact (1-5) | Ease (1-5) | Risk (1-5) | Score | Recommended |
|------|-------------|------------|------------|-------|-------------|
| Restart stuck worker pods | 5 | 5 | 4 | 100 | ✅ Do first |
| Provision dev environments | 5 | 3 | 5 | 75 | ✅ Do next |
| Rotate TLS certs | 3 | 4 | 4 | 48 | 🟠 Q+2 |
| Manual DB failover | 5 | 2 | 2 | 20 | 🔴 Hard, do last |
```

### Automation Approaches by Task Type

| Toil Type | Automation Approach |
|-----------|-------------------|
| Alert-triggered manual restart | Kubernetes operator, HPA, or alert auto-remediation |
| Certificate rotation | cert-manager, external-secrets, or scheduled job |
| Environment provisioning | Terraform module + CI/CD pipeline trigger |
| Repetitive `kubectl --context <context>` commands | Kubernetes operator or CronJob |
| Manual approvals for routine changes | GitOps auto-promotion with SLO gates |
| Dashboard-reading | SLO alerts + automated escalation |

## Phase 4: Measure Reduction Progress

### Toil Reduction Tracking

After each automation ships, re-measure:

```markdown
## Toil Reduction Tracker

| Task | Before (h/w) | After (h/w) | Savings (h/w) | Automation Shipped | Status |
|------|-------------|-------------|---------------|-------------------|--------|
| Restart stuck pods | 2.5 | 0.1 | 2.4 | Auto-restart CronJob | ✅ Done |
| Provision dev envs | 2.0 | 0.2 | 1.8 | Terraform + GitLab CI | ✅ Done |
| Rotate TLS certs | 0.4 | 0.0 | 0.4 | cert-manager installed | ✅ Done |
| **Total** | **8.6** | **5.7** | **3.0** | | |

**Progress:** Reduced from 8.6h/week to 5.7h/week (35% reduction)
**New toil percentage:** X% (down from X%)
```

## SRE Principles

### Safety First
- Automate runbook procedures ONLY after they are documented and tested manually
- All automation must have circuit breakers (max attempts, alert on failure)
- Phase structure: **Measure** (inventory) → **Plan** (prioritize) → **Automate** → **Verify** (re-measure)

### Structured Output
- Present toil inventory as ranked table (hours/week descending)
- Show capacity projection as quarterly timeline
- Include automation prioritization matrix with scores

### Evidence-Driven
- All toil measurements from actual time logs (not estimates)
- Capacity projections use documented growth assumptions
- Reduction progress tracked against measured baseline

### Audit-Ready
- Date-stamp all toil inventories for trend comparison
- Document automation decisions with prioritization rationale
- Track automation ROI (engineering hours spent vs. toil hours saved)

### Communication
- Express toil in business terms: "8.6h/week of manual work = 1 engineer's day per week not building features"
- Frame capacity planning as headcount vs. automation trade-off
- Report toil reduction as productivity gain: "Automation shipped this quarter freed 3h/week per engineer"

## Common Mistakes

### Measuring only incidents, not routine toil
- **Problem**: Scheduled manual tasks are invisible in incident metrics
- **Fix**: Use structured time-logging for all operational work

### Automating without a runbook first
- **Problem**: Automation fails, no one knows the manual procedure
- **Fix**: Use `sre-runbook` skill to document procedure first, then automate

### Prioritizing ease over impact
- **Problem**: Team automates easy tasks, high-impact toil remains
- **Fix**: Use Impact × Ease × Risk scoring; always sort by score

### Not re-measuring after automation
- **Problem**: Can't prove automation worked; toil creeps back
- **Fix**: Re-run toil inventory 4-6 weeks after each automation ships
