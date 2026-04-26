#!/usr/bin/env bash
# Test: pcap-analysis skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/skills/pcap-analysis/SKILL.md"

echo "=== Test: pcap-analysis skill ==="

if ! rg -q "tshark" "$SKILL"; then
  echo "[FAIL] tshark reference missing"
  exit 1
fi

if ! rg -q "TSV|fields" "$SKILL"; then
  echo "[FAIL] TSV-first extraction guidance missing"
  exit 1
fi

if ! rg -q "srepowers:pcap-analysis" "$REPO_ROOT/commands/pcap-analysis.md"; then
  echo "[FAIL] command wrapper missing or references wrong skill"
  exit 1
fi

echo "[PASS] pcap-analysis skill valid"
