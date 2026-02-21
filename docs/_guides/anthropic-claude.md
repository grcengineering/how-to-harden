---
layout: guide
title: "Anthropic Claude Hardening Guide"
vendor: "Anthropic"
slug: "anthropic-claude"
tier: "1"
category: "Productivity"
description: "AI platform security hardening for Claude API, Console, SSO, workspace isolation, and admin controls"
version: "0.4.0"
maturity: "draft"
last_updated: "2026-02-21"
---

## Overview

Anthropic Claude is an AI assistant platform serving organizations through both a web-based chat interface (claude.ai) and a developer API (api.anthropic.com). As AI adoption accelerates, properly securing Claude deployments is critical to prevent API key compromise, enforce data residency requirements, manage costs, and maintain compliance. Anthropic provides a comprehensive Admin API with 25 endpoints for programmatic organization management, alongside a web Console for GUI-based administration.

### Intended Audience
- Security engineers managing AI tools and API integrations
- IT administrators configuring Claude for enterprise teams
- GRC professionals assessing AI compliance posture
- Third-party risk managers evaluating AI platform controls

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations using Claude
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Anthropic Claude security configurations including authentication (SSO/SCIM), organization role management, API key lifecycle, workspace segmentation, data residency, usage monitoring, integration security, and Claude Code enterprise controls (MDM managed settings, permission restrictions, MCP server governance, developer analytics). Model behavior configuration (system prompts, safety settings) is out of scope. This guide applies to Claude API, Claude Team, and Claude Enterprise plans.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Key Management](#2-api-key-management)
3. [Workspace Security](#3-workspace-security)
4. [Data Security & Privacy](#4-data-security--privacy)
5. [Monitoring & Usage Controls](#5-monitoring--usage-controls)
6. [Third-Party Integration Security](#6-third-party-integration-security)
7. [Claude Code Enterprise Controls](#7-claude-code-enterprise-controls)
8. [Compliance Quick Reference](#8-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Single Sign-On

**Profile Level:** L1 (Baseline)

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
- [ ] Claude Team or Enterprise subscription
- [ ] SAML 2.0 or OIDC compatible identity provider (Okta, Azure AD, OneLogin, Google Workspace)
- [ ] Organization Admin access to Claude Console
- [ ] Domain ownership for domain verification

#### ClickOps Implementation

**Step 1: Access Identity & Access Settings**
1. Navigate to: **console.anthropic.com** → **Settings** → **Identity & Access**
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
1. [ ] Attempt login without SSO — should be redirected to IdP
2. [ ] Complete SSO login — should succeed and land in Claude
3. [ ] Remove user from IdP group — should lose Claude access
4. [ ] Cross-reference org member list (API) with IdP directory

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

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-6, AC-6(1) |
| SOC 2 | CC6.1, CC6.3 |

#### Description
Assign the minimum necessary organization role to each user. Anthropic provides six organization roles: `user`, `developer`, `billing`, `admin`, `claude_code_user`, and `managed`. Limit the `admin` role to a small number of trusted operators.

#### Rationale
**Why This Matters:**
- The `admin` role can provision Admin API keys, manage all workspaces, and remove users
- Admins automatically inherit `workspace_admin` in every workspace
- The Admin API deliberately prevents assigning the `admin` role programmatically — a security design decision
- Admins cannot be removed via API — only through the Console

**Attack Prevented:** Privilege escalation, unauthorized admin key provisioning, insider threat

#### Prerequisites
- [ ] Organization Admin access
- [ ] Current member inventory with role justifications

#### ClickOps Implementation

**Step 1: Review Current Role Assignments**
1. Navigate to: **console.anthropic.com** → **Settings** → **Members**
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
1. [ ] List all org members via Admin API — count admins <= 3
2. [ ] Verify no user has admin role without documented justification
3. [ ] Attempt to assign admin role via API — should fail (by design)
4. [ ] Verify billing role holders match authorized finance contacts

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

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | IA-5, SC-12 |
| SOC 2 | CC6.1, CC6.6 |

#### Description
Admin API keys (`sk-ant-admin...`) grant organization-wide management access. They can only be created through the Console by users with the `admin` role — a deliberate security design. Treat Admin API keys with the same care as cloud provider root credentials.

#### Rationale
**Why This Matters:**
- Admin keys can list all users, manage all workspaces, disable API keys, and view usage data
- Unlike standard API keys, admin keys are not scoped to a single workspace
- Compromise of an admin key exposes the entire organization's Claude infrastructure

**Attack Prevented:** Organization takeover, unauthorized workspace creation, data exfiltration via usage APIs

#### Prerequisites
- [ ] Organization Admin access
- [ ] Secrets management solution (Vault, AWS Secrets Manager, etc.)

#### ClickOps Implementation

**Step 1: Audit Existing Admin Keys**
1. Navigate to: **console.anthropic.com** → **Settings** → **Admin Keys**
2. Review all provisioned admin keys
3. Identify and revoke any keys without a clear owner or purpose

**Step 2: Establish Key Hygiene**
1. Name each admin key descriptively (e.g., "CI/CD Org Audit — TeamName")
2. Store keys in a secrets manager — never in source code, env files, or chat
3. Rotate admin keys every 90 days

**Step 3: Limit Admin Key Provisioning**
1. Restrict admin role to 2-3 trusted operators (see Control 1.2)
2. Require documented approval before provisioning new admin keys
3. Log all admin key creation events

**Time to Complete:** ~10 minutes

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="1.3" %}

#### Validation & Testing
1. [ ] Validate admin key works via `/v1/organizations/me` endpoint
2. [ ] Verify admin key is stored in secrets manager (not plaintext)
3. [ ] Confirm admin key naming convention is followed

**Expected result:** All admin keys are named, stored securely, and have documented owners

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC6.6 | Logical access; security of system boundaries |
| **NIST 800-53** | IA-5, SC-12 | Authenticator management; cryptographic key management |
| **ISO 27001** | A.9.4.3 | Password management system |

---

## 2. API Key Management

### 2.1 Scope API Keys to Workspaces

**Profile Level:** L1 (Baseline)

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
- [ ] Organization Admin or Workspace Admin access
- [ ] Workspace naming convention established

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
1. [ ] List all API keys via Admin API — verify each has a workspace assignment
2. [ ] Verify no unnamed keys exist
3. [ ] Test that a key scoped to Workspace A cannot be used with Workspace B resources

**Expected result:** All API keys have descriptive names and are assigned to appropriate workspaces

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC6.3 | Logical access security; role-based access |
| **NIST 800-53** | AC-3, AC-6 | Access enforcement; least privilege |
| **ISO 27001** | A.9.4.1 | Information access restriction |

---

### 2.2 Rotate API Keys Regularly

**Profile Level:** L2 (Hardened)

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
- [ ] API key inventory with creation dates
- [ ] Deployment pipeline that supports key rotation (secrets manager integration)

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
1. [ ] Run stale key audit script — zero keys older than 90 days
2. [ ] Verify disabled keys return 401 when used
3. [ ] Confirm application functionality with rotated keys

**Expected result:** No API key is older than 90 days; old keys are archived

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security over protected information assets |
| **NIST 800-53** | IA-5(1) | Authenticator management — password-based authentication |
| **ISO 27001** | A.9.3.1 | Use of secret authentication information |

---

## 3. Workspace Security

### 3.1 Segment Workspaces by Environment

**Profile Level:** L1 (Baseline)

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
- [ ] Organization Admin access
- [ ] Environment naming convention (e.g., `engineering-prod`, `engineering-dev`, `analytics-prod`)

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
1. [ ] List all workspaces via Admin API — verify naming convention adherence
2. [ ] Verify production workspaces have data residency configured
3. [ ] Confirm workspace count is within the 100-workspace limit

**Expected result:** Separate workspaces exist for each team/environment; naming convention followed

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | System boundaries and security measures |
| **NIST 800-53** | AC-4, SC-7 | Information flow enforcement; boundary protection |
| **ISO 27001** | A.13.1.3 | Segregation in networks |

---

### 3.2 Manage Workspace Membership

**Profile Level:** L1 (Baseline)

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
- [ ] Workspace Admin or Organization Admin access
- [ ] Team-to-workspace mapping documented

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
1. [ ] List workspace members via Admin API for each workspace
2. [ ] Verify no workspace has more than 2 `workspace_admin` members (excluding inherited org admins)
3. [ ] Confirm removed users cannot access workspace resources

**Expected result:** Each workspace has only authorized members at appropriate role levels

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2, CC6.3 | Access provisioning; role-based access |
| **NIST 800-53** | AC-2, AC-6 | Account management; least privilege |
| **ISO 27001** | A.9.2.5 | Review of user access rights |

---

## 4. Data Security & Privacy

### 4.1 Enforce Data Residency Restrictions

**Profile Level:** L2 (Hardened)

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
- [ ] Organization Admin access
- [ ] Data residency requirements documented per team/workspace
- [ ] Legal/compliance approval for geo settings

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
1. [ ] List all workspaces via Admin API — verify `workspace_geo` and `allowed_inference_geos`
2. [ ] Attempt a request with `inference_geo: "global"` against a US-restricted workspace — should fail
3. [ ] Verify new workspaces are created with correct geo from the start

**Expected result:** Regulated workspaces have explicit data residency configuration; inference geo restrictions enforced

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6, P6.1 | System boundaries; privacy — consent and choice |
| **NIST 800-53** | SC-7, SA-9(5) | Boundary protection; processing, storage, and service location |
| **ISO 27001** | A.18.1.4 | Privacy and protection of personally identifiable information |

---

### 4.2 Configure Data Retention Policies

**Profile Level:** L2 (Hardened)

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
- [ ] Claude Enterprise plan (for custom retention or ZDR)
- [ ] Data classification policy for content sent to Claude
- [ ] Legal review of Anthropic's data handling agreement

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
1. [ ] Confirm retention period with Anthropic account team (Enterprise)
2. [ ] Verify client-side PII redaction is in place for sensitive workloads
3. [ ] Review data classification guidelines with engineering team

**Expected result:** Data retention policy documented and aligned with organizational requirements

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | P4.1 | Privacy — data minimization |
| **NIST 800-53** | SI-12 | Information management and retention |
| **ISO 27001** | A.8.10 | Information deletion |

---

## 5. Monitoring & Usage Controls

### 5.1 Monitor API Usage and Costs

**Profile Level:** L1 (Baseline)

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
- [ ] Admin API key provisioned
- [ ] Monitoring infrastructure (Datadog, Grafana, etc.) or cron job for regular checks

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
1. [ ] Run usage report API script — verify data returns for all active workspaces
2. [ ] Run cost report API script — verify cost data is accurate
3. [ ] Confirm observability integration is receiving data

**Expected result:** Usage and cost data is monitored regularly with alerts for anomalies

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | System monitoring |
| **NIST 800-53** | AU-6, SI-4 | Audit record review; system monitoring |
| **ISO 27001** | A.12.4.1 | Event logging |

---

### 5.2 Configure Spend Limits per Workspace

**Profile Level:** L1 (Baseline)

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
- [ ] Organization Admin or Workspace Admin access
- [ ] Budget allocation per workspace/team

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
1. [ ] Verify spend limits are set for every workspace via Console
2. [ ] Run cost anomaly detection script to validate monitoring
3. [ ] Test that requests return 429 when rate limits are exceeded (check `retry-after` header)

**Expected result:** Every workspace has explicit spend and rate limits configured

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2, CC6.8 | System monitoring; change management |
| **NIST 800-53** | SA-9, SI-4 | External system services; system monitoring |
| **ISO 27001** | A.12.1.3 | Capacity management |

---

## 6. Third-Party Integration Security

### 6.1 Audit and Clean Up Pending Invites

**Profile Level:** L1 (Baseline)

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
- [ ] Organization Admin access

#### ClickOps Implementation

**Step 1: Review Pending Invites**
1. Navigate to: **console.anthropic.com** → **Settings** → **Members** → **Invites**
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
1. [ ] Run invite audit script — verify no stale pending invites
2. [ ] Attempt to create invite with admin role via API — should fail (by design)
3. [ ] Confirm expired invites cannot be accepted

**Expected result:** All pending invites are reviewed, authorized, and time-bound

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2 | Prior to issuing system credentials and granting system access |
| **NIST 800-53** | AC-2(3) | Account management — disable accounts |
| **ISO 27001** | A.9.2.1 | User registration and de-registration |

---

### 6.2 Integration Risk Assessment

**Profile Level:** L2 (Hardened)

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
1. [ ] Maintain inventory of all applications using Claude API keys
2. [ ] Verify each application's key is in an appropriately scoped workspace
3. [ ] Confirm keys are stored in secrets managers, not in source code

**Expected result:** All API key consumers are inventoried with risk ratings and appropriate controls

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC3.2, CC9.2 | Risk assessment; vendor and third-party risk management |
| **NIST 800-53** | RA-3, SA-9 | Risk assessment; external system services |
| **ISO 27001** | A.15.1.2 | Addressing security within supplier agreements |

---

## 7. Claude Code Enterprise Controls

### 7.1 Deploy Managed Settings via MDM

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | CM-6, CM-7 |
| SOC 2 | CC6.1, CC8.1 |

#### Description
Deploy a `managed-settings.json` file to all developer workstations via MDM (Jamf, Intune, Kandji) to enforce organization-wide Claude Code security policies. Managed settings cannot be overridden by user or project settings. Alternatively, use server-managed settings via the Claude.ai admin console (Team v2.1.38+ / Enterprise v2.1.30+), which requires no MDM infrastructure.

#### Rationale
**Why This Matters:**
- Without managed settings, individual developers can use `--dangerously-skip-permissions` to bypass all safety checks
- User-defined hooks and MCP servers can introduce supply chain risks
- Managed settings enforce a security baseline that developers cannot weaken
- Server-managed settings are fetched at startup and polled hourly with offline caching

**Attack Prevented:** Permission bypass, unauthorized tool execution, malicious hook injection

#### Prerequisites
- [ ] MDM solution deployed to developer machines (Jamf, Intune, Kandji), OR Claude Team/Enterprise plan for server-managed settings
- [ ] Security team consensus on default permission mode and deny rules
- [ ] Inventory of approved MCP servers and tools

#### ClickOps Implementation

**Option A: Server-Managed Settings (No MDM Required)**
1. Navigate to: **claude.ai** → **Admin Settings** → **Claude Code** → **Managed settings**
2. Add JSON configuration with required security settings
3. Settings propagate to all users at next startup or within 1 hour

**Option B: MDM Deployment**

**Step 1: Create managed-settings.json**
1. Create the JSON configuration file with your organization's security policy
2. Include at minimum: `disableBypassPermissionsMode`, `permissions.deny` rules, and `permissions.defaultMode`

**Step 2: Deploy via MDM**

Deploy to the correct OS-specific path:

| OS | Path |
|----|------|
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json` |
| Linux / WSL | `/etc/claude-code/managed-settings.json` |
| Windows | `C:\Program Files\ClaudeCode\managed-settings.json` |

**Step 3: Verify Deployment**
1. On a test machine, run `claude --version` to confirm Claude Code sees the managed settings
2. Attempt to use `--dangerously-skip-permissions` — should be blocked if `disableBypassPermissionsMode` is set

**Time to Complete:** ~30 minutes (policy creation) + MDM deployment time

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="7.1" %}

#### Validation & Testing
1. [ ] Run validation script — managed-settings.json exists at correct OS path
2. [ ] Verify `disableBypassPermissionsMode` is set to `"disable"`
3. [ ] Attempt `--dangerously-skip-permissions` — should be rejected
4. [ ] Verify deny rules block restricted operations

**Expected result:** All developer machines have managed settings deployed; bypass mode is disabled

#### Monitoring & Maintenance
**Ongoing monitoring:**
- MDM compliance dashboard confirms file is present on all enrolled devices
- Alert on devices missing managed-settings.json

**Maintenance schedule:**
- **Monthly:** Review and update deny rules as tooling changes
- **Quarterly:** Audit managed settings against security policy

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Developers cannot bypass permission checks |
| **System Performance** | None | Settings loaded once at startup |
| **Maintenance Burden** | Low | MDM handles deployment; policy changes are centralized |
| **Rollback Difficulty** | Easy | Remove file from MDM profile |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC8.1 | Logical access security; change management |
| **NIST 800-53** | CM-6, CM-7 | Configuration settings; least functionality |
| **ISO 27001** | A.12.5.1 | Installation of software on operational systems |

---

### 7.2 Restrict Claude Code Permissions and Tools

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3, CM-7 |
| SOC 2 | CC6.1, CC6.3 |

#### Description
Configure granular permission rules in managed settings to control which tools Claude Code can use, which files it can access, and which commands it can execute. Use deny rules (which always take precedence) to block sensitive operations like reading `.env` files, executing `curl` commands, or accessing secrets directories.

#### Rationale
**Why This Matters:**
- Claude Code can read, write, and execute arbitrary commands by default
- Without restrictions, a compromised or confused AI agent could exfiltrate secrets, modify production configs, or execute malicious commands
- Deny rules are evaluated before allow rules — they provide a hard security boundary
- `allowManagedPermissionRulesOnly: true` ensures users cannot add their own allow rules to weaken the policy

**Attack Prevented:** Secret exfiltration via AI agent, unauthorized file access, command injection

#### Prerequisites
- [ ] Managed settings deployment (Control 7.1)
- [ ] Inventory of sensitive file patterns and restricted commands

#### ClickOps Implementation

**Step 1: Define Permission Policy**
1. Identify sensitive file patterns: `.env`, `.env.*`, `secrets/`, credentials files
2. Identify restricted commands: `curl` (data exfiltration), `rm -rf` (destruction), credential access
3. Define approved operations: `npm run *`, `git status`, `git diff`, test runners

**Step 2: Configure via Admin Console or MDM**
1. Add permission rules to managed settings:
   - **deny:** `Read(./.env)`, `Read(./.env.*)`, `Read(./secrets/**)`, `Bash(curl *)`, `Bash(rm -rf *)`
   - **allow:** `Bash(npm run *)`, `Bash(git status)`, `Bash(git diff *)`
   - **ask:** `Bash(git push *)`, `Bash(git commit *)`
2. Set `allowManagedPermissionRulesOnly: true` to prevent user overrides
3. Set `disableBypassPermissionsMode: "disable"` (see Control 7.1)

**Step 3: Configure Network Sandbox (L3)**
1. Enable `sandbox.enabled: true` for OS-level isolation
2. Set `sandbox.network.allowedDomains` to restrict outbound network access
3. Restrict socket access as needed

**Time to Complete:** ~20 minutes

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="7.2" %}

#### Validation & Testing
1. [ ] Attempt to read a `.env` file via Claude Code — should be denied
2. [ ] Attempt to run `curl` via Claude Code — should be denied
3. [ ] Run an approved command (e.g., `npm run test`) — should succeed
4. [ ] Verify user-added allow rules are ignored when `allowManagedPermissionRulesOnly` is true

**Expected result:** Sensitive files and commands are blocked; only approved operations succeed

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Developers see denials for restricted operations |
| **System Performance** | None | Rule evaluation is instant |
| **Maintenance Burden** | Medium | Rules need updating as tooling evolves |
| **Rollback Difficulty** | Easy | Remove deny rules from managed settings |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC6.3 | Logical access security; role-based access |
| **NIST 800-53** | AC-3, CM-7 | Access enforcement; least functionality |
| **ISO 27001** | A.9.4.1 | Information access restriction |

---

### 7.3 Control MCP Server Access

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | CM-7, SA-9 |
| SOC 2 | CC6.6, CC9.2 |

#### Description
Restrict which Model Context Protocol (MCP) servers Claude Code can connect to using a managed MCP configuration file or allowlist/denylist settings. MCP servers extend Claude Code's capabilities by providing additional tools — an uncontrolled MCP server can introduce arbitrary tool access.

#### Rationale
**Why This Matters:**
- MCP servers can provide Claude Code with tools to access databases, APIs, cloud services, and more
- A malicious or misconfigured MCP server can grant unintended access to sensitive systems
- The `managed-mcp.json` file provides exclusive control — when present, users cannot add their own MCP servers
- Deny rules in `deniedMcpServers` always take precedence over allow rules

**Attack Prevented:** Supply chain attack via malicious MCP server, unauthorized system access, data exfiltration through MCP tools

#### Prerequisites
- [ ] MDM deployment capability (for managed-mcp.json) or managed settings access
- [ ] Inventory of approved MCP servers and their security posture

#### ClickOps Implementation

**Step 1: Inventory MCP Servers**
1. Survey development teams for MCP servers in use
2. Assess each server's security posture (source, maintainer, permissions granted)
3. Create an approved list

**Step 2: Deploy Managed MCP Configuration**

Deploy `managed-mcp.json` to the OS-specific path:

| OS | Path |
|----|------|
| macOS | `/Library/Application Support/ClaudeCode/managed-mcp.json` |
| Linux / WSL | `/etc/claude-code/managed-mcp.json` |
| Windows | `C:\Program Files\ClaudeCode\managed-mcp.json` |

When this file exists, it takes **exclusive control** — users cannot add, modify, or use any MCP servers other than those defined in this file.

**Step 3: Alternative — Allowlist/Denylist via Managed Settings**
1. Add `allowedMcpServers` to managed settings with approved server names, commands, or URLs
2. Add `deniedMcpServers` for explicitly blocked servers (deny always wins)
3. URL wildcards are supported (e.g., `https://*.company.com/*`)

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="7.3" %}

#### Validation & Testing
1. [ ] Verify managed-mcp.json is deployed (if using exclusive control)
2. [ ] Attempt to add an unapproved MCP server — should be blocked
3. [ ] Verify approved MCP servers connect successfully
4. [ ] Test deny rule against a specific server name — should be blocked

**Expected result:** Only approved MCP servers can be used; all others are blocked

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Developers can only use pre-approved MCP servers |
| **System Performance** | None | MCP config is loaded once at startup |
| **Maintenance Burden** | Medium | Approved list needs updates as new servers are adopted |
| **Rollback Difficulty** | Easy | Remove managed-mcp.json or update allowlist |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6, CC9.2 | System boundaries; vendor risk management |
| **NIST 800-53** | CM-7, SA-9 | Least functionality; external system services |
| **ISO 27001** | A.15.1.2 | Addressing security within supplier agreements |

---

### 7.4 Monitor Claude Code Developer Metrics

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AU-6, SI-4 |
| SOC 2 | CC7.2 |

#### Description
Use the Claude Code Analytics API (`/v1/organizations/usage_report/claude_code`) to monitor per-user developer activity including sessions, commits, pull requests, lines of code, tool acceptance rates, and cost by model. This endpoint provides daily granularity with per-user breakdowns.

#### Rationale
**Why This Matters:**
- Per-user metrics enable detection of anomalous Claude Code usage patterns
- Tool acceptance rates below 70% may indicate permission configuration issues or developer friction
- Cost attribution by user and model enables budget management
- Tracking commits and PRs created by Claude Code quantifies AI-assisted development impact

**Attack Prevented:** Unauthorized bulk code generation, cost abuse, shadow AI usage detection

#### Prerequisites
- [ ] Admin API key provisioned
- [ ] Claude Team or Enterprise plan with Claude Code enabled
- [ ] Monitoring infrastructure for alert thresholds

#### ClickOps Implementation

**Step 1: Review Usage in Console**
1. Navigate to: **console.anthropic.com** → **Usage**
2. Filter for Claude Code usage
3. Review per-user activity patterns

**Step 2: Configure Alerts**
1. Set up daily automated checks using the API script below
2. Configure alerts for:
   - Users with unusually high session counts
   - Tool acceptance rates below 70%
   - Cost exceeding per-user thresholds
3. Integrate with observability platform (Datadog, Grafana, etc.)

**Step 3: Configure OpenTelemetry (Optional)**
1. Set environment variables in managed settings for OTel export
2. Available metrics: sessions, LOC, PRs, commits, cost, tokens, code edit decisions, active time
3. Available events: user prompts, tool results, API requests, API errors, tool decisions

**Time to Complete:** ~15 minutes (API setup) + integration time

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="7.4" %}

#### Validation & Testing
1. [ ] Run analytics script — verify data returns for active Claude Code users
2. [ ] Verify per-user session counts, commit counts, and LOC metrics
3. [ ] Verify tool acceptance rates are calculated correctly
4. [ ] Confirm cost breakdown by model matches Console dashboard

**Expected result:** Per-user Claude Code metrics are monitored daily with alerts for anomalies

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Daily automated analytics report via cron or CI
- Weekly review of tool acceptance rate trends
- Monthly cost review by user and model

**Maintenance schedule:**
- **Weekly:** Review automated analytics reports
- **Monthly:** Adjust alert thresholds based on team growth
- **Quarterly:** Full access review correlating Claude Code users with org membership

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | System monitoring |
| **NIST 800-53** | AU-6, SI-4 | Audit record review; system monitoring |
| **ISO 27001** | A.12.4.1 | Event logging |

---

## 8. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Anthropic Claude Control | Guide Section |
|-----------|--------------------------|---------------|
| CC6.1 | Enforce SSO, Least-Privilege Roles, API Key Scoping, Managed Settings | 1.1, 1.2, 1.3, 2.1, 2.2, 7.1, 7.2 |
| CC6.2 | Invite Management, Workspace Membership | 3.2, 6.1 |
| CC6.3 | Role-Based Access, Workspace Scoping | 1.2, 2.1, 3.2 |
| CC6.6 | Workspace Segmentation, Data Residency | 1.3, 3.1, 4.1 |
| CC6.8 | Spend Limits and Rate Limits | 5.2 |
| CC7.2 | Usage Monitoring, Cost Monitoring | 5.1, 5.2 |
| CC8.1 | Managed Settings, Change Management | 7.1 |
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
| CM-7 | Least Functionality, Tool Restrictions, MCP Control | 7.1, 7.2, 7.3 |
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
| A.13.1.3 | Network Segregation | 3.1 |
| A.15.1.2 | Supplier Security | 6.2 |
| A.18.1.4 | Privacy Protection | 4.1 |

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
| SCIM Provisioning | ❌ | ❌ | ✅ |
| Audit Logs | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Anthropic Documentation:**
- [Admin API Overview](https://docs.anthropic.com/en/docs/build-with-claude/administration)
- [Admin API Reference](https://docs.anthropic.com/en/api/admin-api)
- [Workspaces Guide](https://docs.anthropic.com/en/docs/build-with-claude/workspaces)
- [Rate Limits](https://docs.anthropic.com/en/api/rate-limits)
- [Data Residency](https://docs.anthropic.com/en/docs/build-with-claude/data-residency)
- [Zero Data Retention](https://docs.anthropic.com/en/docs/build-with-claude/zero-data-retention)
- [Usage and Cost API](https://docs.anthropic.com/en/docs/build-with-claude/usage-cost-api)

**Identity Provider Integration:**
- [SSO Setup Guide](https://support.anthropic.com/en/articles/13132885-setting-up-single-sign-on-sso)
- [SCIM Provisioning Guide](https://support.anthropic.com/en/articles/13133195-setting-up-jit-or-scim-provisioning)
- [Console Roles and Permissions](https://support.anthropic.com/en/articles/10186004-api-console-roles-and-permissions)

**Security and Compliance:**
- [Anthropic Usage Policy](https://www.anthropic.com/policies/usage-policy)
- [Custom Data Retention (Enterprise)](https://support.anthropic.com/en/articles/10440198-custom-data-retention-controls-for-claude-enterprise)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-02-21 | 0.1.0 | draft | Initial guide: 12 controls across 6 categories, API pack scripts for Admin API | `Claude Code (Opus 4.6)` |
| 2026-02-21 | 0.2.0 | draft | Added Section 7: Claude Code Enterprise Controls — MDM managed settings, permission restrictions, MCP server control, developer analytics | `Claude Code (Opus 4.6)` |
| 2026-02-21 | 0.3.0 | draft | Added MDM config templates (L1/L2/L3 profiles), permission deny rule examples, sandbox config, managed-mcp.json template, MCP allowlist/denylist config | `Claude Code (Opus 4.6)` |
| 2026-02-21 | 0.4.0 | draft | Added Config-as-Code pack type with standalone .jsonc config files; added code pack buttons, doc links; moved JSON configs from API scripts to config/ directory | `Claude Code (Opus 4.6)` |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
