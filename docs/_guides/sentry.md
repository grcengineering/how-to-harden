---
layout: guide
title: "Sentry Hardening Guide"
vendor: "Sentry"
slug: "sentry"
tier: "2"
category: "DevOps"
description: "Application monitoring platform hardening for Sentry including SAML SSO, team access, data scrubbing, and integration security"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

Sentry is a leading application monitoring and error tracking platform. As a platform receiving application errors, stack traces, and potentially sensitive data, Sentry security configurations directly impact data privacy and debugging security.

### Intended Audience
- Security engineers managing monitoring platforms
- IT administrators configuring Sentry
- DevOps teams managing application monitoring
- GRC professionals assessing observability security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Sentry security including SAML SSO, team access, data scrubbing, and DSN security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Data Security](#3-data-security)
4. [Monitoring & Compliance](#4-monitoring--compliance)
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
Configure SAML SSO to centralize authentication for Sentry users.

#### Rationale
**Why This Matters:**
- Centralizes Sentry login in your corporate IdP so MFA, conditional access, and session policies apply on every authentication
- Local Sentry passwords bypass IdP controls and are prime targets for credential stuffing and phishing
- IdP-driven provisioning and deprovisioning removes departed employees automatically, eliminating orphaned accounts with standing access to error data
- Sentry events expose stack traces, request payloads, and environment details that map your application's internals, so a single compromised login can reveal them all

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access

#### Prerequisites
- Sentry organization owner access
- Business or Enterprise tier
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Settings** → **Auth**
2. Select **Configure** for SAML2

**Step 2: Configure SAML**
1. Configure IdP settings:
   - Entity ID
   - SSO URL
   - Certificate
2. Configure attribute mapping
3. Download Sentry metadata for IdP

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Configure admin fallback

**Time to Complete:** ~1-2 hours

#### Code Implementation

{% include pack-code.html vendor="sentry" section="1.1" lang="terraform" %}

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Sentry users.

#### Rationale
**Why This Matters:**
- A second factor blocks account takeover even when a password is phished, guessed, or reused from another breach
- Sentry accounts can read error reports containing sensitive data and can alter project, alerting, and DSN settings
- Phishing-resistant factors for owners and admins protect the accounts with the broadest blast radius
- Enforcing 2FA organization-wide closes the gap of individual users who would otherwise opt out

**Attack Prevented:** Credential stuffing, password reuse, account takeover, phishing

#### ClickOps Implementation

**Step 1: Enable 2FA Requirement**
1. Navigate to: **Settings** → **Security**
2. Enable **Require two-factor authentication**
3. All members must configure 2FA

**Step 2: Configure via IdP**
1. Enable MFA in identity provider
2. Use phishing-resistant methods for admins
3. All SSO users subject to IdP MFA

#### Code Implementation

{% include pack-code.html vendor="sentry" section="1.2" lang="terraform" %}

---

## 2. Access Controls

### 2.1 Configure Team Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Sentry teams.

#### Rationale
**Why This Matters:**
- Team-scoped access limits each member to only the projects and error data they need, shrinking the blast radius of any one compromised account
- Over-broad organization roles let a single user read every project's stack traces and modify settings across the org
- Function- or product-aligned teams make access reviews and offboarding straightforward and auditable
- Least privilege contains insider misuse and limits lateral movement after a credential compromise

**Attack Prevented:** Privilege escalation, lateral movement, insider data access, excessive exposure

#### ClickOps Implementation

**Step 1: Create Teams**
1. Navigate to: **Settings** → **Teams**
2. Create teams by function/product
3. Assign projects to teams

**Step 2: Configure Member Roles**
1. Review organization roles:
   - Owner
   - Manager
   - Admin
   - Member
2. Assign minimum necessary role
3. Regular access reviews

#### Code Implementation

{% include pack-code.html vendor="sentry" section="2.1" lang="terraform" %}

---

### 2.2 Configure Project Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control access to specific projects.

#### Rationale
**Why This Matters:**
- Restricting projects to specific teams keeps sensitive production error data away from members who have no business reason to see it
- Separating production from lower environments prevents broad, cross-project visibility into customer-facing systems
- Per-project permissions enforce data segmentation and support compliance and tenant boundaries
- Auditing project access surfaces stale or over-broad grants before they are abused

**Attack Prevented:** Unauthorized data access, lateral movement, data-segregation failures

#### ClickOps Implementation

**Step 1: Configure Project Teams**
1. Assign projects to specific teams
2. Limit cross-team access
3. Separate production projects

**Step 2: Configure Permissions**
1. Set team-level permissions
2. Restrict sensitive projects
3. Audit project access

#### Code Implementation

{% include pack-code.html vendor="sentry" section="2.2" lang="terraform" %}

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
- Owner and admin accounts can change SSO, billing, DSNs, data scrubbing, and member roles, giving them full control over the organization's security posture
- Keeping the number of privileged accounts small reduces the attack surface attackers can target
- Requiring SSO and 2FA on every admin account hardens the highest-value logins against takeover
- Monitoring admin activity gives early warning of misuse or a compromised privileged session

**Attack Prevented:** Privileged-account takeover, configuration tampering, insider abuse, security-control rollback

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review owners and admins
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit owner to 2-3 users
2. Require 2FA/SSO for admins
3. Monitor admin activity

#### Code Implementation

{% include pack-code.html vendor="sentry" section="2.3" lang="terraform" %}

---

## 3. Data Security

### 3.1 Configure Data Scrubbing

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SI-12 |

#### Description
Scrub sensitive data from error reports.

#### Rationale
**Why This Matters:**
- Stack traces and request payloads frequently capture passwords, tokens, session cookies, and PII that should never be stored in a monitoring system
- Server-side scrubbing provides a backstop, while client-side beforeSend filtering keeps sensitive values from ever leaving the application
- Minimizing stored sensitive data shrinks the impact of any breach and supports GDPR, HIPAA, and PCI obligations
- Unscrubbed secrets captured in events become live credentials anyone with Sentry access can harvest

**Attack Prevented:** Sensitive-data exposure, secret leakage, PII overcollection, compliance violations

#### ClickOps Implementation

**Step 1: Enable Server-Side Scrubbing**
1. Navigate to: **Settings** → **Security & Privacy**
2. Enable **Data Scrubber**
3. Configure sensitive fields

**Step 2: Configure Client-Side Scrubbing**
1. Use SDK beforeSend hooks
2. Filter PII before transmission
3. Test scrubbing effectiveness

**Step 3: Configure Defaults**
1. Enable default safe fields
2. Add custom sensitive fields
3. Document scrubbing rules

#### Code Implementation

{% include pack-code.html vendor="sentry" section="3.1" lang="terraform" %}

---

### 3.2 Configure DSN Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure Data Source Names (DSNs).

#### Rationale
**Why This Matters:**
- A leaked DSN lets anyone submit arbitrary events to your project, polluting error data and burning your event quota
- Rate limits and quotas on each DSN contain abuse and prevent denial of service through event flooding
- Rotating compromised DSNs promptly cuts off attackers without disrupting legitimate clients
- Tracking DSN usage makes it possible to detect anomalous ingestion and unauthorized clients

**Attack Prevented:** DSN abuse, event flooding, quota exhaustion, data poisoning

#### ClickOps Implementation

**Step 1: Review DSNs**
1. Navigate to: **Project Settings** → **Client Keys (DSN)**
2. Review all DSNs
3. Document DSN usage

**Step 2: Configure Rate Limiting**
1. Configure DSN rate limits
2. Set event quotas
3. Alert on abuse

**Step 3: Rotate If Needed**
1. Rotate compromised DSNs
2. Update applications
3. Disable old DSNs

#### Code Implementation

{% include pack-code.html vendor="sentry" section="3.2" lang="terraform" %}

---

### 3.3 Configure IP Filtering

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Filter events by IP address.

#### Rationale
**Why This Matters:**
- Restricting event ingestion to known network ranges blocks spoofed or junk events submitted with a leaked DSN from unexpected sources
- Filtering reduces noise and prevents attackers from flooding projects with bogus data that masks real errors
- IP allowlists add a network-layer control on top of DSN secrecy, enforcing defense in depth
- Documented filtering rules make ingestion sources auditable and anomalies easy to spot

**Attack Prevented:** Event spoofing, data poisoning, quota exhaustion, ingestion abuse

#### ClickOps Implementation

**Step 1: Configure Allowed IPs**
1. Configure IP filters for projects
2. Filter internal networks
3. Document filtering rules

#### Code Implementation

{% include pack-code.html vendor="sentry" section="3.3" lang="terraform" %}

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logs

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs.

#### Rationale
**Why This Matters:**
- Audit logs record authentication, permission changes, DSN modifications, and data access so security-relevant actions are attributable
- Without a reliable log trail, account compromise and configuration tampering can go undetected and unattributed
- Monitoring permission and DSN changes catches privilege escalation and exfiltration setup early
- Retained logs are essential evidence for incident response, forensics, and SOC 2 / ISO 27001 audits

**Attack Prevented:** Undetected intrusion, repudiation, unauthorized configuration changes, audit-trail gaps

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Settings** → **Audit Log**
2. Review logged events
3. Configure retention

**Step 2: Monitor Events**
1. User authentication
2. Permission changes
3. DSN modifications
4. Data access events

#### Code Implementation

{% include pack-code.html vendor="sentry" section="4.1" lang="terraform" %}

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Sentry Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Team access | [2.1](#21-configure-team-access) |
| CC6.7 | DSN security | [3.2](#32-configure-dsn-security) |
| CC7.2 | Audit logs | [4.1](#41-configure-audit-logs) |

### NIST 800-53 Rev 5 Mapping

| Control | Sentry Control | Guide Section |
|---------|----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-enforce-two-factor-authentication) |
| AC-6 | Team access | [2.1](#21-configure-team-access) |
| SI-12 | Data scrubbing | [3.1](#31-configure-data-scrubbing) |
| AU-2 | Audit logs | [4.1](#41-configure-audit-logs) |

---

## Appendix A: References

**Official Sentry Documentation:**
- [Sentry Documentation](https://docs.sentry.io/)
- [Sentry Security](https://sentry.io/security/)
- [SSO Configuration](https://docs.sentry.io/product/accounts/sso/)
- [Data Scrubbing](https://docs.sentry.io/product/data-management-settings/scrubbing/)

**API & Developer Resources:**
- [Sentry API Documentation](https://docs.sentry.io/api/)

**Trust & Compliance:**
- [Sentry Trust Center](https://sentry.io/trust/)
- SOC 2 Type II, ISO 27001, HIPAA -- via [Sentry SOC2 & ISO 27001 Documentation](https://docs.sentry.io/security-legal-pii/security/soc2/)

**Security Incidents:**
- No major public security breaches of Sentry's platform infrastructure have been identified.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, teams, and data scrubbing | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
