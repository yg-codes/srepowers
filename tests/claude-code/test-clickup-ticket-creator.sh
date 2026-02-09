#!/usr/bin/env bash
# Test: clickup-ticket-creator skill
# Verifies that the skill creates ClickUp tickets with CCB template format
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: clickup-ticket-creator skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the clickup-ticket-creator skill? Describe what it does briefly." 30)

if assert_contains "$output" "clickup-ticket-creator\|ClickUp.*Ticket\|clickup.*ticket\|Clickup" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: CCB template sections included
echo "Test 2: CCB template sections..."

output=$(run_claude "In the clickup-ticket-creator skill, what is the CCB template? What does CCB stand for?" 30)

if assert_contains "$output" "CCB\|Change Control Board\|change control" "CCB template sections included"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Description/Rationale/Impact/Risk sections
echo "Test 3: Key ticket sections..."

output=$(run_claude "In the clickup-ticket-creator skill, list the main sections of the ticket template." 30)

if assert_contains "$output" "Description" "Description section covered"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Rationale" "Rationale section covered"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Impact" "Impact section covered"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Risk" "Risk section covered"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All clickup-ticket-creator skill tests passed ==="
