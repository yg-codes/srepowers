# Release Notes

## [3.7.0] - 2026-02-24

### Skill Consolidation, Naming Standardization, and Cost Optimization

Consolidated overlapping skills, standardized naming conventions, and added cloud cost optimization skill.

#### New Skills (1)

**Cost & Optimization:**
- **cost-optimizer** - Cloud cost analysis and optimization
  - AWS/GCP/Azure cost analysis and billing data review
  - Right-sizing recommendations for over-provisioned resources
  - Reserved instance and savings plans planning
  - Spot instance strategies for non-critical workloads
  - Cost allocation and chargeback models
  - FinOps best practices and tooling

#### Skill Consolidation

**Merged Skills:**
- **sql-pro** → **postgresql-engineer** (consolidated SQL expertise into PostgreSQL skill)
  - Added cross-database SQL patterns (CTEs, window functions, recursive queries)
  - Added multi-database considerations and query migration guidance
  - Updated skill name from `postgres-pro` to `postgresql-engineer`

#### Naming Standardization

**Renamed Skills (consistent -engineer suffix):**
| Old Name | New Name |
|----------|----------|
| `postgres-pro` | `postgresql-engineer` |
| `docker-expert` | `container-engineer` |
| `monitoring-expert` | `observability-engineer` |

**Updated Commands:**
- `/postgres-pro` → `/postgresql-engineer`
- `/docker-expert` → `/container-engineer`
- `/monitoring-expert` → `/observability-engineer`
- `/sql-pro` → removed (functionality merged)

#### Documentation Improvements

**README.md Updates:**
- Added **Skill Workflow Diagram** (Mermaid) showing operation flow
- Added **Skill Selection Guide** table for quick reference
- Updated all skill references to use new naming
- Removed `verification-before-completion` from superpowers comparison (already removed in v3.5.0)

#### Metrics

- Total skills: 43 → 43 (net: -1 merged, +1 new)
- Total commands: 43 → 43 (net: -1 merged, +1 new)

---

## [3.6.0] - 2026-02-20

### Infrastructure Skills Expansion

Adds 4 new infrastructure skills covering container orchestration, networking, Terragrunt, and platform engineering.

#### New Skills (4)

**Container & Orchestration:**
- **container-engineer** - Container builds, optimization, and security
  - Multi-stage builds, layer optimization, .dockerignore patterns
  - Security hardening (non-root, read-only filesystem, capability dropping)
  - Supply chain security (SBOM generation, cosign signing, SLSA provenance)
  - Docker Compose for local development and production
  - Kubernetes runtime support (containerd, CRI-O)
  - Vulnerability scanning and remediation

**Networking:**
- **network-engineer** - Cloud and hybrid network infrastructure
  - VPC architecture (AWS, Azure, GCP)
  - Load balancing strategies (Layer 4/7, global, internal)
  - DNS management, zone design, failover routing
  - VPN, Direct Connect, ExpressRoute, Cloud Interconnect
  - Zero-trust network architecture
  - Network segmentation and security groups

**Infrastructure Orchestration:**
- **terragrunt-expert** - Terragrunt orchestration for Terraform/OpenTofu
  - DRY configurations across environments
  - Stack architecture (implicit directory-based, explicit blueprint-based)
  - Dependency management with mock outputs
  - Remote state automation
  - Multi-environment deployment workflows

**Platform Engineering:**
- **platform-engineer** - Internal Developer Platforms (IDPs)
  - Self-service infrastructure design
  - Golden path templates for services
  - Backstage developer portal implementation
  - Service catalogs and software templates
  - Platform metrics and adoption tracking
  - Developer experience optimization

#### Updated Components

- `plugin.json`: version 3.6.0, description updated to 43 skills, keywords updated (added terragrunt, docker, networking, platform-engineering, idp, backstage, vpc, load-balancing, dns)

#### Metrics

- Total skills: 39 → 43
- Total commands: 38 → 43

---

## [3.5.0] - 2026-02-19

### Skill Auto-Activation

Introduces automatic skill suggestion via UserPromptSubmit hook, plus refactors skill inventory by delegating non-SRE skills to superpowers plugin.

#### New Features

**Skill Auto-Activation System:**
- **`hooks/skill-activation-prompt.sh`**: UserPromptSubmit hook that reads `hooks/skill-rules.json` and automatically suggests relevant skills before Claude responds. Pure bash+jq implementation with no Node.js dependency.
- **`hooks/skill-rules.json`**: Activation rules for all 39 SRE skills with keyword and intent pattern triggers grouped by priority (critical/high/medium/low).
- Context-aware suggestions based on user message content with minimal overhead (<100ms typical).

#### Refactor (from v3.4.0)

Removed 6 non-SRE or duplicate skills (delegated to superpowers plugin):
- `verification-before-completion` — generic, not SRE-specific
- `requesting-peer-review` — generic, not SRE-specific
- `prompt-engineer` — generic, not SRE-specific
- `cache-cleanup` — developer tool, not SRE-specific
- `clickup-ticket-creator` — project management, not SRE-specific
- `using-srepowers` — delegated to superpowers for cross-plugin coordination

**Remaining skill count: 39** (down from 45)

#### Updated Components

- `plugin.json`: version 3.5.0, description updated to 39 skills, keywords updated (removed cache, clickup, prompt-engineering; added skill-activation, auto-activation)
- `hooks/hooks.json`: updated to use skill-activation-prompt.sh instead of session-start.sh

#### Metrics

- Total skills: 45 → 39
- Total commands: 44 → 38

---

## [3.4.0] - 2026-02-18

### Gap Fixes — Async Verification, Progressive Delivery, Multi-Stack Observability, Toil Analysis, Distributed Incidents

Five gap-fix changes based on comparative analysis against Superpowers. Addresses limitations identified in `comparison-claude.md`.

#### New Skills (2)

**Delivery & Reliability:**
- **progressive-delivery** - Canary/blue-green/shadow traffic release workflows
  - Per-stage TDO cycle with SLO-based rollback triggers
  - Canary stages: 1% → 5% → 25% → 50% → 100%
  - Blue-green cutover with immediate rollback
  - Shadow traffic validation (zero user impact)
  - Inline Prometheus rollback trigger checks (no external scripts)

- **toil-analysis** - Measure and reduce operational toil
  - 4-phase workflow: Inventory → Capacity Planning → Prioritization → Progress
  - Python capacity model projecting 5-quarter toil growth vs team size
  - Impact × Ease × Risk scoring matrix for automation prioritization
  - Reduction progress tracking with before/after baselines

#### Extended Skills (3)

**test-driven-operation:**
- Added `## Async and Eventual-Consistency Verification` section
- Three strategies: Poll-Until-Ready, Event-Based, Baseline-Delta
- Covers managed cloud services (S3, Route53), Kafka lag, async job APIs
- Fixed: silent timeout now explicitly fails with exit code 1

**observability-integration:**
- Added `## Multi-Stack Observability` section
- Datadog: curl API with `DD_API_KEY`/`DD_APP_KEY` variables
- AWS CloudWatch: `aws cloudwatch get-metric-statistics` queries
- New Relic: NerdGraph GraphQL API queries
- Stack-Agnostic Baseline Template: four golden signals table
- Service Mesh: Kiali API + Jaeger trace latency queries
- Fixed: New Relic p99 jq key corrected to `"percentile.duration.99"`
- Fixed: CloudWatch ALB dimensions placeholder marked as requiring substitution

**incident-commander:**
- Added `## Distributed and Async Incident Response` section
- When-to-use table: timezone, duration >8h, >3tz span, no war room
- Async Incident Command Document template (single source of truth)
- IC Handoff Protocol: 30-min checklist + handoff/acknowledgment templates
- Follow-the-Sun IC rotation: APAC/EMEA/Americas windows
- Async communication patterns: channel update + cross-timezone escalation
- Long-running incident management: 4-hour checkpoints
- Escalation Decision Framework: paging thresholds with decision heuristic

#### Metrics

- Total skills: 45 → 47
- Total commands: 44 → 46

---

## [3.3.0] - 2026-02-17

### Developer Experience & Safety Enhancements

Added scaffolding tools, learning resources, safety features, and evaluation framework based on community feedback.

#### New Skills (4)

**Learning & Onboarding:**
- **playground-tutorial** - Safe, local tutorial for learning TDO
  - Uses local files only (no infrastructure risk)
  - Demonstrates RED/GREEN/REFACTOR cycle
  - Practice exercises for verification concepts
  - Safe environment for beginners

- **environment-health-check** - Verify required tools are installed
  - Checks kubectl, terraform, aws CLI, etc.
  - Validates configurations and connectivity
  - Provides installation guidance
  - Can run automatically on session start

**Safety:**
- **safety-validator** - Review commands for high-risk operations
  - Pattern matching for dangerous commands
  - Risk classification (🔴🟠🟡🟢)
  - Requires explicit confirmation for destructive ops
  - Suggests safer alternatives

#### Developer Tools

**Skill Generator (`scripts/create-skill.py`):**
- Interactive skill creation wizard
- Generates SKILL.md with appropriate template
- Creates command wrapper and test template
- Updates README.md automatically
- Supports multiple skill categories

**Evaluation Framework (`evals/`):**
- Automated output quality testing
- Pattern matching for required elements
- Regression detection for skills
- JSON and Markdown report generation
- CI/CD integration ready

#### New Test Scripts

- `test-using-git-worktrees-for-infra.sh`
- `test-finishing-operation-branch.sh`
- `test-systematic-troubleshooting.sh`

#### Metrics

- Total skills: 41 → 45
- Total commands: 40 → 44
- Test scripts: 35 → 38

---

## [3.2.0] - 2026-02-17

### Infrastructure Operations Enhancement

Added 6 new skills to strengthen infrastructure operations workflows, plus completed missing test coverage and structural improvements.

#### New Skills (6)

**Incident Management:**
- **incident-commander** - Coordinate major incident response with ICS structure
  - Role assignment (IC, Operations, Communications, Scribe)
  - Severity levels and escalation triggers
  - Communication templates and timeline tracking
  - Multi-phase response process

- **post-mortem-writer** - Create blameless post-mortems
  - Structured post-mortem template
  - Timeline reconstruction framework
  - Root cause analysis guidelines
  - Action item tracking

**Operations Enhancement:**
- **requesting-peer-review** - Request human peer review for infrastructure changes
  - MR templates with risk assessment
  - Pre-review verification checklist
  - Review criteria (security, reliability, observability)
  - Feedback response templates

- **executing-operation-plans** - Execute plans in separate sessions with checkpoints
  - Batch execution with human review points
  - Environment promotion workflow (sit → uat → prod)
  - Metric verification between batches
  - Rollback decision points

- **observability-integration** - Verify operations using metrics and alerting
  - Pre/post operation metric comparison
  - Prometheus query examples
  - Alert validation
  - Integration with TDO cycles

#### Test Coverage Improvements

**New Test Scripts (3):**
- `test-using-git-worktrees-for-infra.sh` - Tests git worktrees skill
- `test-finishing-operation-branch.sh` - Tests operation completion skill
- `test-systematic-troubleshooting.sh` - Tests troubleshooting skill

#### Structural Improvements

- Added `references/` directories for `using-git-worktrees-for-infra` and `finishing-operation-branch`
- Updated README.md with new skills and commands
- Total skills: 36 → 41
- Total commands: 34 → 40

---

## [3.1.0] - 2026-02-15

### SRE Principles Alignment

All 20 domain expertise skills now include an explicit **SRE Principles** section, aligning them with the same operational discipline that the core workflow skills enforce. Each skill's section is customized to its specific domain.

#### Five SRE Principles (applied to all skills)

1. **Safety First** - All operational commands MUST include dry-run validation before execution
2. **Structured Output** - Use tables, bullet points, and explicit phases (Pre-check → Execute → Verify)
3. **Evidence-Driven** - Always reference specific log lines, metrics, or config parameters
4. **Audit-Ready** - Every recommendation must be traceable and reversible
5. **Communication** - Technical accuracy with business clarity

#### Updated Skills (20)

- architecture-designer, chaos-engineer, cloud-architect, code-documenter, code-reviewer
- devops-engineer, golang-pro, kubernetes-specialist, microservices-architect, monitoring-expert
- postgres-pro, prompt-engineer, python-pro, rust-engineer, secure-code-guardian
- security-reviewer, sql-pro, sre-engineer, terraform-engineer, test-master

#### Also Updated

- **using-srepowers** meta-skill - Added SRE Principles overview section
- **README.md** - Added SRE Principles section
- **plugin.json** - Version bump to 3.1.0

---

## [3.0.0] - 2026-02-10

### Major Release - 20 Domain Expertise Skills

Added 20 domain expertise skills from [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills), providing deep reference knowledge across architecture, cloud, DevOps, languages, security, and SRE domains. These complement the existing 12 SRE workflow skills.

#### New Skills (20)

**Architecture & Design**
- **architecture-designer** - System architecture design, review, ADRs, design patterns, scalability planning
- **cloud-architect** - Cloud architecture, Well-Architected Framework, cost optimization, disaster recovery, landing zones
- **microservices-architect** - Distributed systems, DDD, saga patterns, event sourcing, service mesh

**DevOps & Infrastructure**
- **devops-engineer** - CI/CD pipelines, Docker, Kubernetes, cloud platforms, GitOps
- **terraform-engineer** - Terraform IaC, module development, state management, multi-environment workflows
- **kubernetes-specialist** - Helm charts, RBAC, NetworkPolicies, storage, performance optimization
- **chaos-engineer** - Chaos experiments, failure injection, game days, blast radius control

**Monitoring & Reliability**
- **monitoring-expert** - Prometheus/Grafana, logging, metrics, tracing, alerting, capacity planning
- **sre-engineer** - SLIs/SLOs, error budgets, incident management, toil reduction

**Languages & Development**
- **golang-pro** - Go concurrency, channels, generics, gRPC, microservices
- **python-pro** - Python 3.11+ type safety, async/await, pytest, dataclasses
- **rust-engineer** - Ownership, lifetimes, traits, async with tokio, systems programming
- **sql-pro** - Window functions, CTEs, indexing strategies, query plan analysis
- **postgres-pro** - EXPLAIN analysis, JSONB, replication, VACUUM tuning

**Security**
- **secure-code-guardian** - Authentication, authorization, OWASP Top 10 prevention, encryption
- **security-reviewer** - SAST scans, penetration testing, DevSecOps, cloud security reviews

**Quality & Documentation**
- **code-reviewer** - PR reviews, code quality audits, refactoring suggestions
- **code-documenter** - OpenAPI/Swagger, JSDoc, documentation sites, tutorials
- **test-master** - Test strategies, unit/integration/E2E, coverage analysis, performance testing
- **prompt-engineer** - LLM prompt design, chain-of-thought, few-shot learning, evaluation frameworks

#### New Commands (20)

- `/architecture-designer`, `/cloud-architect`, `/microservices-architect`
- `/devops-engineer`, `/terraform-engineer`, `/kubernetes-specialist`, `/chaos-engineer`
- `/monitoring-expert`, `/sre-engineer`
- `/golang-pro`, `/python-pro`, `/rust-engineer`, `/sql-pro`, `/postgres-pro`
- `/secure-code-guardian`, `/security-reviewer`
- `/code-reviewer`, `/code-documenter`, `/test-master`, `/prompt-engineer`

#### New Tests (20)

- Test scripts for all 20 new skills following existing pattern (3 tests per skill)
- Updated `run-skill-tests.sh` to include all 32 test scripts

#### Enhancements

- **Total skills:** 32 (12 SRE workflow + 20 domain expertise)
- **Total commands:** 31 (11 existing + 20 new)
- **Updated meta-skill** with categorized domain expertise skills and updated priority order
- **Updated plugin description and keywords** to reflect expanded scope
- **Frontmatter standardized** to `name` + `description` only (srepowers convention)

#### Source Attribution

All 20 domain expertise skills sourced from [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills) (MIT license). Each skill includes SKILL.md and references/ directory with deep knowledge bases.

---

## [2.1.0] - 2026-02-09

### Minor Release - Merge from yg-claude Repository

Merged 6 skills from `/home/yg/src/github/yg-claude` into srepowers as the single source of truth, plus container-cicd-reference as documentation.

#### New Skills

**sre-runbook**
- Create structured SRE runbooks with Command/Expected/Result format
- Step-by-step procedures with verification and rollback sections
- Output: Structured runbooks for infrastructure operations

**pve-admin**
- Proxmox VE 8.x/9.x and Proxmox Backup Server 3.x administration
- Cluster management, VM/CT operations, ZFS storage
- Networking, HA setup, backup/restore, health checks
- Helper scripts for common operations

**puppet-code-analyzer**
- Automated Puppet code quality analysis
- Linting, dependency analysis, best practice validation
- Control repo and module analysis
- Error troubleshooting and reporting

**gitlab-ecr-pipeline**
- Generate GitLab CI/CD pipelines for AWS ECR
- Supports building from Containerfile/Dockerfile
- Supports mirroring upstream images
- Proper authentication, tagging, and pushing

**cache-cleanup**
- Interactive cleanup for development tool caches
- Pre-check: Verify tools work before cleanup
- Post-check: Verify tools still work after cleanup
- Supports: mise, npm, Go, Cargo, uv, pipx, pip

**clickup-ticket-creator**
- Create ClickUp tickets following CCB template format
- Structured sections: Description, Rationale, Impact, Risk
- UAT, Procedure, Verification, Rollback sections

#### New Documentation

**Container CI/CD Reference** (`docs/container-cicd-reference/`)
- AWS ECR documentation and patterns
- GitLab Container Registry reference
- IAM authentication patterns
- Container deployment comparisons

#### New Commands

- `/sre-runbook` - Create structured SRE runbooks
- `/pve-admin` - Proxmox VE/Backup administration
- `/puppet-code-analyzer` - Puppet code quality analysis
- `/cache-cleanup` - Interactive dev tool cache cleanup
- `/gitlab-ecr-pipeline` - GitLab CI/CD → AWS ECR pipelines
- `/clickup-ticket-creator` - Create CCB-formatted ClickUp tickets

#### Enhancements

- **Total skills:** 12 (6 core SRE + 6 merged from yg-claude; container-cicd-reference is docs, not a skill)
- **Total commands:** 10 (4 core + 6 new)
- **Updated plugin description** to reflect all skill categories
- **Updated meta-skill** to include all new skills

#### Migration Notes

- `/home/yg/src/github/yg-claude` repository archived (README pointer to srepowers)
- container-cicd-reference moved from skills/ to docs/ (reference documentation)
- All skills now in single source of truth: yg-codes/srepowers

---

## [2.0.0] - 2026-02-09

### Major Release - Complete SRE Operations Framework

Comprehensive expansion with 4 new skills, command system, test suite, meta-skill with hooks, and documentation.

#### New Skills

**verification-before-completion**
- Evidence-before-claims discipline for infrastructure operations
- Infrastructure-specific verification patterns for kubectl, APIs, Git, Keycloak, servers
- Common rationalizations table with infrastructure examples
- Iron Law: NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE

**brainstorming-operations**
- Design infrastructure operations before implementation
- Risk assessment, verification strategies, and rollback planning
- Questions to ask for scope, dependencies, and verification approaches
- Design document output for operation planning

**writing-operation-plans**
- Create detailed infrastructure operation execution plans
- Bite-sized task granularity (2-5 minutes per step)
- Complete YAML, exact commands, expected outputs, rollback steps
- TDO discipline embedded in every task

**using-srepowers** (meta-skill)
- Auto-injected via session-start hook
- Establishes skill invocation discipline before any work
- Red flags table for infrastructure operation rationalizations
- Skill priority and usage patterns

#### New Features

**Command System**
- `/test-driven-operation` - Quick invoke TDO skill
- `/subagent-driven-operation` - Quick invoke SDO skill
- `/brainstorming-operations` - Quick invoke brainstorming skill
- `/writing-operation-plans` - Quick invoke planning skill
- Thin wrappers for fast skill invocation

**Hooks System**
- Session-start hook auto-injects using-srepowers meta-skill
- Hook script reads skill content and injects as context
- Async loading for minimal startup impact

**Test Suite**
- `test-helpers.sh` - Shared test utilities (run_claude, assert_contains, etc.)
- `test-test-driven-operation.sh` - TDO skill unit tests
- `test-subagent-driven-operation.sh` - SDO skill unit tests
- `run-skill-tests.sh` - Test runner with verbose/integration modes

#### Documentation

**Testing Anti-Patterns** (`docs/testing-anti-patterns.md`)
- 8 common infrastructure testing pitfalls
- Why each anti-pattern fails
- Correct TDO approach for each
- Quick reference table

**Persuasion Principles** (`docs/persuasion-principles.md`)
- Seven principles adapted for SRE skills
- Authority + Commitment + Social Proof for discipline
- Infrastructure-specific examples
- Ethical use guidelines

**Implementation Plan** (`docs/plans/2026-02-09-implement-all-8-actions-from-user-feedback.md`)
- Complete development roadmap
- All 8 tasks from user feedback
- Step-by-step implementation guide

#### Enhancements

**Expanded Rationalization Tables**
- TDO: Added 10 infrastructure-specific rationalizations
- SDO: Added 10 operation planning rationalizations

**Why Order Matters Sections**
- TDO: Infrastructure-specific order explanations
- SDO: Two-stage review order rationale with real example
- Review loops explanation with before/after comparison

#### Bug Fixes

- Fixed dangling superpowers references in SDO skill
- All skills now reference srepowers: equivalents
- Removed dependencies on external superpowers plugin

#### Breaking Changes

- Session-start hook requires Claude Code with hooks support
- Meta-skill auto-injection changes startup behavior
- Plugin now standalone (no superpowers dependency)

#### Plugin Structure

```
.claude-plugin/
├── plugin.json (v2.0.0)
└── marketplace.json

commands/
├── test-driven-operation.md
├── subagent-driven-operation.md
├── brainstorming-operations.md (new)
└── writing-operation-plans.md (new)

hooks/
├── hooks.json (new)
└── session-start.sh (new)

skills/
├── test-driven-operation/SKILL.md (enhanced)
├── subagent-driven-operation/SKILL.md (fixed, enhanced)
├── verification-before-completion/SKILL.md (new)
├── brainstorming-operations/SKILL.md (new)
├── writing-operation-plans/SKILL.md (new)
└── using-srepowers/SKILL.md (new)

tests/claude-code/ (new)
├── test-helpers.sh
├── run-skill-tests.sh
├── test-test-driven-operation.sh
└── test-subagent-driven-operation.sh

docs/
├── testing-anti-patterns.md (new)
├── persuasion-principles.md (new)
└── plans/
    └── 2026-02-09-implement-all-8-actions-from-user-feedback.md (new)
```

#### Acknowledgments

Still adapted from the excellent [superpowers](https://github.com/obra/superpowers) plugin, now with full SRE infrastructure adaptations and standalone capability.

---

## [1.0.0] - 2025-02-09

### Initial Release

First release of SREPowers - SRE infrastructure skills for Claude Code.

#### New Skills

**test-driven-operation**
- Test-Driven Operation (TDO) workflow for infrastructure
- Verification-first discipline for kubectl, API calls, Keycloak CRDs, Git MRs, Linux server operations
- Red-Green-Refactor cycle adapted for infrastructure operations
- Comprehensive examples for Kubernetes, Keycloak, Git control repos, APIs, and Linux servers

**subagent-driven-operation**
- Subagent-driven operation workflow for executing infrastructure plans
- Two-stage review process: spec compliance then artifact quality
- Operator subagent with specialized prompts for infrastructure work
- Spec compliance reviewer to verify operations match requirements
- Artifact quality reviewer for YAML/JSON validation and Kubernetes best practices

#### Features

- Full compatibility with Claude Code plugin system
- Marketplace-ready plugin configuration
- Comprehensive documentation with usage examples
- MIT licensed

#### Plugin Structure

- `.claude-plugin/plugin.json` - Plugin manifest
- `.claude-plugin/marketplace.json` - Marketplace configuration
- `skills/test-driven-operation/SKILL.md` - TDO skill definition
- `skills/subagent-driven-operation/` - Subagent-driven operation with prompts:
  - `SKILL.md` - Main skill definition
  - `operator-prompt.md` - Operator subagent prompt template
  - `spec-reviewer-prompt.md` - Spec compliance reviewer prompt
  - `artifact-quality-reviewer-prompt.md` - Artifact quality reviewer prompt

#### Documentation

- Comprehensive README with installation instructions
- Usage examples for multiple infrastructure types
- Clear explanation of TDO principles adapted from TDD
- Two-stage review process documentation

#### Acknowledgments

Adapted from the [superpowers](https://github.com/obra/superpowers) plugin by Jesse Vital, with infrastructure-specific adaptations for SRE workflows.

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 3.7.0 | 2026-02-24 | Skill consolidation (sql-pro → postgresql-engineer), naming standardization (-engineer suffix), cost-optimizer skill |
| 3.6.0 | 2026-02-20 | 4 new infrastructure skills: docker-expert, network-engineer, terragrunt-expert, platform-engineer |
| 3.5.0 | 2026-02-19 | Skill auto-activation via UserPromptSubmit hook; removed 6 non-SRE skills (delegated to superpowers); 39 skills remaining |
| 3.4.0 | 2026-02-18 | Gap fixes: 2 new skills (progressive-delivery, toil-analysis), 3 extended skills (TDO async, observability multi-stack, incident-commander distributed) |
| 3.3.0 | 2026-02-17 | Developer tools: playground-tutorial, environment-health-check, safety-validator, skill generator, evaluation framework |
| 3.2.0 | 2026-02-17 | Infrastructure operations: incident-commander, post-mortem-writer, requesting-peer-review, executing-operation-plans, observability-integration |
| 3.1.0 | 2026-02-15 | SRE Principles added to all 20 domain expertise skills |
| 3.0.0 | 2026-02-10 | Major release: 20 domain expertise skills from Jeffallan/claude-skills (architecture, cloud, DevOps, languages, security, SRE) |
| 2.1.0 | 2026-02-09 | Minor release: Merge 6 skills from yg-claude (sre-runbook, pve-admin, puppet-code-analyzer, gitlab-ecr-pipeline, cache-cleanup, clickup-ticket-creator) + container-cicd-reference docs |
| 2.0.0 | 2026-02-09 | Major release: 4 new skills (VBC, brainstorming-ops, writing-ops, using-srepowers), command system, hooks, test suite, documentation |
| 1.0.0 | 2025-02-09 | Initial release with test-driven-operation and subagent-driven-operation skills |
