#!/usr/bin/env bash
# Test: dispatching-parallel-agents-sre skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-core/skills/dispatching-parallel-agents-sre/SKILL.md"

echo "=== Test: dispatching-parallel-agents-sre skill ==="

if ! rg -q "independent.*infrastructure|parallel.*agent|dispatch.*agent" "$SKILL"; then
  echo "[FAIL] parallel dispatch guidance missing"
  exit 1
fi

if ! rg -q "isolation|shared.state" "$SKILL"; then
  echo "[FAIL] isolation requirement missing"
  exit 1
fi

if ! rg -q "srepowers-core:dispatching-parallel-agents-sre" "$REPO_ROOT/plugins/srepowers-core/commands/dispatching-parallel-agents-sre.md"; then
  echo "[FAIL] command wrapper missing or references wrong skill"
  exit 1
fi

echo "[PASS] dispatching-parallel-agents-sre skill valid"
