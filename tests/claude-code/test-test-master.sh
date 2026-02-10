#!/usr/bin/env bash
# Test: test-master skill
# Verifies that the skill provides testing expertise and quality assurance guidance
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: test-master skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the test-master skill? Describe its purpose briefly." 30)

if assert_contains "$output" "test-master\|Test.*Master\|test.*master" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Test pyramid
echo "Test 2: Test pyramid..."

output=$(run_claude "In the test-master skill, how does it explain the test pyramid and different testing levels?" 30)

if assert_contains "$output" "test.*pyramid\|unit.*test\|integration.*test\|E2E" "Understands test pyramid"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Test coverage
echo "Test 3: Test coverage..."

output=$(run_claude "In the test-master skill, what guidance does it provide on test coverage and quality metrics?" 30)

if assert_contains "$output" "coverage\|code.*coverage\|branch.*coverage\|test.*qualit" "Covers test coverage"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All test-master skill tests passed ==="
