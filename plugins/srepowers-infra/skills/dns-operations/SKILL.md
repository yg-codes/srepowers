---
name: dns-operations
description: Use when managing on-premises DNS infrastructure — editing BIND zone files, adding or removing DNS records (A, AAAA, CNAME, MX, TXT, PTR), debugging DNS resolution failures, managing reverse DNS zones, or verifying DNS propagation. Also use for "add DNS record", "fix DNS", "zone file edit", "reverse DNS", "PTR record", "DNS not resolving", "dig", "named-checkzone", "rndc reload", or any DNS administration task for on-premises BIND or similar DNS servers.
---

# DNS Operations

Manage and troubleshoot on-premises DNS infrastructure. Covers BIND zone file editing, record management, reverse DNS, syntax validation, and resolution debugging.

**Core principle:** Validate before reload, reload before verify, verify before reporting success.

**Announce at start:** "I'm using the dns-operations skill to [manage/debug] DNS records."

## When to Use

**Use when:**
- Adding, modifying, or removing DNS records
- Debugging DNS resolution failures (NXDOMAIN, SERVFAIL, wrong IP)
- Managing reverse DNS (PTR) zones
- Editing BIND zone files or configurations
- Validating zone file syntax
- Checking DNS propagation across servers
- Creating or modifying reverse zones for new subnets

**Exceptions:**
- Kubernetes internal DNS (CoreDNS) — use `kubernetes-specialist`
- DNS queries from application code — use `systematic-troubleshooting`

## The Process

### Record Management Workflow

Every DNS change follows: edit → validate → reload → verify.

#### Step 1: Edit the Zone File

Zone files are typically at `/etc/bind/zones/` or `/var/named/` on the DNS server.

```bash
# Locate the zone file
ssh dns-server 'grep "zone.*example.zone" /etc/bind/named.conf.local'

# Backup before editing
ssh dns-server 'cp /etc/bind/zones/db.example.zone /etc/bind/zones/db.example.zone.bak'

# Edit the zone file (use agent Edit tool or stage via /tmp)
```

**Record format reference:**

| Type | Format | Example |
|------|--------|---------|
| A | `hostname IN A ip` | `web01 IN A 10.0.1.100` |
| AAAA | `hostname IN AAAA ipv6` | `web01 IN AAAA 2001:db8::1` |
| CNAME | `alias IN CNAME target` | `www IN CNAME web01` |
| MX | `@ IN MX priority mailserver` | `@ IN MX 10 mail.example.zone.` |
| TXT | `@ IN TXT "text"` | `@ IN TXT "v=spf1 include:..."` |
| PTR | `reversed-ip IN PTR fqdn.` | `100.1.0.10 IN PTR web01.example.zone.` |
| SRV | `_service._proto IN SRV pri weight port target` | `_ldap._tcp IN SRV 10 60 389 ldap.example.zone.` |

**Always increment the serial number** in the SOA record. Convention: `YYYYMMDDNN` (date + 2-digit revision).

```
; Before
2026060901  ; Serial

; After adding a record
2026060902  ; Serial
```

#### Step 2: Validate Zone Syntax

```bash
# Check zone file syntax
ssh dns-server 'named-checkzone example.zone /etc/bind/zones/db.example.zone'

# Check overall BIND configuration
ssh dns-server 'named-checkconf'

# Expected output: "zone example.zone/IN: loaded serial XXXXXXXXXX  OK"
```

If validation fails, **do not proceed to reload** — fix the syntax error first.

#### Step 3: Reload the Zone

```bash
# Reload a specific zone
ssh dns-server 'sudo rndc reload example.zone'

# Reload all zones
ssh dns-server 'sudo rndc reload'

# Reload BIND entirely (if config changed)
ssh dns-server 'sudo systemctl reload named'
# or
ssh dns-server 'sudo systemctl reload bind9'
```

#### Step 4: Verify Propagation

```bash
# Query the local DNS server directly
dig @dns-server example.zone hostname A

# Check from a client perspective
dig hostname.example.zone A

# Verify reverse DNS
dig -x 10.0.1.100

# Check SOA serial was updated
dig @dns-server example.zone SOA +short

# Compare across DNS servers (if multi-server)
dig @dns1 example.zone hostname A +short
dig @dns2 example.zone hostname A +short
```

### Reverse DNS Management

Reverse zones map IPs to hostnames. The zone name is the reversed network address:

| Network | Reverse zone name | Example PTR entry |
|---------|------------------|-------------------|
| 10.0.1.0/24 | `1.0.10.in-addr.arpa` | `100 IN PTR web01.example.zone.` |
| 192.168.0.0/24 | `0.168.192.in-addr.arpa` | `50 IN PTR server.example.zone.` |

```bash
# Create reverse zone (if new subnet)
# Add to named.conf.local:
# zone "1.0.10.in-addr.arpa" {
#     type master;
#     file "/etc/bind/zones/db.10.0.1";
# };

# Add PTR record
# In the reverse zone file:
# 100    IN PTR    web01.example.zone.
```

**Always end FQDNs with a trailing dot** in zone files — `web01.example.zone.` not `web01.example.zone`.

## Debugging DNS Resolution

### Symptom: NXDOMAIN (record doesn't exist)

```bash
# Check if the record exists on the authoritative server
dig @dns-server hostname.example.zone A

# If it exists on auth but not from client → propagation issue
# If it doesn't exist on auth → record is missing, add it
```

### Symptom: Wrong IP returned

```bash
# Check which server is answering
dig hostname.example.zone A +trace

# Check cached vs authoritative answer
dig @dns-server hostname.example.zone A
dig hostname.example.zone A    # client query

# Flush cache on the DNS server
ssh dns-server 'sudo rndc flush'
```

### Symptom: SERVFAIL

```bash
# Check BIND logs
ssh dns-server 'journalctl -u named --since -1h'
# or
ssh dns-server 'tail -50 /var/log/syslog | grep named'

# Common causes:
# - Zone file syntax error
# - Missing zone file
# - Permission denied on zone file
# - DNSSEC validation failure
```

## Anti-Patterns

| Anti-pattern | Why | Do instead |
|-------------|-----|-----------|
| Forgetting to increment SOA serial | Secondary servers won't pick up changes | Always increment serial before reload |
| FQDN without trailing dot in zone file | BIND appends the zone name, creating `host.zone.zone` | Always use trailing dot: `host.example.zone.` |
| Editing zone file without `named-checkzone` | Syntax errors break the entire zone | Validate before every reload |
| Using tabs in zone files | Mixed indentation causes parsing errors | Use spaces consistently |
| Skipping propagation verification | Record looks correct on auth but clients see old value | Query from client and auth, compare results |

## Integration

**Called by:**
- `srepowers-core:systematic-troubleshooting` — for DNS-related incidents
- `srepowers-core:test-driven-operation` — for verification commands

**Pairs with:**
- `srepowers-domain:network-engineer` — for broader network debugging
- `srepowers-private:puppet-deploy` — when DNS changes are managed via Puppet (`fsx_dns` module)

## SRE Principles

### Safety First
- Always backup zone files before editing
- Always validate with `named-checkzone` before reload
- Never edit multiple zones simultaneously — one zone at a time

### Structured Output
- Report: zone name, serial (before → after), records added/modified/removed, validation result
- Use tables for multi-record changes

### Evidence-Driven
- Capture `dig` output before and after the change
- Show `named-checkzone` output as validation evidence

### Audit-Ready
- Record: zone file path, old serial, new serial, records changed, timestamp
- Include dig verification output in change records

### Communication
- Report propagation status: "record exists on primary, waiting for secondary sync" vs "record resolvable from all clients"
- Surface TTL implications: "clients may cache the old value for up to <TTL> seconds"
