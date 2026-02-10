#!/usr/bin/env bash
# Test: code-reviewer skill
# Verifies that the skill supports code review with checklists and PR review processes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: code-reviewer skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the code-reviewer skill? Describe its purpose briefly." 30)

if assert_contains "$output" "code-reviewer\|Code.*Reviewer\|code.*review" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Review checklist
echo "Test 2: Review checklist..."

output=$(run_claude "In the code-reviewer skill, what key areas should be checked during a code review?" 30)

if assert_contains "$output" "security\|performance\|readability\|maintainab" "Review checklist areas referenced"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: PR review process
echo "Test 3: PR review process..."

output=$(run_claude "In the code-reviewer skill, how does it structure the pull request review process?" 30)

if assert_contains "$output" "[Pp]ull [Rr]equest\|PR\|review.*process" "PR review process covered"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All code-reviewer skill tests passed ==="
