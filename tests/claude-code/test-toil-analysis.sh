#!/usr/bin/env bash
# Test: toil-analysis skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/skills/toil-analysis/SKILL.md"

echo "=== Test: toil-analysis skill ==="

if ! rg -q "toil|manual|repetitive|automat" "$SKILL"; then
  echo "[FAIL] toil identification content missing"
  exit 1
fi

if ! rg -q "measure|reduce|priorit" "$SKILL"; then
  echo "[FAIL] toil reduction strategy missing"
  exit 1
fi

if ! rg -q "srepowers:toil-analysis" "$REPO_ROOT/commands/toil-analysis.md"; then
  echo "[FAIL] command wrapper missing or references wrong skill"
  exit 1
fi

echo "[PASS] toil-analysis skill valid"
