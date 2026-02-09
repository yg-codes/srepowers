#!/usr/bin/env bash
# Test: using-srepowers skill
# Verifies that the skill describes how to find and use SRE infrastructure skills
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: using-srepowers skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the using-srepowers skill? Describe what it does briefly." 30)

if assert_contains "$output" "using-srepowers\|Using.*SREPowers\|using.*srepowers" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Lists available skills
echo "Test 2: Lists available skills..."

output=$(run_claude "In the using-srepowers skill, what SRE infrastructure skills are listed? Name at least 3 specific skills." 30)

if assert_contains "$output" "test-driven-operation\|brainstorming-operations\|verification-before-completion\|subagent-driven-operation\|writing-operation-plans" "Lists available skills"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Mentions mandatory invocation
echo "Test 3: Mandatory invocation..."

output=$(run_claude "In the using-srepowers skill, is it optional to use a skill when it applies? What is the rule about invoking skills?" 30)

if assert_contains "$output" "MUST\|must\|mandatory\|not optional\|not negotiable\|required" "Mentions mandatory invocation"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All using-srepowers skill tests passed ==="
