---
layout: guide
title: "Terraform Cloud Hardening Guide"
vendor: "Terraform Cloud"
slug: "terraform-cloud"
tier: "3"
category: "IaC"
description: "IaC platform security for workspace variables, team access, and run triggers"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

Terraform Cloud state files containing plaintext secrets, cloud provider credentials, and workspace configurations make IaC platforms high-value targets. Vault-backed dynamic credentials via OIDC federation represent best practice for eliminating stored secrets. State file exposure reveals database passwords and API keys; malicious provider backdoors infrastructure.

### Intended Audience
- Security engineers managing IaC platforms
- Platform engineers configuring Terraform
- GRC professionals assessing infrastructure compliance
- DevOps teams implementing secure IaC


### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries


### Scope
This guide covers Terraform Cloud security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Workspace Security](#2-workspace-security)
3. [State File Security](#3-state-file-security)
4. [Secrets Management](#4-secrets-management)
5. [Monitoring & Detection](#5-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SSO (Business)**
1. Navigate to: **Organization → Settings → SSO**
2. Configure SAML with your IdP
3. Enforce SSO for all users

**Step 2: Configure Team Tokens**
1. Create team tokens with minimum permissions
2. Set expiration
3. Rotate quarterly

---

### 1.2 Team-Based Access Control

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Teams**

| Team | Permissions |
|------|-------------|
| owners | Full organization access |
| platform | Manage workspaces |
| developers | Plan only (no apply) |
| read-only | View only |

**Step 2: Assign Workspace Permissions**
1. Navigate to: **Workspace → Team Access**
2. Grant minimum permissions per team

---


{% include pack-code.html vendor="terraform-cloud" section="1.2" %}

## 2. Workspace Security

### 2.1 Configure Workspace Restrictions

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-3

#### ClickOps Implementation

**Step 1: Execution Mode**
1. Navigate to: **Workspace → Settings → General**
2. Configure: **Execution Mode:** Remote
3. Enable: **Auto-apply:** Disabled for production

**Step 2: VCS Integration Security**
1. Configure branch protection
2. Require PR review before apply
3. Enable speculative plans

---


{% include pack-code.html vendor="terraform-cloud" section="2.1" %}

### 2.2 Sentinel Policy Enforcement

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-7

#### Implementation

```hcl
# Sentinel policy - Require encryption
policy "require-s3-encryption" {
  enforcement_level = "hard-mandatory"
}

# policy.sentinel
import "tfplan/v2" as tfplan

s3_buckets = filter tfplan.resource_changes as _, rc {
  rc.type is "aws_s3_bucket" and
  (rc.change.actions contains "create" or rc.change.actions contains "update")
}

encryption_enabled = rule {
  all s3_buckets as _, bucket {
    bucket.change.after.server_side_encryption_configuration is not null
  }
}

main = rule {
  encryption_enabled
}
```

---


{% include pack-code.html vendor="terraform-cloud" section="2.2" %}

## 3. State File Security

### 3.1 State File Protection

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### Rationale
**Why This Matters:**
- State files contain plaintext secrets
- Database passwords, API keys exposed
- State file = infrastructure blueprint

**Attack Scenario:** State file exposure reveals database passwords and API keys; malicious provider backdoors infrastructure.

#### ClickOps Implementation

**Step 1: Enable State Encryption**
- Terraform Cloud encrypts state at rest by default
- Verify encryption settings

**Step 2: Restrict State Access**
1. Navigate to: **Workspace → Settings → General**
2. Configure: **Terraform State:** API access restricted
3. Limit who can view/download state

---

### 3.2 Sensitive Variable Handling

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### Implementation

```hcl
# Mark variables as sensitive
variable "db_password" {
  type      = string
  sensitive = true
}

# Output marking
output "connection_string" {
  value     = local.connection_string
  sensitive = true
}
```

---

## 4. Secrets Management

### 4.1 Dynamic Credentials (OIDC)

**Profile Level:** L2 (Hardened)
**NIST 800-53:** IA-5

#### Description
Use OIDC workload identity instead of static credentials.

#### AWS Configuration

```hcl
# Configure OIDC provider in AWS
resource "aws_iam_openid_connect_provider" "tfc" {
  url             = "https://app.terraform.io"
  client_id_list  = ["aws.workload.identity"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
}

# Trust policy for TFC
data "aws_iam_policy_document" "tfc_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.tfc.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "app.terraform.io:aud"
      values   = ["aws.workload.identity"]
    }
    condition {
      test     = "StringLike"
      variable = "app.terraform.io:sub"
      values   = ["organization:myorg:project:*:workspace:*:run_phase:*"]
    }
  }
}
```

#### Terraform Cloud Workspace

```hcl
# workspace variables
TFC_AWS_PROVIDER_AUTH = true
TFC_AWS_RUN_ROLE_ARN  = arn:aws:iam::123456789:role/tfc-role
```

---

### 4.2 Vault Integration

**Profile Level:** L2 (Hardened)

#### Implementation

```hcl
# Use Vault provider for secrets
provider "vault" {
  address = "https://vault.company.com"
}

data "vault_generic_secret" "db" {
  path = "secret/production/database"
}

resource "aws_db_instance" "main" {
  password = data.vault_generic_secret.db.data["password"]
}
```

---

## 5. Monitoring & Detection

### 5.1 Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Detection Focus

```sql
-- Detect state access
SELECT user, workspace, action
FROM tfc_audit_log
WHERE action = 'state_version.read'
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect variable changes
SELECT user, workspace, variable_name
FROM tfc_audit_log
WHERE action LIKE '%variable%'
  AND timestamp > NOW() - INTERVAL '7 days';
```

---


{% include pack-code.html vendor="terraform-cloud" section="5.1" %}

## Appendix A: Edition Compatibility

| Control | Free | Team | Business | Enterprise |
|---------|------|------|----------|------------|
| SSO | ❌ | ❌ | ✅ | ✅ |
| Sentinel | ❌ | ❌ | ✅ | ✅ |
| Audit Logs | ❌ | ❌ | ✅ | ✅ |
| OIDC | ✅ | ✅ | ✅ | ✅ |

---

## Appendix B: References

**Official HashiCorp Documentation:**
- [Security at HashiCorp](https://www.hashicorp.com/en/trust/security)
- [Terraform Cloud Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [Recommended Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)

**API & Developer Tools:**
- [Terraform Cloud API Documentation](https://developer.hashicorp.com/terraform/cloud-docs/api-docs)
- [Terraform CLI](https://developer.hashicorp.com/terraform/cli)
- [Terraform Registry](https://registry.terraform.io/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018 -- via [HashiCorp Compliance Overview](https://www.hashicorp.com/en/trust/compliance)
- Audit reports available to customers/prospects under NDA (contact customertrust@hashicorp.com)

**Security Incidents:**
- (2021) HashiCorp's GPG private key used for signing product download hashes was exposed in the Codecov supply-chain attack (January-April 2021). The key was revoked and replaced.
- (2025) Terraform Enterprise access control vulnerability (HCSEC-2025-34) allowed users with insufficient permissions to create state versions. Fixed in versions 1.1.1 and 1.0.3. No data breach reported.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Terraform Cloud hardening guide | Claude Code (Opus 4.5) |
