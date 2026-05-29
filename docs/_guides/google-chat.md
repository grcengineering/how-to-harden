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
description: "Security hardening for Google Chat — app & webhook controls, external chat & spaces, file sharing, history & retention, and audit logging & content reporting."
version: "0.1.0"
maturity: "draft"
last_updated: "2026-05-29"
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
This guide covers Google Chat hardening in the Google Workspace Admin Console: Chat app & webhook installation controls, external chat and spaces restrictions, Chat file-sharing posture, history and Vault-based retention, and Chat audit logging & content reporting. Platform-wide authentication, OAuth allowlisting, the DLP engine, and admin-console audit logging are covered in the [Google Workspace guide](/guides/google-workspace/). Gmail and Drive are covered in their own product guides.

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
| CIS Google Workspace | 3.1.4.2.2 |

#### Description
Restrict Google Chat and spaces with people outside your organization. Either turn external chat off, or—if external collaboration is required—allow it **only for allowlisted (trusted) domains**, and apply the same restriction to externally shared spaces.

#### Rationale
**Why This Matters:**
- Unrestricted external chat is a low-friction data-exfiltration channel that is monitored less rigorously than email
- "Auto-accept chat invites from familiar contacts" can pull users into external conversations without an explicit decision
- External spaces let outside members persist in a shared room with access to its files and history

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

**Step 2: Restrict External Spaces**
1. Navigate to: **Apps** → **Google Workspace** → **Google Chat** → **External spaces**
2. For **Allow users to create & join spaces with people outside their organization**: select **Off**, or **On** with **Only allow users to add people from allowlisted domains** checked
3. Click **Save**

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
3. Confirm an allowlisted-domain partner can still chat

**Expected result:** External chat/spaces work only with allowlisted domains (or are fully disabled).

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CISA SCuBA** | GWS.CHAT.4.1v1 | External chat restricted to allowlisted domains |
| **NIST 800-53** | AC-20 | Use of external systems |
| **SOC 2** | CC6.6 | Boundary protection / external access |
| **CIS Google Workspace** | 3.1.4.2.2 | Ensure Google Chat externally is restricted to allowlisted domains |

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

## 3. Monitoring & Detection

### 3.1 Enable Google Chat Audit Logging & Content Reporting

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 8.5 |
| NIST 800-53 | AU-2, AU-6, IR-6 |
| CISA SCuBA | GWS.CHAT.5.1v1, GWS.CHAT.5.2v1 |

#### Description
Monitor Google Chat through the Chat log events report (and Reports API / BigQuery export), and enable content reporting so users can flag malicious or inappropriate messages to admins across all conversation types.

#### Rationale
**Why This Matters:**
- Chat is a phishing and malware-delivery channel; content reporting turns every user into a detection sensor (NIST IR-6)
- Chat audit events (`message_posted`, `attachment_upload`, `room_created`, `add_room_member`) reveal exfiltration and rogue-space activity
- Reporting requires Chat history to be enabled ([2.3](#23-enforce-google-chat-history--retention))

**Attack Prevented:** Undetected Chat phishing/malware, unmonitored data exfiltration, delayed incident response

#### Prerequisites
- Chat history enabled ([2.3](#23-enforce-google-chat-history--retention))
- Audit & Investigation admin privilege; BigQuery export for long-term retention ([Google Workspace Audit Logging](/guides/google-workspace/#51-enable-audit-logging-and-investigation-tool))

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
1. As a user, confirm the **Report** option appears on messages in every conversation type
2. Submit a test report and confirm it surfaces in the admin tooling
3. Run the Reports API / GAM query and confirm Chat events return

**Expected result:** Chat events are auditable; users can report content across all conversation types.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CISA SCuBA** | GWS.CHAT.5.1v1 | Content reporting enabled for all conversation types |
| **CISA SCuBA** | GWS.CHAT.5.2v1 | All reporting categories selected |
| **NIST 800-53** | IR-6 | Incident reporting |
| **SOC 2** | CC7.2 | System monitoring |

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
| [3.1](#31-enable-google-chat-audit-logging--content-reporting) Audit & reporting | CC7.2 | AU-6, IR-6 |

> Platform-wide compliance mappings (authentication, OAuth, DLP, admin audit logging) are in the [Google Workspace guide](/guides/google-workspace/#7-compliance-quick-reference).

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-05-29 | Initial Google Chat product guide — split from the Google Workspace guide (controls 1.1 app allowlisting, 2.1 external chat, 2.2 file sharing, 2.3 history & retention, 3.1 audit & content reporting). Part of the multi-product platform restructure. |

## Contributing

Found an issue or have an improvement? See the [Google Workspace platform guide](/guides/google-workspace/) for platform-wide controls, or open an issue/PR on [GitHub](https://github.com/grcengineering/how-to-harden).
