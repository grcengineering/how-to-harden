---
layout: guide
title: "Assembled AI Agents & Copilot Hardening Guide"
vendor: "Assembled AI Agents & Copilot"
slug: "assembled-ai"
platform: "Assembled"
platform_slug: "assembled"
product: "AI Agents & Copilot"
tier: "2"
category: "Productivity"
description: "Harden Assembled AI knowledge, chat identity and sessions, tools, egress, retention, workflow activation and Copilot actions."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-16"
---

This is a product guide within the [Assembled platform](/guides/assembled/). Apply the hub's shared identity and integration controls first.

## Overview

Assembled AI agents reply to customers through chat, email and voice. Copilot assists support staff and can run configured actions. They share knowledge, role, connector and review settings, so this guide covers their common AI plane while calling out channel-specific behavior. Their tools can reach customer systems independently of workforce sign-in policy.

### Intended Audience

- AI support administrators and workflow owners
- Application engineers embedding chat
- Security and privacy teams reviewing customer-data flows

### How to Use This Guide

L1 (Crawl) sets roles, knowledge, identity and release boundaries. L2 (Walk) adds stricter connector, privacy and evidence controls. Test with synthetic customer records and a sandbox destination before enabling automatic writes.

### Scope

Customer-configurable chat/email/voice, Copilot, knowledge and tool controls. AI agents and Copilot are separately billed add-ons. Some connectors and actions need support enablement. Product labels formerly called Assist are covered through their current AI agents/Copilot documentation; a separate legacy control plane was not verified.

**Validation boundary:** Documentation and offline fixtures only; no tenant or credentials were supplied. Console paths were not walked in a customer account, and API/SDK/SIEM packs were not exercised against a live deployment. See the [source coverage and validation ledger](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/assembled-source-coverage.md) and [maturity definitions](https://github.com/grcengineering/how-to-harden/blob/main/VERSIONS.md#maturity-statuses--the-matrix).

The [November 2026 incident notice](https://support.assembled.com/hc/en-us/articles/50413354064909-November-13-2026-security-incident) includes AI tools/connectors and authenticated-chat JWT keys in its recovery instructions. Check the current notice before resuming an affected integration. This guide does not perform incident recovery or credential rotation.

## Table of Contents

1. [Administrative Access](#1-administrative-access)
2. [Knowledge & Customer Identity](#2-knowledge--customer-identity)
3. [Tool & Integration Security](#3-tool--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Release Controls](#5-monitoring--release-controls)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

## 1. Administrative Access

### 1.1 Separate AI Administration and Review Roles

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Grant distinct permissions to workflow authors, knowledge managers and quality reviewers. Review actual AI permissions rather than relying on broad default role names.

#### Rationale

**Why This Matters:**

- Managers and Team Leads have several AI editing permissions by default.
- Knowledge and tool edits can change what agents disclose or do.

**Attack Prevented:** Unapproved changes to customer-facing AI behavior.

#### Prerequisites

Role administrator, AI add-on, and Pro or Enterprise for custom roles.

#### ClickOps Implementation

1. Go to **Manage team > Roles and permissions > [role]**. On **AI support**, review **Workflows**, channel settings, **Copilot settings** and **Quality review**.
2. On **Configure > AI agent configuration**, restrict **Tools and connectors**, **Knowledge management settings** and **General settings** editing. On **Report**, grant only needed AI reports.
3. Use **Can test and view workflows** for testers and **Review quality for certain agents** for scoped reviewers where appropriate. Save changes and assign the role through People management.

Source: [AI agent permissions](https://support.assembled.com/hc/en-us/articles/43989515767565-AI-agent-permissions) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([AI agent permissions](https://support.assembled.com/hc/en-us/articles/43989515767565-AI-agent-permissions), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Confirm a reviewer can evaluate approved channels but cannot edit connectors or activate workflows.
2. Confirm a workflow test role cannot save production changes. Inspect inherited defaults before granting a custom role.

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

## 2. Knowledge & Customer Identity

### 2.1 Keep Internal Knowledge Out of Customer Agents

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-3 |

#### Description

Review article access levels and every chat/brand override that can expose internal knowledge. Copilot uses both Internal and External articles; its users must be authorized for that information.

#### Rationale

**Why This Matters:**

- An internal article classification is not sufficient when a chat override permits internal sources.
- Publicly synchronized sources can default to External.

**Attack Prevented:** Disclosure of internal operational knowledge in customer replies.

#### Prerequisites

An Assembled administrator; test accounts with the affected roles.

#### ClickOps Implementation

1. Open **Configure > Knowledge** and review **Access level**. For sensitive articles use the row menu **Edit > Access level > Internal > Save**.
2. In **AI support > Chat agent > [agent] > Setup > Knowledge access**, avoid **External and internal knowledge (High risk)** for a public agent. In Brand studio, inspect each brand’s **Access** settings for **Internal and external**.
3. Review any enabled **Content > User segments** knowledge filters. Customers can select their segment; segment labels must not grant confidential access. Review connected Drive folders and newly synced articles before exposing them.

Source: [Knowledge access levels](https://support.assembled.com/hc/en-us/articles/27380002716045-Knowledge-access-levels) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([Knowledge access levels](https://support.assembled.com/hc/en-us/articles/27380002716045-Knowledge-access-levels), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Use synthetic internal-only content to test a public agent and all configured segments; the agent must not retrieve it.
2. Test Copilot separately. Removal of internal source links from a drafted reply does not constitute a guarantee that sensitive source content cannot influence it.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Test with the affected team before rollout. Record the prior setting and restore it through the same documented path if the change blocks approved work.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

User segments are routing/knowledge selectors, not verified customer authorization. The [segment setup](https://support.assembled.com/hc/en-us/articles/38109895225869-User-segments) documents customer-selected segments. Default source access levels differ; review them after connecting a new source.

### 2.2 Require Signed Chat User Data

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | IA-2 |

#### Description

Create chat identity tokens on your authenticated backend and require verified user data in the widget. Never trust a user ID or account role copied from browser-controlled fields for downstream authorization.

#### Rationale

**Why This Matters:**

- Unsigned user data can be changed by the visitor.
- A verified chat identity still needs server-side authorization for each connected-system action.

**Attack Prevented:** Customer impersonation through tampered chat metadata.

#### Prerequisites

AI agents add-on, Chat agent settings edit permission and application/backend engineers. Do not put the signing secret into client JavaScript or a static page.

#### ClickOps Implementation

1. Go to **AI support > Chat agent > [agent] > Setup > User data authentication**. Use **Manage JWT Secret > Create JWT secret** when configuring approved backend token signing. Store the secret only on the server.
2. Have your backend derive the token’s user identity from its authenticated session, then pass the signed token to the official **authenticateUser** JavaScript API.
3. Select **Only accept user data that has been securely verified through a signed token** and save changes.

Source: [Chat widget installation](https://support.assembled.com/hc/en-us/articles/33739474023693-Chat-widget-installation) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([Chat widget installation](https://support.assembled.com/hc/en-us/articles/33739474023693-Chat-widget-installation), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Test signed data for two synthetic users and verify unsigned user-data updates are ignored.
2. Anonymous visitors can still chat: this switch does not require all visitors to log in. Reject unauthorized destination actions on the server regardless of chat fields.
3. Review browser/page data passed to workflows; page URLs, titles and device details are context, not authentication or proof of customer entitlement.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Test with the affected team before rollout. Record the prior setting and restore it through the same documented path if the change blocks approved work.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

The API key used by the administrative REST packs is not the chat JWT signing secret. There is no documented REST endpoint here for configuring chat identity policy.

### 2.3 Clear Chat Sessions on Logout and Account Switch

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-12 |

#### Description

End the current chat session before showing the widget to a different user on the same browser. Removing the widget without clearing its session can retain earlier conversations.

#### Rationale

**Why This Matters:**

- Shared browsers and account switching create a cross-user disclosure path.
- A blocked session-clear request can preserve the old session even when the widget disappears.

**Attack Prevented:** Disclosure of the previous customer’s chat on account switch.

#### Prerequisites

Application engineers; installed official chat widget; control over logout flow and CSP.

#### ClickOps Implementation

1. Open **AI support > Chat agent > [agent] > Setup** to confirm the widget installation used by your application.
2. Have application engineers call and await **teardown** with **clearSession: true** in the logout/account-switch flow before any new initialization.
3. Ensure the page’s Content Security Policy **connect-src** permits **https://cal.assembledhq.com**. Reinitialize only after the clear flow and authenticate the next user with a backend-issued JWT.

Source: [Chat widget advanced setup](https://support.assembled.com/hc/en-us/articles/33739515754637-Chat-widget-advanced-setup) (checked 2026-11-16).

#### Code Implementation

This integration function uses the documented official **window.assembled** browser JavaScript API. Import it into the application and await `clearAssembledChatSession()` in its serialized logout flow. It changes the browser’s live chat session; it is not an administrative audit or an executable Node CLI. It deliberately does not auto-initialize or authenticate the next user.

{% include pack-code.html vendor="assembled-ai" section="2.3" %}

#### Validation & Testing

1. Test account A → logout → anonymous visitor → account B in one browser. Neither new session may show A’s conversation.
2. Verify the session-clear request reaches the service. The documented teardown promise resolves within two seconds even on failure; promise completion alone is insufficient evidence.
3. Test the application’s actual serialized logout flow, full-page navigation, CSP blocking and multiple rapid switches.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Test with the affected team before rollout. Record the prior setting and restore it through the same documented path if the change blocks approved work.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-12; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

## 3. Tool & Integration Security

### 3.1 Constrain Connector Credentials and Read/Write Tools

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Restrict every AI connector to approved data and operations. Require authentication, mark mutating tools as Write and check permissions in the system that actually executes the operation.

#### Rationale

**Why This Matters:**

- Connector credentials can have more access than the customer or support agent.
- A missing or incorrect tool type can allow a test to perform real writes.

**Attack Prevented:** Unauthorized tool actions and data access through an overpowered agent connector.

#### Prerequisites

AI agents add-on, support-enabled MCP if used, Tools and connectors editing permission, and destination service owner.

#### ClickOps Implementation

1. Open **Configure > Tools and connectors**. For MCP connectors, select the appropriate authenticated method rather than leaving **None** for protected data. Review server instructions and the synced tool list.
2. Set **Tool type > Write** on every mutating MCP tool. For API endpoints choose **Type > Write**, and set their workflow step to **Action (Write)**. Labels must match the actual endpoint behavior.
3. Use dedicated least-privilege destination credentials. Review the **Domain URL**, path, HTTP method, headers and response fields for every API domain/endpoint. Limit returned customer data and enforce resource authorization in your service.
4. After connector re-sync, review new/changed tools and their types before using them in workflows.

Source: [MCP connectors](https://support.assembled.com/hc/en-us/articles/42078579457549-MCP-connectors); [Custom API endpoints](https://support.assembled.com/hc/en-us/articles/36300687233677-Custom-API-endpoints) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([MCP connectors](https://support.assembled.com/hc/en-us/articles/42078579457549-MCP-connectors); [Custom API endpoints](https://support.assembled.com/hc/en-us/articles/36300687233677-Custom-API-endpoints), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Test with sandbox records. MCP **Test tool** and API **Preview endpoint** send real requests, even when a workflow test would suppress a Write action.
2. Check your server rejects unauthorized cross-customer IDs and disallowed writes. Workflow safety labels do not enforce destination permissions.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Incorrect credential restrictions can stop customer workflows. Keep a reviewed connector inventory and a controlled sandbox. Do not misclassify a mutating endpoint as a lookup merely to make it run during tests.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

### 3.2 Restrict Connector Egress at the Destination

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | SC-7 |

#### Description

Use the documented static egress option for MCP and Snowflake database connectors when the destination can enforce source-IP restrictions. Pair it with authenticated, least-privilege credentials.

#### Rationale

**Why This Matters:**

- A destination allowlist can limit where a stolen integration credential is usable.
- Static egress addresses are not a substitute for application authorization.

**Attack Prevented:** Reuse of an integration credential from an unapproved network origin.

#### Prerequisites

Tools and connectors edit permission plus an Admin, Manager or Team Lead base role for a custom role; destination network-policy owner.

#### ClickOps Implementation

1. Go to **Configure > Tools and connectors > More actions > Static egress IPs**.
2. Turn on **Use static egress IPs** and copy the addresses actually shown for your company into the destination’s approved allowlist change.
3. Coordinate the destination policy with its owner and test an approved request before tightening the policy.

Source: [MCP connectors](https://support.assembled.com/hc/en-us/articles/42078579457549-MCP-connectors) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([MCP connectors](https://support.assembled.com/hc/en-us/articles/42078579457549-MCP-connectors), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Confirm legitimate MCP/Snowflake requests still succeed and a controlled request from another origin is denied by the destination.
2. Record the tenant-displayed addresses and verification date privately. No static IP literals were verified for publication, and this setting is not documented as covering all REST integrations or every database type.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

The switch applies company-wide to MCP and Snowflake database connectors. A mismatched destination allowlist can interrupt several workflows. Arrange an independent recovery path before destination enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | SC-7; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

### 3.3 Scope Copilot Custom Actions

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Limit which actions are visible on tickets and reserve action configuration for approved owners. Visibility filters narrow exposure, while destination services must enforce the operation’s authorization.

#### Rationale

**Why This Matters:**

- A support user can execute a configured operation with the connector’s credentials.
- Wide ticket eligibility can expose sensitive actions to unrelated cases.

**Attack Prevented:** Unapproved downstream changes through broadly available support actions.

#### Prerequisites

Copilot add-on, support-enabled custom actions, approved connector, and appropriate Copilot settings permission.

#### ClickOps Implementation

1. In **AI support > Copilot > Custom actions**, review each action’s **Connected tools** and its purpose.
2. Use the documented selection filters for groups, tags or assignees so the action is shown only where approved. Remove obsolete actions using their delete icon and select **Save changes**.
3. In role settings, separate **Copilot access**, **Copilot settings** and **Tools and connectors** permissions.

Source: [Custom actions in Copilot](https://support.assembled.com/hc/en-us/articles/42747029750669-Custom-actions-in-Copilot) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([Custom actions in Copilot](https://support.assembled.com/hc/en-us/articles/42747029750669-Custom-actions-in-Copilot), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Use a synthetic ticket outside the approved filter and verify the action is absent.
2. In a sandbox, confirm a permitted ticket can run only the intended operation and the destination rejects unauthorized resources. A filter match is not identity verification.

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

### 3.4 Limit Database Connector Queries

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-3 |

#### Description

Use a dedicated database identity and narrow saved queries. The documented database connectors are Snowflake, Databricks and Redshift; these are downstream query tools, not an Assembled-native SQL administration interface.

#### Rationale

**Why This Matters:**

- A connector can expose warehouse records beyond a customer’s entitlement.
- Query limits reduce returned volume but do not establish row-level authorization.

**Attack Prevented:** Exfiltration of unrelated customer records through an AI lookup.

#### Prerequisites

AI agents add-on, support-enabled database connectors, Tools and connectors edit permission and database owner.

#### ClickOps Implementation

1. Open **Configure > Tools and connectors > Add connector > Database connector** only for an approved use case, using a dedicated read-only service identity with access to required objects only.
2. For Redshift, retain an appropriate SSL mode; do not choose **Disable**. Have the database owner select certificate-verification settings appropriate to the deployment.
3. Review each saved query: explicit columns, a single SELECT/CTE, parameterized customer identifier and only needed **Max rows** and **Timeout**. Keep database-side access controls authoritative.

Source: [Database connectors](https://support.assembled.com/hc/en-us/articles/46918836914957-Database-connectors) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([Database connectors](https://support.assembled.com/hc/en-us/articles/46918836914957-Database-connectors), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Test an authorized synthetic lookup and an unauthorized customer ID. The latter must be denied or return no unauthorized rows.
2. Verify the database identity cannot write or access other schemas. **Test connection** proves connection/authentication, not query permissions or resource isolation.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Test with the affected team before rollout. Record the prior setting and restore it through the same documented path if the change blocks approved work.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

No generic `.sql` pack is supplied: your schema and authorization model are application-specific. The public Assembled API does not document exporting or changing saved database queries.

## 4. Data Security

### 4.1 Enable PII Redaction Where Supported

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AC-3 |

#### Description

Ask Assembled to enable pre-model PII redaction for supported conversation sources when your use case permits it. Confirm the actual source coverage rather than assuming all channels and tool results are redacted.

#### Rationale

**Why This Matters:**

- Customer text can contain sensitive information sent to model providers.
- Detection-based redaction does not guarantee removal of every secret or identifier.

**Attack Prevented:** Unnecessary transmission and storage of identifiable conversation text.

#### Prerequisites

An Assembled administrator; test accounts with the affected roles.

#### ClickOps Implementation

1. Review supported source coverage in **AI data security**: the documented redaction option covers Intercom, Salesforce and Zendesk conversations and is off by default.
2. Ask Assembled support to enable PII redaction for the agreed AI agents/Copilot scope. There is no documented self-service switch for this pre-model feature.
3. Validate personalized workflows and keep sensitive data out of prompts/tool responses by design.

Source: [AI data security](https://support.assembled.com/hc/en-us/articles/21987166296589-AI-data-security) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([AI data security](https://support.assembled.com/hc/en-us/articles/21987166296589-AI-data-security), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. With synthetic PII, confirm stored text is redacted and obtain support confirmation of pre-model handling. Do not use real secrets as test data.
2. Document unsupported channels, data types and tool payloads as gaps. Expect reduced personalization when names, emails and order context are removed.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Redaction reduces personalization and cannot be treated as a lossless reversible transformation. This option differs from delayed cleanup of stored conversations in control 4.2.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

### 4.2 Bound Stored Conversation Retention

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | SI-12 |

#### Description

Configure automatic cleanup of stored AI conversations according to your approved retention need. Delayed cleanup does not prevent initial model processing.

#### Rationale

**Why This Matters:**

- Indefinite conversation retention expands the impact of later unauthorized access.
- Deleting messages and redacting PII have different evidence and business effects.

**Attack Prevented:** Disclosure of unnecessarily retained customer message data.

#### Prerequisites

AI add-on, General settings edit permission, privacy/records approval and a test plan before irreversible cleanup.

#### ClickOps Implementation

1. Go to **Configure > General settings > Data retention settings** and select **Enable automatic data cleanup**.
2. Choose **Redaction type**: **Redact PII** retains redacted conversation text, while **Delete message data** deletes message content and keeps IDs/non-sensitive details.
3. Set **Data retention period** within the documented 7–365 days (default 90) to the shortest approved business/legal period. Select **Update data retention settings** and confirm **Settings updated!**.

Source: [AI data security](https://support.assembled.com/hc/en-us/articles/21987166296589-AI-data-security) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([AI data security](https://support.assembled.com/hc/en-us/articles/21987166296589-AI-data-security), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Verify the saved type and period. After the cleanup period, inspect synthetic old records for the expected behavior.
2. Record which metadata remains. Confirm scope separately for knowledge, connector data, exports and user memories; do not assume this setting deletes those stores.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Redacted or deleted data cannot be recovered. Disabling automatic cleanup stops future cleanup only; it does not restore past data.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | SI-12; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

### 4.3 Disable Unneeded Cross-Conversation Memories

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | SI-12 |

#### Description

Keep user memories disabled unless the organization approves retaining and reusing extracted customer details. Chat memories are linked to a browser-session identifier and can contain account or personal information.

#### Rationale

**Why This Matters:**

- Extracted memories create another data store beyond an individual conversation.
- Browser-based continuity needs explicit shared-device testing.

**Attack Prevented:** Unnecessary persistent customer profiling and cross-session disclosure.

#### Prerequisites

An Assembled administrator; test accounts with the affected roles.

#### ClickOps Implementation

1. For chat, open **AI support > Chat agent > [agent] > Setup > User memories**. Clear **Enable user memories** if not approved and **Save changes**.
2. For voice, inspect **AI support > Voice agent > [agent] > General > User memories** and apply the same decision.
3. If enabled, review **AI quality > Memories** for stored categories and access. Confirm retention/deletion requirements with support rather than assuming conversation cleanup covers them.

Source: [User memories](https://support.assembled.com/hc/en-us/articles/41212723066125-User-memories) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([User memories](https://support.assembled.com/hc/en-us/articles/41212723066125-User-memories), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Verify a disabled agent no longer extracts new memories in synthetic conversations.
2. Check historical memories separately; disabling a feature is not documented as deleting earlier records. Test shared-browser behavior with the session-clear control.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Test with the affected team before rollout. Record the prior setting and restore it through the same documented path if the change blocks approved work.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | SI-12; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

## 5. Monitoring & Release Controls

### 5.1 Test and Gate Automated Workflow Activation

**Profile Level:** L1 (Crawl)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | CM-3 |

#### Description

Keep new or changed workflows inactive until selection and response behavior have been tested. Use Agent review for email before granting unattended actions; chat and voice do not offer that same workflow-review mode.

#### Rationale

**Why This Matters:**

- A workflow selection test does not validate generated replies or real write effects.
- Email knowledge answers have their own activation controls and can run when no workflow matches.

**Attack Prevented:** Automatic execution of an untested or overly broad customer-support workflow.

#### Prerequisites

Workflow edit/test permissions, AI agents add-on and synthetic or appropriately authorized test cases.

#### ClickOps Implementation

1. Open **AI support > Workflows > [workflow] > Test** and test the draft with both expected matches and negative cases. Use single-case tests to review responses and mocked write behavior as well.
2. Select **Manage activation**. Keep each channel **Inactive** until approved; begin email with **Agent review**, then a narrow **Automated** percentage only after review. For chat/voice use their channel-specific controlled rollout and sandbox testing; do not assume email review applies.
3. Inspect **AI support > Email agent > Automated knowledge answers** separately. Keep inactive until reviewed; when first enabling, use **Agent review** or **Quality review**, narrow case filters and gradual activation.
4. Audit installed widget script attributes: a **data-activated** override takes precedence over console activation. Include deployed page code in any shutdown plan.

Source: [Workflow activation](https://support.assembled.com/hc/en-us/articles/35787875078669-Workflow-activation); [Workflow bulk testing](https://support.assembled.com/hc/en-us/articles/38942099792397-Workflow-bulk-testing); [Automated knowledge answers in the email agent](https://support.assembled.com/hc/en-us/articles/43637851710605-Automated-knowledge-answers-in-the-email-agent); [Chat widget advanced setup](https://support.assembled.com/hc/en-us/articles/33739515754637-Chat-widget-advanced-setup) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([Workflow activation](https://support.assembled.com/hc/en-us/articles/35787875078669-Workflow-activation); [Workflow bulk testing](https://support.assembled.com/hc/en-us/articles/38942099792397-Workflow-bulk-testing); [Automated knowledge answers in the email agent](https://support.assembled.com/hc/en-us/articles/43637851710605-Automated-knowledge-answers-in-the-email-agent); [Chat widget advanced setup](https://support.assembled.com/hc/en-us/articles/33739515754637-Chat-widget-advanced-setup), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Include cases that should not be selected, unsafe requests and failing tools. Bulk tests measure selection, not reply quality; errors are excluded from accuracy calculations.
2. Verify disabled channels and unmatched emails do not trigger an unreviewed alternative. Check actual connector test behavior using control 3.1.
3. After each release, compare live samples with expected outcomes and retain a rollback to Inactive for every affected channel and page override.

#### Monitoring & Maintenance

Review quarterly and after changes to the affected role, connector, or product configuration. Keep dated evidence of the expected and denied test cases.

#### Operational Impact

Reducing activation transfers work back to the support team. An activation change is not an adequate emergency stop where deployed widget code overrides it.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | CM-3; evidence for the requirement described above |
| SOC 2 | Logical access / change management relevance; assess against your scoped criteria |
| ISO/IEC 27001:2022 | Access control / information protection relevance; map through your Statement of Applicability |

### 5.2 Review AI Outcomes and Tool Use

**Profile Level:** L2 (Walk)

| Framework | Reference |
|-----------|-----------|
| NIST SP 800-53 Rev. 5 | AU-6 |

#### Description

Review actual AI responses and tool operations using product QA and workflow evidence, supplemented by destination logs. Do not treat a quality score as proof of authorization.

#### Rationale

**Why This Matters:**

- Selection accuracy and response safety are different measurements.
- Tool calls can have downstream effects absent from a summary score.

**Attack Prevented:** Undetected unsafe replies or unexpected connector activity.

#### Prerequisites

AI add-on, scoped Quality review permission and access to destination audit evidence.

#### ClickOps Implementation

1. Go to **AI quality > QA review**, choose the relevant channel or Copilot tab, and inspect sampled cases, replies and sources.
2. Record findings through **QA scoring > Submit evaluation**. For useful Zendesk examples, select **Add test case** and add the expected workflow assignment.
3. For connector-heavy workflows inspect their **Monitor > Top data tools** usage and compare suspicious operations with destination-system logs.

Source: [Quality review](https://support.assembled.com/hc/en-us/articles/21869938807437-Quality-review); [MCP connectors](https://support.assembled.com/hc/en-us/articles/42078579457549-MCP-connectors) (checked 2026-11-16).

**Automation:** Manual or support-assisted — no supported endpoint for this setting was found in the [public REST reference](https://docs.assembled.com/) or its setup documentation ([Quality review](https://support.assembled.com/hc/en-us/articles/21869938807437-Quality-review); [MCP connectors](https://support.assembled.com/hc/en-us/articles/42078579457549-MCP-connectors), 2026-11-16). Private interfaces remain unverified; do not substitute browser-internal endpoints.

#### Validation & Testing

1. Confirm reviewers can see only approved agent types and findings produce a repeatable test or configuration correction.
2. Retain evidence privately. The public REST reference does not document exporting all AI conversation/tool security events as a tenant audit stream.

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
| AI agents; Copilot | Separate add-ons, billed separately |
| Custom roles | Pro or Enterprise |
| MCP / database connectors; Copilot custom actions | Contact support for enablement |
| Static egress | Documented for MCP and Snowflake database connectors |
| PII redaction | Support-assisted; Intercom, Salesforce and Zendesk conversation sources |
| Conversation cleanup | General settings edit permission; 7–365 day period |


## Appendix B: References

- [AI agent permissions](https://support.assembled.com/hc/en-us/articles/43989515767565-AI-agent-permissions)
- [Knowledge access levels](https://support.assembled.com/hc/en-us/articles/27380002716045-Knowledge-access-levels)
- [Chat widget installation](https://support.assembled.com/hc/en-us/articles/33739474023693-Chat-widget-installation)
- [Chat widget advanced setup](https://support.assembled.com/hc/en-us/articles/33739515754637-Chat-widget-advanced-setup)
- [MCP connectors](https://support.assembled.com/hc/en-us/articles/42078579457549-MCP-connectors)
- [Custom API endpoints](https://support.assembled.com/hc/en-us/articles/36300687233677-Custom-API-endpoints)
- [Database connectors](https://support.assembled.com/hc/en-us/articles/46918836914957-Database-connectors)
- [AI data security](https://support.assembled.com/hc/en-us/articles/21987166296589-AI-data-security)
- [User memories](https://support.assembled.com/hc/en-us/articles/41212723066125-User-memories)
- [Workflow activation](https://support.assembled.com/hc/en-us/articles/35787875078669-Workflow-activation)
- [Automated knowledge answers in the email agent](https://support.assembled.com/hc/en-us/articles/43637851710605-Automated-knowledge-answers-in-the-email-agent)

- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)
- [Research boundary and validation results](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/assembled-source-coverage.md)

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-16 | 0.1.0 | ai-drafted | Initial AI agents/Copilot controls, official widget session-reset pack and documented automation boundaries | Codex (GPT-6) |

## Contributing

Report outdated paths or product behavior through [GitHub issues](https://github.com/grcengineering/how-to-harden/issues). Propose corrections using the [contribution guidelines](https://github.com/grcengineering/how-to-harden/blob/main/CONTRIBUTING.md). Do not attach credentials or customer data to a public issue.
