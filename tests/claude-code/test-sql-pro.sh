#!/usr/bin/env bash
# Test: sql-pro skill
# Verifies that the skill provides SQL expertise and query optimization guidance
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: sql-pro skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the sql-pro skill? Describe its purpose briefly." 30)

if assert_contains "$output" "sql-pro\|SQL.*Pro\|SQL.*pro" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Window functions
echo "Test 2: Window functions..."

output=$(run_claude "In the sql-pro skill, how does it explain SQL window functions?" 30)

if assert_contains "$output" "window.*function\|ROW_NUMBER\|RANK\|PARTITION BY\|OVER" "Understands window functions"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Indexing strategies
echo "Test 3: Indexing strategies..."

output=$(run_claude "In the sql-pro skill, what indexing strategies does it recommend for query optimization?" 30)

if assert_contains "$output" "index\|B-tree\|composite.*index\|covering.*index\|query.*plan" "Covers indexing strategies"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All sql-pro skill tests passed ==="
