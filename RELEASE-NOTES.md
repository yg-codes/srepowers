# Release Notes

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
| 3.0.0 | 2026-02-10 | Major release: 20 domain expertise skills from Jeffallan/claude-skills (architecture, cloud, DevOps, languages, security, SRE) |
| 2.1.0 | 2026-02-09 | Minor release: Merge 6 skills from yg-claude (sre-runbook, pve-admin, puppet-code-analyzer, gitlab-ecr-pipeline, cache-cleanup, clickup-ticket-creator) + container-cicd-reference docs |
| 2.0.0 | 2026-02-09 | Major release: 4 new skills (VBC, brainstorming-ops, writing-ops, using-srepowers), command system, hooks, test suite, documentation |
| 1.0.0 | 2025-02-09 | Initial release with test-driven-operation and subagent-driven-operation skills |
