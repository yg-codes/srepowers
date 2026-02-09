# Puppet Module Structure Guide

## Overview

This document describes the expected structure and layout patterns for Puppet modules in the FSX infrastructure. Following these standards ensures consistency across modules and simplifies maintenance.

## Standard Module Layout

### Complete Module Structure

```
fsx_module_name/
├── manifests/              # Puppet manifests (.pp files)
│   ├── init.pp            # Main class (module::init)
│   ├── install.pp         # Installation class
│   ├── config.pp          # Configuration class
│   ├── service.pp         # Service management class
│   └── params.pp          # Default parameters class
├── templates/              # ERB templates (.erb files)
│   └── module_config.erb
├── files/                  # Static files (no interpolation)
│   └── static_file.conf
├── lib/                    # Puppet functions and custom types
│   ├── puppet/
│   │   ├── functions/     # Custom Puppet functions
│   │   ├── provider/      # Custom resource providers
│   │   └── type/          # Custom resource types
│   └── facter/            # Custom Facter facts
├── hiera.yaml              # Hiera data binding configuration
├── metadata.json           # PDK module metadata
├── README.md               # Module documentation
├── CHANGELOG.md            # Version change history
├── LICENSE                 # License file
├── .puppet-lint.rc         # puppet-lint configuration
└── .yamllint               # YAML linting rules
```

### Minimal Module Structure

For simple modules, the minimal required structure:

```
fsx_module_name/
├── manifests/
│   └── init.pp
├── metadata.json
└── README.md
```

## Manifest Organization

### Main Class (init.pp)

Every module should have a main class that serves as the entry point:

```puppet
# manifests/init.pp
class fsx_module_name (
  String $version = 'installed',

  Boolean $enable_service = true,
  Boolean $enable_config  = true,
  Boolean $enable_install = true,
) {

  if $enable_install {
    include fsx_module_name::install
  }

  if $enable_config {
    include fsx_module_name::config
  }

  if $enable_service {
    include fsx_module_name::service
  }
}
```

### Installation Class

```puppet
# manifests/install.pp
class fsx_module_name::install (
  String $package_name      = $fsx_module_name::package_name,
  String $package_ensure    = $fsx_module_name::package_ensure,
) inherits fsx_module_name::params {

  package { $package_name:
    ensure => $package_ensure,
  }
}
```

### Configuration Class

```puppet
# manifests/config.pp
class fsx_module_name::config (
  String $config_file = $fsx_module_name::params::config_file,
  Hash $config      = $fsx_module_name::params::config,
) inherits fsx_module_name::params {

  file { $config_file:
    ensure  => file,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => epp('fsx_module_name/config.epp', {
      config => $config,
    }),
    require => Class['fsx_module_name::install'],
    notify  => Class['fsx_module_name::service'],
  }
}
```

### Service Class

```puppet
# manifests/service.pp
class fsx_module_name::service (
  String $service_name   = $fsx_module_name::params::service_name,
  Boolean $service_enable = $fsx_module_name::params::service_enable,
  Enum['running', 'stopped'] $service_ensure = $fsx_module_name::params::service_ensure,
) inherits fsx_module_name::params {

  service { $service_name:
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasrestart => true,
    hasstatus  => true,
    require    => [
      Class['fsx_module_name::install'],
      Class['fsx_module_name::config'],
    ],
  }
}
```

### Parameters Class

```puppet
# manifests/params.pp
class fsx_module_name::params {
  # OS-specific defaults
  $package_name = $::os.family ? {
    'Debian' => 'module_name',
    'RedHat' => 'module_name',
    default  => 'module_name',
  }

  $service_name = $::os.family ? {
    'Debian' => 'module_name',
    'RedHat' => 'module_named',
    default  => 'module_name',
  }

  $config_file = '/etc/module_name/config.conf'

  $package_ensure = 'installed'
  $service_ensure = 'running'
  $service_enable = true

  # Default configuration
  $config = {
    'setting1' => 'value1',
    'setting2' => 'value2',
  }
}
```

## Template Organization

### ERB Templates (Legacy)

```erb
<%# templates/config.erb - Legacy ERB syntax %>
# Configuration file for <%= @module_name %>
server_port = <%= @port %>
server_host = <%= @host %>

<% if @enable_ssl -%>
ssl_cert = /etc/ssl/certs/<%= @cert_file %>
<% end -%>
```

### EPP Templates (Modern)

```epp
<%# templates/config.epp - Modern EPP syntax %>
# Configuration file for <%= $module_name %>
server_port = <%= $port %>
server_host = <%= $host %>

<% if $enable_ssl { -%>
ssl_cert = /etc/ssl/certs/<%= $cert_file %>
<% } -%>
```

### Template Best Practices

1. **Use EPP for new templates** (better security and syntax)
2. **Keep templates simple** - move complex logic to Puppet
3. **Document template variables** at the top
4. **Use safe navigation** for optional variables

```epp
<%# | $module_name = 'module',
     $port = 80,
     $enable_ssl = false,
     $cert_file = undef
-%%>

# Configuration for <%= $module_name %>
port = <%= $port %>

<% if $enable_ssl and $cert_file { -%>
ssl_cert = /etc/ssl/certs/<%= $cert_file %>
<% } -%>
```

## File Organization

### Static Files

Use `files/` for static content that doesn't need interpolation:

```
files/
├── scripts/
│   └── setup.sh
├── keys/
│   └── app_key.pub
└── config/
    └── default.conf
```

**Usage in manifests:**

```puppet
file { '/usr/local/bin/setup.sh':
  ensure => file,
  mode   => '0755',
  source => 'puppet:///modules/fsx_module_name/scripts/setup.sh',
}
```

### File Naming Conventions

- Use lowercase with underscores: `my_config_file.conf`
- Descriptive names: `apache_ssl_vhost.conf` (not `vhost.conf`)
- Group related files in subdirectories

## Hiera Integration

### Module Hiera Configuration

```yaml
# hiera.yaml
version: 5
hierarchy:
  - name: "OS Family"
    path: "os/%{facts.os.family}.yaml"
  - name: "Common"
    path: "common.yaml"
```

### Data Directory Structure

```
data/
├── os/
│   ├── Debian.yaml
│   ├── RedHat.yaml
│   └── Windows.yaml
└── common.yaml
```

### Automatic Parameter Lookup

```puppet
# manifests/init.pp
class fsx_module_name (
  String $package_name = 'module_name',
  Integer $port        = 80,
  Boolean $enable_ssl  = false,
) {
  # Hiera automatically provides values for these parameters
  # based on module::class::parameter keys
}
```

**Hiera data:**

```yaml
# data/common.yaml
fsx_module_name::package_name: 'custom_module'
fsx_module_name::port: 8080
```

## Module Dependencies

### Declaring Dependencies

In `metadata.json`:

```json
{
  "name": "fsx-module_name",
  "version": "1.0.0",
  "dependencies": [
    {"name": "puppetlabs/stdlib", "version_requirement": ">= 4.25.0"},
    {"name": "puppetlabs/apache", "version_requirement": ">= 5.0.0"}
  ]
}
```

### Using Dependencies in Manifests

```puppet
# Good - explicit dependency declaration
class fsx_module_name (
  Boolean $manage_firewall = true,
) {

  if $manage_firewall {
    include profile::firewall
    Class['Profile::Firewall'] -> Class['Fsx_module_name::Service']
  }
}
```

## Module Types

### Component Module

Single-purpose module (e.g., `fsx_nginx`, `fsx_mysql`):

```
fsx_nginx/
├── manifests/
│   ├── init.pp
│   ├── install.pp
│   └── config.pp
└── files/
    └── nginx.conf
```

### Profile Module

Configuration composition (e.g., `profile::web_server`):

```
profile/
├── manifests/
│   ├── web_server.pp
│   ├── db_server.pp
│   └── base.pp
└── data/
    └── common.yaml
```

### Role Module

Node definition (e.g., `role::frontend_web`):

```
role/
├── manifests/
│   ├── frontend_web.pp
│   ├── backend_db.pp
│   └── base.pp
```

## Naming Conventions

### Module Names

**Format:** `fsx_<component>`

**Examples:**
- `fsx_nginx` - Nginx web server
- `fsx_mysql` - MySQL database
- `fsx_dns` - DNS configuration
- `fsx_backup` - Backup utilities

### Class Names

**Pattern:** `<module>::<subpackage>::<class>`

**Examples:**
```puppet
class fsx_nginx { }                    # Main class
class fsx_nginx::install { }           # Installation
class fsx_nginx::config { }            # Configuration
class fsx_nginx::config::vhost { }     # Specific component
```

### Parameter Names

Use descriptive names with snake_case:

```puppet
class fsx_module (
  String $package_name,      # Good
  Integer $port_number,      # Good
  Boolean $enable_ssl,       # Good
  String $pkg,               # Bad - not descriptive
  Integer $p,                # Bad - too short
) { }
```

## PDK Integration

### Initialize with PDK

```bash
# Create new module
pdk new module fsx_module_name

# Convert existing module
cd fsx_module_name
pdk convert
```

### Validate with PDK

```bash
# Run all validations
pdk validate

# Validate specific checks
pdk validate puppet-lint
pdk validate metadata
pdk validate rubocop
```

### Build Module

```bash
# Build module package
pdk build

# Output: pkg/fsx_module_name-1.0.0.tar.gz
```

## Testing Structure

### Unit Tests

```
spec/
├── classes/
│   ├── init_spec.rb
│   ├── install_spec.rb
│   └── config_spec.rb
└── spec_helper.rb
```

### Acceptance Tests

```
.almacc/
├── acceptance/
│   └── default_spec.rb
└── provision.yml
```

## Best Practices

1. **Single Responsibility**: Each module should do one thing well
2. **Loose Coupling**: Minimize dependencies on other modules
3. **Idempotence**: All resources should be idempotent
4. **Documentation**: Document public classes and parameters
5. **Testing**: Write tests for critical functionality
6. **Version Control**: Use semantic versioning (MAJOR.MINOR.PATCH)

## References

- [Puppet Module Basics](https://puppet.com/docs/puppet/latest/modules_fundamentals.html)
- [Puppet Development Kit (PDK)](https://puppet.com/docs/pdk/latest/)
- [Puppet Style Guide](https://puppet.com/docs/puppet/latest/style_guide.html)
- [Puppet Module Project Template](https://github.com/puppetlabs/puppet-module-template)
