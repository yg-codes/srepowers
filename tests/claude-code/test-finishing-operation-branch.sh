#!/usr/bin/env bash
# Test: finishing-operation-branch skill
# Verifies that the skill is loaded and follows correct workflow
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: finishing-operation-branch skill ==="
echo ""

# Test 1: Verify skill can be loaded
echo "Test 1: Skill loading..."

output=$(run_claude "What is the finishing-operation-branch skill? Describe its purpose briefly." 30)

if assert_contains "$output" "finishing-operation-branch\|complete\|merge\|PR" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "infrastructure\|operation\|control repo" "Mentions infrastructure context"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Verify verification requirement
echo "Test 2: Infrastructure verification requirement..."

output=$(run_claude "In finishing-operation-branch, what must be done before presenting completion options?" 30)

if assert_contains "$output" "verify\|verification\|infrastructure state" "Mentions verification"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "kubectl\|terraform\|argocd" "Mentions infrastructure verification commands"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Verify completion options
echo "Test 3: Completion options..."

output=$(run_claude "In finishing-operation-branch, what are the 5 completion options? List them." 30)

if assert_contains "$output" "Merge\|MR\|promote\|keep\|discard" "Mentions all options"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "promote" "Mentions promotion option (infrastructure-specific)"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 4: Verify environment promotion
echo "Test 4: Environment promotion workflow..."

output=$(run_claude "In finishing-operation-branch, what is the environment promotion path and what are the requirements?" 30)

if assert_contains "$output" "sit\|uat\|prod" "Mentions environments"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "verified\|approval\|confirm" "Mentions verification requirements"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 5: Verify production safety
echo "Test 5: Production safety requirements..."

output=$(run_claude "In finishing-operation-branch, what special requirements exist for production deployments?" 30)

if assert_contains "$output" "explicit confirmation\|typed confirm\|deploy-to-production" "Mentions explicit confirmation"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "peer review\|emergency" "Mentions peer review or emergency context"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 6: Verify rollback documentation
echo "Test 6: Rollback documentation requirement..."

output=$(run_claude "In finishing-operation-branch, when is rollback documentation required and what should it include?" 30)

if assert_contains "$output" "rollback\|document" "Mentions rollback documentation"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "kubectl\|git revert\|undo" "Mentions rollback commands"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 7: Verify SRE Principles section exists
echo "Test 7: SRE Principles integration..."

output=$(run_claude "What are the SRE Principles in the finishing-operation-branch skill? List them." 30)

if assert_contains "$output" "Safety First\|Structured Output\|Evidence-Driven\|Audit-Ready\|Communication" "Lists SRE Principles"; then
    : # pass
else
    exit 1
fi

echo ""

echo "========================================"
echo "All tests passed!"
echo "========================================"
