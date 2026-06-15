#!/usr/bin/env bash
# Test: platform-engineer skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-domain/skills/platform-engineer/SKILL.md"

echo "=== Test: platform-engineer skill ==="

if ! rg -q "IDP|developer.platform|Backstage|golden.path" "$SKILL"; then
  echo "[FAIL] platform engineering concepts missing"
  exit 1
fi

if ! rg -q "self.service|service.catalog" "$SKILL"; then
  echo "[FAIL] self-service infrastructure content missing"
  exit 1
fi

if ! rg -q "srepowers-domain:platform-engineer" "$REPO_ROOT/plugins/srepowers-domain/commands/platform-engineer.md"; then
  echo "[FAIL] command wrapper missing or references wrong skill"
  exit 1
fi

echo "[PASS] platform-engineer skill valid"
