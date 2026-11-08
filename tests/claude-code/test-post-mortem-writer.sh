#!/usr/bin/env bash
# Test: post-mortem-writer skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-core/skills/post-mortem-writer/SKILL.md"

echo "=== Test: post-mortem-writer skill ==="

if ! rg -q "blameless|blame" "$SKILL"; then
  echo "[FAIL] blameless post-mortem content missing"
  exit 1
fi

if ! rg -q "timeline|root.cause|action.item" "$SKILL"; then
  echo "[FAIL] post-mortem structure missing"
  exit 1
fi

if ! rg -q "srepowers-core:post-mortem-writer" "$REPO_ROOT/plugins/srepowers-core/commands/post-mortem-writer.md"; then
  echo "[FAIL] command wrapper missing or references wrong skill"
  exit 1
fi

echo "[PASS] post-mortem-writer skill valid"
