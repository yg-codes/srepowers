#!/usr/bin/env bash
# Test: devops-engineer skill
# Verifies that the skill supports DevOps engineering with CI/CD and containerization
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: devops-engineer skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the devops-engineer skill? Describe its purpose briefly." 30)

if assert_contains "$output" "devops-engineer\|DevOps.*Engineer\|devops.*engineer" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: CI/CD pipeline stages
echo "Test 2: CI/CD pipeline stages..."

output=$(run_claude "In the devops-engineer skill, what are the key stages of a CI/CD pipeline?" 30)

if assert_contains "$output" "CI/CD\|pipeline\|build.*test.*deploy\|continuous" "CI/CD pipeline stages referenced"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Containerization
echo "Test 3: Containerization..."

output=$(run_claude "In the devops-engineer skill, how does it approach containerization of applications?" 30)

if assert_contains "$output" "[Dd]ocker\|[Cc]ontainer\|Podman\|OCI" "Containerization covered"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All devops-engineer skill tests passed ==="
