#!/usr/bin/env bash
# Test: postgres-pro skill
# Verifies that the skill provides PostgreSQL expertise and guidance
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: postgres-pro skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the postgres-pro skill? Describe its purpose briefly." 30)

if assert_contains "$output" "postgres-pro\|Postgres.*Pro\|PostgreSQL" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: EXPLAIN ANALYZE knowledge
echo "Test 2: EXPLAIN ANALYZE knowledge..."

output=$(run_claude "In the postgres-pro skill, how does it guide users through EXPLAIN ANALYZE for query optimization?" 30)

if assert_contains "$output" "EXPLAIN\|ANALYZE\|query.*plan\|execution.*plan" "Understands EXPLAIN ANALYZE"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Replication types
echo "Test 3: Replication types..."

output=$(run_claude "In the postgres-pro skill, what types of PostgreSQL replication does it cover?" 30)

if assert_contains "$output" "streaming.*replication\|logical.*replication\|replica" "Covers replication types"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All postgres-pro skill tests passed ==="
