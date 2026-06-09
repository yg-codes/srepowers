---
name: puppet-fact-query
description: |
  Query PuppetDB for hosts matching OS, environment, or custom fact criteria.
  Returns sorted host lists with FQDNs, IPs, and environments.

  Use when the user says anything like:
  - "query puppet facts", "get puppet hosts", "fetch from puppetdb"
  - "list rocky 8 sit servers", "show centos uat hosts"
  - "how many rocky 9 in prod", "puppetdb query"
  - "get the full list of <OS> <env> servers"
  - "query/fetch/get puppet fact"
  - "bios_vendor is Amazon EC2", "kernel version X"
  - "company fact values", "what values does <fact> have"

  DO NOT use for: applying Puppet changes, deploying code, or modifying
  Puppet resources. This skill is read-only.
---

# PuppetDB Fact Query

Query PuppetDB via Puppetboard's external URL or via SSH to the Puppet master.
Returns sorted host lists with FQDNs, IPs, and environments.

> **Configuration:** Set `PUPPET_WEB_URL` and `PUPPET_MASTER` in your project's
> `CLAUDE.md` (see §Configuration below). This skill has no hardcoded hostnames.

## Configuration

This skill requires two values from your project's `CLAUDE.md` or environment:

| Variable | Purpose | Example |
|----------|---------|---------|
| `PUPPET_WEB_URL` | Puppetboard external URL | `https://puppetweb.example.com` |
| `PUPPET_MASTER` | Puppet master FQDN for SSH queries | `puppet01.example.com` |
| `DOMAIN_SUFFIX` | DNS domain for IP resolution | `example.com` |

If these are not set, ask the user for them before proceeding.

## Fact Catalog (CHECK FIRST)

**Before doing any live query, check `FACTS.txt`** (in this skill directory) for
the full list of available PuppetDB fact names. This avoids guessing fact names
and wasting queries.

Workflow:
1. Look up the fact name in `FACTS.txt`.
2. If found → use the fact name in a Puppetboard or SSH query.
3. If not found → do a live probe on Puppetboard at
   `<PUPPET_WEB_URL>/facts` (browse all facts) or try the fact name
   directly — new facts may have been added since the catalog was last refreshed.

Commonly used facts (for quick reference; full list in `FACTS.txt`):

| Category | Fact names |
|----------|-----------|
| OS | `os_name`, `osfamily`, `operatingsystem`, `os_distro_release_major`, `os_release_full`, `os_architecture` |
| Hardware | `bios_vendor`, `bios_version`, `bios_release_date`, `is_virtual`, `virtual`, `manufacturer`, `productname`, `serialnumber` |
| Network | `ipaddress`, `ipaddress6`, `hostname`, `domain`, `fqdn`, `networking` |
| Identity | `company`, `env` (custom facts), `project`, `role` |
| Kernel | `kernel`, `kernelrelease`, `kernelversion`, `kernelmajversion` |
| Puppet | `aio_agent_version`, `agent_specified_environment`, `puppetversion` |
| Storage | `blockdevices`, `filesystems`, `mountpoints`, `volume_groups` |
| System | `uptime`, `uptime_seconds`, `memory_mb`, `processors`, `architecture` |

To refresh the catalog, curl the Puppetboard facts page and extract fact names:
```bash
curl -s "${PUPPET_WEB_URL}/facts" \
  | python3 -c '
import sys, re
html = sys.stdin.read()
facts = re.findall(r"<a[^>]*>/fact/([^/]+)/[^<]*</a>", html)
for f in sorted(set(facts)):
    print(f)
print(f"\n--- {len(set(facts))} facts ---")
'
```

## CRITICAL: No inline python3 -c

**NEVER use `python3 -c '...'` inline with bash.** Bash mangles escaped quotes
(`\"`) inside single-quoted strings, causing SyntaxError. Always stage a Python
script file instead:

```bash
# GOOD — staged script
curl -s "${PUPPET_WEB_URL}/*/fact/<fact>/<value>/json" \
  | python3 /tmp/pdb_parse.py

# BAD — breaks with any quotes inside the f-string
curl ... | python3 -c 'import json; data=json.load(sys.stdin); print(data.get("key"))'
```

## Reusable Parser Script

Stage this once per session at `/tmp/pdb_parse.py`:

```python
#!/usr/bin/env python3
"""Parse Puppetboard JSON responses. Usage:
  curl -s <url> | python3 /tmp/pdb_parse.py [--values] [--count]
Modes:
  default  — list sorted certnames (strip HTML tags)
  --values — list certname + value pairs, then value counts
  --count  — count only, no host list
"""
import sys, json, re, argparse
from collections import Counter

parser = argparse.ArgumentParser()
parser.add_argument("--values", action="store_true", help="show value column and counts")
parser.add_argument("--count", action="store_true", help="count only")
args = parser.parse_args()

data = json.load(sys.stdin)
rows = data.get("data", [])

if not rows:
    print(f"0 hosts")
    sys.exit(0)

if args.count:
    print(f"{data.get('recordsTotal', len(rows))} hosts")
    sys.exit(0)

hosts = []
values = []
for row in rows:
    host = re.sub(r"<[^>]+>", "", row[0])
    val = None
    if len(row) > 1 and args.values:
        raw = row[1]
        if isinstance(raw, list) and len(raw) >= 2:
            val = raw[1]
        else:
            val = re.sub(r"<[^>]+>", "", str(raw))
        values.append((host, val))
    hosts.append(host)

if args.values and values:
    for host, val in sorted(values, key=lambda x: x[0]):
        print(f"{host}  {val}")
    print()
    c = Counter(v for _, v in values)
    for val, count in c.most_common():
        print(f"  {val}: {count}")
else:
    for host in sorted(hosts):
        print(host)

print(f"\n--- {len(hosts)} hosts ---")
```

## Method 1: Puppetboard External URL (Preferred)

**No SSH required** — queries run from the local workstation.

### URL Pattern

```
${PUPPET_WEB_URL}/*/fact/<fact_name>/<fact_value>/json
```

**IMPORTANT: Always use the `/*/` environment wildcard prefix.** Without it,
Puppetboard defaults to a single environment scope and filters out hosts from
other control repos.

### Fact name mapping

Puppetboard uses **underscores** (not dots) for structured fact names:

| PuppetDB dot-path | Puppetboard URL path |
|---|---|
| `os.name` | `os_name` |
| `os.distro.release.major` | `os_distro_release_major` |
| `os.family` | `osfamily` |
| `bios_vendor` | `bios_vendor` |
| `operatingsystem` | `operatingsystem` |
| `company` | `company` |

### Single-fact query

```bash
# List hosts with a specific fact value
curl -s "${PUPPET_WEB_URL}/*/fact/<fact_name>/<URL-encoded value>/json" \
  | python3 /tmp/pdb_parse.py
```

### Count only

```bash
curl -s "${PUPPET_WEB_URL}/*/fact/osfamily/Debian/json" \
  | python3 /tmp/pdb_parse.py --count
```

### Distinct fact values (no value filter)

List all values and counts for a fact (use the fact overview page JSON):

```bash
curl -s "${PUPPET_WEB_URL}/*/fact/<fact_name>/json?start=0&length=500" \
  | python3 /tmp/pdb_parse.py --values
```

### Common Puppetboard fact queries

| Fact | Example value | URL suffix |
|------|--------------|------------|
| `os_name` | `Rocky`, `CentOS`, `Debian` | `/fact/os_name/Rocky/json` |
| `osfamily` | `RedHat`, `Debian` | `/fact/osfamily/Debian/json` |
| `os_distro_release_major` | `8`, `9` | `/fact/os_distro_release_major/9/json` |
| `bios_vendor` | `Amazon EC2` | `/fact/bios_vendor/Amazon%20EC2/json` |
| `is_virtual` | `true`, `false` | `/fact/is_virtual/true/json` |
| `virtual` | `kvm`, `vmware`, `physical` | `/fact/virtual/kvm/json` |
| `operatingsystem` | `Rocky`, `CentOS` | `/fact/operatingsystem/Rocky/json` |

**Note**: All URLs above assume the `/*/` wildcard prefix before `/fact/`.

### Puppetboard limitations

- **No compound queries** — each query filters on one fact only. Cannot combine
  OS name + OS version + environment in a single Puppetboard URL.
- **No environment column** — the JSON response only includes certname. Derive
  environment from hostname prefix (see §Environment Derivation).
- **URL-encode values** — spaces become `%20`, special chars must be encoded.

### When to use Method 1 vs Method 2

| Query type | Method |
|---|---|
| Single fact (any value) | **Method 1** (Puppetboard, no SSH) |
| OS name only | **Method 1** |
| List distinct fact values | **Method 1** (omit value from URL, add `?start=0&length=500`) |
| Compound: OS + version + env | **Method 2** (SSH, full PuppetDB API) |
| Environment-only host list | **Method 2** (`facts_environment` filter) |

## Method 2: SSH to Puppet Master (Compound Queries)

For compound queries (OS + version + environment), use the PuppetDB API
directly on the master via SSH.

**PuppetDB API**: `http://localhost:8080/pdb/query/v4/` (on the master)

### Query pattern

SSH quoting makes inline queries fragile. **Always stage a shell script**:

```bash
# 1. Write query script locally
cat > /tmp/pdb_query.sh << 'EOF'
#!/bin/bash
set -euo pipefail
curl -s 'http://localhost:8080/pdb/query/v4/nodes' \
  -G \
  --data-urlencode 'query=<JSON_QUERY_HERE>'
EOF

# 2. SCP + execute
scp /tmp/pdb_query.sh ${PUPPET_MASTER}:/tmp/pdb_query.sh
ssh ${PUPPET_MASTER} "bash /tmp/pdb_query.sh"
```

### Key field names

| Concept | Fact path | Node endpoint field |
|---------|-----------|-------------------|
| OS name | `["fact", "os.name"]` | — |
| OS major version | `["fact", "os.distro.release.major"]` | — |
| Environment | — | `facts_environment` (NOT `environment`) |
| Certname | — | `certname` |

**Critical**: the `nodes` endpoint does not accept `environment` — use
`facts_environment` or `catalog_environment` instead.

### Common compound query templates

```bash
# OS + version + environment
--data-urlencode 'query=["and",
  ["=", ["fact", "os.name"], "<OS_NAME>"],
  ["=", ["fact", "os.distro.release.major"], "<OS_MAJOR>"],
  ["or",
    ["=", "facts_environment", "<ENV1>"],
    ["=", "facts_environment", "<ENV2>"]
  ]
]'

# All hosts in one environment
--data-urlencode 'query=["=", "facts_environment", "<ENV>"]'
```

### Output processing

Pipe the SSH output to the staged parser or a dedicated script — never use
`python3 -c` inline:

```bash
ssh ${PUPPET_MASTER} "bash /tmp/pdb_query.sh" \
  | python3 /tmp/pdb_parse_ssh.py
```

Note: Method 2 output is raw PuppetDB JSON (no HTML tags), so a simple staged
script works well for processing.

## Environment Derivation

When Puppetboard (Method 1) returns certnames without environment, derive
from hostname prefix. **Adapt this table to your environment's naming convention:**

| Hostname prefix | Environment | Example source |
|----------------|-------------|----------------|
| `site-a-dev-*`, `site-a-sit-*` | `infra_sit` | control/infra |
| `site-a-uat-*` | `infra_uat` | control/infra |
| `site-a-mgmt-*` | `infra_prod` | control/infra |
| `site-b-dev-*`, `site-b-sit-*` | `jax_sit` | control/jax |
| `site-b-uat-*` | `jax_uat` | control/jax |
| `site-b-mgmt-*` | `jax_prod` | control/jax |
| `pve*` | `proxmox_prod` | control/proxmox |

Replace `site-a`/`site-b` with your actual site prefixes.

## IP Resolution

After getting the FQDN list, resolve IPs locally:

```bash
for h in host1 host2 host3; do
  ip=$(getent hosts "${h}.${DOMAIN_SUFFIX}" 2>/dev/null | awk '{print $1}')
  printf "FQDN: %-45s IPv4: %s\n" "${h}.${DOMAIN_SUFFIX}." "${ip:-<not found>}"
done
```

## Workflow

1. **Stage `/tmp/pdb_parse.py`** if not already present (use the script above).
2. **Determine filter criteria** from the user's request (OS, version,
   environment, custom fact).
3. **Choose method**: single fact → Puppetboard (Method 1); compound → SSH
   (Method 2).
4. **Execute query** — curl for Method 1; stage script + SCP for Method 2.
5. **Process output** — pipe through `/tmp/pdb_parse.py` or a staged script.
6. **Resolve IPs** if the user needs them (e.g. for hosts.txt).
7. **Report results** — count + sorted list. If appending to a file, offer
   to do so.

## Guardrails

- **Read-only** — this skill only queries, never modifies anything.
- **PROD queries are allowed** — listing hosts is safe.
- **No auth needed** — Puppetboard is externally accessible; PuppetDB via SSH
  uses standard SSH access.
- **Never use `python3 -c`** for non-trivial inline Python — bash quoting
  breaks escaped quotes. Always stage a script file.

## See also

- `srepowers:puppet-code-analyzer` — code quality analysis for Puppet manifests
- `srepowers:hiera-debugging` — trace Hiera data resolution (srepowers-private)
- `srepowers:puppet-deploy` — fleet noop/apply execution (srepowers-private)
