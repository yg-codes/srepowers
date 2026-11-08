#!/usr/bin/env bash
# Regression: the staged (public-edition) README must not tell visitors to
# install plugins the edition does not ship, and must not contain local
# filesystem paths (/home/...). Both defects shipped in public v5.41.2 —
# install lines for domain/private/swe read "plugin not found" for visitors,
# and a codex example leaked /home/yg/src/github/srepowers.
#
# Runs the ACTUAL stager against a prepared copy (same pattern as the
# notes-label test: CI checkouts carry no pattern files, so both are
# synthesized; re-entrancy guard against the parity family).
set -euo pipefail

if [ "${SREPOWERS_README_TEST:-0}" = "1" ]; then
    echo "ok   (nested invocation — re-entrancy guard)"
    exit 0
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/src"
cp -a "$REPO_ROOT/." "$TMP/src/"
if [ ! -f "$TMP/src/.leakpatterns" ]; then
    _t="zzsynthetic-readme-""site"; printf '%s\tsynthetic\n' "$_t" > "$TMP/src/.leakpatterns"
fi
if [ ! -f "$TMP/src/.editionpatterns" ]; then
    _t2="zzsynthetic-readme-""edition"; printf '%s\tsynthetic\n' "$_t2" > "$TMP/src/.editionpatterns"
fi
( cd "$TMP/src" && git add tests/ >/dev/null 2>&1; \
  git -c user.name=ci -c user.email=ci@example.invalid commit -q -am "test env" >/dev/null 2>&1 || true )

( cd "$TMP/src" && SREPOWERS_README_TEST=1 DEST="$TMP/dest" bash scripts/publish-edition.sh ) >"$TMP/run.log" 2>&1 \
    || { cat "$TMP/run.log" >&2; echo "FAIL: stager run failed" >&2; exit 1; }

README="$TMP/dest/README.md"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

[ -f "$README" ] || fail "staged README missing"

# shipped plugins per the stager default: core + infra
if grep -qE '/plugin install srepowers-(domain|private|swe)@' "$README"; then
    fail "staged README installs unshipped plugins"
fi
if grep -q 'srepowers-domain@srepowers-marketplace\|srepowers-private@srepowers-marketplace\|srepowers-swe@srepowers-marketplace' "$README"; then
    fail "staged README names unshipped plugins in install context"
fi
# Codex install steps must not name unshipped plugins either
if grep -qE '^[-`* ]*`srepowers-(domain|private|swe)`' "$README"; then
    fail "staged README names unshipped plugins in install-section bullets"
fi
# No count-dependent 'five' wording in install sections
if grep -qiE 'install all five|all five at once|pulls all five' "$README"; then
    fail "staged README has count-dependent 'five' install wording"
fi
grep -q '/plugin install srepowers-core@srepowers-marketplace' "$README" \
    || fail "staged README lost the core install line"
grep -q '/plugin install srepowers-infra@srepowers-marketplace' "$README" \
    || fail "staged README lost the infra install line"
grep -n '/home/' "$README" | head -3 >&2 || true
if grep -q '/home/' "$README"; then
    fail "staged README contains a local filesystem path"
fi

echo "ok   install lines: core+infra only"
echo "ok   no /home/ paths"
echo "PASS: staged README edition-conditioning regression"
