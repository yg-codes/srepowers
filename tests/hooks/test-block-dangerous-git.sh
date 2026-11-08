#!/usr/bin/env bash
set -euo pipefail

# PreToolUse guard tests for SREPowers git-guardrails.
#
# The block-dangerous-git hook must mechanically deny the destructive git
# commands in the SREPowers guardrails while allowing the everyday commands the
# workflow depends on (a normal push is how finishing-operation-branch ships a
# branch). It reads the PreToolUse event as JSON on stdin and exits 2 on a
# blocked command, 0 otherwise, failing open on malformed/absent input.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK_DIR="$REPO_ROOT/plugins/srepowers-core/hooks"
HOOK_UNDER_TEST="$HOOK_DIR/block-dangerous-git"
WRAPPER_UNDER_TEST="$HOOK_DIR/run-hook.cmd"

FAILURES=0

pass() {
    echo "  [PASS] $1"
}

fail() {
    echo "  [FAIL] $1"
    FAILURES=$((FAILURES + 1))
}

# Feed a git command through the hook as a PreToolUse event and assert the
# resulting exit code. jq -Rs turns the command into a JSON string literal so
# quoting inside the command never breaks the payload.
assert_exit() {
    local description="$1"
    local want="$2"
    local command="$3"
    local payload rc
    payload="$(printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$command" | jq -Rs .)")"
    rc=0
    printf '%s' "$payload" | bash "$HOOK_UNDER_TEST" >/dev/null 2>&1 || rc=$?
    if [[ "$rc" -eq "$want" ]]; then
        pass "$description (exit $rc)"
    else
        fail "$description — got exit $rc, want $want  [$command]"
    fi
}

# Feed raw stdin (not a wrapped command) and assert exit code — for fail-open
# and non-git cases.
assert_raw_exit() {
    local description="$1"
    local want="$2"
    local raw="$3"
    local rc=0
    printf '%s' "$raw" | bash "$HOOK_UNDER_TEST" >/dev/null 2>&1 || rc=$?
    if [[ "$rc" -eq "$want" ]]; then
        pass "$description (exit $rc)"
    else
        fail "$description — got exit $rc, want $want"
    fi
}

echo "git-guardrails PreToolUse hook tests"

echo " Blocked (exit 2):"
assert_exit "force push"            2 "git push --force origin main"
assert_exit "force push -f"         2 "git push -f origin main"
assert_exit "force-with-lease"      2 "git push --force-with-lease"
assert_exit "reset --hard"          2 "git reset --hard HEAD~1"
assert_exit "clean -fd"             2 "git clean -fd"
assert_exit "clean -f"             2 "git clean -f"
assert_exit "clean -xdf"            2 "git clean -xdf"
assert_exit "branch -D"             2 "git branch -D feature"
# Flag letter anywhere in the cluster, and with a path argument following —
# the token-boundary fix must not require the letter to be last.
assert_exit "clean -fd with path"   2 "git clean -fd src/"
assert_exit "clean -dfx"            2 "git clean -dfx"
assert_exit "push -fu"              2 "git push -fu origin main"
assert_exit "branch -Dr"            2 "git branch -Dr origin/feature"
assert_exit "checkout ."            2 "git checkout ."
assert_exit "checkout -- ."         2 "git checkout -- ."
assert_exit "restore ."             2 "git restore ."
assert_exit "restore --staged ."    2 "git restore --staged ."
assert_exit "add -A"                2 "git add -A"
assert_exit "add ."                 2 "git add ."
assert_exit "add --all"             2 "git add --all"
assert_exit "commit --no-verify"    2 "git commit --no-verify -m x"

echo " Allowed (exit 0):"
assert_exit "plain push"            0 "git push"
assert_exit "push origin branch"    0 "git push origin feat/x"
assert_exit "push -u"               0 "git push -u origin feat/x"
assert_exit "set-upstream push"     0 "git push --set-upstream origin feat/x"
assert_exit "normal commit"         0 "git commit -m fix"
assert_exit "add explicit file"     0 "git add README.md"
assert_exit "add patch"             0 "git add -p"
assert_exit "add path with dot"     0 "git add src/."
assert_exit "reset --soft"          0 "git reset --soft HEAD~1"
assert_exit "reset path"            0 "git reset HEAD file.txt"
assert_exit "checkout branch"       0 "git checkout main"
assert_exit "checkout file"         0 "git checkout -- README.md"
assert_exit "restore file"          0 "git restore README.md"
assert_exit "clean dry-run"         0 "git clean -n"
assert_exit "clean -d only"         0 "git clean -d"
assert_exit "branch -d safe"        0 "git branch -d merged"
assert_exit "branch -a"             0 "git branch -a"

# Regression: the flag rules used `.*(-[[:alnum:]]*f)` with no token boundary,
# so any hyphenated word ending in the flag letter matched anywhere on the
# line — `-bugf` inside a branch name blocked an ordinary push.
assert_exit "push branch ending f"  0 "git push -u origin fix/superpowers-v620-bugfix-parity"
assert_exit "push branch -conf"     0 "git push origin feat/reload-conf"
assert_exit "clean -d path word f"  0 "git clean -d my-stuff"
assert_exit "branch -d word D"      0 "git branch -d feat/backup-D"
assert_exit "status"                0 "git status"
assert_exit "echo mentions reset"   0 "echo do not reset --hard"

# Regression (5.32.2): rules were anchored on `git <subcommand>`, so any
# global option in between evaded every rule.
echo " Global options do not evade (exit 2):"
assert_exit "-C path reset --hard"      2 "git -C /tmp/wt reset --hard origin/x"
assert_exit "-C quoted path"            2 "git -C \"/tmp/my wt\" reset --hard"
assert_exit "-c key=val push -f"        2 "git -c core.askpass=x push -f origin main"
assert_exit "--git-dir= clean -fd"      2 "git --git-dir=/r/.git --work-tree=/r clean -fd"
assert_exit "--no-pager checkout ."     2 "git --no-pager checkout ."
assert_exit "sudo git -C reset --hard"  2 "sudo git -C /srv/repo reset --hard"
assert_exit "cd && -C chain"            2 "cd / && git -C /tmp/wt reset -q --hard origin/x"

echo " Newly covered (exit 2):"
assert_exit "checkout -f ref"           2 "git checkout -f origin/x"
assert_exit "checkout --force"          2 "git checkout --force main"
assert_exit "switch --discard-changes"  2 "git switch --discard-changes -d origin/x"
assert_exit "switch -f"                 2 "git switch -f main"
assert_exit "worktree remove --force"   2 "git worktree remove --force /tmp/wt"
assert_exit "worktree remove -f"        2 "git -C /r worktree remove -f /tmp/wt"
assert_exit "clean --force"             2 "git clean --force"
assert_exit "force-with-lease=ref"      2 "git push --force-with-lease=main:abc123 origin main"

echo " Newly covered — allowed neighbours (exit 0):"
assert_exit "checkout -b"               0 "git checkout -b feat/fix-f"
assert_exit "switch -c"                 0 "git switch -c feat/x"
assert_exit "switch -d ref"             0 "git switch -d origin/x"
assert_exit "worktree remove plain"     0 "git worktree remove /tmp/wt"
assert_exit "worktree add --detach"     0 "git worktree add --detach /tmp/wt origin/x"
assert_exit "reset --keep"              0 "git -C /tmp/wt reset --keep origin/x"

# Regression (5.32.2): `.*` in a rule crossed command separators, so a flag
# belonging to the NEXT command was read as a git flag.
echo " Flags after a separator belong to the next command (exit 0):"
assert_exit "push && rm -f"             0 "git push origin feat/x && rm -f /tmp/stamp"
assert_exit "checkout ; cp -f"          0 "git checkout main; cp -f a b"
assert_exit "clean -n | xargs rm -f"    0 "git clean -n | xargs rm -f"

# Regression (5.32.2): the raw string was scanned, so text that only MENTIONS
# a dangerous command was denied — searching docs, commit messages, writing
# the docs themselves.
echo " Payload containment — mentions are allowed (exit 0):"
assert_exit "rg pattern"                0 "rg \"git reset --hard\" docs/"
assert_exit "rg flags then pattern"     0 "rg -n -i 'git push --force' plugins/"
assert_exit "grep -e pattern"           0 "grep -rn -e 'git clean -fd' ."
assert_exit "git grep pattern"          0 "git grep -n 'git reset --hard' HEAD~3"
assert_exit "git log -S pattern"        0 "git log -S 'reset --hard' --oneline"
assert_exit "cd && git -C log -S"       0 "cd /r && git -C /r log --grep='git add -A'"
assert_exit "commit -m quoting rule"    0 "git commit -m \"docs: never git reset --hard\""
assert_exit "commit -m single quote"    0 "git commit -m 'fix: block git checkout -f too'"
# shellcheck disable=SC2016  # literal $( ) is the payload under test
assert_exit "commit heredoc message"    0 "$(printf '%s\n' 'git commit -m "$(cat <<'"'"'EOF'"'"'' 'docs: git reset --hard is blocked' 'EOF' ')"')"
assert_exit "heredoc to .txt"           0 "$(printf '%s\n' "cat > /tmp/cases.txt <<'EOF'" 'git -C /tmp/wt reset --hard origin/x' 'EOF' 'wc -l /tmp/cases.txt')"
assert_exit "heredoc to docs/"          0 "$(printf '%s\n' 'cat >> repo/docs/notes <<EOF' 'git push --force' 'EOF')"
assert_exit "heredoc <<- to .md"        0 "$(printf '%s\n' 'cat <<-EOF > notes.md' $'\tgit clean -fd' $'\tEOF')"

# Containment must never become a bypass: anything that can execute stays in.
echo " Payload containment — executable payloads still blocked (exit 2):"
assert_exit "ssh single-quoted"         2 "ssh host 'git reset --hard'"
assert_exit "bash -c double-quoted"     2 "bash -c \"git clean -fd\""
assert_exit "rg ; then reset"           2 "rg 'x' docs/; git reset --hard"
assert_exit "rg && then reset"          2 "rg \"reset\" . && git -C /r reset --hard"
assert_exit "commit -m && reset"        2 "git commit -m \"wip\" && git reset --hard HEAD~1"
assert_exit "rg \$( ) in dquotes"       2 "rg \"\$(git reset --hard)\" ."
assert_exit "commit -m backtick"        2 "git commit -m \"\`git clean -fd\`\""
assert_exit "heredoc to bash"           2 "$(printf '%s\n' 'bash <<EOF' 'git reset --hard' 'EOF')"
assert_exit "heredoc ssh bash -s"       2 "$(printf '%s\n' "ssh h 'bash -s' <<'EOF'" 'git -C /srv reset --hard' 'EOF')"
assert_exit "heredoc to .sh"            2 "$(printf '%s\n' 'cat > /tmp/x.sh <<EOF' 'git reset --hard' 'EOF' 'bash /tmp/x.sh')"
assert_exit "heredoc .md piped"         2 "$(printf '%s\n' 'cat <<EOF | tee notes.md | bash' 'git reset --hard' 'EOF')"
assert_exit "heredoc body then reset"   2 "$(printf '%s\n' 'cat > n.md <<EOF' 'text' 'EOF' 'git reset --hard')"
# shellcheck disable=SC2016  # literal $( ) is the payload under test
assert_exit "bash -c \$(cat heredoc)"   2 "$(printf '%s\n' 'bash -c "$(cat <<EOF' 'git reset --hard' 'EOF' ')"')"
assert_exit "echo pipe to sh"           2 "echo 'git reset --hard' | sh"
# Regression (5.32.2): a flag closed by a quote/backtick/paren had no token
# boundary and passed.
assert_exit "ssh dquoted clean -fd"     2 "ssh host \"git clean -fd\""
assert_exit "bash -c push -f'"          2 "bash -c 'git push -f'"
assert_exit "\$( branch -D )"           2 "x=\$(git branch -D old)"
assert_exit "add -A;"                   2 "git add -A; git commit -m x"

echo " Fail-open / non-git (exit 0):"
assert_raw_exit "empty stdin"       0 ""
assert_raw_exit "malformed json"    0 "not json at all"
assert_raw_exit "no command field"  0 '{"tool_input":{}}'
assert_exit "non-git command"       0 "rm -rf /tmp/scratch"

echo " Wrapper dispatch:"
wrapper_rc=0
printf '{"tool_input":{"command":"git push --force"}}' \
    | bash "$WRAPPER_UNDER_TEST" block-dangerous-git >/dev/null 2>&1 || wrapper_rc=$?
if [[ "$wrapper_rc" -eq 2 ]]; then
    pass "run-hook.cmd wrapper dispatches and denies (exit 2)"
else
    fail "run-hook.cmd wrapper dispatch — got exit $wrapper_rc, want 2"
fi

if [[ "$FAILURES" -gt 0 ]]; then
    echo "STATUS: FAILED ($FAILURES failure(s))"
    exit 1
fi

echo "STATUS: PASSED"
