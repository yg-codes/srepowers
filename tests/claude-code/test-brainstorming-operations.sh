#!/usr/bin/env bash
# Test: brainstorming-operations skill
# Verifies that the skill guides collaborative infrastructure operation design
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-core/skills/brainstorming-operations/SKILL.md"
VISUAL="$REPO_ROOT/plugins/srepowers-core/skills/brainstorming-operations/visual-companion.md"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: brainstorming-operations skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the brainstorming-operations skill? Describe what it does briefly." 30)

if assert_contains "$output" "brainstorming-operations\|Brainstorming.*Operations\|brainstorming.*operation" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Asks questions before proceeding
echo "Test 2: Asks questions before proceeding..."

output=$(run_claude "In the brainstorming-operations skill, how does it gather information? Does it ask questions all at once or one at a time?" 30)

if assert_contains "$output" "one.*at.*a.*time\|one question\|ask.*question" "Asks questions one at a time"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Risk assessment included
echo "Test 3: Risk assessment..."

output=$(run_claude "In brainstorming-operations, what does the design document include about risks? Mention the risk-related sections." 30)

if assert_contains "$output" "risk.*assessment\|Risk Assessment\|risk.*level\|Low.*Medium.*High\|what could go wrong" "Risk assessment is included"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 4: Rollback strategy covered
echo "Test 4: Rollback strategy..."

output=$(run_claude "In brainstorming-operations, is rollback planning part of the design? What does it say about rollback?" 30)

if assert_contains "$output" "rollback\|Rollback" "Rollback strategy is covered"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 5: Shared understanding and stage-specific approval
 echo "Test 5: Shared understanding and approval stages..."

if ! rg -q "Establish Shared Understanding" "$SKILL"; then
    echo "[FAIL] shared-understanding section missing"
    exit 1
fi

if ! rg -q "separate what.*said from assumptions|said.*assumptions" "$SKILL"; then
    echo "[FAIL] skill does not separate operator statements from assumptions"
    exit 1
fi

if ! rg -q "approval.*stage|stage.*approval|earliest incomplete stage|selected path.*prerequisite" "$SKILL"; then
    echo "[FAIL] stage-specific approval boundary missing"
    exit 1
fi

for helper in start-server.sh stop-server.sh; do
    if rg -q "^[[:space:]]*scripts/${helper}" "$VISUAL"; then
        echo "[FAIL] visual companion invokes ${helper} without bash"
        exit 1
    fi
done

if ! rg -Fq 'bash scripts/stop-server.sh "$SESSION_DIR"' "$VISUAL"; then
    echo "[FAIL] visual companion cleanup does not quote SESSION_DIR"
    exit 1
fi

echo "[PASS] shared understanding, staged approval, and visual helper portability present"
echo ""

echo "=== All brainstorming-operations skill tests passed ==="
