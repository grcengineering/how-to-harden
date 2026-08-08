---
layout: guide
title: "Google Drive Hardening Guide"
vendor: "Google Drive"
slug: "google-drive"
platform: "Google Workspace"
platform_slug: "google-workspace"
product: "Google Drive"
tier: "1"
category: "Productivity"
description: "Security hardening for Google Drive — external sharing restrictions, trust rules, general access defaults, shared drive lockdown, DLP for Drive, Drive SDK and Drive for desktop controls, ransomware detection, and Drive log monitoring."
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

Google Drive is the primary file-collaboration and storage surface of Google Workspace, and oversharing is the single biggest data-exposure risk in the platform. This guide hardens Drive-specific surfaces in the Admin console: external sharing posture and trust rules, the general access default applied to every newly created file, access checking, visitor sharing, shared drive creation and download restrictions, Drive-targeted DLP, third-party API access via the Drive SDK, the Drive for desktop sync client, ransomware detection, and the log events that turn Drive into a detection sensor.

This is a **product guide within the [Google Workspace platform](/guides/google-workspace/)**. Platform-wide controls (authentication, OAuth app allowlisting, the DLP engine itself, admin audit logging) live in the Google Workspace **Common Controls** hub and are referenced here rather than duplicated.

Nearly every Drive hardening setting is **ClickOps-only by design**: Google publishes no Admin SDK or Terraform resource that mutates Drive and Docs sharing settings. Controls below state their real automation surface honestly — where none exists, none is claimed.

### Intended Audience
- Security engineers managing Google Workspace / Google Drive
- IT administrators configuring Admin console Drive and Docs settings
- GRC professionals mapping Drive posture to CISA SCuBA and BOD 25-01
- Incident responders investigating data exposure and ransomware in Drive

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Drive-specific hardening in the Google Workspace Admin console: external sharing options, trust rules, the general access default, access checker, visitor sharing, offline access, shared drive creation settings, DLP for Drive rules, Drive SDK API access, Drive for desktop, ransomware detection, and Drive log events. Platform-wide authentication, OAuth allowlisting, the DLP engine, and admin audit logging are covered in the [Google Workspace guide](/guides/google-workspace/). Gmail and Google Chat are covered in their own product guides.

The primary compliance mapping used here is the **CISA SCuBA Secure Configuration Baseline for Drive and Docs** ([ScubaGoggles baseline](https://github.com/cisagov/ScubaGoggles/blob/main/scubagoggles/baselines/drive.md)) — it carries 17 machine-checkable `GWS.DRIVEDOCS.x.xvx` policy IDs, several with binding BOD 25-01 requirements, and the [ScubaGoggles](https://github.com/cisagov/ScubaGoggles) tool programmatically assesses them.

---

## Table of Contents

1. [Sharing & Access Control](#1-sharing--access-control)
2. [Shared Drives](#2-shared-drives)
3. [Data Loss Prevention](#3-data-loss-prevention)
4. [Third-Party & Client Access](#4-third-party--client-access)
5. [Malware & Ransomware](#5-malware--ransomware)
6. [Monitoring & Detection](#6-monitoring--detection)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Sharing & Access Control

### 1.1 Configure External Drive Sharing Restrictions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3, AC-4, AC-22 |
| CISA SCuBA | GWS.DRIVEDOCS.1.2v1, 1.3v1, 1.5v1, 1.7v1, 1.9v1, 1.10v1, 1.11v1 |

#### Description
Set **Sharing outside of your organization** to Off or Allowlisted domains, then tighten the six supporting toggles that decide whether users are warned, whether inbound external files are accepted, whether "anyone with the link" content can be published, whether external files are visually marked, and whether Forms can exchange responses across the organizational boundary.

#### Rationale
**Why This Matters:**
- Oversharing is the biggest security risk in Google Workspace, and the sharing-options page is where the organizational boundary is actually drawn
- The warning and highlight toggles are the only user-facing signals that a file has left the organization — without them, an external share is indistinguishable from an internal one
- Inbound sharing is the neglected half: accepting files from arbitrary external domains creates a malware and social-engineering delivery path that outbound restrictions do nothing about
- Forms are a sharing surface most external-sharing reviews miss entirely, and they carry their own two SCuBA policies

**Attack Prevented:** Data exfiltration and accidental data exposure through unrestricted external Drive sharing, plus inbound malicious-file delivery from untrusted domains

#### Prerequisites
- Inventory of current sharing policies
- Business requirements for external collaboration, with the collaborating domains enumerated
- Drive and Docs settings administrator privilege

#### ClickOps Implementation

**Step 1: Set the External Sharing Posture**
1. Navigate to: **Admin console** → **Apps** → **Google Workspace** → **Drive and Docs**
2. Click **Sharing settings** → **Sharing options**
3. Select the organizational unit or configuration group (configuration-group settings override organizational-unit settings)
4. Set **Sharing outside of your organization** to **Off**, or to **Allowlisted domains** where external collaboration is genuinely required
5. Click **Save**

**Step 2: Enable Sharing Warnings**
1. In the same **Sharing options** panel, check **Warn when files owned by users or shared drives in your organization are shared outside of your organization**
2. When operating in **Allowlisted domains** mode, keep the equivalent warning enabled for shares to allowlisted-domain users — SCuBA GWS.DRIVEDOCS.1.3v1 makes this warning mandatory even for trusted domains
3. Click **Save**

**Step 3: Set the Default Access Level for New Files**
1. The default access level applied to every newly created item is governed by **General access default**, on the same **Sharing settings** page
2. Set it to **Private to the owner** — see [1.2](#12-set-the-general-access-default-to-private-to-the-owner) for the full option list and rollout guidance

> **Correction (2026-08-08):** earlier revisions of this control instructed administrators to find a setting called "Link sharing default." No Admin console setting carries that name. The real setting is **General access default**, documented at [Set general access sharing options](https://knowledge.workspace.google.com/admin/drive/set-general-access-sharing-options-for-your-organization) and covered in [1.2](#12-set-the-general-access-default-to-private-to-the-owner).

**Step 4: Block Inbound Files from Untrusted Domains**
1. Deselect the option allowing users and shared drives in your organization to receive files from users outside allowlisted domains (SCuBA GWS.DRIVEDOCS.1.2v1)
2. Where external sharing remains on for a business unit, disable content availability to **anyone with the link** for that organizational unit (SCuBA GWS.DRIVEDOCS.1.5v1)
3. Click **Save**

**Step 5: Stop Content Leaving to Externally Owned Shared Drives**
1. In the same **Sharing options** panel, set **Distributing content outside of your domain** to **No one**
2. Once a document is moved into a shared drive owned by another organization, your organization no longer controls its dissemination — this setting is what prevents the move (SCuBA GWS.DRIVEDOCS.1.7v1)
3. Click **Save**

**Step 6: Mark External Files**
1. Check **Highlight external files** so files shared with or owned by people outside your organization are visibly marked as external (SCuBA GWS.DRIVEDOCS.1.9v1)
2. Click **Save**

**Step 7: Govern Forms Across the Boundary**
1. On the **Sharing settings** page, locate the two Forms controls: **Users in your domain can respond to forms created externally** and **Users can share forms externally for responses**
2. If external sharing is not allowed, uncheck the option allowing forms owned by your users to accept responses from outside the organization (SCuBA GWS.DRIVEDOCS.1.10v1)
3. If receiving external files is not allowed, uncheck the option allowing your users to submit responses to externally created forms (SCuBA GWS.DRIVEDOCS.1.11v1)
4. Click **Save**

**Step 8: Scope Exceptions to Organizational Units**
1. Select the organizational unit that genuinely requires external collaboration from the left panel
2. Override only the specific toggles that unit needs, leaving every other setting inherited
3. Record the business justification and an owner for each override

> Changes can take up to 24 hours to propagate; during that window old and new settings may be intermittently enforced.

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="google-drive" section="1.1" %}

> **Automation surface:** Google publishes no API that mutates Drive sharing settings. The pack below builds the supporting organizational-unit and group structure and audits externally shared files; the sharing toggles themselves are Admin console only.

#### Validation & Testing
1. Create a test file and confirm it is not externally shareable outside the configured posture
2. Attempt a share to a non-allowlisted domain and confirm it is blocked, and to an allowlisted domain and confirm the warning fires
3. Ask an external test account to share a file inbound and confirm the configured inbound posture is enforced
4. Confirm an externally owned file in a test user's Drive carries the external highlight
5. Audit existing files with external sharing before and after the change

**Expected result:** External sharing off or allowlist-restricted, warnings on, inbound sharing controlled, external files highlighted, and Forms aligned to the same boundary. ([Manage external sharing](https://knowledge.workspace.google.com/admin/drive/manage-external-sharing-for-your-organization))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **SOC 2** | CC6.7 | Restrict transmission of information |
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | AC-4 | Information flow enforcement |
| **NIST 800-53** | AC-22 | Publicly accessible content |
| **CISA SCuBA** | GWS.DRIVEDOCS.1.2v1, 1.3v1, 1.5v1, 1.7v1 | Inbound sharing, warnings, link availability, external shared-drive distribution |
| **CISA SCuBA** | GWS.DRIVEDOCS.1.9v1 | Out-of-domain file-level warnings |
| **CISA SCuBA** | GWS.DRIVEDOCS.1.10v1, 1.11v1 | Forms responses across the boundary |

---

### 1.2 Set the General Access Default to Private to the Owner

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3, AC-22 |
| CISA SCuBA | GWS.DRIVEDOCS.1.8v1 |

#### Description
Set **General access default** to **Private to the owner** so every newly created Drive item starts closed and is opened deliberately, rather than starting open to the whole organization and relying on users to close it.

#### Rationale
**Why This Matters:**
- This one setting decides the starting permission of every file every user creates from now on — no other Drive control has the same multiplier
- The permissive options make new files discoverable through Drive search organization-wide, which converts a single mis-filed document into an internally public one without any user action
- Broad defaults are invisible to the creator: nothing in the Docs or Sheets interface announces that a new file is already readable by thousands of colleagues

**Attack Prevented:** Insider data discovery and lateral information gathering against files that were never intentionally shared, and the compromised-account blast radius that follows from it

#### Prerequisites
- Drive and Docs settings administrator privilege
- If you intend to use a target-audience option instead, target audiences must already be defined under **Sharing settings** → **Target audiences**

#### ClickOps Implementation

**Step 1: Set the Default**
1. Navigate to: **Admin console** → **Apps** → **Google Workspace** → **Drive and Docs**
2. Click **Sharing settings** and locate **General access default**
3. Select the organizational unit or configuration group
4. Choose the hardened value — **Private to the owner** (only the file owner can access new files)
5. Click **Save**

**Step 2: Understand the Alternatives Before Choosing Anything Looser**

The five documented options, from most restrictive to least:

| Option | Effect | Hardened? |
|--------|--------|-----------|
| **Private to the owner** | Only the file owner can access new files | ✅ Hardened value |
| **The primary target audience can access the item if they have the link** | Scoped to a defined audience, link required | Acceptable with a narrow audience |
| **The primary target audience can search and find the item** | Scoped to a defined audience, discoverable in search | Weaker — discoverable |
| **Anyone in your organization can access the item if they have the link** | Whole organization, link required | ❌ Not hardened |
| **Anyone in your organization can search and find the item** | Whole organization, discoverable in search | ❌ Least restrictive |

> The target-audience options appear only for organizations that have defined target audiences; organizations without them see the "Anyone in your organization" pair instead. The primary target audience is the one automatically suggested to users when they share.

**Step 3: Allow for Propagation**
1. Allow up to 24 hours for the change to take effect
2. During that window old and new settings may be intermittently enforced — do not treat an inconsistent test result inside 24 hours as a failure

> This setting applies to newly created items only. Existing files retain the access level they already have — plan a separate remediation sweep for the historical corpus.

**Time to Complete:** ~15 minutes plus up to 24 hours propagation

#### Validation & Testing
1. After propagation, create a new Doc as a standard user and open its sharing dialog — general access should read as restricted to the owner
2. From a second internal account, search for the new file by exact title and confirm it is not discoverable
3. Spot-check one file per organizational unit that overrides the default

**Expected result:** Every newly created Drive item is private to its owner until explicitly shared. ([Set general access sharing options](https://knowledge.workspace.google.com/admin/drive/set-general-access-sharing-options-for-your-organization))

> **Automation surface:** ClickOps only — no documented API mutates the general access default.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | AC-22 | Publicly accessible content |
| **CISA SCuBA** | GWS.DRIVEDOCS.1.8v1 | "Private to owner" default for new items (BOD 25-01) |

---

### 1.3 Adopt Trust Rules for Granular Drive Sharing Policy

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-4, AC-21 |
| CISA SCuBA | GWS.DRIVEDOCS.1.1v1 |

#### Description
Replace the single organization-wide external-sharing switch with trust rules: named rules that pair an internal condition (user, organizational unit, group, or the whole organization) with an external condition (a specific external organization, allowlisted domains, or anyone with a Google Account) and an action of allow, allow with warning, or block. This is how a legal team shares with outside counsel while engineering shares with nobody.

#### Rationale
**Why This Matters:**
- The classic sharing toggle is binary per organizational unit, so a single partner relationship forces you to relax policy for an entire population
- Trust rules make the sharing boundary directional and named, which turns "who can we share with" from tribal knowledge into an auditable list
- "Allow with warning" gives you a middle setting the classic controls do not have — collaboration continues while the user is told the file is leaving the organization

**Attack Prevented:** Data exfiltration to unapproved external organizations, and the over-broad exception grants that a coarse organization-wide sharing switch forces administrators to make

#### Prerequisites
- Editions: Frontline Plus; Enterprise Standard and Enterprise Plus; Education Standard and Education Plus; Enterprise Essentials Plus
- A documented inventory of approved external collaboration partners before you begin
- Super administrator or a role with rule-management privilege

> **⚠️ Irreversible transition — read before enabling.** Turning trust rules on makes the classic Drive setting under **Sharing options** → **Sharing outside of your organization** unusable; your existing settings are converted into equivalent rules. If you later disable trust rules, your Drive sharing settings become active again and revert to their state when trust rules were turned on — and **every trust rule you created is permanently deleted**. There is no export-and-restore path. Build and record your rule set outside the console before you commit.

#### ClickOps Implementation

**Step 1: Create the Rule**
1. Navigate to: **Admin console** → **Menu** → **Rules**
2. Click **Create rule** → **Trust**
3. Name the rule after the relationship it encodes (for example, "Legal to outside counsel")

**Step 2: Define the Conditions**
1. Set the **internal** condition to the population the rule governs: **User**, **Organizational unit**, **Group**, or **My organization**
2. Set the **external** condition to the counterparty: **External organization**, **Allowlisted domains**, or **Anyone with a Google Account**
3. Decide whether to **include visitors and guest accounts** — leave this off unless you have deliberately accepted the visitor-sharing risk in [1.5](#15-disable-visitor-sharing-to-accounts-without-google-identities)

**Step 3: Set the Action**
1. Choose **Allow**, **Allow with warning**, or **Block**
2. Order the rules so the most restrictive relationships are unambiguous, and end with a default-deny posture for anything not explicitly allowed
3. Save the rule and repeat for each approved relationship

**Time to Complete:** ~2 hours for an initial rule set

#### Validation & Testing
1. From an account inside each governed population, attempt a share to an approved external domain and confirm the expected allow/warn behavior
2. Attempt a share to an unapproved external domain and confirm the block
3. Confirm the classic **Sharing outside of your organization** setting now reads as inactive
4. Re-review the rule list quarterly against the partner inventory

**Expected result:** Sharing decisions expressed as named, auditable rules with a default-deny posture for unlisted counterparties. ([Create and manage trust rules for Drive sharing](https://knowledge.workspace.google.com/admin/security/create-and-manage-trust-rules-for-drive-sharing))

> **Automation surface:** ClickOps only — trust rules have no documented management API.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.7 | Restrict transmission of information |
| **NIST 800-53** | AC-4 | Information flow enforcement |
| **NIST 800-53** | AC-21 | Information sharing |
| **CISA SCuBA** | GWS.DRIVEDOCS.1.1v1 | External sharing restricted to allowlisted domains (BOD 25-01) |

---

### 1.4 Set Access Checker to Recipients Only

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3, AC-22 |
| CISA SCuBA | GWS.DRIVEDOCS.1.6v1 |

#### Description
Set Access Checker to **Recipients only**, so that when a user attaches or links a Drive file that the recipient cannot open, the only permission Drive offers to grant is to that specific recipient — not to the whole organization and not to the public.

#### Rationale
**Why This Matters:**
- Access Checker fires at the exact moment a user is trying to get something sent, which is the moment they will accept whatever permission the dialog suggests
- The least restrictive option offers "public" as a one-click remedy, converting a delivery inconvenience into an internet-readable file
- The organization-wide option quietly widens audiences file by file until internal search becomes a data-discovery tool for any compromised account

**Attack Prevented:** Accidental public exposure and unintended organization-wide access granted through the share-time convenience prompt

#### ClickOps Implementation

**Step 1: Restrict the Options Offered**
1. Navigate to: **Admin console** → **Apps** → **Google Workspace** → **Drive and Docs**
2. Click **Sharing settings** → **Sharing options**
3. Select the organizational unit or configuration group
4. Under **Access Checker**, choose the most restrictive option: **Recipients only**
   - **Recipients only, your organization, or public** — least restrictive
   - **Recipients only or your organization** — more restrictive
   - **Recipients only** — most restrictive, and the hardened value
5. Click **Save**

> **Documented gotcha:** when users share files they do not own, the sharing options come from the **file owner's** organizational unit — not the sharer's. When a user shares many files at once, the options come from the **most restrictive** organizational unit involved. A permissive Access Checker setting left on any single organizational unit therefore leaks into shares performed by users elsewhere in the organization.

**Time to Complete:** ~10 minutes

#### Validation & Testing
1. As a standard user, attach a Drive file to a Gmail message addressed to someone without access and confirm the only offered remedy is granting that recipient access
2. Repeat as a user in each organizational unit, including any unit that overrides the setting
3. Confirm no organizational unit retains the "or public" option

**Expected result:** Access Checker offers recipient-scoped grants only, org-wide. ([Restrict the access users can give to files](https://knowledge.workspace.google.com/admin/drive/restrict-the-access-users-can-give-to-files))

> **Automation surface:** ClickOps only.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | AC-22 | Publicly accessible content |
| **CISA SCuBA** | GWS.DRIVEDOCS.1.6v1 | Access checking set to "recipients only" (BOD 25-01) |

---

### 1.5 Disable Visitor Sharing to Accounts Without Google Identities

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-3, IA-8 |
| CISA SCuBA | GWS.DRIVEDOCS.1.4v1 |

#### Description
Turn off visitor sharing so Drive items cannot be shared with people who have no Google Account. Visitor sharing authenticates recipients with a PIN-style identity verification rather than a managed identity, which means the recipient exists outside every identity control you operate.

#### Rationale
**Why This Matters:**
- A visitor is not an identity you can inventory, suspend, or subject to MFA policy — revocation is per-file, not per-account
- Verified visitor access persists for 7 days per verification, and the visitor can re-verify with the original link indefinitely, so a leaked link is a renewable credential
- A visitor holding edit access can share the file onward to another Google user, extending the audience beyond the grant the original sharer approved and beyond anything your sharing policy evaluated

**Attack Prevented:** Persistent unmanaged external access to organizational documents, and audience expansion beyond the original share through visitor-initiated resharing

#### ClickOps Implementation

**Step 1: Turn Off Visitor Sharing**
1. Navigate to: **Admin console** → **Apps** → **Google Workspace** → **Drive and Docs**
2. Click **Sharing settings** → **Sharing options**
3. Select the organizational unit or configuration group
4. Uncheck **Allow users or shared drives in your organization to share items with guest accounts and visitors without Google Accounts**
5. Uncheck **Allow sharing with guest accounts and visitors without a Google account in allowlisted domains**
6. Click **Save**

**Step 2: Provide the Sanctioned Alternative**
1. Where a genuine business need exists, route the counterparty to a Google Account (consumer accounts are acceptable) so the share is made to a durable identity
2. Confirm **Warn when files owned by users or shared drives in your organization are shared outside of your organization** remains checked so the remaining external shares are still surfaced to the sharer

**Time to Complete:** ~15 minutes

#### Validation & Testing
1. As a standard user, attempt to share a file with an email address that has no Google Account and confirm the option is unavailable
2. Audit existing visitor grants and remove those without a current business justification
3. Confirm no organizational unit still permits visitor sharing to allowlisted domains unless explicitly justified

**Expected result:** All Drive sharing is to Google identities; no PIN-verified visitor access remains unjustified. ([Share documents with visitors](https://knowledge.workspace.google.com/admin/drive/allow-sharing-to-non-google-users-with-visitor-sharing))

> **Automation surface:** ClickOps only.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2 | Registration and authorization of users |
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | IA-8 | Identification of non-organizational users |
| **CISA SCuBA** | GWS.DRIVEDOCS.1.4v1 | Disable sharing with individuals not using a Google account |

---

### 1.6 Make Offline Access to Docs, Sheets, and Slides an Explicit Decision

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.6 |
| NIST 800-53 | AC-19, SC-28, MP-7 |

#### Description
Decide deliberately whether users may enable offline access for Docs, Sheets, and Slides, or whether offline access is permitted only on managed devices through device policy. Offline access syncs recent files to local storage in Chrome and Microsoft Edge on Windows, macOS, and Linux — it is an endpoint data-at-rest decision wearing a productivity label.

#### Rationale
**Why This Matters:**
- Offline access copies organizational documents out of Drive's access-controlled boundary and onto whatever disk the browser is running on, where your Drive sharing controls no longer reach
- Google's documentation frames this purely as a productivity feature and supplies no risk guidance, so the setting is routinely left at its permissive default without any explicit decision being made
- The user-enabled option extends to "computers they trust," a trust decision made by the end user rather than by policy — on an unencrypted or shared machine that is an unmanaged copy of recent work

**Attack Prevented:** Recovery of organizational documents from endpoint storage after device loss, theft, or resale, and from shared or personal machines outside the managed estate

#### Prerequisites
- Drive and Docs settings administrator privilege
- For the device-policy option: a managed-device deployment on Windows, macOS, or Linux (device policy does not apply to ChromeOS or mobile devices)

#### ClickOps Implementation

**Step 1: Choose the Posture**
1. Navigate to: **Admin console** → **Apps** → **Google Workspace** → **Drive and Docs**
2. Click **Features and Applications** and locate **Offline**
3. Select the organizational unit or configuration group
4. Choose one of the two documented options deliberately:
   - **Allow users to enable offline access (recommended)** — recent files sync and save on the user's computer and computers they trust
   - **Control offline access using device policies** — recent files sync only on managed computers where the policy is set up
5. To deny offline access entirely for a population, leave the offline options unselected for that organizational unit
6. Click **Save**

**Step 2: Pair With Endpoint Controls**
1. Where offline access is allowed, require full-disk encryption on the devices in scope
2. Restrict the population to managed devices via the device-policy option rather than user opt-in wherever the endpoint estate supports it

> Offline access is supported in Google Chrome and Microsoft Edge only; there is no offline surface to govern in other browsers.

**Time to Complete:** ~20 minutes

#### Validation & Testing
1. As a standard user in a restricted organizational unit, confirm the offline toggle is unavailable in Drive settings
2. On a managed device in a permitted unit, enable offline access and confirm it succeeds; repeat on an unmanaged device and confirm it does not
3. Record the posture decision and its owner alongside your endpoint-encryption standard

**Expected result:** Offline access is a recorded policy decision scoped to managed devices, not an unexamined default. ([Set up offline access to Docs, Sheets, and Slides](https://knowledge.workspace.google.com/admin/drive/set-up-offline-access-to-docs-sheets-and-slides))

> **Automation surface:** ClickOps only. Note this control is a How to Harden addition — Google's page is configuration guidance with no risk framing, and no benchmark body currently covers the setting.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.7 | Restrict transmission and movement of information |
| **NIST 800-53** | AC-19 | Access control for mobile devices |
| **NIST 800-53** | SC-28 | Protection of information at rest |
| **NIST 800-53** | MP-7 | Media use |

---

## 2. Shared Drives

### 2.1 Lock Down Shared Drive Creation, Membership, and Download Rights

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 6.8 |
| NIST 800-53 | AC-3, AC-6 |
| CISA SCuBA | GWS.DRIVEDOCS.2.1v1, 2.2v1 |

#### Description
Configure the five **Shared drive creation** checkboxes so that shared drives inherit organizational policy rather than per-drive manager preference: remove the manager override, keep external members out, restrict content-manager folder sharing, and disable download, print, and copy for viewers and commenters.

#### Rationale
**Why This Matters:**
- The manager-override checkbox is the master switch: leave it checked and every hardened default below becomes advisory, overridable by any manager on any shared drive
- Shared drives are organizational assets, not personal ones — a permissive default multiplies across every drive created from that point forward, including ones nobody has reviewed
- Disabling download, print, and copy for viewers and commenters is Drive's native information-rights control, and it is the difference between "read this" and "keep a copy of this"

**Attack Prevented:** Bulk data exfiltration from shared drives by low-privilege members and external collaborators, and policy erosion through per-drive manager overrides

#### Prerequisites
- Drive and Docs settings administrator privilege
- Awareness that these settings apply to newly created shared drives and to existing ones per the scope you select

#### ClickOps Implementation

**Step 1: Open the Setting**
1. Navigate to: **Admin console** → **Apps** → **Google Workspace** → **Drive and Docs**
2. Click **Sharing settings** → **Shared drive creation**
3. Select the organizational unit or configuration group

**Step 2: Set the Five Checkboxes**

| Checkbox | Hardened state | Why |
|----------|----------------|-----|
| **Allow members with manager access to override the settings below** | ❌ Uncheck | Leaving it checked makes every setting below optional per drive (SCuBA GWS.DRIVEDOCS.2.1v1) |
| **Allow users outside your organization to access files in shared drives** | ❌ Uncheck | Keeps external identities out of organizational shared drives entirely |
| **Allow people who aren't shared drive members to be added to files** | ✅ Check | See the SCuBA callout below — the baseline requires this checked |
| **Allow content managers to share folders** | ❌ Uncheck | Folder-level sharing by content managers grants access to everything the folder will ever contain |
| **Allow viewers and commenters to download, print, and copy files** | ❌ Uncheck | Drive's native download restriction — read access without take-a-copy rights |

3. Click **Save**

> **Benchmark note — the third checkbox runs against intuition.** SCuBA GWS.DRIVEDOCS.2.2v1 states that agencies **SHALL allow** users who are not shared drive members to be added to files, and its implementation step is explicitly "Check 'Allow people who aren't shared drive members to be added to files.'" CISA's stated rationale: restricting non-member file access would force full shared-drive membership for anyone needing a single file, exposing more content than it protects. This guide follows the baseline. If your risk assessment reaches the opposite conclusion, record the deviation — do not silently invert a BOD 25-01 requirement.

**Step 3: Review Existing Shared Drives**
1. Enumerate existing shared drives and their external members
2. Remove external members from drives holding regulated or sensitive content
3. Confirm no drive relies on a manager override that no longer exists

**Time to Complete:** ~45 minutes including the existing-drive review

#### Validation & Testing
1. Create a test shared drive and confirm its per-drive settings panel no longer offers manager overrides
2. As a viewer on a test shared drive, confirm download, print, and copy are unavailable
3. Attempt to add an external identity to a shared drive and confirm it is refused
4. Confirm the non-member file-add behavior matches the baseline posture you selected

**Expected result:** Shared drives inherit organizational policy, exclude external members, and deny take-a-copy rights to viewers and commenters. ([Manage shared drives as an admin](https://knowledge.workspace.google.com/admin/drive/manage-shared-drives-as-an-admin))

> **Automation surface:** ClickOps only for the settings themselves. Shared drive inventory can be enumerated through the Drive API for audit purposes, but the creation settings have no documented write API.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **SOC 2** | CC6.3 | Access authorization |
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | AC-6 | Least privilege |
| **CISA SCuBA** | GWS.DRIVEDOCS.2.1v1 | No manager override of shared drive creation settings |
| **CISA SCuBA** | GWS.DRIVEDOCS.2.2v1 | Non-members may be added to files (BOD 25-01) |

---

## 3. Data Loss Prevention

### 3.1 Build DLP for Drive Rules with Content-Aware Blocking

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.13 |
| NIST 800-53 | AC-4, SC-7, SI-4 |

#### Description
Create Data Protection rules scoped to Drive that inspect file content and metadata and act on it — blocking external sharing or disabling download, print, and copy for commenters and viewers when a file matches a sensitive-data condition. This is the content-aware layer that catches the sensitive file an otherwise-permitted share would have carried out of the organization.

#### Rationale
**Why This Matters:**
- Sharing controls are audience-aware but content-blind: an allowlisted-domain share is permitted whether the file is a lunch menu or a customer database extract
- The "disable download, print, and copy" action is a second, content-triggered information-rights path distinct from the shared-drive checkbox in [2.1](#21-lock-down-shared-drive-creation-membership-and-download-rights) — it applies to the matching file wherever it lives
- Audit-only mode lets you measure the real match rate before enforcement, which is the difference between a rule that ships and a rule that gets rolled back after the first false positive

**Attack Prevented:** Exfiltration of regulated and sensitive data through otherwise-permitted Drive shares, and copy-out of sensitive files by users holding legitimate read access

#### Prerequisites
- Editions: Frontline Standard and Frontline Plus; Enterprise Standard and Enterprise Plus; Education Fundamentals, Education Standard, and Education Plus; Enterprise Essentials Plus
- The platform DLP engine configured per the [Google Workspace guide](/guides/google-workspace/#42-enable-data-loss-prevention-dlp)
- An inventory of the data classes you intend to detect

#### ClickOps Implementation

**Step 1: Create the Rule**
1. Navigate to: **Admin console** → **Security** → **Access and data control** → **Data protection**
2. Click **Manage Rules** → **Add rule** → **New rule**
3. Name the rule and scope it to the relevant organizational units or groups, with **Google Drive** as the application

**Step 2: Define Conditions**
1. Choose one or more condition types:
   - **Predefined content detectors** for standard personal information such as a driver's licence number or taxpayer ID
   - **Custom content detectors** built from a **Regular expression** or a **Word list** (comma-separated; capitalisation and symbols are ignored)
   - **File metadata** to evaluate attributes such as a specific file name or file extension alongside content
2. Combine conditions where a single detector produces too much noise on its own

**Step 3: Choose Actions**
1. Select the enforcement action:
   - **Block external sharing** — prevents sharing the matching file with users outside the organization
   - **Disable download, print, and copy** — with the option to apply it to commenters and viewers only
2. For a new rule, start in audit-only mode so matches are recorded without blocking
3. Set the alerting severity — **Low**, **Medium**, or **High** — and route high-severity alerts to the security team

**Step 4: Tune, Then Enforce**
1. Run in audit mode and review matches until the false-positive rate is acceptable
2. Switch the rule to its blocking action
3. Pair the rule with [1.1](#11-configure-external-drive-sharing-restrictions) so a detector still blocks sensitive content inside an otherwise-allowed external share

> Compose DLP with Context-Aware Access to add device-based conditions to the same enforcement decision.

**Time to Complete:** ~2 hours per data class, including tuning

#### Validation & Testing
1. Upload a test file containing a synthetic pattern matching a predefined detector and attempt an external share — confirm the block
2. As a viewer on a matching file, confirm download, print, and copy are unavailable
3. Confirm alerts of the configured severity reach the security team's queue
4. Review match volume monthly and retune detectors that generate persistent false positives

**Expected result:** Sensitive content is blocked from external sharing and stripped of copy-out rights regardless of the audience the sharer selected. ([Create DLP for Drive rules and custom content detectors](https://knowledge.workspace.google.com/admin/security/create-dlp-for-drive-rules-and-custom-content-detectors))

> **Automation surface:** ClickOps for rule authoring. DLP rule events surface in the security investigation tool and can be exported for downstream alerting.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.7 | Restrict transmission of information |
| **NIST 800-53** | AC-4 | Information flow enforcement |
| **NIST 800-53** | SC-7 | Boundary protection |
| **NIST 800-53** | SI-4 | System monitoring |

---

## 4. Third-Party & Client Access

### 4.1 Disable Drive SDK API Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | AC-3, CM-7 |
| CISA SCuBA | GWS.DRIVEDOCS.4.1v1 |

#### Description
Uncheck **Allow users to access Google Drive with the Drive SDK API** so third-party applications cannot reach Drive content through the Drive API, then re-admit only the integrations you have vetted by installing them as admin-installed Marketplace apps.

#### Rationale
**Why This Matters:**
- Drive API scopes give an application continuous, background access to file content — an OAuth grant that survives password resets and produces no user-visible activity
- Consent-phishing campaigns target exactly these scopes because a single user click yields persistent read access to everything that user can see
- The setting is scopeable to organizational units and configuration groups, so the blast radius of a policy exception is bounded to the population that actually needs it

**Attack Prevented:** Illicit-consent (OAuth) grants producing persistent, invisible exfiltration of Drive content that survives credential rotation

#### Prerequisites
- An inventory of business-critical Drive integrations before you flip the setting — disabling it is disruptive by design
- Drive and Docs settings administrator privilege

> **⚠️ Blast radius.** All third-party apps that use the Drive API — including apps from the Google Workspace Marketplace — stop working when this setting is disabled. The one documented exception is the compensating path: **Google Workspace Marketplace apps installed by an admin continue to work and are not affected by this setting.** Migrate legitimate integrations to admin-installed Marketplace apps before disabling, not after.

#### ClickOps Implementation

**Step 1: Inventory First**
1. Review existing OAuth grants for Drive scopes via **Security** → **Access and data control** → **API controls** → **Manage Third-Party App Access**
2. Identify which integrations are business-critical and whether each is available as a Marketplace app

**Step 2: Move Legitimate Integrations to Admin Installation**
1. Install each vetted integration from the Google Workspace Marketplace as an admin-installed app, scoped to the organizational units that need it
2. Confirm the admin-installed app functions before proceeding

**Step 3: Disable the Drive SDK**
1. Navigate to: **Admin console** → **Apps** → **Google Workspace** → **Drive and Docs**
2. Click **Features and Applications** and locate **Drive SDK**
3. Select the organization, a child organizational unit, or a configuration group
4. Uncheck **Allow users to access Google Drive with the Drive SDK API**
5. Click **Save**

**Time to Complete:** ~2 hours including the integration inventory

#### Validation & Testing
1. As a standard user, attempt to authorize a non-admin-installed third-party app requesting Drive scopes and confirm it fails
2. Confirm each admin-installed Marketplace app still functions
3. Re-review the Drive-scope grant list after the change and revoke residual grants

**Expected result:** No user-authorized third-party app can reach Drive content; vetted integrations run as admin-installed Marketplace apps. ([Allow third-party apps to access Drive files](https://knowledge.workspace.google.com/admin/drive/allow-third-party-apps-for-drive-files))

> **Automation surface:** ClickOps for the toggle. Existing grants are auditable through the Admin console API controls surface.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.3 | Access authorization |
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | CM-7 | Least functionality |
| **CISA SCuBA** | GWS.DRIVEDOCS.4.1v1 | Drive SDK access disabled |

---

### 4.2 Restrict Google Drive for Desktop to Authorized Devices

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.6, 4.1 |
| NIST 800-53 | AC-19, SC-28 |
| CISA SCuBA | GWS.DRIVEDOCS.5.1v1 |

#### Description
Either disable Google Drive for desktop entirely, or allow it only on authorized devices. An unrestricted desktop client will synchronise the user's accessible corpus onto any machine a valid credential reaches, including personal and unmanaged ones.

#### Rationale
**Why This Matters:**
- The desktop client turns a credential into a bulk-copy tool: everything the account can reach becomes local files, at machine speed, with no per-file share event to review
- Unmanaged endpoints are outside your encryption, patching, and remote-wipe controls, so a synced corpus there is a permanent copy you cannot recall
- Restricting to authorized devices keeps the productivity benefit while binding sync to the managed estate you can actually attest to

**Attack Prevented:** Bulk data exfiltration to unmanaged endpoints following credential compromise, and persistent local copies of organizational data on devices outside the managed estate

#### Prerequisites
- A device inventory and endpoint management capability if you intend to use the authorized-devices option
- Drive and Docs settings administrator privilege

#### ClickOps Implementation

**Step 1: Choose the Posture**
1. Navigate to: **Admin console** → **Apps** → **Google Workspace** → **Drive and Docs** → **Google Drive for desktop**
2. Select the organizational unit or configuration group
3. Choose one:
   - To disable sync entirely for a population, uncheck **Allow Google Drive for desktop in your organization**
   - To allow sync on the managed estate only, leave it checked and check **Only allow Google Drive for desktop on authorized devices**
4. Click **Save**

**Step 2: Register the Authorized Devices**
1. Populate the authorized-device list from your managed endpoint inventory
2. Establish an ongoing process to add and remove devices as the estate changes — a stale list either blocks legitimate work or authorizes retired hardware

**Time to Complete:** ~1 hour plus device-list population

#### Validation & Testing
1. Install Drive for desktop on an unauthorized device with valid credentials and confirm sync is refused
2. Confirm sync works on an authorized device
3. Alert on Drive log events showing large-volume sync activity from newly authorized devices

**Expected result:** Desktop sync is either off or bound to enumerated authorized devices. ([Set up Drive for desktop for your organization](https://knowledge.workspace.google.com/admin/drive/set-up-drive-for-desktop-for-your-organization))

> **Automation surface:** ClickOps for the setting; device authorization is managed through the endpoint management surface.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | Boundary protection |
| **NIST 800-53** | AC-19 | Access control for mobile devices |
| **NIST 800-53** | SC-28 | Protection of information at rest |
| **CISA SCuBA** | GWS.DRIVEDOCS.5.1v1 | Drive for Desktop enabled for authorized devices only (BOD 25-01) |

---

## 5. Malware & Ransomware

### 5.1 Keep Drive Ransomware Detection Enabled

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 11.1, 13.1 |
| NIST 800-53 | SI-3, SI-4, CP-10 |
| CISA SCuBA | GWS.DRIVEDOCS.5.2v1 |

#### Description
Confirm the default-on ransomware detection setting stays enabled: Drive automatically monitors unusual file changes to identify potential ransomware corruption, notifies affected users, and offers a bulk restore of files changed in the past 25 days. This setting is on by default, so the real control is detecting and reverting anyone who turned it off.

#### Rationale
**Why This Matters:**
- Ransomware reaching an endpoint running Drive for desktop propagates encrypted versions into Drive as ordinary file updates — the sync client cannot distinguish encryption from editing
- Detection and the 25-day bulk restore turn a corpus-wide encryption event into a recovery operation measured in hours rather than a restore-from-backup project measured in weeks
- Because it is ON by default, its absence is always the result of a deliberate change — which makes an audit-log alert on this setting a high-signal, low-noise detection

**Attack Prevented:** Ransomware corruption of the Drive corpus propagated from an infected endpoint through the desktop sync client

#### Prerequisites
- Editions: Frontline Standard and Plus; Business Standard and Plus; Enterprise Standard and Plus; Education Standard and Plus

#### ClickOps Implementation

**Step 1: Verify the Setting**
1. Navigate to: **Admin console** → **Apps** → **Google Workspace** → **Drive and Docs** → **Malware and Ransomware** → **Ransomware detection**
2. Confirm **Drive automatically monitors unusual file changes to identify potential ransomware corruption** is enabled
3. Confirm the setting is enabled for every organizational unit, not only the top level
4. Click **Save** if any change was required

**Step 2: Alert on Disablement**
1. Build an admin audit-log alert for changes to this setting — SCuBA classifies GWS.DRIVEDOCS.5.2v1 as a manual check, so a log-based alert is the practical enforcement mechanism
2. Route the alert to the security team rather than to IT operations

**Step 3: Rehearse the Restore**
1. Document the restore path: affected files across My Drive, Shared with me, and internal or external shared drives, for changes in the past 25 days
2. Confirm the notification path — affected users receive an email alert and an in-Drive notification, and administrators see alerts in the Admin console

**Time to Complete:** ~20 minutes to verify; ~1 hour to build the alert and document the restore

#### Validation & Testing
1. Confirm the setting is enabled in every organizational unit
2. Confirm the audit-log alert fires by toggling the setting in a test organizational unit and reverting it
3. Walk the restore procedure with the response team so the 25-day window is understood before it matters

**Expected result:** Ransomware detection enabled everywhere, disablement alerted, restore path rehearsed. ([Detect ransomware and recover files](https://knowledge.workspace.google.com/admin/drive/detect-ransomware-and-recover-files-in-drive-for-desktop))

> **Automation surface:** ClickOps for the setting; detection of unauthorized change is via admin audit log alerting.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.4 | Incident containment |
| **NIST 800-53** | SI-3 | Malicious code protection |
| **NIST 800-53** | CP-10 | System recovery and reconstitution |
| **CISA SCuBA** | GWS.DRIVEDOCS.5.2v1 | Monitoring for potential ransomware corruption |

---

## 6. Monitoring & Detection

### 6.1 Operationalize Drive Log Events with BigQuery Export

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 8.9 |
| NIST 800-53 | AU-2, AU-6, AU-11 |

#### Description
Build saved investigations over Drive log events for the exfiltration-relevant event types, and export Drive activity to BigQuery so investigations reach past the 7-day default window that the investigation tool shows.

#### Rationale
**Why This Matters:**
- Drive log events are where mass-download, mass-copy, and external-share bursts become visible — the signals that distinguish a compromised account from a busy one
- The investigation tool shows only the LAST 7 DAYS by default, which is shorter than the median time to discover a data-exposure incident; without export, the evidence has scrolled off before anyone looks
- Google states plainly that not all Drive activity is logged, so a detection strategy that assumes complete coverage will silently miss whole categories of access

**Attack Prevented:** Not preventive — the detection and investigation capability that makes Drive exfiltration and mass-download activity discoverable and reconstructable

#### Prerequisites
- BigQuery export editions: Frontline Standard and Plus, Enterprise Standard and Plus, Education Standard and Plus, Enterprise Essentials Plus
- A billing-enabled Google Cloud project for the export destination
- Reporting administrator privilege

#### ClickOps Implementation

**Step 1: Build Saved Investigations**
1. Navigate to: **Admin console** → **Reporting** → **Audit and investigation** → **Drive log events**
2. Widen or remove the default 7-day date filter
3. Build and save investigations across the documented event types, prioritising the exfiltration-relevant ones:
   - **Download**, **Copy** and **Source Copy**, **Print**, **Upload**
   - **View**, **Edit**, **Create**, **Rename**, **Delete**
   - **Item content synced**, **Item content prefetched**, **Item content accessed**
   - **URL Accessed**, **Sheets Import URL**, **Item search performed**
4. Prioritise investigations by volume anomaly per user rather than by single events

**Step 2: Enable BigQuery Export**
1. Navigate to: **Admin console** → **Reporting** → **Data integrations**
2. On the **BigQuery Export** card, click **Edit** and enable export to a billing-enabled BigQuery project
3. Confirm Drive activity rows land in the activity table — this is the same export mechanism used for Gmail and Chat, so a single export configuration covers all three

**Step 3: Wire Detections**
1. Alert on mass-download and mass-copy bursts per user against that user's own baseline
2. Alert on external-share events from populations that should not be sharing externally at all
3. Correlate Drive events with the desktop-sync posture from [4.2](#42-restrict-google-drive-for-desktop-to-authorized-devices)

> **Documented coverage gap.** Google states that not all activities in Drive are logged. Named exclusions include: print events for files in Google native formats (Docs, Sheets, Slides, Drawings, Forms); downloads via Google Takeout, offline browser caches, Google Photos, and Gmail attachments; and item-content-access events when files are viewed in Drive for web, mobile, or desktop apps. Treat Drive log events as a strong but incomplete sensor and compensate with DLP ([3.1](#31-build-dlp-for-drive-rules-with-content-aware-blocking)) and endpoint telemetry.

**Time to Complete:** ~2 hours

#### Validation & Testing
1. Perform a controlled bulk download as a test user and confirm the events appear in the investigation tool
2. Confirm the same events appear in BigQuery
3. Confirm the alert fires end to end and reaches the security team's queue
4. Re-test after any change to the export configuration

**Expected result:** Drive activity queryable well beyond the 7-day window, with volume-anomaly alerting wired to the security team. ([Drive log events](https://knowledge.workspace.google.com/admin/reports/drive-log-events) · [BigQuery log export](https://knowledge.workspace.google.com/admin/reports/set-up-service-log-exports-to-bigquery))

> **Automation surface:** Drive activity is queryable through the Admin SDK Reports API and, once exported, through BigQuery SQL.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | System monitoring |
| **NIST 800-53** | AU-2 | Event logging |
| **NIST 800-53** | AU-6 | Audit record review and analysis |
| **NIST 800-53** | AU-11 | Audit record retention |

---

## 7. Compliance Quick Reference

### CISA SCuBA Drive and Docs Baseline Mapping

The [SCuBA Drive and Docs baseline](https://github.com/cisagov/ScubaGoggles/blob/main/scubagoggles/baselines/drive.md) is this guide's primary authoritative mapping; the [ScubaGoggles](https://github.com/cisagov/ScubaGoggles) tool assesses these policies programmatically. Several carry binding CISA BOD 25-01 requirements for US federal agencies.

| SCuBA Policy | Requirement | Guide Section |
|--------------|-------------|---------------|
| GWS.DRIVEDOCS.1.1v1 | External sharing restricted to allowlisted domains (BOD 25-01) | [1.3](#13-adopt-trust-rules-for-granular-drive-sharing-policy) |
| GWS.DRIVEDOCS.1.2v1 | Receiving files from non-allowlisted domains disabled | [1.1](#11-configure-external-drive-sharing-restrictions) |
| GWS.DRIVEDOCS.1.3v1 | Warnings on sharing to non-allowlisted domains (BOD 25-01) | [1.1](#11-configure-external-drive-sharing-restrictions) |
| GWS.DRIVEDOCS.1.4v1 | Disable sharing with non-Google-account individuals | [1.5](#15-disable-visitor-sharing-to-accounts-without-google-identities) |
| GWS.DRIVEDOCS.1.5v1 | Disable "anyone with the link" in externally sharing OUs | [1.1](#11-configure-external-drive-sharing-restrictions) |
| GWS.DRIVEDOCS.1.6v1 | Access checking set to "recipients only" (BOD 25-01) | [1.4](#14-set-access-checker-to-recipients-only) |
| GWS.DRIVEDOCS.1.7v1 | No upload or move of content to externally owned shared drives | [1.1](#11-configure-external-drive-sharing-restrictions) |
| GWS.DRIVEDOCS.1.8v1 | "Private to owner" default for new items (BOD 25-01) | [1.2](#12-set-the-general-access-default-to-private-to-the-owner) |
| GWS.DRIVEDOCS.1.9v1 | Out-of-domain file-level warnings (BOD 25-01) | [1.1](#11-configure-external-drive-sharing-restrictions) |
| GWS.DRIVEDOCS.1.10v1 | External responses to internally owned forms | [1.1](#11-configure-external-drive-sharing-restrictions) |
| GWS.DRIVEDOCS.1.11v1 | Internal responses to externally owned forms | [1.1](#11-configure-external-drive-sharing-restrictions) |
| GWS.DRIVEDOCS.2.1v1 | No manager override of shared drive creation settings | [2.1](#21-lock-down-shared-drive-creation-membership-and-download-rights) |
| GWS.DRIVEDOCS.2.2v1 | Non-members may be added to files (BOD 25-01) | [2.1](#21-lock-down-shared-drive-creation-membership-and-download-rights) |
| GWS.DRIVEDOCS.3.1v1 | Security update for Drive files enabled (BOD 25-01) | ⚠️ Not covered — see note below |
| GWS.DRIVEDOCS.4.1v1 | Drive SDK access disabled | [4.1](#41-disable-drive-sdk-api-access) |
| GWS.DRIVEDOCS.5.1v1 | Drive for Desktop on authorized devices only (BOD 25-01) | [4.2](#42-restrict-google-drive-for-desktop-to-authorized-devices) |
| GWS.DRIVEDOCS.5.2v1 | Monitoring for ransomware corruption | [5.1](#51-keep-drive-ransomware-detection-enabled) |

> **Stated limitation — GWS.DRIVEDOCS.3.1v1.** The SCuBA baseline requires enabling the security update for Google Drive files, applied under **Sharing settings** → **Security update for files**. No live first-party Google configuration article for this setting could be resolved at authoring time, and it does not appear in Google's current Drive documentation index. Rather than transcribe console steps from memory or cite a URL that does not resolve, this guide does not yet ship the control. Administrators subject to BOD 25-01 should assess the policy directly with [ScubaGoggles](https://github.com/cisagov/ScubaGoggles) and configure it from the console until a citable vendor article is available.

### SOC 2 Trust Services Criteria Mapping

| Control ID | Drive Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | Sharing posture and access defaults | [1.1](#11-configure-external-drive-sharing-restrictions), [1.2](#12-set-the-general-access-default-to-private-to-the-owner), [1.4](#14-set-access-checker-to-recipients-only) |
| CC6.2 | External identity governance | [1.5](#15-disable-visitor-sharing-to-accounts-without-google-identities) |
| CC6.3 | Access authorization for apps and shared drives | [2.1](#21-lock-down-shared-drive-creation-membership-and-download-rights), [4.1](#41-disable-drive-sdk-api-access) |
| CC6.6 | Boundary protection for sync clients | [4.2](#42-restrict-google-drive-for-desktop-to-authorized-devices) |
| CC6.7 | Restriction of information transmission | [1.3](#13-adopt-trust-rules-for-granular-drive-sharing-policy), [1.6](#16-make-offline-access-to-docs-sheets-and-slides-an-explicit-decision), [3.1](#31-build-dlp-for-drive-rules-with-content-aware-blocking) |
| CC7.2 | System monitoring | [6.1](#61-operationalize-drive-log-events-with-bigquery-export) |
| CC7.4 | Incident containment and recovery | [5.1](#51-keep-drive-ransomware-detection-enabled) |

> **CIS note:** a CIS Google Workspace Foundations Benchmark exists, but its Drive section numbering could not be verified against the benchmark PDF at authoring time. An earlier revision of this guide asserted "CIS Google Workspace 3.1" for control 1.1; that citation was unverifiable and has been removed in favour of the SCuBA mapping. Do not add specific CIS Google Workspace control numbers without confirming them against the downloaded benchmark.

> Platform-wide compliance mappings (authentication, OAuth, the DLP engine, admin audit logging) are in the [Google Workspace guide](/guides/google-workspace/#7-compliance-quick-reference).

---

## Appendix A: Edition Compatibility

| Control | Business Starter | Business Standard/Plus | Enterprise Standard/Plus |
|---------|------------------|------------------------|--------------------------|
| Sharing options, general access default, access checker (1.1, 1.2, 1.4) | ✅ | ✅ | ✅ |
| Trust rules (1.3) | ❌ | ❌ | ✅ |
| Visitor sharing controls (1.5) | ✅ | ✅ | ✅ |
| Offline access controls (1.6) | ✅ | ✅ | ✅ |
| Shared drive creation settings (2.1) | ❌ | ✅ | ✅ |
| DLP for Drive (3.1) | ❌ | ❌ | ✅ (Standard/Plus) |
| Drive SDK toggle (4.1) | ✅ | ✅ | ✅ |
| Drive for desktop restrictions (4.2) | ✅ | ✅ | ✅ |
| Ransomware detection (5.1) | ❌ | ✅ | ✅ |
| BigQuery log export (6.1) | ❌ | ❌ | ✅ |

> Frontline, Education, and Enterprise Essentials editions carry their own entitlements — see the Prerequisites block on each control for the edition list Google documents for that feature.

---

## Appendix B: References

**Official Google Workspace Admin Documentation** (Google migrated Workspace admin docs from support.google.com/a to knowledge.workspace.google.com — cite the new host):
- [Manage external sharing for your organization](https://knowledge.workspace.google.com/admin/drive/manage-external-sharing-for-your-organization)
- [Set general access sharing options for your organization](https://knowledge.workspace.google.com/admin/drive/set-general-access-sharing-options-for-your-organization)
- [Create and manage trust rules for Drive sharing](https://knowledge.workspace.google.com/admin/security/create-and-manage-trust-rules-for-drive-sharing)
- [Restrict the access users can give to files](https://knowledge.workspace.google.com/admin/drive/restrict-the-access-users-can-give-to-files)
- [Share documents with visitors](https://knowledge.workspace.google.com/admin/drive/allow-sharing-to-non-google-users-with-visitor-sharing)
- [Set up offline access to Docs, Sheets, and Slides](https://knowledge.workspace.google.com/admin/drive/set-up-offline-access-to-docs-sheets-and-slides)
- [Manage shared drives as an admin](https://knowledge.workspace.google.com/admin/drive/manage-shared-drives-as-an-admin)
- [Create DLP for Drive rules and custom content detectors](https://knowledge.workspace.google.com/admin/security/create-dlp-for-drive-rules-and-custom-content-detectors)
- [Allow third-party apps to access Drive files](https://knowledge.workspace.google.com/admin/drive/allow-third-party-apps-for-drive-files)
- [Set up Drive for desktop for your organization](https://knowledge.workspace.google.com/admin/drive/set-up-drive-for-desktop-for-your-organization)
- [Detect ransomware and recover files in Drive for desktop](https://knowledge.workspace.google.com/admin/drive/detect-ransomware-and-recover-files-in-drive-for-desktop)
- [Drive log events](https://knowledge.workspace.google.com/admin/reports/drive-log-events)
- [BigQuery log export](https://knowledge.workspace.google.com/admin/reports/set-up-service-log-exports-to-bigquery)
- [Security checklist for medium and large businesses](https://knowledge.workspace.google.com/admin/security/security-checklist-for-medium-and-large-businesses-100-users)

**Hardening Baselines:**
- [CISA SCuBA Drive and Docs baseline (ScubaGoggles)](https://github.com/cisagov/ScubaGoggles/blob/main/scubagoggles/baselines/drive.md) — primary mapping, with the [ScubaGoggles assessment tool](https://github.com/cisagov/ScubaGoggles)
- [CIS Google Workspace Foundations Benchmark](https://www.cisecurity.org/benchmark/google_workspace) — control numbering unverified for Drive; see the CIS note in section 7

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.2.0 | 2026-08-08 | First substantive currency pass: expanded from 1 control to 12 across six sections (sharing and access control, shared drives, DLP, third-party and client access, ransomware, monitoring). Corrected control 1.1's non-existent "Link sharing default" step to the real **General access default** setting and extended it with the inbound-sharing, warning, external-highlight, and Forms toggles; added trust rules, general access default, access checker, visitor sharing, offline access, shared drive lockdown, DLP for Drive, Drive SDK, Drive for desktop, ransomware detection, and Drive log events. Added the full CISA SCuBA `GWS.DRIVEDOCS` baseline mapping (16 of 17 policies) and removed the unverifiable "CIS Google Workspace 3.1" citation. |
| 0.1.0 | 2026-05-29 | Initial Google Drive product guide — split from the Google Workspace guide (control 1.1 external sharing restrictions; DLP-for-Drive cross-references the platform DLP engine). Part of the multi-product platform restructure. |

## Contributing

Found an issue or have an improvement? See the [Google Workspace platform guide](/guides/google-workspace/) for platform-wide controls, or open an issue/PR on [GitHub](https://github.com/grcengineering/how-to-harden). Follow the control structure used in the [Gmail](/guides/gmail/) and [Google Chat](/guides/google-chat/) product guides, and keep all code in Code Packs (no inline code blocks). Note the pack-authoring caution: Drive sharing settings have no documented write API — verification-style packs (ScubaGoggles, Reports API queries, Drive API audits) are the honest automation surface.
