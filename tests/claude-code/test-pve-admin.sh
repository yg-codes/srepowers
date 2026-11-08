#!/usr/bin/env bash
# Test: pve-admin skill
# Verifies that the skill covers Proxmox VE administration
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: pve-admin skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the pve-admin skill? Describe what it covers briefly." 30)

if assert_contains "$output" "pve-admin\|PVE.*Admin\|pve.*admin\|Proxmox" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Mentions Proxmox VE
echo "Test 2: Mentions Proxmox VE..."

output=$(run_claude "What virtualization platform does the pve-admin skill provide guidance for?" 30)

if assert_contains "$output" "Proxmox.*VE\|Proxmox Virtual Environment\|PVE" "Mentions Proxmox VE"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Cluster management covered
echo "Test 3: Cluster management..."

output=$(run_claude "In the pve-admin skill, what cluster management commands or operations are covered? Mention specific commands." 30)

if assert_contains "$output" "pvecm\|cluster\|Cluster" "Cluster management is covered"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All pve-admin skill tests passed ==="
