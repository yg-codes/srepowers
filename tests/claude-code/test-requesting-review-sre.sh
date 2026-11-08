#!/usr/bin/env bash
# Test: requesting-review-sre reviewer contract invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TEMPLATE="$REPO_ROOT/plugins/srepowers-core/skills/requesting-review-sre/code-reviewer.md"

echo "=== Test: requesting-review-sre reviewer contract ==="

if ! rg -qi "reasonable (operator|user|person).*expect|expect.*reasonable (operator|user|person)" "$TEMPLATE"; then
  echo "[FAIL] reviewer does not treat reasonable expectations as requirements"
  exit 1
fi

if ! rg -q "Declined to judge" "$TEMPLATE"; then
  echo "[FAIL] reviewer can silently omit behavior it considers out of scope"
  exit 1
fi

if ! rg -qi "one line each|nothing.*dropped silently|empty list" "$TEMPLATE"; then
  echo "[FAIL] declined-judgment accounting is incomplete"
  exit 1
fi

echo "[PASS] reviewer evaluates reasonable expectations and accounts for every declined judgment"
