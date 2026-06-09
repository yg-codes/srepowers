---
name: certificate-management
description: Use when managing TLS certificates and PKI infrastructure — issuing, renewing, or rotating certificates, debugging TLS handshake failures, managing cert-manager in Kubernetes, operating an internal CA, creating CSRs, or checking certificate expiration. Also use for "certificate expiring", "TLS error", "cert-manager", "openssl", "CSR", "certificate renewal", "TLS handshake failure", "CA certificate", "intermediate CA", "certificate chain", "x509", or any TLS/PKI certificate lifecycle management task.
---

# Certificate Management

Manage the full TLS certificate lifecycle: issuance, renewal, rotation, and debugging. Covers internal CA operations, cert-manager in Kubernetes, OpenSSL troubleshooting, and certificate chain validation.

**Core principle:** Rotate before expiry, validate chain before deploying, monitor proactively.

**Announce at start:** "I'm using the certificate-management skill to [issue/debug/rotate] certificates."

## When to Use

**Use when:**
- Issuing new TLS certificates from an internal CA
- Renewing or rotating expiring certificates
- Debugging TLS handshake failures or certificate validation errors
- Managing cert-manager resources in Kubernetes
- Creating Certificate Signing Requests (CSRs)
- Checking certificate expiration dates across infrastructure
- Building or validating certificate chains
- Configuring trust bundles for applications

**Exceptions:**
- Let's Encrypt with external ACME clients — outside scope (internal CA focus)
- Application-level mTLS design — use `architecture-designer`

## The Process

### Certificate Lifecycle

```
Create CSR → Sign with CA → Deploy → Monitor → Rotate before expiry
```

### Step 1: Generate a CSR

```bash
# Generate private key and CSR in one step
openssl req -new -newkey rsa:4096 -nodes \
  -keyout server.key \
  -out server.csr \
  -subj "/C=JP/ST=Tokyo/O=FSX/CN=server.fsx.zone"

# Generate CSR from existing key
openssl req -new -key server.key -out server.csr \
  -subj "/C=JP/ST=Tokyo/O=FSX/CN=server.fsx.zone"

# Verify the CSR
openssl req -text -noout -in server.csr
```

### Step 2: Sign with Internal CA

```bash
# Sign CSR with the CA (adjust days as needed)
openssl x509 -req -in server.csr \
  -CA ca.crt -CAkey ca.key \
  -CAcreateserial \
  -days 365 \
  -out server.crt \
  -sha256

# Sign with SAN extension (modern TLS requires SAN, not CN)
openssl x509 -req -in server.csr \
  -CA ca.crt -CAkey ca.key \
  -CAcreateserial \
  -days 365 \
  -out server.crt \
  -sha256 \
  -extfile <(printf "subjectAltName=DNS:server.fsx.zone,DNS:server,DNS:server.internal")

# Verify the signed certificate
openssl x509 -text -noout -in server.crt
```

### Step 3: Validate the Chain

```bash
# Verify certificate against CA
openssl verify -CAfile ca.crt server.crt

# Verify full chain (intermediate + root)
openssl verify -CAfile <(cat intermediate.crt root.crt) server.crt

# Check certificate details
openssl x509 -in server.crt -noout -subject -issuer -dates -ext subjectAltName
```

### Step 4: Deploy

Deploy certificate and key to the target service. Common targets:

```bash
# Copy to remote host (stage via /tmp)
scp /tmp/server.crt server.fsx.zone:/etc/ssl/certs/server.crt
scp /tmp/server.key server.fsx.zone:/etc/ssl/private/server.key

# Set correct permissions
ssh server.fsx.zone 'chmod 644 /etc/ssl/certs/server.crt'
ssh server.fsx.zone 'chmod 600 /etc/ssl/private/server.key'
ssh server.fsx.zone 'chown root:ssl-cert /etc/ssl/private/server.key'

# Reload the service to pick up new certificate
ssh server.fsx.zone 'sudo systemctl reload nginx'
# or
ssh server.fsx.zone 'sudo systemctl reload haproxy'
```

### Step 5: Verify the Deployment

```bash
# Check the served certificate
echo | openssl s_client -connect server.fsx.zone:443 -servername server.fsx.zone 2>/dev/null | \
  openssl x509 -noout -dates -subject

# Verify the full chain from client perspective
echo | openssl s_client -connect server.fsx.zone:443 -servername server.fsx.zone -CAfile ca.crt

# Check for upcoming expiry (days until expiry)
echo | openssl s_client -connect server.fsx.zone:443 -servername server.fsx.zone 2>/dev/null | \
  openssl x509 -noout -enddate | cut -d= -f2
```

## Kubernetes: cert-manager

### Certificate Request

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: server-cert
  namespace: default
spec:
  secretName: server-tls
  duration: 2160h    # 90 days
  renewBefore: 360h  # Auto-renew 15 days before expiry
  issuerRef:
    name: ca-issuer
    kind: ClusterIssuer
  dnsNames:
    - server.fsx.zone
    - server
    - server.internal
```

### Check Certificate Status

```bash
# List certificates
kubectl get certificates -A

# Describe a specific certificate
kubectl describe certificate server-cert -n default

# Check the secret
kubectl get secret server-tls -o yaml

# Decode and inspect the certificate
kubectl get secret server-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | \
  openssl x509 -text -noout

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

### Order Processing

```bash
# Check certificate requests
kubectl get certificaterequests -A

# Describe a stuck request
kubectl describe certificaterequest <request-name>
```

### Trust Manager

```bash
# List trust bundles
kubectl get trustbundles -A

# Check bundle content
kubectl get trustbundle <name> -o yaml
```

## Expiration Monitoring

### Fleet-wide Certificate Check

```bash
# Check expiry on a remote host
ssh server.fsx.zone \
  "echo | openssl s_client -connect localhost:443 2>/dev/null | openssl x509 -noout -enddate"

# Check local certificate files
for cert in /etc/ssl/certs/*.crt; do
  expiry=$(openssl x509 -enddate -noout -in "$cert" | cut -d= -f2)
  echo "$cert expires: $expiry"
done | sort -t= -k2
```

### Proactive Rotation Timeline

| Time until expiry | Action |
|-------------------|--------|
| > 30 days | Normal operations |
| 30–14 days | Schedule rotation |
| 14–7 days | Rotate immediately |
| < 7 days | Emergency rotation — treat as incident |

## Debugging TLS Failures

### TLS Handshake Failure

```bash
# Verbose TLS connection attempt
openssl s_client -connect server.fsx.zone:443 -servername server.fsx.zone -showcerts

# Common errors and causes:
# "unable to verify the first certificate" → incomplete chain
# "certificate verify failed" → CA not trusted by client
# "certificate has expired" → obvious — renew
# "self signed certificate" → CA not in trust store
# "CN mismatch" → SAN or CN doesn't match requested hostname
```

### Chain Issues

```bash
# Build a proper chain: leaf → intermediate → root
cat server.crt intermediate.crt > fullchain.crt

# Verify the chain
openssl verify -CAfile <(cat root.crt) -untrusted intermediate.crt server.crt
```

### Certificate Fingerprint Verification

```bash
# Compare fingerprints across servers
openssl x509 -in server.crt -noout -fingerprint -sha256
```

## Anti-Patterns

| Anti-pattern | Why | Do instead |
|-------------|-----|-----------|
| Using self-signed certs in production | No chain of trust, browser warnings | Use internal CA-issued certificates |
| Hardcoded certificate paths in code | Breaks when paths change | Use configuration management (Puppet/Hiera) |
| Ignoring certificate expiry warnings | Service outage when cert expires | Monitor proactively, rotate early |
| 10-year certificate validity | Compromised key is exposed for a decade | Use 90–365 day validity, automate rotation |
| Missing SAN extension | Modern browsers/TLS ignore CN | Always include SAN in CSRs |
| Deploying cert without reloading service | Service continues serving old cert | Always reload/restart after deployment |

## Integration

**Called by:**
- `srepowers:kubernetes-specialist` — for cert-manager operations
- `srepowers:systematic-troubleshooting` — for TLS-related incidents
- `srepowers:puppet-deploy` — when certificates are managed via Puppet (`fsx_ca` module)

**Pairs with:**
- `srepowers:safety-validator` — certificate operations on production services
- `srepowers:network-engineer` — for TLS-related network debugging

## SRE Principles

### Safety First
- Always generate new key + CSR for renewal — never reuse old keys
- Test certificate deployment on a single node before fleet rollout
- Keep the old certificate available for rollback until the new one is verified

### Structured Output
- Report: subject, issuer, serial, notBefore, notAfter, SANs, fingerprint
- Use tables for fleet-wide expiration audits

### Evidence-Driven
- Capture `openssl s_client` output showing successful TLS handshake after deployment
- Show before/after certificate dates when rotating

### Audit-Ready
- Record: old serial → new serial, rotation date, CA used, target service
- Include the CSR and signed certificate in the change record

### Communication
- Report expiration status proactively: "3 certificates expire within 30 days"
- Surface chain issues clearly: "intermediate CA is missing from the server's chain file"
