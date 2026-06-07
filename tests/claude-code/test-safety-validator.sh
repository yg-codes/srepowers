#!/usr/bin/env bash
# Test: safety-validator skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-core/skills/safety-validator/SKILL.md"

echo "=== Test: safety-validator skill ==="

if ! rg -q "Critical Risk|High Risk|Medium Risk|Low Risk" "$SKILL"; then
  echo "[FAIL] risk classification structure missing"
  exit 1
fi

if ! rg -q "kubectl --context <context> delete deployment|kubectl --context <context> scale deployment" "$SKILL"; then
  echo "[FAIL] context-safe kubectl examples missing"
  exit 1
fi

echo "[PASS] safety-validator keeps risk model and context-safe examples"
