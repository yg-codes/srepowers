#!/usr/bin/env bash
# Test: kubernetes-specialist skill
# Verifies that the skill supports Kubernetes administration with RBAC and troubleshooting
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: kubernetes-specialist skill ==="
echo ""

# Test 1: Verify skill is recognized
echo "Test 1: Skill recognition..."

output=$(run_claude "What is the kubernetes-specialist skill? Describe its purpose briefly." 30)

if assert_contains "$output" "kubernetes-specialist\|Kubernetes.*Specialist\|kubernetes.*specialist" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: RBAC
echo "Test 2: RBAC..."

output=$(run_claude "In the kubernetes-specialist skill, how does it handle RBAC and access control?" 30)

if assert_contains "$output" "RBAC\|Role.*Binding\|ClusterRole\|ServiceAccount" "RBAC referenced"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Pod troubleshooting
echo "Test 3: Pod troubleshooting..."

output=$(run_claude "In the kubernetes-specialist skill, what is the approach to troubleshooting pod issues?" 30)

if assert_contains "$output" "kubectl.*describe\|kubectl.*logs\|CrashLoopBackOff\|troubleshoot" "Pod troubleshooting covered"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All kubernetes-specialist skill tests passed ==="
