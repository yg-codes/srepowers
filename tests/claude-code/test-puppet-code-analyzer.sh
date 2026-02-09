#!/usr/bin/env bash
# Test: puppet-code-analyzer skill
# Verifies that the skill covers Puppet code quality analysis
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: puppet-code-analyzer skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the puppet-code-analyzer skill? Describe what it does briefly." 30)

if assert_contains "$output" "puppet-code-analyzer\|Puppet.*Code.*Analyzer\|Puppet.*code.*analy" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Mentions puppet-lint
echo "Test 2: Mentions puppet-lint..."

output=$(run_claude "In the puppet-code-analyzer skill, what linting tool does it use for code quality checks?" 30)

if assert_contains "$output" "puppet-lint\|puppet_lint" "Mentions puppet-lint"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Covers dependency analysis
echo "Test 3: Dependency analysis..."

output=$(run_claude "In the puppet-code-analyzer skill, does it analyze dependencies? What does it detect about dependencies?" 30)

if assert_contains "$output" "dependency\|Dependency\|dependencies\|circular" "Covers dependency analysis"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All puppet-code-analyzer skill tests passed ==="
