#!/usr/bin/env bash
# Test: network-engineer skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-domain/skills/network-engineer/SKILL.md"

echo "=== Test: network-engineer skill ==="

if ! rg -q "VPC|vpc" "$SKILL"; then
  echo "[FAIL] VPC content missing"
  exit 1
fi

if ! rg -q "DNS|load.balanc" "$SKILL"; then
  echo "[FAIL] DNS/load balancing content missing"
  exit 1
fi

if ! rg -q "srepowers:network-engineer" "$REPO_ROOT/plugins/srepowers-domain/commands/network-engineer.md"; then
  echo "[FAIL] command wrapper missing or references wrong skill"
  exit 1
fi

echo "[PASS] network-engineer skill valid"
