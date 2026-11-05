---
layout: guide
title: "Grok Hardening Guide"
vendor: "Grok"
slug: "grok"
platform: "SpaceXSI"
platform_slug: "spacexai"
product: "Grok"
tier: "1"
category: "DevOps"
description: "Grok account, Business and Enterprise workspace hardening, identity, connector consent and data lifecycle"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-05"
---

## Overview

Grok web and mobile Chat, Imagine and Voice share account and workspace boundaries. Business/Enterprise workspaces are managed in console.x.ai; personal Grok accounts and X sign-in links remain separate authority paths. The Cursor team policy in the family hub does not configure this console.

See the [family Common Controls index](/guides/cursor/#products-in-this-platform) for product boundaries. A shared owner does not establish shared policy inheritance. SpaceXSI is the current first-party name; the historical platform URL remains stable. [Source-first reconciliation](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/spacexai-source-coverage.md) records the discovery scope, evidence and gaps.

### Intended Audience

Administrators, security engineers and application owners responsible for this product's identities, data and integrations.

### How to Use This Guide

Apply L1 (Crawl) controls first, then L2 (Walk) for sensitive workloads and L3 (Run) where strict deployment requirements justify them. **No tenants declared — Tier 0+1 only; VERIFIED-LIVE = 0.** All content remains AI-drafted. No credentials, settings or live integrations were created or changed during research.

### Scope

Covers consumer account/data choices and Grok Business/Enterprise organizations, licenses, workspaces and connectors. Developer API/PromptIDE, Grok Bot and Build have separate guides. Grokipedia is a discovered consumer service without a fetched enterprise configuration reference; no tenant controls are invented for it. Government and negotiated deployments require deployment-specific evidence.

## Table of Contents

1. [Identity and Entitlements](#1-identity-and-entitlements)
2. [Workspace and Data Boundaries](#2-workspace-and-data-boundaries)
3. [Connected Services](#3-connected-services)
4. [Lifecycle and Response](#4-lifecycle-and-response)

---

## 1. Identity and Entitlements

### 1.1 Enforce Organization SSO and Review Domain Association

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
On Grok Enterprise, configure and test organization SSO. Domain-associated users are governed by the organization; non-domain email addresses retain standard sign-in paths.

#### Rationale
**Why This Matters:**
- An approved domain and an external collaborator can follow different authentication paths.

**Attack Prevented:** Unauthorized account access through ungoverned identities.

#### ClickOps Implementation
1. Open **console.x.ai/organization → Configure SSO** as an organization admin. Complete the IdP wizard and test before activation.
2. Review **Users** and **Teams** on that page, including domain associations and external addresses; enforce MFA and assignment in the IdP.

[First-party configuration reference](https://docs.x.ai/grok/organization) (fetched 2026-11-05).

**Automation:** Unverified — no setting-specific administrative REST, GraphQL, CLI, SDK or native-policy handle was established by the fetched references. Use the documented console path; do not substitute another product’s API.

#### Validation & Testing
Have an authorized administrator test domain SSO and an external-email account separately; record exceptions without weakening the whole IdP policy. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

### 1.2 Scope SCIM Roles and Verify the Default Member Role

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Use Enterprise SCIM to map IdP groups to teams, permissions and licenses. Review role priority and the default Member fallback before activation.

#### Rationale
**Why This Matters:**
- Overlapping groups and fallback roles can grant unintended seats or privileges.

**Attack Prevented:** Privilege persistence and incorrect automatic provisioning.

#### ClickOps Implementation
1. Open **Organization → Setup SCIM**, connect the directory, create roles and use **Assign Groups → Configure role assignment**.
2. Set role order, team ACLs and product licenses. Inspect the preview before **Activate**. Review the fallback Member role.

[First-party configuration reference](https://docs.x.ai/grok/organization) (fetched 2026-11-05).

**Automation:** Unverified — no setting-specific administrative REST, GraphQL, CLI, SDK or native-policy handle was established by the fetched references. Use the documented console path; do not substitute another product’s API.

#### Validation & Testing
Test joining, group changes and removal using approved test identities. Confirm license and team state in the preview and live console; directory sync is not proof of API-key revocation. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

### 1.3 Separate License Administration from Billing Authority

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Grant Team Read-Write and Billing Read-Write only to approved operators. Review license assignments and pending invitations; an invitation may assign an available license when accepted.

#### Rationale
**Why This Matters:**
- A purchased seat and an accepted invitation can create usable access independently of a project approval.

**Attack Prevented:** Unapproved entitlement and spend expansion.

#### ClickOps Implementation
1. Select the intended team in **console.x.ai → Grok Business Overview**. Review assigned licenses and invitations.
2. Reserve billing changes for billing operators and assignment/invitation management for team operators. Remove stale invitations and unneeded seats.

[First-party configuration reference](https://docs.x.ai/grok/management) (fetched 2026-11-05).

**Automation:** Unverified — no setting-specific administrative REST, GraphQL, CLI, SDK or native-policy handle was established by the fetched references. Use the documented console path; do not substitute another product’s API.

#### Validation & Testing
Reconcile active/pending users and license types against the IdP roster; confirm the operator permissions from the current console. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

## 2. Workspace and Data Boundaries

### 2.1 Keep Business Conversations in the Team Workspace

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Use the licensed team workspace for company data. Personal workspaces have separate terms and data controls; Enterprise disabling of personal workspaces requires sales configuration.

#### Rationale
**Why This Matters:**
- A business license does not turn every personal chat into a protected team conversation.

**Attack Prevented:** Data disclosure through the wrong workspace or share link.

#### ClickOps Implementation
1. Check the **workspace selector at the bottom left of grok.com** before starting work. Select the licensed team.
2. For Enterprise, request personal-workspace disablement and required retention through sales. Share team conversations only with approved licensed members.

[First-party configuration reference](https://docs.x.ai/grok/user-guide) (fetched 2026-11-05).

**Automation:** Unverified — no setting-specific administrative REST, GraphQL, CLI, SDK or native-policy handle was established by the fetched references. Use the documented console path; do not substitute another product’s API.

#### Validation & Testing
Confirm team workspace selection and have an approved unlicensed/non-team test identity attempt a synthetic shared link; verify negotiated settings in writing. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

### 2.2 Review Consumer Training and Linked Sign-In Choices

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Review personal Grok data controls and linked sign-in methods separately from enterprise retention. Consumer Imagine/Voice and web/mobile activity use the account boundary; X-linked settings are a separate operational plane.

#### Rationale
**Why This Matters:**
- Removing an app or a workspace seat does not establish that every linked sign-in and personal data choice has changed.

**Attack Prevented:** Unintended personal-data use and retained account access.

#### ClickOps Implementation
1. Use **Grok → Profile → Settings → Data Controls** to inspect the account’s current data choices; review the linked sign-in methods at **accounts.x.ai**.
2. Use the exact web/mobile training switch described in current privacy help. Verify personal choices separately from the business contract and X account.

[First-party configuration reference](https://x.ai/legal/privacy-policy) (fetched 2026-11-05).

**Automation:** Unverified — no setting-specific administrative REST, GraphQL, CLI, SDK or native-policy handle was established by the fetched references. Use the documented console path; do not substitute another product’s API.

#### Validation & Testing
Record the actual current switch state and linked identities on each approved client. Do not infer API ZDR, business retention or Bot privacy from a consumer switch. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

## 3. Connected Services

### 3.1 Approve the Team Connector Catalog Before User Consent

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Provision only approved Grok Business/Enterprise connectors. Team catalog approval and each member’s provider OAuth connection are separate grants.

#### Rationale
**Why This Matters:**
- A catalog entry can make a new data service available to every eligible team member.

**Attack Prevented:** Unreviewed third-party data access.

#### ClickOps Implementation
1. Select the team in **console.x.ai → Grok Business → Connectors**. Use **+ Add Connector** only after reviewing the service and requested authority.
2. Review **Configure** settings; use **Remove** for unapproved connectors. Members connect their own accounts at **grok.com/connectors**.

[First-party configuration reference](https://docs.x.ai/grok/connector-management) (fetched 2026-11-05).

**Automation:** Unverified — no setting-specific administrative REST, GraphQL, CLI, SDK or native-policy handle was established by the fetched references. Use the documented console path; do not substitute another product’s API.

#### Validation & Testing
Compare the catalog with approved providers and inspect both team configuration and a member’s actual consent scopes; removing an entry is not evidence of revoking every upstream credential. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

### 3.2 Separate Connector Reads, Indexing and Writes

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
For SharePoint, explicitly choose a constrained indexing principal or selected-site application mode. Approve the separate write application only where necessary, and keep member write opt-in limited.

#### Rationale
**Why This Matters:**
- Background indexing, per-user retrieval and write consent use different authority paths.

**Attack Prevented:** Overbroad document indexing and unauthorized overwrite.

#### ClickOps Implementation
1. In **Grok Business → Connectors → SharePoint**, choose delegated access with a constrained account or application **Sites.Selected**, then select approved sites after admin consent.
2. Leave **Enable Write Access** off unless required. If approved, inspect its separate consent and member opt-in; repeat provider-specific scope review for OneDrive, Teams, Google and Salesforce.

[First-party configuration reference](https://docs.x.ai/grok/connectors/sharepoint) (fetched 2026-11-05).

**Automation:** Unverified — no setting-specific administrative REST, GraphQL, CLI, SDK or native-policy handle was established by the fetched references. Use the documented console path; do not substitute another product’s API.

#### Validation & Testing
Test authorized and unauthorized sites with synthetic files; verify upstream ACL checks and write denial for an unapproved member. Review disconnect/index deletion behavior in the connector-specific reference. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

### 3.3 Authenticate Custom MCP Services Beyond Tunnel Reachability

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Approve custom MCP endpoints as external processors with narrowly scoped tools and credentials. A public tunnel changes reachability; it does not supply application authentication.

#### Rationale
**Why This Matters:**
- A tunnel can expose an internal tool server to the internet and to a model-controlled client.

**Attack Prevented:** Unauthenticated tool execution and internal-data exposure.

#### ClickOps Implementation
1. Use **Grok Business → Connectors → + Add Connector → Other** only for an approved server URL and authentication flow.
2. Require service-side authorization and limited tokens. Inventory the tunnel provider and stop/remove unused tunnels and connectors.

[First-party configuration reference](https://docs.x.ai/grok/connectors/custom-mcp-tunneling) (fetched 2026-11-05).

**Automation:** Unverified — no setting-specific administrative REST, GraphQL, CLI, SDK or native-policy handle was established by the fetched references. Use the documented console path; do not substitute another product’s API.

#### Validation & Testing
Confirm an unauthenticated caller is rejected and only approved tools/data are available; avoid using a real write task as a connectivity test. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

## 4. Lifecycle and Response

### 4.1 Remove Assets and Revoke Credentials During Offboarding

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Remove user access, assets, upstream connector consent and API keys as separate lifecycle actions. Removing a console member leaves that member’s API keys with the team; account deletion also removes API access.

#### Rationale
**Why This Matters:**
- Seat removal alone does not end all machine or external-service authority.

**Attack Prevented:** Orphaned API access and retained data after departure.

#### ClickOps Implementation
1. Review **console.x.ai → Users** and team membership, then inventory retained API keys through the [API guide](/guides/grok-api/).
2. Use **grok.com/files** and **Profile → Settings → Data Controls** for authorized asset cleanup. Disconnect connectors and revoke upstream application consent. Account deletion at **accounts.x.ai** affects API access and is a separate approved destructive step.

[First-party configuration reference](https://docs.x.ai/grok/faq) (fetched 2026-11-05).

**Automation:** Unverified — no setting-specific administrative REST, GraphQL, CLI, SDK or native-policy handle was established by the fetched references. Use the documented console path; do not substitute another product’s API.

#### Validation & Testing
Reconcile member, key and provider state after offboarding. Verify retention exceptions and the account restoration window in current help; do not perform destructive tests on production accounts. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

## Automation and Evidence Limits

The fetched Grok workspace references establish GUI/IdP configuration, not a workspace administration API/CLI/SDK schema. The Management API covers developer keys/billing/audit and must not be substituted for licenses or connector policy. No workspace packs are fabricated. Native managed-client policy, organization-wide conversation audit export and product-specific Terraform remain unverified.

The [family research ledger](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/spacexai-source-coverage.md) distinguishes documented interfaces, bounded searches and unverified gaps across Terraform resources/data sources, REST/GraphQL, CLI, SDK, native config/MDM and SIEM. Packs are available only where a fetched contract supports them. Read-only inventories and offline configuration preparation are not enforcement. No live tenant, consent flow, destructive operation or integration trigger was exercised.

## Compliance Quick Reference

| Theme | NIST SP 800-53 | CIS Controls v8 |
|-------|----------------|-----------------|
| Identity and privilege | AC-2, AC-3, AC-6, IA-2 | 5, 6 |
| Data and network boundary | SC-7, SC-8, SI-12 | 3, 13 |
| Monitoring and response | AU-2, AU-6, IR-4 | 8, 17 |

Mappings are thematic. No product-specific CIS, DISA or SCuBA recommendation/version was established by the bounded catalog search. The CIS AI benchmark body was not retrieved, so no numeric benchmark mappings are asserted.

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-11-05 | Initial source-first product coverage; documented control-plane and automation limits |

## Contributing

See [CONTRIBUTING.md](https://github.com/grcengineering/how-to-harden/blob/main/CONTRIBUTING.md). Submit current first-party configuration evidence and edition details with corrections.
