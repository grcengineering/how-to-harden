---
layout: guide
title: "Google Chat Hardening Guide"
vendor: "Google Chat"
slug: "google-chat"
platform: "Google Workspace"
platform_slug: "google-workspace"
product: "Google Chat"
tier: "1"
category: "Productivity"
description: "Security hardening for Google Chat — app & webhook controls, external chat & spaces, file sharing, history, retention & auto-deletion, third-party archiving, DLP for Chat, space access defaults and space inventory, audit logging, content protection, moderation, and Policy API drift detection."
version: "0.3.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-12"
---

## Overview

Google Chat is the messaging surface of Google Workspace, and an increasingly common path for data exfiltration, phishing, and malware delivery that is monitored less rigorously than email. This guide hardens Chat-specific surfaces: which apps and webhooks can run inside conversations, whether users can chat or share spaces externally, file-sharing posture, history/retention for traceability, and the audit + content-reporting controls that turn Chat into a detection sensor.

This is a **product guide within the [Google Workspace platform](/guides/google-workspace/)**. Platform-wide controls (authentication, OAuth app allowlisting, DLP engine, admin audit logging) live in the Google Workspace **Common Controls** hub and are referenced here rather than duplicated.

> **What changed for automation:** Chat settings have historically been ClickOps-only, and much published guidance still says so. That is now half-true. The **Cloud Identity Policy API** exposes eight Chat settings for **reading** — `chat.chat_apps_access`, `chat.external_chat_restriction`, `chat.external_spaces`, `chat.chat_file_sharing`, `chat.chat_history`, `chat.space_history`, `chat.space_access_default`, and `chat.third_party_archiving` — so almost every control in this guide can now be **continuously verified in code** even though none can be **set** in code (`Mutate supported: No` for all of them). The practical consequence runs through the whole guide: configure in the console, then prove and monitor with [3.4](#34-continuously-verify-chat-configuration-with-the-policy-api). Code Packs on each control follow that split, and say plainly which half they are.

### Intended Audience
- Security engineers managing Google Workspace / Google Chat
- IT administrators configuring Admin Console Chat settings
- GRC professionals assessing collaboration-tool compliance (CISA SCuBA, SOC 2)
- Incident responders monitoring messaging-based exfiltration

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Google Chat hardening in the Google Workspace Admin Console: Chat app & webhook installation controls, external chat/spaces/group-DM restrictions, Chat file-sharing posture, history plus Vault-based retention and auto-deletion, third-party archiving, Chat-scoped DLP rules, space access defaults and org-wide space inventory, and Chat audit logging, content protection, moderation, and configuration drift detection. Platform-wide authentication, OAuth allowlisting, the DLP engine itself, and admin-console audit logging are covered in the [Google Workspace guide](/guides/google-workspace/). Gmail and Drive are covered in their own product guides.

---

## Table of Contents

1. [App & Integration Security](#1-app--integration-security)
2. [Data Security](#2-data-security)
3. [Monitoring & Detection](#3-monitoring--detection)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

**Controls in this guide**

| # | Control | Level | Automatable? |
|---|---------|-------|--------------|
| [1.1](#11-restrict--allowlist-google-chat-apps) | Restrict & allowlist Chat apps | L1 | Verify (Policy API) |
| [2.1](#21-restrict-external-google-chat--spaces) | Restrict external chat & spaces | L1 | Verify (Policy API) |
| [2.2](#22-restrict-google-chat-file-sharing) | Restrict Chat file sharing | L2 | Verify (Policy API) |
| [2.3](#23-enforce-google-chat-history--retention) | Enforce history & retention | L2 | Verify (Policy API) + enforce holds (Vault API) |
| [2.4](#24-configure-chat-auto-deletion-retention) | Auto-deletion retention | L2 | ClickOps only |
| [2.5](#25-apply-dlp-to-google-chat-messages-and-attachments) | DLP for Chat | L2 | ClickOps only |
| [2.6](#26-set-the-default-space-access-to-restricted) | Restricted space access default | L2 | Verify (Policy API) + inventory (Chat API) |
| [2.7](#27-govern-third-party-chat-archiving) | Govern third-party archiving | L2 | Verify (Policy API) |
| [3.1](#31-enable-google-chat-audit-logging--content-reporting) | Audit logging & content reporting | L1 | Enforce + detect (Reports API, BigQuery) |
| [3.2](#32-understand-chat-content-protection-coverage-limits) | Content protection coverage limits | L1 | ClickOps only |
| [3.3](#33-delegate-a-scoped-chat-moderator-role) | Scoped Chat moderator role | L2 | Enforce (Directory API) |
| [3.4](#34-continuously-verify-chat-configuration-with-the-policy-api) | Policy API drift detection | L2 | Enforce (Policy API) |

---

## 1. App & Integration Security

### 1.1 Restrict & Allowlist Google Chat Apps

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5, 2.7 |
| NIST 800-53 | AC-3, CM-7 |
| CIS Google Workspace | 2.1 |

#### Description
Control which Google Chat apps (bots) and incoming webhooks users can add. Disable open installation, require an admin-curated Google Workspace Marketplace allowlist, and restrict incoming webhooks—each of which can read, post, and exfiltrate conversation content programmatically.

#### Rationale
**Why This Matters:**
- Chat apps and webhooks run with delegated access to conversations and can silently forward messages or files to external endpoints
- A malicious or over-permissioned Chat app is an OAuth-style data-exfiltration path that bypasses Drive/Gmail controls
- An incoming webhook is authenticated **solely by the secret embedded in its URL** — the documented form is `https://chat.googleapis.com/v1/spaces/SPACE_ID/messages?key=KEY&token=TOKEN`, with no signature verification or separate credential exchange. Anyone who obtains that URL can post into the space as the webhook, which is why a webhook leaked into a repository, a CI log, or a screenshot is a standing phishing channel inside a trusted space rather than a low-severity secret

**Attack Prevented:** Malicious Chat app installation, webhook abuse, data exfiltration via bot integrations

#### Prerequisites
- Inventory of currently used Chat apps and webhooks
- Business justification and owner for each approved app
- Marketplace allowlist workflow (see [Google Workspace OAuth App Allowlisting](/guides/google-workspace/#31-enable-oauth-app-whitelisting))

#### ClickOps Implementation

**Step 1: Restrict Chat App Installation**
1. Navigate to: **Admin Console** → **Apps** → **Google Workspace** → **Google Chat** → **Chat apps**
2. Set **Allow users to install Chat apps** to **Off** (or leave **On** only if paired with a Marketplace allowlist)
3. Set **Allow users to add and use incoming webhooks** to **Off** for the organization (enable only for a dedicated, audited OU if needed)
4. Click **Save**

> **Note:** Chat apps must stay enabled at the **top** organizational unit for the Chat API to function. Use the Marketplace allowlist—not an OU block—to restrict which apps are usable.

> **Two documented ways this control is bypassed — plan for both:**
> 1. **Marketplace overrides the Chat-specific toggle.** If Marketplace app installation is enabled, users can install an allowed app *even without* the Chat-specific install permission. Turning "Allow users to install Chat apps" off is therefore not sufficient on its own — the Marketplace setting is the binding one, which is why Step 2 is not optional.
> 2. **Allowlists do not cover unpublished apps.** A developer can publish an app to a small number of users without going through Marketplace approval, even with allowlisting enabled. That path is invisible to an allowlist review, so pair the allowlist with detection: monitor `app_added` and `app_invoked` in the Chat audit log ([3.1](#31-enable-google-chat-audit-logging--content-reporting)) and reconcile installed apps against the approved list rather than assuming the allowlist enforced itself.

**Step 2: Curate the Marketplace Allowlist**
1. Navigate to: **Admin Console** → **Apps** → **Google Workspace Marketplace apps** → **Apps list**
2. Click **Google Workspace Marketplace allowlist** → **Add app to allowlist**
3. Add only reviewed, business-justified Chat apps
4. Set the Marketplace settings so users can install **allowlisted apps only**

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="google-chat" section="1.1" %}

#### Validation & Testing
1. As a standard user, confirm a non-allowlisted Chat app cannot be installed
2. Confirm incoming webhook creation is blocked outside the approved OU
3. Review **Reporting** → **Audit and investigation** → **Chat log events** for app-related activity

**Expected result:** Only allowlisted Chat apps are usable; webhooks limited to approved users.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | CM-7 | Least functionality |
| **CIS Google Workspace** | 2.1 | Control third-party apps and add-ons |

---

## 2. Data Security

### 2.1 Restrict External Google Chat & Spaces

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3, AC-20 |
| CISA SCuBA | GWS.CHAT.4.1v1 |

#### Description
Restrict Google Chat and spaces with people outside your organization. Either turn external chat off, or—if external collaboration is required—allow it **only for allowlisted (trusted) domains**, and apply the same restriction to externally shared spaces and group direct messages.

#### Rationale
**Why This Matters:**
- Unrestricted external chat is a low-friction data-exfiltration channel that is monitored less rigorously than email
- "Auto-accept chat invites from familiar contacts" can pull users into external conversations without an explicit decision
- External spaces let outside members persist in a shared room with access to its files and history
- The same setting governs external **group direct messages** — a distinct exfiltration channel from spaces, and one that is easy to overlook because it creates no persistent room to audit

**Attack Prevented:** Data exfiltration over Chat, social engineering via external messaging, unauthorized external collaboration

**Real-World Incidents:**
- Messaging apps are an increasingly common exfiltration path (MITRE ATT&CK T1213.005, Data from Information Repositories: Messaging Applications)

#### Prerequisites
- Defined list of trusted external domains
- The shared Workspace **Allowlisted domains** list configured (Account → Domains)

#### ClickOps Implementation

**Step 1: Restrict External Chat**
1. Navigate to: **Admin Console** → **Apps** → **Google Workspace** → **Google Chat** → **External chat settings**
2. For **Allow users to send messages outside your organization** (a.k.a. **Chat externally**):
   - To disable entirely: select **Off**
   - To allow trusted partners only: select **On**, then check **Only allow this for allowlisted domains**
3. Uncheck **Auto-accept chat invites from familiar contacts** (L2+)
4. Click **Save**

**Step 2: Restrict External Spaces and Group Direct Messages**
1. Stay on the same page — **Admin Console** → **Apps** → **Google Workspace** → **Google Chat** → **External chat settings**. There is no separate "External spaces" page; the spaces and group-DM setting lives alongside the external-chat setting.
2. For **Allow users to create & join spaces & group direct messages with people outside their organization**: select **Off**, or **On** restricted to allowlisted domains
3. Click **Save**

> **⚠ This setting is organization-wide and cannot be scoped per organizational unit.** Google's documentation states plainly: "This setting applies to your entire organization." The external *chat* setting in Step 1 **can** be scoped to an OU ("To apply the setting to a department or team, at the side, select an organizational unit") — the spaces and group-DM setting cannot. The practical consequence is that the usual "enable it only for the partner-facing OU" pattern is unavailable here: enabling external spaces for one team enables multi-party external DMs for everyone. Treat it as a whole-tenant decision, and use the allowlisted-domains restriction rather than OU scoping to bound it.

> **Turning it off does not undo what already exists.** Per Google's documentation, disabling external chat "does not delete already created chat messages, conversations, and spaces. They will still be visible and accessible to already invited external users and guests" — your own users lose access, but "their membership status will not change," and re-enabling the setting restores access to everything. Disabling the setting is therefore a control on *new* external collaboration only. Audit and remediate the external spaces and memberships that already exist ([2.6](#26-set-the-default-space-access-to-restricted) Step 3 inventories them), or the exposure survives the fix.

**Step 3: Manage the Allowlisted Domains**
1. The Chat allowlist is the **shared** Workspace trusted-domains allowlist (also used by Drive, Sites, Classroom, Looker Studio)
2. Navigate to: **Account** → **Domains** → **Allowlisted domains** to add/remove trusted domains
3. Scope external-*chat* exceptions per organizational unit where possible; note that the spaces/group-DM setting above admits no such scoping

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="google-chat" section="2.1" %}

#### Validation & Testing
1. As a standard user, attempt to message a non-allowlisted external address—delivery should be blocked
2. Attempt to add a non-allowlisted external user to a space—should fail
3. Attempt to start a group direct message including a non-allowlisted external address—should fail
4. Confirm an allowlisted-domain partner can still chat

**Expected result:** External chat, spaces, and group DMs work only with allowlisted domains (or are fully disabled).

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CISA SCuBA** | GWS.CHAT.4.1v1 | External chat restricted to allowlisted domains |
| **NIST 800-53** | AC-20 | Use of external systems |
| **SOC 2** | CC6.6 | Boundary protection / external access |

> **CIS note (re-checked 2026-08-12):** the CIS Google Workspace Foundations Benchmark does contain Chat recommendations, and a research pass located candidate numbering for external and internal Chat file sharing. Those numbers are still **deliberately not cited here**, for a reason worth stating plainly: the only full benchmark PDFs reachable in that pass came from unofficial third-party mirrors rather than CIS, and the recommendation numbering was shown to shift between benchmark versions. A control ID copied from a mirror is exactly the kind of citation that looks authoritative and is unverifiable, so SCuBA remains the primary mapping. Add CIS Google Workspace numbers only from a PDF downloaded from CIS itself, and pin the benchmark version alongside them.

---

### 2.2 Restrict Google Chat File Sharing

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |
| CISA SCuBA | GWS.CHAT.2.1v1 |

#### Description
Limit which files users can share in Google Chat, separately for internal and external conversations. Per the CISA SCuBA baseline, external file sharing in Chat should be set to **No files**.

#### Rationale
**Why This Matters:**
- File sharing in Chat is a data-loss avenue that is monitored less rigorously than email or Drive
- Disabling external Chat file sharing removes an exfiltration path that DLP alone may not fully cover
- Restricting internal sharing to **Images only** for sensitive OUs reduces accidental document leakage

**Attack Prevented:** Data exfiltration via Chat attachments, malware delivery through shared files

#### Prerequisites
- Decision on internal sharing posture per organizational unit
- DLP for Chat configured for residual risk ([Google Workspace DLP](/guides/google-workspace/#42-enable-data-loss-prevention-dlp))

#### ClickOps Implementation

**Step 1: Configure Chat File Sharing**
1. Navigate to: **Admin Console** → **Apps** → **Google Workspace** → **Google Chat** → **Chat file sharing**
2. Set **External filesharing** to **No files** (SCuBA GWS.CHAT.2.1v1)
3. Set **Internal filesharing** to **Allow all files** or, for sensitive OUs, **Images only**
4. Click **Save**

> **Note:** Files shared in Chat are automatically scanned for viruses before delivery, but malware and DLP scanning do not replace a file-type restriction.

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="google-chat" section="2.2" %}

#### Validation & Testing
1. As a standard user, attempt to attach a file in an external conversation—should be blocked
2. Confirm internal sharing behaves per the configured posture
3. Review **Chat log events** for `attachment_upload` activity

**Expected result:** External Chat file sharing disabled; internal sharing matches policy.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CISA SCuBA** | GWS.CHAT.2.1v1 | External Chat file sharing disabled |
| **NIST 800-53** | AC-3 | Access enforcement |
| **SOC 2** | CC6.6 | Boundary protection |

---

### 2.3 Enforce Google Chat History & Retention

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 8.10 |
| NIST 800-53 | AU-2, AU-9, SC-7(10) |
| CISA SCuBA | GWS.CHAT.1.1v1, GWS.CHAT.1.2v1, GWS.CHAT.3.1v1 |

#### Description
Turn Chat history on by default, prevent users from changing their own history setting, force space history on, and use Google Vault to retain and legally hold Chat content for traceability and eDiscovery.

#### Rationale
**Why This Matters:**
- History off means direct messages are deleted after 24 hours and cannot be retained by Vault—erasing the audit trail
- Allowing users to change their history setting lets them obfuscate sensitive sharing (MITRE ATT&CK T1562.001, Impair Defenses)
- Retention and legal holds preserve Chat evidence for investigations and dispute resolution

**Attack Prevented:** Audit-trail tampering, evidence destruction, insider data hiding

#### Prerequisites
- Information-governance/retention requirements defined
- Google Vault license (Business Plus or Enterprise editions)

#### ClickOps Implementation

**Step 1: Enforce Chat History**
1. Navigate to: **Admin Console** → **Apps** → **Google Workspace** → **Google Chat** → **History for chats**
2. Select **History is ON**
3. Uncheck **Allow users to change their history setting**
4. Click **Save**

**Step 2: Enforce Space History**
1. Navigate to: **Apps** → **Google Workspace** → **Google Chat** → **History for spaces**
2. Select **History is ALWAYS ON**
3. Click **Save**

**Step 3: Configure Vault Retention & Holds**
1. In **Google Vault** → **Retention**, create a Chat retention rule by organizational unit or for all spaces; set retention for DMs, group messages, and space messages
2. In **Vault** → **Matters** → **Holds**, place relevant accounts/OUs on a Chat hold (include spaces the user belongs to)
3. Note: holds never expire and override retention rules; Chat messages are kept 30 days after deletion

> **The one place a Vault hold does not hold.** In **extra-large spaces** (documented at more than 50,000 members), Chat content follows the space retention policy **regardless of holds**. Everywhere else a hold beats retention; here it does not. If a legal hold must cover a conversation, confirm the space is not in that category — an assumption that "the hold covers it" is exactly the assumption that fails at the moment it is tested in an investigation.

**Time to Complete:** ~45 minutes

#### Code Implementation

{% include pack-code.html vendor="google-chat" section="2.3" %}

#### Validation & Testing
1. Confirm a standard user cannot toggle history off in a conversation
2. Verify the Vault retention rule and hold appear and cover the Chat corpus
3. Search Chat in Vault to confirm content is discoverable

**Expected result:** History enforced on; users cannot change it; Chat retained per policy.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CISA SCuBA** | GWS.CHAT.1.1v1 | Chat history enabled |
| **CISA SCuBA** | GWS.CHAT.1.2v1 | Users cannot change history setting |
| **CISA SCuBA** | GWS.CHAT.3.1v1 | Space history enabled |
| **NIST 800-53** | AU-9 | Protection of audit information |
| **ISO 27001** | A.12.4.2 | Protection of log information |

---

### 2.4 Configure Chat Auto-Deletion Retention

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.4 |
| NIST 800-53 | AU-11, SI-12 |

#### Description
Set an explicit auto-deletion period for Chat content per organizational unit, independently for 1:1 direct messages, group direct messages, and space messages. Auto-deletion bounds how long conversational data lingers in Chat — the complement to the retention floor set in [2.3](#23-enforce-google-chat-history--retention).

#### Rationale
**Why This Matters:**
- Chat accumulates unbounded conversational data — credentials pasted into DMs, customer records dropped into spaces — that becomes breach blast radius the longer it is kept
- Data-minimization obligations (GDPR storage limitation, contractual retention caps) require a defensible upper bound, not just a lower one; auto-deletion is the only Chat-native mechanism that provides it
- Auto-deletion applies **only to messages sent while history was ON** — with history off, messages already disappear after 24 hours and this setting is irrelevant, which makes enforcing history ([2.3](#23-enforce-google-chat-history--retention)) a prerequisite for predictable retention

**Attack Prevented:** Excessive data retention increasing breach impact, stale-credential harvesting from old conversations, retention-policy compliance failure

#### Prerequisites
- Chat history enforced ON ([2.3](#23-enforce-google-chat-history--retention)) — auto-deletion has no effect on history-off messages
- A documented retention period per conversation type, agreed with legal/compliance
- A qualifying edition: Frontline Plus, Business Plus, Enterprise Standard/Plus, Education Standard/Plus, or Enterprise Essentials/Plus

#### ClickOps Implementation

**Step 1: Set Auto-Deletion Periods**
1. Navigate to: **Admin Console** → **Apps** → **Google Workspace** → **Google Chat** → **Auto-deletion**
2. Select the organizational unit to configure
3. Set an independent retention period for each of **1:1 direct messages**, **group direct messages**, and **space messages** — any value from **30** to **36,500** days
4. Click **Save**

> **Only 1:1 direct messages support per-OU scoping.** The group-DM and space-message periods are set for the organization, so a stricter retention period for one sensitive team is achievable for their 1:1 DMs only. Where a team genuinely needs tighter retention on spaces, the lever is a separate space with its own Vault retention rule, not this setting.

> **Interaction with Vault:** auto-deletion does not defeat Vault. If auto-deletion fires before a Vault retention rule expires, the message is still held in Vault for the remainder of the Vault retention period, or a minimum of 30 days — whichever is longer. Configure both deliberately rather than assuming one overrides the other.

> **No automation surface (verified 2026-08-12):** this control ships no Code Pack because none can be written honestly. Auto-deletion periods are absent from the eight Chat settings the Policy API exposes, so the setting can be neither enforced nor even *read* programmatically — configure and verify it in the console. Its prerequisite, history enforcement, **is** verifiable ([3.4](#34-continuously-verify-chat-configuration-with-the-policy-api)), so the strongest available proxy is confirming history is on and unmodifiable and reviewing the auto-deletion periods by hand on a schedule.

**Time to Complete:** ~30 minutes

#### Validation & Testing
1. Confirm the configured period appears for each of the three conversation types on the target OU
2. Post a test message in a history-on space, and confirm it is no longer visible in Chat after the retention period elapses
3. Confirm the same message remains discoverable in Vault if it falls under an active retention rule or hold

**Expected result:** Chat content is deleted on a defined schedule per conversation type, while Vault-governed content stays preserved for its own retention window.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AU-11 | Audit record retention |
| **NIST 800-53** | SI-12 | Information management and retention |
| **SOC 2** | CC6.5 | Data disposal |
| **ISO 27001** | A.8.10 | Information deletion |

---

### 2.5 Apply DLP to Google Chat Messages and Attachments

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.13 |
| NIST 800-53 | AC-4, SC-7(10), SI-4 |

#### Description
Create Chat-scoped data protection rules under **Security** → **Access and data control** → **Data protection**, which inspect message text and attachments against content detectors and then block, warn, or audit. This is the only Chat control that inspects content **even when Chat history is off**.

#### Rationale
**Why This Matters:**
- DLP for Chat scans messages **even when history is turned off**, covering 1:1 DMs, group DMs, spaces, and attachments including images — this is the single control that survives the history-off blind spot that simultaneously breaks content reporting ([3.1](#31-enable-google-chat-audit-logging--content-reporting)) and Vault retention ([2.3](#23-enforce-google-chat-history--retention))
- File-type restrictions ([2.2](#22-restrict-google-chat-file-sharing)) stop categories of files but say nothing about what is inside them — a permitted image can carry a screenshot of a customer database
- Warn-mode rules convert an invisible policy into an in-the-moment user prompt, which reduces accidental disclosure without blocking legitimate work

**Attack Prevented:** Sensitive-data exfiltration over Chat, inadvertent disclosure of regulated data in messages or attachments, evasion of message-level monitoring by disabling history

#### Prerequisites
- A qualifying edition: Frontline Standard/Plus, Enterprise Standard/Plus, or Education Fundamentals/Standard/Plus
- Defined sensitive-data categories and the detectors that match them
- Platform DLP context ([Google Workspace DLP](/guides/google-workspace/#42-enable-data-loss-prevention-dlp))

#### ClickOps Implementation

**Step 1: Create a Chat-Scoped Data Protection Rule**
1. Navigate to: **Admin Console** → **Security** → **Access and data control** → **Data protection** → **Manage Rules** → **Add rule**
2. Name the rule and scope it to the target organizational units or groups
3. Under the applications/triggers step, select **Google Chat**, and include message text and attachments in scope
4. Define the conditions using content detectors that match your sensitive-data categories
5. Choose an action: **Block message**, **Warn users**, or **Audit only**
6. Set the alerting level and click **Create**

> **Rule conflicts:** when multiple rules match the same message, the most restrictive action wins — **block** takes precedence over **warn**, and **warn** over **audit only**. Start in **Audit only** to measure false positives, then promote to warn and block.

> **No automation surface (verified 2026-08-12):** data protection rules are not among the Chat settings the Policy API exposes, so this control ships no Code Pack — rules are authored and reviewed in the console. Two facts make manual review tractable: the Chat triggers are identified as `google.workspace.chat.message.v1.send` and `google.workspace.chat.attachment.v1.upload`, and rule *hits* are visible in the security investigation tooling even though the rule *definitions* are not readable by API. Review the rule set on the same cadence as [3.4](#34-continuously-verify-chat-configuration-with-the-policy-api)'s drift check, since a deleted DLP rule leaves no trace in a settings baseline.

**Time to Complete:** ~60 minutes

#### Validation & Testing
1. From a test account in scope, send a message containing synthetic data matching a rule condition — confirm the configured block or warn behavior fires
2. Repeat the test in a conversation with **history turned off** — the rule must still fire, which is the point of this control
3. Attach an image containing matching content and confirm the attachment is inspected
4. Confirm rule hits appear in the security investigation tooling

**Expected result:** Sensitive content is blocked, warned on, or audited in Chat messages and attachments across every conversation type, independent of the history setting.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-4 | Information flow enforcement |
| **NIST 800-53** | SI-4 | System monitoring |
| **SOC 2** | CC6.7 | Restricted data transmission |
| **ISO 27001** | A.8.12 | Data leakage prevention |

---

### 2.6 Set the Default Space Access to Restricted

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3, AC-6 |

#### Description
Set the organization's default space access to **Restricted**, so that a newly created Chat space is joinable only by the people and groups explicitly added to it — rather than defaulting to a target audience that makes the space discoverable and joinable org-wide.

#### Rationale
**Why This Matters:**
- The **Primary Target Audience** default makes every newly created space discoverable and joinable by anyone in that audience, and the shipped default audience is **all users in your domain** — so a space created for a sensitive project is domain-discoverable by default, and private only if its creator remembers to change it
- Space membership grants access to the space's full message history and shared files, so an over-broad default silently widens access to everything ever posted there
- Secure defaults beat user diligence: the creator of a legal, HR, or incident-response space is rarely thinking about discoverability at the moment of creation

**Attack Prevented:** Unauthorized internal access to sensitive discussions, insider browsing of restricted-project spaces, over-broad exposure of files shared in spaces

#### Prerequisites
- Decision on whether any target audience should be offered to space creators at all
- Target audiences defined if used (a maximum of five apply to Chat)

#### ClickOps Implementation

**Step 1: Set the Space Access Default**
1. Navigate to: **Admin Console** → **Apps** → **Google Workspace** → **Google Chat** → **Sharing settings** → **Space access default**
2. Select **Restricted** — only people and groups explicitly added can join the space
3. Click **Save**

**Step 2: Review Target Audiences (if used)**
1. Navigate to: **Admin Console** → **Apps** → **Google Workspace** → **Google Chat** → **Sharing settings** → **Target audiences**
2. Confirm only intentional audiences are listed; up to five apply to Chat, and the audience in the **first position** becomes the recommended default shown to space creators
3. Order the list so the narrowest appropriate audience sits first — never leave a broad organization-wide audience in the first position
4. Click **Save**

> **Note:** this sets the default, not a prohibition. Space creators can still widen access to a target audience; pair the restricted default with the external-chat restrictions in [2.1](#21-restrict-external-google-chat--spaces) to bound how far a space can be widened.

**Step 3: Inventory the Spaces That Already Exist**

1. A default only governs spaces created *after* it is set — it says nothing about the spaces already in the tenant, which is where the accumulated exposure lives
2. Grant the **Manage Chat and Spaces conversation** admin privilege to the account that will run the inventory
3. Use the Chat API's admin space search (`spaces.search` with `useAdminAccess`) to enumerate every named space, then review three populations: spaces with no recent activity, spaces with no remaining manager, and spaces whose membership includes external users
4. Re-run on a schedule — space sprawl is continuous, so a one-off inventory ages out immediately

**Time to Complete:** ~20 minutes (plus inventory review)

#### Code Implementation

{% include pack-code.html vendor="google-chat" section="2.6" %}

#### Validation & Testing
1. As a standard user, create a new space and confirm the access setting defaults to restricted rather than to a target audience
2. From a second account not added to that space, confirm the space is not discoverable in Chat search
3. If target audiences are used, confirm the first-position audience is the intended narrow one
4. Run the admin space search and confirm it returns spaces — an empty result usually means the caller is missing the **Manage Chat and Spaces conversation** privilege rather than that the tenant has no spaces
5. Confirm the Policy API reports `chat.space_access_default` `access_type` as `RESTRICTED` ([3.4](#34-continuously-verify-chat-configuration-with-the-policy-api))

**Expected result:** New spaces are private by default and joinable only by explicitly added members, and the existing space estate has been inventoried rather than assumed.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | AC-6 | Least privilege |
| **SOC 2** | CC6.1 | Logical access security |
| **ISO 27001** | A.5.15 | Access control |

---

### 2.7 Govern Third-Party Chat Archiving

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-4, AU-9, SI-4 |

#### Description
Establish whether Chat's third-party archiving is enabled and, if it is, that its destination is an address your organization actually approved. The setting delivers Chat content to an external email address on a recurring schedule (documented as every 1–24 hours), and it is exposed for reading through the Policy API as `chat.third_party_archiving`.

#### Rationale
**Why This Matters:**

- This is a platform-sanctioned channel that continuously ships Chat content out of the tenant — configured deliberately it is a compliance archive, configured carelessly it is a permanent exfiltration path that no DLP rule inspects, because Google itself is doing the sending
- The destination is a plain email address, so a single mistyped or maliciously altered value redirects the organization's conversations without breaking anything a user would notice
- Archiving destinations outlive the vendor relationships that justified them: an address belonging to a decommissioned archiving provider keeps receiving content until someone thinks to look

**Attack Prevented:** Sanctioned-channel data exfiltration, persistence of Chat content delivery to a decommissioned or attacker-controlled destination, silent redirection of an organization's conversation archive

#### Prerequisites

- A documented decision on whether third-party archiving is used at all, and the approved destination address if it is
- Policy API access for verification ([3.4](#34-continuously-verify-chat-configuration-with-the-policy-api))

#### ClickOps Implementation

**Step 1: Determine the Current State**

1. Navigate to: **Admin Console** → **Apps** → **Google Workspace** → **Google Chat**
2. Locate the third-party archiving configuration and record whether it is enabled, its destination email address, and its archival frequency

**Step 2: Decide and Document**

1. If archiving is not required, confirm it is disabled
2. If it is required, record the approved destination address and frequency in your data-flow documentation, and treat that address as a reviewed egress destination rather than an implementation detail
3. Re-confirm the destination whenever the archiving vendor relationship changes

#### Code Implementation

{% include pack-code.html vendor="google-chat" section="2.7" %}

#### Validation & Testing
1. Read `chat.third_party_archiving` through the Policy API and confirm `enabled` matches your documented decision
2. If enabled, confirm `destination_email_address` exactly equals the approved address — the check is string equality against a recorded value, not a judgement call
3. Confirm the configured `archival_frequency` matches what your retention documentation claims

**Expected result:** Third-party archiving is either off, or on with a destination that matches an approved, documented address.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-4 | Information flow enforcement |
| **NIST 800-53** | AU-9 | Protection of audit information |
| **SOC 2** | CC6.7 | Restricted data transmission |
| **ISO 27001** | A.8.12 | Data leakage prevention |

---

## 3. Monitoring & Detection

### 3.1 Enable Google Chat Audit Logging & Content Reporting

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 8.5 |
| NIST 800-53 | AU-2, AU-6, IR-6 |
| CISA SCuBA | GWS.CHAT.5.1v1, GWS.CHAT.5.2v1 |

#### Description
Monitor Google Chat through the Chat log events report (and Reports API / BigQuery export), and — on editions that support it — enable content reporting so users can flag malicious or inappropriate messages to admins across every conversation type the feature covers.

#### Rationale
**Why This Matters:**
- Chat is a phishing and malware-delivery channel; content reporting turns every user into a detection sensor (NIST IR-6)
- Chat audit events (`message_posted`, `attachment_upload`, `room_created`, `add_room_member`) reveal exfiltration and rogue-space activity
- Reporting requires Chat history to be enabled ([2.3](#23-enforce-google-chat-history--retention))

**Attack Prevented:** Undetected Chat phishing/malware, unmonitored data exfiltration, delayed incident response

#### Prerequisites
- Chat history enabled ([2.3](#23-enforce-google-chat-history--retention))
- Audit & Investigation admin privilege; BigQuery export for long-term retention ([Google Workspace Audit Logging](/guides/google-workspace/#51-enable-audit-logging-and-investigation-tool))
- **Content reporting is not available on every edition.** It requires **Frontline Plus**, **Enterprise Plus**, or **Education Standard/Plus**. Chat log events and the BigQuery export in Step 1 are independent of this and remain available more broadly — organizations without a qualifying edition should implement Step 1 and rely on [3.2 Chat content protection](#32-understand-chat-content-protection-coverage-limits) and [2.5 DLP for Chat](#25-apply-dlp-to-google-chat-messages-and-attachments) for detection coverage
- A designated owner for the report queue ([3.3](#33-delegate-a-scoped-chat-moderator-role))

> **Documented blind spots:** users **cannot** report messages in (a) conversations with history turned off, (b) 1:1 direct messages with external users, or (c) spaces owned by an external organization. These gaps are by design and are not closed by selecting every conversation-type checkbox — cover them with [DLP for Chat](#25-apply-dlp-to-google-chat-messages-and-attachments), which scans even when history is off, and by enforcing history on ([2.3](#23-enforce-google-chat-history--retention)).

#### ClickOps Implementation

**Step 1: Review Chat Log Events**
1. Navigate to: **Admin Console** → **Reporting** → **Audit and investigation** → **Chat log events**
2. Filter by **Event** (e.g., `attachment_upload`, `room_created`) and date range
3. For advanced triage (Enterprise Standard/Plus): **Security** → **Security center** → **Investigation tool**, data source **Chat log events**

**Step 2: Enable Content Reporting**
1. Navigate to: **Apps** → **Google Workspace** → **Google Chat** → **Content reporting**
2. Enable **Allow users to report content in Chat**
3. Select **all conversation type** checkboxes (1:1, group, spaces) — SCuBA GWS.CHAT.5.1v1
4. Select **all** reporting categories — SCuBA GWS.CHAT.5.2v1
5. Click **Save**

**Time to Complete:** ~30 minutes

#### Key Chat Events to Monitor

Event names below are transcribed from the Admin SDK Reports API Chat activity-events appendix. Two parameters are worth knowing because they carry the internal/external distinction the event name alone does not: `conversation_ownership` (`INTERNALLY_OWNED` / `EXTERNALLY_OWNED`) and `conversation_type` (which includes `GROUP_DIRECT_MESSAGE`).

| Event | Detection Use Case |
|-------|-------------------|
| `attachment_upload` | Data exfiltration into Chat |
| `attachment_download` | Data exfiltration **out of** Chat — a compromised account harvesting an existing space downloads without ever uploading |
| `message_posted` | Phishing / malicious link distribution |
| `message_deleted` | Evidence destruction after exfiltration or misconduct |
| `message_edited` | Retroactive alteration of preserved content |
| `room_created` | Rogue or external space creation |
| `room_deleted` | Cascading destruction of a space, its messages, and its memberships |
| `add_room_member` | Users added to spaces in bulk |
| `remove_room_member` | Witnesses removed from a conversation before it continues |
| `direct_message_started` | External DM initiation (check `conversation_ownership`) |
| `app_added` / `app_removed` | Chat app installation outside the approved allowlist workflow ([1.1](#11-restrict--allowlist-google-chat-apps)) |
| `app_invoked` | Chat app driven programmatically far beyond its business purpose |
| `message_reported` / `message_report_resolved` | Content-reporting queue throughput — raised versus resolved is how you prove the queue in [3.3](#33-delegate-a-scoped-chat-moderator-role) is actually worked |

#### Code Implementation

{% include pack-code.html vendor="google-chat" section="3.1" %}

#### Validation & Testing
1. As a user, confirm the **Report** option appears on messages in each enabled conversation type (expect it to be absent in history-off conversations, external 1:1 DMs, and externally owned spaces — those are documented gaps, not misconfiguration)
2. Submit a test report and confirm it surfaces in the Moderation Tool for the assigned moderator ([3.3](#33-delegate-a-scoped-chat-moderator-role))
3. Run the Reports API / GAM query and confirm Chat events return

**Expected result:** Chat events are auditable; users can report content in every conversation type the feature covers, and each report reaches a named owner.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CISA SCuBA** | GWS.CHAT.5.1v1 | Content reporting enabled for all conversation types |
| **CISA SCuBA** | GWS.CHAT.5.2v1 | All reporting categories selected |
| **NIST 800-53** | IR-6 | Incident reporting |
| **SOC 2** | CC7.2 | System monitoring |

---

### 3.2 Understand Chat Content Protection Coverage Limits

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.1, 13.1 |
| NIST 800-53 | SI-3, SI-8 |

#### Description
Confirm Chat content protection is on for external chat, and document what it does **not** cover: Google scans messages exchanged with **external** users for spam, phishing, and malware, and virus-scans files for all users — but internal-only conversations are not scanned for spam or phishing. Treat that gap as a deliberate detection boundary to be covered by other controls.

#### Rationale
**Why This Matters:**
- Content protection is on by default for external chat, which makes it easy to assume Chat is uniformly scanned — it is not, and an internal-only phishing or lateral-movement message passes through unscanned
- Compromised internal accounts are exactly the case where internal-only messaging is used to move laterally, so the unscanned surface is the one an attacker who already has a foothold will use
- File virus-scanning does apply to all users, so the residual internal gap is specifically spam/phishing content — that is what [DLP for Chat](#25-apply-dlp-to-google-chat-messages-and-attachments) and [content reporting](#31-enable-google-chat-audit-logging--content-reporting) exist to cover

**Attack Prevented:** Internal phishing and lateral movement via Chat, misplaced reliance on automatic scanning, malware delivery through Chat attachments

#### Prerequisites
- External chat posture decided ([2.1](#21-restrict-external-google-chat--spaces))
- Compensating coverage in place for internal conversations: [2.5](#25-apply-dlp-to-google-chat-messages-and-attachments) and [3.1](#31-enable-google-chat-audit-logging--content-reporting)

#### ClickOps Implementation

**Step 1: Confirm Chat Content Protection**
1. Navigate to: **Admin Console** → **Apps** → **Google Workspace** → **Google Chat** → **Security & moderation** → **Chat content protection**
2. Confirm protection is enabled for chats with external users (on by default)
3. Click **Save** if any change was made

**Step 2: Close the Internal Gap**
1. Record in your detection coverage documentation that internal-only Chat conversations are **not** scanned for spam or phishing
2. Ensure a DLP for Chat rule ([2.5](#25-apply-dlp-to-google-chat-messages-and-attachments)) covers internal conversations for the sensitive-data categories that matter
3. Ensure content reporting ([3.1](#31-enable-google-chat-audit-logging--content-reporting)) is enabled for internal 1:1, group, and space conversations so users can flag what automation does not catch

> **No automation surface (verified 2026-08-12):** Chat content protection is not among the eight Chat settings the Policy API exposes, so its state cannot be read programmatically and this control ships no Code Pack. That makes the documentation step above the actual deliverable — the control's value is a written, reviewed coverage boundary, not a toggle.

**Time to Complete:** ~20 minutes

#### Validation & Testing
1. Confirm the content protection setting is enabled for external chat
2. Send a benign test file internally and confirm it is virus-scanned before delivery
3. Confirm your detection coverage matrix explicitly names internal-only spam/phishing as covered by DLP and user reporting rather than by Google's scanning

**Expected result:** External Chat is scanned by Google; the internal gap is documented and covered by DLP plus user reporting rather than assumed away.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SI-3 | Malicious code protection |
| **NIST 800-53** | SI-8 | Spam protection |
| **SOC 2** | CC7.1 | Detection of anomalies |
| **ISO 27001** | A.8.7 | Protection against malware |

---

### 3.3 Delegate a Scoped Chat Moderator Role

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 17.4 |
| NIST 800-53 | AC-6(5), IR-4, IR-6 |

#### Description
Create a custom admin role carrying the **Moderate Chat content report** privilege and assign it to the people who will triage reported Chat content in the Workspace Moderation Tool — so reports have a named owner without granting super admin.

#### Rationale
**Why This Matters:**
- Enabling content reporting ([3.1](#31-enable-google-chat-audit-logging--content-reporting)) creates a queue; a queue nobody owns is a detection control that produces no detections, which is the same unmonitored-queue failure that quarantines exhibit in the [Gmail guide](/guides/gmail/)
- Without a scoped role, the only way to triage reports is to hand out super admin, which trades a moderation need for full tenant control — a permanent privilege escalation to solve a temporary workflow problem
- A named moderator establishes a measurable response time for user-reported phishing, which is what turns reporting into an incident-response input (NIST IR-4)

**Attack Prevented:** Unactioned phishing reports, privilege over-provisioning to enable moderation, delayed incident response to user-reported Chat threats

#### Prerequisites
- Content reporting enabled and on a qualifying edition ([3.1](#31-enable-google-chat-audit-logging--content-reporting))
- Named individuals or a security/IT group to own report triage
- A documented triage SLA and escalation path

#### ClickOps Implementation

**Step 1: Create the Custom Role**
1. Navigate to: **Admin Console** → **Account** → **Admin roles** → **Create new role**
2. Name it (for example, `Chat Content Moderator`) and add a description naming the triage owner and SLA
3. In the privileges list, select **Moderate Chat content report** — and nothing else
4. Click **Create role**

**Step 2: Assign the Role**
1. Open the new role → **Admins** → **Assign users**
2. Assign only the individuals responsible for triage
3. Click **Assign role**

**Step 3: Operate the Queue**
1. Direct assigned moderators to the Workspace **Moderation Tool** to review reported Chat content
2. Review the queue on the cadence set by your SLA and record dispositions
3. Re-review role assignments whenever team membership changes

**Time to Complete:** ~30 minutes

#### Code Implementation

Unlike most controls in this guide, this one is fully automatable in both directions: the Admin SDK Directory API can create the custom role, assign it, and audit it. Discover the privilege identifier from your own tenant rather than hardcoding one — the pack's first step prints the Chat-related privileges with their `serviceId`.

{% include pack-code.html vendor="google-chat" section="3.3" %}

#### Validation & Testing
1. Confirm the custom role lists **Moderate Chat content report** and no additional privileges
2. As an assigned moderator, open the Moderation Tool and confirm reported content is visible and actionable
3. As a non-assigned user, confirm the Moderation Tool is inaccessible
4. Submit a test report from [3.1](#31-enable-google-chat-audit-logging--content-reporting) and confirm it reaches the queue and is dispositioned within the SLA
5. Measure the queue rather than trusting it: compare `message_reported` against `message_report_resolved` counts over the review window ([3.1](#31-enable-google-chat-audit-logging--content-reporting) Code Pack) — a rising unresolved backlog means the role exists but the SLA does not

**Expected result:** Reported Chat content is triaged by a named owner holding one narrowly scoped privilege, not by a super admin, and the resolution rate is measurable rather than assumed.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-6(5) | Privileged accounts |
| **NIST 800-53** | IR-4 | Incident handling |
| **SOC 2** | CC7.3 | Evaluation of security events |
| **ISO 27001** | A.5.25 | Assessment and decision on information security events |

---

### 3.4 Continuously Verify Chat Configuration with the Policy API

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.2, 8.5 |
| NIST 800-53 | CM-2, CM-3, CM-6, SI-4 |

#### Description
Read every Chat setting the **Cloud Identity Policy API** exposes and compare it against this guide's baseline on a schedule, so configuration drift is detected rather than discovered during an incident. The API covers eight Chat settings — `chat.chat_apps_access`, `chat.external_chat_restriction`, `chat.external_spaces`, `chat.chat_file_sharing`, `chat.chat_history`, `chat.space_history`, `chat.space_access_default`, and `chat.third_party_archiving` — and is **read-only** for all of them.

#### Rationale
**Why This Matters:**

- Every other Chat control in this guide is configured by hand in a console, which means every one of them can be changed by hand in a console — usually for a good short-term reason ("open external chat for the migration") that nobody remembers to close
- Reading the settings in code turns the SCuBA baselines from a point-in-time audit answer into a continuously testable assertion: `history_on_by_default`, `allow_user_modification`, `external_file_sharing`, and `external_chat_restriction` map directly onto GWS.CHAT.1.1v1, 1.2v1, 2.1v1, and 4.1v1
- Drift detection is the only control here that catches the *removal* of another control, which is exactly what an attacker with admin access does before acting

**Attack Prevented:** Silent weakening of Chat security settings by an admin or a compromised admin account, undetected configuration drift between audits, unnoticed expiry of a temporary exception

#### Prerequisites

- **Super administrator** — the Policy API is restricted to super admins
- A service account with domain-wide delegation, granted `https://www.googleapis.com/auth/cloud-identity.policies.readonly`
- A recorded baseline of intended values per organizational unit

> **Read-only, by design.** Every Chat setting reports `Mutate supported: No`. This control proves and monitors configuration; it cannot set it. Treat a finding as a ticket against the ClickOps control that owns the setting, not as something the script can remediate.

#### ClickOps Implementation

**Step 1: Authorize the Caller**

1. Create (or reuse) a service account and enable domain-wide delegation for it
2. Navigate to: **Admin Console** → **Security** → **Access and data control** → **API controls** → **Domain-wide delegation** → **Add new**
3. Add the service account's client ID with the scope `https://www.googleapis.com/auth/cloud-identity.policies.readonly`
4. Have it impersonate a **super administrator** — lesser admin roles cannot read policies

**Step 2: Schedule the Comparison**

1. Run the posture check against your recorded baseline on a schedule (daily is proportionate; the settings change rarely and drift matters immediately)
2. Route findings to the same queue that owns the underlying control, and treat an unexplained change as an access-review trigger for whoever made it

**Time to Complete:** ~45 minutes

#### Code Implementation

{% include pack-code.html vendor="google-chat" section="3.4" %}

#### Validation & Testing
1. Run the posture check against a known-good tenant and confirm it reports no findings
2. Deliberately change one non-production setting (for example, set internal file sharing to a different value on a test OU) and confirm the next run flags exactly that setting and organizational unit
3. Confirm a non-super-admin caller is rejected — if a lesser role appears to work, verify what it actually returned rather than assuming coverage
4. Enumerate all returned policies after a Workspace release and confirm no new `chat.*` setting has appeared that your baseline does not model

**Expected result:** Every Chat setting the Policy API exposes is compared to a recorded baseline on a schedule, and any deviation produces a finding naming the setting, the value, and the organizational unit.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | CM-2 | Baseline configuration |
| **NIST 800-53** | CM-3 | Configuration change control |
| **NIST 800-53** | SI-4 | System monitoring |
| **SOC 2** | CC7.1 | Detection of configuration changes |
| **ISO 27001** | A.8.9 | Configuration management |

---

## 4. Compliance Quick Reference

### CISA SCuBA Google Chat Baseline Mapping

| SCuBA Baseline | Control | This Guide |
|----------------|---------|------------|
| GWS.CHAT.1.1v1 | Chat history enabled | [2.3](#23-enforce-google-chat-history--retention) |
| GWS.CHAT.1.2v1 | Users cannot change history setting | [2.3](#23-enforce-google-chat-history--retention) |
| GWS.CHAT.2.1v1 | External Chat file sharing disabled | [2.2](#22-restrict-google-chat-file-sharing) |
| GWS.CHAT.3.1v1 | Space history enabled | [2.3](#23-enforce-google-chat-history--retention) |
| GWS.CHAT.4.1v1 | External chat restricted to allowlisted domains | [2.1](#21-restrict-external-google-chat--spaces) |
| GWS.CHAT.5.1v1 | Content reporting enabled for all conversation types | [3.1](#31-enable-google-chat-audit-logging--content-reporting) |
| GWS.CHAT.5.2v1 | All reporting categories selected | [3.1](#31-enable-google-chat-audit-logging--content-reporting) |

**Machine-checking these baselines.** Five of the seven map onto Policy API fields, so they can be asserted continuously rather than sampled at audit time ([3.4](#34-continuously-verify-chat-configuration-with-the-policy-api)):

| SCuBA Baseline | Policy API field to assert |
|----------------|----------------------------|
| GWS.CHAT.1.1v1 | `chat.chat_history` → `history_on_by_default` = `true` |
| GWS.CHAT.1.2v1 | `chat.chat_history` → `allow_user_modification` = `false` |
| GWS.CHAT.2.1v1 | `chat.chat_file_sharing` → `external_file_sharing` = `NO_FILES` |
| GWS.CHAT.3.1v1 | `chat.space_history` → `history_state` = `HISTORY_ALWAYS_ON` |
| GWS.CHAT.4.1v1 | `chat.external_chat_restriction` → `external_chat_restriction` = `TRUSTED_DOMAINS` (or `allow_external_chat` = `false`) |
| GWS.CHAT.5.1v1 / 5.2v1 | No Policy API field — content-reporting configuration is verified in the console |

### SOC 2 / NIST 800-53 Summary

| Control | SOC 2 | NIST 800-53 |
|---------|-------|-------------|
| [1.1](#11-restrict--allowlist-google-chat-apps) Chat apps | CC6.1 | CM-7 |
| [2.1](#21-restrict-external-google-chat--spaces) External chat | CC6.6 | AC-20 |
| [2.2](#22-restrict-google-chat-file-sharing) File sharing | CC6.6 | AC-3 |
| [2.3](#23-enforce-google-chat-history--retention) History & retention | CC7.2 | AU-9 |
| [2.4](#24-configure-chat-auto-deletion-retention) Auto-deletion retention | CC6.5 | AU-11, SI-12 |
| [2.5](#25-apply-dlp-to-google-chat-messages-and-attachments) DLP for Chat | CC6.7 | AC-4, SI-4 |
| [2.6](#26-set-the-default-space-access-to-restricted) Space access default | CC6.1 | AC-3, AC-6 |
| [2.7](#27-govern-third-party-chat-archiving) Third-party archiving | CC6.7 | AC-4, AU-9 |
| [3.1](#31-enable-google-chat-audit-logging--content-reporting) Audit & reporting | CC7.2 | AU-6, IR-6 |
| [3.2](#32-understand-chat-content-protection-coverage-limits) Content protection coverage | CC7.1 | SI-3, SI-8 |
| [3.3](#33-delegate-a-scoped-chat-moderator-role) Scoped moderator role | CC7.3 | AC-6(5), IR-4 |
| [3.4](#34-continuously-verify-chat-configuration-with-the-policy-api) Policy API drift detection | CC7.1 | CM-2, CM-3, SI-4 |

> Platform-wide compliance mappings (authentication, OAuth, DLP, admin audit logging) are in the [Google Workspace guide](/guides/google-workspace/#7-compliance-quick-reference).

---

## References

- [Control external chat and spaces options](https://knowledge.workspace.google.com/admin/chat/control-external-chat-and-spaces-chat-options) — Google Workspace Admin Help
- [Prevent data leaks from Chat messages and attachments (DLP for Chat)](https://knowledge.workspace.google.com/admin/security/prevent-data-leaks-from-chat-messages-and-attachments) — Google Workspace Admin Help
- [Set up content moderation for Chat](https://knowledge.workspace.google.com/admin/chat/set-up-content-moderation-for-chat) — Google Workspace Admin Help
- [Automatically delete Chat messages for your organization](https://knowledge.workspace.google.com/admin/chat/automatically-delete-chat-messages-for-your-organization) — Google Workspace Admin Help
- [Set up space access for Chat](https://knowledge.workspace.google.com/admin/chat/set-up-space-access-for-chat) — Google Workspace Admin Help
- [Chat content protection](https://knowledge.workspace.google.com/admin/chat/chat-content-protection) — Google Workspace Admin Help
- [Security checklist for medium and large businesses](https://knowledge.workspace.google.com/admin/security/security-checklist-for-medium-and-large-businesses-100-users) — Google Workspace Admin Help
- [CIS Google Workspace Foundations Benchmark](https://www.cisecurity.org/benchmark/google_workspace) — Center for Internet Security

**Automation interfaces (verified 2026-08-12):**

- [Settings available in the Policy API](https://cloud.google.com/identity/docs/concepts/supported-policy-api-settings) — the authoritative list of the eight readable `chat.*` settings and their exact fields and enum values
- [Listing and getting policies](https://cloud.google.com/identity/docs/how-to/list-get-policies) — `cloudidentity.googleapis.com/v1/policies`, filter syntax `setting.type.matches("chat.*")`, scope `cloud-identity.policies.readonly`
- [Chat activity events (Admin SDK Reports API)](https://developers.google.com/workspace/admin/reports/v1/appendix/activity/chat) — every Chat event name and its parameters
- [Search for and manage spaces as an administrator](https://developers.google.com/workspace/chat/search-manage-admin) — `spaces.search` with `useAdminAccess`, admin scopes, and query syntax
- [Directory API — roles.insert](https://developers.google.com/workspace/admin/directory/reference/rest/v1/roles/insert) — custom admin role creation for the scoped moderator role
- [Set up service log exports to BigQuery](https://knowledge.workspace.google.com/admin/reports/set-up-service-log-exports-to-bigquery) — export setup and the Pacific-Time partition boundary
- [Example queries for reporting logs in BigQuery](https://knowledge.workspace.google.com/admin/reports/example-queries-for-reporting-logs-in-bigquery) — the `activity` table shape these Code Packs query
- [Google Workspace CLI (`gws`)](https://github.com/googleworkspace/cli) — Google-published, and explicitly "not an officially supported Google product"
- [Terraform provider for Google Workspace](https://github.com/hashicorp/terraform-provider-googleworkspace) — **archived 2025-06-30, read-only**; it has never offered a Chat-specific resource

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-12 | 0.3.0 | ai-drafted | **Corrections:** 2.1 previously advised scoping the external spaces / group-DM setting per organizational unit — Google documents that setting as organization-wide with no OU override, so the advice was unachievable as written and is now corrected, with the OU-scopable external-*chat* setting distinguished from it. Also documented that disabling external chat does not remove existing external conversations or space memberships (they persist and are restored if the setting is re-enabled), which makes the disable a control on new collaboration only. Added the two documented bypasses of 1.1 (Marketplace installation overrides the Chat-specific toggle; unpublished apps can reach a small user set without Marketplace approval despite an allowlist), the extra-large-space exception where Chat content follows space retention *regardless of Vault holds*, and the fact that only 1:1 DMs support per-OU auto-deletion scoping. Sharpened 2.6 with the shipped default target audience (all users in the domain) and 1.1 with the incoming-webhook URL-secret authentication model. Re-checked the CIS Google Workspace citation question and re-affirmed the deliberate omission with its reason (candidate numbering was reachable only via unofficial mirrors and shifts between benchmark versions). SCuBA policy IDs re-verified against ScubaGoggles: unchanged, all seven still current. **Automation-surface currency pass.** **Cloud Identity Policy API** established as a readable interface for eight Chat settings, which reverses this guide's previous "Chat settings have no API" posture: added 3.4 (continuous drift detection) and verification Code Packs on 1.1, 2.1, 2.2, 2.3, and 2.6, each stating plainly that the API is read-only (`Mutate supported: No`). Added 2.7 (govern third-party Chat archiving) — a content-egress setting the guide had never covered. Extended 2.6 with org-wide space inventory via the Chat API's admin `spaces.search`. Added Code Packs to 3.3 (Directory API custom-role creation, assignment, and privilege-creep audit). Rewrote 3.1's Code Packs onto the first-party Reports API, moved the CLI variant to Google's `gws` CLI and off community-maintained GAM, and expanded the events table from 4 to 13 entries against the Reports API appendix — adding `attachment_download`, `message_deleted`/`message_edited`, `room_deleted`, `remove_room_member`, `direct_message_started`, the `app_*` family, and the `message_reported`/`message_report_resolved` pair that makes moderation-queue throughput measurable. Fleshed out the BigQuery detection layer from one file to three (Chat app abuse at 1.1, evidence tampering at 2.3, exfiltration and queue health at 3.1). Annotated 2.4, 2.5, and 3.2 as genuinely ClickOps-only with the reason, rather than leaving them silently pack-less. Disclosed that the `hashicorp/googleworkspace` Terraform provider was archived 2025-06-30. Corrected seven stale pre-platform-split control references in the Code Packs. | Claude Code (Opus 5) † |
| 2026-08-08 | 0.2.1 | ai-drafted | Rewrote §3.1 BigQuery detection pack against the documented Workspace activity schema — completed coverage of the control's event table by adding `message_posted` volume (with distinct source-IP count) and bulk `add_room_member` detections alongside the existing `attachment_upload` and `room_created` queries; all columns verified against Google's BigQuery export example-queries documentation. | How to Harden Community |
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass against Google Workspace admin docs and CISA SCuBA: corrected 3.1 content-reporting edition prerequisites and documented its history-off/external-DM/external-space blind spots; corrected 2.1's console path and label to the single External chat settings page covering spaces *and* group DMs, and dropped the unverifiable CIS Google Workspace citation; added 2.4 auto-deletion retention, 2.5 DLP for Chat, 2.6 restricted space access default, 3.2 Chat content protection coverage limits, and 3.3 scoped Chat moderator role. Rebuilt the BigQuery detection pack against the real Workspace activity-export schema (`activity` table, flat `email` column, `TIMESTAMP_MICROS(time_usec)` window). | Claude Code (Opus 4.8) † |
| 2026-05-29 | 0.1.0 | ai-drafted | Initial Google Chat product guide — split from the Google Workspace guide (controls 1.1 app allowlisting, 2.1 external chat, 2.2 file sharing, 2.3 history & retention, 3.1 audit & content reporting). Part of the multi-product platform restructure. | Jai (PAI) |

> † Author **inferred**, not recorded. This row predates the Author column, so the value comes from the authoring session's commit window (every other guide authored in that window names the same tool and model, with no dissenting entry). Undaggered rows are attributed from a sibling guide that recorded its author explicitly in the same commit, or from the row's own text.


## Contributing

Found an issue or have an improvement? See the [Google Workspace platform guide](/guides/google-workspace/) for platform-wide controls, or open an issue/PR on [GitHub](https://github.com/grcengineering/how-to-harden).
