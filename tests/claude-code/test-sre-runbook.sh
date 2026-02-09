#!/usr/bin/env bash
# Test: sre-runbook skill
# Verifies that the skill creates structured SRE runbooks
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: sre-runbook skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the sre-runbook skill? Describe its purpose briefly." 30)

if assert_contains "$output" "sre-runbook\|SRE.*Runbook\|SRE.*runbook" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Command/Expected/Result format
echo "Test 2: Command/Expected/Result format..."

output=$(run_claude "In the sre-runbook skill, what three mandatory sections must every step include?" 30)

if assert_contains "$output" "Command.*Expected.*Result\|Command\|Expected\|Result" "Uses Command/Expected/Result format"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Verification and rollback sections
echo "Test 3: Verification and rollback sections..."

output=$(run_claude "In the sre-runbook skill, does it include verification steps and how are the steps organized into parts?" 30)

if assert_contains "$output" "Verification\|verification\|Pre-check\|Post-check" "Verification sections included"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All sre-runbook skill tests passed ==="
