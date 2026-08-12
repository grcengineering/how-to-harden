---
layout: guide
title: "Kernel Hardening Guide"
vendor: "Kernel"
slug: "kernel"
tier: "3"
category: "AI/ML Platform"
description: "Cloud browser infrastructure security hardening for API key scoping, project isolation, managed-auth credential protection, Chrome policy enforcement, egress control, and audit log streaming"
version: "0.1.0"
maturity: "draft"
last_updated: "2026-08-11"
---

**Product Editions Covered:** Developer, Hobbyist, Start-Up, Enterprise

---

## Overview

Kernel ([kernel.sh](https://www.kernel.sh)) provides cloud browser infrastructure for AI agents and web automations: isolated Chromium instances that spin up in milliseconds, controlled via REST API, SDKs (TypeScript, Python, Go), a first-party CLI, and a hosted MCP server. Agents drive these browsers with computer-use actions, Playwright execution, or CDP, and the platform persists authenticated session state (cookies, local storage), stored login credentials, replays, and telemetry on the organization's behalf.

That concentration is exactly why hardening matters. A Kernel organization accumulates three classes of high-value material: **long-lived API keys** that can create and control browsers, **stored credentials and browser profiles** that hold live authenticated sessions for third-party services, and **agent egress** — outbound traffic to arbitrary websites executed on your behalf. An attacker who obtains an over-scoped API key doesn't just get compute: they get your agents' logins, their session cookies, and a residential-grade browser fleet to abuse them from. Because agents act on untrusted web content, prompt injection against the agent layer (OWASP GenAI LLM Top 10 2026, LLM01) can also weaponize a browser that hasn't been execution-constrained.

This guide hardens the Kernel platform surface itself: key scoping, project isolation, credential and profile protection, browser execution policy, egress control, and audit visibility.

### Intended Audience

- Security engineers responsible for AI agent infrastructure
- Platform/DevOps teams operating browser automation fleets
- GRC professionals assessing agentic tooling
- Third-party risk managers reviewing Kernel as a subprocessor

### How to Use This Guide

- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries (healthcare, finance, government)

### Scope

Covers tenant-level hardening of the Kernel platform: organization, projects, API keys, managed auth, profiles, browser configuration, proxies, extensions, telemetry, and audit logs. Does not cover application-layer security of the agents you build on top of Kernel (prompt design, tool permissioning inside your agent framework), or the security of target websites your agents visit.

**A note on benchmarks:** no CIS Benchmark, DISA STIG, or CISA SCuBA baseline exists for Kernel as of this writing. Controls in this guide originate from Kernel's first-party configuration documentation (Tier 1), with framework mappings to NIST 800-53, SOC 2, and ISO 27001:2022 at the control-family level — flagged here as **no benchmark equivalent yet**.

---

## Table of Contents

1. [API Keys & Access Scoping](#1-api-keys--access-scoping)
2. [Project Isolation & Resource Governance](#2-project-isolation--resource-governance)
3. [Credential & Session-State Protection](#3-credential--session-state-protection)
4. [Browser Execution Hardening](#4-browser-execution-hardening)
5. [Monitoring & Audit](#5-monitoring--audit)
6. [Third-Party Integration Security](#6-third-party-integration-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. API Keys & Access Scoping

### 1.1 Scope API Keys to Projects

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-6, AC-3
**CIS Controls v8:** 6 (Access Control Management)

#### Description

Kernel API keys come in two scopes: org-scoped keys that can access resources across the entire organization, and project-scoped keys that can only access resources inside the project they were issued for. Issue project-scoped keys for every workload, and reserve org-scoped keys for the small set of administrative operations that genuinely need them.

#### Rationale

**Why This Matters:**

- A leaked org-scoped key exposes every project's browsers, profiles, stored credentials, proxies, and deployments; a project-scoped key caps the blast radius to one environment
- Kernel enforces scoping server-side: a project-scoped key that sends a conflicting `X-Kernel-Project-Id` header receives `403 Forbidden`, and can only mint further keys for its own project
- CI pipelines, per-customer workloads, and experiments each get least-privilege credentials instead of sharing one master key

**Attack Prevented:** Lateral movement across environments after a single key compromise (e.g., a staging key leaked in CI logs being used to read production browser profiles).

#### Prerequisites

- An existing org-scoped key (or dashboard access) to mint new keys
- Projects created for each environment (see Control 2.1)

#### ClickOps Implementation

Kernel's documentation implements key management through the API, CLI, and SDKs; no dashboard console path for key creation is documented. Use the Code implementation below.

#### Code Implementation

{% include pack-code.html vendor="kernel" section="1.1" %}

#### Validation & Testing

1. Call `GET /auth/context` with the new key — the response returns the authenticated principal, organization, and the credential's maximum and effective scope, without exposing the secret
2. Attempt to access a resource in a different project using the project-scoped key

**Expected result:** The auth context shows the project binding; cross-project access fails with `403 Forbidden`.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.3 | Role-based access and least privilege |
| **NIST 800-53** | AC-6 | Least privilege |
| **ISO 27001:2022** | 5.15 | Access control |

---

### 1.2 Set Expiration on Every API Key

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5
**CIS Controls v8:** 5 (Account Management)

#### Description

Kernel API keys accept a `days_to_expire` parameter (1–3650 days) at creation. Set an explicit, short expiration on every key so forgotten credentials age out instead of accumulating as permanent attack surface. Kernel returns the plaintext key exactly once at creation; listing and retrieval return only a `masked_key`.

#### Rationale

**Why This Matters:**

- Non-expiring machine credentials are a top infostealer target — a key harvested from a laptop or CI log today should not still work next year
- Forced expiry creates a natural rotation cadence and an inventory signal: a key that expires unnoticed was a key nobody needed
- Kernel's own guidance: treat the key like a password — keep it out of client-side code, store it in a secret manager, rotate it when access changes

**Attack Prevented:** Long-tail abuse of stale credentials harvested months earlier (credential-stuffing supply chains documented in Push Security's Browser & Identity Attacks Matrix).

#### Prerequisites

- A secret manager to hold the plaintext key (returned only once)

#### ClickOps Implementation

No dashboard console path for key creation is documented. Use the Code implementation below.

#### Code Implementation

{% include pack-code.html vendor="kernel" section="1.2" %}

#### Validation & Testing

1. List keys via `GET /org/api_keys` and confirm every key shows an expiration
2. Confirm the response contains `masked_key` values only — no plaintext

**Expected result:** Zero keys without expiry; no plaintext key material in list responses.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security — credential lifecycle |
| **NIST 800-53** | IA-5 | Authenticator management |
| **ISO 27001:2022** | 5.17 | Authentication information |

---

### 1.3 Rotate API Keys with Bounded Grace Periods

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5
**CIS Controls v8:** 5 (Account Management)

#### Description

Kernel's rotate operation (`POST /org/api_keys/{id}/rotate`) issues a replacement key that copies the rotated key's name and project binding, and schedules the old key to expire after a grace period so in-flight callers can swap over. The grace period defaults to 7 days and is configurable via `expire_in_days` (0–3650); `expire_in_days: 0` revokes the old key immediately. Rotate on a schedule, on personnel change, and immediately on suspected exposure.

#### Rationale

**Why This Matters:**

- Rotation with a grace period makes routine key hygiene a zero-downtime operation — there is no availability excuse for year-old keys
- Immediate revocation (`expire_in_days: 0`) is the documented kill switch for a confirmed leak
- The new plaintext key is returned exactly once, forcing secret-manager discipline on every rotation

**Attack Prevented:** Continued use of a compromised credential after exposure; the grace-period bound also limits how long a superseded key remains a live target.

#### Prerequisites

- Inventory of where each key is deployed (CI secrets, agent runtimes) so consumers can be updated within the grace window

#### ClickOps Implementation

No dashboard console path for key rotation is documented. Use the Code implementation below.

#### Code Implementation

{% include pack-code.html vendor="kernel" section="1.3" %}

#### Validation & Testing

1. Rotate a test key with `--expire-in-days 7`, then verify the old key still authenticates during the grace window and the new key carries the same project binding via `GET /auth/context`
2. Rotate with `--expire-in-days 0` and confirm the old key is rejected immediately

**Expected result:** Old key dies exactly at the configured boundary; new key inherits scope.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Credential rotation and revocation |
| **NIST 800-53** | IA-5 | Authenticator management |
| **ISO 27001:2022** | 5.17 | Authentication information |

---

### 1.4 Audit and Remove Unused API Keys

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-2
**CIS Controls v8:** 5 (Account Management)

#### Description

Review the organization's key inventory (`GET /org/api_keys`, masked) on a cadence and delete keys that no longer map to a live workload. Kernel enforces a safety property worth building into your runbook: an API key cannot delete itself — deletion must be authorized by a different key, so a revocation request can never be signed by the credential it is revoking.

#### Rationale

**Why This Matters:**

- Every dormant key is standing attack surface with no owner watching it
- The cannot-delete-itself rule means your break-glass admin key and your day-to-day keys must be distinct — plan that separation before the incident
- Masked listing makes inventory review safe to automate and archive

**Attack Prevented:** Abuse of orphaned credentials from departed staff, finished projects, or abandoned experiments.

#### Prerequisites

- A second (admin) key to authorize deletions
- Key-to-workload ownership records (names like `staging-ci` help — see Control 1.1)

#### ClickOps Implementation

No dashboard console path for key inventory is documented. Use the Code implementation below.

#### Code Implementation

{% include pack-code.html vendor="kernel" section="1.4" %}

#### Validation & Testing

1. Run the inventory script and reconcile every key against a named owner/workload
2. Attempt to delete a key using itself as the authorizing credential

**Expected result:** Unowned keys are deleted; self-deletion is rejected by the API.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2 | Removal of access when no longer required |
| **NIST 800-53** | AC-2 | Account management |
| **ISO 27001:2022** | 5.18 | Access rights |

---

### 1.5 Prefer OAuth Over Static Keys for MCP Access

**Profile Level:** L2 (Hardened)
**NIST 800-53:** IA-2
**CIS Controls v8:** 6 (Access Control Management)

#### Description

Kernel's hosted MCP server (`mcp.onkernel.com`) gives MCP-capable clients (Claude, Cursor, VS Code, Zed, and others) direct control of browsers, profiles, proxies, and shell execution inside browser VMs. It supports two authentication modes: OAuth 2.1 (recommended, browser-based user authorization) and static API keys passed as a `Bearer` header. Use OAuth for human-driven clients; reserve API-key auth for headless automation that cannot complete an OAuth flow — and scope those keys per Control 1.1.

#### Rationale

**Why This Matters:**

- MCP config files are synced, committed, and screen-shared constantly; a static key embedded in MCP settings is one paste away from exposure, while an OAuth grant is user-bound and revocable
- The MCP server exposes high-consequence tools (`exec_command` runs shell commands inside browser VMs) — the authentication that gates them deserves the stronger mode
- Kernel's documentation is explicit: API keys bypass the OAuth flow; keep them out of client-side code

**Attack Prevented:** Credential theft from committed or synced MCP client configuration files.

#### Prerequisites

- An MCP client that supports OAuth 2.1 authorization flows

#### ClickOps Implementation

**Step 1: Connect via OAuth (recommended)**

1. Add the Kernel MCP server (`https://mcp.onkernel.com/mcp`) in your MCP client's connector settings
2. Complete the browser-based OAuth authorization prompt when the client initiates the connection

**Step 2: Restrict API-key mode to headless automation**

1. Where a headless client must use a key, issue a dedicated project-scoped key (Control 1.1) with a short expiry (Control 1.2)
2. Store the config outside version control

**Time to Complete:** ~10 minutes

#### Code Implementation

{% include pack-code.html vendor="kernel" section="1.5" %}

#### Validation & Testing

1. Review all MCP client configurations in your fleet for hardcoded `Authorization: Bearer` values
2. Confirm headless configs reference environment-injected, project-scoped keys

**Expected result:** Human clients authenticate via OAuth; any static keys are project-scoped, expiring, and absent from version control.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Authentication of users and systems |
| **NIST 800-53** | IA-2 | Identification and authentication |
| **ISO 27001:2022** | 5.16 | Identity management |

---

## 2. Project Isolation & Resource Governance

### 2.1 Isolate Environments with Projects

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-7, AC-4
**CIS Controls v8:** 12 (Network Infrastructure Management)

#### Description

Projects are Kernel's isolation boundary: each project holds its own browsers, profiles, credentials, proxies, extensions, deployments, and browser pools, and API keys can be bound to a single project. Create separate projects for production, staging, and experiments so an agent (or a key) in one environment cannot touch another's session state. Every organization has a **Default** project that cannot be deleted while it is the last active project; requests without a project binding land there.

#### Rationale

**Why This Matters:**

- Browser profiles and stored credentials are live authentication material — a staging experiment must not be able to load production session cookies
- Project-scoped keys plus per-project resources turn a key leak into a single-environment incident instead of an organization-wide one
- Resources created before projects existed were migrated into **Default**; until you segment them, everything shares one blast radius

**Attack Prevented:** Cross-environment contamination — experimental or compromised agent code reaching production profiles, credentials, and proxies.

#### Prerequisites

- Org-scoped key or dashboard access to create projects
- A naming convention (`production`, `staging`, per-customer, per-team)

#### ClickOps Implementation

**Step 1: Create projects**

1. In the Kernel dashboard, navigate to the **Projects** section
2. Create one project per environment (e.g., `production`, `staging`)

**Step 2: Re-home existing resources**

1. Inventory resources sitting in the **Default** project
2. Recreate long-lived resources (profiles, proxies, pools) inside the correct project, then retire the Default-project copies

**Time to Complete:** ~20 minutes plus resource migration

#### Code Implementation

{% include pack-code.html vendor="kernel" section="2.1" %}

#### Validation & Testing

1. `kernel projects list` (or `GET /org/projects`) — confirm the expected project set
2. With a `production`-scoped key, attempt to list `staging` profiles

**Expected result:** Environments enumerate separately; cross-project access with a scoped key returns `403 Forbidden`.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Segregation of environments |
| **NIST 800-53** | SC-7 | Boundary protection |
| **ISO 27001:2022** | 8.31 | Separation of development, test and production environments |

---

### 2.2 Cap Browser Concurrency at Org and Project Level

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-6
**CIS Controls v8:** 4 (Secure Configuration of Enterprise Assets and Software)

#### Description

Kernel enforces a resolution hierarchy for how many browsers can run at once: a project's explicit override wins, else the organization's default per-project cap, else the organization-wide limit. Set an org default (`PATCH /org/limits`, field `default_project_max_concurrent_sessions`) and explicit per-project overrides (`PATCH /org/projects/{id}/limits`, field `max_concurrent_sessions`) so a runaway or hijacked workload cannot consume the entire fleet. Limits cover both on-demand sessions and browser-pool reservations.

#### Rationale

**Why This Matters:**

- An agent caught in a loop — or an attacker with a stolen key — can otherwise spin browsers to the organization ceiling, running up cost and starving production
- Per-project caps convert a single noisy tenant into a contained event
- Setting a value to `0` removes that cap; treat `0` as a deliberate, reviewed exception, not a default

**Attack Prevented:** Resource-exhaustion abuse of a compromised key (cryptomining-style fleet abuse, cost-inflation attacks, denial of service to sibling projects).

#### Prerequisites

- Org-scoped API key (project-limit updates are org-level administration)
- Baseline of legitimate peak concurrency per project

#### ClickOps Implementation

No dashboard console path for limits is documented. Use the Code implementation below (`kernel org` CLI commands are also available).

#### Code Implementation

{% include pack-code.html vendor="kernel" section="2.2" %}

#### Validation & Testing

1. `GET /org/limits` — confirm `default_project_max_concurrent_sessions` is set and `max_concurrent_sessions` reflects the org ceiling
2. `GET /org/projects/{id}/limits` for each production project — confirm explicit overrides (null means the org default applies)

**Expected result:** No project can exceed its reviewed concurrency budget.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 / A1.1 | Capacity management and availability |
| **NIST 800-53** | SC-6 | Resource availability |
| **ISO 27001:2022** | 8.6 | Capacity management |

---

## 3. Credential & Session-State Protection

### 3.1 Inject App Secrets at Deploy Time, Never in Code

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5, SA-3
**CIS Controls v8:** 16 (Application Software Security)

#### Description

Kernel apps receive secrets as environment variables injected at deployment: `kernel deploy my_app.ts --env KEY=value` for individual values, or `--env-file .env` to load a local env file. Code reads them via `process.env` / `os.environ` at runtime. Keep secrets out of app source and out of the repository; for per-invocation secrets passed through the invocation payload, Kernel's documentation directs you to encrypt them in your app rather than sending plaintext.

#### Rationale

**Why This Matters:**

- Deployed app code is long-lived artifact material; environment injection keeps credentials out of it
- A `.env` file that never enters version control is auditable at one choke point — the deploy command
- Payload-borne secrets traverse invocation records; the documented pattern is client-side encryption before the payload, decryption inside the app

**Attack Prevented:** Credential harvesting from committed source, shared app bundles, or invocation payload logs.

#### Prerequisites

- Kernel CLI authenticated (`kernel auth`)
- `.env` files excluded from version control

#### ClickOps Implementation

No dashboard console path for app secrets is documented. Use the Code implementation below.

#### Code Implementation

{% include pack-code.html vendor="kernel" section="3.1" %}

#### Validation & Testing

1. Grep the app source and repository history for hardcoded key material
2. Redeploy with a rotated value and confirm the app picks it up from `process.env` without a code change

**Expected result:** Secrets exist only in the deploy-time environment and your secret manager.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Protection of credentials |
| **NIST 800-53** | IA-5(7) | No embedded unencrypted static authenticators |
| **ISO 27001:2022** | 8.28 | Secure coding |

---

### 3.2 Harden Stored Credentials for Managed Auth

**Profile Level:** L2 (Hardened)
**NIST 800-53:** IA-5, SC-28
**CIS Controls v8:** 3 (Data Protection)

#### Description

Kernel Managed Auth can store login credentials so agents re-authenticate automatically when sessions expire. Stored values are encrypted with per-organization keys and are **write-only** — they cannot be retrieved via API after creation; list responses never include values; one-time codes (TOTP codes, SMS) are never saved, though a `totp_secret` can be stored for TOTP generation. Harden the lifecycle: store credentials deliberately (`kernel.credentials.create()` with `name`, `domain`, `values`), disable automatic capture where you don't want it (`save_credentials: false` on login flows), keep one credential per account, and delete credentials on decommission — deletion unlinks them from associated connections so those connections can no longer auto-authenticate.

#### Rationale

**Why This Matters:**

- These are real third-party passwords for the accounts your agents operate; write-only storage means even a read-scoped compromise cannot exfiltrate values via the API
- Automatic capture during Hosted UI logins is convenient but silent — an org that doesn't decide `save_credentials` per flow accumulates credentials it never inventoried
- Kernel's protections (never logged, never shared with LLMs, isolated login execution) cover the platform side; account-per-credential and prompt deletion are your side

**Attack Prevented:** Bulk credential exfiltration via API access, and orphaned auto-auth paths for accounts that should have been offboarded.

#### Prerequisites

- Inventory of accounts your agents authenticate to
- Managed Auth in use (Hosted UI, React component, or programmatic flow)

#### ClickOps Implementation

**Step 1: Decide capture policy per flow**

1. For each Hosted UI / programmatic login flow, set `save_credentials: false` unless automatic re-auth for that account is an accepted, documented need

**Step 2: Offboard with deletion**

1. When an agent account is retired, delete its stored credential and verify the associated connection no longer auto-authenticates

**Time to Complete:** ~15 minutes plus inventory

#### Code Implementation

{% include pack-code.html vendor="kernel" section="3.2" %}

#### Validation & Testing

1. Attempt to read back a stored credential's values via the API
2. After deleting a test credential, trigger its connection's re-auth and confirm it fails

**Expected result:** Values are unreadable post-creation; deleted credentials cannot auto-authenticate.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Protection of authentication credentials |
| **NIST 800-53** | SC-28 | Protection of information at rest |
| **ISO 27001:2022** | 5.17 | Authentication information |

---

### 3.3 Back Managed Auth with 1Password Vaults

**Profile Level:** L2 (Hardened)
**NIST 800-53:** IA-5
**CIS Controls v8:** 3 (Data Protection)

#### Description

Instead of storing raw credentials in Kernel, connect a 1Password service account: Managed Auth then retrieves credentials from your vaults at authentication time, matched by the item's website/URL field (exact domain, full URL, or wildcard). Values are never persisted in Kernel — the service-account token itself is encrypted with per-organization keys, access is bounded by the service account's vault permissions, and 1Password logs every credential access on its side.

**No benchmark equivalent yet.**

#### Rationale

**Why This Matters:**

- Keeps the system of record for secrets in your existing, audited vault instead of a second store to govern
- Vault-scoped service accounts give you least privilege and instant revocation at the 1Password layer
- 1Password's access logs add an independent audit trail for every agent credential retrieval

**Attack Prevented:** Sprawl of duplicated credential stores; undetected credential access (each retrieval is logged by 1Password).

#### Prerequisites

- 1Password plan supporting service accounts
- A dedicated vault holding only agent-facing credentials (grant the service account access to nothing else)

#### ClickOps Implementation

**Step 1: Create the service account**

1. In 1Password, create a service account with access restricted to the agent-credentials vault
2. Copy the token (starts with `ops_`)

**Step 2: Connect in Kernel**

1. In the Kernel dashboard, navigate to **Integrations** → **Connect 1Password**
2. Enter a provider name, paste the service-account token, and confirm the accessible vaults shown

**Step 3: Reference the provider in flows**

1. In credential objects, use auto-lookup (`{ provider: 'my-1p', auto: true }`) or an explicit path (`{ provider: 'my-1p', path: 'VaultName/ItemName' }`)
2. Where multiple items match a domain, note that the first match wins — keep one item per domain in the agent vault

**Time to Complete:** ~20 minutes

#### Validation & Testing

1. Run a login flow using the provider reference and confirm authentication succeeds
2. Check 1Password's access logs for the corresponding retrieval event
3. Revoke the service account and confirm flows fail closed

**Expected result:** Credentials resolve from the vault, every access is logged, revocation is immediate.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Centralized credential management |
| **NIST 800-53** | IA-5 | Authenticator management |
| **ISO 27001:2022** | 5.17 | Authentication information |

---

### 3.4 Treat Browser Profiles as Credential Material

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28, AC-6
**CIS Controls v8:** 3 (Data Protection)

#### Description

Kernel profiles persist browser state — cookies and local storage — across sessions, which means they hold live session tokens for every site an agent logged into. Profile data is encrypted end-to-end with a per-organization key, but governance is yours: profiles are project-scoped (Control 2.1), writable only when a browser is created with `save_changes: true`, replaced wholesale on save (last writer wins), loaded **read-only** by browser pools (saves are ignored, not rejected), and downloadable as archives via `GET /profiles/{id_or_name}/download`. Restrict which workloads may write profiles, which keys can download them, and delete profiles when their account is retired.

#### Rationale

**Why This Matters:**

- A downloaded profile archive is a portable bundle of authenticated sessions — functionally equivalent to stealing the cookies off a logged-in machine, the exact session-hijacking material catalogued in Push Security's Browser & Identity Attacks Matrix
- `save_changes` discipline prevents accidental persistence of state from untrusted browsing into a trusted profile
- Concurrent writers silently overwrite each other (the browser that ends last wins) — treat write access as single-owner

**Attack Prevented:** Session hijacking via profile-archive exfiltration; trust-poisoning of shared profiles by untrusted workloads.

#### Prerequisites

- Project segmentation in place (Control 2.1)
- Named ownership for each profile (which agent/account it represents)

#### ClickOps Implementation

No dashboard console path for profile governance is documented. Use the Code implementation below.

#### Code Implementation

{% include pack-code.html vendor="kernel" section="3.4" %}

#### Validation & Testing

1. Create a browser against a profile without `save_changes` and confirm post-session state is discarded
2. Acquire a pooled browser with the profile attached and confirm profile writes are ignored
3. With a project-scoped key from another project, attempt `GET /profiles/{id}/download`

**Expected result:** Only designated writers persist state; cross-project download is denied.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Protection of session tokens |
| **NIST 800-53** | SC-28 | Protection of information at rest |
| **ISO 27001:2022** | 8.1 | User endpoint devices (session state) |

---

## 4. Browser Execution Hardening

### 4.1 Enforce Chrome Enterprise Policies on Browsers and Pools

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-7, CM-6
**CIS Controls v8:** 4 (Secure Configuration of Enterprise Assets and Software)

#### Description

Kernel accepts a `chrome_policy` object — standard Chrome enterprise policies — on individual browser creation and on browser pools (where it applies to every browser in the pool). Use it to constrain what an agent-driven browser can do: `URLAllowlist`/`URLBlocklist` to restrict navigation (the documentation's own security example blocks `devtools://*`, `chrome://inspect`, and `view-source:*`), `DownloadRestrictions` to limit file downloads, and startup/homepage pinning. The serialized payload is capped at 5 MiB, and Kernel-managed policy areas (extensions, proxy, CDP/automation) are rejected — those are governed by their own controls (4.2, 4.3).

**No benchmark equivalent yet** — policy values here derive from Kernel's documented examples; tune allowlists to your workload.

#### Rationale

**Why This Matters:**

- Agents act on untrusted page content; a prompt-injected agent (OWASP GenAI LLM Top 10 2026, LLM01/LLM08) with an unrestricted browser can be steered to arbitrary destinations — a URL allowlist turns that into a contained failure
- Blocking DevTools surfaces closes an in-browser route to inspect cookies, storage, and network internals
- Pool-level policy makes the hardened configuration the default fleet-wide, not a per-callsite opt-in

**Attack Prevented:** Prompt-injection-driven navigation to attacker infrastructure; drive-by download execution; in-browser credential/session inspection.

#### Prerequisites

- Inventory of domains each workload legitimately needs (for allowlists)
- Browser pools for production workloads (policy attaches at pool level)

#### ClickOps Implementation

No dashboard console path for Chrome policies is documented. Use the Code implementation below.

#### Code Implementation

{% include pack-code.html vendor="kernel" section="4.1" %}

#### Validation & Testing

1. In a policy-bearing browser, navigate to a blocked URL and to `devtools://` — both must be refused
2. Attempt a restricted download
3. Update the pool with `rebuild_idle_browsers_on_update`/`discard_all_idle` behavior in mind, and confirm idle browsers pick up the new policy

**Expected result:** Navigation and downloads outside policy are blocked in every pooled browser.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.8 | Prevention of unauthorized software/actions |
| **NIST 800-53** | CM-7 | Least functionality |
| **ISO 27001:2022** | 8.9 | Configuration management |

---

### 4.2 Vet, Pin, and Checksum Browser Extensions

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-11, SA-12
**CIS Controls v8:** 2 (Inventory and Control of Software Assets)

#### Description

Extensions loaded into Kernel browsers run inside your agents' authenticated sessions. Kernel's model is upload-based: `kernel extensions upload ./my-extension --name my-extension` registers an unpacked extension (project-scoped, unique names), browsers reference it by name at creation, and `GET /extensions/{id_or_name}/metadata` returns a SHA-256 `checksum` when available. The CLI can also fetch unpacked extensions from the Chrome Web Store (`kernel extensions download-web-store`). Vet extension source before upload, record the checksum, verify it before high-sensitivity runs, and treat runtime ad-hoc uploads to running browsers (`POST /browsers/{id}/extensions` — which restarts Chromium) as an exception path, not a norm.

#### Rationale

**Why This Matters:**

- A malicious or trojaned extension sees every page, cookie, and keystroke in the session — the browser-extension vector is a named technique class in Push Security's Browser & Identity Attacks Matrix
- Upload-based loading is an opportunity: the artifact you vetted is the artifact that runs, and its checksum proves it
- Web Store downloads inherit Web Store supply-chain risk (developer-account takeovers); pin what you reviewed, not "latest"

**Attack Prevented:** Extension-borne session theft and content manipulation inside agent browsers.

#### Prerequisites

- An extension review step (manifest permissions, code provenance) before upload
- A record of approved extension names and checksums per project

#### ClickOps Implementation

No dashboard console path for extension management is documented. Use the Code implementation below.

#### Code Implementation

{% include pack-code.html vendor="kernel" section="4.2" %}

#### Validation & Testing

1. Compare `metadata.checksum` for each uploaded extension against your approval record
2. Enumerate extensions per project (`GET /extensions`) and reconcile against the approved list

**Expected result:** Every extension in every project matches an approved checksum.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC8.1 | Change management for software components |
| **NIST 800-53** | CM-11 | User-installed software |
| **ISO 27001:2022** | 8.19 | Installation of software on operational systems |

---

### 4.3 Route Egress Through Managed, Inspectable Proxies

**Profile Level:** L3 (Maximum Security)
**NIST 800-53:** SC-7, AC-4
**CIS Controls v8:** 13 (Network Monitoring and Defense)

#### Description

Kernel browsers can be bound to proxy configurations (`POST /proxies`) including fully custom proxies: `type: "custom"` with `config.host`, `config.port`, optional `username`/`password` (write-only — responses return `has_password: true`, never the value), optional `bypass_hosts` (up to 100 hostnames that connect directly), and optional `config.ca_bundle` — a PEM CA bundle for a TLS-terminating (MITM) proxy, which Kernel validates and installs into the browser's trust store. A CA-bundle proxy must be bound at browser creation; it cannot be hot-swapped onto a running browser. For regulated workloads, route agent egress through your own inspecting proxy so outbound traffic is logged and policy-enforced at a layer the agent cannot alter.

**No benchmark equivalent yet.**

#### Rationale

**Why This Matters:**

- Agents fetch and act on arbitrary web content; an egress choke point is your only network-layer view of what they actually touched
- An inspecting proxy catches exfiltration and command-and-control patterns that in-browser policy cannot see
- Write-only proxy credentials and creation-time CA binding keep the inspection layer itself tamper-resistant from the session side

**Attack Prevented:** Undetected data exfiltration by a hijacked agent; policy bypass via direct egress (`bypass_hosts` kept minimal and reviewed).

#### Prerequisites

- An inspecting proxy you operate (with its CA bundle in PEM form)
- Legal/privacy review for TLS inspection of agent traffic

#### ClickOps Implementation

No dashboard console path for proxy configuration is documented. Use the Code implementation below.

#### Code Implementation

{% include pack-code.html vendor="kernel" section="4.3" %}

#### Validation & Testing

1. `POST /proxies/{id}/check` (optionally with a target URL) — confirm health from the proxy's exit
2. Create a browser bound to the proxy and confirm target-site traffic appears in your proxy logs
3. Confirm the API response for the proxy shows `has_password: true` and no plaintext

**Expected result:** All agent egress for proxied browsers transits and is logged by your proxy.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | Network boundary protection |
| **NIST 800-53** | SC-7 | Boundary protection |
| **ISO 27001:2022** | 8.20 | Networks security |

---

### 4.4 Enable Zero Data Retention for Sensitive Workloads

**Profile Level:** L3 (Maximum Security)
**NIST 800-53:** SI-12
**CIS Controls v8:** 3 (Data Protection)

#### Description

Kernel's Zero Data Retention (ZDR) suppresses post-session persistence of three surfaces: session recordings, live-view streams, and telemetry. It is an Enterprise-only capability, is not enabled by default, and has no self-service toggle — Enterprise customers contact Kernel support to scope it, specifying which surfaces to suppress and expected volume. Enable it for workloads where browser sessions display regulated data (PHI, payment data, customer PII).

**No benchmark equivalent yet.**

#### Rationale

**Why This Matters:**

- Replays and telemetry are recordings of everything the agent saw — for a healthcare or finance workload, that's a second copy of regulated data living in your vendor
- Suppressing at the platform layer is stronger than deleting after the fact; data never persisted cannot be breached later
- Pairs with the Enterprise HIPAA BAA (see Appendix A) for covered-entity use

**Attack Prevented:** Exposure of regulated data through retained session recordings and telemetry stores.

#### Prerequisites

- Active Enterprise plan
- Data-classification decision on which workloads/surfaces require suppression

#### ClickOps Implementation

**Step 1: Scope with Kernel support**

1. Contact Kernel support (per the documented support path) with the surfaces to suppress — session recordings, live view, telemetry — and expected volume
2. Confirm in writing which organization/projects the ZDR configuration covers

**Step 2: Align internal features**

1. For ZDR workloads, do not start replay recordings (Control 5.3) and confirm telemetry expectations with the scoped configuration

**Time to Complete:** Support-led; days, not minutes

#### Validation & Testing

1. Run a test session in a ZDR-scoped project, then attempt to retrieve its replay and telemetry
2. Verify live view behavior matches the scoped suppression

**Expected result:** No recordings, live-view streams, or telemetry persist for suppressed surfaces.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | C1.1 / P4.2 | Confidentiality and data disposal |
| **NIST 800-53** | SI-12 | Information management and retention |
| **ISO 27001:2022** | 8.10 | Information deletion |

---

### 4.5 Cryptographically Sign Agent Traffic (Web Bot Auth)

**Profile Level:** L3 (Maximum Security)
**NIST 800-53:** IA-9
**CIS Controls v8:** 13 (Network Monitoring and Defense)

#### Description

Web Bot Auth signs your browsers' outbound requests with RFC 9421 HTTP message signatures, adding `Signature`, `Signature-Input`, and `Signature-Agent` headers that services (Cloudflare and Vercel among them) can verify against your published keys. On Kernel: generate an Ed25519 JWK, host the public key at `https://yourdomain.com/.well-known/http-message-signatures-directory` (JWKS), build the signing extension with `kernel extensions build-web-bot-auth --key ./my-key.jwk --signature-agent https://yourdomain.com`, and attach it to browsers via the `extensions` field.

**No benchmark equivalent yet.**

#### Rationale

**Why This Matters:**

- Gives target services a cryptographic way to distinguish your legitimate agents from imposters spoofing your user-agent or brand
- Establishes non-repudiable attribution for your fleet's traffic — valuable in abuse disputes and partner integrations
- Key custody discipline applies: the JWK's private component (`d`) signs everything your fleet does

**Attack Prevented:** Agent impersonation — third parties running attack traffic that appears to originate from your organization's automation.

#### Prerequisites

- A domain where you can publish the JWKS well-known path
- Secure storage for the private JWK

#### ClickOps Implementation

No dashboard console path is documented. Use the Code implementation below.

#### Code Implementation

{% include pack-code.html vendor="kernel" section="4.5" %}

#### Validation & Testing

1. From a signing browser, request a service you control and verify the three signature headers arrive and validate against your JWKS
2. Confirm the public-key directory is reachable at the well-known URL

**Expected result:** Requests carry valid RFC 9421 signatures traceable to your published keys.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | System identification and authentication |
| **NIST 800-53** | IA-9 | Service identification and authentication |
| **ISO 27001:2022** | 5.16 | Identity management |

---

## 5. Monitoring & Audit

### 5.1 Review Organization Audit Logs on a Cadence

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-6
**CIS Controls v8:** 8 (Audit Log Management)

#### Description

Kernel records every authenticated API request across the organization: who called, which endpoint, when, and the outcome. Logs are searchable in the dashboard, via `GET /audit-logs` (30-day window per search, 100 records per page), and via `kernel audit-logs search` — which filters by path, user ID, email, IP, status code, or HTTP method, and excludes GETs by default (`--include-get` reverses that). Bulk export for archival uses `kernel audit-logs download` (compressed JSONL, SHA-256-verified batches). Audit log access requires a Start-Up or Enterprise plan.

#### Rationale

**Why This Matters:**

- Key abuse looks like API traffic — profile downloads, credential-connection changes, key mints — and audit logs are where it shows
- Anchor a weekly review on the write-path: key creation/rotation/deletion, project changes, proxy changes, profile downloads
- The 30-day search window means anything older must already be exported (Control 5.2) to be investigable

**Attack Prevented:** Undetected credential abuse and configuration tampering; loss of forensic timeline after an incident.

#### Prerequisites

- Start-Up or Enterprise plan
- A named owner for the review cadence

#### ClickOps Implementation

**Step 1: Interactive review**

1. In the Kernel dashboard, open the audit logs view
2. Filter to the last 7 days and review write-path events (key, project, proxy, profile, credential operations)

**Time to Complete:** ~15 minutes weekly

#### Code Implementation

{% include pack-code.html vendor="kernel" section="5.1" %}

#### Validation & Testing

1. Mint and delete a test key, then find both events in a search
2. Download a 7-day export and confirm batch checksums verify

**Expected result:** Administrative actions appear in search within the review window; exports verify.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | Monitoring for anomalous activity |
| **NIST 800-53** | AU-6 | Audit record review and analysis |
| **ISO 27001:2022** | 8.15 | Logging |

---

### 5.2 Stream Audit Logs Continuously to S3

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AU-9, AU-4
**CIS Controls v8:** 8 (Audit Log Management)

#### Description

Enterprise organizations can configure continuous audit-log export to an S3 bucket they own: `POST /audit-logs/export/destinations` with `type: "s3"`, `region`, `bucket`, `prefix`, `role_arn`, `format: "jsonl.gz"`, and optional `kms_key_id`. The destination is created **paused**; Kernel returns a `kernel_role_arn` and an `external_id`, you add both to your IAM role's trust policy (`sts:ExternalId` condition), grant S3 (and optional KMS) permissions, run the destination **test** (which assumes the role and writes a probe object), and only then activate. Delivered objects are partitioned `jsonl.gz` under `date=YYYY-MM-DD/hour=HH` prefixes, and events include `event_id`, `timestamp`, `method`, `path`, and `status`.

#### Rationale

**Why This Matters:**

- Puts the audit trail in infrastructure the vendor cannot alter — tamper-resistant custody in your own account, under your own retention
- Escapes the 30-day interactive search window; incident response gets the full timeline
- The `external_id` trust condition is the documented defense against confused-deputy access to your bucket — do not omit it

**Attack Prevented:** Audit-trail loss or tampering; investigation gaps beyond the platform's search window.

#### Prerequisites

- Active Enterprise plan
- An S3 bucket and IAM role you control (optionally a KMS key)

#### ClickOps Implementation

No dashboard console path for export destinations is documented. Use the Code implementation below.

#### Code Implementation

{% include pack-code.html vendor="kernel" section="5.2" %}

#### Validation & Testing

1. Run the destination test and confirm the probe object lands in your bucket
2. After activation, confirm partitioned objects arrive under the expected `date=/hour=` layout
3. From your SIEM, ingest a sample and reconcile `event_id`s against an interactive search

**Expected result:** Continuous, verified delivery into your bucket; SIEM parity with interactive search.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | Security event capture and retention |
| **NIST 800-53** | AU-9 | Protection of audit information |
| **ISO 27001:2022** | 8.15 | Logging |

---

### 5.3 Capture Session Telemetry and Replays for High-Risk Automations

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SI-4, AU-14
**CIS Controls v8:** 8 (Audit Log Management)

#### Description

Kernel captures what happens *inside* a browser session. Telemetry is enabled per session via the `telemetry` field at browser creation: `{ enabled: true }` turns on the default lightweight set (`control`, `connection`, `system`, `captcha`), and `telemetry.browser` enables deeper categories per surface (e.g., `console`, `network`, `page`) — consumable live over SSE or read back later. Replays are explicit MP4 recordings: `kernel.browsers.replays.start(session_id)` / `.stop(...)`, with a `replay_view_url` and download per replay. Enable default telemetry broadly and full capture (network/console telemetry plus replays) for automations that touch sensitive systems — and skip both for ZDR-scoped workloads (Control 4.4).

#### Rationale

**Why This Matters:**

- When an agent misbehaves — or is manipulated by hostile page content — session-level evidence is the difference between "we think" and "we know"
- Network/console telemetry shows what the page actually did (requests, errors, injected script side-effects), not just what the agent intended
- Replays are plan-gated by retention (7 days on Hobbyist, 30 days on Start-Up, custom on Enterprise) — export anything you need longer

**Attack Prevented:** Unattributable agent actions; inability to reconstruct a prompt-injection or account-abuse incident inside a session.

#### Prerequisites

- Plan supporting the retention you need (see Appendix A)
- Storage/retrieval convention for downloaded replays tied to case IDs

#### ClickOps Implementation

No dashboard console path for telemetry configuration is documented. Use the Code implementation below.

#### Code Implementation

{% include pack-code.html vendor="kernel" section="5.3" %}

#### Validation & Testing

1. Create a session with network+console telemetry, browse a test page, and confirm events stream over SSE
2. Start and stop a replay, then fetch the `replay_view_url` and download the MP4

**Expected result:** High-risk sessions produce reviewable telemetry and video evidence.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | Detailed activity monitoring |
| **NIST 800-53** | SI-4 | System monitoring |
| **ISO 27001:2022** | 8.16 | Monitoring activities |

---

## 6. Third-Party Integration Security

### 6.1 Integration Risk Assessment Matrix

Use this matrix to assess integrations that connect to your Kernel organization, and targets your Kernel agents authenticate to:

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **Credential Model** | OAuth, user-bound, revocable | Project-scoped API key, expiring | Org-scoped static key, no expiry |
| **Session Material** | No profile/credential access | Read-only profile use (pools) | Profile write/download, stored credentials |
| **Execution Reach** | Observability only | Browser control | Shell exec in browser VMs (MCP `exec_command`), extension upload |
| **Egress Posture** | Managed proxy, allowlisted | Proxy without inspection | Direct egress, unrestricted navigation |
| **Auditability** | Streaming to your S3/SIEM | Interactive search only | No audit plan coverage |

**Decision guidance:** anything scoring High on Session Material or Execution Reach warrants the L2/L3 controls in sections 3–4 before production use.

### 6.2 Common Integrations and Recommended Controls

#### Hosted MCP Server (Claude, Cursor, VS Code, Zed, Goose, Windsurf, others)

**Data Access:** High — browser control, profile management, proxy management, shell execution in browser VMs
**Recommended Controls:**

- ✅ OAuth over static keys (Control 1.5); project-scoped, expiring keys where headless (Controls 1.1, 1.2)
- ✅ Audit-log review of MCP-originated API activity (Control 5.1)
- ⚠️ MCP clients act on model output; a prompt-injected client can drive real browsers — constrain those browsers with Chrome policies (Control 4.1) and proxies (Control 4.3)

#### Computer-Use Frameworks (Anthropic, OpenAI, Gemini computer-use, Browser Use, Stagehand, and similar)

**Data Access:** High — full browser control within your sessions and profiles
**Recommended Controls:**

- ✅ Dedicated project + project-scoped key per framework deployment (Controls 1.1, 2.1)
- ✅ URL allowlists and download restrictions on the pools they run in (Control 4.1)
- ⚠️ These agents read untrusted page content by design (OWASP GenAI LLM Top 10 2026 — LLM01 Prompt Injection, LLM08 Excessive Agency); telemetry and replays (Control 5.3) are your incident evidence

#### 1Password (Managed Auth credential provider)

**Data Access:** High — retrieves login credentials at authentication time
**Recommended Controls:**

- ✅ Vault-scoped service account, dedicated agent vault (Control 3.3)
- ✅ Review 1Password access logs alongside Kernel audit logs (Controls 3.3, 5.1)

#### Terraform Provider (`kernel/kernel`)

**Data Access:** Medium — manages durable configuration (projects, pools, policies) with an API key
**Recommended Controls:**

- ✅ Dedicated expiring key for CI (Controls 1.1–1.3); `KERNEL_API_KEY` via environment, never in state-committed config
- ✅ Policy-as-code review on `chrome_policy` changes (Control 4.1)

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Kernel Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | Key expiry, credential protection, profile protection | 1.2, 3.2, 3.4 |
| CC6.2 | Unused-key removal | 1.4 |
| CC6.3 | Project-scoped keys | 1.1 |
| CC6.6 | Managed egress proxies | 4.3 |
| CC6.8 | Chrome policy enforcement | 4.1 |
| CC7.2 | Audit review, S3 streaming, telemetry | 5.1, 5.2, 5.3 |
| CC8.1 | Extension vetting | 4.2 |

### NIST 800-53 Rev 5 Mapping

| Control | Kernel Control | Guide Section |
|---------|----------------|---------------|
| AC-2 | Unused-key removal | 1.4 |
| AC-6 | Project-scoped keys, profile access | 1.1, 3.4 |
| IA-5 | Key expiry/rotation, secrets, credentials | 1.2, 1.3, 3.1, 3.2, 3.3 |
| IA-9 | Web Bot Auth | 4.5 |
| SC-6 | Concurrency caps | 2.2 |
| SC-7 | Project isolation, egress proxies | 2.1, 4.3 |
| SC-28 | Credential and profile encryption governance | 3.2, 3.4 |
| CM-7 | Chrome policies | 4.1 |
| CM-11 | Extension control | 4.2 |
| AU-2 / AU-6 / AU-9 | Audit logging, review, protected export | 5.1, 5.2 |
| SI-4 | Session telemetry | 5.3 |
| SI-12 | Zero Data Retention | 4.4 |

### ISO 27001:2022 Mapping

| Control | Kernel Control | Guide Section |
|---------|----------------|---------------|
| 5.15 / 5.16 / 5.17 / 5.18 | Access scoping, identity, authentication info, access rights | 1.1–1.5, 3.2, 3.3 |
| 8.6 | Capacity management | 2.2 |
| 8.31 | Environment separation | 2.1 |
| 8.9 | Configuration management | 4.1 |
| 8.19 | Software installation control | 4.2 |
| 8.20 | Network security | 4.3 |
| 8.10 | Information deletion | 4.4 |
| 8.15 / 8.16 | Logging and monitoring | 5.1–5.3 |

---

## Appendix A: Plan Compatibility

Security-relevant feature availability by plan (per Kernel's pricing documentation):

| Capability | Developer | Hobbyist | Start-Up | Enterprise |
|------------|-----------|----------|----------|------------|
| SOC 2 report coverage | ✅ | ✅ | ✅ | ✅ |
| Audit log search & download (5.1) | ❌ | ❌ | ✅ | ✅ |
| Continuous S3 audit export (5.2) | ❌ | ❌ | ❌ | ✅ |
| Zero Data Retention (4.4) | ❌ | ❌ | ❌ | ✅ |
| HIPAA BAA | ❌ | ❌ | ❌ | ✅ |
| Browser replay retention (5.3) | ❌ | 7 days | 30 days | Custom |

All other controls in this guide (key scoping/rotation, projects, limits, secrets, credentials, profiles, Chrome policies, extensions, proxies, telemetry, Web Bot Auth) are documented as platform features without a stated plan gate — verify current gating against the pricing page, which changes faster than this guide.

---

## Appendix B: References

**Official Kernel Documentation (Tier 1 — all URLs verified 2026-08-11):**

- [API Keys](https://www.kernel.sh/docs/info/api-keys) — creation, scoping, rotation, deletion
- [Projects](https://www.kernel.sh/docs/info/projects) — isolation and access scoping
- [Audit Logs](https://www.kernel.sh/docs/info/audit-logs) — search, download, S3 export
- [Zero Data Retention](https://www.kernel.sh/docs/info/zero-data-retention)
- [Pricing & Limits](https://www.kernel.sh/docs/info/pricing) — plan gates
- [App Secrets](https://www.kernel.sh/docs/apps/secrets)
- [Managed Auth: Credentials](https://www.kernel.sh/docs/auth/credentials)
- [Browser Profiles](https://www.kernel.sh/docs/auth/profiles)
- [1Password Integration](https://www.kernel.sh/docs/integrations/1password)
- [Custom Chrome Policies](https://www.kernel.sh/docs/browsers/chrome-policies)
- [Extensions](https://www.kernel.sh/docs/browsers/extensions)
- [Custom Proxies](https://www.kernel.sh/docs/proxies/custom)
- [Web Bot Auth](https://www.kernel.sh/docs/browsers/bot-detection/web-bot-auth)
- [Telemetry Overview](https://www.kernel.sh/docs/browsers/telemetry/overview)
- [Replays](https://www.kernel.sh/docs/browsers/replays)
- [Browsers on Unikernels](https://www.kernel.sh/docs/info/unikernels) — isolation architecture
- [CLI: API Keys](https://www.kernel.sh/docs/reference/cli/api-keys) · [CLI: Audit Logs](https://www.kernel.sh/docs/reference/cli/audit-logs)
- [MCP Server Authentication](https://www.kernel.sh/docs/reference/mcp-server/authentication)
- [Terraform Integration](https://www.kernel.sh/docs/integrations/terraform) · [Provider docs (GitHub)](https://github.com/kernel/terraform-provider-kernel)
- [OpenAPI specification](https://api.onkernel.com/spec.json) — authoritative endpoint reference

**Corroborating Research (Tier 2b/3):**

- [OWASP GenAI LLM Top 10 2026](https://owasp.org/www-project-top-10-for-large-language-model-applications/) — LLM01 Prompt Injection, LLM08 Excessive Agency
- [Push Security: Browser & Identity Attacks Matrix](https://pushsecurity.com/blog/introducing-the-browser-and-identity-attacks-matrix) — session hijacking, credential theft, malicious-extension technique classes

**Benchmark Coverage:** No CIS Benchmark, DISA STIG, or CISA SCuBA baseline exists for Kernel (verified absent/unverifiable 2026-08-11).

---

## Changelog

> **Date discipline:** the `Date` column below and the `last_updated` value in the front matter **must both be the date the change is committed and pushed** — not the drafting date. Re-stamp both right before `git commit` (run `date +%F`).

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-11 | 0.1.0 | draft | Initial guide: 19 controls across API key scoping, project isolation, credential/profile protection, browser execution hardening, and audit — all sourced from fetch-verified Kernel first-party documentation | Claude Code (Opus 5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
