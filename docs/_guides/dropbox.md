---
layout: guide
title: "Dropbox Hardening Guide"
vendor: "Dropbox"
slug: "dropbox"
tier: "3"
category: "Data"
description: "Cloud storage security for sharing policies, linked apps, and admin controls"
version: "0.3.1"
maturity: ["ai-drafted", "ai-validated"]
last_updated: "2026-09-25"
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

**Automation surface:** every Code Pack here is an `api` pack against the [Dropbox Business API](https://docs.dropboxapi.com/dropbox-api/api-reference/business-endpoints/overview), and that is the whole surface rather than a preference. The only Terraform provider for Dropbox is a 2021 community provider with no team-administration resources. `dbxcli` is vendor-published but not officially supported, and its team commands print neither the team policies nor the granular admin roles. The official SDKs wrap the same HTTP API the packs call directly. The API itself has no write endpoint for any of the policy toggles in this guide, so the packs are read-only audits that prove what the console set, and controls with no readable state carry an Automation line instead (census of the 103 business endpoints, 2026-09-24).

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

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path and the SSO and two-factor options observed read-only on a live Dropbox Advanced trial team; nothing changed" date="2026-09-25" %}

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

**Automation:** ClickOps only — Dropbox exposes no write interface for this setting ([Dropbox Business API](https://docs.dropboxapi.com/dropbox-api/api-reference/business-endpoints/overview), 2026-09-24). No endpoint reads the current SSO mode either. A change to it is recorded afterwards in the team event log as a `sso_change_policy` event, which the [4.1](#41-enable-audit-logging) export pack collects.

#### Validation & Testing
1. With SSO set to Required, attempt a member sign-in using a Dropbox password and confirm it is rejected
2. Disable a test user in the IdP and confirm Dropbox access stops

---

### 1.2 Configure Access Permissions

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Share each team folder only with the people and groups whose role requires it, give groups view-only access unless they need to edit, and keep top-level team folder creation with admins, so members can only reach the content their role requires.

#### Rationale
**Why This Matters:**
- Default-open or overly broad folder permissions let any member browse content well beyond their role, widening the blast radius of a single compromised account
- Least-privilege access on team folders limits how much data an attacker or malicious insider can reach if they obtain a valid session
- By default everyone on the team can create top-level team folders, so the folder structure, and who is granted access to each folder, grows member by member unless admins keep that permission

**Attack Prevented:** Privilege escalation, lateral movement, insider data access, over-broad data exposure

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Content page, folder Manage access, Create team folder and Top-level folder management walked on the live console and the steps corrected; nothing saved" date="2026-09-25" %}

**Step 1: Scope each team folder**
1. Navigate to: **Admin console → Products → Dropbox** (the dropdown under Products) **→ Content** ([Dropbox: Team folder manager](https://help.dropbox.com/organize/team-folder-manager))
2. For each team folder that holds role-scoped content, open its **More actions** menu → **Manage access**. Add the groups or people who need it in **Add people by name or email** (groups rather than individuals where you can), then set the **Everyone at [team name]** entry to **remove**. For a new folder, choose **Create team folder → Who will have access → Only specific people** instead
3. Set each entry to **can view** unless it needs to edit

**Step 2: Narrow one member's access**
1. Navigate to: **Admin console → Members**, then **Manage access** next to the member
2. Uncheck the team folders they should not reach, set **Can view** where editing is not required, and click **Apply**

**Step 3: Keep top-level team folders with admins**
1. Navigate to: **Admin console → Products → Dropbox** (the dropdown under Products) **→ Settings → Content** tab → **Top-level folder management**, and set it to **Admins only** (the default is **All members**). The **Change setting** link on the Content page's **Member access** line opens the same setting

#### Code Implementation

{% include pack-code.html vendor="dropbox" section="1.2" %}

The pack is read-only. Changing folder membership through the API (`sharing/add_folder_member`, `sharing/update_folder_member`, `sharing/update_folder_policy` with the `Dropbox-API-Select-Admin` header) is a per-folder decision and is deliberately not scripted here.

---

### 1.3 Enforce Device Approvals and Session Limits

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-11, AC-12, AC-19, IA-3

#### Description
Cap how many computers and mobile devices each member can link to the Dropbox desktop and mobile apps, decide what happens when a member reaches the cap, and bound how long a web session stays valid through fixed session duration and idle timeout settings.

#### Rationale
**Why This Matters:**
- Without a device cap, an attacker holding valid credentials can link their own machine and get a full local sync of everything the member can reach — the fastest available route from one credential to bulk exfiltration
- Device caps make the appearance of an unexpected device an event someone notices, instead of one more entry in a list nobody reads
- Fixed session duration and idle timeout bound how long a stolen browser session remains usable, which is the exposure that device limits do not address
- Knowing in advance how to remote wipe a lost or offboarded member's device, which deletes the team's files from it the next time it connects, turns device loss into a practiced step rather than an improvised one

**Attack Prevented:** Unauthorized device linking, bulk sync exfiltration from a stolen credential, session hijacking, stale-session abuse

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Security tab Devices section and the member Devices remove icon read on the live console and the steps corrected; remote wipe dialog not opened" date="2026-09-25" %}

**Step 1: Set device limits**
1. Navigate to: **Admin console → Settings → Security** tab → **Devices** section. The settings sit in the section itself; there is no separate Device approvals page ([Dropbox: Device approvals](https://help.dropbox.com/account-access/device-approvals))
2. **Computers** and **Mobile devices**: choose the maximum each member may connect (**Unlimited**, or 0 to 5). The two limits are set separately
3. **Device limit reached**: choose what happens when a member reaches the limit — **Remove oldest**, **Remove all**, or **Make exception**
4. **Disconnected devices**: **Remove** (a disconnected device no longer counts toward the limit) or **Keep** (it counts until an admin removes it). This setting only governs the device count; it does not delete anything from the device
5. **Exceptions → Add exceptions** only where there is a documented reason

**Step 2: Bound web sessions**
1. In the same **Security** settings, set **Fixed web session** — a hard cap on session lifetime, configurable from 1 day to 1 year ([Dropbox: Web session control](https://help.dropbox.com/security/web-session-control)). Reducing it logs out every team member, so schedule the change
2. Set **Idle web sessions** — configurable from None up to 48 hours. Leaving this at None means an abandoned browser session stays live until the fixed duration expires

**Step 3: Remote wipe a lost or offboarded device**
1. Deleting team files from a device is a separate, per-device action called **Remote wipe**, available on Advanced, Business, Business Plus, and Enterprise ([Dropbox: Remote wipe a team member's device](https://help.dropbox.com/delete-restore/remote-wipe))
2. Navigate to: **Admin console → Members**, click the member's name, then under **Devices** click the **Remove** (trash can) icon next to the device
3. Check **Delete files from [Organization name] Dropbox the next time this computer comes online**, then click **Sign out**. A remote wipe cannot be undone

#### Code Implementation

{% include pack-code.html vendor="dropbox" section="1.3" %}

The device caps, the limit-reached and disconnected-device actions and the web session lengths have no API: nothing sets them and nothing reads their current value. The pack reads the outcome instead, every linked device and web session, and measures it against the caps you set. Signing a session out, and remote wipe, is `team/devices/revoke_device_session` with `delete_on_unlink`; it is an incident action and is not scripted here.

#### Scope Limitation

Device limits govern the Dropbox **desktop and mobile applications only**. They do not apply to browser access at dropbox.com — a credential with no linked device at all can still sign in on the web. The web session settings in Step 2 are what bound that path, which is why both halves of this control matter.

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

#### Code Implementation

{% include pack-code.html vendor="dropbox" section="1.4" %}

The pack counts holders of each role and flags a Team admin population above your limit. Changing a role is `team/members/set_admin_permissions_v2`, which accepts at most one role per member; it is not scripted here, because a bulk demotion can remove the last Team admin or the admin whose token is running. `dbxcli team list-members` prints only the legacy admin tier, not these eight roles.

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

**Automation:** ClickOps only — Dropbox exposes no write interface for this setting ([Dropbox Business API](https://docs.dropboxapi.com/dropbox-api/api-reference/business-endpoints/overview), 2026-09-24). Enablement itself is performed by your Dropbox account manager. A later change to the policy is recorded in the team event log as a `network_control_change_policy` event, which the [4.1](#41-enable-audit-logging) export pack collects.

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

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="External sharing settings and option lists read on the live console, link security settings revealed by an unsaved change then undone; steps corrected" date="2026-09-25" %}

**Step 1: Restrict who content can be shared with**
1. Navigate to: **Admin console → Products → Dropbox** (the dropdown under Products) **→ Settings → External sharing** ([Dropbox: Manage team sharing](https://help.dropbox.com/share/manage-team-sharing))
2. **Who can be added to files and folders:** **Members only**, or **Members + approved people** with a curated **Approved list**. The approved list does not apply to shared links
3. **Sharing links to files and folders:** **Off** unless members need to send links outside the team. Off also stops existing member-created links from working for people outside the team

**Step 2: Set shared link defaults**
1. **Who can access links by default:** **Team members only** (or **Only people added**). While this is **Anyone**, the console does not show the password and expiration settings below
2. **What permissions recipients have by default:** **Can view**. With the default, **None**, a link grants **Can edit** unless the member has set their own default
3. **Expiration for links:** 30 days (L2: 7 days). It applies to links a member explicitly sets to **Anyone**
4. **Passwords for links:** **On**, which requires a password on links a member explicitly sets to **Anyone**
5. **Universal link restriction for folders:** **On**, so only people added to a folder can open it through a link
6. Click **Save**. Changes on this tab are staged until you save them

#### Code Implementation

{% include pack-code.html vendor="dropbox" section="2.1" %}

The settings above are readable through `team/get_info` (the approved list through `team/sharing_allowlist/list`), and none of them is writable through the API; the pack proves the console configuration. **Sharing links to files and folders** has no field of its own: the API reference describes the `shared_link_create_policy` value `team_only` as "Only members of the same team can access all shared links", which matches **Off**, and the `default_*` values as defaults members can override, which matches **On**. That mapping comes from the documentation, not from a live team, so the pack reports it as information rather than a finding. The only related write surface, `team/sharing_allowlist/add` and `remove`, edits the approved list and is not scripted here.

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

**Automation:** ClickOps only — Dropbox exposes no write interface for this setting ([Dropbox Business API](https://docs.dropboxapi.com/dropbox-api/api-reference/business-endpoints/overview), 2026-09-24). No endpoint verifies a domain or reads invite enforcement or account capture. Changes appear afterwards in the team event log (`domain_verification_*`, `enabled_domain_invites`, `account_capture_change_policy`), which the [4.1](#41-enable-audit-logging) export pack collects. The DNS TXT record used for verification lives in your own DNS, not in Dropbox.

---

## 3. Third-Party App Security

### 3.1 Manage Connected Apps

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Block members from connecting third-party apps by default, allow only the apps you have approved, and review and revoke the app links that already exist, since blocking an app does not disconnect members already linked to it.

#### Rationale
**Why This Matters:**
- A linked third-party app holds delegated access to files without re-prompting the user, so it reaches content on its own schedule and outside the MFA and session controls that gate human logins
- Dropbox OAuth tokens do not expire on a documented schedule, which means a link created once tends to keep working until somebody deliberately revokes it — an app approved years ago for a project that ended is still a live path to your files
- Revoking an app inside the third-party product does not necessarily sever its Dropbox-side authorization; the revocation that matters is the one performed in Dropbox
- The 2024 Dropbox Sign breach exposed OAuth tokens, demonstrating that these credentials are a target in their own right and not merely a convenience feature

**Attack Prevented:** OAuth token abuse, consent phishing, persistent access via forgotten app links, supply-chain compromise of an approved integration, data exfiltration bypassing user MFA

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Integrations defaults, app actions, the Add exception dialog and member Connected apps read on the live console and the steps corrected; nothing saved" date="2026-09-25" %}

**Step 1: Block by default, then allow what you approved**
1. Navigate to: **Admin console → Products → Dropbox** (the dropdown under Products) **→ Settings → Integrations** tab ([Dropbox: Manage apps for your team](https://help.dropbox.com/integrations/app-integrations))
2. Under **Default connection permissions**, set **Connecting registered integrations** to **Block**
3. Set **Connecting unregistered integrations** to **Block** as well. It governs apps that are not registered in the Dropbox App Center, which the registered-integrations setting does not cover
4. In the app list at the bottom of the tab, **Allow** only the apps you have approved, from each app's **More actions** menu. Filter by **In App Center** or **Not in App Center** to find them
5. For custom apps that are not in the App Center, switch the list filter to **Not in App Center**, click **Add exceptions**, enter the app key or the app ID (prefix `dbaid:`), click **Next**, and choose **Allow** or **Block**
6. Dropbox has no approval-request workflow for new apps; the block-by-default setting plus an allow list is the mechanism. Google Calendar and Outlook Calendar and Contacts are allowed by default and cannot be blocked

**Step 2: Revoke existing connections**
1. Blocking does not disconnect members who are already connected to an app, so every link made before the block survives it
2. Use the pack below to list every app still linked to a member, then revoke each one you cannot attribute to a current business need. Treat revocation in Dropbox as the authoritative action; unlinking on the vendor's side is not a substitute
3. To revoke one member's link in the console, go to **Admin console → Members**, click the member's name, then under **Connected apps** click the **Disconnect app** (trash can) icon next to the app

#### Code Implementation

{% include pack-code.html vendor="dropbox" section="3.1" %}

The block and allow settings have no API: nothing sets them and nothing reads them. The pack reads the links that exist, one row per app with how many members linked it and when, and judges each against your approved list. Revocation is `team/linked_apps/revoke_linked_app`; it is left to the reviewer, one app at a time.

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

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Activity page filters and the Create report dialog read on the live console, then cancelled; no report generated, so the CSV destination folder is from Dropbox's help article" date="2026-09-25" %}

**Step 1: Review activity**
1. Navigate to: **Admin console → Activity**
2. Filter the activity view by member, activity type, and date range ([Dropbox: View team activity](https://help.dropbox.com/account-access/view-activity))

**Step 2: Produce a report**
1. With filters applied, select **Create report**
2. The **Generate member activity report** dialog builds the report from the filters you selected. Leave **Exclude file operations** unchecked when you need file-level events; checking it generates the report faster without them. Click **Generate**
3. Dropbox saves the report as a CSV in a folder named **Dropbox Business reports** in your own Dropbox account and emails you when it is ready ([Dropbox: View team activity](https://help.dropbox.com/account-access/view-activity))

#### Scope Limitations

Three limits to plan around:

- **No SIEM export and no alerting from this surface.** The Activity page produces manually generated CSV reports. It does not stream events to a SIEM and it does not raise alerts — alerting is a separate feature, covered in [4.2](#42-configure-security-alerts). If you need continuous log delivery, that is an integration to build against the Dropbox API, not a setting to switch on here; the pack below is that integration's core
- **File-level activity is plan-gated.** Detailed file activity is available on Business Plus, Advanced, and Enterprise only. On lower plans the record is coarser than an investigation typically needs
- **History has a floor.** Activity history begins in January 2017, or at your team's creation date if that is later

#### Code Implementation

{% include pack-code.html vendor="dropbox" section="4.1" %}

The pack pulls one time window of the team event log through `team_log/get_events` and `team_log/get_events/continue` and writes one event per line to stdout, for a scheduler or log shipper to forward to your SIEM. There is nothing to enable or write: the log is always on, and no endpoint sets its retention or a destination. A window that returns no events exits non-zero, because an empty feed and a broken feed look the same downstream.

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
- Sensitivity tuning on the Mass deletion and Mass data move alerts matters in practice: an alert class that fires constantly gets muted, and a muted alert is the same as no alert

**Attack Prevented:** Ransomware encryption spreading unchecked, insider mass deletion or exfiltration, account takeover from anomalous locations, malware distribution through shared content

#### Prerequisites
- Security alerts are available on Dropbox Standard and Business with the Security add-on, and on Advanced, Business Plus, and Enterprise

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Security alerts, the Alerts policies list and policy Edit pages read on the live console and the steps corrected; no policy saved" date="2026-09-25" %}

**Step 1: Enable the detections**
1. Navigate to: **Admin console → Products → Dropbox → Security → Security alerts**, then click **Set alert policies**
2. The **Alerts policies** page lists eight detections ([Dropbox: Security alerts](https://help.dropbox.com/security/security-alerts)):

| Alert | Detects |
|-------|---------|
| Ransomware suspected | File activity patterns consistent with ransomware encryption |
| Mass deletion | A member deleting an unusually large amount of data over a short period |
| Mass data move | A member moving an unusually large number of files |
| Sensitive content in team folders shared externally | Content classified as sensitive being shared outside the team |
| Malware shared from outside your team | Malware detected in content shared from outside the team |
| Malware shared by a team member | Malware detected in content a team member shares |
| Too many sign-in attempts | An unusual volume of sign-in attempts on an account |
| Sign-in from a high-risk country | Sign-ins from a Dropbox-defined list of high-risk countries (currently Afghanistan, China, Cuba, DPRK, Iran, Libya, Nigeria, Sudan, Syria, and Yemen); the list is not admin-configurable |

3. All eight are on by default. For each, open **Row actions → Edit** and confirm **Status** is on. **Alert sensitivity** (1 - Low to 5 - High) is offered only for **Mass deletion** and **Mass data move**: start those permissive enough that the alerts stay credible, then tighten

**Step 2: Route the alerts**
1. On each policy's **Edit** page, under **Notifications**, choose **All team admins** or **Specific team admins / security admins / groups**, then click **Save**. Only active Team admins and Security admins can receive notifications, so route to named admins where you have divided responsibility by role (see [1.4](#14-assign-granular-admin-roles))

**Step 3: Prepare the response**
1. From an alert, an administrator can suspend the member, email the affected contact, and restore affected files
2. Agree in advance who is authorized to suspend a member, so the decision is not being made for the first time during an incident

**Automation:** ClickOps only — Dropbox exposes no write interface for this setting ([Dropbox Business API](https://docs.dropboxapi.com/dropbox-api/api-reference/business-endpoints/overview), 2026-09-24). No endpoint reads the current alert configuration either. Triggered alerts and configuration changes are recorded in the team event log under the `admin_alerting` category (`admin_alerting_triggered_alert`, `admin_alerting_changed_alert_config`); run the [4.1](#41-enable-audit-logging) export pack with `HTH_DROPBOX_EVENTS_CATEGORY=admin_alerting` to forward them.

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

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Classification labeling options and info types revealed by an unsaved change on the live console, then undone" date="2026-09-25" %}

**Step 1: Enable classification**
1. Navigate to: **Admin console → Products → Dropbox** (the dropdown under Products) **→ Classification** ([Dropbox: Data classification](https://help.dropbox.com/teams-admins/admin/data-classification))
2. Next to **Personal information labeling**, select **Member and team content**. **Only scan team content** leaves member folders unscanned
3. Uncheck only the **Info types** that cannot occur in your data, then click **Save**. Detection covers credit card, passport, bank account, and social security numbers; the console lists the full set

**Step 2: Act on external-share alerts**
1. Alerts fire when classified content in a team folder is shared externally and include the filename, its location, the data types detected, and the recipient
2. Route these to the same responders handling [4.2](#42-configure-security-alerts)

**Automation:** ClickOps only — Dropbox exposes no write interface for this setting ([Dropbox Business API](https://docs.dropboxapi.com/dropbox-api/api-reference/business-endpoints/overview), 2026-09-24). No endpoint reads whether classification is on. A change to it is recorded in the team event log as a `classification_change_policy` event, which the [4.1](#41-enable-audit-logging) export pack collects.

#### Scope Limitation

What gets scanned depends on the **Personal information labeling** choice in Step 1. Dropbox documents classification as covering team folders, team member folders, and shared folders, but **Only scan team content** leaves member folders out of the scan, so select **Member and team content** for that coverage. The **external-sharing alert**, not the underlying scan, fires only for content in team folders: a file in a member folder, or in a shared folder outside the team folder structure, can be classified but raises no alert when it is shared externally. A team that stores regulated data outside team folders therefore gets detection without alerting, so treat team-folder placement as a prerequisite for the alerting half of this control.

---

## Appendix A: Edition Compatibility

| Control | Standard | Business | Advanced | Business Plus | Enterprise |
|---------|----------|----------|----------|---------------|------------|
| SSO (SAML) | ❌ | ❌ | ✅ | ✅ | ✅ |
| Audit Log | Basic | Basic | ✅ | ✅ | ✅ |
| File-level activity | ❌ | ❌ | ✅ | ✅ | ✅ |
| Device approvals | ✅ | ✅ | ✅ | ✅ | ✅ |
| Remote wipe | ❌ | ✅ | ✅ | ✅ | ✅ |
| Granular admin roles | ❌ | ❌ | ✅ | ✅ | ✅ |
| Invite enforcement | ❌ | ❌ | ✅ | ✅ | ✅ |
| Domain insights / account capture | ❌ | ❌ | ❌ | ❌ | ✅ |
| Security alerts | Security add-on | Security add-on | ✅ | ✅ | ✅ |
| Data classification | Security add-on | ✅ | ✅ | ✅ | ✅ |
| Network control | ❌ | ❌ | ❌ | ❌ | ✅ |

Data classification and security alerts are additionally gated by region and, for data classification, by team size — see [4.2](#42-configure-security-alerts) and [4.3](#43-enable-data-classification).

---

## Appendix B: References

**Official Dropbox Documentation:**
- [Help Center](https://help.dropbox.com/)
- [Single sign-on for admins](https://help.dropbox.com/security/sso-admin)
- [Team folder manager](https://help.dropbox.com/organize/team-folder-manager)
- [Device approvals](https://help.dropbox.com/account-access/device-approvals)
- [Web session control](https://help.dropbox.com/security/web-session-control)
- [Remote wipe a team member's device](https://help.dropbox.com/delete-restore/remote-wipe)
- [Manage team sharing](https://help.dropbox.com/share/manage-team-sharing)
- [Manage apps for your team](https://help.dropbox.com/integrations/app-integrations)
- [Change admin rights](https://help.dropbox.com/security/change-admin-rights)
- [Domain verification and invite enforcement](https://help.dropbox.com/account-access/domain-verification-invite-enforcement)
- [Domain insights and account capture](https://help.dropbox.com/account-access/domain-insights-account-capture)
- [View team activity](https://help.dropbox.com/account-access/view-activity)
- [Security alerts](https://help.dropbox.com/security/security-alerts)
- [Data classification](https://help.dropbox.com/teams-admins/admin/data-classification)
- [Network control](https://help.dropbox.com/security/network-control)

**API & Developer Documentation:**
- [Dropbox HTTP API Overview](https://www.dropbox.com/developers/documentation/http/overview)
- [Dropbox Business API](https://docs.dropboxapi.com/dropbox-api/api-reference/business-endpoints/overview)
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
| 2026-09-25 | 0.3.1 | ai-drafted · ai-validated | Added **ai-validated** to this guide's status set, which now reads **ai-drafted** + **ai-validated**. A `validate-hth-guide` run walked the live Admin console of a Dropbox Advanced trial team, read-only, and **8 of 22 implementation surfaces came back VERIFIED-LIVE, all of them ClickOps**: 1.1, 1.2, 1.3, 2.1, 3.1, 4.1, 4.2, and 4.3, each marked on its heading. Nothing was saved in the tenant; the two settings changed to reveal hidden options were undone before saving. No Code surface ran live, because no team API token was stored, and 1.4 (needs a second member), 1.5 (Enterprise only), and 2.2 (needs a verifiable domain) could not be exercised. Corrected against the console: 1.2 (change an existing folder's access through **More actions → Manage access**; **Only specific people** exists only when creating a folder; top-level folder creation is **Settings → Content → Top-level folder management**), 1.3 (the device settings sit in the **Devices** section of the Security tab, and there is no device-approver choice; the per-device remove control is a trash-can icon), 2.1 (the console's setting names, **Passwords for links** and **Expiration for links** appear only when default access is not **Anyone**, and the tab needs **Save**; the 2.1 audit pack now prints the same names), 3.1 (**Connecting unregistered integrations** must be blocked too; **Add exceptions** sits behind the **Not in App Center** filter; revoke a member's app from the member's **Connected apps**), 4.1 (**Create report** opens a **Generate member activity report** dialog with an **Exclude file operations** option and a separate **Generate** click; where the CSV lands is Dropbox's documented behavior and was not observed, because no report was generated), and 4.2 (open **Set alert policies**; the console's eight alert names; sensitivity and notification routing live on each policy's **Edit** page). The six API packs' headers now say that a token generated in the Dropbox App Console also carries `team_data.governance.write`: the console would not save team scopes without `team_data.member`, and ticking `team_data.member` locks that scope on. These read-only packs therefore run with a write-capable token. An AI agent did this; no human practitioner has reviewed or applied this guide, so it claims no **ni-** status. | Claude Code (Opus 5.5) |
| 2026-09-25 | 0.3.0 | ai-drafted | `validate-hth-guide` fix pass against current Dropbox Help Center and Business API documentation. The live console stayed behind a sign-in wall, so 0 of 22 implementation surfaces were exercised live and the maturity set is unchanged. Corrected 1.2 (console path under Products → Dropbox → Content; replaced the undocumented "default permissions by team" and "admin folder" steps with per-folder sharing, Manage Access, and top-level folder creation), 1.3 (the Disconnected devices setting governs the device count only; remote wipe is a separate per-device action; console labels Fixed web session and Idle web sessions), 2.1 (console path under Products → Dropbox → Settings → External sharing and the current setting names, including the rule that expiration and passwords need default access other than Anyone; Share links to files and folders maps to the documented `team_only` value rather than being console-only), 3.1 (Settings → Integrations block-by-default with per-app Allow and Add exception; Dropbox has no approval workflow, and blocking does not disconnect existing links), 4.2 (the high-risk country list is Dropbox-defined; sensitivity tuning applies to Mass deletion and Mass move only), and 4.3 (added the console path and the Personal information labeling choice, where Only scan team content leaves member folders unscanned; only the external-sharing alert is limited to team folders). Appendix A gains a Business column and a Remote wipe row. Rule 4: six read-only API audit packs (1.2, 1.3, 1.4, 2.1, 3.1, 4.1), which exit 2 rather than report a result when a list is not read to the end or admin roles are missing, and evidenced `**Automation:**` lines for 1.1, 1.5, 2.2, 4.2, and 4.3, which have no write or current-state read endpoint. | Claude Code (Opus 5.5) |
| 2026-08-08 | 0.2.0 | ai-drafted | Thin-guide expansion and currency pass against Dropbox Help Center documentation — control count 5 → 11. Added 1.3 device approvals and web session limits, 1.4 granular admin roles, 1.5 network control, 2.2 domain verification and invite enforcement, 4.2 security alerts, and 4.3 data classification. Corrected 1.1 (SSO console path; Optional-vs-Required modes, where Optional leaves a password bypass; plan gating), 3.1 (softened the perpetual-refresh-token claim and annotated the unverified admin app path), and 4.1 (the Activity page produces manual CSV reports, not SIEM export or alerting; file-level activity is plan-gated; history starts January 2017). Repaired the cheat-parser contract on 1.1 and 3.1, which were missing **Attack Prevented:**. Reconciled the 2022 GitHub breach figure at 130 repositories across Overview and Appendix B. Rebuilt Appendix A with a Business Plus column and corrected device-approval and data-classification plan coverage; removed Trust Center, certifications, and whitepaper references from Appendix B. Tier 2 (CIS, DISA STIG, CISA SCuBA) confirmed zero coverage for Dropbox; Tier 3/4 not surveyed this pass. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | ai-drafted | Initial Dropbox hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
