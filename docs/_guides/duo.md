---
layout: guide
title: "Cisco Duo Security Hardening Guide"
vendor: "Duo Security"
slug: "duo"
tier: "2"
category: "Identity"
description: "Multi-factor authentication hardening for Cisco Duo, admin policies, and bypass protection"
version: "0.2.1"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Cisco Duo is a leading multi-factor authentication platform protecting **over 100 million users** globally. As a critical security control for application access, Duo configurations directly impact organizational security posture. Misconfigured policies, excessive bypass access, or unmonitored inactive accounts can undermine MFA protection.

### Intended Audience
- Security engineers managing Duo deployments
- IT administrators configuring MFA policies
- GRC professionals assessing authentication controls
- Third-party risk managers evaluating MFA solutions

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Crawl)

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
- Only the Owner role can create and manage other administrators, and only Owners can manage the Admin API and Account API applications — so Owner is effectively the key to the whole tenant and its programmatic surface

**Attack Prevented:** Admin account takeover, policy tampering to disable MFA, over-privileged administration, unauthorized API application creation

#### Prerequisites
- Duo Admin Panel access
- Organization with defined admin roles

#### ClickOps Implementation

**Step 1: Audit Admin Accounts**
1. Log in as an **Owner** and navigate to: **Users** → **Administrators** → **Administrators**
2. Review all administrator accounts — the list shows names, email addresses, status, and last login dates
3. Document accounts and assigned roles
4. Remove unnecessary admin access

**Step 2: Implement Role-Based Access**

Duo documents ten assignable admin roles. Assign the minimum required role per admin:

| Role | Scope |
|------|-------|
| **Owner** | Full access to all actions, objects, and settings. Only Owners can create/update/delete other administrators, run admin directory sync, create or manage the **Admin API and Account API applications**, change the plan edition, or cancel the subscription. Limit to 1-2 accounts. |
| **Administrator** | Full access to users, devices, settings, policies, and applications **except** the Admin API and Account API application types. Cannot view billing or manage other administrators. |
| **User Manager** | Create/update/delete users, attributes, phones, tokens, bypass codes; run user directory sync. |
| **Help Desk** | Limited support functions — attribute values, phones, tokens, bypass codes, enrollment emails, unlocking users. Cannot manually create or delete users or run a full directory sync. |
| **Security Analyst** | Help Desk scope plus setting Trust Monitor risk profiles, processing events, locking out users, and viewing all logs and reports. |
| **Application Manager** | Add, update, and remove applications (except Admin API / Account API types) and manage SSO authentication sources. Can assign existing policies but cannot create or edit policy settings. |
| **Billing** | View and update billing, purchase hardware tokens and telephony credits, manage sub-accounts. Dashboard and Billing pages only. |
| **Read-only** | View basic user, group, phone, token, and application information plus reports. No access to Billing or Directory Sync pages. |
| **Account Switcher** | View and switch to sub-accounts via the Accounts drop-down. Cannot view users or applications. |
| **Custom Admin Role** | Any custom role you have created appears alongside the built-ins. |

> **Free plan caveat:** In Duo Free plans, all administrators are effectively "Owners" — no other role assignments are available. Role separation is a reason to be on a paid edition, not something you can configure your way to on Free.

**Step 3: Restrict Admin Authentication Methods (MFA Is Already Mandatory)**

> **Correction — admin MFA is not an optional toggle.** Duo documents that **all administrators must use two-factor authentication to access the Duo Admin Panel**. There is no configuration step to "turn on" admin MFA, so the hardening work here is restricting *which* factors are acceptable, not enabling the requirement.

1. Prefer **passkeys** (WebAuthn security keys or platform authenticators) for administrators. Owners can pre-register a removable security key as a passkey for another admin from that admin's details page.
2. Treat SMS and phone-call authentication to the Admin Panel as a fallback of last resort — the phone number recorded on an administrator's details page is what Duo uses for those factors, and it is the weakest option available to a high-value account.
3. Hardware OTP tokens (Duo-purchased, YubiKey OTP, or any OATH HOTP-compatible token) can be assigned by an Owner where a passkey is impractical.
4. Set the **Admin Password Policy** (Users → Administrators → Admin Login Settings) to at least the 12-character default and enable all four complexity options — uppercase, lowercase, number, special character. Note this length can be increased but not subsequently decreased.
5. Consider **Single Sign-On with SAML** for the Admin Panel (Essentials/Advantage/Premier) so admin logins inherit your IdP's controls. Be aware of the documented gap: with "Authentication with SAML" set to Required, administrators with the **Owner** role may still sign in with a password and bypass the external IdP.

> **Note — administrators provisioned via Cisco Security Cloud Control.** New administrators whose accounts were created through Cisco Security Cloud Control (SCC) **after May 11, 2026** have limited access to features and pages in the Admin Panel, and sign in through SCC rather than directly. Factor this into any access review: an SCC-provisioned admin's effective permissions may not match what the role name implies.

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="duo" section="1.1" %}

---

### 1.2 Protect Admin Credentials

**Profile Level:** L1 (Crawl)

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

**Attack Prevented:** Secret-key theft, API-driven policy bypass, credential leakage through source control, unauthorized programmatic access

#### Implementation

**Credential Security Guidelines:**
1. **Never share secret keys** via email or insecure channels
2. **Store secrets in secure vaults** (HashiCorp Vault, AWS Secrets Manager)
3. **Never commit secrets** to source control
4. **Rotate keys** if compromise is suspected
5. **Use environment variables** instead of hardcoded values

---

### 1.3 Tighten Admin Panel Session Limits

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.3 |
| NIST 800-53 | AC-11, AC-12 |

#### Description
Reduce the Admin Panel's absolute session length and idle timeout from their defaults, and expire administrators who stop logging in. These settings live under **Users → Administrators → Admin Login Settings** in the "Admin Access" section and are available on Duo Essentials, Advantage, and Premier.

#### Rationale
**Why This Matters:**
- The default four-hour absolute session and thirty-minute idle timeout mean a stolen Admin Panel session or an unattended browser stays usable far longer than any administrative task requires
- Absolute session length is the only bound that survives an active attacker — an idle timeout alone does nothing against a session being continuously used from a hijacked browser
- Administrator accounts that quietly go dormant remain valid credentials; automatic expiry after a set inactivity period removes them without waiting for an offboarding process to catch up

**Attack Prevented:** Admin session hijacking, unattended-console takeover, indefinite session reuse, dormant-admin-account abuse

#### ClickOps Implementation

**Step 1: Set the Absolute Session Length**
1. Log in as an **Owner** and navigate to: **Users** → **Administrators** → **Admin Login Settings**
2. In the **Admin Access** section, set **Absolute session length** — configurable from **15 minutes to 10 hours**, **default 4 hours**
3. Recommended: **1 hour** at L1, **30 minutes** at L2/L3. Administrators log back in; attackers with a stale session do not.

**Step 2: Set the Idle Timeout**
1. In the same section, set **Idle timeout length** — configurable from **5 to 60 minutes**, **default 30 minutes**
2. Recommended: **15 minutes** at L1, **5-10 minutes** at L2/L3

**Step 3: Expire Inactive Administrators**
1. Select **Disable admins after a set period of inactivity** and enter a threshold between **30 and 365 days**
2. Note the documented exceptions: this has **no effect on administrators with the Owner role** (Owners never expire for inactivity), and it does not act on administrators who have never logged in at all — audit those two populations manually

#### Validation & Testing
1. Log in to the Admin Panel, leave the session idle past the configured idle timeout, and confirm you are logged out
2. Stay actively engaged past the absolute session length and confirm you are still logged out
3. Review the administrator list for accounts showing **Expired** status and confirm inactive accounts are being caught
4. Separately list Owner-role and never-logged-in administrators, since automatic expiry will not reach them

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls over privileged sessions |
| **NIST 800-53** | AC-11 | Device lock / session inactivity |
| **NIST 800-53** | AC-12 | Session termination |
| **CIS Controls** | 4.3 | Configure automatic session locking on enterprise assets |

---

## 2. Authentication Policies

### 2.1 Configure Global Policy

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Configure the Global Policy as the baseline security policy for all Duo-protected applications.

#### Rationale
**Why This Matters:**
- The Global Policy is the default baseline inherited by every Duo-protected application, so one weak setting silently exposes all of them
- Setting the authentication policy to "Enforce MFA" guarantees no application falls back to single-factor access
- A "Deny access" new user policy prevents un-enrolled accounts from logging in without ever completing second-factor setup
- Leaving the global default permissive means newly added applications inherit insecure behavior unless an admin remembers to override it

**Attack Prevented:** Single-factor access, MFA enrollment bypass, policy misconfiguration drift

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

**Step 4: Review the Remembered Devices Default**

> **Changed default — Risk-Based Remembered Devices is ON.** On **Duo Advantage and Duo Premier**, [Risk-Based Remembered Devices is enabled by default](https://duo.com/docs/policy). It analyzes authentications for IP and device patterns and **suppresses further two-factor prompts for 30 days by default**, re-prompting early only when it detects anomalous access. This is a materially different posture from "every login is challenged," and it is inherited by every application under the Global Policy. It is **not** present on Duo Essentials or Free, where remembered devices default to **off**.
>
> Three things follow. First, decide deliberately whether a 30-day suppression window is acceptable for your risk profile — and shorten it, or select **Don't remember devices for browser-based applications**, for sensitive applications. The documented pattern is to configure remembered devices at the global policy level and then override it with application or group policies that disable it for restricted-access applications. Second, note the bound that configuration cannot exceed: a **passwordless remembered-devices session is capped at seven days (168 hours) regardless of the value set in the Admin Panel**. Third, note what still runs: endpoint checks for trust status and security posture **continue to occur** during a remembered-device session, so device-trust controls ([4.1](#41-configure-trusted-endpoints)) are not suspended by it.
>
> Related: authorized-network configuration is covered in [2.4](#24-configure-authorized-networks), and Duo Passport's dependency on this same setting is covered in [6.3](#63-reduce-session-hijacking-exposure-with-duo-passport).

**Time to Complete:** ~15 minutes

---

### 2.2 Eliminate Bypass Access

**Profile Level:** L1 (Crawl)

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

**Attack Prevented:** MFA bypass abuse, persistent single-factor access, help-desk-granted standing exemptions, account takeover of exempted users

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

#### Code Implementation

{% include pack-code.html vendor="duo" section="2.2" %}

---

### 2.3 Require Phishing-Resistant MFA

**Profile Level:** L2 (Walk)

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

**Attack Prevented:** MFA fatigue / push bombing, real-time phishing proxies, SMS interception and SIM swap, adversary-in-the-middle credential relay

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

---

### 2.4 Configure Authorized Networks

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Configure authorized network policies to adjust MFA requirements based on network location while maintaining security.

#### Rationale
**Why This Matters:**
- Network-based policies let you tighten authentication for untrusted locations without weakening protection for trusted ones
- Allowing 2FA-free access from "authorized" IP ranges turns a stolen VPN session or spoofed source address into a full MFA bypass
- IP allowlists are easily defeated by an attacker operating inside the corporate network or routing through a compromised VPN
- Requiring MFA even on trusted networks preserves defense in depth against lateral movement and insider misuse

**Attack Prevented:** IP allowlist bypass, VPN session abuse, lateral movement, insider misuse

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

---

## 3. User Management

### 3.1 Manage Inactive Accounts

**Profile Level:** L1 (Crawl)

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

**Attack Prevented:** Dormant-account takeover, enrollment of an attacker's device against a never-activated account, offboarding gaps, attack-surface accumulation

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

#### Code Implementation

{% include pack-code.html vendor="duo" section="3.1" %}

---

### 3.2 Configure User Enrollment

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | IA-5 |

#### Description
Configure secure user enrollment processes that verify identity before granting MFA access.

#### Rationale
**Why This Matters:**
- Enrollment binds an authentication device to a user identity, so a weak process lets an attacker register their own device against a victim's account
- Unexpired or widely distributed enrollment links can be intercepted and used to enroll an attacker-controlled authenticator
- Verifying identity before enrollment stops social-engineering of the help desk into provisioning MFA for an impostor
- Privileged accounts warrant stronger (in-person or HR-validated) enrollment because their compromise has the highest impact

**Attack Prevented:** Attacker device enrollment, enrollment link interception, help-desk social engineering, account takeover

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

---

## 4. Device Trust

### 4.1 Configure Trusted Endpoints

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | AC-2(11) |

#### Description
Configure Duo's Trusted Endpoints feature to verify device compliance before granting access.

#### Rationale
**Why This Matters:**
- Trusted Endpoints ensures access comes only from managed, compliant devices — not personal or attacker-controlled machines
- Valid credentials plus a working second factor still let an unmanaged or compromised endpoint reach sensitive applications without device checks
- Blocking untrusted devices stops credential replay and stolen-session reuse from machines outside corporate control
- Device posture is a control that phishing and MFA-fatigue attacks cannot satisfy from an unmanaged device

**Attack Prevented:** Unmanaged-device access, credential replay, session-token theft, BYOD compromise

#### Prerequisites
- **Duo Essentials, Duo Advantage, or Duo Premier.** (The retired "Duo Beyond" plan name no longer exists; Trusted Endpoints is included from Essentials upward.)
- **Duo Premier or Duo Advantage** specifically for the **Device Insight** and **Endpoints** pages in the Admin Panel. Essentials customers monitor trusted-device authentications through the Authentication Log report instead.
- A supported device management solution, and **Duo Desktop** on Windows/macOS/Linux endpoints for integrations that verify management status through it

> **Correction — certificate-based verification is dead.** [Certificate-based Trusted Endpoint verification reached end-of-life on October 7, 2024, and Duo device certificates stopped renewing after October 2024.](https://duo.com/docs/policy) If your deployment still relies on device certificates, it is not enforcing device trust — migrate to an integration that verifies status through **Duo Mobile** (mobile) or **Duo Desktop** (desktop) using Duo's Trusted Endpoints Certificate Migration Guide. Note also that Duo Passwordless does not support trusted-device verification via certificates or Google Verified Access at all.

#### ClickOps Implementation

**Step 1: Configure Device Management Integration**
1. Navigate to: **Trusted Endpoints**
2. Click **Add Integration**
3. Select your device management platform. Duo documents fifteen integration types, and recommends configuring more than one to maximize enrollment coverage:
   - Duo Mobile app verification of mobile devices
   - Active Directory Domain Services (AD DS), verified via Duo Desktop
   - Workspace ONE managed device verification
   - Cisco Secure Endpoint security posture verification
   - Cisco Meraki Systems Manager managed device verification
   - Generic Duo Desktop integrations for other Windows and macOS management tools
   - **Google Chrome Enterprise Device Trust Connector** (managed ChromeOS and Chrome browser)
   - Google Workspace managed device verification
   - Jamf Pro managed device verification
   - Ivanti Endpoint Manager Mobile (formerly MobileIron Core)
   - Ivanti Neurons for MDM (formerly MobileIron Cloud)
   - Manual enrollment with Duo Desktop
   - **Microsoft Edge for Business Device Trust** (managed Edge for Business browser)
   - Microsoft Intune managed Android, iOS, and Windows device verification
   - Sophos Mobile managed device verification
4. Configure integration settings. New integrations are created **disabled** and have no effect until you activate them.

**Step 2: Create Trusted Endpoint Policy**
1. Navigate to: **Policies**
2. Edit or create policy
3. Under **Devices**, configure:
   - **Require devices to be trusted**
   - **Block untrusted devices** or **Allow with warning**
4. Note the ordering constraint: the Trusted Endpoints policy setting cannot be changed from the **Allow all endpoints** default until at least one Trusted Endpoints integration exists. Pilot with an application or application-group policy before changing the global policy.

**Step 3: Roll Out and Monitor**
1. Move each integration's status from the pilot group to **Activate for all** once verified
2. Replace or remove the pilot group policies so the global policy takes effect
3. Monitor **Device Insight** and **Endpoints** (Advantage/Premier) or the Authentication Log (Essentials) to confirm endpoints are reporting managed status

---

### 4.2 Monitor Device Registration

**Profile Level:** L1 (Crawl)

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

**Attack Prevented:** Attacker device enrollment after credential theft, silent addition of a second factor under attacker control, undetected account takeover

#### Implementation
1. Enable alerts for new device registrations
2. Review authentication logs for registration events
3. Use **Cisco Identity Intelligence** for anomaly detection — see the migration note below
4. Integrate with SIEM for correlation

> **Trust Monitor has been removed — use Cisco Identity Intelligence.** Per [Duo's own documentation](https://duo.com/docs/trust-monitor): Duo Trust Monitor became unavailable to new Advantage and Premier subscriptions and trials as of **September 29, 2025**; **Trust Monitor functionality was removed from the Duo Admin Panel on July 27, 2026**; and the **Trust Monitor API endpoint reaches end-of-support on January 31, 2027**. The replacement is **Cisco Identity Intelligence**, whose features and capabilities are [included for Duo Premier and Duo Advantage customers](https://duo.com/docs/identity-security). Any runbook, alert, or SIEM integration still pointing at Trust Monitor should be re-pointed now — the API remains reachable until 2027, which makes this the kind of dependency that fails quietly rather than loudly.

---

## 5. Application Security

### 5.1 Configure Application-Specific Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4 |
| NIST 800-53 | AC-3 |

#### Description
Create application-specific policies with appropriate security controls based on application sensitivity.

#### Rationale
**Why This Matters:**
- A single global policy forces low- and high-sensitivity applications to share one authentication strength, either over-restricting users or under-protecting crown-jewel systems
- Application-tiered policies let critical systems (admin portals, financial apps) require WebAuthn-only while standard apps accept broader methods
- Scoping the strongest controls to the highest-risk applications concentrates protection where a breach would be most damaging
- Per-application policy reduces the blast radius when one application or one authentication method is compromised

**Attack Prevented:** Privilege escalation to sensitive apps, weak-method abuse on critical systems, over-broad access

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

---

### 5.2 Secure Windows Logon/RDP

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Configure Duo for Windows Logon and RDP with appropriate security settings.

#### Rationale
**Why This Matters:**
- Windows Logon and RDP are primary targets for ransomware operators and lateral movement after an initial compromise
- A "Deny access" new user policy ensures un-enrolled accounts cannot log in to endpoints without completing MFA first
- Tightly bounded offline access (short expiration, limited login count) prevents indefinite single-factor logins when Duo is unreachable
- A careless "fail open" mode lets attackers force an MFA bypass simply by disrupting Duo connectivity, so the fail mode must be chosen deliberately

**Attack Prevented:** RDP brute force, ransomware lateral movement, offline-access abuse, fail-open MFA bypass

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

---

## 6. Monitoring & Detection

### 6.1 Enable Logging and Alerting

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-6 |

#### Description
Configure Duo logging and integrate with SIEM for security monitoring and incident investigation.

#### Rationale
**Why This Matters:**
- Authentication logs are the primary evidence for detecting MFA fatigue, brute force, and bypass abuse while an attack is in progress
- Without SIEM integration, Duo events stay siloed and cannot be correlated with other security signals during an investigation
- Centralized, retained logs are required to reconstruct an incident timeline and meet audit and compliance obligations
- Real-time alerting on failed authentications and bypass usage shortens attacker dwell time

**Attack Prevented:** Undetected MFA fatigue, brute-force attempts, bypass abuse, delayed incident response

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

**Step 3: Provision Cisco Identity Intelligence (Advantage/Premier)**

Cisco Identity Intelligence (CII) replaces Duo Trust Monitor, which was removed from the Admin Panel on July 27, 2026 (see [4.2](#42-monitor-device-registration)). All CII features are included for Duo Premier and Duo Advantage customers.

1. Log in as an administrator with the **Owner** or **Administrator** role
2. Navigate to: **Monitoring** → **Cisco Identity Intelligence** → **Provision**
3. Click **Connect to Cisco Identity Intelligence**. Most existing customers are already provisioned — if you see "Configuration Details" instead of a connect button, skip ahead.
4. Verify the user access and group mappings for the auto-created CII SSO application. Provisioning creates three Duo groups — **CII Admins**, **CII Help Desk**, and **CII Read-Only** — and the SSO application should default to **Enable only for permitted groups** with those three selected.
5. Navigate to **Users** → **Groups** and populate those groups with the administrators who should reach the CII dashboard. Remove any CII role you do not intend to use; you cannot add roles beyond the three.
6. Launch the dashboard from **Monitoring** → **Cisco Identity Intelligence** → **Launch Identity Intelligence**

> **Identity mapping prerequisite.** If you are not using Active Directory Sync or Microsoft Entra ID Sync, Duo users need an email address in the username or email field for CII to correlate them with identities in other integrated platforms — and that address must match the one used in those platforms. Without it, cross-vendor correlation silently produces incomplete results rather than an error. Data ingestion begins automatically after provisioning and can take several days to fully synchronize.

#### Code Implementation

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

### 6.3 Reduce Session Hijacking Exposure with Duo Passport

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | SC-23 |

#### Description
Deploy Duo Passport (Duo Premier and Duo Advantage) to share one hardware-bound authentication session across a user's browsers, desktop client applications, and Windows logon, instead of issuing a separate remember-me cookie per application. Passport is configured under **Policies → Policies** with a remembered devices policy and requires Duo Desktop 6.6.0 or later.

#### Rationale
**Why This Matters:**
- Passport's session identity is bound to a cryptographic keypair whose private key is generated and held on the access device — Windows devices must support **TPM 2.0** and macOS devices must support **Secure Enclave** — so the session artifact is not a bearer token that copies cleanly to an attacker's machine
- Duo states that Passport "significantly reduces the risk of session hijacking by minimizing the use of cookies," submitting the Passport session directly instead of setting one and thereby "eliminat[ing] the need for a remember-me cookie altogether" — a vendor claim worth verifying against your own threat model, but a materially different design from cookie-based remembered devices
- Duo Desktop signs every data payload with that device-held private key and Duo blocks the access attempt if the signature is invalid, which is what makes a tampered or spoofed health report fail rather than pass
- The alternative — reducing prompt fatigue by extending remembered-device windows per application — buys the same convenience by widening exactly the window an attacker wants

**Attack Prevented:** Session-cookie theft and replay, adversary-in-the-middle session hijacking, forged endpoint health reports, prompt fatigue driving over-long remembered-device windows

#### Prerequisites
- **Duo Premier or Duo Advantage** plan
- **Duo Desktop 6.6.0** (Windows) / **6.6.0.0** (macOS) or later on client machines
- Windows access devices supporting **TPM 2.0**; macOS access devices supporting **Secure Enclave**
- Trusted Endpoints and Duo Desktop device registration policies are *complemented* by Passport but are **not** required for it

#### ClickOps Implementation

**Step 1: Deploy Duo Desktop**
1. Push Duo Desktop 6.6.0+ to managed Windows and macOS clients, or allow self-install during browser authentication
2. Passport does not require configuring any Duo Desktop policy options — existing policies requiring Duo Desktop or device registration can stay as they are

**Step 2: Create the Remembered Devices Policy**
1. Log in as an administrator with the **Owner** or **Administrator** role
2. Navigate to: **Policies** → **Policies** → **+ Add Policy**
3. Name the policy, then select **Remembered devices** in the left-hand list
4. Select either **Remember devices for browser-based applications with risk-based protection** (the Advantage/Premier default — see [2.1](#21-configure-global-policy)) or **Remember devices for browser-based applications**, and set your desired session duration
5. **Critical:** if you choose the non-risk-based option, do **not** select **Remember devices on a per-application basis**. Passport technically tolerates it but the setting prevents sessions initiated by one application from being shared with others, including sessions started by Windows Logon — which removes the entire point of Passport.
6. For Windows Logon 4.3.1 and earlier, also enable **Remember devices for Windows Logon** with the same duration. Version 4.3.16 and newer send the Passport signature for every local authentication regardless, so this step can be skipped.
7. Save the policy

**Step 3: Apply to a Pilot, Then Broaden**
1. Navigate to: **Applications** → **Applications** and open the target application
2. Under **Application-Group policies**, click **Apply a policy to groups of users**, select the Passport policy, and choose a pilot group
3. Expand to the remaining applications once verified

#### Validation & Testing
1. Authenticate to one Duo-protected web application on a Passport-enabled endpoint, then open a second Duo-protected application — the second should not prompt for MFA
2. Log out of Windows, restart the machine, or quit the Duo Desktop app, and confirm the Passport session terminates
3. On a device without TPM 2.0 / Secure Enclave, confirm Passport does not establish a session and the user falls back to standard authentication
4. Confirm Duo Desktop authentication itself does **not** start a Passport session — this is documented behaviour, not a misconfiguration

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls over authenticated sessions |
| **NIST 800-53** | SC-23 | Session authenticity |
| **NIST 800-53** | IA-2(6) | Access to accounts using hardware-backed authenticators |
| **CIS Controls** | 6.5 | Require MFA for administrative access |

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
| Admin role separation | ❌ (all admins are Owners) | ✅ | ✅ | ✅ |
| Admin session/idle limits | ❌ | ✅ | ✅ | ✅ |
| Trusted Endpoints | ❌ | ✅ | ✅ | ✅ |
| Device Insight / Endpoints pages | ❌ | ❌ | ✅ | ✅ |
| Trust Monitor | ❌ | ❌ | Removed 2026-07-27 | Removed 2026-07-27 |
| Cisco Identity Intelligence | ❌ | ❌ | ✅ | ✅ |
| Risk-Based Remembered Devices | ❌ | ❌ | ✅ (default on) | ✅ (default on) |
| Duo Passport | ❌ | ❌ | ✅ | ✅ |
| Admin API | ❌ | ✅ | ✅ | ✅ |

Trusted Endpoints is included from Essentials upward — the "Duo Beyond" plan name in older guidance is retired. Trust Monitor was removed from the Admin Panel on 2026-07-27 and its API reaches end-of-support on 2027-01-31; Cisco Identity Intelligence is the included replacement on Advantage and Premier.

---

## Appendix B: References

**Official Cisco Duo Documentation:**
- [Duo Documentation](https://duo.com/docs)
- [Policy & Control](https://duo.com/docs/policy)
- [Administration — Administrators](https://duo.com/docs/administration-admins)
- [Trusted Endpoints](https://duo.com/docs/trusted-endpoints)
- [Duo Passport](https://duo.com/docs/passport)
- [Duo Identity Security with Cisco Identity Intelligence](https://duo.com/docs/identity-security)
- [Duo Trust Monitor (removal and migration timeline)](https://duo.com/docs/trust-monitor)
- [Windows Logon & RDP](https://duo.com/docs/rdp)

**API & Developer Documentation:**
- [Admin API](https://duo.com/docs/adminapi)
- [Auth API](https://duo.com/docs/authapi)

**Best Practices:**
- [MFA Enrollment Best Practices](https://duo.com/blog/best-practices-for-enrolling-users-in-mfa)
- [Phishing-Resistant MFA](https://duo.com/learn/phishing-resistant-mfa)

**Compliance Frameworks:**
- Framework mappings for the controls in this guide are in [§7 Compliance Quick Reference](#7-compliance-quick-reference). For attestation evidence, request the current reports through your Cisco account team and validate them against your own control set — a vendor assurance page is not configuration guidance and is out of scope for this project's source standard.

**Security Incidents:**
- **April 2024 Telephony Provider Breach:** An unnamed provider handling Duo SMS and VoIP MFA messages was compromised via phishing. The attacker accessed SMS/VoIP message logs (phone numbers, carriers, metadata) for approximately 1% of Duo customers between March 1-31, 2024. No message content was exposed.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.1 | draft | Add first Code Packs (sdk, official duo_client Python SDK against the Admin API): 1.1 administrator role audit with Owner-count check (GET /admin/v1/admins), 2.2 bypass-status user audit and 3.1 never-enrolled/stale-account report (GET /admin/v1/users), 6.1 v2 authentication-log JSONL export for SIEM (GET /admin/v2/logs/authentication with next_offset pagination); wire Code Implementation includes into 1.1, 2.2, 3.1, and 6.1 | Claude Code (Fable 5) |
| 2026-08-08 | 0.2.0 | draft | Record Trust Monitor's removal from the Admin Panel (2026-07-27; API EOS 2027-01-31) and repoint 4.2 and 6.1 to Cisco Identity Intelligence with its provisioning path; correct 1.1 — admin MFA is mandatory, not a toggle — and replace the six-role list with the documented ten roles plus the Owner-only API-application constraint and the post-2026-05-11 SCC provisioning caveat; add 1.3 admin session/idle limits; add a changed-default callout in 2.1 for Risk-Based Remembered Devices (on by default on Advantage/Premier, 30-day suppression, 7-day passwordless cap); correct 4.1 for the 2024-10-07 certificate-verification EOL, the retired "Duo Beyond" plan name, and the fifteen current integrations; rewrite 6.3 as the sourced Duo Passport control; add missing Attack Prevented to 1.1, 1.2, 2.2, 2.3, 3.1, and 4.2; rebuild the plan table and purge trust-portal/compliance-marketing references | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with admin security, policies, and monitoring | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
