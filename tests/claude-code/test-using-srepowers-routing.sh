#!/usr/bin/env bash
# Test: using-srepowers routing behavior
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: using-srepowers routing behavior ==="
echo ""

echo "Test 1: Incident routes to troubleshooting first..."
output=$(run_claude "Using SREPowers, I have a single-service outage with unclear cause. Which skill should I use first and what should I avoid doing before evidence?" 90)

if assert_contains "$output" "systematic-troubleshooting" "Routes incidents to systematic-troubleshooting"; then
  :
else
  exit 1
fi

if assert_contains "$output" "avoid.*fix|don't.*fix|before.*evidence|before.*root cause" "Avoids premature remediation"; then
  :
else
  exit 1
fi

echo ""

echo "Test 2: Low-risk local work uses fast path..."
output=$(run_claude "Using SREPowers, I only need to edit one local manifest file and validate it locally. Do I need brainstorming-operations, or is there a fast path?" 90)

if assert_contains "$output" "fast path|test-driven-operation|low-risk" "Recognizes fast path"; then
  :
else
  exit 1
fi

if assert_not_contains "$output" "must.*brainstorming-operations|always.*brainstorming-operations" "Does not force brainstorming on fast path"; then
  :
else
  exit 1
fi

echo ""

echo "Test 3: Risky prod commands require safety gate..."
output=$(run_claude "Using SREPowers, I am about to run a production kubectl delete command. What gate should apply before execution?" 90)

if assert_contains "$output" "safety-validator" "Routes risky production commands through safety-validator"; then
  :
else
  exit 1
fi

echo ""
echo "=== All using-srepowers routing behavior tests passed ==="
