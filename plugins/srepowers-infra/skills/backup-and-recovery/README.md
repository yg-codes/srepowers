# backup-and-recovery

Manage, verify, and restore backup infrastructure — ZFS snapshots and
send/recv replication, Proxmox Backup Server jobs, restore testing, retention
management, and disaster recovery runbooks. Enforced rule: unverified backups
are not backups. Ships as `srepowers-infra:backup-and-recovery`.
(`SKILL.md` is the agent-facing trigger doc; this file is for humans.)

## Use cases

- Verify backup health and completion status across ZFS and PBS jobs
- Create, replicate (`zfs send` / `zfs receive`), and prune snapshots on a
  retention schedule
- Run a file-level or application restore test — and schedule the next one
- Write a DR runbook (backup source, restore procedure, RTO/RPO, escalation),
  or troubleshoot a failed replication, a hung backup job, or filling storage

## How-to

In Claude Code or Codex, just ask — "backup verify", "test restore",
"ZFS snapshot", "zfs send", "backup failed", "DR runbook", "retention
policy" — the skill triggers automatically, or invoke it directly as the
`srepowers-infra:backup-and-recovery` command. Say which mode you want
(verify / restore / manage) so the right procedure runs.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — the three pillars; ZFS snapshot create/replicate/retain/verify
  procedures; PBS backup status and restore operations; restore-test drills
  (file-level, application, schedule); DR runbook template; symptom-based
  troubleshooting (replication failed / job hung / storage filling);
  anti-patterns

---
Last Updated: 2026-09-14
