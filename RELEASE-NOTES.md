# Release Notes

## [2.1.0] - 2026-02-09

### Minor Release - Merge from yg-claude Repository

Merged all 7 skills from `/home/yg/src/github/yg-claude` into srepowers as the single source of truth.

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

- **Total skills:** 13 (6 core SRE + 7 merged from yg-claude)
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
| 2.1.0 | 2026-02-09 | Minor release: Merge 7 skills from yg-claude (sre-runbook, pve-admin, puppet-code-analyzer, gitlab-ecr-pipeline, cache-cleanup, clickup-ticket-creator, container-cicd-reference docs) |
| 2.0.0 | 2026-02-09 | Major release: 4 new skills (VBC, brainstorming-ops, writing-ops, using-srepowers), command system, hooks, test suite, documentation |
| 1.0.0 | 2025-02-09 | Initial release with test-driven-operation and subagent-driven-operation skills |
