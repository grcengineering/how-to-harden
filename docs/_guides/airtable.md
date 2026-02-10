---
layout: guide
title: "Airtable Enterprise Hardening Guide"
vendor: "Airtable"
slug: "airtable"
tier: "2"
category: "Collaboration & Productivity"
description: "Low-code platform hardening for Airtable Enterprise including SSO, access controls, and collaboration security"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Airtable is a leading low-code platform combining spreadsheets and databases, used by **hundreds of thousands of organizations** for workflow automation, project management, and business applications. As a repository for business-critical data and processes, Airtable security configurations directly impact data protection and operational integrity.

### Intended Audience
- Security engineers managing business platforms
- IT administrators configuring Airtable Enterprise
- GRC professionals assessing low-code security
- Business operations teams managing workspaces

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Airtable Enterprise Admin Panel security including SSO configuration, domain management, access controls, and collaboration settings.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Domain & User Management](#2-domain--user-management)
3. [Access & Collaboration Controls](#3-access--collaboration-controls)
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
Configure SAML SSO to centralize authentication for Airtable users.

#### Prerequisites
- [ ] Airtable Enterprise plan
- [ ] Verified domain in Admin Panel
- [ ] SAML 2.0 compatible identity provider

#### ClickOps Implementation

**Step 1: Verify Domain**
1. Navigate to: **Admin Panel** → **Settings** → **Email domains**
2. Add your organization's domain
3. Complete domain verification via DNS
4. SCIM and SSO cannot be configured for unverified domains

**Step 2: Configure SSO**
1. Navigate to: **Admin Panel** → **Settings** → **SSO**
2. Click **Configure SSO**
3. Select identity provider:
   - Okta
   - Microsoft Entra ID (Azure AD)
   - ADFS
   - Custom SAML

**Step 3: Configure IdP Settings**
1. Download Airtable SP metadata
2. Configure IdP application:
   - NameID: User's email address
   - NameID format: EmailAddress or unspecified
3. Upload IdP metadata to Airtable

**Step 4: Test and Enforce**
1. Test SSO authentication
2. Select enforcement:
   - **Optional:** Users can use SSO or password
   - **Required:** Users must use SSO only
3. Verify before requiring to prevent lockout

**Time to Complete:** ~1 hour

---

### 1.2 Configure Two-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for organization members.

#### Prerequisites
- [ ] Enterprise Scale plan for enforced 2FA

#### ClickOps Implementation

**Step 1: Enable 2FA via SSO (Recommended)**
1. Configure MFA in your identity provider
2. All SSO users subject to IdP MFA
3. Preferred approach for enterprise

**Step 2: Enable Native 2FA (Enterprise Scale)**
1. Navigate to: **Admin Panel** → **Settings** → **Security**
2. Enable **Two-factor authentication**
3. Enforce for all organization members

---

### 1.3 Configure SCIM Provisioning

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure SCIM for automatic user lifecycle management.

#### ClickOps Implementation

**Step 1: Configure SCIM (Okta/Entra)**
1. Navigate to: **Admin Panel** → **Settings** → **SCIM**
2. Generate SCIM token
3. Configure IdP SCIM integration
4. Out-of-the-box support for Okta and Entra ID

**Step 2: Custom SCIM (Enterprise API)**
1. Use Enterprise API for custom integrations
2. Build custom SCIM workflows
3. Requires developer support

**Step 3: Verify Provisioning**
1. Test user creation from IdP
2. Verify user appears in Airtable
3. Test deprovisioning

---

## 2. Domain & User Management

### 2.1 Configure Domain Federation

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Verify and federate your organization's domains for complete control.

#### Rationale
**Why This Matters:**
- Domain verification unlocks full admin panel functionality
- Controls all accounts using your domain
- Required for SSO and SCIM configuration

#### ClickOps Implementation

**Step 1: Add Domain**
1. Navigate to: **Admin Panel** → **Settings** → **Email domains**
2. Click **Add domain**
3. Enter organization domain

**Step 2: Verify Domain**
1. Add DNS TXT record
2. Work with IT/DNS team
3. Verify in Admin Panel

**Step 3: Claim Existing Accounts**
1. View accounts using your domain
2. Migrate to organization membership
3. Consolidate shadow accounts

---

### 2.2 Configure Session Security

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout and security settings.

#### ClickOps Implementation

**Step 1: Configure Session Length**
1. Navigate to: **Admin Panel** → **Settings** → **Security & compliance**
2. Configure **Fixed Web Session length**
3. Set how long users can stay signed in

**Step 2: Configure Session Controls**
1. Balance security with usability
2. Consider shorter sessions for sensitive data
3. Document session policy

---

### 2.3 Configure IP Restrictions

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Restrict access to approved IP addresses.

#### ClickOps Implementation

**Step 1: Configure IP Allowlist**
1. Navigate to: **Admin Panel** → **Settings** → **Security**
2. Configure **IP restrictions**
3. Add approved IP addresses/CIDR blocks

**Step 2: Apply Restrictions**
1. Only users from approved IPs can sign in
2. Test from approved locations
3. Document emergency procedures

---

## 3. Access & Collaboration Controls

### 3.1 Configure Collaborator Invitations

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Control who can invite external collaborators.

#### ClickOps Implementation

**Step 1: Configure Invitation Policy**
1. Navigate to: **Admin Panel** → **Settings** → **Collaboration**
2. Configure **Collaborator invites**:
   - Allow invites to anyone
   - Restrict to verified domains only
   - Disable external invites entirely

**Step 2: Configure Enterprise Hub Restrictions**
1. For Enterprise Hub:
   - Restrict invites to org unit members only
   - Non-member collaborators removed when enabled
2. Apply appropriate restrictions

---

### 3.2 Configure Workspace Permissions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege for workspace access.

#### ClickOps Implementation

**Step 1: Configure Workspace Structure**
1. Navigate to: **Admin Panel** → **Workspaces**
2. Organize by team or function
3. Set appropriate access levels

**Step 2: Configure Base Permissions**
1. Set base-level permissions:
   - Creator
   - Editor
   - Commenter
   - Read only
2. Apply minimum necessary access

---

### 3.3 Configure Interface Permissions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control access to Airtable Interfaces.

#### ClickOps Implementation

**Step 1: Configure Interface Access**
1. Navigate to: **Base** → **Interfaces**
2. Configure who can:
   - Create interfaces
   - View interfaces
   - Edit interfaces

**Step 2: Apply Sensitivity Labels**
1. Navigate to: **Admin Panel** → **Settings** → **Sensitivity labels**
2. Create custom labels
3. Apply to bases and interfaces
4. Visual cue for data sensitivity

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs for security events.

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Admin Panel** → **Audit logs**
2. Review logged events:
   - User login/logout
   - Permission changes
   - Base access
   - Data exports

**Step 2: Enable Change Events (Enterprise Scale)**
1. Contact account manager to enable
2. Provides detailed change tracking
3. API access for integration

**Key Events to Monitor:**
- User provisioning/deprovisioning
- Permission changes
- External collaborator additions
- Data exports
- SSO configuration changes

---

### 4.2 Configure API Security

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure Airtable API access.

#### ClickOps Implementation

**Step 1: Manage Personal Access Tokens**
1. Users generate tokens in account settings
2. Configure token expiration policies
3. Document approved integrations

**Step 2: Monitor API Usage**
1. Review API access patterns
2. Identify unauthorized integrations
3. Revoke unnecessary tokens

---

### 4.3 Configure Conditional Access

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Use IdP conditional access for enhanced security.

#### ClickOps Implementation

**Step 1: Configure IdP Conditional Access**
1. Configure in Microsoft Entra or other IdP
2. Enforce session control
3. Protect against data exfiltration

**Step 2: Configure Policies**
1. Require compliant devices
2. Block risky sign-ins
3. Enable continuous access evaluation

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Airtable Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Workspace permissions | [3.2](#32-configure-workspace-permissions) |
| CC6.6 | IP restrictions | [2.3](#23-configure-ip-restrictions) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |
| CC6.7 | Session security | [2.2](#22-configure-session-security) |

### NIST 800-53 Rev 5 Mapping

| Control | Airtable Control | Guide Section |
|---------|------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-configure-two-factor-authentication) |
| AC-2 | SCIM | [1.3](#13-configure-scim-provisioning) |
| AC-3 | Permissions | [3.2](#32-configure-workspace-permissions) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: Plan Compatibility

| Feature | Team | Business | Enterprise | Enterprise Scale |
|---------|------|----------|------------|------------------|
| SAML SSO | ❌ | ❌ | ✅ | ✅ |
| SCIM | ❌ | ❌ | ✅ | ✅ |
| Enforced 2FA | ❌ | ❌ | ❌ | ✅ |
| IP Restrictions | ❌ | ❌ | ✅ | ✅ |
| Audit Logs | ❌ | ❌ | ✅ | ✅ |
| Change Events | ❌ | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Airtable Documentation:**
- [Trust & Security](https://www.airtable.com/company/trust-and-security)
- [Airtable Support](https://support.airtable.com/)
- [Security Practices](https://support.airtable.com/docs/airtable-security-practices)
- [Admin Panel Overview](https://support.airtable.com/docs/overview-of-the-admin-panel)
- [Configuring SSO in Admin Panel](https://support.airtable.com/docs/configuring-sso-in-the-admin-panel)
- [Enterprise SSO](https://support.airtable.com/docs/enterprise-sso)
- [Domain Federation and Verification](https://support.airtable.com/docs/airtable-domain-federation-and-verification)
- [HIPAA and FERPA Compliance](https://support.airtable.com/docs/hipaa-and-ferpa-compliance)
- [DORA Compliance](https://support.airtable.com/docs/dora-compliance)
- [Enterprise Governance](https://www.airtable.com/platform/governance)

**API & Developer Tools:**
- [Airtable Web API Introduction](https://airtable.com/developers/web/api/introduction)
- [Airtable Developers Portal](https://airtable.com/developers)
- [airtable.js (JavaScript Client)](https://github.com/Airtable/airtable.js)
- [GitHub Organization](https://github.com/airtable)

**Compliance Frameworks:**
- SOC 2 Type II (annual audit) — available via account manager or sales@airtable.com
- ISO/IEC 27001:2022, ISO/IEC 27701:2019 (annual audits) — via [Trust & Security](https://www.airtable.com/company/trust-and-security)
- TX-RAMP Level 2 certified
- GDPR, UK GDPR, CCPA/CPRA compliance
- 256-bit AES encryption at rest, 256-bit SSL/TLS in transit

**Security Incidents:**
- No major public security incidents identified as of early 2026.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, domain management, and collaboration controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
