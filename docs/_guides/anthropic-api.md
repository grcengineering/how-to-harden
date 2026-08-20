---
layout: guide
title: "Claude API & Console Hardening Guide"
vendor: "Claude API"
slug: "anthropic-api"
platform: "Anthropic"
platform_slug: "anthropic"
product: "Claude API & Console"
tier: "1"
category: "AI/ML Platform"
description: "Security hardening for the Claude API and Console — API key scoping and rotation, workload identity federation, workspace segmentation, data residency and retention, and usage/spend monitoring."
version: "1.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-15"
---

## Overview

The Claude API (api.anthropic.com) and its admin Console are the developer platform surface of Anthropic — API keys, workspaces, data-residency and retention settings, and spend controls all live here. A compromised or over-scoped API key is the platform's highest-frequency risk; workspace segmentation and workload identity federation are its strongest structural mitigations.

This is a **product guide within the [Anthropic platform](/guides/anthropic-claude/)**. Organization-wide controls (SSO, roles, admin API keys, integration governance) live in the Anthropic **Common Controls** hub; Claude Code controls live in the [Claude Code guide](/guides/claude-code/).

### Intended Audience
- Platform engineers integrating the Claude API
- Security engineers governing AI API usage
- FinOps/engineering leaders managing AI spend
- GRC professionals assessing AI platform compliance

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Claude API and Console hardening: API key workspace scoping, rotation, and elimination via workload identity federation; workspace segmentation and membership; data residency and retention; usage monitoring and spend limits. Organization identity and Claude Code controls are covered by the sibling Anthropic guides.

---

## Table of Contents

1. [API Key Management](#1-api-key-management)
2. [Workspace Security](#2-workspace-security)
3. [Data Security & Privacy](#3-data-security-privacy)
4. [Monitoring & Usage Controls](#4-monitoring-usage-controls)

---

## 1. API Key Management

### 1.1 Scope API Keys to Workspaces

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3, AC-6 |
| SOC 2 | CC6.1, CC6.3 |

#### Description
Every standard API key in Anthropic Claude is scoped to a single workspace. Leverage this design by creating separate workspaces for different environments (development, staging, production) and teams, ensuring API keys cannot access resources across workspace boundaries.

#### Rationale
**Why This Matters:**
- A compromised development API key cannot access production workspaces
- Workspace-scoped keys enable granular cost tracking and rate limiting
- API keys persist when users are removed — they're scoped to the organization, not individuals
- Keys can only be created via the Console (not via API) — another security design choice

**Attack Prevented:** Lateral movement from development to production, blast radius of key compromise

#### Prerequisites
- Organization Admin or Workspace Admin access
- Workspace naming convention established

#### ClickOps Implementation

**Step 1: Create Workspace-Scoped Keys**
1. Navigate to: **platform.claude.com** → Select target workspace
2. Go to: **Settings** → **API Keys**
3. Click **Create Key**
4. Name the key descriptively: `{team}-{environment}-{purpose}` (e.g., "ml-team-prod-inference")

**Step 2: Audit Existing Keys**
1. Navigate to: **Settings** → **API Keys** (org-wide view)
2. Review each key's workspace assignment
3. Identify keys in the Default Workspace — migrate to dedicated workspaces

**Time to Complete:** ~10 minutes per key

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="2.1" %}

#### Validation & Testing
1. List all API keys via Admin API — verify each has a workspace assignment
2. Verify no unnamed keys exist
3. Test that a key scoped to Workspace A cannot be used with Workspace B resources

**Expected result:** All API keys have descriptive names and are assigned to appropriate workspaces

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC6.3 | Logical access security; role-based access |
| **NIST 800-53** | AC-3, AC-6 | Access enforcement; least privilege |
| **ISO 27001** | A.9.4.1 | Information access restriction |

---

### 1.2 Rotate API Keys Regularly

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | IA-5(1) |
| SOC 2 | CC6.1 |

#### Description
Make key lifetime bounded by default: set an **expiration at key creation** and back it with an **organization maximum expiration policy**, then run a rotation schedule for whatever non-expiring keys remain. Expiration is chosen when the key is created — presets of 3 hours, 1 day, 7 days, or 30 days, a custom duration, or **Never** — and **cannot be changed after creation**. Since API keys can only be created via the Console, rotation still means creating a new key, updating dependents, and disabling the old key via the Admin API.

> **Native expiration changed this control (verified 2026-08-15).** Earlier guidance treated rotation as purely procedural because keys never expired on their own. Keys now carry an `expires_at` timestamp (`null` for non-expiring keys), reported by the Admin API's List and Retrieve API Keys endpoints. With an org **maximum expiration policy** in place, the Console caps the selectable durations and removes **Never** entirely — making unbounded credentials impossible to mint rather than merely discouraged. Expired keys return `401 authentication_error` and cannot be reactivated; Anthropic emails the key's creator 7 days before expiry (keys with ≥14-day lifetimes) and 1 day before (≥7-day lifetimes). ([Key expiration](https://platform.claude.com/docs/en/manage-claude/authentication#key-expiration))

#### Rationale
**Why This Matters:**
- Long-lived API keys increase the window of opportunity for attackers; a leaked expiring key dies on its own, a leaked non-expiring key lives until someone notices
- Keys may be accidentally exposed in logs, error messages, or code repositories
- Anthropic API keys persist after user removal — orphaned keys remain active
- `expires_at == null` is now an auditable finding, not an unavoidable state

**Attack Prevented:** Stale credential exploitation, leaked key abuse

#### Prerequisites
- API key inventory with creation dates
- Deployment pipeline that supports key rotation (secrets manager integration)

#### ClickOps Implementation

**Step 1: Adopt Expiring Keys**
1. When creating keys at **Console → Settings → API keys**, choose the shortest expiration the workload tolerates; reserve **Never** for keys held in a secrets manager with their own rotation automation
2. If available to your organization, set the **maximum expiration policy** so the Console stops offering **Never** and caps custom durations

**Step 2: Identify Keys Due for Rotation**
1. Navigate to: **Console → Settings → API keys**
2. Review each key's expiration column; audit `expires_at` across the org via the Admin API and flag `null`
3. Flag any non-expiring key older than 90 days

**Step 3: Rotate**
1. Create a new key in the same workspace with the same naming convention — with an expiration
2. Update the dependent application/service to use the new key
3. Verify the application works with the new key
4. Disable the old key (set status to `inactive` via Admin API)
5. After a 7-day grace period, archive the old key

**Time to Complete:** ~15 minutes per key (excluding application updates)

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="2.2" %}

#### Validation & Testing
1. Run stale key audit script — zero keys older than 90 days
2. Verify disabled keys return 401 when used
3. Confirm application functionality with rotated keys

**Expected result:** No API key is older than 90 days; old keys are archived

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security over protected information assets |
| **NIST 800-53** | IA-5(1) | Authenticator management — password-based authentication |
| **ISO 27001** | A.9.3.1 | Use of secret authentication information |

---

### 1.3 Eliminate Static API Keys via Workload Identity Federation

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | IA-5(1), IA-9, AC-3 |
| SOC 2 | CC6.1 |
| CIS Controls | 5.6, 6.5 |

#### Description
Anthropic's [Workload Identity Federation (WIF)](https://platform.claude.com/docs/en/manage-claude/workload-identity-federation) lets workloads authenticate to the Claude API using short-lived OpenID Connect (OIDC) tokens issued by an identity provider you already operate — AWS IAM, Google Cloud, Microsoft Azure / Entra ID, GitHub Actions, Kubernetes service accounts, SPIFFE/SPIRE, or Okta — instead of long-lived `sk-ant-...` API keys. Your workload presents a signed JWT to `POST /v1/oauth/token` (RFC 7523 `jwt-bearer` grant); Anthropic validates it against the trust rule you configured in the Console and returns a short-lived `sk-ant-oat01-...` access token bound to a service account in your organization. There are no static secrets to mint, store in CI, rotate, or leak.

WIF complements (rather than replaces) the workspace scoping in 1.1 and the rotation discipline in 1.2: the federation rule pins the upstream identity, and the minted access token still inherits the target workspace's rate limits, billing, and OAuth scope. Use WIF anywhere a workload runs in a federable environment; keep static API keys only for environments that cannot present an OIDC JWT.

> **What changed (verified 2026-08-15).** Three updates since this control was written: **(1)** the Console now documents a **Connect workload** wizard (**Settings → Workload identity → Connect workload**) that creates the issuer, service account, and federation rule in one guided flow — with per-provider tiles, a **Verify issuer** JWKS dry-run before anything is created, and a 15-minute listener that confirms a successful end-to-end token exchange. **(2)** The OAuth scope set has grown beyond `workspace:developer`: `workspace:inference` exists as an API-manageable scope, `workspace:manage_tunnels` is set by the MCP-tunnels flow, and **`org:admin` federation rules exist** — a rule with `oauth_scope: org:admin` must target a service account whose `organization_role` is `admin`, and creating any rule beyond `workspace:developer`/`workspace:inference` requires the Console: "granting a workload organization-admin access is a deliberate human action, not something automation can bootstrap for itself." **(3)** WIF resources are now manageable programmatically via Admin API endpoints under `/v1/organizations/` (`service_accounts`, `federation_issuers`, `federation_rules`) — these endpoints **reject Admin API keys** and require an `org:admin` OAuth bearer token. ([WIF setup](https://platform.claude.com/docs/en/manage-claude/workload-identity-federation) · [WIF Admin API](https://platform.claude.com/docs/en/manage-claude/wif-admin-api))

#### Rationale
**Why This Matters:**
- Removes long-lived `sk-ant-...` API keys from CI runners, container images, and secrets managers — the highest-value Anthropic credential class
- Tokens expire in minutes, not never: the minted lifetime is the lesser of the rule's `token_lifetime_seconds` (API default 3600s) and **twice the remaining lifetime of the presented IdP JWT**, never below 60s — short-lived upstream JWTs automatically shorten Anthropic tokens; SDKs refresh on a two-tier schedule (advisory at expiry−120s, mandatory at expiry−30s)
- Federation rule's `subject_prefix`, `audience`, `claims`, and CEL `condition` matchers bind the credential to a specific workload identity (e.g., a single GitHub repo + branch, a specific Kubernetes service account, or an EKS IRSA role)
- Audit trail attributes API calls to the federated workload identity, not just to "the API key"
- Eliminates the "key was leaked, rotation forgotten" incident class for federated workloads

**Attack Prevented:** Static API key exfiltration from CI logs, container images, secrets managers, or developer machines; long-lived credential abuse after personnel changes; lateral movement using a stolen long-lived key

**Important caveat:** WIF inherits the trust of your upstream IdP. A compromised IdP, an over-broad federation rule, or a misconfigured `audience` value can grant broader access than intended. The documented concrete vector: `subject_prefix` is an exact match unless it ends in `*`, and for GitHub Actions a trailing wildcard like `repo:my-org/my-repo:*` **also matches `pull_request` runs — including runs triggered from forks** — so anyone who can open a PR against the repository could mint a token under that rule (catastrophic for an `org:admin` rule). Pin the subject to a protected branch, e.g. `repo:my-org/my-repo:ref:refs/heads/main`. Pair WIF with your IdP's existing controls (workload identity binding, conditional access, audit logging) for defense in depth.

#### Prerequisites
- Organization Admin access to the Claude Console (Settings → Workload identity)
- An OIDC-capable identity provider with a reachable JWKS endpoint (or an inline JWKS document for air-gapped clusters)
- A workload that can obtain an identity token from that provider (Kubernetes projected service-account token, GitHub Actions OIDC, AWS STS web identity, GCP metadata server, Azure IMDS, etc.)
- Workspace IDs (`wrkspc_...`) for any workspaces the federated workload should act in
- `ANTHROPIC_API_KEY` and `ANTHROPIC_AUTH_TOKEN` removed from anywhere the workload runs (they sit above federation in the SDK credential precedence chain and silently shadow it)

#### ClickOps Implementation

**Step 0 (preferred path): Use the Connect Workload Wizard**
1. Navigate to: **Console → Settings → Workload identity** → **Connect workload**
2. Pick the provider tile (GitHub Actions, AWS, Google Cloud, Microsoft Entra ID, Kubernetes, or Custom OIDC); the wizard creates the issuer, service account, and federation rule in one flow
3. Run **Verify issuer** — a JWKS-reachability dry-run — before anything is created
4. Note the wizard prefills `oauth_scope=workspace:developer` and **`token_lifetime_seconds=600`** (the API default when the field is omitted is 3600) — keep the tighter 600s unless the workload needs longer
5. Let the wizard's 15-minute listener confirm a successful token exchange end-to-end
6. Steps 1–3 below remain the manual equivalents for providers or flows the wizard doesn't cover

**Step 1: Register a Federation Issuer**
1. Navigate to: **Console** → **Settings** → **Workload identity** → **Issuers** tab
2. Click **Create issuer** and select the appropriate preset (AWS, Google Cloud, or generic OIDC for GitHub Actions / Kubernetes / Entra ID / Okta)
3. Set **Issuer URL** to the exact `iss` claim your IdP puts in its JWTs. Decode a sample token to verify: `jq -rR 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | .iss' token`
4. Set **JWKS source** to `discovery` for any provider that serves `/.well-known/openid-configuration`. Use `explicit_url` for providers without discovery, or `inline` for air-gapped clusters
5. URLs must be `https`, port 443, public DNS (no IP literals) — except for `inline` and `explicit_url` modes where the `issuer_url` is only string-compared

**Step 2: Create a Service Account**
1. Go to: **Settings** → **Service accounts** → **Create service account**
2. Name it after the workload it represents (`inference-worker`, `ci-deploy`, `eks-prod-namespace-foo`)
3. Note the service account ID (`svac_...`)
4. Add the service account to each target workspace via that workspace's **Members** page — the federated token inherits the workspace's rate limits and usage attribution
5. **Every service account is implicitly a member of the organization's default workspace** — a matched rule can mint tokens acting there with no explicit grant. Keep production keys and data out of the default workspace, or account for this when scoping rules; prefer explicit `workspace_id` on rules over `applies_to_all_workspaces: true`

**Step 3: Create a Federation Rule**
1. Back on **Workload identity** → **Federation rules** tab → **Create rule**
2. Select the issuer from Step 1 and the service account from Step 2
3. Configure the **Match** block as narrowly as possible:
   - **Static** matchers: `subject_prefix` (with optional trailing `*` for prefix match), exact `audience`, and a map of exact `claims` values
   - **CEL** matcher: a [CEL](https://cel.dev/) `condition` expression for complex logic (nested claims, list membership, boolean logic)
   - At least one of `subject_prefix`, `claims`, or `condition` is required — a rule that only matches `audience` is rejected
4. Set **Authorization** scope (`workspace:developer` for standard workloads; `org:admin` rules are Console-only, must target an `organization_role: admin` service account, and deserve the strictest possible match block) and **Token lifetime** (60–86400 seconds; API default 3600, wizard default 600)
5. Note the rule ID (`fdrl_...`); the workload passes it on every token-exchange request

**Step 4: Migrate the Workload Off the Static Key**
1. Configure WIF in parallel with the existing `ANTHROPIC_API_KEY`
2. Smoke-test with `ant auth status` from inside the workload to confirm the SDK is exchanging the federated token (not falling back to the API key)
3. **Unset `ANTHROPIC_API_KEY` everywhere** it is injected (CI secrets, container env, shell profiles). Re-confirm `ant auth status` reports the federation source as winning
4. Revoke the old API key in **Settings → API keys**

**Time to Complete:** ~30–60 minutes for first issuer + rule; ~10 minutes per additional rule

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="2.3" %}

#### Validation & Testing
1. Run the token-exchange script — confirm it returns an `sk-ant-oat01-...` token with the expected `scope` and `expires_in`
2. From inside the workload, run `ant auth status` — federation should be the winning credential source (not API key)
3. Trigger a `403` test: temporarily change the federation rule's match block to a non-matching value and confirm the exchange returns `400 invalid_grant`
4. Confirm the static-key guardrail: the API script in the pack exits non-zero if `ANTHROPIC_API_KEY` is set
5. For the GitHub Actions workflow: confirm the job succeeds with no `ANTHROPIC_API_KEY` repo secret configured
6. Audit the [authentication history](https://platform.claude.com/settings/workload-identity-federation?tab=history) page in the Console after a successful exchange — verify the issuer, rule, and matched claims are what you expect

**Expected result:** All federable workloads run with no `sk-ant-...` static keys in their environment; every Claude API call is attributable to a federation rule + service account in the audit trail

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Watch the Console's **Workload identity → Authentication history** for failed exchanges (`400 invalid_grant`) — sustained failures indicate IdP key rotation, claim drift, or an attempted misuse
- Inventory federation rules quarterly: archive any rule whose service account or issuer is no longer in active use
- Monitor for new `sk-ant-...` API keys created in workspaces that were supposed to be 100% federated — drift indicates an engineer fell back to a static key

**Maintenance schedule:**
- **Monthly:** Review the active federation rules list against current production workloads
- **Quarterly:** Review the match blocks of every rule for over-broad scope (especially CEL `condition` expressions and bare `subject_prefix` patterns ending in `*`)
- **Annually:** Tabletop exercise an IdP-compromise scenario — confirm you can disable a federation issuer in the Console and that all dependent workloads fail closed

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|---------|
| **User Experience** | None | Workloads run unchanged; SDKs handle the exchange/refresh loop |
| **System Performance** | Low | One extra HTTPS round-trip per token refresh (every ~hour by default) |
| **Maintenance Burden** | Low | Eliminates manual key rotation; only changes when IdP trust changes |
| **Rollback Difficulty** | Easy | Re-issue a static API key and revert the workload's env vars |

**Potential Issues:**
- **`ANTHROPIC_API_KEY` shadow:** A leftover key in the env wins precedence over WIF and silently keeps the workload on a static credential. Check with `ant auth status`.
- **Empty-string variables:** `ANTHROPIC_API_KEY=""` is treated as "API key path with an empty key" — unset the variable entirely, do not blank it.
- **JWKS rotation lag:** In `discovery` and `explicit_url` modes, Anthropic caches the JWKS for up to 60 seconds. If your IdP rotates and signs immediately, exchanges may briefly fail. Publish new keys 15+ minutes before first use; in `inline` mode you must update the issuer config manually.
- **Multi-workspace rules:** When a federation rule covers more than one workspace, `workspace_id` is required on every exchange (`400 invalid_request: workspace_id_required`).

**Rollback Procedure:**
1. In the Console, create a new standard API key in the target workspace
2. Inject it as `ANTHROPIC_API_KEY` in the workload's environment
3. Restart the workload — it will pick up the static key (which sits above WIF in precedence) without any code change
4. Optionally archive the federation rule

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security over protected information assets |
| **NIST 800-53** | IA-5(1) | Authenticator management — short-lived authenticators replacing static credentials |
| **NIST 800-53** | IA-9 | Service identification and authentication |
| **NIST 800-53** | AC-3 | Access enforcement |
| **ISO 27001** | A.9.4.3 | Password management system (eliminating long-lived shared credentials) |
| **CIS Controls** | 5.6 | Centralized account management |
| **CIS Controls** | 6.5 | Require MFA for administrative access (via the upstream IdP) |
| **NIST AI RMF** | GOVERN-1.4 | Authority and accountability for AI system credentials |

---

## 2. Workspace Security

### 2.1 Segment Workspaces by Environment

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-4, SC-7 |
| SOC 2 | CC6.6 |

#### Description
Create separate workspaces for development, staging, and production environments. Each workspace provides an isolated boundary for API keys, rate limits, spend limits, and data residency settings. Anthropic allows up to 100 workspaces per organization (archived workspaces do not count).

#### Rationale
**Why This Matters:**
- Workspace segmentation limits blast radius of API key compromise
- Enables different rate limits and spend caps per environment
- Data residency can be set per workspace (immutable after creation)
- Simplifies cost attribution and usage monitoring

**Attack Prevented:** Cross-environment contamination, production data exposure via development keys

#### Prerequisites
- Organization Admin access
- Environment naming convention (e.g., `engineering-prod`, `engineering-dev`, `analytics-prod`)

#### ClickOps Implementation

**Step 1: Plan Workspace Structure**
1. Define workspaces for each team and environment combination
2. Determine data residency requirements per workspace (`workspace_geo` is immutable after creation)

**Step 2: Create Workspaces**
1. Navigate to: **platform.claude.com** → **Settings** → **Workspaces**
2. Click **Create Workspace**
3. Enter workspace name following naming convention
4. Configure data residency settings if required
5. Repeat for each planned workspace

**Step 3: Archive Unused Workspaces**
1. Identify workspaces with no recent activity
2. Archive via Console (caution: this deactivates ALL API keys in the workspace and is irreversible)

> **Two special workspaces need their own handling (verified 2026-08-15).** The **Default Workspace** cannot be archived, cannot carry spend or rate limits, and its API keys, usage, and cost rows report `null` for `workspace_id` — so the hardening move is keeping **zero production keys** in it and migrating all traffic to explicit workspaces where limits apply. The auto-created **Claude Code workspace** (created when any member first signs in to Claude Code with a Console account) mints per-user API keys you cannot create manually, is the only workspace supporting per-user monthly spend limits — and **archiving it disables Claude Code sign-in through Console billing for the whole organization**, a far larger blast radius than archiving a normal workspace. ([Workspaces](https://platform.claude.com/docs/en/manage-claude/workspaces))

> **Isolation nuance for multi-cloud consumers:** prompt caches are isolated **per workspace** on the Claude API, Claude Platform on AWS, and Microsoft Foundry — but only **per organization** on Amazon Bedrock and Google Cloud. If workspace segmentation is your cache-isolation boundary, it does not hold on those two platforms.

**Time to Complete:** ~5 minutes per workspace

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="3.1" %}

#### Validation & Testing
1. List all workspaces via Admin API — verify naming convention adherence
2. Verify production workspaces have data residency configured
3. Confirm workspace count is within the 100-workspace limit

**Expected result:** Separate workspaces exist for each team/environment; naming convention followed

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | System boundaries and security measures |
| **NIST 800-53** | AC-4, SC-7 | Information flow enforcement; boundary protection |
| **ISO 27001** | A.13.1.3 | Segregation in networks |

---

### 2.2 Manage Workspace Membership

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-2, AC-6 |
| SOC 2 | CC6.2, CC6.3 |

#### Description
Assign users to only the workspaces they need. Five workspace roles provide granular access control: `workspace_user`, **Workspace Limited Developer** (create/manage API keys and use the API, but no session-tracing views or file downloads — prefer it over Workspace Developer wherever tracing and file access aren't needed), `workspace_developer`, `workspace_admin`, and `workspace_billing`. Organization admins automatically inherit `workspace_admin` in every workspace, and the Workspace Billing role cannot be manually assigned — it is inherited from the organization `billing` role, so workspace-level access reviews for org admins and billing members happen at the organization-role level.

#### Rationale
**Why This Matters:**
- Users should only access workspaces relevant to their team and function
- Workspace-level roles limit what actions a user can take within that workspace
- Regular membership audits catch stale access from role changes or departures

**Attack Prevented:** Unauthorized workspace access, privilege creep, insider threat

#### Prerequisites
- Workspace Admin or Organization Admin access
- Team-to-workspace mapping documented

#### ClickOps Implementation

**Step 1: Review Current Membership**
1. Navigate to: **platform.claude.com** → Select workspace → **Members**
2. Review each member's workspace role
3. Document any users who don't belong in this workspace

**Step 2: Adjust Membership**
1. Remove users who no longer need access
2. Downgrade workspace roles where appropriate (e.g., `workspace_admin` → `workspace_developer`)
3. Add users to workspaces they need access to

**Time to Complete:** ~10 minutes per workspace

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="3.2" %}

#### Validation & Testing
1. List workspace members via Admin API for each workspace
2. Verify no workspace has more than 2 `workspace_admin` members (excluding inherited org admins)
3. Confirm removed users can no longer sign in to workspace resources — but do **not** treat removal as key revocation: standard workspace API keys are scoped to the organization/workspace, not the person, and **keys created by a removed user keep working**. Pair every membership removal with a key rotation pass (see 1.2). The one exception is the Claude Code workspace, whose per-user keys stop working when their owner is removed.

**Expected result:** Each workspace has only authorized members at appropriate role levels, and offboarding always pairs membership removal with key rotation

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2, CC6.3 | Access provisioning; role-based access |
| **NIST 800-53** | AC-2, AC-6 | Account management; least privilege |
| **ISO 27001** | A.9.2.5 | Review of user access rights |

---

### 2.3 Adapt Controls for Claude Platform on AWS

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3, AC-6, AU-2, SC-12 |
| CIS Controls | 4.6, 8.5 |

#### Description
If your organization consumes Claude through **Claude Platform on AWS** (base URL `aws-external-anthropic.{region}.api.aws`, SigV4 service name `aws-external-anthropic`, required `anthropic-workspace-id` header on every call), most of this guide's Admin-API-driven controls do not apply as written and must be re-implemented with AWS-native mechanisms. Only the workspace endpoints (create, get, list, update, archive on `/v1/organizations/workspaces`) exist; organization members, workspace members, invites, API keys, usage reports, cost reports, and rate-limit reports are absent.

#### Rationale
**Why This Matters:**

- The §1 key-inventory/rotation validations, §2.2 member listing, and §4.1 usage/cost reporting all call Admin API endpoints that **do not exist** on this platform — running them "successfully" against the wrong org, or assuming their coverage, is a silent audit gap
- Access control moves to AWS IAM: policies target workspace ARNs (`arn:aws:aws-external-anthropic:{region}:{account-id}:workspace/{workspace-id}`) with actions in the `aws-external-anthropic` namespace, and AWS ships five managed policies (`AnthropicFullAccess`, `AnthropicReadOnlyAccess`, `AnthropicInferenceAccess`, `AnthropicLimitedAccess`, `AnthropicSelfHostedEnvironmentAccess`)
- Two hardening levers exist here that the first-party API has no equivalent for: denying the `aws-external-anthropic:CallWithBearerToken` IAM action forces SigV4-only authentication (no bearer tokens at all), and where bearer tokens are unavoidable, short-term API keys minted from AWS credentials are capped at 12 hours
- The AWS region binding **does not pin inference geography** — Anthropic (not AWS) is the inference data processor, and data may route to Anthropic's primary cloud; pinning requires `inference_geo` per request or a workspace `default_inference_geo`
- Monitoring shifts to CloudTrail, where only workspace, compliance, vault, and webhook operations are Management events; **inference, batch, file, skill, and model operations are Data events requiring explicit (paid) data-event logging** — default CloudTrail config silently misses the traffic that matters most

**Attack Prevented:** Silent audit-coverage gaps on the AWS variant, unbounded bearer-token authentication, unlogged inference activity, mistaken data-residency assumptions

#### Prerequisites

- Confirmation of which platform variant each business unit actually uses
- AWS account admin for IAM policy and CloudTrail configuration
- One-time account prerequisite: `aws iam enable-outbound-web-identity-federation` (disabled by default; its absence is the most common setup failure)

#### ClickOps Implementation

**Step 1: Map This Guide's Controls to the AWS Variant**

1. For each Admin-API-driven control in this guide, record its AWS substitute: membership → IAM policies on workspace ARNs; key inventory → short-term keys + `CallWithBearerToken` governance; usage/cost → Console dashboards + CloudTrail

**Step 2: Force SigV4 Where Possible**

1. Deny `aws-external-anthropic:CallWithBearerToken` for all principals that do not strictly need bearer tokens
2. Where bearer tokens are unavoidable (gateways, serverless), mint short-term keys via AWS's token-generator libraries — lifetime defaults to 12 hours, capped at the lesser of the requested duration, the AWS credentials' expiry, and 12 hours

**Step 3: Enable Data-Event Logging**

1. In CloudTrail, add data-event logging for the `aws-external-anthropic` service so inference, batch, file, skill, and model operations are captured
2. Index on `x-amzn-requestid` for CloudTrail correlation

**Step 4: Pin Inference Geography Deliberately**

1. Set `default_inference_geo` on residency-sensitive workspaces (supported geos: `us` — with a 1.1x pricing multiplier — and `global`), or pass `inference_geo` per request
2. Note ZDR is opt-in and Anthropic's HIPAA-ready program is **not available** on this variant

**Time to Complete:** ~2–4 hours initial mapping and IAM work

#### Validation & Testing
1. Attempt a bearer-token call from a principal denied `CallWithBearerToken` — must fail; SigV4 from the same principal must succeed
2. Run an inference call and confirm it appears in CloudTrail as a Data event
3. Confirm every workspace serving residency-sensitive workloads carries `default_inference_geo`

**Expected result:** Every control in this guide has an explicit AWS-variant disposition; no bearer tokens outside approved principals; inference activity visible in CloudTrail. ([Claude Platform on AWS](https://platform.claude.com/docs/en/build-with-claude/claude-platform-on-aws))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC7.2 | Access security; monitoring |
| **NIST 800-53** | AC-6 | Least privilege |
| **NIST 800-53** | AU-2 | Event logging |
| **ISO 27001** | A.8.15 | Logging |

---

## 3. Data Security & Privacy

### 3.1 Enforce Data Residency Restrictions

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SC-7, SA-9(5) |
| SOC 2 | CC6.6, P6.1 |

#### Description
Configure data residency at the workspace level to control where Claude processes inference requests. The `workspace_geo` setting (immutable after creation) controls data storage location. `default_inference_geo` and `allowed_inference_geos` control where requests are processed. Available regions include `us` and `global`.

#### Rationale
**Why This Matters:**
- Regulatory requirements (GDPR, data sovereignty laws) may mandate processing within specific regions
- `workspace_geo` cannot be changed after workspace creation — plan carefully
- The `inference_geo` parameter can also be set per-request by API callers, but `allowed_inference_geos` restricts what values are permitted
- **Model floor (verified 2026-08-15):** the per-request `inference_geo` parameter is supported on Claude 4.6 and later models — requests carrying it on Claude Opus 4.5, Sonnet 4.5, or Haiku 4.5 return a `400` error, and models released before February 2026 report `not_available` in usage reports for this dimension. Residency-restricted workspaces must therefore also pin allowed model versions

**Attack Prevented:** Data sovereignty violations, regulatory non-compliance

#### Prerequisites
- Organization Admin access
- Data residency requirements documented per team/workspace
- Legal/compliance approval for geo settings

#### ClickOps Implementation

**Step 1: Audit Current Settings**
1. Navigate to: **platform.claude.com** → **Settings** → **Workspaces**
2. Review each workspace's data residency configuration
3. Note any workspaces without explicit geo settings

**Step 2: Configure New Workspaces with Correct Geo**
1. When creating new workspaces, select the appropriate `workspace_geo`
2. This setting is **immutable** — double-check before confirming

**Step 3: Restrict Inference Geos**
1. For regulated workspaces, set `allowed_inference_geos` to `["us"]` only
2. Set `default_inference_geo` to `"us"` to ensure all requests default to US processing

**Time to Complete:** ~5 minutes per workspace

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="4.1" %}

#### Validation & Testing
1. List all workspaces via Admin API — verify `workspace_geo` and `allowed_inference_geos`
2. Attempt a request with `inference_geo: "global"` against a US-restricted workspace — should fail
3. Verify new workspaces are created with correct geo from the start

**Expected result:** Regulated workspaces have explicit data residency configuration; inference geo restrictions enforced

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6, P6.1 | System boundaries; privacy — consent and choice |
| **NIST 800-53** | SC-7, SA-9(5) | Boundary protection; processing, storage, and service location |
| **ISO 27001** | A.18.1.4 | Privacy and protection of personally identifiable information |

---

### 3.2 Configure Data Retention Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SI-12 |
| SOC 2 | P4.1 |

#### Description
Understand and configure Anthropic's data retention policies. By default, API inputs and outputs are retained for up to 30 days and are not used for model training. Enterprise customers can negotiate custom retention periods or Zero Data Retention (ZDR), where no inputs or outputs are stored after the response is delivered.

#### Rationale
**Why This Matters:**
- Sensitive prompts containing PII, financial data, or intellectual property are retained for 30 days by default
- ZDR eliminates server-side storage of prompts and completions entirely
- Custom retention periods allow organizations to balance compliance needs with debugging capabilities

**Attack Prevented:** Post-breach data exposure, regulatory non-compliance for data minimization

#### Prerequisites
- Claude Enterprise plan (for custom retention or ZDR)
- Data classification policy for content sent to Claude
- Legal review of Anthropic's data handling agreement

#### ClickOps Implementation

**Step 1: Review Default Retention**
1. Review Anthropic's usage policy at anthropic.com/policies/usage-policy
2. Confirm your plan's default retention (API: 30 days, not used for training)

**Step 2: Request Custom Retention (Enterprise)**
1. Contact your Anthropic account representative
2. Specify desired retention period or request ZDR
3. Obtain written confirmation of retention configuration

**Step 3: Implement Data Handling Controls**
1. Establish guidelines for what data types may be sent to Claude
2. Implement client-side PII redaction before sending sensitive prompts
3. Use workspace segmentation to isolate sensitive vs. non-sensitive workloads

**Time to Complete:** ~30 minutes (policy review) + vendor coordination for custom retention

#### Validation & Testing
1. Confirm retention period with Anthropic account team (Enterprise)
2. Verify client-side PII redaction is in place for sensitive workloads
3. Review data classification guidelines with engineering team

**Expected result:** Data retention policy documented and aligned with organizational requirements

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | P4.1 | Privacy — data minimization |
| **NIST 800-53** | SI-12 | Information management and retention |
| **ISO 27001** | A.8.10 | Information deletion |

---

## 4. Monitoring & Usage Controls

### 4.1 Monitor API Usage and Costs

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AU-6, SI-4 |
| SOC 2 | CC7.2 |

#### Description
Use Anthropic's Admin API usage and cost reporting endpoints to monitor token consumption, request patterns, and spending across workspaces. The usage API supports 1-minute, 1-hour, and 1-day bucket granularity with filtering and grouping by API key, workspace, model, service tier, context window (e.g. `context_window[]=0-200k`), data residency (`inference_geo`: `global`, `us`, `not_available`), and — behind the `fast-mode-2026-02-01` beta header — speed (`standard`/`fast`).

> **Scope and mechanics (verified 2026-08-15):** this Admin API applies to Claude Console organizations with an `sk-ant-admin01-` key. Claude Enterprise (claude.ai) orgs don't appear in Console and carry no Admin API keys — their usage/cost reporting is the Claude Enterprise Analytics API with an Analytics key; Claude Platform on AWS has no programmatic usage/cost endpoints at all (see 2.3). Bucket caps per request: 1m = 60 default/1,440 max, 1h = 24/168, 1d = 7/31, paginated via `has_more`/`next_page`; polling once per minute is the supported sustained cadence. The cost endpoint is daily-only (`1d`), reports decimal-string cents USD, **excludes Priority Tier** (track via the usage endpoint's `service_tier` = `priority`), and is the only place code-execution costs appear. Models released before February 2026 always report `not_available` for `inference_geo` — those rows are not residency violations. For per-user Claude Code cost attribution, Anthropic's sanctioned path is the Claude Code Analytics API, not per-key usage breakdowns. Every Claude API response also carries an `anthropic-workspace-id` header — log it to attribute traffic and to catch keys running in the wrong workspace (absent on Admin API calls and pre-auth failures like 401s).

#### Rationale
**Why This Matters:**
- Unusual usage spikes may indicate compromised API keys
- Cost monitoring prevents unexpected bills from runaway applications
- Per-workspace usage data enables accurate cost attribution to teams
- Data is available within ~5 minutes of request completion

**Attack Prevented:** API key abuse, cryptocurrency mining via API, unauthorized bulk data extraction

#### Prerequisites
- Admin API key provisioned
- Monitoring infrastructure (Datadog, Grafana, etc.) or cron job for regular checks

#### ClickOps Implementation

**Step 1: Review Usage Dashboard**
1. Navigate to: **platform.claude.com** → **Usage**
2. Review token usage charts, rate limit utilization, and cache rates
3. Filter by workspace, model, and time period

**Step 2: Review Cost Dashboard**
1. Navigate to: **platform.claude.com** → **Cost**
2. Review cost breakdown by workspace and model
3. Identify any unexpected cost increases

**Step 3: Configure Observability Integration**
1. Integrate with supported platforms: CloudZero, Datadog, Grafana Cloud, Honeycomb, or Vantage
2. Set up alerts for anomalous usage patterns

**Time to Complete:** ~15 minutes (dashboard review) + integration setup time

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="5.1" %}

#### Validation & Testing
1. Run usage report API script — verify data returns for all active workspaces
2. Run cost report API script — verify cost data is accurate
3. Confirm observability integration is receiving data

**Expected result:** Usage and cost data is monitored regularly with alerts for anomalies

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | System monitoring |
| **NIST 800-53** | AU-6, SI-4 | Audit record review; system monitoring |
| **ISO 27001** | A.12.4.1 | Event logging |

---

### 4.2 Configure Spend Limits per Workspace

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SA-9, SI-4 |
| SOC 2 | CC7.2, CC6.8 |

#### Description
Set per-workspace spend limits and rate limits to prevent cost overruns and abuse. Workspace limits cannot exceed organization-level limits. Configure both monthly spend caps and per-model rate limits (requests per minute, input/output tokens per minute).

#### Rationale
**Why This Matters:**
- A compromised API key without spend limits can generate unlimited costs
- Rate limits prevent individual workspaces from consuming the organization's entire quota
- Workspace-level limits enable differentiated resource allocation (e.g., production gets higher limits)

**Attack Prevented:** Denial-of-wallet attacks, runaway cost from compromised keys or bugs

#### Prerequisites
- Organization Admin or Workspace Admin access
- Budget allocation per workspace/team

#### ClickOps Implementation

**Step 1: Set Organization-Level Limits**
1. Navigate to: **platform.claude.com** → **Settings** → **Limits**
2. Review and configure organization-level spend limits
3. For custom limits beyond Tier 4, contact Anthropic sales

**Step 2: Set Workspace-Level Limits**
1. Navigate to the target workspace: limits are split across two tabs — the **Rate limits** tab (per model tier: requests/min, input tokens, output tokens) and the **Spend limits** tab (monthly cap plus threshold alerts)
2. Set the monthly spend cap below the org limit (e.g., $500 for dev, $5000 for prod) and rate limits as needed
3. Repeat for each workspace — except the **Default Workspace**, which cannot carry limits at all (the mitigation is keeping production keys out of it, per 2.1); unset workspace limits inherit the organization's limits, and org-wide limits always apply even when per-workspace limits sum higher

**Time to Complete:** ~5 minutes per workspace

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="5.2" %}

#### Validation & Testing
1. Verify spend limits are set for every workspace via Console
2. Run cost anomaly detection script to validate monitoring
3. Test that requests return 429 when rate limits are exceeded (check `retry-after` header)
4. Audit configured limits programmatically with the read-only **Rate Limits API** (verified 2026-08-15): `GET /v1/organizations/rate_limits` returns org-level limits grouped by `group_type` (`model_group`, `batch`, `token_count`, `files`, `skills`, `web_search`) with `limiter` `{type, value}` pairs; `GET /v1/organizations/workspaces/{workspace_id}/rate_limits` returns only workspace **overrides** with org-limit comparison values — a workspace absent from the response has no overrides. The API cannot write limits (Console only). ([Rate Limits API](https://platform.claude.com/docs/en/manage-claude/rate-limits-api))

**Expected result:** Every non-default workspace has explicit spend and rate limits configured, and the configuration is auditable in code rather than by Console screenshot

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2, CC6.8 | System monitoring; change management |
| **NIST 800-53** | SA-9, SI-4 | External system services; system monitoring |
| **ISO 27001** | A.12.1.3 | Capacity management |

---


## Compliance Quick Reference

Per-control compliance mappings appear inside each control above. For organization-level SOC 2 / NIST / ISO mappings spanning the Anthropic platform, see the [Anthropic Common Controls hub](/guides/anthropic-claude/#compliance-quick-reference).

---

## Appendix A: References

See the [Anthropic platform hub references](/guides/anthropic-claude/#appendix-b-references) for the shared reference list; key API/Console sources:

- [Claude API Documentation](https://platform.claude.com/docs/en/api/overview)
- [Admin API Reference](https://platform.claude.com/docs/en/api/admin)

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.1.0 | 2026-08-15 | Admin API currency pass. §1.2 rewritten around native key expiration: creation-time presets/custom/Never, the organization maximum-expiration policy that removes Never entirely, `expires_at` auditing (null = finding), 401 at expiry, creator warning emails. §1.3 WIF updated: the Connect-workload wizard as the documented setup path (per-provider tiles, Verify-issuer JWKS dry-run, 15-minute exchange listener, 600s prefill vs the 3600s API default), the grown OAuth scope set (`workspace:inference`, `workspace:manage_tunnels`, Console-only `org:admin` rules targeting admin-role service accounts), the fork-PR wildcard-subject attack with the protected-branch pin, the 2×-remaining-IdP-JWT token-lifetime cap, implicit default-workspace service-account membership, and the OAuth-only WIF Admin API endpoints. §2.1 gains the special-workspace handling (Default Workspace cannot carry limits and reports null `workspace_id`; archiving the auto-created Claude Code workspace disables org-wide Claude Code sign-in) and the prompt-cache isolation platform split. §2.2 corrected: five workspace roles including Workspace Limited Developer, billing-role inheritance, and the offboarding fix — standard workspace keys survive member removal and demand a rotation pass. NEW §2.3: Claude Platform on AWS variant (workspace-endpoints-only Admin API, IAM policies on workspace ARNs, `CallWithBearerToken` denial forcing SigV4, 12-hour short-term keys, CloudTrail data-event logging gap, AWS region does not pin inference geography). §3.1: `inference_geo` model floor (Claude 4.6+; 400 on 4.5-generation). §4.1: expanded dimensions (context window, speed beta, `inference_geo` with the pre-Feb-2026 `not_available` caveat), bucket caps and pagination, cost-endpoint mechanics (daily-only, cents strings, Priority Tier excluded, code-execution only here), and the `anthropic-workspace-id` response header. §4.2: split Rate-limits/Spend-limits tabs and read-only Rate Limits API validation. All ClickOps hosts canonicalized to platform.claude.com. |
| 1.0.0 | 2026-08-03 | Split out of the monolithic Anthropic Claude guide as part of the multi-product platform restructure; carries the API key, workspace, data, and usage controls (formerly sections 2-5) renumbered into four sections. |

## Contributing

Found an issue or want to improve this guide? Open an issue or PR on [GitHub](https://github.com/grcengineering/how-to-harden). Keep all code in Code Packs (no inline code blocks).
