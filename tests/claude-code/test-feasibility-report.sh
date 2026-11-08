#!/usr/bin/env bash
# Test: feasibility-report skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-core/skills/feasibility-report/SKILL.md"

echo "=== Test: feasibility-report skill ==="

if ! rg -q "TELOS" "$SKILL"; then
  echo "[FAIL] TELOS assessment framework missing"
  exit 1
fi

for dim in "echnical" "conomic" "egal" "perational" "cheduling"; do
  if ! rg -q "$dim" "$SKILL"; then
    echo "[FAIL] TELOS dimension missing: $dim"
    exit 1
  fi
done

if ! rg -q "do-nothing|DO-NOTHING" "$SKILL"; then
  echo "[FAIL] do-nothing baseline option missing"
  exit 1
fi

if ! rg -q "rollback" "$SKILL" || ! rg -q "blast radius|Blast Radius" "$SKILL"; then
  echo "[FAIL] rollback/blast radius requirements missing"
  exit 1
fi

# All eight report families present
for fam in "[Cc]apacity expansion" "[Pp]latform/version upgrade" "[Mm]igration" "[Rr]esilience" "[Tt]ooling adoption" "[Dd]ecommissioning" "[Ss]ecurity/compliance" "[Cc]ost reduction"; do
  if ! rg -q "$fam" "$SKILL"; then
    echo "[FAIL] report family missing: $fam"
    exit 1
  fi
done

# Routing: must NOT claim sibling skills' surfaces
if ! rg -q "post-mortem-writer" "$SKILL" || ! rg -q "evidence-first-reporting" "$SKILL" || ! rg -q "change-management" "$SKILL"; then
  echo "[FAIL] sibling-skill routing (When NOT to Use) incomplete"
  exit 1
fi

if ! rg -q "srepowers-core:feasibility-report" "$REPO_ROOT/plugins/srepowers-core/commands/feasibility-report.md"; then
  echo "[FAIL] command wrapper missing or references wrong skill"
  exit 1
fi

echo "[PASS] feasibility-report skill valid"
