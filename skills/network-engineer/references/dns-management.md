# DNS Management

## DNS Architecture Overview

```
                    +-------------------+
                    |   Root Servers    |
                    +---------+---------+
                              |
                    +---------+---------+
                    |    TLD Servers    |
                    |     (.com)        |
                    +---------+---------+
                              |
         +--------------------+--------------------+
         |                    |                    |
    +----+----+          +----+----+          +----+----+
    | Route 53|          |Azure DNS|          |Cloud DNS|
    |(AWS)    |          |(Azure)  |          |(GCP)    |
    +---------+          +---------+          +---------+
```

## Zone Design Patterns

### Hierarchical Zone Structure

```
example.com (Primary Zone)
├── www.example.com          (A Record)
├── api.example.com          (A Record -> ALB)
├── internal.example.com     (Private Zone)
│   ├── db.internal.example.com
│   ├── cache.internal.example.com
│   └── api.internal.example.com
├── dev.example.com          (Environment Subdomain)
├── staging.example.com      (Environment Subdomain)
└── prod.example.com         (Environment Subdomain)
```

### Public vs Private Zones

```hcl
# Public Hosted Zone
resource "aws_route53_zone" "public" {
  name = "example.com"

  tags = {
    Environment = "production"
    Type        = "public"
  }
}

# Private Hosted Zone (VPC-associated)
resource "aws_route53_zone" "private" {
  name = "internal.example.com"

  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = {
    Environment = "production"
    Type        = "private"
  }
}
```

## Record Types Reference

| Type | Purpose | Example |
|------|---------|---------|
| A | IPv4 Address | `192.0.2.1` |
| AAAA | IPv6 Address | `2001:0db8::1` |
| CNAME | Alias to another name | `api.example.com` |
| MX | Mail Exchange | `10 mail.example.com` |
| TXT | Text records (SPF, DKIM) | `v=spf1 include:...` |
| NS | Name Servers | `ns-1.awsdns-01.com` |
| SOA | Start of Authority | Zone metadata |
| SRV | Service Location | `_sip._tcp.example.com` |

## Record Management

### Basic Record Configuration

```hcl
# A Record - Simple
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "www.example.com"
  type    = "A"
  ttl     = 300
  records = ["192.0.2.1"]
}

# CNAME Record
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "api.example.com"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.main.dns_name]
}

# Alias Record (AWS-specific, no charge)
resource "aws_route53_record" "alb" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "app.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
```

### Multi-Value Records

```hcl
# Multiple A records for load distribution
resource "aws_route53_record" "multi" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "multi.example.com"
  type    = "A"
  ttl     = 60

  records = [
    "192.0.2.1",
    "192.0.2.2",
    "192.0.2.3"
  ]
}
```

## Routing Policies

### Simple Routing
Default behavior - single resource per record

```hcl
resource "aws_route53_record" "simple" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "simple.example.com"
  type    = "A"
  ttl     = 300
  records = ["192.0.2.1"]
}
```

### Weighted Routing
Distribute traffic based on weights

```hcl
# Weighted routing - 80% to us-east-1
resource "aws_route53_record" "weighted_east" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "weighted.example.com"
  type    = "A"
  ttl     = 60

  weighted_routing_policy {
    weight = 80
  }

  set_identifier = "us-east-1"
  records        = ["192.0.2.1"]
}

# Weighted routing - 20% to us-west-2
resource "aws_route53_record" "weighted_west" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "weighted.example.com"
  type    = "A"
  ttl     = 60

  weighted_routing_policy {
    weight = 20
  }

  set_identifier = "us-west-2"
  records        = ["192.0.2.2"]
}
```

### Latency-Based Routing
Route to lowest-latency endpoint

```hcl
# Latency routing - US East
resource "aws_route53_record" "latency_east" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "latency.example.com"
  type    = "A"
  ttl     = 60

  latency_routing_policy {
    latency_region = "us-east-1"
  }

  set_identifier = "us-east-1"
  records        = ["192.0.2.1"]
}

# Latency routing - EU West
resource "aws_route53_record" "latency_eu" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "latency.example.com"
  type    = "A"
  ttl     = 60

  latency_routing_policy {
    latency_region = "eu-west-1"
  }

  set_identifier = "eu-west-1"
  records        = ["192.0.2.2"]
}
```

### Failover Routing
Active-passive failover

```hcl
# Primary (active)
resource "aws_route53_record" "failover_primary" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "failover.example.com"
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "primary"

  alias {
    name                   = aws_lb.primary.dns_name
    zone_id                = aws_lb.primary.zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.primary.id
}

# Secondary (passive)
resource "aws_route53_record" "failover_secondary" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "failover.example.com"
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "secondary"

  alias {
    name                   = aws_lb.secondary.dns_name
    zone_id                = aws_lb.secondary.zone_id
    evaluate_target_health = true
  }
}
```

### Geolocation Routing
Route based on user location

```hcl
# Geolocation - North America
resource "aws_route53_record" "geo_na" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "geo.example.com"
  type    = "A"
  ttl     = 60

  geolocation_routing_policy {
    continent = "NA"
  }

  set_identifier = "north-america"
  records        = ["192.0.2.1"]
}

# Geolocation - Europe
resource "aws_route53_record" "geo_eu" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "geo.example.com"
  type    = "A"
  ttl     = 60

  geolocation_routing_policy {
    continent = "EU"
  }

  set_identifier = "europe"
  records        = ["192.0.2.2"]
}

# Geolocation - Default (catch-all)
resource "aws_route53_record" "geo_default" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "geo.example.com"
  type    = "A"
  ttl     = 60

  geolocation_routing_policy {
    country = "*"
  }

  set_identifier = "default"
  records        = ["192.0.2.3"]
}
```

## Health Checks

### Endpoint Health Check

```hcl
resource "aws_route53_health_check" "api" {
  fqdn              = "api.example.com"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  measure_latency = true

  tags = {
    Name = "api-health-check"
  }
}
```

### Health Check Parameters

| Parameter | Values | Description |
|-----------|--------|-------------|
| `failure_threshold` | 1-10 | Failures before unhealthy |
| `request_interval` | 10, 30 | Seconds between checks |
| `measure_latency` | true/false | Enable latency measurement |
| `type` | HTTP/HTTPS/TCP | Protocol to check |

### Calculated Health Check (Composite)

```hcl
# Combine multiple health checks
resource "aws_route53_health_check" "calculated" {
  type = "CALCULATED"

  child_health_threshold = 1
  child_health_checks    = [
    aws_route53_health_check.api.id,
    aws_route53_health_check.web.id
  ]

  tags = {
    Name = "composite-health-check"
  }
}
```

## DNSSEC Configuration

### Enable DNSSEC Signing

```hcl
# KMS Key for DNSSEC
resource "aws_kms_key" "dnssec" {
  customer_master_key_spec = "ECC_NIST_P256"
  key_usage               = "SIGN_VERIFY"
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable Route 53 DNSSEC"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action = [
          "kms:Sign",
          "kms:Verify",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# Enable DNSSEC on zone
resource "aws_route53_key_signing_key" "main" {
  hosted_zone_id             = aws_route53_zone.public.id
  key_management_service_arn = aws_kms_key.dnssec.arn
  name                       = "dnssec-key"
}

resource "aws_route53_hosted_zone_dnssec" "main" {
  hosted_zone_id = aws_route53_zone.public.id
}
```

### DS Record for Parent Zone

After enabling DNSSEC, add DS record to parent zone:
1. Get DS record value from Route 53 console or API
2. Add DS record at domain registrar

## TTL Strategy

| Record Type | Recommended TTL | Rationale |
|-------------|-----------------|-----------|
| Static (A, AAAA) | 3600-86400 | Rarely changes |
| Alias (ALB, CloudFront) | N/A (no TTL) | Uses AWS resolution |
| Failover | 60 | Quick failover |
| Weighted | 60 | Traffic adjustments |
| TXT (SPF, DKIM) | 3600 | Infrequent updates |

```hcl
# Low TTL for frequently changing records
resource "aws_route53_record" "dynamic" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "dynamic.example.com"
  type    = "A"
  ttl     = 60  # 1 minute for quick changes
  records = ["192.0.2.1"]
}
```

## Private DNS for VPC

### Internal Service Discovery

```hcl
# Private zone for internal services
resource "aws_route53_zone" "internal" {
  name = "internal.example.com"

  vpc {
    vpc_id = aws_vpc.main.id
  }
}

# Internal API endpoint
resource "aws_route53_record" "api_internal" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "api.internal.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}
```

### Cross-Account Private DNS

```hcl
# Associate VPC from another account
resource "aws_route53_zone_association" "secondary" {
  zone_id = aws_route53_zone.internal.zone_id
  vpc_id  = var.secondary_vpc_id
}
```

## Best Practices

1. **Use Alias Records**: Prefer alias records over CNAME for AWS resources (no charge, health checks)
2. **Health Checks**: Always configure health checks for failover routing
3. **TTL Strategy**: Use low TTL (60s) for records that change frequently
4. **Private Zones**: Use private zones for internal service discovery
5. **DNSSEC**: Enable DNSSEC for security-sensitive domains
6. **Monitoring**: Set up CloudWatch alarms for health check status changes
7. **Documentation**: Document zone structure and routing policies
8. **Delegation**: Use subdomain delegation for team/department isolation

## DNS Troubleshooting

### Common Commands

```bash
# Query specific record type
dig example.com A
dig example.com MX

# Query specific nameserver
dig @ns-1234.awsdns-12.com example.com

# Full DNS trace
dig +trace example.com

# Check DNS propagation
# (external tools like whatsmydns.net)

# Reverse DNS lookup
dig -x 192.0.2.1
```

### Common Issues

| Issue | Symptom | Solution |
|-------|---------|----------|
| No resolution | NXDOMAIN | Check zone exists, NS delegation |
| Wrong IP | Stale record | Check TTL, clear cache |
| Intermittent | Multiple records | Check routing policy, health checks |
| Slow resolution | High latency | Check TTL, nameserver proximity |
