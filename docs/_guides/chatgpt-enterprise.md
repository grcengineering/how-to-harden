---
layout: guide
title: "ChatGPT Enterprise Hardening Guide"
vendor: "OpenAI"
slug: "chatgpt-enterprise"
tier: "1"
category: "AI/ML Platform"
description: "Enterprise AI security hardening for ChatGPT, SSO configuration, data privacy, admin controls, and workspace agent governance"
version: "0.3.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

ChatGPT Enterprise is OpenAI's enterprise-grade AI assistant serving organizations that require enhanced security, privacy, and administrative controls. With AI adoption accelerating across enterprises, properly securing ChatGPT Enterprise is critical to prevent data leakage, maintain compliance, and ensure responsible AI usage. Unlike consumer versions, Enterprise provides SOC 2 Type II compliance, data isolation, and guarantees that prompts and outputs are not used for model training.

On April 22, 2026, OpenAI announced **[Workspace Agents in ChatGPT](https://openai.com/index/introducing-workspace-agents-in-chatgpt/)** — cloud-resident agents that can connect to enterprise apps (Slack, Google Drive, SharePoint, Gmail, Calendar, GitHub, Jira, Confluence, and others), run on schedules, and complete multi-step workflows on a user's behalf. Workspace agents are an evolution of custom GPTs and inherit a substantially broader risk surface because they can take **actions** in connected systems, not just answer questions. OpenAI's *Workspace Agents Security Overview* PDF (April 29, 2026) was the original authoritative reference for the security model but **has since been removed (the URL now returns HTTP 404)**; the canonical enterprise admin documentation now lives at **[learn.chatgpt.com/docs/enterprise](https://learn.chatgpt.com/docs/enterprise/governance.md)** (Administration, Governance, Compliance API, Roles and workspace permissions, Apps and connectors) with developer surfaces at **[developers.openai.com](https://developers.openai.com/workspace-agents/authentication.md)**. Claims in Section 6 that traced only to the retired PDF are annotated accordingly.

### Intended Audience
- Security engineers managing AI tools
- IT administrators configuring ChatGPT Enterprise
- GRC professionals assessing AI compliance
- Third-party risk managers evaluating AI tools

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers ChatGPT Enterprise security configurations including SSO/SAML, user management, data privacy controls, GPT restrictions, and compliance settings.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Data Security & Privacy](#2-data-security--privacy)
3. [GPT & App Controls](#3-gpt--app-controls)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Third-Party Integration Security](#5-third-party-integration-security)
6. [Workspace Agents Hardening](#6-workspace-agents-hardening)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML-based SSO to authenticate ChatGPT Enterprise users through your corporate identity provider (Okta, Azure AD, OneLogin). This centralizes authentication and enables MFA enforcement.

#### Rationale
**Why This Matters:**
- Centralizes authentication and user lifecycle management
- Enables Conditional Access and MFA through IdP
- Automatic deprovisioning when users leave organization
- Eliminates standalone ChatGPT passwords

**Attack Prevented:** Credential theft, unauthorized access, orphaned accounts

#### Prerequisites
- ChatGPT Enterprise subscription
- SAML 2.0 compatible identity provider
- Workspace Owner access

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **ChatGPT Admin Console** → **Settings** → **Authentication**
2. Click **Configure SSO**

**Step 2: Configure SAML**
1. Enter Identity Provider details:
   - **SSO URL:** Your IdP's SSO endpoint
   - **Entity ID:** IdP entity ID
   - **Certificate:** X.509 certificate from IdP
2. Download ChatGPT's Service Provider metadata for IdP configuration
3. Map user attributes (email, name)

**Step 3: Configure IdP (Example: Okta)**
1. In Okta Admin: **Applications** → **Add Application**
2. Select SAML 2.0 integration
3. Enter ChatGPT's ACS URL and Entity ID
4. Configure attribute statements:
   - email → user.email
   - name → user.displayName
5. Assign users/groups

**Step 4: Enable SSO Enforcement**
1. Return to ChatGPT Authentication settings
2. Enable **Require SSO for all users**
3. Test login before enforcing

**Time to Complete:** ~1 hour

#### Validation & Testing
1. Test SSO sign-in through IdP
2. Verify MFA is enforced (via IdP)
3. Confirm direct password login is disabled
4. Test user deprovisioning from IdP

---

### 1.2 Enable Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Enforce multi-factor authentication for all ChatGPT Enterprise users. With SSO, MFA should be enforced through your identity provider. For non-SSO deployments, enable ChatGPT's native TOTP-based MFA.

#### Rationale
**Why This Matters:**
- Passwords alone are routinely phished, reused, and stolen; a second factor stops an attacker who already holds valid credentials
- ChatGPT Enterprise accounts hold conversation history, uploaded files, and connected-app access — a single takeover can expose all of it
- Enforcing MFA at the IdP applies one consistent policy across every SaaS app, including ChatGPT, rather than relying on per-app toggles

**Attack Prevented:** Credential stuffing, password reuse, phishing, account takeover

#### ClickOps Implementation

**Option A: MFA via SSO (Recommended)**
1. Configure MFA in your identity provider
2. Create Conditional Access policy requiring MFA for ChatGPT app
3. All ChatGPT access will require MFA through IdP

**Option B: Native MFA (Non-SSO)**
1. Navigate to: **Admin Console** → **Settings** → **Authentication**
2. Enable **Require multi-factor authentication**
3. Users will be prompted to enroll in TOTP-based MFA

---

### 1.3 Configure SCIM User Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Enable SCIM (System for Cross-domain Identity Management) for automatic user provisioning and deprovisioning synced with your identity provider.

#### Rationale
**Why This Matters:**
- Automatic user lifecycle management
- Immediate deprovisioning when employees leave
- Eliminates orphaned accounts
- Ensures consistent group memberships

**Attack Prevented:** Orphaned-account exploitation after offboarding, stale access via manual deprovisioning gaps, group-membership drift.

#### ClickOps Implementation

**Step 1: Enable SCIM**
1. Navigate to: **Admin Console** → **Settings** → **User provisioning**
2. Click **Enable SCIM**
3. Copy the SCIM endpoint URL and generate API token

**Step 2: Configure IdP**
1. In your IdP, configure SCIM integration
2. Enter ChatGPT's SCIM endpoint URL
3. Enter the API token for authentication
4. Enable provisioning actions:
   - Create users
   - Update users
   - Deactivate users
5. Map user attributes

**Time to Complete:** ~30 minutes

---

### 1.4 Implement Role-Based Access Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Configure role-based access using ChatGPT Enterprise's three role types: Owner, Admin, and Member. Limit Owner and Admin roles to essential personnel.

#### Rationale
**Why This Matters:**
- Owners have full access to all settings and data
- Excessive admin privileges increase risk
- Members should be the default role for most users

**Attack Prevented:** Privilege escalation via over-assigned admin roles, full-workspace takeover from a single compromised Owner account.

#### ClickOps Implementation

**Step 1: Review Current Roles**
1. Navigate to: **Admin Console** → **Members**
2. Review current role assignments
3. Document Owners and Admins

**Step 2: Implement Least Privilege**
1. Maintain minimum Owners (1-2 maximum)
2. Assign Admin role only for user management needs
3. Use Member role for all regular users

**Role Definitions:**

| Role | Capabilities |
|------|-------------|
| **Owner** | Full workspace control, billing, SSO configuration |
| **Admin** | User management, usage insights, settings |
| **Member** | Standard ChatGPT access, no admin functions |

---

## 2. Data Security & Privacy

### 2.1 Understand Data Privacy Guarantees

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SC-8, SC-28 |

#### Description
ChatGPT Enterprise provides specific data privacy guarantees that differentiate it from consumer versions. Understanding these guarantees is essential for risk assessment.

#### Rationale
**Why This Matters:**
- Risk and compliance teams cannot approve a tool whose data handling they have not validated against the contractual guarantees
- The commitment that inputs and outputs are excluded from model training is what makes Enterprise acceptable for confidential workloads where the consumer edition is not
- Documenting the encryption, ownership, and retention commitments gives auditors the evidence trail required for SOC 2, ISO 27001, and vendor reviews

**Attack Prevented:** Inadvertent data-for-training leakage, unmanaged shadow use of consumer ChatGPT, compliance gaps from unverified vendor claims

#### Key Privacy Features

| Feature | ChatGPT Enterprise | ChatGPT Consumer |
|---------|-------------------|------------------|
| **Training on Data** | ❌ Not used for training | ✅ May be used |
| **Data Encryption at Rest** | ✅ AES-256 | ✅ AES-256 |
| **Data Encryption in Transit** | ✅ TLS 1.2+ | ✅ TLS 1.2+ |
| **SOC 2 Type II** | ✅ Certified | ❌ Not applicable |
| **Enterprise Key Management** | ✅ Available | ❌ Not available |
| **Data Retention Control** | ✅ Configurable | ❌ Standard retention |

#### Data Guarantees
According to OpenAI's Enterprise Privacy commitments:
- **Inputs and outputs are not used for training** OpenAI models
- Organizations **retain ownership** of their data
- Data is encrypted **in transit (TLS 1.2+)** and **at rest (AES-256)**
- Enterprise customers can configure **data retention periods**

---

### 2.2 Configure Data Retention Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.4 |
| NIST 800-53 | SI-12, AU-11 |

#### Description
Configure data retention policies to balance compliance requirements with data minimization principles. Shorter retention reduces breach impact.

#### Rationale
**Why This Matters:**
- Data that no longer exists cannot be stolen, subpoenaed, or leaked — shorter retention directly shrinks the breach blast radius
- GDPR mandates data minimization while sectors such as financial services mandate minimum retention; an explicit policy reconciles the two
- Indefinite conversation storage accumulates sensitive prompts and uploaded files with no expiry, expanding exposure for no business benefit

**Attack Prevented:** Excessive data exposure on breach, retention-policy compliance violations, e-discovery over-collection

#### ClickOps Implementation

**Step 1: Access Retention Settings**
1. Navigate to: **Admin Console** → **Settings** → **Data controls**
2. Click **Retention policy**

**Step 2: Configure Retention**
1. Set conversation retention period:
   - **Indefinite:** Conversations kept until user deletes
   - **90 days:** Auto-delete after 90 days
   - **30 days:** Auto-delete after 30 days (most restrictive)
2. Consider compliance requirements:
   - **FINRA:** May require longer retention for audit trails
   - **GDPR:** Supports data minimization with shorter retention

**Time to Complete:** ~15 minutes

---

### 2.3 Enable Enterprise Key Management (EKM)

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12, SC-28 |

#### Description
Deploy Enterprise Key Management to use your own encryption keys for ChatGPT data, providing customer-controlled encryption.

#### Rationale
**Why This Matters:**
- Customer-managed keys let your organization revoke OpenAI's access to encrypted data unilaterally, an essential control for highly regulated workloads
- Key rotation and access logging stay under your governance rather than depending solely on the provider's internal controls
- Holding the keys enables a cryptographic-shredding response — destroying the key renders the stored data unrecoverable on demand

**Attack Prevented:** Provider-side data exposure, inability to revoke access during an incident, key-management compliance gaps

#### Prerequisites
- ChatGPT Enterprise with EKM add-on
- AWS KMS or compatible key management system

#### ClickOps Implementation

**Step 1: Contact OpenAI**
1. Work with your OpenAI account team to enable EKM
2. Receive EKM configuration instructions

**Step 2: Configure Key Management**
1. Create encryption key in your KMS
2. Configure key policy for OpenAI access
3. Provide key ARN to OpenAI for configuration

---

### 2.4 Establish Acceptable Use Policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.2 |
| NIST 800-53 | PL-4 |

#### Description
Create and enforce acceptable use policies that define what data can and cannot be submitted to ChatGPT Enterprise.

#### Rationale
**Why This Matters:**
- Users may inadvertently submit sensitive data
- Even with Enterprise privacy, minimizing exposure is safest
- Clear policies set expectations and enable enforcement

**Attack Prevented:** Inadvertent disclosure of PII/PHI/credentials into prompts, unenforceable shadow use, compliance violations from ungoverned data submission.

#### Policy Recommendations

**Prohibited Data Types:**
- Personally Identifiable Information (PII)
- Protected Health Information (PHI)
- Payment Card Industry (PCI) data
- Credentials, API keys, passwords
- Proprietary source code (without approval)
- Trade secrets and confidential business records

**Approved Use Cases:**
- General research and information gathering
- Writing assistance (non-confidential content)
- Code explanation and debugging (sanitized)
- Brainstorming and ideation

#### Implementation
1. Document acceptable use policy
2. Require user acknowledgment during onboarding
3. Include in security awareness training
4. Integrate with DLP tools if available

---

## 3. GPT & App Controls

### 3.1 Restrict Third-Party GPT Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | AC-3, CM-7 |

#### Description
Control which third-party extensions can run in your organization. The admin model has moved on from "GPTs / Apps / Plugins" console pages: the current model governs **plugins, bundled skills, and connectors** across **six named control boundaries** — ChatGPT workspace, Local clients, Codex cloud, Platform API, Plugins, and Connected systems — managed at `chatgpt.com/admin/settings` and `chatgpt.com/admin/ca` ("Workspace apps"). Sources: [Apps and connectors](https://learn.chatgpt.com/docs/enterprise/apps-and-connectors.md), [Roles and workspace permissions](https://learn.chatgpt.com/docs/enterprise/roles-and-workspace-permissions.md).

#### Rationale
**Why This Matters:**
- Third-party plugins and connectors may have different data handling practices than your workspace's contractual guarantees
- Extensions can access conversation data and connected-system data based on their configuration
- Restricting to an approved allowlist reduces data exposure risk across all six control boundaries, not just the chat surface

**Attack Prevented:** Data exfiltration through unvetted third-party extensions, unapproved conversation-data access, shadow extension sprawl.

#### ClickOps Implementation

**Step 1: Access Workspace App Controls**
1. Navigate to: `chatgpt.com/admin/settings` and `chatgpt.com/admin/ca` (**Workspace apps**)
2. Review the enablement state of plugins, bundled skills, and connectors for each control boundary

**Step 2: Configure Extension Policies**
1. **Third-party plugins/connectors:** keep disabled by default; enable per-item with a documented business case
2. **Organization-built items:** enable only what your teams actually publish and maintain
3. Apply the same decision to each boundary where the extension can run (workspace, local clients, Codex cloud)

**Step 3: Allowlist Approved Extensions (if needed)**
1. If specific third-party extensions are required:
   - Review the vendor's privacy policy and data handling
   - Add to the approved list
   - Document business justification

**Time to Complete:** ~15 minutes

---

### 3.2 Control App and Plugin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | AC-3 |

#### Description
Control which ChatGPT features and integrations are available to users. All apps are disabled by default in Enterprise.

> **Console model change:** apps are now governed under the **plugins + bundled skills + connectors** model at `chatgpt.com/admin/settings` / `chatgpt.com/admin/ca` ("Workspace apps"). Per-app **Action control** and the **newly-added-actions** deny toggle survive but have moved into this surface. Source: [Apps and connectors](https://learn.chatgpt.com/docs/enterprise/apps-and-connectors.md).

#### Rationale
**Why This Matters:**
- Each enabled capability — web browsing, code interpreter, file uploads — adds an independent data-exposure or execution surface that must be justified
- Web browsing can send internal queries to external sites and file uploads move sensitive documents into the platform; both warrant deliberate approval
- Enabling only the features the business actually needs keeps the attack surface minimal and the data flows auditable

**Attack Prevented:** Data exfiltration through outbound browsing, oversharing via uploads, unnecessary code-execution surface

#### ClickOps Implementation

**Step 1: Access App Settings**
1. Navigate to: **Admin Console** → **Settings** → **Apps**

**Step 2: Configure App Access**
1. Review each app category:
   - **Code Interpreter:** Enable/disable code execution
   - **Web Browsing:** Enable/disable internet access
   - **Image Generation (DALL-E):** Enable/disable image creation
   - **File Uploads:** Enable/disable file analysis
2. Enable only features required for business use
3. Consider security implications of each:
   - Web browsing may expose queries externally
   - File uploads increase data exposure surface

---

### 3.3 Configure Custom Instructions

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.2 |
| NIST 800-53 | PL-4 |

#### Description
Set organization-wide custom instructions that apply to all conversations, embedding security reminders and usage guidelines.

#### Rationale
**Why This Matters:**
- Workspace-wide instructions deliver consistent security guidance at the point of use, when users are most likely to act on it
- Embedding reminders not to paste secrets, PII, or proprietary code reinforces the acceptable-use policy in every session automatically
- Centrally managed instructions cannot be quietly disabled by individual users, unlike one-time training

**Attack Prevented:** Inadvertent disclosure of sensitive data, inconsistent user behavior, acceptable-use policy drift

#### ClickOps Implementation

**Step 1: Access Custom Instructions**
1. Navigate to: **Admin Console** → **Settings** → **Custom instructions**

**Step 2: Configure Organization Instructions**
1. Add security-aware instructions such as:

2. Save and apply to all users

---

## 4. Monitoring & Compliance

### 4.1 Enable Usage Analytics

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-6 |

#### Description
Monitor ChatGPT Enterprise usage through the admin console analytics dashboard for security visibility and compliance reporting.

#### Rationale
**Why This Matters:**
- You cannot detect misuse or anomalous activity in a tool you are not watching; analytics establish the baseline of normal behavior
- Sudden spikes in message volume, accounts created outside provisioning, or unexpected feature usage are early indicators of compromise or policy violation
- Exported usage data is the evidence auditors expect that the deployment is actively monitored, not merely configured

**Attack Prevented:** Undetected account abuse, shadow usage, unmonitored data movement

#### ClickOps Implementation

**Step 1: Access Analytics**
1. Navigate to: **Admin Console** → **Analytics**

**Step 2: Review Key Metrics**
- Active users over time
- Message volume
- Feature usage (code interpreter, web browsing, etc.)
- User adoption trends

**Step 3: Export for Compliance**
1. Export usage data for compliance audits
2. Integrate with enterprise reporting tools

---

### 4.2 Integrate with Microsoft Purview

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SC-8 |

#### Description
For organizations using Microsoft 365, integrate ChatGPT Enterprise with Microsoft Purview for advanced data governance and compliance controls.

#### Rationale
**Why This Matters:**
- Purview extends your existing M365 sensitivity labels and DLP policies to AI interactions, closing the gap where ChatGPT would otherwise be an ungoverned data channel
- A single governance plane across email, files, and AI prevents the inconsistent rules that attackers and careless users exploit
- Centralizing AI activity in the Purview compliance dashboard supports investigations and regulatory reporting from one place

**Attack Prevented:** Sensitive data leaving M365 governance, DLP blind spots in AI chats, fragmented compliance reporting

#### Prerequisites
- Microsoft 365 E5 or Purview add-on
- ChatGPT Enterprise

#### Implementation
1. Configure Purview connector for ChatGPT
2. Apply sensitivity labels to ChatGPT content
3. Enable DLP policies for AI interactions
4. Review Purview compliance dashboard for AI activity

> **Partner ecosystem:** Purview is now one of **18 named Compliance Platform partner integrations** with per-partner setup guides — Concentric AI, CrowdStrike, Cyberhaven, Enkrypt AI, Forcepoint, Global Relay, Microsoft Purview, Netskope, Palo Alto Networks, Relativity, Smarsh, Teleskope, Tenable (formerly Apex Security), Theta Lake, TrojAI, Varonis, Zenity, and Zscaler. If your DLP/SIEM/eDiscovery stack is on this list, use the vendor's supported integration rather than a custom puller. Source: [OpenAI Compliance Platform](https://help.openai.com/en/articles/9261474-compliance-api-for-chatgpt-enterprise-edu-and-chatgpt-for-teachers).

---

### 4.3 Implement Audit Trail Reviews

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | AU-6, AU-7 |

#### Description
Establish regular audit trail reviews to detect policy violations, unusual usage patterns, and potential security incidents.

#### Rationale
**Why This Matters:**
- Logs and analytics only add value when someone reviews them on a cadence; an unread audit trail catches nothing
- Scheduled weekly, monthly, and quarterly reviews surface drift — new admins, stale SSO/SCIM config, retention violations — before it becomes an incident
- A documented review rhythm is itself an auditable control that demonstrates continuous oversight to assessors

**Attack Prevented:** Undetected privilege creep, configuration drift, slow incident discovery

#### Implementation

**Weekly Reviews:**
- Review analytics for unusual activity spikes
- Check for new user additions outside normal provisioning
- Monitor feature usage trends

**Monthly Reviews:**
- Audit admin role assignments
- Review SSO/SCIM configuration integrity
- Validate retention policy compliance

**Quarterly Reviews:**
- Comprehensive access review
- Policy compliance assessment
- Update acceptable use policies as needed

---

## 5. Third-Party Integration Security

### 5.1 Integration Risk Assessment

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **Data Exposure** | No conversation access | Limited conversation access | Full conversation access |
| **External Services** | No external calls | Limited external APIs | Full internet access |
| **Data Persistence** | No data storage | Temporary storage | Permanent storage |

### 5.2 Approved Integration Patterns

#### Identity Provider Integration (Recommended)
**Data Access:** Authentication only
**Controls:**
- ✅ Configure SAML SSO
- ✅ Enable SCIM provisioning
- ✅ Apply IdP Conditional Access policies

#### Microsoft Purview Integration (Recommended for M365)
**Data Access:** Metadata and classification
**Controls:**
- ✅ Apply sensitivity labels
- ✅ Enable DLP scanning
- ✅ Review compliance reports

#### Compliance Platform Partner Integrations
**Data Access:** Compliance log events (pull model)
**Controls:**
- ✅ Prefer one of OpenAI's 18 supported DLP/SIEM/eDiscovery partner integrations (see [4.2](#42-integrate-with-microsoft-purview)) over custom log pullers where your stack matches
- ✅ Scope the partner's Compliance API key per Control 6.6 and enforce the IP allowlist

---

## 6. Workspace Agents Hardening

**Workspace agents** are cloud-resident agents introduced by OpenAI on **April 22, 2026** as the successor to custom GPTs. They help teams turn repeatable work into shared agents that gather context, follow team processes, take action across approved tools, and keep work moving in ChatGPT or Slack. Agents can run in the cloud on schedules, use connected apps and files, and ask for approval when needed.

> **Source note:** OpenAI's *Workspace Agents Security Overview* PDF (April 29, 2026) — previously this section's primary source — **now returns HTTP 404 and is no longer re-verifiable**. Claims in this section that traced only to that PDF (the five RBAC dimensions, ~10-minute log windows, p99 < 30 minutes, at-least-once delivery, the per-event-family names, the six-step pre-launch checklist) are annotated where they appear. The live authoritative docs are [learn.chatgpt.com/docs/enterprise](https://learn.chatgpt.com/docs/enterprise/governance.md) and the [workspace agents help article](https://help.openai.com/en/articles/20001143-chatgpt-workspace-agents-for-enterprise-and-business).

> **Status update (2026-08):** workspace agents are **no longer described as a research preview**. OpenAI's current help documentation describes a shipped feature set — templates, an agent builder, Preview, schedules, ChatGPT/Slack/API channels, a Team directory, and "Publish to [organization] directory" — and states the feature is **off by default at launch for ChatGPT Enterprise workspaces**. Note also: **disabling Workspace Agents for a user or role also disables the Workspace Agents plugin in Codex** — there is no separate Codex-only toggle. Source: [ChatGPT workspace agents for Enterprise and Business](https://help.openai.com/en/articles/20001143-chatgpt-workspace-agents-for-enterprise-and-business).

The full set of governance controls in this section (RBAC, app/action controls, Compliance Platform export) is available on **ChatGPT Enterprise and Edu**; Business and Teachers tiers have a more limited admin surface. The feature is **disabled by default** at the workspace level; admins must enable it per role.

### Why Workspace Agents Need Their Own Hardening Section

Unlike chat conversations, workspace agents combine three properties that map directly onto Simon Willison's [lethal trifecta](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/):

1. **Access to private data** — through connected apps such as Gmail, Drive, SharePoint, Salesforce, Notion.
2. **Exposure to untrusted content** — agents read emails, documents, calendar invites, Slack messages, and web pages that may contain hidden injection payloads.
3. **External communication ability** — agents can send email, post to Slack, create calendar invites, write to CRM records, and invoke arbitrary remote tools via MCP.

Every confirmed exfiltration PoC against AI agents in the past 12 months — **ShadowLeak** (Radware, 2025), **AgentFlayer** (Zenity Labs, Black Hat USA 2025), **ZombieAgent** (Radware, September 2025), and **GeminiJack** (Noma Security, January 2026) — exploited an architecture identical to what workspace agents inherit. The defensive posture is therefore **deny-by-default and approval-gated**, not "trust the model layer."

---

### 6.1 Keep Workspace Agents Disabled Until Governance Is in Place

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 4.7 |
| NIST 800-53 | CM-7, AC-3 |

#### Description

Workspace agents are disabled by default in new and existing Enterprise/Edu workspaces. Do not enable them workspace-wide until RBAC roles, connector posture, approval policies, and Compliance Platform ingestion are all in place. OpenAI's RBAC surface for agents has **five distinct dimensions** — controlling who can use agents, build agents, publish agents, publish agents with shared connections, and enable the Slack bot for agents. *(The five-dimension enumeration traces to the retired security-overview PDF — verify the current toggle set against your workspace's role settings and the live [roles and workspace permissions doc](https://learn.chatgpt.com/docs/enterprise/roles-and-workspace-permissions.md).)* Build a role mapping that separates all five, with the **publish-with-shared-connections** permission reserved for the narrowest possible group because it is the only setting that lets an agent run with one set of credentials on behalf of many users.

#### Rationale

**Why This Matters:**
- Agent build privileges proliferate faster than governance reviews can keep up
- "Publish with shared connections" is the highest-risk privilege — it grants every runner of that agent the union of the shared connection's scopes, regardless of the runner's personal entitlements
- Once the feature is on, suspending it for the whole workspace breaks legitimate work; deny-by-default avoids that trap

**Attack Prevented:** Shadow AI / agent sprawl, orphan agents owned by departed users, premature exposure of the lethal-trifecta surface

**Real-World Pattern:** Custom GPT proliferation in the 2023–2024 period — many enterprises ended up with hundreds of internal GPTs and no inventory; workspace agents inherit the same failure mode plus the ability to take actions.

#### ClickOps Implementation

**Step 1: Confirm the feature is off**

1. Navigate to: **Workspace settings** → **Members** → **Roles**
2. Confirm no existing role has any of the five agent feature toggles enabled
3. If any role does, document the role and the affected user count before proceeding

**Step 2: Create three dedicated RBAC roles**

1. Create `agents-run` — `use_agents: enabled`; build, publish, publish-with-shared-connections, and Slack-bot disabled
2. Create `agents-build` — adds `build_agents: enabled`
3. Create `agents-admin` — adds `publish_agents: enabled` plus `enable_slack_bot: enabled`
4. **Withhold** `publish_agents_with_shared_connections` from all three roles initially — grant it only to a named subset of `agents-admin` users when a specific shared-connection agent has been approved through CAB
5. Map each role to a SCIM-provisioned group in your identity provider — no direct user assignments

**Step 3: Defer workspace-level enablement**

1. Do not enable the agent feature workspace-wide until controls 6.2 (connector posture), 6.3 (approval policy), and 6.6 (Compliance Platform ingestion) are all in place

**Time to Complete:** ~30 minutes plus IdP group provisioning lead time

#### Code Implementation

{% include pack-code.html vendor="chatgpt-enterprise" section="6.1" %}

#### Validation & Testing

1. Pull the role roster and confirm the three roles exist with the expected feature toggles
2. In the Global Admin Console, confirm the `Agents` section shows no published agents
3. Sample a user without any of the three roles and confirm the `Agents` sidebar entry is not visible

**Expected result:** Three roles defined, all SCIM-mapped, zero agents published, the agent feature invisible to non-role users.

---

### 6.2 Minimize Connector Scopes and Default to Read-Only

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 6.8 |
| NIST 800-53 | AC-3, AC-6, CM-7 |

#### Description

OpenAI exposes three values at **Workspace settings** → **Apps** → **{App}** → **Action control**: `allow_all`, `read_only`, and `custom`. All apps are disabled by default. When you enable an app, default it to `read_only` and use `custom` only to allow specific write actions with a documented business case. Never use `allow_all` on a workspace that hosts agents.

#### Rationale

**Why This Matters:**
- OAuth scopes are negotiated at the provider level (Google, Microsoft, Salesforce); they are coarse and cannot be reduced per-action
- The OpenAI Action control toggle is the only granular write-prevention layer between an injected agent and a connected system
- **AgentFlayer** (Zenity Labs, Black Hat USA 2025) demonstrated that hidden 1-pixel instructions in a Google Drive document caused an agent with broad Drive access to traverse a victim's drive and exfiltrate API keys

**Attack Prevented:** Cross-connector data exfiltration, runaway write actions triggered by indirect prompt injection, accidental destructive operations from a faulty agent build

#### ClickOps Implementation

**Step 1: Audit currently enabled apps**

1. Navigate to: **Workspace settings** → **Apps**
2. List every app whose status is `Enabled`
3. For each enabled app, open the app and review its current `Action control` setting

**Step 2: Apply the read-only baseline**

1. For every enabled app, set `Action control` to `read_only` unless there is a documented and approved write workflow
2. Set `Newly added actions` to `Deny` (or the equivalent "deny by default for new actions" toggle)
3. For Slack, use `custom`: allow `search` and `read_channel`; deny `post_to_channel`, `dm_external`, `post_to_dm`

**Step 3: Document exceptions**

1. Any app with `custom` or `allow_all` must have a CAB ticket containing the business case, the approver, and a review date no more than 90 days out

**Time to Complete:** ~1 hour per enabled app

#### Code Implementation

{% include pack-code.html vendor="chatgpt-enterprise" section="6.2" %}

#### Validation & Testing

1. Export the app list and confirm every entry is either `disabled` or `read_only` (or a `custom` entry with a CAB ticket)
2. Have an `agents-build` user attempt to construct an agent that performs a write on a `read_only` app; the action should be unavailable in the Builder

#### Monitoring & Maintenance

- Quarterly: re-attest each enabled app's action control
- On every CAB-approved exception: schedule a review date and a Sigma alert (see 6.4) on the resulting grant event

---

### 6.3 Require Human Approval for Sensitive Agent Actions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.7 |
| NIST 800-53 | AC-3(2), CM-3 |

#### Description

Per OpenAI's security overview, *"write-capable actions default to requiring human approval, providing write-action safety control, with flexibility for authors to configure approval behavior."* The default is therefore deny-on-write — the hardening posture is to **preserve that default** during agent publish review, never relax it for "convenience," and define the explicit list of action categories that no agent may unbind. Agents-admin reviewers must reject any agent that disables approval on the categories below.

#### Rationale

**Why This Matters:**
- Model-layer prompt-injection defenses are probabilistic; Anthropic's best result is ~1% browser-agent attack success after RL training, and OpenAI's own [Atlas hardening post](https://openai.com/index/hardening-atlas-against-prompt-injection/) concedes it *"may never be fully solved"*
- The only deterministic mitigation against an injected agent issuing a malicious write is a separate human signing off on that write
- **CVE-2026-21520** (Microsoft Copilot Studio, "ShareLeak") showed that confirm-before-act gates are bypassable when poorly scoped; the gate must trigger on the action category, not just on a "looks-sensitive" heuristic

**Attack Prevented:** Indirect-prompt-injection-driven email exfiltration, calendar-invite data leaks, CRM record poisoning, code-push backdoors

#### ClickOps Implementation

**Step 1: Define the required-approval action list**

The minimum list every published agent must gate behind human approval:

- Send email (any external recipient)
- Create calendar invite for external attendees
- Salesforce / CRM record create / update / delete
- SharePoint or Drive bulk write or any delete
- GitHub push / merge / release
- Slack post to channel or DM to external recipient
- First invocation of any MCP tool
- Any financial transaction

**Step 2: Enforce during the publish workflow**

1. In `Global Admin Console` → `Agents` → an agent that is pending publish, open its action map
2. Reject the publish if any of the above categories appears without an approval gate
3. Require the agents-admin to record the approver email and the agent ID in a published-agents register

**Time to Complete:** ~15 minutes per agent during publish review

#### Code Implementation

{% include pack-code.html vendor="chatgpt-enterprise" section="6.3" %}

#### Validation & Testing

1. Build a test agent that attempts to send email without an approval gate; the publish should be blocked
2. Approve the agent with the gate in place and confirm the agent run halts at the send step and waits for approver acknowledgement

---

### 6.4 Detect Lethal-Trifecta Agents and First-Use MCP Tools

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4(2), SI-4(24) |

#### Description

A workspace agent crosses the lethal-trifecta threshold the moment its connected app set intersects all three categories: private-data read, untrusted-content ingest, and external-send. Inventory every agent and flag the trifecta cases. Separately, fire a high-severity alert on every first invocation of a custom MCP tool — custom MCP servers extend the trust boundary beyond OpenAI's vetted catalog.

#### Rationale

**Why This Matters:**
- The trifecta is the *architectural* precondition for every published agent exfiltration PoC; eliminating it eliminates the vulnerability class
- Custom MCP tools are bring-your-own-code; their first call is the most informative observation because the agent is exercising a capability that has not yet been seen in production
- OpenAI quote: *"Conversations involving agent tasks will appear in Compliance API logs, but individual agent actions (such as virtual computer usage, app requests, chain of thought) will not."* — the SIEM rules in this section are therefore your only continuous visibility into per-step capability changes

**Attack Prevented:** Architectural exfiltration paths, undocumented MCP tool capability, post-publish scope expansion that bypasses the publish review

#### ClickOps Implementation

**Step 1: Export the agent inventory**

1. Navigate to: **Global Admin Console** → **Agents**
2. Export the full agent list to CSV (columns: `agent_id`, `agent_name`, `owner_email`, `connected_apps`)

**Step 2: Classify each agent**

1. Mark each agent whose `connected_apps` includes any of:
   - Private-data: Gmail, Drive, Calendar, Docs, SharePoint, OneDrive, Outlook, Salesforce, Notion, Confluence, Jira, GitHub, GitLab, Box, Dropbox
   - Untrusted-content: Gmail, Outlook, Slack, Calendar, Web Search, Browser, Notion, Confluence, Jira
   - External-send: Gmail, Outlook, Slack, Calendar, Web Search, Browser, GitHub, GitLab, Salesforce
2. Any agent that appears in all three lists is a trifecta agent — require either app-set reduction or full human-in-the-loop approval on every external-send step

**Time to Complete:** ~30 minutes for the first inventory, then 5 minutes per new agent at publish

#### Code Implementation

{% include pack-code.html vendor="chatgpt-enterprise" section="6.4" %}

#### Validation & Testing

1. Run the trifecta detection script against your exported agent inventory; confirm zero unapproved trifecta agents
2. Have a builder add an MCP tool to a test agent in Preview; confirm the first-use Sigma rule fires in your SIEM

---

### 6.5 Operationalize Agent Suspension for Incident Response

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 17.7 |
| NIST 800-53 | IR-4(1), CM-3 |

#### Description

OpenAI documents agent suspension as a first-class admin action: *"Admins can also suspend agents if needed."* Build the suspension runbook before the first incident — define who can suspend, what evidence is collected, what users are notified, and how the suspension is reversed.

#### Rationale

**Why This Matters:**
- The Global Admin Console → Agents → Suspend action is the kill-switch; latency matters during an active exfiltration
- Without a documented runbook, the suspension decision drifts to whoever happens to be on call, which is rarely the right person
- A suspension event is also a high-confidence detection signal — Sigma rule 6.5 surfaces every suspension to the GRC oncall

**Attack Prevented:** Continued exfiltration after compromise is identified, post-suspension confusion and reversal, lack of forensic evidence

#### ClickOps Implementation

**Step 1: Document the runbook**

1. Suspension authority: anyone in the `agents-admin` role plus the security incident commander
2. Triggering signals: trifecta detection (6.4), Sigma alert on suspension by an unexpected admin, anomalous Compliance API event
3. Required evidence capture before suspension: agent ID, owner, connected apps list, last 10 runs from the Compliance API, builder configuration screenshot
4. Notification list: agent owner, agents-admin chat channel, GRC oncall, security incident commander

**Step 2: Drill the runbook**

1. Suspend a non-production test agent quarterly
2. Time the full suspension-to-evidence-capture cycle; target under 15 minutes
3. After suspension, restore the agent and confirm it resumes correctly

**Time to Complete:** ~2 hours to document; ~30 minutes per quarterly drill

#### Code Implementation

{% include pack-code.html vendor="chatgpt-enterprise" section="6.5" %}

#### Validation & Testing

1. The quarterly drill is the validation — confirm under-15-minute suspension-to-evidence latency and successful restore

---

### 6.6 Stream Compliance Platform Logs to SIEM

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 8.10 |
| NIST 800-53 | AU-6, AU-11, AU-12 |

#### Description

The OpenAI **Compliance Logs Platform** is designed specifically for compliance needs and exposes **immutable, append-only JSONL log files on a pull model**, retained for **30 days** ([Compliance Platform article](https://help.openai.com/en/articles/9261474-compliance-api-for-chatgpt-enterprise-edu-and-chatgpt-for-teachers)). Documented API surface ([Logs Platform cookbook](https://developers.openai.com/cookbook/examples/chatgpt/compliance_api/logs_platform)):

- Base: `https://api.chatgpt.com/v1/compliance`, authenticated with `Authorization: Bearer $COMPLIANCE_API_KEY`
- List: `/{workspaces|organizations}/{principal_id}/logs` with `limit`, `event_type`, and `after` parameters; responses carry `data[].id`, `has_more`, `last_end_time`
- Download: `/{scope}/{principal_id}/logs/{id}`
- Two complementary access patterns: the **Compliance Logs Platform** (immutable append-only log events) and the **Stateful Compliance API** (state at time of request)

> **Provenance note:** the previously cited delivery-timing specs — ~10-minute log windows, p99 under 30 minutes, at-least-once delivery with `event_id` deduplication — and the per-event-family names (agent lifecycle, run creation/completion/failure, connector call requested/completed, connector OAuth resolution, skill use, trigger and memory events) trace only to the **retired security-overview PDF** and are no longer publicly verifiable. OpenAI states the **authenticated Admin API reference owns event coverage, schemas, permissions, filters, retention, and request behavior** — confirm all event types and schemas at `chatgpt.com/admin/api-reference` (Enterprise/Edu login required) before building detections. The only publicly documented `event_type` value is `AUTH_LOG`. Sources: [Compliance API doc](https://learn.chatgpt.com/docs/enterprise/compliance-api.md), [Governance doc](https://learn.chatgpt.com/docs/enterprise/governance.md).

#### Rationale

**Why This Matters:**
- Continuous export is mandatory for SOX, HIPAA, PCI scope and for retention beyond the platform's **30-day** window — the short retention is exactly what makes the continuous puller mandatory rather than optional
- OpenAI explicitly frames SIEM as a supported destination: the Compliance Platform "provides access to logs and metadata from your ChatGPT workspace that you can connect with your eDiscovery, DLP, or SIEM tools"
- Downstream SIEM rules should deduplicate on the log/event identifier — confirm the delivery contract in the tenant Admin API reference before tuning alert thresholds

**Attack Prevented:** Audit-trail gaps, missed lateral movement signals during longer dwell times, inability to support a post-incident forensic timeline

#### ClickOps Implementation

**Step 1: Provision a Compliance API key**

1. Sign in to the Global Admin Console at [admin.openai.com](https://admin.openai.com)
2. Navigate to **API keys** and generate a `Compliance API key`, scoped to your workspace or organization
3. Note the IP allowlist requirement: per OpenAI, IP allowlist is *"always enforced for Compliance API traffic"* — add your puller's egress IPs first

**Step 2: Deploy the continuous puller**

1. Deploy the bash script in 6.6 (or one of the 18 supported partner integrations — see [4.2](#42-integrate-with-microsoft-purview)) on a scheduled job; **every 15 minutes** is a sensible cadence well inside the **30-day retention window**
2. Deduplicate on the log/event identifier at the consumer (confirm the delivery contract in the tenant Admin API reference)
3. Persist each downloaded JSONL log file to an immutable bucket (S3 Object Lock, GCS retention policy, Azure Blob immutability) with a retention setting that matches your compliance scope (1 year for PCI, 6 years for HIPAA, 7 years for SOX) — the platform itself only retains **30 days**

**Step 3: Wire the SIEM**

1. Forward the bucket contents to Splunk (universal forwarder), Microsoft Sentinel (Custom Logs DCR), Google Chronicle, or your existing platform
2. Deploy the three Sigma rules — first MCP tool call and post-publish scope expansion (both keyed to 6.4) and agent suspension (6.5) — and confirm they fire against historical events

**Time to Complete:** ~4 hours including initial backfill

#### Code Implementation

{% include pack-code.html vendor="chatgpt-enterprise" section="6.6" %}

#### Validation & Testing

1. After 24 hours, confirm the SIEM has ingested events from each event type
2. Generate a test agent suspension and confirm Sigma 6.5 fires within the alerting SLA
3. Quarterly: restore a sample log file from the immutable bucket and confirm the JSONL parses cleanly

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|---------|
| **User Experience** | None | Logging is server-side |
| **System Performance** | Low | One scheduled pull every 15 minutes per event type |
| **Maintenance Burden** | Medium | Watch for new OpenAI event types. **Completed removal:** the new conversations logs system shipped **2026-03-05** and the legacy stateful conversations route was **removed on 2026-06-05** — verify no consumer still calls the removed route ([migration reference](https://help.openai.com/en/articles/9261474-compliance-api-for-chatgpt-enterprise-edu-and-chatgpt-for-teachers)) |
| **Rollback Difficulty** | Easy | Disabling the puller stops ingestion; archived logs remain |

---

### 6.7 Execute the OpenAI Pre-Launch Admin Checklist

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 6.8 |
| NIST 800-53 | CM-2, CM-3, CM-6 |

#### Description

OpenAI published a six-step pre-launch checklist in its *Workspace Agents Security Overview* PDF, on the reasoning that many workspace agent settings use controls already set up in an organization's workspace, and reviewing them before launch reduces IT escalations. *(That PDF has since been removed — the checklist below is preserved from it and remains sound practice, but cross-check each step against the live [admin rollout guidance](https://learn.chatgpt.com/docs/enterprise/governance.md).)* Treat the checklist as a publish gate — no agent goes live in your workspace until every step is signed off by `agents-admin`.

#### Rationale

**Why This Matters:**
- OpenAI's own recommended sequence catches the most common misconfigurations before users start building
- Most steps map directly onto controls 6.1–6.6 of this guide; running the checklist also validates that those controls are in effect
- A documented gate per agent publish creates an audit trail you can show to your auditor mapping every published agent to a named approver and an effective date

**Attack Prevented:** Misconfigured early-adopter agents, surprise IT escalations, shadow agents that bypass the broader governance program

#### ClickOps Implementation — Pre-Launch Checklist

Walk the six steps from the OpenAI overview, in order:

**Step 1: Audit users and groups**

Ensure that users are added to the workspace and in the right SCIM-provisioned groups. Confirm no orphaned accounts from departed employees, no service accounts in user groups.

**Step 2: Configure custom roles for builders and users**

Apply the five-dimension RBAC mapping from control 6.1. The `publish_agents_with_shared_connections` permission is the highest-risk bit — withhold it until a specific shared-connection agent has been approved through CAB.

**Step 3: Enable approved apps**

Turn on the apps your builders need (OpenAI's documented examples are Slack, Google Drive, SharePoint, Gmail, Calendar, GitHub, Jira, Confluence). For each app:

- Confirm which actions are read-only vs. write-capable
- Set `Newly added actions` to require admin review (do **not** auto-enable new write actions)
- Apply the read-only baseline from control 6.2

**Step 4: Make required skills available**

Enable skill permissions for the relevant builder and user groups so agents can use approved, repeatable workflows. Skills package instructions, files, and scripts; treat their enablement as a privileged grant.

**Step 5: Review MCP availability**

If builders need custom MCP servers, enable Developer Mode or approved MCP connectors only for the right builder groups. First invocation of any MCP tool fires the Sigma rule from control 6.4 — confirm SIEM ingestion is live before granting MCP access to any builder.

**Step 6: Confirm Slack setup**

If agents will be deployed to Slack, approve the `ChatGPT Agents` app in Slack and define who can deploy agents to Slack via the `enable_slack_bot` RBAC bit. Note from OpenAI: *"In Slack and other non-interactive surfaces, the agent generally relies on shared/agent-owned or builder-configured app connections because Slack cannot pause the run to authenticate each invoking user."* Slack-deployed agents therefore carry higher inherent risk than ChatGPT-resident agents and warrant extra scrutiny on the approval policy.

**Time to Complete:** ~2 hours for the initial pass; ~10 minutes per subsequent agent publish

#### Code Implementation

{% include pack-code.html vendor="chatgpt-enterprise" section="6.7" %}

#### Validation & Testing

1. Walk the checklist for one pilot agent end-to-end; capture screenshots/exports at every step into an evidence folder
2. Have a non-`agents-admin` user attempt to publish an agent without completing the checklist; confirm the publish workflow surfaces the gate

---

### 6.8 Govern the Workspace Agents Trigger API and Personal Access Tokens

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3, 6.8 |
| NIST 800-53 | IA-5, AC-3, AU-12 |

#### Description

Workspace agents can now be triggered **programmatically from outside ChatGPT**: `POST https://api.chatgpt.com/v1/workspace_agents/{agent_id}/trigger`, authenticated with a **"Workspace Agents"-scoped access token**. Enabling this surface requires an admin to enable Workspace agents AND turn on **"Allow users to create personal access tokens"** under **Admin → Permissions & roles**. The API **queues the run and returns 202 Accepted with no body and no run ID**, and the agent's response **cannot be retrieved through the API** — calls are fire-and-forget and invisible to the caller. Keep the PAT toggle off until you have token governance and compensating detection in place. Sources: [Workspace Agents authentication](https://developers.openai.com/workspace-agents/authentication.md), [Trigger runs](https://developers.openai.com/workspace-agents/trigger-runs.md).

#### Rationale

**Why This Matters:**
- The PAT toggle converts every permitted user into a potential issuer of long-lived credentials that can start agent runs from any system — CI jobs, cron boxes, third-party SaaS — outside ChatGPT's interactive controls
- Because the trigger returns **no run ID and no retrievable response**, the caller gets zero feedback — a stolen token can silently queue agent runs, and the only place the activity is visible is the Compliance Platform log stream (Control 6.6)
- Fire-and-forget triggering pairs badly with agents that hold write-capable connections: an attacker does not need to see the output to profit from the side effects

**Attack Prevented:** Unaccounted-for personal access tokens, silent agent-run triggering with stolen credentials, external automation bypassing interactive approval visibility.

#### ClickOps Implementation

**Step 1: Default-deny the PAT toggle**
1. Navigate to: **Admin → Permissions & roles**
2. Keep **"Allow users to create personal access tokens"** disabled until a documented use case exists
3. When enabling, restrict to the narrowest role that needs API triggering

**Step 2: Govern issued tokens**
1. Register every issued Workspace Agents token in your credential inventory with owner, purpose, and rotation date
2. Rotate on a fixed schedule and revoke immediately on personnel change
3. Prohibit embedding tokens in source code or shared automation configs — vault them

**Step 3: Compensating detection**
1. Ensure Compliance Platform ingestion (Control 6.6) is live **before** the first token is issued — it is the only visibility into API-triggered runs
2. Alert on agent runs for agents whose owners have not registered an API-trigger use case

#### Validation & Testing

1. With the toggle off, confirm a user cannot mint a personal access token
2. After enabling for a pilot role, trigger a test agent via the API and confirm the run appears in your SIEM via the Compliance Platform export

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | ChatGPT Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | SSO authentication | [1.1](#11-configure-saml-single-sign-on) |
| CC6.1 | MFA enforcement | [1.2](#12-enable-multi-factor-authentication) |
| CC6.1 | Workspace agent RBAC | [6.1](#61-keep-workspace-agents-disabled-until-governance-is-in-place) |
| CC6.2 | Role-based access | [1.4](#14-implement-role-based-access-control) |
| CC6.6 | Data retention | [2.2](#22-configure-data-retention-policies) |
| CC7.2 | Usage monitoring | [4.1](#41-enable-usage-analytics) |
| CC7.2 | Compliance API SIEM export | [6.6](#66-stream-compliance-platform-logs-to-siem) |
| CC7.4 | Agent approval policy | [6.3](#63-require-human-approval-for-sensitive-agent-actions) |

### NIST 800-53 Rev 5 Mapping

| Control | ChatGPT Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | SAML SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | MFA | [1.2](#12-enable-multi-factor-authentication) |
| AC-2 | User provisioning | [1.3](#13-configure-scim-user-provisioning) |
| AC-3 | Workspace agent RBAC | [6.1](#61-keep-workspace-agents-disabled-until-governance-is-in-place) |
| AC-3(2) | Agent action approvals | [6.3](#63-require-human-approval-for-sensitive-agent-actions) |
| AC-6(1) | Least privilege | [1.4](#14-implement-role-based-access-control) |
| CM-7 | Connector read-only baseline | [6.2](#62-minimize-connector-scopes-and-default-to-read-only) |
| SC-28 | Data encryption | [2.1](#21-understand-data-privacy-guarantees) |
| SI-4(2) | Cross-connector exfil detection | [6.4](#64-detect-lethal-trifecta-agents-and-first-use-mcp-tools) |
| AU-6 | Compliance API SIEM export | [6.6](#66-stream-compliance-platform-logs-to-siem) |
| IR-4(1) | Agent suspension runbook | [6.5](#65-operationalize-agent-suspension-for-incident-response) |

### GDPR Considerations

| Requirement | ChatGPT Enterprise Support |
|-------------|---------------------------|
| Data minimization | Configurable retention policies |
| Purpose limitation | Acceptable use policies |
| Data portability | Export functionality |
| Right to erasure | Conversation deletion |
| Security of processing | SOC 2, encryption, access controls |
| Article 22 (automated decisions) | Workspace agent approval gates ensure human is in the loop for actions with legal or significant effect; see [6.3](#63-require-human-approval-for-sensitive-agent-actions) |

---

## Appendix A: Edition Comparison

| Feature | ChatGPT Team | ChatGPT Business | ChatGPT Enterprise | ChatGPT Edu |
|---------|--------------|------------------|-------------------|-------------|
| SSO/SAML | ❌ | ✅ | ✅ | ✅ |
| SCIM | ❌ | ✅ | ✅ | ✅ |
| Data not used for training | ✅ | ✅ | ✅ | ✅ |
| Enterprise Key Management | ❌ | ❌ | ✅ | ✅ |
| Admin Console | Basic | Full | Full | Full |
| Usage Analytics | Basic | Advanced | Advanced | Advanced |
| SOC 2 Type II | ❌ | ✅ | ✅ | ✅ |
| Custom data retention | ❌ | ✅ | ✅ | ✅ |
| Workspace Agents (shipped; off by default at launch) | ❌ | ✅ | ✅ | ✅ |
| Compliance API for agent logs | ❌ | ❌ | ✅ | ✅ |
| Granular app action control (per-app read-only) | ❌ | Limited | ✅ | ✅ |

---

## Appendix B: References

**Official OpenAI Documentation (learn.chatgpt.com canonical enterprise admin set):**
- [Administration](https://learn.chatgpt.com/docs/enterprise/administration.md)
- [Governance](https://learn.chatgpt.com/docs/enterprise/governance.md)
- [Compliance API and audit events](https://learn.chatgpt.com/docs/enterprise/compliance-api.md)
- [Groups and provisioning](https://learn.chatgpt.com/docs/enterprise/groups-and-provisioning.md)
- [Roles and workspace permissions](https://learn.chatgpt.com/docs/enterprise/roles-and-workspace-permissions.md)
- [Apps and connectors](https://learn.chatgpt.com/docs/enterprise/apps-and-connectors.md)
- [Doc index (llms.txt)](https://learn.chatgpt.com/llms.txt) — full canonical enterprise doc set, including Managed configuration, Plugin controls, Access tokens, Admin rollout guide, and the ChatGPT Work admin FAQ
- [ChatGPT Enterprise Help Center](https://help.openai.com/en/collections/5688074-chatgpt-enterprise)
- [Admin Controls: Security and Compliance in Apps](https://help.openai.com/en/articles/11509118-admin-controls-security-and-compliance-in-apps-enterprise-edu-and-business)
- [Business Data Privacy, Security, and Compliance](https://openai.com/business-data/)

**Workspace Agents:**
- *Workspace Agents Security Overview* (PDF, April 29, 2026) — **removed; the URL now returns HTTP 404.** Retained here as a historical citation only; use the learn.chatgpt.com doc set above.
- [Introducing Workspace Agents in ChatGPT](https://openai.com/index/introducing-workspace-agents-in-chatgpt/) — April 22, 2026 announcement
- [Workspace Agents for Enterprise and Business](https://help.openai.com/en/articles/20001143-chatgpt-workspace-agents-for-enterprise-and-business)
- [Workspace Agents authentication (access tokens)](https://developers.openai.com/workspace-agents/authentication.md)
- [Workspace Agents trigger runs API](https://developers.openai.com/workspace-agents/trigger-runs.md)
- [ChatGPT Agent (underlying technology)](https://help.openai.com/en/articles/11752874-chatgpt-agent)
- [Workspace Agents App in Slack](https://help.openai.com/en/articles/20001199-chatgpt-agents-app-in-slack)
- [Global Admin Console](https://help.openai.com/en/articles/12289294-global-admin-console)
- [RBAC for ChatGPT](https://help.openai.com/en/articles/11750701-rbac)
- [Developer Mode Apps and Full MCP Connectors (beta)](https://help.openai.com/en/articles/12584461-developer-mode-apps-and-full-mcp-connectors-in-chatgpt-beta)
- [Building Workspace Agents — OpenAI Cookbook](https://developers.openai.com/cookbook/articles/chatgpt-agents-sales-meeting-prep)
- [Designing Agents to Resist Prompt Injection](https://openai.com/index/designing-agents-to-resist-prompt-injection/)
- [Hardening Atlas Against Prompt Injection](https://openai.com/index/hardening-atlas-against-prompt-injection/) — note: this page returns HTTP 403 to automated fetchers; verify in a real browser

**Compliance API:**
- [OpenAI Compliance Platform for Enterprise and Edu Customers](https://help.openai.com/en/articles/9261474-compliance-api-for-chatgpt-enterprise-edu-and-chatgpt-for-teachers)
- [Compliance Logs Platform Quickstart — OpenAI Cookbook](https://developers.openai.com/cookbook/examples/chatgpt/compliance_api/logs_platform)
- Tenant Admin API reference (event schemas, login-gated): `chatgpt.com/admin/api-reference`

**API Documentation:**
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference/introduction)
- [Official Python SDK](https://github.com/openai/openai-python)
- [Official Node.js/TypeScript SDK](https://platform.openai.com/docs/libraries)
- [Agents SDK](https://developers.openai.com/api/docs/guides/agents-sdk)
- [Tools, Connectors, and MCP](https://developers.openai.com/api/docs/guides/tools-connectors-mcp)

**Compliance Frameworks:**
- SOC 2 Type II (Security, Availability, Confidentiality, Privacy), ISO 27001:2022, ISO 27017, ISO 27018, ISO 27701 — audit reports available to customers under NDA via your OpenAI account team

**Security Research on AI Agents:**
- [The Lethal Trifecta — Simon Willison, June 2025](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/) — the architectural pattern behind every confirmed agent exfiltration PoC
- [AgentFlayer: ChatGPT Connectors 0-click — Zenity Labs, Black Hat USA 2025](https://labs.zenity.io/p/agentflayer-chatgpt-connectors-0click-attack-5b41)
- [OWASP Top 10 for LLM Applications (LLM01: Prompt Injection)](https://genai.owasp.org/llmrisk/llm01-prompt-injection/)
- [Embrace The Red — Johann Rehberger's prompt-injection research](https://embracethered.com/blog/)

**Security Incidents:**
- **March 2023 — Redis library bug exposed chat titles and payment info.** A bug in the open-source Redis client library allowed some users to see other users' chat history titles and first messages. Payment information of approximately 1.2% of ChatGPT Plus subscribers was also briefly exposed. ([OpenAI Disclosure](https://openai.com/index/march-20-chatgpt-outage/))
- **November 2025 — Vendor (Mixpanel) breach exposed limited business customer data.** Attackers breached OpenAI's third-party analytics vendor Mixpanel, stealing names, emails, locations, and technical system details of business customers. No chat data, API keys, credentials, or payment details were compromised. OpenAI suspended the relationship with Mixpanel and initiated broader vendor security reviews. ([OpenAI Disclosure](https://openai.com/index/mixpanel-incident/))
- **2025 (patched 2026-02-20) — ShadowLeak.** Radware disclosed a zero-click indirect prompt injection against the Deep Research agent. Hidden HTML in an inbound Gmail message caused the agent to exfiltrate inbox contents from OpenAI's cloud infrastructure, invisible to local DLP. Patched. ([Radware advisory via Infosecurity Magazine](https://www.infosecurity-magazine.com/news/vulnerability-chatgpt-agent-gmail/))
- **September 2025 (patched mid-December 2025) — ZombieAgent.** Radware disclosed a persistent indirect-prompt-injection attack that planted rules into ChatGPT memory; every subsequent session re-triggered exfiltration. Bypassed dynamic-URL filters via a pre-built static URL dictionary. ([Coverage via The Hacker News](https://thehackernews.com/2026/03/openai-patches-chatgpt-data.html))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.3.0 | ai-drafted | Currency pass: re-sourced Section 6 off the removed Workspace Agents Security Overview PDF (annotated PDF-only claims; cited live learn.chatgpt.com / developers.openai.com docs); rewrote 3.1/3.2 for the plugins + bundled skills + connectors model and six control boundaries; new control 6.8 (Workspace Agents trigger API + PAT governance); workspace agents no longer "research preview"; added 30-day Compliance Platform retention and endpoint surface to 6.6; converted the stateful-route deprecation to a completed removal (removed 2026-06-05); added the 18-partner Compliance Platform ecosystem to 4.2/5.2; fixed 1.3/1.4/2.4/3.1 cheat-parser misses; fixed 6.6 duplicate pack includes and two broken compliance-table anchors; migrated Appendix B to the learn.chatgpt.com canonical set, fixed the Compliance API slug, purged trust-center links; rewrote the three Sigma rules in schema-agnostic form with login-gated schema warnings | Claude Code (Fable 5) |
| 2026-05-14 | 0.2.1 | ai-drafted | Reconciled Section 6 against OpenAI's *Workspace Agents Security Overview* (April 29, 2026). Added the fifth RBAC dimension `publish_agents_with_shared_connections` (6.1). Replaced reconstructed event-type list with the PDF's authoritative agent lifecycle / run / connector-call / OAuth-resolution / skill / trigger / memory event families (6.6). Added Logs Platform technical specs (~10-min windows, p99 < 30 min, at-least-once, event_id dedup). Added control 6.7 implementing OpenAI's six-step pre-launch checklist. Updated Sigma rules and the SIEM-streaming and trifecta-detection scripts with PDF-verified event names and app catalog. New pack file: `config/hth-chatgpt-enterprise-6.07-prelaunch-checklist.jsonc`. | Claude Code (Opus 4.7) |
| 2026-05-14 | 0.2.0 | ai-drafted | [SECURITY] Added Section 6 Workspace Agents Hardening (6 controls covering RBAC, connector posture, approval policy, lethal-trifecta detection, suspension runbook, Compliance API SIEM export). Added Code Packs under `packs/chatgpt-enterprise/` (api, config, siem/sigma). Updated NIST and GDPR mappings. Expanded References with workspace agent, Compliance API, and agent-security research links. | Claude Code (Opus 4.7) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with SSO, data privacy, GPT controls, and compliance | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
