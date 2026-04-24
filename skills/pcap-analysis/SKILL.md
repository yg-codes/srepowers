---
name: pcap-analysis
description: Use when analyzing network packet capture files (.pcap, .pcapng) for DNS errors, TCP connection failures, HTTP proxy issues, or any network-level investigation using tshark on the local workstation
---

# Packet Capture (pcap) Analysis

## Overview

Packet captures are the ground truth of network behavior — but a 96MB pcap can produce 10MB+ of verbose output, swamping AI context and producing unreliable analysis. TSV-first, layered extraction turns pcaps into structured, token-efficient evidence.

**Core principle:** NEVER dump full verbose or JSON output into context. Extract targeted fields as TSV, analyze with CLI tools, deep-inspect only specific frames.

## When to Use

Use for ANY network packet analysis:
- DNS resolution failures and errors
- TCP connection failures, retransmissions, RST packets
- HTTP proxy errors (CONNECT tunnel failures, forward errors)
- Latency investigation at the packet level
- Correlating application errors with network behavior
- Remote capture collection from infrastructure hosts

**Use this ESPECIALLY when:**
- You have `.pcap` or `.pcapng` files to analyze
- An incident report mentions DNS timeouts or connection failures
- You need to prove whether DNS/network is the root cause
- Access logs show errors but the cause is unclear
- You need evidence to rule out network-layer vs application-layer issues

**Don't skip when:**
- Someone says "DNS might be the issue" (pcap proves or disproves)
- Failure durations are suspiciously fast (< 100ms suggests pre-DNS failure)
- You need to correlate multiple capture files from different hosts

## Preflight Check

Before any analysis, verify tshark is available:

```bash
command -v tshark
```

If missing, do NOT install automatically — ask the user for approval. `tshark` is a system package (`sudo apt install tshark`), not managed by mise. On remote hosts, assume `tcpdump` only — `scp` captures local for tshark analysis.

## The Five Phases

You MUST complete each phase in order. Skipping phases produces unreliable results.

## Output Contract

Use this structure for pcap analysis reports:

```markdown
## Capture Scope
- Files: [list with packet counts, time ranges]
- Protocol mix: [from io,phs]

## Findings
- [TSV-derived statistics: RCODE breakdown, HTTP code distribution, etc.]
- [Specific failure frames with frame numbers]

## Evidence
- [Exact tshark commands that produced each finding]
- [Frame numbers for all referenced events]

## Conclusions
- [What the packet-level evidence proves or rules out]
```

## Phase 1: Scope the Capture

**Goal:** Understand what's in the pcap before extracting anything.

```bash
# Protocol hierarchy (which protocols are present)
tshark -r capture.pcap -nn -q -z io,phs 2>/dev/null

# Packet count
tshark -r capture.pcap -nn -T fields -e frame.number 2>/dev/null | wc -l

# Conversation summary (TCP only — skip for DNS-only captures)
tshark -r capture.pcap -nn -q -z conv,tcp 2>/dev/null
```

Document:
- **Packet count** and **file size**
- **Protocol mix** (DNS-only? TCP+TLS+HTTP? Mixed?)
- **Time range** of the capture

**Critical:** If the pcap is > 50MB, you MUST use filtered TSV extraction only — never full JSON or verbose.

## Phase 2: Extract Relevant Fields as TSV

**Goal:** Produce self-documenting TSV files for analysis.

The TSV format (`-T fields`) is 3-5x more token-efficient than JSON and directly parseable with `awk`, `rg`, `sort`, `uniq`.

### DNS Investigation

```bash
tshark -r capture.pcap -nn -T fields \
  -e frame.number -e frame.time_relative \
  -e ip.src -e ip.dst \
  -e udp.srcport -e udp.dstport \
  -e dns.qry.name -e dns.flags.response -e dns.flags.rcode \
  -e dns.a -e dns.count.answers \
  -E header=y -E separator=$'\t' \
  2>/dev/null > dns-analysis.tsv
```

### TCP Connection Investigation

```bash
tshark -r capture.pcap -nn -T fields \
  -e frame.number -e frame.time_relative \
  -e ip.src -e ip.dst \
  -e tcp.srcport -e tcp.dstport \
  -e tcp.flags -e tcp.analysis.retransmission \
  -e tcp.analysis.lost_segment \
  -E header=y -E separator=$'\t' \
  2>/dev/null > tcp-analysis.tsv
```

### HTTP Proxy / CONNECT Tunnel Investigation

```bash
tshark -r capture.pcap -nn -T fields \
  -e frame.number -e frame.time_relative \
  -e ip.src -e ip.dst \
  -e tcp.srcport -e tcp.dstport \
  -e tcp.flags \
  -e http.request.method -e http.request.full_uri \
  -e http.response.code -e http.connection \
  -E header=y -E separator=$'\t' \
  2>/dev/null > http-analysis.tsv
```

### Key Rules

- ALWAYS use `-E header=y` (self-documenting columns)
- ALWAYS use `-E separator=$'\t'` (reliable field splitting)
- ALWAYS redirect stderr: `2>/dev/null` (tshark warnings on SLL/Linux cooked captures)
- Extract ONCE per investigation question, then analyze the TSV — don't re-read the pcap

## Phase 3: Analyze with CLI Tools

**Goal:** Derive statistics and find suspicious events from TSV data.

**CRITICAL:** Analyze the `.tsv` files with `awk`, `rg`, `sort`, `uniq` — NOT tshark re-reads. Each tshark invocation re-parses the entire pcap.

### DNS Analysis Patterns

```bash
# RCODE breakdown (what types of DNS errors?)
awk -F'\t' 'NR>1 {rcode[$9]++} END {for (r in rcode) printf "RCODE %s: %d\n", r, rcode[r]}' \
  dns-analysis.tsv | sort -t' ' -k2 -rn

# Queries vs responses
awk -F'\t' 'NR>1 {if ($8=="0") q++; else r++} END {printf "queries: %d\nresponses: %d\n", q, r}' \
  dns-analysis.tsv

# Top queried domains
awk -F'\t' 'NR>1 {print $7}' dns-analysis.tsv | sort | uniq -c | sort -rn | head -15

# Find SERVFAIL (RCODE 2) — proves or disproves DNS server failure
awk -F'\t' 'NR>1 && $9=="2"' dns-analysis.tsv

# Find REFUSED (RCODE 5) — shows policy rejections
awk -F'\t' 'NR>1 && $9=="5" {printf "frame=%s domain=%s src=%s\n", $1, $7, $3}' dns-analysis.tsv

# Response source breakdown (who is answering?)
awk -F'\t' 'NR>1 {print $3}' dns-analysis.tsv | sort | uniq -c | sort -rn
```

### HTTP / Proxy Analysis Patterns

```bash
# HTTP response code distribution
awk -F'\t' 'NR>1 && $11!="" {print $11}' http-analysis.tsv | sort | uniq -c | sort -rn

# HTTP 500 responses with full context
awk -F'\t' 'NR>1 && $10=="500" {printf "frame=%s time=%s src=%s:%s dst=%s:%s\n", \
  $1,$2,$3,$5,$4,$6}' http-analysis.tsv

# CONNECT requests (tshark puts URI in method field for CONNECT)
awk -F'\t' 'NR>1 && ($9 ~ /CONNECT/ || $9 ~ /:443/) {printf "frame=%s time=%s src=%s code=%s\n", \
  $1,$2,$3,$10}' http-analysis.tsv
```

### TCP Analysis Patterns

```bash
# TCP flag distribution
awk -F'\t' 'NR>1 {print $7}' tcp-analysis.tsv | sort | uniq -c | sort -rn

# SYN packets to specific destination (proves upstream connection attempt)
awk -F'\t' 'NR>1 && $7=="0x0002" && $4=="<target-ip>"' tcp-analysis.tsv

# Retransmissions (packet loss indicator)
awk -F'\t' 'NR>1 && $8!=""' tcp-analysis.tsv
```

### Timing Analysis

```bash
# Time delta between two frames (e.g., CONNECT to HTTP 500)
awk -F'\t' 'NR>1 {if ($1=="<frame-A>") t1=$2; if ($1=="<frame-B>") t2=$2} \
  END {printf "Delta: %.3f ms\n", (t2-t1)*1000}' http-analysis.tsv
```

## Phase 4: Deep Inspect Specific Frames

**Goal:** Get full packet decode only for frames identified as suspicious in Phase 3.

**CRITICAL:** Only use `-T json` or `-V` for specific, filtered frames — never for the entire capture.

```bash
# Single frame deep decode (JSON)
tshark -r capture.pcap -nn -T json -c 1 \
  -Y 'frame.number == <N>' 2>/dev/null

# Frame range (e.g., ±5 frames around a failure)
tshark -r capture.pcap -nn -T json \
  -Y 'frame.number >= <start> && frame.number <= <end>' 2>/dev/null

# Single frame verbose (for human review only)
tshark -r capture.pcap -nn -V -c 1 \
  -Y 'frame.number == <N>' 2>/dev/null
```

### Key Evidence Patterns

For **CONNECT tunnel failure** investigation, check around the failure frame:

```bash
# Was there a DNS query between CONNECT and error response?
tshark -r capture.pcap -nn -T fields -e frame.number -e dns.qry.name \
  -Y 'frame.number >= <connect_frame> && frame.number <= <error_frame> && dns' \
  2>/dev/null

# Was there an upstream TCP SYN?
tshark -r capture.pcap -nn -T fields -e frame.number -e ip.dst -e tcp.flags \
  -Y 'frame.number >= <connect_frame> && frame.number <= <error_frame> \
    && ip.dst==<target_ip> && tcp.flags==0x0002' \
  2>/dev/null
```

**Zero DNS queries + zero upstream SYN = failure occurs before DNS resolution.**

## Phase 5: Report Findings

Produce a structured report with:

1. **Capture scope** — files, sizes, packet counts, time ranges
2. **Protocol summary** — from Phase 1 `io,phs` output
3. **Statistical findings** — RCODE breakdowns, HTTP code distributions, timing deltas
4. **Failure event analysis** — frame-by-frame walkthrough with ASCII flow diagrams
5. **Cross-correlation** — how pcap evidence aligns with logs or other data sources
6. **Conclusions** — what the evidence proves or rules out (hypothesis table)

### ASCII Flow Diagram Format

```
SUCCESSFUL CONNECT:
  Client ──SYN──► Proxy:3128
  Proxy ──SYN,ACK──► Client
  Client ──CONNECT host:443──► Proxy
  Proxy ──DNS query──► Resolver        ← present
  Proxy ◄─DNS response── Resolver      ← present
  Proxy ──SYN──► host:443              ← present
  Proxy ◄─200 Connection established── Client

FAILED CONNECT:
  Client ──SYN──► Proxy:3128
  Client ──CONNECT host:443──► Proxy
  [NO DNS query]                        ← absent
  [NO upstream SYN]                     ← absent
  Proxy ◄─HTTP 500 ERR_CANNOT_FORWARD── (Xms later)
```

## Remote Capture Pattern

For collecting captures from remote hosts, follow toolchains.md file relay and multi-host patterns.

### Stale Capture Check (MANDATORY before new captures)

```bash
for HOST in host01.fsx.zone host02.fsx.zone; do
  echo "=== $HOST ==="
  sshpass -e ssh root@"$HOST" 'ps -ef | grep "[t]cpdump"'
  echo
done
```

### Start Capture (backgrounded, CAPTURE_ID for isolation)

```bash
CAPTURE_ID="dns_err"  # unique per investigation
for HOST in host01.fsx.zone host02.fsx.zone; do
  sshpass -e ssh root@"$HOST" \
    "nohup /usr/sbin/tcpdump -i any -nn -U -s 0 -C 100 -W 10 \
    -w /var/tmp/${CAPTURE_ID}.pcap '<BPF filter>' </dev/null >/dev/null 2>&1 &"
  echo "Started capture on $HOST"
done
```

### Verify Capture (after 30s wait)

```bash
CAPTURE_ID="dns_err"  # must match start
for HOST in host01.fsx.zone host02.fsx.zone; do
  echo "=== $HOST ==="
  sshpass -e ssh root@"$HOST" \
    "ps aux | grep \"[t]cpdump.*-w /var/tmp/${CAPTURE_ID}.pcap\" | head -3; \
     echo; /usr/sbin/tcpdump -r /var/tmp/${CAPTURE_ID}.pcap 2>/dev/null | wc -l"
done
```

### Retrieve and Stop

```bash
TS=$(date +%Y%m%d_%H%M%S)
CAPTURE_ID="dns_err"
for HOST in host01.fsx.zone host02.fsx.zone; do
  HOST_SHORT=$(echo "$HOST" | sed 's/\..*//')
  mkdir -p "data/${HOST_SHORT}-${TS}"
  sshpass -e scp root@"$HOST":/var/tmp/${CAPTURE_ID}.pcap* "data/${HOST_SHORT}-${TS}/"
done

for HOST in host01.fsx.zone host02.fsx.zone; do
  sshpass -e ssh root@"$HOST" "pkill -f 'tcpdump.*-w /var/tmp/${CAPTURE_ID}.pcap'"
  echo "Stopped capture on $HOST"
done
```

### Notes

- Use `/usr/sbin/tcpdump` full path for non-interactive SSH sessions (PATH may differ)
- `-U` (unbuffered) flushes packets to disk immediately
- `-C 100 -W 10` = 100MB per file, 10 files rotation
- Retrieving into a directory handles rotated files (`.pcap0`, `.pcap1`, etc.)
- Use unique `CAPTURE_ID` per investigation so concurrent captures never conflict

## File Naming Convention

```
<hostname>-<timestamp>-<capture-type>.pcap   # original capture
<hostname>-<timestamp>-<capture-type>.tsv    # TSV field extraction
<hostname>-<timestamp>-<capture-type>.json   # targeted JSON (rare)
```

## DNS RCODE Quick Reference

| RCODE | Name | Meaning | Typical Cause |
|-------|------|---------|---------------|
| 0 | NoError | Success | Normal response |
| 2 | SERVFAIL | Server failure | Resolver bug, upstream timeout |
| 3 | NXDOMAIN | Name not found | Normal for reverse DNS of private IPs |
| 5 | REFUSED | Policy refusal | Server refuses to answer for this zone |
| 7 | REFUSED | Refused | Similar to 5, implementation-dependent |

## TCP Flags Quick Reference

| Flag hex | Meaning |
|----------|---------|
| `0x0002` | SYN |
| `0x0012` | SYN,ACK |
| `0x0010` | ACK |
| `0x0011` | FIN,ACK |
| `0x0014` | RST,ACK |
| `0x0018` | PSH,ACK |

## Anti-Patterns

| Anti-pattern | Why | Do instead |
|---|---|---|
| `tshark -r file.pcap -V > file.txt` | Full verbose = 10-100x pcap size, wastes context | Use `-T fields` TSV |
| `tshark -r file.pcap -T json > file.json` | Full JSON = 5-20x pcap size | Filtered JSON: `-Y '<filter>' -c N` |
| Re-reading pcap for every query | Slow; each invocation re-parses | Extract TSV once, analyze with awk/rg |
| `-z io,stat,1` on sparse captures | Produces thousands of zero-line per-second stats | Use `-z io,phs` for protocol hierarchy |
| Nested quoting over SSH for tshark | Fragile, hard to review | scp pcap local, analyze with local tshark |
| Guessing HTTP fields from `-T fields` | CONNECT tunnels shift columns | Verify with `head -5` before bulk extraction |

## SRE Principles

### Safety First
- Original pcap files are immutable evidence — never modify them
- Remote captures use `tcpdump` (capture only); analysis uses local `tshark`
- Always check for stale tcpdump processes before starting new captures

### Structured Output
- TSV is the default format — self-documenting with `-E header=y`
- Every finding must reference the frame number it came from
- Reports include the exact tshark command that produced each artifact

### Evidence-Driven
- Statistical findings come from TSV analysis (Phase 3), not visual scanning
- Hypothesis table: list each hypothesis, the evidence for/against, and verdict
- Absence of evidence is evidence (e.g., zero DNS queries in failure window)

### Audit-Ready
- Record exact tshark commands for every derived artifact
- File naming includes hostname, timestamp, and capture type
- Cross-correlate pcap timestamps with application log timestamps

### Communication
- Lead with the conclusion (DNS ruled out / DNS confirmed)
- Show the flow diagram (successful vs failed) for visual clarity
- Include timing deltas to distinguish network latency from internal processing

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `-z io,stat,1` for scope | Use `-z io,phs` instead — per-second stats are excessive for sparse captures |
| Forgetting `2>/dev/null` on tshark | tshark exits 2 on SLL captures but data is fine; suppress stderr |
| Matching `grep '500'` on verbose output | Matches TCP ports, timestamps, etc. Use `http.response.code == 500` display filter |
| Wrong column in TSV output | CONNECT tunnels shift HTTP fields; verify column alignment with `head -5` |
| Trusting exit code 2 as failure | tshark exits 2 for warnings on Linux cooked captures; data is correct |
| Analyzing large pcaps without `-Y` filter | Extract targeted TSV with display filter, don't dump all frames |

## Integration

**Called by:**
- Any investigation involving network packet captures
- systematic-troubleshooting when network-layer analysis is needed
- evidence-first-reporting for structured pcap findings

**Pairs with:**
- **systematic-troubleshooting** — pcap analysis is a Phase 1 evidence-gathering technique
- **evidence-first-reporting** — structure findings as evidence/inference/unknowns
- **network-engineer** — for VPC/routing-level investigation beyond proxy analysis
- **incident-commander** — for coordinating multi-host capture during active incidents

**References:**
- Global pcap analysis rule: `~/.claude/rules/pcap-analysis.md`
- Toolchain preferences: `~/.claude/rules/toolchains.md` (file relay, multi-host patterns)
