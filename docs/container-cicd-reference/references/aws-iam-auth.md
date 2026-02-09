# AWS IAM User vs IAM Role - Complete Guide

**Document Version:** 1.0
**Date:** 2025-10-22
**Context:** Understanding IAM for GitLab CI/CD with ECR

---

## Table of Contents

1. [IAM User vs IAM Role - Key Differences](#iam-user-vs-iam-role---key-differences)
2. [Visual Comparison](#visual-comparison)
3. [Which to Use for GitLab CI/CD](#which-to-use-for-gitlab-cicd)
4. [How to Check Existing IAM Resources](#how-to-check-existing-iam-resources)
5. [Decision Guide](#decision-guide)

---

## IAM User vs IAM Role - Key Differences

### **IAM User** - A Permanent Identity

Think of it as a **permanent employee** in your AWS account.

**Characteristics:**
- 🔑 Has **permanent credentials** (Access Key + Secret Key)
- 👤 Represents a **specific person or application**
- 🔒 Credentials **don't expire** automatically (unless you set policy)
- 📦 Credentials are **portable** (can be used anywhere)
- 🎫 You **create and manage** the credentials

**Example:**
```
IAM User: gitlab-ecr-push
  ├── Access Key ID: AKIAIOSFODNN7EXAMPLE (⚠️ DO NOT use - AWS doc example)
  ├── Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY (⚠️ DO NOT use - AWS doc example)
  └── Permissions: ECR push/pull
```

**Use Cases:**
- ✅ GitLab CI/CD (needs permanent credentials)
- ✅ Applications running outside AWS
- ✅ Third-party services
- ✅ Long-term automation

---

### **IAM Role** - A Temporary Hat

Think of it as a **temporary badge** that can be assumed.

**Characteristics:**
- 🎭 **No permanent credentials** (no access keys)
- ⏰ Provides **temporary credentials** (expire after 1-12 hours)
- 🔄 Must be **assumed** by a trusted entity
- 🎯 More secure (credentials auto-rotate)
- 🔐 Based on **trust relationships**

**Example:**
```
IAM Role: gitlab-ecr-role
  ├── Trust Policy: Who can assume this role?
  │   └── GitLab OIDC provider
  ├── Permissions: ECR push/pull
  └── Temporary Credentials: (generated when assumed)
      ├── Access Key: ASIAWUJ... (expires in 1 hour)
      ├── Secret Key: ...
      └── Session Token: ...
```

**Use Cases:**
- ✅ EC2 instances (attach role to instance)
- ✅ Lambda functions
- ✅ Cross-account access
- ✅ GitLab OIDC (advanced)
- ✅ Your current SSO setup (you're assuming a role)

---

## Visual Comparison

### **IAM User Flow**

```
┌─────────────────────────────────────────────────────────┐
│              IAM User: gitlab-ecr-push                  │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Permanent Credentials (never expire)              │  │
│  │  - Access Key: AKIA...                            │  │
│  │  - Secret Key: wJal...                            │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                        │
                        │ Store in GitLab CI/CD Variables
                        ▼
              ┌──────────────────┐
              │  GitLab CI/CD    │
              │  Pipeline        │
              │                  │
              │  Uses same       │
              │  credentials     │
              │  every time      │
              └──────────────────┘
                        │
                        │ Push/Pull Images
                        ▼
              ┌──────────────────┐
              │   AWS ECR        │
              │   ap-northeast-1 │
              └──────────────────┘
```

**Pros:**
- ✅ Simple setup (5 minutes)
- ✅ Works everywhere (no AWS-specific infrastructure needed)
- ✅ Predictable (same credentials always work)

**Cons:**
- ⚠️ Credentials don't expire (security risk if leaked)
- ⚠️ Need manual rotation (every 90-180 days recommended)
- ⚠️ If leaked, valid until rotated

---

### **IAM Role Flow**

```
┌─────────────────────────────────────────────────────────┐
│           IAM Role: gitlab-ecr-role                     │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Trust Policy: Trust GitLab OIDC                   │  │
│  │  - GitLab instance: gitlab.example.com            │  │
│  │  - Project: org/team/cdk/aws-network-cdk          │  │
│  └───────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Permissions: ECR push/pull                        │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                        │
                        │ 1. GitLab generates OIDC token
                        ▼
              ┌──────────────────┐
              │  GitLab CI/CD    │
              │  Pipeline        │
              │                  │
              │  OIDC Token:     │
              │  "I am gitlab    │
              │  project X"      │
              └──────────────────┘
                        │
                        │ 2. Assume role with OIDC token
                        ▼
              ┌──────────────────┐
              │   AWS STS        │
              │   (Security      │
              │   Token Service) │
              └──────────────────┘
                        │
                        │ 3. Returns temporary credentials
                        │    (expire in 1 hour)
                        ▼
              ┌──────────────────┐
              │  Temporary Creds │
              │  - Access Key    │
              │  - Secret Key    │
              │  - Session Token │
              │  - Expiry: 1h    │
              └──────────────────┘
                        │
                        │ 4. Use temporary credentials
                        ▼
              ┌──────────────────┐
              │   AWS ECR        │
              │   ap-northeast-1 │
              └──────────────────┘
```

**Pros:**
- ✅ Most secure (credentials auto-expire)
- ✅ No credential rotation needed
- ✅ If leaked, only valid for 1 hour
- ✅ Fine-grained trust (only specific GitLab project)

**Cons:**
- ⚠️ Complex setup (30-60 minutes)
- ⚠️ Requires GitLab OIDC configuration
- ⚠️ Harder to troubleshoot

---

## Side-by-Side Comparison Table

| Feature | **IAM User** | **IAM Role** |
|---------|-------------|-------------|
| **Credentials Type** | Permanent (Access Key + Secret) | Temporary (STS tokens) |
| **Credential Lifetime** | Forever (until rotated) | 1-12 hours (auto-expire) |
| **Setup Time** | 5 minutes | 30-60 minutes |
| **Complexity** | ⭐ Simple | ⭐⭐⭐ Complex |
| **Security** | ⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ Excellent |
| **Rotation Needed** | ✅ Yes (manual, every 90-180 days) | ❌ No (auto-rotation) |
| **If Leaked** | ⚠️ Valid until rotated | ✅ Valid max 12 hours |
| **GitLab Config** | Simple (add keys to variables) | Complex (OIDC setup) |
| **AWS Config** | Create user, generate keys | Create role, OIDC provider, trust policy |
| **Troubleshooting** | ✅ Easy | ⚠️ More complex |
| **Best For** | Quick setup, simpler projects | High security, advanced teams |

---

## Which to Use for GitLab CI/CD?

### **Use IAM User If:**

✅ You want **simple, quick setup** (5 minutes)
✅ You're okay with **manual credential rotation** (every 6 months)
✅ Your team is **less familiar with AWS**
✅ You want **predictable, stable credentials**
✅ Your GitLab is **self-hosted** (not GitLab.com)

**Recommendation:** ⭐ **Good choice for most projects**

---

### **Use IAM Role (OIDC) If:**

✅ You need **maximum security** (temporary credentials)
✅ You have **time for complex setup** (30-60 min)
✅ Your team is **AWS-experienced**
✅ You want **zero credential management**
✅ Your organization has **strict security policies**

**Recommendation:** ⭐⭐ **Best security, but more complex**

---

## How to Check Existing IAM Resources

### **Check for Existing IAM Users**

```bash
# List all IAM users in your account
aws iam list-users

# Expected output:
{
    "Users": [
        {
            "UserName": "gitlab-ci",
            "UserId": "AIDAI...",
            "Arn": "arn:aws:iam::455931011959:user/gitlab-ci",
            "CreateDate": "2024-01-15T10:30:00Z"
        }
    ]
}

# If empty: []  (no IAM users exist)
```

**Look for users that might be for GitLab/CI/CD:**
- Names like: `gitlab-ci`, `cicd-user`, `ecr-push`, `automation-user`

---

### **Check for Existing IAM Roles**

```bash
# List all IAM roles in your account
aws iam list-roles --query 'Roles[?!contains(RoleName, `AWS`)]' --output table

# This filters out AWS-managed roles and shows only your custom roles

# Look for roles like:
# - gitlab-ecr-role
# - GitLabOIDCRole
# - ECRPushRole
```

---

### **Check if a Specific User/Role Has ECR Permissions**

#### Check IAM User Permissions

```bash
# List policies attached to a user
aws iam list-attached-user-policies --user-name gitlab-ci

# List inline policies
aws iam list-user-policies --user-name gitlab-ci

# Get policy details
aws iam get-user-policy --user-name gitlab-ci --policy-name <policy-name>
```

#### Check IAM Role Permissions

```bash
# List policies attached to a role
aws iam list-attached-role-policies --role-name gitlab-ecr-role

# Get role trust policy (who can assume it)
aws iam get-role --role-name gitlab-ecr-role --query 'Role.AssumeRolePolicyDocument'
```

---

### **Complete Check Script**

Save this as `check-iam-for-gitlab.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "=== Checking IAM Resources for GitLab CI/CD ==="
echo ""

# Check IAM Users
echo "1. IAM Users (potential GitLab users):"
echo "─────────────────────────────────────────"
aws iam list-users --query 'Users[*].[UserName,CreateDate]' --output table | grep -E "gitlab|cicd|ecr|automation" || echo "No obvious GitLab/CI users found"
echo ""

# Check IAM Roles
echo "2. IAM Roles (potential GitLab roles):"
echo "─────────────────────────────────────────"
aws iam list-roles --query 'Roles[?!contains(RoleName, `AWS`)].RoleName' --output table | grep -E "gitlab|cicd|ecr|oidc" || echo "No obvious GitLab/CI roles found"
echo ""

# Check for OIDC providers
echo "3. OIDC Identity Providers:"
echo "─────────────────────────────────────────"
aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[*].Arn' --output table || echo "No OIDC providers configured"
echo ""

echo "=== Recommendations ==="
echo ""
echo "Based on the results above:"
echo "- If you found a user/role with 'gitlab' or 'ecr' in the name:"
echo "  → Check its permissions to see if it's suitable"
echo "  → Verify it has ECR push/pull permissions"
echo ""
echo "- If nothing found:"
echo "  → You'll need to create new IAM user or role"
echo "  → IAM User = simpler (5 min setup)"
echo "  → IAM Role + OIDC = more secure (30-60 min setup)"
```

**Run it:**
```bash
chmod +x check-iam-for-gitlab.sh
./check-iam-for-gitlab.sh
```

---

## Decision Guide

### **Start Here:**

```
Do you have existing IAM user/role for GitLab?
├─ YES → Check permissions (run script above)
│  ├─ Has ECR permissions? → Use it! (configure GitLab)
│  └─ No ECR permissions? → Add ECR policy
│
└─ NO → Need to create one
   ├─ Want simple setup? → Create IAM User (Option A)
   └─ Want best security? → Create IAM Role + OIDC (Option B)
```

---

## Detailed Permission Requirements

### **What Permissions GitLab Needs for ECR**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRAuthToken",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECRPushPull",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "arn:aws:ecr:ap-northeast-1:455931011959:repository/aws-network-cdk"
    }
  ]
}
```

**Actions Breakdown:**
- `GetAuthorizationToken` - Login to ECR
- `BatchCheckLayerAvailability` - Check if layers exist
- `GetDownloadUrlForLayer` - Pull images
- `BatchGetImage` - Pull images
- `PutImage` - Push images
- `InitiateLayerUpload` - Push images
- `UploadLayerPart` - Push images
- `CompleteLayerUpload` - Push images

---

## Example: Checking an Existing IAM User

```bash
# Found user named "gitlab-ci"
# Check if it has ECR permissions

# 1. List attached policies
aws iam list-attached-user-policies --user-name gitlab-ci

# Output might show:
{
    "AttachedPolicies": [
        {
            "PolicyName": "AmazonEC2ContainerRegistryPowerUser",
            "PolicyArn": "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
        }
    ]
}

# 2. Check if user has access keys
aws iam list-access-keys --user-name gitlab-ci

# Output:
{
    "AccessKeyMetadata": [
        {
            "UserName": "gitlab-ci",
            "AccessKeyId": "AKIAI...",
            "Status": "Active",
            "CreateDate": "2024-01-15T10:30:00Z"
        }
    ]
}

# If this user exists and has ECR permissions:
# ✅ You can use it! Just get/rotate the access keys
# ✅ Add keys to GitLab CI/CD variables
# ✅ No need to create new user
```

---

## Summary Table

### **IAM User vs Role for GitLab CI/CD**

| Criteria | **IAM User (Recommended for You)** | **IAM Role (Advanced)** |
|----------|-------------------------------------|------------------------|
| **Setup Time** | ⭐⭐⭐⭐⭐ 5 minutes | ⭐⭐ 30-60 minutes |
| **Security** | ⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ Excellent |
| **Complexity** | ⭐⭐⭐⭐⭐ Simple | ⭐⭐ Complex |
| **Maintenance** | ⭐⭐⭐ Rotate every 6mo | ⭐⭐⭐⭐⭐ None |
| **If Leaked** | ⚠️ Valid until rotated | ✅ Expires in 1 hour |
| **Best For** | Quick setup, most teams | High security, advanced |

---

## Next Steps

### **If You Want to Check Your Account NOW:**

Run these commands:

```bash
# 1. Check for IAM users
aws iam list-users --query 'Users[*].UserName' --output table

# 2. Check for IAM roles
aws iam list-roles --query 'Roles[?!contains(RoleName, `AWS`)].RoleName' --output table

# 3. Check for OIDC providers
aws iam list-open-id-connect-providers
```

**Share the output (just the names, not ARNs/details) and I can tell you if any are suitable for GitLab CI/CD.**

---

**Document Owner:** SRE Team
**Last Updated:** 2025-10-22
