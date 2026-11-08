# splunk-curl-search

Run bounded, read-only SPL searches against a Splunk Enterprise instance over
curl (REST) from a client machine — no SSH to the Splunk host, no extra CLI.
Detects the SSO front door first (oauth2-proxy, SAML IdP, or a filtered
management port), lints every SPL against mutating or
unbounded searches, bounds windows and result counts, and reports from result
files with scan counts. Ships as `srepowers-infra:splunk-curl-search`.
(`SKILL.md` is the agent-facing trigger doc; this file is for humans.)

## Use cases

- "Is host X still logging?" / "when did host Y stop?" — with a
  SENDING/STALE/ABSENT gate per expected host
- Inventory every sender per index/sourcetype with first/last seen
- Index retention and size questions — is "all time" actually complete?
- Sourcetype exploration before writing a raw search
- Any ad-hoc read-only SPL, from a network that cannot reach splunkd :8089

## How-to

In Claude Code or Codex, just ask — "is host X logging to Splunk", "list
senders", "when did host Y stop", "index retention" — the skill triggers
automatically, or invoke it directly as the
`srepowers-infra:splunk-curl-search` command.

Site facts (URL, credential reference, allowed indexes, host-field format)
live in a profile outside the skill — `$SPLUNK_PROFILE_DIR/<name>.env` or
`~/.config/splunk-curl-search/profiles/<name>.env`; copy
`profiles/_template.env` to start one. Credentials resolve via the 1Password
CLI (`op://…`) or a 0600 KEY=VALUE file, and reach curl only via stdin.

### Verify

Fixture: `evals/fixtures/splunk-curl-search/` via `skill-test-runner`. The
SPL linter also self-tests: `tests/test-spl-lint.sh` inside the skill dir
must PASS good and FAIL bad SPL.

## Reference

- `SKILL.md` — front-door detection table, dry-run/confirm workflow,
  ready-made queries (`queries/*.spl`), enforced guardrails, exit codes,
  failure classification (connection vs TLS vs proxy vs front door vs
  authentication vs search)
- `profiles/_template.env` — every profile key with comments

---
Last Updated: 2026-10-13
