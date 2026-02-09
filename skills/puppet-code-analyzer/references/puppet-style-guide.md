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
# Good - selector
$web_root = $::os.family ? {
  'Debian' => '/var/www',
  'RedHat' => '/var/www/html',
  default  => '/var/www',
}

# Acceptable - case statement
case $::os.family {
  'Debian': { $package = 'apache2' }
  'RedHat': { $package = 'httpd' }
  default: { fail("Unsupported OS family: ${::os.family}") }
}
```

## Common Anti-Patterns to Avoid

### Hardcoding Values

```puppet
# Bad
file { '/etc/app/config.conf':
  content => 'server_ip=192.168.1.100
port=8080',
}

# Good - use parameters
file { '/etc/app/config.conf':
  content => template('profile/config.conf.erb'),
}
```

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
if $::os.family == 'RedHat' {
  include fsx_epel
}
```

## References

- [Puppet Language Style Guide](https://puppet.com/docs/puppet/latest/style_guide.html)
- [Puppet Best Practices](https://puppet.com/docs/puppet/latest/best_practices.html)
- [Puppet Development Kit (PDK) Guide](https://puppet.com/docs/pdk/latest/)
