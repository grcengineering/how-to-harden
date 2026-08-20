---
layout: guide
title: "Workday Hardening Guide"
vendor: "Workday"
slug: "workday"
tier: "2"
category: "HR/Finance"
description: "HCM platform hardening for security groups, integration security, and domain policies"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

**60%+ of Fortune 500** rely on Workday for HR and financial management, processing **365 billion transactions annually**. Integration System Users (ISUs) with OAuth access handle payroll, employee PII (SSN, bank accounts), and compensation data. Long-lived refresh tokens amplify token theft risk.

> **Verification note (2026-08-08):** an earlier revision of this guide asserted that Workday refresh tokens are *non-expiring*. That claim could not be re-verified this pass — Workday's OAuth and API-security documentation sits under `doc.workday.com/admin-guide/en-us/authentication-and-security/`, which returns HTTP 401 to unauthenticated readers. Treat token-lifetime specifics in this guide as recommendations to confirm against your own tenant's **Register API Client** configuration, not as asserted platform behavior.

The 2024 Broadcom employee data breach via ransomware attack on ADP/Workday partner Business Systems House demonstrated third-party ecosystem vulnerabilities.

### Intended Audience
- Security engineers hardening HCM systems
- HR technology administrators
- GRC professionals assessing HR compliance
- Third-party risk managers evaluating payroll integrations

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Workday security configurations including authentication, integration security, data privacy controls, and third-party connector hardening.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Integration System User Security](#2-integration-system-user-security)
3. [Data Security & Privacy](#3-data-security--privacy)
4. [API & Integration Security](#4-api--integration-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SAML SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all Workday access, including employee self-service and administrator access.

#### Rationale
**Why This Matters:**
- Workday contains highly sensitive PII (SSN, bank accounts, salary) — a single compromised sign-in exposes an entire workforce's identity and banking data
- Password-only access to a payroll system is directly monetizable: attackers redirect direct deposits and harvest tax identifiers at scale
- Workday exposes several authentication mechanisms in parallel (SAML, OpenID Connect, Workday-native passwords, mobile); any one left ungoverned is an SSO bypass path around your IdP's MFA and conditional access

**Attack Prevented:** Credential theft, phishing, password spraying, MFA bypass via alternate authentication surfaces, payroll-diversion fraud

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Authentication Policies**
2. Create/Edit Authentication Policy:
   - **Name:** "Corporate SSO"
   - **Authentication Type:** SAML
   - **Identity Provider:** Configure IdP metadata

> **Review deprecated SAML fields.** Workday's **SAML Setup** surface carries fields flagged as deprecated and pending retirement. The specifics live behind `doc.workday.com/admin-guide/en-us/authentication-and-security/`, which is 401-gated to unauthenticated readers, so this guide does not enumerate them — review the deprecated-field notices shown on the SAML Setup task in your own tenant and migrate off anything marked for retirement before it is removed.

**Step 2: Configure Security Groups**
1. Assign authentication policy to all security groups
2. Require MFA at IdP level for Workday application

**Step 3: Inventory and Govern Every Parallel Authentication Surface**

Workday's [Tenant Setup - Security](https://doc.workday.com/admin-guide/en-us/manage-workday/tenant-configuration/tenant-setup/dan1370796470031.html) reference groups several authentication mechanisms that operate alongside SAML. Enumerate each and either govern it under the same policy or disable it:

| Surface | Action |
|---------|--------|
| Workday-native password authentication | Disable; retain only documented break-glass accounts (see 1.6) |
| OpenID Connect (Google-based sign-in, which supports Workday's native MFA) | Disable if unused; if used, treat as a second IdP and apply equivalent MFA and conditional-access requirements |
| Mobile Authentication | Confirm mobile sessions inherit the same authentication policy; configure the mobile passcode timeout |
| Trusted Devices | Govern per 1.4 |
| WebAuthn / security keys | Prefer over passwords for any non-SSO access (see 1.5) |

Remove local account access except break-glass, and document each exception with an owner and a review date.

---

### 1.2 Implement Role-Based Security Groups

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure Workday security groups with least-privilege access to HR and financial data.

#### Rationale
**Why This Matters:**
- Workday security groups govern who can view and modify HR, payroll, and financial data — over-broad groups grant standing access far beyond business need
- Least-privilege domain security policies contain the blast radius when any single account is compromised
- Segregation of duties between payroll input and payroll approval prevents one person from both initiating and authorizing fraudulent payments

**Attack Prevented:** Privilege escalation, insider fraud, lateral movement, excessive data exposure

#### ClickOps Implementation

**Step 1: Design Security Group Structure**

**Step 2: Configure Domain Security**
1. Navigate to: **Domain Security Policies**
2. For each functional area:
   - Define view/modify permissions
   - Assign to appropriate security groups
   - Enable "View" vs "Modify" separation

**Step 3: Implement Segregation of Duties**
- Separate payroll input from payroll approval
- Separate benefits setup from enrollment processing
- Document conflicts and implement compensating controls

---

### 1.3 Configure Session Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-12

#### Description
Configure session timeout and management policies.

#### Rationale
**Why This Matters:**
- Idle Workday sessions left open on unattended or shared workstations let anyone resume an authenticated session to sensitive PII
- Short timeouts and re-authentication on extension limit the window an attacker has to use a hijacked or stolen session
- Concurrent-session limits make it harder for a stolen credential to be used alongside the legitimate user without detection

**Attack Prevented:** Session hijacking, unattended-workstation takeover, credential reuse

#### ClickOps Implementation

> **Verify the governing task in your tenant (2026-08-08).** The session-timeout, concurrent-session, and session-extension settings prescribed below were **not locatable** on the current [Tenant Setup - Security](https://doc.workday.com/admin-guide/en-us/manage-workday/tenant-configuration/tenant-setup/dan1370796470031.html) reference, which documents a **Timeout Redirect URL** and a mobile **Passcode Timeout** but not a general session-timeout control. The governing task may differ in your tenant or edition, and Workday's authentication-and-security documentation is 401-gated to unauthenticated readers. Treat the values below as target recommendations and confirm the actual task before writing a runbook against it.

1. Locate the tenant task that governs session behavior (start at **Edit Tenant Setup - Security**, then search your tenant's task index for session/timeout settings).
2. Target configuration:
   - **Session timeout:** 30 minutes (L1) / 15 minutes (L2) — recommendation, not an asserted Workday field name
   - **Concurrent sessions:** limit where the tenant supports it
   - **Session extension:** require re-authentication rather than silent extension
3. Confirmed on the Tenant Setup - Security reference and worth setting regardless:
   - **Timeout Redirect URL** — send timed-out sessions to a controlled landing page rather than a re-authentication prompt an attacker can spoof
   - **Passcode Timeout** (mobile) — shortest interval your workforce tolerates

---

### 1.4 Govern Trusted Devices

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-2(1), IA-3

#### Description
Review and govern Workday's Trusted Devices feature, which lets users mark a device as trusted so it is not re-challenged on every sign-in. It is enabled automatically, and disabling it resets device trust for every user in the tenant at once.

#### Rationale
**Why This Matters:**
- Trusted Devices is **automatically enabled** — no administrator ever chose it, so it is a live authentication-bypass surface in most tenants by default rather than by decision
- A trusted device suppresses re-challenge, so a stolen or shared laptop that was once marked trusted keeps privileged HR and payroll access without further verification
- Disabling the feature **resets the trusted-device list for the entire tenant**, forcing every user to re-verify — a fleet-wide re-MFA event that must be scheduled, communicated, and staffed, not flipped mid-quarter

**Attack Prevented:** Device-trust abuse, MFA suppression on stolen endpoints, persistent access from a compromised or off-boarded device

#### ClickOps Implementation

1. Navigate to: **Edit Tenant Setup - Security**
2. Locate the **Trusted Devices** configuration and record its current state (expect it to be enabled).
3. Decide deliberately:
   - **Keep enabled** where your IdP already enforces device compliance, and pair it with short session timeouts (1.3)
   - **Disable** in regulated environments or where device posture is not independently enforced — but schedule it: disabling resets trust for **all** users and triggers a tenant-wide re-verification wave
4. Communicate any disable in advance to the service desk; the re-MFA spike is indistinguishable from an incident if it is unannounced.

#### Validation & Testing
Sign in from a device previously marked trusted after the change; confirm the challenge behavior matches the configured state.

---

### 1.5 Enable WebAuthn (FIDO2) Authentication

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-2(1), IA-2(8)

#### Description
Enable Workday's native WebAuthn (FIDO2) support so security keys and platform authenticators can be used for phishing-resistant, passwordless authentication to the tenant.

#### Rationale
**Why This Matters:**
- WebAuthn is origin-bound: a credential registered for your Workday tenant cannot be replayed against a lookalike sign-in page, which defeats the credential-phishing and adversary-in-the-middle proxy kits that beat one-time passcodes
- Workday exposes WebAuthn natively on Tenant Setup - Security, so phishing-resistant authentication is available for accounts that cannot route through the corporate IdP — precisely the break-glass and administrator accounts most worth protecting
- Passwordless removes the shared secret entirely, so there is nothing for password spraying or credential-stuffing to hit

**Attack Prevented:** Credential phishing, adversary-in-the-middle passcode relay, password spraying, credential stuffing

#### ClickOps Implementation

1. Navigate to: **Edit Tenant Setup - Security**
2. Enable **WebAuthn** authentication for the tenant.
3. Roll out in order: administrators and break-glass accounts first (L2), then integration owners and payroll/HR staff, then general population (L3).
4. Register at least two authenticators per privileged account so a lost key does not create a lockout.
5. Where accounts authenticate through the corporate IdP, enforce phishing-resistant methods at the IdP as well — WebAuthn in Workday governs Workday-native sign-in, not federated sign-in.

#### Validation & Testing
Register a security key on a test account, sign out, and confirm sign-in completes with the key and without a password.

---

### 1.6 Harden Native Multifactor Authentication Settings

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1), IA-5

#### Description
Configure Workday's native Multifactor Authentication settings — the methods offered and, critically, the maximum grace sign-in count that lets a user bypass MFA enrollment for a set number of sign-ins.

#### Rationale
**Why This Matters:**
- Workday's [Tenant Setup - Security](https://doc.workday.com/admin-guide/en-us/manage-workday/tenant-configuration/tenant-setup/dan1370796470031.html) reference exposes a **Multifactor Authentication Settings** block covering authenticator apps, backup codes, Duo, and email/SMS passcodes — these govern any account that does not reach Workday through your IdP, including break-glass and vendor accounts
- The **maximum grace sign-in count** is an explicit MFA-bypass parameter: every grace sign-in is an authentication that completes without a second factor, so a non-zero value is a documented window an attacker with a valid password can walk through
- Method choice matters: email and SMS passcodes are interceptable via mailbox compromise and SIM swap, while authenticator apps, Duo, and WebAuthn (1.5) are materially harder to relay

**Attack Prevented:** MFA bypass via grace sign-ins, SIM-swap and mailbox-compromise passcode interception, break-glass account takeover

#### ClickOps Implementation

1. Navigate to: **Edit Tenant Setup - Security** → **Multifactor Authentication Settings**
2. Set the **maximum grace sign-in count** to the lowest value your enrollment process tolerates — **0** wherever enrollment can be completed out of band (L2/L3). Any non-zero value is a standing MFA-bypass allowance.
3. Prefer authenticator apps, Duo, or WebAuthn (1.5). Treat email and SMS passcodes as fallback only, and disable them entirely for administrator and break-glass accounts (L3).
4. Issue and escrow **backup codes** for break-glass accounts so a hardened MFA posture does not create a tenant lockout.
5. Re-review after any IdP migration — accounts that fall out of federation land on these native settings.

#### Validation & Testing
Create a test account, confirm it is challenged for a second factor on its first sign-in (grace count 0), and confirm disabled methods are not offered.

---

## 2. Integration System User Security

### 2.1 Secure Integration System Users (ISUs)

**Profile Level:** L1 (Crawl) - CRITICAL
**NIST 800-53:** IA-5, AC-6

#### Description
Harden Integration System Users that provide API access for third-party integrations.

#### Rationale
**Why This Matters:**
- ISUs access sensitive employee data programmatically, at machine speed and volume — one ISU can read more records in a minute than an interactive user reaches in a year
- OAuth tokens issued to ISUs can carry long validity, so a leaked credential stays useful well past the point anyone would notice the original compromise
- ISUs typically sit outside the SSO and MFA controls applied to human accounts, so they are the natural pivot for an attacker who has already breached an integration partner

**Attack Prevented:** Bulk PII exfiltration via compromised integrations, supply-chain pivot from a breached partner, standing programmatic access outside SSO/MFA

**Real-World Incident:**
- **2024 Broadcom Breach:** Partner Business Systems House (BSH) was compromised, exposing employee data from ADP/Workday integrations

#### ClickOps Implementation

**Step 1: Audit Existing ISUs**
1. Navigate to: **View Integration System Users**
2. Document for each ISU:
   - Purpose/integration
   - Security groups assigned
   - Data access scope
   - Last activity date

**Step 2: Create Purpose-Specific ISUs**
For each integration, create dedicated ISU.

**Step 3: Restrict ISU Security Groups**
1. Create integration-specific security groups
2. Grant minimum required domain permissions
3. Document data access justification

**Step 4: Configure ISU Authentication**
1. Navigate to: **Edit Integration System User**
2. Configure:
   - **Authentication:** OAuth 2.0 (not basic auth)
   - **Client credentials:** Store securely
   - **Token lifetime:** Minimum required

---

### 2.2 Implement OAuth Token Policies

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(13)

#### Description
Configure OAuth token policies for integration authentication.

#### Rationale
**Why This Matters:**
- Long-lived or non-expiring refresh tokens for integrations are high-value targets that grant bulk programmatic access to employee data
- Short token lifetimes and regular client-secret rotation shrink the useful lifespan of any leaked credential
- Scoping each OAuth client to the minimum required APIs limits what a stolen token can reach
- Monitoring token issuance and revoking anomalous tokens enables fast containment of a compromise

**Attack Prevented:** Token theft, refresh-token abuse, bulk data exfiltration, replay attacks

#### ClickOps Implementation

> **Verification note (2026-08-08):** the specific OAuth lifetimes below are this guide's target recommendations and were **not re-verifiable this pass** — Workday's OAuth documentation sits under `doc.workday.com/admin-guide/en-us/authentication-and-security/`, which returns HTTP 401 to unauthenticated readers. Confirm the configurable fields and their permitted ranges in your own **Register API Client** task before treating these as tenant settings.

**Step 1: Configure OAuth Clients**
1. Navigate to: **Register API Client**
2. For each integration:
   - **Grant type:** Client Credentials (M2M)
   - **Scope:** Minimum required APIs
   - **Token expiration:** target 1 hour access token, 7 days refresh (L1) / 24h refresh (L2), subject to what your tenant exposes

**Step 2: Rotate Client Secrets**

| Integration Type | Rotation Frequency |
|------------------|--------------------|
| Payroll connectors | Quarterly |
| Benefits integrations | Quarterly |
| Reporting tools | Semi-annually |
| Custom integrations | Quarterly |

**Step 3: Monitor Token Usage**
1. Review OAuth token issuance logs
2. Alert on unusual patterns
3. Revoke suspicious tokens immediately

---

## 3. Data Security & Privacy

### 3.1 Configure Field-Level Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3

#### Description
Restrict access to sensitive fields based on business need.

#### Rationale
**Why This Matters:**
- Fields like SSN, bank account, and compensation are the most damaging data in the tenant and are often exposed to far more roles than need them
- Field-level restrictions and masking ensure most users see only the data their job requires, even within reports they can otherwise run
- Logging access to sensitive fields creates the audit trail needed to detect and investigate misuse

**Attack Prevented:** PII exposure, identity theft, insider data harvesting, over-broad data access

#### ClickOps Implementation

**Step 1: Identify Sensitive Fields**

**Step 2: Configure Field Security**
1. Navigate to: **Domain Security Policies**
2. For sensitive fields:
   - Restrict "View" to specific security groups
   - Enable masking where applicable
   - Log all access

**Step 3: Enable Data Masking**
1. Configure SSN masking (show last 4 only)
2. Configure bank account masking
3. Document unmasked access requirements

---

### 3.2 Configure Data Retention

**Profile Level:** L2 (Walk)
**NIST 800-53:** SI-12

#### Description
Implement data retention policies aligned with legal requirements.

#### Rationale
**Why This Matters:**
- Data retained beyond its legal or business need expands the volume of PII exposed in any future breach
- Automated purging of expired records reduces standing liability and supports privacy obligations such as right-to-erasure
- Clear retention schedules prevent stale employment, payroll, and performance records from accumulating as an unmanaged data hoard

**Attack Prevented:** Excessive data exposure, regulatory non-compliance, breach blast-radius amplification

#### ClickOps Implementation

> **Verify the governing task in your tenant (2026-08-08).** A **Data Retention Policies** task could not be verified against reachable Workday documentation this pass. Retention in Workday is generally handled through purge/archival processes that vary by data type and edition, and the relevant documentation is 401-gated to unauthenticated readers. Use the retention targets below as policy requirements and confirm the implementing task with Workday support or your tenant's task index before building a procedure around this path.

1. Navigate to: **Data Retention Policies** (confirm this task exists in your tenant — see the note above)
2. Configure retention by data type:
   - Employment records: Per jurisdiction requirements
   - Payroll data: 7 years (US)
   - Performance data: 3-5 years
3. Enable automated purging for expired data

---

### 3.3 Keep Sensitive Data Enumeration Protection Enabled

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SI-4, AC-2(12)

#### Description
Verify that your tenant has **not** opted out of Workday's Sensitive Data Enumeration protection — the native defense that signs out sessions and locks accounts that repeatedly access sensitive identifiers such as Bank Account Number, Birth Place, Date of Birth, Global Identifier, and Tax ID.

#### Rationale
**Why This Matters:**
- This is Workday's native anti-mass-enumeration control and it is **on by default** — the tenant setting exists only to **opt out**, so the risk here is not "did we turn it on" but "did someone turn it off," which is exactly the kind of change that never gets revisited
- It targets the highest-value fields in the tenant (bank account, tax ID, date of birth, birth place, global identifier) and responds to the behavior that precedes bulk theft: repeated programmatic or scripted access to sensitive identifiers across many workers
- Signing out the session and locking the account converts a silent scrape into a loud, self-limiting event — the difference between an incident discovered in minutes and one discovered when employees report fraudulent direct-deposit changes

**Attack Prevented:** Mass PII enumeration, scripted harvesting of tax and bank identifiers, insider bulk data collection, identity-theft-grade data scraping

#### ClickOps Implementation

1. Navigate to: **Edit Tenant Setup - Security**
2. Locate the **Sensitive Data Enumeration** configuration on the [Tenant Setup - Security](https://doc.workday.com/admin-guide/en-us/manage-workday/tenant-configuration/tenant-setup/dan1370796470031.html) surface.
3. Confirm the tenant is **not opted out**. If an opt-out is set, record who set it and why before changing anything — some integrations were built assuming no enforcement.
4. Where an opt-out is genuinely required for a legitimate integration, scope the exception to the ISU rather than the whole tenant if your edition allows it, and give it an owner and a review date.
5. Pair with 5.2 so lockouts generated by this control raise a notification rather than a silent help-desk ticket.

#### Validation & Testing
Treat any account lockout attributed to sensitive-data access as a detection signal, not a support nuisance — route it to security triage and confirm the accessing identity had a business reason.

---

## 4. API & Integration Security

### 4.1 Restrict API Scopes

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-6

#### Description
Limit API access to minimum required scopes.

#### Rationale
**Why This Matters:**
- Over-scoped API clients can read and write far more data than their integration needs, magnifying the impact of a compromised client
- Granting only the specific scopes required — for example, Staffing and Payroll for a payroll export — contains what a stolen credential can touch
- Annual scope review with documented justification prevents permission creep as integrations evolve

**Attack Prevented:** Excessive privilege, bulk data exfiltration, scope abuse via compromised integrations

#### Workday API Scopes

| Integration Need | Recommended Scopes |
|-----------------|-------------------|
| Payroll export | `Staffing`, `Payroll` |
| Benefits sync | `Benefits`, `Worker Profile` |
| Org chart | `Organizations`, `Worker Profile (limited)` |
| Reporting | `Reports`, specific report scopes |

#### ClickOps Implementation

1. Navigate to: **API Client Registration**
2. Select only required scopes
3. Document business justification
4. Review annually

---

### 4.2 Secure Workday Studio Integrations

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-7

#### Description
Harden custom Workday Studio integrations.

#### Rationale
**Why This Matters:**
- Custom Studio integrations are application code that can embed hardcoded credentials, mishandle errors, or leak sensitive data if not reviewed
- Authenticating Studio integrations as a dedicated ISU with Workday-managed credential objects, instead of embedding credentials in the integration definition, prevents secret sprawl across integration builds and exports
- Integration audit logging and data-volume anomaly alerting surface compromised or misbehaving connectors before large-scale data loss

**Attack Prevented:** Hardcoded-credential theft, data leakage, supply-chain compromise of custom integrations

#### Best Practices

1. **Code Review:**
   - Review integration code before deployment
   - Check for hardcoded credentials
   - Validate error handling

2. **Credentials:**
   - Authenticate as a dedicated, purpose-scoped ISU (see 2.1) — never embed a username and password in the integration definition
   - Use Workday-managed credential objects (ISU credentials, x509 key pairs for signed/encrypted exchanges) rather than secrets carried inside the integration itself
   - Rotate ISU credentials and x509 certificates on a schedule, and track certificate expiry via the alerting in 5.2

3. **Logging:**
   - Enable integration audit logging
   - Monitor for failures and anomalies
   - Alert on unexpected data volumes

---

## 5. Monitoring & Detection

### 5.1 Enable Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure comprehensive audit logging for Workday operations.

#### Rationale
**Why This Matters:**
- Without comprehensive sign-on, data-access, and configuration-change logging, malicious activity in the tenant goes undetected
- Exporting audit logs to a SIEM enables correlation, alerting, and retention beyond what the platform retains natively
- Real-time webhooks on critical events shorten the time to detect and respond to account compromise or privilege changes

**Attack Prevented:** Undetected intrusion, delayed incident response, audit-trail tampering, insider abuse

#### ClickOps Implementation

> **Verify the governing task in your tenant (2026-08-08).** An **Edit Tenant Setup - Audit** task could not be verified against reachable Workday documentation this pass. In practice Workday's sign-on visibility is **report-based** rather than a toggle — sign-on activity is commonly accessed via sign-on attempt reports (the Signon Attempts family) rather than by enabling a logging setting. Confirm the exact task and report names in your own tenant before writing a procedure against this path; this guide does not assert them.

**Step 1: Establish Audit Visibility**
1. Identify the tenant's sign-on reporting surface — sign-on attempt reports are the usual starting point for authentication activity.
2. Confirm you can retrieve, at minimum:
   - Sign-on activity (success and failure)
   - Sensitive data access
   - Configuration changes
   - Integration activity

**Step 2: Export to SIEM**
1. Create a scheduled integration (RaaS report or API-based export) to deliver these reports to your SIEM.
2. Configure real-time notification for critical events where the tenant supports it.
3. Retain exported logs for your compliance period — SIEM retention, not tenant retention, is what you control.

---

### 5.2 Configure Security Email Settings

**Profile Level:** L2 (Walk)
**NIST 800-53:** SI-4(5), AU-6, SC-12

#### Description
Configure Workday's Security Email Settings so account lockouts, password resets, trusted-device changes, and **certificate expiration** generate notifications to the right recipients at the right intervals.

#### Rationale
**Why This Matters:**
- **Certificate expiration alerts are the highest-value item here:** an expired SAML signing certificate breaks federated sign-in for the entire tenant, and the standard incident response — fall back to native passwords to restore access — converts an outage into a fail-open event that dismantles your SSO and MFA posture under time pressure
- Lockout notifications with configured retry intervals turn password spraying and the sensitive-data-enumeration lockouts from 3.3 into a detection signal that reaches security, rather than a help-desk ticket queue nobody correlates
- Password-reset routing (work versus home email) decides where an account-recovery message lands; routing resets to a personal address that the organization neither controls nor monitors hands account recovery to whoever controls that mailbox
- Trusted-device notifications tell a user when a new device was marked trusted (1.4) — often the first and only visible sign of a session or device compromise

**Attack Prevented:** SSO fail-open on certificate expiry, undetected password spraying, account-recovery hijacking via unmonitored personal mailboxes, silent device-trust abuse

#### ClickOps Implementation

1. Navigate to: **Edit Tenant Setup - Security** → **Security Email Settings**
2. Configure, per the [Tenant Setup - Security](https://doc.workday.com/admin-guide/en-us/manage-workday/tenant-configuration/tenant-setup/dan1370796470031.html) reference:
   - **Certificate expiration alerts** — enable, and route to a monitored security or identity distribution list, never an individual. Track expiry dates independently as well; email is a reminder, not a control.
   - **Account lockout notifications** and their **retry interval** — tune so repeated lockouts generate a signal rather than a flood, and forward that mailbox into your SIEM or ticketing pipeline.
   - **Password reset routing** — route to work email; permit home-email routing only for populations that genuinely lack a corporate mailbox, and document that exception.
   - **Trusted device notifications** — enable so users see new-device trust events (1.4).
3. Verify recipients are monitored aliases with owners, and re-verify after any HR or IT reorganization.

#### Validation & Testing
Trigger a test lockout and confirm the notification arrives at the configured alias. Confirm at least one upcoming certificate expiry appears in your calendar or ticketing system independent of the email alert.

---

## 6. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Workday Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.1 | Native MFA settings and grace sign-in count | 1.6 |
| CC6.2 | Security groups | 1.2 |
| CC6.6 | WebAuthn (FIDO2) authentication | 1.5 |
| CC6.7 | Data security | 3.1 |
| CC7.2 | Sensitive data enumeration protection | 3.3 |
| CC7.3 | Security email settings and certificate expiry alerts | 5.2 |

### NIST 800-53 Mapping

| Control | Workday Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | SSO with MFA | 1.1 |
| IA-2(8) | WebAuthn / phishing-resistant authentication | 1.5 |
| IA-3 | Trusted device governance | 1.4 |
| IA-5 | Native MFA settings, grace sign-in count | 1.6 |
| AC-6 | ISU restrictions | 2.1 |
| AC-2(12) | Sensitive data enumeration protection | 3.3 |
| AU-2 | Audit logging | 5.1 |
| SI-4(5) | Security email notifications | 5.2 |

---

## Appendix A: References

**Official Workday Documentation:**
- [Tenant Setup - Security (Workday Administrator Guide)](https://doc.workday.com/admin-guide/en-us/manage-workday/tenant-configuration/tenant-setup/dan1370796470031.html) -- the primary verified reference for this guide's tenant-level security settings (trusted devices, WebAuthn, multifactor authentication settings, sensitive data enumeration, security email settings, timeout redirect URL, mobile passcode timeout)
- [Workday Documentation Portal](https://doc.workday.com/)
- [Workday Community API Reference](https://community.workday.com/api)
- [Workday SAML SSO with Okta](https://saml-doc.okta.com/SAML_Docs/How-to-Configure-SAML-2.0-for-Workday.html)
- [Workday SSO with Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/identity/saas-apps/workday-tutorial)

> **Documentation access note (2026-08-08):** `doc.workday.com` is split-access to unauthenticated readers. The `/admin-guide/en-us/manage-workday/**` tree (including the Tenant Setup - Security reference above) renders normally, while `/admin-guide/en-us/authentication-and-security/**` returns HTTP 401 and the release center redirects to customer SSO. Controls in this guide that depend on the 401-gated tree carry an inline verification note rather than an asserted claim.

**API Documentation:**
- [Workday REST API](https://community.workday.com/sites/default/files/file-hosting/productionapi/index.html)
- [Workday Community API](https://community.workday.com/api)

**Compliance Frameworks:**
- Workday publishes SOC and ISO attestations for its own service. Certification scope and currency change over time and are stated on Workday's compliance materials rather than in configuration documentation -- request the current attestation reports directly from Workday or your account team rather than relying on a third-hand list. Nothing in a vendor attestation substitutes for the tenant-side controls in this guide.

**Security Incidents:**
- **2024 -- Broadcom/BSH Partner Breach:** Partner Business Systems House (BSH) was compromised via ransomware, exposing employee data from ADP/Workday integrations. Demonstrates third-party ecosystem vulnerability rather than a direct Workday platform compromise.
- **August 2025 -- CRM Social Engineering Campaign:** Threat actors accessed Workday's third-party CRM platform (Salesforce) as part of a broader social engineering campaign, stealing primarily business contact information. No access to customer Workday tenants or tenant data was reported. Discovered August 6, disclosed August 15, 2025.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass against the verified Tenant Setup - Security reference. Added 1.4 Trusted Devices (auto-enabled; disabling resets trust tenant-wide), 1.5 WebAuthn (FIDO2), 1.6 native Multifactor Authentication Settings including the maximum grace sign-in count bypass parameter, 3.3 Sensitive Data Enumeration protection (on by default; the tenant setting only opts out), and 5.2 Security Email Settings (lockout, password-reset routing, trusted-device, and certificate-expiration alerts). Extended 1.1 with the parallel authentication surfaces (OIDC, Mobile Authentication, deprecated SAML Setup fields) and added the missing **Attack Prevented** lines to 1.1 and 2.1. **Fabrication removed:** the 4.2 instruction to "store secrets in Workday vault" cited a product/feature not documented on any reachable Workday source and has been replaced with the ISU/x509 credential-object framing already established in 2.1. Annotated 1.3, 3.2, and 5.1 as unverified console paths (values softened to recommendations, no replacement paths invented) and removed 5.1's empty Detection Queries heading; noted that 5.1's real sign-on visibility is report-based. Marked the Overview's "non-expiring refresh tokens" claim and 2.2's OAuth lifetimes as not re-verifiable this pass — `doc.workday.com/admin-guide/en-us/authentication-and-security/**` returns HTTP 401 to unauthenticated readers while the `manage-workday` tree renders. Appendix A: removed three workday.com Trust Center links and the valencesecurity.com third-party guide (fails Tier 3 admission), re-sourced the compliance claim honestly, added the verified Tenant Setup - Security reference. Tier 2 survey: no CIS Benchmark, DISA STIG, or CISA SCuBA baseline exists for Workday (confirmed zero). Tier 3/4 not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Workday hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
