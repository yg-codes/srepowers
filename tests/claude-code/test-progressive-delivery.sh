#!/usr/bin/env bash
# Test: progressive-delivery skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-core/skills/progressive-delivery/SKILL.md"

echo "=== Test: progressive-delivery skill ==="

if ! rg -q "kubectl --context <context> argo rollouts set weight|kubectl --context <context> patch service api" "$SKILL"; then
  echo "[FAIL] progressive-delivery examples are not context-safe"
  exit 1
fi

if ! rg -q "canary|blue-green|shadow" "$SKILL"; then
  echo "[FAIL] expected delivery modes missing"
  exit 1
fi

echo "[PASS] progressive-delivery keeps delivery patterns and context-safe examples"
