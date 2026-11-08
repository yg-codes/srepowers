#!/usr/bin/env bash
# Test: using-srepowers skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-core/skills/using-srepowers/SKILL.md"

echo "=== Test: using-srepowers skill ==="

if ! rg -q "MINIMUM SUFFICIENT workflow|minimum sufficient workflow" "$SKILL"; then
  echo "[FAIL] minimum sufficient workflow rule missing"
  exit 1
fi

if ! rg -q "Mandatory Gates|verification-before-completion|safety-validator|evidence-first-reporting" "$SKILL"; then
  echo "[FAIL] mandatory gate routing missing"
  exit 1
fi

if ! rg -q "Fast Path|low-risk|single-file/local-only|read-only" "$SKILL"; then
  echo "[FAIL] fast path rule missing"
  exit 1
fi

if ! rg -q "Active incident or unclear failure|systematic-troubleshooting.*first" "$SKILL"; then
  echo "[FAIL] incident routing missing"
  exit 1
fi

echo "[PASS] using-srepowers keeps routing, mandatory gates, and fast path rules"
