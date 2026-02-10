#!/usr/bin/env bash
# Test: chaos-engineer skill
# Verifies that the skill supports chaos engineering experiments and game days
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: chaos-engineer skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the chaos-engineer skill? Describe its purpose briefly." 30)

if assert_contains "$output" "chaos-engineer\|Chaos.*Engineer\|chaos.*engineer" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Blast radius
echo "Test 2: Blast radius..."

output=$(run_claude "In the chaos-engineer skill, how does it handle blast radius when designing chaos experiments?" 30)

if assert_contains "$output" "blast radius\|Blast Radius\|scope.*failure" "Blast radius concept referenced"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Game days
echo "Test 3: Game days..."

output=$(run_claude "In the chaos-engineer skill, what is the role of game days in chaos engineering practice?" 30)

if assert_contains "$output" "[Gg]ame [Dd]ay\|game day\|tabletop" "Game days covered"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All chaos-engineer skill tests passed ==="
