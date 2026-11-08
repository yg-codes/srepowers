#!/usr/bin/env bash
# Test: writing-skills-sre skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-core/skills/writing-skills-sre/SKILL.md"

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

if ! rg -q "bash scripts/.*\.sh" "$SKILL"; then
  echo "[FAIL] explicit Bash interpreter rule for bundled shell scripts missing"
  exit 1
fi

if ! rg -q "node scripts/.*\.js" "$SKILL"; then
  echo "[FAIL] explicit Node interpreter rule for bundled JavaScript missing"
  exit 1
fi

if ! rg -qi "packager.*executable|executable bits.*packager|strip.*executable" "$SKILL"; then
  echo "[FAIL] interpreter rule does not explain stripped executable bits"
  exit 1
fi

echo "[PASS] writing-skills-sre is standalone and keeps SRE and script-portability requirements"
