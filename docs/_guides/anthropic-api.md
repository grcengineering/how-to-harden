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
version: "1.0.0"
maturity: "draft"
last_updated: "2026-08-03"
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
1. Navigate to: **console.anthropic.com** → Select target workspace
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
Establish a 90-day rotation schedule for all API keys. Since API keys can only be created via the Console, rotation requires creating a new key, updating dependent services, and then disabling/archiving the old key via the Admin API.

#### Rationale
**Why This Matters:**
- Long-lived API keys increase the window of opportunity for attackers
- Keys may be accidentally exposed in logs, error messages, or code repositories
- Anthropic API keys persist after user removal — orphaned keys remain active

**Attack Prevented:** Stale credential exploitation, leaked key abuse

#### Prerequisites
- API key inventory with creation dates
- Deployment pipeline that supports key rotation (secrets manager integration)

#### ClickOps Implementation

**Step 1: Identify Keys Due for Rotation**
1. Navigate to: **console.anthropic.com** → **Settings** → **API Keys**
2. Review creation dates for each active key
3. Flag any key older than 90 days

**Step 2: Rotate**
1. Create a new key in the same workspace with the same naming convention
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

WIF complements (rather than replaces) the workspace scoping in 1.1 and the rotation discipline in 1.2: the federation rule pins the upstream identity, and the minted access token still inherits the target workspace's rate limits, billing, and OAuth scope (`workspace:developer` at launch). Use WIF anywhere a workload runs in a federable environment; keep static API keys only for environments that cannot present an OIDC JWT.

#### Rationale
**Why This Matters:**
- Removes long-lived `sk-ant-...` API keys from CI runners, container images, and secrets managers — the highest-value Anthropic credential class
- Tokens expire in minutes (default 3600s; minimum 60s), not never; SDKs refresh transparently before expiry
- Federation rule's `subject_prefix`, `audience`, `claims`, and CEL `condition` matchers bind the credential to a specific workload identity (e.g., a single GitHub repo + branch, a specific Kubernetes service account, or an EKS IRSA role)
- Audit trail attributes API calls to the federated workload identity, not just to "the API key"
- Eliminates the "key was leaked, rotation forgotten" incident class for federated workloads

**Attack Prevented:** Static API key exfiltration from CI logs, container images, secrets managers, or developer machines; long-lived credential abuse after personnel changes; lateral movement using a stolen long-lived key

**Important caveat:** WIF inherits the trust of your upstream IdP. A compromised IdP, an over-broad federation rule (e.g., `repo:my-org/*` without a branch claim), or a misconfigured `audience` value can grant broader access than intended. Pair WIF with your IdP's existing controls (workload identity binding, conditional access, audit logging) for defense in depth.

#### Prerequisites
- Organization Admin access to the Claude Console (Settings → Workload identity)
- An OIDC-capable identity provider with a reachable JWKS endpoint (or an inline JWKS document for air-gapped clusters)
- A workload that can obtain an identity token from that provider (Kubernetes projected service-account token, GitHub Actions OIDC, AWS STS web identity, GCP metadata server, Azure IMDS, etc.)
- Workspace IDs (`wrkspc_...`) for any workspaces the federated workload should act in
- `ANTHROPIC_API_KEY` and `ANTHROPIC_AUTH_TOKEN` removed from anywhere the workload runs (they sit above federation in the SDK credential precedence chain and silently shadow it)

#### ClickOps Implementation

**Step 1: Register a Federation Issuer**
1. Navigate to: **console.anthropic.com** → **Settings** → **Workload identity** → **Issuers** tab
2. Click **Create issuer** and select the appropriate preset (AWS, Google Cloud, or generic OIDC for GitHub Actions / Kubernetes / Entra ID / Okta)
3. Set **Issuer URL** to the exact `iss` claim your IdP puts in its JWTs. Decode a sample token to verify: `jq -rR 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | .iss' token`
4. Set **JWKS source** to `discovery` for any provider that serves `/.well-known/openid-configuration`. Use `explicit_url` for providers without discovery, or `inline` for air-gapped clusters
5. URLs must be `https`, port 443, public DNS (no IP literals) — except for `inline` and `explicit_url` modes where the `issuer_url` is only string-compared

**Step 2: Create a Service Account**
1. Go to: **Settings** → **Service accounts** → **Create service account**
2. Name it after the workload it represents (`inference-worker`, `ci-deploy`, `eks-prod-namespace-foo`)
3. Note the service account ID (`svac_...`)
4. Add the service account to each target workspace via that workspace's **Members** page — the federated token inherits the workspace's rate limits and usage attribution

**Step 3: Create a Federation Rule**
1. Back on **Workload identity** → **Federation rules** tab → **Create rule**
2. Select the issuer from Step 1 and the service account from Step 2
3. Configure the **Match** block as narrowly as possible:
   - **Static** matchers: `subject_prefix` (with optional trailing `*` for prefix match), exact `audience`, and a map of exact `claims` values
   - **CEL** matcher: a [CEL](https://cel.dev/) `condition` expression for complex logic (nested claims, list membership, boolean logic)
   - At least one of `subject_prefix`, `claims`, or `condition` is required — a rule that only matches `audience` is rejected
4. Set **Authorization** scope (`workspace:developer` at launch) and **Token lifetime** (60–86400 seconds; default 3600)
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
1. Navigate to: **console.anthropic.com** → **Settings** → **Workspaces**
2. Click **Create Workspace**
3. Enter workspace name following naming convention
4. Configure data residency settings if required
5. Repeat for each planned workspace

**Step 3: Archive Unused Workspaces**
1. Identify workspaces with no recent activity
2. Archive via Console (caution: this deactivates ALL API keys in the workspace and is irreversible)

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
Assign users to only the workspaces they need. Workspace roles (`workspace_user`, `workspace_developer`, `workspace_admin`, `workspace_billing`) provide granular access control within each workspace. Organization admins automatically inherit `workspace_admin` in every workspace.

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
1. Navigate to: **console.anthropic.com** → Select workspace → **Members**
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
3. Confirm removed users cannot access workspace resources

**Expected result:** Each workspace has only authorized members at appropriate role levels

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2, CC6.3 | Access provisioning; role-based access |
| **NIST 800-53** | AC-2, AC-6 | Account management; least privilege |
| **ISO 27001** | A.9.2.5 | Review of user access rights |

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

**Attack Prevented:** Data sovereignty violations, regulatory non-compliance

#### Prerequisites
- Organization Admin access
- Data residency requirements documented per team/workspace
- Legal/compliance approval for geo settings

#### ClickOps Implementation

**Step 1: Audit Current Settings**
1. Navigate to: **console.anthropic.com** → **Settings** → **Workspaces**
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
Use Anthropic's Admin API usage and cost reporting endpoints to monitor token consumption, request patterns, and spending across workspaces. The usage API supports 1-minute, 1-hour, and 1-day bucket granularity with filtering by model, workspace, API key, service tier, and geography.

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
1. Navigate to: **console.anthropic.com** → **Usage**
2. Review token usage charts, rate limit utilization, and cache rates
3. Filter by workspace, model, and time period

**Step 2: Review Cost Dashboard**
1. Navigate to: **console.anthropic.com** → **Cost**
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
1. Navigate to: **console.anthropic.com** → **Settings** → **Limits**
2. Review and configure organization-level spend limits
3. For custom limits beyond Tier 4, contact Anthropic sales

**Step 2: Set Workspace-Level Limits**
1. Navigate to the target workspace → **Settings** → **Limits**
2. Configure:
   - **Monthly spend limit:** Set below org limit (e.g., $500 for dev, $5000 for prod)
   - **Rate limits:** RPM, ITPM, OTPM per model as needed
3. Repeat for each workspace

**Time to Complete:** ~5 minutes per workspace

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="5.2" %}

#### Validation & Testing
1. Verify spend limits are set for every workspace via Console
2. Run cost anomaly detection script to validate monitoring
3. Test that requests return 429 when rate limits are exceeded (check `retry-after` header)

**Expected result:** Every workspace has explicit spend and rate limits configured

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

- [Anthropic API Documentation](https://docs.anthropic.com/en/api/)
- [Admin API Reference](https://docs.anthropic.com/en/api/administration-api)

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-08-03 | Split out of the monolithic Anthropic Claude guide as part of the multi-product platform restructure; carries the API key, workspace, data, and usage controls (formerly sections 2-5) renumbered into four sections. |

## Contributing

Found an issue or want to improve this guide? Open an issue or PR on [GitHub](https://github.com/grcengineering/how-to-harden). Keep all code in Code Packs (no inline code blocks).
