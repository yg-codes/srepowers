#!/usr/bin/env bash
# Test: systematic-troubleshooting skill
# Verifies that the skill is loaded and follows correct workflow
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: systematic-troubleshooting skill ==="
echo ""

# Test 1: Verify skill can be loaded
echo "Test 1: Skill loading..."

output=$(run_claude "What is the systematic-troubleshooting skill? Describe its purpose briefly." 30)

if assert_contains "$output" "systematic-troubleshooting\|troubleshoot\|incident" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "root cause\|infrastructure\|outage" "Mentions root cause and infrastructure"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Verify Iron Law
echo "Test 2: Iron Law emphasis..."

output=$(run_claude "In systematic-troubleshooting, what is the Iron Law? Quote it." 30)

if assert_contains "$output" "NO REMEDIATION WITHOUT ROOT CAUSE INVESTIGATION FIRST" "Quotes Iron Law"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Verify four phases
echo "Test 3: Four phases..."

output=$(run_claude "In systematic-troubleshooting, what are the four phases? List them in order." 30)

if assert_contains "$output" "Phase 1\|Phase 2\|Phase 3\|Phase 4" "Mentions four phases"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Triage\|Pattern\|Hypothesis\|Remediation" "Mentions phase names"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 4: Verify Phase 1 activities
echo "Test 4: Phase 1 incident triage..."

output=$(run_claude "In systematic-troubleshooting Phase 1, what data must be gathered before attempting remediation?" 30)

if assert_contains "$output" "timeline\|scope\|evidence\|logs" "Mentions data gathering"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "kubectl\|events\|metrics" "Mentions infrastructure tools"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 5: Verify layer-by-layer investigation
echo "Test 5: Layer-by-layer investigation..."

output=$(run_claude "In systematic-troubleshooting, how should distributed systems be investigated? Describe the layers." 30)

if assert_contains "$output" "layer\|ingress\|service\|pod\|container" "Mentions layers"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "boundary\|component" "Mentions component boundaries"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 6: Verify 3+ fixes rule
echo "Test 6: Three-fixes rule..."

output=$(run_claude "In systematic-troubleshooting, what should you do if 3 or more fixes have failed?" 30)

if assert_contains "$output" "STOP\|question\|architecture" "Mentions stopping and questioning"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "architectural\|technical debt" "Mentions architectural issues"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 7: Verify SRE Principles section exists
echo "Test 7: SRE Principles integration..."

output=$(run_claude "What are the SRE Principles in the systematic-troubleshooting skill? List them." 30)

if assert_contains "$output" "Safety First\|Structured Output\|Evidence-Driven\|Audit-Ready\|Communication" "Lists SRE Principles"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 8: Verify incident response integration
echo "Test 8: Incident response integration..."

output=$(run_claude "In systematic-troubleshooting, what are the first 5 minutes of incident response?" 30)

if assert_contains "$output" "acknowledge\|scope\|gather\|DO NOT fix" "Mentions initial response"; then
    : # pass
else
    exit 1
fi

echo ""

echo "========================================"
echo "All tests passed!"
echo "========================================"
