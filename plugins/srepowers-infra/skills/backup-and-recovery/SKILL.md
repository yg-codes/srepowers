---
name: backup-and-recovery
description: Use when managing backup infrastructure — verifying backups, testing restores, managing ZFS snapshots and replication, setting up Proxmox Backup Server jobs, troubleshooting backup failures, or creating disaster recovery runbooks. Also use for "backup verify", "test restore", "ZFS snapshot", "zfs send", "zfs receive", "backup failed", "restore test", "DR runbook", "proxmox backup", "retention policy", or any backup/recovery operations and verification.
---

# Backup and Recovery

Manage, verify, and restore backup infrastructure. Covers ZFS snapshots, Proxmox Backup Server, restore testing, retention management, and disaster recovery documentation.

**Core principle:** Unverified backups are not backups. Regular restore testing is mandatory.

**Announce at start:** "I'm using the backup-and-recovery skill to [verify/restore/manage] backups."

## When to Use

**Use when:**
- Verifying backup health and completion status
- Testing restore procedures
- Managing ZFS snapshots and send/recv replication
- Configuring Proxmox Backup Server jobs
- Troubleshooting backup failures
- Setting or adjusting retention policies
- Creating disaster recovery runbooks
- Planning capacity for backup storage

**Exceptions:**
- Proxmox VM backup configuration — use `pve-admin` for VM-level backup setup
- Application-level data exports — handle in the application's own procedures

## The Three Pillars

```
1. Backup Execution — create snapshots, replicate off-site
2. Verification — confirm data integrity and accessibility
3. Restore Testing — prove recovery works under controlled conditions
```

All three must be operational. Backup without verification is guesswork. Backup without restore testing is hope.

## ZFS Snapshot Management

### Creating Snapshots

```bash
# Manual snapshot
zfs snapshot pool/data@manual-$(date +%Y%m%d-%H%M%S)

# Recursive snapshot of all datasets under pool/data
zfs snapshot -r pool/data@daily-$(date +%Y%m%d)

# List snapshots
zfs list -t snapshot -o name,creation,used,refer -s creation

# List snapshots for a specific dataset
zfs list -t snapshot -o name,creation,used pool/data
```

### Replication (Off-site)

```bash
# Initial replication (full send)
zfs send -R pool/data@initial | ssh backup-server 'zfs receive -F backup-pool/data'

# Incremental replication (send only changes)
zfs send -R -I @last-replicated pool/data@daily-20260609 | \
  ssh backup-server 'zfs receive backup-pool/data'

# Verify replication by comparing snapshot lists
zfs list -t snapshot -o name pool/data | tail -5
ssh backup-server 'zfs list -t snapshot -o name backup-pool/data | tail -5'
```

### Retention Management

```bash
# Destroy old snapshots manually
zfs destroy pool/data@daily-20260501

# Destroy all snapshots matching a pattern
zfs list -t snapshot -o name | grep 'pool/data@daily-202605' | xargs -n1 zfs destroy

# Set retention via zfs-backup-prune (if available)
# Typically configured via cron with retention rules:
# - Keep daily for 7 days
# - Keep weekly for 4 weeks
# - Keep monthly for 12 months
```

### Verifying ZFS Backups

```bash
# Check ZFS pool health
zpool status pool

# Check dataset properties
zfs get used,available,refer,mountpoint pool/data

# Verify a snapshot is readable
zfs diff pool/data@daily-20260609  # Show changes since snapshot

# Mount a snapshot for file-level verification
mkdir -p /mnt/snapshot-verify
mount -t zfs pool/data@daily-20260609 /mnt/snapshot-verify
ls -la /mnt/snapshot-verify/
umount /mnt/snapshot-verify
```

## Proxmox Backup Server

### Check Backup Status

```bash
# List recent backup tasks
proxmox-backup-client status --repository backup-server:datastore

# List all backups for a host
proxmox-backup-client snapshot list --repository backup-server:datastore

# Check backup server health
ssh backup-server 'proxmox-backup-manager status'
```

### Restore Operations

```bash
# List available snapshots for restore
proxmox-backup-client snapshot list --repository backup-server:datastore

# Restore a specific file from backup
proxmox-backup-client restore vm/100/2026-06-09T00:00:00 \
  etc/passwd \
  --repository backup-server:datastore \
  - > /tmp/restored-passwd

# Restore an entire VM (via Proxmox GUI or CLI)
qmrestore /mnt/pbs/vm-100-backup.vma.zst 100
```

## Restore Testing

### File-level Restore Test

```bash
# 1. Mount the backup snapshot
mkdir -p /mnt/restore-test
mount -t zfs pool/data@daily-20260609 /mnt/restore-test

# 2. Verify critical files exist and are non-empty
for file in /mnt/restore-test/path/to/critical/file.db; do
  if [ -s "$file" ]; then
    echo "OK: $file ($(stat -c%s "$file") bytes)"
  else
    echo "FAIL: $file missing or empty"
  fi
done

# 3. Verify file checksums match known-good values
md5sum /mnt/restore-test/path/to/critical/file.db

# 4. Clean up
umount /mnt/restore-test
rmdir /mnt/restore-test
```

### Application Restore Test

```bash
# 1. Restore to a temporary location
zfs send pool/data@test-restore | zfs recv pool/test-restore

# 2. Mount and start the application against test data
zfs set mountpoint=/mnt/test-restore pool/test-restore
# ... application-specific verification ...

# 3. Verify application functionality
# ... run health checks, query tests ...

# 4. Clean up
zfs destroy pool/test-restore
```

### Restore Test Schedule

| Frequency | Scope | Success criteria |
|-----------|-------|-----------------|
| Weekly | File-level spot check | Random sample of 10 files exist and match checksums |
| Monthly | Application-level restore | Restored data starts and passes health checks |
| Quarterly | Full DR simulation | Complete environment restored from backup within RTO |

## Disaster Recovery Runbooks

Every backup system must have a documented DR runbook covering:

```markdown
# DR Runbook: [System Name]

## RTO / RPO
- Recovery Time Objective: [target]
- Recovery Point Objective: [target]

## Backup Source
- What: [datasets/vms/files]
- Where: [primary storage → off-site replication target]
- Schedule: [frequency]
- Retention: [policy]

## Restore Procedure
1. Identify the backup snapshot to restore from
2. [Step-by-step restore commands]
3. [Verification steps]
4. [Service restart procedures]
5. [Post-restore health checks]

## Escalation
- If restore fails: [escalation path]
- If data is corrupted: [fallback procedure]
```

## Troubleshooting Backup Failures

### Symptom: Replication failed

```bash
# Check for common causes:

# 1. Target pool full
ssh backup-server 'zpool list'
ssh backup-server 'zfs list -o name,used,available'

# 2. Network connectivity
ssh backup-server 'echo "OK"' && echo "SSH OK"

# 3. Snapshot missing on source
zfs list -t snapshot pool/data | grep '@last-replicated'

# 4. Target snapshot conflict
ssh backup-server 'zfs list -t snapshot backup-pool/data'
```

### Symptom: Backup job hung

```bash
# Check for running backup processes
ps aux | grep -E 'zfs send|zfs receive|proxmox-backup'

# Check for held ZFS sends
zfs get holds pool/data@daily-20260609
```

### Symptom: Storage filling up

```bash
# Check space usage by dataset
zfs list -o name,used,usedbysnapshots,refer -s used

# Find largest snapshots
zfs list -t snapshot -o name,used -s used | head -20

# Check replication lag (snapshots on source but not on target)
diff <(zfs list -t snapshot -o name pool/data | tail -10) \
     <(ssh backup-server 'zfs list -t snapshot -o name backup-pool/data | tail -10')
```

## Anti-Patterns

| Anti-pattern | Why | Do instead |
|-------------|-----|-----------|
| Never testing restores | Backups silently degrade; first restore attempt fails under pressure | Schedule regular restore tests |
| Single backup target | Target failure means total data loss | Replicate to off-site location |
| Infinite retention | Storage fills up, new backups fail | Define and enforce retention policy |
| Ignoring backup alerts | Small failures compound into data loss | Investigate every backup failure |
| Manual snapshot creation only | Forgetting to snapshot means lost data | Automate via cron or systemd timer |
| Backing up without verification | Corrupted backups look identical to healthy ones | Verify checksums and file accessibility |

## Integration

**Called by:**
- `srepowers-infra:pve-admin` — for Proxmox VM/CT backup configuration
- `srepowers-core:systematic-troubleshooting` — for backup-related incidents
- `srepowers-core:sre-runbook` — for creating DR runbooks

**Pairs with:**
- `srepowers-core:safety-validator` — before destructive operations (zfs destroy, snapshot pruning)
- `srepowers-core:evidence-first-reporting` — when reporting backup health status

## SRE Principles

### Safety First
- Never destroy the only copy of a backup — verify replication before pruning
- Test restores on non-production systems first
- Keep rollback snapshots before any backup infrastructure changes

### Structured Output
- Report backup health as: system → last backup → status → size → next scheduled
- Use tables for fleet-wide backup status

### Evidence-Driven
- Capture restore test results with timestamps and checksums
- Show replication lag metrics: "source has snapshot X, target has snapshot Y"

### Audit-Ready
- Log every restore test: what, when, from which snapshot, result
- Maintain backup inventory: system → backup type → schedule → retention → off-site target

### Communication
- Report backup health proactively, not just when it fails
- Surface capacity trends: "backup storage at 78%, current growth rate projects full in 3 months"
