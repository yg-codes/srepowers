# Puppet Style Guide

## Overview

This document defines the coding standards and conventions for Puppet manifests in the FSX infrastructure. Follow these guidelines to ensure consistency, maintainability, and collaboration across teams.

## Naming Conventions

### Class Names

**Use lowercase with underscores:**

```puppet
# Good
class profile::web_server { }

class role::frontend { }

class fsx_dns::config { }

# Bad
class Profile::WebServer { }
class profile::webServer { }
class profile-web-server { }
```

**Pattern:** `[module_namespace]::[subpackage]::[classname]`

### Resource Types and Titles

**Resource types: lowercase**

```puppet
# Good
package { 'nginx': }
service { 'nginx': }
file { '/etc/nginx/nginx.conf': }

# Bad
Package { 'nginx': }
```

**Resource titles: descriptive and unique**

```puppet
# Good
file { '/etc/nginx/nginx.conf':
  ensure => file,
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
}

# Bad
file { 'nginx_config':  # Not descriptive enough
  path => '/etc/nginx/nginx.conf',
}
```

### Parameters

**Use descriptive names with snake_case:**

```puppet
# Good
class profile::web_server (
  String $web_server_package,
  Integer $port_number,
  Boolean $enable_ssl,
) { }

# Bad
class profile::web_server (
  String $pkg,
  Integer $p,
  Boolean $ssl,
) { }
```

## Code Organization

### Class Structure

**Order class components consistently:**

1. Class definition and parameters
2. Include/require statements
3. Local variables
4. Resource declarations
5. Relationships between resources

```puppet
class profile::web_server (
  String $web_server_package = 'nginx',
  Integer $port_number       = 80,
  Boolean $enable_ssl        = false,
) {

  # Dependencies first
  include profile::firewall
  require fsx_epel::repo

  # Local variables
  $config_file = '/etc/nginx/nginx.conf'

  # Resource declarations
  package { $web_server_package:
    ensure => installed,
  }

  file { $config_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package[$web_server_package],
    notify  => Service['nginx'],
  }

  service { 'nginx':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
  }
}
```

### Module Structure

**Standard Puppet module layout:**

```
fsx_module/
├── manifests/
│   ├── init.pp              # Main class
│   ├── install.pp           # Installation
│   ├── config.pp            # Configuration
│   └── service.pp           # Service management
├── templates/
│   └── module_config.erb    # ERB templates
├── files/
│   └── static_file.conf     # Static files
├── hiera.yaml               # Hiera configuration
└── metadata.json            # PDK metadata
```

## Syntax and Formatting

### Quotes

**Prefer single quotes for static strings:**

```puppet
# Good
package { 'nginx': }
$version = '1.18.0'

# Use double quotes only when needed
$message = "Server running on port ${port_number}"
$escaped = "Use \"double quotes\" inside"
```

### Indentation

**Use 2 spaces for indentation:**

```puppet
class profile::web_server (
  String $package_name,
) {
  package { $package_name:
    ensure => installed,
  }

  file { '/etc/config':
    ensure => file,
  }
}
```

### Alignment

**Align resource attributes for readability:**

```puppet
file { '/etc/nginx/nginx.conf':
  ensure  => file,
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  source  => 'puppet:///modules/fsx_nginx/nginx.conf',
  require => Package['nginx'],
}
```

## Resource Relationships

### Prefer Chaining Arrows

**Use chaining arrows for clarity:**

```puppet
# Good - chaining arrows
Package['nginx'] -> File['/etc/nginx/nginx.conf'] ~> Service['nginx']

# Equivalent but less readable
package { 'nginx':
  before  => File['/etc/nginx/nginx.conf'],
}
file { '/etc/nginx/nginx.conf':
  notify  => Service['nginx'],
}
```

### Relationship Operators

| Operator | Meaning |
|----------|---------|
| `->` | Apply before (ordering) |
| `~>` | Notify (refresh on change) |
| `<-` | Apply after (reverse ordering) |
| `<~` | Subscribe (reverse notify) |

**Choose the right relationship:**

```puppet
# Ordering: ensure software before config
Package['nginx'] -> File['/etc/nginx/nginx.conf']

# Notification: reload service on config change
File['/etc/nginx/nginx.conf'] ~> Service['nginx']

# Combined: order then notify
Package['nginx'] -> File['/etc/nginx/nginx.conf'] ~> Service['nginx']
```

## Parameter Handling

### Type Specifications

**Always specify parameter types:**

```puppet
# Good
class profile::web_server (
  String[1]  $package_name,
  Integer[1,65535] $port,
  Boolean    $enable_ssl,
  Array[String] $virtual_hosts,
) { }

# Bad - no types
class profile::web_server (
  $package_name,
  $port,
  $enable_ssl,
) { }
```

### Default Values

**Provide sensible defaults:**

```puppet
class profile::web_server (
  String $package_name = 'nginx',
  Integer $port_number = 80,
  Boolean $enable_ssl  = false,
) { }
```

### Data Types

**Use appropriate Puppet data types:**

| Type | Usage |
|------|-------|
| `String` | Text values |
| `Integer` | Whole numbers |
| `Float` | Decimal numbers |
| `Boolean` | true/false |
| `Array` | Lists |
| `Hash` | Key-value pairs |
| `Optional[Type]` | Can be undef |
| `Enum['a','b']` | Specific values |

## Hiera Integration

### Prefer Automatic Parameter Lookup

**Use automatic lookup instead of hiera() function:**

```puppet
# Good - automatic lookup
class profile::web_server (
  String $web_server_package = 'nginx',  # overridden by Hiera
  Integer $port_number       = 80,       # overridden by Hiera
) {
  package { $web_server_package: }
}

# Bad - manual hiera() call
class profile::web_server {
  $package = hiera('profile::web_server::web_server_package', 'nginx')
  package { $package: }
}
```

**Hiera data structure:**

```yaml
# data/common.yaml
profile::web_server::web_server_package: 'nginx'
profile::web_server::port_number: 80
profile::web_server::enable_ssl: false

# data/role/frontend.yaml
profile::web_server::port_number: 8080
profile::web_server::enable_ssl: true
```

### Hiera YAML String Quoting

**Always quote string values in Hiera YAML.** Single quotes by default; double quotes only where required.

Applies to every string value — mapping values and sequence items, including class names under `classes:`. Keys stay unquoted. Non-strings (booleans, integers, floats) stay unquoted so typed class parameters bind correctly.

```yaml
# Good
classes:
  - 'profile::web_server'
profile::web_server::admin_key: 'ssh-ed25519 AAAA... admin@host'
profile::web_server::instance: "%{facts.hostname}-web"   # %{} interpolation → double
profile::web_server::port_number: 8080                   # integer, not a string
profile::web_server::enable_ssl: true                    # boolean, not a string

# Bad — unquoted strings (fragile YAML 1.1 behavior)
profile::web_server::admin_key: ssh-ed25519 AAAA... admin@host
profile::web_server::alert_url: https://alert.example.com?token=abc&channel=x
profile::web_server::country: no        # parses as boolean false, not 'no'
# Bad — double quotes where single suffice
profile::web_server::timeout: "40s"
```

**Double quotes are required for:** Hiera `%{}` interpolation (convention — visually flags interpolated values), strings containing single quotes, escape sequences.

**Why — Psych (YAML 1.1) semantics:** Puppet parses Hiera with Ruby Psych, not YAML 1.2: unquoted `yes`/`no`/`on`/`off` become booleans (the Norway problem), `1:23` becomes the integer 83 (sexagesimal), and values starting with `%`/`&`/`*` break parsing. When validating data types or doing bulk YAML rewrites, verify semantic equivalence with **Psych** (`ruby -ryaml -e 'p YAML.unsafe_load_file(f)'`) — PyYAML and YAML 1.2 parsers resolve these scalars differently and will mislead you.

**Enforcement:** control repos carry `quoted-strings: {quote-type: any, required: true}` in `.yamllint.yml`; `yamllint --strict data/` fails on unquoted string values.

### eYAML / ENC Value Handling

- Never reflow, re-wrap, or collapse line-wrapped `ENC[PKCS7,...]` blobs — preserve their original folding verbatim. Collapsing is value-identical (YAML folds line breaks to spaces) but introduces spaces into the long line, breaking yamllint's non-breakable-word line-length exemption.
- Folded block scalar entries (`key: >`) legitimately carry a trailing newline in the parsed value — validation regexes must allow `\]\s*\z`, not anchor on `\]\z`, or healthy values get false-flagged.
- Treat ENC values as ordinary YAML strings for quoting purposes; hiera-eyaml tolerates embedded whitespace in the ciphertext.

## Best Practices

### Idempotence

**Ensure resources are idempotent:**

```puppet
# Good - uses ensure
file { '/tmp/myfile':
  ensure => file,
}

# Bad - assumes file doesn't exist
exec { 'create file':
  command => 'touch /tmp/myfile',
  unless  => 'test -f /tmp/myfile',  # Complex workaround
}
```

### Resource Defaults

**Set resource defaults at class scope:**

```puppet
class profile::web_server {
  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  file { '/etc/nginx/nginx.conf': }
  file { '/etc/nginx/conf.d/default.conf': }
}
```

### Conditional Logic

**Use selectors for simple conditions:**

```puppet
# Good - selector (Puppet 6+ facts syntax)
$web_root = $facts['os']['family'] ? {
  'Debian' => '/var/www',
  'RedHat' => '/var/www/html',
  default  => '/var/www',
}

# Acceptable - case statement
case $facts['os']['family'] {
  'Debian': { $package = 'apache2' }
  'RedHat': { $package = 'httpd' }
  default: { fail("Unsupported OS family: ${facts['os']['family']}") }
}
```

## Common Anti-Patterns to Avoid

### Hardcoding Values in Manifests

```puppet
# Bad - literal values in manifest
file { '/etc/app/config.conf':
  content => 'server_ip=192.168.1.100
port=8080',
}

# Good - use EPP template with parameters
file { '/etc/app/config.conf':
  content => epp('profile/config.conf.epp'),
}
```

### Hardcoding Values in Hiera Data

Hardcoding environment-specific or sensitive values directly in Hiera YAML files is an anti-pattern — it makes data non-portable, leaks secrets into version control, and breaks across environments.

**Hardcoded IPs and hostnames:**

```yaml
# Bad - hardcoded in common.yaml
profile::app::db_host: '10.0.1.45'
profile::app::lb_vip:  '10.0.2.10'

# Good - use facts or trusted data
profile::app::db_host: "%{facts.networking.domain}-db01.%{facts.networking.domain}"

# Better - define in the correct Hiera level (per-environment or per-datacenter)
# data/nodes/appserver01.yaml
profile::app::db_host: 'db01.prod.example.com'
```

**Hardcoded secrets (passwords, tokens, keys):**

```yaml
# Bad - plaintext secret in Hiera
profile::app::db_password: 'S3cr3tP@ssw0rd'
profile::app::api_key:     'abc123xyz'

# Good - use hiera-eyaml for encrypted values
profile::app::db_password: >
  ENC[PKCS7,MIIBeQYJKoZIhvcNAQcDoIIBajCCAWYCAQAxggEhMIIBHQIBAD...]

# Or use a secrets backend (Vault, AWS SSM)
profile::app::db_password: "%{lookup('vault_secret::app/db/password')}"
```

**Hardcoded package versions:**

```yaml
# Bad - pinned to a specific build that may disappear
profile::app::version: '2.3.1-1ubuntu0.1'

# Good - use 'installed' or 'latest', pin only when required
profile::app::version: 'installed'

# If version pinning is required, document why
profile::app::version: '2.3.1'  # pinned: CVE-2024-XXXX fix not yet in 2.3.2
```

**Hardcoded environment names:**

```yaml
# Bad - environment baked into common data
profile::app::env: 'production'

# Good - derive from trusted facts or Hiera hierarchy path
# hiera.yaml hierarchy level handles this automatically:
# - name: "Environment data"
#   path: "env/%{server_facts.environment}.yaml"
```

**Detection:** The `check_best_practices.py` script flags:
- IP address literals (`\d+\.\d+\.\d+\.\d+`) in Hiera YAML values
- Keys matching `password`, `secret`, `token`, `key`, `credential` with plaintext values
- Version strings with build suffixes (e.g., `1.2.3-ubuntu0.4`) in non-pinned contexts

### Command Execution

```puppet
# Bad - shell commands when native resources exist
exec { 'install nginx':
  command => 'apt-get install -y nginx',
}

# Good - use package resource
package { 'nginx':
  ensure => installed,
}
```

### Complex Conditionals

```puppet
# Bad - deeply nested
if $ssl {
  if $firewall {
    if $os == 'Debian' {
      ...
    }
  }
}

# Good - use selectors or early returns
$ssl_config = $ssl ? {
  true  => $firewall_config,
  false => {},
}
```

## Documentation

### Class Documentation

**Document class purpose and parameters:**

```puppet
# Profile::WebServer
# Installs and configures a web server (nginx)
# Manages firewall rules and SSL configuration
#
# Parameters:
#   package_name  - Web server package name (default: 'nginx')
#   port_number   - Port to listen on (default: 80)
#   enable_ssl    - Enable SSL/TLS (default: false)
class profile::web_server (
  String $package_name = 'nginx',
  Integer $port_number = 80,
  Boolean $enable_ssl  = false,
) { }
```

### Inline Comments

**Comment complex logic:**

```puppet
# Extract major version for package repository selection
$major_version = regsubst($version, '^(\d+)\.\d+\.?\d*$', '\1')

# Install nginx from EPEL repo on RedHat (provides newer versions)
if $facts['os']['family'] == 'RedHat' {
  include fsx_epel
}
```

## Puppet 7/8 Compatibility

### Deprecated Features to Avoid

The following patterns are deprecated or removed in Puppet 7/8 and should not be used in new code:

| Pattern | Status | Modern Alternative |
|---------|--------|--------------------|
| `$::top_scope_var` | Deprecated | `$facts['...']` or `$trusted['...']` |
| `$::os.family` | Deprecated | `$facts['os']['family']` |
| `hiera()` / `hiera_array()` / `hiera_hash()` | Deprecated (Puppet 5+) | Automatic parameter lookup or `lookup()` |
| `create_resources()` | Deprecated | Iteration with `each` |
| ERB templates | Deprecated | EPP templates |
| `params` class with `inherits` | Legacy | Hiera data binding |
| `import` statement | Removed | Module autoloading |
| Node inheritance | Removed | Roles and profiles pattern |

### Modern Facts Access (Puppet 6+)

```puppet
# System facts - use $facts hash
$os_family  = $facts['os']['family']       # 'Debian', 'RedHat'
$os_name    = $facts['os']['name']         # 'Ubuntu', 'CentOS'
$os_release = $facts['os']['release']['major']
$hostname   = $facts['networking']['hostname']
$fqdn       = $facts['networking']['fqdn']
$ipaddress  = $facts['networking']['ip']
$memory_mb  = $facts['memory']['system']['total_bytes'] / 1048576

# Trusted facts (from certificate) - immutable, secure
$certname   = $trusted['certname']
$domain     = $trusted['domain']
$pp_role    = $trusted['extensions']['pp_role']
```

### Modern Hiera Lookup (Puppet 5+)

```puppet
# Deprecated - do not use
$port = hiera('profile::web::port', 80)
$servers = hiera_array('profile::web::servers', [])
$config  = hiera_hash('profile::web::config', {})

# Modern - use lookup() or automatic parameter binding
$port    = lookup('profile::web::port', Integer, 'first', 80)
$servers = lookup('profile::web::servers', Array, 'unique', [])
$config  = lookup('profile::web::config', Hash, 'hash', {})

# Best - automatic parameter lookup (Hiera provides value automatically)
class profile::web (
  Integer $port    = 80,
  Array   $servers = [],
  Hash    $config  = {},
) { }
```

### Puppet 8 Breaking Changes

- Ruby 2.x support dropped; requires Ruby 3.x on Puppet Server
- `puppet.conf` settings `stringify_facts` and `trusted_node_data` removed
- `pluginsync` is always enabled; cannot be disabled
- Legacy `auth.conf` format removed — use HOCON format only
- `--noop` is now `--no-noop` to enable; default behavior unchanged

## References

- **Puppet Best Practices** — Chris Barbour & Jo Rhett (O'Reilly, 2018) `references/puppetbestpractices.pdf`
  - Ch3 p.37: Coding practices, KISS/DRY/SRP, variables, EPP vs ERB
  - Ch4 p.75: Module design, PDK, params.pp, input validation
  - Ch5 p.113: Resource declaration, virtual resources, metaparameters
  - Ch6 p.151: Hiera hierarchy design, automatic lookups, eYAML
- [Puppet Language Style Guide](https://puppet.com/docs/puppet/latest/style_guide.html)
- [Puppet Best Practices (online)](https://puppet.com/docs/puppet/latest/best_practices.html)
- [Puppet Development Kit (PDK) Guide](https://puppet.com/docs/pdk/latest/)
- [Puppet 7 Release Notes](https://puppet.com/docs/puppet/7/release_notes_puppet.html)
- [Puppet 8 Release Notes](https://puppet.com/docs/puppet/8/release_notes_puppet.html)
- [Hiera lookup() function](https://puppet.com/docs/puppet/latest/hiera_use_function.html)
