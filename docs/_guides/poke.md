---
layout: guide
title: "Poke Hardening Guide"
vendor: "Poke"
slug: "poke"
platform: "Cognition"
platform_slug: "cognition"
product: "Poke"
tier: "2"
category: "AI/ML Platform"
description: "Harden Poke messaging identity, connected accounts, action-capable API ingress, shared recipes, custom MCP and attended local tunnels."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-05"
---

## Overview

This is a product guide within the [Cognition platform](/guides/devin/). Harden Poke messaging identity, connected accounts, action-capable API ingress, shared recipes, custom MCP and attended local tunnels.

### Intended Audience

- Account and endpoint administrators
- Integration/developer-platform owners
- Security and GRC teams reviewing effective access and evidence

### How to Use This Guide

- **L1 (Crawl):** Establish identity ownership and protect sensitive state.
- **L2 (Walk):** Restrict effective integration and execution authority.
- Pilot changes in a disposable environment with recovery and approved rollback. Configuration evidence and denial tests are separate from policy intent.

### Scope

Poke is the personal assistant continued under Cognition after the [July 23 Interaction team announcement](https://cognition.com/blog/interaction). Its phone/messaging identity, contract, Kitchen keys and integrations are separate from Devin Cloud SSO/SCIM. No enterprise SSO/RBAC/MDM capability is inferred from common ownership. Human assistance is task-scoped in the FAQ; that does not establish an organization-wide access policy or audit exporter.

**Validation status:** no tenants declared — Tier 0+1 only. This guide was researched from public configuration documentation and tested with local fixtures/stubs. No login, key creation, enrollment, integration, live product call or policy change was performed. It remains ai-drafted.

## Table of Contents

1. [Identity & Connected Accounts](#1-identity-connected-accounts)
2. [API & Recipe Governance](#2-api-recipe-governance)
3. [MCP & Local Exposure](#3-mcp-local-exposure)

## 1. Identity & Connected Accounts

### 1.1 Minimize Connected Account Authority

**Profile Level:** L1 (Crawl)

#### Description

Connect only the mail, calendar, files and other accounts needed for the task. Poke is a personal assistant with its own connected-account identity, not an organization configured by Devin SSO.

#### Rationale

**Why This Matters:**
- Connected mail/calendar integrations can perform actions, not only read notifications.
- Disconnecting one integration does not remove other accounts, existing exports or scheduled work.

**Attack Prevented:** Overbroad connected-account access and continued automation after offboarding.

#### Prerequisites

Owner of the Poke account and upstream account/provider consent.

#### ClickOps Implementation

1. Open **poke.com/integrations**, select an integration and inspect the connected account and upstream permissions before accepting consent. Use a dedicated low-privilege account for shared or automated work.
2. For unused access choose the connected account → **Disconnect from Poke**. If compromise is suspected, also revoke provider grants/sessions and inspect actions, recipes and other remaining integrations.
3. Review **Retry/Refresh** reauthorization carefully; it can restore access previously interrupted by provider authentication. Maintain an owner and purpose for every connection.

**Automation:** The fetched integration guide documents account connection/disconnection in the UI. No administrative inventory/disconnect REST/GraphQL API, Terraform provider or distinct SDK was linked in the fetched Poke developer catalog; private/unlisted interfaces remain unverified. The message API is not an account-access setter.

#### Validation & Testing

Inspect the upstream account’s connected applications and effective permissions. On an authorized pilot disconnect one integration and confirm its tools stop while unrelated connections remain understood. No real connection or token was created for this guide.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | AC-2, AC-6, IA-5 | Supports configuration and access objectives |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Managing integrations](https://poke.com/docs/managing-integrations), [FAQ](https://poke.com/faq) (retrieved 2026-11-05; no live validation).

---

### 1.2 Protect Messaging Identity and Account Lifecycle

**Profile Level:** L1 (Crawl)

#### Description

Review linked phone/messaging identities and account merge/deletion consequences before transferring or retiring an account.

#### Rationale

**Why This Matters:**
- A merge keeps the selected account’s memory, recipes and integrations; the other account’s data is scheduled for deletion.
- Account deletion can take up to 24 hours and retained backups/legal obligations have separate handling.

**Attack Prevented:** Wrong-account ownership, accidental disclosure through a transferred number and unintended retention.

#### Prerequisites

Control of the verified messaging channels, account owner and retention/legal-hold decision.

#### ClickOps Implementation

1. In **Settings → messaging** review the preferred SMS, WhatsApp or Telegram channel. Follow the documented phone verification flow; never share verification codes.
2. For a merge use **Settings → phone number** and the documented verification prompts. Review exactly which account is kept before confirming. Other messaging channels migrate; the discarded account’s data is deleted after 30 days, so retain approved records first.
3. For retirement open **Settings → Privacy → Delete Account**. Disconnect sensitive upstream integrations and revoke keys/grants as part of containment; deletion timing does not prove every upstream token/session is gone.

#### Code Implementation

The first-party CLI wrapper runs `whoami` only through an already installed, trusted local Poke package, with npm offline/no-install settings. It creates a protected identity evidence file and does not log in, merge, delete or install anything. CLI logout and account deletion have different scopes.

{% include pack-code.html vendor="poke" section="1.2" %}

#### Validation & Testing

Review the private identity result against the intended account. Independently confirm the chosen account/channel and upstream revocations after an authorized lifecycle action. Account merge and deletion were not executed in this refresh.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | AC-2, IA-2, SI-12 | Supports configuration and access objectives |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Merging accounts](https://poke.com/docs/merging-accounts), [Recipe CLI commands](https://poke.com/docs/creating-recipes), [FAQ](https://poke.com/faq) (retrieved 2026-11-05; no live validation).

---

## 2. API & Recipe Governance

### 2.1 Treat API Messages as Action-Capable Ingress

**Profile Level:** L2 (Walk)

#### Description

Use a separate Kitchen V2 key per reviewed automation and validate event admission before forwarding content. The entire JSON object becomes context for an assistant that can use email, calendar and connected integrations.

#### Rationale

**Why This Matters:**
- An API key holder can cause the agent to process instructions with the account’s connected authority.
- Webhook fields, source URLs and selected text can contain adversarial instructions even inside valid JSON.

**Attack Prevented:** Untrusted event content causing unintended messages, calendar changes or external actions.

#### Prerequisites

Explicitly approved automation and existing Kitchen V2 key supplied by a secret manager. Never create a key merely to test this guide.

#### ClickOps Implementation

1. Open **Kitchen → API Keys** and review the key owner/purpose. For an authorized new workflow use a dedicated named V2 key; the legacy `pk_` V1 webhook is deprecated and cannot be reused at the new endpoint.
2. Authenticate and authorize the originating event, restrict sources and fields, bound payload size and deduplicate/replay-control it before calling Poke. Treat the content as untrusted; prompt labels are not an access boundary.
3. On compromise revoke the affected key and review connected-account actions. Avoid automatic retries after an ambiguous send: delivery may already have happened.

#### Code Implementation

The pack validates a small JSON object offline by default. Only an explicit `--send` makes one POST to the fixed HTTPS origin; it hides the bearer credential from argv, refuses redirects, bounds transport and validates the documented success field. Acceptance means delivery to Poke, not completed or authorized downstream work. No administrative read endpoint or first-party SDK was established; the vendor’s generic HTTP examples are not a separate SDK.

{% include pack-code.html vendor="poke" section="2.1" %}

#### Validation & Testing

Run preview on synthetic content and verify no network request occurs. A live send would require separate action review and an existing key; none was made here. Validate key revocation in the actual account and provider actions during incident response.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | AC-6, IA-5, SI-10 | Supports configuration and access objectives |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Poke API, V2 keys and response contract](https://poke.com/docs/api) (retrieved 2026-11-05; no live validation).

---

### 2.2 Review Shared Recipe Credentials and Existing Subscribers

**Profile Level:** L2 (Walk)

#### Description

Treat a published recipe as a release of instructions and, when selected, shared integration credentials. Review existing subscribers separately from new signups.

#### Rationale

**Why This Matters:**
- The recipe’s shared integration option lets consumers act without connecting their own account.
- Editing a recipe affects new signups, not existing users’ installed behavior.

**Attack Prevented:** Shared-account abuse and false assumptions that a recipe edit revoked existing access.

#### Prerequisites

Kitchen recipe owner and upstream account owner; approved public/private distribution audience.

#### ClickOps Implementation

1. Open **Kitchen → Create Recipe** or edit the intended recipe. Review onboarding instructions, required integrations and whether each connection is personal or **shared**. Avoid shared production credentials.
2. Before publishing, use a low-privilege dedicated connection and review what another subscriber can cause it to do. Inspect any published website/form ingress and its connected-account actions.
3. Track recipe versions and subscribers through the available product workflow. On unsafe releases, notify affected users through an authorized process and revoke upstream shared credentials where necessary; editing the recipe alone does not update existing users.

**Automation:** The fetched recipe documentation provides Kitchen authoring and first-party CLI development tools, but no verified administrative API for forcibly updating/revoking all existing recipe installations. No invented subscriber-enforcement endpoint or native policy file is supplied.

#### Validation & Testing

For an authorized pilot compare a fresh signup with an existing installation after a benign edit. Review shared-account provider logs and ensure the planned rollback revokes actual upstream rights. No recipe was published or subscribed during this refresh.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | CM-3, AC-6, IA-5 | Supports configuration and access objectives |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Creating recipes and shared integrations](https://poke.com/docs/creating-recipes) (retrieved 2026-11-05; no live validation).

---

## 3. MCP & Local Exposure

### 3.1 Authenticate and Scope Custom MCP Servers

**Profile Level:** L2 (Walk)

#### Description

Require server-side authentication and least privilege for each custom MCP connection. Use Poke’s user identifier only as authenticated request context, never as a standalone authorization credential.

#### Rationale

**Why This Matters:**
- A custom server can expose sensitive tools and data to the assistant.
- A caller-supplied `X-Poke-User-Id` header alone cannot prove identity; this is a security inference from the documented header, not a vendor authentication guarantee.

**Attack Prevented:** Unauthenticated MCP access, cross-user data leakage and excessive upstream tool rights.

#### Prerequisites

Owner of the HTTPS MCP endpoint, reviewed tool inventory and supported bearer/API-key authentication.

#### ClickOps Implementation

1. Open **Integrations → Custom / integrations/new**, provide the reviewed name and MCP URL and optional API key, then **Create** only after approving server-side authentication. Use a dedicated secret and do not embed it in URL queries, browser-prefill links or CLI history.
2. On the server validate the configured bearer credential first, then bind user context to the authorized account/tenant. Reject missing/invalid authentication; do not trust a user-ID header from arbitrary callers.
3. Limit exposed tools and upstream account permissions. Remove the integration and revoke its credential on retirement; deletion of the client definition alone does not revoke server access.

**Automation:** Native custom MCP creation is documented in the UI and first-party `poke mcp add` CLI. Credential-bearing writes are intentionally left to the reviewed interactive workflow; the reference examples include argument/query credential paths that this guide does not reproduce. No enterprise MDM/SSO control is inferred.

#### Validation & Testing

Test missing/invalid authentication and a synthetic cross-user request against an authorized test server before connecting. Confirm the server rejects unauthorized operations independently of assistant instructions. No MCP connection was made here.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | AC-3, AC-6, IA-5 | Supports configuration and access objectives |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Custom MCP servers](https://poke.com/docs/mcp-servers), [Integrations](https://poke.com/docs/managing-integrations) (retrieved 2026-11-05; no live validation).

---

### 3.2 Bound Local Development Tunnels

**Profile Level:** L2 (Walk)

#### Description

Expose only an explicitly reviewed loopback MCP service for the duration of an attended development task, and stop the Poke tunnel afterward.

#### Rationale

**Why This Matters:**
- A tunnel exposes local tools/data to a remote assistant; it does not start or secure the MCP server.
- Tool discovery refreshes periodically, so the current tool set may change while a tunnel is active.

**Attack Prevented:** Unattended local-service exposure and unintended tools becoming remotely callable.

#### Prerequisites

Trusted already installed Poke CLI, reviewed local MCP server and an authorized signed-in development account. No agent/package installation is needed to inspect the preview.

#### ClickOps Implementation

1. Start the reviewed MCP server separately with least privilege and no unrelated listeners. Review its authentication and tool set.
2. Use the documented **Poke CLI → tunnel** workflow with a loopback endpoint and reviewed name. Keep the terminal attended; tool synchronization is approximately every five minutes.
3. Stop with Ctrl+C when finished and inspect the Poke integration state plus local listener. Revoke credentials if the endpoint or tools were exposed incorrectly.

#### Code Implementation

The wrapper previews an exact loopback-only tunnel invocation. Only `--start` runs the already installed first-party CLI; npm is offline and no package is downloaded. It does not start an MCP server, create credentials or make background persistence. This refresh exercised only stubs and preview mode.

{% include pack-code.html vendor="poke" section="3.2" %}

#### Validation & Testing

Preview an approved synthetic endpoint and reject external hosts/credential-bearing URLs. During a separately authorized live task confirm Ctrl+C closes exposure and review any calls already made. Do not call preview a security test of the actual tunnel service.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | AC-17, SC-7 | Supports configuration and access objectives |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Recipe development and tunnel lifecycle](https://poke.com/docs/creating-recipes), [MCP tunnel commands](https://poke.com/docs/mcp-servers) (retrieved 2026-11-05; no live validation).

---

## 4. Compliance Quick Reference

Mappings support control objectives; they are not a product benchmark or certification. The bounded November search found no product-specific prescriptive CIS/SCuBA baseline; gated/unpublished coverage is unverified.

| Framework | Objectives | Controls |
|-----------|------------|----------|
| SOC 2 | CC6 access, CC7 monitoring | All controls as mapped individually |
| NIST SP 800-53 Rev. 5 | AC/IA, CM, SC and AU families | See each control’s specific mapping |
| ISO 27001:2022 | Access and secure configuration | A.5.15, A.8.9 objectives |

## Appendix A: Edition and Deployment Compatibility

| Surface | Applicability |
|---------|---------------|
| Poke account and integrations | Supported account/consent features; upstream grant differences apply |
| Kitchen V2 API | Existing authorized V2 key; deprecated V1 is not substituted |
| Recipes | Shared credentials and existing-user update behavior require separate review |
| CLI / tunnel | Trusted preinstalled first-party package and supported local service; no automatic install |
| Devin enterprise controls | Do not configure Poke; private enterprise capabilities remain unverified |

## Appendix B: References and Automation Coverage

The [November source-first inventory](/research/cognition-source-coverage-2026-11/) records product naming, precise configuration evidence, six automation surfaces, read/write differences and retrieval failures. Unverified is not verified absence. The [Code Pack](https://github.com/grcengineering/how-to-harden/tree/main/packs/poke) contains native or documented first-party interfaces only. No GraphQL, fabricated SDK, generic SQL, or guessed enterprise console is supplied. No live evidence or maturity promotion is claimed.

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-05 | 0.1.0 | ai-drafted | Initial source-first 6-control guide with separate identity/deployment boundaries and offline-tested packs; live product verification unavailable. | Codex (GPT-6) |

## Contributing

Report corrections through [GitHub issues](https://github.com/grcengineering/how-to-harden/issues) and the [contribution guide](/contributing/). Share redacted version-specific evidence without tokens, account data or proprietary content.
