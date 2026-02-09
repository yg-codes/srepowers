#!/usr/bin/env bash
# Test: verification-before-completion skill
# Verifies that the skill enforces evidence-before-claims discipline
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: verification-before-completion skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the verification-before-completion skill? Describe its core principle briefly." 30)

if assert_contains "$output" "verification-before-completion\|Verification Before Completion\|Verification before Completion" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "evidence\|Evidence" "Mentions evidence requirement"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Evidence/proof required before claims
echo "Test 2: Evidence before claims..."

output=$(run_claude "In the verification-before-completion skill, can you claim work is complete without running a verification command? What is the iron law?" 30)

if assert_contains "$output" "NO COMPLETION CLAIMS\|no.*claim\|cannot claim\|evidence before claim" "Evidence/proof required before claims"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Fresh verification commands required
echo "Test 3: Fresh verification commands..."

output=$(run_claude "In verification-before-completion, what does the Gate Function require you to do before making a status claim?" 30)

if assert_contains "$output" "RUN\|run.*command\|execute.*command\|fresh.*verification" "Fresh verification commands required"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 4: Prevents claiming done without evidence
echo "Test 4: Prevents claiming done without evidence..."

output=$(run_claude "In verification-before-completion, what are examples of red flags that should make you stop? List a few." 30)

if assert_contains "$output" "should\|probably\|seems\|satisfaction\|Done\|Perfect\|Great" "Prevents claiming done without evidence"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All verification-before-completion skill tests passed ==="
