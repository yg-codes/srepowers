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

    local dir
    dir="$(cd "$repo" && "$SDD_SCRIPTS/sdd-workspace" plan.md)"

    if [[ "$dir" == "$repo/$NS/plan" ]]; then
        pass "prints <repo-root>/$NS/<plan-basename>"
    else
        fail "prints <repo-root>/$NS/<plan-basename>"
        echo "    got: $dir"
    fi

    # The point of plan-scoping: a second plan gets its own directory, so its
    # ledger can never be misread as this plan's progress.
    local other_dir
    other_dir="$(cd "$repo" && "$SDD_SCRIPTS/sdd-workspace" other-plan.md)"
    if [[ "$other_dir" == "$repo/$NS/other-plan" && "$other_dir" != "$dir" ]]; then
        pass "a second plan resolves a distinct workspace"
    else
        fail "a second plan resolves a distinct workspace"
        echo "    plan:  $dir"
        echo "    other: $other_dir"
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
    ( cd "$repo" && "$SDD_SCRIPTS/sdd-workspace" no-such-plan.md ) >/dev/null 2>&1 || rc=$?
    if [[ "$rc" -eq 2 ]]; then
        pass "missing plan file exits 2"
    else
        fail "missing plan file exits 2 (got $rc)"
    fi

    rc=0
    ( cd "$repo" && "$SDD_SCRIPTS/sdd-workspace" ) >/dev/null 2>&1 || rc=$?
    if [[ "$rc" -eq 2 ]]; then
        pass "missing PLAN_FILE argument exits 2"
    else
        fail "missing PLAN_FILE argument exits 2 (got $rc)"
    fi

    # Commit the plan files first: the assertions below are about the workspace
    # being invisible, so untracked test fixtures must not be the thing seen.
    local git_id=(-c user.email=t@example.com -c user.name=t -c commit.gpgsign=false)
    ( cd "$repo" && git add plan.md other-plan.md && git "${git_id[@]}" commit -qm plans )

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
    brief_out="$(cd "$repo" && "$SDD_SCRIPTS/task-brief" plan.md 1)"
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
    rp_out="$(cd "$repo" && "$SDD_SCRIPTS/review-package" plan.md HEAD~1 HEAD)"
    rp_path="$(printf '%s\n' "$rp_out" | sed -n 's/^wrote \(.*\): [0-9].*$/\1/p')"
    case "$rp_path" in
        "$dir/"*) pass "review-package writes its diff under the plan's workspace" ;;
        *)
            fail "review-package writes its diff under the plan's workspace"
            echo "    got:  $rp_path"
            echo "    want: $dir/..."
            ;;
    esac

    # --- Worktree isolation: a linked worktree resolves its own workspace ---
    local wt="$TEST_ROOT/wt"
    ( cd "$repo" && git worktree add -q "$wt" -b wt-feature )
    local wt_root wt_dir
    wt_root="$(cd "$wt" && git rev-parse --show-toplevel)"
    wt_dir="$(cd "$wt" && "$SDD_SCRIPTS/sdd-workspace" plan.md)"
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
