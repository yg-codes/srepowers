#!/usr/bin/env bash
# Test: sdd-workspace claim locking survives scheduling stalls mid-acquire.
# Regression for the CI flake (run 40462625497 et al.): two same-basename
# claimants stalled by CPU-throttled runners could both resolve the SAME
# workspace (both printed plan-team, plus rmdir ENOENT on the .claim dirs)
# because the claim was published empty and stolen under its owner.
#
# Deterministic: the stall is INJECTED into a copy of the real script at the
# exact windows that were unsafe (claim-publish gap; marker-write gap), so the
# interleave does not depend on runner load. Hermetic: everything under mktemp.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REAL="$REPO_ROOT/plugins/srepowers-core/skills/subagent-driven-operation/scripts/sdd-workspace"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

echo "=== Test: sdd-workspace claim locking survives mid-acquire stalls ==="

FAIL=0
pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

# make_repo <dir>: a git repo with the same-basename race fixtures and the
# root plan.md pre-state that makes both racers fall through to -team.
make_repo() {
    git init -q "$1"
    mkdir -p "$1/docs/race-a/team" "$1/docs/race-b/team"
    printf '# a\n' > "$1/docs/race-a/team/plan.md"
    printf '# b\n' > "$1/docs/race-b/team/plan.md"
    printf '# root\n' > "$1/plan.md"
    ( cd "$1" && bash "$REAL" plan.md ) >/dev/null
}

# inject_stalls <src> <dst>: patch a COPY with sleep hooks at the windows that
# were unsafe. Idempotent per pattern: the pre-fix script has a claim-publish
# gap (mkdir-then-pid) and every version has a marker-write gap; the fixed
# script additionally exposes a post-publish point that must be stall-safe.
inject_stalls() {
    python3 - "$1" "$2" <<'PYEOF'
import sys
src, dst = sys.argv[1], sys.argv[2]
s = open(src).read()
patched = []
# (a) PRE-FIX claim-publish gap: between the mkdir loop and the pid write.
needle_a = "  done\n  held_lock=$lock"
if needle_a in s:
    s = s.replace(needle_a,
        "  done\n"
        "  if [ \"${SDD_STALL_LOCK:-}\" = \"$lock\" ]; then sleep \"${SDD_STALL_MS:-1.2}\"; fi\n"
        "  held_lock=$lock", 1)
    patched.append("claim-publish-gap")
# (b) FIXED post-publish point: a stall AFTER the claim is atomically
# published must be harmless — patch it if the shape is present.
needle_b = '    if mv -T "$claim" "$lock" 2>/dev/null; then'
if needle_b in s:
    s = s.replace(needle_b,
        needle_b + "\n"
        "      if [ \"${SDD_STALL_LOCK:-}\" = \"$lock\" ]; then sleep \"${SDD_STALL_MS:-1.2}\"; fi", 1)
    patched.append("post-publish")
# (c) marker-write gap, pre-fix shape: between workspace creation and the
# plan-path write.
needle_c = "    mkdir -p \"$workspace\"\n    printf '%s\\n' \"$plan_id\" > \"$workspace/plan-path\""
if needle_c in s:
    s = s.replace(needle_c,
        "    mkdir -p \"$workspace\"\n"
        "    if [ \"${SDD_STALL_WS:-}\" = \"1\" ]; then sleep \"${SDD_STALL_WS_MS:-0.6}\"; fi\n"
        "    printf '%s\\n' \"$plan_id\" > \"$workspace/plan-path\"", 1)
    patched.append("marker-gap")
# (c') marker-write gap, fixed shape: between workspace creation and the
# atomic marker write.
needle_d = '    mkdir -p "$workspace"\n    # Marker write is atomic'
if needle_d in s:
    s = s.replace(needle_d,
        '    mkdir -p "$workspace"\n'
        '    if [ "${SDD_STALL_WS:-}" = "1" ]; then sleep "${SDD_STALL_WS_MS:-0.6}"; fi\n'
        '    # Marker write is atomic', 1)
    patched.append("marker-gap-fixed")
open(dst, "w").write(s)
print("patched:" + ",".join(patched) if patched else "patched:none")
PYEOF
}

# run_race <script> <repo> <a-stall-lock> <b-stall-lock> <ws-stall:0|1>
# Sets the interleave that broke CI, staggered so every ordering decision
# has ≥ 1s of margin and does not depend on scheduler luck:
#   t=0.0  A acquires plan.claim, stalls 3.0s in the pre-pid window
#     (pre-fix shape) / post-publish (fixed shape — must be stall-safe).
#   t=0.5  B starts; steals A's empty claim at ≈1.5s, finds plan foreign,
#     acquires plan-team.claim, stalls 4.0s in its pre-pid window.
#   t≈3.1  A wakes; its pid write fails (claim stolen+released) — pre-fix
#     degrades to "owned by another"; A falls to plan-team.claim and steals
#     B's still-empty claim at ≈4.1s (1.5s before B's pid lands at 5.65).
#   t≈5.7  B wakes, clobbers the pid (pre-fix), sees the workspace A created
#     but still marker-less (A stalls 2.5s before its marker write), adopts
#     it — both resolve plan-team. On the fixed script every one of these
#   steals is impossible and the race serializes into distinct workspaces.
run_race() {
    local script=$1 repo=$2
    SDD_STALL_LOCK="$repo/.srepowers/sdd/plan.claim" SDD_STALL_MS=3.0 \
      SDD_STALL_WS=1 SDD_STALL_WS_MS=2.5 \
      bash "$script" docs/race-a/team/plan.md > "$T/a.out" 2> "$T/a.err" & local pa=$!
    sleep 0.5
    SDD_STALL_LOCK="$repo/.srepowers/sdd/plan-team.claim" SDD_STALL_MS=4.0 \
      bash "$script" docs/race-b/team/plan.md > "$T/b.out" 2> "$T/b.err" & local pb=$!
    wait "$pa"; wait "$pb"
}

check_race() {  # <repo> <label>
    local repo=$1 label=$2 a b
    a=$(cat "$T/a.out"); b=$(cat "$T/b.out")
    if [[ "$a" != "$b" \
        && "$(cat "$a/plan-path")" == "docs/race-a/team/plan.md" \
        && "$(cat "$b/plan-path")" == "docs/race-b/team/plan.md" ]]; then
        pass "$label"
    else
        fail "$label"
        echo "    race-a: $a"
        echo "    race-b: $b"
        sed 's/^/    stderr: /' "$T/a.err" "$T/b.err" 2>/dev/null | head -6
    fi
}

# The patched helper resolves its execution tree through a sibling script.
cp "$(dirname "$REAL")/sdd-repo" "$T/sdd-repo"
inject_stalls "$REAL" "$T/sdd-stalled"
echo "  (injection profile: $(python3 -c "print(open('$T/sdd-stalled').read().count('SDD_STALL_LOCK'))") stall hooks active)"

# Scenario 1 — the CI interleave, deterministically stalled.
make_repo "$T/repo1"
( cd "$T/repo1" && run_race "$T/sdd-stalled" "$T/repo1" )
check_race "$T/repo1" "stalled claimants resolve distinct workspaces"

# Scenario 2 — no leftover claimant scratch dirs after the race (cleanup trap).
stray=$(find "$T/repo1/.srepowers/sdd" -maxdepth 1 -name '*.claimant.*' | head -3)
if [ -z "$stray" ]; then
    pass "no leftover claimant scratch dirs"
else
    fail "no leftover claimant scratch dirs"
    echo "    stray: $stray"
fi

# Scenario 3 — soak: the unpatched race, 20 rounds on fresh repos; every
# round must resolve distinct workspaces (guards residual nondeterminism).
soak_fail=0
for i in $(seq 1 20); do
    rm -rf "$T/soak"; make_repo "$T/soak"
    ( cd "$T/soak" && run_race "$REAL" "$T/soak" ) || soak_fail=1
    a=$(cat "$T/a.out"); b=$(cat "$T/b.out")
    if [[ "$a" == "$b" || "$(cat "$a/plan-path" 2>/dev/null)" != "docs/race-a/team/plan.md" \
        || "$(cat "$b/plan-path" 2>/dev/null)" != "docs/race-b/team/plan.md" ]]; then
        soak_fail=1
        echo "    soak round $i: a=$a b=$b"
    fi
done
if [ "$soak_fail" -eq 0 ]; then
    pass "20-round unstalled soak keeps workspaces distinct"
else
    fail "20-round unstalled soak keeps workspaces distinct"
fi

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
echo "[PASS] sdd-workspace claim locking survives mid-acquire stalls"
