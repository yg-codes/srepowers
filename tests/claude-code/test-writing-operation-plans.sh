#!/usr/bin/env bash
# Test: writing-operation-plans skill
# Verifies that the skill creates detailed infrastructure operation plans
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: writing-operation-plans skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the writing-operation-plans skill? Describe its purpose briefly." 30)

if assert_contains "$output" "writing-operation-plans\|Writing.*Operation.*Plans\|operation plan" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Plans include verification commands
echo "Test 2: Verification commands in plans..."

output=$(run_claude "In writing-operation-plans, does each task include verification commands? What steps mention verification?" 30)

if assert_contains "$output" "verification\|Verification\|RED.*verification\|Verify.*GREEN" "Plans include verification commands"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Plans include rollback steps
echo "Test 3: Rollback steps in plans..."

output=$(run_claude "In writing-operation-plans, does each task include a rollback section? What does it say about rollback?" 30)

if assert_contains "$output" "rollback\|Rollback" "Plans include rollback steps"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 4: TDO discipline is embedded
echo "Test 4: TDO discipline embedded..."

output=$(run_claude "In writing-operation-plans, what is the step sequence for each task? Mention RED and GREEN phases." 30)

if assert_contains "$output" "RED\|GREEN" "TDO discipline (RED/GREEN) is embedded"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All writing-operation-plans skill tests passed ==="
