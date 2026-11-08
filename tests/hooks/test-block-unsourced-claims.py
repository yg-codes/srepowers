#!/usr/bin/env python3
"""Test harness for block-unsourced-claims (opt-in Stop hook).

Weighted toward false positives: a Stop hook that wrongly blocks prevents the
turn from ever finishing, which is worse than a wrongly-denied Bash call. That
asymmetry is also why this hook ships unwired — see the SKILL.md.

Run: python3 tests/hooks/test-block-unsourced-claims.py
"""
import json
import os
import subprocess
import sys
import tempfile

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HOOK = os.path.join(REPO_ROOT, "plugins", "srepowers-core", "hooks",
                    "block-unsourced-claims")
if not os.path.exists(HOOK):
    sys.exit("hook not found: %s" % HOOK)

passed = failed = 0


def mk_transcript(tool_names, with_user_turn=True):
    """Build a minimal transcript whose last turn used `tool_names`."""
    fd, path = tempfile.mkstemp(suffix=".jsonl")
    with os.fdopen(fd, "w") as f:
        if with_user_turn:
            f.write(json.dumps({"type": "user", "message": {"content": "do the thing"}}) + "\n")
        for n in tool_names:
            f.write(json.dumps({
                "type": "assistant",
                "message": {"content": [
                    {"type": "tool_use", "name": n, "input": {"command": "x"}}]}
            }) + "\n")
    return path


def run(msg, tool_names, stop_active=False, transcript="auto"):
    if transcript == "auto":
        transcript = mk_transcript(tool_names)
        cleanup = True
    else:
        cleanup = False
    payload = {
        "hook_event_name": "Stop",
        "last_assistant_message": msg,
        "transcript_path": transcript,
        "stop_hook_active": stop_active,
        "session_id": "test",
    }
    p = subprocess.run([HOOK], input=json.dumps(payload),
                       capture_output=True, text=True)
    if cleanup:
        os.unlink(transcript)
    blocked = False
    if p.stdout.strip():
        try:
            blocked = json.loads(p.stdout).get("decision") == "block"
        except Exception:
            pass
    return blocked, p.stdout, p.stderr


def check(want, desc, msg, tool_names=(), **kw):
    global passed, failed
    blocked, out, err = run(msg, list(tool_names), **kw)
    got = "BLOCK" if blocked else "ALLOW"
    if got == want:
        passed += 1
        print("  ok   %-6s %s" % (got, desc))
    else:
        failed += 1
        print("  FAIL want=%s got=%s  %s" % (want, got, desc))
        print("       msg: %r" % msg[:110])


print("=== TRUE POSITIVES (must BLOCK: claim with no read in the turn) ===")
check("BLOCK", "negative: apply never ran",
      "I checked and the apply never ran on that host.", [])
check("BLOCK", "negative: was not applied",
      "The Puppet change was not applied to web01.", [])
check("BLOCK", "negative: no changes were made",
      "Summary: no changes were made to the fleet.", [])
check("BLOCK", "negative: nothing was committed",
      "Nothing was committed in this session.", [])
check("BLOCK", "perfect tense: I committed",
      "I committed the fix and it is on main now.", [])
check("BLOCK", "perfect tense: I've pushed",
      "I've pushed the branch upstream.", [])
check("BLOCK", "perfect tense: I applied",
      "I applied the catalog on all three nodes.", [])
check("BLOCK", "claim survives when only a non-corroborating tool ran",
      "The upgrade never ran on db01.", ["TodoWrite"])

print()
print("=== TRUE NEGATIVES (must ALLOW) ===")
check("ALLOW", "same claim, but the turn DID read something",
      "I checked and the apply never ran on that host.", ["Bash"])
check("ALLOW", "perfect tense with a Bash call in the turn",
      "I committed the fix and it is on main now.", ["Bash"])
check("ALLOW", "explicit hedge",
      "I have not confirmed whether the apply ran — checking now.", [])
check("ALLOW", "explicit unverified marker",
      "The apply status is unverified; I did not verify it.", [])
check("ALLOW", "question, not a claim",
      "Did the apply never run on that host?", [])
check("ALLOW", "reported speech in a blockquote",
      "> the apply never ran\n\nThat is what the log claims.", [])
check("ALLOW", "claim inside fenced code",
      "```\nthe apply never ran\n```\nThat string appears in the log.", [])
check("ALLOW", "claim inside inline code",
      "The log line `the apply never ran` is a red herring.", [])
check("ALLOW", "recursion guard",
      "I committed the fix.", [], stop_active=True)
check("ALLOW", "empty message",
      "", [])
check("ALLOW", "ordinary prose, no claims",
      "Here are the three options and their tradeoffs. I'd recommend the first.", [])
check("ALLOW", "third-party subject, not first person",
      "The operator applied the change last night.", [])
check("ALLOW", "describing what a rule says",
      "The rule says a negative claim needs the same evidence as a positive one.", [])
check("ALLOW", "future/conditional",
      "I will commit the fix once you approve.", [])
check("ALLOW", "proposal phrasing",
      "I'd suggest committing this as two separate changes.", [])

print()
print("=== REAL TEXT regression guard (must ALLOW) ===")
# Verbatim assistant messages from a real session. The three marked "real FP"
# were genuine false positives found by running the hook over 140 real
# messages; they are the highest-value cases in this file.
check("ALLOW", "real: hook summary with reads in turn",
      "Applied. Enforcement is live and verified. Registered as PreToolUse on "
      "Bash. Each denial names the fix, not just the ban.", ["Bash"])
check("ALLOW", "real: honest limits paragraph",
      "Two limits you should hold onto. The hook fails open by design. "
      "Most of the rule is not enforceable from a command string.", ["Bash"])
check("ALLOW", "real: not-pushed disclosure",
      "sre-aiops still has the 7 pre-existing unpushed commits from earlier "
      "sessions. Pushing mine carries those, so that stays your call.", ["Bash"])
check("ALLOW", "real: recommendation with no mutation claim",
      "Build #1 only, first. It targets the one limit with a documented "
      "incident and uses a surface that genuinely blocks.", [])
# These three were FALSE POSITIVES found by running the hook over 140 real
# messages from this session: the claim text appears inside a double-quoted
# EXAMPLE of the defect, i.e. discussing it, not asserting it.
check("ALLOW", "real FP: quoted example of the defect",
      'It caused a real PROD misdiagnosis: an agent told the operator '
      '"the apply never ran" when it had run 20 minutes earlier.', [])
check("ALLOW", "real FP: quoted list of patterns to scan for",
      'A hook can scan my own final text for unsupported assertions '
      '("the apply never ran", "I\'ve committed", "verified") and block.', [])
check("ALLOW", "real FP: curly-quoted example",
      "An agent saying “the apply never ran” is the failure mode.", [])
# Genuine claim in the same corpus — must still block with no read behind it.
check("BLOCK", "real TP: unquoted first-person push claim",
      "One note: I pushed directly to main. That tree prescribes "
      "feature-branch to PR but takes direct commits for config archives.", [])

print()
print("=== FAIL-OPEN edges (must ALLOW) ===")
for desc, payload in [
    ("non-JSON stdin", "not json"),
    ("empty stdin", ""),
    ("JSON without fields", '{"a":1}'),
    ("null last_assistant_message", '{"last_assistant_message":null}'),
    ("list instead of dict", '[1,2,3]'),
]:
    p = subprocess.run([HOOK], input=payload, capture_output=True, text=True)
    blocked = False
    if p.stdout.strip():
        try:
            blocked = json.loads(p.stdout).get("decision") == "block"
        except Exception:
            pass
    if not blocked and p.returncode == 0:
        passed += 1
        print("  ok   ALLOW  %s" % desc)
    else:
        failed += 1
        print("  FAIL blocked/rc=%s  %s" % (p.returncode, desc))

# missing transcript -> cannot corroborate -> must allow
blocked, _, _ = run("I committed the fix.", [], transcript="/nonexistent/path.jsonl")
if not blocked:
    passed += 1
    print("  ok   ALLOW  unreadable transcript (cannot corroborate)")
else:
    failed += 1
    print("  FAIL blocked on unreadable transcript")

print()
print("pass=%d fail=%d" % (passed, failed))
sys.exit(1 if failed else 0)
