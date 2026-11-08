#!/usr/bin/env bash
# Integration: inject a failing MIDDLE test into a full copy of this repo and
# run the ACTUAL publisher end-to-end. It must die at the content-test family
# naming the injected test — proving propagation in the real script, not a
# copied loop (the fast structural/behavioral layer lives in
# test-parity-failfast.sh; this file is the end-to-end guarantee).
#
# Cost: one full staging run (~1-2 min) plus a ~100 MB temp copy. That cost is
# the point — the cheaper test shape already shipped one masked-failure defect.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Full copy INCLUDING .git: the publisher's preflight requires a committed,
# clean tracked tree, and staging must exercise the real repository content.
mkdir -p "$WORK/src"
cp -a "$REPO_ROOT/." "$WORK/src/"

# CI checkouts have no .leakpatterns/.editionpatterns (gitignored); the
# publisher requires both. Synthesize benign sets so the run reaches the
# test families. Tokens are assembled from pieces: this test ships in the
# edition, and a literal token in this file would be caught by the very gate
# under test (observed: 'site data ... test-publisher-injected-failure.sh:23').
if [ ! -f "$WORK/src/.leakpatterns" ]; then
    _tok="zzsynthetic-ci-""pattern"
    printf '%s\tsynthetic\n' "$_tok" > "$WORK/src/.leakpatterns"
fi
if [ ! -f "$WORK/src/.editionpatterns" ]; then
    _tok2="zzsynthetic-edition-""shape"
    printf '%s\tsynthetic edition\n' "$_tok2" > "$WORK/src/.editionpatterns"
fi

# Inject a failing test that sorts into the MIDDLE of the content-test family.
cd "$WORK/src"
printf '#!/usr/bin/env bash\n# injected by test-publisher-injected-failure.sh\nexit 1\n' \
    > tests/claude-code/test-mmm-injected-failure.sh
# Commit the injected test, any new test files, and whatever tracked
# modifications the copy carried over (the publisher requires a clean tree,
# and its contamination audit requires every staged path tracked in SRC).
git add tests/
git -c user.name=ci -c user.email=ci@example.invalid commit -q -am "inject failing middle test"

rc=0
DEST="$WORK/dest" bash scripts/publish-edition.sh > "$WORK/run.log" 2>&1 || rc=$?

fail() { printf 'FAIL: %s\n' "$*" >&2; tail -5 "$WORK/run.log" >&2; exit 1; }

[ "$rc" -ne 0 ] || fail "publisher PASSED with an injected failing content test"
grep -q "test-mmm-injected-failure" "$WORK/run.log" \
    || fail "injected test never ran — wrong failure surface"
grep -q "content tests failed" "$WORK/run.log" \
    || fail "failed for a different reason than the injected test"
grep -qE "edition.*5\.4[0-9]" "$WORK/run.log" \
    || fail "run did not reach staging (preflight died early)"

echo "PASS: publisher dies at the injected middle-test failure (rc=$rc, 'content tests failed')"
