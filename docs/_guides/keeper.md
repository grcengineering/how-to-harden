---
layout: guide
title: "Keeper Security Hardening Guide"
vendor: "Keeper Security"
slug: "keeper"
tier: "2"
category: "Identity"
description: "Enterprise password manager hardening for Keeper Security including role enforcement, MFA, and admin console security"
version: "0.2.1"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Keeper Security is a leading zero-knowledge password management platform protecting credentials for **millions of users** across enterprises. With its zero-knowledge security architecture, Keeper ensures that only users can decrypt their vault data. Proper enterprise configuration ensures administrative controls are properly applied while maintaining the security model.

### Intended Audience
- Security engineers managing password management
- IT administrators configuring Keeper Enterprise
- GRC professionals assessing credential security
- Third-party risk managers evaluating password managers

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Keeper Enterprise admin console security, role-based enforcement policies, MFA configuration, and SSO integration.

---

## Table of Contents

1. [Admin Console Security](#1-admin-console-security)
2. [Role-Based Enforcement Policies](#2-role-based-enforcement-policies)
3. [Authentication & MFA](#3-authentication--mfa)
4. [SSO Integration](#4-sso-integration)
5. [Monitoring & Compliance](#5-monitoring--compliance)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Admin Console Security

### 1.1 Protect Keeper Administrator Accounts (Ensure an Administrator Exists Outside of SSO)

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6, CP-2 |

#### Description
Protect Keeper Administrator accounts as they have full control over the enterprise deployment — and keep at least one Keeper Administrator who authenticates with a Master Password rather than through SSO, so a failure of the identity provider does not lock the organization out of its own tenant permanently.

#### Rationale
**Why This Matters:**
- Keeper support cannot elevate users to admin or reset admin passwords by design — this is a property of the zero-knowledge architecture, not a support-policy gap that can be escalated
- Keeper's own recommended security settings call for **ensuring an administrator exists outside of SSO**: if the organization federates every admin and then loses the IdP — outage, misconfiguration, tenant compromise, or vendor exit — there is no path back into the Keeper tenant, and the loss is permanent
- At least two users should hold the Keeper Administrator role, with at least one of them able to sign in with a Master Password independent of the IdP
- Break-glass accounts are essential, and their credentials must be recoverable without the IdP that they exist to work around

**Attack Prevented:** Permanent tenant lockout from IdP loss or compromise; single-admin dependency; denial of administrative access following an identity-provider outage or takeover

#### ClickOps Implementation

**Step 1: Ensure Redundant Admins — Including One Outside SSO**
1. Navigate to: **Admin Console** → **Admin** → **Roles**
2. Verify **Keeper Administrator** role has 2+ members
3. Confirm at least one Keeper Administrator authenticates with a **Master Password** and is **not** in an SSO-enforced role
4. Ensure backup admin has different credentials
5. Document break-glass account procedures

**Step 2: Protect Admin Accounts**
1. Require MFA for all admin accounts
2. Use strong master passwords (20+ characters)
3. Store break-glass credentials securely (physical safe)

**Step 3: Limit Admin Access**
1. Apply principle of least privilege
2. Reduce total number of administrators
3. Use delegated admin roles where possible
4. Remove unnecessary admin privileges

**Time to Complete:** ~30 minutes

---

### 1.2 Configure IP Address Allowlisting for Admins

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17, SC-7 |

#### Description
Restrict admin access to approved IP addresses to prevent unauthorized administrative actions.

#### Rationale
**Why This Matters:**
- At minimum, users with admin privileges should be IP-restricted
- Prevents malicious insider attacks
- Protects against identity provider takeover vectors — an attacker holding a valid federated session still has to originate from an approved network

**Attack Prevented:** Admin account takeover from attacker infrastructure, malicious insider access from unapproved networks, exploitation of a compromised identity provider

#### ClickOps Implementation

**Step 1: Configure IP Allowlist**
1. Navigate to: **Admin Console** → **Admin** → **Roles**
2. Select admin role
3. Navigate to **Enforcement Policies** → **IP Allowlist**
4. Add allowed IP addresses:
   - Corporate network IPs
   - VPN egress IPs
   - Secure admin workstation IPs

**Step 2: Apply to Admin Roles**
1. Apply IP restrictions to:
   - Keeper Administrator role
   - All custom admin roles
2. Test access from allowed IPs
3. Verify blocked from other IPs

---

### 1.3 Enable Administrative Event Alerts

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Configure alerts for administrative events to detect suspicious activity.

#### Rationale
**Why This Matters:**
- Administrative actions in Keeper (role changes, policy edits, user provisioning) directly alter who can access vaults and under what controls
- Without real-time alerting, a compromised or rogue admin can weaken enforcement policies or create backdoor accounts unnoticed
- Timely alerts shrink the detection window, letting the security team respond before the damage spreads
- Routing events to a SIEM creates an independent record that survives tampering inside the console

**Attack Prevented:** Stealthy privilege escalation, malicious policy weakening, insider abuse, delayed breach detection

#### ClickOps Implementation

**Step 1: Configure Alerts**
1. Navigate to: **Admin Console** → **Reporting & Alerts**
2. Enable alerts for:
   - Admin login events
   - Role modifications
   - Policy changes
   - User provisioning/deprovisioning

**Step 2: Configure Notification Recipients**
1. Add security team email addresses
2. Configure alert thresholds
3. Integrate with SIEM if available

---

## 2. Role-Based Enforcement Policies

### 2.1 Configure Master Password Requirements

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2 |
| NIST 800-53 | IA-5 |

#### Description
Configure master password requirements through role enforcement policies.

#### Rationale
**Why This Matters:**
- In Keeper's zero-knowledge model the master password derives the key that decrypts the entire vault, so its strength is the last line of defense
- Weak or short master passwords are vulnerable to offline brute-force once a device, backup, or hash is obtained
- Enforcing length and complexity by role guarantees a consistent baseline instead of relying on individual user choices
- Preventing reuse stops a password already exposed elsewhere from unlocking the vault

**Attack Prevented:** Brute-force cracking, credential stuffing, password reuse, dictionary attacks

#### ClickOps Implementation

**Step 1: Access Role Enforcement**
1. Navigate to: **Admin Console** → **Admin** → **Roles**
2. Select role to configure
3. Click **Enforcement Policies**

**Step 2: Configure Password Policy**
1. Navigate to **Master Password** section
2. Configure:
   - **Minimum length:** 16+ characters
   - **Complexity requirements:** Mixed case, numbers, symbols
   - **Maximum age:** Optional (modern guidance prefers strong passwords without forced rotation)
   - **Password history:** Prevent reuse

**Step 3: Apply to All Users**
1. Apply policy to all user roles
2. Allow grace period for compliance
3. Monitor compliance dashboard

---

### 2.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all users accessing their Keeper vault.

#### Rationale
**Why This Matters:**
- A Keeper vault holds every credential a user owns, making a single compromised login a master key to the organization
- 2FA blocks attackers who have phished or guessed the master password but lack the second factor
- Phishing-resistant factors like FIDO2/WebAuthn defeat man-in-the-middle and replay attacks that weaker factors cannot
- Disabling SMS removes the SIM-swap vector that undermines one-time-code second factors

**Attack Prevented:** Credential theft, phishing, password-only account takeover, SIM-swap

#### ClickOps Implementation

**Step 1: Configure 2FA Enforcement**
1. Navigate to: **Role** → **Enforcement Policies** → **Two-Factor Authentication**
2. Enable **Require 2FA**
3. Configure:
   - **Prompting frequency:** Every login (most secure)
   - **Allowed methods:** Select approved factors

**Step 2: Configure Allowed 2FA Methods**
1. Enable secure methods:
   - **Keeper DNA (Apple Watch):** Biometric
   - **TOTP Authenticator:** Google Authenticator, etc.
   - **FIDO2 WebAuthn:** Hardware keys (recommended)
   - **Duo Security:** If integrated
   - **RSA SecurID:** If integrated
2. Consider disabling:
   - SMS (vulnerable to SIM swap)

**Step 3: Configure Dual 2FA (L3)**
1. For SSO users, enable 2FA on both:
   - Identity provider side
   - Keeper side (additional layer)

#### Code Implementation

{% include pack-code.html vendor="keeper" section="2.2" %}

---

### 2.3 Configure Sharing and Export Restrictions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control how records can be shared and exported from Keeper.

#### Rationale
**Why This Matters:**
- Uncontrolled export lets a user (or an attacker on their session) bulk-extract every credential in plaintext, defeating the vault's protections
- External sharing can leak secrets to personal accounts or third parties outside organizational oversight
- Restricting sharing to within the organization keeps records inside auditable, policy-governed boundaries
- Disabling printing and export reduces insider data-exfiltration and accidental-exposure paths

**Attack Prevented:** Credential exfiltration, insider data theft, unauthorized external sharing, accidental leakage

#### ClickOps Implementation

**Step 1: Configure Sharing Policies**
1. Navigate to: **Role** → **Enforcement Policies** → **Sharing**
2. Configure:
   - **Allow sharing:** Within organization only (L2)
   - **Allow external sharing:** Disable or require approval
   - **One-time share:** Configure expiration

**Step 2: Configure Export Restrictions**
1. Navigate to: **Enforcement Policies** → **Export**
2. Configure:
   - **Allow export:** Disable for L2+ environments
   - **Allow printing:** Disable if not needed

---

### 2.4 Restrict Browser Extensions and Disable Built-In Browser Password Managers

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | CM-7 |

#### Description
Control which browser extensions users can install to prevent malicious extensions from accessing vault data, and disable the browser's own built-in password manager so credentials do not accumulate in a second, uncontrolled store.

#### Rationale
**Why This Matters:**
- Browser extensions with elevated permissions can access information in websites
- Malicious extensions could capture vault data
- Limit to Keeper and approved extensions only
- Keeper's recommended security settings call for disabling the browser's native password manager: a browser-stored credential store sits outside Keeper's zero-knowledge encryption, outside role enforcement policies, and outside the audit trail — it is a second credential vault the security team does not administer
- Built-in browser stores commonly sync to a personal browser profile, carrying corporate credentials to personal devices with no offboarding path

**Attack Prevented:** Vault data capture by malicious extensions, credential theft from an unencrypted or weakly-protected browser credential store, credential sprawl to personal browser profiles that survive offboarding

#### ClickOps Implementation

**Step 1: Configure Extension Policy**
1. Use device management (MDM) to:
   - Allow only Keeper browser extension
   - Block unapproved extensions
   - Remove unknown extensions

**Step 2: Disable the Browser's Built-In Password Manager**
1. Use browser management policy (MDM / group policy / browser enterprise policy) to disable password saving and autofill in Chrome, Edge, Firefox, and Safari
2. Disable browser profile sync for passwords on managed devices
3. Direct users to migrate any credentials already saved in the browser into Keeper, then clear the browser store

**Step 3: Document Approved Extensions**
1. Create whitelist of approved extensions
2. Communicate policy to users
3. Regular audit of installed extensions

---

### 2.5 Enable Account Transfer for Departed Employees

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3, 6.2 |
| NIST 800-53 | AC-2, CP-2 |

#### Description
Enable Keeper's **Account Transfer** enforcement policy and assign an eligible transfer role, so that when an employee leaves the organization their vault contents can be recovered by an authorized party instead of being lost with the account.

#### Rationale
**Why This Matters:**
- Keeper's zero-knowledge model means an offboarded user's vault is not readable by administrators by default — without Account Transfer configured in advance, the credentials in that vault are gone when the account is deprovisioned
- Shared infrastructure, service-account, and vendor credentials frequently live only in an individual's vault; losing them at offboarding causes outages and forces emergency rotations of secrets nobody has a copy of
- Account Transfer must be enabled and an eligible role assigned **before** the departure — it cannot be retrofitted onto an account after the fact
- A documented transfer path also removes the incentive for departing employees to export or copy credentials "just in case," which is exactly the exfiltration behavior sharing and export restrictions exist to stop

**Attack Prevented:** Permanent loss of business credentials at offboarding, emergency uncontrolled secret rotation, pre-departure credential exfiltration driven by a missing recovery path

#### ClickOps Implementation

**Step 1: Enable Account Transfer**
1. Navigate to: **Admin Console** → **Admin** → **Roles**
2. Select the role covering the users whose vaults must be recoverable
3. Click **Enforcement Policies** → **Transfer Account**
4. Enable the account transfer policy for that role

**Step 2: Assign the Eligible Transfer Role**
1. Designate the role whose members are permitted to receive transferred vaults (typically a small security or IT role)
2. Confirm the transfer relationship is in place for every role that holds business credentials
3. Restrict membership of the receiving role tightly — its members can inherit vault contents

**Step 3: Document the Offboarding Runbook**
1. Add the transfer step to the standard offboarding checklist, executed before the account is deleted
2. Record who received each transferred vault
3. Rotate any high-value credentials recovered through transfer

#### Code Implementation

{% include pack-code.html vendor="keeper" section="2.5" %}

#### Validation & Testing
1. Run a transfer against a test account and confirm the receiving admin can access the transferred records
2. Confirm every role holding business credentials has the policy enabled

---

### 2.6 Restrict Client Platforms

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.8 |
| NIST 800-53 | CM-7, AC-3 |

#### Description
Use Keeper's **Platform Restriction** enforcement policies to control which Keeper clients a role may use — Web Vault, browser extensions, mobile apps, desktop app, KeeperChat, and the Commander SDK/CLI — and disable the ones the role has no business need for.

#### Rationale
**Why This Matters:**
- Every enabled client is an authenticated path into the vault; a role that only ever uses the browser extension does not need six other doors left open
- **Commander SDK/CLI** deserves particular attention: it is the programmatic, scriptable interface to the vault, and it is the client best suited to bulk extraction. A standard user role has no reason to hold it, and leaving it enabled hands an attacker with a valid session the most efficient exfiltration tool Keeper ships
- Disabling unused mobile and desktop clients keeps vault data off endpoint classes that fall outside MDM enrollment and EDR coverage
- Platform restriction is enforced by role, so it can be tightened for standard users while remaining available to the small set of engineers and admins who genuinely need programmatic access

**Attack Prevented:** Bulk credential extraction via programmatic clients, vault access from unmanaged device classes, expansion of the authenticated attack surface beyond what the role's job requires

#### ClickOps Implementation

**Step 1: Review Platforms Per Role**
1. Navigate to: **Admin Console** → **Admin** → **Roles**
2. Select the role → **Enforcement Policies** → **Platform Restriction**
3. Review which clients are currently permitted

**Step 2: Disable Unused Clients**
1. Disable the clients the role does not need — commonly KeeperChat, desktop, or mobile for a browser-only population
2. **Disable Commander SDK/CLI for all standard user roles**; enable it only for a narrow, named automation or admin role
3. Keep the client set aligned with the devices the role is actually issued

**Step 3: Communicate and Monitor**
1. Notify affected users before enforcing, so a blocked client is a policy outcome and not a help-desk incident
2. Review platform restrictions when roles change

#### Validation & Testing
1. Attempt to sign in with a disabled client as a member of the restricted role and confirm access is refused
2. Confirm Commander SDK/CLI access is limited to the intended role only

---

## 3. Authentication & MFA

### 3.1 Configure Biometric Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2 |

#### Description
Configure biometric authentication options for improved security and usability.

#### Rationale
**Why This Matters:**
- Biometric unlock lets users keep a long, complex master password without retyping it constantly, reducing pressure to choose a weak one
- Device-bound biometrics (Touch ID, Windows Hello, Face ID) keep the unlock factor on the local device, away from network attackers
- Restricting which biometric methods are allowed prevents users from enabling weaker or unsupported options
- Periodic master-password re-entry ensures the underlying secret is still known and not lost behind biometrics alone

**Attack Prevented:** Shoulder-surfing, keylogging of typed passwords, weak-password adoption, unattended-device access

#### ClickOps Implementation

**Step 1: Enable Biometrics**
1. Navigate to: **Role** → **Enforcement Policies** → **Biometrics**
2. Configure allowed biometric methods:
   - Windows Hello
   - Touch ID
   - Face ID
   - Android biometrics

**Step 2: Configure Biometric Policy**
1. Set biometric timeout
2. Require master password periodically
3. Configure fallback authentication

---

### 3.2 Configure Account Recovery

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2 |
| NIST 800-53 | IA-5 |

#### Description
Configure account recovery deliberately — and in SSO organizations, disable it. Keeper's recommended security settings call for turning **Account Recovery (Recovery Phrase) off** for SSO-authenticated users, because the identity provider is already the recovery path and a second one only widens the attack surface.

> **Correction — this reverses common guidance, including an earlier revision of this guide.** For organizations using SSO, Keeper recommends **disabling** account recovery rather than configuring it. Set **Role → Enforcement Policies → Account Settings → Recovery Phrase** to disabled for SSO-authenticated roles. Enabling recovery for federated users creates a bypass around the IdP that is not subject to the IdP's MFA, conditional access, or session policy — which is the entire reason the IdP was put in front of Keeper. Source: [Keeper Security Benchmarks and Recommended Settings](https://docs.keeper.io/en/enterprise-guide/recommended-security-settings).

#### Rationale
**Why This Matters:**
- Account recovery is a deliberate bypass of normal authentication, so for a federated user it is a path into the vault that never touches the identity provider's controls
- In an SSO organization the IdP already owns account recovery; a second recovery mechanism inside Keeper duplicates the function while subtracting the IdP's MFA and conditional-access enforcement
- Where recovery must remain enabled (non-SSO roles, or the Master Password administrator required by [1.1](#11-protect-keeper-administrator-accounts-ensure-an-administrator-exists-outside-of-sso)), approval workflows and verification steps prevent help-desk social engineering
- Logging every recovery event creates accountability and an audit trail for forensic review

**Attack Prevented:** Account-recovery abuse as an IdP bypass, help-desk social engineering, unauthorized vault access, self-service takeover

#### ClickOps Implementation

**Step 1: Disable Recovery for SSO Roles**
1. Navigate to: **Admin Console** → **Admin** → **Roles** → select an SSO-authenticated role
2. Open **Enforcement Policies** → **Account Settings**
3. Disable **Recovery Phrase** (account recovery) for that role
4. Repeat for every role whose members authenticate through the identity provider

**Step 2: Harden Recovery Where It Must Remain**
1. For non-SSO roles — including the Master Password administrator retained under [1.1](#11-protect-keeper-administrator-accounts-ensure-an-administrator-exists-outside-of-sso) — keep recovery configured but controlled
2. Require verification steps and an approval workflow before recovery completes
3. Log and review all recovery events

#### Validation & Testing
1. As a test SSO user, confirm the account-recovery option is not offered
2. Confirm the non-SSO administrator's recovery path is documented, tested, and stored securely

---

### 3.3 Enable Biometric Login With a Passkey

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1), IA-2(6) |

#### Description
Enable **Biometric Login with a Passkey** so users authenticate to the vault with a device-bound passkey and biometric instead of typing a master password and a one-time code.

#### Rationale
**Why This Matters:**
- A passkey login replaces **both** factors — it is the authentication, not an additional step layered on a password, so there is no password left to phish and no code left to relay
- Passkeys are phishing-resistant by construction: the credential is bound to Keeper's origin, so an adversary-in-the-middle proxy that defeats push and TOTP factors gets nothing usable
- The passkey is held by the platform authenticator and unlocked by the device biometric, keeping the secret on hardware the user physically holds
- Removing the typed master password from the daily login flow also removes it from keyloggers and shoulder-surfing

**Attack Prevented:** Phishing, adversary-in-the-middle credential relay, MFA fatigue, keylogging of the master password, one-time-code interception

#### Prerequisites
- A device with a platform authenticator (Windows Hello, Touch ID, Face ID, Android biometrics)

#### ClickOps Implementation

**Step 1: Enable the Policy**
1. Navigate to: **Admin Console** → **Admin** → **Roles** → select role
2. Open **Enforcement Policies** and enable **Biometric Login** / passkey login for the role

**Step 2: Roll Out to Users**
1. Have users register a passkey from a device they control
2. Confirm the master password is still known and recorded securely — the passkey is the login, not a replacement for knowing the underlying secret

#### Validation & Testing
1. Sign in with the passkey and confirm no master password or second factor is requested
2. Confirm registration succeeds on the device classes your users actually carry

> **Scope limitation — platform authenticators only.** Keeper's biometric passkey login uses the **device's built-in platform authenticator** and is **device-bound**. Roaming security keys (a portable FIDO2 hardware key moved between machines) are **not** supported for this login method. Plan enrollment per device: a user with a laptop and a phone registers on each, and a user who loses their only registered device falls back to the master password path — which is another reason [1.1](#11-protect-keeper-administrator-accounts-ensure-an-administrator-exists-outside-of-sso) and [3.2](#32-configure-account-recovery) matter.

---

### 3.4 Harden Session, Offline, and Clipboard Behavior

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.3, 3.3 |
| NIST 800-53 | AC-11, AC-12, SC-28 |

#### Description
Use role enforcement policies to bound how long a vault session lives, whether a decrypted copy of the vault can exist offline, and how long secrets linger on the clipboard or in the deleted-records store.

#### Rationale
**Why This Matters:**
- **Offline access** keeps a decrypted-capable copy of the vault on the endpoint, so a stolen or compromised laptop no longer needs network access or a live session to be useful to an attacker; restricting it removes that standing local copy
- **Stay Logged In** turns a single successful authentication into an indefinite one; disabling it, together with a **Logout Timer**, ensures an unattended or stolen device does not hold an open vault
- **Require Re-authentication** for sensitive actions means a hijacked session cannot silently perform the operations that matter most
- **Clipboard expiration** matters because copied credentials are readable by any process on the machine and are captured by clipboard-history features; a short expiry bounds that exposure
- **Retention of deleted records** determines how long a "deleted" secret is still recoverable — relevant both for accidental-deletion recovery and for ensuring rotated credentials actually leave the system

**Attack Prevented:** Offline vault extraction from a stolen endpoint, session hijacking and unattended-device access, clipboard scraping by malware or clipboard-history tooling, recovery of secrets believed deleted

#### ClickOps Implementation

**Step 1: Restrict Offline Access**
1. Navigate to: **Admin Console** → **Admin** → **Roles** → select role → **Enforcement Policies**
2. Restrict offline access for roles that do not have a genuine disconnected-work requirement

**Step 2: Bound the Session**
1. Disable **Stay Logged In**
2. Set a **Logout Timer** short enough that an unattended device does not stay unlocked
3. Enable **Require Re-authentication** for sensitive actions

**Step 3: Bound Data at Rest on the Endpoint and in the Vault**
1. Set a short **Clipboard Expiration** so copied secrets clear automatically
2. Set **Retention of Deleted Records** to a period that balances accidental-deletion recovery against leaving rotated secrets recoverable indefinitely

#### Validation & Testing
1. Confirm a session ends at the configured logout timer and that "stay logged in" is not offered
2. Copy a record and confirm the clipboard clears within the configured window
3. Confirm offline access is refused for restricted roles

---

## 4. SSO Integration

### 4.1 Configure SAML SSO

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Integrate Keeper with your SAML identity provider for centralized authentication.

#### Rationale
**Why This Matters:**
- Centralizing authentication in the corporate IdP enforces MFA, conditional access, and session policy on every Keeper login
- SSO removes a standalone Keeper password that could be phished or reused, shrinking the credential attack surface
- Group-to-role mapping keeps Keeper access aligned with IdP identity, so deprovisioning at the IdP cuts off vault access
- Because the IdP becomes the gateway to all vaults, it must itself be locked down with MFA or it becomes a single point of failure

**Attack Prevented:** Credential reuse, phishing of standalone passwords, orphaned-account access, inconsistent access policy

#### Prerequisites
- Keeper SSO Connect Cloud license
- SAML 2.0 compatible identity provider

#### ClickOps Implementation

**Step 1: Configure SSO Connect Cloud**
1. Navigate to: **Admin Console** → **SSO Configuration**
2. Click **Add SSO Configuration**
3. Configure SAML settings:
   - Entity ID
   - SSO URL
   - Certificate

**Step 2: Configure Identity Provider**
1. Create SAML application in IdP
2. Upload Keeper metadata
3. Configure attribute mappings:
   - Email (required)
   - First name, last name (optional)
4. Configure groups for role mapping

**Step 3: Secure SSO Configuration**
1. **Critical:** Lock down IdP with MFA
2. Follow IdP security best practices
3. Ensure admin accounts are secured

---

### 4.2 Configure Just-in-Time Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure automatic user provisioning through SSO.

#### Rationale
**Why This Matters:**
- Automated provisioning creates accounts with the correct default role and policies instead of error-prone manual setup
- JIT and SCIM tie the account lifecycle to the IdP, so departing users are deprovisioned promptly and don't retain standing vault access
- Eliminating manual account creation reduces the chance of over-privileged or forgotten accounts
- Consistent provisioning applies enforcement policies to every new user from first login

**Attack Prevented:** Orphaned-account access, privilege misassignment, lingering ex-employee access, inconsistent policy application

#### ClickOps Implementation

**Step 1: Enable JIT Provisioning**
1. Navigate to: **SSO Configuration** → **Provisioning**
2. Enable **Just-in-Time provisioning**
3. Configure default role for new users

**Step 2: Configure SCIM (Alternative)**
1. For automated lifecycle management
2. Configure SCIM endpoint
3. Integrate with IdP SCIM

---

## 5. Monitoring & Compliance

### 5.1 Configure Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and review audit logs for security events.

#### Rationale
**Why This Matters:**
- Audit logs are the primary evidence for detecting credential access, sharing, and admin abuse inside the vault
- Streaming events to a SIEM preserves an independent, tamper-evident record outside the Keeper console
- Monitoring failed logins and 2FA changes surfaces brute-force and account-takeover attempts early
- Without complete logging, incidents go undetected and post-breach forensics and compliance reporting become impossible

**Attack Prevented:** Undetected intrusion, log tampering, delayed incident response, audit gaps

#### ClickOps Implementation

**Step 1: Access Reporting**
1. Navigate to: **Admin Console** → **Reporting & Alerts**
2. Review available reports:
   - Login activity
   - Record access
   - Sharing activity
   - Admin actions

**Step 2: Configure SIEM Integration**
1. Navigate to: **Reporting & Alerts** → **SIEM Integration**
2. Configure export destination:
   - Splunk
   - Azure Sentinel
   - Custom webhook
3. Select events to stream

**Key Events to Monitor:**
- Failed login attempts
- 2FA changes
- Record sharing
- Admin privilege changes
- Policy modifications

#### Code Implementation

{% include pack-code.html vendor="keeper" section="5.1" %}

---

### 5.2 Monitor Security Audit

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Use Security Audit to monitor organization password health.

#### Rationale
**Why This Matters:**
- Weak and reused passwords across the organization are exploitable even when the vault platform itself is secure
- The Security Audit dashboard quantifies risk (weak/reused passwords, low 2FA adoption) so remediation can be prioritized
- Tracking 2FA adoption identifies accounts still protected by a single factor and at higher takeover risk
- Continuous monitoring turns password hygiene into a measurable, improvable program rather than a one-time check

**Attack Prevented:** Credential stuffing via reused passwords, weak-password cracking, single-factor account takeover

#### ClickOps Implementation

**Step 1: Access Security Audit**
1. Navigate to: **Admin Console** → **Security Audit**
2. Review dashboard metrics:
   - Overall security score
   - Password strength distribution
   - Reused passwords
   - 2FA adoption

**Step 2: Identify Issues**
1. Review weak passwords
2. Identify reused credentials
3. Track 2FA compliance

**Step 3: Remediation**
1. Notify users with weak passwords
2. Set improvement targets
3. Track progress over time

#### Code Implementation

{% include pack-code.html vendor="keeper" section="5.2" %}

---

### 5.3 BreachWatch Integration

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.4 |
| NIST 800-53 | SI-4 |

#### Description
Enable BreachWatch to detect compromised credentials.

#### Rationale
**Why This Matters:**
- Credentials exposed in third-party breaches are quickly weaponized for credential-stuffing against corporate systems
- BreachWatch continuously checks stored records against known breach data so exposed passwords are flagged before attackers use them
- Prompt notification and forced rotation close the window between exposure and exploitation
- Investigating the exposure source helps identify reuse patterns and at-risk accounts across the organization
- BreachWatch findings only drive response if they leave the console: Keeper documents a named enforcement policy, **Send BreachWatch Events to Reporting Systems and External SIEM**, which routes these events into the same pipeline as the rest of your detections instead of leaving them on a dashboard nobody is paged for

**Attack Prevented:** Credential stuffing, breach-replay attacks, account takeover from reused or exposed passwords, undetected exposure sitting unread in a console

#### ClickOps Implementation

**Step 1: Enable BreachWatch**
1. Navigate to: **Admin Console** → **BreachWatch**
2. Enable for organization
3. Configure alert settings

**Step 2: Route Events to Your SIEM**
1. Navigate to: **Admin Console** → **Admin** → **Roles** → select role → **Enforcement Policies**
2. Enable **Send BreachWatch Events to Reporting Systems and External SIEM**
3. Confirm events arrive in the SIEM configured in [5.1](#51-configure-audit-logging) and build an alert on them

**Step 3: Respond to Alerts**
1. When credentials detected:
   - Notify affected users
   - Require password change
   - Investigate exposure source
2. Document incident response

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Keeper Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | 2FA enforcement | [2.2](#22-enforce-two-factor-authentication) |
| CC6.1 | Master password policy | [2.1](#21-configure-master-password-requirements) |
| CC6.2 | Admin protection | [1.1](#11-protect-keeper-administrator-accounts-ensure-an-administrator-exists-outside-of-sso) |
| CC6.6 | IP allowlisting | [1.2](#12-configure-ip-address-allowlisting-for-admins) |
| CC7.2 | Audit logging | [5.1](#51-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Keeper Control | Guide Section |
|---------|----------------|---------------|
| IA-2(1) | MFA | [2.2](#22-enforce-two-factor-authentication) |
| IA-5 | Password policy | [2.1](#21-configure-master-password-requirements) |
| AC-6 | Least privilege | [1.1](#11-protect-keeper-administrator-accounts-ensure-an-administrator-exists-outside-of-sso) |
| AU-2 | Audit logging | [5.1](#51-configure-audit-logging) |
| SI-4 | BreachWatch | [5.3](#53-breachwatch-integration) |

---

## Appendix A: Plan Compatibility

| Feature | Business | Enterprise | Enterprise Plus |
|---------|----------|------------|-----------------|
| Role Enforcement | Basic | ✅ | ✅ |
| SSO Connect Cloud | ❌ | ✅ | ✅ |
| SCIM Provisioning | ❌ | ✅ | ✅ |
| BreachWatch | Add-on | Add-on | ✅ |
| Advanced Reporting | Basic | ✅ | ✅ |
| SIEM Integration | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official Keeper Documentation:**
- [Keeper Documentation](https://docs.keeper.io/en)
- [Security Benchmarks and Recommended Settings](https://docs.keeper.io/en/enterprise-guide/recommended-security-settings)
- [Enforcement Policies](https://docs.keeper.io/en/enterprise-guide/roles/enforcement-policies)
- [Two-Factor Authentication](https://docs.keeper.io/en/enterprise-guide/two-factor-authentication)

**API & Developer Resources:**
- [Developer Tools](https://docs.keeper.io/en/enterprise-guide/developer-tools)
- [Keeper Commander CLI](https://docs.keeper.io/en/keeper-commander/overview)
- [Keeper Secrets Manager](https://docs.keeper.io/en/secrets-manager/overview)

**SSO Integration:**
- [Admin Console Configuration (SSO Connect)](https://docs.keeper.io/en/sso-connect-on-prem/installation-and-setup/admin-console-configuration)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO 27001, ISO 27017, ISO 27018, FedRAMP Authorized, GovRAMP Authorized, PCI DSS, HIPAA

**Security Incidents:**
- No major public security breaches identified. Keeper's zero-knowledge architecture means the company cannot access customer vault data.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.1 | draft | Add Keeper Commander CLI Code Packs: 2.2 (REQUIRE_TWO_FACTOR role enforcement), 2.5 (transfer-user offboarding + action-report bulk transfer), 5.1 (audit-log SIEM export + audit-report review), 5.2 (security-audit-report + user-report) — all commands verified against Commander enterprise-management and reporting command references | Claude Code (Fable 5) |
| 2026-08-08 | 0.2.0 | draft | Add Account Transfer (2.5), Platform Restriction incl. Commander SDK (2.6), passkey biometric login (3.3), and session/offline/clipboard hardening (3.4); correct 3.2 — Keeper recommends DISABLING account recovery for SSO orgs; sharpen 1.1 to "ensure an administrator exists outside of SSO"; name the BreachWatch SIEM enforcement policy in 5.3; add browser built-in password manager disabling to 2.4; add missing Attack Prevented lines; drop Trust Center and marketing-page references | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with admin security, enforcement policies, and SSO | Claude Code (Opus 4.5) |

**Source coverage note:** This revision is built on Keeper's Tier 1 enterprise documentation (recommended security settings, enforcement policies, two-factor authentication). **No Tier 2 benchmark coverage was confirmed** for Keeper (no CIS Benchmark, DISA STIG, or CISA SCuBA baseline located for this product). Tier 3/4 independent research was **not surveyed** for this revision.

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
