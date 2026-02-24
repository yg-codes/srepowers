# Docker Supply Chain Security

## Overview

Supply chain security ensures the integrity and provenance of container images from build to deployment. This includes SBOM generation, image signing, and SLSA provenance attestation.

## SBOM Generation

### Syft (Anchore)

```bash
# Generate SBOM from image
syft myapp:latest

# Output to file in SPDX format
syft myapp:latest -o spdx-json > sbom.spdx.json

# Output in CycloneDX format
syft myapp:latest -o cyclonedx-json > sbom.cdx.json

# Generate SBOM during build
syft registry:myapp:latest -o json > sbom.json

# Include in Dockerfile (not recommended for production images)
# docker build --sbom=generator=syft ...
```

### Trivy SBOM

```bash
# Generate SBOM with Trivy
trivy image --format spdx-json --output sbom.spdx.json myapp:latest

# CycloneDX format
trivy image --format cyclonedx --output sbom.cdx.json myapp:latest

# Generate and scan in one step
trivy sbom sbom.spdx.json
```

### Docker Scout SBOM

```bash
# Quick SBOM view
docker scout sbom myapp:latest

# Export SBOM
docker scout sbom --format spdx --output sbom.spdx.json myapp:latest
```

## Image Signing with Cosign

### Key Generation

```bash
# Generate key pair
cosign generate-key-pair

# Output: cosign.key (private) and cosign.pub (public)
# Store private key securely (e.g., in a secrets manager)

# Generate key with password
COSIGN_PASSWORD=mysecurepassword cosign generate-key-pair
```

### Signing Images

```bash
# Sign image with key
cosign sign --key cosign.key myregistry.io/myapp:v1.0.0

# Sign with annotation
cosign sign --key cosign.key \
  -a "builder=ci-pipeline" \
  -a "commit=$(git rev-parse HEAD)" \
  -a "workflow=build-and-push" \
  myregistry.io/myapp:v1.0.0

# Sign with timestamp
cosign sign --key cosign.key \
  --timestamp-server-url https://timestamp.digicert.com \
  myregistry.io/myapp:v1.0.0
```

### Signing with Keyless (Fulcio)

```bash
# Keyless signing with OIDC (requires authentication)
cosign sign myregistry.io/myapp:v1.0.0

# With specific identity
cosign sign \
  --identity-token $OIDC_TOKEN \
  myregistry.io/myapp:v1.0.0
```

### Verification

```bash
# Verify signature with public key
cosign verify --key cosign.pub myregistry.io/myapp:v1.0.0

# Verify with annotations
cosign verify --key cosign.pub \
  -a "builder=ci-pipeline" \
  myregistry.io/myapp:v1.0.0

# Verify keyless signature
cosign verify myregistry.io/myapp:v1.0.0 \
  --certificate-identity=my@email.com \
  --certificate-oidc-issuer=https://accounts.google.com
```

### Kubernetes Admission Control

```yaml
# Kyverno policy to verify cosign signatures
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signatures
spec:
  validationFailureAction: enforce
  background: false
  rules:
  - name: verify-signature
    match:
      any:
      - resources:
          kinds:
          - Pod
    verifyImages:
    - imageReferences:
      - "myregistry.io/*"
      attestors:
      - entries:
        - keys:
            publicKeys: |-
              -----BEGIN PUBLIC KEY-----
              <your public key here>
              -----END PUBLIC KEY-----
```

## SLSA Provenance

### Overview

SLSA (Supply-chain Levels for Software Artifacts) provenance provides verifiable information about how software was built.

### SLSA Levels

| Level | Description | Requirements |
|-------|-------------|--------------|
| 1 | Provenance exists | Documentation of build process |
| 2 | Hosted build platform | Tamper-resistant build logs |
| 3 | Hardened builds | Non-falsifiable provenance |
| 4 | Two-party review | Hermetic, reproducible builds |

### Generating Provenance with SLSA Generator

```yaml
# GitHub Actions with SLSA generator
name: Build and Sign
on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      digest: ${{ steps.build.outputs.digest }}
    steps:
    - uses: actions/checkout@v4

    - name: Build Image
      id: build
      run: |
        docker build -t myregistry.io/myapp:${{ github.ref_name }} .
        docker push myregistry.io/myapp:${{ github.ref_name }}
        DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' myregistry.io/myapp:${{ github.ref_name}})
        echo "digest=$DIGEST" >> $GITHUB_OUTPUT

  provenance:
    needs: build
    permissions:
      actions: read
      id-token: write
      contents: write
    uses: slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@v2.0.0
    with:
      image: myregistry.io/myapp
      digest: ${{ needs.build.outputs.digest }}
```

### In-Toto Attestations

```bash
# Generate in-toto attestation
cosign attest --predicate ./attestation.json --type slsaprovenance \
  --key cosign.key myregistry.io/myapp:v1.0.0

# Verify attestation
cosign verify-attestation --type slsaprovenance \
  --key cosign.pub myregistry.io/myapp:v1.0.0
```

### Attestation Types

```json
{
  "_type": "https://in-toto.io/Statement/v0.1",
  "predicateType": "https://slsa.dev/provenance/v0.2",
  "subject": [
    {
      "name": "myregistry.io/myapp",
      "digest": { "sha256": "abc123..." }
    }
  ],
  "predicate": {
    "builder": {
      "id": "https://github.com/myorg/myrepo/.github/workflows/build.yml@refs/heads/main"
    },
    "buildType": "https://github.com/slsa-framework/slsa-github-generator/container@v1",
    "invocation": {
      "configSource": {
        "uri": "git+https://github.com/myorg/myrepo",
        "digest": { "sha1": "abc123..." },
        "entryPoint": ".github/workflows/build.yml"
      }
    },
    "metadata": {
      "buildStartedOn": "2024-01-15T10:00:00Z",
      "buildFinishedOn": "2024-01-15T10:05:00Z",
      "completeness": {
        "parameters": true,
        "environment": false,
        "materials": true
      }
    },
    "materials": [
      {
        "uri": "git+https://github.com/myorg/myrepo",
        "digest": { "sha1": "abc123..." }
      }
    ]
  }
}
```

## Complete CI/CD Pipeline Example

```yaml
# .github/workflows/container-supply-chain.yml
name: Container Supply Chain Security

on:
  push:
    branches: [main]
    tags: ['v*']

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      id-token: write

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Log in to Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    - name: Extract Metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=semver,pattern={{version}}
          type=sha,prefix=

    - name: Build and Push
      id: build
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        sbom: true
        provenance: true
        cache-from: type=gha
        cache-to: type=gha,mode=max

    # Vulnerability Scanning
    - name: Scan Image
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        format: 'sarif'
        output: 'trivy-results.sarif'
        severity: 'CRITICAL,HIGH'

    - name: Upload Trivy Results
      uses: github/codeql-action/upload-sarif@v3
      with:
        sarif_file: 'trivy-results.sarif'

    # Generate SBOM
    - name: Generate SBOM
      uses: anchore/sbom-action@v0
      with:
        image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        format: spdx-json
        output-file: sbom.spdx.json

    - name: Upload SBOM
      uses: actions/upload-artifact@v4
      with:
        name: sbom
        path: sbom.spdx.json

    # Sign Image
    - name: Install Cosign
      uses: sigstore/cosign-installer@v3

    - name: Sign Image
      run: |
        cosign sign --yes \
          -a "repo=${{ github.repository }}" \
          -a "workflow=${{ github.workflow }}" \
          -a "ref=${{ github.sha }}" \
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.build.outputs.digest }}

    # Attest SBOM
    - name: Attest SBOM
      run: |
        cosign attest --yes \
          --predicate sbom.spdx.json \
          --type spdxjson \
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.build.outputs.digest }}
```

## Policy Enforcement

### OPA/Gatekeeper Policy

```yaml
# Require signed images
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredcosign
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredCosign
      validation:
        openAPIV3Schema:
          type: object
          properties:
            image:
              type: string
            key:
              type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredcosign

        violation[{"msg": msg}] {
          input.review.kind.kind == "Pod"
          container := input.review.object.spec.containers[_]
          not container.image == input.parameters.image
          msg := sprintf("Container %v image must be signed", [container.name])
        }
```

### Cosign Policy Controller

```yaml
# ClusterImagePolicy for policy-controller
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: myapp-policy
spec:
  images:
  - glob: "myregistry.io/myapp/**"
  authorities:
  - key:
      data: |
        -----BEGIN PUBLIC KEY-----
        <your public key>
        -----END PUBLIC KEY-----
    attestations:
    - predicateType: slsaprovenance
      policy:
        type: cue
        data: |
          predicate: {
            builder: {
              id: =~"^https://github.com/myorg/"
            }
          }
```

## Supply Chain Security Checklist

- [ ] Generate SBOM for all images
- [ ] Sign all production images with cosign
- [ ] Store signing keys securely
- [ ] Verify signatures before deployment
- [ ] Generate SLSA provenance attestations
- [ ] Enforce signature verification in cluster
- [ ] Scan for vulnerabilities regularly
- [ ] Use pinned base image digests
- [ ] Maintain audit trail of image provenance
- [ ] Implement policy for allowed registries
