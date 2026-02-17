---
layout: guide
title: "Datadog Hardening Guide"
vendor: "Datadog"
slug: "datadog"
tier: "1"
category: "Security"
description: "Observability platform hardening for Datadog including SAML SSO, role-based access control, and organization security settings"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Datadog is a leading observability and security platform used by **thousands of organizations** for infrastructure monitoring, APM, log management, and security monitoring. As a platform with access to sensitive operational data and infrastructure metrics, Datadog security configurations directly impact data protection and operational security.

### Intended Audience
- Security engineers managing observability platforms
- IT administrators configuring Datadog
- DevOps teams securing monitoring infrastructure
- GRC professionals assessing observability security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Datadog organization security including SAML SSO, role-based access control, API key management, and session security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [API & Key Security](#3-api--key-security)
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
Configure SAML SSO to centralize authentication for Datadog users.

#### Rationale
**Why This Matters:**
- Centralizes identity management
- Enables enforcement of organizational MFA policies
- Simplifies user lifecycle management
- Required for SAML strict mode

#### Prerequisites
- [ ] Datadog Administrator access
- [ ] SAML 2.0 compatible identity provider
- [ ] IdP admin credentials

#### ClickOps Implementation

**Step 1: Access SAML Configuration**
1. Navigate to: **Organization Settings** → **Login Methods**
2. Click on **SAML** settings
3. Enable SAML configuration

**Step 2: Configure Identity Provider**
1. Create SAML application in IdP:
   - Active Directory
   - Auth0
   - Google
   - LastPass
   - Microsoft Entra ID
   - Okta
   - SafeNet
2. Configure required attributes

**Step 3: Upload IdP Metadata**
1. Download IdP metadata XML
2. Upload to Datadog SAML settings
3. Verify configuration

**Step 4: Configure Datadog Settings**
1. Datadog supports HTTP-POST binding
2. NameIDPolicy format: emailAddress
3. Assertions must be signed

**Time to Complete:** ~1 hour

---

### 1.2 Enable SAML Strict Mode

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Require SAML authentication for all users.

#### ClickOps Implementation

**Step 1: Navigate to Login Methods**
1. Navigate to: **Organization Settings** → **Login Methods**
2. Review enabled authentication methods

**Step 2: Configure Strict Mode**
1. Set Password login: **Disabled**
2. Set Google login: **Disabled**
3. Set SAML login: **Enabled by Default**

**Step 3: Configure User Overrides**
1. Allow per-user overrides if needed
2. Configure individual exceptions carefully

---

### 1.3 Configure Session Security

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout and security settings.

#### ClickOps Implementation

**Step 1: Configure Session Duration**
1. Navigate to: **Organization Settings** → **Security**
2. Set **Maximum session duration**
3. Applies to all new web sessions

**Step 2: Configure Idle Timeout**
1. Enable **Idle time session timeout**
2. Users signed out after 30 minutes inactivity

---

## 2. Access Controls

### 2.1 Configure Role-Based Access Control

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Datadog's RBAC model.

#### ClickOps Implementation

**Step 1: Review Managed Roles**
1. Navigate to: **Organization Settings** → **Roles**
2. Review default managed roles:
   - **Admin:** Full access
   - **Standard:** Read/write on assets
   - **Read Only:** Read data only

**Step 2: Create Custom Roles**
1. Click **Create Role**
2. Configure specific permissions
3. Pay attention to sensitive permissions

**Step 3: Review Sensitive Permissions**
1. Sensitive permissions are flagged in UI
2. Review carefully before assigning

---

### 2.2 Limit Admin Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### ClickOps Implementation

**Step 1: Inventory Admin Users**
1. Navigate to: **Organization Settings** → **Users**
2. Filter by Admin role
3. Document all admin accounts

**Step 2: Apply Least Privilege**
1. Limit Admin to 2-3 users
2. Remove unnecessary admin access
3. Use custom roles for specific needs

---

## 3. API & Key Security

### 3.1 Secure API Keys

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure Datadog API keys used for data ingestion.

#### ClickOps Implementation

**Step 1: Review API Keys**
1. Navigate to: **Organization Settings** → **API Keys**
2. Review all existing keys
3. Identify purpose of each key

**Step 2: Implement Key Management**
1. Create purpose-specific keys
2. Name keys descriptively
3. Remove unused keys

**Step 3: Secure Key Storage**
1. Store keys in secret manager
2. Use environment variables
3. Never commit to code

---

### 3.2 Secure Application Keys

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure application keys used for API access.

#### ClickOps Implementation

**Step 1: Review Application Keys**
1. Navigate to: **Organization Settings** → **Application Keys**
2. Application keys inherit user permissions

**Step 2: Configure Key Scopes**
1. Create keys with limited scopes
2. Grant minimum required permissions

**Step 3: Rotate Keys Regularly**
1. Establish rotation schedule (90 days)
2. Update integrations before deleting

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logs

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Monitor administrative and security events.

#### ClickOps Implementation

**Step 1: Access Audit Trail**
1. Navigate to: **Organization Settings** → **Audit Trail**
2. Review logged events

**Step 2: Configure Alerts**
1. Create monitors for audit events
2. Alert on sensitive operations

**Step 3: Export Logs**
1. Export audit logs for retention
2. Integrate with SIEM

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Datadog Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | SSO/SAML | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [2.1](#21-configure-role-based-access-control) |
| CC6.6 | Session security | [1.3](#13-configure-session-security) |
| CC6.7 | Key security | [3.1](#31-secure-api-keys) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logs) |

### NIST 800-53 Rev 5 Mapping

| Control | Datadog Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-6 | Least privilege | [2.1](#21-configure-role-based-access-control) |
| SC-12 | Key management | [3.1](#31-secure-api-keys) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logs) |

---

## Appendix A: References

**Official Datadog Documentation:**
- [Trust Hub](https://www.datadoghq.com/trust/)
- [Trust Center (SafeBase)](https://trust.datadoghq.com/)
- [Safety Center / Hardening](https://docs.datadoghq.com/account_management/safety_center/)
- [Single Sign On With SAML](https://docs.datadoghq.com/account_management/saml/)
- [Access Control (RBAC)](https://docs.datadoghq.com/account_management/rbac/)
- [How to Set Up RBAC for Logs](https://docs.datadoghq.com/logs/guide/logs-rbac/)
- [Datadog Security](https://docs.datadoghq.com/security/)
- [Role Permissions](https://docs.datadoghq.com/account_management/rbac/permissions/)
- [Privacy at Datadog](https://www.datadoghq.com/privacy/)

**API & Developer Documentation:**
- [REST API Reference](https://docs.datadoghq.com/api/latest/)
- [Product Documentation](https://docs.datadoghq.com/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018, ISO 27701 — via [Trust Center](https://trust.datadoghq.com/)
- HIPAA-compliant Log Management available
- CSA Security, Trust & Assurance Registry (STAR) registered
- Annual penetration testing by NCC Group

**Security Incidents:**
- No major public security incidents identified affecting the Datadog platform directly.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, RBAC, and key security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
