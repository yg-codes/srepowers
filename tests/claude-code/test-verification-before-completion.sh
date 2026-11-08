#!/usr/bin/env bash
# Test: verification-before-completion skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-core/skills/verification-before-completion/SKILL.md"

echo "=== Test: verification-before-completion skill ==="

if ! rg -q "NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE" "$SKILL"; then
  echo "[FAIL] iron law missing"
  exit 1
fi

if ! rg -q "kubectl --context <context> rollout status|kubectl --context <context> get cm" "$SKILL"; then
  echo "[FAIL] kubectl examples are not context-safe"
  exit 1
fi

if ! rg -qi "project.*(suite|validation command)|complete.*(suite|validation command)" "$SKILL"; then
  echo "[FAIL] full-project validation rule missing"
  exit 1
fi

if ! rg -qi "report every failure|every failure.*report|failure.*by name" "$SKILL"; then
  echo "[FAIL] observed failures may be omitted from the report"
  exit 1
fi

echo "[PASS] verification-before-completion preserves core rule, context safety, and full-project validation"
