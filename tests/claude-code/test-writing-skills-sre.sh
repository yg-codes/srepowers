#!/usr/bin/env bash
# Test: writing-skills-sre skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/skills/writing-skills-sre/SKILL.md"

echo "=== Test: writing-skills-sre skill ==="

if rg -q "REQUIRED BACKGROUND:.*superpowers:writing-skills" "$SKILL"; then
  echo "[FAIL] writing-skills-sre still requires superpowers:writing-skills"
  exit 1
fi

if ! rg -q "Core Methodology|RED|GREEN|VERIFY|REFACTOR" "$SKILL"; then
  echo "[FAIL] standalone methodology missing"
  exit 1
fi

if ! rg -q "Verification steps|Rollback documentation|Runtime portability" "$SKILL"; then
  echo "[FAIL] SRE-specific requirements missing"
  exit 1
fi

echo "[PASS] writing-skills-sre is standalone and keeps SRE requirements"
