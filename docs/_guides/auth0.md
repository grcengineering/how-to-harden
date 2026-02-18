---
layout: guide
title: "Auth0 Hardening Guide"
vendor: "Auth0"
slug: "auth0"
tier: "2"
category: "Identity"
description: "Identity platform hardening for Auth0 tenant security, MFA, and attack protection"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Auth0, now part of Okta, is a leading identity platform powering authentication for thousands of applications and **billions of logins monthly**. As the authentication layer for web and mobile applications, Auth0 tenant security directly impacts application security posture. Misconfigurations or weak security controls can expose applications to credential stuffing, brute force attacks, and account takeover.

### Intended Audience
- Security engineers managing Auth0 deployments
- Application developers implementing authentication
- GRC professionals assessing IAM controls
- Third-party risk managers evaluating identity providers

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Auth0 tenant security configurations including attack protection, MFA policies, application security, and monitoring.

---

## Table of Contents

1. [Attack Protection](#1-attack-protection)
2. [Authentication & MFA](#2-authentication--mfa)
3. [Tenant Security](#3-tenant-security)
4. [Application Security](#4-application-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Attack Protection

### 1.1 Enable Brute Force Protection

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.10 |
| NIST 800-53 | AC-7, SI-4 |

#### Description
Brute force protection blocks IP addresses that repeatedly fail to authenticate to a single user account. This is enabled by default but should be verified and configured appropriately.

#### Rationale
**Why This Matters:**
- Blocks credential stuffing attacks targeting specific accounts
- Prevents automated password guessing
- Notifies affected users of suspicious activity
- Default threshold of 10 may be too high for sensitive applications

#### Prerequisites
- [ ] Auth0 Dashboard access with admin privileges
- [ ] Secondary admin account (for recovery)

#### ClickOps Implementation

**Step 1: Access Attack Protection Settings**
1. Navigate to: **Auth0 Dashboard** → **Security** → **Attack Protection**
2. Click **Brute-force Protection**

**Step 2: Configure Protection Settings**
1. Verify **Brute-force Protection** is enabled
2. Configure threshold:
   - **Default:** 10 failed attempts (click Default)
   - **Custom:** Set to 5 for higher security (click Custom)
3. Configure actions:
   - **Block suspicious IP:** Enabled
   - **Send email notification:** Enabled

**Step 3: Configure Shields**
1. Enable available shields:
   - **Shield 1:** Block traffic after threshold
   - **Shield 2:** Block traffic from known bad IPs

**Time to Complete:** ~15 minutes

#### Validation & Testing
1. [ ] Verify protection is enabled in Dashboard
2. [ ] Test by exceeding threshold (in test environment)
3. [ ] Confirm block occurs and notification sent
4. [ ] Verify admin can unblock accounts

---


{% include pack-code.html vendor="auth0" section="1.1" %}

### 1.2 Enable Suspicious IP Throttling

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.10 |
| NIST 800-53 | SI-4 |

#### Description
Suspicious IP throttling monitors and limits requests from IP addresses exhibiting suspicious behavior across multiple accounts.

#### Rationale
**Why This Matters:**
- Detects distributed attacks targeting multiple accounts
- Rate limits suspicious IPs before they can cause damage
- Complements brute force protection

#### ClickOps Implementation

**Step 1: Enable Suspicious IP Throttling**
1. Navigate to: **Security** → **Attack Protection** → **Suspicious IP Throttling**
2. Enable **Suspicious IP Throttling**
3. Configure thresholds:
   - **Max attempts per IP:** 100 (default) or lower
   - **Throttle rate:** Configure based on expected traffic

**Time to Complete:** ~10 minutes

---


{% include pack-code.html vendor="auth0" section="1.2" %}

### 1.3 Enable Breached Password Detection

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2 |
| NIST 800-53 | IA-5 |

#### Description
Breached Password Detection checks user passwords against known breached credential databases and prevents use of compromised passwords.

#### Rationale
**Why This Matters:**
- Prevents credential reuse from breached databases
- Blocks accounts using known compromised passwords
- Minimal friction for legitimate users

#### ClickOps Implementation

**Step 1: Enable Breached Password Detection**
1. Navigate to: **Security** → **Attack Protection** → **Breached Password Detection**
2. Enable the feature
3. Configure response:
   - **At Sign-up:** Block registration with breached passwords
   - **At Login:** Notify user or block access
4. Configure notifications

**Time to Complete:** ~15 minutes

---


{% include pack-code.html vendor="auth0" section="1.3" %}

### 1.4 Configure Bot Detection

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.10 |
| NIST 800-53 | SI-4 |

#### Description
Configure CAPTCHA and bot detection to prevent automated attacks against authentication flows.

#### ClickOps Implementation

**Step 1: Enable Bot Detection**
1. Navigate to: **Security** → **Attack Protection** → **Bot Detection**
2. Enable **Bot Detection**
3. Configure triggers:
   - Login
   - Sign-up
   - Password reset

**Step 2: Configure CAPTCHA Provider**
1. Select CAPTCHA provider:
   - reCAPTCHA (Google)
   - Arkose Labs (enterprise)
2. Configure provider settings
3. Set challenge frequency

---


{% include pack-code.html vendor="auth0" section="1.4" %}

## 2. Authentication & MFA

### 2.1 Enforce Strong Password Policies

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2 |
| NIST 800-53 | IA-5 |

#### Description
Configure password policies that enforce complexity requirements while balancing usability.

#### ClickOps Implementation

**Step 1: Access Password Policy**
1. Navigate to: **Authentication** → **Database** → Select your connection
2. Click **Password Policy**

**Step 2: Configure Policy**
1. Select policy level:
   - **None:** No restrictions (not recommended)
   - **Low:** 6+ characters
   - **Fair:** 8+ characters, lowercase/uppercase/numbers
   - **Good:** 8+ characters, mixed case, numbers, symbols (recommended)
   - **Excellent:** 10+ characters, all requirements
2. Enable additional options:
   - **Password history:** Prevent reuse (last 5)
   - **Password dictionary:** Block common passwords

**Time to Complete:** ~10 minutes

---


{% include pack-code.html vendor="auth0" section="2.1" %}

### 2.2 Enable Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for user authentication. Configure phishing-resistant options like WebAuthn where possible.

#### Rationale
**Why This Matters:**
- MFA prevents 99.9% of automated attacks
- TOTP-based MFA is more secure than SMS
- WebAuthn provides phishing resistance

#### ClickOps Implementation

**Step 1: Enable MFA Factors**
1. Navigate to: **Security** → **Multi-factor Authentication**
2. Enable desired factors:
   - **One-time Password (OTP):** Recommended
   - **WebAuthn with Security Keys:** Highly recommended
   - **WebAuthn with Device Biometrics:** Recommended
   - **SMS:** Discouraged (SIM swapping risk)
   - **Voice:** Discouraged

**Step 2: Configure MFA Policy**
1. Set **Always** for applications requiring MFA
2. Or use **Adaptive MFA** for risk-based enforcement
3. Configure MFA trigger points

**Step 3: Require MFA for Dashboard Access**
1. Navigate to: **Settings** → **Tenant Settings**
2. Enable **Require MFA for all Dashboard users**

**Time to Complete:** ~30 minutes

{% include pack-code.html vendor="auth0" section="2.2" %}

### 2.3 Configure Adaptive MFA

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(6) |

#### Description
Configure Adaptive MFA to trigger additional authentication based on risk signals like new device, location, or suspicious behavior.

#### ClickOps Implementation

**Step 1: Enable Adaptive MFA**
1. Navigate to: **Security** → **Multi-factor Authentication**
2. Set policy to **Adaptive**
3. Configure risk factors:
   - New device
   - Impossible travel
   - High-risk IP

**Step 2: Configure Actions**
1. Define MFA trigger conditions
2. Configure step-up authentication for high-risk scenarios

---

## 3. Tenant Security

### 3.1 Restrict Dashboard Admin Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Limit Dashboard admin access to essential personnel and require MFA for all admins.

#### ClickOps Implementation

**Step 1: Audit Admin Users**
1. Navigate to: **Settings** → **Tenant Members**
2. Review all admin users
3. Remove unnecessary access

**Step 2: Implement Least Privilege**
1. Use role-based access:
   - **Admin:** Full tenant access
   - **Editor:** Manage applications, connections
   - **Viewer:** Read-only access
2. Assign minimum required roles

**Step 3: Require Admin MFA**
1. Navigate to: **Settings** → **Tenant Settings**
2. Enable **Require MFA for all Dashboard users**
3. Admins must enroll in MFA on next login

---


{% include pack-code.html vendor="auth0" section="3.1" %}

### 3.2 Configure Tenant Isolation

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.12 |
| NIST 800-53 | SC-7 |

#### Description
Use separate tenants for production and non-production environments to isolate security configurations and data.

#### Rationale
**Why This Matters:**
- Prevents test configurations from affecting production
- Isolates development credentials from production
- Enables different security policies per environment

#### Implementation
1. Create separate tenants for each environment:
   - `yourcompany-dev.auth0.com`
   - `yourcompany-staging.auth0.com`
   - `yourcompany.auth0.com` (production)
2. Apply strictest security to production tenant
3. Use tenant-specific credentials

---

### 3.3 Secure Tenant Credentials

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Protect Auth0 API credentials (Client ID, Client Secret, Management API tokens) as sensitive secrets.

#### Implementation
1. Store secrets in secure vault (HashiCorp Vault, AWS Secrets Manager)
2. Never commit secrets to source control
3. Rotate credentials regularly
4. Use different credentials per environment

---

## 4. Application Security

### 4.1 Configure Secure Connections

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | SC-8 |

#### Description
Configure database and social connections with security best practices.

#### ClickOps Implementation

**Step 1: Review Database Connections**
1. Navigate to: **Authentication** → **Database**
2. For each connection:
   - Enable password policy (Good or Excellent)
   - Enable brute force protection
   - Disable sign-ups if registration is controlled

**Step 2: Review Social Connections**
1. Navigate to: **Authentication** → **Social**
2. For each social provider:
   - Use dedicated OAuth applications
   - Request minimum required scopes
   - Verify redirect URIs

---

### 4.2 Secure Application Configurations

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7 |

#### Description
Configure Auth0 applications with security best practices.

#### ClickOps Implementation

**Step 1: Review Application Settings**
1. Navigate to: **Applications** → Select application
2. Configure:
   - **Application Type:** Select correct type (SPA, Regular Web, etc.)
   - **Token Endpoint Authentication:** Use Private Key JWT where possible
   - **Allowed Callback URLs:** Specific URLs only (no wildcards)
   - **Allowed Logout URLs:** Specific URLs only

**Step 2: Configure Token Settings**
1. Set appropriate token expiration:
   - **Access Token:** 3600 seconds or less
   - **Refresh Token:** Based on session requirements
2. Configure rotation for refresh tokens

---


{% include pack-code.html vendor="auth0" section="4.2" %}

### 4.3 Secure Rules and Actions

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.1 |
| NIST 800-53 | SA-15 |

#### Description
Secure Auth0 Rules and Actions to prevent injection and ensure proper error handling.

#### Security Best Practices
1. **Never bypass MFA conditionally** based on:
   - Silent authentication
   - Device fingerprinting
   - Geographic location alone
2. **Use allowRememberBrowser or context.authentication** for contextual bypass
3. **Validate all inputs** in Rules and Actions
4. **Handle errors gracefully** without exposing details
5. **Log security events** appropriately

---

## 5. Monitoring & Detection

### 5.1 Enable Logging and Monitoring

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-6 |

#### Description
Configure Auth0 logging and integrate with SIEM for security monitoring.

#### ClickOps Implementation

**Step 1: Access Logs**
1. Navigate to: **Monitoring** → **Logs**
2. Review log types:
   - Success and failure logins
   - Token exchanges
   - Admin actions

**Step 2: Configure Log Streaming**
1. Navigate to: **Monitoring** → **Streams**
2. Click **Create Stream**
3. Select destination:
   - Amazon EventBridge
   - Azure Event Hub
   - Datadog
   - Splunk
   - Custom webhook
4. Configure stream settings

**Time to Complete:** ~30 minutes

---


{% include pack-code.html vendor="auth0" section="5.1" %}

### 5.2 Key Events to Monitor

| Event Code | Event Type | Detection Use Case |
|------------|------------|-------------------|
| `f` | Failed Login | Brute force attempts |
| `fu` | Failed Login (user blocked) | Account lockout |
| `fp` | Failed Login (wrong password) | Credential stuffing |
| `sepft` | Suspicious Email Prevented | Fraud attempt |
| `fcoa` | Failed Cross-Origin Auth | XSS attempt |
| `sapi` | Management API Success | Admin activity |
| `fapi` | Management API Failure | Unauthorized admin access |

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Auth0 Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | MFA enforcement | [2.2](#22-enable-multi-factor-authentication) |
| CC6.1 | Admin access control | [3.1](#31-restrict-dashboard-admin-access) |
| CC6.2 | Attack protection | [1.1](#11-enable-brute-force-protection) |
| CC7.2 | Logging | [5.1](#51-enable-logging-and-monitoring) |

### NIST 800-53 Rev 5 Mapping

| Control | Auth0 Control | Guide Section |
|---------|---------------|---------------|
| IA-2(1) | MFA | [2.2](#22-enable-multi-factor-authentication) |
| AC-7 | Brute force protection | [1.1](#11-enable-brute-force-protection) |
| IA-5 | Password policy | [2.1](#21-enforce-strong-password-policies) |
| AU-2 | Logging | [5.1](#51-enable-logging-and-monitoring) |

---

## Appendix A: Plan Compatibility

| Feature | Free | Essential | Professional | Enterprise |
|---------|------|-----------|--------------|------------|
| Brute Force Protection | ✅ | ✅ | ✅ | ✅ |
| Suspicious IP Throttling | ❌ | ✅ | ✅ | ✅ |
| Breached Password Detection | ❌ | ❌ | ✅ | ✅ |
| Adaptive MFA | ❌ | ❌ | ✅ | ✅ |
| Log Streaming | ❌ | ❌ | ✅ | ✅ |
| Custom Domains | ❌ | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official Auth0 Documentation:**
- [Auth0 Docs](https://auth0.com/docs)
- [Attack Protection](https://auth0.com/docs/secure/attack-protection)
- [Brute Force Protection](https://auth0.com/docs/secure/attack-protection/brute-force-protection)
- [MFA Documentation](https://auth0.com/docs/secure/multi-factor-authentication)

**Security Best Practices:**
- [Rules Security Best Practices](https://auth0.com/docs/customize/rules/rules-best-practices/rules-security-best-practices)
- [Attack Protection Playbook](https://auth0.com/docs/secure/attack-protection/playbooks/brute-force-protection-playbook)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with attack protection, MFA, and tenant security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
