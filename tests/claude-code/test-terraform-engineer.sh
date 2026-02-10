#!/usr/bin/env bash
# Test: terraform-engineer skill
# Verifies that the skill provides Terraform expertise and infrastructure-as-code guidance
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: terraform-engineer skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the terraform-engineer skill? Describe its purpose briefly." 30)

if assert_contains "$output" "terraform-engineer\|Terraform.*Engineer\|terraform.*engineer" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: State management
echo "Test 2: State management..."

output=$(run_claude "In the terraform-engineer skill, how does it guide users on Terraform state management?" 30)

if assert_contains "$output" "state\|backend\|remote.*state\|terraform.*state" "Understands state management"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Module patterns
echo "Test 3: Module patterns..."

output=$(run_claude "In the terraform-engineer skill, what module patterns does it recommend for reusable infrastructure?" 30)

if assert_contains "$output" "module\|[Rr]eusab\|input.*variable\|output" "Covers module patterns"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All terraform-engineer skill tests passed ==="
