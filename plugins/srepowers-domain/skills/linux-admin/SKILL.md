---
name: linux-admin
description: Use when managing Linux server infrastructure — systemd service management, journal log analysis, LVM and disk management, package management with apt, kernel parameter tuning, cron job administration, user and group management, or general Linux system administration. Also use for "systemctl", "journalctl", "systemd", "LVM", "lvextend", "apt install", "sysctl", "cron", "useradd", "usermod", "disk full", "service won't start", "check logs", or any Linux server administration task that goes beyond basic file operations.
---

# Linux Administration

Manage Linux server infrastructure: services, storage, packages, users, scheduling, and kernel configuration. Provides structured approaches to common system administration tasks with verification at every step.

**Core principle:** Check current state, apply change, verify new state. Never assume — always confirm.

**Announce at start:** "I'm using the linux-admin skill to [manage/troubleshoot/configure] Linux system administration."

## When to Use

**Use when:**
- Managing systemd services (start, stop, enable, mask)
- Analyzing system logs with journalctl
- Managing disk and LVM storage
- Installing, updating, or removing packages
- Tuning kernel parameters with sysctl
- Managing cron jobs and timers
- Creating or modifying users and groups
- Debugging service startup failures
- Checking system resource utilization

**Exceptions:**
- Application-level configuration — use the relevant application skill
- Network configuration — use `network-engineer`
- Security hardening — use `security-reviewer`

## Service Management (systemd)

### Common Operations

```bash
# Service lifecycle
systemctl start <service>      # Start now
systemctl stop <service>       # Stop now
systemctl restart <service>    # Stop then start
systemctl reload <service>     # Reload config without restart (if supported)
systemctl status <service>     # Check status

# Boot behavior
systemctl enable <service>     # Start on boot
systemctl disable <service>    # Don't start on boot
systemctl is-enabled <service> # Check if enabled

# Masking (prevent accidental start)
systemctl mask <service>       # Prevent start entirely
systemctl unmask <service>     # Allow start again

# List services
systemctl list-units --type=service --state=running
systemctl list-units --type=service --state=failed
systemctl list-unit-files --type=service
```

### Debugging Service Failures

```bash
# Get detailed status including recent log lines
systemctl status <service> -l

# View full service logs
journalctl -u <service> --since "1 hour ago"

# View logs from a specific boot
journalctl -u <service> -b -1  # Previous boot

# Check service configuration
systemctl cat <service>

# Verify service file syntax (for custom units)
systemd-analyze verify /etc/systemd/system/<service>.service

# Check what a service depends on
systemctl list-dependencies <service>

# Check what failed at boot
systemctl --failed
```

### Custom systemd Service

```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Application
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=myapp
Group=myapp
ExecStart=/usr/local/bin/myapp --config /etc/myapp/config.yaml
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/myapp /var/log/myapp

[Install]
WantedBy=multi-user.target
```

```bash
# After creating/editing a service file
sudo systemctl daemon-reload
sudo systemctl enable myapp.service
sudo systemctl start myapp.service
sudo systemctl status myapp.service
```

## Log Analysis (journalctl)

```bash
# Time-based filtering
journalctl --since "2026-06-09 10:00" --until "2026-06-09 11:00"
journalctl --since "1 hour ago"
journalctl --since yesterday

# Service-specific
journalctl -u nginx
journalctl -u sshd -f  # Follow (tail)

# Priority filtering
journalctl -p err        # Errors and above
journalctl -p warning    # Warnings and above
journalctl -p emerg..err # Emergencies through errors

# Boot-based
journalctl -b            # Current boot
journalctl -b -1         # Previous boot
journalctl --list-boots  # List available boots

# Output formatting
journalctl -o json-pretty    # JSON output
journalctl -o cat            # Just the message
journalctl --no-pager        # No pager

# Disk usage
journalctl --disk-usage
sudo journalctl --vacuum-time=7d    # Keep last 7 days
sudo journalctl --vacuum-size=500M  # Limit to 500MB
```

## Storage Management (LVM)

### Checking Storage

```bash
# Physical volumes
pvs
pvdisplay

# Volume groups
vgs
vgdisplay

# Logical volumes
lvs
lvdisplay

# Filesystem usage
df -hT

# Block devices
lsblk
```

### Extending a Filesystem

```bash
# 1. Check available space in the volume group
vgs

# 2. Extend the logical volume (e.g., add 10GB)
lvextend -L +10G /dev/vg0/data

# 3. Resize the filesystem
# For ext4:
resize2fs /dev/vg0/data
# For xfs:
xfs_growfs /dev/vg0/data   # or mount point

# 4. Verify
df -h /dev/vg0/data
```

### Creating a New Logical Volume

```bash
# 1. Create the LV (e.g., 20GB)
lvcreate -L 20G -n newlv vg0

# 2. Create a filesystem
mkfs.ext4 /dev/vg0/newlv
# or
mkfs.xfs /dev/vg0/newlv

# 3. Mount it
mkdir -p /mnt/newlv
mount /dev/vg0/newlv /mnt/newlv

# 4. Add to fstab for persistence
echo '/dev/vg0/newlv /mnt/newlv ext4 defaults 0 2' >> /etc/fstab
mount -a  # Verify fstab is correct (no errors)
```

## Package Management (APT)

```bash
# Update package index
sudo apt update

# Upgrade installed packages
sudo apt upgrade
sudo apt full-upgrade   # Handle dependency changes

# Install/remove packages
sudo apt install <package>
sudo apt remove <package>      # Remove package, keep config
sudo apt purge <package>       # Remove package and config
sudo apt autoremove             # Remove unused dependencies

# Search and query
apt search <keyword>
apt show <package>
apt list --installed
apt list --upgradable

# Hold packages (prevent upgrade)
sudo apt-mark hold <package>
sudo apt-mark unhold <package>
apt-mark showhold

# Check which package owns a file
dpkg -S /path/to/file
dpkg -l | grep <package>
```

## Kernel Parameters (sysctl)

```bash
# View all parameters
sysctl -a

# View specific parameter
sysctl net.ipv4.ip_forward

# Set temporarily (lost on reboot)
sudo sysctl -w net.ipv4.ip_forward=1

# Set permanently
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-custom.conf
sudo sysctl -p /etc/sysctl.d/99-custom.conf

# Common parameters for servers:
# net.core.somaxconn = 65535         # TCP connection queue
# net.ipv4.tcp_max_syn_backlog = 65535
# vm.swappiness = 10                  # Reduce swap preference
# fs.file-max = 65536                 # Max open files
# net.ipv4.ip_forward = 1             # Enable IP forwarding (router/proxy)
```

## User and Group Management

```bash
# Create user
sudo useradd -m -s /bin/bash -G docker,sudo newuser

# Modify user
sudo usermod -aG additional_group username   # Add to group
sudo usermod -s /bin/zsh username             # Change shell
sudo usermod -L username                       # Lock account
sudo usermod -U username                       # Unlock account

# Delete user
sudo userdel username          # Remove user, keep home dir
sudo userdel -r username       # Remove user and home dir

# Groups
groupadd newgroup
groupdel groupname
groups username                 # Show user's groups
id username                     # Show UID, GID, groups

# Password management
sudo passwd username            # Set password
sudo chage -l username          # Show password policy
sudo chage -M 90 username       # Set max password age to 90 days
```

## Cron and Systemd Timers

### Cron Jobs

```bash
# Edit crontab
crontab -e              # Current user
sudo crontab -e         # Root

# List cron jobs
crontab -l
sudo crontab -l

# System-wide cron directories
ls /etc/cron.d/         # Drop-in cron files
ls /etc/cron.daily/     # Daily jobs
ls /etc/cron.hourly/    # Hourly jobs
```

### Cron Format

```
┌──────── minute (0–59)
│ ┌────── hour (0–23)
│ │ ┌──── day of month (1–31)
│ │ │ ┌── month (1–12)
│ │ │ │ ┌ day of week (0–7, 0 and 7 are Sunday)
│ │ │ │ │
* * * * * command
```

### Systemd Timers (preferred over cron)

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Run backup daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=Backup job

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now backup.timer
systemctl list-timers
```

## Anti-Patterns

| Anti-pattern | Why | Do instead |
|-------------|-----|-----------|
| `systemctl restart` without checking status first | May mask an already-failed service | Check `status` first, understand why it's in its current state |
| `chmod 777` to "fix" permissions | Security risk, lazy fix | Set minimal required permissions |
| Editing files in `/etc/` without backup | No rollback if config breaks | `cp file file.bak` first |
| `apt full-upgrade` without checking what changes | Unexpected removals or conflicts | Run `apt upgrade --dry-run` first |
| Using `cron` when `systemd timers` are available | Cron has no logging, no dependencies, no retry | Use systemd timers for new jobs |
| `kill -9` as first response | Data corruption risk | Try `kill` (SIGTERM) first, wait, then `kill -9` as last resort |

## Integration

**Called by:**
- `srepowers:systematic-troubleshooting` — for service and system debugging
- `srepowers:puppet-deploy` — when managing services via Puppet
- `srepowers:test-driven-operation` — for verification commands

**Pairs with:**
- `srepowers:observability-engineer` — for monitoring and alerting on system metrics
- `srepowers:security-reviewer` — for hardening systemd services

## SRE Principles

### Safety First
- Always check current state before making changes
- Keep backups of configuration files before editing
- Use `--dry-run` or `--simulate` when available

### Structured Output
- Report: service name, before-state, action, after-state
- Use tables for multi-service or multi-host operations

### Evidence-Driven
- Capture `systemctl status` output before and after changes
- Show `journalctl` evidence when debugging failures

### Audit-Ready
- Log every system change: what, when, why, who
- Include verification output in change records

### Communication
- Report service health as status, not exit codes: "running since 2h ago" vs "exit 0"
- Surface resource constraints: "disk at 92%, service may fail soon"
