# Merge yg-claude Skills into SREPowers

> **For Claude:** REQUIRED SUB-SKILL: Use srepowers:subagent-driven-operation to implement this plan task-by-task.

**Goal:** Merge all 7 skills from `/home/yg/src/github/yg-claude` into srepowers plugin as the single source of truth

**User Decisions:**
- ✅ Merge ALL 7 skills (not just SRE-relevant)
- ✅ Archive yg-claude repo (README with pointer to srepowers)
- ✅ Add /command wrappers for new skills
- ✅ Move container-cicd-reference to docs/ (reference documentation)

---

## Source Skills Analysis

**From `/home/yg/src/github/yg-claude/skills/`:**

| Skill | Type | Scripts? | References? | Command Needed |
|-------|------|----------|-------------|----------------|
| cache-cleanup | Executable skill | Yes (pre/post check scripts) | Yes | `/cache-cleanup` |
| clickup-ticket-creator | Executable skill | No | No | `/clickup-ticket-creator` |
| container-cicd-reference | Reference doc | No | Yes | No (move to docs/) |
| gitlab-ecr-pipeline | Executable skill | Yes (pipeline templates) | Yes | `/gitlab-ecr-pipeline` |
| puppet-code-analyzer | Executable skill | Yes (analysis scripts) | Yes | `/puppet-code-analyzer` |
| pve-admin | Executable skill | Yes (cluster mgmt scripts) | Yes | `/pve-admin` |
| sre-runbook | Executable skill | No | No | `/sre-runbook` |

---

## Task 1: Copy Skills to SREPowers

**Source:** `/home/yg/src/github/yg-claude/skills/`
**Target:** `/home/yg/src/github/srepowers/skills/`

**Step 1: Create backup of current srepowers**
```bash
cd /home/yg/src/github/srepowers
git status
# Ensure clean state
```

**Step 2: Copy skills (excluding container-cicd-reference which goes to docs/)**
```bash
# Copy all skills to srepowers
cp -r /home/yg/src/github/yg-claude/skills/cache-cleanup /home/yg/src/github/srepowers/skills/
cp -r /home/yg/src/github/yg-claude/skills/clickup-ticket-creator /home/yg/src/github/srepowers/skills/
cp -r /home/yg/src/github/yg-claude/skills/gitlab-ecr-pipeline /home/yg/src/github/srepowers/skills/
cp -r /home/yg/src/github/yg-claude/skills/puppet-code-analyzer /home/yg/src/github/srepowers/skills/
cp -r /home/yg/src/github/yg-claude/skills/pve-admin /home/yg/src/github/srepowers/skills/
cp -r /home/yg/src/github/yg-claude/skills/sre-runbook /home/yg/src/github/srepowers/skills/
```

**Step 3: Verify skill frontmatter**
- Each SKILL.md should have proper YAML frontmatter
- Check for duplicate skill names (should be unique)
- Verify description format matches srepowers style

**Step 4: Copy container-cicd-reference to docs/**
```bash
cp -r /home/yg/src/github/yg-claude/skills/container-cicd-reference /home/yg/src/github/srepowers/docs/container-cicd-reference
```

---

## Task 2: Create Command Wrappers

**Target:** `/home/yg/src/github/srepowers/commands/`

Create command files for each new skill:

**commands/cache-cleanup.md**
```markdown
---
description: "Interactive cleanup for development tool caches (mise, npm, Go, Cargo, uv, pipx, pip) with pre/post verification"
disable-model-invocation: true
---

Invoke the srepowers:cache-cleanup skill and follow it exactly as presented to you
```

**commands/clickup-ticket-creator.md**
```markdown
---
description: "Create ClickUp tickets following CCB template format with Description, Rationale, Impact, Risk sections"
disable-model-invocation: true
---

Invoke the srepowers:clickup-ticket-creator skill and follow it exactly as presented to you
```

**commands/gitlab-ecr-pipeline.md**
```markdown
---
description: "Generate GitLab CI/CD pipelines that push container images to AWS ECR - supports Containerfile or image mirroring"
disable-model-invocation: true
---

Invoke the srepowers:gitlab-ecr-pipeline skill and follow it exactly as presented to you
```

**commands/puppet-code-analyzer.md**
```markdown
---
description: "Automated Puppet code quality analysis for control repos and modules - linting, dependency analysis, best practices"
disable-model-invocation: true
---

Invoke the srepowers:puppet-code-analyzer skill and follow it exactly as presented to you
```

**commands/pve-admin.md**
```markdown
---
description: "Proxmox VE and Proxmox Backup Server administration - cluster management, VM/CT operations, ZFS, networking, HA, backup/restore"
disable-model-invocation: true
---

Invoke the srepowers:pve-admin skill and follow it exactly as presented to you
```

**commands/sre-runbook.md**
```markdown
---
description: "Create structured SRE runbooks with step-by-step procedures containing Command, Expected, and Result sections"
disable-model-invocation: true
---

Invoke the srepowers:sre-runbook skill and follow it exactly as presented to you
```

---

## Task 3: Update README.md

**File:** `/home/yg/src/github/srepowers/README.md`

**Add new skills section after existing skills:**

```markdown
### cache-cleanup

**Use when:** Cleaning up development tool caches interactively with pre/post verification.

**Core principle:** Clean caches safely - verify tools work before cleanup, verify tools still work after cleanup.

**Supported Tools:** mise-managed tools (Go, Rust, Node.js, Python), npm, Cargo, uv, pipx, pip

### clickup-ticket-creator

**Use when:** Creating ClickUp tickets following CCB template format.

**Core principle:** Structured ticket generation with all required sections.

**Sections:** Description, Rationale, Impact, Risk, UAT, Procedure, Verification, Rollback

### gitlab-ecr-pipeline

**Use when:** Creating GitLab CI/CD pipelines that push container images to AWS ECR.

**Core principle:** Generate complete pipelines with proper authentication, building, and pushing.

**Supports:** Building from Containerfile/Dockerfile, mirroring upstream images

### puppet-code-analyzer

**Use when:** Analyzing Puppet code quality in control repos or modules.

**Core principle:** Automated analysis with linting, dependency checking, best practice validation.

**Features:** Syntax validation, dependency analysis, style guide compliance, error troubleshooting

### pve-admin

**Use when:** Managing Proxmox VE 8.x/9.x and Proxmox Backup Server 3.x infrastructure.

**Core principle:** Complete Proxmox administration with cluster management and safe operations.

**Features:** Cluster management, VM/CT operations, ZFS storage, networking, HA, backup/restore, health checks

### sre-runbook

**Use when:** Creating structured SRE runbooks for infrastructure operations.

**Core principle:** Runbooks with Command/Expected/Result format for verifiable procedures.

**Output:** Structured runbooks with pre-requisites, step-by-step procedures, verification, rollback
```

**Update Commands section:**
```markdown
## Commands

Quick invoke skills using `/command` syntax:

**SRE Operations:**
- `/test-driven-operation` - Execute operations with verification commands
- `/subagent-driven-operation` - Execute operation plans with subagent dispatch
- `/brainstorming-operations` - Design infrastructure operations
- `/writing-operation-plans` - Create detailed execution plans
- `/sre-runbook` - Create structured SRE runbooks
- `/verification-before-completion` - Evidence-before-claims discipline

**Infrastructure Administration:**
- `/pve-admin` - Proxmox VE/Backup administration
- `/puppet-code-analyzer` - Puppet code quality analysis
- `/cache-cleanup` - Interactive dev tool cache cleanup

**CI/CD & Pipelines:**
- `/gitlab-ecr-pipeline` - GitLab CI/CD → AWS ECR pipelines

**Project Management:**
- `/clickup-ticket-creator` - Create CCB-formatted ClickUp tickets

Commands are thin wrappers that invoke skills directly for quick access.
```

**Update Documentation section:**
```markdown
## Documentation

- [Testing Anti-Patterns](docs/testing-anti-patterns.md) - Common infrastructure operation testing pitfalls
- [Persuasion Principles](docs/persuasion-principles.md) - Psychology of effective SRE skill design
- [Container CI/CD Reference](docs/container-cicd-reference/) - ECR, GitLab Container Registry, IAM auth patterns
- [Implementation Plan](docs/plans/2026-02-09-implement-all-8-actions-from-user-feedback.md) - Development roadmap
```

---

## Task 4: Update Plugin Metadata

**File:** `/home/yg/src/github/srepowers/.claude-plugin/plugin.json`

**Update description:**
```json
{
  "name": "srepowers",
  "description": "SRE infrastructure skills: Test-Driven Operations, Subagent-Driven Operations, runbooks, Proxmox administration, Puppet analysis, cache cleanup, GitLab ECR pipelines, and ClickUp ticket creation for Kubernetes, Keycloak, GitOps, Proxmox VE, and CI/CD workflows",
  "version": "2.1.0",
  "author": {
    "name": "yg",
    "email": "yg@example.com"
  },
  "homepage": "https://github.com/yg-codes/srepowers",
  "repository": "https://github.com/yg-codes/srepowers",
  "license": "MIT",
  "keywords": ["sre", "infrastructure", "kubernetes", "keycloak", "gitops", "tdo", "operations", "devops", "api", "kubectl", "verification", "planning", "proxmox", "pve", "pbs", "puppet", "cache", "gitlab", "ecr", "clickup", "runbook"]
}
```

---

## Task 5: Update using-srepowers Meta-Skill

**File:** `/home/yg/src/github/srepowers/skills/using-srepowers/SKILL.md`

**Add new skills to the skills list:**

```markdown
## SRE Infrastructure Skills

### Core Execution Skills

**test-driven-operation** - Execute infrastructure operations with verification commands
**verification-before-completion** - Verify before claiming completion

### Planning & Documentation Skills

**brainstorming-operations** - Design infrastructure operations before implementation
**writing-operation-plans** - Create detailed infrastructure operation execution plans
**sre-runbook** - Create structured SRE runbooks with Command/Expected/Result format

### Multi-Task Execution Skills

**subagent-driven-operation** - Execute infrastructure operation plans with subagent dispatch

### Infrastructure Administration Skills

**pve-admin** - Proxmox VE/Backup Server administration
- Cluster management, VM/CT operations, ZFS storage, networking, HA
- Backup/restore, health checks, resource management

**puppet-code-analyzer** - Puppet code quality analysis
- Linting, dependency analysis, best practice validation
- Control repo and module analysis

### CI/CD & Pipeline Skills

**gitlab-ecr-pipeline** - GitLab CI/CD → AWS ECR pipelines
- Containerfile builds, image mirroring
- AWS authentication, tagging strategies

### Development Tools

**cache-cleanup** - Interactive cleanup for dev tool caches
- mise, npm, Go, Cargo, uv, pipx, pip
- Pre/post verification to ensure tools remain functional

### Project Management

**clickup-ticket-creator** - ClickUp tickets with CCB template
- Description, Rationale, Impact, Risk sections
- UAT, Procedure, Verification, Rollback
```

---

## Task 6: Create Release Notes

**File:** `/home/yg/src/github/srepowers/RELEASE-NOTES.md`

**Add new release section:**

```markdown
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
[... existing 2.0.0 notes ...]
```

**Update version history table:**
```markdown
| Version | Date | Description |
|---------|------|-------------|
| 2.1.0 | 2026-02-09 | Minor release: Merge 7 skills from yg-claude (sre-runbook, pve-admin, puppet-code-analyzer, gitlab-ecr-pipeline, cache-cleanup, clickup-ticket-creator, container-cicd-reference docs) |
| 2.0.0 | 2026-02-09 | Major release: 4 new skills (VBC, brainstorming-ops, writing-ops, using-srepowers), command system, hooks, test suite, documentation |
| 1.0.0 | 2025-02-09 | Initial release with test-driven-operation and subagent-driven-operation skills |
```

---

## Task 7: Archive yg-claude Repository

**Target:** `/home/yg/src/github/yg-claude/`

**Step 1: Create archive README**
```bash
cat > /home/yg/src/github/yg-claude/README.md <<'EOF'
# yg-claude (ARCHIVED)

⚠️ **This repository has been archived.**

All skills from this repository have been merged into the **SREPowers** plugin as the single source of truth.

## New Location

👉 **[yg-codes/srepowers](https://github.com/yg-codes/srepowers)**

## What Changed?

All 7 skills from this repository are now part of SREPowers:

| Skill | New Home |
|-------|----------|
| cache-cleanup | [srepowers:cache-cleanup](https://github.com/yg-codes/srepowers) |
| clickup-ticket-creator | [srepowers:clickup-ticket-creator](https://github.com/yg-codes/srepowers) |
| container-cicd-reference | [docs/container-cicd-reference/](https://github.com/yg-codes/srepowers) |
| gitlab-ecr-pipeline | [srepowers:gitlab-ecr-pipeline](https://github.com/yg-codes/srepowers) |
| puppet-code-analyzer | [srepowers:puppet-code-analyzer](https://github.com/yg-codes/srepowers) |
| pve-admin | [srepowers:pve-admin](https://github.com/yg-codes/srepowers) |
| sre-runbook | [srepowers:sre-runbook](https://github.com/yg-codes/srepowers) |

## Migration Instructions

If you have this repository installed:

1. **Uninstall old skills:**
   ```bash
   rm -rf ~/.claude/plugins/skills/cache-cleanup
   rm -rf ~/.claude/plugins/skills/clickup-ticket-creator
   rm -rf ~/.claude/plugins/skills/gitlab-ecr-pipeline
   rm -rf ~/.claude/plugins/skills/puppet-code-analyzer
   rm -rf ~/.claude/plugins/skills/pve-admin
   rm -rf ~/.claude/plugins/skills/sre-runbook
   ```

2. **Install SREPowers:**
   ```bash
   # Via Claude Code Marketplace
   /plugin marketplace add yg/srepowers-marketplace
   /plugin install srepowers@srepowers-marketplace
   ```

## Why the Merge?

- **Single source of truth** - All skills in one plugin
- **Better organization** - Related skills grouped together
- **Unified documentation** - One place for all SRE/DevOps skills
- **Easier maintenance** - One repository to update
- **Consistent structure** - All skills follow srepowers patterns

## Archive Contents

This repository retains historical context but is no longer actively maintained.

- Last active: 2026-02-09
- Merged to: [yg-codes/srepowers v2.1.0](https://github.com/yg-codes/srepowers)
EOF
```

**Step 2: Remove all content except README and .git**
```bash
cd /home/yg/src/github/yg-claude
rm -rf skills/
rm -rf .claude/
rm -f CLAUDE.md SECURITY_REVIEW_REPORT.md
git add -A
```

**Step 3: Commit archive changes**
```bash
git commit -m "archive: Merge skills to srepowers plugin

All skills migrated to yg-codes/srepowers as single source of truth.
See: https://github.com/yg-codes/srepowers"
```

**Step 4: Push to GitHub**
```bash
git push origin main
```

**Step 5: (Optional) Add GitHub repository redirect**
- Go to repository Settings on GitHub
- Add repository description: "⚠️ ARCHIVED - Merged to yg-codes/srepowers"
- Add link to srepowers in About section

---

## Task 8: Commit and Push SREPowers Changes

**Target:** `/home/yg/src/github/srepowers/`

**Step 1: Stage all changes**
```bash
cd /home/yg/src/github/srepowers
git add -A
```

**Step 2: Review changes**
```bash
git status
git diff --cached --stat
```

**Step 3: Commit with comprehensive message**
```bash
git commit -m "feat: merge all skills from yg-claude (v2.1.0)

Merge 7 skills from yg-claude repository as single source of truth.

New Skills:
- sre-runbook: Structured SRE runbooks with Command/Expected/Result
- pve-admin: Proxmox VE/Backup Server administration
- puppet-code-analyzer: Puppet code quality analysis
- gitlab-ecr-pipeline: GitLab CI/CD → AWS ECR pipelines
- cache-cleanup: Interactive dev tool cache cleanup
- clickup-ticket-creator: CCB-formatted ClickUp tickets

New Documentation:
- container-cicd-reference: ECR, GitLab Container Registry, IAM auth

New Commands:
- /sre-runbook, /pve-admin, /puppet-code-analyzer
- /cache-cleanup, /gitlab-ecr-pipeline, /clickup-ticket-creator

Updates:
- Plugin version: 2.0.0 → 2.1.0
- Total skills: 6 → 13
- Total commands: 4 → 10
- README: New skills documented
- using-srepowers: All skills listed in meta-skill
- RELEASE-NOTES: v2.1.0 changelog

yg-claude repository archived with pointer to srepowers.
"
```

**Step 4: Push to GitHub**
```bash
git push origin main
git tag -a v2.1.0 -m "Release v2.1.0: Merge from yg-claude"
git push origin v2.1.0
```

---

## Summary

**Skills to merge:** 7 (6 executable skills + 1 reference doc)
**Skills after merge:** 13 total
**Commands added:** 6 new command wrappers
**Documentation added:** container-cicd-reference/
**Version bump:** 2.0.0 → 2.1.0

**Repository actions:**
- SREPowers: Updated and pushed as single source of truth
- yg-claude: Archived with README pointing to srepowers

**Execution Order:** Tasks are sequential - complete each task before moving to next.
