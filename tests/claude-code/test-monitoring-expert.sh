#!/usr/bin/env bash
# Test: monitoring-expert skill
# Verifies that the skill supports monitoring with observability pillars and alerting
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: monitoring-expert skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the monitoring-expert skill? Describe its purpose briefly." 30)

if assert_contains "$output" "monitoring-expert\|Monitoring.*Expert\|monitoring.*expert" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Observability pillars
echo "Test 2: Observability pillars..."

output=$(run_claude "In the monitoring-expert skill, what are the key pillars of observability?" 30)

if assert_contains "$output" "metric\|log\|trac\|observab" "Observability pillars referenced"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Alerting best practices
echo "Test 3: Alerting best practices..."

output=$(run_claude "In the monitoring-expert skill, what are the best practices for configuring alerts?" 30)

if assert_contains "$output" "alert\|threshold\|[Pp]rometheus\|Grafana" "Alerting best practices covered"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All monitoring-expert skill tests passed ==="
