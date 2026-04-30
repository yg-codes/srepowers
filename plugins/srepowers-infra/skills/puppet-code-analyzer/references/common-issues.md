# Common Puppet Issues and Solutions

This document catalogs frequently encountered Puppet issues in the FSX infrastructure along with their root causes and solutions.

## Table of Contents

- [Dependency Issues](#dependency-issues)
- [Syntax Errors](#syntax-errors)
- [Hiera Data Issues](#hiera-data-issues)
- [Class Design Issues](#class-design-issues)
- [Package Management](#package-management)
- [File and Template Issues](#file-and-template-issues)
- [Service Management](#service-management)
- [Performance Issues](#performance-issues)

## Dependency Issues

### Circular Dependency Detected

**Error Message:**
```
Error: Could not apply complete catalog: Found 1 dependency cycle:
... (Class[Profile::Web_server] => Service[Nginx] => Class[Profile::Web_server])
```

**Root Cause:**
Resources or classes form a circular dependency chain through require/contain/include relationships.

**Solutions:**

1. **Remove unnecessary dependency:**
```puppet
# Before - circular
Class[A] -> Class[B] -> Class[C] -> Class[A]

# After - break the cycle
Class[A] -> Class[B] -> Class[C]
Class[A] -> Class[C]  # Direct relationship instead
```

2. **Use chaining arrows carefully:**
```puppet
# Explicit ordering without cycles
Package['nginx'] -> File['/etc/nginx/nginx.conf'] ~> Service['nginx']
```

3. **Review include chains:**
```puppet
# Avoid circular includes
# class A { include B }
# class B { include C }
# class C { include A }  # BAD
```

### Duplicate Declaration

**Error Message:**
```
Error: Duplicate declaration: Package[nginx] is already declared
```

**Root Cause:**
Same resource is declared multiple times in the catalog.

**Solutions:**

1. **Check for duplicate resource declarations:**
```puppet
# Bad - duplicate
package { 'nginx': ensure => installed }  # First
package { 'nginx': ensure => installed }  # Second - error!

# Good - declare once
package { 'nginx':
  ensure => installed,
}
```

2. **Use virtual resources for multiple references:**
```puppet
# Define virtual resource
@package { 'nginx':
  ensure => installed,
}

# Realize in multiple places
Package <| title == 'nginx' |>
```

3. **Check module dependencies:**
```puppet
# Check if included modules both declare the same resource
# Use parameterized classes or conditional declarations
```

## Syntax Errors

### Unexpected Token

**Error Message:**
```
Error: Syntax error at '}' at /path/to/manifest.pp:20
```

**Root Cause:**
Invalid Puppet syntax - missing commas, unclosed braces, wrong quotes.

**Solutions:**

1. **Validate with puppet parser:**
```bash
puppet parser validate manifests/init.pp
```

2. **Check for missing commas:**
```puppet
# Bad - missing comma
package { 'nginx':
  ensure => installed
  provider => apt  # Missing comma above
}

# Good
package { 'nginx':
  ensure  => installed,
  provider => apt,
}
```

3. **Check brace matching:**
```puppet
# Use editor's bracket matching
# Count opening vs closing braces
```

### Undefined Variable

**Error Message:**
```
Error: Undefined variable '$config_file'; ...
```

**Root Cause:**
Variable used before definition or typo in variable name.

**Solutions:**

1. **Check variable scope:**
```puppet
# Define before use
$config_file = '/etc/nginx/nginx.conf'

file { $config_file: }  # Now it's defined

# Or use class parameters
class profile::web (
  String $config_file = '/etc/nginx/nginx.conf',
) {
  file { $config_file: }
}
```

2. **Use facts hash for system facts (Puppet 6+):**
```puppet
# Modern - use facts hash
$os_family = $facts['os']['family']

# Access from class
class example {
  $local_value = $facts['os']['family']
}
```

## Hiera Data Issues

### Key Not Found

**Error Message:**
```
Error: Evaluation Error: Error while evaluating a Function Call, hiera(): KeyError: key 'profile::web_server::port' not found
```

**Root Cause:**
Hiera lookup failed to find the requested key in the data hierarchy.

**Solutions:**

1. **Check Hiera hierarchy:**
```yaml
# hiera.yaml
hierarchy:
  - name: "Per-Node data"
    path: "nodes/%{::trusted.certname}.yaml"
  - name: "Common data"
    path: "common.yaml"
```

2. **Provide default values:**
```puppet
# Good - with default
$port = hiera('profile::web_server::port', 80)

# Better - automatic parameter lookup with default
class profile::web_server (
  Integer $port = 80,  # Default value
) { }
```

3. **Verify YAML syntax:**
```bash
yamllint data/common.yaml
```

### Wrong Data Type

**Error Message:**
```
Error: parameter 'port' expects an Integer value, got String
```

**Root Cause:**
Hiera data type doesn't match parameter type specification.

**Solutions:**

1. **Check YAML data types:**
```yaml
# Good - correct types
profile::web_server::port: 8080
profile::web_server::enable_ssl: true
profile::web_server::servers:
  - server1
  - server2

# Bad - wrong types
profile::web_server::port: "8080"  # String, not Integer
profile::web_server::enable_ssl: "true"  # String, not Boolean
```

2. **Use explicit type conversion:**
```puppet
$port = Integer(hiera('profile::web_server::port', 80))
```

### Hardcoded Values in Hiera Data

**Symptoms:**
- IP addresses, passwords, or tokens committed to version control
- Data that works in one environment but fails in another
- Secrets visible in `git log` or `git diff`

**Solutions:**

1. **Replace hardcoded IPs with facts or correct hierarchy level:**
```yaml
# Bad - in common.yaml
profile::app::db_host: '10.0.1.45'

# Good - in data/nodes/<nodename>.yaml or data/env/production.yaml
profile::app::db_host: 'db01.prod.example.com'
```

2. **Encrypt secrets with hiera-eyaml:**
```bash
# Encrypt a value
eyaml encrypt -s 'S3cr3tP@ssw0rd'

# Result in Hiera YAML
profile::app::db_password: >
  ENC[PKCS7,MIIBe...]
```

3. **Use Puppet Sensitive type to prevent secret logging:**
```puppet
class profile::app (
  Sensitive[String] $db_password = Sensitive('changeme'),
) {
  # $db_password is redacted in reports and logs
}
```

4. **Use the correct Hiera hierarchy level** — don't put environment-specific data in `common.yaml`:
```
data/
├── common.yaml           # Only truly global defaults
├── env/
│   ├── production.yaml   # Production-specific values
│   └── staging.yaml      # Staging-specific values
├── datacenter/
│   └── dc1.yaml          # Datacenter-specific IPs/endpoints
└── nodes/
    └── web01.yaml        # Node-specific overrides
```

## Class Design Issues

### Missing Parameter Defaults (Bootstrap Failure)

**Error Message:**
```
Error: Could not find value for <class>::<parameter>
Error: Evaluation Error: Resource type parameter <parameter> expects a <type> value, got Undef
```

**Root Cause:**
Class parameters are declared without default values, and no Hiera data matches the current node's hierarchy. This is a **critical bootstrap issue** - the class fails before any resources can be managed.

**Why This Is a Problem:**

1. **Bootstrap Chicken-and-Egg**: Classes that configure package repositories (e.g., `fsx_repo`) must compile successfully on first run. If they fail, Puppet can't install packages to fix anything.

2. **Tight Coupling**: The class requires Hiera data to exist, violating the "safe defaults" pattern.

3. **Non-Portable**: The module won't work on untested platforms or OS versions.

**Anti-Pattern (Bad):**
```puppet
# manifests/init.pp - NO DEFAULTS
class fsx_repo (
  Fsx_repo::Main_config $main,                         # ← Required, no default
  Hash[String, Fsx_repo::Repofile_config] $repofiles,  # ← Required, no default
  Hash[String, Fsx_repo::Repo_config] $repos,          # ← Required, no default
) {
  include fsx_repo::config
  include fsx_repo::main
}
```

```yaml
# common/all.yaml - class is included everywhere
classes:
  - fsx_repo

# But data only exists in os/RedHat*.yaml
# If a node doesn't match os/RedHat*, Puppet FAILS
```

**Best Practice Pattern (Good):**
```puppet
# manifests/init.pp - SAFE DEFAULTS
class fsx_repo (
  Fsx_repo::Main_config $main = {
    gpgcheck            => true,
    installonly_limit   => 3,
    skip_if_unavailable => true,
  },
  Hash[String, Fsx_repo::Repofile_config] $repofiles = {},
  Hash[String, Fsx_repo::Repo_config] $repos = {},
) {
  # Guard clause - do nothing if no repos configured
  if $repofiles.empty and $repos.empty {
    info("${module_name}: No repository data provided, skipping configuration")
    return
  }

  include fsx_repo::config
  include fsx_repo::main
}
```

**Alternative: Conditional Class Inclusion**

Move class inclusion to where data exists:
```yaml
# os/RedHat.yaml - only include where data exists
classes:
  - fsx_repo

fsx_repo::repofiles:
  elrepo: { ... }
```

**Key Principles:**

| Principle | Violation | Correct Approach |
|-----------|-----------|------------------|
| **Safe Defaults** | No parameter defaults | All parameters have defaults |
| **Graceful Degradation** | Class fails hard | Class does nothing if no data |
| **Data/Code Separation** | Class requires data | Data enhances class behavior |
| **Portability** | OS-specific data required | Works on any OS (may be minimal) |

**Detection:**

Look for class declarations where parameters lack `= <default>` syntax:
```bash
# Find classes with required parameters (potential issue)
grep -r "class.*(" modules/*/manifests/init.pp | grep -v "= "
```

**Reference:** Puppet Best Practices (O'Reilly), Chapter 4: Module Design, pages 75-110

---

## Package Management

### Package Not Found

**Error Message:**
```
Error: Could not find package nginx-custom
```

**Root Cause:**
Package not available in configured repositories.

**Solutions:**

1. **Verify package name:**
```bash
# Debian/Ubuntu
apt-cache search nginx

# RHEL/CentOS
yum search nginx
```

2. **Configure additional repositories:**
```puppet
# Add EPEL for RHEL
package { 'epel-release':
  ensure => installed,
}

package { 'nginx':
  ensure  => installed,
  require => Package['epel-release'],
}
```

3. **Use version pinning carefully:**
```puppet
# Bad - specific version might not exist
package { 'nginx':
  ensure => '1.18.0-1',
}

# Good - version range or latest
package { 'nginx':
  ensure => installed,
  # or ensure => latest,
}
```

### Package Install Fails

**Error Message:**
```
Error: Execution of '/usr/bin/apt-get -q -y install nginx' returned 1
```

**Root Cause:**
Package installation failure due to dependency issues or network problems.

**Solutions:**

1. **Update package cache:**
```puppet
exec { 'apt-update':
  command => '/usr/bin/apt-get update',
  before  => Package['nginx'],
}

package { 'nginx':
  ensure  => installed,
  require => Exec['apt-update'],
}
```

2. **Handle dependencies:**
```puppet
# Install required dependencies first
package { ['libssl1.1', 'libpcre3']:
  ensure => installed,
}

package { 'nginx':
  ensure  => installed,
  require => Package['libssl1.1', 'libpcre3'],
}
```

## File and Template Issues

### Template Not Found

**Error Message:**
```
Error: Could not find template 'profile/nginx.conf.erb'
```

**Root Cause:**
Template file path incorrect or missing from module.

**Solutions:**

1. **Check template location:**
```
module/
├── manifests/
│   └── init.pp
└── templates/
    └── nginx.conf.erb  # Must be here
```

2. **Use correct module path:**
```puppet
# Good
file { '/etc/nginx/nginx.conf':
  content => template('profile/nginx.conf.erb'),
}

# Wrong
file { '/etc/nginx/nginx.conf':
  content => template('/etc/puppetlabs/code/modules/profile/templates/nginx.conf.erb'),
}
```

3. **Verify template file exists:**
```bash
find . -name 'nginx.conf.erb'
```

### Template Rendering Error

**Error Message:**
```
Error: Evaluation Error: Error while evaluating a Function Call, undefined method `[]' for nil:NilClass
```

**Root Cause:**
Template references undefined variable or uses wrong syntax.

**Solutions:**

1. **Use safe navigation:**
```erb
# Bad - crashes if @config is nil
ServerName <%= @config['server_name'] %>

# Good - checks for nil
ServerName <%= @config && @config['server_name'] %>

# Better - use scope function
<%= scope.lookupvar('profile::config::server_name') %>
```

2. **Provide default values in template:**
```erb
Port <%= @port_number || 80 %>
```

## Service Management

### Service Start Fails

**Error Message:**
```
Error: /bin/systemctl restart nginx failed!
```

**Root Cause:**
Service fails to start due to configuration errors or missing dependencies.

**Solutions:**

1. **Validate configuration before starting:**
```puppet
file { '/etc/nginx/nginx.conf':
  ensure  => file,
  content => template('profile/nginx.conf.erb'),
  notify  => Service['nginx'],
}

# Add validation
exec { 'validate nginx config':
  command     => '/usr/sbin/nginx -t',
  refreshonly => true,
  before      => Service['nginx'],
}
```

2. **Enable hasstatus and hasrestart:**
```puppet
service { 'nginx':
  ensure     => running,
  enable     => true,
  hasrestart => true,  # Use systemctl restart
  hasstatus  => true,  # Use systemctl status
}
```

3. **Handle service dependencies:**
```puppet
service { 'nginx':
  ensure  => running,
  require => [
    Package['nginx'],
    File['/etc/nginx/nginx.conf'],
  ],
}
```

## Performance Issues

### Catalog Compilation Slow

**Symptoms:**
- Catalog takes >30 seconds to compile
- High CPU usage on Puppet Server

**Solutions:**

1. **Reduce exported resources:**
```puppet
# Use specific queries
Puppet::Node <<| |>>
# Instead of
Puppet::Node <<| |>>  # All nodes

# Or use facts for hostname:
Puppet::Node <<| title == $facts['networking']['hostname'] |>>
```

2. **Optimize Hiera lookups:**
```puppet
# Cache repeated lookups
$common_config = hiera_hash('profile::common_config')

# Instead of multiple calls
$config_a = hiera('profile::config_a')
$config_b = hiera('profile::config_b')
$config_c = hiera('profile::config_c')
```

3. **Use modern Puppet features (6+):**
```puppet
# Modern Puppet has all "future parser" features enabled by default
# Ensure you're using Puppet 6+ for best performance and features
```

### Agent Run Slow

**Symptoms:**
- Puppet agent runs take >5 minutes
- High I/O during runs

**Solutions:**

1. **Reduce unnecessary file resources:**
```puppet
# Use recurse only when needed
file { '/etc/myapp':
  ensure  => directory,
  recurse => false,  # Default - faster
  # recurse => true,  # Only if needed
  recurse => 'remote',  # Better than true
}
```

2. **Use noop for testing:**
```bash
puppet agent -t --noop  # Faster dry-run
```

3. **Schedule regular runs instead of daemon:**
```puppet
# Use cron for predictable load
cron { 'puppet-agent':
  command => '/opt/puppetlabs/bin/puppet agent -t',
  user    => 'root',
  hour    => 2,
  minute  => fqdn_rand(60),
}
```

## Debugging Tips

### Enable Debug Output

```bash
# Run agent with debug
puppet agent -t --debug

# Show catalog diff
puppet agent -t --show_diff

# Compile catalog locally
puppet apply manifests/site.pp --debug
```

### Validate Manifests

```bash
# Check syntax
puppet parser validate manifests/init.pp

# Lint code
puppet-lint --no-autoloader_layout-check manifests/init.pp

# Validate with PDK
pdk validate
```

### Test Single Classes

```bash
# Apply single class
puppet apply -e 'include profile::web_server'

# With parameters
puppet apply -e 'class {"profile::web_server": port => 8080}'
```

## References

- [Puppet Troubleshooting Guide](https://puppet.com/docs/puppet/latest/troubleshooting.html)
- [Puppet Error Messages](https://puppet.com/docs/puppet/latest/errors.html)
- [Puppet Best Practices](https://puppet.com/docs/puppet/latest/best_practices.html)
