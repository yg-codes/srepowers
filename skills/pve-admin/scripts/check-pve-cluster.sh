#!/bin/bash
# Common check script for Proxmox VE nodes
# Supports: pve-node01.example.com, pve-node02.example.com, pve-node03.example.com
# Usage: ssh <host> 'bash -s' < check-pve-cluster.sh | tee log-<host>-$(date +%Y%m%d-%H%M%S).log

echo "========================================"
echo "System Information"
echo "========================================"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "OS Version: $(cat /etc/os-release | grep PRETTY_NAME)"
echo "Uptime: $(uptime -p)"
echo "Current Date: $(date)"
echo "========================================"
echo ""

echo "========================================"
echo "All Running Services"
echo "========================================"
systemctl list-units --type=service --state=running
echo "========================================"
echo ""

echo "========================================"
echo "Proxmox Specific Services"
echo "========================================"
systemctl status pve-cluster pve-firewall pve-ha-lrm pve-ha-crm pvedaemon pveproxy pvestatd 2>&1
echo "========================================"
echo ""

echo "========================================"
echo "RSyslog Service Status"
echo "========================================"
systemctl status rsyslog --no-pager
echo ""

echo "RSyslog Version:"
rsyslogd -v
echo ""

echo "RSyslog Configuration Files:"
ls -lh /etc/rsyslog* 2>/dev/null
echo ""

echo "RSyslog Main Configuration (non-comment lines):"
cat /etc/rsyslog.conf 2>/dev/null | grep -v "^#" | grep -v "^$"
echo ""

echo "RSyslog Additional Configs:"
find /etc/rsyslog.d/ -type f -exec echo "=== {} ===" \; -exec cat {} \; 2>/dev/null
echo ""

echo "RSyslog Network Configuration (remote forwarding):"
grep -E "(@@|@\(|action\(|module\(load=\"om" /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null | grep -v "^#" || echo "No remote forwarding configured"
echo ""

echo "RSyslog Log Locations:"
grep -E "^\$File|^\$WorkDirectory|^\$IncludeConfig" /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null || echo "No special log locations defined"
echo ""

echo "Active RSyslog Connections:"
ss -tunlp | grep rsyslog || netstat -tunlp 2>/dev/null | grep rsyslog || echo "No active rsyslog connections found"
echo "========================================"
echo ""

echo "========================================"
echo "Splunk Container Status (Podman)"
echo "========================================"
sudo podman ps -a 2>/dev/null || echo "Podman not available or no sudo access"
echo ""

echo "Splunk Container Logs (last 20 lines):"
sudo podman logs --tail 20 splunk 2>/dev/null || sudo podman logs --tail 20 $(sudo podman ps -q --filter name=splunk) 2>/dev/null || echo "No splunk container found"
echo ""

echo "Podman System Info:"
sudo podman system info 2>/dev/null || echo "Podman info not available"
echo "========================================"
echo ""

echo "========================================"
echo "Proxmox Network Configuration"
echo "========================================"
echo "Network Interfaces:"
ip addr show
echo ""

echo "Network Configuration File:"
cat /etc/network/interfaces
echo ""

echo "Bonding Configuration:"
cat /proc/net/bonding/* 2>/dev/null || echo "No bonding interfaces found"
echo ""

echo "Bridge Status:"
bridge link
echo ""

echo "Network Routes:"
ip route show
echo ""

echo "Default Gateway:"
ip route | grep default
echo "========================================"
echo ""

echo "========================================"
echo "Proxmox Storage Layout"
echo "========================================"
echo "LVM Information:"
vgs 2>/dev/null || echo "No LVM configured"
pvs 2>/dev/null || echo "No PVs found"
lvs 2>/dev/null || echo "No LVs found"
echo ""

echo "Mount Points:"
findmnt
echo ""

echo "Disk Usage:"
df -h
echo ""

echo "Block Devices:"
lsblk
echo ""

echo "Proxmox Storage Configuration:"
cat /etc/pve/storage.cfg 2>/dev/null || echo "No storage.cfg found"
echo ""

echo "ZFS Status (if any):"
zpool status 2>/dev/null || echo "No ZFS pools found"
echo ""

echo "ZFS Datasets:"
zfs list 2>/dev/null || echo "No ZFS datasets found"
echo "========================================"
echo ""

echo "========================================"
echo "Proxmox Cluster Status"
echo "========================================"
echo "Cluster Membership:"
pvecm status 2>/dev/null || echo "Not part of a cluster or pvecm not available"
echo ""

echo "Cluster Nodes:"
pvesh get /cluster/status 2>/dev/null --output-format json-pretty 2>/dev/null || pvesh get /cluster/status 2>/dev/null || echo "Cannot get cluster status"
echo ""

echo "Cluster Resources:"
pvesh get /cluster/resources 2>/dev/null --output-format json-pretty 2>/dev/null | head -100 || pvesh get /cluster/resources 2>/dev/null | head -100
echo "========================================"
echo ""

echo "========================================"
echo "Proxmox VM/Container List"
echo "========================================"
echo "VMs on this node:"
qm list 2>/dev/null || echo "No VMs or qm not available"
echo ""

echo "Containers on this node:"
pct list 2>/dev/null || echo "No containers or pct not available"
echo ""

echo "VM Configurations:"
for vmid in $(qm list 2>/dev/null | awk 'NR>1 {print $1}'); do
    echo "=== VM $vmid ==="
    qm config $vmid 2>/dev/null
done
echo ""

echo "Container Configurations:"
for ctid in $(pct list 2>/dev/null | awk 'NR>1 {print $1}'); do
    echo "=== CT $ctid ==="
    pct config $ctid 2>/dev/null
done
echo "========================================"
echo ""

echo "========================================"
echo "Cluster VM Allocation (if clustered)"
echo "========================================"
pvesh get /cluster/resources --type vm 2>/dev/null || echo "Cannot get cluster VM allocation"
echo "========================================"
echo ""

echo "========================================"
echo "System Resources"
echo "========================================"
echo "CPU Info:"
lscpu
echo ""

echo "Memory Info:"
free -h
echo ""

echo "CPU Load:"
uptime
echo ""

echo "Top Processes (by CPU):"
ps aux --sort=-%cpu | head -10
echo ""

echo "Top Processes (by Memory):"
ps aux --sort=-%mem | head -10
echo "========================================"
echo ""

echo "========================================"
echo "Package Versions"
echo "========================================"
echo "Proxmox Packages:"
dpkg -l | grep -E "pve|proxmox" || rpm -qa | grep -E "pve|proxmox"
echo ""

echo "RSyslog Package:"
dpkg -l | grep rsyslog || rpm -qa | grep rsyslog
echo ""

echo "ZFS Packages:"
dpkg -l | grep zfs || rpm -qa | grep zfs
echo "========================================"
echo ""

echo "========================================"
echo "Cluster Join Readiness Check"
echo "========================================"
echo "Checking pre-requisites for cluster join:"
echo ""

echo "1. Corosync Configuration:"
ls -la /etc/pve/corosync.conf 2>/dev/null && echo "  [WARN] Already has corosync.conf - may already be in cluster" || echo "  [OK] No existing corosync.conf"
echo ""

echo "2. SSH Keys:"
ls -la /etc/pve/priv/ssh 2>/dev/null && echo "  [OK] SSH keys present" || echo "  [WARN] SSH keys not found"
echo ""

echo "3. Local Storage:"
pvesm status 2>/dev/null | grep local && echo "  [OK] Local storage configured" || echo "  [WARN] Local storage not found"
echo ""

echo "4. Network Configuration:"
cat /etc/network/interfaces | grep -E "vmbr|bond" && echo "  [OK] Network bridges/bonds configured" || echo "  [WARN] No bridges found"
echo ""

echo "5. Hostname:"
hostname -f && echo "  [OK] FQDN: $(hostname -f)" || echo "  [WARN] FQDN not set"
echo ""

echo "6. DNS Resolution:"
getent hosts $(hostname -f) >/dev/null 2>&1 && echo "  [OK] Hostname resolves" || echo "  [WARN] Hostname does not resolve in DNS"
echo ""

echo "7. Time Sync:"
timedatectl status 2>/dev/null || echo "  timedatectl not available"
echo "========================================"
echo ""

echo "========================================"
echo "Recent System Logs"
echo "========================================"
echo "Journal logs (last 50 lines):"
journalctl -n 50 --no-pager
echo ""

echo "PVE Task logs:"
tail -50 /var/log/pve/tasks/active 2>/dev/null || echo "No PVE task logs found"
echo "========================================"
echo ""

echo "========================================"
echo "Check Complete"
echo "========================================"
echo "End Time: $(date)"
echo "========================================"
