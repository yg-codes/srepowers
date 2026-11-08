# certificate-management

Manage the full TLS certificate lifecycle: issuance from an internal CA,
renewal and rotation, chain validation, deployment verification, and
debugging of TLS handshake failures — plus cert-manager in Kubernetes and
proactive expiration monitoring. Ships as
`srepowers-infra:certificate-management`. (`SKILL.md` is the agent-facing
trigger doc; this file is for humans.)

## Use cases

- Issue a new certificate: generate a CSR, sign with the internal CA,
  validate the chain, deploy, and verify
- Rotate certificates before they expire, with a fleet-wide expiration check
- Debug a TLS handshake failure or a broken/missing intermediate chain
- Manage cert-manager Certificate requests and status in Kubernetes

## How-to

In Claude Code or Codex, just ask — "certificate expiring", "TLS error",
"cert-manager", "CSR", "certificate renewal", "TLS handshake failure",
"certificate chain" — the skill triggers automatically, or invoke it
directly as the `srepowers-infra:certificate-management` command.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — the five-step issue/deploy process; cert-manager request,
  status, and trust-manager sections; fleet-wide expiration checks and the
  proactive rotation timeline; handshake-failure, chain-issue, and
  fingerprint-verification debugging; anti-patterns

---
Last Updated: 2026-09-14
