---
layout: guide
title: "Intercom Hardening Guide"
vendor: "Intercom"
slug: "intercom"
tier: "2"
category: "Marketing"
description: "Customer messaging platform hardening for Intercom including SAML SSO, workspace security, and data protection"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Intercom is a leading customer messaging platform serving **thousands of businesses** for support, marketing, and customer engagement. As a platform handling customer conversations and PII, Intercom security configurations directly impact customer privacy and data protection.

### Intended Audience
- Security engineers managing customer platforms
- IT administrators configuring Intercom
- Support operations managing messaging
- GRC professionals assessing communication security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Intercom security including SAML SSO, workspace access, conversation security, and data protection.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Data Protection](#3-data-protection)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [API Security](#5-api-security)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

> **⚠ Deadline — 2026-12-12: rotate your Intercom SAML certificate.** Intercom is issuing a new SAML certificate, and **your identity provider must be updated with it before 12 December 2026 or SAML logins will fail.** Intercom surfaces a warning banner at **Settings → Workspace → Security** for affected workspaces. If your workspace enforces SSO, missing this date locks every teammate out of the product, so treat it as an availability item as well as a security one. ([Update your identity provider with Intercom's new SAML certificate by Dec 2026](https://www.intercom.com/help/en/articles/13436367-update-your-identity-provider-with-intercom-s-new-saml-certificate-by-dec-2026))

#### Description
Configure SAML SSO to centralize authentication for Intercom teammates, then disable the password login path so SSO is genuinely enforced rather than merely offered.

#### Rationale
**Why This Matters:**
- Routes every Intercom teammate login through your corporate IdP, enforcing MFA, conditional access, and device posture on each sign-in
- Standalone Intercom passwords bypass IdP controls and are prime targets for credential stuffing and phishing
- Central provisioning and deprovisioning removes access the moment an employee leaves, eliminating orphaned teammate accounts
- Intercom inboxes hold customer conversations and PII, so a single compromised login can expose sensitive customer data

**Attack Prevented:** Credential theft, phishing, password reuse, orphaned-account access

#### Prerequisites
- Intercom admin access
- **Enterprise plan — SAML SSO is Enterprise-only**
- SAML 2.0 compatible IdP

**Authentication methods by plan:**

| Method | Availability |
|--------|--------------|
| Email and password with 2FA | All plans |
| Google Sign-In | All plans |
| SAML SSO | Enterprise only |

#### ClickOps Implementation

**Step 1: Access Security Settings**
1. Navigate to: **Settings** → **Workspace** → **Security**
2. Find the SAML/SSO section

**Step 2: Configure SAML**
1. Enable SAML SSO
2. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
3. Configure attribute mapping

**Step 3: Test and Enforce**
1. Test SSO authentication with a non-administrator account before enforcing
2. Enable SSO enforcement
3. Document the admin fallback path you intend to rely on if the IdP is unavailable

**Step 4: Disable Email and Password Logins**
1. Still under **Settings** → **Workspace** → **Security**, turn off the email-and-password login option
2. This step is Intercom's own instruction and it is the one that matters: until password logins are disabled, requiring SSO adds an authentication path without removing the one that bypasses your IdP's MFA and conditional access
3. Confirm every teammate — including any service or shared account — can sign in through the IdP before you remove the password path

**Time to Complete:** ~1-2 hours

**Sources:** [Protect your account with 2FA, Google Sign-on or SAML SSO](https://www.intercom.com/help/en/articles/181-protect-your-account-with-2fa-google-sign-on-or-saml-sso)

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Intercom teammates.

#### Rationale
**Why This Matters:**
- A second authentication factor blocks account takeover even when a teammate password is stolen, guessed, or reused
- Support and marketing staff are frequent phishing targets because their inboxes hold customer data and outbound messaging reach
- Workspace-wide enforcement closes the gap where individual teammates skip optional 2FA
- Without 2FA, a single leaked credential gives an attacker full read access to customer conversations

**Attack Prevented:** Account takeover, credential stuffing, phishing, password reuse

#### ClickOps Implementation

**Step 1: Enable Workspace 2FA**
1. Navigate to: **Settings** → **Workspace** → **Security**
2. Enable **Require two-factor authentication**
3. All teammates must configure 2FA

**Step 2: Verify Compliance**
1. Review 2FA enrollment status
2. Follow up with non-compliant users
3. Document exceptions

---

### 1.3 Configure Session Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout and security settings.

#### Rationale
**Why This Matters:**
- Idle session timeouts limit the window an attacker can hijack an authenticated browser session on a shared or unattended device
- Shorter sessions force periodic reauthentication, reducing exposure from stolen session tokens
- Support agents often work on shared workstations, where lingering sessions risk unauthorized access to customer inboxes
- Session controls bound the blast radius of a device left logged in or a cookie exfiltrated by malware

**Attack Prevented:** Session hijacking, unauthorized access from unattended devices, token replay

> **Changed default — Intercom web sessions last 4 days.** By default a teammate's web session persists for **4 days of activity** before re-authentication is required. That is the window an attacker inherits with a stolen session cookie, and it is long enough that a device left logged in over a weekend is still authenticated on Monday. Shorten it with **Force teammates to re-authenticate after a set period of time**. ([Setting a custom session length for teammates on your workspace](https://www.intercom.com/help/en/articles/8931217-setting-a-custom-session-length-for-teammates-on-your-workspace))

#### ClickOps Implementation

**Step 1: Configure Session Length**
1. Navigate to: **Settings** → **Workspace** → **Security**
2. Enable **Force teammates to re-authenticate after a set period of time**
3. Set a period appropriate to the sensitivity of the conversations in the workspace — the shorter the period, the smaller the value of a stolen session
4. Balance security with usability; support teams re-authenticating mid-shift is a real cost, but 4 days is rarely the right answer for a workspace holding customer PII

#### Validation & Testing
- Confirm the setting is enabled and note the configured period
- Verify a teammate is prompted to re-authenticate after the period elapses

---

### 1.4 Restrict Workspace Access by IP

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Restrict access to the Intercom workspace — both the web app and the mobile apps — to approved IP addresses, so stolen teammate credentials are unusable from arbitrary networks.

#### Rationale
**Why This Matters:**
- A network-layer restriction is one of the few controls that still holds when credentials and session tokens have already been stolen, because the attacker also has to be on your network
- Support and marketing teammates are high-volume phishing targets, and their accounts read customer conversations, so raising the bar beyond "knows the password" is disproportionately valuable here
- Scoping access to corporate or VPN egress ranges makes any successful login from elsewhere an anomaly worth alerting on rather than normal noise
- The restriction covers the web and mobile apps but **not** the REST API, which is why a separate API allowlist exists ([5.1](#51-restrict-rest-api-access-by-ip-allowlist)) — configuring one and assuming it covers the other leaves the API wide open

**Attack Prevented:** Remote credential abuse, session replay from unknown networks, account takeover from outside the corporate perimeter

#### Prerequisites
- Workspace admin access
- A known, stable set of egress IP addresses (corporate network or VPN)

#### ClickOps Implementation

**Step 1: Collect Your Egress Addresses**
1. Determine every IP address teammates legitimately connect from, including VPN concentrators and any office not on the main circuit
2. Include mobile-app users in this inventory — the restriction applies to them too, and a teammate on a cellular network will be blocked

**Step 2: Configure the Restriction**
1. Navigate to: **Settings** → **Workspace** → **Security**
2. Configure IP restrictions with the addresses collected above
3. **Include your own current IP address** before saving, and keep a documented fallback — an incomplete list locks administrators out of the workspace along with everyone else

**Step 3: Validate**
1. Confirm access works from an allowed address
2. Confirm access is refused from an address outside the list
3. Re-review the list whenever network egress changes

#### Validation & Testing
- Test from both an allowed and a disallowed network before announcing the change
- Confirm the mobile app behaves as expected for field staff
- Confirm the REST API is separately restricted — this control does not cover it

**Source:** [Restricting access to your Intercom workspace using IP restrictions](https://www.intercom.com/help/en/articles/8931206-restricting-access-to-your-intercom-workspace-using-ip-restrictions)

---

### 1.5 Provision Teammates with SCIM

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1, 5.3 |
| NIST 800-53 | AC-2, AC-2(1) |

#### Description
Automate teammate provisioning and deprovisioning from your identity provider using SCIM, with IdP group membership mapped to Intercom roles.

#### Rationale
**Why This Matters:**
- Deprovisioning is the step organisations miss, and SCIM makes removal from Intercom a consequence of the IdP offboarding rather than a separate task
- Mapping IdP groups to Intercom roles keeps permission decisions reviewable in one system instead of drifting per-workspace
- Automated joiner handling means new teammates get exactly the role their group implies, rather than whatever the last manually-created account happened to have
- Customer conversations are sensitive; the window between "left the company" and "lost access" is exactly the exposure SCIM closes

**Attack Prevented:** Orphaned-account access, delayed deprovisioning, permission drift, offboarding gaps

> **Sharp edge — SCIM removal deletes teammates permanently.** When a teammate is removed from the Intercom application in your IdP, Intercom **permanently deletes the teammate**, rather than deactivating them, and their assigned items are reassigned. This is not reversible, so confirm the behaviour on a test account and make sure whoever administers your IdP understands that removing a group membership here is a destructive action in Intercom.

#### Prerequisites
- **SAML SSO must be configured first** — SCIM builds on it (see [1.1](#11-configure-saml-single-sign-on))
- Identity provider supporting SCIM provisioning

#### ClickOps Implementation

**Step 1: Confirm SSO Is In Place**
1. Complete SAML SSO configuration before attempting SCIM

**Step 2: Enable SCIM Provisioning**
1. Configure the Intercom application in your identity provider for SCIM provisioning
2. Map IdP groups to Intercom roles so role assignment follows group membership

**Step 3: Rehearse Removal**
1. Provision a test teammate, confirm the mapped role is applied
2. Remove the test teammate from the IdP group and confirm the deletion and item-reassignment behaviour matches your expectations
3. Document the removal procedure for whoever runs offboarding, including the permanence of the deletion

#### Validation & Testing
- Confirm a newly provisioned teammate receives the correct role automatically
- Confirm removal in the IdP results in loss of Intercom access
- Confirm assigned conversations are reassigned where you expect them to go

**Source:** [System for Cross-domain Identity Management (SCIM) provisioning](https://www.intercom.com/help/en/articles/5798401-system-for-cross-domain-identity-management-scim-provisioning)

---

## 2. Access Controls

### 2.1 Configure Team Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Intercom's granular per-teammate permissions, packaged into Custom Roles for consistent assignment.

#### Rationale
**Why This Matters:**
- Intercom's permission model is granular rather than a small ladder of named roles, so least privilege here means deciding permission by permission, not picking the least-powerful title
- Custom Roles turn those decisions into a reusable package, which is what keeps two teammates doing the same job from ending up with different access
- Permissions covering teammate management, workspace settings, and data export are the ones that let a compromised account change the security posture itself, and they deserve separate scrutiny from day-to-day inbox permissions
- Reviewing permissions per teammate contains insider misuse and limits what any single hijacked account reaches

**Attack Prevented:** Privilege escalation, excessive data exposure, insider misuse, lateral movement

> **Correction (2026-08):** Intercom does not use a fixed **Owner / Admin / Teammate** role ladder. Access is governed by **granular per-teammate permissions**, which can be grouped into **Custom Roles**. Configure permissions, not titles. ([Teammate permissions: how to control workspace access](https://www.intercom.com/help/en/articles/176-teammate-permissions-how-to-control-workspace-access))

#### ClickOps Implementation

**Step 1: Review the Permission Groups**
1. Navigate to: **Settings** → **Workspace** → **Teammates**
2. Open a teammate and review the permissions available, which are grouped by area — including:
   - **Teammates and roles** — inviting, removing, and changing other teammates' permissions
   - **Workspace and app settings** — changing workspace configuration, including security settings
   - **Inbox and conversations** — accessing, replying to, and managing conversations
   - **Contacts and data** — viewing, editing, exporting, and deleting people and company data
   - **Outbound messaging** — creating and sending messages to customers
   - **Reporting** — viewing workspace reports
   - **Billing** — managing subscription and payment details
3. Treat the teammate-management and workspace-settings permissions as privileged — they are the ones that can undo the rest of this guide

**Step 2: Build Custom Roles**
1. Create a Custom Role per job function rather than configuring each teammate individually
2. Grant only the permissions that function needs
3. Keep the number of teammates with teammate-management and workspace-settings permissions as small as practical

**Step 3: Review Regularly**
1. Re-review role membership on a defined cadence and after every offboarding wave
2. Use the Security Health Check ([4.2](#42-run-the-workspace-security-health-check)) to surface issues in the Authentication & Access area

#### Validation & Testing
- Confirm every teammate is assigned via a Custom Role rather than ad-hoc permissions
- Enumerate who holds teammate-management, workspace-settings, and export permissions and confirm each is justified

---

### 2.2 Limit Conversation Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Scope which conversations each teammate can see using the per-teammate **Conversation access** setting, and understand what that scoping does and does not cover.

#### Rationale
**Why This Matters:**
- Conversation access is set per teammate, so scoping is a decision you make about each person rather than a property of a shared inbox
- The scoping applies consistently across the inbox, reports, user profiles, and the mobile app, which means it genuinely narrows what a teammate can reach rather than just tidying one view
- Customer conversations hold PII and sensitive support detail, and most teammates need far fewer of them than they can see by default
- **The REST API is not scoped by this setting** — a teammate's API access still returns all conversations, so an API token belonging to a narrowly-scoped teammate is not itself narrowly scoped

**Attack Prevented:** Unauthorized data access, insider snooping, excessive data exposure, over-broad account compromise

> **Bypass to plan for:** Intercom states that **the REST API will continue to allow full conversation access** regardless of a teammate's Conversation access setting. Anyone who can obtain an API token effectively has unscoped conversation access, so control the API surface separately — restrict who can create tokens, and apply the REST API IP allowlist ([5.1](#51-restrict-rest-api-access-by-ip-allowlist)).

#### ClickOps Implementation

**Step 1: Set Conversation Access Per Teammate**
1. Navigate to: **Settings** → **Workspace** → **Teammates**
2. Open a teammate and find the **Conversation access** setting
3. Choose the narrowest of the four scoping options that still lets the teammate do their job — options range from access to all conversations down to only those assigned to the teammate

**Step 2: Confirm the Scope Where It Matters**
1. Verify the teammate's inbox, reports, user profiles, and mobile app all reflect the restricted scope
2. Remember that the restriction does not extend to the REST API

**Step 3: Control the API Path Separately**
1. Limit who can create API tokens for the workspace
2. Apply the REST API IP allowlist ([5.1](#51-restrict-rest-api-access-by-ip-allowlist)) so a leaked token is unusable from arbitrary networks

#### Validation & Testing
- Sign in as a scoped teammate and confirm out-of-scope conversations are not visible in the inbox, reports, or mobile app
- Confirm the workspace's API tokens are inventoried and IP-restricted, since they are the path this control does not cover

**Source:** [Limit teammates' access to conversations](https://www.intercom.com/help/en/articles/4707721-limit-teammates-access-to-conversations)

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### Rationale
**Why This Matters:**
- Admin and owner accounts can change security settings, manage teammates, and export all customer data, making them the highest-value targets
- Keeping the admin count small shrinks the attack surface and makes anomalous admin activity easier to spot
- Requiring 2FA on every admin account blocks takeover even if an admin password leaks
- A single compromised admin can disable SSO, remove logging, or exfiltrate the entire conversation history

**Attack Prevented:** Admin account takeover, privilege escalation, configuration tampering, mass data exfiltration

#### ClickOps Implementation

**Step 1: Inventory Admin Users**
1. Review all admin accounts
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit admin/owner to 2-3 users
2. Require 2FA for admins
3. Monitor admin activity

---

## 3. Data Protection

### 3.1 Configure Data Export Controls

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control data export capabilities.

#### Rationale
**Why This Matters:**
- Bulk export is the fastest path to large-scale data theft, so restricting it to admins limits who can pull customer records at scale
- Auditing export activity surfaces unusual data pulls that may indicate a compromised account or malicious insider
- Defined retention and handling policies reduce how much exportable historical data exists to be stolen
- Customer conversations contain PII subject to GDPR and CCPA, so uncontrolled export is both a breach and a compliance risk

**Attack Prevented:** Bulk data exfiltration, insider data theft, regulatory non-compliance

#### ClickOps Implementation

**Step 1: Review Export Permissions**
1. Understand export capabilities
2. Limit export access to admins
3. Audit export activities

**Step 2: Configure Data Policies**
1. Define data handling policies
2. Configure retention settings
3. Document compliance requirements

---

### 3.2 Redact Sensitive Data in Conversations

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | SC-28, AC-3 |

#### Description
Enable Intercom's two redaction features — **PAN (Primary Account Number) redaction** for payment card numbers, and **custom redaction rules** for organisation-specific patterns — so sensitive values customers volunteer in chat are not stored in readable form.

#### Rationale
**Why This Matters:**
- Customers paste card numbers, national identifiers, and account numbers into support chats regardless of what you ask them to do, so the realistic control is to catch the value on the way in rather than to prevent it being sent
- Redaction shrinks what a compromised teammate account, an over-broad export, or a breach of the conversation store actually yields
- Card data in a support transcript pulls the conversation platform into scope for obligations it was never provisioned for; redacting it at ingest keeps that surface small
- Custom rules extend the same protection to identifiers unique to your business that no vendor default will recognise

**Attack Prevented:** Payment-card exposure in support transcripts, PII harvesting from conversation history, over-broad export impact, compliance-scope creep

> **Both features are opt-in and irreversible.** PAN redaction is **off by default** — it must be explicitly enabled. Once a value is redacted, the original **cannot be recovered**, so decide before enabling that you will never need the full value from a transcript.

#### Prerequisites
- Workspace admin access
- A decision, made in advance, that redacted values will never need to be recovered

#### ClickOps Implementation

**Step 1: Enable PAN Redaction**
1. In the workspace security settings, find and enable **PAN redaction** (Intercom's own documentation is inconsistent about the exact breadcrumb — locate the setting by name; it sits with the workspace's data-protection settings)
2. Understand the behaviour before enabling:
   - Detects **15- and 16-digit** numbers that pass a **Luhn checksum**
   - Masks all but the **last 4 digits**
   - Applies across the **Web Messenger, mobile SDKs, email, and call transcripts**
   - Redaction is **irreversible**
3. Account for the false-positive risk: long numeric identifiers of the same length that happen to satisfy the Luhn check — some order numbers, reference numbers, and account IDs — will also be masked. If your business routinely exchanges 15- or 16-digit identifiers in support, test with real examples first

**Step 2: Add Custom Redaction Rules**
1. Configure **custom redaction rules** for the patterns specific to your organisation
2. Constraints to design around:
   - Up to **10 regular-expression rules**
   - A matching value is replaced with **asterisks across the full match**
3. Write rules narrowly — an over-broad expression destroys legitimate conversation content just as permanently as it redacts a secret

**Step 3: Verify**
1. Send a test message containing a sample card number through the Web Messenger and confirm only the last 4 digits remain
2. Test each custom rule against both a value it should catch and a similar value it should not

#### Validation & Testing
- Confirm PAN redaction is enabled and verify masking end-to-end through the Messenger
- Confirm each custom rule matches its intended pattern and nothing else
- Review a sample of recent conversations for values that should have been caught but were not

**Sources:** [Redacting Primary Account Numbers (PAN) in conversations](https://www.intercom.com/help/en/articles/8524626-redacting-primary-account-numbers-pan-in-conversations) · [Redacting sensitive data in conversations with custom rules](https://www.intercom.com/help/en/articles/13925174-redacting-sensitive-data-in-conversations-with-custom-rules)

---

## 4. Monitoring & Compliance

### 4.1 Monitor Teammate Activity Logs

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-6 |

#### Description
Review Intercom's teammate activity logs, and pull them into your own monitoring so detection does not depend on someone opening the page.

#### Rationale
**Why This Matters:**
- Activity logs provide the audit trail needed to detect account compromise, role changes, and unusual data exports
- Without monitoring, attacker actions such as privilege changes or bulk exports go unnoticed until damage is done
- Logged authentication and configuration events support incident investigation and forensic timelines
- Many compliance frameworks require auditable records of security-relevant activity for customer-data platforms

**Attack Prevented:** Undetected account compromise, unmonitored privilege changes, delayed breach detection

#### ClickOps Implementation

**Step 1: Access the Activity Logs**
1. Navigate to: **Settings** → **Workspace** → **Teammates** → **Activity logs**
2. Activity logs are available on **all plans** — this is not an Enterprise-gated control
3. The UI shows approximately **1 year** of history; older events remain retrievable through the REST API

**Step 2: Monitor Key Events**
1. Teammate authentication
2. Permission and role changes
3. Data exports
4. Workspace and security configuration changes — including changes to the REST API IP allowlist, which are recorded here

**Step 3: Get the Logs Out of Intercom**
1. **CSV download** for point-in-time review and evidence
2. **Activity Logs API** for scheduled collection into your SIEM, and for events older than the ~1 year UI window
3. **Webhook subscriptions** for real-time delivery — this is the option that supports alerting rather than after-the-fact review

#### Validation & Testing
- Confirm the events above appear in the log after you perform them
- Confirm your SIEM or webhook consumer is actually receiving events, not just configured to
- Confirm log retrieval beyond one year works before you need it in an investigation

**Source:** [Review actions taken in your workspace with teammate activity logs](https://www.intercom.com/help/en/articles/4667982-review-actions-taken-in-your-workspace-with-teammate-activity-logs)

---

### 4.2 Run the Workspace Security Health Check

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1, 6.5 |
| NIST 800-53 | CA-7 |

#### Description
Use Intercom's built-in Security Health Check as a standing review of the workspace's security posture across authentication, Messenger, data protection, and mobile SDK configuration.

#### Rationale
**Why This Matters:**
- The health check compresses the review into one page, which is the difference between a posture review that happens quarterly and one that happens when someone remembers
- It covers surfaces that are easy to configure once and never revisit — Messenger security and mobile SDK configuration in particular
- A vendor-authored check reflects settings Intercom has added since your last review, catching drift you would not know to look for
- It gives a defensible, repeatable artefact for access reviews and audits

**Attack Prevented:** Configuration drift, unnoticed insecure defaults, unreviewed Messenger and SDK exposure

#### ClickOps Implementation

**Step 1: Open the Health Check**
1. Navigate to: **Settings** → **Workspace** → **Security** → **Health Check**

**Step 2: Work Each Area**
1. **Authentication & Access** — SSO, 2FA, session length, IP restrictions
2. **Messenger Security** — Messenger configuration and authentication
3. **Data Protection** — redaction and data-handling settings
4. **Mobile SDKs** — SDK configuration for your mobile apps

**Step 3: Resolve and Re-run**
1. Each area reports either **Secure** or **Issues found**
2. Treat every **Issues found** result as an owned, dated work item
3. Re-run the check on a defined cadence and after any significant workspace change

#### Validation & Testing
- Confirm every area reports **Secure**, or that each outstanding issue has a named owner and a decision recorded
- Re-run after remediation to confirm the status actually changed

**Source:** [Workspace security health check](https://www.intercom.com/help/en/articles/12609760-workspace-security-health-check)

---

## 5. API Security

### 5.1 Restrict REST API Access by IP Allowlist

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17, AC-3 |

#### Description
Restrict which source IP addresses may call the Intercom REST API, so a leaked API token is unusable from anywhere but your own infrastructure.

#### Rationale
**Why This Matters:**
- API tokens are long-lived bearer credentials with no MFA prompt, and they end up in code, CI logs, and config files — an IP allowlist is what makes a leaked token worthless to whoever finds it
- The REST API is explicitly **exempt from the workspace IP restrictions** ([1.4](#14-restrict-workspace-access-by-ip)), which is precisely why this separate control exists; hardening the web app does nothing for the API
- The API returns **full conversation access regardless of a teammate's Conversation access scoping** ([2.2](#22-limit-conversation-access)), so the API is the widest data path in the workspace and deserves the strongest network control
- The allowlist covers **all REST authentication methods**, so there is no side door left by a different token type

**Attack Prevented:** Stolen API token reuse, automated data exfiltration via API, credential abuse from unknown hosts, conversation-scoping bypass

> **Fail-open by design — an empty list permits everything.** If REST API access restrictions are **turned off, or turned on with an empty allowlist, all IP addresses are permitted**. This does not fail closed. Enabling the feature is not the control; populating it is. Verify the list is non-empty and contains what you expect.

#### Prerequisites
- Workspace admin access
- The egress IP addresses of every system that calls the Intercom API, including CI runners and third-party integrations
- Addresses must be **IPv4 or CIDR ranges** — IPv6 is not supported

#### ClickOps Implementation

**Step 1: Inventory Your API Callers**
1. Enumerate every service that calls the Intercom REST API and its egress addresses
2. Include CI/CD runners, serverless functions with variable egress, and any third-party integration that calls Intercom on your behalf — these are the ones that break after the allowlist is applied
3. Confirm each address is IPv4 or expressible as a CIDR range

**Step 2: Configure the Allowlist**
1. Navigate to: **Settings** → **Security** → **Workspace** → **REST API access restrictions**
2. Enable the restriction and add every address from your inventory
3. **Confirm the list is not empty before you rely on it** — an enabled-but-empty allowlist permits all IP addresses

**Step 3: Verify and Monitor**
1. Non-allowlisted requests receive a **403** response — test this from an address outside the list
2. Changes to the allowlist are recorded in the **Teammate activity logs** ([4.1](#41-monitor-teammate-activity-logs)); alert on them, because a quiet addition to this list is how an attacker would re-enable their own access
3. Re-review whenever integration infrastructure changes

#### Validation & Testing
- Confirm an API call from an allowlisted address succeeds and one from elsewhere returns 403
- Confirm the allowlist contains at least one entry and no unexplained ones
- Confirm allowlist modifications appear in the activity log and are alerted on

**Source:** [Restrict REST API access by IP allowlist](https://www.intercom.com/help/en/articles/13941009-restrict-rest-api-access-by-ip-allowlist) (launched 2026-03-13)

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Intercom Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Teammate permissions | [2.1](#21-configure-team-roles) |
| CC6.3 | SCIM provisioning | [1.5](#15-provision-teammates-with-scim) |
| CC6.6 | IP restrictions | [1.4](#14-restrict-workspace-access-by-ip) |
| CC6.7 | REST API IP allowlist | [5.1](#51-restrict-rest-api-access-by-ip-allowlist) |
| CC7.2 | Activity logs | [4.1](#41-monitor-teammate-activity-logs) |

### NIST 800-53 Rev 5 Mapping

| Control | Intercom Control | Guide Section |
|---------|------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-enforce-two-factor-authentication) |
| AC-2 | SCIM provisioning | [1.5](#15-provision-teammates-with-scim) |
| AC-6 | Teammate permissions | [2.1](#21-configure-team-roles) |
| AC-12 | Session length | [1.3](#13-configure-session-security) |
| AC-17 | IP restrictions | [1.4](#14-restrict-workspace-access-by-ip) · [5.1](#51-restrict-rest-api-access-by-ip-allowlist) |
| SC-28 | Conversation redaction | [3.2](#32-redact-sensitive-data-in-conversations) |
| AU-2 | Activity logs | [4.1](#41-monitor-teammate-activity-logs) |
| CA-7 | Security Health Check | [4.2](#42-run-the-workspace-security-health-check) |

---

## Appendix A: References

**Official Intercom Documentation:**
- [Help Center](https://www.intercom.com/help/en/)
- [Security & Privacy Collection](https://www.intercom.com/help/en/collections/384-security-privacy)
- [Protect Your Account with 2FA, Google Sign-on or SAML SSO](https://www.intercom.com/help/en/articles/181-protect-your-account-with-2fa-google-sign-on-or-saml-sso)
- [Update Your Identity Provider with Intercom's New SAML Certificate by Dec 2026](https://www.intercom.com/help/en/articles/13436367-update-your-identity-provider-with-intercom-s-new-saml-certificate-by-dec-2026)
- [SCIM Provisioning](https://www.intercom.com/help/en/articles/5798401-system-for-cross-domain-identity-management-scim-provisioning)
- [Restricting Access Using IP Restrictions](https://www.intercom.com/help/en/articles/8931206-restricting-access-to-your-intercom-workspace-using-ip-restrictions)
- [Restrict REST API Access by IP Allowlist](https://www.intercom.com/help/en/articles/13941009-restrict-rest-api-access-by-ip-allowlist)
- [Setting a Custom Session Length for Teammates](https://www.intercom.com/help/en/articles/8931217-setting-a-custom-session-length-for-teammates-on-your-workspace)
- [Teammate Permissions](https://www.intercom.com/help/en/articles/176-teammate-permissions-how-to-control-workspace-access)
- [Limit Teammates' Access to Conversations](https://www.intercom.com/help/en/articles/4707721-limit-teammates-access-to-conversations)
- [Redacting Primary Account Numbers (PAN)](https://www.intercom.com/help/en/articles/8524626-redacting-primary-account-numbers-pan-in-conversations)
- [Redacting Sensitive Data with Custom Rules](https://www.intercom.com/help/en/articles/13925174-redacting-sensitive-data-in-conversations-with-custom-rules)
- [Teammate Activity Logs](https://www.intercom.com/help/en/articles/4667982-review-actions-taken-in-your-workspace-with-teammate-activity-logs)
- [Workspace Security Health Check](https://www.intercom.com/help/en/articles/12609760-workspace-security-health-check)
- [Team Management](https://www.intercom.com/help/en/collections/3181-teammates-and-permissions)

**API & Developer Tools:**
- [Intercom Developer Hub](https://developers.intercom.com/)
- [Intercom REST API Reference](https://developers.intercom.com/docs/references/rest-api/api.intercom.io/Articles/article/)

**Compliance Frameworks:**
- Intercom publishes its certification and audit-report status through its Trust Center and legal pages. Those are compliance attestations rather than hardening documentation and are deliberately not cited as sources in this guide — request the current reports from Intercom and treat their stated scope as authoritative rather than any summary reproduced here. Intercom documents the request process at [Accessing Security and Compliance Documents](https://www.intercom.com/help/en/articles/7053674-accessing-security-and-compliance-documents).

**Deprecation Notice:**
- **Messenger Identity Verification is deprecated** in favour of **JWT-based Messenger authentication**. No control in this guide currently covers Messenger authentication; any future control on that surface must target JWTs rather than the legacy identity-verification mechanism. ([Migrating from Identity Verification to Messenger security with JWTs](https://www.intercom.com/help/en/articles/10807823-migrating-from-identity-verification-to-messenger-security-with-jwts))

**Security Incidents:**
- No major public security incidents identified as of February 2026.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | **Deadline added: Intercom is rotating its SAML certificate and identity providers must carry the new certificate before 2026-12-12 or SAML logins will fail — bolded callout leads control 1.1.** Currency pass against intercom.com/help. Corrections: SAML SSO is Enterprise-only, not Enterprise-or-Pro (1.1, with a per-plan authentication matrix); 1.1 gains Intercom's own instruction to disable email/password logins after requiring SSO; 2.1 rewritten — Intercom uses granular per-teammate permissions and Custom Roles, not an Owner/Admin/Teammate ladder; 2.2 rewritten around the per-teammate Conversation access setting, and now states that the REST API continues to allow full conversation access regardless of that scoping; 3.2 rewritten around the two real features, opt-in Luhn-checked PAN redaction (irreversible, false-positive risk on long identifiers) and up to 10 custom regex redaction rules; 4.1 corrected — activity logs live at Settings → Workspace → Teammates → Activity logs, are available on all plans, retain ~1 year in the UI with older events via the API, and support CSV, Activity Logs API, and webhooks. Changed default: web sessions last 4 days of activity (1.3), shortened via the re-authentication setting. New controls: 1.4 workspace IP restrictions (web + mobile; REST API exempt), 1.5 SCIM provisioning (IdP removal permanently deletes the teammate), 4.2 workspace Security Health Check, and a new section 5 API Security with 5.1 REST API IP allowlist (launched 2026-03-13; fail-open — off or empty list permits all IPs; IPv4/CIDR only; 403 for non-allowlisted; changes logged in Teammate activity). Compliance Quick Reference renumbered 5 → 6 to accommodate the new section; no control was renumbered. Also: Workspace level added to all Settings → Security navigation paths; dead SAML article 2729674 replaced; Trust Center, /security, and legal/security-policy links dropped from Appendix A per the hardening-source standard, with compliance claims re-sourced honestly; deprecation notice added for Messenger Identity Verification in favour of JWT-based Messenger authentication. Tier 2 survey found no CIS Benchmark, DISA STIG, or CISA SCuBA baseline for Intercom; Tier 3/4 research not surveyed this pass | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, roles, and data protection | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
