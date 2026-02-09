---
name: pve-admin
description: Use when managing Proxmox VE 8.x/9.x or Proxmox Backup Server 3.x - cluster management, VM/CT operations, ZFS storage, networking, HA, backup/restore, and health checks
---

# Proxmox VE Administration

## Overview

This skill provides comprehensive guidance for administering Proxmox Virtual Environment (PVE) hypervisors and Proxmox Backup Server (PBS). It covers cluster management, VM/container operations, storage configuration, network setup, high availability, backup strategies, and system health monitoring.

## Quick Reference

### Common Commands

| Task | Command |
|------|---------|
| List VMs | `qm list` |
| List Containers | `pct list` |
| VM Status | `qm status <vmid>` |
| Start VM | `qm start <vmid>` |
| Stop VM | `qm stop <vmid>` |
| Shutdown VM (graceful) | `qm shutdown <vmid>` |
| Container Status | `pct status <ctid>` |
| Start Container | `pct start <ctid>` |
| Stop Container | `pct stop <ctid>` |
| Cluster Status | `pvecm status` |
| Storage Status | `pvesm status` |
| ZFS Pool Status | `zpool status` |
| HA Status | `ha-manager status` |

### Service Management

```bash
# Core PVE services
systemctl status pve-cluster pvedaemon pveproxy pvestatd

# HA services (on cluster nodes)
systemctl status pve-ha-lrm pve-ha-crm

# Firewall service
systemctl status pve-firewall

# Restart all PVE services
systemctl restart pve-cluster pvedaemon pveproxy pvestatd
```

## Cluster Operations

### Cluster Join Procedure

To join a node to an existing cluster:

```bash
# On the new node (not yet in cluster)
pvecm add <existing-cluster-node-ip> --link0 <this-node-cluster-ip>

# Example (using RFC 5737 documentation IP range):
pvecm add 192.0.2.26 --link0 192.0.2.28
```

**Pre-requisites for cluster join:**
1. Fresh PVE installation (no existing VMs/CTs)
2. Unique hostname resolvable via DNS
3. Time synchronized (NTP)
4. Network connectivity to cluster nodes on port 22 (SSH) and 5405-5412 (Corosync)
5. Same PVE major version as existing cluster
6. No existing `/etc/pve/corosync.conf`

### Cluster Status Commands

```bash
# Full cluster status
pvecm status

# List cluster nodes
pvecm nodes

# Get cluster resources (JSON)
pvesh get /cluster/resources --output-format json-pretty

# Get cluster status (JSON)
pvesh get /cluster/status --output-format json-pretty
```

### Cluster Troubleshooting

```bash
# Check corosync ring status
corosync-quorumtool -s

# View corosync logs
journalctl -u corosync

# Check pmxcfs (cluster filesystem)
systemctl status pve-cluster
```

## VM Management

### VM Configuration

```bash
# View VM config
qm config <vmid>

# Set VM memory
qm set <vmid> --memory 4096

# Set VM CPU
qm set <vmid> --cores 4 --sockets 1

# Add disk
qm set <vmid> --scsi1 local-zfs:32

# Enable QEMU agent
qm set <vmid> --agent 1

# Set boot order
qm set <vmid> --boot order=scsi0
```

### VM Migration

```bash
# Online migration
qm migrate <vmid> <target-node> --online

# Offline migration
qm migrate <vmid> <target-node>

# With local disk (requires shared storage or local-to-local)
qm migrate <vmid> <target-node> --with-local-disks
```

### VM Snapshots

```bash
# Create snapshot
qm snapshot <vmid> <snapname> --description "Before upgrade"

# List snapshots
qm listsnapshot <vmid>

# Rollback to snapshot
qm rollback <vmid> <snapname>

# Delete snapshot
qm delsnapshot <vmid> <snapname>
```

## Container Management

### Container Configuration

```bash
# View container config
pct config <ctid>

# Set memory
pct set <ctid> --memory 2048

# Set CPU
pct set <ctid> --cores 2

# Add mount point
pct set <ctid> --mp0 local-zfs:8,mp=/data

# Set network
pct set <ctid> --net0 name=eth0,bridge=vmbr0,ip=dhcp
```

### Container Operations

```bash
# Enter container shell
pct enter <ctid>

# Execute command in container
pct exec <ctid> -- <command>

# Push file to container
pct push <ctid> <local-file> <container-path>

# Pull file from container
pct pull <ctid> <container-path> <local-file>
```

## Storage Management

### ZFS Operations

```bash
# Pool status
zpool status
zpool status <poolname>

# List datasets
zfs list

# Create dataset
zfs create <pool>/<dataset>

# Set ZFS properties
zfs set compression=lz4 <pool>/<dataset>
zfs set recordsize=128k <pool>/<dataset>

# Snapshot management
zfs snapshot <pool>/<dataset>@<snapname>
zfs list -t snapshot
zfs destroy <pool>/<dataset>@<snapname>

# ZFS scrub
zpool scrub <poolname>
zpool status <poolname>  # Check scrub progress
```

### Proxmox Storage Configuration

Storage configuration is in `/etc/pve/storage.cfg`:

```bash
# View storage status
pvesm status

# Add ZFS storage
pvesm add zfspool local-zfs --pool rpool/data

# Add directory storage
pvesm add dir backup --path /mnt/backup --content backup

# Add NFS storage
pvesm add nfs nfs-backup --server 10.0.0.1 --export /backup --content backup,images

# Enable/disable storage
pvesm set <storage> --disable 0
pvesm set <storage> --disable 1
```

## Network Configuration

### Bonding Configuration

Network configuration is in `/etc/network/interfaces`:

```
# Example active-backup bond for 10GbE
auto bond1
iface bond1 inet manual
    bond-slaves eno1 eno2
    bond-miimon 100
    bond-mode active-backup
    bond-primary eno1
    bond-primary_reselect failure

# Bridge on top of bond
auto vmbr1
iface vmbr1 inet manual
    bridge-ports bond1
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
```

### Network Diagnostics

```bash
# View bonding status
cat /proc/net/bonding/bond0
cat /proc/net/bonding/bond1

# Bridge status
bridge link
bridge fdb show

# Network interfaces
ip addr show
ip link show

# Apply network changes
ifreload -a
```

### Network Failover Testing

To test bond failover:
1. Identify active slave: `cat /proc/net/bonding/<bond>`
2. Disconnect primary link physically or via switch
3. Verify failover in `dmesg -T` and bond status
4. Reconnect and verify recovery

## High Availability

### HA Configuration

```bash
# HA status
ha-manager status

# Add VM to HA
ha-manager add vm:<vmid> --group <group> --state started

# Remove from HA
ha-manager remove vm:<vmid>

# Set HA state
ha-manager set vm:<vmid> --state started
ha-manager set vm:<vmid> --state stopped
ha-manager set vm:<vmid> --state disabled

# Migrate HA resource
ha-manager migrate vm:<vmid> <target-node>
```

### HA Groups

HA groups define which nodes can run HA resources:

```bash
# Create HA group
pvesh create /cluster/ha/groups --group production --nodes pve01,pve02

# With priority
pvesh create /cluster/ha/groups --group production --nodes pve01:2,pve02:1

# Restricted (only these nodes)
pvesh create /cluster/ha/groups --group production --nodes pve01,pve02 --restricted 1
```

## Backup and Restore

### Proxmox Backup Server Integration

```bash
# Add PBS storage
pvesm add pbs pbs-backup \
    --server pbs.example.com \
    --datastore datastore1 \
    --username backup@pbs \
    --password <password> \
    --fingerprint <fingerprint>

# Backup VM to PBS
vzdump <vmid> --storage pbs-backup --mode snapshot

# List backups on PBS
pvesm list pbs-backup
```

### vzdump Backup

```bash
# Snapshot backup
vzdump <vmid> --mode snapshot --storage backup

# Stop backup (consistent)
vzdump <vmid> --mode stop --storage backup

# Suspend backup
vzdump <vmid> --mode suspend --storage backup

# All VMs/CTs
vzdump --all --mode snapshot --storage backup

# With compression
vzdump <vmid> --mode snapshot --storage backup --compress zstd
```

### Restore Operations

```bash
# Restore VM
qmrestore <backup-file> <vmid>
qmrestore <backup-file> <vmid> --storage local-zfs

# Restore container
pct restore <ctid> <backup-file>
pct restore <ctid> <backup-file> --storage local-zfs

# Restore from PBS
qmrestore pbs-backup:backup/vm/<vmid>/<timestamp> <new-vmid>
```

## System Health Check

### Using the Check Script

This skill includes `scripts/check-pve-cluster.sh` for comprehensive system checks:

```bash
# Run locally
bash scripts/check-pve-cluster.sh

# Run remotely via SSH
ssh root@<pve-host> 'bash -s' < scripts/check-pve-cluster.sh | tee log-<host>-$(date +%Y%m%d-%H%M%S).log
```

The script collects:
- System information (hostname, kernel, uptime)
- Service status (PVE services, rsyslog)
- Network configuration (bonds, bridges, routes)
- Storage layout (ZFS, LVM, mounts)
- VM/Container inventory
- Cluster status
- Cluster join readiness checks
- Recent system logs

### Manual Health Checks

```bash
# System resources
free -h
df -h
uptime

# PVE services
systemctl status pve-cluster pvedaemon pveproxy

# Cluster quorum
pvecm status | grep -E "Quorum|Total|Expected"

# ZFS health
zpool status -v

# Recent errors
journalctl -p err -n 50 --no-pager
dmesg -T | tail -50
```

## Upgrade Procedures

### PVE Minor Upgrade

```bash
# Update package list
apt update

# Check for updates
apt list --upgradable

# Upgrade packages
apt dist-upgrade

# Reboot if kernel updated
reboot
```

### PVE Major Upgrade

1. Read release notes for target version
2. Backup all VMs/CTs and configurations
3. Check upgrade checklist in Proxmox documentation
4. Update apt sources for new version
5. Run upgrade commands
6. Verify all services after upgrade

```bash
# Example for 8.x to 9.x (always check official docs)
sed -i 's/bookworm/trixie/g' /etc/apt/sources.list
apt update
apt dist-upgrade
```

## Troubleshooting

### Common Issues

**Cluster not forming:**
- Check firewall rules (ports 22, 5405-5412)
- Verify time sync across nodes
- Check hostname resolution

**VM not starting:**
- Check storage availability: `pvesm status`
- Review VM logs: `journalctl -u qemu-server@<vmid>`
- Verify resources available: `free -h`, `df -h`

**HA not working:**
- Check quorum: `pvecm status`
- Verify HA services: `systemctl status pve-ha-lrm pve-ha-crm`
- Review HA logs: `journalctl -u pve-ha-lrm`

**Network issues:**
- Check bond status: `cat /proc/net/bonding/*`
- Verify bridge: `bridge link`
- Test connectivity: `ping`, `traceroute`

### Log Locations

| Log | Location/Command |
|-----|------------------|
| System journal | `journalctl` |
| PVE tasks | `/var/log/pve/tasks/` |
| Firewall | `/var/log/pve-firewall.log` |
| Corosync | `journalctl -u corosync` |
| QEMU | `journalctl -u qemu-server@<vmid>` |
| Container | `journalctl -u pve-container@<ctid>` |

## Resources

### Reference Documentation

This skill includes official Proxmox documentation in `references/`:

- `pve-admin-guide-84.pdf` - PVE 8.4 Administration Guide
- `pve-admin-guide-9.1.pdf` - PVE 9.1 Administration Guide
- `proxmox-backup-3-4.pdf` - Proxmox Backup Server 3.4 Guide

To search these documents:
```bash
# Search for specific topics
grep -i "cluster" references/*.pdf  # Won't work directly on PDF
# Use pdftotext or read the PDF files in context
```

### Scripts

- `scripts/check-pve-cluster.sh` - Comprehensive system health check script

### External Resources

- Proxmox VE Documentation: https://pve.proxmox.com/pve-docs/
- Proxmox Backup Server Documentation: https://pbs.proxmox.com/docs/
- Proxmox Forum: https://forum.proxmox.com/
