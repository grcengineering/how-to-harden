---
layout: guide
title: "Linear Hardening Guide"
vendor: "Linear"
slug: "linear"
tier: "3"
category: "DevOps & Engineering"
description: "Issue tracking platform hardening for Linear including SAML SSO, workspace access, and team permissions"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Linear is a modern issue tracking and project management platform designed for software teams. As a platform managing development workflows and project data, Linear security configurations directly impact operational security and intellectual property protection.

### Intended Audience
- Security engineers managing engineering tools
- IT administrators configuring Linear
- Engineering managers managing workspaces
- GRC professionals assessing development security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Linear security including SAML SSO, workspace access, team permissions, and integration security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Integration Security](#3-integration-security)
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
Configure SAML SSO to centralize authentication for Linear users.

#### Prerequisites
- [ ] Linear workspace admin access
- [ ] Enterprise tier
- [ ] SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Settings** → **Security** → **SAML SSO**
2. Enable SAML SSO

**Step 2: Configure SAML**
1. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
2. Download Linear metadata for IdP
3. Configure attribute mapping

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
Require 2FA for all Linear users.

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

### 1.3 Configure Allowed Domains

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Restrict sign-up to approved email domains.

#### ClickOps Implementation

**Step 1: Configure Allowed Domains**
1. Navigate to: **Settings** → **Security**
2. Configure allowed email domains
3. Block public email providers

---

## 2. Access Controls

### 2.1 Configure Team Permissions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Linear teams.

#### ClickOps Implementation

**Step 1: Create Teams**
1. Navigate to: **Settings** → **Teams**
2. Create teams by function
3. Configure team visibility

**Step 2: Configure Member Roles**
1. Review workspace roles:
   - Admin
   - Member
   - Guest
2. Assign minimum necessary role
3. Regular access reviews

---

### 2.2 Configure Project Visibility

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control project and issue visibility.

#### ClickOps Implementation

**Step 1: Configure Team Privacy**
1. Set team visibility settings
2. Control cross-team access
3. Restrict sensitive projects

**Step 2: Configure Issue Access**
1. Review default visibility
2. Restrict sensitive issues
3. Audit access patterns

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
1. Review workspace admins
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit admin to 2-3 users
2. Require 2FA/SSO for admins
3. Monitor admin activity

---

## 3. Integration Security

### 3.1 Configure Integration Access

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Control third-party integrations.

#### ClickOps Implementation

**Step 1: Review Integrations**
1. Navigate to: **Settings** → **Integrations**
2. Review all integrations
3. Remove unused integrations

**Step 2: Configure Permissions**
1. Review integration scopes
2. Limit data access
3. Audit integration usage

---

### 3.2 Configure API Tokens

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure API token management.

#### ClickOps Implementation

**Step 1: Review API Tokens**
1. Navigate to user settings
2. Review personal API tokens
3. Document token purposes

**Step 2: Secure Tokens**
1. Store tokens securely
2. Rotate tokens regularly
3. Revoke unused tokens

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logs

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor activity logs.

#### ClickOps Implementation

**Step 1: Access Activity**
1. Review workspace activity
2. Monitor key events
3. Document for compliance

**Step 2: Monitor Events**
1. User authentication
2. Permission changes
3. Integration modifications
4. Data exports

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Linear Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Team permissions | [2.1](#21-configure-team-permissions) |
| CC7.2 | Audit logs | [4.1](#41-configure-audit-logs) |

### NIST 800-53 Rev 5 Mapping

| Control | Linear Control | Guide Section |
|---------|----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-enforce-two-factor-authentication) |
| AC-6 | Team permissions | [2.1](#21-configure-team-permissions) |
| AU-2 | Audit logs | [4.1](#41-configure-audit-logs) |

---

## Appendix A: References

**Official Linear Documentation:**
- [Linear Trust Center](https://trust.linear.app/)
- [Linear Security](https://linear.app/security)
- [Linear Documentation](https://linear.app/docs)
- [SSO Configuration](https://linear.app/docs/saml-sso)
- [Team Management](https://linear.app/docs/teams)

**API & Developer Resources:**
- [Linear API Documentation](https://developers.linear.app/docs)
- [Linear GraphQL API](https://developers.linear.app/docs/graphql/working-with-the-graphql-api)
- [Linear SDKs](https://developers.linear.app/docs/sdk/getting-started)

**Compliance Frameworks:**
- SOC 2 Type II, GDPR, HIPAA (Enterprise plan with BAA) -- via [Linear Trust Center](https://trust.linear.app/)

**Security Incidents:**
- No major public security breaches identified as of this writing.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, teams, and integrations | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
