#!/usr/bin/env bash
# Test: environment-health-check skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/skills/environment-health-check/SKILL.md"

echo "=== Test: environment-health-check skill ==="

if rg -q "kubectl config current-context" "$SKILL"; then
  echo "[FAIL] environment-health-check still relies on current-context"
  exit 1
fi

if ! rg -q "kubectl --context <context> cluster-info|kubectl --kubeconfig=/path/to/config --context <context> get nodes" "$SKILL"; then
  echo "[FAIL] explicit context diagnostics missing"
  exit 1
fi

echo "[PASS] environment-health-check avoids current-context reliance"
