---
layout: guide
title: "ServiceNow Hardening Guide"
vendor: "ServiceNow"
slug: "servicenow"
tier: "1"
category: "IT Operations"
description: "IT service management platform hardening for ServiceNow including SSO configuration, Security Center, and high-security plugins"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

ServiceNow is a leading IT service management and business workflow platform used by **thousands of enterprises** worldwide. As a platform managing critical IT operations and business processes, ServiceNow security configurations directly impact operational integrity.

### Intended Audience
- Security engineers managing ITSM platforms
- IT administrators configuring ServiceNow
- GRC professionals assessing IT operations security
- Platform administrators managing instance security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers ServiceNow instance security including SAML SSO, Security Center, high-security plugins, and RBAC.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Security Center & Hardening](#2-security-center--hardening)
3. [Access Controls](#3-access-controls)
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
Configure SAML SSO to centralize authentication for ServiceNow users.

#### Rationale
**Why This Matters:**
- ServiceNow recommends SSO with SAML or OIDC
- Enables organizational MFA enforcement
- Required for enterprise security

#### Prerequisites
- [ ] ServiceNow admin access
- [ ] SAML 2.0 or OIDC compatible IdP
- [ ] Multi-Provider SSO plugin activated

#### ClickOps Implementation

**Step 1: Activate Multi-Provider SSO**
1. Navigate to: **System Definition** → **Plugins**
2. Search for Multi-Provider SSO
3. Activate plugin if not enabled

**Step 2: Create SAML Configuration**
1. Navigate to: **Multi-Provider SSO** → **Identity Providers**
2. Click **New**
3. Select **SAML** as the type

**Step 3: Configure IdP Settings**
1. Enter IdP metadata
2. Use your own certificates (recommended)
3. FIPS mode requires separate Encryption and Signing certificates

**Time to Complete:** ~2 hours

---


{% include pack-code.html vendor="servicenow" section="1.1" %}

### 1.2 Configure Account Recovery Administrator

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure Account Recovery (ACR) administrator for SSO fallback.

#### Rationale
**Why This Matters:**
- ACR provides fallback when SSO fails
- Must be registered before SSO activation

#### ClickOps Implementation

**Step 1: Register ACR Administrator**
1. Before enabling SSO, register ACR admin
2. Navigate to: **System Security** → **Account Recovery**

**Step 2: Configure ACR Settings**
1. Enable MFA for ACR users
2. Restrict ACR to authorized personnel only
3. Document ACR procedures

---

### 1.3 Enable Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Enforce MFA for all authentication methods.

#### ClickOps Implementation

**Step 1: Verify MFA Settings**
1. MFA enabled by default for local logins
2. Navigate to: **System Security** → **Multi-factor Authentication**

**Step 2: Configure via IdP (SSO)**
1. Enable MFA in identity provider
2. Use phishing-resistant methods for admins (PIV/CAC, FIDO2)

---

## 2. Security Center & Hardening

### 2.1 Configure Security Center

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Use Security Center to monitor and improve instance security.

#### ClickOps Implementation

**Step 1: Access Security Center**
1. Navigate to: **Security Center**
2. Review overall security score

**Step 2: Review Hardening Settings**
1. Review hardening compliance score
2. Determine alignment with SSC recommendations

**Step 3: Address Findings**
1. Test fixes in sub-production first
2. Document accepted risks

---

### 2.2 Enable High-Security Plugins

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Activate high-security plugins for enhanced protection.

#### ClickOps Implementation

**Step 1: Verify Plugin Status**
1. Navigate to: **System Definition** → **Plugins**
2. Search for high-security plugins

**Step 2: Enable High-Security Settings**
1. Plugin enables:
   - Centralized security settings
   - Security administrator role
   - Default deny for ACLs

---


{% include pack-code.html vendor="servicenow" section="2.2" %}

## 3. Access Controls

### 3.1 Configure Role-Based Access Control

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using ServiceNow's role model.

#### ClickOps Implementation

**Step 1: Review Role Structure**
1. Navigate to: **User Administration** → **Roles**
2. Review role hierarchy

**Step 2: Apply Least Privilege**
1. Create custom roles for specific functions
2. Avoid over-assigning admin roles
3. Use role contains for hierarchies

**Step 3: Configure ACLs**
1. Use default deny (high-security plugin)
2. Create explicit allows

---

### 3.2 Limit Admin Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### ClickOps Implementation

**Step 1: Inventory Admin Users**
1. Navigate to: **User Administration** → **Users**
2. Filter by admin roles

**Step 2: Apply Least Privilege**
1. Limit admin to 2-3 users
2. Use security_admin for security tasks

---


{% include pack-code.html vendor="servicenow" section="3.2" %}

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

**Step 1: Review Audit Configuration**
1. Navigate to: **System Logs** → **Audit**
2. Verify auditing enabled

**Step 2: Configure Audit Policies**
1. Audit critical tables
2. Audit configuration changes
3. Audit user management

**Step 3: Monitor Audit Logs**
1. Create audit dashboards
2. Set up alerts for suspicious activity

---


{% include pack-code.html vendor="servicenow" section="4.1" %}

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | ServiceNow Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [3.1](#31-configure-role-based-access-control) |
| CC7.1 | Security Center | [2.1](#21-configure-security-center) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | ServiceNow Control | Guide Section |
|---------|-------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | MFA | [1.3](#13-enable-multi-factor-authentication) |
| AC-6 | Least privilege | [3.1](#31-configure-role-based-access-control) |
| CM-6 | Security hardening | [2.2](#22-enable-high-security-plugins) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: References

**Official ServiceNow Documentation:**
- [ServiceNow Documentation](https://docs.servicenow.com/)
- [ServiceNow Security Best Practices Guide](https://www.servicenow.com/content/dam/servicenow-assets/public/en-us/doc-type/resource-center/white-paper/instance-security-best-practice.pdf)
- [Security Center Hardening](https://www.servicenow.com/community/developer-blog/servicenow-security-hardening-security-center/ba-p/2982684)
- [Instance Security Hardening Reference](https://www.servicenow.com/docs/bundle/washingtondc-platform-security/page/administer/security/reference/security-best-practices-instance-security-hardening.html)
- [SAML 2.0 Configuration](https://www.servicenow.com/docs/r/washingtondc/platform-security/authentication/t_CreateASAML2Upd1SSOConfigMultiSSO.html)

**API & Developer Resources:**
- [ServiceNow Developer Reference](https://developer.servicenow.com/dev.do#!/reference)

**Trust & Compliance:**
- [ServiceNow Trust and Compliance Center](https://www.servicenow.com/company/trust.html)
- [ServiceNow TrustShare Certifications](https://trust.servicenow.com/certifications)
- SOC 1 Type II, SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018, ISO 27701, ISO 9001, ISO 22301, ISO 42001 -- via [ServiceNow Compliance](https://www.servicenow.com/company/trust/compliance.html)

**Security Incidents:**
- **BodySnatcher / CVE-2025-12420 (October 2025):** A critical vulnerability in the ServiceNow Virtual Agent API and Now Assist AI Agents allowed unauthenticated attackers to impersonate any user (including admins) using only an email address, bypassing MFA and SSO. Patched by ServiceNow on October 30, 2025. No evidence of exploitation in the wild.
- **Template Injection CVEs (May 2024):** Three vulnerabilities (CVE-2024-4879, CVE-2024-5178, CVE-2024-5217) were patched same day of disclosure but saw in-the-wild exploitation attempts across 6,000+ sites before patching was complete, primarily targeting financial services.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, Security Center, and access controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
