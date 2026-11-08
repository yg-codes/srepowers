#!/usr/bin/env bash
# Test: sre-engineer skill
# Verifies that the skill provides SRE practices including SLOs, SLIs, and error budgets
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: sre-engineer skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the sre-engineer skill? Describe its purpose briefly." 30)

if assert_contains "$output" "sre-engineer\|SRE.*Engineer\|SRE.*engineer" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: SLOs and SLIs
echo "Test 2: SLOs and SLIs..."

output=$(run_claude "In the sre-engineer skill, how does it guide users on defining SLOs and SLIs?" 30)

if assert_contains "$output" "SLO\|SLI\|service.*level\|availability" "Understands SLOs and SLIs"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Error budgets
echo "Test 3: Error budgets..."

output=$(run_claude "In the sre-engineer skill, what guidance does it provide on error budgets?" 30)

if assert_contains "$output" "error.*budget\|budget.*burn\|reliability.*target" "Covers error budgets"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All sre-engineer skill tests passed ==="
