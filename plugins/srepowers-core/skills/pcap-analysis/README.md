# pcap-analysis

Analyze packet captures (.pcap/.pcapng) with tshark on the local workstation —
DNS errors, TCP connection failures, HTTP proxy issues — using TSV-first
extraction so a 96MB capture never turns into 10MB+ of verbose output.
Ships as `srepowers-core:pcap-analysis`. (`SKILL.md` is the agent-facing
trigger doc; this file is for humans.)

## Use cases

- Prove or rule out DNS as the root cause of a connection failure
- Diagnose HTTP CONNECT tunnel failures through a proxy
- Find retransmissions, RSTs, and lost segments behind flaky TCP
- Capture on remote hosts with tcpdump, then analyze locally

## How-to

Just ask — "analyze this pcap", "check the capture for DNS errors", "why did
that connection fail" — or invoke the `srepowers-core:pcap-analysis` command.
Requires tshark; if missing, the skill asks before installing
(`sudo apt install tshark`).

Five phases, in order:

| Phase | Goal |
|-------|------|
| 1. Scope | Protocol hierarchy, packet count, time range (`-z io,phs`) |
| 2. Extract | Targeted fields as TSV (`-T fields -E header=y`), once per question |
| 3. Analyze | awk/rg/sort/uniq on the TSV — never re-read the pcap |
| 4. Deep inspect | Full JSON/verbose decode of specific frames only |
| 5. Report | Scope, findings, evidence, frame-referenced conclusions |

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — the only file. Contains:
  - TSV extraction commands for DNS, TCP, and HTTP/proxy investigations
  - awk analysis patterns (RCODE breakdown, top domains, retransmissions,
    timing deltas)
  - Remote capture pattern: stale-tcpdump check, backgrounded capture with
    `CAPTURE_ID`, retrieve via scp, stop
  - Quick references: DNS RCODEs, TCP flag hex values
  - Anti-patterns table (full-verbose dumps, JSON everywhere, pcap re-reads)

---
Last Updated: 2026-09-14
