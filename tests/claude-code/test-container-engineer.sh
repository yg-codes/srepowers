#!/usr/bin/env bash
# Test: container-engineer skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-domain/skills/container-engineer/SKILL.md"

echo "=== Test: container-engineer skill ==="

if ! rg -q "multi-stage" "$SKILL"; then
  echo "[FAIL] multi-stage build guidance missing"
  exit 1
fi

if ! rg -q "security|hardening|distroless" "$SKILL"; then
  echo "[FAIL] container security content missing"
  exit 1
fi

if ! rg -q "srepowers-domain:container-engineer" "$REPO_ROOT/plugins/srepowers-domain/commands/container-engineer.md"; then
  echo "[FAIL] command wrapper missing or references wrong skill"
  exit 1
fi

echo "[PASS] container-engineer skill valid"
