---
layout: guide
title: "Sentry Hardening Guide"
vendor: "Sentry"
slug: "sentry"
tier: "2"
category: "DevOps"
description: "Application monitoring platform hardening for Sentry including SAML SSO, team access, data scrubbing, and integration security"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Sentry is a leading application monitoring and error tracking platform. As a platform receiving application errors, stack traces, and potentially sensitive data, Sentry security configurations directly impact data privacy and debugging security.

### Intended Audience
- Security engineers managing monitoring platforms
- IT administrators configuring Sentry
- DevOps teams managing application monitoring
- GRC professionals assessing observability security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Sentry users.

#### Prerequisites
- [ ] Sentry organization owner access
- [ ] Business or Enterprise tier
- [ ] SAML 2.0 compatible IdP

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

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Sentry users.

#### ClickOps Implementation

**Step 1: Enable 2FA Requirement**
1. Navigate to: **Settings** → **Security**
2. Enable **Require two-factor authentication**
3. All members must configure 2FA

**Step 2: Configure via IdP**
1. Enable MFA in identity provider
2. Use phishing-resistant methods for admins
3. All SSO users subject to IdP MFA

---

## 2. Access Controls

### 2.1 Configure Team Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Sentry teams.

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

---

### 2.2 Configure Project Access

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control access to specific projects.

#### ClickOps Implementation

**Step 1: Configure Project Teams**
1. Assign projects to specific teams
2. Limit cross-team access
3. Separate production projects

**Step 2: Configure Permissions**
1. Set team-level permissions
2. Restrict sensitive projects
3. Audit project access

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
1. Review owners and admins
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit owner to 2-3 users
2. Require 2FA/SSO for admins
3. Monitor admin activity

---

## 3. Data Security

### 3.1 Configure Data Scrubbing

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SI-12 |

#### Description
Scrub sensitive data from error reports.

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

---

### 3.2 Configure DSN Security

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure Data Source Names (DSNs).

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

---

### 3.3 Configure IP Filtering

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Filter events by IP address.

#### ClickOps Implementation

**Step 1: Configure Allowed IPs**
1. Configure IP filters for projects
2. Filter internal networks
3. Document filtering rules

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logs

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs.

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
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, teams, and data scrubbing | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
