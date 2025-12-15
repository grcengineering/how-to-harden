---
layout: guide
title: "HashiCorp Vault Hardening Guide"
vendor: "HashiCorp Vault"
slug: "hashicorp-vault"
tier: "1"
category: "Secrets"
description: "Secrets management security including auth methods, policies, and audit logging"
last_updated: "2025-12-14"
---


## Overview

HashiCorp Vault is the industry-standard secrets management solution used enterprise-wide for database credentials, API keys, PKI certificates, and dynamic secrets. The **Codecov breach (2021)** exposed HashiCorp's GPG signing key through supply chain attack, forcing rotation of all signing keys and validation of all software releases. CI/CD integrations with CircleCI, GitLab, and Jenkins create numerous OAuth and token-based access points.

### Intended Audience
- Security engineers managing secrets infrastructure
- DevOps engineers configuring Vault integrations
- GRC professionals assessing secrets management compliance
- Platform teams implementing zero-trust architectures

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Vault-specific security configurations including authentication methods, secrets engine hardening, audit logging, and CI/CD integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Secrets Engine Security](#2-secrets-engine-security)
3. [Network & API Security](#3-network--api-security)
4. [Audit Logging](#4-audit-logging)
5. [CI/CD Integration Security](#5-cicd-integration-security)
6. [Operational Security](#6-operational-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Implement Least-Privilege Auth Methods

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.3, 6.8
**NIST 800-53:** AC-6, IA-2

#### Description
Configure Vault authentication methods appropriate to each use case. Avoid using root tokens for regular operations; implement workload identity where possible.

#### Rationale
**Why This Matters:**
- Root tokens provide unlimited access
- Long-lived tokens create persistent risk
- Workload identity eliminates stored secrets

**Attack Prevented:** Token theft, credential stuffing, privilege escalation

**Real-World Incidents:**
- **Codecov Breach (2021):** Compromised CI environment extracted secrets, including HashiCorp's GPG signing key

#### Prerequisites
- [ ] Vault cluster deployed and initialized
- [ ] Authentication backends configured
- [ ] Policy structure designed
- [ ] Identity provider integration (for OIDC)

#### ClickOps Implementation

**Step 1: Disable Root Token After Initial Setup**
```bash
# After initial configuration, revoke root token
vault token revoke <root-token>

# Create admin policy for emergency use
vault policy write admin-emergency - <<EOF
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF

# Create emergency token with TTL
vault token create -policy=admin-emergency -ttl=1h -use-limit=5
```

**Step 2: Configure OIDC for User Authentication**
```bash
# Enable OIDC auth method
vault auth enable oidc

# Configure OIDC with your IdP
vault write auth/oidc/config \
    oidc_discovery_url="https://your-idp.okta.com" \
    oidc_client_id="$CLIENT_ID" \
    oidc_client_secret="$CLIENT_SECRET" \
    default_role="default"

# Create role mapping
vault write auth/oidc/role/default \
    bound_audiences="$CLIENT_ID" \
    allowed_redirect_uris="https://vault.company.com/ui/vault/auth/oidc/oidc/callback" \
    allowed_redirect_uris="http://localhost:8250/oidc/callback" \
    user_claim="email" \
    groups_claim="groups" \
    policies="default"
```

**Step 3: Configure AppRole for Applications**
```bash
# Enable AppRole
vault auth enable approle

# Create role with limited TTL
vault write auth/approle/role/jenkins \
    token_policies="jenkins-secrets" \
    token_ttl=1h \
    token_max_ttl=4h \
    secret_id_ttl=24h \
    secret_id_num_uses=10

# Bind to specific CIDR (L2)
vault write auth/approle/role/jenkins \
    token_bound_cidrs="10.0.0.0/8" \
    secret_id_bound_cidrs="10.0.0.0/8"
```

#### Code Implementation

**Terraform Configuration:**
```hcl
# terraform/vault/auth-methods.tf

# OIDC for human users
resource "vault_jwt_auth_backend" "oidc" {
  path               = "oidc"
  type               = "oidc"
  oidc_discovery_url = var.oidc_discovery_url
  oidc_client_id     = var.oidc_client_id
  oidc_client_secret = var.oidc_client_secret
  default_role       = "default"

  tune {
    default_lease_ttl = "1h"
    max_lease_ttl     = "8h"
  }
}

# AppRole for applications
resource "vault_auth_backend" "approle" {
  type = "approle"

  tune {
    default_lease_ttl = "1h"
    max_lease_ttl     = "4h"
  }
}

resource "vault_approle_auth_backend_role" "jenkins" {
  backend        = vault_auth_backend.approle.path
  role_name      = "jenkins"
  token_policies = ["jenkins-secrets"]
  token_ttl      = 3600
  token_max_ttl  = 14400

  # Bind to CIDR (L2)
  token_bound_cidrs = ["10.0.0.0/8"]
  secret_id_bound_cidrs = ["10.0.0.0/8"]
}

# Kubernetes auth for cloud-native workloads
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "config" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = var.kubernetes_host
}

resource "vault_kubernetes_auth_backend_role" "app" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "app"
  bound_service_account_names      = ["app-sa"]
  bound_service_account_namespaces = ["production"]
  token_ttl                        = 3600
  token_policies                   = ["app-secrets"]
}
```

#### Validation & Testing
1. [ ] Attempt to use root token - should be revoked
2. [ ] Login via OIDC - should succeed with appropriate policies
3. [ ] AppRole authentication - verify CIDR binding works
4. [ ] Check token TTLs are enforced

**Expected result:** Each auth method provides minimal required access

#### Monitoring & Maintenance
```bash
# Monitor auth method usage
vault read sys/auth

# Check token counts by auth method
vault read sys/internal/counters/tokens
```

**Maintenance schedule:**
- **Weekly:** Review failed authentication attempts
- **Monthly:** Audit auth method configurations
- **Quarterly:** Rotate AppRole SecretIDs

#### Compliance Mappings
| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2, IA-5 | Authentication and token management |
| **ISO 27001** | A.9.2.1 | User registration and de-registration |

---

### 1.2 Implement Granular Policies

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Create fine-grained policies limiting access to specific paths. Avoid wildcard policies that grant excessive access.

#### ClickOps Implementation

```bash
# Bad: Overly permissive policy
path "secret/*" {
  capabilities = ["read", "list"]
}

# Good: Scoped policy
path "secret/data/{{identity.entity.aliases.auth_approle_XXXX.metadata.app}}/*" {
  capabilities = ["read"]
}

# Better: Application-specific policy
path "secret/data/jenkins/+/credentials" {
  capabilities = ["read"]
}

# Deny access to sensitive paths explicitly
path "secret/data/production/+/admin" {
  capabilities = ["deny"]
}
```

**Step 1: Create Hierarchical Policy Structure**
```bash
# Base policy - all authenticated users
vault policy write base - <<EOF
path "secret/data/shared/*" {
  capabilities = ["read", "list"]
}
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
path "auth/token/renew-self" {
  capabilities = ["update"]
}
EOF

# Team-specific policy
vault policy write team-platform - <<EOF
path "secret/data/platform/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "aws/creds/platform-deploy" {
  capabilities = ["read"]
}
EOF

# Application policy (most restrictive)
vault policy write app-frontend - <<EOF
path "secret/data/frontend/config" {
  capabilities = ["read"]
}
path "database/creds/frontend-readonly" {
  capabilities = ["read"]
}
EOF
```

---

### 1.3 Enable Entity and Group Management

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-2

#### Description
Use Vault's identity system to manage users and groups across auth methods, enabling consistent policy application.

```bash
# Create identity group
vault write identity/group \
    name="platform-team" \
    policies="team-platform" \
    member_entity_ids=""

# Create entity for user
vault write identity/entity \
    name="john.doe@company.com" \
    policies="base"

# Link OIDC alias to entity
vault write identity/entity-alias \
    name="john.doe@company.com" \
    canonical_id="<entity-id>" \
    mount_accessor="<oidc-accessor>"
```

---

## 2. Secrets Engine Security

### 2.1 Use Dynamic Secrets Where Possible

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(7)

#### Description
Configure dynamic secrets engines that generate credentials on-demand with automatic expiration, eliminating static credential risk.

#### Rationale
**Why This Matters:**
- Static credentials never expire without rotation
- Dynamic credentials auto-revoke after TTL
- Limits blast radius of credential theft

#### ClickOps Implementation

**Database Dynamic Secrets:**
```bash
# Enable database secrets engine
vault secrets enable database

# Configure PostgreSQL connection
vault write database/config/production \
    plugin_name=postgresql-database-plugin \
    connection_url="postgresql://{{username}}:{{password}}@db.company.com:5432/prod" \
    allowed_roles="readonly,readwrite" \
    username="vault_admin" \
    password="$ADMIN_PASSWORD"

# Create role for read-only access
vault write database/roles/readonly \
    db_name=production \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    revocation_statements="DROP ROLE IF EXISTS \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
```

**AWS Dynamic Secrets:**
```bash
# Enable AWS secrets engine
vault secrets enable aws

# Configure AWS backend
vault write aws/config/root \
    access_key=$AWS_ACCESS_KEY \
    secret_key=$AWS_SECRET_KEY \
    region=us-east-1

# Create role for S3 access
vault write aws/roles/s3-readonly \
    credential_type=iam_user \
    policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": ["arn:aws:s3:::company-data/*"]
    }
  ]
}
EOF
```

---

### 2.2 Implement Secrets Versioning and Rotation

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(1)

#### Description
Enable KV v2 secrets engine with versioning for audit trail and rollback capability.

```bash
# Enable KV v2
vault secrets enable -version=2 -path=secret kv

# Configure version retention
vault write secret/config \
    max_versions=10 \
    cas_required=true

# Write secret with CAS (check-and-set) for conflict prevention
vault kv put -cas=0 secret/myapp/config \
    api_key="secret123" \
    db_password="dbpass456"

# Read specific version
vault kv get -version=2 secret/myapp/config

# Delete version (soft delete)
vault kv delete -versions=1 secret/myapp/config

# Destroy version permanently (L3 only)
vault kv destroy -versions=1 secret/myapp/config
```

---

### 2.3 Enable Transit Engine for Encryption-as-a-Service

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-28

#### Description
Use Transit secrets engine for application-level encryption without exposing encryption keys.

```bash
# Enable transit
vault secrets enable transit

# Create encryption key
vault write -f transit/keys/payment-data \
    type=aes256-gcm96 \
    exportable=false \
    allow_plaintext_backup=false

# Encrypt data
vault write transit/encrypt/payment-data \
    plaintext=$(echo "4111111111111111" | base64)

# Decrypt data
vault write transit/decrypt/payment-data \
    ciphertext="vault:v1:..."

# Enable key rotation
vault write -f transit/keys/payment-data/rotate

# Configure minimum decryption version (after key rotation)
vault write transit/keys/payment-data/config \
    min_decryption_version=2
```

---

## 3. Network & API Security

### 3.1 Configure TLS and API Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-8

#### Description
Secure Vault API with TLS, client certificates, and rate limiting.

#### ClickOps Implementation

**vault.hcl configuration:**
```hcl
# Listener configuration
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/vault/certs/vault.crt"
  tls_key_file  = "/vault/certs/vault.key"
  tls_min_version = "tls12"
  tls_cipher_suites = "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"

  # Client certificate verification (L2)
  tls_require_and_verify_client_cert = true
  tls_client_ca_file = "/vault/certs/client-ca.crt"
}

# API address
api_addr = "https://vault.company.com:8200"
cluster_addr = "https://vault-node:8201"

# Disable insecure TLS skip verify
disable_tls_cert_verification = false
```

---

### 3.2 Implement Request Rate Limiting

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-5

#### Description
Configure rate limiting to prevent abuse and detect anomalous access patterns.

```hcl
# In vault.hcl (Enterprise only)
default_lease_ttl = "1h"
max_lease_ttl = "24h"

# Rate limiting
rate_limit {
  rate = 100.0
  burst = 200

  # Per-path limits
  path {
    glob = "auth/*"
    rate = 50.0
    burst = 100
  }

  path {
    glob = "secret/*"
    rate = 200.0
    burst = 400
  }
}
```

---

## 4. Audit Logging

### 4.1 Enable Comprehensive Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable audit logging to file and SIEM for all Vault operations.

#### ClickOps Implementation

```bash
# Enable file audit device
vault audit enable file file_path=/vault/audit/vault-audit.log

# Enable syslog audit device
vault audit enable syslog tag="vault" facility="AUTH"

# Enable socket audit device (for SIEM)
vault audit enable socket \
    address="siem.company.com:514" \
    socket_type="tcp"

# Verify audit devices
vault audit list -detailed
```

**Audit Log Format:**
```json
{
  "time": "2025-01-15T10:30:00Z",
  "type": "request",
  "auth": {
    "client_token": "hmac-sha256:xxx",
    "accessor": "hmac-sha256:xxx",
    "display_name": "approle",
    "policies": ["jenkins-secrets"],
    "token_policies": ["jenkins-secrets"],
    "metadata": {
      "role_name": "jenkins"
    }
  },
  "request": {
    "id": "req-xxx",
    "operation": "read",
    "path": "secret/data/jenkins/credentials",
    "remote_address": "10.0.1.50"
  },
  "response": {
    "succeeded": true
  }
}
```

---

### 4.2 Configure Audit Log Alerting

**Profile Level:** L1 (Baseline)

#### Detection Use Cases

```python
#!/usr/bin/env python3
# vault-audit-monitor.py - Monitor for suspicious patterns

import json
from collections import defaultdict
from datetime import datetime, timedelta

def detect_mass_secret_access(logs, threshold=100, window_minutes=5):
    """Detect unusual volume of secret reads"""
    access_counts = defaultdict(int)
    window_start = datetime.utcnow() - timedelta(minutes=window_minutes)

    for log in logs:
        if log.get('request', {}).get('path', '').startswith('secret/'):
            if log['request']['operation'] == 'read':
                accessor = log.get('auth', {}).get('accessor', 'unknown')
                access_counts[accessor] += 1

    alerts = []
    for accessor, count in access_counts.items():
        if count > threshold:
            alerts.append(f"High secret access: {accessor} read {count} secrets")

    return alerts

def detect_auth_failures(logs, threshold=10, window_minutes=5):
    """Detect brute force attempts"""
    failures = defaultdict(int)

    for log in logs:
        if log.get('type') == 'response':
            if not log.get('response', {}).get('succeeded', True):
                remote_addr = log.get('request', {}).get('remote_address', 'unknown')
                failures[remote_addr] += 1

    return [f"Auth failures from {ip}: {count}"
            for ip, count in failures.items() if count > threshold]
```

---

## 5. CI/CD Integration Security

### 5.1 Secure Jenkins Integration

**Profile Level:** L1 (Baseline)

#### Description
Configure secure Vault integration for Jenkins with minimal privileges and short-lived tokens.

#### Rationale
**Why This Matters:**
- CI/CD systems are prime targets for supply chain attacks
- CircleCI breach (2023) exposed customer secrets
- Jenkins compromise = access to all pipelines' secrets

#### ClickOps Implementation

**Step 1: Create Jenkins-Specific Policy**
```bash
vault policy write jenkins-secrets - <<EOF
# Read secrets for Jenkins builds
path "secret/data/jenkins/*" {
  capabilities = ["read"]
}

# Generate AWS credentials for deployments
path "aws/creds/jenkins-deploy" {
  capabilities = ["read"]
}

# No access to production secrets
path "secret/data/production/*" {
  capabilities = ["deny"]
}
EOF
```

**Step 2: Configure AppRole with Restrictions**
```bash
vault write auth/approle/role/jenkins \
    token_policies="jenkins-secrets" \
    token_ttl=15m \
    token_max_ttl=30m \
    secret_id_ttl=1h \
    secret_id_num_uses=1 \
    token_bound_cidrs="10.0.0.0/8"
```

**Step 3: Jenkins Configuration**
```groovy
// Jenkinsfile
pipeline {
    agent any

    environment {
        VAULT_ADDR = 'https://vault.company.com'
    }

    stages {
        stage('Get Secrets') {
            steps {
                withVault(configuration: [
                    vaultUrl: "${VAULT_ADDR}",
                    vaultCredentialId: 'vault-approle'
                ], vaultSecrets: [
                    [path: 'secret/data/jenkins/api-keys',
                     secretValues: [[envVar: 'API_KEY', vaultKey: 'data.api_key']]]
                ]) {
                    sh 'echo "Using secret safely"'
                }
            }
        }
    }
}
```

---

### 5.2 Implement OIDC for GitHub Actions

**Profile Level:** L2 (Hardened)

#### Description
Use GitHub Actions OIDC to authenticate to Vault without storing long-lived tokens.

```bash
# Configure JWT auth for GitHub Actions
vault auth enable -path=github-actions jwt

vault write auth/github-actions/config \
    oidc_discovery_url="https://token.actions.githubusercontent.com" \
    bound_issuer="https://token.actions.githubusercontent.com"

vault write auth/github-actions/role/deploy \
    role_type="jwt" \
    bound_audiences="https://github.com/your-org" \
    bound_subject="repo:your-org/your-repo:ref:refs/heads/main" \
    user_claim="sub" \
    policies="deploy-secrets" \
    ttl=5m
```

**GitHub Actions Workflow:**
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read

    steps:
      - uses: hashicorp/vault-action@v2
        with:
          url: https://vault.company.com
          method: jwt
          role: deploy
          jwtGithubAudience: https://github.com/your-org
          secrets: |
            secret/data/deploy/credentials api_key | API_KEY ;
```

---

## 6. Operational Security

### 6.1 Configure Auto-Unseal

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-12

#### Description
Configure auto-unseal using cloud KMS to eliminate manual unseal key management.

```hcl
# AWS KMS auto-unseal
seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "alias/vault-unseal-key"
}

# Azure Key Vault auto-unseal
seal "azurekeyvault" {
  tenant_id      = "your-tenant-id"
  client_id      = "your-client-id"
  client_secret  = "your-client-secret"
  vault_name     = "vault-unseal"
  key_name       = "vault-key"
}

# GCP Cloud KMS auto-unseal
seal "gcpckms" {
  project     = "your-project"
  region      = "us-east1"
  key_ring    = "vault"
  crypto_key  = "unseal"
}
```

---

### 6.2 Implement Disaster Recovery

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CP-9, CP-10

#### Description
Configure Vault disaster recovery and backup procedures.

```bash
# Create Raft snapshot
vault operator raft snapshot save backup.snap

# Verify snapshot
vault operator raft snapshot inspect backup.snap

# Restore from snapshot (DR scenario)
vault operator raft snapshot restore backup.snap

# For Enterprise: Configure DR replication
vault write -f sys/replication/dr/primary/enable
```

---

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Vault Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | Auth methods and policies | 1.1 |
| CC6.2 | Granular policies | 1.2 |
| CC7.2 | Audit logging | 4.1 |

### NIST 800-53 Mapping

| Control | Vault Control | Guide Section |
|---------|------------------|---------------|
| AC-6 | Least privilege policies | 1.2 |
| IA-5 | Token and auth management | 1.1 |
| AU-2 | Audit logging | 4.1 |
| SC-28 | Transit encryption | 2.3 |

---

## Appendix A: Edition Compatibility

| Control | Community | Enterprise | HCP Vault |
|---------|-----------|------------|-----------|
| Auth Methods | ✅ | ✅ | ✅ |
| Audit Logging | ✅ | ✅ | ✅ |
| Dynamic Secrets | ✅ | ✅ | ✅ |
| Namespaces | ❌ | ✅ | ✅ |
| Sentinel Policies | ❌ | ✅ | ✅ |
| DR Replication | ❌ | ✅ | ✅ |
| Performance Replication | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official HashiCorp Documentation:**
- [Security Best Practices](https://developer.hashicorp.com/vault/tutorials/operations/production-hardening)
- [Auth Methods](https://developer.hashicorp.com/vault/docs/auth)
- [Audit Devices](https://developer.hashicorp.com/vault/docs/audit)

**Supply Chain Incident:**
- Codecov breach (2021) exposed HashiCorp's GPG signing key via compromised CI environment

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial HashiCorp Vault hardening guide | How to Harden Community |
