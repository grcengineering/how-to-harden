---
layout: guide
title: "Ona Hardening Guide"
vendor: "Ona"
slug: "ona"
tier: "2"
category: "AI/ML Platform"
description: "Security hardening for Ona (formerly Gitpod) — the cloud platform for autonomous AI software-engineering agents: SSO/SCIM identity, agent guardrails (Veto, command deny list, MCP), environment and network policy, secrets, self-hosted runners, and audit logging."
version: "0.2.1"
maturity: ["ai-drafted", "ai-validated"]
last_updated: "2026-08-20"
---

## Overview

Ona (formerly Gitpod) runs autonomous AI software-engineering agents in cloud development environments with access to source code, credentials, package registries, and outbound network. That capability profile makes it a first-class security surface: an over-permissioned agent, a poisoned dev environment, or a leaked scoped credential can read or exfiltrate an entire codebase, and the platform's own history of session/origin/token-boundary vulnerabilities (five Gitpod-era CVEs, one critical workspace-takeover) shows the blast radius is real.

This guide hardens Ona's admin surfaces: identity (OIDC SSO, SCIM, roles), agent guardrails (the kernel-level Veto policy engine, command deny lists, MCP governance), environment and network policy, secrets scoping, deployment architecture, and audit logging.

> **No third-party benchmark exists yet.** Cloud development environments and coding agents are not covered by CIS Benchmarks, DISA STIGs, or CISA SCuBA baselines as of this writing. Controls here are derived from Ona's official documentation (the authoritative source for what settings exist) and grounded in the platform's disclosed vulnerability history. Compliance mappings use control-family catalogs (NIST 800-53, SOC 2, CIS Controls v8, NIST AI RMF), which map and justify controls but do not originate configuration steps.

### Intended Audience
- Security engineers governing AI coding-agent platforms
- Platform/DevSecOps teams administering an Ona organization
- GRC professionals assessing autonomous-agent risk
- Incident responders covering cloud-dev-environment compromise

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Ona organization administration: OIDC SSO and SCIM provisioning, roles and groups, service-account and token hygiene, the Veto executable-policy engine and agent command deny lists, MCP and SCM-tool governance, automation limits, port-admission and in-environment browser policy, environment lifetime/retention, dotfiles supply-chain risk, secrets scoping, OIDC workload identity, repository-access scoping, self-hosted runners, and audit logging. Model-behavior configuration (prompts, agent reasoning) is out of scope.

> **How the console is laid out (verified live, 2026-08-19).** Ona's own docs give inconsistent locations for the policy surface, so every navigation path in this guide was read off the live console rather than transcribed from the docs. The console served at `app.gitpod.io`; **Settings** is one page with a sidebar grouped as **Organization** (General, Terms of Service, Members, Integrations, Billing, Cost & Budgets), **Infrastructure** (All Environments, Runners, Secrets, Policies, Security), **Agents** (Policies, Skills), and **Login & Identity** (Login Configuration, SCIM, OIDC Tokens); personal settings live under the user menu → **Account**. Many controls below are Enterprise-gated (the page renders, the toggle is locked behind "Upgrade") — the paths still hold.
>
> **Hosts and names.** `app.ona.com` and `app.gitpod.io` are both live: `https://app.ona.com/api` answers **308** to `https://app.gitpod.io/api` (and `curl -L` drops the bearer token on that cross-host hop), the OIDC issuer (`iss`) is `https://app.gitpod.io`, and the API namespace remains `gitpod.v1.*` — none of that is legacy debris, so do not "correct" it. Audit-log retention and the LLM training-use posture remain undocumented — treat them as open questions with your Ona account team.

---

## Table of Contents

1. [Identity & Access Controls](#1-identity--access-controls)
2. [Agent Governance & Guardrails](#2-agent-governance--guardrails)
3. [Environment & Network Security](#3-environment--network-security)
4. [Data & Secrets](#4-data--secrets)
5. [Deployment Architecture](#5-deployment-architecture)
6. [Monitoring & Detection](#6-monitoring--detection)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Identity & Access Controls

### 1.1 Enforce SSO with Domain Verification

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.7, 12.5 |
| NIST 800-53 | IA-2, IA-8 |
| SOC 2 | CC6.1 |

#### Description
Configure OIDC single sign-on (Ona supports OIDC only — no SAML is documented) against your identity provider (Okta, Google, GitLab, Entra ID, Cognito, or PingFederate), verify your email domain, and use claims expressions (CEL) for conditional access. Enterprise plan only.

#### Rationale
**Why This Matters:**
- Federated sign-in brings Ona under your IdP's MFA, conditional access, and lifecycle controls instead of standalone accounts
- Ona's disclosed CVEs are dominated by session/token-boundary bugs reachable from a single malicious link — centralizing authentication shrinks the standing credential surface those attacks target
- CEL claims rules let you gate login on verified email, domain, or group membership at the moment of authentication

**Attack Prevented:** Credential-based account takeover, unmanaged accounts surviving offboarding

#### Prerequisites
- Enterprise plan
- OIDC application registered in your IdP
- DNS access to publish a domain-verification TXT record

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path observed live" date="2026-08-19" %}

**Step 1: Verify Your Email Domain**
1. Publish the DNS TXT record Ona provides for your domain — "Sign in with SSO" does not appear on the login screen until the domain is verified.

**Step 2: Configure the OIDC Provider**
1. Navigate to: **Settings** → **Login & Identity** → **Login Configuration** — the **Login domains** section (**Add domain**) is where the email domain is verified, and **Single Sign On** (**New SSO**) is where the provider is added
2. Add your OIDC provider (issuer URL, client ID, client secret) and assign the verified email domain(s) to it
3. Optionally add a **claims expression (CEL)** for conditional access (e.g., `claims.email_verified && claims.email.endsWith("@example.com")`)

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="ona" section="1.1" %}

#### Validation & Testing
1. A user on the verified domain is redirected to your IdP at login
2. A CEL rule denies a test principal that fails its condition
3. **Note the platform limitation:** Ona documents no org-wide SSO-enforcement toggle, and a built-in provider (Google/GitHub) can stay active alongside your IdP — pair this control with SCIM account restriction ([1.2](#12-enforce-scim-provisioning-and-restrict-account-creation)) to close the non-SSO join path.

**Expected result:** Domain-verified OIDC sign-in active. ([SSO overview](https://ona.com/docs/ona/sso/overview.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-2 | Identification and authentication |

---

### 1.2 Enforce SCIM Provisioning and Restrict Account Creation

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3, 6.2 |
| NIST 800-53 | AC-2 |
| SOC 2 | CC6.2 |

#### Description
Enable SCIM provisioning against your IdP, then enable the **Restrict account creation to SCIM** policy so SSO users who were not SCIM-provisioned cannot join the organization. Because Ona cannot mandate SSO org-wide (see 1.1), this policy is what actually closes the uncontrolled-join path.

#### Rationale
**Why This Matters:**
- SCIM automatically deprovisions members when they leave the IdP — without it, departed engineers keep agent and source-code access
- The "restrict account creation to SCIM" toggle blocks the gap left by SSO being non-mandatory: a valid SSO login alone can otherwise create an org membership
- Directory-driven membership keeps agent-capable accounts tied to employment status

**Attack Prevented:** Orphaned accounts with standing code/agent access, uncontrolled organization joins

#### Prerequisites
- An active SSO provider (1.1) — the SCIM restriction toggle stays disabled until SCIM is configured and enabled

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path corrected against the live console" date="2026-08-19" %}

**Step 1: Configure SCIM**
1. Navigate to: **Settings** → **Login & Identity** → **SCIM** → **Configuration** → **Set up SCIM**
2. Generate the SCIM endpoint and bearer token. **The token is shown once and is unrecoverable** — store it in your secrets manager immediately.
3. Configure the SCIM integration in your IdP with the endpoint and token. (An SCIM configuration created through the API is stored disabled until `UpdateSCIMConfiguration` sets `enabled: true`.)

**Step 2: Restrict Account Creation**
1. On the same **SCIM** page, enable **Require SCIM provisioning** — "Only SCIM-provisioned members can access this organization. SSO accounts without SCIM provisioning are blocked." (API/Terraform name: `restrictAccountCreationToScim`)

**Time to Complete:** ~45 minutes

#### Code Implementation{% include status-mark.html status="ai-validated" evidence="API audit pack executed against a live tenant" date="2026-08-19" %}

{% include pack-code.html vendor="ona" section="1.2" %}

#### Validation & Testing
1. Remove a test user from the IdP and confirm deprovisioning in Ona
2. Attempt to join with an SSO account not present in SCIM — the join must be blocked

**Expected result:** Membership mirrors the directory; non-SCIM SSO joins refused. ([SCIM overview](https://ona.com/docs/ona/scim/overview.md) · [SCIM account restriction](https://ona.com/docs/ona/organizations/policies/scim-account-restriction.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2 | User registration and deregistration |
| **NIST 800-53** | AC-2 | Account management |

---

### 1.3 Apply Least-Privilege Organization Roles and Groups

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-6(1) |
| SOC 2 | CC6.3 |

#### Description
Use Ona's delegated organization roles (Runners Admin, Projects Admin, Groups Admin, Automations Admin, plus read-only Insights Viewer, Audit Log Reader, and Billing Viewer) and groups to grant the minimum needed, rather than making everyone a full organization admin.

#### Rationale
**Why This Matters:**
- Delegated roles let a runner operator manage runners without also controlling identity, policy, and secrets
- Group permissions are a union with highest-level-wins, so an over-broad group silently elevates everyone in it — audit membership deliberately
- Read-only roles (Audit Log Reader, Insights Viewer) enable oversight without granting change rights

**Attack Prevented:** Privilege sprawl enabling org-wide policy, secret, or runner tampering from any one account

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path observed live" date="2026-08-19" %}

**Step 1: Assign Delegated Roles**
1. Navigate to: **Settings** → **Organization** → **Members** → **Groups** tab (delegated roles are Enterprise-tier)
2. Toggle the specific role columns per group — grant the narrowest admin role that covers the duty. Under the hood these are **group role assignments over the organization** (`RESOURCE_ROLE_ORG_RUNNERS_ADMIN`, `…_PROJECTS_ADMIN`, `…_GROUPS_ADMIN`, `…_AUTOMATIONS_ADMIN`, `…_AUDIT_LOG_READER`, `…_BILLING_VIEWER`, `…_INSIGHTS_VIEWER`); the member-level role itself is only Admin or Member. Two roles worth knowing that the console list omits: `RESOURCE_ROLE_ORG_SECURITY_ADMIN` and `RESOURCE_ROLE_SECURITY_POLICY_ADMIN`/`_VIEWER` — the least-privilege way to delegate the Veto and port policies ([2.1](#21-enforce-an-executable-policy-with-veto), [3.1](#31-restrict-port-admission-levels)) without full org admin.

**Step 2: Audit Group Unions**
1. Review each group's effective permissions, remembering the highest level across a user's groups wins; the `derivedFromOrgRole` field on a role assignment separates inherited grants from ad-hoc shares
2. Keep full organization admin to a small named set

**Time to Complete:** ~30 minutes

#### Code Implementation{% include status-mark.html status="ai-validated" evidence="API audit pack executed against a live tenant" date="2026-08-19" %}

{% include pack-code.html vendor="ona" section="1.3" %}

#### Validation & Testing
1. A Runners Admin cannot change identity or policy settings
2. An Audit Log Reader can read logs but cannot alter configuration

**Expected result:** Capability follows role; admin count minimized. ([Organization roles](https://ona.com/docs/ona/organizations/organization-roles.md) · [Groups](https://ona.com/docs/ona/organizations/groups.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.3 | Role-based access |
| **NIST 800-53** | AC-6(1) | Least privilege |

---

### 1.4 Harden Service Accounts and Personal Access Tokens

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 16.9 |
| NIST 800-53 | IA-5, AC-2 |
| SOC 2 | CC6.1 |

#### Description
Constrain machine credentials: never issue service-account tokens with **indefinite** validity, prefer the shortest workable token lifetime, and keep personal access tokens read-only unless write is required. Token scope is immutable after creation, so scope tightly up front.

#### Rationale
**Why This Matters:**
- Service-account tokens can be set to indefinite validity — a leaked indefinite token is a permanent foothold that outlives every rotation policy
- PAT actions are logged with the token ID, so short-lived, narrowly-scoped tokens give both containment and attribution
- The Bitbucket-OAuth token-leak CVE (CVE-2025-55750) shows token exposure is a live risk on this platform — minimizing token lifetime and scope caps the damage

**Attack Prevented:** Persistent access via leaked long-lived tokens, over-scoped credential abuse

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path observed live" date="2026-08-19" %}

**Step 1: Constrain Service Accounts**
1. Navigate to: **Settings** → **Organization** → **Members** → **Service Accounts** tab (Core tier and above)
2. Set token validity to the shortest that works (30/60/90 days or 1 year) — **never "no expiry"**. The API contract itself requires `validUntil` on the service account; only the *token* can be minted without an expiry, so audit `expiresAt` on every token.
3. Service-account tokens can start automations and perform read (GET/LIST) API operations; Ona documents no read/write access level for them — keep automations to what a service account can do and use PATs (below) where write access must be scoped.

**Step 2: Govern Personal Access Tokens**
1. In the user menu → **Account** → **Personal access tokens** → **New token** (or `app.ona.com/settings/personal-access-tokens`): expiry is **30 / 60 / 90 days** and access is **Read-only** or **Read & Write Access** — the form defaults to Read & Write, so choose Read-only deliberately unless write is justified
2. Because access level is immutable after creation, review and re-issue rather than widening an existing token; a read-only token is enforced at the data layer ("Mutations will be denied")

**Time to Complete:** ~30 minutes plus recurring review

#### Code Implementation{% include status-mark.html status="ai-validated" evidence="API audit pack executed against a live tenant" date="2026-08-19" %}

{% include pack-code.html vendor="ona" section="1.4" %}

#### Validation & Testing
1. No service account carries an indefinite token
2. Token IDs appear in audit logs for a test action ([6.1](#61-enable-audit-logging-and-siem-streaming))

**Expected result:** Short-lived, least-privilege machine credentials with attribution. ([Service accounts](https://ona.com/docs/ona/organizations/service-accounts.md) · [Personal access tokens](https://ona.com/docs/ona/integrations/personal-access-token.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-5 | Authenticator management |

---

### 1.5 Control Member Invitations and Remove Domain Auto-Admit

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.1, 6.2 |
| NIST 800-53 | AC-2 |
| SOC 2 | CC6.2 |

#### Description
Review the organization's invitation surface: the shareable invite link, email invites, and especially the email-domain whitelist that auto-admits any matching address. In directory-driven orgs, disable the domain auto-admit and rely on SCIM ([1.2](#12-enforce-scim-provisioning-and-restrict-account-creation)).

#### Rationale
**Why This Matters:**
- An email-domain whitelist auto-admits anyone with a matching address — including a compromised or contractor account you never intended to grant agent access
- A leaked shareable invite link admits strangers until it is reset
- Membership should be driven by the directory, not by domain-string matching

**Attack Prevented:** Unauthorized organization joins via domain matching or leaked invite links

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path corrected against the live console" date="2026-08-19" %}

**Step 1: Remove Domain Auto-Admit**
1. The domain allow-list is the organization's `inviteDomains` (API: `UpdateOrganization` with `inviteDomains: {domains: []}`; readable via `GetOrganization`). Where your tier exposes it in the console (**Settings** → **Organization** → **Members**), clear every entry so matching addresses no longer auto-join; the API pack below audits and clears it on any tier.

**Step 2: Control the Invite Link**
1. Navigate to: **Settings** → **Login & Identity** → **Login Configuration** → **Organization login link** — this is the shareable join link; regenerate it if it may have leaked (API: `CreateOrganizationInvite` issues a new id, killing the old link). Email invitations are console-only (no public API method); prefer SCIM ([1.2](#12-enforce-scim-provisioning-and-restrict-account-creation)).

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="ona" section="1.5" %}

#### Validation & Testing
1. A new address on your domain is not auto-admitted after the whitelist is removed
2. The prior invite link no longer grants access after reset

**Expected result:** Joins are explicit or directory-driven. ([Manage members](https://ona.com/docs/ona/organizations/manage-members.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2 | User registration |
| **NIST 800-53** | AC-2 | Account management |

---

## 2. Agent Governance & Guardrails

### 2.1 Enforce an Executable Policy with Veto

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5, 2.7 |
| NIST 800-53 | CM-7, SI-3 |
| NIST AI RMF | MANAGE-2.3 |

#### Description
Use Veto — Ona's Linux Security Module that "runs as a Linux Security Module (LSM) inside the environment kernel, below the agent"; per Ona, "the LLM cannot bypass or disable it" and the agent cannot unload it, modify its configuration, or observe whether an action was flagged — to define an executable policy. Veto Exec rules match by absolute path (`/usr/bin/curl`) or bare name (`npx`), resolve to SHA-256 content identity (rename- and symlink-resistant), and block execution AND read/copy/modify of the target.

#### Rationale
**Why This Matters:**
- Guardrails defined in the agent's own context can be reasoned around; a kernel LSM below the agent cannot be evaded by the agent
- SHA-256 content identity defeats the rename/symlink tricks an agent (or injected instruction) would use to dodge a name-based block
- Blocking read/copy/modify — not just exec — stops an agent from staging a renamed copy of a blocked tool

**Attack Prevented:** Malicious or prompt-injected agent executing exfiltration/attack tooling (`curl`, `scp`, package installers) inside the environment

#### Prerequisites
- Understanding of which executables agents legitimately need (over-blocking breaks builds)

#### ClickOps Implementation

**Step 1: Define Veto Executable Rules**
1. Navigate to: **Settings** → **Infrastructure** → **Security** (Enterprise tier — on lower tiers the page shows only the security-agents section)
2. Add rules by absolute path or bare name (`.`/`..`/relative paths are rejected); leave **Block** unchecked to audit a rule or check it to block execution (`EFFECT_AUDIT` / `EFFECT_BLOCK` in the YAML/API)
3. Leave the default effect at allow (`defaultEffect` omitted or `EFFECT_ALLOW`) and block specific high-risk binaries; start in audit, then move to block once the audit trail is clean
4. Ona runtime binaries are on a server-populated **safelist** (`vetoExecPolicy.safelist`, output-only) and cannot be blocked — a rule naming one silently does not take effect

**Automation surface:** manageable as code. CLI: `ona organization security-policy init policy.yaml --validate-only` → `create policy.yaml -o yaml` → `set-default <security-policy-id>` (a created policy is inert until assigned as the org default; `set-default --clear` removes *every* control in the policy, and running environments keep the policy from their last start). API: `SecurityService/CreateSecurityPolicy` + `OrganizationService/UpdateOrganizationPolicies.securityPolicyId`. Terraform: `ona_security_policy` + `ona_organization_policies.security_policy_id`.

**Time to Complete:** ~1 hour plus an audit-mode observation window

#### Code Implementation

{% include pack-code.html vendor="ona" section="2.1" %}

#### Validation & Testing
1. In audit mode, confirm the intended binaries appear as `AUDIT_LOG_ENTRY_KIND_ENVIRONMENT_VETO` audit events ([6.1](#61-enable-audit-logging-and-siem-streaming)) — Veto Exec enforcement entries are in preview and appear only for organizations where that preview is enabled
2. In block mode, an agent attempt to run a blocked binary fails and is logged
3. A renamed copy of a blocked binary is still blocked (content-identity check)

**Expected result:** Kernel-enforced executable policy on agent environments. ([Veto](https://ona.com/docs/ona/guardrails/veto.md) · [Executable deny list](https://ona.com/docs/ona/organizations/policies/executable-deny-list.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | CM-7 | Least functionality |
| **NIST AI RMF** | MANAGE-2.3 | Mechanisms to supersede/deactivate AI behavior |

---

### 2.2 Configure the Agent Command Deny List

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.7 |
| NIST 800-53 | CM-7 |
| NIST AI RMF | MANAGE-2.3 |

#### Description
Block dangerous agent-issued bash commands with wildcard patterns (e.g., `shutdown`, `shutdown*`, `rm *`). This applies to commands the AGENT runs, not to a user's own terminal, and takes effect for new sessions.

#### Rationale
**Why This Matters:**
- Autonomous agents chain shell commands; a single destructive or exfiltrating command in that chain is the highest-frequency agent failure mode
- The command deny list is a fast, readable first line that complements the kernel-level Veto policy (2.1)
- Scoping to agent commands (not user terminals) keeps human workflows unimpeded

**Attack Prevented:** Destructive or exfiltrating commands executed autonomously by a compromised or prompt-injected agent

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path observed live" date="2026-08-19" %}

**Step 1: Add Deny Patterns**
1. Navigate to: **Settings** → **Agents** → **Policies** → **Command deny list**
2. Add wildcard patterns one per line (start with destructive and network-exfil patterns) and **Save**
3. Confirm the list applies to new agent sessions

**Time to Complete:** ~20 minutes

#### Code Implementation{% include status-mark.html status="ai-validated" evidence="API audit pack executed against a live tenant" date="2026-08-19" %}

{% include pack-code.html vendor="ona" section="2.2" %}

#### Validation & Testing
1. Start a new agent session and confirm a denied command is refused
2. Confirm a user's own terminal is unaffected (by design)

**Expected result:** High-risk agent commands blocked at session start. ([Command deny list](https://ona.com/docs/ona/command-deny-list.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | CM-7 | Least functionality |
| **NIST AI RMF** | MANAGE-2.3 | Mechanisms to supersede AI behavior |

---

### 2.3 Restrict MCP Server Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | CM-7, AC-3 |

#### Description
Decide organization policy on Model Context Protocol (MCP) servers. Org owners can disable MCP entirely — repo `.ona/mcp-config.json` files are then ignored and external MCP is blocked. The org toggle is **all-or-nothing**: there is no org-level allowlist constraining repo-local configs. What Ona does document is admin-curated **organization MCP integrations** (HTTP servers added under Settings → Organization → Integrations and enabled per integration) and a per-server `toolDenyList` in repo-local configs.

#### Rationale
**Why This Matters:**
- MCP servers extend an agent's reach into external systems; each one is delegated, prompt-injectable access to whatever it connects to
- Because the control is all-or-nothing, an org that cannot vet individual MCP servers should disable MCP rather than accept unbounded repo-defined connections
- Repo-level MCP configs are attacker-influenceable (anyone who can commit to a repo can add one) unless the org disables MCP

**Attack Prevented:** Prompt-injection-driven data movement through unvetted, repo-defined MCP connections

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path corrected against the live console" date="2026-08-19" %}

**Step 1: Set the Org MCP Policy**
1. Navigate to: **Settings** → **Agents** → **Policies** → **Agent capabilities** → **Model Context Protocol (MCP)**
2. If your organization cannot vet MCP servers individually, turn MCP off — repo `.ona/mcp-config.json` files will be ignored and external MCP blocked
3. If MCP stays enabled, curate the org-wide integrations at **Settings** → **Organization** → **Integrations** (**Add MCP integration**), treat every repo MCP config as untrusted input, use `toolDenyList` per server, and pair with the command deny list (2.2) and Veto (2.1)

**Time to Complete:** ~15 minutes

#### Code Implementation{% include status-mark.html status="ai-validated" evidence="API audit pack executed against a live tenant" date="2026-08-19" %}

{% include pack-code.html vendor="ona" section="2.3" %}

#### Validation & Testing
1. With MCP disabled, an agent in a repo carrying `.ona/mcp-config.json` does not load the external server

**Expected result:** MCP disabled org-wide, or consciously accepted with compensating guardrails. ([MCP](https://ona.com/docs/ona/mcp.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | CM-7 | Least functionality |
| **NIST 800-53** | AC-3 | Access enforcement |

---

### 2.4 Govern SCM Tools and LLM Provider Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5, 3.3 |
| NIST 800-53 | AC-3, CM-7 |

#### Description
Scope what agents can do against source-control hosts and which model providers they use. The SCM-tools policy chooses whether agents get PR/issue API tools (vs. git commands only), for all members / a specific group / disabled. Provider governance is narrower than it once was: on Ona Cloud, OpenAI model access for Codex Agent is the default; **Ona Agent and Ona-managed Anthropic model access are no longer available on Ona Cloud**; customer-managed runners require Ona Intelligence or an approved OpenAI-compatible provider; custom token providers (BYOK) are available by exception to Enterprise customers; and the AWS Bedrock Runtime, Google Vertex AI, and direct Anthropic API integrations are deprecated and maintenance-only.

#### Rationale
**Why This Matters:**
- Disabling SCM API tools limits an agent to git operations, removing its ability to open/merge PRs or manipulate issues autonomously where that is not intended
- Provider choice determines where prompts and code are sent; the training-use posture of the Ona-managed default is undocumented, so regulated orgs should evaluate BYOK/self-managed backends deliberately
- Scoping SCM tools to a specific group confines high-capability agents to teams that need them

**Attack Prevented:** Autonomous repository manipulation via SCM API tools; unintended code/prompt egress to an unassessed model backend

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path observed live" date="2026-08-19" %}

**Step 1: Scope SCM Tools**
1. Navigate to: **Settings** → **Agents** → **Policies** → **Agent capabilities** → **Source Code Management Tools (SCM)** → **Restrict access to**
2. Set it to the narrowest that works: all members, a specific group, or disabled (git commands only, no PR/issue API tools). API: `agentPolicy.scmToolsDisabled` × `agentPolicy.scmToolsAllowedGroupId`.

**Step 2: Govern Model Providers**
1. On the same page, **Agents available** governs which agents and which Codex models, reasoning-effort ceilings, and service tiers members may use (`agentPolicy.allowedAgentIds`, `codexModelPolicy.modelStates`, `allowedCodexReasoningEfforts`, `allowedCodexServiceTiers`)
2. Review the [LLM providers documentation](https://ona.com/docs/ona/agents/llm-providers/overview.md); for regulated data, confirm the training-use and residency posture with your Ona account team (undocumented as of this writing) and treat any remaining BYOK/self-managed backend as an Enterprise exception to request, not a menu to pick from

**Time to Complete:** ~30 minutes

#### Code Implementation{% include status-mark.html status="ai-validated" evidence="API audit pack executed against a live tenant" date="2026-08-19" %}

{% include pack-code.html vendor="ona" section="2.4" %}

#### Validation & Testing
1. With SCM tools disabled, an agent cannot open a PR via API
2. Confirm the active model backend matches your approved provider

**Expected result:** Agent SCM reach and model backend deliberately scoped. ([SCM tools](https://ona.com/docs/ona/agents/scm-tools.md) · [LLM providers](https://ona.com/docs/ona/agents/llm-providers/overview.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | CM-7 | Least functionality |
| **NIST 800-53** | AC-3 | Access enforcement |

---

### 2.5 Constrain Automations

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.7 |
| NIST 800-53 | AC-6, CM-7 |

#### Description
Set the automation guardrails that cap how much autonomous work members can run: active automations per member, projects per automation, and concurrent actions. Remember org and automation admins bypass these limits.

#### Rationale
**Why This Matters:**
- Automations run agents on triggers across codebases — unbounded, they multiply the blast radius of a single poisoned trigger or injected instruction
- Per-member and concurrency caps contain both accidental runaway automation and deliberate abuse
- Because admins bypass the caps, admin-role hygiene (1.3) is a prerequisite for these limits to mean anything

**Attack Prevented:** Blast-radius amplification through mass or highly-concurrent autonomous automation runs

#### ClickOps Implementation

**Step 1: Set Automation Limits**
1. Navigate to: **Settings** → **Agents** → **Policies** → **Automations** — **Note:** automation organization policy controls are in preview and available only to selected Enterprise organizations; the section is absent on other tiers
2. Set active automations per member (default 5, Enterprise maximum 50), projects per automation (up to 100), and concurrent actions (up to 25 on Enterprise) to values matched to your risk tolerance

**Automation:** ClickOps only — Ona exposes no write interface for this setting ([Automation guardrails](https://ona.com/docs/ona/automations/guardrails.md), 2026-08-19). The limits are visible on the `GetOrganizationPolicies` read path as `agentPolicy.automationPolicy{maxAutomationsPerUser, maxParallelActions, maxProjectsPerAutomation}` (observed live), but that field is undocumented and no method sets it.

**Time to Complete:** ~15 minutes

#### Validation & Testing
1. A non-admin member is blocked from exceeding the active-automation cap
2. Confirm admins' bypass is acceptable given your admin-role assignments

**Expected result:** Autonomous automation volume bounded for non-admins. ([Automation guardrails](https://ona.com/docs/ona/automations/guardrails.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-6 | Least privilege |
| **NIST 800-53** | CM-7 | Least functionality |

---

### 2.6 Deploy Runtime EDR to Agent Environments

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.1, 13.7 |
| NIST 800-53 | SI-3, SI-4 |

#### Description
For regulated or high-sensitivity estates, enable the CrowdStrike Falcon integration, which deploys the falcon-sensor as a privileged sidecar with host-level visibility into all environments. Users cannot disable it.

#### Rationale
**Why This Matters:**
- Agent environments execute untrusted code and autonomous commands — runtime EDR gives detection and response coverage the platform's own guardrails do not provide
- A privileged sidecar with host-level visibility observes what an agent-scoped control cannot
- Enforced (user-non-disableable) deployment ensures coverage is uniform across every environment

**Attack Prevented:** Undetected malware execution and post-exploitation activity inside agent environments

#### Prerequisites
- CrowdStrike Falcon subscription with a CID and a sensor image
- Acceptance of a privileged sidecar in every environment (resource and trust implications)

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path corrected against the live console" date="2026-08-19" %}

**Step 1: Enable Falcon**
1. Navigate to: **Settings** → **Infrastructure** → **Security** → **Security agents** → **CrowdStrike Falcon** (Enterprise tier)
2. Provide the CID (stored as an organization secret and referenced by `cidSecretId`) and the sensor image reference; the sensor deploys as a privileged sidecar to all environments and cannot be disabled by users. API: `UpdateOrganizationPolicies.securityAgentPolicy.crowdstrike{enabled, image, cidSecretId, tags, additionalOptions}` — the read-back type is not expanded in the API docs, so audit scripts must treat its shape defensively.

**Time to Complete:** ~1 hour

#### Code Implementation{% include status-mark.html status="ai-validated" evidence="API audit pack executed against a live tenant" date="2026-08-19" %}

{% include pack-code.html vendor="ona" section="2.6" %}

#### Validation & Testing
1. Confirm the falcon-sensor is present in a newly created environment
2. Confirm a test detection surfaces in your CrowdStrike console

**Expected result:** Enforced runtime EDR across agent environments. ([Security agents](https://ona.com/docs/ona/organizations/policies/security-agents.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SI-3 | Malicious code protection |
| **NIST 800-53** | SI-4 | System monitoring |

---

## 3. Environment & Network Security

### 3.1 Restrict Port Admission Levels

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 12.2 |
| NIST 800-53 | AC-3, SC-7 |
| SOC 2 | CC6.6 |

#### Description
Cap how widely environment ports can be exposed. Admission levels run `creator_only` → `organization` → `everyone` (public); set the organization's **Maximum port admission level** so members cannot expose ports beyond your ceiling (options above the cap show "restricted by policy"), or disable port sharing entirely.

#### Rationale
**Why This Matters:**
- A public port URL exposes an in-development service on a shared domain — and three of Ona/Gitpod's five CVEs turn on subdomain/redirect trust on exactly such shared domains
- Defaulting to `creator_only` keeps a service reachable only by its creator unless a wider level is deliberately chosen
- An org-wide ceiling prevents any single member from publishing a port to the internet

**Attack Prevented:** Exposure of in-development services and subdomain-trust abuse via public port URLs

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path corrected against the live console" date="2026-08-19" %}

**Step 1: Set the Maximum Admission Level**
1. Navigate to: **Settings** → **Infrastructure** → **Policies** → **Environment access** → **Port sharing** / **Maximum port admission level** (Enterprise tier; the observed default is **Anyone (no login required)**, i.e. no cap)
2. Set **Maximum port admission level** to the lowest that supports collaboration needs (prefer `creator_only` or `organization`), or turn **Port sharing** off entirely (`portSharingDisabled: true` takes precedence over the level)

**Automation surface:** manageable as code — org policy `maxPortAdmissionLevel` / `portSharingDisabled` (`OrganizationService/UpdateOrganizationPolicies`, Terraform `ona_organization_policies`), and per security policy `spec.ports.maxAdmissionLevel` (`SecurityService`, Terraform `ona_security_policy`). Enum `ADMISSION_LEVEL_{UNSPECIFIED, CREATOR_ONLY, ORGANIZATION, EVERYONE}` — `ADMISSION_LEVEL_OWNER_ONLY` is **deprecated** in favor of `CREATOR_ONLY` (the vendor's own cURL example still uses it), and `UNSPECIFIED` applies no cap. See the [Security Policy API](https://ona.com/docs/api-reference/generated/security/create-security-policy.md).

**Time to Complete:** ~15 minutes

#### Code Implementation{% include status-mark.html status="ai-validated" evidence="API audit pack executed against a live tenant" date="2026-08-19" %}

{% include pack-code.html vendor="ona" section="3.1" %}

#### Validation & Testing
1. A member attempting to expose a port above the cap sees "restricted by policy"
2. `ona environment port open <port> --admission everyone` is refused when the ceiling is lower

**Expected result:** Port exposure bounded org-wide. ([Ports](https://ona.com/docs/ona/integrations/ports.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | Boundary protection |
| **NIST 800-53** | SC-7 | Boundary protection |

---

### 3.2 Control the In-Environment Web Browser

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.2 |
| NIST 800-53 | SC-7, AC-4 |

#### Description
Govern the built-in environment web browser and the agent's browse-web skill, which is **enabled by default on all tiers**. The browser can reach environment-local services including `http://localhost:3000`. Only Enterprise can change this policy.

#### Rationale
**Why This Matters:**
- An agent that can browse the web is a two-way channel: it can pull instructions from attacker-controlled pages (prompt injection) and reach internal environment services
- Default-on across all tiers means this capability is live unless explicitly reviewed
- Reachability of `localhost` services means the browser is inside the environment's trust boundary, not merely an external fetch tool

**Attack Prevented:** Prompt injection via agent web browsing and access to environment-local services

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path and toggle label corrected against the live console" date="2026-08-19" %}

**Step 1: Review the Browser Policy**
1. Navigate to: **Settings** → **Infrastructure** → **Policies** → **Environment access** → **Web browser** ("Allow members to open the built-in browser panel. VS Code Browser is not affected.")
2. On Enterprise, disable it where agents have no legitimate browsing need (API/Terraform: `webBrowserDisabled: true`); where enabled, treat browsed content as untrusted agent input and pair with command/executable guardrails (2.1, 2.2)

**Time to Complete:** ~15 minutes

#### Code Implementation{% include status-mark.html status="ai-validated" evidence="API audit pack executed against a live tenant" date="2026-08-19" %}

{% include pack-code.html vendor="ona" section="3.2" %}

#### Validation & Testing
1. With the browser disabled, the agent's browse-web skill is unavailable
2. Confirm the setting's effect on a test environment

**Expected result:** Agent web browsing consciously scoped. ([Web browser policy](https://ona.com/docs/ona/organizations/policies/web-browser.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SC-7 | Boundary protection |
| **NIST 800-53** | AC-4 | Information flow enforcement |

---

### 3.3 Enforce Environment Lifetime, Timeout, and Retention

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6, AC-12 |

#### Description
Bound how long environments live and linger: set a maximum environment lifetime with strict enforcement, an auto-stop timeout ceiling, and archive/auto-delete retention. These limit the window a stale, credentialed environment stays exploitable.

#### Rationale
**Why This Matters:**
- The maximum-lifetime policy defaults to OFF (warning only) — without strict enforcement, expired environments can be restarted indefinitely
- Auto-stop defaults to 30 minutes only when a user sets no preference; an explicit ceiling caps idle credentialed compute
- Retention (archive then auto-delete) determines how long source and secrets persist in a dormant environment

**Attack Prevented:** Long-lived stale environments retaining source and credentials as a standing target

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path corrected against the live console" date="2026-08-19" %}

**Step 1: Enforce Maximum Lifetime**
1. Navigate to: **Settings** → **Infrastructure** → **Policies** → **Environment lifecycle**
2. Set **Maximum lifetime** (1h–1mo) and enable **Strict enforcement** ("Block non-compliant environments from restarting") so expired environments cannot be restarted

**Step 2: Cap Timeout and Retention**
1. Set the **Auto-stop timeout** ceiling (default user value is 30 min if unset; the observed org default is "No max timeout")
2. Set **Archive inactive** and **Auto-delete archived** to the shortest that meets your workflow — deletion is irreversible. **API trap:** on `UpdateOrganizationPolicies` a duration of `0s` means *no limit* for `maximumEnvironmentTimeout`, `maximumEnvironmentLifetime`, and `deleteArchivedEnvironmentsAfter` — zeroing these fields *weakens* the org; `archiveEnvironmentsAfter` must be a whole number of days.

**Time to Complete:** ~20 minutes

#### Code Implementation{% include status-mark.html status="ai-validated" evidence="API audit pack executed against a live tenant" date="2026-08-19" %}

{% include pack-code.html vendor="ona" section="3.3" %}

#### Validation & Testing
1. An expired environment cannot be restarted under strict enforcement
2. An idle environment auto-stops at the configured ceiling

**Expected result:** Environments are time-bounded and reclaimed. ([Lifetime](https://ona.com/docs/ona/organizations/policies/environment-lifetime.md) · [Timeout](https://ona.com/docs/ona/organizations/policies/environment-timeout.md) · [Archive/auto-delete](https://ona.com/docs/ona/environments/archive-auto-delete.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-12 | Session termination |
| **NIST 800-53** | CM-6 | Configuration settings |

---

### 3.4 Restrict Environment Creation

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7, AC-6 |

#### Description
Limit who can spin up blank environments with the **Only admins can start from scratch** environment policy, so members work from vetted project configurations rather than arbitrary from-scratch environments.

#### Rationale
**Why This Matters:**
- A from-scratch environment bypasses the guardrails and configuration baked into a project's setup
- Restricting blank creation channels members into reviewed project templates where secrets scope and repo access are already governed
- It reduces the surface of unmanaged, ad-hoc environments an attacker or careless user could stand up

**Attack Prevented:** Unmanaged ad-hoc environments that sidestep project-level controls

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path corrected against the live console" date="2026-08-19" %}

**Step 1: Restrict Blank Creation**
1. Navigate to: **Settings** → **Infrastructure** → **Policies** → **Environment setup**
2. Enable **Only admins can start from scratch** (API/Terraform `disableFromScratch`); consider **Only admins can create projects** and `membersRequireProjects` alongside it

**Time to Complete:** ~10 minutes

#### Code Implementation{% include status-mark.html status="ai-validated" evidence="API audit pack executed against a live tenant" date="2026-08-19" %}

{% include pack-code.html vendor="ona" section="3.4" %}

#### Validation & Testing
1. A non-admin member cannot create a from-scratch environment and must use a project

**Expected result:** Blank environment creation restricted to admins. ([Environment creation](https://ona.com/docs/ona/organizations/policies/environment-creation.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | CM-7 | Least functionality |
| **NIST 800-53** | AC-6 | Least privilege |

---

### 3.5 Mitigate Dotfiles Auto-Execution Supply-Chain Risk

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5, 16.4 |
| NIST 800-53 | CM-7, SI-3 |

#### Description
Ona clones a user's configured dotfiles repository (user menu → **Account** → **Preferences** → **Dotfiles repository**, or `ona user dotfiles set`) into every environment and **auto-executes** the first of `install.sh` / `install` / `bootstrap.sh` / `bootstrap` / `setup.sh` / `setup`. Ona documents **no admin control to restrict dotfiles** — and no admin *visibility* either: `GetDotfilesConfiguration` reads only the caller's own setting — so treat this as a supply-chain gap and enforce it through the guardrails that do exist.

#### Rationale
**Why This Matters:**
- Auto-executing a user-controlled bootstrap script in every environment is arbitrary code execution at environment start, from a source outside your review
- A compromised dotfiles repo (or a compromised developer account pointing at a malicious one) runs before the developer touches anything
- Because there is no admin off-switch, the Veto executable policy and command deny list are the only enforcement points

**Attack Prevented:** Environment-start code execution via a malicious or compromised dotfiles bootstrap script

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path observed live; no organization-level control exists at the tenant's tier" date="2026-08-19" %}

**Step 1: Enforce via Existing Guardrails (no direct admin toggle exists)**
1. Use the **Veto executable policy** ([2.1](#21-enforce-an-executable-policy-with-veto)) to AUDIT then BLOCK high-risk binaries the bootstrap might invoke (network and package tooling)
2. Use the **command deny list** ([2.2](#22-configure-the-agent-command-deny-list)) for destructive/exfil patterns
3. Publish a policy requiring dotfiles repositories to be organization-controlled and reviewed; monitor for dotfiles-driven execution in audit logs ([6.1](#61-enable-audit-logging-and-siem-streaming))

**Automation:** ClickOps only — Ona exposes no write interface for this setting at the organization level ([Dotfiles](https://ona.com/docs/ona/configuration/dotfiles/overview.md), 2026-08-19); the only surfaces are per-user (`UserService/SetDotfilesConfiguration`, `ona user dotfiles set`).

**Time to Complete:** ~30 minutes (plus the Veto/command-deny setup they depend on)

#### Validation & Testing
1. A Veto-blocked binary invoked by a dotfiles script is blocked and logged
2. Confirm the audit trail surfaces dotfiles bootstrap execution

**Expected result:** Dotfiles auto-execution risk contained by kernel and command guardrails. ([Dotfiles](https://ona.com/docs/ona/configuration/dotfiles/overview.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SI-3 | Malicious code protection |
| **NIST 800-53** | CM-7 | Least functionality |

---

## 4. Data & Secrets

### 4.1 Scope Secrets and Restrict Organization Secrets

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 16.4 |
| NIST 800-53 | AC-3, SC-28 |
| SOC 2 | CC6.1 |

#### Description
Use the tightest secret scope (user > project > organization precedence) and treat organization secrets with caution: they are available to **everyone in the organization** with no documented granular access control. Agents pull credentials from secrets, so scope is a direct agent-access decision.

#### Rationale
**Why This Matters:**
- An organization secret is readable by every member's environments and agents — one org-scoped cloud key is a shared, broadly-reachable credential
- Project and user scope confine a secret to where it is actually needed
- Because agents pull credentials from secrets, over-broad secret scope directly widens what a compromised agent can reach

**Attack Prevented:** Broad credential exposure via org-wide secrets reachable by every agent

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path corrected against the live console" date="2026-08-19" %}

**Step 1: Prefer Narrow Scope**
1. Define secrets at **user** (user menu → **Account** → **Secrets**) or **project** scope wherever possible rather than organization scope
2. For unavoidable org secrets (**Settings** → **Infrastructure** → **Secrets**, Enterprise tier), document that they are readable org-wide and reserve them for genuinely shared, lower-sensitivity values
3. Prefer the **credential proxy** mount where the target is an HTTPS API: "the credential proxy intercepts HTTPS traffic to the target hosts and replaces the dummy mounted value with the real value in the specified HTTP header. The real secret value is never exposed in the environment." (`Secret.credentialProxy`) — an agent that cannot read the value cannot exfiltrate it

**Time to Complete:** ~30 minutes plus inventory

#### Code Implementation{% include status-mark.html status="ai-validated" evidence="API audit pack executed against a live tenant" date="2026-08-19" %}

{% include pack-code.html vendor="ona" section="4.1" %}

#### Validation & Testing
1. A project-scoped secret is not visible to environments outside that project
2. Inventory org secrets and confirm each is acceptable as an org-readable value

**Expected result:** Secrets scoped to least exposure; org secrets minimized. ([Secrets overview](https://ona.com/docs/ona/configuration/secrets/overview.md) · [Organization secrets](https://ona.com/docs/ona/organizations/organization-secrets.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | SC-28 | Protection of information at rest |

---

### 4.2 Use OIDC Workload Identity for Keyless Cloud Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 16.9 |
| NIST 800-53 | IA-5, AC-3 |

#### Description
Instead of storing long-lived cloud credentials as secrets, use Ona's OIDC workload identity to exchange an Ona-issued ID token for short-lived cloud credentials, with custom subject claims (`organization_id`, `project_id`, `creator_email`, `environment_id`, `runner_name`) to scope trust in your cloud IAM.

#### Rationale
**Why This Matters:**
- Keyless federation removes the standing long-lived cloud key that would otherwise sit in secrets as a theft target
- Custom sub claims let your cloud IAM trust policy scope access to specific projects/environments rather than "any Ona workload"
- Short-lived credentials shrink the window a leaked token is useful

**Attack Prevented:** Theft of long-lived cloud credentials stored as environment secrets

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path observed live" date="2026-08-19" %}

**Step 1: Configure Workload Identity**
1. In your cloud IAM, register **`https://app.gitpod.io`** as the OIDC issuer (that is the `iss` claim even for an org that only ever sees `ona.com` branding) and constrain the trust policy using the sub claims you selected (`organization_id`, `project_id`, `runner_id`, `environment_id`, `creator_email`, …)
2. In Ona, navigate to **Settings** → **Login & Identity** → **OIDC Tokens** (Enterprise tier; API `UpdateOIDCConfig`): choose **v3** tokens and set `extraSubFields` so the `sub` pins a specific project/runner/environment rather than the whole org
3. From agents/automations, retrieve a token with `ona idp token --audience <audience>` or authenticate directly with `ona idp login aws --role-arn <arn>` / `ona idp login vault --role <role>` instead of stored keys

**Time to Complete:** ~1-2 hours with cloud IAM changes

#### Code Implementation{% include status-mark.html status="ai-validated" evidence="API audit pack executed against a live tenant" date="2026-08-19" %}

{% include pack-code.html vendor="ona" section="4.2" %}

#### Validation & Testing
1. An agent obtains short-lived cloud credentials via token exchange with no stored long-lived key
2. The cloud trust policy rejects a token whose claims fall outside the allowed project/environment

**Expected result:** Cloud access is keyless and claim-scoped. ([OIDC configuration](https://ona.com/docs/ona/configuration/oidc.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | IA-5 | Authenticator management |
| **NIST 800-53** | AC-3 | Access enforcement |

---

### 4.3 Scope Repository Access to Least Privilege

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 6.8 |
| NIST 800-53 | AC-3, AC-6 |

#### Description
Configure per-runner repository access deliberately. The GitHub integration requests broad, all-repository access with scopes `repo`, `read:user`, `user:email`, `workflow` (per-repo scoping is roadmap only), so choose the connection method and account carefully and remove access when unused.

#### Rationale
**Why This Matters:**
- Broad all-repository access means a compromised runner or agent reaches every repo the connected account can, not just the one in play
- Connection credentials are stored encrypted and removed when the method is disabled or the integration deleted — so disabling unused integrations actually revokes access
- Choosing a least-privilege service identity for the SCM connection limits blast radius where per-repo scoping is unavailable

**Attack Prevented:** Whole-org source exposure via an over-broad SCM integration on a compromised runner

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path corrected against the live console" date="2026-08-19" %}

**Step 1: Configure Repository Access Deliberately**
1. Navigate to: **Settings** → **Infrastructure** → **Runners** → open the runner → **Configure repository access** → **New provider** (Ona Cloud runners ship github/gitlab/bitbucket via OAuth; private or self-hosted Git servers require Enterprise)
2. Prefer OAuth over PAT where possible (`SCMIntegration.pat` allows PAT auth — leave it off when `supportsOauth2` is true); where a PAT is used, mint it on a least-privilege service identity
3. Remove providers/integrations that are no longer needed to revoke their stored credentials; `CheckRepositoryAccess` and `ListSCMOrganizations` answer "what can this runner actually reach"

**Time to Complete:** ~30 minutes

#### Code Implementation{% include status-mark.html status="ai-validated" evidence="API audit pack executed against a live tenant" date="2026-08-19" %}

{% include pack-code.html vendor="ona" section="4.3" %}

#### Validation & Testing
1. Deleting an unused integration removes its stored credentials (access no longer works)
2. Inventory which repositories the connected account can reach and confirm it is the minimum acceptable

**Expected result:** SCM access scoped to the least the platform allows, unused integrations revoked. ([Configuring repository access](https://ona.com/docs/ona/runners/configuring-repository-access.md) · [GitHub integration](https://ona.com/docs/ona/source-control/github.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | AC-6 | Least privilege |

---

## 5. Deployment Architecture

### 5.1 Run Self-Hosted Runners for Sensitive Source Code

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 12.2 |
| NIST 800-53 | SC-7, SA-9 |
| SOC 2 | CC6.6 |

#### Description
For sensitive codebases, run self-hosted runners in your own AWS/GCP VPC rather than Ona Cloud. With self-hosted runners, source code and SCM credentials stay on the runner in your infrastructure and never reach Ona's management plane; guardrails are still defined centrally but enforced at the runner.

#### Rationale
**Why This Matters:**
- The management/runner plane separation means a self-hosted runner keeps source and secrets inside your VPC — the management plane handles only auth, policy, and coordination
- Ona Cloud is limited to two regions (eu-central-1, us-east-1) with no private networking and cannot reach self-hosted Git providers; self-hosting is required for private-network and residency needs
- Guardrails (Veto, deny lists, policies) still apply, so self-hosting adds isolation without losing central governance

**Attack Prevented:** Exposure of sensitive source and credentials to a shared multi-tenant control plane

#### Prerequisites
- AWS or GCP account and VPC; capacity for Fargate-based runners
- Network path for the runner's required egress (see below)

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path observed live" date="2026-08-19" %}

**Step 1: Provision a Self-Hosted Runner**
1. Navigate to: **Settings** → **Infrastructure** → **Runners** → **Set up a new runner** → **AWS** or **GCP** (Enterprise tier; Azure is waitlisted) and deploy it in your VPC
2. Provision the documented network access. **Gotcha:** the AWS runner requires direct TCP 443 to Secrets Manager, CloudWatch Logs, ECR API, ECR Docker, and S3 — these **bypass HTTP proxies**; use PrivateLink/VPC endpoints. Allow Ona AMIs by **owner account ID `995913728426`**, not by AMI ID.
3. Configure repository access on the runner ([4.3](#43-scope-repository-access-to-least-privilege)); block the deprecated local-runner path with the org policy `allowLocalRunners: false` (or set the system-managed `RUNNER_KIND_LOCAL_CONFIGURATION` runner's desired phase to STOPPED)

**Time to Complete:** ~half day including cloud networking

#### Code Implementation{% include status-mark.html status="ai-validated" evidence="API audit pack executed against a live tenant" date="2026-08-19" %}

{% include pack-code.html vendor="ona" section="5.1" %}

#### Validation & Testing
1. Confirm source code and SCM credentials remain in your VPC (never transit the management plane)
2. Confirm centrally-defined guardrails enforce at the self-hosted runner

**Expected result:** Sensitive code processed in your own VPC under central governance. ([Runners overview](https://ona.com/docs/ona/runners/overview.md) · [Ona Cloud regions](https://ona.com/docs/ona/runners/ona-cloud.md) · [Architecture](https://ona.com/docs/ona/understanding/architecture.md) · [AWS setup](https://ona.com/docs/ona/runners/aws/setup.md) · [AWS networking](https://ona.com/docs/ona/runners/aws/networking.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | Boundary protection |
| **NIST 800-53** | SA-9 | External system services |

---

## 6. Monitoring & Detection

### 6.1 Enable Audit Logging and SIEM Streaming

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 8.9 |
| NIST 800-53 | AU-2, AU-6 |
| SOC 2 | CC7.2 |

#### Description
Operationalize Ona's audit logs — covering infrastructure, execution, security (including **environment Veto enforcement** events), organization, and integration activity — and stream them to your SIEM. Assign the read-only **Audit Log Reader** role for oversight without change rights.

#### Rationale
**Why This Matters:**
- Veto-enforcement events are how you confirm the kernel guardrails (2.1) are actually blocking — audit logging is what makes the guardrails observable
- Regular members cannot read audit logs (not even their own resources), so oversight requires deliberately assigning the Audit Log Reader role
- Real-time streaming to a SIEM enables correlation and alerting beyond the console

**Attack Prevented:** Undetected agent/admin misuse; unobserved guardrail bypass attempts

#### ClickOps Implementation

**Step 1: Assign Oversight and Stream Logs**
1. Assign the **Audit Log Reader** role to your security team ([1.3](#13-apply-least-privilege-organization-roles-and-groups)); audit logs are Enterprise-only, and there is no console page for them — the surfaces are the CLI and the API
2. Export via CLI (`ona audit-logs --format=json --limit=1000`) or the API (`POST /api/gitpod.v1.EventService/ListAuditLogs`, base `https://app.gitpod.io` — or your custom dashboard domain), filtering on `actorIds`, `actorPrincipals` (USER/SERVICE_ACCOUNT/RUNNER/…), `subjectTypes`, and `from`/`to` (RFC 3339, `[from, to)` half-open; max 100 entries per page, 25 values per filter)
3. For SIEM ingestion, **poll `ListAuditLogs` on a schedule** — it is the only surface carrying actor attribution. `WatchEvents` streams resource changes only (`{operation, resourceType, resourceId}`, no actor, readable by anyone with resource read access) and is a live-dashboard feed, not the audit trail; there is no method to enable logging, set retention, or register a SIEM destination (logging is always-on and pull-only, and Ona documents no named SIEM connector)

**Automation surface:** genuinely API-manageable for the read side — `EventService/ListAuditLogs` + `GetAuditLog` (the typed `details.vetoExec` payload lives on `GetAuditLog`), plus the `ona audit-logs` CLI (see [audit-log API](https://ona.com/docs/api-reference/generated/event/list-audit-logs.md)).

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="ona" section="6.1" %}

#### Validation & Testing
1. A Veto-enforcement event (`AUDIT_LOG_ENTRY_KIND_ENVIRONMENT_VETO`) appears in the audit log after a blocked execution (2.1) — Veto Exec entries are in preview and appear only for organizations where that preview is enabled
2. Confirm polled `ListAuditLogs` entries reach your SIEM
3. **Note:** audit-log retention is undocumented ("per your data retention policy") — export continuously rather than relying on in-platform retention

**Expected result:** Auditable, SIEM-integrated activity trail with oversight roles assigned. ([Audit logs](https://ona.com/docs/ona/audit-logs/overview.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | System monitoring |
| **NIST 800-53** | AU-2 | Event logging |

---

### 6.2 Secure Webhooks with HMAC Verification

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | SC-8, AU-10 |

#### Description
Where automations are triggered by Git-provider webhooks, Ona is the **receiver**: you register Ona's payload URL and the webhook secret in your Git provider, and Ona verifies the HMAC signature on every inbound payload (invalid signatures are rejected). Rotate the secret when needed (rotation invalidates the old secret immediately) and keep webhook management to organization admins — the Automations Admin role deliberately cannot manage webhooks (webhook-scoped roles are `RESOURCE_ROLE_WEBHOOK_ADMIN` / `_VIEWER`).

#### Rationale
**Why This Matters:**
- HMAC verification ensures Ona only triggers automations on payloads genuinely from your Git provider, not spoofed calls to the payload URL
- Immediate old-secret invalidation on rotation closes the window a leaked secret is usable
- Restricting webhook management to org admins keeps a high-trust integration point out of broader delegated hands

**Attack Prevented:** Spoofed webhook payloads triggering unintended automation; stale-secret replay

#### ClickOps Implementation

**Step 1: Verify and Restrict Webhooks**
1. Navigate to: **Automations** → **Webhooks** → **+ Webhook** (Automations require the Core tier or above)
2. Register the generated payload URL and secret in your Git provider (repository or organization scope); Ona verifies the HMAC signature and matches the event to bound automations
3. Rotate the signing secret on suspicion of exposure (`WebhookService/RotateWebhookSecret`, or `ona webhook secret get <id>` to re-read it for the provider side — the old secret invalidates immediately); keep webhook management limited to org admins and review `boundWorkflowCount` / `lastTriggeredAt` for orphaned or dormant webhooks

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="ona" section="6.2" %}

#### Validation & Testing
1. A payload with an invalid signature is rejected by Ona (no automation triggers)
2. After rotation, a payload signed with the old secret is rejected

**Expected result:** Authenticated, admin-managed webhooks. ([Webhooks](https://ona.com/docs/ona/automations/webhooks.md))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AU-10 | Non-repudiation |
| **NIST 800-53** | SC-8 | Transmission integrity |

---

## 7. Compliance Quick Reference

> **No product-specific benchmark exists for Ona/Gitpod** (verified: not in the CIS Benchmarks catalog, no DISA STIG, not in CISA SCuBA scope). The mappings below use control-family catalogs, which justify and map these controls but do not originate configuration steps. When a benchmark is eventually published, re-map against it.

### NIST 800-53 Rev 5 Mapping

| Control | Ona Control | Guide Section |
|---------|-------------|---------------|
| IA-2 / IA-8 | OIDC SSO | [1.1](#11-enforce-sso-with-domain-verification) |
| AC-2 | SCIM provisioning + account restriction | [1.2](#12-enforce-scim-provisioning-and-restrict-account-creation) |
| AC-6(1) | Least-privilege roles | [1.3](#13-apply-least-privilege-organization-roles-and-groups) |
| IA-5 | Token/service-account hygiene; workload identity | [1.4](#14-harden-service-accounts-and-personal-access-tokens), [4.2](#42-use-oidc-workload-identity-for-keyless-cloud-access) |
| CM-7 | Veto policy, command deny list, MCP/SCM governance | [2.1](#21-enforce-an-executable-policy-with-veto)–[2.5](#25-constrain-automations) |
| SI-3 / SI-4 | Runtime EDR; dotfiles mitigation | [2.6](#26-deploy-runtime-edr-to-agent-environments), [3.5](#35-mitigate-dotfiles-auto-execution-supply-chain-risk) |
| SC-7 | Port admission, browser policy, self-hosted runners | [3.1](#31-restrict-port-admission-levels), [3.2](#32-control-the-in-environment-web-browser), [5.1](#51-run-self-hosted-runners-for-sensitive-source-code) |
| SC-28 | Secret scoping | [4.1](#41-scope-secrets-and-restrict-organization-secrets) |
| AU-2 / AU-6 | Audit logging + SIEM | [6.1](#61-enable-audit-logging-and-siem-streaming) |

### NIST AI RMF Mapping

| Function | Ona Control | Guide Section |
|----------|-------------|---------------|
| MANAGE-2.3 (mechanisms to supersede/deactivate AI) | Veto engine, command deny list | [2.1](#21-enforce-an-executable-policy-with-veto), [2.2](#22-configure-the-agent-command-deny-list) |
| MAP / MEASURE (context + monitoring) | Automation limits, audit logging | [2.5](#25-constrain-automations), [6.1](#61-enable-audit-logging-and-siem-streaming) |

### SOC 2 Trust Services Criteria Mapping

| Control ID | Ona Control | Guide Section |
|-----------|-------------|---------------|
| CC6.1 | SSO, secrets, tokens | [1.1](#11-enforce-sso-with-domain-verification), [4.1](#41-scope-secrets-and-restrict-organization-secrets) |
| CC6.2 | Provisioning, invitations | [1.2](#12-enforce-scim-provisioning-and-restrict-account-creation), [1.5](#15-control-member-invitations-and-remove-domain-auto-admit) |
| CC6.6 | Port/network boundary, self-hosting | [3.1](#31-restrict-port-admission-levels), [5.1](#51-run-self-hosted-runners-for-sensitive-source-code) |
| CC7.2 | Audit logging | [6.1](#61-enable-audit-logging-and-siem-streaming) |

---

## Appendix A: Edition Notes

Ona gates several hardening controls to the **Enterprise** plan (OIDC SSO, organization secrets, longer retention options, the ability to change certain default-on policies like the in-environment web browser). Several policies are **default-permissive** (maximum environment lifetime off/warning-only; web browser enabled on all tiers; project visibility org-wide on non-Enterprise tiers) — treat every default as something to review, not to inherit. Confirm plan-gating and defaults in your own tenant.

## Appendix B: Security Incidents (Gitpod-era)

The platform's disclosed vulnerability history is dominated by session/origin/token-boundary bugs reachable from a single malicious link — directly motivating the port-admission (3.1), token-lifetime (1.4), and SSO (1.1) controls:

- **CVE-2023-0957** (Critical, 9.6) — Cross-Site WebSocket Hijacking from missing Origin validation led to full workspace takeover plus persistent SSH access from one clicked link. Research: [Snyk Security Labs (Elliot Ward)](https://labs.snyk.io/resources/gitpod-remote-code-execution-vulnerability-websockets/). Patched SaaS 2023-02-14.
- **CVE-2025-55750** (Medium, 6.5) — Bitbucket OAuth integration leaked valid access tokens via URL fragment through a crafted link.
- **CVE-2024-21583** (Medium) — Cookie tossing via a session cookie missing the `__Host-` prefix, enabling JWT manipulation from a subdomain-controlling attacker.
- **CVE-2023-32766** (Medium) and **CVE-2021-35206** (Medium) — XSS/unvalidated-redirect issues.

Source: [NVD keyword search "gitpod"](https://services.nvd.nist.gov/rest/json/cves/2.0?keywordSearch=gitpod).

## Appendix C: References

**Official Ona Documentation:**
- [Documentation home](https://ona.com/docs) · [full page index (llms.txt)](https://ona.com/docs/llms.txt)
- [Guardrails overview](https://ona.com/docs/ona/guardrails/overview.md) · [Veto](https://ona.com/docs/ona/guardrails/veto.md) · [Executable deny list](https://ona.com/docs/ona/organizations/policies/executable-deny-list.md) · [Command deny list](https://ona.com/docs/ona/command-deny-list.md)
- [Organization policies overview](https://ona.com/docs/ona/organizations/policies/overview.md) · [Best practices](https://ona.com/docs/ona/best-practices.md)
- [SSO](https://ona.com/docs/ona/sso/overview.md) · [SCIM](https://ona.com/docs/ona/scim/overview.md) · [Audit logs](https://ona.com/docs/ona/audit-logs/overview.md) · [Secrets](https://ona.com/docs/ona/configuration/secrets/overview.md)

**API, CLI, Terraform, SDK:**
- [API reference](https://ona.com/docs/api-reference.md) · [Organization policies API](https://ona.com/docs/api-reference/generated/organization/get-organization-policies.md) · [Security Policy API](https://ona.com/docs/api-reference/generated/security/create-security-policy.md) · [Audit-log API](https://ona.com/docs/api-reference/generated/event/list-audit-logs.md)
- [Ona CLI](https://ona.com/docs/ona/integrations/cli.md) · [CLI reference](https://ona.com/docs/ona/reference/cli.md) · [Terraform provider `gitpod-io/ona`](https://ona.com/docs/ona/integrations/terraform-provider.md) (beta, Linux-only packages) · [SDKs](https://ona.com/docs/ona/integrations/sdk.md) · [MCP configuration](https://ona.com/docs/ona/mcp.md)

**Hardening Baselines:** none product-specific as of this writing (no CIS Benchmark, DISA STIG, or CISA SCuBA baseline for cloud development environments / coding agents).

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-20 | 0.2.1 | ai-drafted · ai-validated | Added **ai-validated** to this guide's status set, which now reads **ai-drafted** + **ai-validated** — an AI agent exercised this guidance against a live Ona tenant and the guidance survived that contact; no human practitioner has reviewed or applied it, so the guide claims no **ni-** status, and an AI status never substitutes for one. **What was exercised:** all 22 controls walked on the live console (`app.gitpod.io`, a `free_ona` tenant) and 18 read-only `api/` audit packs executed against that tenant, exit codes and sanitized output captured per pack; the OCEAN `ona` source observed live against the same organization. 18 controls carry a per-requirement badge naming what was run for that control. **What was NOT exercised — the badges are absent on purpose:** every `terraform/` pack was only `terraform validate`d inside Docker and was never applied to any organization, so no Terraform path in this guide has been proven to run; the four `cli/` packs were never executed (the `ona` CLI was not installed on the run host); the three mutating packs (`api` 1.01 and 1.05, `cli` 2.01) were deliberately not run, so 1.1 and 1.5 rest on console observation alone; 2.5 and 6.2 are plan-gated to Core+/Enterprise on this tenant and 6.1 has no console surface at all with its API pack returning the Enterprise gate, so all three are unbadged; 2.1 came back PARTIAL because its executables section is Enterprise-gated, so it too is unbadged even though its audit pack ran. Enterprise-gated toggle behaviour throughout remains a documentation claim, not a live one. No control text, control number, or heading changed. | Claude Code (Opus 5) |
| 2026-08-19 | 0.2.0 | ai-drafted | Live validation pass (validate-hth-guide): every console path re-read off the live console (`app.gitpod.io`; sidebar Organization / Infrastructure / Agents / Login & Identity) — 11 controls needed path corrections (1.2, 1.5, 2.3, 2.6, 3.1–3.4, 4.1, 4.3 wrong; 2.1 partial — its executables section is plan-gated on the tenant walked); 14 doc-drift corrections (`set-default` takes a policy id, MCP toggle lives under Agents → Policies, WatchEvents is not the audit trail, API base `app.gitpod.io`, LLM-provider posture, `ona idp token`, webhook direction, deprecated `OWNER_ONLY`, preview gating for automation limits and Veto audit entries, service-account "no expiry" wording); Code Packs landed for the first time — api (read-only audit scripts, executed against a live tenant), terraform (`gitpod-io/ona`), cli (`ona`), config (Veto policy YAML, MCP `toolDenyList`), and Sigma rules on the audit-log schema; controls with no write surface now carry an explicit Automation verdict (2.5, 3.5); Ona added to the CLI inventory. | Claude Code (Opus 5) † |
| 2026-08-08 | 0.1.0 | ai-drafted | Initial guide — 20 controls across identity, agent guardrails (Veto/command-deny/MCP), environment & network policy, secrets, self-hosted runners, and audit logging. Authored per the create-hth-guide playbook: every control traces to fetched Ona documentation; no product benchmark exists so mappings use NIST 800-53/AI RMF/SOC 2 catalogs; the Gitpod-era CVE history grounds the rationale. Automation surfaces stated honestly (Security Policy API/CLI for ports+executables, EventService for audit) — Code Packs deferred to a follow-up. Unverified "Ona joining OpenAI" claim deliberately excluded. | Claude Code (Opus 4.8) † |

> † Author **inferred**, not recorded. This row predates the Author column, so the value comes from the authoring session's commit window (every other guide authored in that window names the same tool and model, with no dissenting entry). Undaggered rows are attributed from a sibling guide that recorded its author explicitly in the same commit, or from the row's own text.


## Contributing

Found an issue or want to improve this guide? Open an issue or PR on [GitHub](https://github.com/grcengineering/how-to-harden). Console paths should be verified against the live `app.ona.com` console (Ona's own docs give inconsistent locations for the policy surface), and all code belongs in Code Packs (no inline code blocks). Follow the [create-hth-guide and create-code-pack playbooks](../../.claude/skills/).
