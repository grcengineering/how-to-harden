---
layout: guide
title: "Webex Hardening Guide"
vendor: "Webex"
slug: "webex"
tier: "2"
category: "Productivity"
description: "Enterprise collaboration hardening for Cisco Webex including meeting security, SSO configuration, and admin controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Cisco Webex is a leading enterprise collaboration platform providing video conferencing, messaging, and calling for **millions of users** worldwide. As a critical communication tool handling sensitive business discussions and data, Webex security configurations directly impact confidentiality and compliance with data protection requirements.

### Intended Audience
- Security engineers managing collaboration platforms
- IT administrators configuring Webex
- GRC professionals assessing communication security
- Meeting administrators managing site settings

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Webex Control Hub and Site Administration security including meeting security, SSO, user management, and data protection.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Meeting Security](#2-meeting-security)
3. [Admin & Site Security](#3-admin--site-security)
4. [Data Protection](#4-data-protection)
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
Configure SAML SSO to centralize authentication for Webex applications.

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Control Hub** → **Management** → **Organization Settings** → **Authentication**
2. Click **Modify** for SSO configuration

**Step 2: Configure SAML**
1. Select **Integrate a 3rd-party identity provider**
2. Download Webex metadata
3. Configure IdP with Webex metadata
4. Upload IdP metadata to Webex

**Step 3: Configure IdP Application**
1. Create SAML application in your IdP
2. Webex supports SAML 2.0 and OAuth 2.0
3. Configure attribute mappings
4. Assign users/groups

**Step 4: Test and Enable**
1. Test SSO authentication
2. Verify user provisioning works
3. Enable SSO enforcement

**Time to Complete:** ~1 hour

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Webex users.

#### ClickOps Implementation

**Step 1: Enable Organization MFA**
1. Navigate to: **Control Hub** → **Management** → **Organization Settings**
2. Scroll to **Authentication** section
3. Enable **Require multi-factor authentication**
4. This makes MFA mandatory for all users

**Step 2: Configure via IdP (Recommended)**
1. Enable MFA in your identity provider
2. All SSO users subject to IdP MFA policies
3. Use phishing-resistant methods for admins

---

### 1.3 Configure User Provisioning

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure automatic user provisioning and deprovisioning.

#### ClickOps Implementation

**Step 1: Configure SCIM Provisioning**
1. Navigate to: **Control Hub** → **Users** → **Directory Sync**
2. Configure directory sync:
   - Okta
   - Azure Active Directory
   - Other SCIM providers

**Step 2: Configure Synchronization**
1. Map user attributes
2. Configure group synchronization
3. Enable automatic deprovisioning

**Step 3: Test Provisioning**
1. Create test user in IdP
2. Verify user appears in Webex
3. Test deprovisioning

---

## 2. Meeting Security

### 2.1 Configure Meeting Passwords

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Require passwords for all Webex meetings.

#### Rationale
**Why This Matters:**
- Prevents unauthorized meeting access
- Protects against meeting bombing
- Required for compliance

#### ClickOps Implementation

**Step 1: Configure Site Password Settings**
1. Navigate to: **Control Hub** → **Services** → **Meeting** → **Sites**
2. Select your site → **Configure Site**
3. Navigate to **Common Settings** → **Security**

**Step 2: Enable Password Requirements**
1. Enable **Require meeting password**
2. Configure password complexity
3. Enable **Require password when joining by phone**

**Step 3: Apply to All Meeting Types**
1. Apply to scheduled meetings
2. Apply to Personal Room meetings
3. Apply to PMR meetings

---

### 2.2 Configure Meeting Lock and Lobby

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-3 |

#### Description
Configure automatic meeting lock and lobby controls.

#### ClickOps Implementation

**Step 1: Configure Auto-Lock**
1. Navigate to: **Site Settings** → **Security**
2. Configure **Automatically lock meetings**:
   - Lock after: 5 minutes (recommended)
   - Options: 0, 5, 10, 15, or 20 minutes

**Step 2: Configure Lobby Behavior**
1. Configure **When meeting is locked**:
   - **Everyone waits in lobby** (recommended)
   - Or **No one can join**
2. Configure host notification

**Step 3: Configure Guest Access**
1. Control unauthenticated guest access
2. Require sign-in for external participants
3. Configure lobby hold time

---

### 2.3 Require Authentication for Meetings

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Require users to sign in before joining meetings.

#### ClickOps Implementation

**Step 1: Enable Sign-In Requirement**
1. Navigate to: **Site Settings** → **Security**
2. Enable **Require sign-in when joining meetings**
3. This prompts all participants for credentials

**Step 2: Configure Host Requirements**
1. Require hosts to be signed in
2. Require attendees to be signed in (L3)
3. Allow exceptions for external guests if needed

---

### 2.4 Configure Content Sharing Controls

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control what content can be shared in meetings.

#### ClickOps Implementation

**Step 1: Configure Sharing Permissions**
1. Navigate to: **Site Settings** → **Common Settings**
2. Configure sharing options:
   - Screen sharing permissions
   - Application sharing
   - File transfer capabilities

**Step 2: Configure Host Controls**
1. Allow hosts to disable participant sharing
2. Configure annotation permissions
3. Set default sharing preferences

---

## 3. Admin & Site Security

### 3.1 Limit Administrator Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Minimize administrator accounts to reduce risk.

#### Rationale
**Why This Matters:**
- Cisco recommends keeping administrators to minimum
- Fewer admins means fewer opportunities for errors
- Reduces blast radius of compromised accounts

#### ClickOps Implementation

**Step 1: Review Administrators**
1. Navigate to: **Control Hub** → **Users** → Filter by admin roles
2. Review all administrator accounts
3. Identify unnecessary admin access

**Step 2: Implement Role-Based Access**
1. Use granular admin roles:
   - Full Administrator
   - Site Administrator
   - User Administrator
   - Read-only Administrator
2. Assign minimum required role

**Step 3: Regular Access Reviews**
1. Quarterly review of admin access
2. Remove departed employees
3. Document business justification

---

### 3.2 Configure Enterprise Mobility Management

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.7 |
| NIST 800-53 | AC-19 |

#### Description
Configure EMM for mobile device security.

#### ClickOps Implementation

**Step 1: Enable EMM Integration**
1. Navigate to: **Control Hub** → **Organization Settings** → **Device Management**
2. Configure EMM/MDM integration:
   - Microsoft Intune
   - VMware Workspace ONE
   - Other AppConfig providers

**Step 2: Configure App Protection**
1. Prevent copy/paste from Webex app
2. Prevent screenshots
3. Control file sharing destinations

---

### 3.3 Configure Audit Tracking

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor administrative audit logs.

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Control Hub** → **Management** → **Troubleshooting** → **Audit**
2. Review admin actions
3. Filter by user, date, or action

**Step 2: Export Logs**
1. Export logs for SIEM integration
2. Configure REST API access for automation
3. Set up regular exports

**Key Events to Monitor:**
- Admin login events
- Configuration changes
- User provisioning/deprovisioning
- Security setting modifications

---

## 4. Data Protection

### 4.1 Configure Encryption Settings

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-8, SC-28 |

#### Description
Verify and configure encryption for data protection.

#### Webex Encryption Features
1. **End-to-End Encryption (E2E):** Messages encrypted before reaching servers
2. **TLS 1.2+:** All data in transit encrypted
3. **Zero-Trust Architecture:** Standards-based encryption

#### ClickOps Implementation

**Step 1: Enable E2E Encryption**
1. Navigate to: **Control Hub** → **Services** → **Messaging**
2. Enable end-to-end encryption where available
3. Configure for sensitive spaces

**Step 2: Configure Meeting Encryption**
1. Enable end-to-end encryption for meetings
2. Note: Some features may be limited with E2E

---

### 4.2 Configure Data Loss Prevention

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Configure DLP controls for data protection.

#### Rationale
**Why This Matters:**
- Webex offers awareness of data loss risks
- Presence of external participants shown
- Integration with third-party DLP tools

#### ClickOps Implementation

**Step 1: Configure External Participant Indicators**
1. Enable external participant indicators
2. Users see when external participants join
3. Visual cues for sensitive discussions

**Step 2: Configure DLP Integration**
1. Navigate to: **Control Hub** → **Apps** → **Compliance**
2. Configure third-party DLP integration
3. Monitor for policy violations

**Step 3: Configure Retention**
1. Set message retention policies
2. Configure eDiscovery access
3. Enable legal holds

---

### 4.3 Configure Pro Pack Features

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Configure Pro Pack for advanced security controls.

#### Prerequisites
- [ ] Webex Pro Pack license

#### ClickOps Implementation

**Step 1: Configure File Sharing Controls**
1. Navigate to: **Control Hub** → **Organization Settings**
2. Configure file sharing restrictions
3. Control sharing destinations

**Step 2: Configure Advanced Compliance**
1. Enable eDiscovery
2. Configure extended retention
3. Enable compliance exports

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Webex Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Admin controls | [3.1](#31-limit-administrator-access) |
| CC6.6 | Meeting security | [2.1](#21-configure-meeting-passwords) |
| CC6.7 | Encryption | [4.1](#41-configure-encryption-settings) |
| CC7.2 | Audit logging | [3.3](#33-configure-audit-tracking) |

### NIST 800-53 Rev 5 Mapping

| Control | Webex Control | Guide Section |
|---------|---------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | MFA | [1.2](#12-enforce-multi-factor-authentication) |
| AC-3 | Meeting controls | [2.2](#22-configure-meeting-lock-and-lobby) |
| SC-8 | Encryption | [4.1](#41-configure-encryption-settings) |
| AU-2 | Audit logging | [3.3](#33-configure-audit-tracking) |

---

## Appendix A: References

**Official Cisco Documentation:**
- [Cisco Trust Portal](https://trustportal.cisco.com/c/r/ctp/home.html)
- [Webex Trusted Platform](https://www.cisco.com/c/en/us/about/trust-center/webex.html)
- [Webex Help Center](https://help.webex.com/)
- [Webex Compliance and Certifications](https://help.webex.com/en-us/article/pdz31w/Webex-Compliance-and-Certifications)
- [Best Practices for Secure Meetings: Site Administration](https://help.webex.com/en-us/article/v5rgi1/Cisco-Webex-Best-Practices-for-Secure-Meetings-Site-Administration)
- [Best Practices for Secure Meetings: Control Hub](https://help.webex.com/en-us/article/ov50hy/Webex-best-practices-for-secure-meetings:-Control-Hub)
- [Webex Security White Paper](https://www.cisco.com/c/en/us/products/collateral/conferencing/webex-meeting-center/white-paper-c11-737588.html)
- [Webex Hardening Guide](https://www.cisco.com/c/en/us/td/docs/voice_ip_comm/cloudCollaboration/wbxt/hardening-guide/webex-hardening-guide.html)

**API Documentation:**
- [Webex Developer Portal](https://developer.webex.com/docs/getting-started)
- [Webex REST API Reference](https://developer.webex.com/docs/api/getting-started)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO 27001:2013, ISO 27017:2015, ISO 27018:2019, ISO 27701:2019, EU Cloud Code of Conduct (Level 3) -- via [Cisco Trust Portal](https://trustportal.cisco.com/c/r/ctp/home.html)

**Security Incidents:**
- **May 2024 -- German Government Meeting Metadata Exposure:** An IDOR vulnerability in Cisco Webex allowed threat actors to access meeting metadata (topics, hosts, dates) by incrementing meeting URL numbers. Sensitive meetings of German government officials and European defense/tech companies were exposed. Meeting passwords and participant lists were not accessible. The flaw was fully patched by May 28, 2024.
- **March 2024 -- German Military Meeting Eavesdropping:** Russia-linked actors intercepted a German military Webex meeting discussing Ukraine support, attributed to participants joining via unsecured phone lines rather than a Webex platform vulnerability.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, meeting security, and data protection | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
