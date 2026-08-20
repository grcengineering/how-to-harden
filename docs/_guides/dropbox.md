---
layout: guide
title: "Dropbox Hardening Guide"
vendor: "Dropbox"
slug: "dropbox"
tier: "3"
category: "Data"
description: "Cloud storage security for sharing policies, linked apps, and admin controls"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

Dropbox has **700+ million registered users** with enterprise file storage. The **2024 Dropbox Sign breach** exposed OAuth tokens, API keys, hashed passwords, and MFA data via compromised service account. Third-party app permissions and long-lived OAuth tokens enable persistent file access. The 2022 GitHub breach resulted in 130 private code repositories being accessed and copied (per Dropbox's 2022 disclosure).

### Intended Audience
- Security engineers managing file storage
- IT administrators configuring Dropbox
- GRC professionals assessing collaboration compliance
- Third-party risk managers evaluating storage integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Dropbox security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Sharing & External Access](#2-sharing--external-access)
3. [Third-Party App Security](#3-third-party-app-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Configure SAML single sign-on for your Dropbox team and set it to **Required**, so every member authenticates through your corporate identity provider and Dropbox passwords stop being a usable second door into team content.

#### Rationale
**Why This Matters:**
- Setting SSO to Optional rather than Required leaves a bypass in place: members can still sign in with a Dropbox password, so none of your IdP's MFA, conditional access, or device posture checks are actually enforced on that path
- Centralizing authentication in the IdP means departures are handled once, in one place — otherwise a disabled IdP account leaves a working Dropbox password behind it
- Dropbox teams hold contracts, source material, and customer files, so a single credential-stuffed or phished login exposes the content of every folder that member can reach
- Dropbox's own history shows credential-driven compromise as the recurring entry point rather than platform vulnerabilities

**Attack Prevented:** Credential theft, phishing, password reuse, MFA bypass via password fallback, orphaned-account access

**Real-World Incidents:**
- **2024 Dropbox Sign Breach:** Compromised service account exposed OAuth tokens, API keys, hashed passwords, and MFA data
- **2022 GitHub Breach:** Phishing against Dropbox employees resulted in 130 private code repositories being accessed and copied (per Dropbox's 2022 disclosure)
- **2012 Password Breach:** Credentials stolen from an unrelated third-party site were reused against a Dropbox employee account, ultimately exposing roughly 68 million user email addresses and hashed passwords

#### Prerequisites
- SSO is available on Dropbox Advanced, Business Plus, and Enterprise plans
- A SAML 2.0 identity provider

#### ClickOps Implementation

**Step 1: Configure SSO**
1. Navigate to: **Admin console → Team → Settings → Security** tab → **Authentication**
2. Configure SAML with your identity provider ([Dropbox: Single sign-on for admins](https://help.dropbox.com/security/sso-admin))

**Step 2: Choose the enforcement mode deliberately**

Dropbox offers two SSO modes, and only one of them closes the password path:

| Mode | Behavior | Use it when |
|------|----------|-------------|
| **Optional** | Members may sign in with SSO **or** with their Dropbox password | Migration window only — this is a documented bypass, not an end state |
| **Required** | Dropbox passwords stop working for members; SSO is the only path | Steady state |

1. Set the mode to **Required** once your IdP integration is confirmed working
2. Note that with SSO set to Required, team admins retain the ability to sign in with their admin credentials — plan for that path being reachable and protect those accounts accordingly

**Step 3: Enforce MFA**
1. Enforce MFA at the identity provider so it applies on the SSO path
2. For any account that can still authenticate against Dropbox directly, enable two-step verification in the same **Security** tab

#### Validation & Testing
1. With SSO set to Required, attempt a member sign-in using a Dropbox password and confirm it is rejected
2. Disable a test user in the IdP and confirm Dropbox access stops

---

### 1.2 Configure Access Permissions

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure team folder permissions using least privilege so members can only reach the content their role requires, and restrict access to sensitive admin folders.

#### Rationale
**Why This Matters:**
- Default-open or overly broad folder permissions let any member browse content well beyond their role, widening the blast radius of a single compromised account
- Least-privilege access on team and admin folders limits how much data an attacker or malicious insider can reach if they obtain a valid session
- Restricting admin folder access protects the most sensitive governance and configuration content from lateral movement

**Attack Prevented:** Privilege escalation, lateral movement, insider data access, over-broad data exposure

#### ClickOps Implementation

**Step 1: Configure Team Folder Permissions**
1. Navigate to: **Admin Console → Content → Team Folders**
2. Set default permissions by team
3. Restrict admin folder access

---

### 1.3 Enforce Device Approvals and Session Limits

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-11, AC-12, AC-19, IA-3

#### Description
Require admin approval before a new device can link to a member's Dropbox account, cap how many devices each member may link, and bound how long a web session stays valid through fixed session duration and idle timeout settings.

#### Rationale
**Why This Matters:**
- Without device approvals, an attacker holding valid credentials silently links their own machine and gets a full local sync of everything the member can reach — the fastest available route from one credential to bulk exfiltration
- Device caps make the appearance of an unexpected device an event someone notices, instead of one more entry in a list nobody reads
- Fixed session duration and idle timeout bound how long a stolen browser session remains usable, which is the exposure that device approvals do not address
- Deciding in advance what happens to a disconnected device — and whether its local copy is deleted — turns offboarding and device loss into a configured outcome rather than an improvised one

**Attack Prevented:** Unauthorized device linking, bulk sync exfiltration from a stolen credential, session hijacking, stale-session abuse

#### ClickOps Implementation

**Step 1: Enable device approvals**
1. Navigate to: **Admin console → Settings → Security → Devices → Device approvals**
2. Choose who approves new devices, and set the maximum number of devices a member may link — computer and mobile limits are configured separately ([Dropbox: Device approvals](https://help.dropbox.com/account-access/device-approvals))
3. Set the over-limit action — what Dropbox does when a member tries to link beyond the cap
4. Set the disconnected-device behavior, including whether the local copy is deleted when a device is disconnected
5. Add per-member exceptions only where there is a documented reason

**Step 2: Bound web sessions**
1. In the same **Security** settings, set **Fixed web session duration** — a hard cap on session lifetime, configurable from 1 day to 1 year
2. Set **Idle timeout** — configurable from None up to 48 hours. Leaving this at None means an abandoned browser session stays live until the fixed duration expires

#### Scope Limitation

Device approvals govern the Dropbox **desktop and mobile applications only**. They do not apply to browser access at dropbox.com — a credential that has been approved on no device at all can still sign in on the web. The web session settings in Step 2 are what bound that path, which is why both halves of this control matter.

---

### 1.4 Assign Granular Admin Roles

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-6, AC-6(7)

#### Description
Replace uniform full-admin access with Dropbox's pre-built granular admin roles, assigning each administrator only the console areas their responsibilities require.

#### Rationale
**Why This Matters:**
- On plans without granular roles, every administrator is effectively a full administrator — billing staff and helpdesk staff hold the same power to change security settings, alter sharing policy, and reach content
- Scoped roles mean a compromised admin session yields only that role's surface rather than the whole tenant, which is the difference between an incident and a total loss of control over the team
- Separating content and compliance duties from user management supports the segregation-of-duties evidence auditors ask for, and makes admin actions attributable to a role rather than to an undifferentiated pool

**Attack Prevented:** Admin account takeover with tenant-wide blast radius, privilege escalation, insider abuse of unnecessary admin power

#### Prerequisites
- Granular admin roles require Dropbox Advanced, Business Plus, or Enterprise. Standard and Business plans give every admin uniform full-admin rights, so on those plans the compensating control is minimizing the number of admins

#### ClickOps Implementation

**Step 1: Review the available roles**
1. Navigate to: **Admin console → Members**
2. Dropbox provides eight pre-built admin roles ([Dropbox: Change admin rights](https://help.dropbox.com/security/change-admin-rights)):

| Role | Scope |
|------|-------|
| Team admin | Full administrative control of the team |
| User management admin | Add, remove, and manage members |
| Support admin | Day-to-day member support tasks |
| Billing admin | Billing and subscription only |
| Content admin | Team content and folder administration |
| Compliance admin | Data governance functions — requires the Data Governance add-on |
| Reporting admin | Reporting and activity visibility |
| Security admin | Security settings and posture |

**Step 2: Right-size every administrator**
1. Assign each administrator the narrowest role that covers their actual duties
2. Keep the number of Team admins to the minimum needed for continuity, and review the admin roster on a fixed cadence

---

### 1.5 Restrict Dropbox Network Traffic

**Profile Level:** L3 (Run)
**NIST 800-53:** AC-4, SC-7

#### Description
Use Dropbox network control to restrict Dropbox traffic on your corporate network so only your own team's Dropbox accounts are reachable, blocking employees from signing into personal or third-party Dropbox accounts from managed networks and devices.

#### Rationale
**Why This Matters:**
- Every identity, sharing, and device control in this guide governs your team's Dropbox tenant — none of them stop an employee from opening a personal Dropbox account and moving corporate files into a tenant you do not administer
- Network control closes that path at the network layer, which is the only place it can be closed for accounts that were never yours to manage
- Pairs with domain verification and account capture ([2.2](#22-verify-domains-and-enforce-team-invites)): those bring in-domain personal accounts under management, while network control blocks out-of-domain accounts outright

**Attack Prevented:** Shadow-IT exfiltration to unmanaged personal Dropbox accounts, data movement outside the governed tenant

#### Prerequisites
- Network control is available on Dropbox Enterprise only, and must be enabled for your team by your Dropbox account manager — it is not self-service
- A proxy or CASB capable of injecting a custom HTTP header into Dropbox traffic. Dropbox names supported vendors in its documentation; confirm your own vendor against that list before planning the rollout

#### ClickOps Implementation

**Step 1: Request enablement**
1. Contact your Dropbox account manager to have network control enabled for your team ([Dropbox: Network control](https://help.dropbox.com/security/network-control))

**Step 2: Configure the traffic restriction**
1. Navigate to: **Admin console → Settings → Security → Restricted Dropbox traffic**
2. Configure your proxy or CASB to inject the custom HTTP header Dropbox specifies, so requests from your network are evaluated against the allowed teams

#### Validation & Testing
1. From a managed device on the corporate network, attempt to sign in to a personal Dropbox account and confirm the attempt is blocked
2. Confirm managed team accounts are unaffected

---

## 2. Sharing & External Access

### 2.1 Restrict External Sharing

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-21

#### Description
Restrict external sharing, default shared links to team members only, require passwords on links, and enforce a maximum link expiration so files are not exposed beyond intended recipients.

#### Rationale
**Why This Matters:**
- Unrestricted shared links can be forwarded, indexed, or guessed, exposing files to anyone on the internet with no authentication
- Password protection and team-only defaults ensure shared content reaches only the intended recipients
- Link expiration prevents stale links from granting indefinite access long after a project ends or a recipient leaves the organization

**Attack Prevented:** Data leakage, unauthorized external access, link forwarding, accidental public exposure

#### ClickOps Implementation

**Step 1: Configure Sharing Settings**
1. Navigate to: **Admin Console → Settings → Sharing**
2. Configure:
   - **External sharing:** Restricted or disabled
   - **Link permissions:** Team members only by default
   - **Password on links:** Required

**Step 2: Configure Link Expiration**
1. Enable: **Default expiration for shared links**
2. Set: Maximum 30 days (L2: 7 days)

---

### 2.2 Verify Domains and Enforce Team Invites

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-2, IA-4

#### Description
Verify the domains your organization owns, then use invite enforcement — and, where available, account capture — so that employees using a company email address end up inside the team you administer rather than in personal Dropbox accounts outside it.

#### Rationale
**Why This Matters:**
- An employee who signs up for Dropbox with their work email creates an account that carries your domain but sits entirely outside your admin console — no sharing policy, no device approvals, no audit trail, and nothing to revoke at offboarding
- Domain verification is the prerequisite that lets Dropbox recognize those accounts as yours; without it, invite enforcement and account capture cannot act on them
- Invite enforcement stops the problem from recurring by requiring anyone with a verified-domain address to join the managed team
- This is the shadow-IT path that identity and sharing controls cannot see, because the content never enters your tenant in the first place

**Attack Prevented:** Shadow-IT data sprawl to unmanaged accounts, unrevoked access after offboarding, corporate content held outside audit and DLP scope

#### ClickOps Implementation

**Step 1: Verify your domains**
1. Navigate to: **Admin console → Settings → Account → Domains → Manage**
2. Add each domain your organization owns and complete verification using one of Dropbox's documented methods — a meta tag on your website, an HTML file upload, or a DNS TXT record ([Dropbox: Domain verification and invite enforcement](https://help.dropbox.com/account-access/domain-verification-invite-enforcement))

**Step 2: Enable invite enforcement**
1. With the domain verified, enable invite enforcement so users on that domain are required to join your team
2. Invite enforcement requires Dropbox Advanced or above

**Step 3: Consider account capture (Enterprise)**
1. Domain insights and account capture are Enterprise-only features. Domain insights surfaces existing accounts on your verified domains; account capture brings them into the managed team ([Dropbox: Domain insights and account capture](https://help.dropbox.com/account-access/domain-insights-account-capture))
2. Account capture changes accounts people consider personal — communicate the change before enabling it

---

## 3. Third-Party App Security

### 3.1 Manage Connected Apps

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Review, approve, and revoke third-party OAuth apps connected to your Dropbox tenant, and require admin approval before new apps can be linked.

#### Rationale
**Why This Matters:**
- A linked third-party app holds delegated access to files without re-prompting the user, so it reaches content on its own schedule and outside the MFA and session controls that gate human logins
- Dropbox OAuth tokens do not expire on a documented schedule, which means a link created once tends to keep working until somebody deliberately revokes it — an app approved years ago for a project that ended is still a live path to your files
- Revoking an app inside the third-party product does not necessarily sever its Dropbox-side authorization; the revocation that matters is the one performed in Dropbox
- The 2024 Dropbox Sign breach exposed OAuth tokens, demonstrating that these credentials are a target in their own right and not merely a convenience feature

**Attack Prevented:** OAuth token abuse, consent phishing, persistent access via forgotten app links, supply-chain compromise of an approved integration, data exfiltration bypassing user MFA

#### ClickOps Implementation

**Step 1: Review connected apps**
1. Navigate to: **Admin Console → Settings → Apps**
2. Review all connected apps and revoke any you cannot attribute to a current business need
3. Treat revocation in Dropbox as the authoritative action — unlinking on the vendor's side is not a substitute

> **Verification note:** Dropbox documents the member-facing app-management flow (Settings → Connected apps in a user's own account), but the admin-console path above could not be confirmed against current Dropbox documentation during the 2026-08 currency pass. Confirm the exact console location in your own tenant before writing it into a runbook.

**Step 2: Restrict App Installation**
1. Configure: **Who can link third-party apps**
2. Require admin approval for new apps

---

## 4. Monitoring & Detection

### 4.1 Enable Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Use the Dropbox Activity page to review team activity and produce CSV reports for investigation and compliance evidence, and understand what the Activity page does and does not provide so you do not assume detection coverage it lacks.

#### Rationale
**Why This Matters:**
- Without a reviewed activity record, suspicious file access, sharing changes, and admin actions go unnoticed until the consequences surface somewhere else
- Activity reports are the forensic substrate for an investigation: who touched what, when, and from where — evidence you cannot reconstruct after the fact if nobody pulled it
- Knowing the limits of this surface matters as much as enabling it, because a team that believes it has SIEM-integrated monitoring here will not build the detection it actually needs (see [4.2](#42-configure-security-alerts))

**Attack Prevented:** Undetected data exfiltration, delayed breach detection, insufficient forensic evidence, audit gaps

#### ClickOps Implementation

**Step 1: Review activity**
1. Navigate to: **Admin console → Activity**
2. Filter the activity view by member, activity type, and date range ([Dropbox: View team activity](https://help.dropbox.com/account-access/view-activity))

**Step 2: Produce a report**
1. With filters applied, select **Create report**
2. Dropbox generates a CSV and places it in a **Dropbox Business reports** folder in your own Dropbox account

#### Scope Limitations

Three limits to plan around:

- **No SIEM export and no alerting from this surface.** The Activity page produces manually generated CSV reports. It does not stream events to a SIEM and it does not raise alerts — alerting is a separate feature, covered in [4.2](#42-configure-security-alerts). If you need continuous log delivery, that is an integration to build against the Dropbox API, not a setting to switch on here
- **File-level activity is plan-gated.** Detailed file activity is available on Business Plus, Advanced, and Enterprise only. On lower plans the record is coarser than an investigation typically needs
- **History has a floor.** Activity history begins in January 2017, or at your team's creation date if that is later

---

### 4.2 Configure Security Alerts

**Profile Level:** L2 (Walk)
**NIST 800-53:** SI-4, IR-4

#### Description
Enable Dropbox security alerts so the platform detects and notifies on high-risk behavior — ransomware activity, mass deletions and moves, sensitive external sharing, malware, and anomalous logins — and route those alerts to administrators who will act on them.

#### Rationale
**Why This Matters:**
- The Activity page ([4.1](#41-enable-audit-logging)) is a place you go and look; security alerts are what tells you to go look, and without them detection depends on somebody happening to review a report at the right moment
- Ransomware and mass-deletion detections are time-critical — the value of catching them is measured in minutes, which no manual review cadence delivers
- Built-in response actions let an administrator suspend the member and restore affected files from the alert itself, collapsing detection and containment into one step
- Tunable sensitivity matters in practice: an alert class that fires constantly gets muted, and a muted alert is the same as no alert

**Attack Prevented:** Ransomware encryption spreading unchecked, insider mass deletion or exfiltration, account takeover from anomalous locations, malware distribution through shared content

#### Prerequisites
- Security alerts are available on Dropbox Standard and Business with the Security add-on, and on Advanced, Business Plus, and Enterprise

#### ClickOps Implementation

**Step 1: Enable the detections**
1. Navigate to: **Admin console → Products → Dropbox → Security → Security alerts**
2. Dropbox provides eight detections ([Dropbox: Security alerts](https://help.dropbox.com/security/security-alerts)):

| Alert | Detects |
|-------|---------|
| Ransomware | File activity patterns consistent with ransomware encryption |
| Mass deletion | A member deleting an unusually large number of files |
| Mass move | A member moving an unusually large number of files |
| Sensitive external sharing | Content classified as sensitive being shared outside the team |
| External malware | Malware detected in content shared from outside the team |
| Internal malware | Malware detected in content shared within the team |
| Excessive logins | An unusual volume of login attempts on an account |
| High-risk country logins | Sign-ins from countries you have designated high-risk |

3. Enable each detection your plan supports and tune its sensitivity — start permissive enough that the alerts stay credible, then tighten

**Step 2: Route the alerts**
1. Send alerts to all administrators, or to named admin groups where you have divided responsibility by role (see [1.4](#14-assign-granular-admin-roles))

**Step 3: Prepare the response**
1. From an alert, an administrator can suspend the member, email the affected contact, and restore affected files
2. Agree in advance who is authorized to suspend a member, so the decision is not being made for the first time during an incident

---

### 4.3 Enable Data Classification

**Profile Level:** L3 (Run)
**NIST 800-53:** RA-2, SI-4

#### Description
Enable Dropbox data classification so the platform automatically identifies files containing regulated personal data — credit card numbers, passport numbers, bank account numbers, and social security numbers — and alerts administrators when that content is shared externally.

#### Rationale
**Why This Matters:**
- Teams routinely cannot answer where regulated data sits in their file store, which makes both breach impact assessment and regulatory response guesswork
- Automatic detection turns a policy statement about handling sensitive data into something observable, and pairs with the sensitive-external-sharing alert in [4.2](#42-configure-security-alerts)
- External-share alerts carry the filename, location, detected data types, and recipient — enough for a responder to judge severity without first reconstructing what was in the file

**Attack Prevented:** Undetected exposure of regulated personal data, uncontrolled external sharing of sensitive content, unquantifiable breach scope

#### Prerequisites
- Availability is limited by region and by plan; confirm your team qualifies before designing around it
- Dropbox documents that the feature is unavailable for very large teams — check this before planning a rollout at scale

#### ClickOps Implementation

**Step 1: Enable classification**
1. Enable data classification for your team ([Dropbox: Data classification](https://help.dropbox.com/teams-admins/admin/data-classification))
2. Dropbox automatically scans for credit card numbers, passport numbers, bank account numbers, and social security numbers

**Step 2: Act on external-share alerts**
1. Alerts fire when classified content is shared externally and include the filename, its location, the data types detected, and the recipient
2. Route these to the same responders handling [4.2](#42-configure-security-alerts)

#### Scope Limitation

Classification scans **team folders only**. Content in individual member folders and in shared folders outside the team folder structure is not scanned. A team that stores regulated data outside team folders gets no coverage from this control, so treat team-folder placement as a prerequisite for the classification program rather than an implementation detail.

---

## Appendix A: Edition Compatibility

| Control | Standard | Advanced | Business Plus | Enterprise |
|---------|----------|----------|---------------|------------|
| SSO (SAML) | ❌ | ✅ | ✅ | ✅ |
| Audit Log | Basic | ✅ | ✅ | ✅ |
| File-level activity | ❌ | ✅ | ✅ | ✅ |
| Device approvals | ✅ | ✅ | ✅ | ✅ |
| Granular admin roles | ❌ | ✅ | ✅ | ✅ |
| Invite enforcement | ❌ | ✅ | ✅ | ✅ |
| Domain insights / account capture | ❌ | ❌ | ❌ | ✅ |
| Security alerts | Security add-on | ✅ | ✅ | ✅ |
| Data classification | Security add-on | ✅ | ✅ | ✅ |
| Network control | ❌ | ❌ | ❌ | ✅ |

Data classification and security alerts are additionally gated by region and, for data classification, by team size — see [4.2](#42-configure-security-alerts) and [4.3](#43-enable-data-classification).

---

## Appendix B: References

**Official Dropbox Documentation:**
- [Help Center](https://help.dropbox.com/)
- [Single sign-on for admins](https://help.dropbox.com/security/sso-admin)
- [Device approvals](https://help.dropbox.com/account-access/device-approvals)
- [Change admin rights](https://help.dropbox.com/security/change-admin-rights)
- [Domain verification and invite enforcement](https://help.dropbox.com/account-access/domain-verification-invite-enforcement)
- [Domain insights and account capture](https://help.dropbox.com/account-access/domain-insights-account-capture)
- [View team activity](https://help.dropbox.com/account-access/view-activity)
- [Security alerts](https://help.dropbox.com/security/security-alerts)
- [Data classification](https://help.dropbox.com/teams-admins/admin/data-classification)
- [Network control](https://help.dropbox.com/security/network-control)

**API & Developer Documentation:**
- [Dropbox HTTP API Overview](https://www.dropbox.com/developers/documentation/http/overview)
- [Dropbox Developer Center](https://www.dropbox.com/developers)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018, ISO 22301, ISO 27701
- CSA STAR Level 2 Certification and Attestation
- GDPR, HIPAA compliant

Request current attestation reports directly from Dropbox rather than relying on this list.

**Security Incidents:**
- **2024 Dropbox Sign Breach:** Compromised service account exposed OAuth tokens, API keys, hashed passwords, and MFA data for Dropbox Sign (formerly HelloSign) users.
- **2022 GitHub Repository Breach:** Phishing attack against Dropbox employees resulted in 130 private code repositories being accessed and copied (per Dropbox's 2022 disclosure).
- **2012 Password Breach:** Credentials stolen from a third-party site used to access a Dropbox employee account, leading to exposure of approximately 68 million user email addresses and hashed passwords (disclosed publicly in 2016).

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | ai-drafted | Thin-guide expansion and currency pass against Dropbox Help Center documentation — control count 5 → 11. Added 1.3 device approvals and web session limits, 1.4 granular admin roles, 1.5 network control, 2.2 domain verification and invite enforcement, 4.2 security alerts, and 4.3 data classification. Corrected 1.1 (SSO console path; Optional-vs-Required modes, where Optional leaves a password bypass; plan gating), 3.1 (softened the perpetual-refresh-token claim and annotated the unverified admin app path), and 4.1 (the Activity page produces manual CSV reports, not SIEM export or alerting; file-level activity is plan-gated; history starts January 2017). Repaired the cheat-parser contract on 1.1 and 3.1, which were missing **Attack Prevented:**. Reconciled the 2022 GitHub breach figure at 130 repositories across Overview and Appendix B. Rebuilt Appendix A with a Business Plus column and corrected device-approval and data-classification plan coverage; removed Trust Center, certifications, and whitepaper references from Appendix B. Tier 2 (CIS, DISA STIG, CISA SCuBA) confirmed zero coverage for Dropbox; Tier 3/4 not surveyed this pass. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | ai-drafted | Initial Dropbox hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
