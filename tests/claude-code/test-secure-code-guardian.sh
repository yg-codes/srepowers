#!/usr/bin/env bash
# Test: secure-code-guardian skill
# Verifies that the skill provides secure coding practices and vulnerability guidance
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: secure-code-guardian skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the secure-code-guardian skill? Describe its purpose briefly." 30)

if assert_contains "$output" "secure-code-guardian\|Secure.*Code.*Guardian\|secure.*code" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: OWASP Top 10
echo "Test 2: OWASP Top 10..."

output=$(run_claude "In the secure-code-guardian skill, how does it address OWASP Top 10 vulnerabilities?" 30)

if assert_contains "$output" "OWASP\|injection\|XSS\|CSRF\|vulnerabilit" "Understands OWASP Top 10"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Authentication security
echo "Test 3: Authentication security..."

output=$(run_claude "In the secure-code-guardian skill, what guidance does it provide on authentication security?" 30)

if assert_contains "$output" "authenticat\|JWT\|OAuth\|token\|session" "Covers authentication security"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All secure-code-guardian skill tests passed ==="
