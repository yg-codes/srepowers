#!/usr/bin/env bash
# Test: evidence-first-reporting skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/skills/evidence-first-reporting/SKILL.md"

echo "=== Test: evidence-first-reporting skill ==="

if ! rg -q "Observations first, inferences labeled, unknowns preserved" "$SKILL"; then
  echo "[FAIL] core principle missing"
  exit 1
fi

if ! rg -q "Observed:|Inference:|Unknowns:|Next Verification:|Risk / Blast Radius:" "$SKILL"; then
  echo "[FAIL] output contract missing"
  exit 1
fi

if ! rg -q "Present inference as fact|Claim root cause from one signal|exit code alone" "$SKILL"; then
  echo "[FAIL] anti-pattern rules missing"
  exit 1
fi

echo "[PASS] evidence-first-reporting keeps evidence/inference separation"
