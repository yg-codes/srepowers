# Defense-in-Depth Validation (Infrastructure)

## Overview

When you fix an infrastructure issue caused by a misconfiguration or missing validation, fixing it at one layer feels sufficient. But that single fix can be bypassed by different code paths, automation, or human error.

**Core principle:** Validate at EVERY layer data or configuration passes through. Make the misconfiguration structurally impossible.

## Why Multiple Layers

Single validation: "We fixed the issue"
Multiple layers: "We made the issue impossible"

Different layers catch different cases:
- Entry validation catches most misconfigurations
- Admission control catches violations at the cluster boundary
- Runtime guards prevent context-specific dangers
- Observability helps when other layers fail silently

## The Four Layers (Infrastructure)

### Layer 1: Input Validation
**Purpose:** Reject obviously invalid configuration at the source

```yaml
# Helm values schema validation
# values.schema.json - rejects empty/missing required fields
{
  "properties": {
    "image": {
      "properties": {
        "repository": { "type": "string", "minLength": 1 },
        "tag": { "type": "string", "minLength": 1 }
      },
      "required": ["repository", "tag"]
    }
  }
}
```

### Layer 2: Policy Enforcement
**Purpose:** Ensure configuration is valid for this operation/environment

```yaml
# OPA/Gatekeeper constraint: require resource limits
# Catches what schema validation misses (presence vs correctness)
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredResources
spec:
  match:
    kinds: [{ apiGroups: ["apps"], kinds: ["Deployment"] }]
  parameters:
    limits: ["memory", "cpu"]
    requests: ["memory", "cpu"]
```

### Layer 3: Admission / Environment Guards
**Purpose:** Prevent dangerous operations in specific contexts

```bash
# Pre-deployment check script
# Refuses to deploy to production without explicit env confirmation
if [[ "$KUBE_CONTEXT" == *"prod"* ]]; then
  if [[ -z "$CONFIRMED_PROD_DEPLOY" ]]; then
    echo "ERROR: Production deploy requires CONFIRMED_PROD_DEPLOY=true"
    exit 1
  fi
fi
```

### Layer 4: Observability Instrumentation
**Purpose:** Capture context for forensics when other layers fail

```yaml
# Structured logging with deployment context
# Log at every significant operation boundary
{
  "level": "info",
  "event": "deployment_started",
  "namespace": "production",
  "image": "app:v1.2.3",
  "triggered_by": "ci/cd pipeline #456",
  "timestamp": "2025-03-17T14:00:00Z"
}
```

## Applying the Pattern

When you find an infrastructure issue:

1. **Trace the data flow** — Where does the bad config originate? Where is it consumed?
2. **Map all checkpoints** — List every layer it passes through (source → CI → Helm → K8s → runtime)
3. **Add validation at each layer** — Input, policy, admission guard, observability
4. **Test each layer** — Try to bypass layer 1, verify layer 2 catches it

## Example: Wrong Image Tag in Production

**Issue:** A deployment used `latest` tag instead of a pinned version

**Data flow:**
1. Developer commits `image.tag: latest` to values file
2. CI pipeline renders Helm chart (no tag validation)
3. Kubernetes accepts the deployment (no policy)
4. Pod pulls `:latest` — unpredictable behavior

**Four layers added:**
- Layer 1: `values.schema.json` rejects `latest` as tag value
- Layer 2: OPA policy requires semver-format tags in production namespace
- Layer 3: CI pipeline checks `KUBE_CONTEXT` and validates tag format
- Layer 4: Deployment event log includes full image reference with digest

**Result:** All four paths blocked; `:latest` impossible to reach production

## Key Insight

**Don't stop at one validation point.** Different code paths (manual apply, CI pipeline, GitOps reconciler) can bypass a single check. Add guards at every layer that data passes through.

## See Also

- `root-cause-tracing.md` — How to trace where the misconfiguration originated
