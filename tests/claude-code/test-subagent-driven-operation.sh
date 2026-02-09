#!/usr/bin/env bash
# Test: subagent-driven-operation skill
# Verifies that the skill is loaded and follows correct workflow
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: subagent-driven-operation skill ==="
echo ""

# Test 1: Verify skill can be loaded
echo "Test 1: Skill loading..."

output=$(run_claude "What is the subagent-driven-operation skill? Describe its key steps briefly." 30)

if assert_contains "$output" "subagent-driven-operation\|Subagent-Driven Operation\|Subagent Driven Operation" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "subagent\|operator\|reviewer" "Mentions subagents"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Verify workflow order
echo "Test 2: Workflow ordering..."

output=$(run_claude "In the subagent-driven-operation skill, what comes first: spec compliance review or artifact quality review? Be specific about the order." 30)

if assert_order "$output" "spec.*compliance" "artifact.*quality" "Spec compliance before artifact quality"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Verify self-review is mentioned
echo "Test 3: Self-review requirement..."

output=$(run_claude "Does the subagent-driven-operation skill require operators to do self-review? What should they check?" 30)

if assert_contains "$output" "self-review\|self review" "Mentions self-review"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "completeness\|Completeness" "Checks completeness"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 4: Verify plan is read once
echo "Test 4: Plan reading efficiency..."

output=$(run_claude "In subagent-driven-operation, how many times should the controller read the plan file? When does this happen?" 30)

if assert_contains "$output" "once\|one time\|single" "Read plan once"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Step 1\|beginning\|start\|Load Plan\|extract.*tasks" "Read at beginning"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 5: Verify spec compliance reviewer is skeptical
echo "Test 5: Spec compliance reviewer mindset..."

output=$(run_claude "What is the spec compliance reviewer's attitude toward the operator's report in subagent-driven-operation?" 30)

if assert_contains "$output" "not trust\|don't trust\|skeptical\|verify.*independently\|suspiciously" "Reviewer is skeptical"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "read.*code\|inspect.*code\|verify.*code\|check.*artifacts" "Reviewer reads code/artifacts"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 6: Verify review loops
echo "Test 6: Review loop requirements..."

output=$(run_claude "In subagent-driven-operation, what happens if a reviewer finds issues? Is it a one-time review or a loop?" 30)

if assert_contains "$output" "loop\|again\|repeat\|until.*approved\|until.*compliant" "Review loops mentioned"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "operator.*fix\|fix.*issues" "Operator fixes issues"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 7: Verify full task text is provided
echo "Test 7: Task context provision..."

output=$(run_claude "In subagent-driven-operation, how does the controller provide task information to the operator subagent? Does it make them read a file or provide it directly?" 30)

if assert_contains "$output" "provide.*directly\|full.*text\|paste\|include.*prompt" "Provides text directly"; then
    : # pass
else
    exit 1
fi

if assert_not_contains "$output" "read.*file\|open.*file" "Doesn't make subagent read file"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 8: Verify TDO usage
echo "Test 8: TDO requirement..."

output=$(run_claude "What skill should operator subagents use when executing operations in subagent-driven-operation?" 30)

if assert_contains "$output" "test-driven-operation\|TDO\|Test-Driven Operation" "Mentions TDO"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 9: Verify two-stage review
echo "Test 9: Two-stage review..."

output=$(run_claude "What are the two stages of review in subagent-driven-operation? What does each check?" 30)

if assert_contains "$output" "spec.*compliance" "Mentions spec compliance"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "artifact.*quality\|quality" "Mentions artifact quality"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 10: Verify infrastructure operations mentioned
echo "Test 10: Infrastructure operation examples..."

output=$(run_claude "What types of infrastructure operations does subagent-driven-operation apply to? List a few." 30)

if assert_contains "$output" "Kubernetes\|kubectl" "Mentions Kubernetes/kubectl"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Keycloak\|Git\|API" "Mentions other infra operations"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All subagent-driven-operation skill tests passed ==="
