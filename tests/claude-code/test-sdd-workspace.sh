#!/usr/bin/env bash
# Tests for the SDD workspace: the sdd-workspace helper resolves a self-ignoring
# working-tree directory for SDD artifacts, and the task-brief and review-package
# scripts write into it. A linked worktree resolves its own distinct workspace
# (parity with superpowers v6.0.3 per-worktree isolation).
#
# The workspace is plan-scoped (superpowers v6.2.0 parity): each plan owns
# .srepowers/sdd/<plan-basename>/, so a follow-up plan in the same working tree
# can never read the previous plan's ledger as its own progress.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDD_SCRIPTS="$REPO_ROOT/plugins/srepowers-core/skills/subagent-driven-operation/scripts"
NS=".srepowers/sdd"

FAILURES=0
TEST_ROOT=""

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

main() {
    echo "=== Test: sdd-workspace ==="

    TEST_ROOT="$(mktemp -d)"
    trap cleanup EXIT

    # Resolve repo to its physical path so string comparisons match the
    # helper's output (git rev-parse --show-toplevel resolves symlinks).
    git init -q -b main "$TEST_ROOT/repo"
    local repo
    repo="$(cd "$TEST_ROOT/repo" && git rev-parse --show-toplevel)"

    cat > "$repo/plan.md" <<'PLAN'
# Plan

## Task 1: First thing

Do the first thing.
PLAN
    cat > "$repo/other-plan.md" <<'PLAN'
# Other Plan

## Task 1: Different thing

Do a different thing.
PLAN
    mkdir -p \
        "$repo/docs/alpha" "$repo/docs/beta" \
        "$repo/docs/legacy-a" "$repo/docs/legacy-b" \
        "$repo/docs/race-a/team" "$repo/docs/race-b/team" \
        "$repo/docs/orphan" "$repo/docs/stale"
    printf '# Alpha plan\n' > "$repo/docs/alpha/plan.md"
    printf '# Beta plan\n' > "$repo/docs/beta/plan.md"
    printf '# Legacy alpha plan\n' > "$repo/docs/legacy-a/legacy.md"
    printf '# Legacy beta plan\n' > "$repo/docs/legacy-b/legacy.md"
    printf '# Race alpha plan\n' > "$repo/docs/race-a/team/plan.md"
    printf '# Race beta plan\n' > "$repo/docs/race-b/team/plan.md"
    printf '# Orphan plan\n' > "$repo/docs/orphan/orphan.md"
    printf '# Stale-lock plan\n' > "$repo/docs/stale/stale.md"

    local dir
    dir="$(cd "$repo" && bash "$SDD_SCRIPTS/sdd-workspace" plan.md)"

    if [[ "$dir" == "$repo/$NS/plan" ]]; then
        pass "prints <repo-root>/$NS/<plan-basename>"
    else
        fail "prints <repo-root>/$NS/<plan-basename>"
        echo "    got: $dir"
    fi

    # The point of plan-scoping: a second plan gets its own directory, so its
    # ledger can never be misread as this plan's progress.
    local other_dir
    other_dir="$(cd "$repo" && bash "$SDD_SCRIPTS/sdd-workspace" other-plan.md)"
    if [[ "$other_dir" == "$repo/$NS/other-plan" && "$other_dir" != "$dir" ]]; then
        pass "a second plan resolves a distinct workspace"
    else
        fail "a second plan resolves a distinct workspace"
        echo "    plan:  $dir"
        echo "    other: $other_dir"
    fi

    # Plans with the same basename but different paths must not collide.
    local alpha_dir beta_dir
    alpha_dir="$(cd "$repo" && bash "$SDD_SCRIPTS/sdd-workspace" docs/alpha/plan.md)"
    beta_dir="$(cd "$repo" && bash "$SDD_SCRIPTS/sdd-workspace" docs/beta/plan.md)"
    if [[ "$alpha_dir" != "$beta_dir" \
        && "$(cat "$alpha_dir/plan-path" 2>/dev/null)" == "docs/alpha/plan.md" \
        && "$(cat "$beta_dir/plan-path" 2>/dev/null)" == "docs/beta/plan.md" ]]; then
        pass "same-basename plans resolve distinct owned workspaces"
    else
        fail "same-basename plans resolve distinct owned workspaces"
        echo "    alpha: $alpha_dir"
        echo "    beta:  $beta_dir"
    fi

    # A foreign marker-less legacy ledger must not be adopted by whichever
    # same-basename plan happens to resolve first.
    mkdir -p "$repo/$NS/legacy"
    printf '# SDO ledger — plan: docs/legacy-a/legacy.md\n' \
        > "$repo/$NS/legacy/progress.md"
    local legacy_b_dir legacy_a_dir
    legacy_b_dir="$(cd "$repo" && bash "$SDD_SCRIPTS/sdd-workspace" docs/legacy-b/legacy.md)"
    legacy_a_dir="$(cd "$repo" && bash "$SDD_SCRIPTS/sdd-workspace" docs/legacy-a/legacy.md)"
    if [[ "$legacy_a_dir" == "$repo/$NS/legacy" \
        && "$legacy_b_dir" != "$legacy_a_dir" \
        && "$(cat "$legacy_a_dir/plan-path")" == "docs/legacy-a/legacy.md" \
        && "$(cat "$legacy_b_dir/plan-path")" == "docs/legacy-b/legacy.md" ]]; then
        pass "legacy ledger ownership survives reverse-order resolution"
    else
        fail "legacy ledger ownership survives reverse-order resolution"
        echo "    legacy-a: $legacy_a_dir"
        echo "    legacy-b: $legacy_b_dir"
    fi

    # A non-empty marker-less workspace with no ledger has unknown ownership;
    # preserve it and disambiguate rather than overwriting its artifacts.
    mkdir -p "$repo/$NS/orphan"
    printf 'existing report\n' > "$repo/$NS/orphan/task-1-report.md"
    local orphan_dir
    orphan_dir="$(cd "$repo" && bash "$SDD_SCRIPTS/sdd-workspace" docs/orphan/orphan.md)"
    if [[ "$orphan_dir" != "$repo/$NS/orphan" \
        && ! -e "$repo/$NS/orphan/plan-path" \
        && "$(cat "$repo/$NS/orphan/task-1-report.md")" == "existing report" ]]; then
        pass "non-empty ownerless workspace is preserved and disambiguated"
    else
        fail "non-empty ownerless workspace is preserved and disambiguated"
        echo "    resolved: $orphan_dir"
    fi

    # A dead claimant must not block future runs forever.
    mkdir -p "$repo/$NS/stale.claim"
    printf '99999999\n' > "$repo/$NS/stale.claim/pid"
    local stale_dir
    stale_dir="$(cd "$repo" && timeout 15s bash "$SDD_SCRIPTS/sdd-workspace" docs/stale/stale.md)"
    if [[ "$stale_dir" == "$repo/$NS/stale" && ! -e "$repo/$NS/stale.claim" ]]; then
        pass "stale claim lock is recovered"
    else
        fail "stale claim lock is recovered"
        echo "    resolved: $stale_dir"
    fi

    # Competing claims for the same basename and same parent-directory name
    # must serialize; otherwise both calls can return one shared workspace.
    local race_a_out race_b_out race_a_pid race_b_pid
    race_a_out="$TEST_ROOT/race-a.out"
    race_b_out="$TEST_ROOT/race-b.out"
    ( cd "$repo" && timeout 15s bash "$SDD_SCRIPTS/sdd-workspace" docs/race-a/team/plan.md > "$race_a_out" ) &
    race_a_pid=$!
    ( cd "$repo" && timeout 15s bash "$SDD_SCRIPTS/sdd-workspace" docs/race-b/team/plan.md > "$race_b_out" ) &
    race_b_pid=$!
    local race_failed
    race_failed=0
    wait "$race_a_pid" || race_failed=1
    wait "$race_b_pid" || race_failed=1
    local race_a_dir race_b_dir
    race_a_dir="$(cat "$race_a_out")"
    race_b_dir="$(cat "$race_b_out")"
    if [[ "$race_failed" -eq 0 && "$race_a_dir" != "$race_b_dir" \
        && "$(cat "$race_a_dir/plan-path")" == "docs/race-a/team/plan.md" \
        && "$(cat "$race_b_dir/plan-path")" == "docs/race-b/team/plan.md" ]]; then
        pass "concurrent same-basename claims resolve distinct workspaces"
    else
        fail "concurrent same-basename claims resolve distinct workspaces"
        echo "    race-a: $race_a_dir"
        echo "    race-b: $race_b_dir"
    fi

    # The .gitignore lives at the .srepowers/sdd/ parent so it covers every
    # plan's directory, not just the first one created.
    if [[ -f "$repo/$NS/.gitignore" && "$(cat "$repo/$NS/.gitignore")" == "*" ]]; then
        pass "self-ignoring .gitignore created with '*' at the sdd/ parent"
    else
        fail "self-ignoring .gitignore created with '*' at the sdd/ parent"
    fi

    # A missing plan file is a usage error, not a silently-created workspace.
    local rc=0
    ( cd "$repo" && bash "$SDD_SCRIPTS/sdd-workspace" no-such-plan.md ) >/dev/null 2>&1 || rc=$?
    if [[ "$rc" -eq 2 ]]; then
        pass "missing plan file exits 2"
    else
        fail "missing plan file exits 2 (got $rc)"
    fi

    rc=0
    ( cd "$repo" && bash "$SDD_SCRIPTS/sdd-workspace" ) >/dev/null 2>&1 || rc=$?
    if [[ "$rc" -eq 2 ]]; then
        pass "missing PLAN_FILE argument exits 2"
    else
        fail "missing PLAN_FILE argument exits 2 (got $rc)"
    fi

    # Commit the plan files first: the assertions below are about the workspace
    # being invisible, so untracked test fixtures must not be the thing seen.
    local git_id=(-c user.email=t@example.com -c user.name=t -c commit.gpgsign=false)
    ( cd "$repo" && git add plan.md other-plan.md docs && git "${git_id[@]}" commit -qm plans )

    printf 'x\n' > "$dir/artifact.md"
    local status
    status="$(cd "$repo" && git status --porcelain)"
    if [[ -z "$status" ]]; then
        pass "workspace invisible to git status"
    else
        fail "workspace invisible to git status"
        echo "    status: $status"
    fi

    ( cd "$repo" && git add -A )
    local staged
    staged="$(cd "$repo" && git diff --cached --name-only)"
    if [[ -z "$staged" ]]; then
        pass "git add -A does not stage the workspace"
    else
        fail "git add -A does not stage the workspace"
        echo "    staged: $staged"
    fi

    local brief_out brief_path
    brief_out="$(cd "$repo" && bash "$SDD_SCRIPTS/task-brief" plan.md 1)"
    brief_path="$(printf '%s\n' "$brief_out" | sed -n 's/^wrote \(.*\): [0-9][0-9]* lines$/\1/p')"
    case "$brief_path" in
        "$dir/"*) pass "task-brief writes its brief under the plan's workspace" ;;
        *)
            fail "task-brief writes its brief under the plan's workspace"
            echo "    got:  $brief_path"
            echo "    want: $dir/..."
            ;;
    esac

    ( cd "$repo" \
        && printf 'y\n' > f && git add f \
        && git "${git_id[@]}" commit -qm c2 )
    local rp_out rp_path
    rp_out="$(cd "$repo" && bash "$SDD_SCRIPTS/review-package" plan.md HEAD~1 HEAD)"
    rp_path="$(printf '%s\n' "$rp_out" | sed -n 's/^wrote \(.*\): [0-9].*$/\1/p')"
    case "$rp_path" in
        "$dir/"*) pass "review-package writes its diff under the plan's workspace" ;;
        *)
            fail "review-package writes its diff under the plan's workspace"
            echo "    got:  $rp_path"
            echo "    want: $dir/..."
            ;;
    esac

    rc=0
    ( cd "$repo" && bash "$SDD_SCRIPTS/review-package" plan.md HEAD HEAD ) >/dev/null 2>&1 || rc=$?
    if [[ "$rc" -eq 3 ]]; then
        pass "review-package rejects an empty BASE..HEAD range"
    else
        fail "review-package rejects an empty BASE..HEAD range (got $rc)"
    fi

    local side_sha
    side_sha="$(cd "$repo" && printf 'unrelated\n' | git "${git_id[@]}" commit-tree "$(git write-tree)")"
    rc=0
    ( cd "$repo" && bash "$SDD_SCRIPTS/review-package" plan.md HEAD "$side_sha" ) >/dev/null 2>&1 || rc=$?
    if [[ "$rc" -eq 3 ]]; then
        pass "review-package rejects a HEAD not descended from BASE"
    else
        fail "review-package rejects a HEAD not descended from BASE (got $rc)"
    fi

    # --- Worktree isolation: a linked worktree resolves its own workspace ---
    local wt="$TEST_ROOT/wt"
    ( cd "$repo" && git worktree add -q "$wt" -b wt-feature )
    local wt_root wt_dir
    wt_root="$(cd "$wt" && git rev-parse --show-toplevel)"
    wt_dir="$(cd "$wt" && bash "$SDD_SCRIPTS/sdd-workspace" plan.md)"
    if [[ "$wt_dir" == "$wt_root/$NS/plan" && "$wt_dir" != "$dir" ]]; then
        pass "linked worktree resolves its own distinct workspace"
    else
        fail "linked worktree resolves its own distinct workspace"
        echo "    main: $dir"
        echo "    wt:   $wt_dir"
    fi

    printf 'y\n' > "$wt_dir/artifact.md"
    local wt_status
    wt_status="$(cd "$wt" && git status --porcelain)"
    if [[ -z "$wt_status" ]]; then
        pass "worktree workspace invisible to git status"
    else
        fail "worktree workspace invisible to git status"
        echo "    status: $wt_status"
    fi

    echo ""
    if [[ "$FAILURES" -ne 0 ]]; then
        echo "FAILED: $FAILURES assertion(s)."
        exit 1
    fi
    echo "PASS"
}

main "$@"
