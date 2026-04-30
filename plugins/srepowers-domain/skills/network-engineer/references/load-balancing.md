# Load Balancing

## Load Balancer Types Comparison

| Type | Layer | Protocol | Use Case | AWS Service |
|------|-------|----------|----------|-------------|
| Layer 4 | Transport | TCP/UDP | High performance, non-HTTP | Network Load Balancer (NLB) |
| Layer 7 | Application | HTTP/HTTPS | Web apps, content routing | Application Load Balancer (ALB) |
| Classic | Layer 4/7 | TCP/HTTP/HTTPS | Legacy applications | Classic Load Balancer (CLB) |

## Application Load Balancer (ALB)

### Architecture

```
                    Users
                      |
                  [ Internet ]
                      |
              [ ALB (HTTPS:443) ]
                      |
         +------------+------------+
         |            |            |
    +----+----+  +----+----+  +----+----+
    | Target 1 |  | Target 2 |  | Target 3 |
    | (AZ-A)   |  | (AZ-B)   |  | (AZ-C)   |
    +----------+  +----------+  +----------+
```

### Listener and Target Group Configuration

```hcl
# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.environment == "production"
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# HTTP to HTTPS redirect
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Target Group
resource "aws_lb_target_group" "app" {
  name     = "${var.name}-app"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }
}
```

### Path-Based Routing

```hcl
# Path-based routing rules
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.static.arn
  }

  condition {
    path_pattern {
      values = ["/static/*", "/assets/*"]
    }
  }
}
```

### Host-Based Routing

```hcl
# Host-based routing for multi-tenant
resource "aws_lb_listener_rule" "tenant_a" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tenant_a.arn
  }

  condition {
    host_header {
      values = ["tenant-a.example.com"]
    }
  }
}
```

## Network Load Balancer (NLB)

### Architecture

```
                    Users
                      |
                  [ Internet ]
                      |
              [ NLB (TCP:443) ]
                      |
         +------------+------------+
         |            |            |
    +----+----+  +----+----+  +----+----+
    | Target 1 |  | Target 2 |  | Target 3 |
    | 10.0.1.10|  | 10.0.2.10|  | 10.0.3.10|
    +----------+  +----------+  +----------+
```

### NLB Configuration

```hcl
# Network Load Balancer
resource "aws_lb" "main" {
  name               = "${var.name}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.public[*].id

  enable_cross_zone_load_balancing = true
}

# TCP Listener
resource "aws_lb_listener" "tcp" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Target Group (TCP)
resource "aws_lb_target_group" "app" {
  name        = "${var.name}-app"
  port        = 8443
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    port                = 8080
    protocol            = "HTTP"
    unhealthy_threshold = 2
  }
}
```

## Load Balancing Algorithms

### Round Robin (Default)
- Distributes requests sequentially
- Best for homogeneous targets

### Least Outstanding Requests
- Routes to target with fewest pending requests
- Better for varying request durations

```hcl
resource "aws_lb_target_group" "app" {
  # ... other config

  load_balancing_algorithm_type = "least_outstanding_requests"
}
```

### Weighted Target Groups
```hcl
# Blue-Green deployment with weights
resource "aws_lb_target_group" "blue" {
  name = "${var.name}-blue"
  # ... config
}

resource "aws_lb_target_group" "green" {
  name = "${var.name}-green"
  # ... config
}

# Weighted forwarding
resource "aws_lb_listener" "main" {
  # ...

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.blue.arn
        weight = 90
      }

      target_group {
        arn    = aws_lb_target_group.green.arn
        weight = 10
      }
    }
  }
}
```

## Health Check Configuration

### Health Check Parameters

| Parameter | Recommended Value | Description |
|-----------|-------------------|-------------|
| `interval` | 30s | Time between checks |
| `timeout` | 5s | Max wait for response |
| `healthy_threshold` | 2 | Consecutive successes to mark healthy |
| `unhealthy_threshold` | 3 | Consecutive failures to mark unhealthy |
| `matcher` | 200 | Expected HTTP status code(s) |

### Health Check Endpoint Design

```python
# Recommended health check endpoint
@app.route('/health')
def health():
    checks = {
        'database': check_db_connection(),
        'cache': check_redis_connection(),
        'storage': check_s3_access(),
    }

    all_healthy = all(checks.values())
    status_code = 200 if all_healthy else 503

    return jsonify({
        'status': 'healthy' if all_healthy else 'unhealthy',
        'checks': checks,
        'timestamp': datetime.utcnow().isoformat()
    }), status_code
```

## SSL/TLS Termination

### Certificate Configuration

```hcl
# ACM Certificate
resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# SSL Policy Selection
# Use modern TLS policies for production
# ELBSecurityPolicy-TLS-1-2-2017-01 - TLS 1.2 only
# ELBSecurityPolicy-TLS-1-2-Ext-2018-06 - Extended TLS 1.2 ciphers
# ELBSecurityPolicy-FS-1-2-Res-2019-08 - Forward secrecy, TLS 1.2
```

### SSL Negotiation Settings

```hcl
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"

  # Modern TLS policy (recommended)
  ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

## Internal vs External Load Balancers

| Aspect | External | Internal |
|--------|----------|----------|
| Access | Internet-facing | VPC-only |
| IP Address | Public IPs | Private IPs |
| Use Case | Web applications | Internal services, microservices |

```hcl
# External ALB
resource "aws_lb" "external" {
  name               = "external-alb"
  internal           = false  # Internet-facing
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
}

# Internal ALB
resource "aws_lb" "internal" {
  name               = "internal-alb"
  internal           = true  # VPC-only
  load_balancer_type = "application"
  subnets            = aws_subnet.private[*].id
}
```

## Connection Draining

```hcl
resource "aws_lb_target_group" "app" {
  # ... other config

  # Deregistration delay (connection draining)
  deregistration_delay = 300  # 5 minutes for graceful shutdown
}
```

## Access Logging

```hcl
# Enable ALB access logs
resource "aws_lb" "main" {
  # ... other config

  access_logs {
    bucket  = aws_s3_bucket.logs.id
    prefix  = "alb-logs"
    enabled = true
  }
}

# S3 bucket policy for ALB logs
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}
```

## Best Practices

1. **Multi-AZ Deployment**: Always deploy across at least 2 AZs
2. **Health Checks**: Use dedicated /health endpoints with dependency checks
3. **SSL Termination**: Terminate SSL at the load balancer, use HTTP internally
4. **Access Logs**: Enable for troubleshooting and security analysis
5. **Connection Draining**: Set appropriate deregistration delay for graceful shutdown
6. **Security Groups**: Restrict ALB inbound to necessary ports, restrict target inbound to ALB SG only
7. **Monitoring**: Set up CloudWatch alarms for 4xx/5xx errors, latency, and healthy host count
