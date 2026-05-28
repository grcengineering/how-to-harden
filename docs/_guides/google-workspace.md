---
layout: guide
title: "Google Workspace Hardening Guide"
vendor: "Google"
slug: "google-workspace"
tier: "1"
category: "Productivity"
description: "Comprehensive security hardening for Google Workspace, Gmail, Drive, Google Chat, and Google Admin Console"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-05-28"
---

## Overview

Google Workspace is used by over **9 million organizations** worldwide for email, document collaboration, and cloud storage. As a primary target for phishing and credential theft, Google Workspace security is critical—phishing was responsible for financially devastating data breaches for 9/10 organizations in 2024. According to CISA, accounts with MFA enabled are 99% less likely to be compromised.

### Intended Audience
- Security engineers managing Google Workspace environments
- IT administrators configuring Admin Console security
- GRC professionals assessing cloud productivity compliance
- Third-party risk managers evaluating Google integrations

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Google Workspace Admin Console security configurations including authentication policies, OAuth app controls, Drive sharing settings, Gmail protection, Google Chat hardening, and device management. Google Cloud Platform (GCP) infrastructure is covered in a separate guide.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Network Access Controls](#2-network-access-controls)
3. [OAuth & Integration Security](#3-oauth--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Multi-Factor Authentication for All Users

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 6.5 |
| NIST 800-53 | IA-2(1), IA-2(6) |
| CIS Google Workspace | 1.1 |

#### Description
Require 2-Step Verification (2SV) for all users with enforcement, not just enrollment. Microsoft found that enabling MFA prevents 99.9% of automated attacks on cloud accounts.

#### Rationale
**Why This Matters:**
- Phishing remains the #1 attack vector against Google Workspace
- Password reuse and credential stuffing are common attack methods
- Accounts with MFA are 99% less likely to be compromised (CISA)

**Attack Prevented:** Credential theft, phishing, password spray, account takeover

**Real-World Incidents:**
- **Twitter (2020):** Compromised employee credentials led to high-profile account takeover
- **Colonial Pipeline (2021):** VPN credentials without MFA enabled ransomware deployment

#### Prerequisites
- Super Admin access to Google Admin Console
- User communication plan for 2SV enrollment
- Security keys for privileged users (recommended)

#### ClickOps Implementation

**Step 1: Enable 2-Step Verification Enrollment**
1. Navigate to: **Admin Console** → **Security** → **Authentication** → **2-Step Verification**
2. Check **Allow users to turn on 2-Step Verification**
3. Set **Enforcement** to **On** for all organizational units
4. Configure **New user enrollment period:** 7 days (grace period)
5. Click **Save**

**Step 2: Configure Allowed Methods**
1. In the same section, click **Allowed methods**
2. Select **Any except verification codes via text or phone call** (recommended)
3. This forces users to use authenticator apps or security keys instead of vulnerable SMS

**Step 3: Enforce Security Keys for Admins**
1. Navigate to: **Security** → **Authentication** → **2-Step Verification**
2. Select the Admin organizational unit
3. Set **Allowed methods** to **Only security key**
4. Click **Save**

**Time to Complete:** ~30 minutes

#### Code Implementation

#### Validation & Testing
**How to verify the control is working:**
1. Sign in as test user - 2SV prompt should appear
2. Check Admin Console → Reports → User Reports → Security
3. Verify 2SV enrollment percentage approaches 100%
4. Attempt sign-in with only password - should fail after enforcement

**Expected result:** All users prompted for second factor, enforcement active

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Monitor Security → Investigation Tool for failed 2SV attempts
- Alert on suspicious sign-in attempts
- Track 2SV enrollment completion

**Admin Console Query:** Navigate to Security, then Investigation Tool. Set Event to Login, and filter by 2SV method = None, Login result = Success.

**Maintenance schedule:**
- **Weekly:** Review new user 2SV enrollment
- **Monthly:** Audit 2SV enforcement exceptions
- **Quarterly:** Review and rotate Super Admin security keys

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Low-Medium | Initial enrollment required; subsequent logins add ~5 seconds |
| **System Performance** | None | No performance impact |
| **Maintenance Burden** | Low | Minimal after initial rollout |
| **Rollback Difficulty** | Easy | Disable enforcement in Admin Console |

**Potential Issues:**
- Users without smartphones: Provide hardware security keys
- Shared device environments: Use security keys instead of mobile apps

**Rollback Procedure:**
1. Navigate to Admin Console → Security → 2-Step Verification
2. Set Enforcement to **Off**
3. Note: This leaves accounts vulnerable; use only for emergency troubleshooting

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-2(1) | Multi-factor authentication |
| **ISO 27001** | A.9.4.2 | Secure log-on procedures |
| **CIS Google Workspace** | 1.1 | Ensure 2-Step Verification is enforced |

{% include pack-code.html vendor="google-workspace" section="1.1" %}

---

### 1.2 Restrict Super Admin Account Usage

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1), AC-6(5) |
| CIS Google Workspace | 1.2 |

#### Description
Limit Super Admin privileges to 2-4 dedicated accounts, enforce security keys for authentication, and use delegated admin roles for day-to-day administration.

#### Rationale
**Why This Matters:**
- Super Admin accounts have unrestricted access to all data and settings
- Compromised Super Admin = complete organization compromise
- Delegated roles follow principle of least privilege

**Attack Prevented:** Privilege escalation, lateral movement, admin account compromise

#### Prerequisites
- Inventory of current Super Admin accounts
- Security keys for all Super Admins
- Defined delegated admin roles

#### ClickOps Implementation

**Step 1: Audit Current Super Admins**
1. Navigate to: **Admin Console** → **Account** → **Admin roles**
2. Click **Super Admin** role
3. Review assigned users - should be 2-4 maximum
4. Document and remove unnecessary assignments

**Step 2: Create Delegated Admin Roles**
1. Navigate to: **Admin Console** → **Account** → **Admin roles**
2. Click **Create new role**
3. Create role-specific admins:
   - **User Admin:** Manage users, reset passwords
   - **Groups Admin:** Manage groups and memberships
   - **Help Desk Admin:** Reset passwords, view user info
4. Assign appropriate permissions for each role

**Step 3: Enforce Security Keys for Super Admins**
1. Create organizational unit: **Super Admins**
2. Move Super Admin accounts to this OU
3. Navigate to: **Security** → **2-Step Verification**
4. Select Super Admins OU
5. Set **Allowed methods** to **Only security key**

**Time to Complete:** ~45 minutes

#### Code Implementation

#### Validation & Testing
1. Verify only 2-4 Super Admin accounts exist
2. Confirm all Super Admins use security keys
3. Test delegated admin can perform assigned tasks only
4. Verify delegated admin cannot access Super Admin functions

{% include pack-code.html vendor="google-workspace" section="1.2" %}

---

### 1.3 Configure Context-Aware Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4, 13.5 |
| NIST 800-53 | AC-2(11), AC-6(1) |

#### Description
Implement context-aware access policies that evaluate device, location, and user risk before granting access to Google Workspace applications.

#### Rationale
**Why This Matters:**
- Allows enforcement of device compliance before access
- Can block access from high-risk locations
- Provides additional layer beyond authentication

#### Prerequisites
- Google Workspace Enterprise Standard or Plus
- BeyondCorp Enterprise (for advanced features)
- Endpoint Verification deployed to managed devices

#### ClickOps Implementation

**Step 1: Deploy Endpoint Verification**
1. Navigate to: **Admin Console** → **Devices** → **Mobile & endpoints** → **Settings**
2. Enable **Endpoint Verification**
3. Deploy Chrome extension to managed devices
4. Or use Google's Endpoint Verification app for unmanaged devices

**Step 2: Create Access Level**
1. Navigate to: **Security** → **Access and data control** → **Context-Aware Access**
2. Click **Access Levels** → **Create Access Level**
3. Configure conditions:
   - Device must have Endpoint Verification
   - Device must be encrypted
   - Device must have screen lock
4. Save access level

**Step 3: Assign Access Level to Apps**
1. In Context-Aware Access, click **Assign Access Levels**
2. Select apps (Gmail, Drive, etc.)
3. Assign the created access level
4. Enable enforcement after testing

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="google-workspace" section="1.3" %}

---

## 2. Network Access Controls

### 2.1 Configure Allowed IP Ranges for Admin Console

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17, SC-7 |

#### Description
Restrict Admin Console access to specific IP ranges (corporate network, VPN) to prevent unauthorized administrative access.

#### ClickOps Implementation

**Step 1: Configure Allowed IPs**
1. Navigate to: **Admin Console** → **Security** → **Access and data control** → **Context-Aware Access**
2. Create access level with IP conditions
3. Specify corporate egress IP ranges
4. Apply to Admin Console access

**Step 2: Alternative - Session Control**
1. Navigate to: **Security** → **Google Cloud session control**
2. Configure reauthentication frequency for sensitive apps

#### Code Implementation

{% include pack-code.html vendor="google-workspace" section="2.1" %}

---

## 3. OAuth & Integration Security

### 3.1 Enable OAuth App Whitelisting

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | AC-3, CM-7 |
| CIS Google Workspace | 2.1 |

#### Description
Restrict which third-party applications can access Google Workspace data via OAuth. Block unverified apps and require admin approval for new integrations.

#### Rationale
**Why This Matters:**
- OAuth consent phishing is a growing attack vector
- Malicious apps can gain persistent access to email and files
- Users often grant excessive permissions without understanding risks

**Attack Prevented:** OAuth consent phishing, malicious app installation, data exfiltration

**Real-World Incidents:**
- **Google Docs Phishing (2017):** Fake "Google Docs" app tricked users into granting email access
- Multiple incidents of data-stealing apps masquerading as productivity tools

#### Prerequisites
- Inventory of currently authorized OAuth apps
- Business justification for each approved app
- User communication about approval process

#### ClickOps Implementation

**Step 1: Review Current OAuth Apps**
1. Navigate to: **Admin Console** → **Security** → **API controls** → **App access control**
2. Click **Manage Third-Party App Access**
3. Review list of apps with access to organizational data
4. Document apps that should be allowed

**Step 2: Configure App Whitelisting**
1. In **App access control**, click **Settings**
2. Set default policy: **Block all third-party API access** or **Block unconfigured third-party apps**
3. Configure trusted apps list
4. Click **Save**

**Step 3: Whitelist Approved Apps**
1. Click **Add app** → **OAuth App Name or Client ID**
2. Search for app or enter Client ID
3. Configure access level:
   - **Trusted:** Full access to requested scopes
   - **Limited:** Access to only non-sensitive scopes
   - **Blocked:** No access
4. Add business justification
5. Click **Configure**

**Time to Complete:** ~1 hour (initial configuration), ongoing for new app requests

#### Code Implementation

#### Validation & Testing
1. Verify blocked apps cannot access data
2. Test app approval workflow
3. Review Security Investigation Tool for blocked app attempts
4. Confirm whitelisted apps function correctly

**Expected result:** Only approved apps can access organizational data

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | AC-3 | Access enforcement |
| **CIS Google Workspace** | 2.1 | Ensure third-party apps are audited and controlled |

{% include pack-code.html vendor="google-workspace" section="3.1" %}

---

### 3.2 Disable Less Secure Apps

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.2 |
| NIST 800-53 | IA-2 |

#### Description
Disable "Less Secure Apps" access which allows applications to authenticate with just username/password, bypassing 2-Step Verification.

#### Rationale
**Why This Matters:**
- Less Secure Apps bypass MFA completely
- Legacy protocols are targets for password spray
- Google has deprecated this feature, but some tenants may still have it enabled

#### ClickOps Implementation

**Step 1: Disable Less Secure Apps**
1. Navigate to: **Admin Console** → **Security** → **Less secure apps**
2. Select **Disable access to less secure apps (Recommended)**
3. Click **Save**

> **Note:** This should be disabled by default for most tenants as of recent Google updates.

#### Code Implementation

{% include pack-code.html vendor="google-workspace" section="3.2" %}

---

### 3.3 Restrict & Allowlist Google Chat Apps

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
- Marketplace allowlist workflow (see [3.1](#31-enable-oauth-app-whitelisting))

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

{% include pack-code.html vendor="google-workspace" section="3.3" %}

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

## 4. Data Security

### 4.1 Configure External Drive Sharing Restrictions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3, AC-22 |
| CIS Google Workspace | 3.1 |

#### Description
Restrict external sharing of Google Drive files to prevent unauthorized data exposure. Configure default sharing settings to "Restricted" and control "Anyone with the link" sharing.

#### Rationale
**Why This Matters:**
- Oversharing is one of the biggest security risks in Google Workspace
- "Anyone with the link" files can be accessed by anyone who discovers the URL
- Data exposure from misconfigured sharing is common

**Attack Prevented:** Data exfiltration, accidental data exposure, insider threats

#### Prerequisites
- Inventory of current sharing policies
- Business requirements for external collaboration

#### ClickOps Implementation

**Step 1: Configure Organization-Wide Sharing**
1. Navigate to: **Admin Console** → **Apps** → **Google Workspace** → **Drive and Docs**
2. Click **Sharing settings**
3. Configure **Sharing options**:
   - **Sharing outside of [organization]:** Off or Allowlisted domains only
   - **Default link sharing:** Restricted (only people added)
4. Click **Save**

**Step 2: Configure Sharing for Specific OUs**
1. Select organizational unit from left panel
2. Override settings for teams requiring external collaboration
3. Use most restrictive settings possible

**Step 3: Disable "Anyone with the link"**
1. In Sharing settings, find **Link sharing default**
2. Set to **Restricted** (not "Anyone with the link")
3. Optionally block "Anyone with the link" entirely

**Time to Complete:** ~30 minutes

#### Code Implementation

#### Validation & Testing
1. Create test file and verify default sharing is Restricted
2. Attempt to share externally - verify appropriate restrictions apply
3. Audit existing files with external sharing
4. Confirm allowed external sharing still functions

{% include pack-code.html vendor="google-workspace" section="4.1" %}

---

### 4.2 Enable Data Loss Prevention (DLP)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.2 |
| NIST 800-53 | SC-8, SC-28 |

#### Description
Configure Google Workspace DLP rules to detect and prevent sharing of sensitive information like credit cards, SSNs, and confidential documents.

#### Prerequisites
- Google Workspace Enterprise Standard or Plus
- Defined sensitive data types for your organization

#### ClickOps Implementation

**Step 1: Access DLP Settings**
1. Navigate to: **Admin Console** → **Security** → **Access and data control** → **Data protection**
2. Click **Manage Rules**

**Step 2: Create DLP Rule**
1. Click **Create rule**
2. Configure:
   - **Name:** Block sharing of PII
   - **Scope:** Entire organization or specific OUs
   - **Apps:** Drive, Chat
   - **Conditions:** Content matches predefined detectors (SSN, Credit Card, etc.)
   - **Actions:** Block external sharing, warn user, alert admin
3. Save and enable rule

#### Code Implementation

{% include pack-code.html vendor="google-workspace" section="4.2" %}

> **Google Chat DLP:** The same data protection rules apply to Chat messages and attachments. When creating a rule, set **Apps** to **Chat**, choose the conversation type (**internal** or **external**), and enable OCR to scan images. Attachments over 50 MB are sent without scanning. See [4.4](#44-restrict-google-chat-file-sharing) to also cap what file types can be shared.

---

### 4.3 Restrict External Google Chat & Spaces

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

{% include pack-code.html vendor="google-workspace" section="4.3" %}

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

### 4.4 Restrict Google Chat File Sharing

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
- DLP for Chat configured for residual risk ([4.2](#42-enable-data-loss-prevention-dlp))

#### ClickOps Implementation

**Step 1: Configure Chat File Sharing**
1. Navigate to: **Admin Console** → **Apps** → **Google Workspace** → **Google Chat** → **Chat file sharing**
2. Set **External filesharing** to **No files** (SCuBA GWS.CHAT.2.1v1)
3. Set **Internal filesharing** to **Allow all files** or, for sensitive OUs, **Images only**
4. Click **Save**

> **Note:** Files shared in Chat are automatically scanned for viruses before delivery, but malware and DLP scanning do not replace a file-type restriction.

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="google-workspace" section="4.4" %}

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

### 4.5 Enforce Google Chat History & Retention

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

{% include pack-code.html vendor="google-workspace" section="4.5" %}

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

## 5. Monitoring & Detection

### 5.1 Enable Audit Logging and Investigation Tool

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-3, AU-6 |
| CIS Google Workspace | 5.1 |

#### Description
Enable and configure audit logging across all Google Workspace services. Use the Security Investigation Tool for threat detection and incident response.

#### Rationale
**Why This Matters:**
- Audit logs are essential for incident investigation
- Provides visibility into admin actions, file access, and sign-in events
- Required for compliance with most security frameworks

#### ClickOps Implementation

**Step 1: Verify Audit Logging**
1. Navigate to: **Admin Console** → **Reporting** → **Audit and investigation**
2. Verify logs are being captured for:
   - Admin activities
   - Login activities
   - Drive activities
   - Token activities
   - Rules activities

**Step 2: Configure Audit Log Exports**
1. Navigate to: **Reporting** → **Audit and investigation** → **Export to BigQuery**
2. Enable export to BigQuery for long-term retention
3. Configure retention period

**Step 3: Create Alert Rules**
1. Navigate to: **Security** → **Alert center** → **Configure alerts**
2. Enable critical alerts:
   - Suspicious login
   - Government-backed attack
   - Device compromised
   - Super Admin added

**Time to Complete:** ~30 minutes

#### Key Events to Monitor

| Event | Log Source | Detection Use Case |
|-------|------------|-------------------|
| `CHANGE_PASSWORD` | Admin | Unauthorized password resets |
| `GRANT_ADMIN_ROLE` | Admin | Privilege escalation |
| `CREATE_APPLICATION_SETTING` | Admin | OAuth app approval |
| `LOGIN_FAILURE` | Login | Brute force attempts |
| `SUSPICIOUS_LOGIN` | Login | Account compromise |
| `DOWNLOAD` | Drive | Data exfiltration |

#### Code Implementation

{% include pack-code.html vendor="google-workspace" section="5.1" %}

---

### 5.2 Enable Google Chat Audit Logging & Content Reporting

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
- Reporting requires Chat history to be enabled ([4.5](#45-enforce-google-chat-history--retention))

**Attack Prevented:** Undetected Chat phishing/malware, unmonitored data exfiltration, delayed incident response

#### Prerequisites
- Chat history enabled ([4.5](#45-enforce-google-chat-history--retention))
- Audit & Investigation admin privilege; BigQuery export for long-term retention ([5.1](#51-enable-audit-logging-and-investigation-tool))

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

{% include pack-code.html vendor="google-workspace" section="5.2" %}

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

## 6. Third-Party Integration Security

### 6.1 Integration Risk Assessment Matrix

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **Data Access** | Read-only, limited scope | Read most data | Write access, full API |
| **OAuth Scopes** | Specific scopes | Broad API access | Full admin/Gmail access |
| **Session Duration** | Short-lived tokens | Refresh tokens | Offline access |
| **Vendor Security** | SOC 2 Type II + ISO | SOC 2 Type I | No certification |

### 6.2 Common Integrations and Recommended Controls

#### Obsidian Security
**Data Access:** Read (Gmail metadata, Drive metadata, audit logs)
**Recommended Controls:**
- ✅ Use dedicated service account
- ✅ Grant minimum required OAuth scopes
- ✅ Review access quarterly
- ✅ Monitor API usage via Reports

#### Slack
**Data Access:** Medium (Google Calendar, Drive file links)
**Recommended Controls:**
- ✅ Approve specific scopes only
- ✅ Limit to approved workspaces
- ✅ Monitor for unusual activity

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Google Workspace Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA for all users | [1.1](#11-enforce-multi-factor-authentication-for-all-users) |
| CC6.1 | OAuth app controls | [3.1](#31-enable-oauth-app-whitelisting) |
| CC6.2 | Super Admin restrictions | [1.2](#12-restrict-super-admin-account-usage) |
| CC6.6 | External sharing restrictions | [4.1](#41-configure-external-drive-sharing-restrictions) |
| CC6.6 | Chat external & file-sharing restrictions | [4.3](#43-restrict-external-google-chat--spaces), [4.4](#44-restrict-google-chat-file-sharing) |
| CC7.2 | Audit logging | [5.1](#51-enable-audit-logging-and-investigation-tool) |
| CC7.2 | Chat audit logging & content reporting | [5.2](#52-enable-google-chat-audit-logging--content-reporting) |

### NIST 800-53 Rev 5 Mapping

| Control | Google Workspace Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | MFA enforcement | [1.1](#11-enforce-multi-factor-authentication-for-all-users) |
| AC-6(1) | Least privilege admin | [1.2](#12-restrict-super-admin-account-usage) |
| AC-3 | OAuth app control | [3.1](#31-enable-oauth-app-whitelisting) |
| CM-7 | Chat app restriction | [3.3](#33-restrict--allowlist-google-chat-apps) |
| AC-20 | Chat external messaging | [4.3](#43-restrict-external-google-chat--spaces) |
| AU-9 | Chat history protection | [4.5](#45-enforce-google-chat-history--retention) |
| AU-2 | Audit logging | [5.1](#51-enable-audit-logging-and-investigation-tool) |
| IR-6 | Chat content reporting | [5.2](#52-enable-google-chat-audit-logging--content-reporting) |

### CIS Google Workspace Foundations Benchmark Mapping

| Recommendation | Google Workspace Control | Guide Section |
|---------------|------------------|---------------|
| 1.1 | Ensure 2SV is enforced | [1.1](#11-enforce-multi-factor-authentication-for-all-users) |
| 1.2 | Limit Super Admin accounts | [1.2](#12-restrict-super-admin-account-usage) |
| 2.1 | Control third-party apps | [3.1](#31-enable-oauth-app-whitelisting) |
| 3.1 | Restrict external sharing | [4.1](#41-configure-external-drive-sharing-restrictions) |
| 3.1.4.2.2 | Restrict Google Chat externally to allowlisted domains | [4.3](#43-restrict-external-google-chat--spaces) |

### CISA SCuBA Google Chat Baseline Mapping

| Policy ID | Requirement | Guide Section |
|-----------|-------------|---------------|
| GWS.CHAT.1.1v1 | Chat history enabled | [4.5](#45-enforce-google-chat-history--retention) |
| GWS.CHAT.1.2v1 | Users cannot change history setting | [4.5](#45-enforce-google-chat-history--retention) |
| GWS.CHAT.2.1v1 | External Chat file sharing disabled | [4.4](#44-restrict-google-chat-file-sharing) |
| GWS.CHAT.3.1v1 | Space history enabled | [4.5](#45-enforce-google-chat-history--retention) |
| GWS.CHAT.4.1v1 | External chat restricted to allowlisted domains | [4.3](#43-restrict-external-google-chat--spaces) |
| GWS.CHAT.5.1v1 | Content reporting enabled for all conversation types | [5.2](#52-enable-google-chat-audit-logging--content-reporting) |
| GWS.CHAT.5.2v1 | All reporting categories selected | [5.2](#52-enable-google-chat-audit-logging--content-reporting) |

---

## Appendix A: Edition/Tier Compatibility

| Control | Business Starter | Business Standard | Business Plus | Enterprise Standard | Enterprise Plus |
|---------|------------------|-------------------|---------------|---------------------|-----------------|
| 2-Step Verification | ✅ | ✅ | ✅ | ✅ | ✅ |
| Security Keys enforcement | ✅ | ✅ | ✅ | ✅ | ✅ |
| OAuth app whitelisting | ❌ | ✅ | ✅ | ✅ | ✅ |
| Context-Aware Access | ❌ | ❌ | ✅ | ✅ | ✅ |
| Data Loss Prevention | ❌ | ❌ | ❌ | ❌ | ✅ |
| Security Investigation Tool | ❌ | ❌ | ❌ | ✅ | ✅ |
| BigQuery export | ❌ | ❌ | ❌ | ✅ | ✅ |
| Google Chat external & spaces restrictions | ✅ | ✅ | ✅ | ✅ | ✅ |
| Google Chat history & content reporting | ✅ | ✅ | ✅ | ✅ | ✅ |
| Google Chat file-sharing & app controls | ✅ | ✅ | ✅ | ✅ | ✅ |
| Vault retention/holds for Chat | ❌ | ❌ | ✅ | ✅ | ✅ |

---

## Appendix B: References

**Official Google Documentation:**
- [Google Workspace Admin Help](https://support.google.com/a)
- [Security Best Practices](https://support.google.com/a/answer/7587183)
- [Google Cloud MFA Requirement](https://docs.cloud.google.com/docs/authentication/mfa-requirement)
- [Data Protection and Compliance](https://business.safety.google/compliance/)
- [Compliance Reports Manager](https://cloud.google.com/security/compliance/compliance-reports-manager)

**Google Chat Hardening:**
- [Control external Chat & spaces chat options](https://support.google.com/a/answer/9269229)
- [Allow users to install Chat apps](https://support.google.com/a/answer/7651360)
- [Control file sharing in Chat](https://support.google.com/a/answer/10277783)
- [Turn chat history on or off for users](https://support.google.com/a/answer/7664184)
- [Set a space history option for users](https://support.google.com/a/answer/9948515)
- [Prevent data leaks from Chat messages & attachments (DLP)](https://support.google.com/a/answer/10846568)
- [Chat log events](https://support.google.com/a/answer/9142478)
- [Chat Audit Activity Events (Reports API)](https://developers.google.com/workspace/admin/reports/v1/appendix/activity/chat)
- [Retain Google Chat messages with Vault](https://support.google.com/vault/answer/7657597)
- [Vault API — manage holds (HANGOUTS_CHAT corpus)](https://developers.google.com/workspace/vault/guides/holds)

**API & Developer Tools:**
- [Google Workspace Developer Hub](https://developers.google.com/workspace)
- [Admin SDK API Reference](https://developers.google.com/admin-sdk)
- [GAM - Google Workspace Admin CLI](https://github.com/GAM-team/GAM)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO/IEC 27001:2022, ISO 27017, ISO 27018, ISO 27701, FedRAMP (High), BSI C5, MTCS -- via [Compliance Reports Manager](https://cloud.google.com/security/compliance/compliance-reports-manager)
- [ISO/IEC 27001 Compliance](https://cloud.google.com/security/compliance/iso-27001)
- [SOC 2 Compliance](https://cloud.google.com/security/compliance/soc-2)

**Security Incidents:**
- Google Workspace has not had a major platform-level breach. Notable ecosystem incidents include the **Google Docs OAuth Phishing Attack (2017)**, where a fake "Google Docs" app tricked users into granting email access via OAuth consent.

**Third-Party Security Guides:**
- [CISA Google Common Controls](https://www.cisa.gov/resources-tools/services/gws-commoncontrols)
- [CISA SCuBA Secure Configuration Baseline for Google Chat](https://www.cisa.gov/resources-tools/services/gws-chat)
- [CISA ScubaGoggles (GWS assessment tool & baselines)](https://github.com/cisagov/ScubaGoggles)
- [CIS Google Workspace Benchmark](https://www.cisecurity.org/benchmark/google_workspace)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-05-28 | 0.2.0 | draft | Added Google Chat hardening: app/webhook allowlisting (3.3), external chat & spaces restrictions (4.3), Chat file sharing (4.4), history & Vault retention (4.5), and Chat audit logging & content reporting (5.2). Mapped to CISA SCuBA GWS.CHAT baseline; added Chat code packs and references. | Claude Code (Opus 4.7) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with authentication, OAuth, data security, and monitoring controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
