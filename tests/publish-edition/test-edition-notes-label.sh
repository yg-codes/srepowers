#!/usr/bin/env bash
# Regression: the generated edition RELEASE-NOTES must carry "(initial)" ONLY
# when EDITION_INITIAL=1. The 5.41.1 cut shipped mislabelled because the label
# was hardcoded; nothing asserted the output. Runs the ACTUAL stager twice
# (default + EDITION_INITIAL=1) against a prepared copy — CI checkouts carry
# no .leakpatterns/.editionpatterns, so both are synthesized in the copy (the
# same pattern test-publisher-injected-failure.sh uses). Absence assertions
# use if-form: `grep -q … && fail` under set -e aborts on the good case.
set -euo pipefail

# Re-entrancy guard: this test runs the full stager, whose parity suite runs
# the tests family — including THIS test — which would recurse without bound.
# Nested invocations (inside a stager we launched) exit 0 immediately.
if [ "${SREPOWERS_NOTES_LABEL_TEST:-0}" = "1" ]; then
    echo "ok   (nested invocation — re-entrancy guard)"
    exit 0
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

VERSION="$(python3 -c 'import json;print(json.load(open("'"$REPO_ROOT"'/plugins/srepowers-core/.claude-plugin/plugin.json"))["version"])')"

mkdir -p "$TMP/src"
cp -a "$REPO_ROOT/." "$TMP/src/"
if [ ! -f "$TMP/src/.leakpatterns" ]; then
    _t1="zzsynthetic-notes-""site"
    printf '%s\tsynthetic\n' "$_t1" > "$TMP/src/.leakpatterns"
fi
if [ ! -f "$TMP/src/.editionpatterns" ]; then
    _t2="zzsynthetic-notes-""edition"
    printf '%s\tsynthetic\n' "$_t2" > "$TMP/src/.editionpatterns"
fi
# The publisher needs a clean committed tree; commit whatever the copy
# carried. A clean checkout (CI PR-merge refs) has nothing to commit — that
# is success, not failure. The copy is disposable; the stager's own
# preflight is the real gate on its state.
( cd "$TMP/src" && git add tests/ >/dev/null 2>&1; \
  git -c user.name=ci -c user.email=ci@example.invalid commit -q -am "test env" >/dev/null 2>&1 || true )

run_and_read_notes() { # <env-assignment|-> -> prints the generated RELEASE-NOTES.md
    if [ "$1" = "-" ]; then
        ( cd "$TMP/src" && SREPOWERS_NOTES_LABEL_TEST=1 DEST="$TMP/dest" bash scripts/publish-edition.sh ) >"$TMP/run.log" 2>&1
    else
        ( cd "$TMP/src" && env SREPOWERS_NOTES_LABEL_TEST=1 DEST="$TMP/dest" "$1" bash scripts/publish-edition.sh ) >"$TMP/run.log" 2>&1
    fi || { cat "$TMP/run.log" >&2; echo "FAIL: stager run failed ($1)" >&2; return 1; }
    cat "$TMP/dest/RELEASE-NOTES.md"
}

PLAIN="## $VERSION — SREPowers public edition"
INITIAL="## $VERSION — SREPowers public edition (initial)"

notes="$(run_and_read_notes -)"
printf '%s' "$notes" | grep -qxF "$PLAIN" || { echo "FAIL: default cut missing plain title '$PLAIN'" >&2; exit 1; }
if printf '%s' "$notes" | grep -q "(initial)"; then echo "FAIL: default cut says (initial)" >&2; exit 1; fi
printf '%s' "$notes" | grep -q "^An edition of SREPowers" || { echo "FAIL: default lead wrong" >&2; exit 1; }
if printf '%s' "$notes" | grep -qE '\bp[p]r\b|infra_(sit|uat|prod)|INFRA-[0-9]|[_]cu[_]|[_]mr[_]'; then echo "FAIL: default notes not born-sanitized" >&2; exit 1; fi
echo "ok   default: plain title, no (initial), sanitized"

notes="$(run_and_read_notes EDITION_INITIAL=1)"
printf '%s' "$notes" | grep -qxF "$INITIAL" || { echo "FAIL: EDITION_INITIAL=1 missing '$INITIAL'" >&2; exit 1; }
printf '%s' "$notes" | grep -q "^The first public edition of SREPowers" || { echo "FAIL: initial lead wrong" >&2; exit 1; }
if printf '%s' "$notes" | grep -qE '\bp[p]r\b|infra_(sit|uat|prod)|INFRA-[0-9]|[_]cu[_]|[_]mr[_]'; then echo "FAIL: initial notes not born-sanitized" >&2; exit 1; fi
echo "ok   EDITION_INITIAL=1: (initial) title, first-edition lead, sanitized"

echo "PASS: edition notes label regression (both variants)"
