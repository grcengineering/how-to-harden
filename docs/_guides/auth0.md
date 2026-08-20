---
layout: guide
title: "Auth0 Hardening Guide"
vendor: "Auth0"
slug: "auth0"
tier: "2"
category: "Identity"
description: "Identity platform hardening for Auth0 tenant security, MFA, and attack protection"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Auth0, now part of Okta, is a leading identity platform powering authentication for thousands of applications and **billions of logins monthly**. As the authentication layer for web and mobile applications, Auth0 tenant security directly impacts application security posture. Misconfigurations or weak security controls can expose applications to credential stuffing, brute force attacks, and account takeover.

### Intended Audience
- Security engineers managing Auth0 deployments
- Application developers implementing authentication
- GRC professionals assessing IAM controls
- Third-party risk managers evaluating identity providers

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Crawl)

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

**Attack Prevented:** Brute force password guessing, targeted credential stuffing against a single account, automated login abuse

#### Prerequisites
- Auth0 Dashboard access with admin privileges
- Secondary admin account (for recovery)

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

**Step 3: Review the Shields**

Auth0 documents three shields on Brute-force Protection — review each rather than looking for generic "Shield 1 / Shield 2" toggles:

| Shield | Effect | Default |
|--------|--------|---------|
| **Block brute-force logins** | Blocks the offending IP from logging in to the targeted account after the threshold is reached | Enabled |
| **Account lockout** | Blocks the targeted account itself from further login attempts regardless of source IP | Disabled |
| **Send notification to affected user** | Emails the account owner that suspicious login activity was detected | Enabled with the IP block |

1. Confirm **Block brute-force logins** is enabled
2. Enable **Account lockout** only where account-level denial of service is an acceptable trade-off — an attacker who knows a username can deliberately lock it
3. Keep user notification enabled so account owners can act on the signal

Source: [Auth0 — Brute-Force Protection](https://auth0.com/docs/secure/attack-protection/brute-force-protection)

**Time to Complete:** ~15 minutes

#### Validation & Testing
1. Verify protection is enabled in Dashboard
2. Test by exceeding threshold (in test environment)
3. Confirm block occurs and notification sent
4. Verify admin can unblock accounts

---


{% include pack-code.html vendor="auth0" section="1.1" %}

### 1.2 Enable Suspicious IP Throttling

**Profile Level:** L1 (Crawl)

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

**Attack Prevented:** Distributed credential stuffing, IP-rotating password spraying, high-volume signup and login abuse

#### ClickOps Implementation

**Step 1: Enable Suspicious IP Throttling**
1. Navigate to: **Security** → **Attack Protection** → **Suspicious IP Throttling**
2. Enable **Suspicious IP Throttling**
3. Review the shields your tenant exposes (block the suspicious IP, and notify tenant administrators) and enable both
4. Tune the rate/threshold values to your expected traffic rather than assuming a fixed number — Auth0 does not publish a universal numeric default for this feature, and the 100-entry figure visible in the console is the capacity of the IP **allowlist**, not an attempt threshold

Source: [Auth0 — Suspicious IP Throttling](https://auth0.com/docs/secure/attack-protection/suspicious-ip-throttling)

**Time to Complete:** ~10 minutes

---


{% include pack-code.html vendor="auth0" section="1.2" %}

### 1.3 Enable Breached Password Detection

**Profile Level:** L1 (Crawl)

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

**Attack Prevented:** Credential stuffing with breached passwords, password reuse across services, account takeover using previously leaked credentials

#### ClickOps Implementation

**Step 1: Enable Breached Password Detection**
1. Navigate to: **Security** → **Attack Protection** → **Breached Password Detection**
2. Enable the feature
3. Configure the enforcement points — Auth0 applies detection at **three** stages, not two:
   - **At Sign-up:** block registration with a breached password
   - **At Login:** notify the user, or block access
   - **At Password Reset:** block a reset that sets a known-breached password (this third stage is frequently missed and leaves a reset flow as the gap)
4. Configure notifications to the affected user and to tenant administrators

**Step 2: Consider Credential Guard (Enterprise add-on)**

Standard breached-password detection relies on publicly available breach corpora, which Auth0 describes as typically surfacing 7-13 months after a compromise. The **Credential Guard** add-on — an Enterprise-plan option — sources credentials from the dark web and private channels, reducing typical detection latency to roughly **12-36 hours** with coverage across 200+ countries.

1. Confirm Enterprise-plan eligibility with your Auth0 account team
2. Enable Credential Guard on the tenant
3. Route the resulting log events to your SIEM (see [5.1](#51-enable-logging-and-monitoring)) — the relevant event codes are `pwd_leak` (breached password used at login), `signup_pwd_leak` (at sign-up), and `reset_pwd_leak` (at password reset)

Source: [Auth0 — Breached Password Detection](https://auth0.com/docs/secure/attack-protection/breached-password-detection)

**Time to Complete:** ~15 minutes

---


{% include pack-code.html vendor="auth0" section="1.3" %}

### 1.4 Configure Bot Detection

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.10 |
| NIST 800-53 | SI-4 |

#### Description
Configure CAPTCHA and bot detection to prevent automated attacks against authentication flows.

#### Rationale
**Why This Matters:**
- Distinguishes human users from automated scripts that drive credential stuffing and mass account-creation abuse
- CAPTCHA challenges raise the cost of large-scale automated login and signup attempts to an uneconomic level
- Applying detection to login, signup, and password reset closes the flows bots most often exploit for enumeration and takeover
- Layers on top of rate limiting and brute force protection so attackers cannot simply rotate IPs to evade fixed thresholds

**Attack Prevented:** Credential stuffing, automated account creation, account enumeration, scripted brute force

#### ClickOps Implementation

**Step 1: Enable Bot Detection**
1. Navigate to: **Security** → **Attack Protection** → **Bot Detection**
2. Enable **Bot Detection**
3. Configure triggers:
   - Login
   - Sign-up
   - Password reset

**Step 2: Configure CAPTCHA Provider**

Auth0's provider list has expanded well beyond reCAPTCHA and Arkose. Current options fall into two groups:

| Provider | Type | Notes |
|----------|------|-------|
| **Auth Challenge** | Auth0-provided | Proof-of-work style challenge; no third-party account required |
| **Simple CAPTCHA** | Auth0-provided | Basic challenge; no third-party account required |
| **reCAPTCHA Enterprise** | Third-party (Google) | Requires a Google Cloud reCAPTCHA Enterprise key |
| **hCaptcha** | Third-party | Requires an hCaptcha site key |
| **Friendly Captcha** | Third-party | Requires a Friendly Captcha key |
| **Arkose** | Third-party | Enterprise bot-mitigation service |

1. Select a provider — the Auth0-provided options (**Auth Challenge**, **Simple CAPTCHA**) avoid an external dependency; the third-party options provide stronger adaptive scoring
2. Configure provider credentials and settings
3. Set challenge frequency

Sources: [Auth0 — Bot Detection](https://auth0.com/docs/secure/attack-protection/bot-detection) · [Auth0 — Configure CAPTCHA](https://auth0.com/docs/secure/attack-protection/bot-detection/configure-captcha)

---


{% include pack-code.html vendor="auth0" section="1.4" %}

## 2. Authentication & MFA

### 2.1 Enforce Strong Password Policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2 |
| NIST 800-53 | IA-5 |

#### Description
Configure password policies that enforce complexity requirements while balancing usability.

#### Rationale
**Why This Matters:**
- Minimum length and complexity requirements directly increase the work factor for online and offline password guessing
- Blocking common-password dictionaries stops the weak, predictable credentials attackers try first
- Password history prevents users from cycling back to a previously compromised password after a forced reset
- Stronger policies shrink the pool of guessable accounts that feed credential stuffing and brute force campaigns

**Attack Prevented:** Brute force, password guessing, dictionary attacks, credential reuse

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

**Profile Level:** L1 (Crawl)

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

**Attack Prevented:** Credential theft and phishing, credential stuffing, password-only account takeover, SIM-swap-assisted takeover (when phishing-resistant factors are used)

#### ClickOps Implementation

**Step 1: Enable MFA Factors**
1. Navigate to: **Security** → **Multi-factor Auth**
2. Enable desired factors:
   - **WebAuthn with Security Keys:** Highly recommended (phishing-resistant)
   - **WebAuthn with Device Biometrics:** Recommended (phishing-resistant)
   - **One-time Password (OTP):** Recommended
   - **Push via Auth0 Guardian:** Recommended where a mobile app is acceptable
   - **Duo Security:** Available where Duo is already the enterprise MFA standard
   - **Email:** Weak — use only as a fallback
   - **SMS:** Discouraged (SIM swapping risk)
   - **Voice:** Discouraged

**Independent vs dependent factors.** Auth0 classifies factors by whether they can stand alone as a first factor. Independent factors (for example WebAuthn with security keys, OTP, push, Duo) can be used without a prior password step; dependent factors (for example WebAuthn with device biometrics, which is bound to a device already associated with the user) require another factor first. This matters when designing passwordless or step-up flows — enrolling users only in dependent factors leaves no viable standalone path.

Source: [Auth0 — Enable Multi-Factor Authentication](https://auth0.com/docs/secure/multi-factor-authentication/enable-mfa)

**Step 2: Configure MFA Policy**
1. Set **Always** for applications requiring MFA
2. Or use **Adaptive MFA** for risk-based enforcement
3. Configure MFA trigger points

**Step 3: Enforce MFA on Dashboard (Tenant Member) Access**

> **Correction (2026-08-08):** Earlier revisions of this guide instructed enabling a **Require MFA for all Dashboard users** toggle under **Settings → Tenant Settings**. **No such tenant-wide toggle exists.** Auth0 Dashboard MFA is enrolled **per tenant member** by the member themselves; the Tenant Members screen only *displays* each member's enrollment status. Treat Dashboard MFA as an enrollment-and-audit control, not a switch.

1. Each tenant member enrolls their own Dashboard MFA from their Auth0 profile / account settings (**Dashboard** → profile menu → account security), adding or changing their MFA factor
2. Navigate to: **Settings** → **Tenant Members** and review the MFA column to confirm every member shows as enrolled
3. Treat any member without MFA enrolled as a finding — remove their access or require enrollment before restoring it
4. Re-run this audit on a schedule; new members are not auto-enrolled

Sources: [Auth0 — Tenant Settings](https://auth0.com/docs/get-started/tenant-settings) · [Auth0 — Add, Change, or Remove MFA for Dashboard Access](https://auth0.com/docs/get-started/manage-dashboard-access/add-change-remove-mfa)

**Time to Complete:** ~30 minutes

{% include pack-code.html vendor="auth0" section="2.2" %}

### 2.3 Configure Adaptive MFA

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(6) |

#### Description
Configure Adaptive MFA to trigger additional authentication based on risk signals like new device, location, or suspicious behavior.

#### Rationale
**Why This Matters:**
- Risk-based step-up authentication challenges suspicious logins without adding friction to routine, low-risk access
- Signals like new device, impossible travel, and high-risk IP catch credential abuse that static, always-on policies miss
- Forcing an extra factor on anomalous logins blocks attackers who already hold valid stolen credentials
- Concentrating challenges where real risk exists keeps MFA adoption high while preserving a smooth user experience

**Attack Prevented:** Account takeover with stolen credentials, session hijacking, impossible-travel logins, anomalous-device access

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Limit Dashboard admin access to essential personnel and require MFA for all admins.

#### Rationale
**Why This Matters:**
- The Auth0 Dashboard controls authentication for every connected application, making admin accounts the highest-value target in the tenant
- Least-privilege roles ensure a compromised member account cannot rewrite security policies or exfiltrate user data
- MFA on every Dashboard member blocks takeover of admin accounts via phished or stuffed credentials
- Removing unnecessary admins shrinks the attack surface and eliminates standing access left behind by departed staff

**Attack Prevented:** Admin account takeover, privilege escalation, tenant-wide misconfiguration, insider misuse

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

**Step 3: Audit Admin MFA Enrollment**

> **Correction (2026-08-08):** There is no **Require MFA for all Dashboard users** tenant setting. Dashboard MFA is enrolled per tenant member; **Settings → Tenant Members** reports enrollment status but does not enforce it. See [2.2 Step 3](#22-enable-multi-factor-authentication) for the enrollment-and-audit procedure.

1. Navigate to: **Settings** → **Tenant Members** and read the MFA enrollment status for every member
2. Require each admin to enroll MFA from their own Auth0 account settings
3. Remove or suspend Dashboard access for any admin who remains unenrolled

Sources: [Auth0 — Tenant Settings](https://auth0.com/docs/get-started/tenant-settings) · [Auth0 — Add, Change, or Remove MFA for Dashboard Access](https://auth0.com/docs/get-started/manage-dashboard-access/add-change-remove-mfa)

---


{% include pack-code.html vendor="auth0" section="3.1" %}

### 3.2 Configure Tenant Isolation

**Profile Level:** L2 (Walk)

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

**Attack Prevented:** Non-production credential reuse against production, test-configuration drift into production, blast-radius expansion from a compromised lower environment

#### Implementation
1. Create separate tenants for each environment:
   - `yourcompany-dev.auth0.com`
   - `yourcompany-staging.auth0.com`
   - `yourcompany.auth0.com` (production)
2. Apply strictest security to production tenant
3. Use tenant-specific credentials

---

### 3.3 Secure Tenant Credentials

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Protect Auth0 API credentials (Client ID, Client Secret, Management API tokens) as sensitive secrets.

#### Rationale
**Why This Matters:**
- A leaked Client Secret or Management API token lets an attacker mint tokens, read users, and reconfigure the tenant programmatically
- Secrets committed to source control are routinely harvested by automated scanners within minutes of a public push
- Per-environment credentials and regular rotation limit the blast radius and lifespan of any single exposed secret
- A central vault provides access control, audit trails, and revocation that scattered config files and environment variables cannot

**Attack Prevented:** Credential leakage, secret harvesting from source control, unauthorized Management API access, tenant compromise

#### Implementation
1. Store secrets in secure vault (HashiCorp Vault, AWS Secrets Manager)
2. Never commit secrets to source control
3. Rotate credentials regularly
4. Use different credentials per environment

---

## 4. Application Security

### 4.1 Configure Secure Connections

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | SC-8 |

#### Description
Configure database and social connections with security best practices.

#### Rationale
**Why This Matters:**
- Connections are the entry points where users authenticate, so weak settings here undermine every downstream application
- Enforcing password policy and brute force protection per connection blocks guessing attacks at the source
- Disabling open sign-ups on controlled connections prevents attacker-created accounts and self-registration abuse
- Scoping social OAuth apps to minimum permissions and validated redirect URIs limits token theft and consent abuse

**Attack Prevented:** Brute force, unauthorized account registration, OAuth scope abuse, redirect-URI manipulation

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7 |

#### Description
Configure Auth0 applications with security best practices.

#### Rationale
**Why This Matters:**
- Exact-match callback and logout URLs prevent the open-redirect and token-interception attacks that wildcard URLs enable
- Choosing the correct application type and Private Key JWT authentication avoids exposing client secrets in public clients
- Short access-token lifetimes shrink the window in which a stolen or leaked token remains usable
- Refresh-token rotation detects and invalidates replayed tokens, containing session theft early

**Attack Prevented:** Open redirect, authorization code and token interception, token replay, session hijacking

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

**Step 3: Configure Refresh Token Rotation Deliberately**

Rotation is only as strong as the values around it. Auth0 documents these:

| Setting | Documented value | Hardening note |
|---------|------------------|----------------|
| Absolute refresh-token lifetime (default) | 30 days | Shorten for high-value applications |
| Absolute refresh-token lifetime (maximum) | 1 year | Avoid — a year-long refresh token defeats the purpose of rotation |
| Rotation leeway | Disabled by default | Leave at 0 unless a specific client race condition demands it; any leeway widens the replay window |
| Reuse detection | Revokes the **entire token family** and the underlying grant | This is the security property worth having — a replayed token kills every descendant token, not just the replayed one |

1. Enable **Refresh Token Rotation** on the application
2. Set the absolute lifetime well below the 30-day default where the application's session model allows
3. Leave rotation leeway disabled unless you have a documented client-side reason
4. Instrument alerting on reuse-detection revocations — a family revocation is a strong signal of token theft, not routine noise

Source: [Auth0 — Configure Refresh Token Rotation](https://auth0.com/docs/secure/tokens/refresh-tokens/configure-refresh-token-rotation)

> **Changed default — third-party applications.** Auth0 deprecated its **Enhanced security for third-party applications** setting on **2026-04-23**, with end of life on **2026-10-23**. After that change, Auth0 **automatically applies the strict controls to newly created third-party applications** — mandatory PKCE and explicit API authorization — rather than leaving them behind an opt-in toggle. Existing third-party applications should be reviewed and migrated to the strict behavior before the EOL date so the transition is not a surprise. Source: [Auth0 — Deprecations and Migrations](https://auth0.com/docs/troubleshoot/product-lifecycle/deprecations-and-migrations)

---


{% include pack-code.html vendor="auth0" section="4.2" %}

### 4.3 Secure Actions (and Migrate off Rules and Hooks)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.1 |
| NIST 800-53 | SA-15 |

#### Description
Secure Auth0 Actions to prevent injection and ensure proper error handling, and migrate any remaining Rules or Hooks to Actions before they stop executing.

> **DEPRECATION — Rules and Hooks stop executing 2026-11-18.** Auth0 made Rules and Hooks **read-only on 2024-11-18**: they can be viewed but not created or edited. Auth0 has stated they **stop executing entirely on 2026-11-18** — roughly three months from this revision. Any authentication logic still implemented as a Rule or Hook (including MFA enforcement, claim enrichment, and access denial) will silently stop running at that point; a Rule that currently blocks a login will simply stop blocking it. **Migrate every remaining Rule and Hook to Actions now**, and verify by confirming the tenant lists no active Rules or Hooks. Sources: [Auth0 — Rules](https://auth0.com/docs/customize/rules) · [Auth0 — Deprecations and Migrations](https://auth0.com/docs/troubleshoot/product-lifecycle/deprecations-and-migrations)

#### Rationale
**Why This Matters:**
- Actions run privileged custom code inside the authentication pipeline, so a flaw there compromises every login
- Conditionally bypassing MFA on weak signals like device fingerprint or geolocation hands attackers a reliable evasion path
- Validating all inputs prevents injection and logic abuse through attacker-controlled profile and request data
- Graceful error handling avoids leaking secrets, tokens, or internal details that aid further attacks

**Attack Prevented:** MFA bypass, injection into the auth pipeline, sensitive information disclosure, authentication logic abuse

#### Security Best Practices
1. **Never bypass MFA conditionally** based on:
   - Silent authentication
   - Device fingerprinting
   - Geographic location alone
2. **Use allowRememberBrowser or context.authentication** for contextual bypass
3. **Validate all inputs** in Actions
4. **Handle errors gracefully** without exposing details
5. **Log security events** appropriately
6. **Confirm no live Rules or Hooks remain** — anything not yet migrated to Actions stops executing on 2026-11-18 (see the deprecation callout above)

---

## 5. Monitoring & Detection

### 5.1 Enable Logging and Monitoring

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-6 |

#### Description
Configure Auth0 logging and integrate with SIEM for security monitoring.

#### Rationale
**Why This Matters:**
- Streaming authentication logs to a SIEM enables near real-time detection of credential stuffing, brute force, and anomalous admin activity
- Auth0 retains logs for a limited window, so exporting them preserves the evidence needed for incident response and forensics
- Correlating login and Management API events surfaces account takeover and privilege abuse that isolated events hide
- Centralized monitoring satisfies audit and compliance requirements for security event logging and review

**Attack Prevented:** Undetected account takeover, credential stuffing, unauthorized admin activity, delayed breach detection

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
| Credential Guard (dark-web credential detection add-on) | ❌ | ❌ | ❌ | ✅ |
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

- [Breached Password Detection](https://auth0.com/docs/secure/attack-protection/breached-password-detection)
- [Bot Detection](https://auth0.com/docs/secure/attack-protection/bot-detection)
- [Configure Refresh Token Rotation](https://auth0.com/docs/secure/tokens/refresh-tokens/configure-refresh-token-rotation)
- [Tenant Settings](https://auth0.com/docs/get-started/tenant-settings)
- [Add, Change, or Remove MFA for Dashboard Access](https://auth0.com/docs/get-started/manage-dashboard-access/add-change-remove-mfa)

**Security Best Practices:**
- [Auth0 Security Guidance](https://auth0.com/docs/secure/security-guidance)
- [Action Coding Guidelines](https://auth0.com/docs/customize/actions/action-coding-guidelines) — the security reference for Actions. *Link-rot note: the former `customize/rules/rules-best-practices/rules-security-best-practices` URL now serves Actions content, so cite the Actions page directly.*
- [Attack Protection Playbook](https://auth0.com/docs/secure/attack-protection/playbooks/brute-force-protection-playbook)

**Product Lifecycle:**
- [Deprecations and Migrations](https://auth0.com/docs/troubleshoot/product-lifecycle/deprecations-and-migrations) — tracks the Rules/Hooks end of execution (2026-11-18) and the third-party-application enhanced-security EOL (2026-10-23)
- [Rules (deprecated)](https://auth0.com/docs/customize/rules)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass. Corrections: removed the nonexistent "Require MFA for all Dashboard users" tenant toggle from 2.2 and 3.1 (Dashboard MFA is per-member enrollment; Tenant Members only reports status); replaced the invented "Shield 1/Shield 2" list in 1.1 with the documented shields (block brute-force logins enabled by default, account lockout disabled by default, user notification); dropped the unverifiable "Max attempts per IP: 100 (default)" from 1.2 (100 is the allowlist capacity). Deprecations: bolded Rules/Hooks end-of-execution callout (read-only since 2024-11-18, stop executing 2026-11-18) and retitled 4.3 to Actions; changed-default callout in 4.2 for third-party-application enhanced security (deprecated 2026-04-23, EOL 2026-10-23, strict controls auto-applied to new third-party apps). Additions: breached-password detection at password reset plus the Credential Guard add-on and its log events (1.3, Appendix A); expanded CAPTCHA provider list (1.4); refresh-token rotation values and token-family reuse revocation (4.2); independent-vs-dependent MFA factor distinction plus Guardian push and Duo (2.2). Fixed the rotted Rules security-best-practices reference (now serves Actions content). Added missing **Attack Prevented:** lines to 1.1, 1.2, 1.3, 2.2, and 3.2 so they render in the cheat sheet. Tier 2 currency check returned no configuration-prescriptive Auth0 baseline (no CIS Benchmark, DISA STIG, or CISA SCuBA coverage found). Tier 3/4 not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with attack protection, MFA, and tenant security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
