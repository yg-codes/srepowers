# pve-vlan-trunk-troubleshooting

Diagnose VLAN connectivity failures on Proxmox VE where the VM is almost
never the problem: the real causes are a missing trunk on the upstream
switch port or bridge-vlan-aware differences between nodes. Core rule:
test VLAN reachability from the PVE host itself before blaming the VM.
Ships as `srepowers-infra:pve-vlan-trunk-troubleshooting`. (`SKILL.md` is
the agent-facing trigger doc; this file is for humans.)

## Use cases

- A VM on a VLAN cannot reach the network while other VMs on the same VLAN
  on other nodes work fine
- A newly created VM has no connectivity despite correct `bridge=`/`tag=`
  config in `qm config`
- A VM worked on node A and broke after migrating to node B
- Gather the right evidence before escalating to the network/switch team

## How-to

In Claude Code or Codex, describe the symptom — "VM on VLAN X can't ping
anything", "ping works on one PVE node but not another", "ARP fails for
the VLAN gateway from the host" — or invoke it directly as the
`srepowers-infra:pve-vlan-trunk-troubleshooting` command. The skill runs
as an interactive session using the four-phase method.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — interactive session setup; the four-phase method (VM config
  → PVE bridge config → host-level reachability test → switch uplink
  verification with `lldpcli` → guest OS last); decision matrix;
  post-fix quick verification; urgent mitigation workaround; common
  mistakes; escalation evidence checklist

---
Last Updated: 2026-09-14
