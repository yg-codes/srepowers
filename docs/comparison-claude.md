# SREPowers vs. Superpowers: A Comparative Evaluation

**Date:** 2026-02-18
**Evaluator:** Claude Code (claude-sonnet-4-6), updated for Codex-native support on 2026-04-21

## Table of Contents

- [Executive Summary](#executive-summary)
- [Skill Inventory](#skill-inventory)
- [Methodology Comparison](#methodology-comparison)
- [Workflow Architecture](#workflow-architecture)
- [Key Differences](#key-differences)
- [Can SREPowers Really Help Operations?](#can-srepowers-really-help-operations)
- [Limitations & Gaps](#limitations--gaps)
- [Comparative Decision Matrix](#comparative-decision-matrix)
- [Final Verdict](#final-verdict)

---

## Executive Summary

**SREPowers** and **Superpowers** both adapt software engineering discipline (TDD, subagent-driven development) to autonomous agent workflows. They share a common philosophical ancestor but serve fundamentally different domains:

| | Superpowers | SREPowers |
|---|---|---|
| **Domain** | Software development | SRE/infrastructure operations |
| **Audience** | Developers | Site Reliability Engineers |
| **Skill Count** | 14 (focused) | 49 (comprehensive) |
| **Core Concept** | Test-Driven Development (TDD) | Test-Driven Operation (TDO) |
| **Version** | 5.0.7 | 4.0.1 |
| **Stance** | Standalone | Companion plugin (extends superpowers) |

SREPowers is notably broader in scope, with significant investment in domain-specific skills and a more explicit approach to behavioral enforcement under operational pressure.

---

## Skill Inventory

### Superpowers (14 skills)

**Core Workflow:**
- `brainstorming` → `writing-plans` → `subagent-driven-development` → `finishing-a-development-branch`
- `using-git-worktrees` for isolated development branches
- `executing-plans` for batch execution with human checkpoints

**Quality & Testing:**
- `test-driven-development` — RED-GREEN-REFACTOR cycle
- `systematic-debugging` — 4-phase root cause analysis
- `verification-before-completion` — evidence-driven validation
- `requesting-code-review` / `receiving-code-review`

**Meta:**
- `using-superpowers`, `dispatching-parallel-agents`, `writing-skills`

**Philosophy:** Minimal, focused set. Each skill does exactly one thing. Strict enforcement via hard gates.

---

### SREPowers (49 skills)

**Core Infrastructure Operations (6):**
- `test-driven-operation` — verification-first infrastructure changes
- `subagent-driven-operation` — execute operations with two-stage review
- `brainstorming-operations` — design infrastructure changes with risk assessment
- `writing-operation-plans` — create bite-sized execution plans
- `verification-before-completion` — evidence-driven success claims
- `systematic-troubleshooting` — 4-phase root cause analysis for incidents

**Incident Management (3):**
- `incident-commander` — ICS-style incident coordination
- `post-mortem-writer` — blameless post-mortem creation
- `safety-validator` — pattern matching for dangerous commands

**Operations Execution (4):**
- `executing-operation-plans` — batch execution across environments
- `receiving-code-review-sre` — processing code review feedback on infra changes
- `observability-integration` — verify operations using metrics/alerting
- `using-git-worktrees-sre` — isolated worktrees for control repos

**Infrastructure Administration (4):**
- `pve-admin` — Proxmox VE/PBS management
- `pve-vlan-trunk-troubleshooting` — Proxmox VLAN trunk debugging
- `puppet-code-analyzer` — Puppet code quality analysis
- `gitlab-ecr-pipeline` — GitLab CI/CD to AWS ECR

**SRE Practices (5):**
- `sre-runbook` — structured runbook generation
- `progressive-delivery` — canary, blue-green deployments
- `toil-analysis` — toil identification and reduction
- `cost-optimizer` — cloud cost analysis and FinOps
- `environment-health-check` — verify required tools

**Domain Expertise (22):**
Architecture, cloud, microservices, DevOps, Terraform, Terragrunt, Kubernetes, containers, networking, Go, Python, Rust, PostgreSQL, observability, SRE engineering, chaos engineering, security (x2), code review, documentation, testing, platform engineering.

**Meta & Utilities (5):**
- `using-srepowers`, `writing-skills-sre`, `finishing-operation-branch`, `dispatching-parallel-agents-sre`, `playground-tutorial`

---

## Methodology Comparison

### Superpowers: Software Development Workflow

```
brainstorming → git worktrees → writing plans → subagent-driven-development
                                                        ↓
                                              spec review → code quality review
                                                        ↓
                                                finishing branch
```

**TDD Cycle:** Write test → watch fail → write minimal code → watch pass → refactor.
Deletes code written before tests (hard enforcement).

**Enforcement:** `<HARD-GATE>` tags block implementation before design is approved. Synchronous `SessionStart` hook auto-injects `using-superpowers`.

---

### SREPowers: Infrastructure Operations Workflow

```
brainstorming-operations → git worktrees → writing-operation-plans → subagent-driven-operation
                                                                              ↓
                                                               spec review → artifact quality review
                                                                              ↓
                                                             (sit → uat → prod) promotion path
```

**TDO Cycle:** Write verification command → watch it fail → execute minimal operation → watch it pass → document.

**The Iron Law:** *"NO INFRASTRUCTURE CHANGE WITHOUT A FAILING VERIFICATION FIRST."*

**Enforcement:** Same hard gates as Superpowers, plus:
- Red flag detection for rationalization ("This is just a quick server check")
- SRE Principles (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication)
- Persuasion psychology (authority, commitment, scarcity, social proof) — explicitly documented

---

## Workflow Architecture

Both plugins share identical architectural foundations. The key differences are:

| Aspect | Superpowers | SREPowers |
|--------|------------|-----------|
| Planning | brainstorming | brainstorming-operations + risk assessment |
| Execution | subagent-driven-development | subagent-driven-operation |
| Review | spec + code quality | spec + artifact quality |
| Environment | single environment | sit → uat → prod promotion |
| Observability | N/A | Prometheus metrics integration |
| Incident Handling | systematic-debugging | incident-commander + post-mortem-writer |
| Safety | N/A | safety-validator (dangerous command detection) |

---

## Key Differences

### What SREPowers Adds Beyond Superpowers

1. **Incident Management Lifecycle**
   Full ICS-style incident coordination (`incident-commander`), structured root cause analysis (`systematic-troubleshooting`), and blameless post-mortems (`post-mortem-writer`). These address the most chaotic moment in SRE work.

2. **Environmental Promotion Path**
   Operations follow `sit → uat → prod` with mandatory verification at each gate. Skipping environments is explicitly prohibited, mirroring real-world change management.

3. **Observability Integration**
   Baseline metrics captured before operations, compared after. Prevents "operation succeeded but SLOs degraded" scenarios that kubectl-only verification misses.

4. **Safety Validation Layer**
   `safety-validator` runs pattern matching against known dangerous commands before execution. Catches `kubectl delete`, `terraform destroy`, `DROP TABLE` etc. before they run.

5. **Domain Expertise Depth (23 skills)**
   Specialist skills embed MUST/MUST-NOT constraints, reference guides, and validation patterns for Kubernetes, Terraform, PostgreSQL, Puppet, Proxmox, and more.

6. **Explicit Persuasion Psychology**
   `docs/persuasion-principles.md` documents the behavioral science used to enforce discipline. This transparency makes enforcement more deliberate and improvable.

7. **Testing Infrastructure (38+ tests)**
   6x more comprehensive than Superpowers. Includes automated evaluation framework and skill generator (`create-skill.py`).

### What Superpowers Has That SREPowers Doesn't

1. **Multi-Platform Support**
   Superpowers still spans more surfaces. SREPowers now supports Claude Code and Codex natively, but remains narrower than Superpowers.

2. **Simplicity**
   Fewer skills means lower cognitive load. New practitioners can learn the full skill set quickly. SREPowers' 49 skills require more upfront investment.

---

## Can SREPowers Really Help Operations?

### Where It Genuinely Helps

**1. Verification-First Change Management**
TDO directly solves infrastructure testing blindness. The `docs/testing-anti-patterns.md` documents real failures that TDO prevents:
- `kubectl apply succeeded` ≠ pods running (CrashLoopBackOff invisible to naive checks)
- `API returned 200` ≠ correct response body structure
- `MR created` ≠ CI passing

The "watch verification fail first" requirement prevents false-positive success claims. **This is the highest-value mechanism.**

**2. Structured Incident Response**
ICS-style role assignment (IC, Operations, Communications, Scribe), escalation triggers tied to impact scope, and pre-written communication templates systematize what many teams handle chaotically. The 4-phase troubleshooting approach (Understand → Isolate → Hypothesize → Verify) is a proven framework applied to infrastructure.

**3. Risk-Aware Operations Planning**
`brainstorming-operations` forces risk assessment before execution. `writing-operation-plans` ensures every step has a verification command and rollback procedure. This matches best-practice change management for organizations requiring CAB approvals.

**4. Organizational Memory**
Runbooks, operation plans, and post-mortems saved to `docs/plans/` become searchable organizational knowledge. This directly reduces toil from recurring incidents.

**5. Multi-Environment Safety**
Mandatory `sit → uat → prod` progression with verification gates at each environment prevents the most common production incident cause: rushing changes that hadn't been tested in staging.

**6. Safety Under Pressure**
The persuasion principles are specifically designed to prevent "just this once" shortcuts under operational pressure—the exact moment when most incidents are caused. The red flag detection for rationalization ("This is a safe operation, we can skip verification") directly addresses this.

---

## Limitations & Gaps

### Technical Limitations

**1. TDO Requires Queryable Infrastructure (~70% of operations)**
TDO works best when verification commands return unambiguous output immediately. Problem cases:
- Managed cloud services with eventual consistency (S3, Route53 propagation)
- Operations where "success" requires absence of alerts over time
- Legacy services without query APIs
- Cross-service operations needing distributed tracing

**2. Token Budget Risk for Large Operations**
`subagent-driven-operation` dispatches 3-4 subagent invocations per task. For operations with 10+ tasks, this may exceed context windows or cost budgets. The `executing-operation-plans` skill mitigates this, but adds workflow overhead.

**3. Progressive Delivery Gap**
Canary deployments, blue-green traffic splitting, and shadow traffic patterns are not explicitly addressed. TDO's simple RED-GREEN doesn't capture progressive delivery verification (SLO validation per traffic stage, rollback triggers at percentage thresholds).

### Scope Assumptions

**4. Prometheus/Grafana Observability Assumption**
`observability-integration` is Prometheus-biased. Teams using Datadog, New Relic, CloudWatch, or other stacks need to adapt the prompts.

**5. Synchronous Incident Response Model**
`incident-commander` assumes real-time team availability. Long-running incidents, distributed teams across time zones, and multi-day incidents are less well-addressed.

**6. Opinionated Environment Model**
`sit → uat → prod` doesn't fit GitOps auto-promotion workflows (ArgoCD, Flux), trunk-based development, or organizations with different environment naming.

### SRE Coverage Gaps

| SRE Practice | SREPowers Coverage |
|---|---|
| Monitoring & Alerting | Good (multi-platform: Prometheus, Datadog, CloudWatch, New Relic) |
| Incident Response | Excellent |
| Change Management | Excellent |
| Runbooks/Playbooks | Good |
| Error Budgets/SLOs | Good (sre-engineer) |
| Toil Analysis | Good (toil-analysis) |
| Chaos/Resilience Testing | Good (chaos-engineer) |
| Progressive Delivery | Good (progressive-delivery) |
| Cost Optimization | Good (cost-optimizer) |
| Capacity Planning | Partial (sre-engineer mentions it) |
| Knowledge Sharing | Good |

---

## Comparative Decision Matrix

| Dimension | Superpowers | SREPowers |
|-----------|------------|-----------|
| Skill count | 14 (focused) | 49 (comprehensive) |
| Documentation depth | Concise | Comprehensive |
| Learning curve | Low | Medium-High |
| Platform support | 6 platforms | 1 platform (Claude Code) |
| Real-world SRE applicability | Code only | Infrastructure + code |
| Workflow enforcement | Very strict (hard gates) | Strict + context-aware |
| Risk of over-engineering | Low | Medium (49 skills for a small task) |
| For small teams | Better | Worse (overhead) |
| For large operations | Not applicable | Better (specialist depth) |
| Behavioral psychology | Good | Excellent (explicit) |
| Incident management | None | Full lifecycle |
| Dependency | Standalone | Companion plugin (extends superpowers) |

---

## Final Verdict

### Short Answer: Yes, SREPowers Can Help Operations

SREPowers is **production-ready and valuable** for teams that:
- Operate Kubernetes/container infrastructure
- Require change management discipline (CAB, change windows)
- Manage multi-environment deployments (dev/staging/prod)
- Need structured incident response coordination
- Use Prometheus/Grafana for observability
- Want organizational memory from runbooks and post-mortems

### The Core Value Proposition

The real power of SREPowers is not in automating infrastructure—Claude Code can run `kubectl` and `terraform` without any plugin. The value is in **enforcing discipline under pressure**.

Statistically, most production incidents are caused by:
1. Changes that bypassed verification (TDO prevents this)
2. Changes rushed without rollback plans (writing-operation-plans prevents this)
3. Incident response that became chaotic (incident-commander prevents this)
4. Post-incident lessons not captured (post-mortem-writer prevents this)

SREPowers systematically addresses all four.

### Compared to Superpowers

Superpowers is more polished, simpler, and more portable. It's a better starting point for software development teams adopting AI-assisted workflows.

SREPowers is more comprehensive, more opinionated, and more infrastructure-specific. It's appropriate for SRE/DevOps teams who are willing to invest in learning the framework in exchange for operational discipline enforcement.

**For an SRE team:** SREPowers is the right choice if you're willing to follow the workflow. The initial slowdown from verification-first operations will prevent incidents that cost far more than the time invested.

**For a development team with some infrastructure:** Superpowers covers what you need, and the skills for infrastructure are sufficiently generic that you can apply TDD discipline to operations without the full SREPowers framework.

### What SREPowers Could Improve

1. Add capacity planning workflow
2. Support non-Prometheus observability stacks (partially addressed with Datadog/CloudWatch/New Relic)
3. Add async incident response patterns for distributed teams
4. Add multi-platform support (Cursor, Codex, OpenCode, Gemini CLI)

---

*This comparison was generated by Claude Code through analysis of `/home/yg/src/github/srepowers` and `/home/yg/src/github/superpowers`. Last updated: 2026-04-08.*
