# wizard

Generate an interactive bash script that walks a human, step by step,
through a procedure only they can perform — vendor portals, CA dashboards,
CI secret provisioning, approval-driven cutovers. The script opens each
URL, says what to click, captures values into `.env`/CI secrets, and
confirms at every gate. Ships as `srepowers-core:wizard`. (`SKILL.md` is the
agent-facing trigger doc; this file is for humans.)

## Use cases

- Onboard a third-party service whose setup lives in a web console the agent cannot touch
- Rotate a certificate through a CA dashboard: paste CSR, download chain, copy values back
- Provision GitHub Actions secrets/variables without dictating each `gh secret set` by hand
- Drive a migration or cutover that pauses for human approval before each irreversible step

## How-to

Ask — "generate a wizard for this vendor setup", "walk me through the
console-only steps" — or invoke `srepowers-core:wizard`. Not for steps the
agent can perform itself.

The agent scopes your procedure, shows you the stage list for confirmation,
then authors stages into `template.sh`'s library (progress with
time-remaining, URL opening incl. WSL, hidden secret entry, `.env` upserts,
`gh secret`/`gh variable` writes). You run the script; it pauses for you at
each step.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo. The skill's own gate for output: `bash -n` (plus `shellcheck`
if available), then a static trace that every captured value lands where the
scoping step said.

## Reference

- `SKILL.md` — the four-step process: scope the procedure (stages, captured
  values, secret vs public), map each stage's journey, author the stages,
  verify and hand off
- `template.sh` — the wizard library above the `STAGES` marker (identical in
  every wizard, never hand-edited) plus one example stage to replace

## Provenance

Adapted from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT, © Matt Pocock) `engineering/wizard`, rewired onto srepowers skill
names and doctrines. Recast for infrastructure cutovers and vendor portals. Upstream reference rewires are recorded in
`RELEASE-NOTES.md`.

---
Last Updated: 2026-09-14
