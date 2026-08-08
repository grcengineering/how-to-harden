---
layout: guide
title: "Box Hardening Guide"
vendor: "Box"
slug: "box"
tier: "3"
category: "Data"
description: "Enterprise content security for sharing policies, app controls, and classification"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---


## Overview

Box serves **115,000+ customers including 70% of Fortune 500**. Box Platform API with OAuth 2.0 and **1,500+ app integrations** access enterprise documents, contracts, and financial records. Service account credentials and custom applications extend attack surface.

### Intended Audience
- Security engineers managing enterprise storage
- IT administrators configuring Box
- GRC professionals assessing content compliance
- Third-party risk managers evaluating storage integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Box security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Sharing & External Access](#2-sharing--external-access)
3. [App Integration Security](#3-app-integration-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML single sign-on with two-step verification (MFA) for all Box access, so every user authenticates through your corporate identity provider instead of a standalone Box password.

#### Rationale
**Why This Matters:**
- Centralizes Box authentication in your corporate IdP, enforcing MFA and conditional access on every login
- Local Box passwords bypass IdP controls and are prime targets for credential stuffing and phishing
- IdP-driven deprovisioning removes departed users in one place, eliminating orphaned accounts with standing access to enterprise content
- Box holds contracts, financial records, and sensitive documents — a single compromised login can expose all of it

**Attack Prevented:** Credential theft, phishing, MFA bypass, password reuse, orphaned-account access

#### ClickOps Implementation

**Step 1: Configure SSO**
1. Navigate to: **Admin Console → Enterprise Settings → User Settings → SSO**
2. Configure SAML with your IdP
3. Enable: **Require SSO**

**Step 2: Configure 2FA**
1. Navigate to: **Admin Console → Enterprise Settings → Security**
2. Enable: **Require 2-step verification for all users**

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Assign Box administrative and content permissions using least-privilege roles (Co-Admin, Group Admin, Content Manager, User) so each person receives only the access their job actually requires.

#### Rationale
**Why This Matters:**
- Least-privilege roles limit how much content and how many users any single account can reach or modify
- Granting full admin broadly means one compromised account can change sharing settings, exfiltrate content, or remove other admins
- Scoped roles such as Content Manager and Group Admin contain the blast radius of a compromised or insider account
- Clear role separation supports audit and accountability for who can change enterprise content and settings

**Attack Prevented:** Privilege escalation, insider abuse, lateral movement, excessive-permission compromise

#### ClickOps Implementation

| Role | Permissions |
|------|-------------|
| Co-Admin | Full admin (limited users) |
| Group Admin | Manage specific groups |
| Content Manager | Manage content, no users |
| User | Standard access |

---

### 1.3 Enforce Device Trust Requirements

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-3, AC-19

#### Description
Use Box Device Trust to require that devices meet defined security requirements — such as disk encryption, screen lock, minimum OS version, or a managed-device certificate — before they are allowed to access Box content, and apply those requirements across the Web App, desktop, and mobile clients.

#### Rationale
**Why This Matters:**
- Identity controls alone say who is signing in but nothing about the security posture of the machine the content lands on, so a valid session on an unencrypted or unpatched device still exfiltrates enterprise files
- Device Trust moves the boundary from the account to the endpoint, blocking access from devices that fail encryption, screen-lock, or OS-version requirements
- Stolen credentials become far less useful when the attacker's own device cannot satisfy the enterprise's device requirements
- Platform Restrictions let you shut off entire access channels (for example legacy or unmanaged clients) rather than trying to police them individually

**Attack Prevented:** Access from compromised or unmanaged endpoints, credential theft replayed from attacker-controlled devices, data landing on unencrypted machines

#### Prerequisites
- Box plan that includes Device Trust (see Appendix A)
- Box Tools installed on managed workstations — Device Trust checks for the Box Web App are performed through Box Tools

#### ClickOps Implementation

**Step 1: Open Device Protection**
1. Navigate to: **Admin Console → Enterprise Settings → Device Protection**
2. Review the existing Device Trust and Platform Restrictions configuration ([Box: Setting Up Device Trust Security Requirements](https://support.box.com/hc/en-us/articles/360044194993-Setting-Up-Device-Trust-Security-Requirements))

**Step 2: Define device security requirements**
1. Configure the security requirements devices must satisfy (for example disk encryption, screen lock, minimum OS version, or a managed-device certificate)
2. Choose the enforcement posture. Requirements are evaluated at login for managed users and access is blocked when a device fails — unless the policy is set to **Audit-Only**, in which case failures are recorded but access is still permitted
3. Use Audit-Only first to size the impact, then switch to enforcement

**Step 3: Review Platform Restrictions**
1. Platform Restrictions are **on by default** — confirm which access platforms are permitted for your enterprise rather than assuming the default matches your policy

#### Validation & Testing
1. With the policy in Audit-Only, sign in from a device that deliberately fails one requirement and confirm the failure is recorded
2. Switch to enforcement and confirm the same device is blocked at login
3. Confirm Box Tools is deployed on managed workstations — without it, Web App device checks cannot be evaluated

#### Documented Exemptions

Box documents categories of access that Device Trust does **not** cover. Treat these as a residual risk to be closed with other controls, not as an oversight:

- **Admins and co-admins editing enterprise settings are exempt** from Device Trust enforcement — the highest-privilege accounts in the tenant are precisely the ones the control does not gate. Compensate with hardware-backed MFA and admin-count minimization (see [1.2](#12-role-based-access))
- **FTP and SFTP users are exempt.** If FTP/SFTP access is enabled in your enterprise it is an unchecked path around Device Trust; disable it unless there is a business requirement

---

### 1.4 Shorten Web Session Duration

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-11, AC-12

#### Description
Reduce the Box web session inactivity timeout from its long default so that abandoned browser sessions expire quickly, and understand which clients that setting actually governs.

#### Rationale
**Why This Matters:**
- Box's default web session expires after **14 days of inactivity**, which leaves an authenticated browser session usable for two weeks on any machine where a user walked away without signing out
- Shortening the timeout narrows the window for session hijacking, cookie theft, and opportunistic misuse of shared or unattended workstations
- Shared, kiosk, and contractor-managed machines are the realistic exposure — the shorter the timeout, the smaller the population of live sessions at any moment

**Attack Prevented:** Session hijacking, unattended-session abuse, stolen-cookie replay

#### ClickOps Implementation

**Step 1: Set the web session timeout**
1. Navigate to: **Admin Console → Enterprise Settings → Security**
2. Set the web session expiration to the shortest interval your users will tolerate, rather than leaving the 14-day default ([Box: Best Practice — Choosing Security Settings](https://support.box.com/hc/en-us/articles/360044193273-Best-Practice-Choosing-Security-Settings))

#### Scope Limitation

This setting applies **only to the Box web application**. Mobile and desktop client sessions are not governed by it, and neither are API tokens held by connected applications and service accounts. Session hardening alone therefore does not bound how long access to your content persists — pair it with the app and service-account controls in [Section 3](#3-app-integration-security) and with Device Trust ([1.3](#13-enforce-device-trust-requirements)).

---

## 2. Sharing & External Access

### 2.1 Configure Sharing Restrictions

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-21

#### Description
Restrict default shared-link scope, external collaboration domains, and link passwords so Box content cannot be shared publicly or with untrusted parties by default.

#### Rationale
**Why This Matters:**
- Open or public shared links can expose confidential documents to anyone who discovers or guesses the URL
- Misconfigured custom shared-link URLs have historically led to mass exposure of enterprise data stored on Box
- Defaulting links to company-only and requiring passwords forces a deliberate choice before content leaves the organization
- Restricting external collaboration to approved domains blocks accidental sharing with personal or attacker-controlled accounts

**Attack Prevented:** Data leakage, public link exposure, unauthorized external access, accidental oversharing

#### ClickOps Implementation

**Step 1: Configure Default Sharing**
1. Navigate to: **Admin Console → Enterprise Settings → Content & Sharing**
2. Configure:
   - **Default shared link access:** Company only
   - **External collaboration:** Restricted domains
   - **Password on links:** Required

**Step 2: Enable Box Shield**
1. Navigate to: **Admin Console → Shield**
2. Configure:
   - Smart Access policies
   - Classification labels
   - Threat detection

---

## 3. App Integration Security

### 3.1 Manage OAuth Apps

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Inventory connected OAuth applications, remove unused ones, and require admin approval and scope review before any new app can access Box content.

#### Rationale
**Why This Matters:**
- Connected OAuth apps hold delegated, often long-lived access to enterprise content without re-prompting for credentials
- A malicious or compromised third-party app can read or exfiltrate documents using its granted token, bypassing user MFA
- Unused or over-scoped apps expand the attack surface and create forgotten access paths into Box data
- Admin approval and scope auditing prevent users from consenting to risky integrations that violate data-handling policy

**Attack Prevented:** OAuth token abuse, malicious app integration, consent phishing, supply-chain access, data exfiltration

#### ClickOps Implementation

Box splits application management across two distinct admin surfaces. Reviewing only one of them leaves the other class of app unmanaged.

**Step 1: Review and restrict third-party integrations**
1. Navigate to: **Admin Console → Integrations**
2. Under **Individual Integration Controls**, review every listed integration
3. Set each to allowed or restricted; restrict any integration you do not recognize or no longer use
4. Restricting an integration blocks it for all managed users in the enterprise ([Box: Restricting Applications from the Admin Console](https://support.box.com/hc/en-us/articles/360043691294-Restricting-Applications-from-the-Admin-Console))

**Step 2: Review and approve custom/server applications**
1. Navigate to: **Admin Console → Platform → Platform Apps**
2. Review every custom application — JWT (server authentication) and Client Credentials Grant (CCG) apps appear here, not under Integrations
3. Authorize only applications you can attribute to a known owner and business purpose; remove the rest ([Box: Platform App Approval](https://developer.box.com/guides/authorization/platform-app-approval.md))

**Step 3: Re-authorize after any scope change**
1. Box does **not** apply scope changes to an already-authorized application automatically. Per Box's platform app approval documentation, when an application's scopes or access level change, the application must be re-authorized before the new configuration takes effect
2. The practical consequence: an app whose scopes were tightened in its configuration silently keeps operating under its **old, broader** scopes until an admin re-authorizes it — a scope reduction that was never actually enforced
3. Maintain a periodic review that compares each Platform App's configured scopes against its authorized scopes, and re-authorize any app whose configuration has drifted

---

### 3.2 Service Account Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-5

#### Description
Scope Box service accounts to specific folders, rotate their credentials on a regular schedule, and monitor their activity so non-human integrations cannot become an unchecked access path.

#### Rationale
**Why This Matters:**
- Service accounts often hold broad, non-interactive access and are not protected by user MFA
- Long-lived or shared service-account credentials are high-value targets that grant persistent access if leaked
- Scoping each account to specific folders limits what a compromised integration can reach
- Regular rotation and activity monitoring shorten the window of misuse and surface anomalous automated access

**Attack Prevented:** Credential leakage, standing-access abuse, lateral movement, undetected automated exfiltration

#### Implementation

1. Create dedicated service accounts
2. Limit to specific folders
3. Rotate credentials quarterly
4. Monitor service account activity

---

## 4. Monitoring & Detection

### 4.1 Enable Box Shield

**Profile Level:** L2 (Walk)
**NIST 800-53:** SI-4, AC-3

#### Description
Deploy Box Shield to add ML-driven threat detection, anomalous-download and external-sharing alerts, and classification-based access controls on top of Box's native permissions.

#### Rationale
**Why This Matters:**
- Native permissions prevent unauthorized access but do little to detect a compromised account behaving abnormally
- Shield's anomaly detection flags unusual download volumes and access patterns that signal account takeover or insider exfiltration
- Real-time external-sharing and classification alerts catch risky data movement before sensitive content leaves the organization
- Classification-based access controls enforce handling rules consistently rather than relying on user discretion

**Attack Prevented:** Account takeover, insider data theft, anomalous bulk download, undetected external sharing

#### ClickOps Implementation

**Step 1: Choose the control types to apply**

Shield access policies are built from documented security control types. Each one is attached to a classification label, so the label a file carries determines which restrictions follow it ([Box: Security Control Types](https://support.box.com/hc/en-us/articles/7711419517331-Security-Control-Types)):

| Control type | What it restricts |
|--------------|-------------------|
| External collaboration restriction | Who outside the enterprise may be added as a collaborator on classified content |
| Shared link restriction | The audience a shared link on classified content may be set to |
| Download and print restriction | Whether classified content can be downloaded or printed, and by whom |
| Integration restriction | Which third-party integrations may access classified content — the Shield-side counterpart to the app controls in [3.1](#31-manage-oauth-apps) |
| FTP restriction | Whether classified content may be reached over FTP/SFTP — the same channel that is exempt from Device Trust ([1.3](#13-enforce-device-trust-requirements)) |
| Watermarking | Applies a watermark to classified content, attributing any screenshot or capture to the viewer |
| Box Sign request restriction | Whether classified content may be sent out in a Box Sign signature request |

**Step 2: Choose the enforcement mode**
1. Each access policy runs in either **Monitor** mode (the action is permitted and recorded) or **Enforce** mode (the action is blocked) ([Box: Shield Access Policy Settings](https://support.box.com/hc/en-us/articles/14596333776403-Shield-Access-Policy-Settings))
2. Deploy new policies in Monitor mode first to size the impact on real user behavior, then move to Enforce once the volume of would-be blocks is understood. A policy left in Monitor indefinitely detects but does not prevent — track which of your policies are still in Monitor as an open risk

**Step 3: Enable threat detection**
1. Enable Shield's anomaly detection for unusual download volume, suspicious locations, and suspicious sessions, and route its alerts to the team that will actually triage them

---

## Appendix A: Edition Compatibility

| Control | Business | Business Plus | Enterprise |
|---------|----------|---------------|------------|
| SSO | ✅ | ✅ | ✅ |
| Device Trust | ❌ | ✅ | ✅ |
| Box Shield | ❌ | ❌ | Add-on |
| DLP | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Box Documentation:**
- [Box Support](https://support.box.com/hc/en-us)
- [Best Practice: Choosing Security Settings](https://support.box.com/hc/en-us/articles/360044193273-Best-Practice-Choosing-Security-Settings)
- [Setting Up Device Trust Security Requirements](https://support.box.com/hc/en-us/articles/360044194993-Setting-Up-Device-Trust-Security-Requirements)
- [Restricting Applications from the Admin Console](https://support.box.com/hc/en-us/articles/360043691294-Restricting-Applications-from-the-Admin-Console)
- [Box Shield: Security Control Types](https://support.box.com/hc/en-us/articles/7711419517331-Security-Control-Types)
- [Box Shield: Access Policy Settings](https://support.box.com/hc/en-us/articles/14596333776403-Shield-Access-Policy-Settings)

**API Documentation:**
- [Box Developer Platform](https://developer.box.com/)
- [Box SDKs & Tools](https://developer.box.com/sdks-and-tools/)
- [Platform App Approval](https://developer.box.com/guides/authorization/platform-app-approval.md)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO 27001, ISO 27018, FedRAMP, FIPS 140-2, PCI DSS Level 1, HIPAA/HITECH. Request current attestation reports directly from Box rather than relying on this list.

**Security Incidents:**
- **2019 — Misconfigured shared links exposed enterprise data.** Security researchers at Adversis discovered hundreds of thousands of documents across hundreds of Box customers were publicly accessible due to misconfigured custom shared link URLs. Exposed data included passport photos, SSNs, financial records, and internal network diagrams from companies including Apple, Amadeus, Discovery, and Herbalife. This was not a platform vulnerability but a user misconfiguration of an intended sharing feature. Box responded by disabling the default public custom-sharing URL setting. ([TechCrunch](https://techcrunch.com/2019/03/11/data-leak-box-accounts/))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass against Box Support and Box Developer documentation. Corrected 3.1 — Box splits app management across two surfaces (third-party integrations under Admin Console → Integrations; JWT/CCG custom apps under Admin Console → Platform → Platform Apps) — and added a scope re-authorization step, since Box does not apply scope changes to an already-authorized app. Added 1.3 Device Trust (including its documented admin and FTP/SFTP exemptions) and 1.4 web session duration (14-day default, web app only). Expanded 4.1 with Box Shield's seven documented security control types and the Monitor-vs-Enforce mode choice, and added its missing NIST mapping. Removed an empty Detection Queries heading and Trust Center references. Tier 2 (CIS, DISA STIG, CISA SCuBA) confirmed zero coverage for Box; Tier 3/4 not surveyed this pass. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Box hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
