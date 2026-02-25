---
layout: guide
title: "Notion Hardening Guide"
vendor: "Notion"
slug: "notion"
tier: "2"
category: "Productivity"
description: "Collaboration platform hardening for Notion including SAML SSO, workspace security, and data protection controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Notion is a leading collaboration and productivity platform used by **millions of users** for documentation, project management, and knowledge sharing. As a repository for organizational knowledge and sensitive business information, Notion security configurations directly impact data protection and information governance.

### Intended Audience
- Security engineers managing collaboration platforms
- IT administrators configuring Notion Enterprise
- GRC professionals assessing collaboration security
- Workspace administrators managing access controls

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Notion workspace and organization security including SAML SSO, SCIM provisioning, data protection, and workspace permissions.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Organization Security](#2-organization-security)
3. [Data Protection](#3-data-protection)
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
Configure SAML SSO to centralize authentication for Notion users.

#### Prerequisites
- Notion Business or Enterprise plan
- At least one verified domain
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Verify Domain**
1. Navigate to: **Settings** → **Identity** (Business) or **Organization Settings** → **General** (Enterprise)
2. Add and verify your organization's domain
3. Domain verification required before SSO setup

**Step 2: Access SSO Configuration**
1. For Business: Navigate to **Settings** → **Identity**
2. For Enterprise: Navigate to **Organization Settings** → **General** → **SAML Single sign-on (SSO)**

**Step 3: Configure SAML Settings**
1. Copy the **Assertion Consumer Service (ACS) URL**
2. Enter in your IdP portal
3. Configure IdP with:
   - ACS URL from Notion
   - Entity ID
4. Supported IdPs: Azure, Google, Gusto, Okta, OneLogin, Rippling

**Step 4: Enter IdP Details**
1. Provide either IdP URL or IdP metadata XML
2. Complete configuration
3. Test SSO authentication

**Time to Complete:** ~1 hour

---

### 1.2 Enforce SAML SSO

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Require SAML authentication for all workspace members.

#### ClickOps Implementation

**Step 1: Configure Login Method**
1. Navigate to SSO settings
2. Default login method is **Any method**
3. Change to **Only SAML SSO**

**Step 2: Understand Exceptions**
1. Workspace owners can still log in with email
2. This allows recovery if SSO fails
3. Can change configuration to re-enable other methods

**Step 3: Guest Access**
1. Note: Guests cannot use SAML SSO
2. Guests must use username/password or social login
3. Consider this for external collaboration

---

### 1.3 Configure SCIM Provisioning

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure SCIM for automated user lifecycle management.

#### ClickOps Implementation

**Step 1: Enable SCIM**
1. Navigate to organization settings
2. Access SCIM provisioning section
3. Generate SCIM API token

**Step 2: Configure IdP SCIM**
1. Add Notion SCIM integration in IdP
2. Enter SCIM endpoint URL
3. Enter API token

**Step 3: Configure Provisioning Settings**
1. Turn on **Suppress invite emails from SCIM provisioning**
2. Control internal rollout communication
3. Test user synchronization

---

## 2. Organization Security

### 2.1 Configure Workspace Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control who can access workspaces and create accounts.

#### ClickOps Implementation

**Step 1: Configure Allowed Email Domains**
1. Navigate to: **Settings** → **General**
2. Configure **Allowed email domains**
3. Restrict to corporate domains only

**Step 2: Disable Automatic Account Creation**
1. Turn off **Automatic account creation**
2. Prevents users from creating accounts through SSO
3. Requires explicit provisioning

**Step 3: Configure Membership**
1. Review workspace membership
2. Remove unauthorized users
3. Apply least privilege

---

### 2.2 Configure Team Spaces

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Organize content using team spaces for access control.

#### ClickOps Implementation

**Step 1: Create Team Spaces**
1. Organize by team or function
2. Configure team space permissions
3. Limit membership appropriately

**Step 2: Configure Team Space Security**
1. Enable security settings per team space
2. Configure sharing restrictions
3. Apply export controls selectively

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect workspace owner accounts.

#### ClickOps Implementation

**Step 1: Inventory Workspace Owners**
1. Navigate to: **Settings** → **People**
2. Review workspace owners
3. Document all administrators

**Step 2: Apply Least Privilege**
1. Limit workspace owners to 2-3 users
2. Use member roles for regular users
3. Remove unnecessary admin access

---

## 3. Data Protection

### 3.1 Configure Sharing Controls

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control how content can be shared internally and externally.

#### ClickOps Implementation

**Step 1: Configure Guest Access**
1. Navigate to: **Settings** → **Members**
2. Configure guest permissions
3. Limit guest capabilities

**Step 2: Configure Public Pages**
1. Control who can publish pages publicly
2. Audit existing public pages
3. Disable if not needed

**Step 3: Configure Link Sharing**
1. Set default sharing permissions
2. Restrict "Anyone with link" access
3. Require explicit permissions

---

### 3.2 Disable Content Duplication

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Prevent members from copying pages to other workspaces.

#### ClickOps Implementation

**Step 1: Enable Duplication Controls**
1. Navigate to: **Settings** → **Security**
2. Turn on **Disable duplicating pages**
3. Prevents copying content externally

**Step 2: Review Exceptions**
1. Document any business need for duplication
2. Consider enabling per team space if needed
3. Monitor for policy violations

---

### 3.3 Configure Export Controls

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Control ability to export content from Notion.

#### ClickOps Implementation

**Step 1: Configure Export Settings**
1. Navigate to: **Settings** → **Security**
2. Turn on **Disable export**
3. Enable only in team spaces that need it

**Step 2: Audit Export Activity**
1. Review export logs
2. Monitor for unusual patterns
3. Investigate bulk exports

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Monitor user activity through audit logs (Enterprise).

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Organization Settings** → **Analytics**
2. Review audit events
3. Export for analysis

**Step 2: Monitor Key Events**
1. User provisioning/deprovisioning
2. Permission changes
3. Content exports
4. SSO configuration changes

---

### 4.2 Configure Analytics

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | CA-7 |

#### Description
Use analytics to monitor workspace activity.

#### ClickOps Implementation

**Step 1: Access Analytics**
1. Navigate to organization analytics
2. Review workspace usage
3. Monitor member activity

**Step 2: Review Security Metrics**
1. Track guest access patterns
2. Monitor sharing activity
3. Identify unusual behavior

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Notion Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/SAML | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Workspace permissions | [2.3](#23-limit-admin-access) |
| CC6.6 | Access controls | [2.1](#21-configure-workspace-access) |
| CC6.7 | Export controls | [3.3](#33-configure-export-controls) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Notion Control | Guide Section |
|---------|----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-2 | SCIM provisioning | [1.3](#13-configure-scim-provisioning) |
| AC-3 | Sharing controls | [3.1](#31-configure-sharing-controls) |
| AC-6 | Least privilege | [2.3](#23-limit-admin-access) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: Plan Compatibility

| Feature | Free | Plus | Business | Enterprise |
|---------|------|------|----------|------------|
| SAML SSO | ❌ | ❌ | ✅ | ✅ |
| SCIM | ❌ | ❌ | ❌ | ✅ |
| Domain Verification | ❌ | ❌ | ✅ | ✅ |
| Audit Logs | ❌ | ❌ | ❌ | ✅ |
| Export Controls | ❌ | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official Notion Documentation:**
- [Trust Center](https://trustcenter.notion.com/)
- [Security & Compliance Overview](https://www.notion.com/security)
- [Help Center](https://www.notion.com/help)
- [Security Practices](https://www.notion.com/help/security-and-privacy)
- [Enterprise Security Provisions](https://www.notion.com/help/guides/notion-enterprise-security-provisions)
- [SAML SSO Configuration](https://www.notion.com/help/saml-sso-configuration)
- [Provision Users with SCIM](https://www.notion.com/help/provision-users-and-groups-with-scim)
- [Managing Organization in Notion](https://www.notion.com/help/guides/everything-about-setting-up-and-managing-an-organization-in-notion)

**API Documentation:**
- [Notion API Reference](https://developers.notion.com/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27701, ISO 27017, ISO 27018 — via [Trust Center](https://trustcenter.notion.com/)
- HIPAA (with Enterprise plan and BAA) — via [Security & Compliance](https://www.notion.com/security)

**Security Incidents:**
- No major breaches of Notion infrastructure identified. In 2025, security researchers disclosed prompt injection risks in Notion AI agents that could enable data exfiltration via crafted workspace content (CVE-2024-23745 also affected Notion Web Clipper 1.0.3). These are configuration and feature-level risks, not infrastructure compromises.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, organization security, and data protection | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
