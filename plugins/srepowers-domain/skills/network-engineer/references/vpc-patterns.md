# VPC Patterns

## VPC Architecture Overview

```
                    Internet
                        |
                [ Internet Gateway ]
                        |
    +-------------------+-------------------+
    |                   VPC                  |
    |              10.0.0.0/16               |
    |                                        |
    |   +-------------+    +-------------+   |
    |   | Public AZ-A |    | Public AZ-B |   |
    |   | 10.0.0.0/24 |    | 10.0.1.0/24 |   |
    |   +------+------+    +------+------+   |
    |          |                  |          |
    |   [ NAT Gateway ]    [ NAT Gateway ]   |
    |          |                  |          |
    |   +------+------+    +------+------+   |
    |   |Private AZ-A |    |Private AZ-B |   |
    |   | 10.0.10.0/24|    |10.0.11.0/24 |   |
    |   +-------------+    +-------------+   |
    |                                        |
    +----------------------------------------+
```

## Subnet Design Patterns

### Three-Tier Architecture

| Tier | Subnet Purpose | CIDR Example | Access |
|------|---------------|--------------|--------|
| Web | Public-facing load balancers | 10.0.1.0/24, 10.0.2.0/24 | Public |
| App | Application servers | 10.0.10.0/24, 10.0.11.0/24 | Private |
| Data | Databases, caches | 10.0.20.0/24, 10.0.21.0/24 | Private, Isolated |

### Subnet Allocation Strategy

```
# Recommended CIDR allocation for /16 VPC
10.0.0.0/16    - VPC CIDR
  ├── 10.0.0.0/20    - Reserved (future use)
  ├── 10.0.16.0/20   - Public subnets (AZ-based slices)
  │     ├── 10.0.16.0/24 - Public AZ-A
  │     ├── 10.0.17.0/24 - Public AZ-B
  │     └── 10.0.18.0/24 - Public AZ-C
  ├── 10.0.32.0/20   - Private App subnets
  │     ├── 10.0.32.0/24 - App AZ-A
  │     ├── 10.0.33.0/24 - App AZ-B
  │     └── 10.0.34.0/24 - App AZ-C
  ├── 10.0.48.0/20   - Private Data subnets
  │     ├── 10.0.48.0/24 - Data AZ-A
  │     ├── 10.0.49.0/24 - Data AZ-B
  │     └── 10.0.50.0/24 - Data AZ-C
  └── 10.0.64.0/18   - Reserved (future expansion)
```

## Route Table Patterns

### Public Subnet Route Table

```json
{
  "Routes": [
    {
      "DestinationCidrBlock": "10.0.0.0/16",
      "Target": "local",
      "Description": "Local VPC traffic"
    },
    {
      "DestinationCidrBlock": "0.0.0.0/0",
      "Target": "igw-xxxxxxx",
      "Description": "Internet Gateway for public access"
    }
  ]
}
```

### Private Subnet Route Table (with NAT)

```json
{
  "Routes": [
    {
      "DestinationCidrBlock": "10.0.0.0/16",
      "Target": "local",
      "Description": "Local VPC traffic"
    },
    {
      "DestinationCidrBlock": "0.0.0.0/0",
      "Target": "nat-xxxxxxx",
      "Description": "NAT Gateway for outbound internet"
    }
  ]
}
```

### Private Subnet Route Table (with Transit Gateway)

```json
{
  "Routes": [
    {
      "DestinationCidrBlock": "10.0.0.0/16",
      "Target": "local",
      "Description": "Local VPC traffic"
    },
    {
      "DestinationCidrBlock": "10.1.0.0/16",
      "Target": "tgw-xxxxxxx",
      "Description": "Transit Gateway to Shared Services VPC"
    },
    {
      "DestinationCidrBlock": "10.2.0.0/16",
      "Target": "tgw-xxxxxxx",
      "Description": "Transit Gateway to Production VPC"
    }
  ]
}
```

## NAT Gateway Patterns

### High-Availability NAT Setup

```
                    Internet
                        |
            +-----------+-----------+
            |     Internet Gateway   |
            +-----------+-----------+
                        |
        +---------------+---------------+
        |               VPC              |
        |                               |
   +----+----+                    +-----+----+
   | AZ-A    |                    | AZ-B     |
   |         |                    |          |
   | [NAT-A] |                    | [NAT-B]  |
   |    |    |                    |    |     |
   +----+----+                    +----+-----+
        |                              |
   [Private-A]                    [Private-B]
   Route to NAT-A                 Route to NAT-B
```

**Key Rule**: Each AZ should have its own NAT Gateway for HA. Private subnets in AZ-A route to NAT-A, AZ-B to NAT-B.

### NAT Gateway Cost Optimization

For non-production environments, use single NAT Gateway:

```hcl
# Single NAT for cost savings (dev/test only)
resource "aws_nat_gateway" "single" {
  count = var.environment == "production" ? 2 : 1

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}
```

## Transit Gateway Patterns

### Hub-and-Spoke Architecture

```
                    +------------------+
                    |  Transit Gateway |
                    |    (Hub VPC)     |
                    +--------+---------+
                             |
          +--------+---------+---------+--------+
          |                  |                  |
    +-----+-----+      +-----+-----+      +-----+-----+
    | Shared    |      | Production|      | Dev       |
    | Services  |      | VPC       |      | VPC       |
    | VPC       |      |           |      |           |
    +-----------+      +-----------+      +-----------+
```

### Transit Gateway Route Table Design

| Route Table | Purpose | Attachments |
|-------------|---------|-------------|
| `shared-services-rt` | Shared services routes | Shared VPC, VPN |
| `production-rt` | Production VPC routes | Production VPC, Shared VPC |
| `development-rt` | Development VPC routes | Dev VPC, Shared VPC |
| `vpn-rt` | On-premises routes | VPN, Shared VPC |

## VPC Peering Patterns

### Same-Region Peering

```
+------------------+        +------------------+
|   VPC-A          |        |   VPC-B          |
|   10.0.0.0/16    |<------>|   10.1.0.0/16    |
|                  |  Peer  |                  |
|  [App Servers]   |        |  [API Services]  |
+------------------+        +------------------+
```

### Cross-Region Peering

```hcl
# Cross-region VPC peering
resource "aws_vpc_peering_connection" "cross_region" {
  provider    = aws.us_east_1
  vpc_id      = aws_vpc.east.id
  peer_vpc_id = aws_vpc.west.id
  peer_region = "us-west-2"

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_accepter" "cross_region" {
  provider                  = aws.us_west_2
  vpc_peering_connection_id = aws_vpc_peering_connection.cross_region.id
  auto_accept               = true
}
```

## PrivateLink Patterns

### Service Consumer Pattern

```
+------------------+        +------------------+
|  Consumer VPC    |        |  Provider VPC    |
|                  |        |                  |
| [ENI in subnet]  |<------>| [NLB + Service]  |
|                  | VPC    |                  |
|  PrivateLink     | Endpoint|                 |
+------------------+        +------------------+
```

**Use Cases**:
- Access shared services without peering
- Third-party SaaS integration
- Cross-account service access

## Network Security Patterns

### Security Group Rules Reference

| Tier | Inbound | Source | Outbound | Destination |
|------|---------|--------|----------|-------------|
| Web LB | 443 | 0.0.0.0/0 | 8080 | App SG |
| App | 8080 | Web LB SG | 5432 | Data SG |
| Data | 5432 | App SG | - | - |

### Network ACL Rules

```json
{
  "Inbound": [
    { "RuleNumber": 100, "Protocol": "TCP", "Port": 443, "Source": "0.0.0.0/0", "Action": "ALLOW" },
    { "RuleNumber": 110, "Protocol": "TCP", "Port": 22, "Source": "10.0.0.0/8", "Action": "ALLOW" },
    { "RuleNumber": "*", "Protocol": "ALL", "Port": "ALL", "Source": "0.0.0.0/0", "Action": "DENY" }
  ],
  "Outbound": [
    { "RuleNumber": 100, "Protocol": "TCP", "Port": "1024-65535", "Destination": "0.0.0.0/0", "Action": "ALLOW" },
    { "RuleNumber": "*", "Protocol": "ALL", "Port": "ALL", "Destination": "0.0.0.0/0", "Action": "DENY" }
  ]
}
```

## Flow Logs Analysis

### Enabling VPC Flow Logs

```hcl
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name = "${var.name}-flow-logs"
  }
}
```

### Common Flow Log Queries

```
# Find rejected traffic
fields @timestamp, srcAddr, dstAddr, srcPort, dstPort, protocol, action
| filter action = 'REJECT'
| sort @timestamp desc

# Find top talkers
stats sum(bytes) as totalBytes by srcAddr
| sort totalBytes desc
| limit 10
```

## Best Practices

1. **CIDR Planning**: Always reserve space for growth (use /16 minimum for production)
2. **HA NAT**: Deploy NAT Gateway in each AZ for production workloads
3. **Flow Logs**: Enable in all production VPCs for troubleshooting and security
4. **Documentation**: Maintain topology diagrams and routing documentation
5. **Security Groups**: Prefer over NACLs for granular control; NACLs for subnet-level protection
6. **DNS Resolution**: Enable DNS hostnames and resolution in VPC settings
7. **Monitoring**: Set up CloudWatch alarms for NAT Gateway port allocation and bandwidth
