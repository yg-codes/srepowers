#!/usr/bin/env bash
# Test: python-pro skill
# Verifies that the skill provides Python development expertise and best practices
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: python-pro skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the python-pro skill? Describe its purpose briefly." 30)

if assert_contains "$output" "python-pro\|Python.*Pro\|Python.*pro" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Type hints
echo "Test 2: Type hints..."

output=$(run_claude "In the python-pro skill, how does it guide users on using type hints in Python?" 30)

if assert_contains "$output" "type.*hint\|typing\|mypy\|annotation" "Understands Python type hints"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Async Python
echo "Test 3: Async Python..."

output=$(run_claude "In the python-pro skill, what guidance does it provide on async Python programming?" 30)

if assert_contains "$output" "async\|await\|asyncio\|coroutine" "Covers async Python"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All python-pro skill tests passed ==="
