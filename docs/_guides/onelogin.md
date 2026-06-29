---
layout: guide
title: "OneLogin Hardening Guide"
vendor: "OneLogin"
slug: "onelogin"
tier: "1"
category: "Identity"
description: "Identity provider hardening for OneLogin including MFA policies, user security, and SmartFactor Authentication"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

OneLogin is a leading cloud identity and access management platform providing SSO and MFA to **thousands of enterprises** worldwide. As the authentication gateway for corporate applications, OneLogin security configurations directly impact access control for all integrated systems. Compromised identity providers can provide attackers with access to the entire SaaS ecosystem.

### Intended Audience
- Security engineers managing identity infrastructure
- IT administrators configuring OneLogin
- GRC professionals assessing IAM security
- Third-party risk managers evaluating identity providers

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2 |
| NIST 800-53 | IA-5 |

#### Description
Configure password policies to enforce strong authentication requirements for OneLogin users.

#### Rationale
**Why This Matters:**
- Weak or reused passwords are the most common entry point for credential stuffing and brute-force attacks against the identity provider
- OneLogin authenticates access to every downstream SaaS app, so a single guessed password can cascade into the entire application portfolio
- Account lockout thresholds blunt automated password-guessing tools before they succeed

**Attack Prevented:** Credential stuffing, brute-force password guessing, password reuse exploitation

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout and activity controls to limit exposure from idle sessions.

#### Rationale
**Why This Matters:**
- Long-lived or idle sessions leave authenticated tokens available for theft on unattended or shared devices
- Bounded session and idle timeouts shrink the window an attacker has to ride a hijacked session into connected applications
- Forced re-authentication on sensitive apps ensures a stolen session cannot silently reach the most critical resources

**Attack Prevented:** Session hijacking, token replay, unauthorized access from unattended devices

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2 |
| NIST 800-53 | IA-5 |

#### Description
Configure secure self-service password reset to reduce helpdesk burden while maintaining security.

#### Rationale
**Why This Matters:**
- Password reset flows are a frequent target for social engineering and account takeover when identity proofing is weak
- Requiring MFA and strong verification on reset prevents attackers from seizing accounts through the recovery path
- Self-service reset removes helpdesk impersonation as an attack vector while keeping verification controls enforced

**Attack Prevented:** Account takeover via recovery flow, helpdesk social engineering, password reset abuse

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

**Profile Level:** L1 (Crawl)

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

**Profile Level:** L2 (Walk)

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
- OneLogin Expert plan or higher

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(6) |

#### Description
Require WebAuthn/FIDO2 hardware keys for administrator accounts.

#### Rationale
**Why This Matters:**
- Administrators hold the keys to the entire identity platform, making their accounts the highest-value target for attackers
- WebAuthn/FIDO2 keys are bound to the origin and cannot be replayed, defeating phishing and adversary-in-the-middle proxies that bypass push and TOTP factors
- Disabling SMS, email, and TOTP for admins removes the weaker factors attackers prefer to intercept or fatigue

**Attack Prevented:** Phishing, adversary-in-the-middle, MFA fatigue, SIM swapping, admin account takeover

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Configure delegated administration to implement least privilege for admin access.

#### Rationale
**Why This Matters:**
- Super-user accounts can alter any policy, user, or app integration, so broad admin grants dramatically expand the blast radius of a compromise
- Scoped custom roles ensure helpdesk and tier-1 staff hold only the permissions their job requires
- Limiting the number of full administrators reduces the set of accounts an attacker can target for total control

**Attack Prevented:** Privilege escalation, lateral movement, insider misuse, blast-radius expansion

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17, SC-7 |

#### Description
Restrict access to OneLogin from approved IP addresses.

#### Rationale
**Why This Matters:**
- Restricting logins to corporate and VPN egress IPs denies attackers access even when they hold valid stolen credentials
- Network-based restrictions add a control that cannot be defeated by phishing the password or a one-time code
- Step-up or block responses for unknown IPs flag and contain anomalous access attempts from unexpected locations

**Attack Prevented:** Credential theft exploitation, remote access from untrusted networks, geographic-anomaly logins

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement additional protections for privileged administrator accounts.

#### Rationale
**Why This Matters:**
- Privileged accounts are the primary objective of targeted attacks because they control the entire identity fabric
- Separate admin and daily-use accounts prevent routine browsing or email compromise from exposing administrative power
- Shorter timeouts, mandatory MFA, and enhanced logging on these accounts detect and limit misuse faster

**Attack Prevented:** Admin account takeover, privilege abuse, lateral movement, standing-privilege exploitation

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | SC-8 |

#### Description
Ensure all OneLogin communications use strong TLS encryption.

#### Rationale
**Why This Matters:**
- Authentication traffic, SAML assertions, and API calls carry credentials and session tokens that are exposed if transport is unencrypted or downgraded
- Enforcing TLS 1.2+ prevents attackers on the network path from intercepting or tampering with login flows
- Strong transport encryption is a baseline requirement for protecting identity data in transit and meeting compliance mandates

**Attack Prevented:** Man-in-the-middle interception, protocol downgrade, credential and token sniffing

#### Validation
1. Verify OneLogin portal uses TLS 1.2+
2. Check SAML connections use HTTPS
3. Validate API connections are encrypted

---

### 4.2 Configure Brute Force Protection

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | AC-7 |

#### Description
Configure account lockout and brute force protection.

#### Rationale
**Why This Matters:**
- Without lockout thresholds, attackers can run unlimited automated password-guessing attempts against accounts
- Lockout and counter-reset settings slow credential-guessing tools enough to make brute force impractical
- Login anomaly detection and alerting surface ongoing attacks so responders can block malicious sources

**Attack Prevented:** Brute-force attacks, password spraying, credential stuffing

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.7 |
| NIST 800-53 | AC-17 |

#### Description
Implement device trust policies to verify device security posture.

#### Rationale
**Why This Matters:**
- Allowing logins only from domain-joined or managed devices stops attackers using stolen credentials on unmanaged hardware
- Device posture checks ensure authenticating endpoints meet security baselines before granting access
- Binding access to trusted devices adds a factor that phished passwords and codes alone cannot satisfy

**Attack Prevented:** Credential theft exploitation, unmanaged-device access, endpoint compromise propagation

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs for security events.

#### Rationale
**Why This Matters:**
- Without comprehensive logs, account compromise and admin abuse can occur undetected and cannot be investigated after the fact
- Capturing login, MFA, and configuration-change events provides the forensic trail needed for incident response
- Exporting logs to a SIEM enables correlation, alerting, and retention beyond the platform's native window

**Attack Prevented:** Undetected intrusion, log tampering, delayed breach discovery

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Configure alerts for security-relevant events.

#### Rationale
**Why This Matters:**
- Real-time alerts on failed logins, privilege changes, and policy edits shrink the time attackers operate unnoticed
- Notifying responders of unusual login locations and admin actions enables rapid containment before damage spreads
- Alerting on policy modifications detects attempts to weaken security controls from within

**Attack Prevented:** Delayed incident response, stealthy privilege escalation, undetected configuration tampering

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
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with MFA, policies, and admin controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
