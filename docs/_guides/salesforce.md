---
layout: guide
title: "Salesforce Hardening Guide"
vendor: "Salesforce"
slug: "salesforce"
tier: "2"
category: "Marketing"
description: "CRM platform security for MFA enforcement, Connected Apps, and Shield Event Monitoring"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-03"
---


**Salesforce Editions Covered:** Enterprise, Unlimited, Performance (some controls require Shield add-on)

---

## Overview

This guide provides comprehensive security hardening recommendations for Salesforce, organized by control category. Each recommendation includes both **ClickOps** (GUI-based) and **Code** (automation-based) implementation methods.

### Intended Audience
- Security engineers configuring Salesforce security controls
- IT administrators managing Salesforce instances
- GRC professionals assessing Salesforce compliance
- Third-party risk managers evaluating integration security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Salesforce-specific security configurations. For infrastructure hardening (AWS, Azure where Salesforce runs), refer to CIS Benchmarks.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Network Access Controls](#2-network-access-controls)
3. [OAuth & Connected App Security](#3-oauth--connected-app-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Multi-Factor Authentication (MFA) for All Users

**Profile Level:** L1 (Crawl)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1), IA-2(2)

#### Description
Require all Salesforce users to use MFA for authentication, eliminating single-factor authentication vulnerabilities.

**Changed requirement — phishing-resistant MFA for privileged users (2026):** Salesforce is phasing in a requirement that privileged users authenticate with *phishing-resistant* MFA. Enforcement begins **10 July 2026 for sandboxes** and rolls out to **production orgs on a staggered schedule between 20 July and 3 September 2026**. Once your org reaches its enforcement date, SMS one-time codes, email one-time codes, Salesforce Authenticator push notifications, and TOTP authenticator apps (Google Authenticator, Authy) **no longer satisfy the MFA requirement for in-scope users**.

Users in scope are those assigned the **System Administrator** profile, plus any user holding **Modify All Data**, **View All Data**, **Customize Application**, or **Author Apex**. Only three verification methods qualify as phishing-resistant: FIDO2/WebAuthn security keys, passkeys (including platform biometrics such as Touch ID, Face ID, and Windows Hello), and certificate-based authentication. Separately, the **Waive MFA for Exempt Users** permission stops automatically exempting these privileged users, so previously exempted admins will be challenged. Source: [Salesforce Help: Phishing-Resistant MFA Requirement](https://help.salesforce.com/s/articleView?id=005321563&language=en_US&type=1)

#### Rationale
**Why This Matters:**
- MFA is the single highest-leverage control against credential stuffing, password spray, and phished passwords, all of which remain routine entry points into SaaS tenants
- Administrator accounts are the highest-value target in any Salesforce org: a compromised System Administrator can export every object, authorize new Connected Apps, and disable the very controls in this guide
- Push notifications and TOTP codes are phishable — an adversary-in-the-middle proxy relays the code or fatigues the user into approving a push, which is exactly how modern real-time phishing kits defeat "MFA-enabled" accounts
- FIDO2/WebAuthn keys and passkeys cryptographically bind the authentication to the legitimate Salesforce origin, so a proxied phishing site cannot replay the assertion no matter how convincing the lure
- Planning the rollout ahead of your org's enforcement date avoids a hard lockout: admins who have not enrolled a qualifying method when enforcement lands lose access at the worst possible moment

**Attack Prevented:** Credential stuffing, password spray, phished passwords, adversary-in-the-middle MFA relay, MFA fatigue/push bombing, SIM swap interception of SMS codes

**Incident Example:** Okta support breach (2023) — attackers used stolen credentials without MFA.

#### ClickOps Implementation

**Step 1: Enforce MFA org-wide**
1. Navigate to: **Setup → Identity → Multi-Factor Authentication**
2. Enable: **"Require Multi-Factor Authentication (MFA) for all direct UI logins"**
3. Configure allowed authenticator types:
   - ☑ Security keys and built-in authenticators (FIDO2/WebAuthn, passkeys) — required for privileged users
   - ☑ Salesforce Authenticator (acceptable for standard users only)
   - ☑ TOTP-based apps such as Google Authenticator or Authy (acceptable for standard users only)
   - ☐ SMS (NOT recommended — vulnerable to SIM swapping, and not accepted for privileged users)
4. Set enforcement date and communicate to users

**Step 2: Identify users in scope for phishing-resistant MFA**
1. **Setup → Users → Profiles** — list every user assigned the **System Administrator** profile
2. **Setup → Users → Permission Sets** and **Profiles** — find every assignment of **Modify All Data**, **View All Data**, **Customize Application**, and **Author Apex**
3. Treat the union of those users as the in-scope population; expect it to be larger than your admin headcount, because these permissions are frequently granted through permission sets to developers and integration owners

**Step 3: Enrol privileged users in a qualifying method**
1. Issue FIDO2/WebAuthn security keys, or confirm each privileged user has a passkey-capable device (Touch ID, Face ID, Windows Hello)
2. Have each user register the method under their personal settings: **Settings → My Personal Information → Advanced User Details → Register a Security Key / Built-In Authenticator**
3. Register a second key per user as a break-glass backup, stored in your physical safe or credential vault
4. For automated or headless privileged access, use certificate-based authentication instead of an interactive method

**Step 4: Remove reliance on exemptions**
1. Audit who holds **Waive MFA for Exempt Users** — it no longer auto-exempts privileged users once enforcement lands
2. Remove the permission from anyone who does not have a documented, time-bounded justification

#### Validation & Testing
1. **Setup → Security → Login History** — confirm the MFA column shows a verification method on recent logins, and that privileged users show a security key or built-in authenticator rather than TOTP or push
2. Attempt a login as a test user assigned the System Administrator profile with only a TOTP app registered; after your org's enforcement date the login must be rejected or force enrolment of a qualifying method
3. Confirm the break-glass account has a registered backup security key and that the key physically works, before enforcement lands
4. Re-run the Step 2 permission audit quarterly — new permission set assignments silently expand the in-scope population

#### Compliance Mappings
- **SOC 2:** CC6.1 (Logical Access)
- **NIST 800-53:** IA-2(1), IA-2(2)
- **PCI DSS:** 8.3

---


{% include pack-code.html vendor="salesforce" section="1.1" %}

## 2. Network Access Controls

### 2.1 Restrict API Access via IP Allowlisting for Third-Party Integrations

**Profile Level:** L1 (Crawl)
**CIS Controls:** 13.3, 13.6
**NIST 800-53:** AC-3, SC-7

#### Description
Restrict third-party integrations (like Gainsight, Drift, HubSpot) so their API calls only succeed from the vendor's documented static egress IP addresses. This prevents a compromised integration from using stolen OAuth tokens against your org from attacker-controlled infrastructure.

**Important correction — Trusted IP Ranges do NOT block API access.** Salesforce exposes three distinct IP mechanisms and only two of them enforce anything against an integration. Choosing the wrong one produces a control that looks configured but blocks nothing:

| Mechanism | Where | What it actually does |
|-----------|-------|-----------------------|
| **Trusted IP Ranges** | Setup → Security → Network Access | Only *skips identity-verification challenges* for interactive UI logins from those addresses. It does **not** block API, OAuth, or Connected App traffic from any other address. This is a login-friction setting, not a security boundary. |
| **Login IP Ranges (profile-level)** | Setup → Users → Profiles → [Profile] → Login IP Ranges | **Hard-blocks** every login for users on that profile from outside the listed ranges, including API and OAuth sessions. This is the control to apply to a dedicated integration user. |
| **Connected App "Enforce IP restrictions"** | Setup → Apps → App Manager → [App] → Manage → Edit Policies | Binds the Connected App to the org's IP restrictions so the app's sessions are subject to them rather than relaxed out of them. |

To hard-block a compromised integration by IP you must use **profile-level Login IP Ranges on the integration user**, the Connected App's **Enforce IP restrictions** policy, or both. Adding the vendor's IPs to Trusted IP Ranges alone leaves stolen tokens fully usable from anywhere. Source: [Gearset: Deploying IP ranges in Salesforce](https://gearset.com/blog/deploy-ip-ranges/)

#### Rationale
**Why This Matters:**
- Stolen OAuth tokens are bearer credentials: whoever holds one can call the API as the integration, from any network, until the token is revoked — an IP boundary is what turns a global credential into a locally usable one
- Login IP Ranges on the integration user are enforced at authentication, so an attacker replaying a token from their own infrastructure fails before touching a single record
- Trusted IP Ranges create a dangerous false sense of security: teams frequently record "IP allowlisting: implemented" in their control evidence while every API path remains wide open
- Integrations are the ideal place to apply IP restrictions because they run from documented static egress addresses, unlike human users who roam across networks
- Combined with least-privilege OAuth scopes (Section 3.1), an IP boundary means a supply chain breach at the vendor yields a token that is both narrow in reach and unusable from the attacker's network

**Attack Prevented:** Supply chain compromise via OAuth token theft, stolen refresh token replay from attacker infrastructure, integration credential abuse from unauthorized networks

**Real-World Incidents:**
- **Gainsight Breach (November 2025):** Attackers exfiltrated data from 200+ Salesforce orgs using stolen OAuth tokens from compromised Gainsight infrastructure
- **Salesloft/Drift Breach (August 2025):** 700+ orgs compromised via stolen OAuth tokens
- **Okta Survival:** Okta was targeted but protected because they had IP restrictions configured

#### ClickOps Implementation

**Step 1: Give each integration its own user**
1. **Setup → Users → Users → New User** — create a dedicated integration user per vendor rather than reusing an employee or shared admin account
2. Assign it a dedicated profile (cloned from a minimal profile) so the IP restrictions you apply next affect only that integration

**Step 2: Apply Login IP Ranges to the integration profile (the enforcing control)**
1. **Setup → Users → Profiles → [integration profile] → Login IP Ranges → New**
2. Enter the vendor's documented egress range as **IP Start Address** and **IP End Address**, with a description recording the vendor and verification date
3. Repeat for each documented range, then **Save**
4. Any login for a user on this profile from outside these ranges is now refused, including API and OAuth

**Step 3: Enforce IP restrictions on the Connected App**
1. **Setup → Apps → App Manager → [integration app] → Manage → Edit Policies**
2. Under **IP Relaxation**, select **Enforce IP restrictions**
3. **Save**

**Step 4 (optional): Trusted IP Ranges for staff convenience only**
1. **Setup → Security → Network Access** — use this only to reduce identity-verification prompts for your own office or VPN egress
2. Do not record this as an integration security control; it enforces nothing against API traffic

#### Validation & Testing
1. From a network outside the allowlisted ranges, attempt an API authentication as the integration user — it must fail with a restricted-IP login error, not succeed
2. **Setup → Security → Login History** — filter to the integration user and confirm blocked attempts appear with a restricted IP status
3. Trigger a real sync from the vendor's platform and confirm it still succeeds, proving the allowlist covers the vendor's live egress addresses
4. Re-verify the vendor's egress IPs quarterly with the vendor directly, and re-test after any vendor infrastructure migration announcement

---


{% include pack-code.html vendor="salesforce" section="2.1" %}

### 2.1.1 IP Allowlisting: Restricting Gainsight

#### Prerequisites
- Salesforce Enterprise Edition or higher
- Gainsight's current static egress IP addresses
- System Administrator access

#### Gainsight IP Addresses

⚠️ **These example addresses are stale — do not deploy them without re-verification.** The values below were recorded on 2025-12-12 and are retained only to show the shape of the configuration. Gainsight's published IP documentation page that this guide previously cited no longer resolves, so there is no public URL we can honestly point you to. **Obtain Gainsight's current production egress IP addresses directly from your Gainsight CSM or Gainsight Support before configuring anything.**

Example (2025-12-12, unverified since):
- `35.166.202.113/32`
- `52.35.87.209/32`
- `34.221.135.142/32`

Deploying stale addresses fails in both directions: it breaks the integration if Gainsight has migrated, and it can leave an allowlist entry pointing at cloud IP space Gainsight no longer controls.

#### ClickOps Implementation

**Step 1: Locate the Gainsight integration user's profile**
1. **Setup → Users → Users** — identify the dedicated user Gainsight authenticates as
2. Note its profile, then go to **Setup → Users → Profiles → [that profile]**

**Step 2: Add Gainsight ranges as Login IP Ranges**
For each verified IP address:
1. In the profile, scroll to **Login IP Ranges** and click **New**
2. Enter:
   - **IP Start Address:** the verified Gainsight address
   - **IP End Address:** the same address for a single host
   - **Description:** `Gainsight Production 1 - verified [date you confirmed with CSM]`
3. Click **Save**
4. Repeat for each remaining verified address

**Step 3: Enforce IP restrictions on the Gainsight Connected App**
1. **Setup → Apps → App Manager → [Gainsight app] → Manage → Edit Policies**
2. Set **IP Relaxation** to **Enforce IP restrictions**, then **Save**

**Step 4: Test Integration**
1. Trigger a Gainsight manual sync
2. Verify data flows correctly
3. Check Login History for blocked attempts: **Setup → Security → Login History**

**Time to Complete:** ~10 minutes, plus vendor lead time to obtain current IPs

#### Monitoring & Maintenance

**Quarterly Review Checklist:**
- Re-confirm Gainsight's egress IPs with your CSM or Gainsight Support — treat any IP list older than one quarter as unverified
- Update description fields with the new verification date
- Review Event Monitoring logs for blocked attempts
- Test integration after any changes

**Alert Configuration:**
If using Salesforce Shield Event Monitoring, see the DB Query in the Code Pack for section 2.1 above.

#### Operational Impact
- **User Experience:** None (users don't interact with integration directly)
- **Integration Functionality:** Low risk if IPs verified with vendor
- **Rollback:** Easy - remove IP ranges from trusted list

#### Compliance Mappings
- **SOC 2:** CC6.6 (Boundary Protection)
- **NIST 800-53:** AC-3, SC-7, SC-7(5)
- **ISO 27001:** A.8.3 (Supplier relationships)

---

### 2.1.2 IP Allowlisting: Restricting Drift

#### Drift IP Addresses

⚠️ **These example addresses are stale — do not deploy them without re-verification.** Recorded 2025-12-12 and unverified since. Drift's dedicated help centre has been folded into Salesloft's support site following the acquisition, and the article this guide previously cited no longer resolves. **Obtain Drift's current egress IP addresses from Salesloft/Drift support or your account team before configuring anything** — this is especially important given the August 2025 Salesloft/Drift compromise and the infrastructure changes that followed it.

Example (2025-12-12, unverified since):
- `52.2.219.12/32`
- `54.196.47.40/32`
- `54.82.90.31/32`

**Implementation:** Follow the same process as Gainsight (Section 2.1.1) — profile-level **Login IP Ranges** on the Drift integration user plus **Enforce IP restrictions** on the Drift Connected App — substituting the addresses you verified with the vendor.

---

### 2.1.3 IP Allowlisting: Restricting HubSpot

#### HubSpot IP Addresses

⚠️ **No verified public IP list is available to cite.** The HubSpot knowledge base article this guide previously linked no longer resolves. **Request HubSpot's current outbound IP ranges from HubSpot Support or your HubSpot account manager**, and record the date you received them alongside each Login IP Range entry.

**Note:** HubSpot operates a larger IP range than the other integrations here and changes it more frequently. Consider:
- More frequent verification (monthly rather than quarterly)
- Monitoring HubSpot's status page for infrastructure change announcements
- Treating a broad HubSpot range as a weaker boundary than a three-address Gainsight allowlist, and compensating with tighter OAuth scopes (Section 3.1)

**Implementation:** Follow the same process as Gainsight (Section 2.1.1), using profile-level **Login IP Ranges** rather than Trusted IP Ranges.

---

### 2.2 Restrict Login Hours by Profile

**Profile Level:** L2 (Walk)

#### Description
Limit when users can log into Salesforce based on their role/profile, reducing attack surface during off-hours.

#### Rationale
**Why This Matters:**
- Restricting login hours shrinks the window during which stolen credentials or a hijacked session can be used against Salesforce
- Off-hours logins are a common indicator of compromise; blocking them outright removes a whole class of unattended attack opportunity
- Scoping by profile lets you tightly constrain high-risk groups such as contractors and third-party integrators without disrupting normal business users
- Combined with MFA and IP allowlisting, time-based restrictions add a defense-in-depth layer that an attacker must also defeat to operate

**Attack Prevented:** Off-hours credential abuse, stolen-credential reuse, unauthorized after-hours access, automated bot logins

#### ClickOps Implementation
1. **Setup → Users → Profiles → [Select Profile]**
2. Click **"Login Hours"** button
3. Configure allowed hours per day of week
4. Save and test with affected users

#### Use Cases
- Restrict contractor access to business hours only
- Limit admin account login times to reduce exposure
- Geographic-based restrictions (e.g., US-only profiles during US business hours)

---

## 3. OAuth & Connected App Security

**Platform note — Connected Apps are being superseded by External Client Apps.** Salesforce is steering new integration development toward **External Client Apps (ECAs)**, the successor to the classic Connected App framework, and is phasing new-app creation toward ECAs. If you attempt the Connected App creation steps in this section and find the option unavailable or restricted, your org has likely already reached that transition — create an External Client App instead.

ECAs improve on Connected Apps in ways that matter for the controls below: they separate admin ownership from developer ownership, so a developer can no longer silently alter the security policies an admin set, and they are **not accessible to all users by default**, which closes the permissive default that made rogue Connected App authorization so easy to exploit. The OAuth scope, session, and IP policies described in this section have ECA equivalents — apply them to whichever app framework your org uses. Existing Connected Apps continue to function; plan a migration path rather than a rushed cutover, and consult current Salesforce release notes for your org's specific timeline rather than relying on any single third-party date claim. Source: [Salesforce disabling new Connected Apps (vendor advisory)](https://help-people.sage.com/Content/SP_AdditionalResources/Salesforce_updates/SP_AddRes_SFUpdates_Salesforce_disabling_new_connected_apps.htm)

### 3.1 Audit and Reduce OAuth Scopes for Connected Apps

**Profile Level:** L1 (Crawl)
**CIS Controls:** 6.2 (Least Privilege)
**NIST 800-53:** AC-6

#### Description
Review all Connected Apps (third-party integrations) and ensure they only have minimum required OAuth scopes. Over-permissioned apps increase breach impact.

#### Rationale
**Attack Impact:** When Gainsight was breached, attackers had `full` OAuth scope, allowing complete data exfiltration. Scoped permissions would have limited damage.

**Why This Matters:**
- Connected Apps granted broad scopes such as full or api can read and write nearly every object, so a single compromised integration token exposes the entire CRM dataset
- Least-privilege scoping ensures a breached third party can only reach the specific objects and operations it genuinely needs, containing the blast radius of a token theft
- Persistent grants like refresh_token and offline_access let stolen tokens work indefinitely; trimming and expiring them limits how long compromised credentials stay useful
- Requiring explicit user authorization for OAuth flows surfaces rogue or unexpected app connections before they gain standing access to your org

**Attack Prevented:** Over-permissioned token abuse, full-scope data exfiltration, persistent OAuth access via stolen refresh tokens, supply chain compromise

#### ClickOps Implementation

**Step 1: Audit Current Connected Apps**
1. **Setup → Apps → Connected Apps → Manage Connected Apps**
2. Review each app's "Selected OAuth Scopes"
3. Document current scopes and business justification

**Step 2: Identify Over-Permissioned Apps**
Look for apps with:
- `full` - Complete access (almost never needed)
- `api` - Full API access (often too broad)
- `refresh_token, offline_access` - Persistent access (risk if breached)

**Step 3: Reduce Scopes**
For each over-permissioned app:
1. Click app name → **Edit Policies**
2. Modify **Selected OAuth Scopes** to minimum required:
   - Example: Change `full` to specific scopes like `chatter_api`, `custom_permissions`
3. **Save**
4. Test integration to ensure functionality maintained

**Step 4: Enable OAuth App Approval**
1. **Setup → Security → Session Settings**
2. Enable: **"Require user authorization for OAuth flows"**
3. This forces users to explicitly approve OAuth apps

#### Recommended Scope Restrictions by Integration Type

| Integration Type | Recommended Scopes | Avoid |
|------------------|--------------------|-------|
| **Customer Success (Gainsight)** | `api`, `custom_permissions`, specific objects | `full`, `refresh_token` with long expiry |
| **Marketing (HubSpot, Drift)** | `api`, `chatter_api`, limited objects | `full`, `manage_users` |
| **Support (Zendesk, Intercom)** | `api`, `chatter_api`, Case object only | `full`, access to all objects |
| **Analytics (Tableau)** | `api`, read-only specific objects | Write access, `full` |

#### Compliance Mappings
- **SOC 2:** CC6.2 (Least Privilege)
- **NIST 800-53:** AC-6, AC-6(1)
- **ISO 27001:** A.9.2.3

---


{% include pack-code.html vendor="salesforce" section="3.1" %}

### 3.2 Enable Connected App Session-Level Security

**Profile Level:** L2 (Walk)

#### Description
Configure Connected Apps to inherit session security policies (IP restrictions, timeout) from user's profile.

#### Rationale
**Why This Matters:**
- Inheriting profile session policies binds Connected Apps to the same IP restrictions and timeouts as interactive users, closing gaps where integrations would otherwise bypass org-wide controls
- Short session timeouts and bounded refresh-token lifetimes shrink the window a stolen token remains valid, forcing attackers to re-authenticate
- "Never expires" tokens are effectively permanent credentials; expiring them ensures revoked or rotated access actually takes effect
- Enforcing IP restrictions on the app prevents a leaked token from being replayed from attacker-controlled infrastructure

**Attack Prevented:** Stolen token replay, indefinite session persistence, IP restriction bypass, long-lived refresh token abuse

#### ClickOps Implementation
1. **Setup → Apps → Connected Apps → [App Name]**
2. Edit Policies
3. **Session Timeout:** Set to "2 hours" or less (not "Never expires")
4. **Refresh Token Policy:** "Expire after 30 days" (not "Refresh token valid indefinitely")
5. Enable: **"Enforce IP restrictions"**

---

### 3.3 Enable API Access Control (Org-Wide Connected App Allowlist)

**Profile Level:** L2 (Walk)

| Framework | Control Reference |
|-----------|-------------------|
| **CIS Controls** | 2.5 (Allowlist Authorized Software), 6.8 (Role-Based Access Control) |
| **NIST 800-53** | AC-3, AC-6, CM-7(5) |
| **SOC 2** | CC6.1, CC6.3 |
| **ISO 27001** | A.8.2, A.8.9 |

#### Description
API Access Control locks **all** API access to your org down to an admin-approved list of connected and external client apps. With it enabled, any user who does not hold the **Use Any API Client** permission can only reach the API through an app an administrator has explicitly approved — every other OAuth client is refused, including one the user authorized themselves.

This is the org-wide equivalent of application allowlisting, and it is the control that stops an unapproved OAuth client at the API rather than after the fact. Without it, any user with API access can authorize an arbitrary third-party app (a rebranded Data Loader clone, a "reporting tool" handed to them over the phone) and that app inherits the user's data reach immediately.

**Prerequisite:** API Access Control is not self-service. You must **contact Salesforce Support to have the feature enabled for your org** before the setup page becomes functional. Plan for that lead time. Source: [Salesforce Help: API Access Control](https://help.salesforce.com/apex/HTViewHelpDoc?id=xcloud.security_api_access_control_about.htm&language=en_US)

#### Rationale
**Why This Matters:**
- OAuth authorization is a user-level decision by default: any employee who can be persuaded to click "Allow" grants a third party standing API access to everything that employee can see, with no administrator in the loop
- Allowlisting inverts that default — the org declares which apps may touch the API, so social engineering a single user no longer yields a working API client
- The 2025 vishing campaigns against Salesforce customers (Section 3.4) depended entirely on a user authorizing an attacker-controlled app; API Access Control breaks that chain at the authorization step rather than relying on the user to spot the fraud
- Scoping **Use Any API Client** to a small, deliberate set of users converts an implicit org-wide capability into an auditable exception list
- Allowlisting also constrains shadow IT: unsanctioned integrations that quietly accumulated OAuth grants become visible and fail closed rather than persisting unnoticed

**Attack Prevented:** Unapproved OAuth client authorization, malicious Data Loader clones, vishing-driven app consent, shadow IT integrations, rogue API clients operating on stolen user credentials

#### ClickOps Implementation

**Step 1: Request the feature**
1. Open a case with Salesforce Support requesting **API Access Control** be enabled for your org
2. Ask them to confirm which orgs (production and sandboxes) the enablement covers

**Step 2: Inventory before you enforce**
1. **Setup → Apps → Connected Apps → Manage Connected Apps** — list every app currently in use
2. Cross-reference with **Setup → Event Monitoring** API event logs to catch apps in active use that nobody documented
3. Confirm a business owner for each app; anything without an owner is a candidate for removal rather than approval

**Step 3: Enable and configure**
1. **Setup → Quick Find: "API Access Control" → API Access Control**
2. Enable API access control for your org
3. Add each inventoried, business-approved connected app or external client app to the allowlist
4. Save

**Step 4: Scope the bypass permission**
1. Locate every profile and permission set granting **Use Any API Client** — holders bypass the allowlist entirely
2. Remove it from all but a documented, minimal set of users (typically integration owners and a break-glass admin)
3. Record the justification and a review date for each remaining holder

**Step 5: Roll out in stages**
1. Enable in a sandbox first and run a full integration cycle
2. Communicate the change to integration owners before production enablement, since an omitted app will fail closed

#### Validation & Testing
1. Authenticate to the API using an app that is deliberately **not** on the allowlist, as a user without **Use Any API Client** — the call must be refused
2. Run each approved integration's normal sync and confirm it succeeds unchanged
3. Re-run the **Use Any API Client** permission query quarterly; new permission set assignments silently reopen the bypass
4. Review the allowlist itself quarterly and remove apps whose business owner or use case has lapsed

#### Compliance Mappings
- **SOC 2:** CC6.1 (Logical Access), CC6.3 (Access Authorization)
- **NIST 800-53:** AC-3, AC-6, CM-7(5) (Authorized Software — Allowlisting)
- **CIS Controls:** 2.5, 6.8
- **ISO 27001:** A.8.2 (Privileged Access Rights), A.8.9 (Configuration Management)

---

### 3.4 Defend Against Vishing-Driven Connected App Authorization (UNC6040)

**Profile Level:** L1 (Crawl)

| Framework | Control Reference |
|-----------|-------------------|
| **CIS Controls** | 6.2, 6.8, 14.1 (Security Awareness), 8.11 (Log Review) |
| **NIST 800-53** | AC-6, AT-2, AU-6, IA-2(1) |
| **SOC 2** | CC6.1, CC6.3, CC7.2 |
| **ISO 27001** | A.6.3, A.8.2, A.8.16 |

#### Description
Throughout 2025, the threat cluster tracked as **UNC6040** — publicly associated with the ShinyHunters extortion brand — ran a voice phishing (vishing) campaign against Salesforce customers that required no software vulnerability at all. Attackers telephoned employees posing as internal IT support and talked them through authorizing a **modified, rebranded version of Salesforce's Data Loader** connected app against the company's org. Once the victim completed the OAuth authorization, the attackers used the app's API access to bulk-export CRM data, followed by extortion demands.

This control hardens the specific chain that campaign relied on: a user who can authorize apps, an app authorization that requires no admin approval, and bulk API export that nobody is watching. It is a permissions-and-detection control, not an awareness poster — the technical restrictions below hold even when the phone call succeeds. Source: [Google Cloud Threat Intelligence: Voice Phishing Data Extortion](https://cloud.google.com/blog/topics/threat-intelligence/voice-phishing-data-extortion)

#### Rationale
**Why This Matters:**
- The attack bypasses every perimeter control by design: no exploit, no malware, no stolen password — a legitimate user performs a legitimate authorization under false pretenses, so the traffic is indistinguishable from sanctioned integration activity at the network layer
- A rebranded Data Loader is genuinely convincing, because Data Loader is real Salesforce tooling that employees have been legitimately asked to install before; "our IT team needs you to connect the data tool" is a plausible request
- Restricting **API Enabled** to users who actually need programmatic access removes most of the target population outright — a user without it cannot grant a working API client no matter what they authorize
- **Manage Connected Apps** and **Customize Application** are the permissions that let a victim install or approve an app org-wide; concentrating them in a small trusted admin group means the phone call has to reach one of a handful of people rather than anyone in sales ops
- Bulk export is the loud part of the attack: a Data Loader-style client pulling entire objects looks nothing like normal integration traffic, and Event Monitoring surfaces it if anyone is looking
- Phishing-resistant MFA (Section 1.1) and enforced IP restrictions (Sections 2.1, 3.2) constrain where a fraudulently authorized app can be operated from, shrinking the window even after a successful authorization

**Attack Prevented:** Vishing-driven OAuth consent, rogue Data Loader clone authorization, mass CRM data exfiltration via API, extortion following bulk export, social-engineered privilege abuse

#### ClickOps Implementation

**Step 1: Restrict the API Enabled permission**
1. **Setup → Users → Profiles** and **Setup → Users → Permission Sets** — find every grant of **API Enabled**
2. Remove it from profiles that exist for interactive UI users (sales reps, support agents, marketing staff)
3. Grant it via a dedicated permission set only to users and integration accounts with a documented programmatic need

**Step 2: Concentrate app administration permissions**
1. Audit every holder of **Manage Connected Apps** and **Customize Application**
2. Reduce both to a named, small group of trusted administrators — these are the permissions that let someone stand up a working integration
3. Remove **Modify All Data** and **View All Data** from anyone who does not require org-wide data reach

**Step 3: Require administrator approval for app authorization**
1. Enable API Access Control (Section 3.3) so only allowlisted apps can reach the API at all
2. **Setup → Apps → Connected Apps → Manage Connected Apps → [app] → Edit Policies** — set **Permitted Users** to **Admin approved users are pre-authorized** for every app, so self-service user authorization is not possible
3. **Setup → Security → Session Settings** — confirm **"Require user authorization for OAuth flows"** is enabled so unexpected authorizations surface rather than happening silently

**Step 4: Enforce universal MFA and IP restrictions**
1. Apply MFA to all users, with phishing-resistant methods for privileged users (Section 1.1)
2. Apply Login IP Ranges and Connected App **Enforce IP restrictions** so an authorized-but-fraudulent app cannot be driven from attacker infrastructure (Sections 2.1 and 3.2)

**Step 5: Monitor for bulk export anomalies**
1. Enable Event Monitoring API, Login, and Report Export events (Section 5.1)
2. Alert on: a newly authorized connected app, a first-time API client performing large record counts, and any export volume materially above that app's baseline
3. Route these alerts to a team that will act on them within the hour — bulk export completes fast

**Step 6: Brief the humans on the specific pretext**
1. Tell staff plainly that IT will never phone them and walk them through authorizing a Salesforce app or reading out a connection code
2. Give them a verification path: hang up, contact IT through a known internal channel, confirm the request
3. Make clear there is no penalty for refusing or for reporting a call that turned out to be legitimate

#### Validation & Testing
1. Query which users hold **API Enabled**, **Manage Connected Apps**, **Customize Application**, **Modify All Data**, and **View All Data** — the result should be a short list you can name individually, and you should re-run it quarterly
2. As a standard non-admin user, attempt to authorize a new external OAuth app; with Steps 1-3 applied the authorization must fail or require admin approval rather than completing
3. Confirm your Event Monitoring alert fires by running a deliberately large export through an approved integration in a sandbox
4. Review **Setup → Apps → Connected Apps → Manage Connected Apps** monthly for apps nobody recognizes, and revoke unknown entries immediately
5. Run a tabletop exercise on the vishing scenario: who is called, who notices, how fast the app is revoked and tokens invalidated

#### Compliance Mappings
- **SOC 2:** CC6.1 (Logical Access), CC6.3 (Access Authorization), CC7.2 (Monitoring)
- **NIST 800-53:** AC-6 (Least Privilege), AT-2 (Security Awareness Training), AU-6 (Audit Review), IA-2(1)
- **CIS Controls:** 6.2, 6.8, 8.11, 14.1
- **ISO 27001:** A.6.3 (Awareness and Training), A.8.2 (Privileged Access Rights), A.8.16 (Monitoring Activities)

---

## 4. Data Security

### 4.1 Enable Field-Level Encryption for Sensitive Data

**Profile Level:** L2 (Walk)
**Requires:** Salesforce Shield

#### Description
Encrypt sensitive fields (SSN, credit card, health data) at rest using Salesforce Shield Platform Encryption.

#### Rationale
**Why This Matters:**
- Platform Encryption protects sensitive fields at rest so that database-level exposure, backup theft, or insider access to raw storage does not reveal plaintext SSNs, card numbers, or health data
- Encryption keys are derived from a tenant secret you control, decoupling data confidentiality from Salesforce's own infrastructure access
- Encrypting regulated data fields directly supports data-at-rest obligations under PCI DSS, HIPAA, and privacy regulations
- Limiting encryption to genuinely sensitive fields preserves query and reporting functionality while still shrinking the sensitive-data exposure surface

**Attack Prevented:** Data-at-rest exposure, insider data theft, backup or storage compromise, regulated-data disclosure

#### ClickOps Implementation
1. **Setup → Security → Platform Encryption**
2. Generate tenant secret (store securely!)
3. Select fields to encrypt:
   - Custom fields marked as sensitive
   - Standard fields: SSN, Credit Card, etc.
4. Enable encryption per field
5. Test: Encrypted fields show lock icon

#### Limitations
- Encrypted fields cannot be used in:
  - WHERE clauses (except equality)
  - ORDER BY
  - Formula fields (in some cases)
- Requires Shield add-on (~$25/user/month)

---

## 5. Monitoring & Detection

### 5.1 Enable Event Monitoring for API Anomalies

**Profile Level:** L1 (Crawl)
**Requires:** Salesforce Shield or Event Monitoring add-on

#### Description
Enable Salesforce Event Monitoring to detect anomalous API usage patterns that could indicate compromised integrations.

#### Rationale
**Why This Matters:**
- API, login, and report-export event logs provide the visibility needed to detect compromised integrations and anomalous data access that would otherwise go unnoticed
- Bulk query spikes, unusual export volumes, and off-pattern API callers are strong indicators of token theft or exfiltration in progress
- Feeding event logs to a SIEM enables alerting and correlation, turning passive logs into active detection and incident response
- Without monitoring, supply chain breaches via stolen OAuth tokens can run undetected for extended periods before discovery

**Attack Prevented:** Undetected data exfiltration, compromised-integration abuse, OAuth token theft, anomalous bulk API access

#### ClickOps Implementation
1. **Setup → Event Monitoring → Event Manager**
2. Enable these event types:
   - **API** (all API calls)
   - **Login** (authentication events)
   - **URI** (page views)
   - **Report Export** (data exfiltration indicator)
3. Configure storage: EventLogFile (24hr) or Event Monitoring Analytics (30 days)

#### Detection Queries

{% include pack-code.html vendor="salesforce" section="5.1" %}

#### Alert Configuration
**Using Salesforce Shield:**
1. Create custom report with anomaly query
2. Subscribe to report with alert threshold
3. Configure email/Slack notification

**Using Third-Party SIEM:**
Export EventLogFile daily to:
- Splunk
- Datadog
- Sumo Logic
- AWS Security Lake

---

## 6. Third-Party Integration Security

### 6.1 Integration Risk Assessment Matrix

Before allowing any third-party integration, assess risk:

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **Data Access** | Read-only, limited objects | Read most objects | Write access, full API |
| **OAuth Scopes** | Specific scopes only | `api` scope | `full` scope |
| **Session Duration** | <2 hours | 2-8 hours | >8 hours, refresh tokens |
| **IP Restriction** | Static IPs, allowlisted | Some static IPs | Dynamic IPs, no allowlist |
| **Vendor Security** | SOC 2 Type II, recent audit | SOC 2 Type I | No SOC 2 |

**Decision Matrix:**
- **0-5 points:** Approve with standard controls
- **6-10 points:** Approve with enhanced monitoring
- **11-15 points:** Require additional security measures or reject

### 6.2 Common Integrations and Recommended Controls

#### Gainsight (Customer Success Platform)

**Data Access:** High (needs Account, Contact, Case, Custom Objects)
**Recommended Controls:**
- ✅ IP allowlisting (Section 2.1.1)
- ✅ Reduce OAuth scopes from `full` to `api` + specific objects
- ✅ Enable Event Monitoring for bulk queries
- ✅ 30-day refresh token expiration

#### Drift (Marketing/Chat Platform)

**Data Access:** Medium (needs Lead, Contact, Account)
**Recommended Controls:**
- ✅ IP allowlisting (Section 2.1.2)
- ✅ Read-only access to Lead/Contact
- ✅ Restrict to marketing team profile
- ⚠️ Note: Drift was breached in 2025 - high-risk integration

#### HubSpot (Marketing Automation)

**Data Access:** Medium-High
**Recommended Controls:**
- ✅ IP allowlisting (Section 2.1.3) with monthly verification
- ✅ Bidirectional sync monitoring (alert on unexpected write operations)
- ✅ Field-level restrictions (don't sync SSN, financial data)

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Salesforce Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | MFA for all users | 1.1 |
| CC6.2 | OAuth scope reduction | 3.1 |
| CC6.3 | API Access Control (app allowlist) | 3.3 |
| CC6.3 | Restricted app authorization permissions | 3.4 |
| CC6.6 | Login IP Range restrictions | 2.1 |
| CC7.2 | Event Monitoring | 5.1 |

### NIST 800-53 Rev 5 Mapping

| Control | Salesforce Control | Guide Section |
|---------|-------------------|---------------|
| AC-3 | Login IP Range restrictions | 2.1 |
| AC-6 | Least privilege OAuth | 3.1 |
| AC-6 | Restricted API and app-admin permissions | 3.4 |
| CM-7(5) | Authorized app allowlisting | 3.3 |
| IA-2(1) | MFA enforcement (phishing-resistant for privileged users) | 1.1 |
| AT-2 | Vishing awareness and verification path | 3.4 |
| AU-6 | Event monitoring | 5.1 |

---

## Appendix A: Edition Compatibility

| Control | Professional | Enterprise | Unlimited | Performance | Shield Required |
|---------|-------------|------------|-----------|-------------|----------------|
| MFA | ✅ | ✅ | ✅ | ✅ | ❌ |
| Login IP Ranges (profile) | ❌ | ✅ | ✅ | ✅ | ❌ |
| OAuth Scoping | ✅ | ✅ | ✅ | ✅ | ❌ |
| API Access Control | Contact Support | Contact Support | Contact Support | Contact Support | ❌ |
| Event Monitoring | ❌ | Add-on | Add-on | Add-on | ✅ |
| Field Encryption | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Salesforce Documentation:**
- [Salesforce Help Center](https://help.salesforce.com/)
- [Salesforce Security Best Practices](https://security.salesforce.com/security-best-practices)
- [Salesforce Security Guide (PDF)](https://resources.docs.salesforce.com/latest/latest/en-us/sfdc/pdf/salesforce_security_impl_guide.pdf)
- [Network Access (IP Allowlisting)](https://help.salesforce.com/articleView?id=admin_loginipranges.htm)
- [Connected Apps and OAuth](https://help.salesforce.com/articleView?id=connected_app_overview.htm)
- [Event Monitoring](https://help.salesforce.com/articleView?id=event_monitoring.htm)
- [API Access Control](https://help.salesforce.com/apex/HTViewHelpDoc?id=xcloud.security_api_access_control_about.htm&language=en_US)
- [Phishing-Resistant MFA Requirement (2026)](https://help.salesforce.com/s/articleView?id=005321563&language=en_US&type=1)
- [Gearset: Deploying IP ranges in Salesforce (Trusted IP Ranges vs Login IP Ranges)](https://gearset.com/blog/deploy-ip-ranges/)
- [Salesforce disabling new Connected Apps — External Client App migration (vendor advisory)](https://help-people.sage.com/Content/SP_AdditionalResources/Salesforce_updates/SP_AddRes_SFUpdates_Salesforce_disabling_new_connected_apps.htm)

**API & Developer Resources:**
- [Salesforce Developer APIs](https://developer.salesforce.com/docs/apis)

**Trust & Compliance:**
- [Salesforce Compliance Site](https://compliance.salesforce.com/en)
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018 -- via [Salesforce Compliance Documents](https://compliance.salesforce.com/en/documents)

**Integration Vendor IP Documentation:**

⚠️ **No current public vendor IP documentation URLs are cited here, by design.** The pages previously linked for Gainsight, Drift, and HubSpot no longer resolve — Gainsight's support article returns 404, Drift's help centre was folded into Salesloft's support site after the acquisition, and the HubSpot knowledge base URL returns 404. Rather than substitute guessed replacement URLs, obtain current egress IP ranges directly from each vendor:

- **Gainsight:** your Gainsight CSM or Gainsight Support
- **Drift:** Salesloft/Drift support or your account team
- **HubSpot:** HubSpot Support or your HubSpot account manager

Record the date and channel of every IP list you receive, and treat any list older than one quarter as unverified.

**Supply Chain Incident Reports:**
- [Okta: Salesloft Incident Response](https://www.okta.com/newsroom/articles/the-salesloft-incident--a-wake-up-call-for-saas-security-and-ips/)
- [Mandiant: UNC6395 Campaign Analysis](https://www.mandiant.com/resources/blog/unc6395-supply-chain-compromise)
- [Google Cloud Threat Intelligence: UNC6040 Voice Phishing Data Extortion](https://cloud.google.com/blog/topics/threat-intelligence/voice-phishing-data-extortion)

**Security Incidents:**
- **Salesloft/Drift OAuth Supply Chain Attack (August-September 2025):** Attackers compromised Salesloft/Drift infrastructure and exfiltrated OAuth tokens, affecting 700+ Salesforce orgs. Gainsight breach separately impacted 200+ orgs via stolen OAuth tokens (November 2025). IP restrictions proved effective -- Okta was targeted but protected because they had IP restrictions configured.
- **UNC6040 / ShinyHunters Vishing Campaign (2025):** Attackers telephoned employees posing as internal IT support and walked them through authorizing a rebranded copy of Salesforce Data Loader as a connected app, then used its API access to bulk-export CRM data and extort the victim organizations. No vulnerability was exploited -- the entire campaign ran on social engineering plus permissive default OAuth authorization. See Section 3.4.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-03 | 0.2.0 | draft | Correct 2.1 (Trusted IP Ranges do not block API/OAuth; use profile Login IP Ranges and Connected App IP enforcement); update 1.1 for the 2026 phishing-resistant MFA requirement; add 3.3 API Access Control and 3.4 UNC6040 vishing defense; note External Client Apps superseding Connected Apps; replace dead vendor IP links with vendor-contact guidance | Claude Code (Sonnet 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-12 | 0.1.0 | draft | Initial Salesforce hardening guide with focus on integration security | Claude Code (Opus 4.5) |

---

**Next Steps:**
1. Review your current Salesforce configuration against L1 (Crawl) controls
2. Check whether your "IP allowlisting" is actually Trusted IP Ranges — if so it blocks no API traffic, and you need profile Login IP Ranges instead (Section 2.1)
3. Identify your phishing-resistant MFA population and enrol them before your org's 2026 enforcement date (Section 1.1)
4. Audit Connected App OAuth scopes and reduce over-permissions (Section 3.1)
5. Open a Salesforce Support case to enable API Access Control, then build your app allowlist (Section 3.3)
6. Restrict **API Enabled**, **Manage Connected Apps**, and **Customize Application** to a named minimum set of users (Section 3.4)
7. Enable Event Monitoring for API anomaly and bulk-export detection (Section 5.1)
8. Establish a quarterly review process for integration security, including re-verifying vendor egress IPs directly with each vendor

**Questions or Improvements?**
- Open an issue: [GitHub Issues](https://github.com/yourproject/how-to-harden/issues)
- Contribute: [Contributing Guide](/contributing/)

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
