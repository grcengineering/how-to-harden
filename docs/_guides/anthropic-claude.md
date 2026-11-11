---
layout: guide
title: "Anthropic Platform Hardening Guide"
vendor: "Anthropic"
slug: "anthropic-claude"
platform: "Anthropic"
platform_slug: "anthropic"
product: "Common Controls"
tier: "1"
category: "AI/ML Platform"
description: "Harden Anthropic common controls across identity, sessions, centralized administration, network access, inference hooks and audit governance."
version: "1.3.1"
maturity: ["ai-drafted"]
last_updated: "2026-11-11"
---

## Overview

Anthropic is a multi-product AI platform: the claude.ai chat product (Team/Enterprise plans), Claude Code (the agentic coding tool), and the Claude API with its admin Console. Each product has a distinct hardening surface, so each has its own guide — this hub carries the **Common Controls** that span them: organization identity (SSO, roles), admin API key protection, and third-party integration governance. Anthropic provides a comprehensive Admin API for programmatic organization management alongside the web Console.

**Product guides:** [Claude Enterprise (claude.ai)](/guides/claude-enterprise/) · [Claude Code](/guides/claude-code/) · [Claude API & Console](/guides/anthropic-api/)

### Research and validation boundary

This refresh used the [source-first candidate ledger](/research/anthropic-source-coverage-2026-11) and public vendor references, including the published Cowork/unified baseline. It did not access a live tenant, change settings or create credentials. Source verification and mocked/native-interface tests do not earn live-validation status. The exact applicable Security Center checklist must be reconciled with an Owner’s current report; the effective-settings schema is a separate evidence surface.

### Intended Audience
- Security engineers managing AI tools and API integrations
- IT administrators configuring Claude for enterprise teams
- GRC professionals assessing AI compliance posture
- Third-party risk managers evaluating AI platform controls

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations using Claude
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This hub covers platform-wide Anthropic controls: organization authentication (SSO/SCIM), least-privilege organization roles, admin API key protection, and third-party integration governance (pending invites, integration risk). Product-specific hardening lives in the product guides: [Claude Enterprise](/guides/claude-enterprise/) for claude.ai workspace administration, [Claude Code](/guides/claude-code/) for the agentic coding tool (managed settings, MCP, sandboxing, CI/CD), and [Claude API & Console](/guides/anthropic-api/) for API keys, workspaces, data residency, and spend. Model behavior configuration (system prompts, safety settings) is out of scope.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Third-Party Integration Security](#2-third-party-integration-security)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

**Product guides:** [Claude Enterprise (claude.ai)](/guides/claude-enterprise/) · [Claude Code](/guides/claude-code/) · [Claude API & Console](/guides/anthropic-api/)

---

## Products in This Platform

Anthropic is a multi-product platform. This guide is the **Common Controls hub**. Parent identity, child-organization settings, Console API administration, Code managed policy and Desktop MDM are distinct planes; a setting on one does not automatically govern the others. Product-specific controls live in their own guides:

| Product | Guide | Covers |
|---------|-------|--------|
| **Common Controls** (this guide) | — | Organization SSO & SCIM, least-privilege organization roles, admin API key protection, third-party integration governance |
| **Claude Enterprise (claude.ai)** | [Claude Enterprise guide](/guides/claude-enterprise/) | Identity & provisioning, audit & compliance export, connectors & extensions, spend governance |
| **Claude Tag** | [Claude Tag guide](/guides/claude-tag/) | Slack-native team agent: channel identity and audience, connector/federation grants, egress, runtime, retention and audit |
| **Claude Code** | [Claude Code guide](/guides/claude-code/) | Managed settings & policy deployment, extensions & supply chain, execution isolation & sandboxing, threat defense, monitoring & incident response |
| **Claude API & Console** | [Claude API & Console guide](/guides/anthropic-api/) | API key management, workspace security, data security & privacy, monitoring & usage controls |

---

Claude Tag now has a [dedicated hardening guide](/guides/claude-tag/) and [current source ledger](/research/claude-tag-source-coverage-2026-11). Its Slack identity, retention, federation and network boundaries differ from ordinary Enterprise chat and must be assessed separately.

## Published Baselines and Product Boundaries

Anthropic publishes a public **Unified Claude and Cowork Security Best Practices v1.3 (2026-09-17)**, available from its [Trust Center resource](https://trust.anthropic.com/resources?name=claude-cowork-security-best-practices&s=uukz8hyx7jmdmo80lys36s) ([PDF](https://trust.anthropic.com/doc/trust?rid=6aa2110030a7f2cf301af4fd&r=iz673w96495gyjer8h78n&download=true)). Its admin-configuration tables cover organization identity, sessions, Cowork tools/egress, Desktop restrictions, plugins, monitoring and data handling. This is the published recommended baseline found in this review. It is **not documented as the complete Security Center pass/fail inventory**. The [Security Center help](https://support.claude.com/en/articles/18246629-review-your-organization-s-security-posture-with-the-security-center) describes results and manual attestations but does not enumerate every applicable check. An Owner's current report establishes the tenant-specific list; the effective-settings API does not supply equivalent recommendations or status.

The PDF predates several changes. Current configuration references govern the November 16 unified-experience rollout, Chrome enablement, skill-scanning/publishing defaults and chat-linked cloud retention. The source ledger records these discrepancies instead of copying stale defaults.

| Public source | Applicability and handling |
|---------------|----------------------------|
| [Unified Claude/Cowork v1.3](https://trust.anthropic.com/doc/trust?rid=6aa2110030a7f2cf301af4fd&r=iz673w96495gyjer8h78n&download=true) | Commercial organization and client baseline; mapped throughout this hub and the Enterprise/Code guides, with current per-feature caveats. |
| [C4G FedRAMP Secure Configuration Guide v2.1, July 16, 2026](https://trust.anthropic.com/doc/trust?rid=6ab43afba6eead3d68716b5c&r=iz673w96495gyjer8h78n&download=true) | **Claude for Government on claude.fedstart.com**, FedRAMP Rev. 5. Apply its customer SSO/MFA, SCIM/secret lifecycle, constrained egress/folders, approved MCP, approvals, updates, tenant restriction and telemetry guidance within that deployment. Its role model, device bootstrap/sign-in keys, headers and content-local storage are not commercial Enterprise defaults. |
| [Claude Code FISMA Best Practices v1.0, January 2026](https://trust.anthropic.com/doc/trust?rid=698639ba9484b19b52b6f1d2&r=iz673w96495gyjer8h78n&download=true) | Deployment/governance guidance for agency-managed endpoints and approved provider regions; use [Code 1.4](/guides/claude-code/#14-reconcile-federal-deployment-guidance-with-current-provider-routing) and current variable names. It does not itself authorize an agency deployment. |
| [Claude for Enterprise 20x Certification Package Overview](https://trust.anthropic.com/doc/trust?rid=6a8dcddb0fb2cfb4ca5be4ab&r=iz673w96495gyjer8h78n&download=true) | A separate public JSON package overview, not a configuration guide. A schema, package ID or certification-type field alone does not prove a completed authorization or make C4G controls apply to Enterprise. |

**Government audit discrepancy:** The C4G PDF prints `GET /v1/compliance/activities` and six-year event retention. The [current C4G API documentation](https://claude.com/docs/government/org-admin/compliance-api) uses `GET /gateway-api/v1/compliance/activities` on the C4G deployment host and a **30-day query lookback**, with a required since bound and opaque page tokens. A query window is not a statement of provider storage retention. This governance feed excludes conversation content, tool calls and usage metrics; endpoint telemetry/eDiscovery is a separate responsibility. Do not send commercial packs or keys to the Government endpoint, and do not assume its defaults apply to commercial Compliance APIs. No Government deployment or destructive recovery test was performed.

| Product / administration plane | Coverage and explicit limits |
|--------------------------------|------------------------------|
| Parent administration and child identity | Hub 1.1–1.7; parent roles, linked child settings and irreversible enrollment are separate. |
| Enterprise chats, Cowork/unified, Desktop and Chrome | Enterprise 1–5; organization, role, cloud runtime and local MDM controls are reconciled separately. |
| Code CLI/IDE, Remote Control, cloud/routines and CI | Code guide; local, hosted and cloud-provider policy/credential boundaries differ. |
| Console/API, WIF, workspaces, CMEK and Managed Agents | API guide; direct API examples use a fixed first-party host. AWS/other-provider routing is separately scoped. |
| Connectors, private MCP tunnels and managed connector authentication | Enterprise 3.1/3.9; downstream authorization and consent remain independent. |
| Science, Design, artifacts, M365 and hosted review/security | Enterprise 3.10 and 5.1/5.3 plus hub 1.8/2.3 establish capability admission, integration and coverage checks. This is not a claim of a dedicated full product benchmark for every specialized app or preview. |
| Agent SDK / custom agents | Code policy and API credential boundaries apply where documented; the application's own authorization, tool implementation and hosting baseline remain separate. |
| Personal subscriptions and research previews | Organizational controls are not assumed to exist. Verify plan eligibility before processing organizational data; dedicated personal-product hardening is outside these Enterprise/Code/API guides. |

---

## 1. Authentication & Access Controls

### 1.1 Enforce Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML 2.0 or OIDC-based SSO to authenticate Claude users through your corporate identity provider. Anthropic integrates SSO via WorkOS, supporting domain verification and just-in-time provisioning.

#### Rationale
**Why This Matters:**
- Centralizes authentication and user lifecycle management
- Enables MFA enforcement through your IdP's Conditional Access policies
- Eliminates standalone Claude passwords and reduces credential sprawl
- Directory-backed deprovisioning when SCIM is enabled; SSO/JIT alone does not remove stale memberships

**Attack Prevented:** Credential theft, unauthorized access, orphaned accounts

#### Prerequisites
- A Claude Team or Enterprise plan, or a Claude Console organization (single sign-on is available to all three)
- SAML 2.0 or OIDC compatible identity provider (Okta, Azure AD, OneLogin, Google Workspace)
- Owner or Primary Owner role (Team/Enterprise) or Admin role (Console)
- Domain ownership for domain verification
- **Console organizations:** the SSO controls on **Identity and access** appear only after SSO has been enabled for the organization through Anthropic Sales or a completed organization merge. Until then the page shows only the API-key creation settings

#### ClickOps Implementation

**Step 1: Access Identity and Access Settings**
1. Navigate to: **platform.claude.com** → **Settings** → **Identity and access** (Console organizations) or **claude.ai** → **Organization settings** → **Organization and access** (Team and Enterprise plans)
2. In the **Authentication** section, click **Setup SSO** (or **Manage SSO** if a connection already exists)

**Step 2: Configure SSO via WorkOS**
1. Select your IdP type (SAML 2.0 or OIDC)
2. Enter Identity Provider details:
   - **SSO URL:** Your IdP's SSO endpoint
   - **Entity ID / Issuer:** IdP entity ID
   - **Certificate:** X.509 certificate from IdP (for SAML)
3. Download Claude's Service Provider metadata for IdP configuration
4. Map required user attributes (email, name)

**Step 3: Configure Your IdP (Example: Okta)**
1. In Okta Admin: **Applications** → **Create App Integration** → **SAML 2.0**
2. Enter Claude's ACS URL and Entity ID from Step 2
3. Configure attribute statements:
   - email → user.email
   - name → user.displayName
4. Assign users/groups

**Step 4: Verify Domain and Enforce SSO**
1. Complete domain verification (DNS TXT record)
2. In the **Authentication** section, turn on **Require SSO for Console** and/or **Require SSO for Claude**
3. Test login before full enforcement

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="1.1" %}

#### Validation & Testing
1. Attempt login without SSO — should be redirected to IdP
2. Complete SSO login — should succeed and land in Claude
3. With SCIM configured, remove a pilot user from the assigned IdP group and verify deprovisioning. With SSO alone, separately terminate existing sessions and remove membership; do not infer those actions from a failed new login.
4. Cross-reference org member list (API) with IdP directory

**Expected result:** All users authenticate via SSO; no standalone password logins

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Monitor IdP for failed authentication attempts to Claude
- Review pending invites monthly for unauthorized additions

**Maintenance schedule:**
- **Monthly:** Review org member list vs IdP directory
- **Quarterly:** Rotate SSO certificates before expiration
- **Annually:** Re-verify domain ownership

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Low | Users authenticate via familiar IdP login |
| **System Performance** | None | No performance impact |
| **Maintenance Burden** | Low | Standard IdP maintenance applies |
| **Rollback Difficulty** | Easy | Disable SSO enforcement in Console |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security over protected information assets |
| **NIST 800-53** | IA-2, IA-8 | Identification and authentication (org users + non-org users) |
| **ISO 27001** | A.9.2.1 | User registration and de-registration |

---

### 1.2 Enforce Least-Privilege Organization Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-6, AC-6(1) |
| SOC 2 | CC6.1, CC6.3 |

#### Description
Assign the minimum necessary organization role to each user. The role model differs by organization type, and the Admin API's `role` enum is wider than either product's assignable set — audit scripts must handle every value. **Claude Console / API organizations** assign `user`, `claude_code_user`, `developer`, `billing`, and `admin` (the Console's **Limited Developer** role is a *workspace* role, not an organization role — see [Manage Workspace Membership](/guides/anthropic-api/#22-manage-workspace-membership)); above `admin` sit `owner` and `primary_owner`, which hold all admin permissions and additionally manage admins. **Claude Enterprise (claude.ai) organizations** manage members with `user` and `managed` via the API, and the enum also carries `membership_admin`. Limit the `admin` role (and its owner tiers) to a small number of trusted operators.

#### Rationale
**Why This Matters:**
- The `admin` role can provision Admin API keys, manage all workspaces, and remove users; `owner`/`primary_owner` additionally manage admins — the audit boundary is the whole elevated tier, not just `admin`
- Admins automatically inherit `workspace_admin` in every workspace
- The Admin API deliberately prevents assigning the `admin` role programmatically — the update endpoint documents: "Console and API organizations accept `user`, `developer`, `billing`, and `claude_code_user`; `admin` cannot be assigned through the API. Claude Enterprise organizations (beta) accept `user` and `managed`"
- Admins cannot be removed via API — only through the Console
- A role-audit script that only recognizes the classic four roles silently miscounts organizations using `claude_code_user`, `managed`, `membership_admin`, or the owner tiers — the full documented enum is `user`, `claude_code_user`, `developer`, `billing`, `admin`, `managed`, `membership_admin`, `owner`, `primary_owner`

**Attack Prevented:** Privilege escalation, unauthorized admin key provisioning, insider threat

#### Prerequisites
- Organization Admin access
- Current member inventory with role justifications

#### ClickOps Implementation

**Step 1: Review Current Role Assignments**
1. Navigate to: **platform.claude.com** → **Settings** → **Members**
2. Review each member's role
3. Document justification for each admin and billing role holder

**Step 2: Downgrade Excessive Privileges**
1. For each user with unnecessary admin access:
   - Click the user → **Edit Role**
   - Select `developer` or `user` as appropriate
2. Keep a small, named set with a tested independent recovery path. A numeric headcount alone does not establish least privilege. Review parent Owners/Admins independently from child roles (1.7).

**Step 3: Establish Role Assignment Policy**
1. Define criteria for each role level
2. Require approval for admin role assignments
3. Schedule quarterly role reviews

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="1.2" %}

#### Validation & Testing
1. List all org members via Admin API — count admins <= 3
2. Verify no user has admin role without documented justification
3. Review the documented assignable-role set without attempting a privilege grant. Confirm existing elevated roles and their business justification through the read-only inventory.
4. Verify billing role holders match authorized finance contacts

**Expected result:** Admin role limited to 2-3 operators; all other users at minimum necessary privilege

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Alert on new admin role assignments (Console audit)
- Monthly review of role distribution

**Maintenance schedule:**
- **Monthly:** Review member roles via API script
- **Quarterly:** Full access review with role justifications

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC6.3 | Logical access security; role-based access |
| **NIST 800-53** | AC-6, AC-6(1) | Least privilege; authorize access for security functions |
| **ISO 27001** | A.9.2.3 | Management of privileged access rights |

---

### 1.3 Protect Admin API Keys

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | IA-5, SC-12 |
| SOC 2 | CC6.1, CC6.6 |

#### Description
Admin credentials grant organization-wide management access — treat them with the same care as cloud provider root credentials. The credential model is now two-track, and differs by organization type. **Claude Console organizations** create Admin API keys (`sk-ant-admin01-...`) at **Console → Settings → Admin keys** (admin role required); Console admin keys have **no selectable scopes** — every key carries broad access to the endpoints that accept it. For Enterprise integrations choose the exact narrow scopes needed; `read:org_audit` also reaches conversation and session content and is excessive for a settings-only monitor. **Claude Enterprise (claude.ai) organizations** create *scoped* keys (`sk-ant-api01-...`) at **claude.ai → Organization settings → API**: the parent org's **primary owner** can create keys for all linked organizations, while an **organization owner** can create only Compliance-scoped keys restricted to their own organization. Separately, the Admin API also accepts a short-lived **OAuth bearer token with the `org:admin` scope** — and the service-account, federation-issuer, and federation-rule endpoints accept *only* that OAuth token, never an admin key.

#### Rationale
**Why This Matters:**
- Admin keys can list all users, manage all workspaces, disable API keys, and view usage data
- Unlike standard API keys, Console admin keys are not scoped to a single workspace — and cannot be scoped down at all, which makes each one a full-tenant credential
- A key created in one organization cannot manage another — organizations running both Console and Enterprise need one key per org, each inventoried separately
- The short-lived OAuth path (`org:admin`) exists precisely so interactive and break-glass administration need not mint another static full-access secret

**Attack Prevented:** Organization takeover, unauthorized workspace creation, data exfiltration via usage APIs

#### Prerequisites
- Organization Admin access (Console) / primary owner or organization owner (Enterprise)
- Secrets management solution (Vault, AWS Secrets Manager, etc.)

#### ClickOps Implementation

**Step 1: Audit Existing Admin Keys**
1. Navigate to: **Console → Settings → Admin keys** (Console orgs) and **claude.ai → Organization settings → API → Keys** (Enterprise orgs)
2. Review all provisioned admin keys
3. Identify and revoke any keys without a clear owner or purpose

**Step 2: Establish Key Hygiene**
1. Name each admin key descriptively (e.g., "CI/CD Org Audit — TeamName")
2. **Set an expiration at creation.** Key expiration is chosen when the key is created (presets from 3 hours to 30 days, custom durations, or Never) and cannot be changed afterward; the same expiration choice applies to Admin API keys. If your organization has a **maximum expiration policy**, the Console limits the choices and **Never** becomes unavailable — adopt that policy so unexpiring admin keys cannot be minted at all
3. Store keys in a secrets manager — never in source code, env files, or chat
4. Rotate admin keys on a schedule; audit each key's `expires_at` via the Admin API (the field is `null` for non-expiring keys — treat those as findings)

**Step 3: Limit Admin Key Provisioning**
1. Restrict admin role to 2-3 trusted operators (see Control 1.2)
2. Require documented approval before provisioning new admin keys
3. Log all admin key creation events

**Step 4: Prefer the OAuth Path for Interactive Administration**
1. For human-driven admin work, use an `org:admin` OAuth bearer token via the `ant` CLI under a dedicated profile (`ant auth login --profile admin --scope "org:admin"`) instead of handling a static admin key — interactive tokens are short-lived and refresh on demand
2. Reserve static admin keys for non-interactive integrations that cannot complete an OAuth flow, and consider Workload Identity Federation for CI (see the [Claude API guide](/guides/anthropic-api/))

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="1.3" %}

#### Validation & Testing
1. Validate admin key works via `/v1/organizations/me` endpoint
2. Verify admin key is stored in secrets manager (not plaintext)
3. Confirm admin key naming convention is followed

**Expected result:** All admin keys are named, stored securely, and have documented owners

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC6.6 | Logical access; security of system boundaries |
| **NIST 800-53** | IA-5, SC-12 | Authenticator management; cryptographic key management |
| **ISO 27001** | A.9.4.3 | Password management system |

---

### 1.4 Enforce Tenant Restrictions at the Network Edge

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 12.3, 3.3 |
| NIST 800-53 | SC-7, AC-4 |

#### Description
Configure your egress proxy to inject the `anthropic-allowed-org-ids` header on traffic to Anthropic, so only your organization's Claude tenants are reachable from corporate networks — blocking personal Claude accounts across web, desktop, API keys, and OAuth (Enterprise and Console).

#### Rationale
**Why This Matters:**
- Product-level controls govern YOUR org; they do nothing about an employee pasting corporate data into a personal Claude account from the corporate network
- Tenant pinning at the network edge is the platform-wide backstop that the per-product controls (connector verified-domain protection, Claude Code org pinning) each cover only partially
- Enforcement spans surfaces: claude.ai web, desktop apps, API key usage, and OAuth flows

**Attack Prevented:** Corporate-data exfiltration through personal Claude tenants on managed networks

#### ClickOps Implementation

1. Collect your organization IDs (claude.ai org and Console org): Console organizations show the ID at **Settings** → **Organization**; Enterprise organizations show it at **Organization settings** → **Organization** (bottom of the page) or **Settings** → **Account**
2. Configure the egress proxy/SWG to inject `anthropic-allowed-org-ids: <org-id>[,<org-id>]` on requests to Anthropic domains, and to **overwrite** the header on every request rather than add it only when absent
3. Roll out in monitor mode first, then enforce
4. Pair with [Claude Code login pinning](/guides/claude-code/) (`forceLoginOrgUUID`) for the client-side half

**Time to Complete:** ~2 hours with proxy change control

#### Code Implementation

Anthropic exposes no API that sets tenant restrictions; the proxy does. This pack verifies enforcement from inside the managed network: a key from an organization that is not allowlisted must get HTTP 403 with `tenant_restriction_violation`, and an allowlisted key must still be served.

{% include pack-code.html vendor="anthropic-claude" section="1.4" %}

#### Validation & Testing
1. From a corporate network, sign-in to a personal Claude account is refused
2. Org-tenant access works unchanged across web, desktop, and API

**Expected result:** Only sanctioned tenants reachable from managed networks. ([Tenant Restrictions](https://support.claude.com/en/articles/13198485-enforce-network-level-access-control-with-tenant-restrictions))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.7 | Restrict transmission of information |
| **NIST 800-53** | SC-7, AC-4 | Boundary protection; information flow enforcement |

---

### 1.5 Bound Interactive Session Lifetimes

**Profile Level:** L2 (Walk)

#### Description
Choose a finite session duration on each child organization. The published Cowork baseline recommends seven days, with one day for higher assurance; this is guidance, not a claim about the Security Center’s exact pass value.

#### Rationale
**Why This Matters:**
- A stolen authenticated session can outlive an IdP policy change.
- Shortening the duration immediately expires sessions older than the new limit and may interrupt scheduled work.

**Attack Prevented:** Persistent use of stolen interactive sessions.

#### ClickOps Implementation

1. Open **claude.ai → Organization settings → Organization and access → Session security → Shortened session length** (Admin or above). Enterprise offers 1, 7, 14 or 28 days; choose seven days or a documented stricter requirement.
2. For Console, use **Settings → Organization and access → Session security**; its choices are 1, 3 or 7 days. Do not assume identical plan choices.
3. Pilot before shortening. Document the effect on unattended schedules, authentication dependencies and the recovery owner. Do not treat the default active-session behavior as a 28-day absolute limit.

**Automation:** Unverified — no write handle verified for this setting in the inspected public Admin/Compliance references. Configure it on the documented surface; the effective-settings read pack in [Enterprise 2.4](/guides/claude-enterprise/#24-assess-effective-settings-against-an-explicit-baseline) covers only rows actually returned, not device policy or manual attestations.

#### Validation & Testing
1. Read `account_session_duration_seconds` through Enterprise effective settings where returned; null means no limit, missing means unavailable/not admin-controllable.
2. Verify sign-in expiry with a pilot account and confirm required scheduled work still authenticates.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
Expect reauthentication. Increasing or disabling the limit does not restore already expired sessions; existing expirations can remain scheduled.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [support.claude.com](https://support.claude.com/en/articles/13163631-configuring-session-security-settings) · [trust.anthropic.com](https://trust.anthropic.com/resources?name=claude-cowork-security-best-practices&s=uukz8hyx7jmdmo80lys36s) (checked 2026-11-05).

---

### 1.6 Prevent Shadow Accounts and Plan Domain Capture

**Profile Level:** L2 (Walk)

#### Description
Verify company domains, restrict new organization creation, and separately decide whether to claim existing personal accounts. Domain capture is an irreversible migration decision, not a routine toggle to test.

#### Rationale
**Why This Matters:**
- Verified email domains do not by themselves force existing personal accounts into an Enterprise.
- Migration changes the organization’s access to account data and can disrupt users unless SSO and provisioning already work.

**Attack Prevented:** Corporate data leaving through unmanaged personal accounts or shadow organizations.

#### ClickOps Implementation

1. As an Owner, open **Organization settings → Organization and access → Security** and review **Restrict organization creation** for verified domains. Team plans can block new personal accounts but cannot claim existing ones.
2. For Enterprise domain capture, verify DNS, actively enforce SSO and enable JIT or SCIM first. Review/export the discovered personal-account inventory and plan the migration with affected owners.
3. Only after that review, decide whether to enable **Migrate accounts using your domain**. Follow the current migration procedure; do not enable it as an audit or promise a rollback.

**Automation:** Unverified — no write handle verified for this setting in the inspected public Admin/Compliance references. Configure it on the documented surface; the effective-settings read pack in [Enterprise 2.4](/guides/claude-enterprise/#24-assess-effective-settings-against-an-explicit-baseline) covers only rows actually returned, not device policy or manual attestations.

#### Validation & Testing
1. Confirm the domain, SSO enforcement and provisioning prerequisites independently.
2. Check new account/organization restrictions and migration outcomes with a specifically approved pilot; retain a record of scope and notices.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
Capture cannot be reversed. Local/device org pinning and connector Domain Guard remain separate controls, including off-network users.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [support.claude.com](https://support.claude.com/en/articles/14625619-claim-and-migrate-accounts-on-your-domain) · [trust.anthropic.com](https://trust.anthropic.com/resources?name=claude-cowork-security-best-practices&s=uukz8hyx7jmdmo80lys36s) (checked 2026-11-05).

---

### 1.7 Separate Parent Administration from Child Access

**Profile Level:** L2 (Walk)

#### Description
For organizations enrolled in centralized management (beta), review the parent at admin.claude.com as a separate privileged plane. Enrollment does not merge child organizations or grant parent administrators access to their content.

#### Rationale
**Why This Matters:**
- Parent Owners can assign parent administrators; parent Admins manage company identity but cannot assign those roles.
- A parent-wide Compliance key can read across linked organizations even though a parent role alone does not grant child membership.

**Attack Prevented:** Cross-organization privilege expansion through centralized identity or audit credentials.

#### ClickOps Implementation

1. If already enrolled, open **admin.claude.com → Admin roles** and minimize the named parent Owners and Admins; review each child organization’s membership independently.
2. Review parent **Identity providers**, **Domains**, **Groups** and **API keys**. With multiple IdPs, check each domain’s routing, SSO enforcement, directory and each child’s group-to-role mappings. Split domains require SCIM or invite-only provisioning, not JIT.
3. Treat enrollment as a separate approved project: every child must approve, and final approval completes an irreversible transition. Do not enroll solely to follow this guide. Marketplace and HIPAA eligibility have beta limitations.
4. Before disabling/removing an IdP, migrate domain routes and group mappings. Removing the last SSO can turn off Require SSO; disconnected directories can remove members or switch provisioning to invite-only, and reconnecting does not restore the mode automatically.

**Automation:** Unverified — no write handle verified for this setting in the inspected public Admin/Compliance references. Configure it on the documented surface; the effective-settings read pack in [Enterprise 2.4](/guides/claude-enterprise/#24-assess-effective-settings-against-an-explicit-baseline) covers only rows actually returned, not device policy or manual attestations.

#### Validation & Testing
1. Reconcile parent roles, child roles and key scopes separately; a successful child-role audit is insufficient.
2. Verify fresh sign-in and offboarding for each domain/IdP and retain an independent recovery path before changes.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
Identity changes can affect every child. Use current enrollment eligibility and recovery instructions; do not infer a safe reversal from the continued existence of the child orgs.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [support.claude.com](https://support.claude.com/en/articles/18232924-get-started-with-centralized-management) · [support.claude.com](https://support.claude.com/en/articles/18246779-set-up-multiple-identity-providers-and-split-domains) (checked 2026-11-05).

---

### 1.8 Restrict Source IPs with Explicit App Exceptions

**Profile Level:** L2 (Walk)

#### Description
Use each Enterprise or Console organization’s IP allowlist to limit covered access to approved public egress addresses. This controls where a request originates; tenant restrictions in 1.4 control which organization can be used.

#### Rationale
**Why This Matters:**
- A leaked key or session is harder to replay outside approved networks.
- Parent-wide keys, excluded products and already running work need separate containment.

**Attack Prevented:** Replay of stolen sessions or API credentials from unapproved networks.

#### ClickOps Implementation

1. Enterprise Owners open **Organization settings → Organization and access → IP allowlist**; Console Admins use **Identity and access**. Record the current public IPv4/IPv6 egress of users, CI, VPNs, proxies and `bridge.claudeusercontent.com`.
2. Add narrow public ranges; validate all needed sources before saving. The vendor recommends the **Allow owners/admins to access this settings page from any IP address** recovery option, which also lets a compromised privileged session change the list remotely. Document that tradeoff and a tested recovery path.
3. Allow up to 15 minutes and test both allowed and disallowed networks. API/Compliance restrictions apply to keys bound to one org, not parent-wide keys.
4. Record exclusions: Enterprise Claude Design, Claude in Slack and Academy; externally shared artifacts; Science has partial coverage. Blocked chat tasks can continue up to 24 hours. Managed Agents API coverage does not restrict the agent runtime’s egress; cloud-provider variants have their own controls.

**Automation:** Unverified — no write handle verified for this setting in the inspected public Admin/Compliance references. Configure it on the documented surface; the effective-settings read pack in [Enterprise 2.4](/guides/claude-enterprise/#24-assess-effective-settings-against-an-explicit-baseline) covers only rows actually returned, not device policy or manual attestations.

#### Validation & Testing
1. Read `ip_allowlist_enabled` and `ip_allowlist_ip_ranges` where returned; enabled resolves false when there is no active range.
2. Validate covered-app rejection and successful recovery separately; review every exception rather than declaring the whole platform contained.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
Missing a NAT/VPN/mobile source can block admins and workloads. Restore through a listed network, the limited recovery page, another authorized owner or Anthropic support; an IP block does not erase device data.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/ip-allowlisting) · [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/compliance-org-data) (checked 2026-11-05).

---

## 2. Third-Party Integration Security

### 2.1 Audit and Clean Up Pending Invites

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-2(3) |
| SOC 2 | CC6.2 |

#### Description
Regularly audit pending organization invites. Invites in Anthropic expire after 21 days (not configurable). Stale or unauthorized invites should be revoked promptly. The invite system supports role assignment at invite time, so a malicious invite could grant elevated access.

#### Rationale
**Why This Matters:**
- Pending invites represent pre-authorized access that hasn't been claimed
- An attacker who gains access to an invited email account could join the organization
- Invites specify the role upfront — verify that invited roles follow least privilege

**Attack Prevented:** Unauthorized organization access via intercepted/forwarded invites

#### Prerequisites
- Organization Admin access

#### ClickOps Implementation

**Step 1: Review Pending Invites**
1. Navigate to: **platform.claude.com** → **Settings** → **Members** → **Invites**
2. Review each pending invite: email, role, creation date
3. Revoke any invite where the recipient is unknown or no longer needed

**Step 2: Establish Invite Policy**
1. Require approval before sending invites
2. Review pending invites weekly
3. Use the lowest necessary role for each invite (invites cannot use `admin` role via API)

**Time to Complete:** ~5 minutes

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="6.1" %}

#### Validation & Testing
1. Run invite audit script — verify no stale pending invites
2. Attempt to create invite with admin role via API — should fail (by design)
3. Confirm expired invites cannot be accepted

**Expected result:** All pending invites are reviewed, authorized, and time-bound

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2 | Prior to issuing system credentials and granting system access |
| **NIST 800-53** | AC-2(3) | Account management — disable accounts |
| **ISO 27001** | A.9.2.1 | User registration and de-registration |

---

### 2.2 Integration Risk Assessment

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | RA-3, SA-9 |
| SOC 2 | CC3.2, CC9.2 |

#### Description
Assess the security posture of applications and services that consume your Claude API keys. API keys are bearer tokens — any application with the key can make requests on your behalf within the workspace scope.

#### Rationale
**Why This Matters:**
- Any application holding your API key can generate costs and access model capabilities
- Third-party tools (LangChain, LlamaIndex, custom applications) embed API keys
- A compromised third-party application with your key = a compromised key

**Attack Prevented:** Key compromise via insecure third-party applications, unauthorized API usage through embedded bearer tokens

#### Integration Risk Assessment Matrix

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **Data Sensitivity** | Non-sensitive prompts | Internal business data | PII, financial, health data |
| **Key Scope** | Dedicated low-limit workspace | Shared development workspace | Production workspace |
| **Application Trust** | First-party, audited code | Vendor with SOC 2 | Unaudited open-source tool |
| **Key Storage** | Secrets manager | Environment variable | Hardcoded or config file |
| **Rate Limit** | Strict per-workspace limits | Moderate limits | Organization-level defaults |

**Decision Matrix:**
- **0-5 points:** Standard controls (workspace scoping, naming)
- **6-10 points:** Enhanced controls (dedicated workspace, low spend limits, key rotation)
- **11-15 points:** Reject or isolate (dedicated workspace with minimum limits, frequent rotation, monitoring)

#### ClickOps Implementation

**Step 1: Inventory the Keys and Their Consumers**
1. Navigate to: **platform.claude.com** → **Settings** → **API keys**
2. For each active key, record the application that holds it, the owner, and the key's workspace

**Step 2: Score Each Integration**
1. Score every integration against the risk matrix above
2. Record the rating and owner next to the key in your inventory

**Step 3: Apply Controls by Score**
1. For integrations scoring 6 or more, navigate to: **platform.claude.com** → **Settings** → **Workspaces** and create a dedicated workspace for that consumer
2. On the workspace's **Spend limits** and **Rate limits** tabs, set limits below the organization's (a workspace limit can be lower than, but not higher than, the organization's; the Default Workspace cannot carry limits at all)
3. Issue the consumer a new key scoped to that workspace, then disable the old key on the **API keys** page

**Time to Complete:** ~1 hour per 10 integrations

#### Code Implementation

The scoring stays a human judgement. This read-only pack supplies the matrix's **Key Scope** factor: every active key, labelled by the workspace it belongs to, the Default Workspace, or the organization (a principal-bound key with no workspace).

{% include pack-code.html vendor="anthropic-claude" section="6.2" %}

#### Validation & Testing
1. Maintain inventory of all applications using Claude API keys
2. Verify each application's key is in an appropriately scoped workspace
3. Confirm keys are stored in secrets managers, not in source code

**Expected result:** All API key consumers are inventoried with risk ratings and appropriate controls

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC3.2, CC9.2 | Risk assessment; vendor and third-party risk management |
| **NIST 800-53** | RA-3, SA-9 | Risk assessment; external system services |
| **ISO 27001** | A.15.1.2 | Addressing security within supplier agreements |

---

### 2.3 Enforce Signed Inference Hooks on Governed Requests

**Profile Level:** L3 (Run)

#### Description
For Claude Enterprise, route governed prompts and pre-tool-call frames through a reviewed AI security server. Stage in shadow mode, then explicitly enforce denials and fail closed if inline inspection is mandatory. These hooks do not cover Console API organizations or cloud-provider inference.

#### Rationale
**Why This Matters:**
- A post-event Compliance integration cannot stop a sensitive prompt before inference.
- Enabling the feature, sampling, role exclusions, fail-open handling and circuit-breaker operation can all leave requests uninspected.

**Attack Prevented:** Sensitive-text disclosure and policy-violating tool execution on governed surfaces.

#### ClickOps Implementation

1. An Owner/Primary Owner opens **Organization settings → Data and privacy → Inference hooks**, allows the feature, and configures a public HTTPS endpoint on port 443 without redirects or reverse tunnels. Allowing it forces **Enforce verdicts** off, even for a prior configuration.
2. Store the generated signing secret in the approved secret manager. The server must verify raw request bytes, Standard Webhooks HMAC signatures and a five-minute timestamp bound. Enforce idempotency on webhook-id; reject unsigned requests after a signing secret exists. Never put transcripts or secrets into routine diagnostic logs.
3. Test an allow and a deny through **Test connection**. Begin in **Shadow mode** and assess false positives; then set **Block the request**, **Requests inspected: 100%**, **Enforce verdicts: on**, **Validate tool calls: on** and review all exclusions. Default failure handling is Allow, and shadow mode never blocks.
4. Prefer all governed roles for a baseline: **Only selected roles** inspects only members set to Custom with a selected role, excludes built-in roles and requests without a member (including Tag Slack conversations). Sampling below 100% allows the unsampled turns through even with fail-closed selected.
5. Monitor endpoint health and `inference_hooks_circuit_breaker_tripped`; the circuit breaker applies failure handling to every request and has no per-request hook events while tripped. Keep an approved availability/recovery procedure.

#### Code Implementation

The documented setup is console-managed; the custom HTTPS verdict protocol is not a settings write API. Use the vendor’s [integration implementation and signature reference](https://platform.claude.com/docs/en/manage-claude/inference-hooks-endpoint) and the [Activity Feed detection pack](/guides/claude-enterprise/#21-export-and-retain-audit-logs). No undocumented toggle endpoint is supplied.

#### Validation & Testing
1. Test denial, endpoint timeout and circuit-breaker behavior in an approved pilot before relying on enforcement; confirm feed events and signature rejection.
2. Record gaps: raw images/files, system prompts and definitions are not sent; some internal/voice tool calls and hosted Security/Code Review model calls are excluded. A deny does not remove the already stored conversation.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
Adds synchronous latency and grants the endpoint access to transcript text. Full enforcement can stop all governed work during endpoint failure; fail open preserves availability but loses inspection.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/inference-hooks-configuration) · [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/inference-hooks) · [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/inference-hooks-endpoint) (checked 2026-11-05).

---

## 3. Compliance Quick Reference

The original tables below map controls 1.1–1.4 and 2.1–2.2; the new controls carry their own mappings above. The SOC 2, NIST 800-53 and ISO 27001 IDs are taken from the controls' own mapping tables. The NIST CSF 2.0 and AI RMF tables map the same controls at category level only, and no control's own table repeats those categories. Each product guide ([Claude Enterprise](/guides/claude-enterprise/), [Claude Code](/guides/claude-code/), [Claude API & Console](/guides/anthropic-api/)) carries the mappings for its own controls.

### SOC 2 Trust Services Criteria Mapping

| Control ID | Anthropic Claude Control | Guide Section |
|-----------|--------------------------|---------------|
| CC3.2 | Integration Risk Assessment | 2.2 |
| CC6.1 | Enforce SSO, Least-Privilege Roles, Admin API Key Protection | 1.1, 1.2, 1.3 |
| CC6.2 | Pending Invite Audit | 2.1 |
| CC6.3 | Least-Privilege Roles | 1.2 |
| CC6.6 | Admin API Key Protection | 1.3 |
| CC6.7 | Tenant Restrictions | 1.4 |
| CC9.2 | Integration Risk Assessment | 2.2 |

### NIST 800-53 Rev 5 Mapping

| Control | Anthropic Claude Control | Guide Section |
|---------|--------------------------|---------------|
| AC-2(3) | Pending Invite Audit | 2.1 |
| AC-4 | Tenant Restrictions (information flow) | 1.4 |
| AC-6, AC-6(1) | Least-Privilege Roles | 1.2 |
| IA-2 | SSO Enforcement | 1.1 |
| IA-5 | Admin API Key Protection | 1.3 |
| IA-8 | Non-Organization User Authentication | 1.1 |
| RA-3 | Integration Risk Assessment | 2.2 |
| SA-9 | External System Services | 2.2 |
| SC-7 | Boundary Protection (Tenant Restrictions) | 1.4 |
| SC-12 | Cryptographic Key Management | 1.3 |

### ISO 27001 Mapping

Control IDs use the ISO/IEC 27001:2013 Annex A numbering, as in each control's own table.

| Control | Anthropic Claude Control | Guide Section |
|---------|--------------------------|---------------|
| A.9.2.1 | User Registration and De-registration | 1.1, 2.1 |
| A.9.2.3 | Privileged Access Management | 1.2 |
| A.9.4.3 | Password/Key Management | 1.3 |
| A.15.1.2 | Supplier Security | 2.2 |

### NIST Cybersecurity Framework (CSF) 2.0 Mapping

| Function.Category | Anthropic Claude Control | Guide Section |
|-------------------|--------------------------|---------------|
| **PR.AA** (Protect: Identity Management, Authentication, and Access Control) | SSO, least-privilege roles, admin key protection, tenant restrictions | 1.1, 1.2, 1.3, 1.4 |
| **GV.SC** (Govern: Cybersecurity Supply Chain Risk Management) | Risk rating of third-party applications that hold API keys | 2.2 |

### NIST AI Risk Management Framework (AI RMF) Mapping

| Function | Anthropic Claude Control | Guide Section |
|----------|--------------------------|---------------|
| **GOVERN 2** (Accountability) | SSO, defined admin roles, tenant restrictions | 1.1, 1.2, 1.4 |
| **GOVERN 6** (Third-Party & Supply Chain) | Risk rating of third-party applications that hold API keys | 2.2 |

---

## Appendix A: Edition/Tier Compatibility

This table covers this hub's controls. Product-specific availability is in each product guide.

| Control | API (All Tiers) | Team | Enterprise |
|---------|----------------|------|------------|
| 1.1 Enforce SSO | ✅ (Console organizations, once SSO is enabled via Anthropic Sales or an organization merge) | ✅ | ✅ |
| 1.2 Least-Privilege Roles | ✅ | ✅ | ✅ |
| 1.3 Admin Key Protection | ✅ | ✅ | ✅ |
| 1.4 Tenant Restrictions | ✅ (Console org IDs can be allowlisted) | Not documented | ✅ |
| 2.1 Invite Auditing | ✅ | ✅ | ✅ |
| 2.2 Integration Risk | ✅ | ✅ | ✅ |
| SCIM Provisioning | ❌ | ❌ | ✅ |
| Audit Logs | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Anthropic Documentation:**
- [Admin API Overview](https://platform.claude.com/docs/en/manage-claude/admin-api)
- [Admin API Reference](https://platform.claude.com/docs/en/api/admin)
- [Create an Admin API Key (both org types + Enterprise scope table)](https://platform.claude.com/docs/en/manage-claude/admin-api-keys)
- [Authentication & Key Expiration](https://platform.claude.com/docs/en/manage-claude/authentication)
- [Workspaces Guide](https://platform.claude.com/docs/en/manage-claude/workspaces)
- [Rate Limits](https://platform.claude.com/docs/en/api/rate-limits)
- [Data Residency](https://platform.claude.com/docs/en/manage-claude/data-residency)
- [API Data Retention (incl. Zero Data Retention)](https://platform.claude.com/docs/en/manage-claude/api-and-data-retention)
- [Usage and Cost API](https://platform.claude.com/docs/en/manage-claude/usage-cost-api)

**Identity Provider Integration:**
- [SSO Setup Guide](https://support.anthropic.com/en/articles/13132885-setting-up-single-sign-on-sso)
- [SCIM Provisioning Guide](https://support.anthropic.com/en/articles/13133195-setting-up-jit-or-scim-provisioning)
- [Console Roles and Permissions](https://support.anthropic.com/en/articles/10186004-api-console-roles-and-permissions)

**Claude Code Security:**
- [Claude Code Security Best Practices](https://code.claude.com/docs/en/security)
- [Claude Code Sandboxing](https://code.claude.com/docs/en/sandboxing)
- [Claude Code Permissions](https://code.claude.com/docs/en/permissions)
- [Claude Code Settings Reference](https://code.claude.com/docs/en/settings)
- [Claude Code Hooks](https://code.claude.com/docs/en/hooks)
- [Claude Code MCP Configuration](https://code.claude.com/docs/en/mcp)
- [Claude Code Monitoring (OpenTelemetry)](https://code.claude.com/docs/en/monitoring-usage)
- [Claude Code GitHub Actions](https://code.claude.com/docs/en/github-actions)

**Open-Source Security Tools:**
- [nono — Kernel-Enforced Agent Sandbox](https://github.com/always-further/nono) (Apache-2.0)
- [NVIDIA OpenShell — Container Agent Sandbox](https://github.com/NVIDIA/OpenShell) (Apache-2.0)
- [claude-code-safety-net — Destructive Command Hook](https://github.com/kenryu42/claude-code-safety-net) (MIT)
- [claude-code-security-review — AI Security Review Action](https://github.com/anthropics/claude-code-security-review) (MIT)
- [claude-code-action — GitHub Actions Integration](https://github.com/anthropics/claude-code-action) (MIT)
- [step-security/harden-runner — CI/CD Network Egress Control](https://github.com/step-security/harden-runner) (Apache-2.0)
- [snyk/agent-scan — AI Agent and MCP Server Security Scanner](https://github.com/snyk/agent-scan) (Apache-2.0)
- [stacklok/toolhive — Enterprise MCP Server Management](https://github.com/stacklok/toolhive) (Apache-2.0)
- [cisco-ai-defense/mcp-scanner — MCP Threat Scanner](https://github.com/cisco-ai-defense/mcp-scanner) (Apache-2.0)
- [stacklok/codegate — AI Coding Assistant Security Gateway](https://github.com/stacklok/codegate) (Apache-2.0)
- [trailofbits/claude-code-devcontainer — Sandboxed Devcontainer](https://github.com/trailofbits/claude-code-devcontainer) (Apache-2.0)
- [wiz-sec-public/secure-rules-files — Baseline Secure CLAUDE.md Files](https://github.com/wiz-sec-public/secure-rules-files)
- [seojoonkim/prompt-guard — Prompt Injection Defense System](https://github.com/seojoonkim/prompt-guard) (MIT)
- [vexscan — Plugin/Skill Security Scanner](https://github.com/edimuj/vexscan-claude-code)

**Security Research:**
- [Pillar Security: Rules File Backdoor Attack](https://www.pillar.security/blog/new-vulnerability-in-github-copilot-and-cursor-how-hackers-can-weaponize-code-agents) (2025)
- [Snyk: ToxicSkills — Malicious AI Agent Skills Study](https://snyk.io/blog/toxicskills-malicious-ai-agent-skills-clawhub/) (February 2026)
- [Lasso Security: Indirect Prompt Injection in Claude Code](https://www.lasso.security/blog/the-hidden-backdoor-in-claude-coding-assistant) (2026)
- [Cymulate: InversePrompt (CVE-2025-54794, CVE-2025-54795)](https://cymulate.com/blog/cve-2025-547954-54795-claude-inverseprompt/) (2025)
- [StepSecurity: Securing claude-code-action in GitHub Actions](https://www.stepsecurity.io/blog/anthropics-claude-code-action-security-how-to-secure-claude-code-in-github-actions-with-harden-runner) (2026)
- [Check Point: RCE and API Token Exfiltration via Claude Code (CVE-2025-59536)](https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/) (2026)
- [PromptArmor: Claude Cowork File Exfiltration](https://www.promptarmor.com/resources/claude-cowork-exfiltrates-files) (2026)
- [Oasis Security: Claudy Day — Claude.ai Prompt Injection Chain](https://www.oasis.security/blog/claude-ai-prompt-injection-data-exfiltration-vulnerability) (2026)
- [Invariant Labs: MCP Tool Poisoning Attacks](https://invariantlabs.ai/blog/mcp-security-notification-tool-poisoning-attacks) (2025)
- [OWASP Top 10 for Agentic Applications 2026](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/)
- [Redguard: Arbitrary Code Execution in Claude Code (CVE-2025-59828)](https://www.redguard.ch/blog/2025/12/19/advisory-anthropic-claude-code/) (2025)

**Claude Cowork:**
- [Use Cowork on Team and Enterprise Plans](https://support.claude.com/en/articles/13455879-use-cowork-on-team-and-enterprise-plans)
- [Use Cowork Safely](https://support.claude.com/en/articles/13364135-use-cowork-safely)
- [Use Plugins in Cowork](https://support.claude.com/en/articles/13837440-use-plugins-in-cowork)
- [Securing Claude Cowork — Harmonic Security](https://www.harmonic.security/resources/securing-claude-cowork-a-security-practitioners-guide)
- [Claude Cowork Security — MintMCP](https://www.mintmcp.com/blog/claude-cowork-security)

**Security and Compliance:**
- [Anthropic Usage Policy](https://www.anthropic.com/legal/aup)
- [Anthropic Trust Center](https://trust.anthropic.com)
- [Custom Data Retention (Enterprise)](https://support.anthropic.com/en/articles/10440198-custom-data-retention-controls-for-claude-enterprise)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-11 | 1.3.1 | ai-drafted | Link dedicated Claude Tag hardening guide and current research/automation boundaries. | OpenAI Codex |
| 2026-11-05 | 1.3.0 | ai-drafted | Source-first refresh: public recommended baseline and Government/FISMA scope; session/domain/parent/IP controls and signed inference hooks; corrected access and assurance boundaries. Removed prior ai-validated status and stale surface marks after revising credential/identity guidance; public-source/offline checks only. | Codex |
| 2026-10-04 | 1.2.1 | ai-drafted · ai-validated | validate-hth-guide run against a live Claude Console organization (Evaluation access): 4 surfaces came back VERIFIED-LIVE across 3 of 6 controls — ClickOps 1.2 (Members), 1.3 (Admin keys: a short-lived key was created and then deleted) and 2.2 (API keys, Workspaces); Code 1.3 (the admin-key validity pack, run with a short-lived admin key that was revoked afterwards: exit 0 with the live key, exit 1 with an invalid and with the revoked key). The 1.1 and 1.2 Code packs also ran read-only but are not marked: 1.01 lists members and cannot see SSO state, and 1.02 ran against a one-member org that cannot exceed its admin threshold. 1.4 and 2.1 were not exercised (no egress proxy; no pending invite), and 6.02 ran against an org with no API keys, so its Code surface is not marked. §1.1 corrected against the live Console and the SSO setup article: the Console page is **Identity and access**, its SSO controls are **Setup SSO**/**Manage SSO** under Authentication and appear only once SSO is enabled via Anthropic Sales or an organization merge, the enforcement toggles are **Require SSO for Console**/**Require SSO for Claude**, SSO is available to Console organizations as well as Team and Enterprise, and the roles are Owner/Primary Owner or Console Admin; Appendix A no longer marks 1.1 N/A for Console organizations. SSO Steps 2–4 were not walked live. | `Claude Code (Opus 5.5)` |
| 2026-09-25 | 1.2.0 | ai-drafted | validate-hth-guide run (Phases 4-6, including an independent audit). The live Console stayed behind its sign-in wall and no Admin API key could be minted, so 0 surfaces were exercised live and no status was added; packs were exercised offline against a mock of the documented Admin API. Fixes: the shared POST helper appended a stray `}` to every request body, so 1.02's role change could never send valid JSON (now fixed, and 1.02 keeps the API's response, a member record, off stdout); packs 1.01, 1.02, 1.03 and 6.01 now exit 1 when an API call fails (they printed `[FAIL]` and exited 0) and page through `has_more`/`last_id` with `limit=1000` (the shared helper read a `next_page` field the API never returns, so every list stopped at 20 entries); the admin key reaches curl as a header file instead of a command-line argument; 1.01 drops the Linux-only `column -N`; 6.01 prints `invited_at` (invites have no `created_at`); 1.02 matches undocumented roles exactly; 1.02 and 6.01 now declare `mode: mutating` for their opt-in write branches, which also validate their inputs. New read-only packs: 1.04 verifies tenant restrictions from inside the network against the documented HTTP 403 `tenant_restriction_violation`; 6.02 inventories active API keys by scope (workspace, Default Workspace, organization) for 2.2. §2.2 gains ClickOps steps (Settings → API keys, workspace limits under Settings → Workspaces). §1.4 names where each organization type shows its organization ID and says to overwrite the header. §1.2: Limited Developer is a workspace role, not an organization role. §3 and Appendix A rebuilt around this hub's six controls (they cited sections 3.1-7.11, which now live in the product guides); CSF 2.0 `PR.AC` corrected to `PR.AA`; ISO IDs labelled as 2013 Annex A numbering; §3 now says its CSF 2.0 and AI RMF rows are category-level mappings that no control table carries; §1.4's Compliance Mappings table gains `AC-4`, which its header table already listed. Usage Policy link moved to anthropic.com/legal/aup; doc_links.yml points at platform.claude.com and academy.claude.com directly. Correction to the 1.1.0 row: Anthropic documents the OAuth access-token prefix quoted there for tokens issued by `POST /v1/oauth/token` (WIF reference); the prefix of interactive `ant auth login --scope "org:admin"` tokens is not documented and was not verified. | `Claude Code (Opus 5.5)` |
| 2026-08-15 | 1.1.0 | ai-drafted | Admin API currency pass against platform.claude.com. §1.2 role model corrected to the two-org-type picture: five Console/API roles plus the Console UI's Limited Developer tier, `owner`/`primary_owner` above admin, `managed`/`membership_admin` on the Enterprise side, and the full nine-value API role enum documented so audit scripts stop silently miscounting; the admin-assignment and admin-removal API blocks are now quoted from the current references. §1.3 rebuilt on the two-track credential model — Console admin keys (`sk-ant-admin01-`, no selectable scopes) vs Claude Enterprise scoped keys (`sk-ant-api01-`, 12-scope table, primary-owner/org-owner creation split) — plus key expiration at creation, the organization maximum-expiration policy, the `org:admin` OAuth bearer path via the `ant` CLI (dedicated admin profile, `sk-ant-oat01-` prefix added for secret-scanning coverage), and the WIF-endpoints carve-out (service-account/federation endpoints reject admin keys). References moved to canonical platform.claude.com URLs — two of the old docs.anthropic.com links were dead 404s. Roles pack rewritten to count the full enum and the elevated tier; rotation pack now audits `expires_at`. | `Claude Code (Opus 5)` |
| 2026-02-21 | 0.1.0 | ai-drafted | Initial guide: 12 controls across 6 categories, API pack scripts for Admin API | `Claude Code (Opus 4.6)` |
| 2026-02-21 | 0.2.0 | ai-drafted | Added Section 7: Claude Code Enterprise Controls — MDM managed settings, permission restrictions, MCP server control, developer analytics | `Claude Code (Opus 4.6)` |
| 2026-02-21 | 0.3.0 | ai-drafted | Added MDM config templates (L1/L2/L3 profiles), permission deny rule examples, sandbox config, managed-mcp.json template, MCP allowlist/denylist config | `Claude Code (Opus 4.6)` |
| 2026-02-21 | 0.4.0 | ai-drafted | Added Config-as-Code pack type with standalone .jsonc config files; added code pack buttons, doc links; moved JSON configs from API scripts to config/ directory | `Claude Code (Opus 4.6)` |
| 2026-03-27 | 0.5.0 | ai-drafted | Major expansion: Added 6 new controls (7.5-7.10) — Bash sandbox isolation, hook/plugin lockdown, prompt injection defense, CI/CD pipeline hardening, external sandbox tooling (nono, OpenShell), Cowork governance. Updated 7.1 with drop-in directory, plist/registry delivery, new managed settings. Added comprehensive references for security research (ToxicSkills, Rules File Backdoor, InversePrompt CVEs) and open-source tools. Updated all compliance mappings. | `Claude Code (Opus 4.6)` |
| 2026-04-06 | 0.6.0 | ai-drafted | Added 7.11 Incident Response (kill-switch, forensic collection, AI agent IR scenarios, tabletop exercises). Major expansion of 7.10 Cowork: Chrome hardening (allowlist/blocklist, default gap warnings), global defensive instructions, dedicated workspace scoping, scheduled task governance, plugin install preferences, tenant restriction details (exact header format, proxy platforms, error codes), data training opt-out by tier, web search egress bypass warning, OTel prompt content toggle. Added NIST CSF 2.0 and NIST AI RMF compliance mappings. Added web search bypass warning to 7.5 sandbox. | `Claude Code (Opus 4.6)` |
| 2026-05-06 | 0.7.0 | ai-drafted | Added 2.3 Eliminate Static API Keys via Workload Identity Federation: covers Anthropic's new WIF capability (RFC 7523 jwt-bearer flow against `POST /v1/oauth/token`), Console setup walkthrough for federation issuers / service accounts / federation rules, IdP coverage (AWS / GCP / Azure-Entra / GitHub Actions / Kubernetes / SPIFFE / Okta), credential precedence pitfalls (`ANTHROPIC_API_KEY` shadowing WIF), token lifetime/refresh semantics, JWKS rotation gotchas, and migration runbook. Code Packs: token-exchange script with static-key guardrail (api/), reference hardened GitHub Actions workflow (config/), config-as-code WIF profile (config/), Python SDK pattern (sdk/). Verified against platform.claude.com/docs/en/manage-claude/workload-identity-federation and wif-reference. | `Claude Opus 4.7 (1M)` |
| 2026-08-08 | 1.0.1 | ai-drafted | Added "Products in This Platform" navigation section (product guide table mirroring the Google Workspace hub) so the Anthropic hub lists Claude Enterprise, Claude Code, and Claude API & Console with their coverage. No control changes. | `Claude Opus 5 (1M)` |
| 2026-08-08 | 1.0.2 | ai-drafted | Cheat-sheet cell repair: added missing Attack Prevented line(s) to §2.2 (no content-facts changed) | `Claude Code (Fable 5)` |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
