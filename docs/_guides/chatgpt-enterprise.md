---
layout: guide
title: "ChatGPT Enterprise Hardening Guide"
vendor: "OpenAI"
slug: "chatgpt-enterprise"
platform: "OpenAI"
platform_slug: "openai"
product: "Common Controls"
tier: "1"
category: "AI/ML Platform"
description: "ChatGPT workspace identity, sharing, data, plugins, integration and agent governance with explicit product boundaries"
version: "0.4.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-05"
---

## Overview

This is the OpenAI platform’s common-controls hub. Its settings govern eligible **ChatGPT workspaces**, with tenant identity controls only where the selected product supports them. OpenAI is a shared owner, not one security control plane: ChatGPT membership, API organization/projects, Ads accounts, local/device policy, Codex Cloud, source systems, Ona and Statsig each require their own configuration. No product inherits a control merely because it appears on this platform.

**Intended audience:** workspace/global administrators, security engineers, connected-service owners and integration developers. **Profiles:** L1 (Crawl) for essential controls, L2 (Walk) for sensitive environments, L3 (Run) for regulated requirements. **Scope:** current official customer controls reviewed 2026-11-05, with edition and runtime limitations below. No live tenant was accessed and no maturity promotion is claimed.

## Products in This Platform

| Product / surface | Guide or disposition | Control boundary |
|-------------------|----------------------|------------------|
| ChatGPT Enterprise and common workspace controls | This guide | Enterprise/Edu identity, permissions, GPTs/plugins, sharing, data, supported logging and agents; verify edition eligibility |
| ChatGPT Work, Codex desktop/CLI/IDE/Cloud and Codex Security | [Work and Codex](/guides/chatgpt-work-codex/) | Device policy, runtime/network/browser/computer permissions, cloud environments, state and scanning; does not inherit every workspace control |
| ChatGPT Dots | [Dots](/guides/chatgpt-dots/) | Personal-dot identity, app/channel capabilities, context, audits and lifecycle |
| OpenAI API Platform, models, Responses/Realtime/media, hosted tools and Agents | [API Platform](/guides/openai-api/) | Separate org/project roles, keys, retention, egress, webhooks and stored application state |
| Frontier | [Separate deployment; research gap](https://openai.com/business/frontier/) | Current enterprise-agent platform; public configuration/audit contracts unverified, no inherited ChatGPT/API enforcement claim |
| GPT-Rosalind life-sciences workflow | Common 1.4 and approved Work/Codex/API scope | Research/Discovery access, workspace roles and separately approved API access |
| Ads Manager / Ads API | [Ads](/guides/openai-ads/) | Distinct ad-account roles, keys, OAuth, assets and audit; shared tenant SSO only when configured |
| Ona, formerly Gitpod | [Ona](/guides/ona/) | Acquired 2026-08-10; separate Ona console, runners, API/CLI, native policies and contract |
| Prism / former Crixet | Common 2.7 and personal-account controls | Active pending announced January 1, 2027 shutdown; distinct sharing, Zotero and export lifecycle |
| Statsig | [Statsig](/guides/statsig/) | Current OpenAI family; separate experimentation/configuration service, identity, keys and telemetry |
| ChatGPT Business, Edu, Teachers and Healthcare | [Edition and workflow boundaries](#edition-and-workflow-boundaries) | Apply only supported controls; clinical and district-specific configuration called out |
| Free/Go/Plus/Pro, Health and Clinicians | [Individual accounts](#individual-accounts-and-healthcare-boundaries) | Individual account/training/memory/connection controls; no automatic Enterprise admin inheritance |
| Space, projects, Sites, plugins, Company Knowledge, search/research, image, voice, meetings and scheduled/team tasks | This guide’s sharing, app/data and task controls | Features of ChatGPT; sources/settings and saved copies may differ. Work/Codex runtime controls are separate |
| Sign in with ChatGPT | [5.6](#56-bind-sign-in-with-chatgpt-transactions-and-relying-party-sessions), [5.7](#57-verify-signed-account-security-logout-notifications) | Limited partner trial; relying-party authentication/session implementation, not project policy |
| Plugin/Apps SDK and Agentic Commerce developer integrations | [5.8](#58-enforce-plugin-and-apps-sdk-authorization-on-every-tool-call), [5.9](#59-protect-agentic-commerce-credentials-and-transaction-boundaries) | Developer application authorization, provider credentials and transaction boundaries; no native universal workspace toggle |
| Atlas, Sora and Neptune SaaS | Lifecycle records in the source inventory | Retired/announced shutdown; no new active-product guide fabricated |
| Pierre / Code Storage / Trees / Diffs / Highlights | [Pending acquisition](https://openai.com/index/openai-to-acquire-pierre/) announced 2026-11-04 | Companies remain independent until closing; no OpenAI policy inheritance |
| TBPN | Media acquisition; excluded from hardening settings | No documented customer SaaS security configuration plane |

**Product guides:** [Dots](/guides/chatgpt-dots/) · [Work and Codex](/guides/chatgpt-work-codex/) · [API Platform](/guides/openai-api/) · [Ads](/guides/openai-ads/) · [Ona](/guides/ona/) · [Statsig](/guides/statsig/)

### Intended Audience

Workspace and identity administrators, security engineers, integration owners and developers responsible for ChatGPT data and delegated actions.

### How to Use This Guide

Apply L1 (Crawl) controls first; use L2 (Walk) for sensitive workflows and L3 (Run) where contractual or regulated requirements apply. Follow the product links and verify each control’s edition/runtime conditions.

### Scope

Eligible ChatGPT workspace identity, data, sharing, plugins, agent governance and developer integration boundaries. API Platform, Ads, installed executors, Ona and Statsig retain the separate control planes described below.

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
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Configure identity in the correct OpenAI tenant and then require the intended product’s SSO policy. A shared identity-provider connection does not automatically enable SSO for ChatGPT, API Platform or Ads, or grant product membership.

#### Rationale

**Why This Matters:**

- Optional or alternate sign-in can bypass IdP MFA and device policies.
- Changing a shared connection can affect multiple products and recovery paths.

**Attack Prevented:** Unauthorized alternate sign-in and identity migration lockout.

#### ClickOps Implementation

1. As a tenant global admin, open **Admin Console > Access > Domains / Single Sign-On**. Standalone Business owners use **Workspace settings > Identity & access**; follow the Console link if settings are read-only.
2. Verify the intended domain and use **Set up SSO** from the live flow to obtain connection-specific values. Configure the IdP with those values and test while SSO is Optional where offered.
3. Set the ChatGPT product sign-in policy to Required only after representative and recovery-admin tests. Off disables SSO; it does not mean optional. Review API and Ads product policies separately.

**Automation:** The documented console path is verified. The current public ChatGPT Admin schema did not load during this review, so API writes and corresponding CLI/SDK/provider coverage for this setting remain unverified. API Platform organization/project endpoints do not configure it.

#### Validation & Testing

Test the intended work account, alternate permitted sign-in, recovery procedure and each affected product. Retain a separate authorized recovery path before changing an existing connection.

**Sources:** [Configuration guidance](https://help.openai.com/en/articles/9534785-single-sign-on-sso-setup-for-openai-products)

---

### 1.2 Enable Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Require MFA through the identity provider and require its sign-in path. OpenAI currently has no native workspace-level or API-organization-level MFA enforcement. Individual enrollment is a useful account control, not proof that all workspace members have MFA.

#### Rationale

**Why This Matters:**

- A compromised privileged account exposes connected services and retained content.
- Enabling MFA does not invalidate existing sessions.

**Attack Prevented:** Credential reuse, phishing and persistent unauthorized sessions.

#### ClickOps Implementation

1. In your **identity provider’s ChatGPT application policy**, require the organization’s approved MFA and conditional access, then verify required SSO under 1.1.
2. For permitted individual accounts open **Settings > Security and login > Multi-factor authentication** and enroll a supported method and recovery plan. Available methods vary by account/device.
3. After suspected compromise use **Security and login > Log out of all devices** as well as credential/token and connected-service revocation. Session logout may take up to 30 minutes.

**Automation:** No native workspace/org MFA enforcement is currently documented. IdP policy enforces the required sign-in route; OpenAI account enrollment and session logout are separate user controls. IdP automation belongs to the identity provider.

#### Validation & Testing

Use a disposable member to prove the required IdP MFA challenge. Check direct sign-in and existing sessions separately; do not rely on a nonexistent Require MFA workspace toggle.

**Sources:** [Configuration guidance](https://help.openai.com/en/articles/7967234-managing-multi-factor-authentication-mfa)

---

### 1.3 Configure SCIM User Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Choose tenant-wide or product-level SCIM deliberately and synchronize only intended groups. SCIM provisions membership; SSO authenticates. Directory membership does not confer connected-service access.

#### Rationale

**Why This Matters:**

- Direct invitations and alternate group grants can retain access after a directory change.
- Replacing a working provisioning scope can affect multiple products.

**Attack Prevented:** Orphaned accounts and unintended cross-product provisioning.

#### ClickOps Implementation

1. For tenant-wide sync, a global admin opens **Admin Console > Global settings > Access > Directory > Enable Directory Sync (SCIM)**, then **Manage directory > Manage product access**. Assign pilot groups to intended workspaces/products.
2. For eligible workspace-only sync, an owner opens **Workspace settings > Identity & access > Directory Sync** and chooses **Use SCIM only for this workspace**. Coordinate existing tenant/product sync with the account team before migration.
3. For Teachers district tenants sync verified staff only, never student groups, and review direct/domain joins separately. Standalone Business does not include SCIM. API organization membership remains an API product boundary.

**Automation:** SCIM is a documented provisioning protocol; use the endpoint and credential issued for the actual tenant/product. This review did not verify its current schema and cannot safely provide a generic token or guessed provisioning request.

#### Validation & Testing

Remove a disposable user’s provider assignment, verify successful sync and effective workspace removal, then check direct memberships, other groups, active dots/tasks and source authorizations separately.

**Sources:** [Configuration guidance](https://help.openai.com/en/articles/10011769-scim-provisioning-and-management) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/groups-and-provisioning) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/user-lifecycle)

---

### 1.4 Implement Role-Based Access Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Review seats, built-in administrative roles, custom feature roles, direct assignments and groups independently. Owners, Admins, Members and Analytics Viewers have different authority. Ordinary role On grants are additive; Off does not revoke another role’s grant.

#### Rationale

**Why This Matters:**

- A seat or feature role is not an administrative role.
- An overlooked group or direct grant can defeat a restrictive workspace default.

**Attack Prevented:** Excess administrative privileges and additive-role bypass.

#### ClickOps Implementation

1. In **Admin Console > Members**, review Owners/Admins, Analytics Viewers, seat eligibility and delegated group management. Keep privileged access with accountable administrators.
2. In **Permissions & roles**, set a restrictive workspace default and grant reviewed features through targeted custom roles/groups. Inspect every direct and group assignment.
3. Check Lockdown Mode, seat, plan and product restrictions separately; workspace roles do not grant repository access, API project membership or local runtime permissions.

**Automation:** The documented console path is verified. The current public ChatGPT Admin schema did not load during this review, so API writes and corresponding CLI/SDK/provider coverage for this setting remain unverified. API Platform organization/project endpoints do not configure it.


**GPT-Rosalind:** In the approved workspace, an Owner uses **Groups**, then **Permissions & roles > Custom roles**, to grant approved users **Life Sciences** and required **Skills/Codex** permissions. Keep the default member model grant Off and reconcile additive roles. Research and Discovery approvals differ; API needs separate approval. GPT-6 Rosalind Research uses Work/Codex and has a separate, initially off two-week Admin Preview. Business and Academic Plan follow their approval-specific access paths. Plugin installation alone grants no model access. [Current setup](https://help.openai.com/en/articles/20001193-gpt-rosalind-for-life-sciences-research).

#### Validation & Testing

Test an allowed and denied member with realistic multiple-role membership. Preserve exported assignments and the effective access result; an audit log of role changes is not a complete current role inventory.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/roles-and-workspace-permissions) · [Supporting documentation](https://help.openai.com/en/articles/8266401-managing-members-workspace-roles-and-seats-in-chatgpt-enterprise-and-edu)

---

### 1.5 Apply Lockdown Mode to sensitive member populations

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Use a managed Lockdown Mode role where reduced live egress is required. It restricts supported capabilities but does not prevent all prompt injection or govern Codex networking, memory, training or all managed apps.

#### Rationale

**Why This Matters:**

- Untrusted content can request outbound disclosure through a legitimate tool.
- A normal feature grant does not override a Lockdown role restriction.

**Attack Prevented:** Prompt-injection-driven exfiltration through supported outbound capabilities.

#### ClickOps Implementation

1. In **Workspace settings > Permissions & roles > Custom roles**, create/designate the supported **Lockdown Mode** role and assign the intended members/groups.
2. Review each trusted app and action retained for that role. Avoid untrusted apps and broad external write visibility; source data access remains independently authorized.
3. Test required workflows, live versus cached browsing, agent mode, deep research and Canvas networking. Personal/self-serve account per-chat disable behavior is separate from managed-role restrictions.

**Automation:** The documented console path is verified. The current public ChatGPT Admin schema did not load during this review, so API writes and corresponding CLI/SDK/provider coverage for this setting remain unverified. API Platform organization/project endpoints do not configure it.

#### Validation & Testing

Use disposable prompts and destinations to verify blocked egress and approved reads. Verify memory/sharing/training and Codex networking separately.

**Sources:** [Configuration guidance](https://help.openai.com/en/articles/20001061-lockdown-mode) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/roles-and-workspace-permissions)

---

## 2. Data Security & Privacy

### 2.1 Understand Data Privacy Guarantees

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Approve data use by the actual product, workspace contract and content category. Business, Enterprise, Edu and Healthcare content is excluded from model training by default; personal accounts and third-party integrations have separate settings and terms.

#### Rationale

**Why This Matters:**

- A privacy promise does not configure retention, source authorization or an integration’s processing region.
- Local Work/Codex execution still sends selected context to OpenAI.

**Attack Prevented:** Submission through an unapproved account or processing boundary.

#### ClickOps Implementation

1. Confirm the selected workspace and product, intended data classes, agreements and any BAA before onboarding. Use approved managed accounts for organization data.
2. Review **Settings / Workspace settings > Data controls** and the applicable plan’s retention, Memory and sharing settings. Record which controls are admin-managed and which are individual.
3. Inventory external apps, shared connections, local/client state and cloud snapshots separately; require the receiving service’s appropriate agreement for regulated data.

**Automation:** Contract/edition review is not an executable hardening setting. Implement its actual identity, retention, sharing, app and runtime controls in the corresponding sections.

#### Validation & Testing

Confirm the approved workspace and contract for a representative workflow; verify each downstream recipient. Do not use a compliance certification or training setting as proof that an action is authorized.

**Sources:** [Configuration guidance](https://help.openai.com/en/articles/7730893-data-controls-in-chatgpt) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/chatgpt-work-cloud-security)

---

### 2.2 Configure Data Retention Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Set the required workspace retention policy and reconcile chats, files, Space pages, Memory, dots, cloud snapshots and exported logs separately. A single conversation-retention value does not expire every copy.

#### Rationale

**Why This Matters:**

- Saved files or memory can outlive the chat or source connection.
- Compliance exports and legal holds introduce independent retention obligations.

**Attack Prevented:** Residual sensitive information after apparent deletion.

#### ClickOps Implementation

1. In the selected workspace’s **Workspace settings > Data controls**, review the retention configuration offered by the plan; coordinate account-team-managed policy changes instead of assuming fixed 30/90-day choices.
2. Inventory chat/file policy, Space/Library pages and attachments, ChatGPT Memory, dots context/snapshots, delegated tasks and third-party copies. Assign an owner and deletion path for each.
3. Export required evidence before expiration and apply downstream retention/legal holds to actual received records. A hold on an export is not proof of a hold on all original content.

**Automation:** The documented console path is verified. The current public ChatGPT Admin schema did not load during this review, so API writes and corresponding CLI/SDK/provider coverage for this setting remain unverified. API Platform organization/project endpoints do not configure it.

#### Validation & Testing

Use disposable content to verify expiry/deletion in each location. Access revocation and account removal are not deletion tests; record contractual exceptions and any unsupported category.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/chatgpt-space) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/dots-security) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/chatgpt-work-cloud-security) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/compliance-api)

---

### 2.3 Enable Enterprise Key Management (EKM)

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Where eligible, use external customer-managed keys and test the lifecycle for supported content. Current EKM documentation supports AWS KMS, GCP and Azure Key Vault; eligibility and onboarding remain account-team dependent.

#### Rationale

**Why This Matters:**

- Revocation, rotation and deletion have different operational consequences.
- Not every product, content copy or integration inherits EKM coverage.

**Attack Prevented:** Uncontrolled access to supported encrypted content and unsafe key lifecycle changes.

#### ClickOps Implementation

1. Work with the OpenAI account representative to confirm the workspace, eligible content categories and chosen KMS provider before activation. Follow its current provider-specific integration procedure.
2. In your **KMS administration console**, grant only the vendor-documented identity and operations. Record ownership, availability, access logs and recovery arrangements.
3. Plan test rotation and controlled revocation with the account team, including separately stored snapshots, data exports and integration copies. Do not describe key destruction as an immediate universal purge.

**Automation:** KMS configuration and an EKM Management API are documented, but the ChatGPT current external-key contract was not fetched successfully in this review. Treat API automation as unverified; do not reuse API project key endpoints as workspace EKM configuration.

#### Validation & Testing

Validate the supported-content behavior and KMS access logs through the documented onboarding/lifecycle checks. Test recovery on disposable data before a production revocation.

**Sources:** [Configuration guidance](https://help.openai.com/en/articles/20000943-openai-enterprise-key-management-ekm-overview) · [Supporting documentation](https://help.openai.com/en/articles/20000957-ekm-kms-key-lifecycle)

---

### 2.4 Establish Acceptable Use Policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Define approved data classes and workflows using enforceable identity, app, sharing, runtime and guardrail controls. Written instructions alone do not create a product security boundary.

#### Rationale

**Why This Matters:**

- Users need clear guidance on connected accounts, intended recipients and unattended actions.
- A generic ban or policy prompt cannot replace authorization in the receiving system.

**Attack Prevented:** Unapproved data submission and overbroad delegated actions.

#### ClickOps Implementation

1. Document approved workspace/product/data combinations, permitted recipients, regulated-use agreements and an accountable owner for each workflow.
2. During onboarding require review of **connected accounts**, **sharing audiences**, action approvals and the applicable workspace roles. Teach users to distinguish drafting from authorizing a send.
3. For prompt-text inspection where eligible, follow [Work/Codex 4.2](/guides/chatgpt-work-codex/#42-test-external-prompt-guardrails-and-choose-failure-behavior). Its coverage does not include every file, tool result or API credential route.

**Automation:** The policy document is organizational governance. Its enforceable settings are covered by the product-specific controls; no native universal acceptable-use JSON policy is documented.

#### Validation & Testing

Rehearse a harmless draft, approved send and unauthorized recipient with the intended identity; confirm the actual product controls stop the prohibited path.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/admin-setup) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/apps-and-connectors) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/prisma-airs)

---

### 2.5 Restrict Space, project and Site sharing audiences

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Treat source file access, copied summaries, project membership, Space pages and published Sites as distinct disclosure boundaries. Disabling new sharing can leave existing access intact.

#### Rationale

**Why This Matters:**

- A summary can expose source content to a broader destination audience.
- UI-hidden records and unpublished edits are not authorization controls.

**Attack Prevented:** External publication and cross-audience data disclosure.

#### ClickOps Implementation

1. In **Permissions & roles**, review project sharing and **Share Library files and folders**. Disabling the latter blocks new shares/permission changes, not existing access; review current shares explicitly.
2. Review each **Space page / project > Share** audience and separately stored attachments. Shared projects use project-only memory; members can see the shared project content according to its permissions.
3. In **Admin Console > Sites**, restrict create/publish, external invitation, public access and plugin use independently. Review additive audience grants and editor publication rights. Connected Sites must authorize records server-side under each visitor’s account; test as a non-owner.

**Automation:** The documented console path is verified. The current public ChatGPT Admin schema did not load during this review, so API writes and corresponding CLI/SDK/provider coverage for this setting remain unverified. API Platform organization/project endpoints do not configure it.

#### Validation & Testing

Test internal, unauthorized, external and public access with disposable content. Check old shares, copied snapshots and Site record requests; deleting chats/projects does not necessarily delete Space files.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/chatgpt-space) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/sites) · [Supporting documentation](https://help.openai.com/en/articles/10169521-projects-in-chatgpt)

---

### 2.6 Limit personal Health connections and retained copies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3, AC-4, IA-2 |
| CIS Controls v8 | 3.3, 6.1 |

#### Description

Health uses personal medical and Apple Health data in eligible chats when allowed. It is separate from Healthcare and the legacy Health Project.

#### Rationale

**Why This Matters:**

- Synced records can inform ordinary chats; legacy project isolation does not describe the new Health tab.
- Authentication, source access and the final recipient need independent checks.

**Attack Prevented:** Unauthorized disclosure and integration credential misuse.

#### ClickOps Implementation

1. In **Settings > Plugins > Health**, choose the required permission; new connections follow global plugin permissions, whose unchanged default is Allow low-risk actions.
2. In **Health > Accounts** connect only intended records. For Apple Health, choose the approved categories on iPhone. Review Memory under **Settings > Personalization** or use Temporary Chat/project-only memory.
3. To retire a source use **Health > Accounts > account > Remove account**, or **Health > … > Apple Health > Disconnect**. Synced source data is deleted within 30 days; delete retained conversations and memories separately.

**Automation:** Member settings are documented; no managed Enterprise policy or current public Health admin API was verified.

#### Validation & Testing

Test with disposable data and confirm revocation in Health and the source. Review conversations, memory and legacy project copies independently.

**Sources:** [Configuration guidance](https://help.openai.com/en/articles/20001036-health-in-chatgpt)

---

### 2.7 Restrict Prism collaboration and preserve controlled exports

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.3, 6.8 |
| NIST 800-53 | AC-3, CP-9 |

#### Description

Review Prism separately from managed workspaces. The current personal-account product is scheduled to shut down January 1, 2027; Enterprise settings do not establish its data protections.

#### Rationale

**Why This Matters:**

- Its FAQ rules out strict ZDR and gives no committed privacy-mode or EU-only residency timeline.
- Link viewers and named editors have different access; exported files can outlive Prism and need a new collaboration boundary.

**Attack Prevented:** Unintended manuscript disclosure and loss of access controls or recoverable research at retirement.

#### ClickOps Implementation

1. Check eligibility before approving sensitive work: the current FAQ permits personal plans only for people who are not and have not been Business/Enterprise members. Review personal model-improvement choices and applicable agreements.
2. Review every collaborator and view link; accountless editable links are unsupported. Editors require collaborator accounts. Review individual Zotero library access separately; group libraries are unsupported and account unlink/relink can require Support.
3. Export through **Settings > Data Controls > Export all projects (zip) > Download zip**, or the project-title menu **Export (zip)**. Protect archives and conversation JSON, check export-errors.json and verify a backup before shutdown. Preserve needed history/comments separately; re-establish collaborator permissions and Zotero in the destination. Prism data deletion after shutdown is irreversible.
4. Before compiling imported LaTeX in Codex, review build files, selected folder, tools and approvals using the Work/Codex guide. An exported folder does not recreate Prism live collaboration or serve as its own backup.

**Automation:** The documented UI exports are verified. Current public Prism administration APIs, Terraform, CLI, SDK, managed configuration and audit contracts were not verified; no private browser route is presented as supported automation.

#### Validation & Testing

Use a nonsensitive project to verify viewer/editor access and export completeness. Check that the approved destination has the intended collaborators, private storage and working recovery path.

**Sources:** [Current Prism FAQ](https://help.openai.com/en/articles/20001050-troubleshooting-prism) · [Shutdown notice](https://openai.com/index/introducing-prism/) · [Migration](https://help.openai.com/en/articles/20001615-prism-to-codex-migration-guide)

---

## 3. GPT & App Controls

### 3.1 Restrict Third-Party GPT Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Govern custom GPT creation, third-party access, sharing, action domains and ownership separately from plugins. GPT builders may use apps or custom actions, not both in the same GPT. Migration to plugins requires a fresh access review.

#### Rationale

**Why This Matters:**

- GPT instructions and custom actions can introduce a new data recipient.
- An action-domain allowlist does not authenticate an API or authorize the user.

**Attack Prevented:** Unvetted GPT use and custom-action disclosure.

#### ClickOps Implementation

1. In **Workspace settings > Permissions & roles**, review GPT creation, access and sharing for the workspace default and custom roles. Restrict outside-workspace sharing where offered.
2. Review **GPT actions** domain restrictions and admit only approved external API domains. With no allowed domains custom GPT actions cannot execute. Review authentication and provider permissions separately.
3. Open workspace **GPT management**, review builder, actions, access and assigned/unassigned ownership; reassign or remove orphaned GPTs. Re-review replacement plugins before migration.

**Automation:** The documented console path is verified. The current public ChatGPT Admin schema did not load during this review, so API writes and corresponding CLI/SDK/provider coverage for this setting remain unverified. API Platform organization/project endpoints do not configure it.

#### Validation & Testing

As a representative member test an unapproved GPT/action domain and a permitted workflow. Verify sharing audiences and source authorization independently.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/gpts-and-sharing) · [Supporting documentation](https://help.openai.com/en/articles/8555535-managing-gpt-access-in-enterprise-and-edu-workspaces)

---

### 3.2 Control App and Plugin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Review plugin installation, included app access, existing/new tools, confirmation and content restrictions as separate decisions. Disabling an app does not necessarily uninstall its plugin or remove skill-only capabilities.

#### Rationale

**Why This Matters:**

- An installed plugin is not an authorization grant in its source system.
- New actions or additive role grants can silently widen an established workflow.

**Attack Prevented:** Unapproved tools, overbroad app writes and source-data disclosure.

#### ClickOps Implementation

1. Open **Admin Console > selected workspace > Plugins** (or **Manage Legacy Apps** where retained). Set workspace installation and role-specific availability for approved plugins.
2. Review each included app’s **App access**, **Tools / Actions**, **New tools / New actions**, and **Permissions**. Default to approved read actions; turn off automatic admission of new write tools where available.
3. Review supported **Safety & Security Controls** for content access, including source/resource and sensitivity-label exclusions. Verify company-domain connection restrictions separately: activation affects new connections and does not revoke existing ones.

**Automation:** The documented console path is verified. The current public ChatGPT Admin schema did not load during this review, so API writes and corresponding CLI/SDK/provider coverage for this setting remain unverified. API Platform organization/project endpoints do not configure it.

#### Validation & Testing

Use a member with all assigned roles to test an allowed and restricted source, read/write action and new tool. In Healthcare review its distinct defaults; Business apps are enabled by default and role-level controls differ.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/apps-and-connectors) · [Supporting documentation](https://help.openai.com/en/articles/11509118-admin-controls-security-and-compliance-for-plugins-and-apps)

---

### 3.3 Configure Custom Instructions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Use custom instructions for workflow guidance and keep secrets out of them. They do not override authorization or guarantee action approval. Relevant instruction content can be shared with third-party plugins.

#### Rationale

**Why This Matters:**

- Persistent instruction text can become another disclosure source.
- A model instruction cannot revoke an underlying tool’s authority.

**Attack Prevented:** Persistent sensitive prompt leakage and reliance on unenforceable instructions.

#### ClickOps Implementation

1. For individual web/desktop accounts open **Settings > Personalization > Enable customization**; mobile uses **Settings > Customize ChatGPT**. Review or remove sensitive instructions.
2. Place security requirements in enforceable workspace/native controls, and keep instructions to approved workflow context. Review plugin recipients before including confidential text.

**Automation:** Member personalization is documented. A universal administrator-enforced custom-instruction policy/write contract was not verified; do not invent an admin menu or policy JSON.

#### Validation & Testing

Check future chats after editing/disabling and inspect relevant permitted tool inputs with disposable text. Do not treat a natural-language refusal as a product-enforced deny.

**Sources:** [Configuration guidance](https://help.openai.com/en/articles/8096356-chatgpt-custom-instructions)

---

### 3.4 Control plugin publishing, custom MCP and skill supply chains

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Grant plugin creation, upload, custom-MCP, share and publish permissions separately from use. Review executable content, manifests, sources and updates before workspace distribution.

#### Rationale

**Why This Matters:**

- A trusted-looking skill can carry tool instructions or executable dependencies.
- Disabling an underlying app need not remove bundled skills or a plugin installation.

**Attack Prevented:** Malicious workspace extension distribution and supply-chain persistence.

#### ClickOps Implementation

1. In **Permissions & roles**, search **plugins** and restrict **Upload plugins**, **Upload plugins with custom MCP servers**, **Create plugins with MCPs**, **Share plugins**, and **Publish plugins to workspace** to reviewed maintainers.
2. In **Admin Console > Plugins**, review source, owner, skills, included apps/MCP, hooks and intended audience before availability/install changes. Review GitHub import/sync permissions and updates if used.
3. For local marketplace and MCP enforcement use [Work/Codex 2.5](/guides/chatgpt-work-codex/#25-admit-trusted-mcp-servers-plugins-and-marketplaces). Workspace and local plugin policies have distinct coverage.

**Automation:** The documented console path is verified. The current public ChatGPT Admin schema did not load during this review, so API writes and corresponding CLI/SDK/provider coverage for this setting remain unverified. API Platform organization/project endpoints do not configure it.

#### Validation & Testing

Test that a user can use an approved plugin while being unable to upload/publish an unapproved one. Review an update before sync and prove revocation in each applicable runtime.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/apps-and-connectors) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/plugin-management) · [Supporting documentation](https://learn.chatgpt.com/docs/plugins)

---

## 4. Monitoring & Compliance

### 4.1 Enable Usage Analytics

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Use analytics to track adoption and credits, not to establish authorization or reconstruct every action. Workspace reporting, Codex reporting and supported product usage have different measures.

#### Rationale

**Why This Matters:**

- A usage count cannot show who authorized an action or whether it succeeded.
- Workspace credit controls do not set API Platform billing limits.

**Attack Prevented:** Unnoticed adoption/spend and inaccurate audit conclusions.

#### ClickOps Implementation

1. Open **Workspace analytics** at **chatgpt.com/admin/usage** and grant the minimum supported reporting role, such as Analytics Viewer.
2. Use the **Analytics API** reference for programmatic reporting. Dots usage identifies client_id DOTS; delegated Work/Codex usage appears under those products.
3. Review eligible workspace **usage limits and spend controls** separately from feature roles and API Platform project budgets. Record reporting delays and actual pause/limit behavior.

**Automation:** Analytics API reads are documented; current full schema/pagination was unavailable in the public Admin reference during this review. Existing historical APIs are not promoted to current verified contracts.

#### Validation & Testing

Compare harmless representative activity with the dashboard/API for the intended date and client. Investigate actions using Compliance and receiving-service logs instead.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/governance) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/analytics-api) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/usage-limits) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide)

---

### 4.2 Integrate with Microsoft Purview

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Where licensed, use a supported Compliance Platform partner integration to govern received ChatGPT records. A downstream connector is not a universal inline ChatGPT DLP control.

#### Rationale

**Why This Matters:**

- Partial or delayed ingestion can leave audit and e-discovery gaps.
- Downloaded messages and app results need their own access, retention and legal-hold controls.

**Attack Prevented:** Unretained evidence and overbroad downstream access.

#### ClickOps Implementation

1. Start with the **OpenAI Compliance Platform > Microsoft** partner setup links and the current licensed Purview procedure. Scope a ChatGPT workspace Admin key to the integration’s required logs.
2. In the **Purview administration console**, configure the supported connector and intended retention/discovery policies according to that integration. Do not assume an obsolete ChatGPT Integrations toggle exists.
3. Review connector health, record coverage, identities and downstream access. Source-side Microsoft sensitivity-label exclusions are separate app controls under 3.2.

**Automation:** OpenAI documents supported partner integrations. This review verifies the OpenAI handoff and export boundary, not a tenant’s licensed Purview configuration; follow the partner’s current implementation contract.

#### Validation & Testing

Generate harmless identifiable test records and prove arrival, search/access and expiry/hold behavior in the configured downstream system. Record excluded event categories and delay.

**Sources:** [Configuration guidance](https://help.openai.com/en/articles/9261474-openai-compliance-platform-for-enterprise-and-edu-customers) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/compliance-api)

---

### 4.3 Implement Audit Trail Reviews

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Use workspace-scoped ChatGPT Admin keys and Compliance records for ChatGPT investigations. API Platform /organization/audit_logs, API Admin keys and API organization roles do not verify ChatGPT policy.

#### Rationale

**Why This Matters:**

- A sampled change log cannot prove the complete effective state.
- Conversation visibility alone omits some tool detail, approvals and receiving-system outcomes.

**Attack Prevented:** Undetected governance changes and incomplete incident evidence.

#### ClickOps Implementation

1. In **Admin Console > selected workspace > Credentials > Admin keys**, select supported minimum custom log permissions. Only owners can grant broad compliance or Conversation messages access where supported.
2. Continuously export required records before the **30-day** Compliance Logs Platform retention window. Use 6.6 for a private resumable export.
3. Review role/app/policy/lifecycle changes alongside current configuration inventories and receiving-service evidence. Record missing fields/event coverage rather than manufacturing a clean result from an empty export.

**Automation:** Current workspace list/download reads are verified from the current official downloader and implemented at 6.6. Exact event schemas and every admin-write contract remain unverified until the current reference/tenant export is available.

#### Validation & Testing

Trace a harmless governance/action test through actual emitted records, verify attribution and check the destination outcome. Protect export content, keys, checkpoints and backups.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/compliance-api) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide)

---

## 5. Third-Party Integration Security

### 5.1 Integration Risk Assessment

Review the authenticated actor, allowed source resources/actions, output audience, approved runtime, retained copies and separate revocation paths. A shared owner or install button does not collapse these boundaries.

### 5.2 Approved Integration Patterns

Use narrowly scoped personal or company identities, reviewed app actions and explicit audience/approval limits. Test denials and offboarding at both ChatGPT and the connected service.

### 5.3 Scope shared connections and their source identities

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Workspace connections and team-shared individual connections can give a workflow data access beyond the invoker’s personal account. Separate permission to use a connection from permission to manage it.

#### Rationale

**Why This Matters:**

- Central connections may expose shared-drive, mailbox or repository data to a broader audience.
- Disconnecting in ChatGPT does not revoke every source grant or delete saved copies.

**Attack Prevented:** Shared-identity privilege escalation and persistent connected data.

#### ClickOps Implementation

1. Open **Admin Console > Workspace connections > +**, use the approved company identity and grant use/manage rights only to intended users, teams or service accounts.
2. For Drive choose explicit files/shared drives or separately reviewed domain-wide delegation and scopes. Gmail requires a real dedicated mailbox, not a group address. For GitHub this shared-connection flow currently uses a user sign-in, not GitHub App sign-in; Codex Security Cloud uses its own personal connection.
3. Review source-account rights, requester identity for delegated operations, connection ownership and unattended sign-in limits. During retirement revoke ChatGPT connection and provider grants/sessions, then handle saved outputs separately.

**Automation:** The documented console path is verified. The current public ChatGPT Admin schema did not load during this review, so API writes and corresponding CLI/SDK/provider coverage for this setting remain unverified. API Platform organization/project endpoints do not configure it.

#### Validation & Testing

Use a member lacking source access to establish exactly what the shared identity exposes. Verify denied resources/actions and both sides of revocation.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/shared-connections) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/teams)

---

### 5.4 Constrain @ChatGPT in Slack and Microsoft Teams

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Treat the organization’s @ChatGPT service-account assistant as distinct from a user’s app connection, a personal dot identity and legacy workspace-agent Slack channels. Its configured connections may exceed the requester’s personal access.

#### Rationale

**Why This Matters:**

- Everyone in the destination conversation can read the assistant’s response.
- A selected-channel setting does not necessarily block direct messages.

**Attack Prevented:** Cross-channel or shared-connection disclosure and unauthorized chat-triggered actions.

#### ClickOps Implementation

1. In **Admin Console > Agents**, configure the intended @ChatGPT assistant, approved connections and source identity. Grant only the tools/actions appropriate for every permitted audience.
2. Have the Slack/Teams administrator install/approve the required app and permissions in the intended workspace/tenant. Check Enterprise Grid/workspace scope, private/external channels and direct-message reach. ChatGPT enablement alone does not install the source app.
3. Restrict allowed surfaces/channels, review member and guest audiences, and verify existing installations after app-permission changes. New requested permissions do not by themselves stop an old installation.

**Automation:** The documented console path is verified. The current public ChatGPT Admin schema did not load during this review, so API writes and corresponding CLI/SDK/provider coverage for this setting remain unverified. API Platform organization/project endpoints do not configure it.

#### Validation & Testing

Test approved channel, denied channel, DM and an external/guest audience with disposable data. Compare the source identity, ChatGPT request and actual destination result; revoke every identity separately at offboarding.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/chatgpt-slack-and-teams) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/shared-connections) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide)

---

### 5.5 Restrict Team Tasks, membership and unattended writes

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Teams are distinct from SCIM groups. Team Tasks run in the cloud as a team service account with configured connections; members may see earlier runs/files and tasks have no independent run-level access restriction.

#### Rationale

**Why This Matters:**

- Inviting a teammate can disclose historical outputs and central connection access.
- Pausing/deleting a task prevents future triggers but does not reliably interrupt an active run.

**Attack Prevented:** Persistent unattended writes and historical team data disclosure.

#### ClickOps Implementation

1. In **Permissions & roles**, restrict **Create teams** and **Create and manage team tasks**. Review team membership and connection resources before enabling unattended work.
2. In **Settings > Teams**, review owners, member invites/removals and same-workspace join links. In **Scheduled > task > Team**, verify the team, connection identity, allowed actions and audience before publishing.
3. During offboarding transfer ownership first, review connections the new owner cannot use, pause future schedules/events and separately cancel active work. In Healthcare do not use non-BAA-covered event-triggered tasks with PHI.

**Automation:** The documented console path is verified. The current public ChatGPT Admin schema did not load during this review, so API writes and corresponding CLI/SDK/provider coverage for this setting remain unverified. API Platform organization/project endpoints do not configure it.

#### Validation & Testing

Test read/write approval, invitation access to prior runs, future-trigger pause and an already active run. Verify connection access after ownership transfer and compare actual Compliance coverage.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/teams) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/shared-connections) · [Supporting documentation](https://help.openai.com/en/articles/10291617-scheduled-tasks-in-chatgpt)

---

### 5.6 Bind Sign in with ChatGPT transactions and relying-party sessions

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

For selected commercial partners in the limited Sign in with ChatGPT trial, enforce the relying party’s OAuth/OIDC transaction and session security. This is an application integration, not ChatGPT workspace or API project administration.

#### Rationale

**Why This Matters:**

- A successful callback is unsafe unless it is bound to the browser’s initiating transaction.
- Unvalidated identity claims can create account confusion or session substitution.

**Attack Prevented:** Login CSRF, code injection and identity/session confusion.

#### ClickOps Implementation

1. Through the approved partner’s **Request an OAuth client** process, register exact production callback URLs and obtain the environment-specific client/discovery configuration. Trial access does not imply general product availability.
2. In the relying-party backend, generate one-time state, nonce and PKCE S256 verifier/challenge, bind them atomically to the initiating session, set short expiry and consume once. Never accept a callback-selected redirect or verifier.
3. Exchange the code server-side and validate issuer, signature/JWKS, audience, expiry and nonce before binding the verified subject to an application session. Store verified issuer/client/sub and sid for security notifications.

**Automation:** Protocol/native application implementation is documented; the storage/session framework and partner registration are deployment-specific. No generic policy file can enforce atomic transaction/session behavior; application tests are required.

#### Validation & Testing

Test wrong/replayed/expired state, wrong nonce/audience/issuer and callback mismatch with offline fixtures and the approved partner test environment. Confirm the browser session receives only the identity from its own transaction.

**Sources:** [Configuration guidance](https://developers.openai.com/siwc/website)

---

### 5.7 Verify signed account-security logout notifications

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

A Sign in with ChatGPT relying party must verify signed OIDC back-channel Logout Tokens and revoke exactly the matching local sessions and renewable credentials. The token is a logout instruction, not a login credential.

#### Rationale

**Why This Matters:**

- An unknown session ID must not cause a user-wide logout.
- Replay or token-selected key URLs can undermine a security notification endpoint.

**Attack Prevented:** Forged logout, session confusion and failure to revoke compromised sessions.

#### ClickOps Implementation

1. Configure a public HTTPS backend endpoint accepting exactly one nonempty logout_token form field without requiring a browser login. Use fixed configured OpenAI discovery/JWKS and support key rotation; ignore token-supplied key URLs.
2. Verify signature, issuer, audience, iat/exp (maximum 120 seconds), jti and the logout event, reject nonce, and enforce atomic replay detection. Invalid tokens return 400 without changing sessions.
3. With sid revoke only issuer/client/sid matches and verify optional sub. Unknown sid must not fall back to user logout. Without sid revoke issuer/client/sub sessions. Enforce revocation across all application servers; duplicate or no-match valid notifications can return 200/204.

**Automation:** The protocol and first-party example are documented; durable replay and session revocation need the relying party’s actual datastore. A snippet without that transaction boundary would be misleading, so no pseudo logout pack is supplied.

#### Validation & Testing

Use signed offline fixtures to test bad signatures/claims, expired and replayed tokens, unknown sid and subject mismatch, then prove exact-session and user-wide revocation in the application’s session store.

**Sources:** [Configuration guidance](https://developers.openai.com/siwc/account-security-notification)

---

### 5.8 Enforce plugin and Apps SDK authorization on every tool call

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3, AC-4, IA-2 |
| CIS Controls v8 | 3.3, 6.1 |

#### Description

Plugin/MCP developers must implement resource authorization in their own backend. Client metadata, tool annotations and workspace installation do not enforce access to customer-specific data or writes.

#### Rationale

**Why This Matters:**

- Anonymous tools must not expose authenticated data and OAuth discovery is not a substitute for server authorization.
- Authentication, source access and the final recipient need independent checks.

**Attack Prevented:** Unauthorized disclosure and integration credential misuse.

#### ClickOps Implementation

1. In the integration’s **authorization-server registration/configuration**, configure OAuth 2.1 with PKCE S256 and correct discovery, resource and client-registration metadata. Use the actual ChatGPT/Codex callback and supported CIMD, DCR or predefined-client flow.
2. At the MCP resource server verify token signature, issuer, intended audience/resource, expiry and required scopes for every invocation. Bind the verified identity to application authorization; never trust a model-supplied user ID.
3. Publish matching per-tool securitySchemes and protected-resource metadata. Return the documented runtime auth challenge when authorization is missing; review scopes, linked identity and provider revocation separately.

**Automation:** OAuth metadata, tool declarations and backend checks are documented. Native application wiring depends on the server/IdP; a static manifest alone cannot implement authorization. No universal ChatGPT policy is supplied.

#### Validation & Testing

Test expired/wrong-audience/wrong-scope credentials, cross-user resource IDs and unauthenticated writes. Confirm the server denies them even if a tool advertises broader access.

**Sources:** [Configuration guidance](https://developers.openai.com/plugins/build/auth)

---

### 5.9 Protect Agentic Commerce credentials and transaction boundaries

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3, AC-4, IA-2 |
| CIS Controls v8 | 3.3, 6.1 |

#### Description

Merchant and payment-provider implementations own checkout authorization, transaction integrity and payment-data handling. These controls are separate from API project credentials and API Platform webhook signatures.

#### Rationale

**Why This Matters:**

- Duplicate or altered payment requests can create financial side effects; direct card-data handling changes PCI scope.
- Authentication, source access and the final recipient need independent checks.

**Attack Prevented:** Unauthorized disclosure and integration credential misuse.

#### ClickOps Implementation

1. In the merchant/PSP **production integration configuration**, use TLS 1.2+ on port 443, reviewed credentials and required API version. Keep secrets/payment data out of repository logs and use the approved provider sandbox for launch tests.
2. Enforce Idempotency-Key across create/complete requests: identical retries return the same outcome and mismatched parameters produce 409. Verify order-created/updated webhook HMAC using the commerce contract, not the API Platform unwrap helper.
3. For delegated payment enforce single-use tokens, approved maximum amount and expiry, and the specified canonical JSON/detached signature. Review actual cardholder-data handling with the PSP/assessor before production; OpenAI is not the merchant of record.

**Automation:** Protocol/native merchant configuration is documented. Replay/idempotency enforcement needs the merchant’s actual datastore and PSP. No placeholder payment processor or production transaction is included.

#### Validation & Testing

In the provider sandbox test duplicate/mismatched idempotency, invalid/replayed/expired tokens, amount limits and invalid webhook signatures. Confirm no duplicate charge/order or unauthorized state change.

**Sources:** [Configuration guidance](https://developers.openai.com/commerce/guides/production) · [Supporting documentation](https://developers.openai.com/commerce/specs/payment)

---

## 6. Workspace Agents Hardening

### 6.1 Keep Workspace Agents Disabled Until Governance Is in Place

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Enable workspace-agent creation/use only for a reviewed audience after connection, action, sharing and owner lifecycle decisions. Current permission labels and available surfaces vary by workspace and migration.

#### Rationale

**Why This Matters:**

- An agent can combine private reads, untrusted content and external writes.
- A role-change audit sample is not evidence of effective agent permission.

**Attack Prevented:** Unreviewed autonomous workflows and excessive builder/publisher access.

#### ClickOps Implementation

1. In **Admin > Permissions & roles**, review the current **Workspace agents** access and relevant create/share/publish permissions offered for the workspace. Keep the workspace default restrictive and inspect all additive role/group grants.
2. Approve a named owner, source identities, allowed actions, recipients, schedules/triggers, evidence and a retirement path before enabling the audience. Check Team Tasks, @ChatGPT, dots and Work product gates separately.

**Automation:** The documented console path is verified. The current public ChatGPT Admin schema did not load during this review, so API writes and corresponding CLI/SDK/provider coverage for this setting remain unverified. API Platform organization/project endpoints do not configure it.

#### Validation & Testing

Test one denied member and the intended builder/user against the actual workspace controls. Record labels and effective rights; do not infer agent RBAC from USER_LOG samples.

**Sources:** [Configuration guidance](https://developers.openai.com/workspace-agents/authentication) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/roles-and-workspace-permissions) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/teams)

---

### 6.2 Minimize Connector Scopes and Default to Read-Only

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Constrain source permissions and allowed app actions before agent use. Read-only plugin settings do not prevent writes through a signed-in browser or separately connected computer.

#### Rationale

**Why This Matters:**

- An agent can take an action through a different enabled route.
- OAuth consent and workspace app availability do not establish least privilege.

**Attack Prevented:** Overbroad source access and alternate-route writes.

#### ClickOps Implementation

1. In **Admin Console > Plugins > included app > Tools / Actions**, permit reviewed read actions and deny unneeded existing/new write tools.
2. In the **connected service’s account/app administration**, scope the actual identity, repositories/resources and consent. Review shared accounts and browser/local access separately.

**Automation:** The documented console path is verified. The current public ChatGPT Admin schema did not load during this review, so API writes and corresponding CLI/SDK/provider coverage for this setting remain unverified. API Platform organization/project endpoints do not configure it.

#### Validation & Testing

Attempt the prohibited write through each enabled app/browser/computer route with disposable data. Confirm denial at the relevant product and source system.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/apps-and-connectors) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/shared-connections) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/dots-security)

---

### 6.3 Require Human Approval for Sensitive Agent Actions

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Configure app confirmation and runtime approvals for the actual action path. Natural-language owner instructions and automated review are additional safeguards, not proof that every consequential action requires a human click.

#### Rationale

**Why This Matters:**

- Scheduled authorizations can permit unattended sends.
- Approval settings have runtime and tool-specific coverage.

**Attack Prevented:** Unreviewed consequential actions and overclaimed approval gates.

#### ClickOps Implementation

1. In **Plugins > app > Permissions**, select the supported confirmation setting for sensitive actions; restrict the tools themselves where approval coverage is insufficient.
2. For supported orchestrator/command workflows review **Agent Security > Global > Requirements > Allowed approval policies** and execution-specific requirements; see the Work/Codex guide.
3. Test scheduled/event-triggered authorizations, browser and desktop actions independently. Disable the unsupported path if the organization requires a stronger approval gate.

**Automation:** App confirmation and native managed requirements are documented. The removed universal approval-policy JSONC was not a native interface; implement the actual app/runtime controls and verify their coverage.

#### Validation & Testing

Use harmless writes to verify exactly when a human is asked, what was authorized and the receiving-system outcome. Record automated-review and hook failure limits.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/apps-and-connectors) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/agent-security) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/dots-security)

---

### 6.4 Detect Lethal-Trifecta Agents and First-Use MCP Tools

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Review workflows that combine private data, untrusted inputs and external actions. Use current configuration inventories and supported audit records; a plugin catalog is a review lead, not a member entitlement or trifecta detector.

#### Rationale

**Why This Matters:**

- A newly granted tool can expand an established workflow’s trust boundary.
- Unknown schemas and missing log values cannot produce a trustworthy clean result.

**Attack Prevented:** Cross-source prompt injection and unnoticed tool expansion.

#### ClickOps Implementation

1. Open **Admin Console > Plugins > Public > Export CSV** to review the public catalog metadata, included apps and skills. It may be 48 hours old and excludes workspace-created plugins and member entitlements.
2. Combine it with actual agent/team/dot inventory, owners, source permissions, app tools and recipients. Review custom MCP tools and high-risk combinations manually.
3. Use current emitted APP_MCP_CALL/RESULT or other documented product records only where applicable. Establish a per-identity/tool baseline in the SIEM and test it before alerting; do not invent event names or treat a Sigma selection as first-seen correlation.

**Automation:** Current public catalog export and product logs are documented, but no current public complete agent-permission CSV/API contract was verified. The fabricated CSV detector and placeholder Sigma rules were removed; first-use correlation remains deployment-specific.

#### Validation & Testing

Use a disposable tool change to prove the inventory and record actually identify the actor/tool. Missing inventory or schema means incomplete review, not No trifecta detected.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/apps-and-connectors) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/dots-security) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/compliance-api)

---

### 6.5 Operationalize Agent Suspension for Incident Response

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Maintain a containment procedure for each actual product. Pause future work and revoke identities while separately checking active/delegated runs, schedules, source sessions and completed external actions.

#### Rationale

**Why This Matters:**

- A generic no-op script cannot suspend an agent.
- Pausing future triggers does not establish that an active task or external side effect stopped.

**Attack Prevented:** Continued autonomous access during an incident.

#### ClickOps Implementation

1. For personal dots use **Admin Console > Dots > dot > Pause** and verify inventory state. For Team Tasks use **Scheduled > task > Pause** and cancel active/delegated work separately.
2. For legacy workspace agents use the current agent management controls actually offered; if suspension is unavailable or unverified, revoke the applicable product access and source grants and escalate through the organization’s incident process.
3. Preserve task IDs, source/action evidence and timestamps, revoke connected tokens/sessions/devices, then verify destination changes. Reverse completed actions through the receiving service when possible.

**Automation:** Verified product-specific console paths above; current generic workspace-agent suspension API was not verified. The prior no-op suspend pack and placeholder event rule were invalidated and removed.

#### Validation & Testing

Rehearse future, active and delegated tasks with disposable data, verify source revocation and measure reporting delay. Do not report successful containment from a printed manual prompt.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/dots-security) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/teams) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/user-lifecycle)

---

### 6.6 Stream Compliance Platform Logs to SIEM

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Continuously export the ChatGPT workspace log families authorized by the Admin key. Preserve complete files and advance checkpoints only after every page/file succeeds. This is a pull exporter, not an assertion of real-time or complete agent coverage.

#### Rationale

**Why This Matters:**

- The platform retains logs for 30 days.
- Advancing on a partial download can permanently skip evidence.

**Attack Prevented:** Audit gaps, checkpoint data loss and sensitive export disclosure.

#### ClickOps Implementation

1. Create a minimum-scope workspace key in **Admin Console > Credentials > Admin keys**, using CODEX_LOG for supported Work/dots records and other supported families as required. Broad/conversation grants require an owner.
2. Run the pack with an approved private output directory, UTC start and explicitly reviewed event families; forward completed JSONL files with the SIEM’s supported ingestion path.
3. Monitor HTTP failures, malformed pagination, disk failures, freshness and missing families. Keep checkpoints and exports private, deduplicate by file ID and set downstream retention.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-enterprise" section="6.6" %}

#### Validation & Testing

Use fixtures to verify multiple pages, failed download/resume, malformed responses and private outputs. In the tenant prove actual log families and downstream arrival with a harmless test; an empty pull is not an audit pass.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/compliance-api) · [Supporting documentation](https://developers.openai.com/downloads/compliance-api/download_compliance_files.sh)

---

### 6.7 Execute the OpenAI Pre-Launch Admin Checklist

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Record a reviewable release decision with owner, audience, identities, tools, destinations, approval behavior, retention, evidence and containment. The checklist is governance, not a native policy object.

#### Rationale

**Why This Matters:**

- An undocumented assumption can become a production permission boundary.
- Ongoing source/tool changes can invalidate a one-time review.

**Attack Prevented:** Unsafe rollout and unowned agent lifecycle.

#### ClickOps Implementation

1. Before enablement, attach configuration evidence for roles, source identities, permitted actions, runtime environments, recipients and data categories to the organization’s change record.
2. Record all unsupported/unverified paths and require the workflow’s security needs to fit verified controls. Assign a reviewer, re-review trigger and expiry date.
3. Run harmless end-to-end denial, approval, audit and containment tests for every enabled route. Re-review when plugins, models, connections, owners or runtime policies change.

**Automation:** No native checklist JSONC policy exists in the admitted documentation. Use the organization’s change-management system and the real implementation packs for its individual controls.

#### Validation & Testing

A second administrator must be able to reproduce the effective permissions and locate evidence. A completed JSON checklist alone cannot pass deployment.

**Sources:** [Configuration guidance](https://learn.chatgpt.com/docs/enterprise/admin-setup) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/teams)

---

### 6.8 Govern the Workspace Agents Trigger API and Personal Access Tokens

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, AU-6 |

#### Description

Use dedicated Workspace Agents tokens for published API triggers, with upstream event authentication, per-event idempotency and correct conversation isolation. The trigger is asynchronous; beta status does not return the agent’s response content.

#### Rationale

**Why This Matters:**

- A repeated external event can enqueue duplicate actions.
- Reusing conversation_key across unrelated users can mix context.

**Attack Prevented:** Unauthorized trigger execution, duplicated actions and cross-conversation context exposure.

#### ClickOps Implementation

1. In **Admin > Permissions & roles**, review **Allow users to create personal access tokens** and Workspace agents eligibility. In **Admin > Access tokens** provision only the **Workspace Agents** scope and store the token securely.
2. In the calling backend authenticate the upstream event, map it to the intended published agtch_ trigger and conversation, and reuse Idempotency-Key only for retries of the same event. Do not accept an arbitrary user-supplied trigger or conversation key.
3. If using beta run tracking, send the documented beta header on the authorized trigger call and persist the returned apirun_ ID. Use the read-only pack to inspect status; queued/suspended/completed do not prove an external write outcome or return response content.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-enterprise" section="6.8" %}

#### Validation & Testing

With approved disposable triggers test invalid/revoked scope, event replay, conversation separation and failure/conflict behavior. The supplied status-read fixture never triggers a live run.

**Sources:** [Configuration guidance](https://developers.openai.com/workspace-agents/authentication) · [Supporting documentation](https://developers.openai.com/workspace-agents/trigger-runs)

---

## Edition and workflow boundaries

**Enterprise and Edu:** use the verified workspace/tenant controls, then check actual entitlement and UI. **Business:** standalone SSO exists; standalone SCIM and Enterprise role-level/compliance capabilities must not be assumed. App availability defaults differ. **Teachers:** district-managed verified U.S. K–12 educators and staff, not students; tenant SCIM must target staff only. Domain joining/direct invites require separate review, and Teachers has no Automatic Account Creation setting. [Teachers guidance](https://help.openai.com/en/articles/12844995-chatgpt-for-teachers), [identity guidance](https://help.openai.com/en/articles/9047883-getting-started-with-openai-identity-and-access-for-managed-workspaces).

**Healthcare:** confirm the BAA covers each enabled workflow. Enable **Trusted clinical search** only for intended roles in **Permissions & roles**. Improved Memory is off by default in Healthcare/Regulated Workspace; enable **Use improved memory** only for approved populations and confirm the current PHI restriction. Event-triggered tasks are not BAA-covered: do not transmit, store or process PHI through them. Epic is organization-activated for eligible Healthcare/HIPAA Enterprise workspaces and uses each clinician’s Epic account; Healthcare Public Data is a different public-source plugin. Neither workspace access nor plugin installation grants patient access. [Healthcare](https://help.openai.com/en/articles/20001046-chatgpt-for-healthcare), [HIPAA functionality](https://help.openai.com/en/articles/20001069-hipaa-eligible-products-and-functionality), [Epic](https://help.openai.com/en/articles/20001490-using-the-epic-plugin-with-chatgpt-and-codex).

### Individual accounts and healthcare boundaries

Free/Go/Plus/Pro use individual **Security and login**, **Data controls**, **Personalization/Memory**, app connections and sharing controls. Review model-improvement, temporary chats, saved files and source-service access; managed-workspace no-training defaults do not establish personal settings. Lockdown Mode availability and per-chat override depend on the account. **Health** is a personal feature with separate health-data and connected-service controls; it is not a Healthcare workspace. **Clinicians** is an individual verified-clinician offering: accept an eligible BAA in **Settings > Agreements** before authorized PHI use, and use Healthcare for a multi-user agreement/central deployment. Third-party GPTs/apps need their own permissions and agreements. [Data controls](https://help.openai.com/en/articles/7730893-data-controls-in-chatgpt), [Health](https://help.openai.com/en/articles/20001036-what-is-chatgpt-health), [Clinicians](https://help.openai.com/en/articles/20001202-chatgpt-for-clinicians).

## 7. Compliance Quick Reference

| Control family | Guide sections | Evidence limit |
|----------------|----------------|----------------|
| Identity and least privilege — NIST IA-2, AC-2, AC-6 | 1.1–1.5 | Verify effective sign-in and all grants; native MFA enforcement unavailable |
| Data, keys and sharing — NIST SC-12, SC-28, SI-12, AC-4 | 2.1–2.5 | Contract/content category and downstream copy boundaries differ |
| Configuration and integrations — NIST CM-6, CM-7, AC-3 | 3.1–3.4, 5.3–5.7 | Source identity and relying-party/session controls remain independent |
| Audit and incident response — NIST AU-6, AU-12, IR-4 | 4.1–4.3, 6.1–6.8 | Current schema, runtime coverage and receiving-system outcome must be proven |

These are mappings to control objectives, not claims of certification. The [source-first inventory](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/openai-source-coverage.md) separates verified settings, unavailable features and unverified contracts. The current public Admin API schema could not be loaded in this run; no current absence claim is inferred. Existing fake JSONC/no-op and placeholder detection packs were invalidated; the actual native Work/Codex packs and current Compliance/trigger status reads replace those claims.

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-05 | 0.4.0 | ai-drafted | Source-first platform map; correct tenant identity/native MFA, sharing, plugin and integration controls; add Lockdown, Space/Sites, shared connections, Slack/Teams, Team Tasks and SIWC. Preserve control IDs/headings; replace invalidated pseudo-policies/no-op packs and 6.6 collision with current export/status reads. No live validation. | Codex |
| 2026-10-10 | 0.3.2 | ai-drafted | Added Ona, acquired by OpenAI in August 2026, to the Products in This Platform table and the product-guide line, stating that the ChatGPT controls here do not configure it. No control changed | Claude Code (Opus 5.5) |
| 2026-10-09 | 0.3.1 | ai-drafted | Became the Common Controls hub of the new OpenAI multi-product platform (`platform: "OpenAI"`, `product: "Common Controls"`): added a Products in This Platform table linking the ChatGPT Dots product guide, and a dots pointer in Section 6. No control changed. | Claude Code (Opus 5.5) |
| 2026-08-08 | 0.3.0 | ai-drafted | Currency pass: re-sourced Section 6 off the removed Workspace Agents Security Overview PDF (annotated PDF-only claims; cited live learn.chatgpt.com / developers.openai.com docs); rewrote 3.1/3.2 for the plugins + bundled skills + connectors model and six control boundaries; new control 6.8 (Workspace Agents trigger API + PAT governance); workspace agents no longer "research preview"; added 30-day Compliance Platform retention and endpoint surface to 6.6; converted the stateful-route deprecation to a completed removal (removed 2026-06-05); added the 18-partner Compliance Platform ecosystem to 4.2/5.2; fixed 1.3/1.4/2.4/3.1 cheat-parser misses; fixed 6.6 duplicate pack includes and two broken compliance-table anchors; migrated Appendix B to the learn.chatgpt.com canonical set, fixed the Compliance API slug, purged trust-center links; rewrote the three Sigma rules in schema-agnostic form with login-gated schema warnings | Claude Code (Fable 5) |
| 2026-05-14 | 0.2.1 | ai-drafted | Reconciled Section 6 against OpenAI's *Workspace Agents Security Overview* (April 29, 2026). Added the fifth RBAC dimension `publish_agents_with_shared_connections` (6.1). Replaced reconstructed event-type list with the PDF's authoritative agent lifecycle / run / connector-call / OAuth-resolution / skill / trigger / memory event families (6.6). Added Logs Platform technical specs (~10-min windows, p99 < 30 min, at-least-once, event_id dedup). Added control 6.7 implementing OpenAI's six-step pre-launch checklist. Updated Sigma rules and the SIEM-streaming and trifecta-detection scripts with PDF-verified event names and app catalog. New pack file: `config/hth-chatgpt-enterprise-6.07-prelaunch-checklist.jsonc`. | Claude Code (Opus 4.7) |
| 2026-05-14 | 0.2.0 | ai-drafted | [SECURITY] Added Section 6 Workspace Agents Hardening (6 controls covering RBAC, connector posture, approval policy, lethal-trifecta detection, suspension runbook, Compliance API SIEM export). Added Code Packs under `packs/chatgpt-enterprise/` (api, config, siem/sigma). Updated NIST and GDPR mappings. Expanded References with workspace agent, Compliance API, and agent-security research links. | Claude Code (Opus 4.7) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with SSO, data privacy, GPT controls, and compliance | Claude Code (Opus 4.5) |
