#!/usr/bin/env bash
# Test: test-driven-operation skill
# Verifies that the skill is loaded and follows correct workflow
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: test-driven-operation skill ==="
echo ""

# Test 1: Verify skill can be loaded
echo "Test 1: Skill loading..."

output=$(run_claude "What is the test-driven-operation skill? Describe its key steps briefly." 30)

if assert_contains "$output" "test-driven-operation\|Test-Driven Operation\|Test Driven Operation" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "RED\|GREEN\|REFACTOR" "Mentions TDO cycle"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Verify RED phase emphasis
echo "Test 2: RED phase emphasis..."

output=$(run_claude "In the test-driven-operation skill, what comes first: writing the verification or executing the operation?" 30)

if assert_contains "$output" "verification.*first\|write.*verification.*first\|RED.*first" "Verification first emphasized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Verify verification must fail first
echo "Test 3: Verification failure requirement..."

output=$(run_claude "In test-driven-operation, should you watch the verification command fail before executing the operation? Why or why not?" 30)

if assert_contains "$output" "watch.*fail\|must.*fail\|fail.*first" "Mentions watching verification fail"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "proves\|verifies\|correct" "Explains why failure is important"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 4: Verify GREEN phase comes after RED
echo "Test 4: Workflow order..."

output=$(run_claude "In test-driven-operation, what is the order of RED and GREEN phases? Be specific." 30)

if assert_order "$output" "RED" "GREEN" "RED before GREEN"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 5: Verify rollback requirement
echo "Test 5: Rollback requirement..."

output=$(run_claude "In test-driven-operation, what should you do if you execute an operation before writing the verification?" 30)

if assert_contains "$output" "rollback\|delete\|start over\|revert" "Mentions rollback"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 6: Verify infrastructure operations mentioned
echo "Test 6: Infrastructure operation examples..."

output=$(run_claude "What types of infrastructure operations does test-driven-operation apply to? List a few." 30)

if assert_contains "$output" "kubectl\|Kubernetes" "Mentions kubectl/Kubernetes"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "API\|curl" "Mentions API/curl"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 7: Verify rationalization prevention
echo "Test 7: Rationalization prevention..."

output=$(run_claude "Does test-driven-operation address common rationalizations? Give an example of one." 30)

if assert_contains "$output" "rationalization\|excuse\|reality" "Mentions rationalizations"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 8: Verify verification command examples
echo "Test 8: Verification command examples..."

output=$(run_claude "Give me an example verification command for checking if a Kubernetes pod is running." 30)

if assert_contains "$output" "kubectl get pod" "Shows kubectl get pod"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All test-driven-operation skill tests passed ==="
