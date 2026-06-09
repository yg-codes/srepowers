---
name: puppet-deploy
description: Use when deploying Puppet changes to infrastructure hosts — running noop or apply across single hosts or fleets, verifying environments on the puppet master, classifying results with the Puppet exit code decision rule, and collecting post-apply evidence. Also use for "deploy to fleet", "run noop on hosts", "apply puppet to UAT/SIT/PROD", "roll out to prod", "puppet apply", "ppr", "parallel-ssh puppet", or any Puppet agent execution on remote hosts.
---

# Puppet Fleet Deploy

Execute the mandatory Puppet deploy sequence: verify environment → Hiera validation → fleet noop → classify results → apply → post-check. Every deploy follows this exact order — noop before apply is not optional.

**Core principle:** Noop always, classify before proceeding, apply only with approval, verify with evidence.

**Announce at start:** "I'm using the puppet-deploy skill to execute the Puppet fleet deployment."

## The Mandatory Sequence

```
1. Verify environment on puppet master
2. Hiera spot-check (optional)
3. Fleet noop
4. Classify results (single decision rule)
5. Apply (requires user approval)
6. Post-apply verification
```

Skipping noop requires explicit user approval. This is non-negotiable unless the user demands it in the current turn.

## Prerequisites

- Target host(s) accessible via SSH
- Environment name derived from hostname (see Environment Reference below)
- `parallel-ssh` installed (for fleet operations)
- `sshpass` or SSH key access to target hosts
- Puppet master accessible at `fsx-mgmt-puppet01.fsx.zone`

Verify before starting:
```bash
which parallel-ssh     # Must be available for fleet deploys
which ppr              # Check on target host: ssh <host> "which ppr"
```

## Environment Reference

Derive the `--environment` value from the target host's hostname prefix. **Branch context overrides hostname suffix** — if validating an unmerged topic branch, use `<source>_<branch_name>` regardless of the host's environment.

| Host prefix | Environment prefix | Default suffix | Example |
|-------------|-------------------|----------------|---------|
| `fsx-*` | `infra_` | From hostname (see below) | `infra_sit`, `infra_uat`, `infra_prod` |
| `jax-*` | `jax_` | From hostname (see below) | `jax_sit`, `jax_uat`, `jax_prod` |
| `pve*` | `proxmox_` | `prod` | `proxmox_prod` |

**Hostname suffix → environment suffix:**

| Hostname pattern | Suffix | Full environment |
|-----------------|--------|-----------------|
| `fsx-dev-*`, `fsx-sit-*` | `sit` | `infra_sit` |
| `fsx-uat-*` | `uat` | `infra_uat` |
| `fsx-mgmt-*` (production) | `prod` | `infra_prod` |
| `jax-dev-*`, `jax-sit-*` | `sit` | `jax_sit` |
| `jax-uat-*` | `uat` | `jax_uat` |
| `jax-mgmt-*` (production) | `prod` | `jax_prod` |

**Unmerged branch override:** Validating branch `cu_infra_10689` on `fsx-uat-rsyslog01` → use `infra_cu_infra_10689` (branch wins over `infra_uat`).

---

## Step 1: Verify Environment on Puppet Master

Confirm the environment exists and g10k has deployed it before touching any agent.

```bash
ssh fsx-mgmt-puppet01.fsx.zone \
  "cat /etc/puppetlabs/code/environments/<env_name>/.g10k-deploy.json"
```

**If environment is missing or stale:**
```bash
ssh fsx-mgmt-puppet01.fsx.zone \
  "sudo -u puppet env https_proxy=http://proxy:3128 \
  /opt/puppetlabs/puppet/bin/g10k -config /etc/puppetlabs/g10k/g10k.yaml"
```

**Halt if the environment cannot be deployed.** Running puppet agent against a missing environment will fall back to `puppet.conf` defaults, which may apply the wrong configuration.

---

## Step 2: Hiera Validation (Optional)

Spot-check critical Hiera keys before running noop. This catches hierarchy misresolution before it surfaces as compilation errors.

```bash
ssh fsx-mgmt-puppet01.fsx.zone \
  "sudo puppet lookup --environment <env_name> --node <node_fqdn> <key>"
```

Ask the user which keys to verify. Common candidates:
- Profile class keys (ports, servers, features)
- Notification channels (google_chat webhook URLs)
- Package versions

Skip this step if the user confirms it's unnecessary.

---

## Step 3: Fleet Noop

Run puppet agent in noop mode across all target hosts. **ppr defaults to noop** — omit `--no-noop` for dry runs.

### Single Host

```bash
ssh <host>.fsx.zone 'sudo ppr --environment <env_name>' 2>&1 | tail -20
```

### Fleet (parallel-ssh)

```bash
parallel-ssh -h <hosts_file> -o /tmp/pssh-noop -e /tmp/pssh-noop \
  "sudo ppr --environment <env_name>"
```

Or with inline hosts:
```bash
parallel-ssh -H "host01.fsx.zone host02.fsx.zone" -i \
  "sudo ppr --environment <env_name>" 2>&1 | tail -40
```

**For large fleets**, save output for review:
```bash
parallel-ssh -h <hosts_file> -o /tmp/pssh-noop -e /tmp/pssh-noop \
  "sudo ppr --environment <env_name>"

# Review per-host results
for f in /tmp/pssh-noop/*.fsx.zone; do
  echo "=== $(basename $f) ==="
  tail -10 "$f"
done
```

---

## Step 4: Classify Results (The Single Decision Rule)

This is the most critical step. Puppet exit codes are misleading — `parallel-ssh` reports exit 2 as `[FAILURE]` even though it means "changes applied successfully." You must classify by inspecting the output, not the exit code.

### The Single Decision Rule

```
Real success = (exit ∈ {0, 2}) AND (no "^Error:" or "^Failed" lines in output)
Real failure = anything else
```

Apply this rule uniformly to single-host `ssh` runs and `parallel-ssh` aggregated output.

### Classification Script

For fleet noop results:
```bash
for f in /tmp/pssh-noop/*; do
  host=$(basename "$f")
  errs=$(grep -cE "^Error:|^Failed" "$f" 2>/dev/null || echo 0)
  changes=$(grep -E "changed=" "$f" | tail -1)
  applied=$(grep -E "Applied catalog in" "$f" | tail -1)
  if [ "$errs" -eq 0 ]; then
    status="OK"
  else
    status="FAILED"
  fi
  printf "%-40s errors=%-3s  %s  %s\n" "$host" "$errs" "$status" "$applied"
done
```

### What to Look For

| Output pattern | Classification | Action |
|---------------|----------------|--------|
| No changes, no errors | Clean noop | Proceed to apply |
| Changes previewed, no errors | Normal noop | Review changes, proceed to apply |
| `Error:` lines | Compilation error | **Halt.** Fix before proceeding |
| `Failed` lines | Resource failure | **Halt.** Investigate |
| Empty output | Connection issue | Check host accessibility |

**Do not proceed to apply if any host shows compilation errors.**

---

## Step 5: Apply (Requires User Approval)

Only after confirming noop results are acceptable across all hosts.

### Important: ppr Flag Semantics

`ppr` always prepends `--noop` to the command line. When you pass `--no-noop`, the actual command becomes:
```
puppet agent -t --noop --no-noop --environment <env_name>
```

Puppet honors the **last flag** for conflicting options, so `--no-noop` wins. This is by design — ppr's default-noop is a safety net.

**The leading `--noop` in ppr output is expected.** A log line showing `puppet agent -t --noop --no-noop ...` means a real apply ran, not a dry run.

### Single Host Apply

```bash
ssh <host>.fsx.zone 'sudo ppr --no-noop --environment <env_name>' 2>&1 | tail -20
```

### Fleet Apply

```bash
parallel-ssh -h <hosts_file> -o /tmp/pssh-apply -e /tmp/pssh-apply-err \
  "sudo ppr --no-noop --environment <env_name>"
```

**Expect `[FAILURE]` on hosts that applied changes.** Exit 2 = success with changes. Apply the single decision rule to the output, not the parallel-ssh summary.

### Fleet Classification After Apply

```bash
for f in /tmp/pssh-apply/*; do
  host=$(basename "$f")
  errs=$(grep -cE "^Error:|^Failed" "$f" 2>/dev/null || echo 0)
  applied=$(grep -E "Applied catalog in" "$f" | tail -1)
  printf "%-40s errors=%s  %s\n" "$host" "$errs" "$applied"
done
```

Real success = `errors=0` AND `Applied catalog in ...` present (even if parallel-ssh showed `[FAILURE]`).

### Rolling Apply (For Clustered Services)

When hosts must be updated one at a time:

```bash
hosts=(host01 host02 host03)
for host in "${hosts[@]}"; do
  fqdn="${host}.fsx.zone"
  echo "--- Applying on $fqdn ---"
  ssh "$fqdn" 'sudo ppr --no-noop --environment <env_name>' 2>&1 | tail -20 || true
  ssh "$fqdn" 'sudo pplog' 2>&1 | tail -10
  echo "--- Waiting 10s before next host ---"
  sleep 10
done
```

The `|| true` suppresses puppet exit-2 from breaking `set -e`. Inspect the `tail -20` output for `Error:` lines instead.

---

## Step 6: Post-Apply Verification

Collect evidence that the apply succeeded and the system is in the expected state.

### Collect pplog from All Hosts

```bash
parallel-ssh -h <hosts_file> -o /tmp/pssh-pplog "sudo pplog"

for f in /tmp/pssh-pplog/*; do
  echo "=== $(basename $f) ==="
  tail -10 "$f"
done
```

### Application-Specific Verification

Run verification commands tailored to what was changed. Examples:

```bash
# Verify a config file was rendered correctly
ssh <host> "cat /etc/app/config.yaml" | head -20

# Verify a cron job was installed
ssh <host> "crontab -l | grep <pattern>"

# Verify a service is running
ssh <host> "systemctl is-active <service>"

# Verify idempotency — noop after apply should show zero changes
ssh <host> 'sudo ppr --environment <env_name>' 2>&1 | grep -E "changed="
# Expected: changed=0
```

### Final Classification Report

Present a structured summary to the user:

```
Host                           Status    Errors  Catalog Time
fsx-sit-rsyslog01.fsx.zone     OK        0       12.4s
fsx-sit-rsyslog02.fsx.zone     OK        0       11.8s
fsx-uat-rsyslog01.fsx.zone     FAILED    2       8.2s

Action required: Investigate failures on fsx-uat-rsyslog01 before promoting to prod.
```

---

## Guardrails

- **Never** execute commands against PROD hosts (`fsx-mgmt-*`, `jax-mgmt-*`, `pve*` with `*_prod` environment) without the user's explicit demand in the current turn
- **Never** skip noop — dry run is mandatory before apply unless the user explicitly approves skipping in this turn
- **Never** apply to all hosts at once if the change affects clustered services — use Rolling Apply
- **Never** classify a run as success without applying the single decision rule. Exit 2 alone is not enough — exit 6 also signals failure
- **Never** use bare `puppet agent` — always use `ppr` which enforces environment prefix validation
- **Always** pass `--environment` (not `--env`) — puppet silently ignores unrecognized flags
- **Always** verify environment deployment on puppet master before running agent
- **Always** check for compilation errors in noop output before proceeding to apply
- **Always** review pplog after apply to confirm expected state

---

## Puppet Exit Code Reference

| Exit Code | Meaning | parallel-ssh Reports | Real Classification |
|-----------|---------|---------------------|-------------------|
| 0 | No changes, no failures | `[SUCCESS]` | Success — nothing to do |
| 2 | Changes applied, no failures | `[FAILURE]` | **Success** — changes applied correctly |
| 4 | No changes, failures occurred | `[FAILURE]` | Failure — investigate |
| 6 | Changes AND failures | `[FAILURE]` | **Failure** — partial apply, investigate immediately |

The discrepancy between exit code 2 (success) and parallel-ssh's `[FAILURE]` label is the most common source of misclassification. Always inspect output for `Error:` and `Failed:` lines.

---

## Integration

**Pairs with:**
- `srepowers:puppet-release` — the release skill promotes code through repos; this skill applies it
- `srepowers:puppet-merge-request` — creates the MRs that make code available for deployment
- `srepowers:test-driven-operation` — verification discipline for pre/post checks
- `srepowers:verification-before-completion` — final evidence check before claiming success
- `srepowers:dispatching-parallel-agents-sre` — lightweight parallel-ssh pattern for fleet operations
