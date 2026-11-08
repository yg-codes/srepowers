#!/usr/bin/env bash
# Test: gitlab-ecr-pipeline skill
# Verifies that the skill covers GitLab CI/CD to AWS ECR pipelines
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: gitlab-ecr-pipeline skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the gitlab-ecr-pipeline skill? Describe what it does briefly." 30)

if assert_contains "$output" "gitlab-ecr-pipeline\|GitLab.*ECR\|gitlab.*ecr" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: ECR authentication covered
echo "Test 2: ECR authentication..."

output=$(run_claude "In the gitlab-ecr-pipeline skill, how does the pipeline authenticate with AWS ECR? Mention the login method." 30)

if assert_contains "$output" "aws ecr get-login-password\|ECR.*login\|ecr.*auth\|AWS.*credential\|ECR_AWS" "ECR authentication is covered"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Supports both build and mirror patterns
echo "Test 3: Build and mirror patterns..."

output=$(run_claude "In the gitlab-ecr-pipeline skill, what two workflow patterns are supported? Name them." 30)

if assert_contains "$output" "Build.*Push\|build.*push" "Build pattern supported"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Mirror.*Push\|mirror.*push\|mirror" "Mirror pattern supported"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All gitlab-ecr-pipeline skill tests passed ==="
