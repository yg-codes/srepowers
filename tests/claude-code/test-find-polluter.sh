#!/usr/bin/env bash
# Tests for find-polluter.sh: the bisection helper that runs a sequence of
# check scripts and identifies the one leaving stray state behind.
#
# Covers the two defects fixed for superpowers v6.2.0 parity (upstream #2008,
# #2011), recast for the SRE check-script variant:
#   1. `find .` emits ./-prefixed paths, so the documented glob
#      'checks/**/*.sh' matched nothing and the script silently found no checks.
#   2. `wc -l` on empty input reports 1, so a zero-match run announced
#      "Found 1 check scripts".
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_UNDER_TEST="$REPO_ROOT/plugins/srepowers-core/skills/systematic-troubleshooting/find-polluter.sh"

FAILURES=0
TEST_ROOT=""
PROJECT=""

pass() { echo "  [PASS] $1"; }
fail() {
    echo "  [FAIL] $1"
    FAILURES=$((FAILURES + 1))
}

cleanup() {
    if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
        rm -rf "$TEST_ROOT"
    fi
}

assert_contains() {
    local haystack="$1" needle="$2" description="$3"
    if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
        pass "$description"
    else
        fail "$description (expected output to contain: $needle)"
    fi
}

# Toy check suite: one check directly under checks/, one nested a level deeper.
# Both create the pollution marker, so whichever runs first is the polluter.
setup_project() {
    PROJECT="$TEST_ROOT/project"
    rm -rf "$PROJECT"
    mkdir -p "$PROJECT/checks/sub"
    printf '#!/usr/bin/env bash\ntouch pollution.marker\n' > "$PROJECT/checks/top.sh"
    printf '#!/usr/bin/env bash\ntouch pollution.marker\n' > "$PROJECT/checks/sub/nested.sh"
    chmod +x "$PROJECT/checks/top.sh" "$PROJECT/checks/sub/nested.sh"
}

# run_polluter <glob> — run the script in the toy suite, capture combined
# output, never abort on the script's own exit code (1 means polluter found).
run_polluter() {
    local glob="$1"
    rm -f "$PROJECT/pollution.marker"
    (
        cd "$PROJECT"
        "$SCRIPT_UNDER_TEST" 'pollution.marker' "$glob" 2>&1
    ) || true
}

main() {
    echo "=== Test: find-polluter.sh ==="

    TEST_ROOT="$(mktemp -d)"
    trap cleanup EXIT

    local output

    echo "Test: documented glob finds nested check scripts"
    setup_project
    output="$(run_polluter 'checks/**/*.sh')"
    assert_contains "$output" "FOUND POLLUTER" "documented glob runs checks and detects pollution"

    echo "Test: documented glob also finds checks directly under the base dir"
    setup_project
    output="$(run_polluter 'checks/**/*.sh')"
    assert_contains "$output" "Found 2 check scripts" "checks/**/*.sh matches checks/top.sh and checks/sub/nested.sh"

    echo "Test: ./-prefixed glob matches the same scripts"
    setup_project
    output="$(run_polluter './checks/**/*.sh')"
    assert_contains "$output" "Found 2 check scripts" "leading ./ on the glob is accepted"

    echo "Test: non-matching glob reports an honest zero"
    setup_project
    output="$(run_polluter 'nomatch/**/*.sh')"
    assert_contains "$output" "Found 0 check scripts" "empty result counts as 0, not 1"
    assert_contains "$output" "No polluter found" "empty result exits via the clean path"

    echo ""
    if [[ "$FAILURES" -gt 0 ]]; then
        echo "$FAILURES test(s) failed"
        exit 1
    fi
    echo "All tests passed"
}

main "$@"
