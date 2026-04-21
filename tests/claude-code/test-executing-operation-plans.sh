#!/usr/bin/env bash
# Test: executing-operation-plans skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/skills/executing-operation-plans/SKILL.md"

echo "=== Test: executing-operation-plans skill ==="

if rg -q "TodoWrite" "$SKILL"; then
  echo "[FAIL] executing-operation-plans still references TodoWrite"
  exit 1
fi

if ! rg -q "Record the execution state and proceed|Update execution state in plan file|resume state" "$SKILL"; then
  echo "[FAIL] execution-state tracking wording missing"
  exit 1
fi

if ! rg -q "kubectl --context <context>" "$SKILL"; then
  echo "[FAIL] expected --context normalization missing"
  exit 1
fi

echo "[PASS] executing-operation-plans is runtime-agnostic and context-safe"
