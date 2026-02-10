#!/usr/bin/env bash
# Test: prompt-engineer skill
# Verifies that the skill provides prompt engineering expertise and techniques
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: prompt-engineer skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the prompt-engineer skill? Describe its purpose briefly." 30)

if assert_contains "$output" "prompt-engineer\|Prompt.*Engineer\|prompt.*engineer" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Chain-of-thought prompting
echo "Test 2: Chain-of-thought prompting..."

output=$(run_claude "In the prompt-engineer skill, how does it describe chain-of-thought prompting techniques?" 30)

if assert_contains "$output" "chain.*of.*thought\|CoT\|step.*by.*step\|reasoning" "Understands chain-of-thought prompting"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Prompt evaluation
echo "Test 3: Prompt evaluation..."

output=$(run_claude "In the prompt-engineer skill, how does it approach evaluating and testing prompts?" 30)

if assert_contains "$output" "evaluat\|benchmark\|metric\|test.*prompt" "Covers prompt evaluation"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All prompt-engineer skill tests passed ==="
