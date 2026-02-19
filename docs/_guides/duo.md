---
layout: guide
title: "Cisco Duo Security Hardening Guide"
vendor: "Duo Security"
slug: "duo"
tier: "2"
category: "Identity"
description: "Multi-factor authentication hardening for Cisco Duo, admin policies, and bypass protection"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Cisco Duo is a leading multi-factor authentication platform protecting **over 100 million users** globally. As a critical security control for application access, Duo configurations directly impact organizational security posture. Misconfigured policies, excessive bypass access, or unmonitored inactive accounts can undermine MFA protection.

### Intended Audience
- Security engineers managing Duo deployments
- IT administrators configuring MFA policies
- GRC professionals assessing authentication controls
- Third-party risk managers evaluating MFA solutions

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Cisco Duo security configurations including admin policies, application policies, user management, device trust, and monitoring.

---

## Table of Contents

1. [Admin Account Security](#1-admin-account-security)
2. [Authentication Policies](#2-authentication-policies)
3. [User Management](#3-user-management)
4. [Device Trust](#4-device-trust)
5. [Application Security](#5-application-security)
6. [Monitoring & Detection](#6-monitoring--detection)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Admin Account Security

### 1.1 Secure Admin Panel Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Secure Duo Admin Panel access with MFA, role-based access, and monitoring. Admin accounts are high-value targets for attackers.

#### Rationale
**Why This Matters:**
- Admin access allows policy changes that could bypass MFA
- Compromised admin accounts can disable protection entirely
- Admin actions should be audited and limited

#### Prerequisites
- [ ] Duo Admin Panel access
- [ ] Organization with defined admin roles

#### ClickOps Implementation

**Step 1: Audit Admin Accounts**
1. Navigate to: **Duo Admin Panel** → **Administrators**
2. Review all administrator accounts
3. Document accounts and assigned roles
4. Remove unnecessary admin access

**Step 2: Implement Role-Based Access**
1. Available roles:
   - **Owner:** Full access (limit to 1-2 accounts)
   - **Administrator:** Most settings except billing
   - **Application Manager:** Manage applications only
   - **User Manager:** Manage users only
   - **Read-Only:** View-only access
   - **Help Desk:** Limited support functions
2. Assign minimum required role per admin

**Step 3: Enable Admin MFA**
1. Navigate to: **Settings** → **Administrators**
2. Ensure **Require two-factor authentication** is enabled
3. Enforce strong authentication methods

**Time to Complete:** ~30 minutes

{% include pack-code.html vendor="duo" section="1.1" %}

---

### 1.2 Protect Admin Credentials

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Protect Duo integration keys, secret keys, and API credentials as highly sensitive secrets.

#### Rationale
**Why This Matters:**
- Integration Secret Key (skey) allows API access
- Compromised credentials enable policy bypass
- Leaked secrets can be abused for unauthorized access

#### Implementation

**Credential Security Guidelines:**
1. **Never share secret keys** via email or insecure channels
2. **Store secrets in secure vaults** (HashiCorp Vault, AWS Secrets Manager)
3. **Never commit secrets** to source control
4. **Rotate keys** if compromise is suspected
5. **Use environment variables** instead of hardcoded values

**Secret Key Handling:**

{% include pack-code.html vendor="duo" section="1.2" %}

---

## 2. Authentication Policies

### 2.1 Configure Global Policy

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Configure the Global Policy as the baseline security policy for all Duo-protected applications.

#### ClickOps Implementation

**Step 1: Access Global Policy**
1. Navigate to: **Policies** → **Global Policy**
2. Review current settings

**Step 2: Configure Authentication Policy**
1. Set **Authentication policy**: **Enforce MFA**
2. This ensures all users must complete two-factor authentication

**Step 3: Configure New User Policy**
1. Set **New user policy**: **Deny access** (recommended)
2. Or **Require enrollment** if self-enrollment is needed
3. **Never** set to "Allow access without 2FA" for production

**Time to Complete:** ~15 minutes

{% include pack-code.html vendor="duo" section="2.1" %}

---

### 2.2 Eliminate Bypass Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2 |

#### Description
Review and minimize bypass access that allows users to skip MFA. Bypass status should be temporary and monitored.

#### Rationale
**Why This Matters:**
- Users with Bypass status skip MFA entirely
- Bypass is intended for temporary troubleshooting only
- Excessive bypass undermines MFA investment
- Attackers target bypass accounts for persistent access

#### ClickOps Implementation

**Step 1: Audit Bypass Users**
1. Navigate to: **Users**
2. Filter by **Status: Bypass**
3. Review each bypass user:
   - Is bypass still needed?
   - Who approved bypass?
   - How long has bypass been active?

**Step 2: Remove Unnecessary Bypass**
1. Select bypass user
2. Change status to **Active**
3. Document removal

**Step 3: Configure Bypass Expiration**
1. When bypass is required, set expiration
2. Use shortest reasonable duration
3. Monitor for expiration

**Step 4: Review Group Bypass**
1. Check groups with bypass policies
2. Verify business justification
3. Consider per-user bypass instead

{% include pack-code.html vendor="duo" section="2.2" %}

---

### 2.3 Require Phishing-Resistant MFA

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(6) |

#### Description
Configure policies to require phishing-resistant authentication methods like WebAuthn (FIDO2) or Duo Verified Push.

#### Rationale
**Why This Matters:**
- Duo Push can be compromised via MFA fatigue attacks
- Verified Push requires user interaction (number matching)
- WebAuthn provides strongest phishing resistance

#### ClickOps Implementation

**Step 1: Enable Verified Push**
1. Navigate to: **Policies** → Edit policy
2. Under **Authentication methods**
3. Configure **Duo Push** settings:
   - Enable **Verified Duo Push** (requires number entry)

**Step 2: Require Strong Methods**
1. In policy, under **Authentication methods**
2. Restrict to strong methods:
   - **Duo Push with Verified Push**
   - **WebAuthn (Security Keys)**
   - **WebAuthn (Platform Authenticators)**
3. Consider disabling weaker methods:
   - SMS passcodes
   - Phone callback

**Step 3: Configure Per-Application**
1. For high-security applications
2. Create custom policy requiring WebAuthn only

{% include pack-code.html vendor="duo" section="2.3" %}

---

### 2.4 Configure Authorized Networks

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Configure authorized network policies to adjust MFA requirements based on network location while maintaining security.

#### ClickOps Implementation

**Step 1: Define Authorized Networks**
1. Navigate to: **Policies** → Edit policy
2. Under **Networks**
3. Add authorized IP ranges (corporate network, VPN)

**Step 2: Configure Network Behavior**
1. For authorized networks:
   - **Require MFA:** Always recommended
   - **Allow access without 2FA:** Only if risk-assessed
2. For unknown networks:
   - **Always require MFA**

**Important:** Authorized networks should reduce friction, not bypass security. Continue requiring MFA from trusted networks.

{% include pack-code.html vendor="duo" section="2.4" %}

---

## 3. User Management

### 3.1 Manage Inactive Accounts

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Identify and manage inactive Duo accounts to prevent account takeover and unauthorized access.

#### Rationale
**Why This Matters:**
- Inactive accounts can be taken over by attackers
- Accounts provisioned but never enrolled are high risk
- Regular cleanup reduces attack surface

#### ClickOps Implementation

**Step 1: Identify Inactive Users**
1. Navigate to: **Users**
2. Filter by:
   - **Status: Pending activation** (never enrolled)
   - **Last login:** More than 90 days ago

**Step 2: Review and Remediate**
1. For pending activation users:
   - Verify still employed
   - Resend enrollment or delete
2. For long-inactive users:
   - Verify still needed
   - Consider disabling until re-verification

**Step 3: Automate Cleanup**
1. Use Duo Admin API for automated reporting
2. Create process for regular review (monthly)

{% include pack-code.html vendor="duo" section="3.1" %}

---

### 3.2 Configure User Enrollment

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | IA-5 |

#### Description
Configure secure user enrollment processes that verify identity before granting MFA access.

#### ClickOps Implementation

**Step 1: Configure Enrollment Methods**
1. Navigate to: **Settings** → **Enrollment**
2. Configure enrollment options:
   - **Self-enrollment:** Via enrollment portal
   - **Admin enrollment:** Manual by administrator
   - **Directory sync:** Automated from AD/LDAP

**Step 2: Secure Enrollment Links**
1. Set enrollment link expiration (24-72 hours)
2. Send via verified email addresses
3. Monitor for unusual enrollment patterns

**Step 3: Verify Identity**
1. For high-security environments:
   - Require identity verification before enrollment
   - Use HR systems to validate user
   - Consider in-person enrollment for privileged users

{% include pack-code.html vendor="duo" section="3.2" %}

---

## 4. Device Trust

### 4.1 Configure Trusted Endpoints

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | AC-2(11) |

#### Description
Configure Duo's Trusted Endpoints feature to verify device compliance before granting access.

#### Prerequisites
- [ ] Duo Beyond or Duo Advantage plan
- [ ] Device management solution (Intune, JAMF, etc.)

#### ClickOps Implementation

**Step 1: Configure Device Management Integration**
1. Navigate to: **Trusted Endpoints**
2. Click **Add Integration**
3. Select your device management platform
4. Configure integration settings

**Step 2: Create Trusted Endpoint Policy**
1. Navigate to: **Policies**
2. Edit or create policy
3. Under **Devices**, configure:
   - **Require devices to be trusted**
   - **Block untrusted devices** or **Allow with warning**

{% include pack-code.html vendor="duo" section="4.1" %}

---

### 4.2 Monitor Device Registration

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 1.4 |
| NIST 800-53 | CM-8 |

#### Description
Monitor device registrations to detect suspicious activity that could indicate account compromise.

#### Rationale
**Why This Matters:**
- Attackers may register malicious devices after credential theft
- New device registration is a critical security event
- Anomalous registrations indicate potential compromise

#### Implementation
1. Enable alerts for new device registrations
2. Review authentication logs for registration events
3. Use Duo Trust Monitor (Advantage/Premier) for anomaly detection
4. Integrate with SIEM for correlation

{% include pack-code.html vendor="duo" section="4.2" %}

---

## 5. Application Security

### 5.1 Configure Application-Specific Policies

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4 |
| NIST 800-53 | AC-3 |

#### Description
Create application-specific policies with appropriate security controls based on application sensitivity.

#### ClickOps Implementation

**Step 1: Assess Applications**
1. Categorize applications by sensitivity:
   - **Critical:** Admin portals, financial systems
   - **High:** Customer data access, email
   - **Standard:** General business applications

**Step 2: Create Tiered Policies**
1. Navigate to: **Policies** → **New Policy**
2. Create policies for each tier:

**Critical Applications Policy:**
- New user policy: Deny access
- Authentication policy: Enforce MFA
- Authentication methods: WebAuthn only
- Authorized networks: Require MFA always

**Standard Applications Policy:**
- New user policy: Require enrollment
- Authentication policy: Enforce MFA
- Authentication methods: All enabled methods
- Authorized networks: Standard configuration

**Step 3: Apply Policies**
1. Navigate to: **Applications**
2. Select application
3. Under **Policy**, select appropriate policy

{% include pack-code.html vendor="duo" section="5.1" %}

---

### 5.2 Secure Windows Logon/RDP

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Configure Duo for Windows Logon and RDP with appropriate security settings.

#### ClickOps Implementation

**Step 1: Configure New User Policy**
1. Navigate to: **Applications** → Windows Logon
2. Set **New user policy**: **Deny access**
3. Users must be pre-enrolled before accessing Windows via Duo

**Step 2: Configure Offline Access**
1. Configure offline access settings:
   - **Enable offline access:** Based on requirements
   - **Offline access expiration:** 24-72 hours
   - **Number of offline logins:** Limited (5-10)

**Step 3: Configure Fail Mode**
1. Set **Fail mode** based on security vs. availability:
   - **Fail closed:** Block access if Duo unreachable (more secure)
   - **Fail open:** Allow access if Duo unreachable (more available)

{% include pack-code.html vendor="duo" section="5.2" %}

---

## 6. Monitoring & Detection

### 6.1 Enable Logging and Alerting

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-6 |

#### Description
Configure Duo logging and integrate with SIEM for security monitoring and incident investigation.

#### ClickOps Implementation

**Step 1: Access Logs**
1. Navigate to: **Reports** → **Authentication Log**
2. Review authentication events
3. Note failed authentications and bypass usage

**Step 2: Configure SIEM Integration**
1. Use Duo Admin API for log export
2. Configure log streaming to SIEM:
   - Splunk (Duo add-on available)
   - Azure Sentinel
   - Other SIEM via API

**Step 3: Enable Trust Monitor (Advantage/Premier)**
1. Navigate to: **Devices** → **Trust Monitor**
2. Enable anomaly detection
3. Configure alerting for suspicious activity

> **Note:** Trust Monitor will be replaced by Cisco Identity Intelligence after September 2025.

{% include pack-code.html vendor="duo" section="6.1" %}

---

### 6.2 Key Events to Monitor

| Event | Detection Use Case |
|-------|-------------------|
| Authentication denied | Failed MFA attempts |
| Bypass used | Policy bypass abuse |
| New device enrolled | Potential account takeover |
| Admin login | Administrative access |
| Policy changed | Unauthorized policy modification |
| User created/deleted | Account management |
| Fraud reported | User-reported compromise |

---

### 6.3 Implement Session Hijacking Protection

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | SC-23 |

#### Description
Configure Duo's session protection features to defend against session hijacking attacks that bypass MFA.

#### Rationale
**Why This Matters:**
- Session hijacking steals authenticated sessions
- Attackers bypass MFA by reusing stolen sessions
- Session protection secures post-authentication access

#### Implementation
1. Enable continuous authentication features
2. Configure session policies with appropriate timeouts
3. Enable re-authentication for sensitive actions
4. Monitor for session anomalies

{% include pack-code.html vendor="duo" section="6.3" %}

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Duo Control | Guide Section |
|-----------|-------------|---------------|
| CC6.1 | Admin MFA | [1.1](#11-secure-admin-panel-access) |
| CC6.1 | Enforce MFA | [2.1](#21-configure-global-policy) |
| CC6.2 | Role-based admin | [1.1](#11-secure-admin-panel-access) |
| CC6.6 | Bypass controls | [2.2](#22-eliminate-bypass-access) |
| CC7.2 | Logging | [6.1](#61-enable-logging-and-alerting) |

### NIST 800-53 Rev 5 Mapping

| Control | Duo Control | Guide Section |
|---------|-------------|---------------|
| IA-2 | MFA enforcement | [2.1](#21-configure-global-policy) |
| IA-2(6) | Phishing-resistant MFA | [2.3](#23-require-phishing-resistant-mfa) |
| AC-2 | User management | [3.1](#31-manage-inactive-accounts) |
| AC-6(1) | Admin privileges | [1.1](#11-secure-admin-panel-access) |
| AU-2 | Logging | [6.1](#61-enable-logging-and-alerting) |

---

## Appendix A: Plan Compatibility

| Feature | Duo Free | Duo Essentials | Duo Advantage | Duo Premier |
|---------|----------|----------------|---------------|-------------|
| MFA | ✅ (10 users) | ✅ | ✅ | ✅ |
| Verified Push | ❌ | ✅ | ✅ | ✅ |
| Trusted Endpoints | ❌ | ❌ | ✅ | ✅ |
| Trust Monitor | ❌ | ❌ | ✅ | ✅ |
| Risk-Based Auth | ❌ | ❌ | ❌ | ✅ |
| Admin API | ❌ | ✅ | ✅ | ✅ |

---

## Appendix B: References

**Official Cisco Duo Documentation:**
- [Cisco Trust Portal](https://trustportal.cisco.com/c/r/ctp/home.html)
- [Duo Security & Reliability](https://duo.com/support/security-and-reliability)
- [Duo Compliance](https://duo.com/support/security-and-reliability/compliance)
- [Duo Documentation](https://duo.com/docs)
- [Policy & Control](https://duo.com/docs/policy)
- [Windows Logon & RDP](https://duo.com/docs/rdp)

**API & Developer Documentation:**
- [Admin API](https://duo.com/docs/adminapi)
- [Auth API](https://duo.com/docs/authapi)

**Best Practices:**
- [MFA Enrollment Best Practices](https://duo.com/blog/best-practices-for-enrolling-users-in-mfa)
- [Phishing-Resistant MFA](https://duo.com/learn/phishing-resistant-mfa)

**Compliance Frameworks:**
- SOC 2, ISO 27001, ISO 27017, ISO 27018, PCI DSS — via [Duo Compliance](https://duo.com/support/security-and-reliability/compliance)
- Data centers in 9 countries with 99.999% availability target
- Regular independent third-party audits of infrastructure and operations

**Security Incidents:**
- **April 2024 Telephony Provider Breach:** An unnamed provider handling Duo SMS and VoIP MFA messages was compromised via phishing. The attacker accessed SMS/VoIP message logs (phone numbers, carriers, metadata) for approximately 1% of Duo customers between March 1-31, 2024. No message content was exposed.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with admin security, policies, and monitoring | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
