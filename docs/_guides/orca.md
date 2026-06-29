---
layout: guide
title: "Orca Security Hardening Guide"
vendor: "Orca Security"
slug: "orca"
tier: "2"
category: "Security"
description: "Cloud security platform hardening for Orca Security including SAML SSO, role-based access, and cloud account integration"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

Orca Security is a cloud security platform providing agentless workload protection and cloud security posture management. As a platform with visibility into cloud infrastructure, Orca security configurations directly impact cloud security operations.

### Intended Audience
- Security engineers managing cloud security
- IT administrators configuring Orca
- Cloud security architects
- GRC professionals assessing cloud security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Orca platform security including SSO, RBAC, cloud account integration, and audit logging.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Cloud Integration Security](#3-cloud-integration-security)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO for Orca platform access.

#### Rationale
**Why This Matters:**
- Centralizes Orca authentication in your corporate IdP, enforcing MFA and conditional access on every login to the cloud security console
- Local password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- Centralized provisioning and deprovisioning removes access for departed users automatically, eliminating orphaned accounts with standing visibility
- Orca holds a complete map of cloud assets, vulnerabilities, and misconfigurations — a single compromised login hands an attacker a blueprint of where you are weakest

**Attack Prevented:** Credential theft, phishing, orphaned-account access, reconnaissance of cloud weaknesses

#### Prerequisites
- Orca admin access
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Settings** → **Authentication** → **SSO**
2. Enable SAML authentication

**Step 2: Configure SAML**
1. Configure IdP settings:
   - Entity ID
   - SSO URL
   - Certificate
2. Configure Orca in IdP

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Configure fallback access

**Time to Complete:** ~1-2 hours

#### Code Implementation

{% include pack-code.html vendor="orca" section="1.1" lang="terraform" %}

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Orca users.

#### Rationale
**Why This Matters:**
- A second authentication factor stops attackers who have already stolen or guessed a valid Orca password
- Orca's console exposes the organization's full cloud risk posture, so a single-factor compromise leaks high-value security intelligence
- Phishing-resistant methods such as FIDO2/WebAuthn for admins defeat real-time credential-relay and one-time-code interception
- Enforcing MFA on every account closes the gap left by reused or previously breached corporate passwords

**Attack Prevented:** Credential stuffing, password reuse, phishing, MFA-bypass via stolen passwords

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA
3. Use phishing-resistant methods for admins

#### Code Implementation

{% include pack-code.html vendor="orca" section="1.2" lang="terraform" %}

---

## 2. Access Controls

### 2.1 Configure Role-Based Access Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Orca roles.

#### Rationale
**Why This Matters:**
- Least-privilege roles ensure each user can only see and act on what their job requires, limiting the blast radius of any one compromised account
- Default broad roles let analysts or viewers reach sensitive findings and configuration controls they should never touch
- Custom roles scoped to specific accounts prevent lateral visibility across unrelated business units
- Quarterly access reviews catch privilege creep and remove standing access that accumulated beyond need

**Attack Prevented:** Privilege escalation, lateral movement, insider misuse, excessive data exposure

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Settings** → **Users & Roles**
2. Review available roles:
   - Admin
   - Security Analyst
   - Viewer
3. Assign minimum necessary role

**Step 2: Configure Custom Roles**
1. Create roles for specific needs
2. Limit scope to required accounts
3. Apply asset-level permissions

**Step 3: Regular Reviews**
1. Quarterly access reviews
2. Remove inactive users
3. Update role assignments

#### Code Implementation

{% include pack-code.html vendor="orca" section="2.1" lang="terraform" %}

---

### 2.2 Configure Account Scope

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Limit user access to specific cloud accounts.

#### Rationale
**Why This Matters:**
- Restricting users to only the cloud accounts they support contains exposure if their credentials are compromised
- Separating production visibility prevents non-production staff from viewing sensitive production findings and assets
- Business-unit boundaries enforce the data segregation many compliance regimes require
- Scoped access reduces the value of any single Orca account to an attacker who obtains it

**Attack Prevented:** Cross-tenant data exposure, lateral movement, unauthorized production access

#### ClickOps Implementation

**Step 1: Configure Scoped Access**
1. Limit users to required accounts
2. Separate production visibility
3. Apply business unit boundaries

#### Code Implementation

{% include pack-code.html vendor="orca" section="2.2" lang="terraform" %}

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect admin accounts.

#### Rationale
**Why This Matters:**
- Admin accounts can modify integrations, roles, and platform settings, so each one is a high-value target and fewer admins means fewer paths to full control
- Limiting admins to a small set and requiring MFA shrinks the attack surface for takeover of the security platform itself
- Monitoring admin activity provides early detection of misuse or a hijacked admin session
- An attacker controlling an Orca admin could disable monitoring or alter integrations to hide an active cloud compromise

**Attack Prevented:** Admin-account takeover, privilege escalation, tampering with security monitoring

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review admin accounts
2. Document admin access

**Step 2: Apply Restrictions**
1. Limit admins to 2-3 users
2. Require MFA
3. Monitor admin activity

#### Code Implementation

{% include pack-code.html vendor="orca" section="2.3" lang="terraform" %}

---

## 3. Cloud Integration Security

### 3.1 Configure Cloud Account Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure cloud account integrations.

#### Rationale
**Why This Matters:**
- Orca's cloud integrations grant it standing access into your cloud accounts, so least-privilege, read-only roles limit what a compromise of that trust relationship could reach
- Following Orca's recommended IAM policies avoids over-permissioning that an attacker could abuse for write or delete actions
- Regular permission reviews catch scope creep and stale grants that widen the integration's blast radius
- A misconfigured integration role is a direct pathway from the security platform into the production cloud environment

**Attack Prevented:** Cloud integration abuse, privilege escalation into cloud accounts, supply-chain pivot

#### ClickOps Implementation

**Step 1: Review Integrations**
1. Navigate to: **Settings** → **Cloud Accounts**
2. Review connected accounts
3. Verify permissions

**Step 2: Apply Least Privilege**
1. Use read-only roles where possible
2. Follow Orca's recommended IAM policies
3. Review cloud permissions regularly

#### Code Implementation

{% include pack-code.html vendor="orca" section="3.1" lang="terraform" %}

---

### 3.2 Configure API Security

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure Orca API access.

#### Rationale
**Why This Matters:**
- Orca API keys can read findings and drive automation, so an exposed key gives an attacker programmatic access to your cloud risk data
- Storing keys in a secrets manager rather than in code or config prevents accidental leaks through repositories and logs
- Regular rotation limits the useful lifetime of any key that does leak
- Monitoring key usage surfaces anomalous access that signals a stolen or misused credential

**Attack Prevented:** API key leakage, unauthorized data access, automation abuse, credential replay

#### ClickOps Implementation

**Step 1: Review API Keys**
1. Navigate to: **Settings** → **API Keys**
2. Review all API keys
3. Document key purposes

**Step 2: Secure Keys**
1. Store keys securely
2. Rotate regularly
3. Monitor usage

#### Code Implementation

{% include pack-code.html vendor="orca" section="3.2" lang="terraform" %}

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Orca Control | Guide Section |
|-----------|--------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [2.1](#21-configure-role-based-access-control) |
| CC6.7 | Integration security | [3.1](#31-configure-cloud-account-security) |

### NIST 800-53 Rev 5 Mapping

| Control | Orca Control | Guide Section |
|---------|--------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-6 | RBAC | [2.1](#21-configure-role-based-access-control) |
| SC-12 | API security | [3.2](#32-configure-api-security) |

---

## Appendix B: References

**Official Orca Security Documentation:**
- [Trust Center (SafeBase)](https://trustcenter.orca.security/)
- [Knowledge Base](https://docs.orcasecurity.io/)
- [Resource Library](https://orca.security/resources/)
- [API Security Datasheet](https://orca.security/resources/literature/api-security-datasheet/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018, ISO 27701, PCI DSS v4.0.1, FedRAMP Moderate, StateRAMP — via [Trust Center](https://trustcenter.orca.security/)
- [FedRAMP Authorization Announcement](https://orca.security/resources/blog/orca-security-earns-fedramp-authorization/)
- [StateRAMP Authorization Announcement](https://orca.security/resources/press-releases/orca-security-achieves-stateramp-authorization/)

**Security Incidents:**
- No major public incidents identified

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, RBAC, and integration security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
