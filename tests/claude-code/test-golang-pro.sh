#!/usr/bin/env bash
# Test: golang-pro skill
# Verifies that the skill supports Go development with concurrency and error handling patterns
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: golang-pro skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the golang-pro skill? Describe its purpose briefly." 30)

if assert_contains "$output" "golang-pro\|Golang.*Pro\|Go.*pro" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Go concurrency patterns
echo "Test 2: Go concurrency patterns..."

output=$(run_claude "In the golang-pro skill, what Go concurrency patterns does it cover?" 30)

if assert_contains "$output" "goroutine\|channel\|concurren\|sync" "Go concurrency patterns referenced"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Go error handling
echo "Test 3: Go error handling..."

output=$(run_claude "In the golang-pro skill, how does it approach Go error handling best practices?" 30)

if assert_contains "$output" "error.*handling\|errors\\.Is\|errors\\.As\|wrap" "Go error handling covered"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All golang-pro skill tests passed ==="
