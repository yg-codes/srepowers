#!/usr/bin/env bash
# Test: microservices-architect skill
# Verifies that the skill supports microservices architecture with service boundaries and saga patterns
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: microservices-architect skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the microservices-architect skill? Describe its purpose briefly." 30)

if assert_contains "$output" "microservices-architect\|Microservices.*Architect\|microservices.*architect" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Service boundaries
echo "Test 2: Service boundaries..."

output=$(run_claude "In the microservices-architect skill, how does it define service boundaries and domain-driven design?" 30)

if assert_contains "$output" "service.*boundar\|domain.*driven\|bounded context\|DDD" "Service boundaries referenced"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Saga pattern
echo "Test 3: Saga pattern..."

output=$(run_claude "In the microservices-architect skill, how does it handle distributed transactions using the saga pattern?" 30)

if assert_contains "$output" "[Ss]aga\|choreograph\|orchestrat\|distributed.*transaction" "Saga pattern covered"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All microservices-architect skill tests passed ==="
