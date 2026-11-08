# pve-admin

Administer Proxmox VE 8.x/9.x hypervisors and Proxmox Backup Server 3.x:
cluster management, VM and container operations, ZFS storage, networking,
high availability, backup/restore, health checks, upgrades. Bundles
official Proxmox PDF guides for offline use. Ships as
`srepowers-infra:pve-admin`. (`SKILL.md` is the agent-facing trigger doc;
this file is for humans.)

## Use cases

- Join or inspect a cluster (`pvecm status`, `pvesh get /cluster/resources
  --output-format json-pretty`)
- Manage VMs and containers: config, migrate, snapshot, start/stop
- Configure storage (ZFS pools, PVE storage), bonded networking, and HA
- Run health and capacity checks, plan minor/major upgrades, or work
  air-gapped via the upload-run-collect pattern

## How-to

In Claude Code or Codex, just ask — "check the PVE cluster", "migrate this
VM", "set up HA", "PVE upgrade" — or invoke it directly as the
`srepowers-infra:pve-admin` command. Prefer the bundled health-check scripts.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

Scripts:

| Script | Purpose |
|--------|---------|
| `scripts/check-pve-cluster.sh` | Comprehensive cluster health check |
| `scripts/check-pve-capacity.sh` | Capacity, allocation, and inventory reporting |
| `scripts/phase0-replication.sh` | ZFS replication job management |

References (official docs, readable offline during incidents):

- `references/pve-admin-guide.pdf` — PVE Administration Guide (not bundled in public editions; canonical URLs in SKILL.md)
- `references/proxmox-backup.pdf` / `references/proxmox-backup-3-4.pdf` — PBS guides (not bundled in public editions)
- `references/proxmox-datacenter-manager.pdf` — Datacenter Manager guide (not bundled in public editions)

- `SKILL.md` — command quick-reference tables; cluster/VM/CT/storage/network/
  HA/backup procedures; upgrades; troubleshooting and log locations

---
Last Updated: 2026-09-14
