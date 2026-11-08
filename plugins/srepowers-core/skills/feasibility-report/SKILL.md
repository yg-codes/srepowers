---
name: feasibility-report
description: Use when evaluating whether an infrastructure change should proceed at all; the go/no-go decision before implementation. Covers "should we / can we / is it feasible to" questions across capacity expansion (VM resize CPU/memory, scale-out, storage), platform upgrades (OS EOL, Kubernetes, database major version), migrations (cloud, datacenter, service, data), resilience (HA, DR, backup redesign), tooling adoption (build vs buy vs open source), decommissioning, security/compliance remediation, and cost reduction (right-sizing). Produces a TELOS assessment (technical, economic, legal, operational, scheduling), option comparison, blast radius, and rollback feasibility. Also use for "feasibility study", "go/no-go", "evaluate options for", "capacity report", "is it worth it". NOT for incident reports (use post-mortem-writer), status/findings reports (use evidence-first-reporting), CCB records after approval (use change-management), or option brainstorming before a question exists (use brainstorming-operations).
---

# Feasibility Report

Produce go/no-go decision documents for infrastructure changes: the "should we do this at all" assessment that precedes any plan, CCB record, or implementation.

**Core principle:** Evaluate each option against the evidence and return NO-GO when it fails the feasibility criteria. Do not assume approval before the assessment.

**Announce at start:** "I'm using the feasibility-report skill to produce a go/no-go assessment for [change]. This document ends in a decision."

## When to Use

| Family | Typical trigger |
|--------|-----------------|
| 1. Capacity expansion | Resize VM (CPU/memory), scale-out, storage growth, bandwidth |
| 2. Platform/version upgrade | OS EOL, Kubernetes minor, database major, firmware |
| 3. Migration | On-prem→cloud, DC move, service migration, data migration |
| 4. Resilience | HA/quorum, DR site, backup redesign, load-shedding |
| 5. Tooling adoption | Build vs buy vs open source; observability or CI/CD stack |
| 6. Decommissioning | Service sunset, hardware retirement, legacy shutdown |
| 7. Security/compliance | Cert rotation regime, hardening, audit findings |
| 8. Cost reduction | Right-sizing, reserved capacity, storage tiering |

Any of these phrased as "can we / should we / is it feasible to / evaluate options for" is this skill.

## When NOT to Use

| Requested | Use instead |
|-----------|-------------|
| "What went wrong last night?" (incident happened) | `post-mortem-writer` |
| "What's the current state?" (status/findings) | `evidence-first-reporting` |
| Change approved, need the approval record | `change-management` (CCB) |
| "Help me think of options" (no question framed yet) | `brainstorming-operations`, then return here |
| Designing the system itself after GO | `architecture-designer`, then `writing-operation-plans` |

## The TELOS Assessment

Every option (**including do-nothing**) is scored against all five dimensions. A dimension scored from memory instead of evidence is a guess; mark it Unknown.

| Dimension | Question | SRE evidence to gather |
|-----------|----------|------------------------|
| **T**echnical | Is it possible on OUR platform, with OUR skills? | Max host/instance spec, version support matrix, driver compatibility, in-house expertise, PoC result |
| **E**conomic | What does it cost, and what does inaction cost? | Change cost, steady-state cost, incident/EOL exposure if nothing changes |
| **L**egal | Is it permitted? | Data residency, compliance scope, license terms, support contracts |
| **O**perational | Who runs it afterward? | Runbook delta, on-call impact, toil delta, training needed |
| **S**cheduling | When can it be done? | Maintenance window availability, freeze periods, dependency chain, deadline mandatory vs desirable |

Two supplementary dimensions; include when they bind:

- **Resource feasibility:** are the people and hardware available at all in the window?
- **Time feasibility:** is the deadline itself realistic, or does scope need to shrink?

## Measure, Then Assert

Family-specific claims require fresh measurements, not remembered state. A capacity claim without utilization data is a guess with a number attached.

| Claim type | Minimum evidence |
|------------|------------------|
| "CPU/memory is insufficient" | Measured utilization over a representative window (`kubectl top nodes`, Prometheus range query, `vmstat`) + growth rate |
| "Storage will run out" | `zfs list -o space` / `df -h` trend + snapshot delta |
| "Traffic needs more capacity" | Load test result at target throughput, p95 latency included |
| "The app supports version N+1" | Vendor matrix entry or staging validation, not the vendor's marketing page |
| "It expires on date D" | Source cited. Date-only values stay as published; `tzstamp` rejects date-only input by design. Dual-stamp only instants with a known time and zone; where an operational cutoff is needed from a date-only deadline, state the assumed cutoff time and zone explicitly |

## Report Skeleton

Every report contains all twelve sections. Treat "not applicable" as a finding: write the section and say why it does not apply.

```markdown
# Feasibility: [short title] (GO / NO-GO / GO-WITH-CONDITIONS)

## 1. Question
What decision does this report enable? Who owns the decision?

## 2. Current State
Measured, timestamped, sourced. Observed facts separated from
inference (evidence-first-reporting).

## 3. Cost of Inaction
What happens if nothing changes: EOL exposure, incident risk,
toil, contract penalty. Do-nothing is an option with a price.

## 4. Options
2 to 3 minimum. Option A is DO-NOTHING (the baseline). A single
"real" option is a proposal, not a feasibility report.

## 5. TELOS Assessment
One row per option per dimension (T, E, L, O, S).

## 6. Comparison
Side-by-side table scoring each option against the dimensions,
with weights stated where they bind.

## 7. Risk & Blast Radius
For the recommended option: worst-case scope (hosts, services,
customers) and what failure looks like.

## 8. Rollback Feasibility
The undo, as commands, reachable over the channel you would
actually have mid-incident. No demonstrable undo ⇒ NO-GO, or
GO-WITH-CONDITIONS with the undo built first.

## 9. Cost
Change cost + steady-state cost + cost of inaction (§3),
side by side.

## 10. Schedule
Window(s), freeze periods, dependencies, deadline type
(mandatory vs desirable).

## 11. Recommendation & Conditions
GO / NO-GO / GO-WITH-CONDITIONS, named decision owner,
conditions with an expiry date each.

## 12. Open Questions
Unknowns preserved, each paired with the check that would
resolve it.
```

## Common Mistakes

- **Single-option report.** One candidate examined means the conclusion was written before the research.
- **Do-nothing omitted.** Inaction has a cost (EOL, incident risk, toil) and sometimes wins.
- **Best-case-only numbers.** Every estimate needs an optimistic/pessimistic pair; a range survives review, a point value dies in it.
- **No decision owner.** A recommendation addressed to nobody is a blog post.
- **Rollback skipped "because it's only a report."** Feasibility of the undo is a required dimension; an undo you cannot state is a NO-GO finding.
- **Reused measurements.** Numbers copied from a previous report describe a previous system. Re-measure.
- **Vague capacity claims.** "CPU is high" without percentile, window, and source is noise.

## Rationalizations

| Excuse | Reality |
|--------|---------|
| "Management already decided; the report is a formality" | A report that manufactures consent is worse than none. Assess honestly and record the dissent. |
| "No time to evaluate three options" | Do-nothing always exists as option B. Evaluating one option is advocacy for it. |
| "Rollback is obvious; we'll document it later" | Later is mid-incident. If you cannot state the undo now, it does not exist. |
| "The vendor's whitepaper says it works" | A whitepaper is marketing. Staging validation on your platform is evidence. |
| "We'll measure utilization after the decision" | Capacity decisions made without measurements are guesses. |

## Red Flags

- The recommended option is the only option examined.
- "Rollback: TBD."
- No cost-of-inaction section, with inaction framed as free.
- Capacity numbers without unit, percentile, or measurement window.
- No named decision owner in §11.
- Recommendation text recycled from a previous report.
- The closing summary or verdict line upgrades a point-in-time reading to a percentile: "measured p95 at 85 to 91%" restated from a single `kubectl top` snapshot. Evidence keeps its class everywhere, §2 and summary alike.

## Integration

**Pairs with:**
- `brainstorming-operations`: generates the option set this report assesses
- `evidence-first-reporting`: §2 Current State and all measurement claims follow its observed/inferred split
- `safety-validator`: risk and blast-radius review of the recommended option
- `cost-optimizer`: economic dimension for cloud spend
- `toil-analysis`: operational dimension for automation-family reports
- `tzstamp`: instants with a known time and zone (freeze windows, event times) dual-stamped; date-only published values (EOL, audit dates) preserved verbatim, never invent a time the source never supplied. A needed cutoff from a date-only deadline records its assumption explicitly.

**Sequence:**
- Called after `brainstorming-operations` frames the options
- Its GO verdict becomes the input to `change-management` (CCB record) and `writing-operation-plans` (implementation plan)
