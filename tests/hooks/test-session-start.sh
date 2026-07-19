#!/usr/bin/env bash
set -euo pipefail

# SessionStart hook output tests for SREPowers.
#
# Guards the printf-based emission (no bash 5.3+ heredoc hang, upstream #571)
# and the run-hook.cmd polyglot wrapper that makes the hook fire on Windows
# Git-Bash as well as Unix. srepowers targets Claude Code + Codex (nested
# hookSpecificOutput shape) with an SDK-standard fallback for Copilot/unknown.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK_DIR="$REPO_ROOT/plugins/srepowers-core/hooks"
HOOK_UNDER_TEST="$HOOK_DIR/session-start"
WRAPPER_UNDER_TEST="$HOOK_DIR/run-hook.cmd"

FAILURES=0
TEST_ROOT="$(mktemp -d)"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

pass() {
    echo "  [PASS] $1"
}

fail() {
    echo "  [FAIL] $1"
    FAILURES=$((FAILURES + 1))
}

make_home() {
    local name="$1"
    local home="$TEST_ROOT/$name/home"
    mkdir -p "$home"
    printf '%s\n' "$home"
}

assert_command_output() {
    local description="$1"
    local shape="$2"
    local contains="$3"
    local not_contains="$4"
    local home="$5"
    shift 5

    local output
    if ! output="$(env -i PATH="${PATH:-}" HOME="$home" "$@" 2>&1)"; then
        fail "$description"
        echo "    hook exited non-zero"
        echo "$output" | sed 's/^/      /'
        return
    fi

    if printf '%s' "$output" | \
        EXPECT_SHAPE="$shape" \
        EXPECT_CONTAINS="$contains" \
        EXPECT_NOT_CONTAINS="$not_contains" \
        node -e '
const fs = require("fs");

const input = fs.readFileSync(0, "utf8");
let payload;
try {
  payload = JSON.parse(input);
} catch (error) {
  console.error(`invalid JSON: ${error.message}`);
  process.exit(1);
}

function hasOwn(object, key) {
  return Object.prototype.hasOwnProperty.call(object, key);
}

function fail(message) {
  console.error(message);
  process.exit(1);
}

const shape = process.env.EXPECT_SHAPE;
let context;

if (shape === "nested") {
  if (!hasOwn(payload, "hookSpecificOutput")) {
    fail("missing hookSpecificOutput");
  }
  if (hasOwn(payload, "additional_context") || hasOwn(payload, "additionalContext")) {
    fail("nested output also included a top-level context field");
  }
  const hookOutput = payload.hookSpecificOutput;
  if (!hookOutput || typeof hookOutput !== "object" || Array.isArray(hookOutput)) {
    fail("hookSpecificOutput is not an object");
  }
  if (hookOutput.hookEventName !== "SessionStart") {
    fail(`unexpected hookEventName: ${hookOutput.hookEventName}`);
  }
  context = hookOutput.additionalContext;
} else if (shape === "sdk") {
  if (hasOwn(payload, "hookSpecificOutput")) {
    fail("sdk output included hookSpecificOutput");
  }
  if (!hasOwn(payload, "additionalContext")) {
    fail("sdk output missing additionalContext");
  }
  if (hasOwn(payload, "additional_context")) {
    fail("sdk output included additional_context");
  }
  context = payload.additionalContext;
} else {
  fail(`unknown expected shape: ${shape}`);
}

if (typeof context !== "string" || context.trim() === "") {
  fail("injected context was empty");
}

const expectedText = process.env.EXPECT_CONTAINS || "";
if (expectedText && !context.includes(expectedText)) {
  fail(`context did not contain expected text: ${expectedText}`);
}

const forbiddenTexts = (process.env.EXPECT_NOT_CONTAINS || "")
  .split("")
  .filter(Boolean);
for (const forbiddenText of forbiddenTexts) {
  if (context.includes(forbiddenText)) {
    fail(`context contained forbidden text: ${forbiddenText}`);
  }
}
'; then
        pass "$description"
    else
        fail "$description"
        echo "    output:"
        echo "$output" | sed 's/^/      /'
    fi
}

echo "SessionStart hook output tests"

claude_home="$(make_home claude-code)"
assert_command_output \
    "Claude Code / Codex emit nested SessionStart additionalContext" \
    "nested" \
    "You have SREPowers" \
    "" \
    "$claude_home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT/plugins/srepowers-core" \
    bash "$HOOK_UNDER_TEST"

wrapper_home="$(make_home run-hook-wrapper)"
assert_command_output \
    "run-hook.cmd wrapper dispatches to the named session-start script" \
    "nested" \
    "using-srepowers" \
    "" \
    "$wrapper_home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT/plugins/srepowers-core" \
    bash "$WRAPPER_UNDER_TEST" session-start

copilot_home="$(make_home copilot-cli)"
assert_command_output \
    "Copilot CLI / unknown emit top-level additionalContext only" \
    "sdk" \
    "You have SREPowers" \
    "" \
    "$copilot_home" \
    COPILOT_CLI=1 \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT/plugins/srepowers-core" \
    bash "$HOOK_UNDER_TEST"

# Regression guard for #571: the emission must be printf-based, so no raw
# heredoc terminator or unescaped delimiter can leak into the JSON payload.
leak_home="$(make_home heredoc-leak-guard)"
assert_command_output \
    "SessionStart output contains no leaked heredoc terminator" \
    "nested" \
    "" \
    $'\nEOF\n' \
    "$leak_home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT/plugins/srepowers-core" \
    bash "$HOOK_UNDER_TEST"

# The source must not reintroduce the heredoc pattern the printf fix replaced.
if grep -qE '^cat[[:space:]]+<<' "$HOOK_UNDER_TEST"; then
    fail "session-start reintroduced a 'cat <<' heredoc (bash 5.3+ hang, #571)"
else
    pass "session-start uses printf, not a 'cat <<' heredoc"
fi

if [[ "$FAILURES" -gt 0 ]]; then
    echo "STATUS: FAILED ($FAILURES failure(s))"
    exit 1
fi

echo "STATUS: PASSED"
