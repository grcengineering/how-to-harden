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
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-05"
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

These enterprise controls do **not** automatically configure local CLI/Desktop permissions, public DeepWiki, or Outpost firewalls. Cloud-backed Outposts are not a fully air-gapped deployment. The separately administered [Devin Federal / air-gapped guide](/guides/devin-federal/) covers its own portal and host policies; these commercial settings do not configure it. [Poke](/guides/poke/) has a separate account and integration plane. Windsurf Plugins are covered conditionally in the [Desktop guide](/guides/devin-desktop/). The [November source-first ledger](/research/cognition-source-coverage-2026-11/) records bounded exclusions and unverified acquired-product surfaces.

**Validation:** Documentation-backed draft; local structural and mocked pack tests are not tenant validation. No live console, API credential, provider plan/apply or OCEAN run was exercised. All guides remain `ai-drafted`.

## Products in This Platform

| Product | Guide | Control-plane boundary |
|---------|-------|------------------------|
| Common Controls / Devin Cloud | This guide | Enterprise and organization identity, cloud agent governance and evidence |
| Devin CLI | [Devin CLI](/guides/devin-cli/) | Local permissions, sandbox and managed client controls; cloud profiles do not replace these |
| Devin Desktop (formerly Windsurf) | [Devin Desktop](/guides/devin-desktop/) | IDE policies and Cascade; Devin Local follows CLI controls instead |
| DeepWiki | [DeepWiki](/guides/deepwiki/) | Public documentation/MCP versus private Devin indexing and authenticated access |
| Poke | [Poke](/guides/poke/) | Separate personal messaging, integration, recipe, API and tunnel identity; does not inherit Devin SSO |
| Devin Federal / air-gapped | [Devin Federal](/guides/devin-federal/) | Separate federal portal and offline host policy; commercial common controls do not configure it |

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

Enterprise; self-service SAML/OIDC configuration and identity-provider administrator. Prove a recovery path before changing authentication.

#### ClickOps Implementation

1. Open **Settings → Authentication**. Verify the work domain using the displayed `_devin-verification` DNS TXT record and **Check DNS**; create the supported SAML/OIDC application at your IdP.
2. Select **Add SSO connection**, configure the confirmed metadata/credentials and verified domains, then test with a pilot administrator. Apply MFA at the IdP.
3. Under **Sign-in methods**, disable weaker email, Google and GitHub methods after proving recovery. At least one method must remain enabled; the current method cannot be disabled. Adding SSO alone does not enforce it.
4. Inspect **Edit connection → Add members automatically** (default on). Disable automatic membership if access must require provisioning; deprovisioning and existing sessions still need lifecycle controls.

**Automation:** The current SSO guide documents self-service ClickOps. No connection/sign-in-policy writer was established in the fetched provider and API references; a complete current OpenAPI export remained unavailable, so unlisted interfaces are **unverified**. Membership APIs do not enforce SSO. [Current procedure](https://docs.devin.ai/enterprise/security-access/sso/guide), retrieved 2026-11-05.

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
2. Assign roles in **Membership → Members** or **Groups (IdP)**. A direct assignment is not the effective role set: direct membership and IdP-group roles are additive unions without a role hierarchy. Enterprise administrators can access every organization. Review each granting path; login-claim refresh and SCIM propagation differ.
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

[November 2 release notes](https://docs.devin.ai/release-notes/2026) specifically say automation network-policy edits now apply to active automation sessions. Do not generalize this exception to all profile fields.

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

### 2.4 Constrain Devin Connect Routes and Gateway Identity

**Profile Level:** L3 (Run)

#### Description

For dedicated deployments, authorize each destination on both the Devin Connect control plane and the customer gateway. Keep the gateway administration listener private and route policy default-deny.

#### Rationale

**Why This Matters:**
- A session security profile and a gateway route are separate intersecting boundaries.
- Omitting a route port permits every port for the matching destination; a leaked enrollment token can impersonate a gateway.

**Attack Prevented:** Unintended access from cloud agents to private services and unauthorized gateway enrollment.

#### Prerequisites

Dedicated single-tenant deployment, approved destination/port inventory, network owner and enrollment-token secret storage.

#### ClickOps Implementation

1. Open **Enterprise Settings → Devin Connect → Add gateway**; choose Tunnel or Direct for the actual deployment. In **Add destination**, use approved exact hosts or supported IPv4 CIDRs; wildcards are not accepted.
2. Generate the enrollment token through the gateway workflow and mount it as a protected token file. Keep it out of images, logs, command arguments and repository files. Regeneration revokes the old token; coordinate replacement and availability.
3. Copy the deployment configuration again after destination changes. On the customer host, keep `admin_listen` on loopback, enumerate route ports, and apply a matching session network profile. An empty route list denies destinations.
4. For Tunnel, permit only the provided TLS edge and necessary proxy/CA path. For Direct/PrivateLink, use the actual AWS principal supplied by Cognition; do not expose the listener publicly or guess an account ID.

#### Code Implementation

The config emitter produces an inert **deny-all** Tunnel configuration using confirmed gateway values and a token-file path; it does not enroll or start a daemon. The first-party `gateway validate-config` wrapper only validates a reviewed file. Review and add exact routes through configuration management before an approved deployment. JSONL connection events exist, but their full field schema was not established, so no speculative SIEM detection is shipped.

{% include pack-code.html vendor="devin" section="2.4" %}

#### Validation & Testing

Validate offline, then on an authorized pilot test an allowed host/port and a controlled denied host/port. Inspect `conn_open`, `conn_close` and denial records privately. Reload validation rejects the whole invalid file and retains the previous policy; check effective policy and last-seen status rather than assuming an edited file was accepted. Stop the gateway/disable destinations to contain access, then rotate tokens and investigate existing sessions.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | SC-7, IA-5, AU-12 | Supports configuration and access boundaries |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Devin Connect configuration and lifecycle](https://docs.devin.ai/enterprise/deployment/devin-connect) (retrieved 2026-11-05; documentation-backed, no live validation).

---

### 2.5 Control Local Hands Pairing and Revoke Host Access

**Profile Level:** L2 (Walk)

#### Description

Treat Local Hands as a new connection from a cloud session to the developer OS account. Permit it only for an owned, private session and preserve per-tool approvals.

#### Rationale

**Why This Matters:**
- Local tools can read, write, copy files and execute a shell with the local user’s authority.
- A public session can be steered by others, while a saved local bypass setting can approve pending requests immediately.

**Attack Prevented:** Unreviewed cloud-to-workstation tool execution and continued local access after a task.

#### Prerequisites

Feature rollout and eligible human-owned session. Enterprise defaults off and non-enterprise defaults on; security-profile sessions, disabled native deployment and ownerless automation/service-user sessions are ineligible.

#### ClickOps Implementation

1. In **Organization Settings → Devin → Local Hands**, disable the feature unless the workflow needs it. Enable only after reviewing local permission and endpoint policy with the owner.
2. Pair only your own cloud session with the same-account CLI/Desktop. Pairing codes are single-use, expire in ten minutes, and a replacement invalidates the previous code. Do not publish a code or use `--public` for a sensitive host.
3. Keep Normal permissions and choose **Allow once** for bounded actions. **Allow for this session** and bypass have broader effects. Apply the [CLI Local Hands control](/guides/devin-cli/#23-preserve-local-hands-approvals); organization deny/ask rules still apply.
4. At completion use **Revoke access**, stop the CLI with Ctrl+C, or close the Desktop connection; ending the cloud session also disconnects. Review any commands already running and credentials/files already exposed separately.

**Automation:** The documented organization gate is UI-managed; no setter was verified in the fetched API/provider catalogs. The native user preference and first-party CLI state checks are in [CLI 2.3](/guides/devin-cli/#23-preserve-local-hands-approvals). Neither a local false preference nor a pairing code proves organization enforcement.

#### Validation & Testing

On an authorized pilot confirm a second user cannot steer the private session, tool requests ask as expected and revocation stops new local calls. Test with dummy files only. The client always asks about certain credential/destructive/privilege operations, but this is not a guarantee against every malicious instruction.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | AC-3, AC-6, CM-6 | Supports configuration and access boundaries |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Local Hands](https://docs.devin.ai/work-with-devin/local-hands) (retrieved 2026-11-05; documentation-backed, no live validation).

---

### 2.6 Reconcile Local-Agent Root Policy and Organization Overrides

**Profile Level:** L2 (Walk)

#### Description

Review effective local-agent policy at both enterprise root and organization scope; an organization list override is a complete replacement.

#### Rationale

**Why This Matters:**
- A root deny/ask, model or MCP list can disappear from an override even though the root remains configured.

**Attack Prevented:** Unintentional weakening through incomplete organization override lists.

#### Prerequisites

The appropriate organization/enterprise settings permission; pilot and recovery access before changing policy.

#### ClickOps Implementation

1. Open **Settings → Enterprise → Devin Desktop** and review the root baseline.
2. At the organization’s Devin Desktop settings page inspect every **Override**. Copy required root entries into the complete replacement list; lists do not merge.
3. Use **Reset** to restore inheritance for that control. Organization overrides are gradual rollout; confirm availability and effective policy before relying on them.

**Automation:** The documented root/override workflow is UI-managed. The model-access API is documented in the Desktop guide, but a generic writer for every override was not established in the fetched current references. Local user files cannot substitute for managed configuration.

#### Validation & Testing

Compare root, override and actual client behavior for a harmless denied operation. Root changes reach only controls still inheriting them. Coordinate Desktop and CLI baselines; legacy Cascade settings have different applicability.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1 | Supports effective-access review |
| NIST SP 800-53 Rev. 5 | AC-3, CM-6, SI-12 | Supports access/configuration and data lifecycle |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access/configuration management |

**Source:** [Local Agent Controls](https://docs.devin.ai/enterprise/local/controls) (retrieved 2026-11-05; no live validation).

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

Administrator of the relevant SCM connection and Devin repository/security-profile manager. Review each connector's real account/token requirements; GitHub App grants do not describe GitLab or Bitbucket authority.

#### ClickOps Implementation

1. In **Settings → Connections → GitHub**, review the connection. In GitHub organization **Settings → GitHub Apps → Devin.ai Integration → Configure → Repository access**, select only approved repositories.
2. Delegate repositories to the appropriate Devin organizations under **Settings → Repositories**. Remove unnecessary broad grants; apply protected-branch review/check requirements in your SCM.
3. Use the profile in 2.2 for MCP restrictions and GitHub CLI token removal. A network allowlist alone does not disable an allowed MCP server.
4. For **GitLab**, use **Settings → Connections → GitLab** and a dedicated service identity. The documented PAT connection requires `api` scope; keep its upstream memberships narrow. Review both organization delegation and personal **Link** identities/“Open PRs as” behavior. Where automatic webhook setup is available, it can install hooks on every project/group that identity administers; review the installation inventory and secret token separately.
5. For **Bitbucket**, review **Settings → Connections → Bitbucket** and whether the connection is a Premium workspace token or dedicated-account OAuth. Documented token setup requires repository administration and webhook read/write; OAuth hook installation requires repository admin. Review per-repository installed/skipped webhook status rather than assuming automatic review works everywhere. Devin's own writes use the connection identity; human Review actions use the actor's separate linked account. Revoke obsolete connection and personal grants upstream as well as in Devin.

#### Code Implementation

The Terraform pack grants read-only access to one exact repository. It is **additive**, not an authoritative restriction: overlapping group/prefix grants must be reviewed separately. Private DeepWiki indexing is covered in its [product guide](/guides/deepwiki/).

{% include pack-code.html vendor="devin" section="3.1" %}

#### Validation & Testing

Use a pilot account/session to confirm an unauthorized repository is inaccessible, and a read-only task cannot push. Require review before merges; do not automatically approve agent PRs.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-6 | Supports the mapped access, configuration or monitoring objective; not a certification claim |

**Sources:** [GitHub integration](https://docs.devin.ai/integrations/gh), [GitLab identity/webhooks](https://docs.devin.ai/integrations/gitlab), [Bitbucket identities/webhooks](https://docs.devin.ai/integrations/bitbucket), [Security profiles](https://docs.devin.ai/product-guides/security-profiles) (retrieved 2026-11-05).

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

### 3.3 Bound Automations, Oncall and Auto-triage Authority

**Profile Level:** L2 (Walk)

#### Description

Review the effective principal, every event trigger, tool grant, network policy and budget before enabling an automation or responder. Treat integration payloads as untrusted input to an action-capable agent.

#### Rationale

**Why This Matters:**
- Triggers are ORed, so a broad additional trigger can bypass a narrow channel or issue filter.
- Default organization execution may resolve to a configured service user or SystemUser; reply access is different from trigger admission.

**Attack Prevented:** Untrusted Slack, SCM, incident or webhook content initiating excessive agent actions.

#### Prerequisites

Automation/Oncall management rights; approved service-user role, integration scope and incident owner. The provider requires Terraform state access protection.

#### ClickOps Implementation

1. Open **Automations → Create automation** or edit an existing automation; in **Oncall**, inspect each responder’s triggers and runbook. Choose an explicit reviewed execution principal and minimum tool/network grants. Do not rely on an unset organization default identity.
2. Constrain Slack channel/user/group filters and Teams installation scope. Slack automations can read and write the trigger channel by default. Prefer reply access restricted to Devin users where appropriate; this does not restrict which events start a run.
3. Under **Settings → Connections → GitHub → connection menu → Automation Scope**, retain private-repository scope unless public comments are deliberately trusted. For webhooks use `X-Webhook-Secret`, rotate on exposure, and validate/replay-control events at the upstream source; no signed/replay-protected webhook guarantee was verified.
4. Set ACU, invocation and concurrency limits and a narrow network policy. Preflight is not an authorization boundary: **Run now** bypasses it, and script tests can execute real external writes. Limit selected secrets.
5. Review **Enterprise Settings → Devin → Dynamic workflows** (enterprise default off) before permitting deterministic orchestration and its child-session authority. Review reusable workflow/skill changes as code, and retain the parent session’s identity/tool/network boundaries.
6. For Auto-triage, review persistent shared scratchpad context, child-session budgets and Linear write access. For Oncall, review learned skills and **Settings/gear → Instructions → Skills** refresh policy; select **Never** where updates require approval. Disable triggers to stop new admission and inspect active sessions separately.

#### Code Implementation

The API collector inventories every page of automation and responder configuration using GET, redacts webhook URLs/runbook bodies, and fails unknown on malformed or incomplete evidence. The Terraform data source inventories Oncall schema capability flags; the disabled-by-default automation resource demonstrates explicit identity, limits and restricted replies. Inventory and a plan are not proof of a safe effective principal. Existing migrated schedules are not silently recreated as automations.

{% include pack-code.html vendor="devin" section="3.3" %}

#### Validation & Testing

Review each trigger independently using synthetic events and inspect Activity (documented 30-day history). Confirm a nonmatching event does not run and a harmless matching event uses the expected principal. Do not send production webhooks during document validation. November 2 notes say automation network-policy edits reach active sessions; other policy changes may require new sessions. Contain by disabling admission, canceling running work and revoking upstream credentials as needed.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | AC-6, SC-7, SI-4 | Supports configuration and access boundaries |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Automations](https://docs.devin.ai/product-guides/automations), [Oncall](https://docs.devin.ai/product-guides/devin-oncall), [Auto-triage](https://docs.devin.ai/product-guides/auto-triage), [provider 0.5.0](https://github.com/CognitionAI/terraform-provider-devin/releases/tag/v0.5.0), [Dynamic Workflows](https://docs.devin.ai/work-with-devin/dynamic-workflows) (retrieved 2026-11-05; documentation-backed, no live validation).

---

### 3.4 Separate Shared MCP, DANA and Messaging Identities

**Profile Level:** L2 (Walk)

#### Description

Grant MCP/database and messaging access to a narrowly scoped upstream identity. Distinguish personal OAuth from organization-shared credentials and model-generated instructions from enforceable database/tool permissions.

#### Rationale

**Why This Matters:**
- An organization OAuth connection uses one shared service account for members; adding DANA does not make SQL read-only.
- Teams delegated-token deletion does not remove the bot’s independent resource-specific consent.

**Attack Prevented:** Cross-user credential sharing, destructive database tools and continuing bot access after partial disconnection.

#### Prerequisites

Owners of each upstream account, MCP server, Slack workspace or Teams installation; read-only database roles for analysis-only work.

#### ClickOps Implementation

1. Open **Customize → MCPs** and inspect scope (personal, organization, enterprise), transport and credentials. Prefer per-user OAuth when isolation is required; organization OAuth must use a dedicated service account with minimum upstream grants. Review executable stdio commands and environment secrets.
2. For **Mode → Data** / Slack `dana!`, enable only the approved data sources and restrict writes at the database/MCP server. Review persistent database knowledge; prompts are not SQL authorization.
3. For dynamic credentials inspect **Advanced → Header Script** and the session-machine execution option. The Bash script runs before a connection, has a ten-second timeout and replaces headers; reject scripts that print credentials in logs. Error/timeout/malformed output fails the connection without fallback.
4. In **Settings → Connections**, review Slack’s file/history/write scopes and invited channels. For Teams distinguish bot installation RSC from separately linked user posting and any Microsoft 365 plugin. To remove access, uninstall the bot from the affected team/chat as well as disconnecting delegated users; verify upstream token/grant removal.

**Automation:** The fetched native workflow documents UI/OAuth and header-script configuration. Commercial API/MCP integration reads do not establish a shared-credential setter, and a current complete settings schema was unavailable; write automation remains **unverified** rather than declared nonexistent. No invented database connector SDK or SQL enforcement query is shipped.

#### Validation & Testing

With pilot accounts compare users’ effective upstream identity and denied write operations. Disconnect personal OAuth and separately remove bot installation to confirm both boundaries. Rotate shared secrets on compromise and investigate already-exported data; deleting a configuration does not recall it.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | AC-6, IA-5, AC-20 | Supports configuration and access boundaries |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [MCP configuration](https://docs.devin.ai/work-with-devin/mcp), [DANA](https://docs.devin.ai/work-with-devin/data-analyst), [Slack](https://docs.devin.ai/integrations/slack), [Teams](https://docs.devin.ai/integrations/microsoft-teams) (retrieved 2026-11-05; documentation-backed, no live validation).

---

### 3.5 Restrict Reusable Authenticated Browser Profiles

**Profile Level:** L2 (Walk)

#### Description

Use dedicated low-privilege browser accounts for reusable authentication blueprints and treat uploaded profile archives as credentials.

#### Rationale

**Why This Matters:**
- Chrome profiles carry cookies and local storage capable of bypassing repeated login.
- Blueprint setup can authenticate future organization sessions without another interactive approval.

**Attack Prevented:** Personal-session theft and unintended shared access through stored browser credentials.

#### Prerequisites

Manage Org Blueprints and ownership of the upstream application account. Default organization roles can carry blueprint-management rights; review assignments.

#### ClickOps Implementation

1. Follow **Browser authentication** with a fresh dedicated profile and minimum upstream permissions; never export the operator’s everyday browser profile.
2. In the blueprint workflow attach only the reviewed profile archive and initialization steps. Restrict the Manage Org Blueprints permission, archive storage and recipients.
3. On removal or offboarding delete/replace the blueprint material and revoke the upstream application sessions/tokens. Previously copied profiles and running sessions need separate containment.

**Automation:** The documented workflow uploads credential-bearing archives and edits blueprint initialization. Terraform blueprint/blueprint_file resources and CLI blueprint tooling exist, but no safe generic credential archive is supplied. Their availability is recorded in the census; creating or reading sensitive archives is deliberately excluded from the pack, not asserted unsupported.

#### Validation & Testing

Use a pilot application account to confirm its effective rights and absence of personal identities; then revoke upstream sessions and test rejection. Audit future-session initialization and retained archive copies without exposing cookie contents.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | IA-5, AC-6 | Supports configuration and access boundaries |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Browser authentication](https://docs.devin.ai/work-with-devin/browser-auth) (retrieved 2026-11-05; documentation-backed, no live validation).

---

### 3.6 Review Managed Plugin Releases and Dependencies

**Profile Level:** L2 (Walk)

#### Description

Maintain a reviewed organization/enterprise plugin manifest and release process. Govern dependencies explicitly and keep independent permission controls when governance retrieval or hooks fail.

#### Rationale

**Why This Matters:**
- Default-branch merges release code/instructions to future sessions.
- A wildcard forbid is not a dependency exemption: required/optional dependency entries must be explicit, and a failed managed-manifest fetch leaves that level unenforced.

**Attack Prevented:** Supply-chain execution through unreviewed hooks, MCP servers and transitive plugins.

#### Prerequisites

Customize Plugins administration, protected repository default branch, reviewed plugin dependency inventory and Git connection.

#### ClickOps Implementation

1. Open **Customize → Plugins → Add plugin → From repo** at organization or enterprise scope. Confirm the repository and `.devin-plugin/plugin.json` source before adding it.
2. Use required/optional/forbidden entries with explicit dependencies. Enterprise outranks organization, repository and user. Organization plugins reach local clients through the primary organization; enterprise plugins span organizations.
3. Protect and review default-branch merges, repository `.agents/skills`/AGENTS instructions, shared playbooks/knowledge, and executable hooks/MCP definitions. Pilot cloud and local agents separately; this ecosystem does not configure legacy Cascade. Retain organization permission/sandbox/endpoint boundaries if fetches or hooks fail.
4. Review skill frontmatter as permission-bearing code: `allowed-tools` can remove prompts, `permissions` adds allow/deny/ask matchers, and permissions remain after invocation. Automatic model invocation is the default; use the documented user-only trigger when appropriate. Review all supported skill-discovery paths, including other agent-tool directories, rather than only `.agents/skills`.
5. Use Skills for new instructions. Legacy Knowledge is deprecated and migrates to Skills in Plugins; from October 24 new accounts have Skills without Playbooks, and migrated Playbook APIs read/write the skill. Existing provider handles do not prove the old UI/workflow still applies to every account.

#### Code Implementation

The native manifest fragment is inert until reviewed and merged into the correct managed manifest. Its empty reviewed exceptions plus wildcard forbid are a restrictive starting point; explicitly enumerate approved required/optional plugins and dependencies before production use. It does not deploy or fetch plugins.

{% include pack-code.html vendor="devin" section="3.6" %}

#### Validation & Testing

Test an approved plugin and an unapproved dependency on a disposable pilot. Inspect effective sources and retrieval errors at each scope. Roll back the repository release and remove access/credentials separately if plugin code already ran. Current generic hook documentation is best-effort; see the CLI guide for version-specific `fail_closed` documentation conflict.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | AC-3, AC-6, CM-6 | Supports configuration and access boundaries |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Managed plugin ecosystem](https://docs.devin.ai/product-guides/plugin-ecosystem), [CLI plugin reference](https://docs.devin.ai/cli/extensibility/plugins/overview), [Skills permissions/discovery/migration](https://docs.devin.ai/product-guides/skills), [deprecated Knowledge](https://docs.devin.ai/onboard-devin/knowledge-onboarding) (retrieved 2026-11-05; documentation-backed, no live validation).

---

### 3.7 Constrain Review Approvals, Auto-Fix and Security Actions

**Profile Level:** L2 (Walk)

#### Description

Enroll repositories and users separately for auto-review, custom reviewers and Autoapprover. Govern approval-producing and code-changing features with repository authorization and explicit exclusions.

#### Rationale

**Why This Matters:**
- Autoapprover beta posts a real SCM approval that can unblock an existing merge queue or auto-merge.
- Removing an enrollment rule does not revoke an approval already posted; CI success can mean review completion rather than no findings.

**Attack Prevented:** Unexpected merge authorization and excessive code-changing actions from automated review or security findings.

#### Prerequisites

Review-management permission, SCM branch-policy owner and eligible feature plan/beta. Security scans/finding changes require their separate RBAC permissions.

#### ClickOps Implementation

1. Open **Settings → Review**, inspect each enrollment rule by repository, author, branch, label and diff limits, and add sensitive-scope exclusions. Exclusions take precedence; a personal Manual setting does not disable another matching rule.
2. Inspect **Autoapprover** enrollment independently and leave it disabled unless real approval is intended. Treat custom reviewer skills and shared enterprise instructions as executable review inputs; default-branch updates affect future reviews.
3. Under **Settings → Devin → Pull requests → Responding to bots**, prefer Selected bots over All Bots for Auto-Fix. This is an organization-wide write-capable session trigger, not a one-PR preference.
4. In **Security**, separate Start/Manage Scans and Manage Findings permissions from Fix with Devin. Review repository grants and profile availability. A Reviewed finding is not proof that its fix merged.
5. To contain, remove future enrollment, inspect and dismiss existing SCM approvals where required, stop active fix sessions and review commits/check requirements. Enforce intended checks and authorized reviewers in the SCM.

**Automation:** Review/security API families are documented, but a complete current settings schema could not be exported. Enrollment/Autoapprover writers remain **unverified**; scan/result APIs do not prove enrollment enforcement. No fabricated setting endpoint or automated approval/merge action is supplied.

#### Validation & Testing

On an authorized test repository inspect matching rules and the actual SCM check meaning. Verify that an excluded PR gets no automatic approval or fix. Inspect standing approvals after rule removal; no approval, merge or live PR test was performed in this refresh.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | AC-5, AC-6, CM-3 | Supports configuration and access boundaries |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Devin Review](https://docs.devin.ai/work-with-devin/devin-review), [Security 2.0](https://docs.devin.ai/work-with-devin/security-2-0) (retrieved 2026-11-05; documentation-backed, no live validation).

---

### 3.8 Govern Persistent Memory and Dreaming

**Profile Level:** L2 (Walk)

#### Description

Choose the allowed scope of personal memory and review persistent instructions after sensitive work.

#### Rationale

**Why This Matters:**
- Turning memory off retains existing notes; automated consolidation can affect future sessions.

**Attack Prevented:** Unreviewed instructions persisting across sessions and mistaken assumptions about deletion.

#### Prerequisites

The appropriate organization/enterprise settings permission; pilot and recovery access before changing policy.

#### ClickOps Implementation

1. Review **Enterprise settings → Devin → Sessions → Memory**. Choose **Always off** where persistence is prohibited; **Default on** permits organization changes.
2. Review **Settings → Devin → Sessions → Memory** at organization scope and **Customize → Memory** personally. Memory defaults on, is personal within each organization, and automation sessions do not use it.
3. Inspect changes/source links and request removal through a session where needed. Disabling personal or organization memory stops use/dreaming but does not delete notes.

**Automation:** The fetched feature reference documents UI gates, not a verified policy API/provider writer. The open Git memory format is not an administrator enforcement API; no guessed deletion/retention endpoint is shipped.

#### Validation & Testing

Confirm disabled use in an authorized new session and review retained notes separately. A memory instruction is not a permission boundary.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1 | Supports effective-access review |
| NIST SP 800-53 Rev. 5 | AC-3, CM-6, SI-12 | Supports access/configuration and data lifecycle |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access/configuration management |

**Source:** [Memory and Dreaming](https://docs.devin.ai/product-guides/memory) (retrieved 2026-11-05; no live validation).

---

### 3.9 Control Native Public App Deployments

**Profile Level:** L2 (Walk)

#### Description

Disable native public deployment where unnecessary and review each approved publication as an external-data release.

#### Rationale

**Why This Matters:**
- Hosted apps remain publicly reachable after the creating session ends.

**Attack Prevented:** Unintended publication of internal content and confusion between native and customer CI deployment authority.

#### Prerequisites

The appropriate organization/enterprise settings permission; pilot and recovery access before changing policy.

#### ClickOps Implementation

1. In eligible non-enterprise organizations open **Settings → Devin → Enable native deployments**; turn it off unless approved.
2. Review each explicit approve/deny deployment prompt before publication. Enterprise organizations and sessions with enforced security profiles/network policy cannot use these native deploy tools.
3. Govern customer CI/cloud credentials separately: those deployments use supplied tooling and are not disabled merely by the native toggle.

**Automation:** The fetched deployment guide documents the native UI gate and per-deploy approval. A native-toggle writer was not verified in the fetched API/provider references; no endpoint or automatic publish/delete action is invented.

#### Validation & Testing

On an authorized pilot confirm the tool is unavailable under the intended restriction. Stopping a session is not evidence an already-hosted site was removed; inspect published artifacts and revoke exposed credentials through the owning service.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1 | Supports effective-access review |
| NIST SP 800-53 Rev. 5 | AC-3, CM-6, SI-12 | Supports access/configuration and data lifecycle |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access/configuration management |

**Source:** [Native app deployments](https://docs.devin.ai/product-guides/deployment-capabilities) (retrieved 2026-11-05; no live validation).

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

### 4.3 Plan Customer-Managed Encryption Key Lifecycle

**Profile Level:** L3 (Run)

#### Description

For eligible dedicated deployments, select and govern the customer-managed KMS key before provisioning and preserve the ability to decrypt required data.

#### Rationale

**Why This Matters:**
- The configured KMS ARN is fixed when the tenant is created and cannot later be replaced through this feature.
- Disabling the key or revoking required Cognition access can interrupt the service.

**Attack Prevented:** Unreviewed key access and accidental loss of application availability.

#### Prerequisites

Enterprise Assured dedicated deployment, AWS KMS administrator and Cognition account team. Key rotation of material differs from changing the configured ARN.

#### ClickOps Implementation

1. Before tenant creation, agree the supported symmetric encryption key and exact Cognition AWS principal(s) with the account team. Apply only that reviewed key policy; do not substitute documentation example accounts.
2. Record key ownership, CloudTrail monitoring, rotation and recovery procedures. Protect administrative policy edits and test the recovery process with the service owner.
3. Coordinate disablement, revocation and deletion as availability-affecting changes. Use customer KMS monitoring to detect policy/use anomalies; do not claim a Devin UI switch exists.

**Automation:** Cognition-assisted provisioning plus native AWS KMS key policy. No commercial Devin CMK writer or data source was established in the fetched provider/API references. A universal policy would require unknown tenant principals, so none is fabricated; customer-specific KMS configuration and evidence belong in the approved infrastructure workflow.

#### Validation & Testing

Confirm the configured ARN and permitted principals with the account team and review actual KMS audit evidence. Do not disable a production key for a document test. Review key policy and recovery ownership after changes.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | SC-12, SC-13 | Supports configuration and access boundaries |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Customer-managed keys](https://docs.devin.ai/enterprise/security-access/security/customer-managed-keys) (retrieved 2026-11-05; documentation-backed, no live validation).

---

### 4.4 Enable Attribution Filtering Where Required

**Profile Level:** L2 (Walk)

#### Description

For Enterprise code-use policy, ask Cognition to enable attribution filtering and verify its behavior for cloud and local agents independently.

#### Rationale

**Why This Matters:**
- The feature is off by default and has no self-service enablement toggle in the documented workflow.
- Cloud filtering can block or scrub generated file edits; local behavior includes reverting matching edits and flagging chat, with documented exclusions.

**Attack Prevented:** Some unattributed generated-code matches reaching the repository; not malware, all IP risk or prompt injection.

#### Prerequisites

Enterprise, account-team/support enablement and a policy owner who understands matching limits.

#### ClickOps Implementation

1. Contact the Cognition account team/support to enable attribution filtering for the intended organization/enterprise and confirm local-client applicability.
2. Use the documented controlled examples to compare cloud file writes and local edits/chat. Account for trivial-snippet exclusions.
3. Monitor filter failures: the cloud write fails closed when the attribution service or scrubbing fails. Investigate rather than disabling the feature to complete a write.

**Automation:** Cognition-assisted enablement; no self-service policy writer or local substitute was verified in the fetched references. Model policies and content ignore files do not enable this service. Retain the support confirmation and pilot evidence without proprietary source.

#### Validation & Testing

Record actual enabled scope and pilot outcome. A blocked matching sample does not prove all code is original or licensed appropriately. Keep ordinary code review and provenance processes.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| SOC 2 | CC6.1, CC7.2 | Supports access and monitoring objectives |
| NIST SP 800-53 Rev. 5 | SI-7, CM-6 | Supports configuration and access boundaries |
| ISO 27001:2022 | A.5.15, A.8.9 | Supports access and configuration management |

**Sources:** [Attribution filtering](https://docs.devin.ai/enterprise/features/attribution-filtering) (retrieved 2026-11-05; documentation-backed, no live validation).

---

### 4.5 Set Data Controls and Verify Retention Scope

**Profile Level:** L1 (Crawl)

#### Description

Review the commercial account's Data Controls and opt out of model training where organizational policy requires it. Verify the applicable plan and contract before sending sensitive context.

#### Rationale

**Why This Matters:**
- The current security reference permits training by default for nonenterprise accounts; a paid-plan opt-out is an explicit choice, and Teams requires an administrator.
- Provider Zero Data Retention does not erase product history, feedback, backups or third-party integration records.

**Attack Prevented:** Unintended secondary use and retention of sensitive code or conversation content beyond the approved workflow.

#### Prerequisites

The commercial account's applicable plan, an authorized Teams administrator where required, and an approved data-handling policy. Enterprise commitments depend on the actual agreement; Poke and Federal have separate boundaries.

#### ClickOps Implementation

1. Open the documented **Data Controls** settings page for the intended commercial account and review the training preference. On an eligible paid plan, exercise the opt-out when required; on Teams, have an administrator perform it.
2. For Enterprise, retain the applicable agreement and confirm the documented requirement for express prior written consent before training. Do not infer an identical toggle or entitlement for every plan or acquired product.
3. Record provider-retention scope and exceptions separately from product history, Memory, feedback and integration storage. The published terms retain safety, abuse-review and legal-process exceptions; have the contract owner resolve any deployment-specific requirements.

#### Code Implementation

**Automation: Unverified.** The fetched security page documents Data Controls, but no training/retention policy setter or readback was established in the fetched provider/API references. Editor telemetry settings, file exclusions and memory switches do not exercise this opt-out. No guessed API or policy key is supplied.

#### Validation & Testing

An authorized administrator should re-open the intended account's page and retain redacted evidence of the selected preference and its account/plan scope. Confirm contractual and provider commitments with the account owner without sending real sensitive content as a test. No tenant preference or contract was inspected in this run.

#### Compliance Mappings

| Framework | Control | Mapping intent |
|-----------|---------|----------------|
| NIST SP 800-53 Rev. 5 | AC-21, SI-12 | Supports approved information sharing and retention |
| ISO 27001:2022 | A.5.12, A.5.23, A.8.10 | Supports classification and cloud data handling |

**Sources:** [Security and Data Controls](https://docs.devin.ai/admin/security), [Platform terms §§1.8, 3.3](https://cognition.com/legal/platform-terms-of-service) (retrieved 2026-11-05; configuration guidance, not a contract interpretation).

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

The pack separates **verification** from **enforcement**. Hub API collectors are GET-only; Terraform data sources do not enforce settings. Terraform resource examples are opt-in source artifacts, not executed changes. SSO, PAT policy, guardrails, Data Controls and secrets/trust setup require the documented administrative workflow. No GraphQL, generic SQL or invented SDK is assumed. The official CLI has cloud blueprint/secret commands; no SSO/PAT-policy/IP-list management command was established in the fetched reference. The Connect gateway has a distinct validated native configuration path. The [November census](/research/cognition-source-coverage-2026-11/) records each surface's read/write decision and uncertainty; local CLI and Outposts do not configure enterprise identity administration.

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-05 | 0.2.0 | ai-drafted | Source-first scope reconciliation; self-service SSO and additive roles corrected; Connect, Local Hands, automation/integration identities, plugin/skill permissions and migration, review, memory/dreaming, native deployment, root/override, Data Controls, CMK and attribution added; Poke/Federal boundaries. Offline checks only. | Codex (GPT-6) |
| 2026-10-30 | 0.1.0 | ai-drafted | Initial Cognition hub and Devin Cloud controls with source-backed read-only audits and opt-in Terraform examples; no live tenant validation | Codex |

## Contributing

Report inaccuracies or propose improvements through [GitHub issues](https://github.com/grcengineering/how-to-harden/issues). See the [contribution guide](/contributing/). Re-stamp the guide and changelog dates on the actual publication date.
