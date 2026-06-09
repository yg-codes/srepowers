---
name: ansible-operations
description: Use when writing or running Ansible playbooks, managing inventory, working with ansible-vault, troubleshooting playbook failures, or managing fleet automation with Ansible. Also use for "run this playbook", "write an ansible role", "decrypt vault", "ansible inventory", "ansible-playbook", "check playbook syntax", "run against these hosts", or any Ansible-related task including playbook authoring, role development, inventory management, and execution.
---

# Ansible Operations

Author, validate, and execute Ansible playbooks for fleet automation. Covers the full lifecycle: playbook development, role structure, inventory management, vault handling, execution, and result classification.

**Core principle:** Idempotent by default, dry-run before apply, structured output for result classification.

**Announce at start:** "I'm using the ansible-operations skill to [author/validate/execute] Ansible playbooks."

## When to Use

**Use when:**
- Writing new playbooks or roles
- Modifying existing playbooks in `ansible-playbooks-prod/`
- Running playbooks against hosts (local or remote)
- Managing ansible-vault encrypted variables
- Debugging playbook failures or unexpected changes
- Managing inventory files (INI, YAML, dynamic)
- Converting ad-hoc shell commands into idempotent Ansible tasks

**Exceptions:**
- One-off commands on a single host — use SSH directly
- Configuration management that belongs in Puppet — Ansible supplements, not replaces, Puppet in this environment

## Project Detection

| Path Pattern | Type | Notes |
|-------------|------|-------|
| `~/src/ansible-playbooks-prod/` | Main playbook repo | INI inventory in `inventory/`, variables in `group_vars/` and `host_vars/` |
| `ansible.cfg` present | Playbook root | Ansible configuration file |
| `roles/` directory | Role structure | Standard or custom role layout |
| `*.yml` / `*.yaml` with `---` and `hosts:` | Playbook file | Ansible YAML playbook |

## The Process

### Phase 1: Author / Review

When writing or modifying playbooks:

**Idempotency is the primary quality metric.** Every task should produce the same result whether run once or ten times. Use:

- `creates` / `removes` parameters on `command`/`shell` tasks
- `when` conditionals to skip already-applied state
- `register` + `changed_when`/`failed_when` for command tasks
- Ansible modules over shell commands (`file` over `mkdir`, `copy` over `scp`, `package` over `apt`)

**Role structure** — follow the standard layout:
```
role-name/
├── defaults/main.yml      # Default variables (lowest priority)
├── vars/main.yml          # Role variables (higher priority)
├── tasks/main.yml         # Task list
├── handlers/main.yml      # Handlers (notified by tasks)
├── templates/             # Jinja2 templates
├── files/                 # Static files
├── meta/main.yml          # Role dependencies and metadata
└── templates/             # Jinja2 templates
```

**Variable precedence** (most common sources, low to high):
1. `role/defaults/main.yml`
2. `group_vars/all.yml`
3. `group_vars/<group>.yml`
4. `host_vars/<host>.yml`
5. `role/vars/main.yml`
6. `--extra-vars` on command line

### Phase 2: Validate

Before any execution, validate syntax and structure:

```bash
# Syntax check (no execution)
ansible-playbook --syntax-check playbook.yml

# Dry run with diff (shows what would change)
ansible-playbook --check --diff playbook.yml

# List affected hosts without running
ansible-playbook --list-hosts playbook.yml

# List tasks without running
ansible-playbook --list-tasks playbook.yml
```

**Review the diff output for:**
- Unexpected changes (task not as idempotent as expected)
- Changes to files that shouldn't be touched
- Missing changes (task didn't detect drift)

### Phase 3: Execute

**Local-connection mode** — this environment runs playbooks primarily with `connection: local` on the target host:

```bash
# Run on a single host via SSH (playbook has connection: local)
ssh host01.example.com 'cd /path/to/playbooks && ansible-playbook playbook.yml'

# Run with verbose output for debugging
ansible-playbook -vv playbook.yml

# Limit to specific hosts or groups
ansible-playbook --limit host01 playbook.yml
```

**Remote mode** (when playbook runs from a control node):

```bash
# Standard execution
ansible-playbook -i inventory/production playbook.yml

# With vault-encrypted variables
ansible-playbook --ask-vault-pass -i inventory/production playbook.yml

# With extra variables
ansible-playbook -i inventory/production playbook.yml --extra-vars "key=value"
```

### Phase 4: Classify Results

Ansible task results follow this pattern:

| Result | Meaning | Action |
|--------|---------|--------|
| `ok` | No change needed (idempotent) | Expected for repeat runs |
| `changed` | Task modified system state | Review — was this expected? |
| `failed` | Task encountered an error | Investigate, fix, re-run |
| `unreachable` | Host not contactable | Network/SSH issue |
| `rescued` | Failed but rescued by `rescue` block | Check the rescue logic |
| `ignored` | Failed but `ignore_errors: true` | Verify this is intentional |

**The single rule for a successful run:**
```
Real success = (no "failed" or "unreachable" tasks) AND (play recap shows expected changed/ok counts)
```

### Phase 5: Verify

After execution, verify the intended state:

```bash
# Check service status
ssh host 'systemctl is-active <service>'

# Verify file content
ssh host 'cat /path/to/file'

# Run a validation playbook (read-only gather facts)
ansible host -m setup | grep '<fact_name>'
```

## Vault Operations

Encrypt sensitive variables with ansible-vault:

```bash
# Create encrypted file
ansible-vault create group_vars/vault.yml

# Edit encrypted file
ansible-vault edit group_vars/vault.yml

# Encrypt existing file
ansible-vault encrypt group_vars/secrets.yml

# Decrypt (for local review only — re-encrypt after)
ansible-vault decrypt group_vars/secrets.yml

# View without decrypting
ansible-vault view group_vars/secrets.yml

# Re-key (change password)
ansible-vault rekey group_vars/secrets.yml
```

**Vault file conventions:**
- Store vault files separately from non-sensitive variables (`vault.yml` vs `vars.yml`)
- Reference vault variables in playbooks the same way as regular variables
- Never commit decrypted vault files to git

## Inventory Patterns

**INI format** (most common in this environment):
```ini
[web_servers]
web01.example.com
web02.example.com

[db_servers]
db01.example.com

[production:children]
web_servers
db_servers

[production:vars]
env=prod
```

**Dynamic groups** from hostnames:

| Hostname prefix | Group | Environment |
|----------------|-------|-------------|
| `site-a-dev-*` | development | SIT |
| `site-a-sit-*` | sit | SIT |
| `site-a-uat-*` | uat | UAT |
| `site-a-mgmt-*` | management | PROD |
| `site-b-*` | site-b | varies |

## Common Modules Quick Reference

| Category | Module | Use for |
|----------|--------|---------|
| Package | `package`, `apt`, `yum` | Installing/removing software |
| Service | `systemd`, `service` | Managing services |
| File | `file`, `copy`, `template`, `synchronize` | File operations |
| User | `user`, `group` | User/group management |
| Command | `command`, `shell` | Running commands (last resort) |
| Fetch info | `setup`, `stat`, `slurp` | Gathering facts and data |
| Wait | `wait_for`, `pause` | Timing and readiness checks |

## Anti-Patterns

| Anti-pattern | Why | Do instead |
|-------------|-----|-----------|
| `shell: systemctl restart nginx` without `changed_when` | Always reports "changed" even when nothing happened | Use `systemd` module or add `changed_when` |
| Bare `shell`/`command` when a module exists | Loses idempotency, harder to audit | Use the native module (`file`, `copy`, `package`, etc.) |
| `ignore_errors: true` without documentation | Silently swallows failures | Add a comment explaining why, and handle the failure |
| Hardcoded hostnames in playbooks | Not portable, breaks across environments | Use inventory groups and variables |
| Running against `all` without `--limit` | Accidentally touches wrong hosts | Always specify target group or `--limit` |
| Decrypting vault files for editing | Risk of committing plaintext | Use `ansible-vault edit` instead |

## Integration

**Called by:**
- `srepowers:test-driven-operation` — for verification commands
- `srepowers:safety-validator` — before running playbooks with `--diff` against production

**Pairs with:**
- `srepowers:puppet-deploy` — when Ansible supplements Puppet for specific tasks
- `srepowers:pve-admin` — when managing Proxmox hosts via Ansible
- `srepowers:systematic-troubleshooting` — when diagnosing playbook failures

## SRE Principles

### Safety First
- Always run `--check --diff` before `--diff` (apply mode) — the dry-run is not optional
- Never run against production (`site-a-mgmt-*`, `site-b-mgmt-*`) without explicit user approval
- Use `--limit` to scope execution to intended hosts only

### Structured Output
- Parse play recap for `ok`, `changed`, `failed`, `unreachable` counts
- Present results as a table per host, not raw Ansible output

### Evidence-Driven
- Capture `--diff` output as evidence of what changed
- Compare dry-run vs actual run output when results are unexpected

### Audit-Ready
- Record playbook name, inventory, and `--extra-vars` for every execution
- Save play recap output for change records

### Communication
- Report host-level results, not aggregate — "3 hosts changed, 1 failed" is not enough
- Surface the failed host and task immediately, not buried in output
