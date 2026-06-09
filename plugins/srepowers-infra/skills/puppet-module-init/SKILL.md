---
name: puppet-module-init
description: Use when starting work on a new Puppet infrastructure ticket — reads the ClickUp ticket, identifies the target module, creates a correctly-named topic branch, sets up development context, and creates the ticket documentation skeleton. Also use for "start work on INFRA-XXXX", "begin EXCH-XXXX", "set up module for <ticket>", "create topic branch for <ticket>", "start new ticket", or when beginning any new Puppet infrastructure work.
---

# Puppet Module Init — Start Work on a Ticket

Set up the development context for a new Puppet infrastructure ticket: read the ticket from ClickUp, identify the target module, create a correctly-named topic branch, and create the ticket documentation skeleton. This skill bridges the gap between the ticket system and the development workflow.

**Core principle:** Context before code. Read the ticket, understand the module conventions, create the branch, then start working.

**Announce at start:** "I'm using the puppet-module-init skill to set up work on this ticket."

## Prerequisites

- ClickUp MCP tools available (for ticket lookup)
- Git configured with correct author email (company domain)
- Module repo already cloned locally under `~/src/fsx/puppet/modules/`
- `glab` CLI authenticated to `gitlab.fsx.zone`

Verify before starting:
```bash
git config user.email              # Must be company email
glab auth status                   # Must show authenticated
ls ~/src/fsx/puppet/modules/       # Module must exist locally
```

---

## Step 1: Read the Ticket

Fetch the ticket details from ClickUp.

### If the user provides a ticket ID (e.g., "INFRA-11349"):

```bash
# Use ClickUp search to find the ticket
# The ticket ID is the ClickUp task name or referenced in the description
```

Use the ClickUp MCP tools to search for the ticket:
- Search by the ticket ID in the task name
- Fetch: title, description, status, priority, due date, custom fields
- Report the CCB State if it exists (read the actual API value, never infer)

### If the user provides a ClickUp task URL:

Extract the task ID from the URL and fetch directly.

### Present Summary to User

After fetching the ticket, present a structured summary:

```
Ticket: INFRA-11349 — Modulejail kernel module blacklist
Status: In Progress
Priority: High
CCB State: Approved
Description: <key points from description>
```

Ask the user to confirm this is the correct ticket before proceeding.

---

## Step 2: Identify Target Module(s)

Determine which Puppet module(s) need changes.

### Ask the User

Present the question: "Which module(s) will be modified for this ticket?"

If the ticket description mentions specific modules, suggest them. Otherwise, help the user identify the right module by searching the module list:

```bash
# List available modules
ls ~/src/fsx/puppet/modules/ | sort
```

### Module Selection Guide

| Change Type | Likely Module |
|-------------|--------------|
| Kernel/security hardening | `fsx_infra`, `fsx_kernel_security` |
| Monitoring/checks | `fsx_nrpe` |
| Log management | `fsx_rsyslog`, `fsx_logrotate` |
| User management | `fsx_accounts` (via control repo Hiera) |
| DNS configuration | `fsx_unbound` |
| SSH/server hardening | `fsx_infra` |
| Proxmox management | `fsx_proxmox` |
| JAX business apps | `fsx_jax` |
| Utility/cron jobs | `fsx_run` |
| FreeIPA/SSSD | `fsx_ipa` |
| SFTP configuration | `fsx_sftp` |
| Squid proxy | `fsx_squid` |
| Container runtime | `fsx_podman` |

### Check Module Status

Once the module is identified, verify its current state:

```bash
cd ~/src/fsx/puppet/modules/<module_name>
git status
git branch --show-current       # Should be on main (or master for exceptions)
git log --oneline -5             # Recent activity
```

**Exception modules** that use `master` instead of `main`: `fsx_pcap`, `fsx_repo`, `puppet-keepalived`, `fsx_tacacs`.

### Read Module Conventions

Read the module's `CLAUDE.md` file for coding conventions, testing patterns, and module-specific rules:

```bash
cat ~/src/fsx/puppet/modules/<module_name>/CLAUDE.md
```

Key things to extract:
- Default branch name (`main` vs `master`)
- Test framework (PDK version, rspec-puppet patterns)
- Manifest count and naming conventions
- Template type (ERB vs EPP)
- Hiera data patterns (if module has `data/` directory)
- Any module-specific lint overrides

---

## Step 3: Create Topic Branch

Create a correctly-named topic branch in the module repo.

### Branch Naming Convention

Topic branches **must** follow these rules (enforced by server-side hooks):
- Prefix: `cu_` (change) or `mr_` (merge request)
- Word characters only: letters, digits, underscores
- No hyphens, slashes, dots, or commas
- Include ticket ID and brief description

**Pattern:** `cu_<ticket_id>_<description>`

**Examples:**
```
cu_infra_11349_modulejail
cu_exch_717_auto_reboot
cu_infra_10615_logrotate
```

### Create the Branch

```bash
cd ~/src/fsx/puppet/modules/<module_name>

# Ensure on default branch and up to date
git checkout main          # or 'master' for exception modules
git pull

# Create topic branch
git checkout -b cu_<ticket_id>_<description>
```

### Validate Branch Name

```bash
# Server-side hook rejects branches with non-word characters
# Quick validation:
branch_name=$(git branch --show-current)
echo "$branch_name" | grep -qE '^cu_[a-zA-Z0-9_]+$' && echo "Valid" || echo "INVALID — will be rejected by server hook"
```

If the branch name contains invalid characters, rename immediately:
```bash
git branch -m "$current_name" "cu_<ticket_id>_<sanitized_description>"
```

---

## Step 4: Set Development Context

Present the developer with a comprehensive context summary for working on this ticket.

### Context Summary Template

```
═══ Development Context ═══

Ticket: INFRA-11349 — Modulejail kernel module blacklist
Module: fsx_infra (20 manifests, 41 templates)
Branch: cu_infra_11349_modulejail (from main @ <latest-commit>)

Module Conventions:
  - Default branch: main
  - Template type: EPP (all new templates must use EPP)
  - Testing: pdk validate + bundle exec rake lint + bundle exec rake spec
  - Lint overrides: relative, 140chars, documentation, parameter_documentation

Likely Files to Modify:
  - manifests/security/modulejail.pp (existing class)
  - data/common.yaml (module data)
  - templates/security/modulejail_blacklist.conf.epp (new template)

Related Files:
  - Control repo: control/infra/data/profile/ (Hiera profiles)
  - Test specs: spec/classes/security/modulejail_spec.rb

════════════════════════════
```

### Identify Related Files

Based on the ticket description and module structure, suggest:

1. **Manifests to modify** — grep for existing classes related to the ticket topic
2. **Templates to modify or create** — check existing template patterns
3. **Hiera data to update** — check if the module has a `data/` directory
4. **Spec files to update** — find existing tests for related classes
5. **Control repo files** — identify profile/node YAML files that may need updates

```bash
# Find related manifests
cd ~/src/fsx/puppet/modules/<module_name>
grep -rl "<keyword>" manifests/ 2>/dev/null

# Find related templates
grep -rl "<keyword>" templates/ 2>/dev/null

# Find related specs
grep -rl "<keyword>" spec/ 2>/dev/null
```

---

## Step 5: Create Ticket Documentation Skeleton

Create the `docs/<ticket>` directory and an initial `CLAUDE.md` for tracking work.

### Create Directory

```bash
mkdir -p ~/src/fsx/puppet/docs/<TICKET_ID>
```

### Write Skeleton CLAUDE.md

Write the initial documentation file with ticket metadata and placeholder sections:

```markdown
# <TICKET_ID>: <Ticket Title>

> ClickUp: <ticket_url> | Module: <module_name> | Branch: cu_<ticket>_<desc>

## Goal

<One sentence describing what this ticket achieves>

## Approach

<Describe the approach — fill in after initial analysis>

## Module Changes

### <module_name> (branch: cu_<ticket>_<desc>)

- <change description>

## Control Repo Changes

### control/<infra|jax>

- <change description>

## Validation Checklist

- [ ] pdk validate passes
- [ ] bundle exec rake lint passes
- [ ] bundle exec rake spec passes (all examples)
- [ ] Puppetfile format check passes
- [ ] Noop clean on target hosts
- [ ] Apply successful on target hosts
- [ ] Idempotency verified (second noop shows zero changes)

## Status Log

| Date | Action | Result |
|------|--------|--------|
| <today> | Ticket work started | Module: <name>, Branch: cu_<ticket>_<desc> |
```

This skeleton becomes the living document for the ticket. Update it as work progresses — it serves as the handoff document and audit trail.

---

## Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Module not cloned locally | Module exists on GitLab but not checked out | `cd ~/src/fsx/puppet && git clone <url> modules/<name>` |
| Branch name rejected by server | Contains hyphens, slashes, or dots | Use underscores only: `cu_infra_1234_my_feature` |
| ClickUp ticket not found | Ticket ID doesn't match any task name | Ask user for the exact ClickUp task URL or task ID |
| Module uses `master` not `main` | Exception modules listed above | Use `git checkout master` and `git pull` instead |
| `glab auth` fails | Token expired | User needs to re-authenticate |

---

## Red Flags

- **Never** create a branch name with non-word characters — server hooks reject it
- **Never** create a topic branch from another topic branch — always from `main`/`master`
- **Never** skip reading the module's CLAUDE.md — it contains module-specific conventions
- **Never** assume the default branch is `main` — check the exception list
- **Always** verify `git config user.email` is the company address before committing
- **Always** include the ticket ID in the branch name
- **Always** create the docs skeleton — it's the audit trail for the ticket

---

## Integration

**Pairs with:**
- `srepowers:puppet-release` — after development is complete, use to release the module
- `srepowers:puppet-deploy` — to deploy and validate changes on target hosts
- `srepowers:puppet-code-analyzer` — to validate code quality during development
- `srepowers:puppet-merge-request` — to create MRs when the branch is ready for review
- `srepowers:test-driven-operation` — for verification discipline during development
- `clickup-ticket-searcher` — to find the ClickUp ticket details
