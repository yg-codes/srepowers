#!/usr/bin/env bash
# Test: rust-engineer skill
# Verifies that the skill provides Rust development expertise and guidance
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: rust-engineer skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the rust-engineer skill? Describe its purpose briefly." 30)

if assert_contains "$output" "rust-engineer\|Rust.*Engineer\|rust.*engineer" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Ownership and borrowing
echo "Test 2: Ownership and borrowing..."

output=$(run_claude "In the rust-engineer skill, how does it explain Rust's ownership and borrowing system?" 30)

if assert_contains "$output" "ownership\|borrow\|lifetime\|move" "Understands ownership and borrowing"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Async Rust
echo "Test 3: Async Rust..."

output=$(run_claude "In the rust-engineer skill, what guidance does it provide on async Rust programming?" 30)

if assert_contains "$output" "tokio\|async\|future\|runtime" "Covers async Rust"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All rust-engineer skill tests passed ==="
