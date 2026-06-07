#!/usr/bin/env bash
# Static regression checks for the golang-pro code-review reference.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-domain/skills/golang-pro/SKILL.md"
REFERENCE="$REPO_ROOT/plugins/srepowers-domain/skills/golang-pro/references/code-review.md"

fail() {
  echo "[FAIL] $1"
  exit 1
}

rg -q '^description: Use when .*review' "$SKILL" ||
  fail "golang-pro description does not advertise Go code review"

if rg -q 'func NewUserGetter\(db \*sql\.DB\) \*UserGetter' "$REFERENCE"; then
  fail "constructor example returns a pointer to an interface"
fi

if rg -q 'ticker.*goroutine leaks|ticker\.Goroutine still running' "$REFERENCE"; then
  fail "ticker guidance incorrectly claims a per-ticker goroutine leak"
fi

rg -q 'crypto/rand\.Text.*Go 1\.24\+' "$REFERENCE" ||
  fail "crypto/rand.Text guidance must identify Go 1.24+"

echo "[PASS] golang-pro code-review reference regression checks"
