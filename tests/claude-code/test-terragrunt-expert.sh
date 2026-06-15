#!/usr/bin/env bash
# Test: terragrunt-expert skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-domain/skills/terragrunt-expert/SKILL.md"

echo "=== Test: terragrunt-expert skill ==="

if ! rg -q "Terragrunt|terragrunt" "$SKILL"; then
  echo "[FAIL] Terragrunt references missing"
  exit 1
fi

if ! rg -q "DRY|dependency|run.all|state.backend" "$SKILL"; then
  echo "[FAIL] Terragrunt concepts (DRY, dependencies, state) missing"
  exit 1
fi

if ! rg -q "srepowers-domain:terragrunt-expert" "$REPO_ROOT/plugins/srepowers-domain/commands/terragrunt-expert.md"; then
  echo "[FAIL] command wrapper missing or references wrong skill"
  exit 1
fi

echo "[PASS] terragrunt-expert skill valid"
