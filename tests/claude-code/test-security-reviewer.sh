#!/usr/bin/env bash
# Test: security-reviewer skill
# Verifies that the skill provides security review and analysis capabilities
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: security-reviewer skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the security-reviewer skill? Describe its purpose briefly." 30)

if assert_contains "$output" "security-reviewer\|Security.*Reviewer\|security.*review" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: SAST scanning
echo "Test 2: SAST scanning..."

output=$(run_claude "In the security-reviewer skill, how does it guide users through SAST scanning and static analysis?" 30)

if assert_contains "$output" "SAST\|static.*analysis\|code.*scan\|vulnerabilit" "Understands SAST scanning"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Infrastructure security
echo "Test 3: Infrastructure security..."

output=$(run_claude "In the security-reviewer skill, what guidance does it provide on infrastructure security?" 30)

if assert_contains "$output" "infrastructure.*security\|network.*security\|hardening\|compliance" "Covers infrastructure security"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All security-reviewer skill tests passed ==="
