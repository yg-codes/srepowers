# Docker Security Hardening

## Container User Security

### Non-Root User Pattern

```dockerfile
# Create dedicated user with specific UID/GID
RUN groupadd -r appgroup -g 1000 && \
    useradd -r -g appgroup -u 1000 -m -s /sbin/nologin appuser

# Set ownership for application files
COPY --chown=appuser:appgroup . /app

# Switch to non-root user
USER appuser:appgroup
```

### Distroless Non-Root

```dockerfile
# Distroless images come with nonroot user (UID 65532)
FROM gcr.io/distroless/static-debian12:nonroot

# Already configured for non-root
USER nonroot:nonroot
```

### Alpine Non-Root

```dockerfile
FROM alpine:3.21

# Create user and group
RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

USER appuser:appgroup
```

## Dockerfile Security Hardening

### Secure Base Image Selection

```dockerfile
# PREFER: Distroless (minimal attack surface)
FROM gcr.io/distroless/static-debian12:nonroot
FROM gcr.io/distroless/base-debian12:nonroot
FROM gcr.io/distroless/java21-debian12

# PREFER: Alpine (small, minimal packages)
FROM alpine:3.21

# AVOID: Full OS images (large attack surface)
# FROM ubuntu:latest
# FROM debian:latest

# AVOID: Latest tag (unpredictable)
# FROM node:latest
```

### Pinned Image Digests

```dockerfile
# GOOD: Pin with digest for reproducibility
FROM alpine:3.21@sha256:0a4eaa0eecf5f8c050e5bba433f58c052be7587ee8af3e8b39fef0a49d771e04

# Can also use variable for digest
ARG ALPINE_DIGEST=sha256:0a4eaa0eecf5f8c050e5bba433f58c052be7587ee8af3e8b39fef0a49d771e04
FROM alpine:3.21@${ALPINE_DIGEST}
```

### Read-Only Root Filesystem

```dockerfile
# Dockerfile
FROM alpine:3.21

# Create writable directories for application
RUN mkdir -p /tmp/app && chmod 777 /tmp/app

# docker run with read-only
# docker run --read-only --tmpfs /tmp/app:rw,size=10m myimage
```

```yaml
# Kubernetes
securityContext:
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
```

### Drop All Capabilities

```dockerfile
# In docker-compose.yml or k8s manifest, not Dockerfile
# Only grant what's needed

# Docker Compose
cap_drop:
  - ALL
cap_add:
  - NET_BIND_SERVICE  # Only if binding to ports < 1024
```

```yaml
# Kubernetes
securityContext:
  capabilities:
    drop:
      - ALL
    add:
      - NET_BIND_SERVICE
```

## Secret Management

### NEVER Do This

```dockerfile
# BAD: Secrets in environment variables
ENV DB_PASSWORD=SuperSecret123

# BAD: Secrets in ARG (end up in image history)
ARG API_KEY=secret123

# BAD: Copying secret files into image
COPY .env /app/.env
COPY secrets/ /app/secrets/
```

### Proper Secret Handling

```dockerfile
# GOOD: Use BuildKit secret mounting (build time)
# syntax=docker/dockerfile:1.4

FROM alpine:3.21

# Mount secret during build, not stored in image
RUN --mount=type=secret,id=db_password \
    DB_PASSWORD=$(cat /run/secrets/db_password) && \
    ./configure-with-password.sh

# Build command:
# docker build --secret id=db_password,src=./secrets/db_password.txt .
```

```yaml
# docker-compose.yml for runtime secrets
services:
  app:
    image: myapp:latest
    secrets:
      - db_password
      - api_key

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    external: true
```

```yaml
# Kubernetes secrets
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  db-password: SuperSecret123
---
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: db-password
```

## Vulnerability Scanning

### Trivy Integration

```bash
# Scan image for vulnerabilities
trivy image myapp:latest

# Scan with severity filter
trivy image --severity HIGH,CRITICAL myapp:latest

# Output in different formats
trivy image --format json --output results.json myapp:latest
trivy image --format sarif --output results.sarif myapp:latest

# Scan Dockerfile for misconfigurations
trivy config ./Dockerfile
```

### Grype Integration

```bash
# Scan image
grype myapp:latest

# Output JSON
grype myapp:latest -o json > results.json

# Fail on severity
grype myapp:latest --fail-on high
```

### Docker Scout (Built-in)

```bash
# Quick vulnerability check
docker scout quickview myapp:latest

# Detailed CVE analysis
docker scout cves myapp:latest

# Compare images
docker scout compare --to myapp:v1 myapp:v2

# Recommendations
docker scout recommendations myapp:latest
```

## DHI Detection (Docker Host Intrusion)

### Monitoring Patterns

```bash
# Check for container anomalies
docker ps --filter "status=exited" --format "table {{.ID}}\t{{.Image}}\t{{.Status}}"

# Monitor container resource usage
docker stats --no-stream

# Inspect container security settings
docker inspect --format='{{.HostConfig.SecurityOpt}}' <container>

# Check capability drops
docker inspect --format='{{.HostConfig.CapDrop}}' <container>

# Verify non-root execution
docker inspect --format='{{.Config.User}}' <container>
```

### Falco Rules for Docker

```yaml
# Detect container started with privileged mode
- rule: Launch Privileged Container
  desc: Detect container started with privileged flag
  condition: container_started and container.privileged=true
  output: Privileged container started (user=%user.name container=%container.id image=%container.image.repository)
  priority: WARNING
  tags: [container, privileged]

# Detect container with sensitive mount
- rule: Launch Sensitive Mount Container
  desc: Detect container with sensitive path mounted
  condition: >
    container_started and
    (container.mount.dest contains "/etc" or
     container.mount.dest contains "/root" or
     container.mount.dest contains "/var/run/docker.sock")
  output: Container with sensitive mount (user=%user.name container=%container.id mounts=%container.mounts)
  priority: WARNING
  tags: [container, mount]

# Detect shell spawned in container
- rule: Shell Spawned in Container
  desc: Detect shell executed inside container
  condition: >
    spawned_process and
    container and
    (proc.name in (bash, sh, zsh, dash))
  output: Shell spawned in container (user=%user.name container=%container.id shell=%proc.name)
  priority: NOTICE
  tags: [container, shell]
```

## Security Best Practices Checklist

### Dockerfile

- [ ] Use minimal base images (distroless, alpine)
- [ ] Pin image versions with digests
- [ ] Run as non-root user
- [ ] Do not store secrets in image
- [ ] Use COPY instead of ADD (unless extracting tar)
- [ ] Set appropriate file permissions
- [ ] Include HEALTHCHECK
- [ ] Minimize layers and clean up in same layer
- [ ] Use multi-stage builds

### Runtime

- [ ] Drop all unnecessary capabilities
- [ ] Use read-only root filesystem
- [ ] Set resource limits
- [ ] Use security profiles (seccomp, AppArmor)
- [ ] Enable Docker Content Trust
- [ ] Scan images regularly
- [ ] Use signed images only
- [ ] Network segmentation

### CI/CD

- [ ] Automated vulnerability scanning
- [ ] Block images with HIGH/CRITICAL CVEs
- [ ] Generate and verify SBOM
- [ ] Sign all production images
- [ ] Audit trail for image pulls

## Common Vulnerability Remediation

| CVE Type | Remediation |
|----------|-------------|
| Base image CVE | Update base image version |
| Package CVE | Update package in same layer |
| Dependency CVE | Rebuild with updated dependencies |
| Runtime CVE | Patch or replace vulnerable library |

```dockerfile
# Remediation example
# Before (vulnerable)
FROM alpine:3.20
RUN apk add --no-cache curl=8.5.0

# After (patched)
FROM alpine:3.21
RUN apk add --no-cache curl=8.12.0
```
