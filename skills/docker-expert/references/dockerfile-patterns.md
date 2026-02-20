# Dockerfile Patterns

## Multi-Stage Build Pattern

Separate build dependencies from runtime dependencies for minimal final images.

```dockerfile
# Stage 1: Build
FROM golang:1.25-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /build

# Copy go.mod first for better layer caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source and build
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app ./cmd/server

# Stage 2: Runtime
FROM gcr.io/distroless/static-debian12:nonroot

# Copy binary from builder
COPY --from=builder /app /app
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Distroless runs as nonroot by default (UID 65532)
USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/app"]
```

## Go Application Pattern (Full Example)

```dockerfile
# Syntax docker/dockerfile:1.4 for advanced features
# docker build --build-arg BUILDKIT_INLINE_CACHE=1 .

ARG GO_VERSION=1.25.3
ARG ALPINE_VERSION=3.21

# Build stage
FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS builder

RUN apk add --no-cache git ca-certificates build-base

WORKDIR /src

# Dependencies (cached layer)
COPY go.mod go.sum ./
RUN go mod download

# Build with cache mounting for faster rebuilds
COPY . .
RUN --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64 \
    go build -ldflags="-w -s -X main.version=$(git describe --tags --always)" \
    -o /app ./cmd/server

# Final stage using distroless
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /app /app
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

USER nonroot:nonroot

EXPOSE 8080 9090

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/app", "health"]

ENTRYPOINT ["/app"]
```

## Python Application Pattern

```dockerfile
ARG PYTHON_VERSION=3.14.3
ARG POETRY_VERSION=2.1.0

# Build stage
FROM python:${PYTHON_VERSION}-slim AS builder

WORKDIR /app

# Install poetry
RUN pip install poetry==${POETRY_VERSION}

# Copy dependency files
COPY pyproject.toml poetry.lock ./

# Install dependencies to venv
RUN poetry config virtualenvs.create false && \
    poetry install --no-interaction --no-ansi --only main

# Production stage
FROM python:${PYTHON_VERSION}-slim

# Create non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python${PYTHON_VERSION%.*}/site-packages /usr/local/lib/python${PYTHON_VERSION%.*}/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY --chown=appuser:appgroup . .

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Node.js Application Pattern

```dockerfile
ARG NODE_VERSION=25.4.0
ARG ALPINE_VERSION=3.21

# Build stage
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} AS builder

WORKDIR /app

# Copy package files first for caching
COPY package.json package-lock.json ./

# Install dependencies with ci for reproducible builds
RUN npm ci --prefer-offline --no-audit

# Copy source and build
COPY . .
RUN npm run build

# Prune dev dependencies
RUN npm prune --production

# Production stage
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION}

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001 -G nodejs

WORKDIR /app

# Copy built application and production dependencies
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./

USER nextjs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "dist/server.js"]
```

## Rust Application Pattern

```dockerfile
ARG RUST_VERSION=1.91.0
ARG ALPINE_VERSION=3.21

# Build stage
FROM rust:${RUST_VERSION}-alpine${ALPINE_VERSION} AS builder

RUN apk add --no-cache musl-dev

WORKDIR /app

# Create dummy main.rs to cache dependencies
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm -rf src

# Build actual application
COPY src ./src
RUN touch src/main.rs && cargo build --release

# Runtime stage
FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache ca-certificates tzdata && \
    addgroup -g 1000 appuser && \
    adduser -u 1000 -G appuser -D appuser

WORKDIR /app

COPY --from=builder /app/target/release/myapp /app/myapp

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s CMD wget -q --spider http://localhost:8080/health || exit 1

ENTRYPOINT ["./myapp"]
```

## Layer Optimization Techniques

### Order Instructions by Change Frequency

```dockerfile
# GOOD: Least frequently changed first
FROM alpine:3.21

# System packages (rarely change)
RUN apk add --no-cache ca-certificates

# Application user (rarely change)
RUN addgroup -g 1000 app && adduser -u 1000 -G app -D app

WORKDIR /app

# Dependencies (change with dependency updates)
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Application code (changes frequently)
COPY --chown=app:app . .

USER app
CMD ["python", "app.py"]
```

### Combine RUN Instructions

```dockerfile
# BAD: Multiple layers
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# GOOD: Single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

### Use BuildKit Cache Mounts

```dockerfile
# syntax=docker/dockerfile:1.4

FROM python:3.14-slim

WORKDIR /app

COPY requirements.txt .

# Mount cache for pip to reuse downloads
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

COPY . .
CMD ["python", "app.py"]
```

## .dockerignore Patterns

```dockerfile
# Version control
.git
.gitignore
.gitattributes

# Documentation
*.md
docs/
LICENSE

# CI/CD
.github/
.gitlab-ci.yml
.travis.yml
Jenkinsfile

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Build artifacts
dist/
build/
target/
node_modules/
__pycache__/
*.pyc
.pytest_cache/
.coverage
htmlcov/

# Environment files
.env
.env.*
*.local

# Logs and temporary files
*.log
logs/
tmp/
temp/

# Test files
tests/
test/
*_test.go
*_test.py
*.test.js
coverage/

# Docker files (prevent recursive copy)
Dockerfile*
docker-compose*.yml
.docker/

# OS files
.DS_Store
Thumbs.db
```

## HEALTHCHECK Patterns

```dockerfile
# HTTP health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# curl health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Custom script health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD /app/healthcheck.sh

# TCP health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD nc -z localhost 6379 || exit 1
```

## Best Practices

1. **Use Specific Versions**: Pin base images with digests, not `latest`
2. **Multi-Stage Builds**: Separate build and runtime environments
3. **Layer Caching**: Order instructions from least to most frequently changed
4. **Minimize Layers**: Combine related RUN commands
5. **Non-Root User**: Never run as root in production
6. **.dockerignore**: Exclude unnecessary files from build context
7. **HEALTHCHECK**: Include for long-running services
8. **Distroless/Alpine**: Use minimal base images for smaller attack surface
9. **BuildKit**: Enable for advanced features and caching
10. **Security Scan**: Always scan images before deployment
