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
description: "Security hardening for Google Chat — app & webhook controls, external chat & spaces, file sharing, history, retention & auto-deletion, DLP for Chat, space access defaults, and audit logging, content protection & moderation."
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

Google Chat is the messaging surface of Google Workspace, and an increasingly common path for data exfiltration, phishing, and malware delivery that is monitored less rigorously than email. This guide hardens Chat-specific surfaces: which apps and webhooks can run inside conversations, whether users can chat or share spaces externally, file-sharing posture, history/retention for traceability, and the audit + content-reporting controls that turn Chat into a detection sensor.

This is a **product guide within the [Google Workspace platform](/guides/google-workspace/)**. Platform-wide controls (authentication, OAuth app allowlisting, DLP engine, admin audit logging) live in the Google Workspace **Common Controls** hub and are referenced here rather than duplicated.

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
This guide covers Google Chat hardening in the Google Workspace Admin Console: Chat app & webhook installation controls, external chat/spaces/group-DM restrictions, Chat file-sharing posture, history plus Vault-based retention and auto-deletion, Chat-scoped DLP rules, space access defaults, and Chat audit logging, content protection, and moderation. Platform-wide authentication, OAuth allowlisting, the DLP engine itself, and admin-console audit logging are covered in the [Google Workspace guide](/guides/google-workspace/). Gmail and Drive are covered in their own product guides.

---

## Table of Contents

1. [App & Integration Security](#1-app--integration-security)
2. [Data Security](#2-data-security)
3. [Monitoring & Detection](#3-monitoring--detection)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

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
- Incoming webhooks post to spaces using a URL that, if leaked, lets anyone inject messages (phishing, social engineering)

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

> **Note:** Because one setting covers both external spaces *and* external group DMs, turning it on to enable partner spaces simultaneously opens multi-party external DMs. Scope it per organizational unit rather than org-wide.

**Step 3: Manage the Allowlisted Domains**
1. The Chat allowlist is the **shared** Workspace trusted-domains allowlist (also used by Drive, Sites, Classroom, Looker Studio)
2. Navigate to: **Account** → **Domains** → **Allowlisted domains** to add/remove trusted domains
3. Apply external-chat exceptions per organizational unit, not org-wide

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

> **CIS note:** a CIS Google Workspace Foundations Benchmark exists, but its Chat section numbering could not be verified against the benchmark PDF at authoring time — SCuBA is used as the primary mapping. Do not add specific CIS Google Workspace control numbers without confirming them against the downloaded benchmark.

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

> **Interaction with Vault:** auto-deletion does not defeat Vault. If auto-deletion fires before a Vault retention rule expires, the message is still held in Vault for the remainder of the Vault retention period, or a minimum of 30 days — whichever is longer. Configure both deliberately rather than assuming one overrides the other.

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
- The **Primary Target Audience** default makes every newly created space discoverable and joinable by anyone in that audience — typically the whole organization — so a space created for a sensitive project is open by default and private only if its creator remembers to change it
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

**Time to Complete:** ~20 minutes

#### Validation & Testing
1. As a standard user, create a new space and confirm the access setting defaults to restricted rather than to a target audience
2. From a second account not added to that space, confirm the space is not discoverable in Chat search
3. If target audiences are used, confirm the first-position audience is the intended narrow one

**Expected result:** New spaces are private by default and joinable only by explicitly added members.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | AC-6 | Least privilege |
| **SOC 2** | CC6.1 | Logical access security |
| **ISO 27001** | A.5.15 | Access control |

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

| Event | Detection Use Case |
|-------|-------------------|
| `attachment_upload` | Data exfiltration via Chat attachments |
| `message_posted` | Phishing / malicious link distribution |
| `room_created` | Rogue or external space creation |
| `add_room_member` | External users added to spaces |

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

#### Validation & Testing
1. Confirm the custom role lists **Moderate Chat content report** and no additional privileges
2. As an assigned moderator, open the Moderation Tool and confirm reported content is visible and actionable
3. As a non-assigned user, confirm the Moderation Tool is inaccessible
4. Submit a test report from [3.1](#31-enable-google-chat-audit-logging--content-reporting) and confirm it reaches the queue and is dispositioned within the SLA

**Expected result:** Reported Chat content is triaged by a named owner holding one narrowly scoped privilege, not by a super admin.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-6(5) | Privileged accounts |
| **NIST 800-53** | IR-4 | Incident handling |
| **SOC 2** | CC7.3 | Evaluation of security events |
| **ISO 27001** | A.5.25 | Assessment and decision on information security events |

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
| [3.1](#31-enable-google-chat-audit-logging--content-reporting) Audit & reporting | CC7.2 | AU-6, IR-6 |
| [3.2](#32-understand-chat-content-protection-coverage-limits) Content protection coverage | CC7.1 | SI-3, SI-8 |
| [3.3](#33-delegate-a-scoped-chat-moderator-role) Scoped moderator role | CC7.3 | AC-6(5), IR-4 |

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

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.2.0 | 2026-08-08 | Currency pass against Google Workspace admin docs and CISA SCuBA: corrected 3.1 content-reporting edition prerequisites and documented its history-off/external-DM/external-space blind spots; corrected 2.1's console path and label to the single External chat settings page covering spaces *and* group DMs, and dropped the unverifiable CIS Google Workspace citation; added 2.4 auto-deletion retention, 2.5 DLP for Chat, 2.6 restricted space access default, 3.2 Chat content protection coverage limits, and 3.3 scoped Chat moderator role. Rebuilt the BigQuery detection pack against the real Workspace activity-export schema (`activity` table, flat `email` column, `TIMESTAMP_MICROS(time_usec)` window). |
| 0.1.0 | 2026-05-29 | Initial Google Chat product guide — split from the Google Workspace guide (controls 1.1 app allowlisting, 2.1 external chat, 2.2 file sharing, 2.3 history & retention, 3.1 audit & content reporting). Part of the multi-product platform restructure. |

## Contributing

Found an issue or have an improvement? See the [Google Workspace platform guide](/guides/google-workspace/) for platform-wide controls, or open an issue/PR on [GitHub](https://github.com/grcengineering/how-to-harden).
