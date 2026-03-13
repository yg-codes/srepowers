---
name: puppet-doc-sync
description: |
  Daily documentation sync for Puppet multi-repo projects. Use when user wants to update CLAUDE.md files after pulling latest code, sync documentation across control repos and modules, or mentions "daily sync", "update docs after pull", "puppet documentation sync". Triggers for Puppet infrastructure repositories with multiple independent git sub-projects.

  TRIGGER: When user says "pull and update docs", "sync puppet docs", "update CLAUDE.md after pull", "daily puppet sync", or similar documentation maintenance tasks for multi-repo Puppet projects.
---

# Puppet Documentation Sync

Synchronize CLAUDE.md documentation across a multi-repo Puppet infrastructure after pulling latest code.

## Overview

This skill automates the daily workflow of:
1. Pulling latest code from all sub-projects
2. Analyzing git history for recent changes
3. Updating each sub-project's CLAUDE.md with current state
4. Consolidating findings into the root project CLAUDE.md

## When to Use

- After pulling latest code in a Puppet multi-repo project
- When updating documentation after code changes
- Daily maintenance of CLAUDE.md files
- When user mentions "sync docs", "update CLAUDE.md", "pull and document"

## Project Structure Assumptions

```
/puppet-root/
├── CLAUDE.md              # Root documentation
├── control/
│   ├── infra/CLAUDE.md    # Control repo docs
│   ├── jax/CLAUDE.md
│   └── proxmox/CLAUDE.md
└── modules/
    ├── fsx_run/CLAUDE.md  # Module docs
    ├── fsx_atp/CLAUDE.md
    └── ... (50+ modules)
```

Each subdirectory is an **independent git repository**.

## Workflow

### Step 1: Pull Latest Code

```bash
# Pull all control repos
for repo in control/infra control/jax control/proxmox; do
  git -C $repo pull
done

# Pull all modules
for module in modules/*/; do
  git -C $module pull 2>/dev/null || echo "Skipped: $module"
done
```

### Step 2: Dispatch Parallel Agents

Use the **subagent-driven approach** for efficiency. Group sub-projects into logical domains:

| Agent | Scope | Modules |
|-------|-------|---------|
| Control Repos | infra, jax, proxmox | 3 |
| Core Infra | accounts, dns, ipa, network, etc. | ~15 |
| Business | atp, jax, jsda, surveillance, etc. | ~11 |
| Services | keepalived, postgres, podman, etc. | ~10 |
| Utilities | run, archive, sftp, repo, etc. | ~11 |

**Total: ~50 sub-projects**

### Step 3: Agent Task Template

Each agent should:

1. **Read existing CLAUDE.md** for each assigned module
2. **Check git history**:
   ```bash
   git -C <path> log --oneline -5
   ```
3. **Count manifests and templates**:
   ```bash
   ls <path>/manifests/ | wc -l
   ls <path>/templates/ 2>/dev/null | wc -l
   ```
4. **Update CLAUDE.md** with:
   - Current manifest/template counts
   - "Recent Changes" section from git history
   - Any notable ticket IDs (INFRA-XXXX, EXCH-XXX, OPS-XXXX)
5. **Return summary table**:
   ```
   | Module | Manifests | Templates | Recent Changes | Updated? |
   ```

### Step 4: Update Root CLAUDE.md

After all agents complete:

1. **Update Last Updated date**:
   ```markdown
   **Last Updated:** YYYY-MM-DD
   ```

2. **Add/Update Recent Changes section**:
   ```markdown
   ## Recent Changes (YYYY-MM)

   ### Control Repositories
   - **infra**: TICKET-ID (description)
   - **jax**: TICKET-ID (description)
   - **proxmox**: TICKET-ID (description)

   ### Key Module Updates
   - **module_name**: TICKET-ID (description)

   ### PDK Conversions
   List modules converted to PDK format
   ```

3. **Correct any inaccurate counts** discovered during the sync

## Agent Prompt Template

```markdown
You are updating CLAUDE.md documentation files for Puppet [domain] modules after a git pull.

## Task
Review and update CLAUDE.md files for these modules:
- /path/to/module1/
- /path/to/module2/
- ...

## Process for each module:
1. Read the existing CLAUDE.md
2. Check git log: `git -C <path> log --oneline -5`
3. List manifest files: `ls <path>/manifests/`
4. Check for templates: `ls <path>/templates/ 2>/dev/null | wc -l`
5. Update CLAUDE.md with:
   - Current manifest count and key classes
   - Recent changes from git history
   - Template count if applicable

## Output format
Return a summary table:
| Module | Manifests | Templates | Recent Changes | CLAUDE.md Updated? |

Do NOT make changes unrelated to documentation.
```

## Key Conventions

### Ticket ID Formats
- `INFRA-XXXX` - Infrastructure tickets
- `EXCH-XXX` - Exchange-related tickets
- `OPS-XXXX` - Operations tickets
- `DEVOPS-XXX` - DevOps tickets

### Branch Conventions
- Default branch: `main`
- Exceptions using `master`: fsx_pcap, fsx_repo, puppet-keepalived, fsx_tacacs

### Documentation Sections
Each CLAUDE.md should include:
- Module description
- Classes/manifests table
- Templates (if any)
- Custom types/providers (if any)
- Recent Changes section (date-based)

## Verification

After completion, verify:

```bash
# Count CLAUDE.md files
find /puppet-root -name "CLAUDE.md" -type f | wc -l

# Check modules with Recent Changes
grep -l "Recent Changes" modules/*/CLAUDE.md | wc -l

# Verify root CLAUDE.md date
grep "Last Updated" CLAUDE.md
```

## Time Estimate

- Pull all repos: ~1-2 minutes
- Parallel agent updates: ~3-5 minutes
- Root CLAUDE.md update: ~1 minute
- **Total: ~5-8 minutes** (vs 20+ minutes sequential)

## Example Usage

```
User: "puppet doc sync"
User: "pull and update docs"
User: "daily sync"
User: "update CLAUDE.md after pull"
```

## Notes

- Always use `git -C <path>` for git operations (root is not a git repo)
- Preserve existing documentation structure
- Only add "Recent Changes" if there are meaningful commits
- Skip modules with no changes since last sync
