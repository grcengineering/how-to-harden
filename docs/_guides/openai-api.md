---
layout: guide
title: "OpenAI API Platform Hardening Guide"
vendor: "OpenAI API Platform"
slug: "openai-api"
platform: "OpenAI"
platform_slug: "openai"
product: "API Platform"
tier: "1"
category: "AI/ML Platform"
description: "OpenAI API organization and project security: workload identity, native Terraform controls, model and tool permissions, ingress, hosted Agents, data lifecycle, signed webhooks, audit and spend limits."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-05"
---

## Overview

This is a **product guide within the [OpenAI platform](/guides/chatgpt-enterprise/)**. The OpenAI API Platform has its own organization, projects, roles, service accounts, administrative credentials and audit records. ChatGPT workspace permissions and Compliance logs do not configure or audit all API Platform activity. OpenAI's [API documentation index](https://developers.openai.com/api/llms.txt) establishes the product and its administration surface.

The controls cover customer access and integration boundaries across model APIs and the beta Agents API. They include current official [Terraform resources and data sources](https://developers.openai.com/api/docs/guides/terraform), the [OpenAI CLI](https://developers.openai.com/api/docs/libraries/openai-cli), and the official SDK. These are separate surfaces: an Admin API key manages the organization but cannot authorize model requests, while a project workload key cannot administer the organization.

### Intended Audience

- Security and platform engineers administering API organizations and production integrations
- Application owners using hosted Agents, MCP servers and callbacks
- GRC and incident response teams assessing data access, lifecycle and administrative evidence

### How to Use This Guide

- **L1 (Crawl):** Isolate access, own credentials, bound data and verify callbacks.
- **L2 (Walk):** Enforce network, workload identity and tool policies with repeatable assessment.
- **L3 (Run):** Apply eligible contractual retention and regional controls after checking endpoint exceptions.

### Scope

The source-first [coverage ledger](/research/openai-api-source-coverage/) records the feature/index census, provider resource and data-source discovery, interface lifecycle and remaining gaps. Model APIs for text, images, audio, Realtime, Decisions, embeddings, moderation, fine-tuning and evals share project controls but have distinct data-lifecycle exceptions. Agents, Conversations, ChatKit, files and vector stores need explicit application-state review. Merchant checkout, Ads account management, Sign in with ChatGPT and plugin publishing have different integration contracts; their disposition is recorded in the platform research ledger rather than implied to inherit these project settings.

**Validation boundary:** This guide is AI-drafted from public documentation and offline tests. No live tenant, credential, console setting or model execution was used. No product-specific CIS/STIG/SCuBA setting identifiers are asserted; compliance tables map NIST control families, not a product benchmark certification.

## Table of Contents

1. [Identity and Project Access](#1-identity-and-project-access)
2. [Network, Models and Tools](#2-network-models-and-tools)
3. [Data Lifecycle](#3-data-lifecycle)
4. [Hosted Agents and Integrations](#4-hosted-agents-and-integrations)
5. [Delivery, Audit and Resource Limits](#5-delivery-audit-and-resource-limits)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

## 1. Identity and Project Access

### 1.1 Isolate Projects and Minimize Effective Access

**Profile Level:** L1 (Crawl)

#### Description

Separate production, experiments and third-party workloads into API projects, and grant only the required project roles. [RBAC permissions combine across organization, project and group assignments](https://developers.openai.com/api/docs/guides/rbac); a narrow project role cannot cancel an organization-wide grant. Allow up to 30 minutes for changes and group sync to propagate.

#### Rationale

**Why This Matters:**
- Project separation limits which resources a compromised integration can reach.
- Reviewing the union of roles prevents a nominally restricted contractor from retaining broader access.

**Attack Prevented:** Excessive API privileges and development-to-production access through a shared identity.

#### ClickOps Implementation

1. Open **Platform settings → Organization** and review users, groups and assigned roles; keep owner and organization-wide roles limited to their operational need.
2. Select the intended **project**, review its members and project roles, and assign the approved group a least-privilege role. Use separate groups for outside integrations.
3. Compare all direct and group assignments. Test effective API and dashboard access with a non-owner identity after propagation, using disposable resources.

The [Terraform project/access guide](https://developers.openai.com/api/docs/guides/terraform/projects-and-access) documents native role and group resources. The read pack lists direct project members; it is **not** a complete effective-permissions calculation. The CLI example is an inventory and retains its version-dependent pagination limitation.

#### Code Implementation

{% include pack-code.html vendor="openai-api" section="1.1" %}

#### Validation & Testing

Require the approved non-owner to succeed only in the intended project. Check that a second project and an ungranted operation are denied. Retain a reviewed role inventory separately from the project-member export; restore any required access through the approved owner if the test reveals an operational dependency.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | Access enforcement and least privilege — AC-3, AC-6 |

### 1.2 Govern Workload Identities and Key Lifetimes

**Profile Level:** L2 (Walk)

#### Description

Give each production workload a project service account and use [workload identity federation](https://developers.openai.com/api/docs/guides/workload-identity-federation) where supported. Bind issuer, audience and exact workload claims; do not trust an entire external repository organization. For keys that remain necessary, enforce maximum lifetime and allowed creation types in **API Key Governance**. [Creation restrictions leave existing keys unaffected](https://developers.openai.com/api/docs/guides/production-best-practices#api-keys), so inventory them separately.

#### Rationale

**Why This Matters:**
- A workload identity has an independently reviewable owner and lifecycle.
- Short-lived federation reduces standing credentials, while key expiration limits forgotten grants.

**Attack Prevented:** Reuse of shared developer credentials and unauthorized CI workloads assuming a production identity.

#### ClickOps Implementation

1. In **Platform settings**, review organization and project **API Key Governance** and maximum API key lifetime. Organization restrictions take precedence; projects can add restrictions.
2. Under **Organization Settings → Security → Workload Identity Provider**, create a reviewed provider and a service-account mapping for an existing project identity. Configure exact audience and workload attributes. For GitHub Actions, use a protected branch or environment subject, as described in the [GitHub federation guide](https://developers.openai.com/api/docs/guides/workload-identity-federation/github-actions).
3. Assign the minimum role, then inventory existing project keys and revoke grants through your approved retirement workflow. Include `owner_project_access=any` when listing keys: the default visibility rules can omit enabled keys whose owners lost project access. Do not treat a new-creation restriction as revocation. [Key-list contract](https://developers.openai.com/api/reference/resources/admin/subresources/organization/subresources/projects/subresources/api_keys/methods/list)

#### Code Implementation

{% include pack-code.html vendor="openai-api" section="1.2" %}

The official provider's service-account resource creates an identity **without an API key or default role**. The pack assigns a response-only role and a restricted federation rule. It does not exchange a token or issue credentials. The REST pack flags missing/expired key lifetimes without outputting key values. A write handle for the dashboard's maximum lifetime/type policy was not verified in this run; do not substitute the federation resource for that setting.

#### Validation & Testing

Validate the provider schema offline before reviewing an apply. In an authorized environment, confirm an approved subject can obtain the intended access and a different branch/subject cannot. Check every existing key, owner and application dependency before revocation; changing a provider can interrupt CI immediately.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | Authenticator management and least privilege — IA-5, AC-6 |

## 2. Network, Models and Tools

### 2.1 Restrict API Ingress and Test Scope Precedence

**Profile Level:** L2 (Walk)

#### Description

Apply an [IP allowlist](https://developers.openai.com/api/docs/guides/ip-allowlist) to API workloads with stable public egress. It restricts API requests, not Platform login. **An active project list replaces the organization list; entries do not combine.** [Private Link](https://developers.openai.com/api/docs/guides/private-link) is a different route and is not compatible with IP allowlist controls **or mTLS**. Evaluate [mutual TLS](https://developers.openai.com/api/docs/guides/mutual-tls) where the integration requires certificate-bound ingress.

#### Rationale

**Why This Matters:**
- A stolen key is less useful from an unapproved network path.
- Testing project overrides prevents a broad project exception from defeating the intended organization boundary.

**Attack Prevented:** Off-network reuse of stolen integration credentials.

#### Prerequisites

Know the actual post-NAT egress of production, staging, CI and disaster recovery. Keep an independently tested allowed path before changing access. Changes can take up to 15 minutes; up to 50 addresses/CIDRs are supported by the current IP guide.

#### ClickOps Implementation

1. Open **Settings → Security → IP allowlist**. Add the reviewed egress addresses, use **Check**, and pilot a non-critical project.
2. Review every active project override before enabling organization coverage. Retain the recovery path; wait for propagation.
3. For certificate-bound deployments, open **Organization settings → Security → Mutual TLS**. Upload one approved PEM trust anchor per certificate object, optionally constrain client attributes with the documented CEL filter, and activate it for a non-critical project. Upload alone does not enforce mTLS. Use a supported mTLS host, present the complete client chain, and retain the bearer credential. Test replacement certificates before deactivating old trust; OpenAI does not perform CRL/OCSP checks or fetch missing AIA intermediates.
4. For Private Link, request onboarding and exact regional service identifiers from OpenAI, create the approved Azure Private Endpoints and test the documented `/v2/privatelink_healthcheck` before changing private DNS. Check resolution and authenticated requests from the workload network. Plan regional failover explicitly; the service is not self-service and a healthy private endpoint does not establish API authorization or data-residency eligibility.

#### Code Implementation

{% include pack-code.html vendor="openai-api" section="2.1" %}

The pack sends only a model-list read and distinguishes `ip_not_authorized` from authentication failures. It verifies one credential and path; it does not set an allowlist or prove mTLS/Private Link routing. First-party certificate Terraform resources exist, but certificate deployment/activation and private DNS were not exercised here.

#### Validation & Testing

From an approved path, require normal API authorization. From a separately approved negative-test path, require HTTP 401 with `ip_not_authorized`. A generic 401/403 is inconclusive. Verify certificate and private-route behavior separately; restore the tested access configuration if legitimate workloads fail.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | Information flow and boundary protection — AC-4, SC-7 |

### 2.2 Allowlist Models and Hosted Tools

**Profile Level:** L2 (Walk)

#### Description

Use native [project model and hosted-tool controls](https://developers.openai.com/api/docs/guides/terraform/project-controls) to approve the models and tools a workload needs. Set all five hosted-tool permissions explicitly: file search, web search, image generation, MCP and Code Interpreter. A tool disabled at project level requires the organization's tool policy to use selected-project access; a project cannot override an organization policy that enables it for every project.

#### Rationale

**Why This Matters:**
- A response-only integration should not gain remote MCP or code execution simply because a new tool becomes available.
- Explicit allowlists make unintended dashboard changes visible to drift review.

**Attack Prevented:** Unapproved data egress, execution and model use by an over-capable API integration.

#### ClickOps Implementation

1. Review the organization's tool policy in Platform settings and select project-scoped access for tools requiring restrictions.
2. Select the target **project** and review its model and hosted-tool permissions. Approve exact visible model IDs and only required tools.
3. Read back the resulting settings with the assessment in [5.2](#52-export-audit-records-and-read-back-security-policy). The native Terraform path supplies the precise supported fields; do not invent a ChatGPT workspace toggle with equivalent effect.

#### Code Implementation

{% include pack-code.html vendor="openai-api" section="2.2" %}

#### Validation & Testing

Review an imported-state plan before applying. Verify an approved model remains usable and a denied tool fails. Removing the hosted-tool resource from Terraform leaves remote settings unchanged, while removing the model-permissions resource deletes that model configuration; inspect destroy plans and restore the approved remote values deliberately.

A model allowlist constrains available models; it does not grant separate Daybreak or Rosalind approval. See 5.4 for API Daybreak and the [common guide](/guides/chatgpt-enterprise/) for Rosalind's separately approved product/API scope.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | Least functionality and least privilege — CM-7, AC-6 |

## 3. Data Lifecycle

### 3.1 Apply Endpoint-Specific Retention and Residency

**Profile Level:** L3 (Run)

#### Description

Use the [Data controls endpoint matrix](https://developers.openai.com/api/docs/guides/your-data) to approve the exact endpoint, tool, region and retention combination. No-training-by-default is not zero retention. Abuse-monitoring content is ordinarily retained up to 30 days; approved retention programs and their exceptions differ. Agents state, files and vector stores are not automatically erased by a ZDR setting, and third-party MCP retention is governed by that service.

#### Rationale

**Why This Matters:**
- An integration can retain sensitive application state after the model request ends.
- A regional API endpoint does not promise that every hosted tool or connected service shares its residency boundary.

**Attack Prevented:** Sensitive information retained or processed outside an approved integration boundary.

#### ClickOps Implementation

1. For an approved organization, open **Settings → Organization → Data controls → Data Retention** and review the organization policy and project override.
2. Confirm program eligibility and the project's regional configuration before selecting an override. Enrollment and some transitions require OpenAI approval/support.
3. Review the endpoint/tool matrix for Responses background mode, prompt caching, Agents, files, web search and remote MCP. Document exceptions and disable incompatible workflows; avoid a blanket HIPAA, BAA or ZDR claim.

#### Code Implementation

{% include pack-code.html vendor="openai-api" section="3.1" %}

The pack changes an eligible existing setting; it cannot enroll the organization. The read-only Terraform assessment in 5.2 retrieves the project's retention type. Request-level `store: false` is useful for compatible APIs but does not change every endpoint's application-state policy.

[ZDR with Private Safety Processing](https://developers.openai.com/api/docs/guides/private-safety-processing) stores encrypted safety records in customer-controlled cloud storage. Registering storage alone does not activate the policy; successful validation does. It applies to all API traffic in that project, including other models. Separate projects if eligible traffic needs ZDR without PSP. See [5.4](#54-gate-cyber-access-by-project-and-explicit-request) for conditional Cyber-model setup and a saved-status assessment.

#### Validation & Testing

Require a read-back matching the approved mode and an endpoint/region review for every tool used. Investigate unsupported transitions rather than relaxing retention to make a deployment pass. Removing the Terraform resource leaves the remote retention setting in place; an approved rollback must explicitly restore a supported previous value.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | Information management and retention — SI-12 |

### 3.2 Bound Application State and Offboard Every Copy

**Profile Level:** L1 (Crawl)

#### Description

Inventory stored files, vector stores, Conversations/ChatKit state, Agents sessions, traces, model artifacts and external copies. [Files support `expires_after`](https://developers.openai.com/api/docs/guides/your-data#v1files); other objects have different deletion behavior. Stop active work and scheduled agent activity before removing source-service access and retiring API identities. Do not assume deleting a session also destroys files, environment artifacts, vault credentials or copies already delivered to a connected system.

#### Rationale

**Why This Matters:**
- An offboarded user's integration can retain callable credentials and stored customer data.
- Independently retained resources outlive a single response or session.

**Attack Prevented:** Access through orphaned integration identities and retrieval of stale sensitive artifacts.

#### ClickOps Implementation

1. Review stored resources in the relevant project views, and record which application owns each resource and expiration.
2. Use the [Agents session-management workflow](https://developers.openai.com/api/docs/guides/agents-api/sessions/manage) to identify ongoing work and saved sessions. Review automations, environment lifecycle and vault grants as separate resources.
3. Retire affected source-service grants and API keys after confirming dependencies. Delete approved stored objects using their documented resource action; retain required evidence in an access-controlled location.

#### Code Implementation

{% include pack-code.html vendor="openai-api" section="3.2" %}

This read pack inventories **files and vector stores only**. It performs no deletion and is not an all-resource retention attestation. Session, automation, vault, training/eval artifact and downstream-store cleanup requires the relevant owner and documented resource-specific operation.

For PSP, preserve encrypted customer-cloud records for at least 30 days and maintain regional storage and key access. Disconnecting the last storage connection resets the project's retention policy to the organization default; it does not delete the bucket or its records. Review the changed policy and remaining content before offboarding.

#### Validation & Testing

Compare inventories with application owners; verify an expired/retired fixture is no longer retrievable through the intended identity. Check downstream storage independently. Restore accidentally removed application dependencies from an approved source; do not recreate retired grants merely to hide a failure.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | Account lifecycle and retained information — AC-2, SI-12 |

## 4. Hosted Agents and Integrations

### 4.1 Isolate Hosted Agents and Enable Action Review

**Profile Level:** L2 (Walk)

#### Description

For the beta Agents API, use a separate project and environment per trust boundary. Set [automatic review](https://developers.openai.com/api/docs/guides/agents-api/sessions/approvals) explicitly: omitting `review` defaults to `none`, which does not route actions to a manual approval queue. Set the [hosted network policy](https://developers.openai.com/api/docs/guides/agents-api/environments/openai-hosted#control-network-access) explicitly; unrestricted outbound access is the default unless a template supplies restrictions.

#### Rationale

**Why This Matters:**
- Agent-generated code can access credentials, files and reachable services in its environment.
- Review and network policy address different boundaries; neither replaces the other.

**Attack Prevented:** Prompt-injected agent code obtaining broad execution or reaching unauthorized destinations.

#### ClickOps Implementation

The reviewed-session fields are native API configuration; the fetched guide documents the API request rather than an equivalent dashboard enforcement toggle. Configure the supported session request in Code. For self-hosted executors, review [environment keys](https://platform.openai.com/agents?tab=environments&environment_view=keys) and keep the restricted executor key separate from the application's API key, following [Sandbox security](https://developers.openai.com/api/docs/guides/agents-api/environments/security).

#### Code Implementation

{% include pack-code.html vendor="openai-api" section="4.1" %}

Direct execution drafts JSON only. `executeReviewedSession` starts real work only when an application explicitly calls it with its official SDK client. Restricted network lists accept exact hosts, not wildcard URLs; subdomains and redirect destinations need their own entries. Automatic review requires a new hosted environment and is not supported when reusing one via `environment_id`; browser-origin and sign-in handlers remain application responsibilities.

#### Validation & Testing

Offline tests inspect real SDK request serialization. An authorized staging deployment must separately prove denied egress, supported action-review outcomes and sandbox prerequisites. Reusing an existing environment or setting `review: none` is not a safe fallback for a failed check.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | Least privilege and network boundaries — AC-6, SC-7 |

### 4.2 Constrain MCP Tools and Broker Third-Party Secrets

**Profile Level:** L2 (Walk)

#### Description

Approve each [MCP server's connection origin, tool allowlist and identity](https://developers.openai.com/api/docs/guides/agents-api/tools/mcp). Service-origin MCP connects from OpenAI and is outside the hosted sandbox's network policy; environment-origin MCP connects from the executor. A vault-backed credential matches the server URL. [Vault secret brokering](https://developers.openai.com/api/docs/guides/agents-api/tools/vaults) can keep real credentials outside hosted sandbox code; ordinary environment variables remain readable by that code.

#### Rationale

**Why This Matters:**
- Restricting sandbox internet access does not restrict a remote MCP service connection.
- Tool definitions and returned content are untrusted, and a server can exercise the connected account's privileges.

**Attack Prevented:** Credential exposure and malicious tool use across an overlooked remote integration path.

#### ClickOps Implementation

Review the connected service's account/scopes and vault ownership before attaching it. The documented tool and vault controls are API fields; no equivalent GUI path was verified here. Set `allowed_tools` to exact required names, use `required: true` for a mandatory dependency, and provide only the session's approved vault IDs. Separately govern plugin/skill package provenance; a plugin can bundle instructions, executables and MCP configuration.

#### Code Implementation

{% include pack-code.html vendor="openai-api" section="4.2" %}

The native tool builder creates no connection and stores no secret. Review its output before adding it to an approved session. A required server's failed startup should fail the turn; default optional initialization is unsuitable when the dependency is part of your control boundary. Source-service authorization and revocation still govern the data/actions the account can reach.

#### Validation & Testing

Test unavailable mandatory servers and disallowed tools with disposable accounts. Inspect the source service's own audit record for consequential actions. Offboard both the OpenAI session/vault grant and the upstream credential; neither revocation guarantees deletion of data previously returned to the agent.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | Access enforcement and information flow — AC-3, AC-4 |

## 5. Delivery, Audit and Resource Limits

### 5.1 Authenticate Webhooks and Deduplicate Durable Delivery

**Profile Level:** L1 (Crawl)

#### Description

Use the official SDK's [webhook verification](https://developers.openai.com/api/docs/guides/webhooks) on the original request body, with the endpoint's signing secret and timestamp validation. Treat `webhook-id` as a durable delivery idempotency key. API and Agents session callbacks can be duplicated or retried; callback content is a notification to retrieve authorized state, not permission to perform an arbitrary action from a supplied URL.

#### Rationale

**Why This Matters:**
- A forged completion notification can trigger an application's privileged downstream workflow.
- A valid replay can repeat an external write unless deduplication survives process restarts.

**Attack Prevented:** Forged callbacks and duplicate side effects from replayed delivery.

#### ClickOps Implementation

1. Open **Platform settings → Project → Webhooks**, review endpoint ownership and subscribe only to required event types.
2. Store the signing secret through your approved secret-manager workflow. Validate raw bytes in the application before accepting the event.
3. Supply an atomic durable queue/idempotency store and a worker that retrieves only authorized resource IDs. Use the dashboard's test-event feature with disposable data after deployment approval.

#### Code Implementation

{% include pack-code.html vendor="openai-api" section="5.1" %}

The receiver starts no listener and makes no API call. The application supplies an official SDK client configured with `webhookSecret` and an atomic `enqueueOnce` adapter. A process-local set is insufficient. Queue failures return a retryable failure rather than acknowledging work that was lost.

#### Validation & Testing

Require rejection of missing, tampered and stale signatures. Test duplicate delivery, out-of-order notifications and storage failure; restart the receiver to check durable deduplication. SDK-only signature verification does not prove your worker is idempotent.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | Transmission integrity and input validation — SC-8, SI-10 |

### 5.2 Export Audit Records and Read Back Security Policy

**Profile Level:** L2 (Walk)

#### Description

Export [API Platform organization audit logs](https://developers.openai.com/api/reference/resources/admin/subresources/organization/subresources/audit_logs/methods/list), alert on access/network changes, and compare project settings with their approved values. These records are separate from ChatGPT Compliance logs, inference usage, and Agents traces. A successful list read does not prove every tool action is audited.

#### Rationale

**Why This Matters:**
- An administrator can weaken a control after a deployment passes review.
- Read-only policy data sources reveal drift that an enforcement template alone cannot establish.

**Attack Prevented:** Persistent unauthorized access through unnoticed security-policy changes.

#### ClickOps Implementation

Use organization audit administration and the relevant project settings to review the same time window and configuration represented by the exports. Confirm the permission and audit-enablement requirements in the [Admin APIs guide](https://developers.openai.com/api/docs/guides/admin-apis). Configure protected SIEM ingestion and map the raw API audit `type` field before enabling the sample detection.

#### Code Implementation

{% include pack-code.html vendor="openai-api" section="5.2" %}

The REST exporter stages all pages privately and emits rows only after complete success. It exits unsuccessfully on fetch/schema/cursor errors. Requests use fixed documented API bases, stdin-only credential headers, no curlrc or redirects, 5-second connect/30-second total timeouts and an 8 MiB response bound. Exports stop at 64 MiB or 10,000 pages; narrow the time window when a bound is reached. The explicit `HTH_FIXTURE_LOOPBACK=1` override permits only `127.0.0.1` fixture URLs. Commit an export checkpoint only after success, overlap subsequent windows and deduplicate by event ID. The separate Terraform assessment reads model, tool and retention settings without managing them: copy it with `versions.tf` into a read-only assessment directory, excluding resource packs.

#### Validation & Testing

In an authorized fixture project, correlate an approved policy change with its API audit record and a policy read-back. Verify SIEM fields against actual ingested JSON; the Sigma rule remains experimental until that mapping is tested. Protect exported actor identities and resource metadata. Do not claim trace or action completeness from configuration-change events.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | Audit review and continuous monitoring — AU-6, CA-7 |

### 5.3 Enforce Reviewed Spend and Rate Limits

**Profile Level:** L1 (Crawl)

#### Description

Use [spend alerts and enforced hard spend limits](https://developers.openai.com/api/docs/guides/spend-limits) according to the workload's interruption tolerance. An alert sends a notification; a hard limit stops affected API traffic with a specific 429 error. Enforcement is not instantaneous and can permit a small overrun. Apply model-specific rate limits separately; use the current singular Terraform `openai_project_rate_limit` resource, not the removed aggregate resource.

#### Rationale

**Why This Matters:**
- A compromised integration can exhaust shared budget or capacity.
- An unplanned hard cap can itself interrupt a critical production service.

**Attack Prevented:** Unbounded API consumption and resource exhaustion from an abused integration.

#### ClickOps Implementation

1. Open **Organization limits** or the target **Project → Limits**. In **Spend**, choose **Edit spend limit**.
2. Set the reviewed monthly value and enable **Enforce a hard limit** when traffic interruption is acceptable. Set earlier spend alerts with an accountable responder.
3. Record recovery ownership and distinguish spend-limit errors from request/token rate limiting and exhausted prepaid credits. Review each project's model rate limits separately.

#### Code Implementation

{% include pack-code.html vendor="openai-api" section="5.3" %}

The native hard-limit resource uses **USD cents**. Organization and project caps can both apply. The official [rate/spend Terraform guide](https://developers.openai.com/api/docs/guides/terraform/rate-limits-and-spend) documents discovery and import of model-specific rate-limit IDs; a spend limit is not a rate-limit substitute.

#### Validation & Testing

Read back enforcement status and compare usage with alert delivery in an authorized non-production project. Do not exhaust a production budget to test it. For `project_spend_limit_exceeded` or `organization_spend_limit_exceeded`, a reviewed increase/removal allows recovery after propagation, or wait for the monthly reset. Never retry those errors indefinitely as transient capacity failures.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | Denial-of-service protection — SC-5 |

### 5.4 Gate Cyber Access by Project and Explicit Request

**Profile Level:** L2 (Walk)

#### Description

Treat [Daybreak](https://developers.openai.com/api/docs/guides/daybreak) as an approved access program with separate organization, project, model and request gates. Enable only approved internal security workloads in a non-default project. API project access does not provision ChatGPT/Codex workspace access. Daybreak Red requires organization SSO and IdP-enforced MFA; approval does not grant every model or Zero Data Retention.

Set `access_programs.cyber` explicitly and record the served model/program. Defaults are model-dependent:

| Request/model case | Documented behavior |
|---|---|
| Omitted on `gpt-6.1-terra` | Standard safeguards; reduced cyber refusals require Red approval and an explicit compatible selection through Responses, not Chat Completions |
| Omitted on earlier eligible mainline models such as `gpt-6-sol` | Can select Blue when organization and project access permit, otherwise standard |
| `gpt-6.1-sol` / `gpt-6-astra` | Reduced refusals require Red approval, but the request value is `daybreak_blue`; `daybreak_red` is incompatible |
| Cyber-specialized models | Use the approved model and `daybreak_red`; `gpt-6-cyber` needs additional model approval |

`standard` explicitly retains standard safeguards on compatible models. The request setting never grants access. Check current compatibility instead of deriving the value from the approval tier or a `-latest` alias.

#### Rationale

**Why This Matters:**
- Implicit selection can change the safeguards used after a model change.
- A broad project or downstream integration can expose capabilities beyond the approved users and engagement.

**Attack Prevented:** Use of specialized cyber access outside the approved identity, project and tool-execution scope.

#### ClickOps Implementation

1. Confirm the approved organization, users/services, models and engagement with the onboarding owner. For Red, enforce SSO and IdP MFA in the API organization holding access.
2. As an **API organization owner**, select the approved non-default project. Open **Project settings → General → Daybreak model access**, enable only approved tiers and save. A project owner alone cannot change this setting. Allow about 15 minutes, then recheck saved settings and membership. Follow the [team setup instructions](https://help.openai.com/en/articles/20001531-openai-daybreak-set-up-access-for-your-team).
3. Use that project's credential and separately restrict model permissions through 2.2. For `gpt-6-cyber`, verify additional approval and the application's IP allowlist in 2.1. Do not infer model unavailability solely from its absence in `/models`.
4. If the Cyber project uses ZDR, configure PSP using **Organization settings → Data controls → Data retention → Connect storage**. Follow the cloud-specific least-privilege setup, connect and validate storage, and confirm **Validated** plus **Zero Data Retention with Private Safety Processing**. Refresh only reloads saved state; it does not test connectivity. Monitor storage/key access and follow the lifecycle in 3.1–3.2.

#### Code Implementation

{% include pack-code.html vendor="openai-api" section="5.4" %}

The SDK builder defaults to an explicit `standard` selection; changing it requires a reviewed compatible model/program. Execution is an explicitly invoked integration function and returns only response ID, request ID when available, served model and selected program. Use a stable pseudonymous `safety_identifier` per user, with no email or other direct identifier. The separate Admin GET assesses saved PSP status without running validation. Native project/provider contracts inspected here do not expose a verified Daybreak-toggle automation field; the request and PSP GET are not substitutes for project enablement.

#### Validation & Testing

Use an authorized bounded defensive fixture on the exact project/model after setup; verify an excluded identity/project remains denied. No tenant test was performed here. Reconcile the returned model/program with intended selection; implicit standard treatment can appear as `access_programs: null`. Investigate `invalid_access_program`, `unsupported_access_program` and `access_program_not_enabled` separately. Do not automatically change the program or retry `cyber_policy` as a transient failure. Cyber safeguards remain active, including possible streaming errors. Enforce independent filesystem/network boundaries and review sensitive tool calls against the engagement scope, failing closed when review is unavailable; application review and the hosted-session review in 4.1 are separate controls.

#### Compliance Mappings

| Framework | Mapping |
|---|---|
| NIST 800-53 Rev 5 | Access enforcement and least privilege — AC-3, AC-6 |

## 6. Compliance Quick Reference

| Control family | Guide controls | Evidence boundary |
|---|---|---|
| Access and authenticators | 1.1–1.2, 5.4 | Effective roles, workload claims and Daybreak approval/project access need authorized tenant tests |
| Network and least functionality | 2.1–2.2, 4.1–4.2 | Ingress, sandbox egress and service-origin MCP are separate |
| Retention | 3.1–3.2 | Contract, endpoint/tool eligibility and downstream copies remain distinct |
| Audit and integrity | 5.1–5.2 | Offline signature tests do not establish live delivery/action coverage |
| Resource availability | 5.3 | Hard caps can interrupt workloads; propagation is not instantaneous |

## Appendices

### Automation and Lifecycle Notes

Terraform packs use official `openai/openai` 1.5.x resources; the provider added workload identity in 1.5.0 and removed the deprecated aggregate project rate-limit resource in 1.0.0. The [provider changelog](https://github.com/openai/terraform-provider-openai/blob/main/CHANGELOG.md), full resources and data-source lists were checked. Read packs, pure request builders and enforcement packs have separate purposes. Nothing executes a product write by default; Terraform still requires deliberate plan/apply review, and the SDK integration entry point starts work only when explicitly invoked.

The module pins provider **1.5.0** with its dependency lockfile. SDK examples use the isolated `packs/openai-api/sdk` package and committed Bun lockfile: run `bun install --cwd packs/openai-api/sdk --frozen-lockfile --ignore-scripts` to install official **openai 7.51.0**. Tests import that local SDK directly; an ambient root installation is not a validation dependency.

The API feature index still contains legacy Assistants/Agent Builder surfaces; use the [current deprecation schedule](https://developers.openai.com/api/docs/deprecations) when migrating. Videos API/Sora shutdown guidance is a lifecycle issue, not an opportunity to create new video integration controls. No fabricated GraphQL, native SQL, ChatGPT-policy Terraform or universal retention setting is supplied.

### References

- [Source-first API coverage and remaining gaps](/research/openai-api-source-coverage/)
- [API guides and endpoint indexes](https://developers.openai.com/api/llms.txt)
- [API keys and service accounts](https://developers.openai.com/api/docs/guides/api-keys)
- [Official provider resources and data sources](https://github.com/openai/terraform-provider-openai/tree/main/docs)
- [API data controls](https://developers.openai.com/api/docs/guides/your-data)
- [Sandbox security](https://developers.openai.com/api/docs/guides/agents-api/environments/security)
- [Webhook delivery and verification](https://developers.openai.com/api/docs/guides/webhooks)

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-05 | 0.1.0 | ai-drafted | Initial source-first API Platform guide covering project/workload access, network and tool policies, data lifecycle, beta Agents boundaries, signed callbacks, native Terraform assessment and spend enforcement. Public documentation and offline fixtures only; no tenant exercised. | Codex (GPT-6) |
| 2026-11-05 | 0.1.0 | ai-drafted | Reconciled the omitted Daybreak index branch: explicit program selection, separate project/model approval, model-dependent defaults, Cyber prerequisites and customer-owned PSP storage lifecycle. | Codex (GPT-6) |

## Contributing

Report source drift or propose verified configuration improvements through the [contribution process](/contributing/). Include the exact product, endpoint/tool, plan, region and interface version; a successful offline test does not establish tenant availability.
