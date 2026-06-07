#!/usr/bin/env bash
# Test: playground-tutorial skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-core/skills/playground-tutorial/SKILL.md"

echo "=== Test: playground-tutorial skill ==="

if ! rg -q "first.time|learn|tutorial|onboarding" "$SKILL"; then
  echo "[FAIL] tutorial/onboarding content missing"
  exit 1
fi

if ! rg -q "safely|harmless|no.*risk|without.*risk" "$SKILL"; then
  echo "[FAIL] safety assurance for playground missing"
  exit 1
fi

if ! rg -q "srepowers:playground-tutorial" "$REPO_ROOT/plugins/srepowers-core/commands/playground-tutorial.md"; then
  echo "[FAIL] command wrapper missing or references wrong skill"
  exit 1
fi

echo "[PASS] playground-tutorial skill valid"
