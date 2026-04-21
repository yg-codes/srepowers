#!/usr/bin/env bash
# Lightweight Codex-oriented validation for repo-native and plugin packaging.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$REPO_ROOT"

echo "========================================"
echo " Codex Skill Validation"
echo "========================================"
echo ""

fail() {
  echo "[FAIL] $1"
  exit 1
}

pass() {
  echo "[PASS] $1"
}

[ -f .codex-plugin/plugin.json ] || fail ".codex-plugin/plugin.json missing"
pass "Codex plugin manifest present"

[ -f .agents/plugins/marketplace.json ] || fail ".agents/plugins/marketplace.json missing"
pass "Codex marketplace present"

[ -f .codex/hooks.json ] || fail ".codex/hooks.json missing"
pass "Codex hooks config present"

[ -f .codex/agents/infrastructure-operator.toml ] || fail "Codex infrastructure operator missing"
[ -f .codex/agents/infrastructure-reviewer.toml ] || fail "Codex infrastructure reviewer missing"
pass "Codex custom agents present"

[ -d skills ] || fail "skills directory missing"
[ -d .agents/skills ] || fail ".agents/skills directory missing"

skill_count=$(find skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
mirror_count=$(find .agents/skills -mindepth 1 -maxdepth 1 \( -type d -o -type l \) | wc -l | tr -d ' ')
[ "$skill_count" = "$mirror_count" ] || fail "skill mirror count mismatch: skills=$skill_count mirror=$mirror_count"
pass "Codex skill mirror count matches canonical skills"

if command -v codex >/dev/null 2>&1; then
  echo ""
  echo "codex detected: $(codex --version 2>/dev/null || echo unknown)"
else
  echo ""
  echo "[INFO] codex CLI not installed; skipping interactive runtime checks"
fi

echo ""
echo "STATUS: PASSED"
