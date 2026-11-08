#!/usr/bin/env bash
# Test: sdd-workspace reclaims a dead owner's claim by IDENTITY, never by path.
# Regression for issue #78: with a crashed claimant and two waiters, a waiter
# that observed the dead pid and then stalled would delete whatever claim sat
# at the path when it woke — the OTHER waiter's freshly acquired, live claim —
# and both waiters held the claim at once (both resolved one workspace).
#
# Deterministic: hooks are INJECTED into a copy of the real script. Workers
# write marker files at the liveness check, on entering the reclaim branch,
# at the end of a reclaim attempt, and inside the workspace marker-write gap;
# at the reclaim branch and the workspace gap they also BLOCK on a gate file
# the test creates. Every interleave is therefore a handshake, never a timed
# sleep, and each worker's exit code and output are asserted, so a worker
# that fails early or never reaches the race cannot make a scenario pass.
# Hermetic: everything under mktemp.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REAL="$REPO_ROOT/plugins/srepowers-core/skills/subagent-driven-operation/scripts/sdd-workspace"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

echo "=== Test: sdd-workspace dead-owner reclaim is by identity ==="

FAIL=0
pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

# inject_hooks <src> <dst>. Around the liveness check:
#   SDD_SEEN_MARK  — append the observed owner pid on reaching the check
#   SDD_REAP_MARK  — touched on entering the dead-owner (reclaim) branch
#   SDD_REAP_GATE  — then block until this file exists; 10s → exit 99
#   SDD_DONE_MARK  — touched at the end of a loop iteration that reclaimed
# and in the workspace marker-write gap, so a claim stays held:
#   SDD_WS_MARK    — touched on entering the gap
#   SDD_WS_GATE    — then block until this file exists; 10s → exit 99
inject_hooks() {
    python3 - "$1" "$2" <<'PYEOF'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
s = open(src).read()
# The liveness check and its indentation differ across versions; match any.
live_re = re.compile(r'^([ \t]*)(if ! (?:kill -0 "\$owner" 2>/dev/null|owner_alive "\$owner"); then\n)', re.M)
loop_end = '    attempts=$((attempts + 1))\n'
needle_ws = '    mkdir -p "$workspace"\n    # Marker write is atomic'
assert live_re.search(s), "liveness hook point not found"
assert loop_end in s, "loop-end hook point not found"
assert needle_ws in s, "marker-gap hook point not found"
def hook(m):
    ind = m.group(1)
    return (ind + 'if [ -n "${SDD_SEEN_MARK:-}" ]; then printf \'%s\\n\' "$owner" >> "$SDD_SEEN_MARK"; fi\n'
            + ind + m.group(2)
            + ind + '  if [ -n "${SDD_REAP_MARK:-}" ]; then : > "$SDD_REAP_MARK"; fi\n'
            + ind + '  if [ -n "${SDD_REAP_GATE:-}" ]; then _hk=0; while [ ! -e "$SDD_REAP_GATE" ]; do [ "$_hk" -lt 200 ] || { echo "hook: reap gate timeout" >&2; exit 99; }; sleep 0.05; _hk=$((_hk + 1)); done; fi\n')
s = live_re.sub(hook, s, count=1)
s = s.replace(loop_end,
    '    if [ -n "${SDD_DONE_MARK:-}" ] && [ -e "${SDD_REAP_MARK:-/nonexistent}" ]; then : > "$SDD_DONE_MARK"; fi\n'
    + loop_end, 1)
s = s.replace(needle_ws,
    '    mkdir -p "$workspace"\n'
    '    if [ -n "${SDD_WS_MARK:-}" ]; then : > "$SDD_WS_MARK"; _hk=0; while [ ! -e "${SDD_WS_GATE:-/nonexistent}" ]; do [ "$_hk" -lt 200 ] || { echo "hook: workspace gate timeout" >&2; exit 99; }; sleep 0.05; _hk=$((_hk + 1)); done; fi\n'
    '    # Marker write is atomic', 1)
open(dst, "w").write(s)
PYEOF
}

# wait_for <file> <seconds>: bounded wait for a marker file.
wait_for() {
    local i n
    n=$(awk -v s="$2" 'BEGIN { print int(s / 0.05) }')
    for ((i = 0; i < n; i++)); do
        [ -e "$1" ] && return 0
        sleep 0.05
    done
    return 1
}

# run_worker <name> <repo> <plan> <timeout> [VAR=value...]: run the hooked
# script in the background; stdout, stderr and exit code land in $T/<name>.*
run_worker() {
    local name=$1 repo=$2 plan=$3 secs=$4
    shift 4
    (
        cd "$repo"
        rc=0
        env "$@" timeout "$secs" bash "$T/sdd-hooked" "$plan" \
            > "$T/$name.out" 2> "$T/$name.err" || rc=$?
        echo "$rc" > "$T/$name.rc"
    ) &
}

# diag <name>: print a worker's result for a failing assertion.
diag() {
    echo "    $1: rc=$(cat "$T/$1.rc" 2>/dev/null || echo '<none>') out=$(cat "$T/$1.out" 2>/dev/null || :)"
    sed "s/^/    $1 stderr: /" "$T/$1.err" 2>/dev/null | head -4
}

dead_pid() { bash -c 'echo $$'; }

# Keep the resolver beside the injected copy, as in the installed skill.
cp "$(dirname "$REAL")/sdd-repo" "$T/sdd-repo"
inject_hooks "$REAL" "$T/sdd-hooked"

# --- 1. The #78 interleave, as a handshake ---------------------------------
#   B sees plan.claim owned by a dead pid, enters the reclaim branch, blocks.
#   A starts, reclaims the same dead claim, acquires plan.claim, creates
#   workspace `plan`, signals from inside the marker-write gap, blocks.
#   Only then is B released. A by-path reclaim deletes A's LIVE claim, then
#   B acquires and adopts the still-empty `plan` and finishes. A by-identity
#   reclaim leaves A's claim alone, and B goes back to waiting on A (seen as
#   a live owner). Once B has done one or the other, A is released.
#   Buggy: both resolve `plan`. Fixed: B takes `plan-team`.
R1="$T/repo1"
git init -q "$R1"
mkdir -p "$R1/docs/race-a/team" "$R1/docs/race-b/team" "$R1/.srepowers/sdd/plan.claim"
printf '# a\n' > "$R1/docs/race-a/team/plan.md"
printf '# b\n' > "$R1/docs/race-b/team/plan.md"
dead1=$(dead_pid)
printf '%s\n' "$dead1" > "$R1/.srepowers/sdd/plan.claim/pid"
run_worker b1 "$R1" docs/race-b/team/plan.md 30 \
    SDD_SEEN_MARK="$T/b1.seen" SDD_REAP_MARK="$T/b1.reap" SDD_REAP_GATE="$T/b1.go"
why1=''
if ! wait_for "$T/b1.reap" 5; then
    why1="B never reached the reclaim branch"
else
    run_worker a1 "$R1" docs/race-a/team/plan.md 30 \
        SDD_WS_MARK="$T/a1.ws" SDD_WS_GATE="$T/a1.go"
    if ! wait_for "$T/a1.ws" 5; then
        why1="A never held the claim inside the workspace gap"
    else
        : > "$T/b1.go"
        # B either finished (deleted A's claim) or saw A as a live owner.
        for ((i = 0; i < 200; i++)); do
            [ -e "$T/b1.rc" ] && break
            grep -qvx "$dead1" "$T/b1.seen" 2>/dev/null && break
            sleep 0.05
        done
        [ "$i" -lt 200 ] || why1="B neither finished nor waited on A"
    fi
fi
: > "$T/b1.go"; : > "$T/a1.go"
wait
a=$(cat "$T/a1.out" 2>/dev/null || :); b=$(cat "$T/b1.out" 2>/dev/null || :)
if [[ -z "$why1" && "$(cat "$T/a1.rc")" == 0 && "$(cat "$T/b1.rc")" == 0 && -n "$a" && "$a" != "$b" \
    && "$(cat "$a/plan-path" 2>/dev/null)" == "docs/race-a/team/plan.md" \
    && "$(cat "$b/plan-path" 2>/dev/null)" == "docs/race-b/team/plan.md" ]]; then
    pass "reaper never deletes a live claim (distinct workspaces)"
else
    fail "reaper never deletes a live claim (distinct workspaces)${why1:+ ($why1)}"
    diag a1; diag b1
fi
stray=$(find "$R1/.srepowers/sdd" -maxdepth 1 \( -name '*.claim' -o -name '*.claimant.*' -o -name '*.reap.*' \) | head -3)
if [ -z "$stray" ]; then
    pass "no leftover claim, claimant or reap entries"
else
    fail "no leftover claim, claimant or reap entries"
    echo "    stray: $stray"
fi

# --- 2. A dead claimant in the CURRENT `owner.<pid>` format is reclaimed ----
R2="$T/repo2"
git init -q "$R2"
printf '# s\n' > "$R2/stale.md"
mkdir -p "$R2/.srepowers/sdd/stale.claim"
: > "$R2/.srepowers/sdd/stale.claim/owner.$(dead_pid)"
run_worker w2 "$R2" stale.md 15 SDD_REAP_MARK="$T/w2.reap"
wait
if [[ "$(cat "$T/w2.rc")" == 0 && "$(cat "$T/w2.out")" == "$R2/.srepowers/sdd/stale" \
    && -e "$T/w2.reap" && ! -e "$R2/.srepowers/sdd/stale.claim" ]]; then
    pass "dead owner.<pid> claim is reclaimed"
else
    fail "dead owner.<pid> claim is reclaimed"
    diag w2
fi

# overlap <name> <repo> <claim-dir> <plan>: worker B is held at its reclaim
# gate; the test then republishes the claim as a LIVE legacy `pid` claim (a
# 5.36.1 client), waits for B to finish that reclaim attempt, and samples the
# pid file. Afterwards the live owner exits and B must complete normally.
overlap() {
    local name=$1 repo=$2 lock=$3 plan=$4 live seen
    sleep 60 & live=$!
    run_worker "$name" "$repo" "$plan" 20 \
        SDD_REAP_MARK="$T/$name.reap" SDD_DONE_MARK="$T/$name.done" SDD_REAP_GATE="$T/$name.go"
    if ! wait_for "$T/$name.reap" 5; then
        kill "$live" 2>/dev/null || :; wait
        echo "never reached the reclaim branch"
        return
    fi
    rm -f "$lock"/owner.* "$lock/pid"; rmdir "$lock"   # the dead claim is cleared...
    mkdir "$lock"; printf '%s\n' "$live" > "$lock/pid" # ...and a live 5.36.1 client holds it
    : > "$T/$name.go"                                  # only now may B reclaim
    if ! wait_for "$T/$name.done" 5; then
        kill "$live" 2>/dev/null || :; wait
        echo "never finished its reclaim attempt"
        return
    fi
    seen=$(cat "$lock/pid" 2>/dev/null || :)
    kill "$live" 2>/dev/null || :
    wait
    if [ "$seen" != "$live" ]; then
        echo "pid file after B's reclaim: '${seen:-<gone>}' (expected $live)"
    elif [ "$(cat "$T/$name.rc")" != 0 ] || [ "$(cat "$T/$name.out")" != "${lock%.claim}" ]; then
        echo "worker did not complete normally after the live owner exited"
    fi
}

# --- 3. Mixed-version overlap: B observed a dead owner.<pid> marker ---------
# It must not fall back to the `pid` path because that marker has gone.
R3="$T/repo3"
git init -q "$R3"
printf '# m\n' > "$R3/mixed.md"
mkdir -p "$R3/.srepowers/sdd/mixed.claim"
: > "$R3/.srepowers/sdd/mixed.claim/owner.$(dead_pid)"
why=$(overlap w3 "$R3" "$R3/.srepowers/sdd/mixed.claim" mixed.md)
if [ -z "$why" ]; then
    pass "mixed-version: a live legacy pid claim is never reclaimed"
else
    fail "mixed-version: a live legacy pid claim is never reclaimed ($why)"
    diag w3
fi

# --- 4. Legacy overlap: B observed a dead legacy `pid`; a 5.36.1 client ------
# republishes a live one. B takes the file, sees it isn't the dead owner's,
# and must hand it straight back.
R5="$T/repo5"
git init -q "$R5"
printf '# l\n' > "$R5/legacy.md"
mkdir -p "$R5/.srepowers/sdd/legacy.claim"
dead_pid > "$R5/.srepowers/sdd/legacy.claim/pid"
why=$(overlap w5 "$R5" "$R5/.srepowers/sdd/legacy.claim" legacy.md)
if [ -z "$why" ]; then
    pass "legacy overlap: a republished live pid is handed back"
else
    fail "legacy overlap: a republished live pid is handed back ($why)"
    diag w5
fi

# --- 5. A live process of ANOTHER user (kill -0 → EPERM) is alive ------------
# pid 1 is root's init: only discriminating when the test is not root. The
# worker must reach the liveness check with owner 1, never enter the reclaim
# branch, and wait until its timeout (rc 124) with the claim untouched.
if [ "$(id -u)" -eq 0 ]; then
    echo "  [SKIP] foreign-user live owner (running as root: kill -0 1 succeeds)"
else
    R4="$T/repo4"
    git init -q "$R4"
    printf '# f\n' > "$R4/foreign.md"
    L4="$R4/.srepowers/sdd/foreign.claim"
    mkdir -p "$L4"; : > "$L4/owner.1"
    run_worker w4 "$R4" foreign.md 2 SDD_SEEN_MARK="$T/w4.seen" SDD_REAP_MARK="$T/w4.reap"
    wait
    if [[ "$(cat "$T/w4.rc")" == 124 && "$(head -1 "$T/w4.seen" 2>/dev/null)" == 1 \
        && ! -e "$T/w4.reap" && -e "$L4/owner.1" ]]; then
        pass "foreign-user live owner (EPERM) is not reclaimed"
    else
        fail "foreign-user live owner (EPERM) is not reclaimed"
        echo "    seen owner: $(head -1 "$T/w4.seen" 2>/dev/null || echo '<never reached the check>'), reclaim branch entered: $([ -e "$T/w4.reap" ] && echo yes || echo no)"
        diag w4
    fi
fi

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
echo "[PASS] sdd-workspace dead-owner reclaim is by identity"
