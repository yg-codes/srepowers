# puppet-fact-query

Query PuppetDB for hosts matching OS, environment, hardware, or custom fact
criteria, returning sorted host lists with FQDNs, IPs, and environments.
Two access methods: the Puppetboard external URL (preferred) or SSH to the
puppet master for compound queries. Ships as
`srepowers-infra:puppet-fact-query`. (`SKILL.md` is the agent-facing trigger
doc; this file is for humans.)

## Use cases

- List hosts by fact criteria — "how many rocky 9 in prod", "list servers
  where bios_vendor is Amazon EC2", "show centos uat hosts"
- Get the distinct values a fact takes across the fleet, or just a count
- Run compound queries (fact + environment) via SSH to the puppet master
- Check a fact name is real before querying, using the fact catalog

## How-to

In Claude Code or Codex, just ask for the hosts — "query puppet facts",
"get puppet hosts", "list rocky 8 sit servers" — or invoke it directly as
the `srepowers-infra:puppet-fact-query` command. Requires two values set in
your project's `CLAUDE.md` or environment (the skill has no hardcoded
hostnames):

| Variable | Purpose |
|----------|---------|
| `PUPPET_WEB_URL` | Puppetboard external URL (method 1, preferred) |
| `PUPPET_MASTER` | Puppet master for SSH compound queries (method 2) |

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — both query methods with URL/query patterns; the
  environment-is-read-never-derived rule; result-validity rules (freshness
  and what a query structurally cannot see); workflow and accuracy checklist
- `FACTS.txt` — full catalog of available PuppetDB fact names, checked
  before any live query (refreshable via the Puppetboard facts page).
  Per-interface and per-CPU facts are templated (`mtu_<interface>`,
  `processor<N>`): a raw dump encodes the source host's VLAN and VM IDs

---
Last Updated: 2026-09-14
