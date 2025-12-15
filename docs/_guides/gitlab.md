---
layout: guide
title: "GitLab Hardening Guide"
vendor: "GitLab"
slug: "gitlab"
tier: "2"
category: "DevOps"
description: "DevOps platform security for CI/CD pipelines, repository access, and runners"
last_updated: "2025-12-14"
---


## Overview

GitLab is used by **50%+ of Fortune 100** with 30,000+ paying customers. Integrated CI/CD pipelines, container registry, and secrets management concentrate attack surface. Runner tokens, project API keys, and OAuth integrations with cloud providers enable code injection and infrastructure access. A compromised GitLab instance provides attackers with source code, CI/CD secrets, and deployment capabilities.

### Intended Audience
- Security engineers hardening GitLab instances
- DevOps engineers configuring CI/CD security
- GRC professionals assessing DevSecOps compliance
- Platform teams managing GitLab infrastructure

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers GitLab security configurations including authentication, CI/CD pipeline security, runner hardening, and third-party integration controls.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [CI/CD Pipeline Security](#2-cicd-pipeline-security)
3. [Runner Security](#3-runner-security)
4. [Repository Security](#4-repository-security)
5. [Secrets Management](#5-secrets-management)
6. [Monitoring & Detection](#6-monitoring--detection)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1)

#### Description
Require SAML/OIDC SSO with MFA for all GitLab authentication, eliminating password-based access.

#### Rationale
**Why This Matters:**
- GitLab credentials provide access to source code and CI/CD pipelines
- Compromised accounts can inject malicious code
- SSO enables centralized access control and MFA enforcement

**Attack Scenario:** Malicious .gitlab-ci.yml injects backdoor during build; stolen runner token enables unauthorized deployments.

#### ClickOps Implementation (GitLab.com Premium/Ultimate)

**Step 1: Configure SAML SSO**
1. Navigate to: **Group → Settings → SAML SSO**
2. Configure:
   - **Identity provider SSO URL:** Your IdP endpoint
   - **Certificate fingerprint:** From IdP
   - **Enforce SSO:** Enable
3. Click **Save changes**

**Step 2: Enforce Group-Managed Accounts**
1. Navigate to: **Group → Settings → SAML SSO**
2. Enable: **Enforce SSO-only authentication for web activity**
3. Enable: **Enforce SSO-only authentication for Git and Dependency Proxy activity**

**Step 3: Disable Password Authentication**
1. Navigate to: **Admin → Settings → General → Sign-in restrictions**
2. Disable: **Password authentication enabled for web interface**
3. Disable: **Password authentication enabled for Git over HTTP(S)**

#### Code Implementation (Self-Managed)

```ruby
# /etc/gitlab/gitlab.rb

# SAML Configuration
gitlab_rails['omniauth_enabled'] = true
gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']
gitlab_rails['omniauth_block_auto_created_users'] = false
gitlab_rails['omniauth_providers'] = [
  {
    name: 'saml',
    args: {
      assertion_consumer_service_url: 'https://gitlab.company.com/users/auth/saml/callback',
      idp_cert_fingerprint: 'XX:XX:XX...',
      idp_sso_target_url: 'https://idp.company.com/saml/sso',
      issuer: 'https://gitlab.company.com',
      name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
    }
  }
]

# Disable password authentication
gitlab_rails['gitlab_signin_enabled'] = false
```

#### Compliance Mappings
| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(1) | MFA for network access |

---

### 1.2 Implement Granular Project Permissions

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure project-level access controls using GitLab's role-based permissions.

#### ClickOps Implementation

**Step 1: Define Role Strategy**
| Role | Permissions | Use Case |
|------|-------------|----------|
| Guest | View issues, wiki | External stakeholders |
| Reporter | Clone, view CI/CD | QA, read-only developers |
| Developer | Push to non-protected branches | Development team |
| Maintainer | Merge to protected, manage CI/CD | Tech leads |
| Owner | Full control | Project owners only |

**Step 2: Configure Protected Branches**
1. Navigate to: **Project → Settings → Repository → Protected branches**
2. Protect `main` and `release/*`:
   - **Allowed to merge:** Maintainers
   - **Allowed to push:** No one (force MR workflow)
   - **Require approval from code owners:** Enable

**Step 3: Enable Required Approvals**
1. Navigate to: **Project → Settings → Merge requests**
2. Configure:
   - **Approvals required:** 2 (minimum)
   - **Prevent approval by author:** Enable
   - **Prevent editing approval rules:** Enable

---

### 1.3 Configure Personal Access Token Policies

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Restrict personal access token (PAT) creation and enforce expiration policies.

#### ClickOps Implementation

**Step 1: Set Token Expiration Limits**
1. Navigate to: **Admin → Settings → General → Account and limit**
2. Configure:
   - **Maximum allowable lifetime for access tokens:** 90 days
   - **Limit project access token creation:** Enable

**Step 2: Audit Existing Tokens**
```bash
# GitLab API - List all personal access tokens (Admin)
curl -H "PRIVATE-TOKEN: ${ADMIN_TOKEN}" \
  "https://gitlab.company.com/api/v4/personal_access_tokens?state=active" \
  | jq '.[] | {user: .user.username, name: .name, expires_at: .expires_at, scopes: .scopes}'
```

**Step 3: Disable API Scope for Non-Essential Tokens**
- Audit tokens with `api` scope
- Replace with minimal scopes (read_repository, write_repository)

---

## 2. CI/CD Pipeline Security

### 2.1 Protect CI/CD Variables

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### Description
Configure CI/CD variables with appropriate protection levels and masking.

#### ClickOps Implementation

**Step 1: Configure Variable Protection**
1. Navigate to: **Project → Settings → CI/CD → Variables**
2. For each sensitive variable:
   - **Protect variable:** Enable (only available in protected branches)
   - **Mask variable:** Enable (hidden in job logs)
   - **Expand variable reference:** Disable

**Step 2: Use Group-Level Variables**
1. Navigate to: **Group → Settings → CI/CD → Variables**
2. Define shared secrets at group level
3. Limit duplication across projects

**Step 3: Environment-Scoped Variables**
1. Create separate variables for each environment:
   - `PROD_API_KEY` (protected)
   - `STAGING_API_KEY`
2. Scope to specific environments

#### Code Implementation

```yaml
# .gitlab-ci.yml - Secure variable usage

variables:
  # Never hardcode secrets
  # Reference protected CI/CD variables

deploy_production:
  stage: deploy
  script:
    - echo "Deploying with protected credentials"
    - ./deploy.sh  # Uses $PROD_API_KEY from CI/CD settings
  environment:
    name: production
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  # Only run on protected branch with protected variables
```

---

### 2.2 Implement Pipeline Security Controls

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7, SI-7

#### Description
Restrict pipeline execution and prevent unauthorized CI/CD modifications.

#### ClickOps Implementation

**Step 1: Require Pipeline Approval for Forks**
1. Navigate to: **Project → Settings → CI/CD → General pipelines**
2. Enable: **Protect CI/CD variables in pipeline subscriptions**
3. Enable: **CI/CD job token scope:** Limit access to necessary projects

**Step 2: Configure Merge Request Pipelines**
1. Navigate to: **Project → Settings → Merge requests**
2. Enable: **Pipelines must succeed before merge**
3. Enable: **All discussions must be resolved**

**Step 3: Limit Who Can Run Pipelines**
1. Navigate to: **Project → Settings → CI/CD**
2. Configure: **Who can run pipelines on protected branches**
3. Restrict manual job triggers

---

### 2.3 Harden .gitlab-ci.yml Configuration

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-7

#### Description
Implement secure CI/CD configuration practices.

```yaml
# .gitlab-ci.yml - Security hardened example

default:
  # Use specific image tags, not :latest
  image: ruby:3.2.0-alpine@sha256:abc123...

  # Limit job timeout
  timeout: 30 minutes

  # Run in isolated environment
  tags:
    - docker
    - isolated

# Prevent secret leakage in logs
variables:
  GIT_STRATEGY: clone
  SECURE_LOG_LEVEL: "warn"

# Security scanning stages
stages:
  - test
  - security
  - build
  - deploy

sast:
  stage: security
  allow_failure: false  # Block on security issues

dependency_scanning:
  stage: security
  allow_failure: false

container_scanning:
  stage: security
  allow_failure: false

# Restrict production deployment
deploy_production:
  stage: deploy
  script:
    - ./deploy.sh
  environment:
    name: production
    url: https://prod.company.com
  rules:
    # Only from main branch
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual  # Require manual approval
  # Prevent concurrent deployments
  resource_group: production
```

---

## 3. Runner Security

### 3.1 Isolate CI/CD Runners

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-7

#### Description
Deploy isolated runners for different trust levels and environments.

#### Implementation

**Step 1: Create Runner Tiers**
```
Runner Architecture:
├── shared-runners (general use)
│   └── Docker executor, ephemeral containers
├── group-runners (team-specific)
│   └── Isolated per business unit
├── project-runners (sensitive projects)
│   └── Dedicated to single project
└── production-runners (deployment only)
    └── Network access to production, limited users
```

**Step 2: Register Isolated Runner**
```bash
# Register runner with specific tags
gitlab-runner register \
  --url "https://gitlab.company.com" \
  --registration-token "${RUNNER_TOKEN}" \
  --executor "docker" \
  --docker-image "alpine:3.18" \
  --tag-list "isolated,security-sensitive" \
  --run-untagged="false" \
  --locked="true"
```

**Step 3: Configure Runner Security**
```toml
# /etc/gitlab-runner/config.toml

[[runners]]
  name = "secure-runner"
  executor = "docker"
  [runners.docker]
    image = "alpine:3.18"
    privileged = false  # Never enable unless absolutely required
    disable_entrypoint_overwrite = true
    volumes = ["/cache"]
    # Limit network access
    network_mode = "bridge"
    # Read-only root filesystem
    read_only = true
    # Drop capabilities
    cap_drop = ["ALL"]
```

---

### 3.2 Rotate Runner Tokens

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(1)

#### Description
Implement regular runner token rotation to limit exposure from compromised tokens.

#### ClickOps Implementation

**Step 1: Reset Runner Token**
1. Navigate to: **Admin → CI/CD → Runners → [Runner]**
2. Click **Reset registration token**
3. Update runner configuration with new token

**Step 2: Automate Rotation**
```bash
#!/bin/bash
# runner-token-rotation.sh

# Reset project runner token
curl -X POST -H "PRIVATE-TOKEN: ${ADMIN_TOKEN}" \
  "https://gitlab.company.com/api/v4/projects/${PROJECT_ID}/runners/reset_registration_token"

# Re-register runner
gitlab-runner unregister --all-runners
gitlab-runner register --non-interactive \
  --url "https://gitlab.company.com" \
  --registration-token "${NEW_TOKEN}" \
  --executor "docker"
```

---

## 4. Repository Security

### 4.1 Enable Push Rules

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-3

#### Description
Configure push rules to prevent accidental secret commits and enforce commit hygiene.

#### ClickOps Implementation

**Step 1: Configure Project Push Rules**
1. Navigate to: **Project → Settings → Repository → Push rules**
2. Enable:
   - **Prevent pushing secret files:** Enable
   - **Reject unsigned commits:** Enable (L2)
   - **Check author email against verified:** Enable

**Step 2: Configure Secret Detection**
```yaml
# .gitlab-ci.yml
secret_detection:
  stage: security
  variables:
    SECRET_DETECTION_HISTORIC_SCAN: "true"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

---

### 4.2 Enable Commit Signing

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AU-10

#### Description
Require GPG or SSH signed commits to verify commit authorship.

#### ClickOps Implementation

**Step 1: Configure Signature Requirements**
1. Navigate to: **Project → Settings → Repository → Push rules**
2. Enable: **Reject unsigned commits**
3. Enable: **Reject unverified users**

**Step 2: User Setup**
1. Navigate to: **User Settings → GPG Keys**
2. Add GPG public key
3. Configure git client:
```bash
git config --global commit.gpgsign true
git config --global user.signingkey YOUR_KEY_ID
```

---

## 5. Secrets Management

### 5.1 Use External Secrets Management

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-28

#### Description
Integrate with external secrets managers instead of storing secrets in GitLab.

#### HashiCorp Vault Integration

```yaml
# .gitlab-ci.yml
deploy:
  stage: deploy
  secrets:
    DATABASE_PASSWORD:
      vault: production/db/password@secret
    API_KEY:
      vault: production/api/key@secret
  script:
    - echo "Using secrets from Vault"
    - ./deploy.sh
```

**Step 1: Configure Vault Integration**
1. Navigate to: **Project → Settings → CI/CD → Secure Files**
2. Configure JWT authentication with Vault
3. Map CI/CD variables to Vault paths

---

## 6. Monitoring & Detection

### 6.1 Enable Audit Events

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure comprehensive audit logging for GitLab operations.

#### ClickOps Implementation

**Step 1: Configure Audit Event Streaming**
1. Navigate to: **Group → Security & Compliance → Audit events**
2. Enable streaming to SIEM
3. Configure: All event types

**Step 2: Alert on Critical Events**
- Repository deletion
- Protected branch modification
- Runner registration
- Admin privilege changes

#### Detection Queries

```sql
-- Detect unusual repository cloning
SELECT user_id, project_path, COUNT(*) as clone_count
FROM audit_events
WHERE action = 'repository_clone'
  AND created_at > NOW() - INTERVAL '1 hour'
GROUP BY user_id, project_path
HAVING COUNT(*) > 20;

-- Detect pipeline variable modifications
SELECT *
FROM audit_events
WHERE entity_type = 'Ci::Variable'
  AND action IN ('create', 'update', 'destroy')
  AND created_at > NOW() - INTERVAL '24 hours';
```

---

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | GitLab Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.2 | Project permissions | 1.2 |
| CC7.2 | Audit events | 6.1 |
| CC8.1 | Protected branches | 1.2 |

### NIST 800-53 Mapping

| Control | GitLab Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | SSO with MFA | 1.1 |
| AC-6 | Role-based access | 1.2 |
| CM-3 | Push rules | 4.1 |
| SC-28 | CI/CD variable protection | 2.1 |

---

## Appendix A: Edition Compatibility

| Control | Free | Premium | Ultimate |
|---------|------|---------|----------|
| SAML SSO | ❌ | ✅ | ✅ |
| Push Rules | Basic | ✅ | ✅ |
| Audit Events | ❌ | ✅ | ✅ |
| SAST/DAST | ❌ | ❌ | ✅ |
| Compliance Dashboard | ❌ | ❌ | ✅ |

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial GitLab hardening guide | How to Harden Community |
