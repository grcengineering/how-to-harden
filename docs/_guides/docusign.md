---
layout: guide
title: "DocuSign Hardening Guide"
vendor: "DocuSign"
slug: "docusign"
tier: "2"
category: "Business Applications"
description: "eSignature platform hardening for DocuSign including SSO configuration, session security, and admin controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

DocuSign is the leading eSignature platform used by **over 1 million customers** worldwide for digital agreements, contracts, and document workflows. As a repository for sensitive business documents and legally binding agreements, DocuSign security configurations directly impact document integrity and regulatory compliance.

### Intended Audience
- Security engineers managing business applications
- IT administrators configuring DocuSign Enterprise
- GRC professionals assessing document security
- Legal/compliance teams managing agreement workflows

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers DocuSign eSignature security configurations including admin tools, SSO, security settings, and compliance features.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Security Settings](#2-security-settings)
3. [Admin Controls](#3-admin-controls)
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
Configure SAML SSO to centralize authentication and enforce organizational security policies.

#### Rationale
**Why This Matters:**
- Enterprise SSO ties DocuSign access to corporate identity
- Enables enforcement of MFA through IdP
- Supports just-in-time provisioning
- Critical for SOC 2 and ISO 27001 compliance

#### Prerequisites
- [ ] DocuSign Enterprise plan
- [ ] Domain verified in DocuSign Admin
- [ ] SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Configuration**
1. Navigate to: **DocuSign Admin** → **Identity Providers**
2. Click **Add Identity Provider**
3. Select SAML 2.0

**Step 2: Configure IdP Settings**
1. Enter IdP metadata:
   - Entity ID
   - SSO URL
   - Certificate
2. Download DocuSign SP metadata for IdP configuration

**Step 3: Configure IdP Application**
1. Create SAML application in IdP
2. Configure attribute mappings:
   - Email (required)
   - First name, last name (optional)
3. Assign users/groups

**Step 4: Enforce SSO**
1. Test SSO authentication
2. Check **Require all users to login with SSO only**
3. Configure backup admin access

**Time to Complete:** ~1 hour

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all DocuSign users.

#### ClickOps Implementation

**Step 1: Enable MFA via SSO**
1. Configure MFA enforcement in your IdP
2. All SSO users will require MFA
3. Verify MFA is enforced before login

**Step 2: Native DocuSign MFA (if not using SSO)**
1. Navigate to: **Admin** → **Security Settings**
2. Enable two-factor authentication
3. Configure allowed methods

**Step 3: Session Control**
1. Configure conditional access policies in IdP
2. Enable session control for data protection
3. Configure re-authentication requirements

---

### 1.3 Configure User Provisioning

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure automated user provisioning and deprovisioning.

#### ClickOps Implementation

**Step 1: Enable JIT Provisioning**
1. Configure SSO with JIT provisioning enabled
2. User accounts created on first login
3. Roles assigned based on IdP attributes

**Step 2: Configure SCIM (if available)**
1. Navigate to: **Admin** → **User Management** → **SCIM**
2. Generate SCIM token
3. Configure IdP SCIM integration

**Step 3: Configure Automatic Deprovisioning**
1. Ensure disabled IdP users lose DocuSign access
2. Test deprovisioning workflow
3. Document offboarding procedures

---

## 2. Security Settings

### 2.1 Configure Session Security

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout and security settings.

#### ClickOps Implementation

**Step 1: Configure Session Timeout**
1. Navigate to: **Admin** → **Security Settings**
2. Configure session settings:
   - Idle timeout: 15-30 minutes
   - Maximum session: 8 hours
3. Apply to all users

**Step 2: Configure Fixed Web Session Length**
1. Set fixed session length if needed
2. Configure re-authentication for sensitive operations

---

### 2.2 Configure Document Security

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-8, SC-28 |

#### Description
Configure document encryption and security settings.

#### ClickOps Implementation

**Step 1: Verify Encryption**
1. DocuSign uses AES 256-bit encryption at rest
2. TLS 1.2+ for data in transit
3. Verify certificate-based signatures

**Step 2: Configure Access Permissions**
1. Navigate to: **Admin** → **Permissions**
2. Configure who can:
   - Send envelopes
   - Access templates
   - View audit trails
3. Apply least privilege

**Step 3: Configure Retention**
1. Set document retention policies
2. Configure automatic purging if needed
3. Comply with legal holds

---

### 2.3 Configure Envelope Security

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-8 |

#### Description
Configure enhanced security for sensitive envelopes.

#### ClickOps Implementation

**Step 1: Configure Signing Authentication**
1. Navigate to: **Account** → **Signing Settings**
2. Configure signer authentication:
   - Email verification
   - Access code
   - Phone authentication
   - SMS verification
   - Knowledge-based authentication

**Step 2: Configure Envelope Expiration**
1. Set default expiration periods
2. Configure reminders
3. Enable notifications

---

## 3. Admin Controls

### 3.1 Implement Role-Based Access Control

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure role-based permissions for DocuSign administration.

#### ClickOps Implementation

**Step 1: Review Permission Profiles**
1. Navigate to: **Admin** → **Permission Profiles**
2. Review available profiles:
   - Account Administrator
   - Sender
   - Viewer
3. Create custom profiles as needed

**Step 2: Assign Appropriate Roles**
1. Limit Account Administrator to essential personnel
2. Use Sender for standard users
3. Use Viewer for read-only access

**Step 3: Configure Permission Settings**
1. Configure granular permissions:
   - Template management
   - User management
   - Branding settings
   - API access

---

### 3.2 Centralize Admin Management

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Use DocuSign Admin Tools for centralized management across accounts.

#### ClickOps Implementation

**Step 1: Configure Admin Tools**
1. Navigate to: **DocuSign Admin**
2. Link multiple accounts if applicable
3. Configure centralized policies

**Step 2: Configure Bulk Operations**
1. Use bulk user management
2. Apply consistent security settings
3. Manage SSO centrally

---

### 3.3 Configure API Security

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure DocuSign API access and integrations.

#### ClickOps Implementation

**Step 1: Manage Integration Keys**
1. Navigate to: **Apps and Keys**
2. Review existing integration keys
3. Remove unused integrations

**Step 2: Configure API Permissions**
1. Grant minimum required scopes
2. Use OAuth 2.0 authentication
3. Rotate keys regularly

**Step 3: Monitor API Usage**
1. Review API call logs
2. Alert on unusual patterns
3. Set rate limiting

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Trails

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable comprehensive audit logging for compliance.

#### ClickOps Implementation

**Step 1: Access Audit Trails**
1. Navigate to: **Reports** → **Audit Trail**
2. Review envelope audit certificates
3. Export for compliance documentation

**Step 2: Configure Admin Activity Logs**
1. Review admin actions
2. Track configuration changes
3. Monitor user management

**Key Events to Monitor:**
- User login events
- Envelope sends and completions
- Template changes
- Admin configuration changes
- Permission modifications

---

### 4.2 Configure Compliance Features

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | CA-7 |

#### Description
Enable compliance-specific features for regulated industries.

#### ClickOps Implementation

**Step 1: Enable Advanced Audit**
1. Configure advanced audit features
2. Enable tamper-evident logging
3. Configure certificate of completion

**Step 2: Configure Retention**
1. Set retention policies per document type
2. Configure legal holds
3. Enable compliance exports

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | DocuSign Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [3.1](#31-implement-role-based-access-control) |
| CC6.7 | Encryption | [2.2](#22-configure-document-security) |
| CC7.2 | Audit trails | [4.1](#41-configure-audit-trails) |
| CC7.3 | Compliance features | [4.2](#42-configure-compliance-features) |

### NIST 800-53 Rev 5 Mapping

| Control | DocuSign Control | Guide Section |
|---------|------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | MFA | [1.2](#12-enforce-multi-factor-authentication) |
| AC-2 | User provisioning | [1.3](#13-configure-user-provisioning) |
| AC-6 | Least privilege | [3.1](#31-implement-role-based-access-control) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-trails) |

---

## Appendix A: Plan Compatibility

| Feature | Personal | Standard | Business Pro | Enterprise |
|---------|----------|----------|--------------|------------|
| SSO | ❌ | ❌ | ❌ | ✅ |
| MFA | Basic | Basic | Basic | ✅ |
| Admin Tools | ❌ | ❌ | ✅ | ✅ |
| Advanced Authentication | ❌ | ❌ | ✅ | ✅ |
| API Access | ❌ | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official DocuSign Documentation:**
- [Security Settings Guide](https://support.docusign.com/guides/ndse-admin-guide-security-settings)
- [SSO Configuration Guide](https://support.docusign.com/s/document-item?bundleId=rrf1583359212854&topicId=ozd1583359139126.html)
- [Security Recommendations](https://support.docusign.com/s/document-item?bundleId=ieh1606952453299&topicId=swt1606952443828.html)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, security settings, and admin controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
