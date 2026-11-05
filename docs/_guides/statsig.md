---
layout: guide
title: "Statsig Hardening Guide"
vendor: "Statsig"
slug: "statsig"
platform: "OpenAI"
platform_slug: "openai"
product: "Statsig"
tier: "4"
category: "DevOps"
description: "Identity, SDK credentials, configuration reviews, analytics privacy, MCP and integration boundaries for Statsig Cloud and Warehouse Native"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-05"
---

## Overview

Statsig controls application feature gates, dynamic configuration and experiments, and collects associated analytics. A compromised project writer can change production behavior; a misplaced server key, replay plugin or warehouse integration can expose sensitive data. This guide covers the Statsig organization, project, SDK, Console API, MCP, CLI and Terraform planes, including Cloud and Warehouse Native differences.

Statsig belongs in the OpenAI family: current first-party material describes its post-acquisition organization. Its console, keys, subscriptions and project policies remain separate. The [OpenAI common controls](/guides/chatgpt-enterprise/) do not configure Statsig. The original acquisition announcement was conditional; it does not establish a closing date. ([Current ownership evidence](https://openai.com/careers/engineering-manager-core-experimentation-seattle/), [announcement](https://openai.com/index/vijaye-raji-to-become-cto-of-applications-with-acquisition-of-statsig/))

### Intended Audience

Project owners, identity and application administrators, security engineers and data-platform owners.

### How to Use This Guide

**L1 (Crawl)** establishes the basic boundary; **L2 (Walk)** adds controls for sensitive environments. Framework mappings describe intent rather than product certification. Review the code-pack execution and recovery notes before use.

### Scope

Enterprise is required for several identity, Target App and deletion capabilities; verify your contract. AI Experimentation is documented as Early Access and is not accepting new customers; apply the relevant project and provider boundaries to existing deployments rather than assume general availability. This guide was researched on 2026-11-05 and has not been tested against a live tenant. ([Product index](https://docs.statsig.com/llms.txt))

## Table of Contents

1. [Identity and project access](#1-identity-and-project-access)
2. [SDK credentials and application data](#2-sdk-credentials-and-application-data)
3. [Configuration change safety](#3-configuration-change-safety)
4. [Capture and integration boundaries](#4-capture-and-integration-boundaries)
5. [Evidence and data lifecycle](#5-evidence-and-data-lifecycle)

---

## 1. Identity and project access

### 1.1 Enforce OIDC SSO and Protect Owner Recovery

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.3, 6.5 |
| NIST 800-53 | IA-2, AC-2 |

#### Description

Use Enterprise organization OIDC SSO with IdP MFA and enforce Strict SSO on each project that requires it. Protect the exceptional Owner recovery path separately.

#### Rationale

**Why This Matters:** A configured identity connection does not enforce project sign-in. The Owner remains exempt from Strict SSO and can use the documented password-only recovery path.

**Attack Prevented:** Password-only member access and takeover of the recovery identity.

#### ClickOps Implementation

1. As an organization Owner or Admin, open the organization’s **Info Settings** page and select **Enable** for **Single Sign-on** to configure the approved OIDC connection. Require MFA and relevant sign-in conditions at the IdP.
2. Enable **Strict SSO** for each intended project. Record the Owner exception and protect that account's password and recovery channels with controlled access.
3. Review the automatic Member provisioning and project-join behavior before rollout. Test sign-in with a non-Owner and maintain a separately controlled recovery procedure.

#### Validation & Testing

In an approved test window, verify a non-Owner cannot use local sign-in for a Strict SSO project. Confirm Owner recovery still works without distributing its credentials. Organization SSO alone is insufficient evidence.

**Operational impact:** Incorrect issuer or IdP policy can lock members out; stage enforcement and retain Owner recovery.

**Sources:** [SSO setup and exceptions](https://docs.statsig.com/access-management/sso/overview).

---

### 1.2 Close Projects and Restrict Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 5.1, 6.8 |
| NIST 800-53 | AC-3, AC-6 |

#### Description

Close projects to domain-wide joining and grant only reviewed roles. Treat user roles, custom per-type creation permissions and shared Console key authority as different boundaries.

#### Rationale

**Why This Matters:** Moving a project into an organization makes it OPEN by default. A shared project Console key acts as Admin, even when the human user has a restricted role. API role updates can reset granular creation restrictions.

**Attack Prevented:** Unintended project membership and unauthorized configuration changes.

#### ClickOps Implementation

1. Open **Project settings > Basic settings > Edit project settings**. Disable **Anyone who signs up with the same email domain can join** where automatic joining is unnecessary; inspect its default role otherwise.
2. Under **Project settings > Members & Invites**, reconcile members, outstanding invitations, Admins and the Owner. Use Read Only for observers; transfer ownership deliberately.
3. On enabled Enterprise custom roles, inspect Create/Edit permissions for each configuration type and the all-or-nothing Delete capability. Re-enabling Create can select all types. Do not use a flat role API or Terraform update to preserve granular creation restrictions: the documented Console API cannot manage them and resets them when updating a role.

#### Code Implementation

{% include pack-code.html vendor="statsig" section="1.2" %}

The REST pack reads project visibility. Terraform defaults to managing no resources; an explicit reviewed project object closes the key-scoped existing project while preserving its name and nonempty default unit type. Provider 2.2.1 has no import implementation for this resource; do not invent an import workflow or apply it to a project with a null default unit type.

#### Validation & Testing

Use a nonmember test account and a restricted test role to verify joining and creation behavior. Compare the complete permission matrix after any role API update. Visibility and Terraform plans do not prove membership or granular authorization.

**Operational impact:** Closing a project blocks automatic onboarding. Review existing memberships separately.

**Sources:** [Projects and custom roles](https://docs.statsig.com/access-management/projects), [organization project migration](https://docs.statsig.com/access-management/organizations), [pinned provider resource](https://github.com/statsig-io/terraform-provider-statsig/blob/v2.2.1/docs/resources/settings_project.md).

---

### 1.3 Reconcile SCIM Groups and Deprovisioning

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 5.3, 6.2 |
| NIST 800-53 | AC-2 |

#### Description

Use Enterprise organization SCIM to manage membership and role assignment, and verify removal across identity, groups and credentials.

#### Rationale

**Why This Matters:** SSO authenticates users but does not perform the same lifecycle work as SCIM. Stale group aliases can retain the wrong project/role mapping.

**Attack Prevented:** Orphaned access and unintended role inheritance.

#### ClickOps Implementation

1. Open **Settings > Organization > Organization Info > Access Management** and configure the approved SCIM IdP using a protected SCIM key. Restrict its administration and record its lifecycle owner.
2. Reconcile each IdP group or alias to the intended project and role. For changed alias targets, follow the documented delete/re-add procedure and perform a full IdP sync; an existing alias is not automatically remapped.
3. Test IdP unassignment and inspect the deactivated Statsig user and removed roles. Review team membership and remaining project/service credentials separately; project-level deletion is unsupported by the documented SCIM behavior.

#### Validation & Testing

Use a disposable member assigned through the actual group mapping. Verify access disappears after IdP unassignment and synchronization, then reconcile direct grants and Console credentials.

**Sources:** [SCIM overview](https://docs.statsig.com/access-management/scim/overview), [SCIM groups and aliases](https://docs.statsig.com/access-management/scim/concepts), [access-management distinction](https://docs.statsig.com/access-management/introduction).

---

## 2. SDK credentials and application data

### 2.1 Separate and Scope SDK and Console Keys

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.3, 6.8 |
| NIST 800-53 | IA-5, AC-6 |

#### Description

Use client keys only in public clients; protect server and Console keys. Limit environments, Target Apps and personal-key privileges to their actual purpose.

#### Rationale

**Why This Matters:** Server keys expose configuration definitions, while Console keys can manage project resources. Optional client download-config-spec permissions expose more targeting information than pre-evaluated values.

**Attack Prevented:** Configuration disclosure and credential-based production changes.

#### ClickOps Implementation

1. Open **Project settings > Keys & Environments** and inventory each key's type, status, scopes, environments, owner and use. Remove unused credentials through a staged rotation; never place privileged keys in browser bundles.
2. On Enterprise **Target Applications**, assign only needed entities and bind the intended SDK keys. Explicitly tag referenced dependencies: Target App scope does not propagate and an omitted gate can evaluate false.
3. For bootstrapping, review the server key's union of required applications and filter the returned payload using the intended client key. Review personal Console key creation policy and user-role inheritance separately from shared Admin-equivalent project keys.

#### Code Implementation

{% include pack-code.html vendor="statsig" section="2.1" %}

The read-only collector follows bounded pagination and replaces returned raw key values with SHA-256 fingerprints. Fingerprints are evidence identifiers, not permission enforcement. Reconcile personal/organization credentials and masked values in the console.

#### Validation & Testing

Inspect a built client bundle and intercepted SDK response in a safe test environment. Confirm no server/Console key or unexpected configuration definitions are exposed. Test dependency evaluation before rotating production keys.

**Sources:** [Key classes and permissions](https://docs.statsig.com/access-management/api-keys), [Target Apps and bootstrap dependencies](https://docs.statsig.com/sdks/target-apps), [key-list response contract](https://docs.statsig.com/api-reference/keys/list-keys).

---

### 2.2 Keep Sensitive Targeting Data out of Logs

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.1, 3.3 |
| NIST 800-53 | PT-3, SI-12 |

#### Description

Minimize the user object, event metadata and local SDK state. Use private attributes for supported targeting fields that must not be logged, with an explicit decision about remote evaluation.

#### Rationale

**Why This Matters:** Private attributes are stripped from event logs but browser initialization still sends them for evaluation. A duplicate top-level/custom field is logged despite a private copy. A pseudonymous ID remains an identifier.

**Attack Prevented:** Sensitive telemetry disclosure and residual browser-state exposure.

#### ClickOps Implementation

**Configuration-only control:** these are application SDK options and user parameters, not a project-console privacy switch.

1. In the reviewed SDK initialization and user-building code, remove unnecessary fields and duplicate public copies. Prefer local server evaluation/bootstrap when sensitive targeting values must remain on your server.
2. When consent is required, gate SDK/plugin initialization and exposure/manual event generation through the application's consent process. In JavaScript SDK 3.33.7, **loggingEnabled: disabled** and **disableStorage: true** alone are insufficient: disabled events can buffer in memory and replay when logging resumes. These options do not block all evaluation traffic or remove existing localStorage. Review stable-ID/cookie options separately.
3. Test offline/fallback behavior before deployment: localStorage normally contains evaluations and unsent events. Do not use client-side feature flags as an authorization boundary.

#### Code Implementation

{% include pack-code.html vendor="statsig" section="2.2" %}

The generator emits a native StatsigUser parameter object from a deliberately limited input subset. It does not anonymize the user ID, initialize an SDK, enforce consent or delete existing data.

#### Validation & Testing

Use synthetic attributes and inspect initialization, event payloads and localStorage before/after consent and logout. Confirm sensitive values are absent from events and that the chosen evaluation path meets the data boundary.

**Sources:** [Private-attribute semantics](https://docs.statsig.com/guides/private-attributes), [JavaScript SDK options and local state](https://docs.statsig.com/client/javascript-sdk).

---

## 3. Configuration change safety

### 3.1 Require Independent Production Reviews

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.8 |
| NIST 800-53 | CM-3, AC-5 |

#### Description

Require independent approval for sensitive configuration changes, including relevant nonproduction environments and designated reviewer groups.

#### Rationale

**Why This Matters:** Production-only review defaults and configurable self-approval or role bypass leave alternate paths to changing behavior. An approved review is not necessarily a committed change.

**Attack Prevented:** Unreviewed releases and self-approved configuration changes.

#### ClickOps Implementation

1. Open **Project settings > Reviews** and require configuration review. Inspect permitted bypass/self-approval roles and set designated reviewers or teams for sensitive entities.
2. In **Keys & Environments**, edit review settings for every relevant environment; nonproduction environments are exempt by default.
3. Inspect metric and Warehouse Native review flags separately. Preserve existing decisions rather than copying a blanket settings payload that resets them.

#### Code Implementation

{% include pack-code.html vendor="statsig" section="3.1" %}

The REST pack observes flags; it does not assess role or environment bypass. Terraform requires an explicit snapshot of the other flags and the Cloud/Warehouse deployment model before managing settings. It defaults to no resources and does not apply itself.

#### Validation & Testing

In a test project, attempt a self-approved change and an environment-specific change as a restricted user. Inspect the pending review and committed configuration independently.

**Sources:** [Review settings and designated reviewers](https://docs.statsig.com/guides/setting-up-reviews), [configuration workflow](https://docs.statsig.com/guides/fomo), [provider review resource](https://github.com/statsig-io/terraform-provider-statsig/blob/v2.2.1/docs/resources/settings_reviews.md).

---

### 3.2 Authenticate Pre-Commit Validation and Cover Creations

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 16.1 |
| NIST 800-53 | CM-3, SC-8 |

#### Description

Authenticate the native pre-commit webhook and verify both creation and edit coverage, callback identity and recovery behavior.

#### Rationale

**Why This Matters:** Enabling edit validation does not enable creation validation. A successful webhook acknowledgement confirms delivery, not an approved change.

**Attack Prevented:** Forged validation and unvalidated resource creation.

#### ClickOps Implementation

1. In **Settings > Product Configuration > General**, configure the approved HTTPS endpoint and shared **x-statsig-webhook-key**. Verify the required organization feature and project toggles for edits and creations separately; creation validation defaults off.
2. Require secret verification, bounded processing and protected callback credentials in the receiver. Acknowledge delivery within two minutes, then use the documented change_validation callback with the correct review/creation-attempt identifier and verdict.
3. Treat approval semantics separately: edits require a subsequent Commit; approved creations activate automatically. Document UI recovery and tightly control administrator bypass. Do not invent a polling, creation-initiation or recovery API.

#### Validation & Testing

Use approved synthetic changes to test wrong secrets, stale attempt IDs, timeout, rejection and bypass. Ensure a delivery 2xx cannot be interpreted as approval.

**Operational impact:** Failed validation can block releases; establish the documented recovery owner before enabling it. No webhook receiver or credentials are deployed by these packs.

**Sources:** [Pre-commit validation contract and limitations](https://docs.statsig.com/guides/pre-commit-webhooks).

---

### 3.3 Review Config Dependencies and IaC Writers

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 2.1, 4.1 |
| NIST 800-53 | CM-3, CM-8 |

#### Description

Review referenced gates/segments and every writer, including Terraform, Siggy and coding-agent skills, before trusting an entity history or rollback.

#### Rationale

**Why This Matters:** Entity history omits changes inside referenced gates and segments. A privileged automation credential can change the effective outcome through another resource.

**Attack Prevented:** Hidden dependency changes and automation supply-chain misuse.

#### ClickOps Implementation

1. Open an entity's **History** and inspect each referenced gate/segment separately. Preview supported restore actions before applying them; a parent rollback is not a complete dependency rollback.
2. Inventory approved Siggy packages, provider versions, Console credentials and agent skills. Review their source and authority before installation, including global user-level skills. The Statsig skill catalog includes workflows that can create resources.
3. Review Terraform plans and protected state. The pinned provider's project/review Create operations update the existing key-scoped project; Delete is a no-op for those settings and is not a vendor-side rollback. Defaults in this pack manage nothing.

#### Code Implementation

{% include pack-code.html vendor="statsig" section="3.3" %}

The CLI pack runs only an already installed Siggy version read. It does not read credential-bearing config or establish project identity, freshness or effective permissions.

#### Validation & Testing

Compare an effective configuration before/after a controlled dependency change. Trace each writer to an owner and pinned source. Review plans without applying them during assessment.

**Sources:** [History limitations](https://docs.statsig.com/guides/config-history), [Siggy CLI](https://docs.statsig.com/statsigcli/introduction), [agent-skill catalog](https://docs.statsig.com/integrations/agent-skills), [provider implementation](https://github.com/statsig-io/terraform-provider-statsig/tree/v2.2.1/internal/provider).

---

## 4. Capture and integration boundaries

### 4.1 Minimize Replay and Autocapture

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.1, 3.3 |
| NIST 800-53 | PT-3, SI-12 |

#### Description

Enable only approved capture surfaces, audiences and retention. Treat replay privacy, sampling, conditional recording and web analytics as distinct controls.

#### Rationale

**Why This Matters:** Replay's Passwords default masks only password inputs. Default global targeting includes everyone; sampling defaults to 100%. Conditional triggers and forced recording have separate sampling behavior.

**Attack Prevented:** Collection of sensitive screens, form data, URLs and application telemetry.

#### ClickOps Implementation

1. As Project Admin, open **Project settings > Analytics & Session Replay**. Limit replay targeting and retention, choose the required Inputs/Maximum privacy level, and inspect selectors that can unmask content. Console privacy settings can override SDK masking options.
2. Review conditional recording and any forceStartRecording calls: force bypasses sampling while respecting the targeting gate. Verify withdrawal/stop behavior and sensitive routes using synthetic data.
3. Review web-analytics plugins and the combined installation script before deployment. Filter unwanted events and sensitive URL/query/referrer metadata; leave console capture and copied-text capture disabled unless explicitly approved. The current 3.33.7 SDK defaults differ from some prose examples.

#### Code Implementation

{% include pack-code.html vendor="statsig" section="4.1" %}

The version-pinned plugin factory defaults to denying all events; an explicit exact HTTPS page list allows page views only when the actual browser location and native event URL fields agree. Query-derived metadata cannot authorize a page. It does not initialize a client, redact every metadata field, govern manual events, enforce consent or configure Replay. Review actual payloads before enabling it.

#### Validation & Testing

Exercise synthetic sensitive inputs, navigation, copied text, error messages and logout. Inspect recordings and event payloads; check the effective console settings and all enabled plugins rather than source options alone.

**Sources:** [Replay privacy](https://docs.statsig.com/session-replay/privacy), [recording, sampling and retention](https://docs.statsig.com/session-replay/configure), [web analytics](https://docs.statsig.com/webanalytics/overview), [SDK implementation](https://github.com/statsig-io/js-client-monorepo/blob/main/packages/web-analytics/src/AutoCaptureOptions.ts).

---

### 4.2 Restrict MCP Identity and Write Authority

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.8, 15.1 |
| NIST 800-53 | AC-6, IA-5 |

#### Description

Separate public Docs MCP from authenticated project MCP. Use individual identity and read-only authorization unless a reviewed workflow needs writes.

#### Rationale

**Why This Matters:** Project MCP supports discovered operations beyond visible tools. A confirmation object is an API input, not independent human approval, and not every write uses the same confirmation requirement.

**Attack Prevented:** Agent-driven project changes and shared-key privilege expansion.

#### ClickOps Implementation

1. In the supported client's **MCP server settings**, distinguish public documentation access from **https://api.statsig.com/v3/mcp**. For project access, use individual OAuth/personal Console credentials and the minimum role. Review saved client authentication and revoke it during offboarding.
2. For Enterprise Managed Auth, have the organization Admin configure the exact verified issuer and project Tenant ID; this does not provision missing members. Verify the intersection of Statsig permissions, client scopes and IdP resource policy. Use personal_read_only for observation; do not widen scopes merely to clear an authorization error.
3. Inspect the documented tool capabilities, including discovery, api_write and api_destructive. Keep Statsig review/commit controls and explicit human approval for consequential changes; do not treat a tool's confirmation field as that approval.

#### Validation & Testing

With an approved read-only test identity, verify context reports the intended project and that a prohibited write is denied. Audit shared project Console keys separately because they carry Admin authority.

**Sources:** [MCP overview](https://docs.statsig.com/integrations/mcp/overview), [tool contract](https://docs.statsig.com/integrations/mcp/tool-reference), [Enterprise Managed Auth](https://docs.statsig.com/integrations/mcp/enterprise-managed-auth), [client OAuth configuration](https://docs.statsig.com/integrations/mcp/claude-code).

---

### 4.3 Bound Warehouse and Notification Integrations

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.3, 15.1 |
| NIST 800-53 | AC-6, SA-9 |

#### Description

Scope warehouse service access, repository ingestion and notification audiences to the reviewed Statsig use case. Inspect model-provider telemetry separately.

#### Rationale

**Why This Matters:** Warehouse Native still reads small samples and stores aggregate results. Repository integrations process source to build a knowledge graph; Slack can distribute operational details outside the console.

**Attack Prevented:** Excessive delegated data access and unintended integration disclosure.

#### ClickOps Implementation

1. For Warehouse Native's native connection, review the warehouse service identity: read only intended event/metric/exposure data and grant job access where required. Restrict write/delete to an isolated Statsig staging dataset/schema. The precise connection editor varies by warehouse; confirm the applicable setup page before changes.
2. Under **Settings > Integrations > Slack**, review the workspace/channel connection, notification types and Team/Tag/Target App filters. Review personal **My Account > Notifications** separately.
3. Under **Settings > Integrations > Statsig GitHub App**, select only approved repositories. Multiple Statsig projects can share the underlying GitHub organization installation; inspect inherited connections before adding another project. Prefer the documented App migration over legacy PATs, and review source processing and automatically drafted cleanup PRs.
4. For OpenAI/AzureAI instrumentation, minimize feedback, token/timing and application metadata. Inspect your actual wrapper for prompt/response capture. Historical provider examples do not establish safe current credentials, SDKs or retention.

#### Validation & Testing

Review integration permissions in both systems. Use synthetic events and a test repository to confirm recipient/repository boundaries. Verify warehouse staging access cannot write production source tables.

**Sources:** [Warehouse egress and permissions](https://docs.statsig.com/statsig-warehouse-native/analysis-tools/data-privacy), [Slack settings](https://docs.statsig.com/integrations/slack), [GitHub AI connection](https://docs.statsig.com/integrations/github-ai-integration), [model instrumentation example](https://docs.statsig.com/integrations/openai).

---

## 5. Evidence and data lifecycle

### 5.1 Retain Project Audit and Change Evidence

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 8.2, 8.10 |
| NIST 800-53 | AU-2, AU-6 |

#### Description

Review project audit records and entity dependencies, and protect any exported evidence. Validate the source schema before writing SIEM detections.

#### Rationale

**Why This Matters:** Parent entity history cannot explain every effective change. A missing event field or partial export can make a detection silently ineffective.

**Attack Prevented:** Undetected configuration changes and false assurance from incomplete monitoring.

#### ClickOps Implementation

1. Open **Project settings > Audit Logs** and review sensitive membership, credential, role and configuration changes against approved activity. The vendor documents indefinite audit retention; establish your own evidence access and retention requirements.
2. Correlate relevant entities' **History** and dependency changes. Authenticated MCP documents get_audit_logs through its log-read capability; review authorization and output before allowing agents to collect it.
3. Before automation, verify the current export contract, pagination, timestamps and identifiers against an approved tenant. This research did not establish an exact complete audit REST/export schema; no speculative endpoint or Sigma field mapping is supplied.

#### Validation & Testing

Make an approved synthetic change and find the corresponding record and actor. Confirm a test export's completeness and SIEM field mapping before relying on alerts.

**Sources:** [Audit logs and history](https://docs.statsig.com/guides/config-history), [MCP log-read operation](https://docs.statsig.com/integrations/mcp/tool-reference).

---

### 5.2 Verify Retention and Data Deletion Outcomes

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.4, 3.5 |
| NIST 800-53 | SI-12, PT-3 |

#### Description

Assign data-lifecycle owners for replay, SDK events, Warehouse Native artifacts and user-deletion requests. Distinguish a submitted request from completed removal.

#### Rationale

**Why This Matters:** Different surfaces have different retention and cleanup semantics. Enterprise user deletion is asynchronous, limited to user_id and cannot be cancelled after submission.

**Attack Prevented:** Residual personal data and inaccurate deletion attestations.

#### ClickOps Implementation

1. In **Analytics & Session Replay**, lower the documented default 30-day replay retention when appropriate. For Warehouse Native, review SDK diagnostic exposure retention, staging cleanup and retained result sets; use the experiment's three-dot table-deletion action only with explicit approval.
2. For Enterprise user-deletion requests, follow the documented SERVER-key API procedure through the approved privacy process. Deletion is destructive, batched and can take up to 30 days. This guide does not submit a request.
3. Retain the existing request ID and check its status until COMPLETE. Treat UNKNOWN, transport failure and malformed responses as unresolved. Separately verify local SDK/browser data and external integration copies.

#### Code Implementation

{% include pack-code.html vendor="statsig" section="5.2" %}

The only POST performed by this pack is the documented read of an existing request's status. It implements no deletion submission and accepts only PENDING/COMPLETE as recognized evidence, without certifying external copies.

#### Validation & Testing

Use a previously authorized request and reconcile status with the relevant retention and downstream-copy owners. Do not generate real deletion requests merely to test this guide.

**Sources:** [User deletion and status contract](https://docs.statsig.com/compliance/user_data_deletion_requests), [Replay retention](https://docs.statsig.com/session-replay/configure), [Warehouse retention and cleanup](https://docs.statsig.com/statsig-warehouse-native/analysis-tools/data-privacy).

---

## Appendix A: Availability and automation limits

| Surface | Verified boundary | Remaining limit |
|---------|-------------------|-----------------|
| Identity | Enterprise OIDC/Strict SSO and SCIM | Owner exception, plan enablement and tenant paths require rollout validation |
| Project access | Visibility REST read; provider 2.2.1 project setting | Granular per-type creation is not manageable through the documented role API |
| Keys | Paginated Console key metadata | Caller visibility, personal/org keys and masked values need console reconciliation |
| Change reviews | REST flags and provider settings | Role, environment, designated-reviewer and pre-commit behavior remain separate |
| SDK | Private user parameter; actual web analytics 3.33.7 options | Consent, fallback, existing storage, all metadata and Replay require application testing |
| CLI | Official Siggy version read | No CLI setting/credential collector or live configuration proof |
| MCP | Documented project tools and Enterprise Managed Auth | No account connection, token creation or write performed |
| Audit/SIEM | Console and documented MCP log-read capability | Complete REST/export schema and production Sigma mapping unverified |
| Warehouse/integrations | Native trust and configuration boundaries | Warehouse-specific setup and external copies need deployment review |

Framework mappings describe control intent; they do not assert a Statsig-specific CIS Benchmark or certification. The [source-first inventory](/research/statsig-source-coverage/) records verified controls, exclusions, lifecycle limits and unresolved contracts. All supplied execution checks are offline; no live Statsig settings or credentials were created.

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-05 | 0.1.0 | ai-drafted | Initial source-first coverage for organization/project identity, SDK and Console credentials, reviews, capture, MCP, integrations, audit and data lifecycle, with version-pinned code and explicit verification limits. Offline checks only; no live validation. | Codex |
