#!/usr/bin/env bash
# Test: cache-cleanup skill
# Verifies that the skill provides interactive cache cleanup with verification
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: cache-cleanup skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the cache-cleanup skill? Describe what it does briefly." 30)

if assert_contains "$output" "cache-cleanup\|Cache.*Cleanup\|cache.*cleanup" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Pre-check mentioned
echo "Test 2: Pre-check phase..."

output=$(run_claude "In the cache-cleanup skill, what happens in Phase 1 before cleanup begins? What is it called?" 30)

if assert_contains "$output" "pre-check\|Pre-Check\|Pre-check\|analyze\|cache size" "Pre-check is mentioned"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Post-check verification mentioned
echo "Test 3: Post-check verification..."

output=$(run_claude "In the cache-cleanup skill, what happens after cleanup to ensure tools still work? What is Phase 3?" 30)

if assert_contains "$output" "post-check\|Post-Check\|Post-check\|verify.*tool\|tool.*still.*work\|functional" "Post-check verification is mentioned"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All cache-cleanup skill tests passed ==="
