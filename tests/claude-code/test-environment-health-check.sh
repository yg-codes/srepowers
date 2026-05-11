#!/usr/bin/env bash
# Test: environment-health-check skill content invariants
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-core/skills/environment-health-check/SKILL.md"

echo "=== Test: environment-health-check skill ==="

# Must not rely on current-context
if rg -q "kubectl config current-context" "$SKILL"; then
  echo "[FAIL] environment-health-check still relies on current-context"
  exit 1
fi

# Must have explicit context diagnostics
if ! rg -q "kubectl --context <context> cluster-info|kubectl --kubeconfig=/path/to/config --context <context> get nodes" "$SKILL"; then
  echo "[FAIL] explicit context diagnostics missing"
  exit 1
fi

# Must use per-tool version command lookup (not blind $tool --version)
if ! rg -q "VERSION_CMD|declare -A" "$SKILL"; then
  echo "[FAIL] missing per-tool version command lookup table"
  exit 1
fi

# Must not instruct users to run kubectl version --short (deprecated in kubectl v1.33+)
# Only check inside code blocks (```...```), not in prose explanations
CODEBLOCK_CONTENT=$(sed -n '/^```/,/^```/p' "$SKILL")
if echo "$CODEBLOCK_CONTENT" | rg -q 'kubectl.*version.*--short'; then
  echo "[FAIL] code block references deprecated kubectl version --short"
  exit 1
fi
unset CODEBLOCK_CONTENT

# Must document the --version mismatch issue
if ! rg -q "does NOT support.*--version|not all tools use --version" "$SKILL"; then
  echo "[FAIL] missing documentation about --version flag inconsistencies"
  exit 1
fi

# Must document Vault TLS issue
if ! rg -q "tls-skip-verify|TLS.*error.*vault|x509.*certificate.*unknown authority" "$SKILL"; then
  echo "[FAIL] missing Vault TLS error guidance"
  exit 1
fi

# Must document openssl-not-in-static-pods issue
if ! rg -q "openssl.*not.*found|minimal.*base.*image|static pod.*openssl" "$SKILL"; then
  echo "[FAIL] missing guidance for openssl absence in static pod containers"
  exit 1
fi

echo "[PASS] environment-health-check skill content validated"
