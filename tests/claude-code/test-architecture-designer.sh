#!/usr/bin/env bash
# Test: architecture-designer skill
# Verifies that the skill supports architecture design with ADRs and design patterns
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: architecture-designer skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the architecture-designer skill? Describe its purpose briefly." 30)

if assert_contains "$output" "architecture-designer\|Architecture.*Designer\|architecture.*design" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: ADRs and design patterns
echo "Test 2: ADRs and design patterns..."

output=$(run_claude "In the architecture-designer skill, what role do Architecture Decision Records and design patterns play?" 30)

if assert_contains "$output" "ADR\|Architecture Decision Record\|design pattern" "ADRs and design patterns referenced"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Scalability planning
echo "Test 3: Scalability planning..."

output=$(run_claude "In the architecture-designer skill, how does it approach scalability planning for systems?" 30)

if assert_contains "$output" "scalab\|horizontal\|vertical" "Scalability planning covered"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All architecture-designer skill tests passed ==="
