#!/usr/bin/env bash
#
# Proxmox VE Cluster Health Check Script
# Description: Comprehensive system health check for PVE nodes and clusters
# Usage: bash check-pve-cluster.sh
#        ssh root@pve-host 'bash -s' < check-pve-cluster.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_header() {
	echo ""
	echo "========================================"
	echo "$1"
	echo "========================================"
	echo ""
}

print_section() {
	echo ""
	echo "--- $1 ---"
	echo ""
}

check_status() {
	if [ $1 -eq 0 ]; then
		echo -e "${GREEN}✓${NC} $2"
		return 0
	else
		echo -e "${RED}✗${NC} $2"
		return 1
	fi
}

warn_status() {
	echo -e "${YELLOW}⚠${NC} $1"
}

# Start of health check
print_header "Proxmox VE Cluster Health Check"
echo "Run date: $(date)"
echo "Run by: $(whoami)@$(hostname)"
echo ""

# System Information
print_section "System Information"

echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

# PVE Version
echo "PVE Version:"
pveversion -v 2>/dev/null | head -5 || echo "  pveversion command not available"
echo ""

# CPU Info
echo "CPU Info:"
lscpu | grep -E "Architecture|CPU|Core|Thread|Model name" | head -10
echo ""

# Memory Info
print_section "Memory Information"
free -h
echo ""

# Disk Usage
print_section "Disk Usage"
df -h | grep -E "Filesystem|/dev/|rpool|tank"
echo ""

# Service Status
print_section "PVE Service Status"

services="pve-cluster pvedaemon pveproxy pvestatd rsyslog"
services_failed=0

for service in $services; do
	if systemctl is-active --quiet $service; then
		check_status 0 "$service is running"
	else
		check_status 1 "$service is NOT running"
		services_failed=1
	fi
done

# Optional services (only check if installed)
echo ""
echo "Optional Services:"
for service in pve-firewall spiceproxy; do
	if systemctl list-unit-files "${service}.service" &>/dev/null; then
		if systemctl is-active --quiet "$service"; then
			check_status 0 "$service is running"
		else
			warn_status "$service is installed but not running"
		fi
	fi
done

# HA services (if cluster)
if systemctl list-units | grep -q pve-ha-crm; then
	echo ""
	echo "HA Services:"
	for service in pve-ha-crm pve-ha-lrm; do
		if systemctl is-active --quiet $service; then
			check_status 0 "$service is running"
		else
			check_status 1 "$service is NOT running"
			services_failed=1
		fi
	done
fi

# Network Configuration
print_section "Network Configuration"

echo "Network Interfaces:"
ip -br addr show
echo ""

echo "Routing Table:"
ip route show
echo ""

# Bond status (if configured)
for bond in /proc/net/bonding/*; do
	if [ -f "$bond" ]; then
		bond_name=$(basename "$bond")
		echo "Bond: $bond_name"
		cat "$bond" | grep -E "Bonding Mode|Currently Active Slave|MII Status"
		# Check for degraded bond (any slave with MII Status: down)
		slave_down=$(
			grep -c "MII Status: down" "$bond" 2>/dev/null
			true
		)
		if [ "$slave_down" -gt 0 ]; then
			warn_status "Bond $bond_name has $slave_down slave(s) DOWN"
		else
			check_status 0 "All slaves in $bond_name are UP"
		fi
		echo ""
	fi
done

# Bridge status
echo "Bridge Status:"
bridge link 2>/dev/null || echo "No bridges configured"
echo ""

# Storage Status
print_section "Storage Status"

echo "Proxmox Storage:"
pvesm status 2>/dev/null || warn_status "Could not get storage status"
echo ""

# ZFS status (if configured)
if command -v zpool &>/dev/null; then
	echo "ZFS Pools:"
	zpool list -o name,size,alloc,free,cap,health 2>/dev/null || warn_status "No ZFS pools configured"
	echo ""

	echo "ZFS Health:"
	zpool status -x 2>/dev/null || warn_status "Could not get ZFS health"
	echo ""
fi

# LVM status (if configured)
if command -v vgs &>/dev/null; then
	echo "LVM Volume Groups:"
	vgs 2>/dev/null || warn_status "No LVM configured"
	echo ""
fi

# Mount points
echo "Mount Points:"
df -h | grep -E "Filesystem|/rpool|/mnt/|tank"
echo ""

# VM/Container Inventory
print_section "VM and Container Inventory"

echo "Virtual Machines:"
qm list
echo ""

echo "Containers:"
pct list
echo ""

# Cluster Status (if cluster)
if command -v pvecm &>/dev/null; then
	print_section "Cluster Status"

	if pvecm status &>/dev/null; then
		echo "Cluster Information:"
		pvecm status
		echo ""

		echo "Cluster Nodes:"
		pvecm nodes
		echo ""

		# Check quorum
		quorum_info=$(pvecm status 2>/dev/null | grep "Quorate:" || echo "")
		if echo "$quorum_info" | grep -q "Quorate:.*Yes"; then
			check_status 0 "Cluster has quorum"
		else
			check_status 1 "Cluster does NOT have quorum"
		fi
	else
		echo "This node is not part of a cluster"
	fi
	echo ""
fi

# HA Resources (if configured)
if command -v ha-manager &>/dev/null; then
	ha_output=$(ha-manager status 2>/dev/null || echo "")
	if [ -n "$ha_output" ]; then
		print_section "HA Resources"
		ha-manager status
		echo ""
	fi
fi

# Cluster Join Readiness (if not in cluster)
if ! command -v pvecm &>/dev/null || ! pvecm status &>/dev/null; then
	print_section "Cluster Join Readiness Check"

	# Check for existing cluster config
	if [ -f /etc/pve/corosync.conf ]; then
		warn_status "Existing cluster configuration found at /etc/pve/corosync.conf"
		echo "Remove with: rm /etc/pve/corosync.conf"
	else
		check_status 0 "No existing cluster configuration"
	fi

	# Check hostname resolution
	if getent hosts "$(hostname)" &>/dev/null; then
		check_status 0 "Hostname resolves: $(hostname)"
	else
		check_status 1 "Hostname does not resolve: $(hostname)"
	fi

	# Check for existing VMs/CTs
	vm_count=$(qm list 2>/dev/null | tail -n +2 | wc -l)
	ct_count=$(pct list 2>/dev/null | tail -n +2 | wc -l)
	if [ $vm_count -eq 0 ] && [ $ct_count -eq 0 ]; then
		check_status 0 "No VMs or containers (ready for cluster join)"
	else
		warn_status "Found $vm_count VM(s) and $ct_count container(s)"
		echo "VMs and/or containers should not exist before joining a cluster"
	fi
	echo ""
fi

# Package Versions
print_section "Package Versions"

echo "Proxmox Packages:"
dpkg -l 2>/dev/null | grep -E "pve-|proxmox-" | awk '{printf "  %-40s %s\n", $2, $3}' || echo "  Could not query packages"
echo ""

echo "ZFS Packages:"
dpkg -l 2>/dev/null | grep -E "zfs" | awk '{printf "  %-40s %s\n", $2, $3}' || echo "  No ZFS packages found"
echo ""

# Replication Status
print_section "Replication Jobs"

if command -v pvesr &>/dev/null; then
	repl_output=$(pvesr status 2>/dev/null || echo "")
	if [ -n "$repl_output" ]; then
		echo "$repl_output"
		# Check for failed replication jobs
		repl_errors=$(echo "$repl_output" | grep -ci "error" || true)
		if [ "$repl_errors" -gt 0 ]; then
			warn_status "Replication job errors detected ($repl_errors)"
		else
			check_status 0 "All replication jobs OK"
		fi
	else
		echo "No replication jobs configured"
	fi
else
	echo "pvesr command not available"
fi
echo ""

# Recent System Logs
print_section "Recent System Logs (Errors and Warnings)"

echo "Recent journal errors (last 50):"
journalctl -p err -n 50 --no-pager
echo ""

echo "Recent dmesg errors (last 20):"
dmesg -T | tail -20
echo ""

# Recent PVE tasks
if [ -d /var/log/pve/tasks ]; then
	print_section "Recent PVE Tasks (Last 10)"
	ls -lt /var/log/pve/tasks/ | head -11 | tail -10
	echo ""
fi

# Summary
print_header "Health Check Summary"

# Count issues
total_issues=0

# Check service failures
if [ $services_failed -eq 1 ]; then
	warn_status "Some PVE services are not running"
	total_issues=$((total_issues + 1))
fi

# Check disk usage
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $disk_usage -gt 80 ]; then
	warn_status "Root filesystem usage is ${disk_usage}%"
	total_issues=$((total_issues + 1))
fi

# Check memory
mem_avail=$(free | awk 'NR==2{printf "%.0f", $7/$2 * 100.0}')
if [ $mem_avail -lt 10 ]; then
	warn_status "Available memory is ${mem_avail}%"
	total_issues=$((total_issues + 1))
fi

# Check ZFS health
if command -v zpool &>/dev/null; then
	zfs_health=$(zpool status -x 2>/dev/null)
	if ! echo "$zfs_health" | grep -q "all pools are healthy"; then
		warn_status "ZFS pool health issues detected"
		total_issues=$((total_issues + 1))
	fi
fi

# Check replication jobs
if command -v pvesr &>/dev/null; then
	repl_check=$(pvesr status 2>/dev/null | grep -ci "error" || true)
	if [ "$repl_check" -gt 0 ]; then
		warn_status "Replication job errors detected"
		total_issues=$((total_issues + 1))
	fi
fi

echo ""
if [ $total_issues -eq 0 ]; then
	echo -e "${GREEN}✓ System health check completed with no critical issues${NC}"
else
	echo -e "${YELLOW}⚠ System health check completed with $total_issues issue(s)${NC}"
fi
echo ""

# End of script
exit 0
