#!/usr/bin/env bash
set -euo pipefail

# PreToolUse guard tests for SREPowers verification-guardrails.
#
# The block-lying-gates hook must deny shell idioms that make a verification
# gate lie — in BOTH directions: a gate that cannot fail (reports PASS while
# broken) and a gate that cannot pass (reports FAIL on a healthy system). It
# reads the PreToolUse event as JSON on stdin and exits 2 on a blocked command,
# 0 otherwise, failing open on malformed/absent input.
#
# The allow-cases matter as much as the block-cases: every pattern here is one
# character away from banning the correct form it prescribes. An earlier
# `.*&&` version of the comm rule blocked `NEW=$(comm -13 a b); [ -z "$NEW" ]`
# — exactly what the rule tells you to write.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK_DIR="$REPO_ROOT/plugins/srepowers-core/hooks"
HOOK_UNDER_TEST="$HOOK_DIR/block-lying-gates"
WRAPPER_UNDER_TEST="$HOOK_DIR/run-hook.cmd"

FAILURES=0

pass() {
    echo "  [PASS] $1"
}

fail() {
    echo "  [FAIL] $1"
    FAILURES=$((FAILURES + 1))
}

# Feed a command through the hook as a PreToolUse event and assert the exit
# code. jq -Rs turns the command into a JSON string literal so quoting inside
# the command never breaks the payload.
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
# cases.
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

# `&&` is assembled at runtime so this file never contains a literal lying
# idiom on a line an active copy of the hook could match if it were ever
# pasted into a shell.
AND="$(printf '%s%s' '&' '&')"

echo "verification-guardrails PreToolUse hook tests"

echo " Blocked — gates that cannot fail (exit 2):"
assert_exit "comm && echo PASS"        2 "comm -13 before.txt after.txt $AND echo PASS"
assert_exit "comm -3 && echo ok"       2 "comm -3 a b $AND echo ok"
# Same §2.2 defect, other tool: bare `diff` also exits 0 while printing
# differences (exit 1 means "differed", and `&&` never sees it). The local
# Python hook matched `(comm|diff)` from the start; this one matched `comm`
# only, which was the last hook-parity gap — closed here.
assert_exit "diff && echo PASS"        2 "diff a b $AND echo PASS"
assert_exit "tee then echo \$?"        2 'sudo dnf upgrade -y | tee /tmp/apply.log; echo "rc=$?"'
assert_exit "head then rc=\$?"         2 'git status --cached | head -2; rc=$?'
assert_exit "tail then echo \$?"       2 'make build | tail -5; echo $?'
assert_exit "sudo ls privileged glob"  2 'ssh host "sudo ls /boot/loader/entries/*.conf | wc -l"'
assert_exit "sudo cat privileged glob" 2 'sudo cat /boot/loader/entries/*.conf'
assert_exit "sudo grep ssh_host glob"  2 'sudo grep -l x /etc/ssh/ssh_host*'
# §2.5's other half: the glob expands in the unprivileged OUTER shell before
# the loop body's sudo runs, so over a mode-700 path the loop iterates zero
# times and reports clean. Ported from the local Python hook's rule 3; the
# `privileged loop done right` allow case below pins the prescribed fix.
assert_exit "for-loop glob, sudo body" 2 'for e in /boot/loader/entries/*.conf; do sudo test -f "$e"; done'
assert_exit "grep -v Error denylist"   2 'ldapsearch -x | grep -v "Error (1)" | grep "Error (0)"'
assert_exit "grep -v FAIL denylist"    2 'cat report.txt | grep -v FAIL'

echo " Blocked — gates that cannot pass (exit 2):"
# (The trailing-slash pointer and aligned Return-Code deny cases were removed
# with the §2.9 rules — those forms are now prose-only advice; see the
# "§2.9 rules retired" allow section below.)
assert_exit "is-active | grep active"  2 'systemctl is-active puppetserver | grep -q active'

echo " Allowed — the correct forms these rules prescribe (exit 0):"
# Each of these is the fix the corresponding block message recommends. If a
# pattern ever starts matching one of them, the guard is banning its own advice.
assert_exit "capture-and-test comm"    0 "NEW=\$(comm -13 <(sort -u before.txt) <(sort -u after.txt)); [ -z \"\$NEW\" ] $AND echo PASS || echo FAIL"
# The same prescribed fix written with `diff`. Pinned alongside the widening of
# the §2.2 rule to (comm|diff): the rule must ban the unconditional-PASS form
# without banning the capture-and-test form it tells you to write instead.
assert_exit "capture-and-test diff"    0 "D=\$(diff a b); [ -z \"\$D\" ] $AND echo PASS"
# The false-positive guard for the diff widening: `git diff` in an
# informational chain with a non-PASS success token must stay allowed. The
# diff alternative deliberately requires the literal token PASS (comm keeps
# the wider OK/ok/pass set) — see the rule's comment in the hook.
assert_exit "git diff informational"   0 "git diff --stat HEAD~1 $AND echo ok"
assert_exit "PIPESTATUS"               0 'sudo dnf upgrade -y | tee /tmp/apply.log; rc=${PIPESTATUS[0]}'
assert_exit "privileged loop done right" 0 'sudo bash -c "shopt -s nullglob; N=0; for e in /boot/loader/entries/*.conf; do N=$((N+1)); done; [ $N -eq 0 ] && exit 9"'
assert_exit "end-anchored pointer"     0 'grep -c "/uat$" /etc/yum.repos.d/rocky.repo'
assert_exit "flexible-separator"       0 'sudo dnf history info last | grep -qE "Return-Code *: *Success"'
assert_exit "is-active --quiet"        0 'systemctl is-active --quiet puppetserver'
assert_exit "is-active exact compare"  0 "[ \"\$(systemctl is-active puppetserver)\" = active ] $AND echo PASS"
assert_exit "allowlist success value"  0 "grep -qE \"Error \\(0\\)\" /tmp/repl.txt $AND echo PASS"

echo " Allowed — ordinary commands that resemble the patterns (exit 0):"
assert_exit "truncation for volume"    0 'journalctl -u squid --since -1h | tail -50'
assert_exit "tee without reading \$?"  0 'dnf upgrade --assumeno | tee /tmp/plan.txt'
assert_exit "grep -v ordinary filter"  0 'grep -v "^#" /etc/hosts'
assert_exit "sudo ls no glob"          0 'sudo ls -la /boot/loader/entries/'
assert_exit "comm without && echo"     0 'comm -13 a b > /tmp/new.txt'
assert_exit "ordinary git push"        0 'git push origin main'
assert_exit "plain rg search"          0 'rg -n "PASS" rules/'
assert_exit "systemctl status"         0 'systemctl status puppetserver'
assert_exit "head for volume only"     0 'ls -la | head -20'

echo " Blocked — prose containment bypass pins (exit 2):"
# Task 2 adds prose containment: the idiom text inside a quoted payload or
# heredoc body must be allowed, but the idiom itself in open command position
# must still be denied. These pin that the containment cannot be used to
# smuggle a live gate past the guard — including the sandwich: heredoc
# stripping ends at the FIRST terminator line, so a gate sitting between two
# doc heredocs survives the strip (a greedy last-terminator strip swallowed
# it; found in review, round 1).
assert_exit "commit msg then open idiom" 2 "git commit -m \"wip\" $AND comm -13 a b $AND echo PASS"
assert_exit "plain comm lying gate"      2 "comm -13 /tmp/t1 /tmp/t2 $AND echo PASS"
assert_exit "gate sandwiched between doc heredocs" 2 "cat >> docs/a.md <<'EOF'
docs text
EOF
comm -13 /tmp/b1 /tmp/b2 $AND echo PASS
cat >> docs/b.md <<'EOF'
more docs
EOF"

echo " Allowed — prose containment + §2.9 rules retired (exit 0):"
# Task 2 target behavior, pinned BEFORE the hook changes. Cases 1-2: the
# idiom appears as PROSE (a commit-message payload, a heredoc body redirected
# into a doc) — the current hook matches the text anywhere and denies these.
# Cases 3-4: §2.9 forms the hook cannot express reliably — Task 2 retires
# both rules (see the retired-rule comments in the hook's rules array) and
# these allow; the end-anchored and flexible-separator forms above remain
# the prescribed fix.
assert_exit "idiom as prose in commit msg" 0 "git commit -m \"docs: never write comm -13 a b $AND echo PASS inside a gate\""
assert_exit "idiom as prose in heredoc"    0 "cat >> docs/notes.md <<'EOF'
grep -v 'Error (1)' somewhere
EOF"
assert_exit "two doc heredocs, prose in both bodies" 0 "cat >> docs/a.md <<'EOF'
never write comm -13 x y $AND echo PASS
EOF
cat >> docs/b.md <<'EOF'
or grep -v 'Error (1)' inside a gate
EOF"
assert_exit "trailing-slash pointer retired" 0 'grep -c "/uat/" /etc/yum.repos.d/app.repo'
assert_exit "aligned Return-Code retired"    0 'grep -q "Return-Code: Success" /tmp/tx.log'
# Heredoc-opener variants the FSM regex handles but nothing pinned (added
# 5.20.1 per final-review triage — "one character away" from the pinned
# plain form). The terminator must be the exact line `EOF` at column 0.
assert_exit "quoted opener heredoc prose" 0 "cat >> docs/q.md <<'EOF'
never write comm -13 x y $AND echo PASS
EOF"
assert_exit "dash-opener heredoc prose"   0 "cat >> docs/d.md <<-EOF
or grep -v 'Error (1)' inside a gate
EOF"
# Same dash opener with a TAB-indented terminator. Measured, not assumed: the
# exact-line `^EOF$` requirement means the tab form never terminates, so the
# awk treats the heredoc as UNTERMINATED and drops everything after the opener
# — and the Python original's `(?:\nEOF|$)` fallback strips identically. Both
# hooks allow; pinned so the agreement is visible. (An earlier draft of this
# pin asserted DENY from reading the "strips less" comment — wrong direction.)
TAB="$(printf '\t')"
assert_exit "tab-terminated heredoc allows" 0 "cat >> docs/t.md <<-EOF
${TAB}comm -13 x y $AND echo PASS
${TAB}EOF"

echo " Fail-open (exit 0):"
assert_raw_exit "empty stdin"          0 ""
assert_raw_exit "malformed json"       0 "not json at all"
assert_raw_exit "no command field"     0 '{"tool_input":{}}'
assert_raw_exit "no tool_input"        0 '{"a":1}'

echo " Wrapper dispatch:"
wrapper_rc=0
printf '{"tool_input":{"command":%s}}' "$(printf '%s' "comm -13 a b $AND echo PASS" | jq -Rs .)" \
    | bash "$WRAPPER_UNDER_TEST" block-lying-gates >/dev/null 2>&1 || wrapper_rc=$?
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
