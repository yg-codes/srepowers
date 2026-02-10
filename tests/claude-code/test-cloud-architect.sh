#!/usr/bin/env bash
# Test: cloud-architect skill
# Verifies that the skill supports cloud architecture with Well-Architected Framework and multi-cloud
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: cloud-architect skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the cloud-architect skill? Describe its purpose briefly." 30)

if assert_contains "$output" "cloud-architect\|Cloud.*Architect\|cloud.*architect" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Well-Architected Framework pillars
echo "Test 2: Well-Architected Framework pillars..."

output=$(run_claude "In the cloud-architect skill, how does it incorporate the Well-Architected Framework pillars?" 30)

if assert_contains "$output" "Well-Architected\|pillar\|cost\|reliability\|security" "Well-Architected Framework referenced"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Landing zones
echo "Test 3: Landing zones..."

output=$(run_claude "In the cloud-architect skill, how does it approach landing zones and account structure?" 30)

if assert_contains "$output" "landing zone\|Landing Zone\|account.*structure" "Landing zones covered"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All cloud-architect skill tests passed ==="
