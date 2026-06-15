#!/usr/bin/env bash
# Test: cost-optimizer skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-domain/skills/cost-optimizer/SKILL.md"

echo "=== Test: cost-optimizer skill ==="

if ! rg -q "right-sizing|right.size|reserved.instance|FinOps" "$SKILL"; then
  echo "[FAIL] cost optimization strategies missing"
  exit 1
fi

if ! rg -q "cost.allocation|cost.driver" "$SKILL"; then
  echo "[FAIL] cost allocation content missing"
  exit 1
fi

if ! rg -q "srepowers-domain:cost-optimizer" "$REPO_ROOT/plugins/srepowers-domain/commands/cost-optimizer.md"; then
  echo "[FAIL] command wrapper missing or references wrong skill"
  exit 1
fi

echo "[PASS] cost-optimizer skill valid"
