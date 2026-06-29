---
layout: guide
title: "Harness Hardening Guide"
vendor: "Harness"
slug: "harness"
tier: "2"
category: "DevOps"
description: "Software delivery platform hardening for Harness including SAML SSO, RBAC, secret management, and pipeline security"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

Harness is a leading software delivery platform providing CI/CD, feature flags, cloud cost management, and service reliability. As a platform managing deployments and infrastructure access, Harness security configurations directly impact software supply chain security.

### Intended Audience
- Security engineers managing DevOps platforms
- Platform engineers configuring Harness
- DevOps teams managing pipelines
- GRC professionals assessing CI/CD security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Harness users.

#### Rationale
**Why This Matters:**
- Centralizes Harness authentication in your corporate IdP, enforcing MFA, conditional access, and a consistent password policy on every login
- Harness controls deployment pipelines, infrastructure connectors, and cloud credentials, so a single compromised login can push malicious code to production
- IdP-driven provisioning deprovisions departed users automatically, eliminating orphaned accounts with standing pipeline access
- Local Harness logins bypass IdP controls and become a soft target for credential stuffing and phishing

**Attack Prevented:** Credential theft, phishing, credential stuffing, orphaned-account access

#### Prerequisites
- Harness admin access
- SAML 2.0 compatible IdP
- Enterprise tier (for some features)

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Harness users.

#### Rationale
**Why This Matters:**
- Adds a second factor so a stolen or guessed password alone cannot grant access to deployment controls
- Harness operators can trigger production deployments and reference pipeline secrets, so a single-factor compromise exposes the whole delivery chain
- Phishing-resistant MFA for admins blocks real-time credential relay and MFA-fatigue attacks
- Enforcing 2FA at the IdP covers all SSO users consistently instead of relying on per-user opt-in

**Attack Prevented:** Password reuse, credential stuffing, phishing, account takeover, MFA fatigue

#### ClickOps Implementation

**Step 1: Enable 2FA Requirement**
1. Navigate to: **Account Settings** → **Authentication**
2. Enable **Two-Factor Authentication**
3. Configure enforcement policy

**Step 2: Configure via IdP**
1. Enable MFA in identity provider
2. Use phishing-resistant methods for admins
3. All SSO users subject to IdP MFA

#### Code Implementation

{% include pack-code.html vendor="harness" section="1.2" lang="terraform" %}

---

### 1.3 Configure IP Allowlisting

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Restrict access to approved IP ranges.

#### Rationale
**Why This Matters:**
- Restricts Harness console and API access to known corporate or VPN egress ranges, shrinking the externally reachable attack surface
- Even if credentials or session tokens are stolen, an attacker outside the allowed ranges cannot reach the platform
- Confines automation and API tokens used in CI to their expected network locations
- Adds a network-layer control that complements identity controls for defense in depth

**Attack Prevented:** Stolen-credential reuse from untrusted networks, token replay, unauthorized API access

#### ClickOps Implementation

**Step 1: Configure IP Allowlist**
1. Navigate to: **Account Settings** → **Security**
2. Enable IP allowlisting
3. Add approved IP ranges

#### Code Implementation

{% include pack-code.html vendor="harness" section="1.3" lang="terraform" %}

---

## 2. Access Controls

### 2.1 Configure Role-Based Access Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Harness RBAC.

#### Rationale
**Why This Matters:**
- Least-privilege roles ensure users and service accounts can only act on the pipelines, secrets, and connectors they actually need
- Custom roles paired with resource groups prevent the over-broad standing access that turns one compromised account into account-wide control
- Scoping limits blast radius — a developer role cannot modify production governance or read every secret
- Regular access reviews catch privilege creep before it becomes an audit or breach finding

**Attack Prevented:** Privilege escalation, lateral movement, insider misuse, excessive standing access

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

#### Code Implementation

{% include pack-code.html vendor="harness" section="2.1" lang="terraform" %}

---

### 2.2 Configure Organization/Project Hierarchy

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Use hierarchy for access isolation.

#### Rationale
**Why This Matters:**
- Separating business units, and especially production from development, into distinct organizations and projects enforces tenant isolation
- Scoped project-level access prevents a developer on one team from touching another team's pipelines, connectors, or secrets
- Hierarchy creates clear boundaries for least privilege and for auditing cross-project access
- Isolation contains the blast radius of a compromised account or misconfigured role to a single scope

**Attack Prevented:** Cross-project access, lateral movement, accidental or malicious production changes

#### ClickOps Implementation

**Step 1: Define Organization Structure**
1. Create organizations for business units
2. Create projects within organizations
3. Separate production and development

**Step 2: Configure Scoped Access**
1. Assign users at appropriate level
2. Use project-level access for least privilege
3. Audit cross-project access

#### Code Implementation

{% include pack-code.html vendor="harness" section="2.2" lang="terraform" %}

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### Rationale
**Why This Matters:**
- Account admins can change authentication, governance, RBAC, and every connector, so minimizing their number reduces high-value targets
- Requiring SSO and 2FA on admin accounts hardens the most powerful credentials against phishing and reuse
- A small, documented admin set makes anomalous admin activity easy to spot and investigate
- Fewer standing admins limits the damage from a single compromised privileged account

**Attack Prevented:** Privileged-account takeover, configuration tampering, persistence, audit evasion

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review account admins
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit account admin to 2-3 users
2. Require 2FA/SSO for admins
3. Monitor admin activity

#### Code Implementation

{% include pack-code.html vendor="harness" section="2.3" lang="terraform" %}

---

## 3. Secret Management

### 3.1 Configure Secret Manager

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Securely manage secrets for pipelines.

#### Rationale
**Why This Matters:**
- Centralizing secrets in a dedicated manager (Vault, a cloud KMS, or the built-in store) keeps credentials out of pipeline YAML and source control
- Referenced secrets are injected at runtime and masked in logs, avoiding plaintext exposure to anyone who can read the pipeline
- External managers add rotation, versioning, and access auditing that hardcoded credentials lack
- Pipelines hold deploy keys and cloud credentials, so leaking one can compromise production infrastructure

**Attack Prevented:** Hardcoded-secret leakage, credential exposure in logs or VCS, supply-chain compromise via stolen deploy keys

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

#### Code Implementation

{% include pack-code.html vendor="harness" section="3.1" lang="terraform" %}

---

### 3.2 Configure Secret Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Control access to secrets.

#### Rationale
**Why This Matters:**
- Scoping secrets to the narrowest level (project over account) ensures only the pipelines that need a credential can read it
- Restricting who can create and view secrets prevents quiet exfiltration of cloud and registry credentials
- Auditing secret access provides the trail needed to detect and investigate misuse
- Limiting account- and org-wide secrets stops one compromised project from reaching every other team's credentials

**Attack Prevented:** Unauthorized secret access, credential exfiltration, lateral movement, insider misuse

#### ClickOps Implementation

**Step 1: Scope Secrets**
1. Create secrets at appropriate level
2. Use project-scoped secrets
3. Limit organization/account secrets

**Step 2: Configure Permissions**
1. Restrict secret creation
2. Limit secret viewing
3. Audit secret access

#### Code Implementation

{% include pack-code.html vendor="harness" section="3.2" lang="terraform" %}

---

## 4. Pipeline Security

### 4.1 Configure Pipeline Governance

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.1 |
| NIST 800-53 | SA-15 |

#### Description
Implement pipeline governance controls.

#### Rationale
**Why This Matters:**
- OPA policies enforce baseline standards (approved steps, images, and connectors) so non-compliant or risky pipelines cannot run
- Mandatory approval gates for production insert human review between a change and its deployment
- Governance prevents an attacker or careless user from silently altering a pipeline to ship malicious artifacts
- Policy-as-code makes controls consistent, auditable, and resistant to one-off bypasses

**Attack Prevented:** Poisoned pipeline execution, unauthorized or unreviewed production deploys, policy bypass, supply-chain tampering

#### ClickOps Implementation

**Step 1: Configure OPA Policies**
1. Navigate to: **Account Settings** → **Governance**
2. Create OPA policies
3. Enforce pipeline standards

**Step 2: Configure Approval Gates**
1. Add manual approval stages
2. Configure approval groups
3. Require approvals for production

#### Code Implementation

{% include pack-code.html vendor="harness" section="4.1" lang="terraform" %}

---

### 4.2 Configure Audit Trail

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs.

#### Rationale
**Why This Matters:**
- Logging pipeline runs, configuration changes, permission edits, and secret access creates the evidence needed to detect and investigate incidents
- Without an audit trail, malicious deploys, privilege changes, and secret access go unnoticed and cannot be reconstructed
- Monitoring and retention support breach forensics and satisfy compliance evidence requirements
- A reliable audit record deters insiders and makes persistence and configuration drift visible

**Attack Prevented:** Undetected intrusion, insider misuse, repudiation, delayed breach detection

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

#### Code Implementation

{% include pack-code.html vendor="harness" section="4.2" lang="terraform" %}

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
- [Trust Center](https://trust.harness.io/)
- [Harness Security](https://www.harness.io/security)
- [Developer Hub](https://developer.harness.io/docs/)
- [Security Hardening for CI](https://developer.harness.io/docs/continuous-integration/secure-ci/security-hardening/)
- [SAML SSO Configuration](https://developer.harness.io/docs/platform/authentication/single-sign-on-saml/)
- [RBAC Documentation](https://developer.harness.io/docs/platform/role-based-access-control/)

**API & Developer Tools:**
- [Harness API Documentation](https://apidocs.harness.io/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018 -- via [Trust Center](https://trust.harness.io/)

**Security Incidents:**
- No major public security incidents identified as of February 2026.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, RBAC, and secret management | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
