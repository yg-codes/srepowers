#!/usr/bin/env bash
# Test: observability-integration skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-core/skills/observability-integration/SKILL.md"

echo "=== Test: observability-integration skill ==="

if ! rg -q "Prometheus|Grafana|Datadog|CloudWatch" "$SKILL"; then
  echo "[FAIL] observability platform references missing"
  exit 1
fi

if ! rg -q "metric|alert" "$SKILL"; then
  echo "[FAIL] metrics/alerting content missing"
  exit 1
fi

if ! rg -q "srepowers:observability-integration" "$REPO_ROOT/plugins/srepowers-core/commands/observability-integration.md"; then
  echo "[FAIL] command wrapper missing or references wrong skill"
  exit 1
fi

echo "[PASS] observability-integration skill valid"
