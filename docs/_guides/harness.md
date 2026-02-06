---
layout: guide
title: "Harness Hardening Guide"
vendor: "Harness"
slug: "harness"
tier: "2"
category: "DevOps & Engineering"
description: "Software delivery platform hardening for Harness including SAML SSO, RBAC, secret management, and pipeline security"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Harness is a leading software delivery platform providing CI/CD, feature flags, cloud cost management, and service reliability. As a platform managing deployments and infrastructure access, Harness security configurations directly impact software supply chain security.

### Intended Audience
- Security engineers managing DevOps platforms
- Platform engineers configuring Harness
- DevOps teams managing pipelines
- GRC professionals assessing CI/CD security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Harness security including SAML SSO, RBAC, secret management, and pipeline governance.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Secret Management](#3-secret-management)
4. [Pipeline Security](#4-pipeline-security)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Harness users.

#### Prerequisites
- [ ] Harness admin access
- [ ] SAML 2.0 compatible IdP
- [ ] Enterprise tier (for some features)

#### ClickOps Implementation

**Step 1: Access Authentication Settings**
1. Navigate to: **Account Settings** → **Authentication**
2. Select **SAML Provider**

**Step 2: Configure SAML**
1. Click **Add SAML Provider**
2. Configure IdP settings:
   - Entity ID
   - SSO URL
   - Certificate
3. Configure group mappings

**Step 3: Test and Enable**
1. Test SSO authentication
2. Configure SSO enforcement
3. Document admin fallback

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Harness users.

#### ClickOps Implementation

**Step 1: Enable 2FA Requirement**
1. Navigate to: **Account Settings** → **Authentication**
2. Enable **Two-Factor Authentication**
3. Configure enforcement policy

**Step 2: Configure via IdP**
1. Enable MFA in identity provider
2. Use phishing-resistant methods for admins
3. All SSO users subject to IdP MFA

---

### 1.3 Configure IP Allowlisting

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Restrict access to approved IP ranges.

#### ClickOps Implementation

**Step 1: Configure IP Allowlist**
1. Navigate to: **Account Settings** → **Security**
2. Enable IP allowlisting
3. Add approved IP ranges

---

## 2. Access Controls

### 2.1 Configure Role-Based Access Control

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Harness RBAC.

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Account Settings** → **Access Control** → **Roles**
2. Review predefined roles:
   - Account Admin
   - Organization Admin
   - Project Admin
   - Pipeline Executor
3. Create custom roles

**Step 2: Configure Resource Groups**
1. Define resource groups
2. Scope access to specific resources
3. Apply least privilege

**Step 3: Assign Permissions**
1. Assign roles to users/groups
2. Use resource groups for scoping
3. Regular access reviews

---

### 2.2 Configure Organization/Project Hierarchy

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Use hierarchy for access isolation.

#### ClickOps Implementation

**Step 1: Define Organization Structure**
1. Create organizations for business units
2. Create projects within organizations
3. Separate production and development

**Step 2: Configure Scoped Access**
1. Assign users at appropriate level
2. Use project-level access for least privilege
3. Audit cross-project access

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review account admins
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit account admin to 2-3 users
2. Require 2FA/SSO for admins
3. Monitor admin activity

---

## 3. Secret Management

### 3.1 Configure Secret Manager

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Securely manage secrets for pipelines.

#### ClickOps Implementation

**Step 1: Configure Secret Manager**
1. Navigate to: **Account Settings** → **Connectors** → **Secrets Managers**
2. Configure preferred secret manager:
   - Harness Built-in
   - HashiCorp Vault
   - AWS Secrets Manager
   - Azure Key Vault
   - GCP Secret Manager

**Step 2: Migrate Secrets**
1. Migrate existing secrets
2. Reference secrets in pipelines
3. Never hardcode credentials

---

### 3.2 Configure Secret Access

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Control access to secrets.

#### ClickOps Implementation

**Step 1: Scope Secrets**
1. Create secrets at appropriate level
2. Use project-scoped secrets
3. Limit organization/account secrets

**Step 2: Configure Permissions**
1. Restrict secret creation
2. Limit secret viewing
3. Audit secret access

---

## 4. Pipeline Security

### 4.1 Configure Pipeline Governance

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.1 |
| NIST 800-53 | SA-15 |

#### Description
Implement pipeline governance controls.

#### ClickOps Implementation

**Step 1: Configure OPA Policies**
1. Navigate to: **Account Settings** → **Governance**
2. Create OPA policies
3. Enforce pipeline standards

**Step 2: Configure Approval Gates**
1. Add manual approval stages
2. Configure approval groups
3. Require approvals for production

---

### 4.2 Configure Audit Trail

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs.

#### ClickOps Implementation

**Step 1: Access Audit Trail**
1. Navigate to: **Account Settings** → **Audit Trail**
2. Review logged events
3. Configure retention

**Step 2: Monitor Events**
1. Pipeline executions
2. Configuration changes
3. Permission modifications
4. Secret access

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Harness Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [2.1](#21-configure-role-based-access-control) |
| CC6.7 | Secret management | [3.1](#31-configure-secret-manager) |
| CC7.2 | Audit trail | [4.2](#42-configure-audit-trail) |

### NIST 800-53 Rev 5 Mapping

| Control | Harness Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-enforce-two-factor-authentication) |
| AC-6 | RBAC | [2.1](#21-configure-role-based-access-control) |
| SC-12 | Secret management | [3.1](#31-configure-secret-manager) |
| AU-2 | Audit trail | [4.2](#42-configure-audit-trail) |

---

## Appendix A: References

**Official Harness Documentation:**
- [Harness Security](https://www.harness.io/security)
- [SAML SSO Configuration](https://developer.harness.io/docs/platform/authentication/single-sign-on-saml/)
- [RBAC Documentation](https://developer.harness.io/docs/platform/role-based-access-control/)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, RBAC, and secret management | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
