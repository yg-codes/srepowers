#!/usr/bin/env bash
# Test: code-documenter skill
# Verifies that the skill supports code documentation with OpenAPI and docstrings
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: code-documenter skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the code-documenter skill? Describe its purpose briefly." 30)

if assert_contains "$output" "code-documenter\|Code.*Documenter\|code.*document" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: OpenAPI/Swagger
echo "Test 2: OpenAPI/Swagger..."

output=$(run_claude "In the code-documenter skill, how does it handle OpenAPI or Swagger documentation?" 30)

if assert_contains "$output" "OpenAPI\|Swagger\|API.*doc" "OpenAPI/Swagger referenced"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Docstring best practices
echo "Test 3: Docstring best practices..."

output=$(run_claude "In the code-documenter skill, what are the best practices for writing docstrings and code comments?" 30)

if assert_contains "$output" "docstring\|JSDoc\|comment\|documentation" "Docstring best practices covered"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All code-documenter skill tests passed ==="
