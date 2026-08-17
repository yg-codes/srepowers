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

# Truncation guard: the payload states how many records exist. If we received
# fewer, the caller is about to act on a partial fleet — say so, loudly.
total = data.get("recordsTotal")
if total is not None and len(rows) != total:
    print(f"WARNING: received {len(rows)} rows but recordsTotal={total} "
          f"— result is TRUNCATED, re-query with ?start=0&length={total + 100}",
          file=sys.stderr)

if not rows:
    print("0 hosts")
    sys.exit(0)

if args.count:
    print(f"{data.get('recordsTotal', len(rows))} hosts")
    sys.exit(0)

def parse_value(raw):
    """Puppetboard returns the value cell as a JSON-ENCODED STRING of the form
    '["<href>", "<value>"]' — NOT a Python list. isinstance(raw, list) is
    therefore False and a naive str() emits the whole blob as the value.
    Decode it, then fall back to tag-stripping."""
    if isinstance(raw, list) and len(raw) >= 2:
        return raw[1]
    s = re.sub(r"<[^>]+>", "", str(raw)).strip()
    if s.startswith("["):
        try:
            decoded = json.loads(s)
            if isinstance(decoded, list) and len(decoded) >= 2:
                return decoded[1]
        except (ValueError, TypeError):
            pass
    return s

hosts = []
values = []
for row in rows:
    host = re.sub(r"<[^>]+>", "", row[0])
    if len(row) > 1 and args.values:
        values.append((host, parse_value(row[1])))
    hosts.append(host)

# TSV output: machine-readable, safe to pipe into cut/awk/join.
if args.values and values:
    for host, val in sorted(values, key=lambda x: x[0]):
        print(f"{host}\t{val}")
else:
    for host in sorted(hosts):
        print(host)

# Summary goes to STDERR so it never contaminates a piped data stream.
if args.values and values:
    print("", file=sys.stderr)
    for val, count in Counter(v for _, v in values).most_common():
        print(f"  {val}: {count}", file=sys.stderr)
print(f"--- {len(hosts)} hosts ---", file=sys.stderr)
```

**Three defects this version fixes** — each produced wrong output in real use:

1. **The value column was emitted raw.** Puppetboard sends
   `'["/*/fact/kernelrelease/%22...%22", "5.14.0-687.36.1.el9_8.x86_64"]'` as a
   **JSON-encoded string**, so the `isinstance(raw, list)` test never fires and
   the `else` branch prints the whole blob. Measured: **285/285 rows malformed**
   before the fix, 0 after. Every `--values` count was consequently wrong.
2. **Two-space separator, now a tab.** `f"{host}  {val}"` cannot be split
   reliably (`cut -f2` fails; values may contain spaces). TSV is parseable.
3. **The summary was on stdout.** The `--- N hosts ---` footer and the value
   counts landed in any file the caller redirected, so downstream `sort`/`comm`
   silently ingested them as data rows. They now go to stderr — still visible in
   a terminal, invisible to a pipe.

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
- **No environment column** — the JSON response is `[certname_html, value_html]`
  only. Do **not** fall back to hostname-prefix guessing for anything grouped or
  scheduled by env; join to `facts_environment` instead (see §Environment: read
  the fact, do not derive it).
- **The value cell is a JSON-encoded string**, not a list — see the parser note.
- **Assert completeness, don't assume it.** The response carries
  `recordsTotal`; **check `len(data) == recordsTotal`** rather than trusting the
  row count. (Measured on one instance: the default page returned all 285 rows
  untruncated, so `?start=0&length=<N>` was not required there — but that is an
  instance/version behaviour, not a guarantee. The assertion costs nothing and
  catches truncation wherever it does occur.)
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

## Environment: read the fact, do not derive it

> **A hostname is a naming convention. An environment is a fact.** Deriving one
> from the other works until it silently doesn't, and the failure mode is a
> host **dropping out of scope with no error**.

**MUST: get environment from PuppetDB `facts_environment`, not the hostname**,
whenever the answer will be grouped, counted, or scheduled by environment.

The cheapest way is one extra call to the `nodes` endpoint, joined locally to
the Method 1 fact results. `nodes` returns `certname` **and**
`facts_environment` for every node in a single request:

```bash
# 1. Fact values (Method 1, no SSH)
curl -s "${PUPPET_WEB_URL}/*/fact/<fact>/json?start=0&length=1000" \
  | python3 /tmp/pdb_parse.py --values > /tmp/facts.tsv

# 2. Authoritative env map (one call, via the master)
cat > /tmp/pdb_nodes.sh <<'EOF'
#!/bin/bash
set -euo pipefail
curl -s 'http://localhost:8080/pdb/query/v4/nodes'
EOF
scp -q /tmp/pdb_nodes.sh ${PUPPET_MASTER}:/tmp/pdb_nodes.sh
ssh ${PUPPET_MASTER} 'bash /tmp/pdb_nodes.sh' > /tmp/pdb_nodes.json

# 3. Join locally (stage a script — never inline python3 -c)
python3 /tmp/pdb_join_env.py /tmp/pdb_nodes.json /tmp/facts.tsv
```

Stage `/tmp/pdb_join_env.py`:

```python
#!/usr/bin/env python3
"""Join fact TSV (certname<TAB>value) to authoritative facts_environment.
Usage: pdb_join_env.py <nodes.json> <facts.tsv> [--collapse-topic-branches]
Emits: env<TAB>value<TAB>certname   (sorted)
Any host absent from nodes.json is emitted with env '<absent>' — never guessed.
"""
import sys, json

nodes_path, facts_path = sys.argv[1], sys.argv[2]
collapse = "--collapse-topic-branches" in sys.argv

env = {}
for n in json.load(open(nodes_path)):
    env[n["certname"]] = n.get("facts_environment") or "<none>"

out, absent = [], 0
for line in open(facts_path):
    line = line.rstrip("\n")
    if not line or "\t" not in line:
        continue
    cert, val = line.split("\t", 1)
    e = env.get(cert)
    if e is None:
        e, absent = "<absent>", absent + 1
    # A topic-branch env (infra_cu_*, jax_mr_*) is a transient Puppet pin, not
    # a different estate. Collapse ONLY when explicitly asked, and only to the
    # base env implied by the same prefix the branch env already carries.
    if collapse and ("_cu_" in e or "_mr_" in e):
        e = e.split("_cu_")[0].split("_mr_")[0] + "_<base>"
    out.append((e, val, cert))

for row in sorted(out):
    print("\t".join(row))
if absent:
    print(f"WARNING: {absent} host(s) had no PuppetDB node entry "
          f"— emitted as '<absent>', NOT guessed.", file=sys.stderr)
```

### Why this matters (measured failure, 2026-08-17)

A fleet query classified environment by matching the hostname against
`fsx-*`/`jax-*`/`ixj-*`. Nine production hosts used a **different naming
scheme** (`ninja-rolx-*`), matched no pattern, and fell into a catch-all
bucket — reported as "no environment" and excluded from the six env lines of a
168-host upgrade worklist. All nine had correct `facts_environment` values
(`infra_prod` / `infra_sit` / `infra_uat`) in PuppetDB the whole time. Three
were on an unpatched EL minor and needed a **full OS upgrade**, not the
z-stream bump the rest of their group got. Corrected scope: **177 hosts**.

Two related traps in the same data:

- **Topic-branch environments.** A host mid-ticket reads
  `infra_cu_1234_feature` / `jax_mr_…`, not `infra_sit`. That is a transient
  Puppet pin — collapse it to the base env **for scheduling**, but never treat
  it as a different estate, and never let it silently become `<absent>`.
- **Stock `production`.** A host that never had its environment set reads
  `production`. It is a real value and a real signal — usually a
  misconfiguration worth reporting, not normalising away.

### Fallback only: hostname derivation

Use the prefix table **only** when no fact source is reachable — e.g. deriving
a `--environment` flag for a one-off `ppr` on a single known host. Adapt to
your naming convention:

| Hostname prefix | Environment | Example source |
|----------------|-------------|----------------|
| `site-a-dev-*`, `site-a-sit-*` | `site_a_sit` | control/site-a |
| `site-a-uat-*` | `site_a_uat` | control/site-a |
| `site-a-mgmt-*` | `site_a_prod` | control/site-a |
| `site-b-dev-*`, `site-b-sit-*` | `site_b_sit` | control/site-b |
| `site-b-uat-*` | `site_b_uat` | control/site-b |
| `site-b-mgmt-*` | `site_b_prod` | control/site-b |
| `pve*` | `proxmox_prod` | control/proxmox |

**If you use this table on a fleet, you MUST report the count of hosts that
matched no pattern.** A silent catch-all bucket is how hosts disappear.

## IP Resolution

After getting the FQDN list, resolve IPs locally:

```bash
for h in host1 host2 host3; do
  ip=$(getent hosts "${h}.${DOMAIN_SUFFIX}" 2>/dev/null | awk '{print $1}')
  printf "FQDN: %-45s IPv4: %s\n" "${h}.${DOMAIN_SUFFIX}." "${ip:-<not found>}"
done
```

## Result validity: freshness and absence

PuppetDB answers *"what did agents last report?"* — **not** *"what is true
now?"* and **not** *"what hosts exist?"*. Both gaps are invisible in the
output: a stale fact and a fresh fact look identical, and a host that never
reported simply is not in the list. When the result will drive scheduling,
sizing, or a change window, **check both**.

### Freshness — one call, always worth it

```bash
# Age of every node's last report (uses /tmp/pdb_nodes.json from above).
# Pass the current time explicitly — never let a script guess it.
python3 /tmp/pdb_stale.py /tmp/pdb_nodes.json "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

```python
#!/usr/bin/env python3
"""Bucket PuppetDB nodes by report age.
Usage: pdb_stale.py <nodes.json> <now_iso_utc>"""
import sys, json
from datetime import datetime

now = datetime.fromisoformat(sys.argv[2].replace("Z", "+00:00"))
rows = []
for n in json.load(open(sys.argv[1])):
    rt = n.get("report_timestamp")
    age = ((now - datetime.fromisoformat(rt.replace("Z", "+00:00"))).total_seconds() / 3600
           if rt else None)
    rows.append((n["certname"], n.get("facts_environment"), age))

def bucket(a):
    return "never" if a is None else "fresh" if a < 1 else "late" if a < 24 else "stale"

for b in ("fresh", "late", "stale", "never"):
    print(f"  {b:6s}: {sum(1 for r in rows if bucket(r[2]) == b)}")
print("\n=== not fresh ===")
for c, e, a in sorted((r for r in rows if bucket(r[2]) != "fresh"),
                      key=lambda r: -(r[2] or 1e9)):
    print(f"  {a:8.1f}h  {c:45s} {e}" if a else f"     never  {c:45s} {e}")
```

Compare the spread against the configured interval — get it from the master,
do not assume 30 min:

```bash
ssh ${PUPPET_MASTER} 'puppet config print runinterval splay splaylimit --section agent'
```

**A tight cluster of identical ages is a signal, not noise.** Measured
2026-08-17: `runinterval=1800` with `splay=false`, yet 248 of 285 nodes had
last reported inside one 49-minute window ~4.5 h earlier — agents were not
running on the interval the config claimed. The fact data was still usable for
planning, but every value was hours old, and two hosts were >24 h stale and had
to be re-read on the host before scheduling.

### Absence — what the query structurally cannot see

- **A powered-off host** either carries stale facts or is missing entirely. A
  fleet count taken while hosts are down is an undercount that reads exactly
  like a complete list. (Measured: a 281-node query missed four hosts that were
  powered off overnight; the re-query next morning returned 285.)
- **A host with no Puppet agent is invisible by construction.** No PuppetDB
  query can find it. Closing that gap needs an external inventory — DNS zone
  file, NetBox, hypervisor VM list, cloud API — diffed against the certname
  set. Note that each has its own blind spot (DNS misses unregistered hosts; a
  hypervisor list misses cloud instances), so **state which inventory you used
  and what it cannot see.**
- **A host reporting to a different PuppetDB.** A separate dev/lab Puppet
  master's agents do not appear in the estate PuppetDB at all — they are not
  "unenrolled", just enrolled elsewhere.

**MUST: state the query time and node count** with any fleet result, and say
explicitly whether freshness was checked. A count with no timestamp is an
assertion nobody can verify later.

## Workflow

1. **Stage `/tmp/pdb_parse.py`** if not already present (use the script above).
2. **Determine filter criteria** from the user's request (OS, version,
   environment, custom fact).
3. **Choose method**: single fact → Puppetboard (Method 1); compound → SSH
   (Method 2).
4. **Execute query** — curl for Method 1; stage script + SCP for Method 2.
5. **Process output** — pipe through `/tmp/pdb_parse.py` or a staged script.
6. **Attach environment from `facts_environment`** if the answer is grouped,
   counted, or scheduled per env — never from the hostname.
7. **Check freshness** (and report it) when the result drives scheduling,
   sizing, or a change window.
8. **Resolve IPs** if the user needs them (e.g. for hosts.txt).
9. **Report results** — query time, node count, sorted list, and any
   unmatched/stale/absent hosts. If appending to a file, offer to do so.

## Accuracy checklist

Run through this before presenting any fleet-wide result. Each line is a real
defect that shipped a wrong answer:

- [ ] `len(data) == recordsTotal` — result is not truncated
- [ ] Values are decoded, not raw `["<href>", "<value>"]` blobs
- [ ] Environment came from `facts_environment`, not a hostname pattern
- [ ] Hosts matching **no** classification rule are **counted and named**, not
      dropped into a silent catch-all
- [ ] Topic-branch envs (`*_cu_*`, `*_mr_*`) and stock `production` handled
      deliberately
- [ ] Report freshness checked against the configured `runinterval`
- [ ] Totals in any table are **tool-computed**, and row sums, column sums and
      the grand total agree
- [ ] Query timestamp and node count stated in the answer
- [ ] Stated what the query **cannot** see (powered-off, unenrolled, other
      PuppetDB)

## Guardrails

- **Read-only** — this skill only queries, never modifies anything.
- **PROD queries are allowed** — listing hosts is safe.
- **No auth needed** — Puppetboard is externally accessible; PuppetDB via SSH
  uses standard SSH access.
- **Never use `python3 -c`** for non-trivial inline Python — bash quoting
  breaks escaped quotes. Always stage a script file.
- **Never present a derived environment as if it were queried.** If the fact
  was unavailable and the hostname was used, say so in the output.
- **A fact is a report, not the live system.** For anything that gates a
  change, re-read the value on the host before acting on it.

## See also

- `srepowers-infra:puppet-code-analyzer` — code quality analysis for Puppet manifests
- `srepowers-private:hiera-debugging` — trace Hiera data resolution (srepowers-private)
- `srepowers-private:puppet-deploy` — fleet noop/apply execution (srepowers-private)
