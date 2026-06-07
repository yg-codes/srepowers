#!/usr/bin/env bash
# Test: incident-commander skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-core/skills/incident-commander/SKILL.md"

echo "=== Test: incident-commander skill ==="

if ! rg -q "Incident Commander|Operations Lead|Communications Lead|Scribe" "$SKILL"; then
  echo "[FAIL] ICS role structure missing"
  exit 1
fi

if ! rg -q "kubectl --context <context> get pods|kubectl --context <context> rollout history" "$SKILL"; then
  echo "[FAIL] incident-commander examples are not context-safe"
  exit 1
fi

echo "[PASS] incident-commander keeps ICS structure and context-safe examples"
