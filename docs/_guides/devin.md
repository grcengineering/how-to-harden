---
layout: guide
title: "Devin & Cognition Hardening Guide"
vendor: "Cognition"
slug: "devin"
platform: "Cognition"
platform_slug: "cognition"
product: "Common Controls"
tier: "1"
category: "AI/ML Platform"
description: "Cognition common controls and Devin Cloud hardening: SSO, SCIM, roles, API credentials, security profiles, repository access, secrets, and audit evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-10-30"
---

## Overview

Devin is Cognition's software-engineering agent. Its ability to execute commands, use connected repositories and call external tools makes identity, authorization and execution boundaries more important than prompt instructions alone. This is the **Cognition Common Controls hub**, centered on the Devin Cloud organization/enterprise control plane. Product-specific local execution and knowledge-access controls live in the linked guides.

### Intended Audience

- Enterprise identity and security administrators
- Platform engineers governing autonomous coding and integrations
- GRC teams collecting configuration evidence

### How to Use This Guide

- **L1 (Crawl):** Establish ownership, least privilege and monitoring.
- **L2 (Walk):** Enforce lifecycle, network and integration boundaries.
- **L3 (Run):** Separate execution infrastructure and sensitive-data workflows.
- Test changes in a non-production organization first. Before authentication or inbound-network changes, prove an independent administrative recovery path; otherwise do not apply.

### Scope

Cognition is the owner/platform; Devin Cloud, Devin CLI, Devin Desktop and DeepWiki are distinct surfaces. Desktop succeeds acquired Windsurf; it is included for current Cognition coverage, not described as originally created by Cognition. Devin Security, Review, Oncall and Outposts are capabilities/deployment surfaces, not additional duplicate product guides. See the [source and automation census](/research/cognition-sources/).

These enterprise controls do **not** automatically configure local CLI/Desktop permissions, public DeepWiki, or Outpost firewalls. Cloud-backed Outposts are not a fully air-gapped deployment. Federal air-gapped Desktop/CLI is a separate beta deployment and is outside these cloud-connected baselines.

**Validation:** Documentation-backed draft; local structural and mocked pack tests are not tenant validation. No live console, API credential, provider plan/apply or OCEAN run was exercised. All guides remain `ai-drafted`.

## Products in This Platform

| Product | Guide | Control-plane boundary |
|---------|-------|------------------------|
| Common Controls / Devin Cloud | This guide | Enterprise and organization identity, cloud agent governance and evidence |
| Devin CLI | [Devin CLI](/guides/devin-cli/) | Local permissions, sandbox and managed client controls; cloud profiles do not replace these |
| Devin Desktop (formerly Windsurf) | [Devin Desktop](/guides/devin-desktop/) | IDE policies and Cascade; Devin Local follows CLI controls instead |
| DeepWiki | [DeepWiki](/guides/deepwiki/) | Public documentation/MCP versus private Devin indexing and authenticated access |

## Table of Contents

1. [Identity & Credentials](#1-identity--credentials)
2. [Network & Execution Boundaries](#2-network--execution-boundaries)
3. [Repositories, Tools & Secrets](#3-repositories-tools--secrets)
4. [Monitoring & Detection](#4-monitoring--detection)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

## 1. Identity & Credentials

### 1.1 Require Enterprise SSO Without Default-Login Bypass

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2, AC-3 |

#### Description

Require the enterprise identity provider and its phishing-resistant MFA policy; do not mistake an SSO connection for enforcement.

#### Rationale

**Why This Matters:**
- Alternate login routes undermine centralized authentication.
- Existing membership and sessions require separate lifecycle handling.

**Attack Prevented:** Account takeover through a weaker sign-in route.

#### Prerequisites

Enterprise; Cognition-assisted SAML/OIDC setup and identity-provider administrator. Prove a recovery path before changing authentication.

#### ClickOps Implementation

1. Create the supported SAML/OIDC application following the provider-specific onboarding instructions; send metadata and any client secret only through the approved secure channel.
2. Ask Cognition to select **Disable default login connections** when configuring SSO. Setup alone leaves email, GitHub and Google login enabled.
3. Confirm trusted domains and permitted login connections with Cognition. Apply MFA in your IdP; do not invent a Devin-native MFA toggle.

**Automation:** Cognition-assisted setup — the documented public v3 API/provider catalog does not expose an SSO-connection write interface. Membership APIs are not SSO enforcement. Use the linked onboarding workflow (verified 2026-10-29).

#### Validation & Testing

Use a pilot account to verify IdP authentication and rejection through each disabled alternative. Test the independent recovery route; record results without credentials.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| NIST SP 800-53 Rev. 5 | IA-2, AC-3 | Supports the mapped access, configuration or monitoring objective; not a certification claim |

**Source:** [SSO onboarding](https://docs.devin.ai/enterprise/security-access/sso/guide) (verified 2026-10-29).

---

### 1.2 Automate Deprovisioning with SCIM

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2 |

#### Description

Use SCIM for user/group lifecycle and disable conflicting login-time JIT provisioning.

#### Rationale

**Why This Matters:**
- Login-only group synchronization does not promptly remove departed users.
- A token-generation warning can leave JIT enabled.

**Attack Prevented:** Orphaned enterprise membership and stale group grants.

#### Prerequisites

Enterprise; SCIM-capable IdP. Manage Enterprise Settings is needed to disable JIT.

#### ClickOps Implementation

1. Open **Settings → Enterprise → Membership → Members → User and IdP group provisioning**. Generate the SCIM bearer token and store it securely with the displayed base URL.
2. Configure the IdP using the vendor SCIM procedure, including create/update/deactivate operations and matching work-email/userName mappings.
3. Confirm **Just-in-time (JIT) provisioning** is off. Token generation only attempts to disable it; missing permissions or errors leave it on.

#### Code Implementation

SCIM is the enforcement interface configured in the IdP. The Terraform pack is **partial inventory only**, not proof that SCIM/JIT settings are correct or that all group-derived users were enumerated.

{% include pack-code.html vendor="devin" section="1.2" %}

#### Validation & Testing

Provision then deactivate a disposable pilot user; confirm enterprise membership removal and inspect active-session behavior. Reconcile both direct and group-derived access against the IdP; account for its provisioning delay.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| NIST SP 800-53 Rev. 5 | AC-2 | Supports the mapped access, configuration or monitoring objective; not a certification claim |

**Source:** [SCIM setup](https://docs.devin.ai/enterprise/security-access/scim) (verified 2026-10-29).

---

### 1.3 Minimize Roles and Service Users

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Separate enterprise administration from organization work and give each automation a purpose-specific service user.

#### Rationale

**Why This Matters:**
- Enterprise-level permissions can span organizations.
- A shared human credential obscures ownership and offboarding.

**Attack Prevented:** Excessive automation privileges and lateral access across organizations.

#### Prerequisites

Enterprise role administration requires Manage Account Membership; read-only inventory needs the permissions listed in each pack.

#### ClickOps Implementation

1. Open **Enterprise Settings → Membership → Roles**; create a role with only the required permissions. Review both enterprise and organization scope.
2. Assign roles in **Membership → Members** or **Groups (IdP)**. A user currently has one role per organization and one account-level role.
3. Create automation principals under **Settings → Devin API → Service users** (organization) or **Enterprise settings → Devin API → Service users**. Prefer organization scope when enterprise access is unnecessary.

#### Code Implementation

The API pack reads role definitions and service-user assignments; the Terraform alternative inventories names/scopes and counts, not permission definitions. Neither changes assignments or certifies least privilege.

{% include pack-code.html vendor="devin" section="1.3" %}

#### Validation & Testing

Compare every assignment with an approved owner/purpose inventory. Test a representative denied operation with a pilot principal. Review after team changes and monthly.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| NIST SP 800-53 Rev. 5 | AC-6 | Supports the mapped access, configuration or monitoring objective; not a certification claim |

**Source:** [Custom roles](https://docs.devin.ai/enterprise/security-access/custom-roles) · [API authentication](https://docs.devin.ai/api-reference/authentication) (verified 2026-10-29).

---

### 1.4 Govern Personal Access Tokens

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-5, AC-6 |

#### Description

Keep enterprise PATs disabled unless necessary; otherwise require approval and a short maximum lifetime.

#### Rationale

**Why This Matters:**
- PATs inherit the human user’s rights across accessible organizations.
- Non-expiring human credentials are unsuitable for shared production automation.

**Attack Prevented:** Long-lived credential misuse and unreviewed programmatic access.

#### Prerequisites

Enterprise PAT policy: Manage enterprise settings. Inventory/revocation: Manage account API keys.

#### ClickOps Implementation

1. Open enterprise **Devin API → PAT policies**. Retain **Disabled**, or choose **Approval required** when a documented workflow needs PATs.
2. Set the shortest practical maximum lifetime rather than accepting the 365-day default. Review requests in the **Approval queue**.
3. Review **PAT inventory**. Before tightening policy, inspect the confirmation: affected tokens are revoked; disabling revokes every active PAT and cancels pending requests.

**Automation:** ClickOps only for enterprise PAT policy — no policy write handle was found in the fetched public v3 OpenAPI/provider index. Service-user endpoints do not manage human PAT policy ([PAT documentation](https://docs.devin.ai/api-reference/personal-access-tokens), verified 2026-10-29).

#### Validation & Testing

Test with a pilot user that self-service creation is unavailable and expiration is capped. Coordinate revocation with tool owners to avoid breaking active workflows.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| NIST SP 800-53 Rev. 5 | IA-5, AC-6 | Supports the mapped access, configuration or monitoring objective; not a certification claim |

**Source:** [Personal access tokens](https://docs.devin.ai/api-reference/personal-access-tokens) (verified 2026-10-29).

---

## 2. Network & Execution Boundaries

### 2.1 Restrict Inbound Access with IP Access Lists

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, SC-7 |

#### Description

Limit enterprise webapp and API ingress to approved corporate, VPN and automation egress CIDRs.

#### Rationale

**Why This Matters:**
- A stolen credential remains usable from an attacker network without an ingress boundary.
- Empty lists remove restrictions; incomplete replacements can lock out administrators.

**Attack Prevented:** Credential replay from unapproved networks.

#### Prerequisites

Enterprise; the GET endpoint requires **Manage IP Whitelist**, even for this read-only audit. Prove an independent allowed administrator route before writing.

#### ClickOps Implementation

1. No documented web-console editor exists for this setting. Inventory the required egress networks with networking and automation owners.
2. Use the read-only API pack to capture current configuration. Review the complete replacement list before the Terraform change; never use documentation example addresses.

#### Code Implementation

API verification is GET-only. The separate Terraform **mutating** pack replaces the enterprise singleton: review a plan, retain the complete approved list, and never apply without verified recovery access. Destroying the provider resource clears restrictions; its lifecycle guard is not protection after removing the block.

{% include pack-code.html vendor="devin" section="2.1" %}

#### Validation & Testing

After an authorized change, confirm allowed access and a denied request from a controlled outside network (documented denial: HTTP 401). This ingress policy does not constrain agent egress.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| NIST SP 800-53 Rev. 5 | AC-3, SC-7 | Supports the mapped access, configuration or monitoring objective; not a certification claim |

**Source:** [IP access lists](https://docs.devin.ai/enterprise/security-access/ip-access-lists) (verified 2026-10-29).

---

### 2.2 Enforce Mandatory Session Security Profiles

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, CM-6, SC-7 |

#### Description

Bind a tested mandatory security profile to the enterprise or organization default instead of relying on an optional recommendation.

#### Rationale

**Why This Matters:**
- Unbound profiles do not restrict sessions.
- Recommended profiles can be overridden or explicitly opted out of.

**Attack Prevented:** Excessive agent network, tool and repository access.

#### Prerequisites

Manage security profiles at the relevant scope; enterprise-wide defaults require Enterprise. Beta API access is not guaranteed.

#### ClickOps Implementation

1. Open **Enterprise settings → Devin → Security profiles**, or **Settings → Customization → Security profiles** for organization scope.
2. Create a pilot profile with narrow destinations, approved MCP servers, read-only Git/Devin MCP and GitHub CLI token removal where feasible. Pilot compatibility, then select **Mandatory** and bind the default.
3. Inspect automation and session selections. Restart or wake existing sessions after changes; running sessions retain the restrictions from their last boot/wake.

#### Code Implementation

The beta API pack inventories profiles and default bindings only; it does not prove effective policy on every session. Authentication/plan failures are unknown evidence, not a secure result. No automatic binding changes are made.

{% include pack-code.html vendor="devin" section="2.2" %}

#### Validation & Testing

In a new pilot session, verify a required destination works and an unapproved destination does not; try an opt-out and confirm the mandatory floor remains. Keep required vendor destinations in mind.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| NIST SP 800-53 Rev. 5 | AC-3, CM-6, SC-7 | Supports the mapped access, configuration or monitoring objective; not a certification claim |

**Source:** [Security profiles](https://docs.devin.ai/product-guides/security-profiles) (verified 2026-10-29).

---

### 2.3 Separate Build and Outpost Network Boundaries

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | SC-7, CM-6 |

#### Description

Treat snapshot builds and self-hosted Outpost workers as separate enforcement boundaries, not inherited proof of session isolation.

#### Rationale

**Why This Matters:**
- A build-default override can replace even a mandatory session default.
- An Outpost policy description is not a firewall.

**Attack Prevented:** Exfiltration through privileged build jobs or unrestricted self-hosted execution.

#### Prerequisites

Security-profile manager plus build/Outpost infrastructure owner; isolated pilot execution environment.

#### ClickOps Implementation

1. In enterprise security settings, inspect **Default profile for snapshot builds**. Select a reviewed build network policy rather than **No profile**; only the network restriction applies to builds.
2. For Outposts, require the orchestrator to enforce each queued session’s effective **spec.network_policy** at the infrastructure layer before starting its worker. Re-read when re-queued; do not assume cached policy remains valid.

**Automation:** The build-default settings API and Outposts fleet API expose policy, but actual Outpost egress enforcement is infrastructure-specific. The [Outposts reference](https://docs.devin.ai/cloud/outposts/reference) documents the contract; this guide deliberately does not supply a universal firewall or claim the worker installs one (verified 2026-10-29).

#### Validation & Testing

Run separate benign allowed/denied egress tests in a snapshot build and an Outpost session. Stop worker admission if your orchestrator cannot establish its required boundary.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| NIST SP 800-53 Rev. 5 | SC-7, CM-6 | Supports the mapped access, configuration or monitoring objective; not a certification claim |

**Source:** [Build/Outpost profile behavior](https://docs.devin.ai/product-guides/security-profiles) · [Outposts contract](https://docs.devin.ai/cloud/outposts/reference) (verified 2026-10-29).

---

## 3. Repositories, Tools & Secrets

### 3.1 Limit Repository and MCP Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-6 |

#### Description

Expose only approved repositories and tools to each organization; keep generated changes behind human review and SCM protections.

#### Rationale

**Why This Matters:**
- A broad integration grant exposes unrelated code to agent tasks.
- Repository access, MCP access and direct GitHub API access are different permissions.

**Attack Prevented:** Cross-repository access and unexpected tool-driven changes.

#### Prerequisites

GitHub organization/app administrator and Devin repository/security-profile manager.

#### ClickOps Implementation

1. In **Settings → Connections → GitHub**, review the connection. In GitHub organization **Settings → GitHub Apps → Devin.ai Integration → Configure → Repository access**, select only approved repositories.
2. Delegate repositories to the appropriate Devin organizations under **Settings → Repositories**. Remove unnecessary broad grants; apply protected-branch review/check requirements in your SCM.
3. Use the profile in 2.2 for MCP restrictions and GitHub CLI token removal. A network allowlist alone does not disable an allowed MCP server.

#### Code Implementation

The Terraform pack grants read-only access to one exact repository. It is **additive**, not an authoritative restriction: overlapping group/prefix grants must be reviewed separately. Private DeepWiki indexing is covered in its [product guide](/guides/deepwiki/).

{% include pack-code.html vendor="devin" section="3.1" %}

#### Validation & Testing

Use a pilot account/session to confirm an unauthorized repository is inaccessible, and a read-only task cannot push. Require review before merges; do not automatically approve agent PRs.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-6 | Supports the mapped access, configuration or monitoring objective; not a certification claim |

**Source:** [GitHub integration](https://docs.devin.ai/integrations/gh) · [Security profiles](https://docs.devin.ai/product-guides/security-profiles) (verified 2026-10-29).

---

### 3.2 Scope Secrets and Prefer Workload Identity

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-5, AC-6 |

#### Description

Use the narrowest secret scope and replace static cloud credentials with scoped workload federation where supported.

#### Rationale

**Why This Matters:**
- Organization secrets are usable by all member sessions.
- Agent-readable credentials can be misused following prompt injection.

**Attack Prevented:** Credential exposure and reusable cloud-token theft.

#### Prerequisites

Secret administrator; cloud/IAM owner for OIDC. Use dedicated service accounts, never a personal account’s TOTP or browser session.

#### ClickOps Implementation

1. Review **Settings → Resources → Secrets**. Prefer personal/session scope for individual tasks and repository scope under **Settings → Environment → Blueprints → repository → Secrets** for repo-bound credentials.
2. For cloud access, follow the provider-specific OIDC setup action in the environment blueprint’s **initialize** phase. Constrain issuer, audience and organization subject in the relying party; do not trust every Devin organization.
3. Revoke unused upstream credentials. Avoid secrets in prompts, repository files, logs or snapshots.

**Automation:** Devin documents secrets APIs, the `devin_secret` Terraform resource and OIDC setup actions. No generic credential-writing pack is supplied: Terraform secret values enter state and cloud trust must be provider-specific. Follow the [OIDC action instructions](https://docs.devin.ai/product-guides/oidc) with a reviewed pinned action revision; do not copy unrestricted trust (verified 2026-10-29).

#### Validation & Testing

In a disposable session, confirm the expected cloud identity and denied access to an unrelated resource. Verify that a different organization cannot obtain the role. Never print the OIDC token.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| NIST SP 800-53 Rev. 5 | IA-5, AC-6 | Supports the mapped access, configuration or monitoring objective; not a certification claim |

**Source:** [Secrets](https://docs.devin.ai/product-guides/secrets) · [Workload identity](https://docs.devin.ai/product-guides/oidc) (verified 2026-10-29).

---

## 4. Monitoring & Detection

### 4.1 Collect Enterprise Audit Logs

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-2, AU-6, AU-9 |

#### Description

Collect bounded, paginated audit evidence using a dedicated service user and protect the exported records.

#### Rationale

**Why This Matters:**
- A successful first page is not a complete audit interval.
- Audit payloads can themselves contain sensitive content.

**Attack Prevented:** Undetected administrative misuse and loss of forensic visibility.

#### Prerequisites

Enterprise; **View Audit Logs** (`ViewAccountAuditLogs`). Protected output directory and a defined collection interval.

#### ClickOps Implementation

1. In **Enterprise Settings → Membership → Roles**, create a collection role with **View Audit Logs** and assign it to the dedicated enterprise service user.
2. Use the documented API collector below. The cited API reference does not establish a console export path; no fictional export button is assumed.

#### Code Implementation

The pack requires UTC Unix-second start/end bounds, follows cursors and fails on incomplete/malformed responses. Its conservative 31-day cap is a pack policy; the documented endpoint permits up to 100 days. Successful collection is not a clean-security verdict.

{% include pack-code.html vendor="devin" section="4.1" %}

#### Validation & Testing

Generate a benign authorized pilot event and confirm it appears in the protected collection. Test pagination and collector-failure alerting. Ship to your SIEM with a separately reviewed schema/retention policy.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| NIST SP 800-53 Rev. 5 | AU-2, AU-6, AU-9 | Supports the mapped access, configuration or monitoring objective; not a certification claim |

**Source:** [Audit API](https://docs.devin.ai/api-reference/v3/audit-logs/enterprise-audit-logs) (verified 2026-10-29).

---

### 4.2 Configure Input Guardrails

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | SI-4, AU-6 |

#### Description

Enable enterprise input guardrails as defense in depth, with monitored responses and a tested blocking policy.

#### Rationale

**Why This Matters:**
- Warnings and log-only modes still process the message.
- Message screening cannot substitute for tool, network or credential boundaries.

**Attack Prevented:** Known malicious-message patterns reaching agent processing; not all prompt injection.

#### Prerequisites

Enterprise feature enablement may require the account team; Manage enterprise settings.

#### ClickOps Implementation

1. Open enterprise **Settings → Guardrails → Guardrails** and inspect each preset’s description/examples.
2. Use **Log only** during a controlled pilot; then select **Block message** for reviewed categories. **Warn user** does not block.
3. Inspect **Violations** and route **ai_guardrail_violation** audit events to review. Do not configure historical **kill_session**: it is no longer a selectable action.

#### Code Implementation

Configuration is ClickOps; the documented API supports violation reads, not a guardrail-policy writer. Reuse the audit pack with `DEVIN_AUDIT_ACTION=ai_guardrail_violation` and its required time/output variables. It collects evidence without changing policy.

{% include pack-code.html vendor="devin" section="4.1" %}

#### Validation & Testing

Test a harmless vendor-provided example and a normal work request. Confirm the selected action and recorded event. Screening covers incoming initial/follow-up messages and PR comments, not an asserted universal content firewall.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| NIST SP 800-53 Rev. 5 | SI-4, AU-6 | Supports the mapped access, configuration or monitoring objective; not a certification claim |

**Source:** [AI Guardrails](https://docs.devin.ai/enterprise/features/ai-guardrails) (verified 2026-10-29).

---

## 5. Compliance Quick Reference

These are implementation mappings, not a Cognition benchmark or proof of compliance. No Devin/DeepWiki-specific CIS or SCuBA baseline was identified. The generic CIS AI MCP Server benchmark may inform MCP deployments; the DISA index was fetcher-limited, so STIG coverage could not be conclusively ruled out. Framework mapping does not override product plan/role prerequisites.

| NIST SP 800-53 Rev. 5 | Guide controls | Objective |
|----------------------|----------------|-----------|
| AC-2 | 1.2 | Account lifecycle |
| AC-3, AC-6 | 1.1, 1.3, 1.4, 2.1, 2.2, 3.1, 3.2 | Access enforcement and least privilege |
| IA-2, IA-5 | 1.1, 1.4, 3.2 | Identification and authenticator management |
| CM-6, SC-7 | 2.1–2.3 | Configuration and boundary protection |
| AU-2, AU-6, AU-9, SI-4 | 4.1, 4.2 | Event review, protection and monitoring |

## Appendix A: Edition and Deployment Compatibility

| Surface | Availability and limits |
|---------|--------------------------|
| Enterprise identity/admin | SSO/SCIM, custom enterprise roles, PAT policy, ingress list and enterprise audit API require Enterprise |
| Organization service users/repository integration | Use an eligible organization and the documented permissions; do not give an enterprise token to a single-org workload |
| Security profiles | Organization profiles and enterprise-wide profiles have different scopes; the API is beta and requires the matching Manage security profiles permission, including reads |
| Guardrails | Enterprise; account-team enablement may be required |
| Builds / Outposts | Build profiles constrain network only; Outpost network enforcement is operator-owned |
| Desktop / CLI / DeepWiki | Consult each product guide; a shared owner does not make cloud controls universal |

## Appendix B: References and Automation Coverage

- [Cognition source census and limitations](/research/cognition-sources/)
- [Devin API overview](https://docs.devin.ai/api-reference/overview) and [OpenAPI schema](https://docs.devin.ai/v3-openapi.json)
- [Official Cognition Terraform provider](https://github.com/CognitionAI/terraform-provider-devin) — pinned 0.5.0 packs; resources and data sources both inspected
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

The pack deliberately separates **verification** from **enforcement**. API collectors are GET-only; Terraform data sources do not enforce settings. The two Terraform resources are opt-in source artifacts, not executed changes. SSO, PAT policy, guardrails and secrets/trust setup require the documented administrative workflow. No GraphQL, generic SQL or invented SDK is assumed. The official CLI has cloud blueprint/secret commands, but no documented SSO/PAT-policy/IP-list management commands in the inspected reference. Those CLI surfaces and deployment-specific SDK/log formats are recorded in the source census; neither the local agent nor the Outposts worker substitutes for enterprise identity administration.

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-10-30 | 0.1.0 | ai-drafted | Initial Cognition hub and Devin Cloud controls with source-backed read-only audits and opt-in Terraform examples; no live tenant validation | Codex |

## Contributing

Report inaccuracies or propose improvements through [GitHub issues](https://github.com/grcengineering/how-to-harden/issues). See the [contribution guide](/contributing/). Re-stamp the guide and changelog dates on the actual publication date.
