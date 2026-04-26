#!/usr/bin/env bash
# Test: receiving-code-review-sre skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/skills/receiving-code-review-sre/SKILL.md"

echo "=== Test: receiving-code-review-sre skill ==="

if ! rg -q "code.review|review.feedback" "$SKILL"; then
  echo "[FAIL] code review reception content missing"
  exit 1
fi

if ! rg -q "verify|technical|rigor|blind" "$SKILL"; then
  echo "[FAIL] technical rigor guidance missing"
  exit 1
fi

if ! rg -q "srepowers:receiving-code-review-sre" "$REPO_ROOT/commands/receiving-code-review-sre.md"; then
  echo "[FAIL] command wrapper missing or references wrong skill"
  exit 1
fi

echo "[PASS] receiving-code-review-sre skill valid"
