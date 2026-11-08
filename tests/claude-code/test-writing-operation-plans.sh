#!/usr/bin/env bash
# Test: writing-operation-plans skill
# Verifies that the skill creates detailed infrastructure operation plans
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-core/skills/writing-operation-plans/SKILL.md"
CHECKER="$REPO_ROOT/plugins/srepowers-core/skills/writing-operation-plans/plan-checker-prompt.md"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: writing-operation-plans skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the writing-operation-plans skill? Describe its purpose briefly." 30)

if assert_contains "$output" "writing-operation-plans\|Writing.*Operation.*Plans\|operation plan" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Plans include verification commands
echo "Test 2: Verification commands in plans..."

output=$(run_claude "In writing-operation-plans, does each task include verification commands? What steps mention verification?" 30)

if assert_contains "$output" "verification\|Verification\|RED.*verification\|Verify.*GREEN" "Plans include verification commands"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Plans include rollback steps
echo "Test 3: Rollback steps in plans..."

output=$(run_claude "In writing-operation-plans, does each task include a rollback section? What does it say about rollback?" 30)

if assert_contains "$output" "rollback\|Rollback" "Plans include rollback steps"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 4: TDO discipline is embedded
echo "Test 4: TDO discipline embedded..."

output=$(run_claude "In writing-operation-plans, what is the step sequence for each task? Mention RED and GREEN phases." 30)

if assert_contains "$output" "RED\|GREEN" "TDO discipline (RED/GREEN) is embedded"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 5: Global Constraints and Interfaces blocks
echo "Test 5: Global Constraints and Interfaces..."

output=$(run_claude "In writing-operation-plans, does the plan format include a Global Constraints block and per-task Interfaces (Consumes/Produces)? Why do they matter for subagent execution?" 30)

if assert_contains "$output" "Global Constraints\|global constraint" "Mentions Global Constraints"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Interfaces\|Consumes\|Produces" "Mentions Interfaces block"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 6: Plan review and failure-mode coverage
 echo "Test 6: Plan review and Review Focus..."

if ! rg -qi "review the plan.*confirm|confirm.*plan.*captures|does it capture.*intent" "$SKILL"; then
    echo "[FAIL] execution handoff does not require intent confirmation"
    exit 1
fi

if ! rg -q "Review Focus" "$SKILL"; then
    echo "[FAIL] plan format lacks Review Focus"
    exit 1
fi

if ! rg -qi "failure mode.*verification|verification.*failure mode" "$SKILL"; then
    echo "[FAIL] Review Focus does not close uncovered failure modes"
    exit 1
fi

if ! rg -q "Review Focus" "$CHECKER"; then
    echo "[FAIL] plan checker does not validate Review Focus"
    exit 1
fi

echo "[PASS] plan intent review and Review Focus are enforced"
echo ""

# Test 7: Lean-plan guidance (v6.4.2 sync)
echo "Test 7: Lean-plan guidance — unambiguous-not-complete, proportion, checker dimension 9"

if ! rg -q "Unambiguous, not complete" "$SKILL"; then
    echo "[FAIL] Key Principles lacks the unambiguous-not-complete step test"
    exit 1
fi

if ! rg -qi "transcript" "$SKILL"; then
    echo "[FAIL] anti-patterns do not call out transcript-style over-specification"
    exit 1
fi

if ! rg -qi "proportionate|proportion" "$SKILL"; then
    echo "[FAIL] author self-check lacks the proportion check"
    exit 1
fi

if rg -q "reasonable choice wherever the plan leaves" "$SKILL"; then
    echo "[FAIL] refused upstream clause (executor improvises where plan is silent) leaked into the skill"
    exit 1
fi

if ! rg -q "9 dimensions" "$SKILL"; then
    echo "[FAIL] Plan Quality Gate does not declare 9 dimensions"
    exit 1
fi

if ! rg -q "### 9\. Proportion" "$CHECKER"; then
    echo "[FAIL] plan checker lacks dimension 9 (Proportion)"
    exit 1
fi

echo "[PASS] lean-plan guidance enforced (both-directions test, proportion, checker dimension 9)"
echo ""

echo "=== All writing-operation-plans skill tests passed ==="
