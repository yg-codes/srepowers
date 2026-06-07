#!/usr/bin/env bash
# Test: pve-vlan-trunk-troubleshooting skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-infra/skills/pve-vlan-trunk-troubleshooting/SKILL.md"

echo "=== Test: pve-vlan-trunk-troubleshooting skill ==="

if ! rg -q "VLAN|vlan" "$SKILL"; then
  echo "[FAIL] VLAN content missing"
  exit 1
fi

if ! rg -q "bridge|trunk|tcpdump|Proxmox" "$SKILL"; then
  echo "[FAIL] PVE network troubleshooting content missing"
  exit 1
fi

if ! rg -q "srepowers:pve-vlan-trunk-troubleshooting" "$REPO_ROOT/plugins/srepowers-infra/commands/pve-vlan-trunk-troubleshooting.md"; then
  echo "[FAIL] command wrapper missing or references wrong skill"
  exit 1
fi

echo "[PASS] pve-vlan-trunk-troubleshooting skill valid"
