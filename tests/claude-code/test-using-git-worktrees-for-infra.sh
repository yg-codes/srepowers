#!/usr/bin/env bash
# Test: using-git-worktrees-for-infra skill
# Verifies that the skill is loaded and follows correct workflow
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: using-git-worktrees-for-infra skill ==="
echo ""

# Test 1: Verify skill can be loaded
echo "Test 1: Skill loading..."

output=$(run_claude "What is the using-git-worktrees-for-infra skill? Describe its purpose briefly." 30)

if assert_contains "$output" "using-git-worktrees-for-infra\|git worktrees\|worktree" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "infrastructure\|isolation\|control repo" "Mentions infrastructure context"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Verify safety verification emphasis
echo "Test 2: Safety verification emphasis..."

output=$(run_claude "In using-git-worktrees-for-infra, what safety check must be done before creating a project-local worktree?" 30)

if assert_contains "$output" "ignored\|gitignore\|check-ignore" "Mentions gitignore verification"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "safety\|accidental commit\|deployment" "Explains safety rationale"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Verify environment detection
echo "Test 3: Environment detection..."

output=$(run_claude "In using-git-worktrees-for-infra, how is the target environment detected and why does it matter?" 30)

if assert_contains "$output" "branch\|sit\|uat\|prod" "Mentions environment detection"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "production\|warn\|confirm" "Mentions production warnings"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 4: Verify directory selection priority
echo "Test 4: Directory selection priority..."

output=$(run_claude "In using-git-worktrees-for-infra, what is the priority order for selecting a worktree directory?" 30)

if assert_contains "$output" "existing\|CLAUDE.md\|ask" "Mentions priority order"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" ".worktrees\|worktrees" "Mentions directory names"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 5: Verify SRE Principles section exists
echo "Test 5: SRE Principles integration..."

output=$(run_claude "What are the SRE Principles in the using-git-worktrees-for-infra skill? List them." 30)

if assert_contains "$output" "Safety First\|Structured Output\|Evidence-Driven\|Audit-Ready\|Communication" "Lists SRE Principles"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 6: Verify control repo detection
echo "Test 6: Control repo type detection..."

output=$(run_claude "In using-git-worktrees-for-infra, how is the control repo type detected? Give examples." 30)

if assert_contains "$output" "manifests\|terraform\|ansible\|k8s" "Mentions repo type indicators"; then
    : # pass
else
    exit 1
fi

echo ""

echo "========================================"
echo "All tests passed!"
echo "========================================"
