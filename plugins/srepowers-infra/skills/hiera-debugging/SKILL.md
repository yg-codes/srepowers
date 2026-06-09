---
name: hiera-debugging
description: Use when debugging Hiera data lookups in Puppet — tracing why a key resolves to an unexpected value, diagnosing hierarchy misresolution, validating Hiera data against class parameter types, or using puppet lookup and hiera-validator to investigate data binding failures. Also use for "why does Hiera return X", "hiera lookup wrong value", "puppet lookup debug", "hierarchy not matching", "hiera-validator", "data binding failure", "parameter type mismatch", or any Hiera data investigation.
---

# Hiera Debugging

Diagnose and fix Hiera data resolution issues in Puppet environments. Traces key lookups through the hierarchy, validates data types against class parameters, and identifies mismatches between Hiera data and Puppet code expectations.

**Core principle:** Trace before guessing. Use `puppet lookup` to see what Hiera actually resolves, then compare against what the class expects.

**Announce at start:** "I'm using the hiera-debugging skill to debug Hiera data resolution."

## When to Use

**Use when:**
- A Puppet class receives an unexpected parameter value
- `puppet agent -t` fails with "expected X, got Y" type errors
- Hiera data was changed but the agent run doesn't reflect it
- Adding a new parameter to a class and Hiera data doesn't bind
- Moving Hiera data between environments (sit → uat → prod)
- Reviewing a `hiera.yaml` hierarchy change
- Running `hiera-validator` and getting type mismatch errors

**Exceptions:**
- Simple "what value does this key have?" queries — just run `puppet lookup` directly
- Puppet catalog compilation errors that aren't Hiera-related — use `systematic-troubleshooting`

## The Investigation Flow

### Step 1: Reproduce the Problem

Identify the exact key and the host where it fails:

```bash
# On puppet master — look up the key for the specific node
ssh fsx-mgmt-puppet01.fsx.zone \
  "sudo puppet lookup --environment <env> --node <node_fqdn> <key>"

# With explain — shows the full resolution path
ssh fsx-mgmt-puppet01.fsx.zone \
  "sudo puppet lookup --environment <env> --node <node_fqdn> <key> --explain"
```

The `--explain` output shows:
- Which hierarchy levels were checked
- Which data source provided the value
- Which paths were searched at each level
- Whether a path was skipped (missing file, no key)

### Step 2: Check the Hierarchy

Read the `hiera.yaml` for the environment:

```bash
ssh fsx-mgmt-puppet01.fsx.zone \
  "cat /etc/puppetlabs/code/environments/<env>/hiera.yaml"
```

Verify the hierarchy levels match expectations. Common issues:
- `facts.<fact>` references a fact that doesn't exist on the node
- `environment` level is missing or misordered
- Custom fact used in hierarchy not deployed to the node

### Step 3: Trace the Data Path

Walk the hierarchy manually to find where the value comes from:

```bash
# Check each level of the hierarchy
# Level 1: node-specific
ssh fsx-mgmt-puppet01.fsx.zone \
  "cat /etc/puppetlabs/code/environments/<env>/data/nodes/<node_fqdn>.yaml 2>/dev/null | grep '<key>'"

# Level 2: role (if using role/profile pattern)
ssh fsx-mgmt-puppet01.fsx.zone \
  "cat /etc/puppetlabs/code/environments/<env>/data/roles/<role>.yaml 2>/dev/null | grep '<key>'"

# Level 3: common
ssh fsx-mgmt-puppet01.fsx.zone \
  "cat /etc/puppetlabs/code/environments/<env>/data/common.yaml 2>/dev/null | grep '<key>'"
```

### Step 4: Validate Types

Compare the Hiera value against the class parameter type:

```bash
# Get the class parameter type declaration
grep -A2 "<parameter>" ~/src/fsx/puppet/modules/<module>/manifests/<file>.pp

# Get the actual resolved value
ssh fsx-mgmt-puppet01.fsx.zone \
  "sudo puppet lookup --environment <env> --node <node_fqdn> <class>::<parameter> --render-as json"
```

**Common type mismatches:**

| Puppet type | Hiera value should be | Common mistake |
|-------------|----------------------|----------------|
| `String` | `"value"` (quoted) | Unquoted string in YAML |
| `Integer` | `8080` (number) | `"8080"` (string) |
| `Boolean` | `true` / `false` (no quotes) | `"true"` (string) |
| `Array[String]` | `["a", "b"]` | Single string instead of array |
| `Hash` | `{key: value}` | Array of hashes instead |
| `Optional[String]` | `null` or string | Empty string `""` vs `null` |
| `Variant[String, Integer]` | Either type | Confusion about which variant |

### Step 5: Validate with hiera-validator

If the `hiera-validator` tool is available:

```bash
# Validate all Hiera data against class parameter types
~/src/fsx/it/sre/hiera-validator/bin/hiera-validator \
  --hiera-data /path/to/data/ \
  --module-path /path/to/modules/ \
  --environment <env>
```

This catches:
- Keys that don't match any class parameter
- Type mismatches between Hiera values and parameter declarations
- Missing required parameters (no default, no Hiera value)

### Step 6: Fix and Verify

Apply the fix to the correct hierarchy level, then verify:

```bash
# Re-run lookup to confirm the fix
ssh fsx-mgmt-puppet01.fsx.zone \
  "sudo puppet lookup --environment <env> --node <node_fqdn> <key>"

# Run noop on the affected node to confirm no compilation errors
ssh <node_fqdn> 'sudo ppr --environment <env>'
```

## Common Failure Patterns

### Pattern 1: Wrong hierarchy level

**Symptom:** Key resolves from `common.yaml` instead of node-specific file.

**Cause:** Node-specific YAML file has a typo in the filename, or the hierarchy level for nodes is below `common`.

**Fix:** Check the filename matches the node's certname exactly (including domain).

### Pattern 2: YAML syntax error

**Symptom:** Key returns `nil` / undef despite being in the file.

**Cause:** YAML parsing error silently returns nil. Common issues: tabs instead of spaces, missing colon, unquoted special characters.

**Fix:**
```bash
# Validate YAML syntax
ruby -e "require 'yaml'; YAML.load_file('data/nodes/host.yaml')"
# Or use yamllint
yamllint data/nodes/host.yaml
```

### Pattern 3: Automatic lookup key mismatch

**Symptom:** Class parameter not receiving Hiera value.

**Cause:** Hiera key doesn't follow `<class>::<parameter>` convention. Remember the key must be lowercase with double-colon separator.

**Fix:** Verify the key name matches exactly:
```bash
# Class parameter
class mymodule::config (
  Integer $port,
) { ... }

# Hiera key must be
mymodule::config::port: 8080
```

### Pattern 4: Environment cache stale

**Symptom:** Changed Hiera data not reflected in lookups.

**Cause:** Puppet master caches the environment. g10k deploys are usually immediate but the Puppet master may need to reload.

**Fix:**
```bash
# Check g10k deploy timestamp
ssh fsx-mgmt-puppet01.fsx.zone \
  "cat /etc/puppetlabs/code/environments/<env>/.g10k-deploy.json"

# Force g10k redeploy if needed
ssh fsx-mgmt-puppet01.fsx.zone \
  "sudo -u puppet /opt/puppetlabs/puppet/bin/g10k -config /etc/puppetlabs/g10k/g10k.yaml"
```

## Integration

**Called by:**
- `srepowers:puppet-deploy` — during the Hiera validation step
- `srepowers:puppet-code-analyzer` — when validating Hiera data quality
- `srepowers:systematic-troubleshooting` — when investigating Puppet failures

**Pairs with:**
- `srepowers:puppet-merge-request` — for promoting Hiera data changes
- `srepowers:test-driven-operation` — for verification commands

## SRE Principles

### Safety First
- Debug with `puppet lookup --explain` — read-only, no changes
- Never modify Hiera data on the puppet master directly — edit in the control repo, push, let g10k deploy

### Structured Output
- Present findings as: key → expected value → actual value → resolution path → fix
- Use tables for multi-key investigations

### Evidence-Driven
- Capture `--explain` output as evidence
- Show before/after lookup results when a fix is applied

### Audit-Ready
- Record the exact key, node, environment, and resolution path for every investigation
- Note the hierarchy level that provided the value

### Communication
- Explain hierarchy resolution in plain terms: "the value came from common.yaml because the node-specific file didn't contain this key"
- Surface type mismatches with the exact Puppet type expected vs. the YAML value provided
