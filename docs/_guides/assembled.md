---
layout: guide
title: "Assembled Common Controls Hardening Guide"
vendor: "Assembled"
slug: "assembled"
platform: "Assembled"
platform_slug: "assembled"
product: "Common Controls"
tier: "2"
category: "Productivity"
description: "Harden Assembled identity, provisioning, API keys, integrations and inbound MCP access across workforce management and AI products."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-16"
---

## Overview

Assembled is a support operations platform from Assembled, Inc. Its shared administrative plane manages workforce identities, roles, integrations, and API access. Product-specific guidance sits in the two guides below. The [company terms](https://www.assembled.com/terms-of-service) identify Assembled, Inc.; the current [product overview](https://support.assembled.com/hc/en-us/articles/39589572987789-About-Assembled) distinguishes WFM from AI agents and Copilot. No change of ownership was established by this research.

### Products in This Platform

| Product | Guide | Security scope |
|---------|-------|----------------|
| Common Controls | This guide | Shared identity, API access and integration governance |
| Workforce Management | [WFM guide](/guides/assembled-wfm/) | BPO/site boundaries, reports, exports, tracking and schedule audit |
| AI Agents & Copilot | [AI guide](/guides/assembled-ai/) | Customer identity, knowledge, tools, privacy and workflow release controls |

### Intended Audience

- Security and identity administrators
- Support operations and integration owners
- GRC practitioners collecting configuration evidence

### How to Use This Guide

Apply L1 (Crawl) controls first; L2 (Walk) adds tighter access boundaries. Enforce MFA and contextual sign-in policy in your identity provider. Confirm your contract and feature flags with Assembled before changing access.

### Scope

Commercial Assembled customer settings. This hub does not duplicate WFM or AI product controls. Vendor infrastructure, certifications and credential-rotation runbooks are outside this guide's scope.

**Validation boundary:** Documentation and offline fixtures only; no tenant or credentials were supplied. Console paths were not walked in a customer account, and API/SDK/SIEM packs were not exercised against a live deployment. See the [source coverage and validation ledger](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/assembled-source-coverage.md) and [maturity definitions](https://github.com/grcengineering/how-to-harden/blob/main/VERSIONS.md#maturity-statuses--the-matrix).

**Current incident context:** Assembled's [November 13, 2026 incident notice](https://support.assembled.com/hc/en-us/articles/50413354064909-November-13-2026-security-incident), updated November 15, reports access to its integration-credential database. It treats stored outbound integration credentials as compromised and provides account-specific recovery guidance. The notice distinguishes those from customer-created Assembled API keys, which it says are stored hashed and need no replacement for this incident. Scope may evolve with the promised root-cause analysis; use the notice for recovery and this guide for reducing continuing exposure.

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Network Access Controls](#2-network-access-controls)
3. [OAuth & Integration Security](#3-oauth--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

## 1. Authentication & Access Controls

### 1.1 Require SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | IA-2 |

#### Description

Connect the corporate identity provider and require SSO after testing the connection. Apply phishing-resistant MFA through that provider; a separate native Assembled MFA-enforcement setting was not verified.

#### Rationale

**Why This Matters:**

- SSO centralizes sign-in policy and access review.
- Leaving alternate password sign-in enabled can bypass identity-provider safeguards.

**Attack Prevented:** Password reuse and bypass of corporate sign-in policy.

#### Prerequisites

IdP administrator, company-specific SAML values from Assembled, active test accounts and a proven recovery process.

#### ClickOps Implementation

1. Ask Assembled support for your company-specific SAML metadata, ACS URL and Entity ID.
2. Register the application in your IdP, set NameID to the Assembled email address, and assign approved users or groups. Send IdP metadata through the agreed support channel.
3. From the Assembled sign-in page, select **Sign in with SAML SSO** and test an existing active account.
4. After testing every required population and arranging recovery with support, ask support to require SSO at an agreed rollout time. This disables other sign-in methods, including password and Google sign-in.

Source: [SAML single sign-on](https://support.assembled.com/hc/en-us/articles/14654026012173-SAML-single-sign-on) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([SAML single sign-on](https://support.assembled.com/hc/en-us/articles/14654026012173-SAML-single-sign-on), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Verify an assigned test user completes IdP MFA and signs in.
2. After enforcement, verify alternate sign-in is denied and an unassigned test user cannot obtain a new session. Review existing-session behavior separately with support.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

High lockout risk: enforcement disables every alternate sign-in path. Do not enable it before SSO works for administrators and users. Coordinate rollback with Assembled support.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

### 1.2 Minimize Administrative Roles

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Assign each person the least powerful role needed and restrict who can change roles. Custom-role capabilities need Pro or Enterprise; do not assume a role name proves its current permissions.

#### Rationale

**Why This Matters:**

- Role editors can expand access across the company.
- Default roles may have been customized since deployment.

**Attack Prevented:** Privilege escalation through excessive administrative access.

#### Prerequisites

An Assembled administrator; test accounts with the affected roles.

#### ClickOps Implementation

1. Open **Manage team > Roles and permissions** and review the role permissions against approved duties.
2. On Pro or Enterprise, use **Add custom role** and a suitable base role for narrower duties; save the approved settings.
3. Use **Manage team > People management > [person] > Role** to assign the approved role and select **Save changes**.

Source: [Roles and permissions](https://support.assembled.com/hc/en-us/articles/4414692774285-Roles-and-permissions) (checked 2026-11-16).

#### Code Implementation

Read-only membership inventory using **GET /v0/roles** and paginated **GET /v0/people**. It emits `REVIEW`, never a permission-compliance verdict. Keep the complete pack tree: the shell wrapper calls `common.py`. Inject `ASSEMBLED_API_KEY` from a secret manager; the code does not create a read-only key scope.

{% include pack-code.html vendor="assembled" section="1.2" %}

#### Validation & Testing

1. Test required tasks and a denied administrative task with a non-admin account.
2. Compare API membership counts with the console. Inspect role permissions manually: the roles endpoint returns ID, name and description, not effective permissions.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Test with the affected team before rollout. Record the prior setting and restore it through the same documented path if the change blocks approved work.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

### 1.3 Provision and Deprovision Through SCIM

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-2 |

#### Description

Use supported IdP provisioning and verify actual Assembled deactivation. SCIM goes through WorkOS Directory Sync; there is no documented direct Assembled SCIM endpoint to configure by guessing a URL.

#### Rationale

**Why This Matters:**

- IdP suspension alone may not deprovision Assembled.
- SCIM synchronizes sign-in accounts and roles, not sites, teams, queues or schedules.

**Attack Prevented:** Orphaned workforce accounts and stale role assignments.

#### Prerequisites

Admin role, support-enabled SCIM, IdP administrator and a non-production test identity.

#### ClickOps Implementation

1. Have support enable SCIM, then open **Configure > SCIM provisioning > Enable SCIM provisioning**.
2. Select **Set up integration**, complete the WorkOS Admin Portal flow, and assign a test user in the IdP.
3. Ask support to map IdP groups to Assembled roles. Unmapped new users get Basic; existing users retain their role.
4. Deprovision a test user in the IdP and inspect the **Directory sync (SCIM)** status. Do not substitute suspension for removal or deprovisioning.

Source: [SCIM provisioning](https://support.assembled.com/hc/en-us/articles/45775797385613-SCIM-provisioning) (checked 2026-11-16).

#### Code Implementation

Read-only comparison with a private file containing one departed email address per line. The pack queries **GET /v0/people?include_deleted=true**, reports matching IDs without printing email addresses, and explicitly leaves login-state assessment to the console. Pass the file path as the single argument.

{% include pack-code.html vendor="assembled" section="1.3" %}

#### Validation & Testing

1. Wait for the documented asynchronous sync, inspect errors and confirm the person is inactive in People management. Verify sign-in denial.
2. Use the directory pack as supporting evidence only. Its `deleted` flag means soft-deletion, not deactivation. A missing record does not prove session revocation.
3. Test a returning user: SCIM may create a new account rather than restore the old one; coordinate restoration before reassignment if history must be preserved.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Test with the affected team before rollout. Record the prior setting and restore it through the same documented path if the change blocks approved work.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

## 2. Network Access Controls

A native tenant login/API IP allowlist and configurable session lifetime were not verified in the public setup documentation. Treat them as research gaps, not available switches or proven absences. Enforce applicable workforce sign-in conditions in the IdP. For supported outbound MCP/Snowflake connector egress restrictions, follow [AI control 3.2](/guides/assembled-ai/#32-restrict-connector-egress-at-the-destination); those addresses do not establish an inbound Assembled login perimeter.

## 3. OAuth & Integration Security

### 3.1 Restrict API Key Administration

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Limit API-key creation and custody to approved integration owners. The API uses HTTP Basic authentication with the key as username and an empty password; bearer authentication is not supported.

#### Rationale

**Why This Matters:**

- Keys can be used independently of an interactive SSO session.
- A key shared between integrations makes attribution and revocation harder.

**Attack Prevented:** Unauthorized API access with an unmanaged integration credential.

#### Prerequisites

An Assembled administrator; test accounts with the affected roles.

#### ClickOps Implementation

1. Use **Manage team > Roles and permissions** to restrict **Assembled API keys** administration to approved owners.
2. Open **Configure > Assembled API** and review the keys your company uses. When an approved integration needs a key, select **Create API key**, enter a purpose-specific name and optional description, then **Create key**.
3. Copy the one-time key directly into approved secret storage and document its owner and consumer. Do not place it in browser code, source control or tickets.

Source: [Custom integrations](https://support.assembled.com/hc/en-us/articles/47949671516813-Custom-integrations) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([Custom integrations](https://support.assembled.com/hc/en-us/articles/47949671516813-Custom-integrations), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Use an unprivileged test role to verify key creation is unavailable.
2. Confirm the owner can account for every key. A successful GET request proves connectivity, not that the credential has a restricted read-only scope.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Test with the affected team before rollout. Record the prior setting and restore it through the same documented path if the change blocks approved work.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

The public API reference does not document key-scoping, expiry or a key-management REST endpoint. The packs send GET requests, but that does not reduce the underlying credential privileges.

### 3.2 Limit Connected Integrations and Their Privileges

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-3 |

#### Description

Approve each outbound connection, its owner, accessed data and required external permissions. Remove unused integrations and restrict who can reconnect them.

#### Rationale

**Why This Matters:**

- Assembled uses the connecting account’s permissions in the other platform.
- A compromised stored integration credential can reach outside Assembled.

**Attack Prevented:** Supply-chain access through broad or abandoned integrations.

#### Prerequisites

An Assembled administrator; test accounts with the affected roles.

#### ClickOps Implementation

1. Open **Configure > Third-party integrations > Connected** and reconcile cards with the approved integration register.
2. Review the linked platform-specific setup guide before reducing privileges. Use a dedicated integration identity where that guide supports one.
3. For an unused connection, open its **Edit integration** menu and choose **Disable integration**, then confirm **Disable**. Remove the unused authorization in the source system too.
4. Review AI tools separately under **Configure > Tools and connectors**; the third-party integration list alone does not inventory them.

Source: [Third-party integrations](https://support.assembled.com/hc/en-us/articles/4414692932109-Third-party-integrations) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([Third-party integrations](https://support.assembled.com/hc/en-us/articles/4414692932109-Third-party-integrations), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Verify required syncs continue with approved source-system permissions.
2. Check a removed integration no longer performs new reads or writes in destination logs. Disabling sync retains data already stored in Assembled.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Disabling stops current and future syncs. Agent-state gaps cannot be backfilled for the disabled interval. Schedule required reconnections and coordinate source-system access changes with the integration owner.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

### 3.3 Gate Access to the Assembled MCP Server

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Restrict external AI assistants’ access to Assembled WFM data. MCP access can read all company data available through MCP regardless of other role data restrictions; read/write permission additionally enables operational changes.

#### Rationale

**Why This Matters:**

- A restricted report role does not imply restricted MCP access.
- External AI clients can combine workforce data with other connected systems.

**Attack Prevented:** Data exfiltration or unauthorized operational changes through an external AI assistant.

#### Prerequisites

Pro or Enterprise, role administrator and organization-approved external AI client.

#### ClickOps Implementation

1. Open **Manage team > Roles and permissions** and inspect **Assembled MCP** for each role.
2. Grant **Can access all data via the MCP** only to approved users and clients. Grant **Can access and make changes to all data via MCP** only for an approved write use case. Deny unneeded access.
3. Require an approved AI client and review its tool approvals and data handling before connecting to the server using the documented OAuth flow.

Source: [Assembled MCP server](https://support.assembled.com/hc/en-us/articles/45407559982221-Assembled-MCP-server) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([Assembled MCP server](https://support.assembled.com/hc/en-us/articles/45407559982221-Assembled-MCP-server), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Check an unapproved role cannot establish usable MCP access.
2. For an approved read role, confirm the access review acknowledges company-wide MCP visibility and the two write tools remain unavailable. Do not execute a write tool merely to test it.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Test with the affected team before rollout. Record the prior setting and restore it through the same documented path if the change blocks approved work.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

The Assembled MCP server is the inbound WFM integration. It is distinct from outbound AI-agent MCP connectors. Documented write tools include `create_forecast_adjustments` and `create_overtime_and_vto`; ordinary client approval prompts are not a replacement for server-side permission control.

## 4. Data Security

Configure WFM report/export boundaries in the [WFM guide](/guides/assembled-wfm/) and AI knowledge, verified identity, redaction and retention in the [AI guide](/guides/assembled-ai/). Assembled's statements about encryption or training practices are vendor assurances; they are not customer-configurable toggles demonstrated by this guide.

## 5. Monitoring & Detection

### 5.1 Review Integration Health and External Access Evidence

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AU-6 |

#### Description

Inspect integration sync status and retain destination-system access evidence. A healthy sync status reports connectivity; it does not prove that the integration has only approved privileges or that credentials were never abused.

#### Rationale

**Why This Matters:**

- Broken or unexpected sync behavior can reveal a changed integration identity.
- The destination platform holds important evidence of reads and writes made with its credentials.

**Attack Prevented:** Undetected connector drift and unauthorized use of integration credentials.

#### Prerequisites

An Assembled administrator; test accounts with the affected roles.

#### ClickOps Implementation

1. Go to **Configure > Third-party integrations > Connected** and inspect each integration’s sync rows. Hover over an error to read its message.
2. Investigate unexpected access errors with the owner before reconnecting. Compare the connecting account and approved changes with the external system’s logs.
3. Use the incident notice’s support route to request account-specific indicators or logs when relevant; retain evidence privately and follow the current notice for recovery.

Source: [Third-party integrations](https://support.assembled.com/hc/en-us/articles/4414692932109-Third-party-integrations) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([Third-party integrations](https://support.assembled.com/hc/en-us/articles/4414692932109-Third-party-integrations), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Confirm the review records owner, status, time window and external evidence source.
2. Do not call a green row a security pass. The public REST reference does not document a tenant-wide authentication/admin audit stream.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Test with the affected team before rollout. Record the prior setting and restore it through the same documented path if the change blocks approved work.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

## 6. Third-Party Integration Security

| Connection | Exposure to review | Recommended boundary |
|------------|--------------------|----------------------|
| Zendesk / Salesforce / other contact platforms | Connecting identity's privileges and imported customer/agent data | Control 3.2 and that connector's first-party setup guide |
| Google Drive knowledge | Files made available to AI products | AI knowledge control 2.1 and a dedicated approved source folder |
| AI tools, API domains and MCP connectors | Stored credentials and downstream read/write operations | AI controls 3.1–3.3 |
| Assembled MCP server | Broad WFM data access from an external AI client | Control 3.3; do not inherit site restrictions by assumption |

The November 2026 incident demonstrates the relevance of outbound-credential blast radius. This is not an Assembled recovery runbook: follow the current vendor notice and your incident process, and use [howtorotate.com](https://howtorotate.com) for rotation procedures. Never assume disconnecting an integration deletes its historical data.

## 7. Compliance Quick Reference

These are implementation evidence mappings, not a product certification or an assertion of compliance. No Assembled-specific CIS Benchmark, DISA STIG, SCuBA, NSA, or ACSC baseline was found in the bounded searches recorded in the ledger; benchmark coverage remains unverified. SOC 2 and ISO mappings above are thematic, without invented numbered requirements.

| NIST SP 800-53 Rev. 5 area | Evidence in this guide |
|--------------------------|------------------------|
| AC-2, AC-3, AC-6 | Approved identities, roles, data access and integration privileges where applicable |
| IA-2, AC-12 | Authentication and session controls where applicable |
| AU-6, CM-3, SI-12 | Audit review, change control and retention where applicable |

## Appendix A: Edition and Feature Compatibility

| Capability | Documented availability |
|------------|-------------------------|
| Custom roles; inbound Assembled MCP | Pro or Enterprise |
| SCIM | Support-enabled; Admin setup; public plan entitlement not specified |
| SAML enforcement | Support-assisted; confirm commercial entitlement |
| AI agents / Copilot / BPO management | Separately billed features; see product guides |


## Appendix B: References

- [SAML single sign-on](https://support.assembled.com/hc/en-us/articles/14654026012173-SAML-single-sign-on)
- [SCIM provisioning](https://support.assembled.com/hc/en-us/articles/45775797385613-SCIM-provisioning)
- [Roles and permissions](https://support.assembled.com/hc/en-us/articles/4414692774285-Roles-and-permissions)
- [Assembled MCP server](https://support.assembled.com/hc/en-us/articles/45407559982221-Assembled-MCP-server)
- [November 13, 2026 security incident](https://support.assembled.com/hc/en-us/articles/50413354064909-November-13-2026-security-incident)
- [Assembled API](https://docs.assembled.com/)

- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)
- [Research boundary and validation results](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/assembled-source-coverage.md)

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-16 | 0.1.0 | ai-drafted | Initial shared identity and integration controls; read-only directory packs; current incident and automation limits | Codex (GPT-6) |

## Contributing

Report outdated paths or product behavior through [GitHub issues](https://github.com/grcengineering/how-to-harden/issues). Propose corrections using the [contribution guidelines](https://github.com/grcengineering/how-to-harden/blob/main/CONTRIBUTING.md). Do not attach credentials or customer data to a public issue.
