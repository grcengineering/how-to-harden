---
layout: guide
title: "Cursor Origin Hardening Guide"
vendor: "Cursor Origin"
slug: "cursor-origin"
platform: "SpaceXSI"
platform_slug: "spacexai"
product: "Cursor Origin"
tier: "1"
category: "DevOps"
description: "Cursor Origin early-beta hardening for repository and namespace access, rulesets, app tokens, webhooks and GitHub mirrors"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-05"
---

## Overview

Origin is Cursor’s early-beta Git hosting and collaboration product. It follows the namespace owner’s Privacy Mode; legacy Privacy Mode cannot enable Origin. [Current product reference](https://cursor.com/docs/origin). It has repository/namespace grants, protection rulesets, apps and tokens in addition to Cursor account identity. GitHub mirrors, agent actions and CI integrations require independent authorization review.

See the [family Common Controls index](/guides/cursor/#products-in-this-platform) for product boundaries. A shared owner does not establish shared policy inheritance. SpaceXSI is the current first-party name; the historical platform URL remains stable. [Source-first reconciliation](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/spacexai-source-coverage.md) records the discovery scope, evidence and gaps.

### Intended Audience

Administrators, security engineers and application owners responsible for this product's identities, data and integrations.

### How to Use This Guide

Apply L1 (Crawl) controls first, then L2 (Walk) for sensitive workloads and L3 (Run) where strict deployment requirements justify them. **No tenants declared — Tier 0+1 only; VERIFIED-LIVE = 0.** All content remains AI-drafted. No credentials, settings or live integrations were created or changed during research.

### Scope

Covers Origin codebase/repository access, native rulesets, mirrors, CLI credential handling, apps/delegated user tokens and signed webhooks. Inherit Cursor identity only where documented; console.x.ai keys and generic Cursor Admin keys are not interchangeable Origin tokens. Beta interfaces and migration compatibility need live verification before rollout.

## Table of Contents

1. [Access and Repository Authority](#1-access-and-repository-authority)
2. [Protection Rules](#2-protection-rules)
3. [Apps and Credentials](#3-apps-and-credentials)
4. [Webhook and Agent Integrations](#4-webhook-and-agent-integrations)

---

## 1. Access and Repository Authority

### 1.1 Limit Codebase and Repository Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Enable Origin only for approved users/groups and review namespace plus repository grants. Team Internal visibility is broader than Private; removing a direct repository grant does not remove namespace access.

#### Rationale
**Why This Matters:**
- An inherited namespace permission can preserve access after a direct collaborator entry is removed.

**Attack Prevented:** Unintended source disclosure and persistent collaborator access.

#### ClickOps Implementation
1. Open **cursor.com/codebase → Settings → Permissions** to review Origin enablement, creation permissions and grants.
2. Open **Repository → Settings → Access** (team-owned) or **Collaborators** (personal). Prefer Private for sensitive repositories and remove unnecessary external/organization grants at both levels.

[First-party configuration reference](https://cursor.com/docs/origin/settings) (fetched 2026-11-05).

#### Code Implementation

The CLI and pinned native Terraform data sources inventory direct repository **and** namespace grants. Neither resolves all effective group/custom-policy access. Treat unresolvable actors as unknown and protect evidence/state.

{% include pack-code.html vendor="cursor-origin" section="1.1" %}

#### Validation & Testing
Review effective roles with an authorized read-only identity at each inheritance layer. Personal repositories are private by default; do not assume the team Internal toggle exists there. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

### 1.2 Verify Mirror Direction Before Changing Source of Truth

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Identify whether GitHub or Origin owns each repository. Review protections, collaborators, integrations and CI during migration rather than assuming a mirror copies every security control.

#### Rationale
**Why This Matters:**
- Detaching a mirror changes the authoritative write plane and can leave workflows or protections behind.

**Attack Prevented:** Unprotected writes or inconsistent access after migration.

#### ClickOps Implementation
1. Review **Repository → Settings** mirror status and direction. Inspect **Danger Zone → Detach** only as an explicitly approved migration.
2. Use native migration verification and review the source provider’s settings. Origin installation tokens reject pushes to inbound mirrored repositories; keep the source system’s protections active.

[First-party configuration reference](https://cursor.com/docs/origin/cli/reference/commands) (fetched 2026-11-05).

**Automation:** The native CLI has **origin repo verify-migration** and mirror operations; the Migration REST API documents transition/detach/read-job operations using a Cursor **user** credential with mirror scopes plus upstream-admin rights. Installation tokens cannot change mirror state. The provider repository data source exposes mirror metadata, but does not configure mirroring. No destructive migration pack is supplied.

#### Validation & Testing
Capture mirror status and run the read-only **origin repo verify-migration** workflow with captured GitHub evidence or authorized read credentials. Review reported mismatches before migration. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

## 2. Protection Rules

### 2.1 Enforce Native Merge and Push Rulesets

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Create active Origin rulesets for protected references and review bypass actors. Evaluate mode observes policy without enforcing it; imported GitHub protection JSON must be reconciled before activation.

#### Rationale
**Why This Matters:**
- A configured rule can look protective while disabled, evaluation-only or bypassable.

**Attack Prevented:** Direct protected-branch updates and merges without required checks/review.

#### ClickOps Implementation
1. Open **Repository → Settings → Rules & Protections** and review the actual ruleset scope.
2. Use native CLI/REST to inspect **enforcement**, included/excluded refs and bypass actors. Require appropriate PR approvals/status checks and push restrictions; review imported rules in evaluate mode, then activate after testing.

[First-party configuration reference](https://cursor.com/docs/api/origin) (fetched 2026-11-05).

#### Code Implementation

The native provider resource writes reviewed rulesets; the CLI reads current state. Ruleset updates replace lists, so import/inventory existing rules and bypasses first. Keep native deletion protection and Terraform prevent_destroy. Origin can omit an inaccessible bypass identity from API output: an empty visible list does not prove no bypass.

{% include pack-code.html vendor="cursor-origin" section="2.1" %}

#### Validation & Testing
Attempt synthetic direct push and merge violations in an approved test repository. The pack only inventories rulesets; it cannot prove every ref pattern or omitted inaccessible bypass identity is safe. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

## 3. Apps and Credentials

### 3.1 Install Apps on Selected Repositories with Minimal Scopes

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Review each Origin app installation’s owner, repository-selection mode and scopes. Keep app Ed25519 signing keys restricted and rotate with a tested overlap.

#### Rationale
**Why This Matters:**
- The app signing key can mint credentials for each accepted installation grant.

**Attack Prevented:** Broad repository access after third-party app compromise.

#### ClickOps Implementation
1. As workspace admin, open **Origin app settings**, review signing keys and the app’s install page. Select only the approved owner/repositories.
2. Review **Repository → Settings → Apps → Manage Apps** and codebase app installations. Apps are private until published; marketplace publication and installation are separate decisions.

[First-party configuration reference](https://cursor.com/docs/origin/apps/build-app) (fetched 2026-11-05).

#### Code Implementation

{% include pack-code.html vendor="cursor-origin" section="3.1" %}

#### Validation & Testing
Use the read-only app-specific inventory pack for each app JWT. It does not enumerate other vendors’ apps across the whole organization; reconcile the codebase GUI inventory too. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

### 3.2 Attenuate Short-Lived Tokens and Review User Delegation

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Use installation tokens narrowed to needed repositories/scopes, with at most fifteen-minute lifetime. Treat installation user tokens as delegated user authority, distinct from app-only actions.

#### Rationale
**Why This Matters:**
- Broad contents-write includes pushes and merges; namespace user-token creation can act on behalf of a member.

**Attack Prevented:** Privilege escalation through oversized app or impersonation grants.

#### ClickOps Implementation
1. Review accepted app scopes before minting installation tokens; request an explicit subset of scopes and repository IDs.
2. Use the documented delegated-user flow only when required. Check actor and **performedVia** attribution; revoking an installation prevents new tokens but issued tokens may live until expiry.

[First-party configuration reference](https://cursor.com/docs/api/origin) (fetched 2026-11-05).

**Automation:** Native Origin REST creates installation access tokens with narrowed scopes/repository IDs and delegated user tokens where **namespace:user_tokens:write** is granted. Token creation is not run here. Validate the intersection of app/install/user authority; deleting an installation blocks new tokens but issued tokens can remain valid for up to 15 minutes. No interchangeable Cursor team-admin key or inferred SDK is used.

#### Validation & Testing
Verify denied repositories/scopes with synthetic calls in an approved environment. User-token permissions are the intersection of user and installation; no app JWT, user token or signing key is generated by these packs. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

### 3.3 Protect CLI and Git Credentials

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Use the Origin CLI’s supported authentication exchange and avoid storing installation tokens in Git remote URLs. User login credentials and app integration tokens serve different purposes.

#### Rationale
**Why This Matters:**
- A secret in .git/config can be copied into logs, archives or another agent’s context.

**Attack Prevented:** Credential leakage and unintended reuse of personal authority in CI.

#### ClickOps Implementation
1. For interactive users, review **origin auth** and the configured credential helper; keep personal API keys in the approved secret manager.
2. For app CI, use the documented installation-token Git Basic flow with username **x-access-token**. Keep tokens out of URLs/logs and remove obsolete credentials/SSH keys when offboarding.

[First-party configuration reference](https://cursor.com/docs/api/origin) (fetched 2026-11-05).

**Automation:** Native **origin auth** and Git credential-helper configuration exist. **CURSOR_AUTH_TOKEN** takes precedence; **CURSOR_API_KEY** is exchanged and is not the raw Origin API credential. Keep credential-helper configuration out of repositories and restrict overrides. This guide’s read CLI packs refuse a custom endpoint. No login/token creation was run.

#### Validation & Testing
Inspect sanitized Git remotes and CI variable handling. The CLI exchanges personal API keys for short-lived user tokens; do not send a personal API key directly to an Origin endpoint. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

### 3.4 Constrain Namespace Inbound IP Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 | AC-3, SC-7 |

#### Description
Use the native namespace inbound IP policy where eligible. Admit required user, integration and recovery egress before enforcement; an enabled flag with no enabled entries does not establish a restrictive policy.

#### Rationale
**Why This Matters:**
- A namespace-wide rule can lock out legitimate users and automation. Per-entry and whole-set ownership models can delete or replace each other’s intended exceptions.

**Attack Prevented:** Use of permitted Origin credentials from unauthorized network locations.

#### ClickOps Implementation
No exact dashboard navigation for this policy was established from the fetched settings reference. Use the documented native Origin API/provider paths rather than an invented UI switch. Review the namespace, allowed caller CIDRs and an independently tested recovery route before enabling; preserve existing enforcement while adopting entries.

[First-party resource configuration](https://github.com/cursor/terraform-provider-cursor/blob/v0.8.0/docs/resources/origin_inbound_ip_allowlist.md) and [read data source](https://github.com/cursor/terraform-provider-cursor/blob/v0.8.0/docs/data-sources/origin_inbound_ip_allowlist_entries.md), fetched 2026-11-05. The current [REST contract](https://cursor.com/docs/api/origin#inbound-ip-allowlist) covers Git SSH/HTTPS, API, MCP and downloads, but Cursor-owned services/Cloud Agents on Cursor’s network are exempt. Both a target team’s policy and a member/service-account’s own team policy can apply. **trustAppDeclaredIps** can admit installation/user tokens using every installed app’s declared egress, including future apps; it does not cover tarballs/downloads or other credentials. The pinned provider does **not** expose that field/readout: inspect the raw API policy separately and leave it UNKNOWN until reviewed.

#### Code Implementation

The example reads native posture and separately gates entry management and enforcement. It avoids mixing individual entries with the whole-set resource. Keep native deletion protection and Terraform prevent_destroy; do not treat the API’s caller-address checks as recovery for every caller.

{% include pack-code.html vendor="cursor-origin" section="3.4" %}

#### Validation & Testing
In an authorized pilot, test admitted and denied locations for each actual credential/protocol and the recovery route. Confirm enabled entries and effective namespace enforcement independently; a data-source read is not a reachability test. No live calls were run.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3, SC-7; thematic, not certification |

---

### 3.5 Require Trusted SSH Certificates

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 | IA-5, AC-3 |

#### Description
For eligible team namespaces, trust approved SSH certificate authorities and deliberately enable certificate requirements. Supply only the verified CA public key; keep the signing private key in the organization’s own protected system.

#### Rationale
**Why This Matters:**
- A certificate requirement changes accepted Git credentials. Removing an authority invalidates its certificates and can break access immediately.

**Attack Prevented:** Persistent access through unmanaged personal SSH keys and user API keys on the covered Git paths.

#### ClickOps Implementation
The fetched native provider/API schema establishes the control; an exact dashboard path was not established. Inventory existing authorities and requirement state before adopting them. Plan overlapping authority rotation, short-lived issued credentials and independent recovery; do not generate or upload private keys as part of this guide.

[First-party CA resource](https://github.com/cursor/terraform-provider-cursor/blob/v0.8.0/docs/resources/origin_ssh_certificate_authority.md), [requirement resource](https://github.com/cursor/terraform-provider-cursor/blob/v0.8.0/docs/resources/origin_ssh_certificate_requirement.md) and [read inventory](https://github.com/cursor/terraform-provider-cursor/blob/v0.8.0/docs/data-sources/origin_ssh_certificate_authorities.md), fetched 2026-11-05.

#### Code Implementation

The example defaults to no writes and gates enforcement on a managed/imported CA plus tested recovery. Requiring certificates rejects user-registered SSH keys and user API keys over HTTPS; do not infer that all app credentials or REST access are revoked. The native API has no CA rename/update; replacement needs an approved rotation. The final CA cannot be removed while certificates are required.

{% include pack-code.html vendor="cursor-origin" section="3.5" %}

#### Validation & Testing
Verify issued-certificate identity, expiry, trusted CA and rejection of unmanaged keys using a pilot. Independently verify the requirement state and alternative application/protocol paths. Native deletion protection and Terraform prevent_destroy intentionally block casual replacement; create_before_destroy does not override them. No live credentials or policy changes were made.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | IA-5, AC-3; thematic, not certification |

---

## 4. Webhook and Agent Integrations

### 4.1 Verify Signed Deliveries and Limit Trigger Effects

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Authenticate Origin webhooks and installation receipts using the documented signing/discovery contract. Deduplicate/reject replayed events before any downstream agent, CI or write action.

#### Rationale
**Why This Matters:**
- A webhook delivery is untrusted until signature, time and intended app/installation are checked.

**Attack Prevented:** Forged or replayed events triggering privileged automation.

#### ClickOps Implementation
1. Review the app’s webhook URL, subscribed events and receiver verification in **Origin app settings**. Use HTTPS and only required events.
2. Verify the **Ed25519 v1ed** signature over the UTF-8 bytes of the **lowercase SHA-256 hex digest** of **webhook-id.webhook-timestamp.raw-body**, using an active Origin JWKS key. Standard Webhooks libraries do **not** implement this Origin construction. Reject timestamps outside five minutes and deduplicate stable **webhook-id** retries.
3. Routing headers are convenience only: after signature verification, authorize the signed body’s app, installation, event and repository before downstream CI/agent actions. Cache keys within documented limits and fail closed on unavailable/unknown keys.

[First-party configuration reference](https://cursor.com/docs/api/origin) (fetched 2026-11-05).

**Automation:** Native Origin app REST/CLI configure webhook URL/subscriptions and expose delivery history/ping/redelivery. This guide does not send events or redeliver production work. Receiver verification and idempotent authorization are required deployment code, not a console-only feature.

#### Validation & Testing
Test bad signatures, stale timestamps, replay IDs and unknown installations offline. Review delivery history without redelivering real production events; exact receiver implementation remains deployment-specific. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

## Automation and Evidence Limits

Origin exposes a first-party early-beta CLI plus extensive REST reads/writes for access, rulesets, apps/keys, repositories, tokens and webhooks. CLI packs perform read-only inventories; REST app inventory is app-scoped and paginated. The official cursor/cursor **v0.8.0** provider exposes rulesets, grants, inbound IP and SSH-certificate resources plus read data sources. The examples are opt-in, retain native deletion protection and Terraform prevent_destroy, and require recovery evidence before enforcement. A separate administrative SDK was not established. API/CLI beta contracts and hidden/inaccessible principals prevent a blanket compliance conclusion from a successful inventory.

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
