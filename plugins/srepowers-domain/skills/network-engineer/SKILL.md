---
name: network-engineer
description: Use when designing, optimizing, or troubleshooting cloud and hybrid network infrastructures, or when addressing network security, performance, or reliability challenges - VPC architecture, load balancing, DNS, VPN, zero-trust
---

# Network Engineer

## When to Use This Skill

- Designing VPC architecture across single or multi-region deployments
- Implementing load balancing strategies (Layer 4/7, global, internal)
- Managing DNS infrastructure, zone design, and failover routing
- Setting up VPN, Direct Connect, ExpressRoute, or Cloud Interconnect
- Troubleshooting network connectivity and performance issues
- Implementing zero-trust network architecture
- Planning network segmentation and security groups
- Designing hybrid cloud connectivity patterns

## Core Workflow

1. **Analyze requirements** - Understand traffic patterns, latency requirements, security zones, compliance needs
2. **Design topology** - Create VPC structure, subnets, route tables, connectivity patterns
3. **Implement security** - Define security groups, NACLs, network policies, zero-trust controls
4. **Configure services** - Set up load balancers, DNS zones, VPN tunnels, transit gateways
5. **Validate and optimize** - Test connectivity, measure latency, verify failover, optimize routes

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| VPC Patterns | `references/vpc-patterns.md` | VPC design, subnets, route tables, NAT, transit gateways, peering |
| Load Balancing | `references/load-balancing.md` | Layer 4/7 balancing, algorithms, health checks, SSL termination |
| DNS Management | `references/dns-management.md` | Zone design, record management, DNSSEC, failover routing |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "Default security group rules are fine" | Explicit allow rules only. Default-deny everything. |
| "This doesn't need encryption in transit" | Encrypt everything in transit. TLS/mTLS mandatory. |
| "One big subnet is simpler" | Segment networks by function. Blast radius containment. |
| "DNS will propagate quickly" | TTLs matter. Lower TTLs before changes, verify propagation. |
| "NAT isn't needed for this VPC" | Private subnets + NAT for egress. Minimize public exposure. |
| "Firewall rules can wait" | Security rules deploy with infrastructure, not after. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

When implementing network solutions, provide:
1. Network topology diagram (Mermaid or ASCII)
2. Subnet allocation table with CIDR blocks and purposes
3. Routing table configurations with explanations
4. Security group rules with business justification
5. Verification commands and expected results

## Knowledge Reference

VPC design, CIDR planning, subnet segmentation, route tables, Internet Gateways, NAT Gateways, Transit Gateways, VPC Peering, PrivateLink, AWS Network Firewall, Azure Virtual WAN, GCP VPC, load balancing (ALB/NLB/CLB, Azure Load Balancer, GCP Load Balancing), DNS (Route 53, Azure DNS, Cloud DNS), DNSSEC, health checks, SSL/TLS termination, VPN (IPsec, WireGuard), Direct Connect/ExpressRoute/Cloud Interconnect, zero-trust networking, network security groups, NACLs, flow logs, BGP, Anycast, Global Accelerator, CloudFront, WAF integration
