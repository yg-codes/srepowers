# SRE Principles Alignment: Skill Improvement Plan

> **For Claude:** REQUIRED SUB-SKILL: Use srepowers:subagent-driven-operation to implement this plan task-by-task.

**Goal:** Align all 20 domain expertise skills with the 5 SRE principles that the core workflow skills already embody.

**Risk Level:** Low (editing skill documentation only, no infrastructure changes)

**Rollback Plan:** `git revert HEAD~N` to undo commits

---

## Analysis Summary

### What's Already Strong (Core Workflow Skills - No Changes Needed)

The 6 core workflow skills + 6 specialized SRE skills already embody all 5 principles:

| Skill | Safety First | Structured Output | Evidence-Driven | Audit-Ready | Communication |
|-------|:-----------:|:-----------------:|:---------------:|:-----------:|:-------------:|
| test-driven-operation | ✅ | ✅ | ✅ | ✅ | ✅ |
| subagent-driven-operation | ✅ | ✅ | ✅ | ✅ | ✅ |
| brainstorming-operations | ✅ | ✅ | ✅ | ✅ | ✅ |
| writing-operation-plans | ✅ | ✅ | ✅ | ✅ | ✅ |
| verification-before-completion | ✅ | ✅ | ✅ | ✅ | ✅ |
| sre-runbook | ✅ | ✅ | ✅ | ✅ | ✅ |
| pve-admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| puppet-code-analyzer | ✅ | ✅ | ✅ | ✅ | ✅ |
| gitlab-ecr-pipeline | ✅ | ✅ | ✅ | ✅ | ✅ |
| cache-cleanup | ✅ | ✅ | ✅ | ✅ | ✅ |
| clickup-ticket-creator | ✅ | ✅ | ✅ | ✅ | ✅ |
| using-srepowers | ✅ | ✅ | ✅ | ✅ | ✅ |

### What Needs Improvement (20 Domain Expertise Skills)

All 20 domain expertise skills share the same structural gap: they have good technical content but lack explicit alignment with the 5 SRE principles. They are missing:

1. **SAFETY FIRST**: No dry-run/validation section. Skills say "MUST NOT deploy without X" but don't enforce Pre-check → Execute → Verify phases.
2. **STRUCTURED OUTPUT**: No explicit phase structure. Core Workflow has clear phases (RED → GREEN → REFACTOR). Domain skills just have "Core Workflow" with numbered steps but no enforcement.
3. **EVIDENCE-DRIVEN**: No requirement to reference specific log lines, metrics, or config parameters in output.
4. **AUDIT-READY**: No requirement for traceability or reversibility documentation in outputs.
5. **COMMUNICATION**: No explicit requirement for business clarity alongside technical accuracy.

### The Fix: Add an "SRE Principles" Section to All 20 Domain Skills

Add a standardized section to each domain expertise skill that bridges the gap. This section sits between "Constraints" and "Output Templates" and explicitly binds the skill to the 5 principles.

---

## Tasks

### Task 1: Create the standard SRE Principles section template

**Goal:** Define the reusable section that will be adapted for each domain expertise skill.

**Standard template (to be customized per skill):**

```markdown
## SRE Principles

### Safety First
- All operational commands MUST include dry-run validation before execution
- Use `--dry-run` flags where available ([skill-specific examples])
- Phase structure: **Pre-check** (validate current state) → **Execute** (apply changes) → **Verify** (confirm success)

### Structured Output
- Present findings using tables, bullet points, and explicit phases
- Use Pre-check → Execute → Verify structure for all recommendations
- Include severity/priority ratings in tabular format

### Evidence-Driven
- Reference specific [skill-specific: log lines, metrics, config parameters, query plans, etc.]
- Include actual command output, not assumptions
- Cite version numbers, timestamps, and resource identifiers

### Audit-Ready
- Every recommendation must be traceable (what changed, why, when, by whom)
- All changes must be reversible with documented rollback steps
- Include before/after state documentation

### Communication
- Lead with business impact (e.g., "This reduces deployment time by 40%")
- Follow with technical details
- Summarize risks in non-technical terms for stakeholders
```

**Files:** None created - this is the template for subsequent tasks.

### Task 2: Add SRE Principles to architecture-designer

**Goal:** Add SRE Principles section customized for architecture design context.

**File:** `skills/architecture-designer/SKILL.md`

**Customizations:**
- Safety: ADR review before implementation, design review gates
- Evidence: Reference specific latency metrics, throughput numbers, cost estimates
- Audit: ADR format with decision rationale and rollback/migration paths

### Task 3: Add SRE Principles to chaos-engineer

**Goal:** Add SRE Principles section customized for chaos engineering context.

**File:** `skills/chaos-engineer/SKILL.md`

**Customizations:**
- Safety: Blast radius controls, automated rollback < 30s, staging-first
- Evidence: Reference steady-state metrics, experiment results, error rates
- Audit: Experiment logs with hypothesis, results, remediation actions

### Task 4: Add SRE Principles to cloud-architect

**Goal:** Add SRE Principles section customized for cloud architecture context.

**File:** `skills/cloud-architect/SKILL.md`

**Customizations:**
- Safety: terraform plan before apply, cost estimates before provisioning
- Evidence: Reference Well-Architected review scores, cost breakdowns, compliance scan results
- Audit: Architecture Decision Records, change logs, cost tracking tags

### Task 5: Add SRE Principles to code-documenter

**Goal:** Add SRE Principles section customized for documentation context.

**File:** `skills/code-documenter/SKILL.md`

**Customizations:**
- Safety: Validate documentation builds before publishing, link checking
- Evidence: Reference API response examples, actual endpoint URLs, version-specific behavior
- Audit: Documentation versioning, changelog entries, review trails

### Task 6: Add SRE Principles to code-reviewer

**Goal:** Add SRE Principles section customized for code review context.

**File:** `skills/code-reviewer/SKILL.md`

**Customizations:**
- Safety: Non-blocking suggestions vs blocking issues, severity levels
- Evidence: Reference specific file:line, test results, benchmark numbers
- Audit: Review checklist with sign-off, finding tracking

### Task 7: Add SRE Principles to devops-engineer

**Goal:** Add SRE Principles section customized for DevOps context.

**File:** `skills/devops-engineer/SKILL.md`

**Customizations:**
- Safety: Pipeline dry-runs, canary deployments, automated rollback
- Evidence: Reference build logs, deployment metrics, health check results
- Audit: Deployment manifests, pipeline run IDs, artifact checksums

### Task 8: Add SRE Principles to golang-pro

**Goal:** Add SRE Principles section customized for Go development context.

**File:** `skills/golang-pro/SKILL.md`

**Customizations:**
- Safety: `go vet`, `golangci-lint`, race detector before merge
- Evidence: Reference benchmark results, pprof output, test coverage numbers
- Audit: Test reports, benchmark comparisons, dependency audit

### Task 9: Add SRE Principles to kubernetes-specialist

**Goal:** Add SRE Principles section customized for Kubernetes context.

**File:** `skills/kubernetes-specialist/SKILL.md`

**Customizations:**
- Safety: `--dry-run=client`, diff before apply, staging-first
- Evidence: Reference pod status, event logs, resource utilization metrics
- Audit: kubectl diff output, applied manifest versions, rollout history

### Task 10: Add SRE Principles to microservices-architect

**Goal:** Add SRE Principles section customized for microservices context.

**File:** `skills/microservices-architect/SKILL.md`

**Customizations:**
- Safety: Contract testing before deployment, circuit breaker configuration
- Evidence: Reference distributed traces, service mesh metrics, SLO dashboards
- Audit: Service dependency maps, API versioning, change impact analysis

### Task 11: Add SRE Principles to monitoring-expert

**Goal:** Add SRE Principles section customized for monitoring/observability context.

**File:** `skills/monitoring-expert/SKILL.md`

**Customizations:**
- Safety: Alert rule testing, dashboard validation, synthetic monitoring
- Evidence: Reference specific PromQL queries, metric values, alert firing history
- Audit: Alert rule change logs, dashboard version history, SLO burn rate records

### Task 12: Add SRE Principles to postgres-pro

**Goal:** Add SRE Principles section customized for PostgreSQL context.

**File:** `skills/postgres-pro/SKILL.md`

**Customizations:**
- Safety: EXPLAIN ANALYZE before execution, transaction wrapping, backup before migration
- Evidence: Reference query plan output, pg_stat metrics, VACUUM statistics
- Audit: Migration scripts with rollback, schema version tracking, query performance baselines

### Task 13: Add SRE Principles to prompt-engineer

**Goal:** Add SRE Principles section customized for prompt engineering context.

**File:** `skills/prompt-engineer/SKILL.md`

**Customizations:**
- Safety: Test on evaluation suite before deployment, A/B testing
- Evidence: Reference accuracy scores, latency measurements, token usage
- Audit: Prompt version history, evaluation results, regression test logs

### Task 14: Add SRE Principles to python-pro

**Goal:** Add SRE Principles section customized for Python development context.

**File:** `skills/python-pro/SKILL.md`

**Customizations:**
- Safety: mypy, ruff, pytest before merge; virtual environment isolation
- Evidence: Reference test coverage reports, type check results, profiling output
- Audit: Test reports, dependency audit (pip-audit), changelog entries

### Task 15: Add SRE Principles to rust-engineer

**Goal:** Add SRE Principles section customized for Rust development context.

**File:** `skills/rust-engineer/SKILL.md`

**Customizations:**
- Safety: `cargo clippy`, `cargo test`, `cargo audit` before merge
- Evidence: Reference benchmark results, unsafe usage audit, test output
- Audit: Cargo.lock changes, dependency audit, MSRV documentation

### Task 16: Add SRE Principles to secure-code-guardian

**Goal:** Add SRE Principles section customized for application security context.

**File:** `skills/secure-code-guardian/SKILL.md`

**Customizations:**
- Safety: SAST scan before deploy, dependency vulnerability check, secret scanning
- Evidence: Reference CVE IDs, CVSS scores, specific vulnerable code paths
- Audit: Security finding tracker, remediation timelines, compliance evidence

### Task 17: Add SRE Principles to security-reviewer

**Goal:** Add SRE Principles section customized for security audit context.

**File:** `skills/security-reviewer/SKILL.md`

**Customizations:**
- Safety: Authorized testing scope, rules of engagement, non-destructive testing
- Evidence: Reference CVE IDs, CWE classifications, CVSS scores, proof-of-concept results
- Audit: Findings register, remediation tracking, retest evidence

### Task 18: Add SRE Principles to sql-pro

**Goal:** Add SRE Principles section customized for SQL optimization context.

**File:** `skills/sql-pro/SKILL.md`

**Customizations:**
- Safety: EXPLAIN before execution, transaction wrapping, read-replica testing
- Evidence: Reference query plan costs, row estimates vs actuals, index usage statistics
- Audit: Query performance baselines, schema migration history, optimization changelog

### Task 19: Add SRE Principles to sre-engineer

**Goal:** Add SRE Principles section customized for SRE practice context.

**File:** `skills/sre-engineer/SKILL.md`

**Customizations:**
- Safety: Error budget checks before changes, change freeze enforcement
- Evidence: Reference SLO burn rates, error budget remaining, incident metrics
- Audit: SLO revision history, incident postmortems, toil measurements

### Task 20: Add SRE Principles to terraform-engineer

**Goal:** Add SRE Principles section customized for Terraform/IaC context.

**File:** `skills/terraform-engineer/SKILL.md`

**Customizations:**
- Safety: `terraform plan` before apply, state backup, Sentinel/OPA policies
- Evidence: Reference plan output diffs, cost estimates, drift detection results
- Audit: State file versions, apply logs, resource change history

### Task 21: Add SRE Principles to test-master

**Goal:** Add SRE Principles section customized for testing strategy context.

**File:** `skills/test-master/SKILL.md`

**Customizations:**
- Safety: Test isolation, deterministic fixtures, no production data in tests
- Evidence: Reference coverage reports, flakiness rates, test execution times
- Audit: Test result history, coverage trends, flaky test tracking

### Task 22: Update using-srepowers meta-skill with SRE Principles overview

**Goal:** Add the 5 SRE Principles to the meta-skill so they're visible at the top level.

**File:** `skills/using-srepowers/SKILL.md`

**Changes:**
- Add "SRE Principles" section after "The Rule" section
- List all 5 principles with brief descriptions
- Note that all skills (core and domain) are bound by these principles

### Task 23: Update README.md with SRE Principles

**Goal:** Add SRE Principles section to README so marketplace users understand the philosophy.

**File:** `README.md`

**Changes:**
- Add "SRE Principles" section near the top, after Overview
- List all 5 principles with brief descriptions

### Task 24: Update RELEASE-NOTES.md and version

**Goal:** Document the improvement in release notes and bump version.

**Files:**
- `RELEASE-NOTES.md` - Add v3.1.0 entry
- `.claude-plugin/plugin.json` - Bump to 3.1.0

**Changes:**
- Document: "All 20 domain expertise skills now include explicit SRE Principles section"
- List the 5 principles
- Note this is a quality improvement, no breaking changes

---

## Verification

After all tasks complete:

1. Every skill in `skills/*/SKILL.md` contains an "SRE Principles" section with all 5 principles
2. `using-srepowers/SKILL.md` references the 5 principles
3. `README.md` lists the 5 principles
4. `RELEASE-NOTES.md` documents the changes
5. Version bumped in `plugin.json`
6. All existing tests still pass

**Verification commands:**
```bash
# Verify all domain skills have SRE Principles section
for skill in architecture-designer chaos-engineer cloud-architect code-documenter code-reviewer devops-engineer golang-pro kubernetes-specialist microservices-architect monitoring-expert postgres-pro prompt-engineer python-pro rust-engineer secure-code-guardian security-reviewer sql-pro sre-engineer terraform-engineer test-master; do
  grep -q "## SRE Principles" "skills/$skill/SKILL.md" && echo "✅ $skill" || echo "❌ $skill"
done

# Verify meta-skill and README
grep -q "SRE Principles" skills/using-srepowers/SKILL.md && echo "✅ using-srepowers" || echo "❌ using-srepowers"
grep -q "SRE Principles" README.md && echo "✅ README" || echo "❌ README"

# Verify version bump
grep "version" .claude-plugin/plugin.json

# Run tests
bash tests/claude-code/run-skill-tests.sh
```
