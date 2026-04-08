#!/usr/bin/env bash
# Test: postgresql-engineer-sql skill
# Verifies that the skill provides SQL expertise and query optimization guidance
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: postgresql-engineer-sql skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the postgresql-engineer-sql skill? Describe its purpose briefly." 30)

if assert_contains "$output" "postgrepostgresql-engineer-sql" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Window functions
echo "Test 2: Window functions..."

output=$(run_claude "In the postgresql-engineer-sql skill, how does it explain SQL window functions?" 30)

if assert_contains "$output" "window.*function\|ROW_NUMBER\|RANK\|PARTITION BY\|OVER" "Understands window functions"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Indexing strategies
echo "Test 3: Indexing strategies..."

output=$(run_claude "In the postgresql-engineer-sql skill, what indexing strategies does it recommend for query optimization?" 30)

if assert_contains "$output" "index\|B-tree\|composite.*index\|covering.*index\|query.*plan" "Covers indexing strategies"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All postgresql-engineer-sql skill tests passed ==="
