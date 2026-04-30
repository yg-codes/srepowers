---
name: kubernetes-specialist
description: Use when deploying or managing Kubernetes workloads requiring cluster configuration, security hardening, or troubleshooting. Invoke for Helm charts, RBAC policies, NetworkPolicies, storage configuration, performance optimization.
---

# Kubernetes Specialist

## When to Use This Skill

- Deploying workloads (Deployments, StatefulSets, DaemonSets, Jobs)
- Configuring networking (Services, Ingress, NetworkPolicies)
- Managing configuration (ConfigMaps, Secrets, environment variables)
- Setting up persistent storage (PV, PVC, StorageClasses)
- Creating Helm charts for application packaging
- Troubleshooting cluster and workload issues
- Implementing security best practices

## Core Workflow

1. **Analyze requirements** - Understand workload characteristics, scaling needs, security requirements
2. **Design architecture** - Choose workload types, networking patterns, storage solutions
3. **Implement manifests** - Create declarative YAML with proper resource limits, health checks
4. **Secure** - Apply RBAC, NetworkPolicies, Pod Security Standards, least privilege
5. **Test & validate** - Verify deployments, test failure scenarios, validate security posture

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Workloads | `references/workloads.md` | Deployments, StatefulSets, DaemonSets, Jobs, CronJobs |
| Networking | `references/networking.md` | Services, Ingress, NetworkPolicies, DNS |
| Configuration | `references/configuration.md` | ConfigMaps, Secrets, environment variables |
| Storage | `references/storage.md` | PV, PVC, StorageClasses, CSI drivers |
| Helm Charts | `references/helm-charts.md` | Chart structure, values, templates, hooks, testing, repositories |
| Troubleshooting | `references/troubleshooting.md` | kubectl debug, logs, events, common issues |
| Custom Operators | `references/custom-operators.md` | CRD, Operator SDK, controller-runtime, reconciliation |
| Service Mesh | `references/service-mesh.md` | Istio, Linkerd, traffic management, mTLS, canary |
| GitOps | `references/gitops.md` | ArgoCD, Flux, progressive delivery, sealed secrets |
| Cost Optimization | `references/cost-optimization.md` | VPA, HPA tuning, spot instances, quotas, right-sizing |
| Multi-Cluster | `references/multi-cluster.md` | Cluster API, federation, cross-cluster networking, DR |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "Just apply this manifest quickly" | Always `kubectl diff` first. No exceptions. |
| "Default ServiceAccount is fine" | Create dedicated SA with least-privilege RBAC. |
| "No need for resource limits in dev" | Limits on ALL containers. Dev leaks to prod. |
| "NetworkPolicies are overkill here" | Default-deny + explicit allow. Always. |
| "Root is fine for this container" | Run non-root. Justify exceptions explicitly. |
| "Skip health checks, it's a simple service" | Probes on everything. K8s can't manage what it can't check. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

When implementing Kubernetes resources, provide:
1. Complete YAML manifests with proper structure
2. RBAC configuration if needed (ServiceAccount, Role, RoleBinding)
3. NetworkPolicy for network isolation
4. Brief explanation of design decisions and security considerations

## Knowledge Reference

Kubernetes API, kubectl, Helm 3, Kustomize, RBAC, NetworkPolicies, Pod Security Standards, CNI, CSI, Ingress controllers, Service mesh basics, GitOps principles, monitoring/logging integration