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
description: "Platform-wide security hardening for Anthropic — the Common Controls hub (SSO, organization roles, admin API keys, integration governance) shared by the Claude Enterprise, Claude Code, and Claude API & Console product guides."
version: "1.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-15"
---

## Overview

Anthropic is a multi-product AI platform: the claude.ai chat product (Team/Enterprise plans), Claude Code (the agentic coding tool), and the Claude API with its admin Console. Each product has a distinct hardening surface, so each has its own guide — this hub carries the **Common Controls** that span them: organization identity (SSO, roles), admin API key protection, and third-party integration governance. Anthropic provides a comprehensive Admin API for programmatic organization management alongside the web Console.

**Product guides:** [Claude Enterprise (claude.ai)](/guides/claude-enterprise/) · [Claude Code](/guides/claude-code/) · [Claude API & Console](/guides/anthropic-api/)

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

Anthropic is a multi-product platform. This guide is the **Common Controls hub** — the platform-wide controls that apply across every Anthropic product. Product-specific controls live in their own guides:

| Product | Guide | Covers |
|---------|-------|--------|
| **Common Controls** (this guide) | — | Organization SSO & SCIM, least-privilege organization roles, admin API key protection, third-party integration governance |
| **Claude Enterprise (claude.ai)** | [Claude Enterprise guide](/guides/claude-enterprise/) | Identity & provisioning, audit & compliance export, connectors & extensions, spend governance |
| **Claude Code** | [Claude Code guide](/guides/claude-code/) | Managed settings & policy deployment, extensions & supply chain, execution isolation & sandboxing, threat defense, monitoring & incident response |
| **Claude API & Console** | [Claude API & Console guide](/guides/anthropic-api/) | API key management, workspace security, data security & privacy, monitoring & usage controls |

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
- Automatic deprovisioning when users leave the organization

**Attack Prevented:** Credential theft, unauthorized access, orphaned accounts

#### Prerequisites
- Claude Team or Enterprise subscription
- SAML 2.0 or OIDC compatible identity provider (Okta, Azure AD, OneLogin, Google Workspace)
- Organization Admin access to Claude Console
- Domain ownership for domain verification

#### ClickOps Implementation

**Step 1: Access Identity & Access Settings**
1. Navigate to: **platform.claude.com** → **Settings** → **Identity & Access**
2. Click **Configure SSO**

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
2. Enable **Require SSO for all users**
3. Test login before full enforcement

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="1.1" %}

#### Validation & Testing
1. Attempt login without SSO — should be redirected to IdP
2. Complete SSO login — should succeed and land in Claude
3. Remove user from IdP group — should lose Claude access
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
Assign the minimum necessary organization role to each user. The role model differs by organization type, and the Admin API's `role` enum is wider than either product's assignable set — audit scripts must handle every value. **Claude Console / API organizations** assign `user`, `claude_code_user`, `developer`, `billing`, and `admin` (the Console UI additionally offers a **Limited Developer** tier between `user` and `developer`); above `admin` sit `owner` and `primary_owner`, which hold all admin permissions and additionally manage admins. **Claude Enterprise (claude.ai) organizations** manage members with `user` and `managed` via the API, and the enum also carries `membership_admin`. Limit the `admin` role (and its owner tiers) to a small number of trusted operators.

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
2. Ensure at least 2 (but no more than 3) admins remain for redundancy

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
3. Attempt to assign admin role via API — should fail (by design)
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
Admin credentials grant organization-wide management access — treat them with the same care as cloud provider root credentials. The credential model is now two-track, and differs by organization type. **Claude Console organizations** create Admin API keys (`sk-ant-admin01-...`) at **Console → Settings → Admin keys** (admin role required); Console admin keys have **no selectable scopes** — every key carries full access to all endpoints that accept admin keys. **Claude Enterprise (claude.ai) organizations** create *scoped* keys (`sk-ant-api01-...`) at **claude.ai → Organization settings → API**: the parent org's **primary owner** can create keys for all linked organizations, while an **organization owner** can create only Compliance-scoped keys restricted to their own organization. Separately, the Admin API also accepts a short-lived **OAuth bearer token with the `org:admin` scope** — and the service-account, federation-issuer, and federation-rule endpoints accept *only* that OAuth token, never an admin key.

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

1. Collect your organization IDs (claude.ai org and Console org)
2. Configure the egress proxy/SWG to inject `anthropic-allowed-org-ids: <org-id>[,<org-id>]` on requests to Anthropic domains
3. Roll out in monitor mode first, then enforce
4. Pair with [Claude Code login pinning](/guides/claude-code/) (`forceLoginOrgUUID`) for the client-side half

**Time to Complete:** ~2 hours with proxy change control

#### Validation & Testing
1. From a corporate network, sign-in to a personal Claude account is refused
2. Org-tenant access works unchanged across web, desktop, and API

**Expected result:** Only sanctioned tenants reachable from managed networks. ([Tenant Restrictions](https://support.claude.com/en/articles/13198485-enforce-network-level-access-control-with-tenant-restrictions))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.7 | Restrict transmission of information |
| **NIST 800-53** | SC-7 | Boundary protection |

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

## 3. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Anthropic Claude Control | Guide Section |
|-----------|--------------------------|---------------|
| CC6.1 | Enforce SSO, Least-Privilege Roles, API Key Scoping, Managed Settings, Sandbox, Hooks/Plugins, Prompt Injection Defense, Cowork Governance | 1.1, 1.2, 1.3, 2.1, 2.2, 7.1, 7.2, 7.5, 7.6, 7.7, 7.10 |
| CC6.2 | Invite Management, Workspace Membership | 3.2, 6.1 |
| CC6.3 | Role-Based Access, Workspace Scoping | 1.2, 2.1, 3.2 |
| CC6.6 | Workspace Segmentation, Data Residency | 1.3, 3.1, 4.1 |
| CC6.8 | Spend Limits, Sandbox Boundaries, External Sandbox | 5.2, 7.5, 7.9 |
| CC7.1 | CI/CD Pipeline Security | 7.8 |
| CC7.2 | Usage Monitoring, Cost Monitoring, Prompt Injection Detection, Cowork Audit | 5.1, 5.2, 7.7, 7.10 |
| CC8.1 | Managed Settings, Change Management, Hook/Plugin Governance, CI/CD Hardening | 7.1, 7.6, 7.8 |
| CC7.3 | Incident Detection and Response | 7.11 |
| CC7.4 | Incident Recovery | 7.11 |
| CC9.2 | Integration Risk Assessment, MCP Server Control | 6.2, 7.3 |

### NIST 800-53 Rev 5 Mapping

| Control | Anthropic Claude Control | Guide Section |
|---------|--------------------------|---------------|
| AC-2 | Account Management, Workspace Membership | 3.2, 6.1 |
| AC-3 | API Key Scoping, Workspace Isolation | 2.1 |
| AC-4 | Workspace Segmentation | 3.1 |
| AC-6 | Least-Privilege Roles | 1.2, 2.1, 3.2 |
| AU-6 | Usage Monitoring | 5.1 |
| IA-2 | SSO Enforcement | 1.1 |
| IA-5 | Admin Key Protection, Key Rotation | 1.3, 2.2 |
| IA-8 | Non-Organization User Authentication | 1.1 |
| RA-3 | Integration Risk Assessment | 6.2 |
| SA-9 | External Service Controls, Spend Limits | 5.2, 6.2 |
| SC-7 | Workspace Boundaries, Data Residency | 3.1, 4.1 |
| SI-4 | System Monitoring | 5.1, 5.2 |
| CM-6 | Managed Configuration Settings | 7.1 |
| CM-7 | Least Functionality, Tool Restrictions, MCP Control, Sandbox, Hooks/Plugins | 7.1, 7.2, 7.3, 7.5, 7.6 |
| SA-11 | Developer Security Testing, CI/CD Hardening | 7.8 |
| SA-15 | Development Process Security | 7.8 |
| SC-7 | Boundary Protection, External Sandbox | 3.1, 4.1, 7.9 |
| SC-39 | Process Isolation, Sandbox Enforcement | 7.5, 7.9 |
| SI-7 | Software Integrity, Hook/Plugin Validation | 7.6, 7.7 |
| IR-4 | Incident Handling | 7.11 |
| IR-5 | Incident Monitoring | 7.11 |
| IR-8 | Incident Response Plan | 7.11 |
| SI-10 | Information Input Validation, Prompt Injection Defense | 7.7 |
| SI-12 | Data Retention | 4.2 |

### ISO 27001:2022 Mapping

| Control | Anthropic Claude Control | Guide Section |
|---------|--------------------------|---------------|
| A.8.10 | Data Retention and Deletion | 4.2 |
| A.9.2.1 | User Registration | 1.1, 6.1 |
| A.9.2.3 | Privileged Access Management | 1.2 |
| A.9.2.5 | User Access Review | 3.2 |
| A.9.3.1 | Secret Authentication Information | 2.2 |
| A.9.4.1 | Information Access Restriction | 2.1 |
| A.9.4.3 | Password/Key Management | 1.3 |
| A.12.1.3 | Capacity Management | 5.2 |
| A.12.4.1 | Event Logging | 5.1 |
| A.12.2.1 | Controls Against Malware | 7.7 |
| A.12.5.1 | Software Installation Controls | 7.6 |
| A.12.6.1 | Technical Vulnerability Management | 7.6 |
| A.13.1.1 | Network Controls | 7.9 |
| A.13.1.3 | Network Segregation | 3.1, 7.5, 7.9 |
| A.14.2.1 | Secure Development Policy | 7.8 |
| A.14.2.8 | System Security Testing | 7.7, 7.8 |
| A.15.1.2 | Supplier Security | 6.2 |
| A.16.1.1 | Information Security Incident Management | 7.11 |
| A.16.1.5 | Response to Information Security Incidents | 7.11 |
| A.18.1.4 | Privacy Protection | 4.1 |

### NIST Cybersecurity Framework (CSF) 2.0 Mapping

| Function.Category | Anthropic Claude Control | Guide Section |
|-------------------|--------------------------|---------------|
| **GV.PO** (Govern: Policy) | Acceptable use policy, scheduled task governance, regulated workload restrictions | 7.10, 7.11 |
| **GV.SC** (Govern: Supply Chain) | Vendor risk register, plugin/MCP supply chain review, audit gap tracking | 7.3, 7.6, 7.7, 7.10 |
| **ID.AM** (Identify: Asset Management) | Plugin inventory, connector registry, MCP server registry, scheduled task inventory | 7.3, 7.6, 7.10 |
| **ID.RA** (Identify: Risk Assessment) | Plugin risk tiers, MCP blast radius analysis, CVE tracking | 7.6, 7.7 |
| **PR.AC** (Protect: Access Control) | SSO/SCIM, tenant restrictions, RBAC, Chrome allowlists, connector controls, folder scoping | 1.1, 7.2, 7.10 |
| **PR.AT** (Protect: Training) | Prompt injection awareness, safety guide distribution, AUP training, folder hygiene | 7.7, 7.10 |
| **PR.DS** (Protect: Data Security) | File access controls, cross-app data flow, local history handling, ZDR, disk encryption | 4.1, 4.2, 7.5, 7.10 |
| **PR.PS** (Protect: Platform Security) | Managed settings, global instructions, plugin install preferences, network egress, sandbox | 7.1, 7.5, 7.6, 7.10 |
| **DE.CM** (Detect: Monitoring) | OpenTelemetry, SIEM integration, scheduled task review, anomaly alerting, cost monitoring | 5.1, 7.4, 7.10 |
| **DE.AE** (Detect: Analysis) | Prompt injection detection, scope creep monitoring, exfiltration pattern detection | 7.7, 7.10 |
| **RS.RP** (Respond: Planning) | IR playbook with AI agent scenarios, kill-switch authority, tabletop exercises | 7.11 |
| **RS.CO** (Respond: Communications) | Anthropic reporting (HackerOne), in-app feedback, security team escalation | 7.11 |
| **RS.AN** (Respond: Analysis) | Local forensic collection, OTel log correlation, Compliance API (non-Cowork) | 7.11 |

### NIST AI Risk Management Framework (AI RMF) Mapping

| Function | Anthropic Claude Control | Guide Section |
|----------|--------------------------|---------------|
| **GOVERN 1** (Policies & Legal) | Acceptable use policy, regulated workload restrictions, AI usage policy | 7.10, 7.11 |
| **GOVERN 2** (Accountability) | SSO/SCIM, tenant restrictions, RBAC, defined admin roles | 1.1, 1.2, 7.10 |
| **GOVERN 4** (Culture & Training) | Prompt injection awareness, safety guides, folder hygiene training | 7.7, 7.10 |
| **GOVERN 6** (Supply Chain) | Vendor risk register, plugin/MCP review, audit gap tracking | 7.3, 7.6, 7.7 |
| **MAP 1** (Context & Scope) | Deployment posture selection, plan-tier analysis, plugin/connector inventories | 7.1, 7.10 |
| **MAP 3** (Risk Identification) | Prompt injection threat model, MCP blast radius, CVE tracking | 7.7, 7.10 |
| **MEASURE 1** (Monitoring) | OpenTelemetry, SIEM, alerting, cost monitoring, task review | 5.1, 7.4, 7.10 |
| **MANAGE 1** (Risk Treatment) | ZDR, disk encryption, managed settings, Chrome controls, connector controls | 4.2, 7.1, 7.5, 7.10 |
| **MANAGE 2** (Response) | IR playbook with AI agent scenarios, kill-switch, tabletop exercises | 7.11 |
| **MANAGE 4** (Residual Risk) | Audit log gap documented, regulated workload prohibition, OTel as compensating control | 7.10, 7.11 |

---

## Appendix A: Edition/Tier Compatibility

| Control | API (All Tiers) | Team | Enterprise |
|---------|----------------|------|------------|
| 1.1 Enforce SSO | N/A (API-only) | ✅ | ✅ |
| 1.2 Least-Privilege Roles | ✅ | ✅ | ✅ |
| 1.3 Admin Key Protection | ✅ | ✅ | ✅ |
| 2.1 API Key Scoping | ✅ | ✅ | ✅ |
| 2.2 API Key Rotation | ✅ | ✅ | ✅ |
| 3.1 Workspace Segmentation | ✅ | ✅ | ✅ |
| 3.2 Workspace Membership | ✅ | ✅ | ✅ |
| 4.1 Data Residency | ✅ | ✅ | ✅ |
| 4.2 Custom Data Retention | ❌ | ❌ | ✅ |
| 4.2 Zero Data Retention | ❌ | ❌ | ✅ (by arrangement) |
| 5.1 Usage Monitoring | ✅ | ✅ | ✅ |
| 5.2 Spend Limits | ✅ | ✅ | ✅ |
| 6.1 Invite Auditing | ✅ | ✅ | ✅ |
| 6.2 Integration Risk | ✅ | ✅ | ✅ |
| 7.1 Managed Settings (MDM) | ✅ (MDM only) | ✅ | ✅ |
| 7.1 Server-Managed Settings | ❌ | ✅ (v2.1.38+) | ✅ (v2.1.30+) |
| 7.2 Permission Restrictions | ✅ (MDM only) | ✅ | ✅ |
| 7.3 MCP Server Control | ✅ (MDM only) | ✅ | ✅ |
| 7.4 Claude Code Analytics | ✅ | ✅ | ✅ |
| 7.5 Bash Sandbox Isolation | ✅ (MDM only) | ✅ | ✅ |
| 7.6 Hooks & Plugin Lockdown | ✅ (MDM only) | ✅ | ✅ |
| 7.7 Prompt Injection Defense | ✅ (open-source tools) | ✅ | ✅ |
| 7.8 CI/CD Pipeline Hardening | ✅ (GitHub Actions) | ✅ | ✅ |
| 7.9 External Sandbox (nono/OpenShell) | ✅ (open-source tools) | ✅ | ✅ |
| 7.10 Cowork Governance | ❌ | ✅ | ✅ |
| 7.11 Incident Response | ✅ (procedural) | ✅ | ✅ |
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
- [Anthropic Usage Policy](https://www.anthropic.com/policies/usage-policy)
- [Anthropic Trust Center](https://trust.anthropic.com)
- [Custom Data Retention (Enterprise)](https://support.anthropic.com/en/articles/10440198-custom-data-retention-controls-for-claude-enterprise)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-15 | 1.1.0 | draft | Admin API currency pass against platform.claude.com. §1.2 role model corrected to the two-org-type picture: five Console/API roles plus the Console UI's Limited Developer tier, `owner`/`primary_owner` above admin, `managed`/`membership_admin` on the Enterprise side, and the full nine-value API role enum documented so audit scripts stop silently miscounting; the admin-assignment and admin-removal API blocks are now quoted from the current references. §1.3 rebuilt on the two-track credential model — Console admin keys (`sk-ant-admin01-`, no selectable scopes) vs Claude Enterprise scoped keys (`sk-ant-api01-`, 12-scope table, primary-owner/org-owner creation split) — plus key expiration at creation, the organization maximum-expiration policy, the `org:admin` OAuth bearer path via the `ant` CLI (dedicated admin profile, `sk-ant-oat01-` prefix added for secret-scanning coverage), and the WIF-endpoints carve-out (service-account/federation endpoints reject admin keys). References moved to canonical platform.claude.com URLs — two of the old docs.anthropic.com links were dead 404s. Roles pack rewritten to count the full enum and the elevated tier; rotation pack now audits `expires_at`. | `Claude Code (Opus 5)` |
| 2026-02-21 | 0.1.0 | draft | Initial guide: 12 controls across 6 categories, API pack scripts for Admin API | `Claude Code (Opus 4.6)` |
| 2026-02-21 | 0.2.0 | draft | Added Section 7: Claude Code Enterprise Controls — MDM managed settings, permission restrictions, MCP server control, developer analytics | `Claude Code (Opus 4.6)` |
| 2026-02-21 | 0.3.0 | draft | Added MDM config templates (L1/L2/L3 profiles), permission deny rule examples, sandbox config, managed-mcp.json template, MCP allowlist/denylist config | `Claude Code (Opus 4.6)` |
| 2026-02-21 | 0.4.0 | draft | Added Config-as-Code pack type with standalone .jsonc config files; added code pack buttons, doc links; moved JSON configs from API scripts to config/ directory | `Claude Code (Opus 4.6)` |
| 2026-03-27 | 0.5.0 | draft | Major expansion: Added 6 new controls (7.5-7.10) — Bash sandbox isolation, hook/plugin lockdown, prompt injection defense, CI/CD pipeline hardening, external sandbox tooling (nono, OpenShell), Cowork governance. Updated 7.1 with drop-in directory, plist/registry delivery, new managed settings. Added comprehensive references for security research (ToxicSkills, Rules File Backdoor, InversePrompt CVEs) and open-source tools. Updated all compliance mappings. | `Claude Code (Opus 4.6)` |
| 2026-04-06 | 0.6.0 | draft | Added 7.11 Incident Response (kill-switch, forensic collection, AI agent IR scenarios, tabletop exercises). Major expansion of 7.10 Cowork: Chrome hardening (allowlist/blocklist, default gap warnings), global defensive instructions, dedicated workspace scoping, scheduled task governance, plugin install preferences, tenant restriction details (exact header format, proxy platforms, error codes), data training opt-out by tier, web search egress bypass warning, OTel prompt content toggle. Added NIST CSF 2.0 and NIST AI RMF compliance mappings. Added web search bypass warning to 7.5 sandbox. | `Claude Code (Opus 4.6)` |
| 2026-05-06 | 0.7.0 | draft | Added 2.3 Eliminate Static API Keys via Workload Identity Federation: covers Anthropic's new WIF capability (RFC 7523 jwt-bearer flow against `POST /v1/oauth/token`), Console setup walkthrough for federation issuers / service accounts / federation rules, IdP coverage (AWS / GCP / Azure-Entra / GitHub Actions / Kubernetes / SPIFFE / Okta), credential precedence pitfalls (`ANTHROPIC_API_KEY` shadowing WIF), token lifetime/refresh semantics, JWKS rotation gotchas, and migration runbook. Code Packs: token-exchange script with static-key guardrail (api/), reference hardened GitHub Actions workflow (config/), config-as-code WIF profile (config/), Python SDK pattern (sdk/). Verified against platform.claude.com/docs/en/manage-claude/workload-identity-federation and wif-reference. | `Claude Opus 4.7 (1M)` |
| 2026-08-08 | 1.0.1 | draft | Added "Products in This Platform" navigation section (product guide table mirroring the Google Workspace hub) so the Anthropic hub lists Claude Enterprise, Claude Code, and Claude API & Console with their coverage. No control changes. | `Claude Opus 5 (1M)` |
| 2026-08-08 | 1.0.2 | draft | Cheat-sheet cell repair: added missing Attack Prevented line(s) to §2.2 (no content-facts changed) | `Claude Code (Fable 5)` |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
