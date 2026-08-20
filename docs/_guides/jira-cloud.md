---
layout: guide
title: "Jira Cloud Hardening Guide"
vendor: "Jira Cloud"
slug: "jira-cloud"
platform: "Atlassian"
platform_slug: "atlassian"
product: "Jira Cloud"
tier: "2"
category: "Productivity"
description: "Jira Cloud hardening for in-product authorization — permission schemes, work item security schemes, public space exposure, global permissions, guest access, and automation rule egress."
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Atlassian Jira is a leading issue tracking and project management platform used by **millions of users** for software development, IT service management, and business operations. Jira accumulates exactly the material an attacker wants after initial access: security tickets describing unpatched systems, roadmaps, customer records, and credentials pasted into comments and attachments.

This is a **product guide within the [Atlassian platform](/guides/atlassian/)**. Organization-wide controls — SAML SSO and enforced authentication policies, two-step verification, SCIM provisioning, domain verification, Atlassian Guard licensing, IP allowlisting, Marketplace app governance, API token policy, data security policies, and the organization audit log — live in the Atlassian **Common Controls** hub and are referenced here rather than duplicated. Everything below is Jira-specific: the authorization model *inside* the product, which the organization controls do not touch.

That distinction matters because the two layers fail independently. Organization controls decide **who can reach Jira at all**. The controls in this guide decide **what a legitimately authenticated user can then see and do** — and a correctly configured SSO tenant with a default-open permission scheme still exposes every space to every licensed user.

> **Terminology note.** Atlassian's Jira Cloud administration documentation now uses **space** where older documentation and much of the industry still say *project*, and **work item** where they say *issue*. The console reflects the new terms. This guide uses Atlassian's current terminology with the older term in parentheses on first use in each control, so the steps match what you actually see on screen.

### Intended Audience
- Security engineers managing Atlassian products
- Jira administrators configuring space and work item access
- GRC professionals assessing collaboration security
- Incident responders scoping what a compromised Jira account could reach

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Jira Cloud in-product authorization and extensibility: permission schemes, work item security schemes, public and anonymous space exposure, global permissions, guest access, and Jira automation. Organization authentication, app governance, and audit logging are in the [Atlassian Common Controls guide](/guides/atlassian/). Bitbucket is covered in the [Bitbucket guide](/guides/bitbucket/).

**Automation surface:** Jira Cloud exposes permission schemes, work item security schemes, and global permissions through the Jira Cloud REST API v3, but the practical hardening workflow for all of them is ClickOps — the API is most useful for *auditing* current state rather than setting it. Controls below state their real automation surface honestly.

**Plan limitation:** permission schemes, space roles, and work item security schemes **are not available on Free Jira sites**. A Free site cannot implement §1.1 or §1.2 at all. Source: [Permissions limitations in Free Jira sites](https://support.atlassian.com/jira-cloud-administration/docs/permissions-limitations-in-free-jira-sites/)

---

## Table of Contents

1. [Space & Work Item Access](#1-space--work-item-access)
2. [Global Permissions & Guests](#2-global-permissions--guests)
3. [Automation & Extensibility](#3-automation--extensibility)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Space & Work Item Access

### 1.1 Configure Permission Schemes for Least Privilege

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 5.4, 6.8 |
| NIST 800-53 | AC-3, AC-6 |
| ISO 27001:2022 | A.5.15, A.8.3 |

#### Description
A permission scheme is the reusable set of grants that decides who can browse, create, edit, comment on, transition, and administer the work in a Jira space (project). Schemes are managed at **Settings (gear icon) → Work items → Permission schemes**, and each grant can be assigned to a space role, an application-access group, a specific group, a single user, the space lead, the current assignee or reporter, a user or group picker custom field value, **Any logged in user**, or **Public**. Assigning through space roles and IdP-synced groups — rather than to individuals — is what keeps the model auditable as people change teams. Source: [Grant or revoke permissions in a scheme](https://support.atlassian.com/jira-cloud-administration/docs/grant-or-revoke-permissions-in-a-scheme/)

#### Rationale
**Why This Matters:**
- The default scheme in most tenants grants **Browse spaces** to *Any logged in user*, which means every licensed person in the company can read every space — including the security space where vulnerabilities are tracked before they are fixed
- Permission grants are the boundary that determines blast radius after a single account is phished; an attacker inherits exactly the scheme grants their victim held, and a default-open scheme hands them the whole tenant
- Granting to individuals instead of roles and groups produces access that never gets revoked, because there is no joiner/mover/leaver process that reaches individual grants inside a permission scheme
- The **Make bulk changes** and **Delete work items** grants are destructive at scale — an account holding them can silently move or delete thousands of items, which is both a data-loss and an evidence-destruction risk
- Schemes are shared across spaces, so a single careless edit made for one space silently widens access to every other space using that scheme

**Attack Prevented:** Lateral movement after account compromise, insider data harvesting, privilege creep, mass deletion or bulk modification, unauthorized workflow transitions

#### Prerequisites
- **Administer Jira** global permission
- Standard, Premium, or Enterprise plan — permission schemes are unavailable on Free sites

#### ClickOps Implementation

**Step 1: Inventory Existing Schemes and Their Grants**
1. Navigate to: **Settings (gear icon) → Work items**
2. Under **Work item attributes**, select **Permission schemes** (at the bottom of the list)
3. For each scheme, record which spaces use it and which grants it makes — a scheme applied to twenty spaces needs twenty times the scrutiny
4. Flag every grant assigned to **Any logged in user** or **Public**, and every grant assigned to a named individual rather than a role or group

**Step 2: Tighten the Browse Grant First**
1. Open a scheme and select **Permissions** in the actions column
2. Find **Browse spaces** and select **Update**
3. Replace broad grants with specific space roles or IdP-synced groups
4. Treat **Browse spaces** as the control that matters most — every other read-oriented permission is gated behind it

**Step 3: Scope the Destructive Grants**
1. Restrict **Administer spaces** to a named administrator role, not to a general developer group
2. Restrict **Delete work items** and **Delete all comments** narrowly; most users never need either
3. Confirm **Make bulk changes** is a global permission held by very few accounts (see §2.1)

**Step 4: Assign Through Roles, Not People**
1. Prefer grants to **space roles**, then populate those roles from IdP-synced groups, so access follows the identity lifecycle automatically
2. Remove every **Single user** grant you found in Step 1, replacing it with role membership
3. Where a permission scheme is used by only one space, consider whether a shared scheme would be clearer — and where a scheme is used by many, verify every one of them should have identical access

**Step 5: Review on a Cadence**
1. Re-review scheme grants quarterly, and immediately after any reorganization
2. Verify that newly created spaces picked up a restrictive scheme rather than the permissive default
3. Confirm no scheme drifted back to **Any logged in user** on the browse grant

#### Validation & Testing

1. Sign in as a low-privilege test user with product access but no space role, and confirm the sensitive spaces do not appear in the space list and are not reachable by direct URL
2. Search with JQL across all spaces as that test user and confirm no work items from restricted spaces appear in results — JQL respects browse permissions, so this is the fastest end-to-end proof
3. As the same user, attempt a bulk change and confirm the option is unavailable
4. Use **Check a user's access from a work item** on a restricted item to confirm the effective permission calculation matches your intent rather than your assumption
5. Create a new space and confirm the scheme it receives is the restrictive default, not the permissive one

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls restrict access to protected information |
| **SOC 2** | CC6.3 | Access is granted based on roles and responsibilities |
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | AC-6 | Least privilege |
| **ISO 27001:2022** | A.5.15 | Access control |
| **CIS Controls** | 3.3 | Configure data access control lists |

---

### 1.2 Restrict Sensitive Work Items with Security Schemes

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 3.12 |
| NIST 800-53 | AC-3, AC-4, AC-21 |
| ISO 27001:2022 | A.5.12, A.8.3 |

#### Description
A work item security scheme (issue security scheme) controls visibility of **individual work items within a space**, below the space-level permission boundary. Each scheme defines named security levels; a work item tagged with a level is visible only to the users, groups, and roles granted that level — a user who can otherwise browse the entire space cannot see it. Schemes are created at **Settings (gear icon) → Work items → Work item security schemes**. Applying a level requires the **Set work item security** permission, and the **Work item security** field must be present on the space's **Layout** page or nobody can set it. Source: [Create a new work item security scheme and security levels](https://support.atlassian.com/jira-cloud-administration/docs/create-a-new-work-item-security-scheme-and-security-levels/)

#### Rationale
**Why This Matters:**
- Space permissions are all-or-nothing for reading: anyone who can browse a space can read every work item in it, which breaks down the moment one space legitimately holds both routine tickets and sensitive ones
- Security levels are the only mechanism that keeps an embargoed vulnerability, an HR investigation, or a security incident ticket invisible to the wider team that shares the space — the alternative, a separate space per sensitivity tier, fragments workflow and gets abandoned
- Setting a **default** security level on the scheme means new work items are protected on creation rather than depending on someone remembering to classify them, which is the difference between a control and an aspiration
- Without a default level, the failure mode is silent: an item created without classification is fully visible, and nobody receives a signal that protection was skipped
- Security levels degrade safely under movement between spaces — but only if the destination space has a scheme. Atlassian documents that a work item moved into a space with **no** security scheme becomes "visible to anyone with access to the space," which is a real and easily-missed exposure path

**Attack Prevented:** Insider reading of embargoed vulnerability and incident tickets, over-broad exposure of HR and legal matters, information disclosure through space-wide search and JQL, exposure via cross-space work item movement

#### Prerequisites
- **Administer Jira** global permission to create schemes
- **Set work item security** permission for the users who will apply levels
- Standard, Premium, or Enterprise plan — unavailable on Free sites

#### ClickOps Implementation

**Step 1: Create the Scheme**
1. Navigate to: **Settings (gear icon) → Work items**
2. Under **Work item attributes**, select **Work item security schemes** (at the bottom of the list)
3. Select **Add work item security scheme**
4. Enter a name that states its intent, such as "Restricted — Security and Legal", and select **Add**

**Step 2: Define Security Levels**
1. Select **Security levels** in the **Action** column for your new scheme
2. In the **Add security level** section, enter a name and description for each level, then select **Add security level**. Keep the set small — two or three levels that people understand beat six that they guess at
3. Select **Default** in the **Actions** column for the level that should apply to work items created without an explicit choice. Choose the *more* restrictive level as the default; an over-restricted item gets reported and fixed, while an under-restricted one is never noticed

**Step 3: Grant Access to Each Level**
1. For each security level, add the groups, space roles, or fields (reporter, assignee) that should see items at that level
2. Prefer roles and IdP-synced groups over individuals, for the same lifecycle reason as §1.1
3. Verify that whoever needs to *triage* restricted items — the security team, for instance — holds the level, or restricted items will silently go unworked

**Step 4: Associate the Scheme and Expose the Field**
1. Associate the scheme with each space that needs it
2. Confirm the **Work item security** field appears on the space's **Layout** page — without it, nobody can set or change a level, and the scheme is inert
3. Grant the **Set work item security** permission in the space's permission scheme to the roles that need to classify items

**Step 5: Close the Cross-Space Movement Gap**
1. Identify every space that restricted work items might be moved into
2. Associate a security scheme with those spaces too, so a move cannot strip protection
3. Where a destination space genuinely has no scheme, document the risk and alert on move events for restricted items

#### Validation & Testing

1. Create a work item, apply a restricted security level, then view the space as a user who can browse the space but does not hold that level — confirm the item is absent from the space view
2. Run a JQL search as that same user across all work items and confirm the restricted item does not appear in results
3. Attempt to open the restricted item by its direct URL as that user and confirm access is refused
4. Create a work item **without** setting a level and confirm it inherits the default restrictive level rather than being unrestricted
5. Move a restricted work item to another space and confirm it lands on that space's default security level rather than becoming visible to everyone
6. Confirm the **Work item security** field is visible on the layout for every space using the scheme

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls over protected information |
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | AC-21 | Information sharing restrictions |
| **ISO 27001:2022** | A.5.12 | Classification of information |
| **CIS Controls** | 3.12 | Segment data processing and storage by sensitivity |

---

### 1.3 Eliminate Unintended Public and Anonymous Space Exposure

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 4.8 |
| NIST 800-53 | AC-3, AC-22 |
| ISO 27001:2022 | A.5.10, A.8.3 |

#### Description
Jira spaces (projects) can be exposed to unauthenticated visitors by granting the **Browse spaces** permission to **Public** in the space's permission scheme. Atlassian documents this explicitly: setting **Browse spaces** to **Public** "allows anyone to view a space and the work within it," and the permission "doesn't require Jira app access." Granting **Create work items** to **Public** additionally lets anonymous visitors file items. This control is about finding and removing that grant where it was never intended — and governing it deliberately where it was. Source: [Use permissions to make a space publicly visible](https://support.atlassian.com/jira-cloud-administration/docs/use-permissions-to-make-a-space-publicly-visible/)

#### Rationale
**Why This Matters:**
- A **Public** browse grant makes every work item in the space readable with no authentication at all, which means no SSO enforcement, no two-step verification, no IP allowlist, and no audit trail tied to a named user — every organization-level control in the platform hub is bypassed in a single grant
- The grant is made inside a permission scheme, and permission schemes are shared across spaces, so exposing one space can expose every space using the same scheme — this is the most common way public exposure happens by accident
- Publicly readable Jira content is indexed and scraped; ticket titles alone leak the technologies you run, the vulnerabilities you have not yet fixed, employee names, and customer identities, which is high-grade reconnaissance material before any exploit is attempted
- Granting **Create work items** to **Public** turns the space into an unauthenticated write surface — a spam and malicious-attachment intake with no rate limit tied to an identity
- Free sites cannot make spaces public, so this exposure appears only after an upgrade to Standard or above, which means it can arrive without anyone re-reviewing the permission model

**Attack Prevented:** Unauthenticated information disclosure, reconnaissance through indexed ticket content, bypass of SSO/MFA/IP-allowlist controls, anonymous spam and malicious attachment upload

#### ClickOps Implementation

**Step 1: Audit Every Scheme for Public Grants**
1. Navigate to: **Settings (gear icon) → Work items → Permission schemes**
2. Open each scheme and review its permissions list
3. Record every permission granted to **Public** — pay particular attention to **Browse spaces**, **Create work items**, and any comment or attachment permission
4. For each scheme carrying a Public grant, list every space using that scheme; the exposure covers all of them, not just the one you had in mind

**Step 2: Remove Unintended Public Grants**
1. Select **Update** on the affected permission and remove the **Public** grant
2. Where broad internal visibility is genuinely wanted, replace **Public** with **Any logged in user** — that keeps content inside the authenticated boundary where audit logging and authentication policy still apply
3. Re-check after each change that no space you did not intend to touch lost legitimate access

**Step 3: Govern the Spaces That Must Stay Public**
1. For a space that is intentionally public — an open-source project tracker, for instance — give it a **dedicated permission scheme used by no other space**, so the public grant can never leak sideways
2. Confirm the space holds no attachments, comments, or work items containing internal detail; treat everything in it as published
3. Do not grant **Create work items** to **Public** unless anonymous intake is a deliberate requirement, and if it is, pair it with a moderation workflow
4. Document the space in your data inventory as a public asset with a named owner and a review date

**Step 4: Make It Stick**
1. Alert on permission scheme changes in the organization audit log ([Atlassian Common Controls guide](/guides/atlassian/) §5.1)
2. Re-audit Public grants on the same cadence as §1.1, and specifically after any plan upgrade
3. Where the organization uses Atlassian data security policies, scope a policy over sensitive spaces to restrict anonymous and external access as a second, org-enforced layer that a space admin cannot override ([Atlassian Common Controls guide](/guides/atlassian/) §4.3)

#### Validation & Testing

1. Open each space's URL in a private/incognito browser window with no session and confirm you are prompted to authenticate rather than shown content
2. Repeat for a direct work item URL, not just the space home — space-level and item-level exposure can differ
3. Search for `site:yourorg.atlassian.net` in a public search engine and confirm no work item content is indexed
4. For any intentionally public space, confirm from a logged-out session that only the intended space is reachable and that no other space using the same scheme is exposed
5. As an anonymous visitor to an intentionally public space, attempt to create a work item and confirm the outcome matches your intent

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls restrict access to authorized users |
| **SOC 2** | CC6.6 | Boundary protection for external access points |
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | AC-22 | Publicly accessible content |
| **ISO 27001:2022** | A.5.10 | Acceptable use of information |
| **CIS Controls** | 3.3 | Configure data access control lists |

---

## 2. Global Permissions & Guests

### 2.1 Restrict Jira Global Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-6, AC-6(1), AC-6(7) |
| ISO 27001:2022 | A.5.15, A.8.2 |

#### Description
Global permissions apply across the whole Jira site rather than to one space, and are managed at **Settings (gear icon) → System → Global permissions**. Atlassian documents the set as **Administer Jira**, **Browse users and groups**, **Share dashboards and filters**, **Manage group filter subscriptions**, **Make bulk changes**, **Create team-managed spaces**, and **Manage custom onboarding**. Each can be granted to a group, a user, or **Anyone**, and granting or revoking requires the **Administer Jira** permission. Sources: [What are global permissions, and what do they control?](https://support.atlassian.com/jira-cloud-administration/docs/manage-global-permissions/) · [View, grant, revoke global permissions in Jira](https://support.atlassian.com/jira-cloud-administration/docs/view-grant-revoke-global-permissions-in-jira/)

#### Rationale
**Why This Matters:**
- **Administer Jira** is effectively site ownership: it grants the ability to create spaces, and to change work types, fields, workflows, permission schemes, and security schemes — which means a holder can simply rewrite the controls in §1.1 and §1.2 rather than having to defeat them
- **Make bulk changes** authorizes editing, moving, transitioning, or deleting thousands of work items in one operation, so it is simultaneously the fastest mass-exfiltration primitive (bulk move into a space the attacker can read) and the fastest destruction primitive in the product
- **Browse users and groups** exposes the full employee directory through picker fields and mentions, which is precise targeting data for phishing; without it, a user sees only people who share space access with them
- **Manage group filter subscriptions** creates scheduled emails of filter results to entire groups — an attacker with it can establish a recurring, automated exfiltration channel that looks exactly like normal Jira notification traffic and survives the loss of their session
- **Create team-managed spaces** matters because team-managed spaces are administered by their creator outside the company-managed scheme model, so broad grants here quietly create pockets of access your permission schemes do not govern
- Grants here default to broad groups in many tenants, and unlike space permissions, nothing about day-to-day use surfaces the over-grant

**Attack Prevented:** Privilege escalation to site administration, mass data modification and deletion, directory harvesting for targeted phishing, persistent exfiltration via scheduled filter subscriptions, ungoverned space sprawl

#### Prerequisites
- **Administer Jira** global permission

#### ClickOps Implementation

**Step 1: Inventory Current Grants**
1. Navigate to: **Settings (gear icon) → System**
2. Select **Global permissions** in the sidebar
3. Record every group and user holding each permission, and flag every grant to **Anyone**

**Step 2: Reduce Administer Jira to a Named Few**
1. Confirm **Administer Jira** is held only by a small, named administrator group — not by "jira-users", "developers", or any group that grows with headcount
2. Cross-check that group's membership against your organization admin roster ([Atlassian Common Controls guide](/guides/atlassian/) §1.2); the two roles are distinct, and both should be small
3. Remove any individual user grants in favour of the administrator group

**Step 3: Contain the High-Impact Non-Admin Permissions**
1. Restrict **Make bulk changes** to a small group with a documented operational need; most organizations need it for a handful of administrators only
2. Restrict **Manage group filter subscriptions** to administrators, and review existing subscriptions for recipients and filter scope
3. Decide deliberately on **Browse users and groups** — restricting it reduces phishing reconnaissance but does affect mention and assignee workflows, so validate the impact before enforcing
4. Restrict **Create team-managed spaces** so that new spaces land under governed schemes by default

**Step 4: Revoke and Re-verify**
1. To revoke, locate the permission and select **Delete** under the group whose access you are removing
2. After every change, re-open the page and confirm the resulting grant list matches your intended state
3. Alert on global permission changes in the organization audit log ([Atlassian Common Controls guide](/guides/atlassian/) §5.1)

#### Validation & Testing

1. Sign in as an ordinary user and confirm the **Settings → System** administration area is unavailable
2. As that user, select several work items and confirm no bulk-change option is offered
3. As that user, open a user picker and confirm the visible directory is limited to people sharing space access, if you restricted **Browse users and groups**
4. As that user, attempt to create a filter subscription for a group and confirm it is refused
5. Attempt to create a team-managed space as that user and confirm the outcome matches policy
6. Re-run this check quarterly and after any group-membership change in the IdP, since a global permission grant to a synced group inherits whatever that group becomes

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **SOC 2** | CC6.3 | Role-based access assignment |
| **NIST 800-53** | AC-6(1) | Authorize access to security functions |
| **NIST 800-53** | AC-6(7) | Review of user privileges |
| **ISO 27001:2022** | A.8.2 | Privileged access rights |
| **CIS Controls** | 5.4 | Restrict administrator privileges to dedicated accounts |

---

### 2.2 Control Guest and External Collaborator Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.1, 6.2, 6.8 |
| NIST 800-53 | AC-2, AC-3, PS-7 |
| ISO 27001:2022 | A.5.19, A.5.20 |

#### Description
Guests are external collaborators granted narrow access to specific Jira spaces rather than to the whole site. A site admin invites them at **Settings (gear icon) → User management → Users** by selecting **Invite users**, entering the email, and assigning the **Guest** role in the Apps tab. A space admin then adds a guest to a specific space via the space's **More actions (•••) → Space settings → People → Add people**, assigning the **Guest - Collaborator** role. Guest allocation is capped at five guests per paid user, and Atlassian states that current or former paid users may not be converted to guests. Source: [Manage guest access in Jira](https://support.atlassian.com/jira-cloud-administration/docs/manage-guest-access-in-jira/)

#### Rationale
**Why This Matters:**
- Guests are identities your organization does not control: you cannot enforce your device posture on them, you do not see their authentication events end to end, and you learn nothing when their employer offboards them
- Guest access is granted per space by *space* admins, not only by site admins, which distributes the decision to people who may not know what else lives in the space — the site admin who approved the guest may never see which spaces they end up in
- External collaborator access is durable in a way project engagements are not: contracts end, but nobody receives a ticket to remove the guest, so guest rosters only ever grow without a scheduled review
- A guest in a space with no work item security scheme reads every work item in that space, including anything an internal colleague filed there assuming an internal audience
- The five-guests-per-paid-user allocation means guest count can grow substantially before any billing signal prompts a review

**Attack Prevented:** Data leakage to third parties, standing access after an engagement ends, supply-chain compromise through a partner's breached account, over-broad external visibility into internal work items

#### Prerequisites
- Site admin role to invite or remove guests at the site level
- Space admin role to add or remove guests within a space

#### ClickOps Implementation

**Step 1: Inventory Existing Guests**
1. Navigate to: **Settings (gear icon) → User management → Users**
2. Filter for accounts holding the **Guest** role and record, for each, the sponsoring internal owner, the business justification, and the expected end date
3. For each guest, identify every space they can reach — the site-level list tells you who is a guest, not what they can see

**Step 2: Apply Least Privilege Per Space**
1. For each space with guests, open **More actions (•••) → Space settings → People**
2. Confirm each guest holds **Guest - Collaborator** and nothing broader
3. Remove guests from any space that is not directly required by their engagement
4. Where a space mixes external-appropriate and internal-only work, apply a work item security scheme (§1.2) so guests see only what is classified for them, rather than relying on people to file sensitive items elsewhere

**Step 3: Establish a Lifecycle**
1. Require a named internal sponsor and an expiry date for every guest invitation, recorded outside Jira since Jira will not expire them for you
2. Review the guest roster on a fixed cadence — monthly is reasonable given how easily guests accumulate — and remove anyone past their date
3. Remove guests from a space via **Space settings → People → Remove**, and from the site via **User management → user profile → More actions (•••) → Remove access**
4. Tie guest removal into your vendor and contractor offboarding checklist so it is triggered by the engagement ending rather than by the next review

**Step 4: Monitor**
1. Alert on guest invitations and space additions in the organization audit log ([Atlassian Common Controls guide](/guides/atlassian/) §5.1)
2. Compare the guest roster against active contracts at each review and treat any guest with no matching contract as an incident, not as cleanup

#### Validation & Testing

1. Sign in as a test guest and confirm only the intended spaces are visible, and that no other space is reachable by direct URL
2. As the test guest, run a JQL search across all work items and confirm results are confined to the intended spaces
3. Where a work item security scheme applies, confirm the guest cannot see restricted items in a space they can otherwise browse
4. Confirm the guest cannot reach administration areas or user pickers beyond their space membership
5. Remove the test guest and confirm access is revoked immediately at both the space and site level
6. Verify the current guest count and roster against your sponsor records at each scheduled review

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls for external parties |
| **SOC 2** | CC6.2 | Registration and authorization of new users |
| **SOC 2** | CC9.2 | Vendor and business partner risk management |
| **NIST 800-53** | AC-2 | Account management |
| **NIST 800-53** | PS-7 | External personnel security |
| **ISO 27001:2022** | A.5.19 | Information security in supplier relationships |

---

## 3. Automation & Extensibility

### 3.1 Restrict Automation Rule Scope and Outgoing Web Requests

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 4.8, 8.2 |
| NIST 800-53 | AC-4, AU-2, SC-7, SI-4 |
| ISO 27001:2022 | A.8.12, A.8.15, A.8.16 |

#### Description
Jira automation rules run server-side on triggers and can call external systems. The **Send web request** action sends an outgoing HTTP request "to notify another system when a flow is run" and can return response data for use in later actions; Atlassian restricts it to ports 80, 8080, 443, 6017, 8443, 8444, 7990, 8090, 8085, 8060, 8900, and 9900. Other actions — **Send customized email**, **Send Slack message**, **Send Microsoft Teams message**, **Send Twilio (SMS) message**, **Send message to Amazon SNS topic** — also move data outside Jira. Global rules are managed at **Settings (gear icon) → System → Global automation**, and **More actions (•••) → Global configuration** there controls whether space admins may manage space flows and whether non-admins may create recurring flows. In company-managed spaces, rule authorship requires **Administer spaces** and **Browse spaces**; global, multi-space rules require the **Administer Jira** global permission. Sources: [Jira automation actions](https://support.atlassian.com/cloud-automation/docs/jira-automation-actions/) · [Permissions required to manage automation flows](https://support.atlassian.com/cloud-automation/docs/permissions-required-for-jira-cloud-automation-rules/)

#### Rationale
**Why This Matters:**
- **Send web request** is a general-purpose egress primitive that lives inside Jira's own trusted execution context: a rule triggered on every work item creation can POST the full work item — summary, description, comments, custom fields — to an arbitrary external endpoint, continuously and silently
- Automation runs server-side under a rule actor rather than under the interactive user, so egress continues after the creating account's session ends, after their password is rotated, and in many cases after they are deprovisioned — it is a persistence mechanism, not just a data-flow one
- There is no destination allowlist for outgoing requests; the port restriction constrains *which ports* a rule may reach, not *which hosts*, so the only real control is who may author rules and whether you review what they built
- A rule reads whatever its actor can read, so a global rule authored by an administrator can reach across every space regardless of the permission scheme boundaries established in §1.1 — automation is a legitimate bypass of your own access model
- Values marked hidden in a rule are replaced by asterisks once saved, so a credential embedded in a rule cannot be re-read for audit — and Atlassian notes hidden values are lost on duplication or export/import, which pushes people toward storing them unhidden
- Automation audit logs retain only the **past 90 days** and older entries are "automatically deleted and can't be recovered", so an automation-based exfiltration channel running longer than a quarter is not fully reconstructable from Jira alone

**Attack Prevented:** Continuous data exfiltration through attacker-authored automation, persistence surviving credential rotation and deprovisioning, cross-space data access bypassing permission schemes, credential exposure in rule configuration, undetected long-running egress

#### Prerequisites
- **Administer Jira** global permission to reach global automation and its global configuration

#### ClickOps Implementation

**Step 1: Inventory Every Rule That Sends Data Out**
1. Navigate to: **Settings (gear icon) → System → Global automation**
2. Review every rule and identify each one containing a **Send web request**, **Send customized email** to external addresses, **Send Slack message**, **Send Microsoft Teams message**, **Send Twilio (SMS) message**, or **Send message to Amazon SNS topic** action
3. For each, record the destination, the trigger, the rule scope, the author, and the business justification — a rule with an external destination and no owner who can explain it should be disabled pending review, not left running
4. Repeat within each space for space-scoped rules, which do not all appear in the global list

**Step 2: Restrict Who Can Author Rules**
1. From **Global automation**, select **More actions (•••) → Global configuration**
2. Uncheck **Allow space administrators to manage space flows** where space admins should not be authoring automation
3. Disable **Allow non-admins to create recurring flows** — recurring rules run without any user-visible trigger, which makes them the easiest kind to overlook
4. Confirm **Administer spaces** in company-managed spaces is held only by the roles you intended in §1.1, since that permission is what confers rule authorship there
5. Confirm the **Administer Jira** global permission roster from §2.1 is small, since it confers authorship of global rules that cross every space

**Step 3: Review the Destinations You Keep**
1. For each retained **Send web request**, verify the destination is a system you own or have contracted with, and that it is reachable over HTTPS
2. Confirm no rule sends work item content to a destination that would not pass third-party review as a data processor
3. Prefer scoping rules to the narrowest set of spaces that satisfies the requirement, rather than leaving them global
4. Where a rule needs a credential, use the hidden-value option and record the credential's existence and owner in your secret inventory — since hidden values cannot be read back, an undocumented one becomes unrotatable

**Step 4: Monitor Continuously**
1. Use the automation audit log to review rule executions; note the **90-day** retention limit and export beyond it if you need a longer window
2. Alert on rule creation and modification, and treat any new rule with an external destination as requiring review
3. Re-inventory rules on the same cadence as your permission reviews, since a rule added between reviews runs unnoticed for the whole interval

#### Validation & Testing

1. As a non-administrator with space access, attempt to create a global rule and confirm it is refused
2. With **Allow non-admins to create recurring flows** disabled, attempt to create a recurring rule as a non-admin and confirm it is refused
3. For each retained outbound rule, trigger it in a test space and confirm from the automation audit log that it executed with the expected destination and payload
4. Confirm the automation audit log records rule creation and modification with an attributable actor
5. Cross-check the rule inventory against egress observed at your network or SaaS monitoring layer, and investigate any Atlassian-originating destination that does not appear in the inventory
6. Confirm no rule in the inventory carries a plaintext credential in a non-hidden field

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.7 | Restrictions on transmission and movement of information |
| **SOC 2** | CC7.2 | Monitoring for anomalies |
| **NIST 800-53** | AC-4 | Information flow enforcement |
| **NIST 800-53** | AU-2 | Event logging |
| **NIST 800-53** | SI-4 | System monitoring |
| **ISO 27001:2022** | A.8.12 | Data leakage prevention |
| **CIS Controls** | 3.3 | Configure data access control lists |

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Jira Cloud Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | Permission schemes | [1.1](#11-configure-permission-schemes-for-least-privilege) |
| CC6.1 | Work item security schemes | [1.2](#12-restrict-sensitive-work-items-with-security-schemes) |
| CC6.6 | Public and anonymous space exposure | [1.3](#13-eliminate-unintended-public-and-anonymous-space-exposure) |
| CC6.3 | Global permissions | [2.1](#21-restrict-jira-global-permissions) |
| CC6.2 | Guest and external collaborator access | [2.2](#22-control-guest-and-external-collaborator-access) |
| CC6.7 | Automation outgoing requests | [3.1](#31-restrict-automation-rule-scope-and-outgoing-web-requests) |

**Organization-level criteria** — CC6.1 SSO and two-step verification, CC6.6 IP allowlisting, CC7.2 audit logging — map to the [Atlassian Common Controls guide](/guides/atlassian/) §1.1, §1.4, and §5.1.

### NIST 800-53 Rev 5 Mapping

| Control | Jira Cloud Control | Guide Section |
|---------|-------------------|---------------|
| AC-3 | Permission schemes | [1.1](#11-configure-permission-schemes-for-least-privilege) |
| AC-21 | Work item security schemes | [1.2](#12-restrict-sensitive-work-items-with-security-schemes) |
| AC-22 | Publicly accessible content | [1.3](#13-eliminate-unintended-public-and-anonymous-space-exposure) |
| AC-6(1) | Global permissions | [2.1](#21-restrict-jira-global-permissions) |
| AC-2 | Guest account management | [2.2](#22-control-guest-and-external-collaborator-access) |
| AC-4 | Automation information flow | [3.1](#31-restrict-automation-rule-scope-and-outgoing-web-requests) |

**Organization-level controls** — IA-2(1) MFA, AC-17 remote access restriction, AU-2 audit logging — map to the [Atlassian Common Controls guide](/guides/atlassian/).

---

## Appendix A: Plan Compatibility

| Feature | Free | Standard | Premium | Enterprise |
|---------|------|----------|---------|------------|
| Permission schemes (1.1) | ❌ | ✅ | ✅ | ✅ |
| Space roles (1.1) | ❌ | ✅ | ✅ | ✅ |
| Work item security schemes (1.2) | ❌ | ✅ | ✅ | ✅ |
| Public space visibility (1.3) | ❌ | ✅ | ✅ | ✅ |
| Global permissions (2.1) | ✅ | ✅ | ✅ | ✅ |
| Guest access (2.2) | ❌ | ✅ | ✅ | ✅ |
| Jira automation (3.1) | Limited executions | Limited executions | ✅ | ✅ |

**Note:** Free sites cannot use permission schemes, space roles, or work item security schemes, which makes §1.1 and §1.2 unimplementable there — a Free site relies entirely on space membership for access control. A site that *downgrades* to Free keeps its existing permission configuration, but that configuration becomes read-only and cannot be edited until the site is upgraded again, so a downgrade freezes your access model exactly as it stood, mistakes included. Organization-level capabilities (SAML SSO, enforced authentication policies, audit logging, data classification) depend on the **Atlassian Guard** subscription rather than the Jira plan; see the [Atlassian Common Controls guide](/guides/atlassian/) Appendix A.

---

## Appendix B: References

**Official Atlassian Documentation:**
- [Manage permissions in Jira Cloud](https://support.atlassian.com/jira-cloud-administration/docs/manage-permissions-in-jira-cloud/) (index of the permission model)
- [Grant or revoke permissions in a scheme](https://support.atlassian.com/jira-cloud-administration/docs/grant-or-revoke-permissions-in-a-scheme/) (exact console path and grant types)
- [Manage project (space) permissions](https://support.atlassian.com/jira-cloud-administration/docs/manage-project-permissions/)
- [What are global permissions, and what do they control?](https://support.atlassian.com/jira-cloud-administration/docs/manage-global-permissions/)
- [View, grant, revoke global permissions in Jira](https://support.atlassian.com/jira-cloud-administration/docs/view-grant-revoke-global-permissions-in-jira/)
- [Configure work item (issue) security schemes](https://support.atlassian.com/jira-cloud-administration/docs/configure-issue-security-schemes/)
- [Create a new work item security scheme and security levels](https://support.atlassian.com/jira-cloud-administration/docs/create-a-new-work-item-security-scheme-and-security-levels/)
- [Use permissions to make a space publicly visible](https://support.atlassian.com/jira-cloud-administration/docs/use-permissions-to-make-a-space-publicly-visible/)
- [Manage guest access in Jira](https://support.atlassian.com/jira-cloud-administration/docs/manage-guest-access-in-jira/)
- [Permissions limitations in Free Jira sites](https://support.atlassian.com/jira-cloud-administration/docs/permissions-limitations-in-free-jira-sites/)
- [Jira automation actions](https://support.atlassian.com/cloud-automation/docs/jira-automation-actions/) (Send web request, permitted ports, hidden values)
- [Permissions required to manage automation flows](https://support.atlassian.com/cloud-automation/docs/permissions-required-for-jira-cloud-automation-rules/)
- [What is an automation audit log?](https://support.atlassian.com/cloud-automation/docs/what-is-the-automation-audit-log/) (90-day retention)
- [How to keep your organization secure](https://support.atlassian.com/security-and-access-policies/docs/how-to-keep-my-organization-secure/)
- [Atlassian Security Advisories](https://www.atlassian.com/trust/security/advisories)

**API & Developer Resources:**
- [Jira Cloud REST API v3](https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/) (permission scheme, issue security scheme, and permissions endpoints — useful for auditing current state)
- [Security Overview (Developer)](https://developer.atlassian.com/cloud/jira/platform/security-overview/)
- [Atlassian Developer Documentation](https://developer.atlassian.com/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27018 — via [Atlassian Compliance Resource Center](https://www.atlassian.com/trust/compliance/resources)

**Security Incidents:**
- **CVE-2023-22523 (CVSS 9.8):** Remote code execution in Assets Discovery for Jira Service Management (2023).
- **Credential-stuffing campaigns (2024):** Multiple organizations experienced Jira account takeovers via compromised credentials, with attackers using integrated tools to scrape data. Six public breaches were reported in five months across various Jira customers.
- Atlassian publishes security advisories at [atlassian.com/trust/security/advisories](https://www.atlassian.com/trust/security/advisories).

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Restructure as a product guide under the Atlassian platform hub: add `platform`/`platform_slug`/`product` frontmatter and a hub pointer. Remove duplicated organization-level controls — former 1.1 SAML SSO, 1.2 authentication policies, 1.3 two-step verification, 1.4 JIT provisioning, 2.1 Atlassian Guard, 2.2 domain verification, and 2.3 org admin roles now live in Atlassian §1.1 and §1.2; former 3.3 app access in Atlassian §2.1/§3.3; former 4.1 audit logging and 4.2 security alerts in Atlassian §5.1/§5.2. Rebuild around six Jira-specific controls: permission schemes, work item security schemes, public/anonymous space exposure, global permissions, guest access, and automation rule scope and outgoing web requests. Adopt Atlassian's current space/work item terminology and record the Free-plan permission-scheme limitation | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, organization security, and access controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
