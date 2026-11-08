#!/usr/bin/env bash
# Regression: the publisher's parity loops must fail on a MIDDLE test failure.
#
# History: `set -e` inside `( ... ) || die` is suppressed (bash ignores errexit
# in a command whose failure is being tested), so a mid-loop test failure was
# masked by the last iteration's exit 0 — an edition with red hosted CI passed
# the dry run. The fix is explicit `|| exit 1` per iteration. This test proves
# BOTH halves: the loop pattern fails on a middle failure (behavioral), and
# publish-edition.sh actually uses the pattern (structural).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- behavioral: three fake tests, the MIDDLE one fails -------------------
mkdir -p "$TMP/tests"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/tests/aaa-pass.sh"
printf '#!/usr/bin/env bash\nexit 1\n' > "$TMP/tests/bbb-fail.sh"   # the middle failure
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/tests/ccc-pass.sh"
chmod +x "$TMP"/tests/*.sh

# The stager's loop shape, verbatim semantics: ( set -e; for ...; bash || exit 1 )
rc=0
(
    cd "$TMP" && set -e
    for t in tests/*.sh; do
        bash "$t" >/dev/null || exit 1
    done
) || rc=$?
if [ "$rc" -eq 0 ]; then
    echo "FAIL: loop survived a middle-test failure (the shipped defect)" >&2
    exit 1
fi
echo "ok   loop aborts on middle-test failure (rc=$rc)"

# --- counter-proof: the OLD shape (bare invocation, set -e suppressed) ---
# If this ever FAILS, bash semantics changed and the fix's premise is gone —
# revisit publish-edition.sh accordingly.
rc=0
(
    cd "$TMP" && set -e
    for t in tests/*.sh; do
        bash "$t" >/dev/null            # no explicit propagation
    done
) || rc=$?
if [ "$rc" -ne 0 ]; then
    echo "NOTE: bare set -e loop now fails fast — bash semantics changed" >&2
else
    echo "ok   old shape confirmed still-masking (why the explicit form is required)"
fi

# --- structural: the stager uses the explicit-propagation form -------------
n=$(grep -c '|| exit 1' "$REPO_ROOT/scripts/publish-edition.sh")
if [ "$n" -lt 6 ]; then
    echo "FAIL: publish-edition.sh carries only $n '|| exit 1' guards (expected >= 6 — one per parity loop iteration class)" >&2
    exit 1
fi
echo "ok   publish-edition.sh uses explicit per-iteration propagation ($n sites)"

echo "PASS: parity fail-fast regression"
