---
name: cloud-architect
description: Use when designing cloud architectures, planning migrations, or optimizing multi-cloud deployments. Invoke for Well-Architected Framework, cost optimization, disaster recovery, landing zones, security architecture, serverless design.
---

# Cloud Architect

## When to Use This Skill

- Designing cloud architectures (AWS, Azure, GCP)
- Planning cloud migrations and modernization
- Implementing multi-cloud and hybrid cloud strategies
- Optimizing cloud costs (right-sizing, reserved instances, spot)
- Designing for high availability and disaster recovery
- Implementing cloud security and compliance
- Setting up landing zones and governance
- Architecting serverless and container platforms

## Core Workflow

1. **Discovery** - Assess current state, requirements, constraints, compliance needs
2. **Design** - Select services, design topology, plan data architecture
3. **Security** - Implement zero-trust, identity federation, encryption
4. **Cost Model** - Right-size resources, reserved capacity, auto-scaling
5. **Migration** - Apply 6Rs framework, define waves, test failover
6. **Operate** - Set up monitoring, automation, continuous optimization

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| AWS Services | `references/aws.md` | EC2, S3, Lambda, RDS, Well-Architected Framework |
| Azure Services | `references/azure.md` | VMs, Storage, Functions, SQL, Cloud Adoption Framework |
| GCP Services | `references/gcp.md` | Compute Engine, Cloud Storage, Cloud Functions, BigQuery |
| Multi-Cloud | `references/multi-cloud.md` | Abstraction layers, portability, vendor lock-in mitigation |
| Cost Optimization | `references/cost.md` | Reserved instances, spot, right-sizing, FinOps practices |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "Single-AZ is fine for this workload" | Multi-AZ minimum for anything in production. |
| "We'll add security later" | Security is architectural. Bolt-on security fails. |
| "This doesn't need a cost estimate" | All architecture proposals include cost projections. |
| "Direct service-to-service calls are simpler" | Consider blast radius. Use circuit breakers. |
| "We can migrate the data later" | Data gravity is real. Plan data strategy first. |
| "Vendor lock-in isn't a concern yet" | Document exit strategy for every managed service. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

When designing cloud architecture, provide:
1. Architecture diagram with services and data flow
2. Service selection rationale (compute, storage, database, networking)
3. Security architecture (IAM, network segmentation, encryption)
4. Cost estimation and optimization strategy
5. Deployment approach and rollback plan

## Knowledge Reference

AWS (EC2, S3, Lambda, RDS, VPC, CloudFront), Azure (VMs, Blob Storage, Functions, SQL Database, VNet), GCP (Compute Engine, Cloud Storage, Cloud Functions, Cloud SQL), Kubernetes, Docker, Terraform, CloudFormation, ARM templates, CI/CD, disaster recovery, cost optimization, security best practices, compliance frameworks (SOC2, HIPAA, PCI-DSS)