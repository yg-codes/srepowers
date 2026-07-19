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

# Test 2: Verify verdict order within the single task review
echo "Test 2: Verdict ordering..."

output=$(run_claude "In the subagent-driven-operation skill, how many reviewer subagents run per task, and in what order does the reviewer report its verdicts?" 30)

if assert_contains "$output" "one reviewer\|single reviewer\|one task reviewer\|task-reviewer\|task reviewer" "One reviewer per task"; then
    : # pass
else
    exit 1
fi

if assert_order "$output" "spec.*compliance" "quality" "Spec compliance verdict reported before quality"; then
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

# Test 5: Verify the task reviewer is skeptical
echo "Test 5: Task reviewer mindset..."

output=$(run_claude "What is the task reviewer's attitude toward the operator's report in subagent-driven-operation?" 30)

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

# Test 7: Verify file-handoff model (task brief + report/review-package files)
echo "Test 7: File-handoff model..."

output=$(run_claude "In subagent-driven-operation, how does the controller give a subagent its task — does it paste the full task text into the prompt, or hand over a file the subagent reads? What script produces it?" 30)

if assert_contains "$output" "brief\|task-brief\|file" "Hands over a brief file"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "report file\|report\|review.package\|review-package" "Artifacts move as files"; then
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

# Test 9: Verify the two verdicts returned by the single task reviewer
echo "Test 9: Two verdicts, one reviewer..."

output=$(run_claude "What verdicts does the task reviewer return in subagent-driven-operation? What does each check?" 30)

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

# Test 9b: Verify the cannot-verify-from-diff verdict
echo "Test 9b: Cannot-verify-from-diff handling..."

output=$(run_claude "In subagent-driven-operation, what should the task reviewer do about a requirement it cannot verify from the diff alone, and who resolves it?" 30)

if assert_contains "$output" "cannot verify\|can't verify\|Cannot verify\|⚠️" "Reports a cannot-verify item"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "controller\|yourself\|resolve" "Controller resolves it"; then
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
