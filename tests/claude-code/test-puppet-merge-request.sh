#!/usr/bin/env bash
# Test: puppet-merge-request skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-private/skills/puppet-merge-request/SKILL.md"

echo "=== Test: puppet-merge-request skill ==="

if ! rg -q "merge.request|MR" "$SKILL"; then
  echo "[FAIL] merge request guidance missing"
  exit 1
fi

if ! rg -q "sit.*uat.*prod|control.repo|glab" "$SKILL"; then
  echo "[FAIL] Puppet pipeline or glab references missing"
  exit 1
fi

if ! rg -q "srepowers-private:puppet-merge-request" "$REPO_ROOT/plugins/srepowers-private/commands/puppet-merge-request.md"; then
  echo "[FAIL] command wrapper missing or references wrong skill"
  exit 1
fi

echo "[PASS] puppet-merge-request skill valid"
