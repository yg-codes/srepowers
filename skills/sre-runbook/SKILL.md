---
name: sre-runbook
description: Use when creating or updating SRE runbooks for ANY infrastructure operations. Invoke this skill for documenting step-by-step procedures that require non-interactive SSH commands, with each step containing Command, Expected, and Result sections.
---

# SRE Runbook Writer

## Overview

This skill enables creation of comprehensive, executable SRE runbooks for ANY infrastructure operation. Each runbook step must include three mandatory sections: **Command** (the action), **Expected** (anticipated outcome), and **Result** (actual outcome).

Runbooks are designed for **non-interactive command execution** - all commands must be scriptable, copy-pasteable, and require no user input during execution.

## When to Use This Skill

Invoke this skill when:
- Documenting any server operation (configuration changes, maintenance, troubleshooting)
- Creating procedures for service restarts, log checks, health verification
- Writing operational checklists (pre-flight, post-flight, validation)
- Documenting command sequences for incident response
- Creating step-by-step guides for infrastructure tasks
- Writing procedures that use SSH, systemctl, podman/docker, kubectl, etc.

## Non-Interactive Command Principles

All commands in runbooks must be **non-interactive**:

| Principle | Do | Don't |
|-----------|-----|-------|
| No prompts | Use `--yes`, `--force`, `--batch` flags | Commands that ask for confirmation |
| No stdin | Pass passwords via environment variables | Interactive password prompts |
| No editors | Use `sed`, `awk`, or file replacement | `vi`, `nano`, `vim` |
| No paging | Use `--no-pager` or `| head -N` | Commands that paginate output |
| Explicit | Full paths, explicit flags | Rely on shell state |

```bash
# ✅ Good - Non-interactive
ssh server "sudo systemctl restart service --no-block"
ssh server "sudo podman exec -i container command < /dev/null"

# ❌ Bad - Requires interaction
ssh server "vi /etc/config.conf"
ssh server "systemctl restart service"  # may ask for password
```

## Runbook Structure

### 1. Header Metadata

```markdown
# [Operation Name] Runbook

**Date**: [YYYY-MM-DD]
**Environment**: [production/staging/dev]
**Servers**: [host1.example.com, host2.example.com]
**Purpose**: [What this runbook accomplishes]

## Overview

[2-3 sentences explaining the operation]
```

### 2. Step Format (REQUIRED)

Every step MUST follow this exact format:

```markdown
### Step X.X: [Descriptive Title]

[Brief explanation of what this step does and why]

**Command**:
```bash
[exact, non-interactive command]
```

**Expected**: [precise description of successful outcome]

**Result**: ✅ [actual outcome] or ❌ [failure] or ⏳ [pending]
```

### 3. Section Organization

Organize steps into logical parts based on the operation:

- **Part 1: Pre-checks** - Verify system state before changes
- **Part 2: Execution** - Perform the actual operations
- **Part 3: Verification** - Confirm the changes worked
- **Part 4: Post-checks** - Ensure system health after completion

### 4. Completion Summary

```markdown
## Completion Summary

| Step | Description | Status |
|------|-------------|--------|
| 1.1 | [Brief description] | ✅ |
| 1.2 | [Brief description] | ✅ |
| 2.1 | [Brief description] | ⏳ |
```

## Step Patterns by Operation Type

### Service Operations

```markdown
### Step 1.1: Check Service Status

Verify current service state before making changes.

**Command**:
```bash
ssh server.example.com "sudo systemctl status nginx --no-pager | head -15"
```

**Expected**: Service shows `active (running)` or `inactive (dead)`

**Result**: ✅ Service active (running), uptime 5 days
```

### Configuration Changes

```markdown
### Step 2.3: Update Configuration File

Apply new configuration using non-interactive replacement.

**Command**:
```bash
ssh server.example.com "sudo sed -i 's/old_value/new_value/g' /etc/config.conf && sudo cat /etc/config.conf | grep new_value"
```

**Expected**: Configuration file shows updated value

**Result**: ✅ Value updated from "old_value" to "new_value"
```

### Container Operations

```markdown
### Step 3.1: Verify Container Health

Check all containers are running and healthy.

**Command**:
```bash
ssh server.example.com "sudo podman ps --format 'table {{.Names}}\t{{.Status}}'"
```

**Expected**: All required containers show "Up" status

**Result**: ✅ 3 containers running (db, app, proxy)
```

### Log Verification

```markdown
### Step 4.2: Check for Errors

Verify no critical errors in recent logs.

**Command**:
```bash
ssh server.example.com "sudo journalctl -u service --since '10 minutes ago' --no-pager | grep -iE 'error|fail|crit' | tail -5 || echo 'No errors found'"
```

**Expected**: No critical errors (warnings acceptable)

**Result**: ✅ No critical errors found
```

### Disk/Resource Checks

```markdown
### Step 1.2: Verify Disk Space

Confirm sufficient disk space for operation.

**Command**:
```bash
ssh server.example.com "df -h /var/log | tail -1"
```

**Expected**: Available space > 5GB

**Result**: ✅ 24G available (18% used)
```

### Backup Operations

```markdown
### Step 2.1: Create Backup

Generate timestamped backup before changes.

**Command**:
```bash
ssh server.example.com "sudo cp /etc/config.conf /etc/config.conf.backup_\$(date +%Y%m%d_%H%M%S) && ls -lh /etc/config.conf.backup_*"
```

**Expected**: Backup file created with timestamp

**Result**: ✅ Backup created: config.conf.backup_20260129_120000
```

### File Verification

```markdown
### Step 3.4: Verify File Integrity

Confirm transferred file is valid.

**Command**:
```bash
ssh server.example.com "md5sum /tmp/datafile.tar.gz && tar -tzf /tmp/datafile.tar.gz | head -5"
```

**Expected**: Checksum matches source, archive is readable

**Result**: ✅ MD5: a1b2c3d4..., archive valid
```

### Network/Connectivity Checks

```markdown
### Step 1.3: Test Network Connectivity

Verify target is reachable before operation.

**Command**:
```bash
ssh -o ConnectTimeout=5 server.example.com "echo 'Connected' && hostname"
```

**Expected**: Returns "Connected" and hostname

**Result**: ✅ Connected, hostname: server.example.com
```

## Writing Guidelines

### Command Blocks
- Use exact, copy-pasteable commands
- Always quote commands passed to SSH: `ssh server "command"`
- Use `--no-pager` for systemctl, journalctl
- Use `| head -N` to limit output size
- Use `|| echo "fallback"` for graceful failure handling

### Expected Section
- Be specific about what success looks like
- Include expected values, counts, or status strings
- Define what constitutes warning vs failure
- Note acceptable variances (e.g., "> 5GB", "3-5 containers")

### Result Section
- Use ✅ for successful completion
- Use ❌ for failed steps
- Use ⏳ for pending/not executed steps
- Include actual values from verification (e.g., "✅ 769 assets")
- Note any deviations from expected

### Numbering
- Use hierarchical numbering: Part (X) → Step (X.X)
- Restart step numbers per part (1.1, 1.2, then 2.1, 2.2)
- Makes it easy to reference specific steps during execution

### Step Granularity
- One verifiable action per step
- Split complex operations into multiple steps
- Each step should produce a checkable result
- Verification step after every critical operation

## Common SSH Flags for Non-Interactive Execution

| Flag | Purpose | Example |
|------|---------|---------|
| `-o ConnectTimeout=N` | Fail fast if unreachable | `ssh -o ConnectTimeout=5 server` |
| `-o BatchMode=yes` | Never ask for passwords | `ssh -o BatchMode=yes server` |
| `-o StrictHostKeyChecking=no` | Skip host key prompt (use carefully) | `ssh -o StrictHostKeyChecking=no server` |
| `-q` | Quiet mode, reduce output | `ssh -q server "command"` |

## Output

Generate the runbook as a `.md` file in the user's specified location or a sensible default (e.g., current directory or `/tmp/`).
