---
name: pve-vlan-trunk-troubleshooting
description: Use when a VM on Proxmox VE cannot reach the network despite correct PVE bridge/VLAN config, when ping or ARP fails for a specific VLAN from the hypervisor host, or when VLAN connectivity works on one PVE node but not another
---

# PVE VLAN Trunk Troubleshooting

## Overview

VLAN connectivity failures on PVE are almost never VM configuration problems. The bridge and tap config is usually correct. The real causes are: missing trunk on the upstream switch port, or subtle bridge-vlan-aware differences between nodes.

**Core principle:** Test VLAN reachability from the PVE host itself before blaming the VM. If the gateway ARP fails from the hypervisor, the VM is a victim — not the cause.

## When to Use

- VM on VLAN X cannot ping anything; other VMs on same VLAN on other nodes work
- New VM created — no connectivity despite correct bridge/tag config
- `qm config` shows correct `bridge=vmbr1,tag=227` but VM is unreachable
- Migration — VM worked on node A, broken on node B

**Do NOT use for:**
- All VLANs broken on a node (likely physical link down — check bond status first)
- VM cannot reach internet but can reach local subnet (routing/firewall issue)

## The Four-Phase Method

Complete phases in order. Stop when root cause is found.

### Phase 1 — VM Config (5 min)

**Goal:** Confirm VM NIC matches working reference VM.

```bash
# Affected VM
qm config <VMID> | grep -E "net|bridge|tag|firewall"

# Reference VM (working, same VLAN, different node)
qm config <REF_VMID> | grep -E "net|bridge|tag|firewall"
```

Expected: `net0: virtio=XX:XX:XX:XX:XX:XX,bridge=vmbr1,tag=<VLANID>`

Check PVE firewall — if enabled, verify ICMP is not blocked:
```bash
cat /etc/pve/firewall/<VMID>.fw 2>/dev/null || echo "No VM firewall"
pvesh get /nodes/<node>/firewall/options
```

**If config differs → fix and stop. If identical → Phase 2.**

### Phase 2 — PVE Bridge Config (5 min)

**Goal:** Confirm `bridge-vlan-aware yes` and VLAN present in bridge table.

```bash
# Check bridge-vlan-aware on affected node vs reference node
grep -A10 "vmbr1" /etc/network/interfaces

# Full bridge VLAN table — VLAN must appear on vmbr1, bond1, and tap
bridge vlan show

# Tap interface specifically
bridge vlan show dev tap<VMID>i0
```

Expected tap output: `<VLANID> PVID Egress Untagged`

If `bridge-vlan-aware yes` is missing or VLAN not in table → bridge config is the cause.

**If bridge config matches reference → Phase 3.**

### Phase 3 — Host-Level Reachability Test (2 min)

**This is the decisive test.**

```bash
# Ping VLAN gateway from PVE host
ping -c 5 -I vmbr1.<VLANID> <GATEWAY_IP>

# Check ARP
ip neigh show | grep <VLAN_SUBNET>
```

**Interpret results:**

| Result | Meaning |
|--------|---------|
| Ping works | Host can reach VLAN — go to Phase 4 (guest OS) |
| 100% loss + ARP FAILED | Switch not trunking VLAN on this node's uplink → **Phase 3b** |
| 100% loss + ARP STALE | Switch issue or IP conflict |

### Phase 3b — Switch Uplink Verification (lldpcli)

**lldpcli is available on PVE nodes** — use it to identify exact switch ports and compare against working node.

```bash
# Affected node — note the switch name and port for bond1's active slave
lldpcli show neighbors detail

# Reference node (working VLAN)
# Run same command on reference node
lldpcli show neighbors detail
```

Look in the output for the `bond1` primary slave interface (check `/proc/net/bonding/bond1` for active slave). Note:
- **Switch hostname** (e.g., `typhlsw02a`)
- **Port ID** (e.g., `Ethernet1/30`)

Compare with the reference node's port. If ports differ, the switch ports may have different trunk configs.

**Provide to network team:**
```
Affected node: <switch> port <port>  ← needs VLAN <ID> added to trunk
Reference node: <switch> port <port> ← VLAN <ID> already trunked (working)
```

Verify bond1 active slave:
```bash
cat /proc/net/bonding/bond1 | grep -E "Active Slave|Slave Interface|MII Status"
```

Capture pcap proof for network team escalation:
```bash
# Zero captured = VLAN not trunked on uplink
timeout 30 tcpdump -i bond1 -w /tmp/vlan<ID>-bond1.pcap vlan <VLANID>

# Frames here = VM is transmitting; frames absent on bond1 = bridge or switch issue
timeout 30 tcpdump -i tap<VMID>i0 -w /tmp/vlan<ID>-tap.pcap
```

### Phase 4 — Guest OS (if Phase 3 ping works)

Only reach here if host-level VLAN reachability is confirmed.

```bash
# Guest agent network info
qm guest cmd <VMID> network-get-interfaces

# ARP probe from bridge
arping -I vmbr1.<VLANID> -c 5 <VM_IP>
```

- ARP response but ping fails → guest firewall blocking ICMP
- No ARP response → wrong IP in guest or NIC down

Check guest via console if agent unavailable.

## Decision Matrix

| Finding | Root Cause | Action |
|---------|-----------|--------|
| VM NIC has wrong bridge or no tag | PVE VM config | `qm set <VMID> -net0 virtio,bridge=vmbr1,tag=<ID>` |
| `bridge-vlan-aware` missing | PVE bridge config | Add to `/etc/network/interfaces`, `ifreload -a` |
| Tap not in bridge vlan table | Bridge not updated | Restart VM |
| Host-level ping/ARP fails | Switch not trunking VLAN | Network team: add VLAN to trunk on uplink port (from lldpcli) |
| ARP works, ping fails | Guest firewall | Disable ICMP block in guest |
| Duplicate IP | IP conflict | Assign unique IP |

## Quick Verification After Fix

```bash
# Confirm VLAN reachable from host
ping -c 3 -I vmbr1.<VLANID> <GATEWAY_IP>

# Confirm VM reachable
ping -c 3 <VM_IP>
```

## Mitigation — Urgent Workaround

If VM is needed before root cause is resolved, migrate to a working node:

```bash
qm migrate <VMID> <working-node> --online
```

## Common Mistakes

| Mistake | Reality |
|---------|---------|
| Checking only VM config | Bridge and switch are more likely causes |
| Skipping Phase 3 host-level test | This is the decisive test — do it early |
| Blaming the VM when tap traffic exists | If tap has traffic but bond1 has none, the bridge or switch is the cause |
| Asking network team without port IDs | Always run `lldpcli show neighbors detail` first — it gives exact switch/port |
| Forgetting to check reference node | Always compare with a working node on same VLAN |

## Evidence to Collect (for escalation)

```bash
# All read-only — safe to run on production
lldpcli show neighbors detail > /tmp/lldp-<node>.log
bridge vlan show > /tmp/bridge-vlan-<node>.log
qm config <VMID> > /tmp/vm-config-<VMID>.log
ping -c 5 -I vmbr1.<VLANID> <GW> > /tmp/ping-gw.log
ip neigh show > /tmp/arp.log
timeout 30 tcpdump -i bond1 -w /tmp/bond1-vlan<ID>.pcap vlan <VLANID>
timeout 30 tcpdump -i tap<VMID>i0 -w /tmp/tap-<VMID>.pcap
```
