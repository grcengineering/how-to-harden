---
layout: guide
title: "Slack Hardening Guide"
vendor: "Slack"
slug: "slack"
tier: "1"
category: "Productivity"
description: "Enterprise security hardening for Slack workspaces, SSO, DLP, and data governance"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-03"
---

## Overview

Slack is used by over **750,000 organizations** worldwide for business communication, with Enterprise Grid serving large enterprises requiring centralized security controls. As a repository of sensitive business communications, intellectual property, and credentials shared in messages, Slack security is critical for preventing data breaches and maintaining compliance.

### Intended Audience
- Security engineers managing Slack Enterprise deployments
- IT administrators configuring workspace security
- GRC professionals assessing collaboration tool compliance
- Third-party risk managers evaluating Slack integrations

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries (HIPAA, FINRA, FedRAMP)

### Scope
This guide covers Slack workspace and Enterprise Grid security configurations including SSO/SAML, data loss prevention, retention policies, app management, and external collaboration controls.

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

### 1.1 Enable SAML Single Sign-On (SSO)

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML-based SSO to authenticate Slack users through your corporate identity provider (Okta, Azure AD, OneLogin, Ping Identity). This centralizes authentication and enables MFA enforcement through your IdP.

#### Rationale
**Why This Matters:**
- Centralizes authentication management
- Enables Conditional Access, MFA, and risk-based policies
- Automatic deprovisioning when users leave the organization
- Eliminates standalone Slack passwords

**Attack Prevented:** Credential theft, password reuse, orphaned accounts

#### Prerequisites
- Slack Business+ or Enterprise Grid plan
- SAML 2.0 compatible identity provider
- Workspace Owner or Org Admin access

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Slack Admin** → **Settings** → **Authentication**
2. Click **Configure** next to SAML authentication

**Step 2: Configure SAML Provider**
1. Enter your Identity Provider details:
   - **SAML SSO URL:** Your IdP's SSO endpoint
   - **Identity Provider Issuer:** IdP entity ID
   - **Public Certificate:** X.509 certificate from IdP
2. Configure options:
   - **Sign AuthnRequest:** Yes (recommended)
   - **Service Provider Issuer:** Your Slack workspace URL

**Step 3: Configure IdP (Example: Okta)**
1. In Okta Admin Console: **Applications** → **Add Application** → Search "Slack"
2. Configure SAML settings using Slack's metadata
3. Assign users/groups to the Slack application
4. Enable SCIM provisioning for automatic user management

**Step 4: Enforce SSO**
1. Return to Slack Authentication settings
2. Under **SSO settings**, select **SAML SSO Required**
3. This prevents password-based sign-in

**Time to Complete:** ~1 hour (depending on IdP complexity)

#### Code Implementation

{% include pack-code.html vendor="slack" section="1.1" %}

#### Validation & Testing
**How to verify the control is working:**
1. Attempt to sign in - should redirect to IdP
2. Verify MFA prompt from IdP
3. Confirm password-only sign-in is blocked
4. Test user deprovisioning from IdP removes Slack access

**Expected result:** All users authenticate via SSO with MFA enforced by IdP

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-2 | Identification and authentication |
| **ISO 27001** | A.9.4.2 | Secure log-on procedures |
| **HIPAA** | 164.312(d) | Person or entity authentication |

---

### 1.2 Configure SCIM User Provisioning

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Enable SCIM (System for Cross-domain Identity Management) to automatically provision and deprovision Slack users based on your identity provider directory.

#### Rationale
**Why This Matters:**
- Automatic user lifecycle management
- Immediate deprovisioning when employees leave
- Eliminates orphaned accounts
- Reduces manual administration

**Attack Prevented:** Orphaned account abuse, unauthorized access after termination

#### Prerequisites
- Slack Enterprise Grid
- SCIM-compatible identity provider
- Org Admin access

#### ClickOps Implementation

**Step 1: Enable SCIM Provisioning**
1. Navigate to: **Enterprise Grid Admin** → **Settings** → **Authentication**
2. Click **Configure** next to SCIM provisioning
3. Generate SCIM API token
4. Copy the SCIM endpoint URL

**Step 2: Configure IdP**
1. In your IdP, configure SCIM integration with:
   - Base URL: `https://api.slack.com/scim/v1`
   - Authentication: Bearer token (from Step 1)
2. Enable provisioning features:
   - Create users
   - Update user attributes
   - Deactivate users
3. Map user attributes (email, displayName, etc.)

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="slack" section="1.2" %}

#### Validation & Testing
1. Create user in IdP - verify appears in Slack
2. Update user in IdP - verify changes sync
3. Deactivate user in IdP - verify Slack access removed
4. Verify deprovisioned users cannot sign in

---

### 1.3 Restrict Workspace Admin Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Limit Primary Owner and Admin roles to essential personnel. Use granular roles like Workspace Admins and User Groups Admins for delegated administration.

#### Rationale
**Why This Matters:**
- Primary Owners have unrestricted access
- Admins can modify security settings
- Excessive admin privileges increase risk

#### ClickOps Implementation

**Step 1: Audit Current Admins**
1. Navigate to: **Slack Admin** → **Manage members**
2. Filter by **Account type:** Owners and Admins
3. Document current assignments

**Step 2: Implement Least Privilege**
1. Remove unnecessary Admin/Owner assignments
2. Use specific roles for delegated tasks:
   - **Workspace Admin:** Manage workspace settings
   - **User Groups Admin:** Manage user groups only
   - **Billing Admin:** Manage billing only

**Step 3: Enable Admin Approval for Role Changes**
1. Navigate to: **Settings** → **Permissions**
2. Configure approval workflow for admin role assignments

---

### 1.4 Configure Session Management

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.3 |
| NIST 800-53 | AC-11, AC-12 |

#### Description
Configure session duration controls to automatically log out inactive users and limit session lifetime.

#### Rationale
**Why This Matters:**
- Long-lived or never-expiring sessions let a stolen device, browser token, or unattended workstation retain authenticated Slack access indefinitely
- Forced logout after inactivity and a bounded session lifetime shrink the window an attacker can ride a hijacked session
- Shorter web-session durations force re-validation against the IdP and its MFA / conditional-access policies on a regular cadence
- Mobile devices are easily lost or stolen, so capping mobile session length contains exposure of corporate conversations and files

**Attack Prevented:** Session hijacking, stolen-token reuse, unattended-device access, lost or stolen mobile device access

#### ClickOps Implementation

**Step 1: Configure Session Duration**
1. Navigate to: **Enterprise Grid Admin** → **Settings** → **Authentication**
2. Under **Session duration**, configure:
   - **Web sessions:** 24 hours (or less for sensitive environments)
   - **Mobile sessions:** 30 days (balance security/usability)
3. Enable **Force logout after duration**

**Step 2: Enable Forced Logout**
1. In Authentication settings
2. Enable **Sign out users from all devices after inactivity**
3. Configure inactivity timeout (e.g., 4 hours)

---

### 1.5 Create Information Barriers Between Groups

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 6.8 |
| NIST 800-53 | AC-3, AC-4, SC-7(21) |

#### Description
Configure Slack Information Barriers to block direct messages and huddles between defined groups of users, enforcing regulatory "ethical walls" (for example, between research and trading desks, or between an acquiring and acquired business unit) directly inside Slack. Barriers are defined against groups synced from your identity provider, so membership follows the IdP rather than manual Slack lists. See [Create information barriers in Slack](https://slack.com/help/articles/360056171734-Create-information-barriers-in-Slack).

#### Rationale
**Why This Matters:**
- Regulated industries (FINRA, SEC, MiFID II) require enforced separation between functions that must not exchange material non-public information; policy documents alone are not an enforced control
- Slack DMs and huddles are the least-observed channels in a workspace, making them the natural path for informal information leakage between segregated groups
- Binding barriers to IdP-synced groups means a role change or transfer automatically re-scopes what a user can reach, closing the gap between HR reality and Slack reality
- During M&A or divestiture, barriers keep two organizations inside one Enterprise Grid without exposing each side's deal-sensitive conversations to the other

**Attack Prevented:** Insider information leakage across regulated boundaries, MNPI exchange between segregated desks, collusion via unmonitored DMs and huddles, cross-entity data exposure during M&A integration

#### Prerequisites
- Slack Enterprise plan (Enterprise Grid / Enterprise+)
- Org Owner or Org Admin access
- IdP groups that accurately represent the populations to be separated, synced into Slack

#### ClickOps Implementation

**Step 1: Prepare the Group Definitions**
1. In your identity provider, confirm the groups that define each side of the barrier (for example, `Research-Analysts` and `Trading-Desk`)
2. Verify the groups are syncing into Slack and that membership is current
3. Document the regulatory basis for each barrier before creating it

**Step 2: Create the Barrier**
1. Navigate to: **Tools & settings** → **Organization settings** → **Security** → **Information Barriers**
2. Click **Create Barrier**
3. Select the first group, then select the group or groups it must be barred from
4. Review the direction and scope of the restriction, then save

**Step 3: Communicate and Monitor**
1. Notify affected users that DMs and huddles across the barrier are blocked by policy
2. Record the barrier in your compliance control inventory with an owner and review cadence
3. Re-review barriers whenever the underlying IdP groups are restructured

**Time to Complete:** ~45 minutes (excluding IdP group preparation)

#### Validation & Testing
**How to verify the control is working:**
1. As a member of Group A, attempt to open a direct message with a member of Group B -- the user should not be selectable or the DM should be blocked
2. Attempt to start a huddle with a barred user and confirm it fails
3. Move a test user between IdP groups and confirm the barrier applies to their new group after sync
4. Confirm that users outside both groups are unaffected

**Expected result:** Direct messages and huddles between barred groups are prevented, and enforcement follows IdP group membership automatically

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.3 | Access is restricted based on role and segregation of duties |
| **NIST 800-53** | AC-4 | Information flow enforcement |
| **ISO 27001** | A.5.15 | Access control |
| **FINRA** | 3110 | Supervision and internal controls over communications |

---

## 2. Network Access Controls

### 2.1 Configure Approved IP Ranges

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17, SC-7 |

#### Description
Restrict Slack access to approved IP ranges (corporate network, VPN) to prevent unauthorized access from unknown locations.

#### Rationale
**Why This Matters:**
- IP allowlisting makes the workspace reachable only from trusted corporate egress points or the VPN, not from arbitrary internet locations
- Even if credentials or a session token are phished or stolen, an attacker outside the approved ranges cannot use them to reach Slack
- Network-layer restriction is independent of authentication, so a single failed control does not by itself grant access
- Confines exposure of sensitive business communications, files, and shared secrets to managed, monitored network paths

**Attack Prevented:** Credential-stuffing from unknown locations, stolen-token reuse off-network, account takeover from untrusted networks

#### Prerequisites
- Slack Enterprise Grid
- Known corporate egress IP ranges

#### ClickOps Implementation

**Step 1: Configure IP Allowlist**
1. Navigate to: **Enterprise Grid Admin** → **Settings** → **Authentication**
2. Click **IP allowlist**
3. Add approved IP ranges (CIDR notation)
4. Enable **Require sign-in from approved IPs only**

**Step 2: Configure Exceptions**
1. Optionally allow specific users (executives, remote workers) bypass
2. Document business justification for exceptions

---

## 3. OAuth & Integration Security

### 3.1 Restrict App Installation and Approval

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | AC-3, CM-7 |

#### Description
Control which Slack apps and integrations can be installed. Require admin approval for new app installations and regularly audit existing apps.

#### Rationale
**Why This Matters:**
- Slack apps can access messages, files, and user data
- Malicious apps can exfiltrate sensitive information
- OAuth tokens provide persistent access
- Slack now enforces a platform-level throttle that favors vetted apps: since **May 29, 2025**, non-Marketplace apps are limited to **1 request per minute** and **15 objects per call** on `conversations.history` and `conversations.replies` (existing non-Marketplace installs inherit the limit from **March 3, 2026**). Slack introduced this explicitly to curb bulk conversation-history exfiltration, so preferring Marketplace-listed apps both raises the vetting bar and preserves usable API throughput -- see [Rate limit changes for non-Marketplace apps](https://docs.slack.dev/changelog/2025/05/29/rate-limit-changes-for-non-marketplace-apps/)

**Attack Prevented:** Malicious app installation, bulk conversation-history exfiltration, unauthorized integrations

#### Prerequisites
- Slack Business+ or Enterprise Grid
- Workspace Owner or Admin access
- App approval workflow defined

#### ClickOps Implementation

**Step 1: Configure App Management**
1. Navigate to: **Slack Admin** → **Manage apps**
2. Click **App Management Settings**
3. Configure:
   - **Who can install apps:** Only Admins
   - **App approval:** Require admin approval for all new apps
   - **Pre-approved apps:** Define list of vetted apps

**Step 2: Review Existing Apps**
1. In **Manage apps**, review all installed apps
2. For each app, review:
   - Requested permissions/scopes
   - Data access level
   - Last used date
3. Remove unused or risky apps

**Step 3: Configure App Approval Workflow**
1. Under **App approval settings**
2. Configure reviewers (Security team)
3. Enable notification for new requests
4. Set up app review criteria -- include a preference for Slack Marketplace-listed apps, which pass Slack's review process and are exempt from the non-Marketplace conversation-history rate limits

**Time to Complete:** ~45 minutes

#### Code Implementation

{% include pack-code.html vendor="slack" section="3.1" %}

#### Validation & Testing
1. Attempt to install unapproved app - verify blocked
2. Submit app approval request - verify workflow triggers
3. Verify pre-approved apps can be installed
4. Audit existing apps for excessive permissions

---

### 3.2 Manage Slack Connect (External Collaboration)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-22, SC-7 |

#### Description
Control Slack Connect channels that enable collaboration with external organizations. Require approval for external connections and define allowed organizations.

#### Rationale
**Why This Matters:**
- Slack Connect enables data sharing with external parties
- Unauthorized connections can lead to data leakage
- External parties may have different security postures

#### ClickOps Implementation

**Step 1: Configure Slack Connect Permissions**
1. Navigate to: **Slack Admin** → **Settings** → **Slack Connect**
2. Configure:
   - **Who can create Slack Connect channels:** Only Admins
   - **Require approval for:** All external connections
   - **Allowed organizations:** Whitelist approved partners

**Step 2: Configure Data Loss Prevention for Connect**
1. Apply DLP rules to Slack Connect channels
2. Block sensitive data sharing to external channels

**Step 3: Configure Guest Access**
1. Navigate to: **Settings** → **Guest access**
2. Configure guest account restrictions
3. Limit guest access to specific channels

---

### 3.3 Govern Slack MCP Server and AI Agent Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5, 3.3 |
| NIST 800-53 | AC-3, AC-6, CM-7 |

#### Description
Treat AI agents that reach Slack through Slack's official remote MCP (Model Context Protocol) server as first-class app-directory decisions. The MCP server lets third-party AI assistants and agents query Slack data over OAuth, and it honors the requesting user's existing permissions -- it grants no new visibility, but it does give an external model programmatic reach into everything that user can already see. Approve specific agents and scopes deliberately rather than allowing MCP connections by default. See [Secure data connectivity for the modern AI era](https://slack.dev/secure-data-connectivity-for-the-modern-ai-era/).

#### Rationale
**Why This Matters:**
- An MCP-connected agent inherits the full read surface of the user who authorized it, so a single broadly-permissioned employee can expose a wide slice of the workspace to an external model
- Permission inheritance is a floor, not a ceiling: the control question is not "can this agent see more than the user?" but "should this vendor's model process what the user can see?"
- AI agents retrieve at machine speed and breadth, turning a permission set that is acceptable for human browsing into a bulk-retrieval channel
- Agent-side prompt injection can redirect what an otherwise legitimate agent asks Slack for, so the approved scope is the real containment boundary
- Data handled by the agent leaves Slack's compliance perimeter and lands in the AI vendor's retention, logging, and training regime, which your DLP and eDiscovery tooling does not cover

**Attack Prevented:** Unvetted AI vendor access to workspace content, bulk data retrieval via agent automation, prompt-injection-driven data pulls, shadow AI integrations outside the app-approval process

#### Prerequisites
- App approval controls already enforced (see [3.1](#31-restrict-app-installation-and-approval))
- Workspace Owner, Admin, or Org Admin access
- A defined AI vendor review standard (data retention, training use, subprocessors, certifications)

#### ClickOps Implementation

**Step 1: Inventory Existing AI and MCP Connections**
1. Navigate to: **Slack Admin** → **Manage apps**
2. Identify apps that are AI assistants, agent platforms, or MCP clients
3. For each, record the vendor, the OAuth scopes granted, and which users authorized it

**Step 2: Set the Approval Standard**
1. Require every MCP-connected agent to go through the same admin approval workflow as any other app
2. Add AI-specific review criteria: whether workspace content is retained, whether it is used for model training, which subprocessors receive it, and where it is stored
3. Reject or restrict agents that cannot answer those questions in writing

**Step 3: Constrain Who Can Authorize Agents**
1. Under **App Management Settings**, keep installation restricted to admins so individual users cannot connect an agent unilaterally
2. Prefer authorizing agents under a purpose-built service account with deliberately narrow channel membership rather than a broadly-permissioned admin
3. Pair with Information Barriers (see [1.5](#15-create-information-barriers-between-groups)) and AI channel restrictions (see [4.5](#45-restrict-slack-ai-access-to-sensitive-channels-canvases-and-lists)) so sensitive spaces stay out of reach regardless of the authorizing identity

**Step 4: Monitor Agent Activity**
1. Track the approved agents' API activity in audit logs (see [5.1](#51-enable-audit-logs))
2. Alert on sudden increases in message or file retrieval volume by an app token
3. Re-review every AI agent authorization quarterly and revoke unused ones

**Time to Complete:** ~1 hour for initial inventory and standard

#### Validation & Testing
**How to verify the control is working:**
1. Attempt to connect an unapproved MCP client or AI agent as a standard user -- installation should be blocked pending admin approval
2. Authorize an approved agent and confirm it can only retrieve content the authorizing identity can already access, including that it cannot read private channels the identity is not in
3. Confirm the agent's retrievals appear in audit logs attributable to its app token
4. Revoke the agent's authorization and verify subsequent queries fail

**Expected result:** Only reviewed AI agents hold MCP access, each scoped to a deliberately limited identity, with all retrieval activity visible in audit logs

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls over third-party access |
| **SOC 2** | CC9.2 | Vendor and business partner risk management |
| **NIST 800-53** | AC-6 | Least privilege |
| **NIST 800-53** | CM-7 | Least functionality |
| **ISO 27001** | A.5.19 | Information security in supplier relationships |

---

## 4. Data Security

### 4.1 Enable Data Loss Prevention (DLP)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.2 |
| NIST 800-53 | SC-8, SC-28 |

#### Description
Configure Slack's native DLP to detect and prevent sharing of sensitive information like credit card numbers, SSNs, API keys, and confidential documents.

#### Rationale
**Why This Matters:**
- Credentials and API keys are frequently shared in Slack
- Sensitive PII can be accidentally posted
- DLP provides automated protection

**Limitations:**
- Native DLP scans message text, text-based file types, and canvases -- but it does **not** scan non-text files (images, video, audio), files larger than 100 MB, or externally hosted files (for example, Google Drive or Box links posted into a channel)
- Cannot redact portions of messages (only tombstone the entire message)
- Consider third-party DLP for advanced capabilities, especially image and binary file inspection

#### Prerequisites
- Slack Enterprise plan (native DLP is available on Enterprise plans; no GovSlack or separate Compliance add-on is required) -- see [Slack data loss prevention](https://slack.com/help/articles/12914005852819-Slack-data-loss-prevention)
- DLP Admin role

#### ClickOps Implementation

**Step 1: Access DLP Settings**
1. Navigate to: **Enterprise Grid Admin** → **Security** → **Data Loss Prevention**
2. Click **Create rule**

**Step 2: Create DLP Rule**
1. Configure rule:
   - **Name:** Block credit card sharing
   - **Detection:** Use regex or predefined patterns
   - **Scope:** All workspaces or specific channels
   - **Actions:** Warn user, tombstone message, alert admin
2. Save rule

**Step 3: Configure Predefined Rules**
1. Enable predefined rules for:
   - Credit card numbers
   - Social Security numbers
   - Bank account numbers
   - Custom patterns (API keys, internal project names)

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="slack" section="4.1" %}

#### Validation & Testing
1. Send test message with fake credit card number
2. Verify DLP rule triggers
3. Confirm admin receives alert
4. Test that legitimate content is not blocked

---

### 4.2 Configure Message Retention Policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.4 |
| NIST 800-53 | SI-12, AU-11 |

#### Description
Configure message and file retention policies to balance compliance requirements with data minimization. Enable legal holds for litigation preservation.

#### Rationale
**Why This Matters:**
- Regulatory compliance may require specific retention periods
- Data minimization reduces breach impact
- Legal holds prevent destruction of relevant evidence

#### Prerequisites
- Slack Business+ or Enterprise Grid
- Defined retention requirements per regulation

#### ClickOps Implementation

**Step 1: Configure Default Retention**
1. Navigate to: **Slack Admin** → **Settings** → **Retention & Exports**
2. Configure workspace-wide defaults:
   - **Messages:** Keep all, or delete after X days
   - **Files:** Keep all, or delete after X days
3. Consider compliance requirements:
   - **FINRA:** 3-6 years
   - **HIPAA:** 6 years
   - **SOX:** 7 years

**Step 2: Configure Per-Channel Retention**
1. Override retention for specific channels
2. Shorter retention for informal channels
3. Longer retention for compliance-relevant channels

**Step 3: Enable Legal Holds**
1. Navigate to: **Security** → **Legal holds**
2. Create hold for specific users, channels, or date ranges
3. Legal holds override retention policies

**Time to Complete:** ~30 minutes

---

### 4.3 Enable Enterprise Key Management (EKM)

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12, SC-28 |

#### Description
Deploy Slack Enterprise Key Management to use your own AWS KMS keys for encrypting Slack messages and files, providing customer-controlled encryption.

#### Rationale
**Why This Matters:**
- Customer-managed KMS keys give your organization, not the vendor, ultimate control over the keys that decrypt messages and files
- Revoking key access instantly cuts off decryption during an incident, insider-threat event, or contract termination
- AWS CloudTrail key-access logging provides granular visibility into when and how Slack content is decrypted
- Satisfies data-sovereignty and regulatory mandates that require customer-held encryption keys for sensitive or regulated data

**Attack Prevented:** Provider-side data exposure, insider misuse, inability to revoke access during an incident, compliance gaps for regulated data

#### Prerequisites
- Slack Enterprise Grid
- AWS account with KMS
- Additional licensing for EKM

#### ClickOps Implementation

**Step 1: Set Up AWS KMS**
1. Create KMS key in AWS
2. Configure key policy for Slack access
3. Note key ARN

**Step 2: Configure EKM in Slack**
1. Navigate to: **Enterprise Grid Admin** → **Security** → **Encryption**
2. Click **Configure Enterprise Key Management**
3. Enter AWS KMS key ARN
4. Complete verification process

---

### 4.4 Govern Slack AI Feature Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 4.8 |
| NIST 800-53 | AC-3, CM-7, SC-28 |

#### Description
Decide deliberately which Slack AI features are available in your workspace rather than accepting the defaults. Under **Feature access**, each AI capability -- conversation summaries, AI search answers, recaps, translations, and file summaries -- can be set independently to **Everyone** or **No one**. This is a workspace permission surface that exists regardless of whether you license DLP, so a DLP-free workspace still needs an explicit decision here. See [Manage access to AI features in Slack](https://slack.com/help/articles/28244420881555-Manage-access-to-AI-features-in-Slack).

#### Rationale
**Why This Matters:**
- AI features read across the content a user can access and re-present it in condensed, easily-copied form, which changes the practical exposure of material that was technically readable but buried
- Feature access is independent of DLP licensing, so organizations without native DLP have no compensating control if AI features are simply left on
- Enabling features one at a time lets you allow low-risk capabilities (translations) while withholding high-risk ones (cross-channel search answers) instead of making a single all-or-nothing choice
- In August 2024, PromptArmor disclosed that an indirect prompt injection planted in a **public** channel could cause Slack AI to surface data from a **private** channel to the attacker via a crafted Markdown link -- and Slack characterized public-channel-wide ingestion as intended behavior. That combination means AI feature scope, not just channel permissions, defines your real exposure. See [Data exfiltration from Slack AI via indirect prompt injection](https://www.promptarmor.com/resources/data-exfiltration-from-slack-ai-via-indirect-prompt-injection)
- Regulated content subject to retention, residency, or eDiscovery obligations may be summarized into surfaces your existing tooling does not inspect

**Attack Prevented:** Indirect prompt injection driving AI-assisted data exfiltration, over-broad AI summarization of sensitive content, unreviewed AI processing of regulated data, silent expansion of exposure through default-on features

#### Prerequisites
- Workspace Owner or Admin access (Org Admin for org-wide enforcement)
- A plan that includes the AI features in question (see Appendix A)
- A documented position on which AI capabilities are acceptable for your data classification

#### ClickOps Implementation

**Step 1: Review Current AI Feature State**
1. Navigate to: **Slack Admin** → **Workspace settings** → **Roles & permissions** → **Feature access** → **AI**
2. Record the current setting for each AI feature before changing anything
3. Note which features are on by default -- defaults change as Slack ships new capabilities

**Step 2: Set Each Feature Deliberately**
1. For each AI capability, set access to **Everyone** or **No one** based on your data classification:
   - **Conversation summaries and recaps:** highest condensation of channel content
   - **AI search answers:** broadest reach across the content a user can access
   - **File summaries:** extends AI processing to document contents
   - **Translations:** generally lowest risk
2. Default to **No one** for any feature you have not explicitly assessed
3. Save and record the rationale for each decision

**Step 3: Establish a Re-Review Cadence**
1. Re-check this page after every major Slack release, since new AI features arrive with their own defaults
2. Assign an owner responsible for evaluating new AI capabilities before they are left enabled
3. Pair with channel-level restrictions (see [4.5](#45-restrict-slack-ai-access-to-sensitive-channels-canvases-and-lists)) where the plan supports it

**Time to Complete:** ~30 minutes

#### Validation & Testing
**How to verify the control is working:**
1. As a standard user, confirm that features set to **No one** do not appear in the Slack UI and cannot be invoked
2. Confirm that features set to **Everyone** behave as expected for an ordinary user
3. Re-open the Feature access page after a Slack release and verify no new AI feature has been enabled without review
4. Confirm the recorded rationale matches the live configuration during periodic access reviews

**Expected result:** Every Slack AI feature has an explicit, documented on or off decision, and no feature is enabled purely by default

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls over data processing features |
| **SOC 2** | CC6.7 | Restriction of information transmission and disclosure |
| **NIST 800-53** | CM-7 | Least functionality |
| **ISO 27001** | A.8.11 | Data masking and restriction of data exposure |
| **GDPR** | Art. 25 | Data protection by design and by default |

---

### 4.5 Restrict Slack AI Access to Sensitive Channels, Canvases, and Lists

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 3.12 |
| NIST 800-53 | AC-3, AC-4, SC-28 |

#### Description
On Enterprise+ plans, exclude specific channels, canvases, and lists from Slack AI processing so that highly sensitive spaces -- legal, M&A, incident response, HR investigations -- are never ingested into summaries, recaps, or search answers. Restriction can be applied per-channel by its owner or centrally across the organization. See [Restrict AI access to certain channels, canvases and lists](https://slack.com/help/articles/47421816860947-Restrict-AI-access-to-certain-channels-canvases-and-lists).

#### Rationale
**Why This Matters:**
- Feature-level governance (see [4.4](#44-govern-slack-ai-feature-access)) is all-or-nothing per capability; channel-level restriction is what lets you keep AI broadly useful while carving out the handful of spaces where any AI processing is unacceptable
- The PromptArmor disclosure showed that content reachable by Slack AI can be surfaced through injected instructions the user never wrote, so removing a channel from AI's reach is a stronger guarantee than trusting the model's behavior. Restriction is the control that reduces that residual risk to zero for the spaces you designate
- Legal privilege, deal confidentiality, and investigation integrity depend on content not being reproduced into derived summaries visible to a wider audience
- Applying restriction centrally rather than relying on individual channel owners makes the control auditable and survives ownership changes

**Documented Limitation:** This setting restricts AI **read** access to the designated channel, canvas, or list. It is a scoping control over what AI ingests -- treat it as such, and do not assume it changes any other aspect of how the content is stored, retained, or shared.

**Attack Prevented:** Indirect prompt injection reaching privileged content, AI-derived leakage of legal or deal-sensitive material, exposure of investigation channels through summarization, residual AI ingestion after channel ownership changes

#### Prerequisites
- Slack Enterprise+ plan
- Org Owner or Org Admin access for organization-wide restriction
- A classified inventory of channels, canvases, and lists that must be excluded from AI

#### ClickOps Implementation

**Step 1: Identify Channels to Restrict**
1. Build the list of spaces that must never be AI-processed: legal and privileged channels, M&A and deal rooms, security incident channels, HR investigation channels, and any canvas or list holding regulated data
2. Confirm each has a named owner and a documented classification

**Step 2: Restrict at the Channel, Canvas, or List Level**
1. Open the channel, canvas, or list
2. Go to **Settings** → **AI use**
3. Select **Restrict** to exclude it from Slack AI processing
4. Repeat for each item on the inventory

**Step 3: Apply Organization-Wide Controls**
1. Navigate to: **Tools & settings** → **Organization settings** → **Roles & permissions**
2. Apply AI access restrictions centrally so the control does not depend on individual channel owners
3. Record the restricted inventory in your compliance control documentation

**Step 4: Maintain the Inventory**
1. Add AI restriction to the checklist for creating any new privileged or incident channel
2. Re-review the restricted list quarterly and whenever a new sensitive workstream begins
3. Verify restriction survives channel renames and ownership transfers

**Time to Complete:** ~1 hour for initial inventory and application

#### Validation & Testing
**How to verify the control is working:**
1. In a restricted channel, attempt to generate a summary or recap and confirm the AI feature is unavailable or returns nothing
2. From an AI search prompt, query for a distinctive phrase that exists only in a restricted channel and confirm it is not returned to a user who would otherwise have access
3. Confirm an unrestricted control channel still returns AI results, proving the restriction is targeted rather than global
4. Rename a restricted channel and re-run the checks to confirm the restriction persists

**Expected result:** Designated channels, canvases, and lists produce no AI summaries, recaps, or search answers, while the rest of the workspace retains AI functionality

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls over sensitive data |
| **SOC 2** | CC6.7 | Restriction of information transmission and disclosure |
| **NIST 800-53** | AC-4 | Information flow enforcement |
| **ISO 27001** | A.8.12 | Data leakage prevention |
| **HIPAA** | 164.312(a)(1) | Access control over protected health information |

---

## 5. Monitoring & Detection

### 5.1 Enable Audit Logs

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-3, AU-6 |

#### Description
Enable and export Slack audit logs for security monitoring, incident investigation, and compliance. Integrate with SIEM for automated threat detection.

#### Rationale
**Why This Matters:**
- Audit logs capture admin actions, authentication events, and data access
- Essential for incident investigation
- Required for most compliance frameworks

#### Prerequisites
- Slack Enterprise Grid
- SIEM or log management platform

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Enterprise Grid Admin** → **Security** → **Audit logs**
2. Review available log categories:
   - User actions
   - Workspace settings
   - App installations
   - File access
   - Channel management

**Step 2: Configure Log Export**
1. Click **Export logs**
2. Configure export destination:
   - Amazon S3 bucket
   - Direct API integration with SIEM
3. Set export frequency (real-time or scheduled)

**Step 3: Integrate with SIEM**
1. Use Slack Audit Logs API for real-time streaming
2. Configure alerts for critical events

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="slack" section="5.1" %}

#### Key Events to Monitor

| Event | Description | Detection Use Case |
|-------|-------------|-------------------|
| `user_login_failed` | Failed authentication | Brute force attempts |
| `role_change_to_admin` | Admin role assigned | Privilege escalation |
| `app_installed` | New app installed | Malicious app detection |
| `file_downloaded` | File downloaded | Data exfiltration |
| `channel_created` | New channel created | Shadow IT detection |
| `message_tombstoned` | Message deleted by DLP | Policy violations |

---

## 6. Third-Party Integration Security

### 6.1 Integration Risk Assessment Matrix

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **Data Access** | Read channel list only | Read messages in public channels | Read all messages + files |
| **OAuth Scopes** | Limited scopes | Broad read access | Write access, admin scopes |
| **Data Retention** | No data storage | Temporary storage | Permanent storage |
| **Vendor Security** | SOC 2 Type II + ISO | SOC 2 Type I | No certification |

### 6.2 Common Integrations and Recommended Controls

#### Obsidian Security
**Data Access:** Read (messages, channels, users, audit logs)
**Recommended Controls:**
- ✅ Use dedicated bot user
- ✅ Grant minimum required OAuth scopes
- ✅ Review access quarterly
- ✅ Monitor API usage via audit logs

#### Zoom
**Data Access:** Low (meeting links, calendar)
**Recommended Controls:**
- ✅ Limit to meeting creation only
- ✅ Disable automatic meeting recording sharing

#### Google Drive / Dropbox
**Data Access:** Medium (file sharing)
**Recommended Controls:**
- ✅ Control which files can be shared
- ✅ Apply DLP to file sharing
- ✅ Monitor for sensitive file sharing

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Slack Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | SSO/SAML authentication | [1.1](#11-enable-saml-single-sign-on-sso) |
| CC6.1 | App approval controls | [3.1](#31-restrict-app-installation-and-approval) |
| CC6.2 | Admin role restrictions | [1.3](#13-restrict-workspace-admin-roles) |
| CC6.3 | Information barriers between groups | [1.5](#15-create-information-barriers-between-groups) |
| CC6.6 | Slack Connect controls | [3.2](#32-manage-slack-connect-external-collaboration) |
| CC6.7 | Slack AI feature and channel restrictions | [4.4](#44-govern-slack-ai-feature-access), [4.5](#45-restrict-slack-ai-access-to-sensitive-channels-canvases-and-lists) |
| CC7.2 | Audit logging | [5.1](#51-enable-audit-logs) |
| CC9.2 | AI agent and MCP vendor governance | [3.3](#33-govern-slack-mcp-server-and-ai-agent-access) |

### NIST 800-53 Rev 5 Mapping

| Control | Slack Control | Guide Section |
|---------|---------------|---------------|
| IA-2 | SAML SSO | [1.1](#11-enable-saml-single-sign-on-sso) |
| AC-2 | SCIM provisioning | [1.2](#12-configure-scim-user-provisioning) |
| AC-4 | Information flow enforcement | [1.5](#15-create-information-barriers-between-groups), [4.5](#45-restrict-slack-ai-access-to-sensitive-channels-canvases-and-lists) |
| AC-6(1) | Least privilege admin | [1.3](#13-restrict-workspace-admin-roles) |
| CM-7 | Least functionality | [3.3](#33-govern-slack-mcp-server-and-ai-agent-access), [4.4](#44-govern-slack-ai-feature-access) |
| SC-28 | DLP / EKM | [4.1](#41-enable-data-loss-prevention-dlp), [4.3](#43-enable-enterprise-key-management-ekm) |
| AU-2 | Audit logging | [5.1](#51-enable-audit-logs) |

### HIPAA Security Rule Mapping

| Requirement | Slack Control | Guide Section |
|-------------|---------------|---------------|
| 164.312(d) | SSO authentication | [1.1](#11-enable-saml-single-sign-on-sso) |
| 164.312(b) | Audit controls | [5.1](#51-enable-audit-logs) |
| 164.312(c)(1) | Integrity controls | [4.1](#41-enable-data-loss-prevention-dlp) |
| 164.312(e)(1) | Transmission security | [4.3](#43-enable-enterprise-key-management-ekm) |

---

## Appendix A: Edition/Tier Compatibility

As of **August 17, 2025**, Slack's plan lineup is **Free, Pro, Business+, and Enterprise+** (Enterprise+ is the plan formerly positioned as Enterprise Grid). The standalone Slack AI add-on was discontinued, and AI capabilities -- AI search, recaps, translations, and file summaries -- are now included in Business+ and above rather than sold separately. See [Updates to feature availability and pricing for Slack plans](https://slack.com/help/articles/39264531104275-Updates-to-feature-availability-and-pricing-for-Slack-plans).

| Control | Free | Pro | Business+ | Enterprise+ |
|---------|------|-----|-----------|-------------|
| 2FA (local) | ✅ | ✅ | ✅ | ✅ |
| SAML SSO | ❌ | ❌ | ✅ | ✅ |
| SCIM Provisioning | ❌ | ❌ | ❌ | ✅ |
| App Management | Basic | Basic | ✅ | ✅ |
| Data Loss Prevention | ❌ | ❌ | ❌ | ✅ |
| Enterprise Key Management | ❌ | ❌ | ❌ | ✅ |
| Custom Retention | ❌ | ❌ | ✅ | ✅ |
| Audit Logs API | ❌ | ❌ | ❌ | ✅ |
| Information Barriers | ❌ | ❌ | ❌ | ✅ |
| AI features (search, recaps, translations, file summaries) | ❌ | ❌ | ✅ | ✅ |
| AI feature access controls (Feature access → AI) | ❌ | ❌ | ✅ | ✅ |
| Restrict AI access to channels, canvases, lists | ❌ | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Slack Documentation:**
- [Trust Center / Security](https://slack.com/trust/security)
- [Help Center](https://slack.com/help)
- [Security Tips to Protect Your Workspace](https://slack.com/help/articles/115004155306-Security-tips-to-protect-your-workspace)
- [Security Practices](https://slack.com/security-practices)
- [Manage Single Sign-On Settings](https://slack.com/help/articles/220403548-Manage-single-sign-on-settings)
- [Introduction to Enterprise Grid](https://slack.com/resources/why-use-slack/slack-enterprise-grid)
- [Enterprise Grid Admin Guide](https://slack.com/help/articles/360004150931)

**API & Developer Tools:**
- [Slack API Documentation](https://docs.slack.dev/apis/)
- [Legacy API Reference](https://api.slack.com/)
- [Audit Logs API](https://api.slack.com/admins/audit-logs)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO 27001, ISO 27017, ISO 27018, APEC PRP, APEC CBPR -- via [Trust Center / Compliance](https://slack.com/trust/compliance)
- [HIPAA Compliance on Slack](https://slack.com/trust/compliance/hipaa)
- [FedRAMP Moderate (Slack), FedRAMP High JAB (GovSlack)](https://slack.com/trust/compliance/fedramp)
- GDPR, CCPA/CPRA, FINRA compliant -- via [Compliance Resources](https://slack.com/trust/compliance)

**Security Incidents:**
- (2022-12) Stolen Slack employee tokens used to access externally hosted GitHub repositories. No customer data affected.
- (2022-07) A vulnerability transmitted hashed user passwords to other workspace members; approximately 0.5% of users required password resets.
- (2024-07) Credential-stuffing attack using leaked credentials granted unauthorized access to employee accounts and sensitive corporate data. Disclosed July 12, 2024.
- (2024-08) PromptArmor disclosed an indirect prompt injection against Slack AI: instructions planted in a public channel caused Slack AI to exfiltrate private-channel data through a crafted Markdown link. Slack characterized Slack AI's ingestion of public-channel content as intended behavior, making it a residual risk to be managed through AI feature and channel restrictions ([4.4](#44-govern-slack-ai-feature-access), [4.5](#45-restrict-slack-ai-access-to-sensitive-channels-canvases-and-lists)) rather than a patched vulnerability. [Details](https://www.promptarmor.com/resources/data-exfiltration-from-slack-ai-via-indirect-prompt-injection)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-03 | 0.2.0 | draft | Add Information Barriers (1.5), MCP/AI agent governance (3.3), Slack AI feature access (4.4), and AI channel restriction (4.5); correct DLP plan prerequisite and file-scanning scope; note non-Marketplace app rate limits; update plan matrix to post-Aug 2025 lineup | Claude Code (Sonnet 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, DLP, retention, and app controls | Claude Code (Opus 4.5) |
| 2026-02-19 | 0.1.1 | draft | Extract inline code to Code Packs (SDK, Terraform, API) | Claude Code (Opus 4.6) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
