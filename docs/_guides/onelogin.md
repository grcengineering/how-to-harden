---
layout: guide
title: "OneLogin Hardening Guide"
vendor: "OneLogin"
slug: "onelogin"
tier: "1"
category: "Identity"
description: "Identity provider hardening for OneLogin including MFA policies, user security, and SmartFactor Authentication"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

OneLogin is a leading cloud identity and access management platform providing SSO and MFA to **thousands of enterprises** worldwide. As the authentication gateway for corporate applications, OneLogin security configurations directly impact access control for all integrated systems. Compromised identity providers can provide attackers with access to the entire SaaS ecosystem.

### Intended Audience
- Security engineers managing identity infrastructure
- IT administrators configuring OneLogin
- GRC professionals assessing IAM security
- Third-party risk managers evaluating identity providers

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers OneLogin administration console security, user policies, MFA configuration, and access controls.

---

## Table of Contents

1. [User Security Policies](#1-user-security-policies)
2. [Multi-Factor Authentication](#2-multi-factor-authentication)
3. [Admin & Access Controls](#3-admin--access-controls)
4. [Session & Network Security](#4-session--network-security)
5. [Monitoring & Compliance](#5-monitoring--compliance)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. User Security Policies

### 1.1 Configure Password Policy

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2 |
| NIST 800-53 | IA-5 |

#### Description
Configure password policies to enforce strong authentication requirements for OneLogin users.

#### ClickOps Implementation

**Step 1: Access User Policies**
1. Navigate to: **Security** → **Policies**
2. Select **Default policy** or create new policy

**Step 2: Configure Password Settings**
1. Configure password requirements:
   - **Minimum length:** 12+ characters (14+ for L2)
   - **Complexity requirements:** Uppercase, lowercase, numbers, symbols
   - **Password history:** Prevent reuse of last 10 passwords
   - **Password expiration:** 90 days (or disable for modern approach)
2. Configure lockout settings:
   - **Failed attempts:** 5 attempts
   - **Lockout duration:** 30 minutes
   - **Reset counter:** After 15 minutes

**Step 3: Apply Policy**
1. Assign policy to users or groups
2. Communicate changes to users
3. Monitor compliance

**Time to Complete:** ~20 minutes

---

### 1.2 Configure Session Controls

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout and activity controls to limit exposure from idle sessions.

#### ClickOps Implementation

**Step 1: Configure Session Timeout**
1. Navigate to: **Security** → **Policies** → Select policy
2. Configure session settings:
   - **Session timeout:** 8 hours (or less for L2)
   - **Idle timeout:** 15 minutes (L2: 5 minutes)
   - **Force re-authentication:** For sensitive apps

**Step 2: Configure Session Controls**
1. Enable **Single session enforcement** if required
2. Configure re-authentication for sensitive operations
3. Enable session termination on logout

---

### 1.3 Enable Self-Service Password Reset

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2 |
| NIST 800-53 | IA-5 |

#### Description
Configure secure self-service password reset to reduce helpdesk burden while maintaining security.

#### ClickOps Implementation

**Step 1: Enable Self-Service**
1. Navigate to: **Security** → **Policies** → Select policy
2. Enable **Self-service password reset**

**Step 2: Configure Reset Methods**
1. Configure recovery methods:
   - **Security questions:** 3+ questions required
   - **Email verification:** Send reset link
   - **SMS verification:** If enabled
2. Require MFA for password reset (recommended)

**Step 3: Set Security Questions**
1. Navigate to: **Settings** → **Security Questions**
2. Configure custom security questions
3. Require unique answers

---

## 2. Multi-Factor Authentication

### 2.1 Enforce MFA for All Users

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require multi-factor authentication for all users accessing OneLogin.

#### Rationale
**Why This Matters:**
- Single-factor authentication is insufficient for identity providers
- MFA prevents account takeover from credential theft
- Required for compliance with most frameworks

#### ClickOps Implementation

**Step 1: Configure Authentication Factors**
1. Navigate to: **Security** → **Authentication Factors**
2. Click **New Auth Factor**
3. Add desired factors:
   - **OneLogin Protect:** Push notification app (recommended)
   - **Google Authenticator:** TOTP app
   - **WebAuthn/FIDO2:** Hardware keys (most secure)
   - **SMS:** Not recommended but available
   - **Email:** Not recommended but available

**Step 2: Configure MFA Policy**
1. Navigate to: **Security** → **Policies** → Select policy
2. Enable **OTP Auth Required**
3. Configure MFA settings:
   - **Require at login:** Always
   - **Allowed factors:** Select approved factors
   - **Remember device:** 7-30 days (or never for L3)

**Step 3: Apply MFA Policy**
1. Apply policy to all users
2. Set grace period for enrollment
3. Monitor compliance

**Time to Complete:** ~30 minutes

---

### 2.2 Configure SmartFactor Authentication

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(13) |

#### Description
Enable SmartFactor Authentication for risk-based adaptive MFA.

#### Rationale
**Why This Matters:**
- Adaptive MFA uses machine learning to evaluate risk
- Low-risk logins can skip MFA step-up for better UX
- High-risk logins require additional verification
- Protects against brute force and phishing attacks

#### Prerequisites
- [ ] OneLogin Expert plan or higher

#### ClickOps Implementation

**Step 1: Enable SmartFactor**
1. Navigate to: **Security** → **Policies** → Select policy
2. Enable **SmartFactor Authentication**
3. Configure risk thresholds

**Step 2: Configure Risk Signals**
1. Configure risk assessment:
   - Login location
   - Device fingerprint
   - Time of access
   - Network reputation
2. Set response actions for risk levels:
   - **Low risk:** No additional MFA
   - **Medium risk:** Require MFA
   - **High risk:** Block and alert

**Step 3: Review and Tune**
1. Monitor SmartFactor decisions
2. Adjust thresholds based on false positives
3. Review blocked attempts

---

### 2.3 Require Phishing-Resistant MFA for Admins

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(6) |

#### Description
Require WebAuthn/FIDO2 hardware keys for administrator accounts.

#### ClickOps Implementation

**Step 1: Create Admin MFA Policy**
1. Navigate to: **Security** → **Policies**
2. Create new policy: `Admin MFA Policy`

**Step 2: Configure WebAuthn Requirement**
1. Configure MFA factors:
   - **WebAuthn/FIDO2:** Required
   - **Disable:** SMS, email, TOTP
2. Enable **Require phishing-resistant MFA**

**Step 3: Apply to Admins**
1. Create admin group if not exists
2. Assign `Admin MFA Policy` to admin group
3. Document hardware key distribution

---

## 3. Admin & Access Controls

### 3.1 Implement Delegated Administration

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Configure delegated administration to implement least privilege for admin access.

#### ClickOps Implementation

**Step 1: Review Admin Roles**
1. Navigate to: **Users** → **Roles**
2. Review built-in roles:
   - **Super user:** Full access (limit to 2-3)
   - **User admin:** User management
   - **App admin:** Application management
   - **Help desk:** Limited support access

**Step 2: Create Custom Roles**
1. Click **New Role**
2. Configure role permissions:
   - Name: `Tier 1 Support`
   - Permissions: Password reset, unlock accounts
3. Apply principle of least privilege

**Step 3: Assign Roles**
1. Assign appropriate roles to administrators
2. Document role assignments
3. Regular review of admin access

---

### 3.2 Configure IP Address Allowlisting

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17, SC-7 |

#### Description
Restrict access to OneLogin from approved IP addresses.

#### ClickOps Implementation

**Step 1: Configure IP Restrictions**
1. Navigate to: **Security** → **Policies** → Select policy
2. Enable **IP address restrictions**
3. Add allowed IP addresses/ranges:
   - Corporate network
   - VPN egress IPs
   - Trusted partner IPs

**Step 2: Configure Response**
1. Configure action for unauthorized IPs:
   - **Block access:** Deny login
   - **Require MFA:** Step-up authentication
   - **Alert:** Notify administrators

**Step 3: Test and Validate**
1. Test from allowed IPs
2. Verify blocked from unauthorized IPs
3. Document emergency procedures

---

### 3.3 Protect Privileged Accounts

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement additional protections for privileged administrator accounts.

#### ClickOps Implementation

**Step 1: Identify Privileged Accounts**
1. Navigate to: **Users** → Filter by admin roles
2. Document all privileged accounts
3. Verify business need for each

**Step 2: Apply Enhanced Protections**
1. Create dedicated policy for admins
2. Configure:
   - Shorter session timeout
   - Mandatory MFA at every login
   - IP restrictions (if possible)
   - Enhanced logging

**Step 3: Implement Separation of Duties**
1. Use separate accounts for admin vs. daily work
2. Require approval for privilege changes
3. Regular access reviews

---

## 4. Session & Network Security

### 4.1 Configure TLS Requirements

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | SC-8 |

#### Description
Ensure all OneLogin communications use strong TLS encryption.

#### Validation
1. Verify OneLogin portal uses TLS 1.2+
2. Check SAML connections use HTTPS
3. Validate API connections are encrypted

---

### 4.2 Configure Brute Force Protection

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | AC-7 |

#### Description
Configure account lockout and brute force protection.

#### ClickOps Implementation

**Step 1: Configure Lockout Policy**
1. Navigate to: **Security** → **Policies** → Select policy
2. Configure lockout settings:
   - **Max failed attempts:** 5
   - **Lockout duration:** 30 minutes
   - **Counter reset:** 15 minutes

**Step 2: Enable Detection**
1. Enable login anomaly detection
2. Configure alerts for repeated failures
3. Block known malicious IPs

---

### 4.3 Configure Device Trust

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.7 |
| NIST 800-53 | AC-17 |

#### Description
Implement device trust policies to verify device security posture.

#### ClickOps Implementation

**Step 1: Enable Desktop SSO**
1. Navigate to: **Security** → **Desktop SSO**
2. Configure device trust requirements
3. Deploy OneLogin desktop agent

**Step 2: Configure Device Policies**
1. Configure device requirements:
   - Domain-joined devices
   - Certificate validation
   - Managed devices only

---

## 5. Monitoring & Compliance

### 5.1 Enable Audit Logging

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs for security events.

#### ClickOps Implementation

**Step 1: Access Event Logs**
1. Navigate to: **Activity** → **Events**
2. Review login and admin events
3. Export logs for SIEM

**Step 2: Configure SIEM Integration**
1. Navigate to: **Settings** → **SIEM Integration**
2. Configure log export:
   - Splunk
   - AWS S3
   - Custom webhook
3. Verify log delivery

**Key Events to Monitor:**
- Failed login attempts
- Admin configuration changes
- MFA enrollment changes
- Password resets
- User provisioning/deprovisioning

---

### 5.2 Configure Security Alerts

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Configure alerts for security-relevant events.

#### ClickOps Implementation

**Step 1: Configure Alert Rules**
1. Navigate to: **Settings** → **Alerts**
2. Create alert rules for:
   - Multiple failed logins
   - Admin privilege changes
   - Policy modifications
   - Unusual login locations

**Step 2: Configure Notification**
1. Set notification recipients
2. Configure escalation procedures
3. Test alert delivery

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | OneLogin Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA enforcement | [2.1](#21-enforce-mfa-for-all-users) |
| CC6.1 | Password policy | [1.1](#11-configure-password-policy) |
| CC6.2 | Delegated admin | [3.1](#31-implement-delegated-administration) |
| CC6.6 | IP allowlisting | [3.2](#32-configure-ip-address-allowlisting) |
| CC7.2 | Audit logging | [5.1](#51-enable-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | OneLogin Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | MFA | [2.1](#21-enforce-mfa-for-all-users) |
| IA-2(13) | Adaptive MFA | [2.2](#22-configure-smartfactor-authentication) |
| IA-5 | Password policy | [1.1](#11-configure-password-policy) |
| AC-6(1) | Least privilege | [3.1](#31-implement-delegated-administration) |
| AU-2 | Audit logging | [5.1](#51-enable-audit-logging) |

---

## Appendix A: Plan Compatibility

| Feature | Starter | Advanced | Professional | Expert |
|---------|---------|----------|--------------|--------|
| SSO | ✅ | ✅ | ✅ | ✅ |
| MFA | Basic | ✅ | ✅ | ✅ |
| SmartFactor | ❌ | ❌ | ❌ | ✅ |
| Delegated Admin | ❌ | ❌ | ✅ | ✅ |
| Custom Policies | ❌ | ✅ | ✅ | ✅ |
| SIEM Integration | ❌ | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official OneLogin Documentation:**
- [Compliance & Certifications](https://www.onelogin.com/compliance)
- [Support Portal](https://support.onelogin.com/)
- [OneLogin User Policies](https://onelogin.service-now.com/kb_view_customer.do?sysparm_article=KB0010420)
- [Best Practices for Advanced Authentication](https://www.onelogin.com/blog/best-practices-when-deploying-advanced-authentication)
- [SAML SSO Best Practices and FAQs](https://developers.onelogin.com/saml/best-practices-and-faqs)
- [How to Authenticate Users](https://developers.onelogin.com/quickstart/authentication)
- [Rethinking MFA: Smarter Security](https://www.onelogin.com/blog/rethinking-mfa-smarter-security-for-smarter-threats)

**API Documentation:**
- [OneLogin Developer Portal](https://developers.onelogin.com/)

**Compliance Frameworks:**
- SOC 1 Type II, SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018, HIPAA, GDPR, Privacy Shield — via [OneLogin Compliance](https://www.onelogin.com/compliance)

**Security Incidents:**
- **May 2017:** Threat actor used a stolen AWS key to access OneLogin's U.S. data center infrastructure for approximately seven hours, compromising database tables containing user data, app configurations, and encryption keys. OneLogin could not rule out the attacker's ability to decrypt customer data. — [Krebs on Security Report](https://krebsonsecurity.com/2017/06/onelogin-breach-exposed-ability-to-decrypt-data/)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with MFA, policies, and admin controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
