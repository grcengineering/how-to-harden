---
layout: guide
title: "Vercel Hardening Guide"
vendor: "Vercel"
slug: "vercel"
tier: "5"
category: "DevOps"
description: "Comprehensive platform security for authentication, WAF, deployment protection, secrets, network isolation, security headers, and monitoring"
version: "1.1.0"
maturity: "draft"
last_updated: "2026-04-24"
---


## Overview

Vercel is a frontend cloud platform providing deployment, hosting, and serverless compute. Its attack surface includes REST API tokens, deployment secrets, Git integrations, serverless functions, edge middleware, DNS management, and third-party marketplace integrations. Compromised access exposes deployment secrets, environment variables, source code, and enables malicious deployments or supply chain attacks.

### Shared Responsibility Model

Vercel operates under a shared responsibility model ([source](https://vercel.com/docs/security/shared-responsibility)):

**Vercel manages:** Infrastructure security, DDoS mitigation (L3/L4/L7), TLS encryption (automatic HTTPS with TLS 1.2/1.3), platform patching, compute isolation, data encryption at rest (AES-256), certificate management, and edge network operations across 126 PoPs globally.

**Customer must configure:** Application-level authentication, security headers (CSP, X-Frame-Options, etc.), environment variable scoping and access controls, WAF custom rules, deployment protection settings, RBAC and team access policies, log drain forwarding to SIEM, OIDC federation for CI/CD, and domain/DNS security.

### Intended Audience

- Security engineers managing deployment platforms
- DevOps and platform engineering teams
- GRC professionals assessing deployment security posture
- Third-party risk managers evaluating hosting integrations

### How to Use This Guide

- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope

This guide covers Vercel platform security configurations including authentication and RBAC, deployment protection, Web Application Firewall, network security and DDoS mitigation, security headers, secrets management, domain security, and monitoring and detection. Application-level security (e.g., Next.js framework hardening) is out of scope but referenced where relevant.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Deployment Security](#2-deployment-security)
3. [Web Application Firewall](#3-web-application-firewall)
4. [Network Security](#4-network-security)
5. [Security Headers](#5-security-headers)
6. [Secrets Management](#6-secrets-management)
7. [Domain & Certificate Security](#7-domain--certificate-security)
8. [Monitoring & Detection](#8-monitoring--detection)
9. [Framework CVE Management (Next.js)](#9-framework-cve-management-nextjs)
10. [Customer Misconfiguration Anti-Patterns](#10-customer-misconfiguration-anti-patterns)

Appendices: [A. Edition Compatibility](#appendix-a-edition-compatibility) · [B. References](#appendix-b-references) · [C. April 2026 Incident Response Playbook](#appendix-c-april-2026-incident-response-playbook)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with SAML

**Profile Level:** L1 (Baseline)

**NIST 800-53:** IA-2(1), IA-8

#### Description

Configure SAML Single Sign-On to centralize authentication through your identity provider and eliminate password-based Vercel logins.

#### Rationale

**Why This Matters:**
- Centralizes authentication policy enforcement through your IdP
- Enables MFA enforcement at the IdP level rather than relying on individual user compliance
- Provides single point of revocation when employees leave

**Attack Prevented:** Credential stuffing, password reuse, unauthorized access after employee departure

#### Prerequisites

- Vercel Enterprise plan (or Pro with SSO add-on)
- SAML-compatible IdP (Okta, Entra ID, Google, OneLogin, etc. -- 24+ supported)
- Team Owner access in Vercel

#### ClickOps Implementation

**Step 1: Configure SAML IdP**
1. Navigate to: **Team Settings → Security → SAML Single Sign-On**
2. Select your identity provider from the 24+ supported providers
3. Configure the SAML connection following your IdP's instructions
4. Map IdP groups to Vercel roles (vercel-role-owner, vercel-role-member, etc.)

**Step 2: Enforce SAML**
1. After confirming SSO works: Toggle **Enforce SAML** to ON
2. Distribute custom login URL: `https://vercel.com/login?saml=<team_id>`
3. Verify session duration is 24 hours (default -- re-authentication required after)

**Time to Complete:** ~30 minutes

{% include pack-code.html vendor="vercel" section="1.1" %}

#### Validation & Testing

1. Attempt login without SAML -- should be blocked when enforcement is ON
2. Login via IdP -- should succeed and land on team dashboard
3. Remove user from IdP group -- should lose Vercel access within sync interval

**Expected result:** Only IdP-authenticated users can access the Vercel team

#### Monitoring & Maintenance

- **Monthly:** Review SAML configuration and IdP group mappings
- **Quarterly:** Audit active sessions and SAML enforcement status
- **On event:** Re-verify after IdP changes or Vercel plan changes

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Users must authenticate via IdP; custom login URL required |
| **System Performance** | None | No performance impact |
| **Maintenance Burden** | Low | Managed by IdP; Vercel config rarely changes |
| **Rollback Difficulty** | Easy | Toggle enforcement OFF in Team Settings |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical and physical access controls |
| **NIST 800-53** | IA-2(1) | Multi-factor authentication |
| **ISO 27001** | A.9.4.2 | Secure log-on procedures |
| **PCI DSS** | 8.3.1 | Multi-factor authentication for all access |

---

### 1.2 Configure Directory Sync (SCIM)

**Profile Level:** L2 (Hardened)

**NIST 800-53:** AC-2, IA-5(1)

#### Description

Enable SCIM-based directory synchronization to automatically provision and deprovision team members from your identity provider.

#### Rationale

**Why This Matters:**
- Eliminates manual user lifecycle management
- Ensures immediate deprovisioning when employees leave
- Enforces consistent role assignments across the organization

**Attack Prevented:** Orphaned accounts, delayed deprovisioning, unauthorized persistent access

#### Prerequisites

- Vercel Enterprise plan
- SAML SSO configured (Section 1.1)
- IdP supports SCIM (Okta, Entra ID, etc.)

#### ClickOps Implementation

**Step 1: Enable Directory Sync**
1. Navigate to: **Team Settings → Security → Directory Sync**
2. Generate SCIM endpoint URL and bearer token
3. Configure your IdP with the SCIM endpoint

**Step 2: Map Groups to Roles**
1. Create IdP groups matching Vercel roles: `vercel-role-owner`, `vercel-role-member`, `vercel-role-developer`, `vercel-role-security`, `vercel-role-billing`
2. Map IdP groups to Access Groups for project-level permissions
3. Ensure at least one owner mapping exists to prevent lockout

**Time to Complete:** ~45 minutes

{% include pack-code.html vendor="vercel" section="1.2" %}

#### Validation & Testing

1. Add a test user in IdP -- should appear in Vercel team within sync interval
2. Remove test user from IdP group -- should lose Vercel access
3. Change user role in IdP -- should reflect in Vercel

**Expected result:** Team membership mirrors IdP directory state

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Low | Transparent to end users |
| **System Performance** | None | No performance impact |
| **Maintenance Burden** | Low | Fully automated after setup |
| **Rollback Difficulty** | Moderate | Must manually manage members if disabled |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2 | Prior to issuing system credentials, verify identity |
| **NIST 800-53** | AC-2 | Account management |
| **ISO 27001** | A.9.2.1 | User registration and de-registration |
| **PCI DSS** | 8.1.3 | Immediately revoke access for terminated users |

---

### 1.3 Enforce Least-Privilege RBAC

**Profile Level:** L1 (Baseline)

**NIST 800-53:** AC-3, AC-6

#### Description

Configure team and project-level role-based access control using Vercel's granular role system and Access Groups.

#### Rationale

**Why This Matters:**
- Prevents over-privileged access to production environments
- Developers cannot modify production environment variables without explicit elevation
- Security role enables firewall management without deployment access

**Attack Prevented:** Insider threat, privilege escalation, unauthorized production modifications

**Vercel Role Summary:**

| Role | Deploy | Prod Env Vars | Billing | Firewall | Members |
|------|--------|---------------|---------|----------|---------|
| Owner | Yes | Yes | Yes | Yes | Yes |
| Member | Yes | Yes | No | No | No |
| Developer | Yes | No | No | No | No |
| Security | No | No | No | Yes | No |
| Billing | No | No | Yes | No | No |
| Viewer | No | No | No | No | No |
| Contributor | Per-project | Per-project | No | No | No |

#### ClickOps Implementation

**Step 1: Audit Current Roles**
1. Navigate to: **Team Settings → Members**
2. Review all members and their assigned roles
3. Identify over-privileged accounts (Owners who should be Members, etc.)

**Step 2: Implement Least Privilege**
1. Downgrade accounts to minimum required role
2. Use Contributor role + project-level assignments for granular access
3. Create Access Groups for team-based project permissions
4. Assign Permission Groups additively (Create Project, Full Production Deployment, etc.)

**Step 3: Configure Access Groups (Enterprise)**
1. Navigate to: **Team Settings → Access Groups**
2. Create groups aligned to team structure (e.g., "Frontend Team", "Platform Team")
3. Assign projects with appropriate roles (Admin, Developer, Viewer)
4. Link to Directory Sync groups if SCIM is configured

**Time to Complete:** ~20 minutes

{% include pack-code.html vendor="vercel" section="1.3" %}

#### Validation & Testing

1. Developer role cannot modify production environment variables
2. Security role can manage firewall but cannot deploy
3. Viewer role has read-only access with no deploy capability
4. Contributor role has no access until explicitly assigned to a project

**Expected result:** Each team member has minimum required permissions

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC6.3 | Logical access controls, role-based access |
| **NIST 800-53** | AC-3, AC-6 | Access enforcement, least privilege |
| **ISO 27001** | A.9.1.2 | Access to networks and network services |
| **PCI DSS** | 7.1 | Limit access to system components |

---

### 1.4 Harden API Token Lifecycle

**Profile Level:** L1 (Baseline)

**NIST 800-53:** IA-5, IA-4

#### Description

Enforce scoped, time-limited API tokens and replace long-lived credentials with OIDC federation where possible.

#### Rationale

**Why This Matters:**
- Vercel now enforces 90-day maximum lifetime on granular tokens
- Classic tokens have been revoked platform-wide
- OIDC federation eliminates static credentials entirely for cloud provider access
- 2FA is required by default for token creation

**Attack Prevented:** Token theft, credential leakage in CI/CD logs, unauthorized API access

#### ClickOps Implementation

**Step 1: Audit Existing Tokens**
1. Navigate to: **Account Settings → Tokens**
2. Review all active tokens for scope and expiration
3. Delete unused or overly-scoped tokens

**Step 2: Create Scoped Tokens**
1. Create new tokens with minimum required scopes
2. Set expiration to shortest practical duration (max 90 days)
3. Use descriptive names indicating purpose (e.g., "github-actions-deploy")

**Step 3: Implement OIDC Federation (Preferred)**
1. Navigate to: **Team Settings → OIDC Federation**
2. Set issuer mode to **Team** (recommended over Global)
3. Configure cloud provider trust policies (AWS, GCP, Azure)
4. Replace static credentials in environment variables with OIDC token references

**Time to Complete:** ~30 minutes

{% include pack-code.html vendor="vercel" section="1.4" %}

#### Validation & Testing

1. No tokens exist with unlimited expiration
2. OIDC federation provides short-lived credentials (60-min TTL)
3. All CI/CD pipelines use scoped tokens or OIDC
4. Token creation requires 2FA

**Expected result:** No long-lived, overly-scoped tokens; OIDC for cloud provider access

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-5 | Authenticator management |
| **ISO 27001** | A.9.2.4 | Management of secret authentication information |
| **PCI DSS** | 8.2.4 | Change user passwords/passphrases at least every 90 days |

---

### 1.5 Audit Third-Party Integrations and OAuth Grants

**Profile Level:** L1 (Baseline)

**NIST 800-53:** AC-6, SA-12, CM-8

#### Description

Maintain an inventory of all Marketplace integrations, Git connections, deploy hooks, and third-party OAuth grants that can act against the Vercel team, and review them quarterly. Extend the audit into the identity providers (Google Workspace, GitHub org, Microsoft Entra, Slack) that issue OAuth trust to Vercel-adjacent vendors.

#### Rationale

**Why This Matters:**

- Third-party OAuth relationships are invisible to most security tooling and are not detected by Vercel's platform monitoring
- A compromised vendor with OAuth access to your identity provider can pivot into systems that trust it (including Vercel)
- Marketplace integrations and deploy hooks act with elevated team privileges even after the installer leaves

**Attack Prevented:** Vendor-to-vendor OAuth supply-chain compromise, orphaned integration privileges, deploy-hook URL leakage.

**Real-World Incidents:**

- **Vercel April 2026 incident:** Lumma Stealer on a Context.ai employee laptop stole Google Workspace OAuth tokens. The attacker used that OAuth trust to hijack a Vercel employee's Google Workspace account and enumerate customer non-sensitive environment variables. Customers with **no direct relationship** to Context.ai were affected. ([Vercel KB Bulletin](https://vercel.com/kb/bulletin/vercel-april-2026-security-incident), [Trend Micro analysis](https://www.trendmicro.com/en_us/research/26/d/vercel-breach-oauth-supply-chain.html))

#### Prerequisites

- Team Owner access in Vercel
- Admin access to Google Workspace, GitHub, Microsoft Entra, and any other OAuth issuers used by your organization
- Vercel API token with `read` scope

#### ClickOps Implementation

**Step 1: Vercel-side Inventory**

1. Navigate to: **Team Settings → Integrations** -- list all installed Marketplace integrations and the projects each has access to. Remove anything unused.
2. Navigate to: **Team Settings → Git** -- review connected Git namespaces. Remove stale installations.
3. For each project: **Project Settings → Git** -- confirm the Vercel GitHub App is scoped to specific repositories rather than entire organizations.
4. For each project: **Project Settings → Deploy Hooks** -- list all hooks, rotate any older than 90 days, and confirm each hook URL is stored in your secrets manager (not git).

**Step 2: Identity-Provider-side Audit (quarterly)**

1. **Google Workspace:** `admin.google.com` → **Security → API Controls → Third-party app access**. Revoke unrecognized apps and any Drive-permissioned apps that are not business-critical.
2. **GitHub Organization:** `github.com/organizations/<org>/settings/oauth_application_policy`. Review installed OAuth apps and GitHub Apps. Restrict the Vercel GitHub App to specific repositories.
3. **Microsoft Entra ID:** `entra.microsoft.com` → **Enterprise applications**. Review consented permissions for each Enterprise application.
4. **Slack:** `<workspace>.slack.com/apps/manage` → **Installed apps**. Audit scopes per app; remove unused integrations.

**Time to Complete:** ~60 minutes (initial), ~20 minutes (quarterly review)

{% include pack-code.html vendor="vercel" section="1.5" %}

#### Validation & Testing

1. All Marketplace integrations have a business owner on record
2. The Vercel GitHub App is scoped to specific repositories (not org-wide) for every connection
3. Every deploy hook URL is stored in a secrets manager and rotated ≤90 days ago
4. No unrecognized third-party OAuth grants exist in Google Workspace, GitHub, Entra, or Slack

**Expected result:** Every OAuth-trust relationship touching Vercel is explicitly authorized, scoped, and rotated on a schedule.

#### Monitoring & Maintenance

- **Quarterly:** Re-run the full inventory script and identity-provider audit
- **On event:** Re-audit immediately after any vendor security advisory affecting an OAuth-connected service
- **On event:** Rotate all deploy hooks and Vercel API tokens when a Vercel employee or any team member with admin access to a connected identity provider leaves

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | None | Background audit — no end-user impact |
| **System Performance** | None | Read-only API calls |
| **Maintenance Burden** | Medium | Quarterly human review required |
| **Rollback Difficulty** | Easy | Inventory is read-only; remediation actions are independently reversible |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC9.2 | Logical access controls, vendor management |
| **NIST 800-53** | AC-6, CM-8, SA-12 | Least privilege, information system component inventory, supply chain protection |
| **ISO 27001** | A.15.2.1, A.9.2.5 | Monitoring and review of supplier services, review of user access rights |
| **PCI DSS** | 12.8.2, 12.8.4 | Maintain service provider list; monitor service provider compliance |

---

## 2. Deployment Security

### 2.1 Configure Deployment Protection

**Profile Level:** L1 (Baseline)

**NIST 800-53:** CM-3, AC-3

#### Description

Enable multi-layered deployment protection using Vercel Authentication, password protection, and trusted IPs to prevent unauthorized access to preview and production deployments.

#### Rationale

**Why This Matters:**
- Preview deployments can expose unreleased features, staging credentials, and internal APIs
- Unprotected preview URLs are indexed by search engines and discoverable by attackers
- Production environment variables can leak through unprotected preview deployments

**Attack Prevented:** Unauthorized access to staging environments, information disclosure via preview URLs, credential harvesting from preview deployments

**Attack Scenario:** Attacker discovers `*.vercel.app` preview URL via DNS enumeration, accesses unprotected preview with staging database credentials exposed in client-side code.

#### Protection Methods × Scopes

Vercel documents three protection **methods** and four protection **scopes**. Choose one method and one scope per project.

**Methods:**

| Method | Plans | Notes |
|--------|-------|-------|
| Vercel Authentication | Hobby, Pro, Enterprise | Requires team login; covers Routing Middleware |
| Password Protection | Enterprise, or **Pro + $150/mo Advanced Deployment Protection add-on** | 30-day minimum commitment on Pro add-on |
| Trusted IPs | Enterprise only | IPv4 CIDR allowlist |

**Scopes:**

| Scope | Plans | What it covers |
|-------|-------|----------------|
| Standard Protection | All | Preview + generated URLs; production custom domain remains public |
| All Deployments | Pro, Enterprise | Preview + production + generated URLs |
| Only Production Deployments (via Trusted IPs) | Enterprise only | Production domain only; preview stays public |
| (Legacy) Standard / Pre-Production | All | Retained for backwards compatibility — migrate to current scopes |

**Hobby-plan caveat:** Vercel Authentication + Standard Protection on Hobby protects preview and generated URLs but production custom domains remain public.

#### ClickOps Implementation

**Step 1: Set Team Default for New Projects**

1. Navigate to: **Team Settings → Deployment Protection**
2. Configure the team default protection method + scope so new projects inherit the hardened baseline
3. Individual projects can override the default when legitimately required

**Step 2: Enable Standard Protection on Each Existing Project (L1, All Plans)**

1. Navigate to: **Project Settings → Deployment Protection**
2. Select scope **Standard Protection** and method **Vercel Authentication**
3. Note: Deployment Protection applies to **Routing Middleware** requests as well — automation that depends on reaching middleware without auth will need a bypass token

**Step 3: Add Password Protection (L2 — Enterprise or Pro Add-on)**

1. Enable **Password Protection** for the appropriate scope
2. Set a strong password and rotate quarterly; distribute via secrets manager, never in docs
3. For shareable-link scenarios use **Deployment Protection Exceptions** (Advanced DP) rather than disabling protection

**Step 4: Configure Trusted IPs (L3 — Enterprise)**

1. Add office and VPN egress IP ranges as trusted IPs
2. Set protection mode to **Trusted IP Required**
3. Apply to **All Deployments** for maximum protection — or to **Only Production Deployments** if previews must stay publicly accessible

**Step 5: Harden Protection Bypass for Automation**

1. Navigate to: **Project Settings → Deployment Protection → Protection Bypass for Automation**
2. If required, generate a bypass secret of 32+ random characters; exposed to builds via `VERCEL_AUTOMATION_BYPASS_SECRET`
3. Callers may present the secret via header `x-vercel-protection-bypass` or query parameter `?x-vercel-protection-bypass=...` (query form is required for Slack/Stripe webhook URL verification that cannot set headers)
4. For iframe scenarios, add query parameter `?x-vercel-set-bypass-cookie=samesitenone`
5. Bypass does **not** override active DDoS mitigations, rate limits during attacks, or attack-triggered challenges — defense-in-depth is preserved
6. Regenerating or deleting a bypass secret invalidates previously-deployed builds; a redeploy is required to take effect
7. L3: Disable automation bypass entirely if not required

**Time to Complete:** ~20 minutes

{% include pack-code.html vendor="vercel" section="2.1" %}

#### Validation & Testing

1. Unauthenticated access to preview URL returns login prompt
2. Password-protected deployment requires correct password
3. Access from non-trusted IP is blocked (Enterprise)
4. Automation bypass secret is 32+ characters if enabled
5. Requests to Routing Middleware without auth are rejected at the edge
6. Team default for new projects matches the hardened baseline

**Expected result:** All non-production deployments require authentication; team default enforces the baseline.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical and physical access controls |
| **NIST 800-53** | CM-3, AC-3 | Configuration change control, access enforcement |
| **ISO 27001** | A.14.2.5 | Secure system engineering principles |
| **PCI DSS** | 6.4.1 | Separate development/test from production |

---

### 2.2 Harden Git Integration

**Profile Level:** L1 (Baseline)

**NIST 800-53:** CM-7, SA-10

#### Description

Secure the Git integration pipeline to prevent unauthorized deployments from forks, unverified commits, and compromised repositories.

#### Rationale

**Why This Matters:**
- Fork-based deployments can inject malicious code into your deployment pipeline
- Unverified commits may contain unauthorized changes
- Unrestricted deployment triggers enable supply chain attacks

**Attack Prevented:** Supply chain injection via forks, unauthorized code deployment, commit impersonation

#### ClickOps Implementation

**Step 1: Enable Fork Protection**
1. Navigate to: **Project Settings → Git**
2. Ensure **Git Fork Protection** is enabled (blocks deployments from forked repos without approval)

**Step 2: Restrict Deployment Creation (L2)**
1. Set **Create Deployments** to **Only Production** -- prevents preview deployments from PRs
2. Or set to **Disabled** for fully manual deployment control

**Step 3: Require Verified Commits (L2)**
1. Enable **Require Verified Commits** in Git provider options
2. Configure commit signing in your Git provider (GPG or SSH keys)

**Step 4: Review Connected Repositories**
1. Navigate to: **Team Settings → Integrations**
2. Audit all connected Git repositories
3. Remove access to repositories no longer in use
4. Limit repository access to specific repos rather than full organization access

**Time to Complete:** ~10 minutes

{% include pack-code.html vendor="vercel" section="2.2" %}

#### Validation & Testing

1. Fork deployment is blocked without explicit approval
2. Unsigned commits fail deployment (when verified commits enabled)
3. Only authorized repositories are connected
4. Deployment creation restricted to production-only (L2)

**Expected result:** Deployment pipeline only accepts authorized, verified code

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC8.1 | Change management controls |
| **NIST 800-53** | CM-7, SA-10 | Least functionality, developer security testing |
| **ISO 27001** | A.14.2.2 | System change control procedures |
| **PCI DSS** | 6.3.2 | Review custom code prior to release |

---

### 2.3 Configure Rolling Releases

**Profile Level:** L2 (Hardened)

**NIST 800-53:** CM-3(2)

#### Description

Enable progressive deployment rollouts to limit blast radius of production changes. Pair with Skew Protection so client code and backend APIs always come from the same deployment revision.

#### Rationale

**Why This Matters:**

- Full instant deployments expose 100% of traffic to potential issues
- Rolling releases enable canary-style testing with real production traffic
- Manual approval gates add human verification before full rollout

**Attack Prevented:** Blast radius of compromised deployments, rapid exploitation of deployed vulnerabilities, client/server version mismatch during rollout.

#### Security Caveats from Vercel Docs

- **Skew Protection is required for defense in depth.** Without it, a user can fetch a page from one deployment and send API calls that are served by the other — breaking invariants that security code depends on.
- **0% canaries are not securely hidden.** Any visitor can force the canary deployment by appending `?vcrrForceCanary=true` to a URL. Do not use 0% stages to stage secret pre-release changes; use Deployment Protection Exceptions instead.
- **The `vcrrForceStable=true` / `vcrrForceCanary=true` query parameters** are honored by Vercel edge and write a cookie. Treat traffic from these parameters as attacker-controllable; do not use them as a trust signal.

#### ClickOps Implementation

**Step 1: Enable Skew Protection (Prerequisite)**

1. Navigate to: **Project Settings → Advanced → Skew Protection**
2. Set maximum skew window to `12 hours` or the minimum your deployment cadence supports

**Step 2: Configure Rolling Release**

1. Navigate to: **Project Settings → Build & Deployment → Rolling Releases**
2. Choose **Manual Approval** for production deployments
3. Configure stages (e.g., 5% → 25% → 100%) — the last stage must always be 100%
4. Set duration for automatic advancement if using automatic mode

**Step 3: Document Rollback Path**

1. Confirm **Instant Rollback** is available from the **Deployments** page or REST API (`POST /v1/projects/{projectId}/rollback/{deploymentId}`)
2. Rehearse the rollback procedure with the on-call team at least once per quarter

**Time to Complete:** ~15 minutes

{% include pack-code.html vendor="vercel" section="2.3" %}

#### Validation & Testing

1. New deployment starts at first stage percentage
2. Manual approval required before advancing (if configured)
3. Skew Protection prevents client/server mismatch for the configured window
4. Rollback available at any stage
5. 0% canary stages are treated as accessible to the public (not a privacy boundary)

**Expected result:** Production deployments roll out progressively with approval gates, paired with Skew Protection.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC8.1 | Change management process |
| **NIST 800-53** | CM-3(2) | Testing, validation, and documentation of changes |
| **ISO 27001** | A.14.2.9 | System acceptance testing |
| **PCI DSS** | 6.4.5 | Change control procedures |

---

### 2.4 Private Production Deployments (Advanced Deployment Protection)

**Profile Level:** L2 (Hardened)

**NIST 800-53:** AC-3, SC-7, AC-4

#### Description

Restrict access to production domains — not just preview URLs — to authenticated users, corporate IP ranges, or password-holders. Available to Enterprise plans and to Pro teams that opt into the Advanced Deployment Protection add-on ($150/month, 30-day minimum commitment).

#### Rationale

**Why This Matters:**

- Internal tools, admin consoles, and staging-adjacent production workloads often have no business being indexed by search engines or reachable by anonymous traffic
- "Private production" reduces attack surface for applications that only serve authenticated users anyway
- The Advanced DP add-on unlocks Password Protection and Deployment Protection Exceptions on Pro without requiring an Enterprise contract

**Attack Prevented:** Anonymous reconnaissance of production admin surfaces, credential-stuffing at public login pages, automated scanning of production endpoints.

#### Prerequisites

- Vercel Pro plan + **Advanced Deployment Protection** add-on ($150/month, minimum 30 days before disabling), **or** Enterprise plan
- Trusted IP list (if using Trusted IPs) or IdP for Vercel Authentication or password distribution channel

#### ClickOps Implementation

**Step 1: Enable Advanced Deployment Protection (Pro only)**

1. Navigate to: **Project Settings → Deployment Protection**
2. Choose one of **Password Protection**, **Private Production Deployments (All Deployments)**, or **Deployment Protection Exceptions**
3. Click **Enable and Pay** when prompted
4. Add-on activates immediately; all Advanced DP features unlock

**Step 2: Choose a Scope**

1. **All Deployments:** preview + production + generated URLs all require authentication
2. **Only Production Deployments (Trusted IPs, Enterprise):** production domain restricted to trusted IPs; preview remains publicly accessible for iteration
3. **Standard Protection + Exceptions:** keep standard protection, explicitly grant named exceptions for external services or shareable preview links

**Step 3: Configure Method**

1. Select **Vercel Authentication** (team members only), **Password Protection** (strong password distributed via secrets manager), or **Trusted IPs** (Enterprise)
2. For production-only Trusted IPs, set `protection_mode = trusted_ip_required` and `deployment_type = production`

**Step 4: Plan 30-Day Minimum Commitment (Pro Add-on)**

1. Note the add-on bills for a minimum 30 days before it can be disabled
2. Review the use-case quarterly to decide whether to keep, downgrade to Standard Protection, or upgrade to Enterprise

**Time to Complete:** ~20 minutes (including billing approval)

{% include pack-code.html vendor="vercel" section="2.4" %}

#### Validation & Testing

1. Unauthenticated request to production domain returns the Vercel auth/password gate
2. Non-trusted-IP request to production is blocked at the edge (Enterprise Trusted IPs scope)
3. Deployment Protection Exceptions work for the specific named paths/services only
4. Billing reflects the $150/month Pro add-on line item (Pro teams)

**Expected result:** Production domains enforce the chosen protection method end-to-end.

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium-High | End users outside the team/trusted IPs cannot reach production |
| **System Performance** | None | Enforced at the edge |
| **Maintenance Burden** | Low | Password rotation + Trusted IP list maintenance |
| **Rollback Difficulty** | Moderate | Must wait 30 days before disabling Pro add-on |

**Potential Issues:**

- Webhook callers (Slack, Stripe, external CI) will need Protection Bypass for Automation tokens or be added to Deployment Protection Exceptions
- Public search engine indexing is suppressed — do not use Private Production for content that must remain discoverable

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC6.6 | Access controls, physical and logical boundaries |
| **NIST 800-53** | AC-3, AC-4, SC-7 | Access enforcement, information flow enforcement, boundary protection |
| **ISO 27001** | A.13.1.3 | Segregation in networks |
| **PCI DSS** | 1.3, 6.4.1 | Prohibit direct public access, separate dev/test from production |

---

## 3. Web Application Firewall

### 3.1 Enable WAF with Managed Rulesets

**Profile Level:** L2 (Hardened)

**NIST 800-53:** SC-7, SI-3

#### Description

Enable the Vercel Web Application Firewall with OWASP managed rulesets, bot protection, and AI bot filtering.

#### Rationale

**Why This Matters:**

- Vercel WAF cannot be bypassed once enabled — all traffic passes through it
- Managed rulesets protect against OWASP Top 10 without custom rule writing
- Vercel paid $1M+ across 20 unique bypass techniques during the React2Shell bounty, validating rule tuning — but the result was specific to that vulnerability class and does **not** guarantee protection against future CVEs
- Rules propagate globally in under 300ms with instant rollback capability
- Vercel Firewall uses JA3/JA4 TLS client-hello fingerprints in addition to IP, header, and path signals to classify traffic

**Attack Prevented:** SQL injection, XSS, command injection, path traversal, remote file inclusion, bot abuse, AI scraping.

**Real-World Incidents:**

- **CVE-2025-29927 (Next.js middleware auth bypass):** Vercel deployed a WAF rule stripping `x-middleware-subrequest` at the edge **before** public disclosure — Vercel-hosted customers were auto-protected. Discovered by [zhero_web_security](https://zhero-web-sec.github.io/research-and-things/nextjs-and-the-corrupt-middleware) + yvvdwf.
- **React2Shell (CVE-2025-55182 / 66478):** Critical RCE in React Server Components — Vercel shipped 20 WAF iterations in 48 hours during the $1M bounty, but external researchers consistently found bypasses, underscoring that patching the framework is mandatory (see Section 9).

#### Firewall Rule Execution Order

Per Vercel docs, every request passes through these layers in order:

1. DDoS mitigation (automatic, all plans)
2. WAF IP blocking
3. WAF custom rules (including Persistent Actions — see Section 3.3)
4. WAF Managed Rulesets

#### Reverse-Proxy Caveat

Placing a reverse proxy (Cloudflare, Azure Front Door, AWS CloudFront) **in front** of Vercel significantly degrades Bot Protection accuracy: the proxy masks JA3/JA4 signals and rotates exit IPs that Vercel relies on for classification. If a dedicated perimeter WAF is required for multi-cloud or regulatory reasons, disable Vercel Bot Protection and rely on the front WAF; otherwise run Vercel Firewall directly.

#### Prerequisites

- Vercel Enterprise plan for managed rulesets
- Pro plan for custom rules (up to 40)

#### ClickOps Implementation

**Step 1: Enable Firewall**

1. Navigate to: **Project → Firewall**
2. Toggle firewall to **Enabled**

**Step 2: Enable OWASP Managed Rulesets (Enterprise)**

1. Navigate to: **Firewall → Rules → WAF Managed Rulesets**
2. Enable **OWASP Core Ruleset** in **Log** mode first
3. Monitor live traffic in the Firewall observability view for 48-72 hours and tune false positives
4. Switch to **Deny** mode rule-by-rule after tuning

**Step 3: Enable Bot Protection (Challenge)**

1. From **Firewall → Rules → Bot Management**, set the **Bot Protection** managed rule to **Challenge**
2. Verified bots (Googlebot, webhook providers, services on the [bots.fyi](https://bots.fyi/) directory) are auto-allowed
3. For custom automated clients, add a **WAF Custom Rule** with a **Bypass** action matching your `User-Agent` or `Signature-Agent` header

**Step 4: Enable AI Bots Managed Ruleset**

See Section 3.4 — configure in **Log** mode, review for 7 days, then decide Deny vs Allow based on your content licensing policy.

**Step 5: Configure Custom Rules (Pro+)**

1. Create rules for application-specific protection; always start in **Log** mode
2. For GitOps, declare rules in `vercel.json` under `routes[].mitigate` — but note **only `challenge` and `deny` actions** are supported in config-as-code; `log`, `bypass`, and `redirect` are dashboard-only
3. Pair abuse-blocking rules with **Persistent Actions** (Section 3.3) to prevent repeat requests billing through the CDN

**Time to Complete:** ~30 minutes

{% include pack-code.html vendor="vercel" section="3.1" %}

#### Validation & Testing

1. WAF is enabled and processing traffic (check Firewall tab)
2. OWASP rules detecting common attack patterns in logs
3. Bot protection challenging automated requests
4. AI bots blocked (if configured)

**Expected result:** WAF actively filtering malicious traffic with managed rulesets

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | Security measures against threats outside boundaries |
| **NIST 800-53** | SC-7, SI-3 | Boundary protection, malicious code protection |
| **ISO 27001** | A.13.1.1 | Network controls |
| **PCI DSS** | 6.6 | Web application firewall |

---

### 3.2 Configure IP Blocking and Rate Limiting

**Profile Level:** L1 (Baseline)

**NIST 800-53:** SC-5, SI-4

#### Description

Implement IP-based access control and rate limiting to protect against brute force attacks, abuse, and targeted threats.

#### Rationale

**Why This Matters:**
- IP blocking available on all plans (Hobby: 10, Pro: 100, Enterprise: custom)
- Rate limiting prevents brute force, credential stuffing, and API abuse
- Persistent actions automatically block repeat offenders for configurable durations

**Attack Prevented:** Brute force attacks, credential stuffing, API abuse, scraping, DDoS amplification

#### ClickOps Implementation

**Step 1: Block Known Bad IPs**
1. Navigate to: **Project → Firewall → IP Blocking**
2. Add known malicious IP addresses or ranges
3. Use per-host blocking for domain-specific rules

**Step 2: Configure Rate Limiting Rules (Pro+)**
1. Navigate to: **Firewall → Configure → Rules**
2. Create rate limiting rules for sensitive endpoints:
   - Authentication endpoints: 10 requests/minute per IP
   - API endpoints: appropriate limits per use case
   - Registration: 5 requests/minute per IP
3. Set follow-up action to **Deny** with persistent duration (e.g., 5 minutes)
4. Use **Log** action first to validate thresholds

**Step 3: Enable Persistent Actions**
1. Configure persistent actions on deny/challenge rules
2. Set duration based on attack type (1 min for rate limits, longer for abuse patterns)

**Time to Complete:** ~15 minutes

{% include pack-code.html vendor="vercel" section="3.2" %}

#### Validation & Testing

1. Blocked IPs return 403/challenge response
2. Rate-limited endpoints enforce configured thresholds
3. Persistent actions block repeat offenders
4. Rules show in Firewall activity logs

**Expected result:** Malicious and abusive traffic blocked at the edge

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | Security measures against external threats |
| **NIST 800-53** | SC-5, SI-4 | Denial of service protection, system monitoring |
| **ISO 27001** | A.13.1.2 | Security of network services |
| **PCI DSS** | 11.4 | Intrusion-detection/prevention techniques |

---

### 3.3 Configure Firewall Persistent Actions

**Profile Level:** L2 (Hardened)

**NIST 800-53:** SC-5, SI-4

#### Description

Persistent Actions are time-based IP-level blocks that execute **before** the request reaches the CDN. On first match, subsequent requests from the same source are rejected at the firewall edge for the configured duration without accruing CDN bandwidth or compute billing.

#### Rationale

**Why This Matters:**

- Repeat-abuse scans (vulnerability probes, brute-force, scraping) drive the largest share of attacker-induced cost amplification on Vercel — the Shared Responsibility Model explicitly makes malicious-traffic billing the customer's responsibility
- Without Persistent Actions, every retry from the same IP incurs at least minimal CDN processing cost
- With Persistent Actions, the first match creates a time-boxed block that enforces at the edge for free

**Attack Prevented:** Attacker-driven cost amplification, scanner persistence, brute-force credential attacks.

#### Prerequisites

- WAF Custom Rules enabled on the project (Pro+)
- Known abuse patterns or sensitive endpoints to protect

#### ClickOps Implementation

**Step 1: Identify Targets**

1. Review Firewall observability for the top 10 probed paths (typical: `/.env`, `/.git`, `/wp-admin`, `/admin`, `/phpmyadmin`)
2. Identify sensitive endpoints that must not be scanned (`/api/auth/*`, `/api/billing/*`)

**Step 2: Create Persistent Deny Rule for Scanner Paths**

1. Navigate to: **Firewall → Rules → Custom Rules → Create Rule**
2. Name: `hth-persistent-block-scanners`
3. Condition: `path` starts with any of `/.env`, `/.git`, `/wp-admin`
4. Action: `Deny` with `actionDuration: 24h` and `persistentAction: true`

**Step 3: Create Persistent Rate Limit on Auth Endpoints**

1. Create rule named `hth-auth-rate-limit-persistent`
2. Condition: `path` starts with `/api/auth`
3. Action: `Rate Limit` (20 req/min, fixed-window, keyed by IP) with follow-up action `Deny` for `1h`, `persistentAction: true`

**Step 4: Review Weekly**

1. From Firewall observability, verify Persistent Actions are firing against expected traffic
2. Adjust thresholds or add exceptions for false positives

**Time to Complete:** ~20 minutes

{% include pack-code.html vendor="vercel" section="3.3" %}

#### Validation & Testing

1. Repeat probing from a single IP is blocked after the first hit for the configured duration
2. Firewall observability shows `persistentAction: true` on matched rules
3. Blocked requests do **not** appear in CDN bandwidth/compute usage

**Expected result:** Scanner and brute-force traffic is blocked at zero cost to the customer.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | External threat protections |
| **NIST 800-53** | SC-5(1), SI-4(4) | Denial-of-service protection, inbound/outbound monitoring |
| **ISO 27001** | A.13.1.1 | Network controls |
| **PCI DSS** | 11.4 | Network intrusion-detection/prevention |

---

### 3.4 Configure AI Bots Managed Ruleset

**Profile Level:** L2 (Hardened)

**NIST 800-53:** SI-4, AC-4

#### Description

Control traffic from known AI crawlers — training crawlers, search-assistant user fetches, and generative scrapers — using Vercel's managed AI Bots ruleset. Log first, then decide whether to allow or deny based on your content-licensing and data-sensitivity posture.

#### Rationale

**Why This Matters:**

- AI crawlers account for a growing share of request volume on public sites and can drive both cost and content-exfiltration concerns
- Many AI crawlers ignore `robots.txt`; edge-side blocking is the only reliable enforcement
- The AI Bots list is continuously updated by Vercel — new crawlers inherit your existing Log/Deny decision

**Attack Prevented:** Unlicensed training data extraction, competitive scraping, elevated costs from unwanted automated traffic.

#### Prerequisites

- WAF Managed Rulesets available on plan (Enterprise, or Pro with applicable add-on)
- Policy decision: allow, log, or deny AI crawlers

#### ClickOps Implementation

**Step 1: Enable in Log Mode**

1. Navigate to: **Firewall → Rules → Bot Management → AI Bots Ruleset**
2. Set action to **Log**
3. Save and publish

**Step 2: Observe for 7 Days**

1. Review Firewall observability daily and confirm no business-critical AI-assistant traffic (e.g., user-authorized ChatGPT web-browsing fetches for your internal users) is being matched

**Step 3: Decide Deny vs Allow**

1. If content is proprietary or not licensed for AI training, switch to **Deny**
2. If the site benefits from AI discoverability (docs, marketing), leave at **Log** and optionally add a narrower **Custom Rule** to block only specific crawlers that ignore robots.txt

**Step 4: Document Exception Paths**

1. Use WAF Custom Rules with **Bypass** action to explicitly allow specific crawlers you do want (e.g., your own enterprise AI assistant)

**Time to Complete:** ~15 minutes (plus 7 days of observation)

{% include pack-code.html vendor="vercel" section="3.4" %}

#### Validation & Testing

1. Known AI crawler user-agents hit the rule when probing the site
2. Firewall observability shows AI Bot traffic volume before/after the action change
3. Legitimate bots (search engines, webhook providers) remain unaffected

**Expected result:** AI crawler traffic is visible and (optionally) blocked.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | External threat and unauthorized-access protection |
| **NIST 800-53** | SI-4, AC-4 | Monitoring, information flow enforcement |
| **ISO 27001** | A.13.1.1, A.13.2.1 | Network controls; information transfer policies |
| **PCI DSS** | 12.10.5 | Include alerts from monitoring systems |

---

## 4. Network Security

### 4.1 Enable Secure Compute

**Profile Level:** L3 (Maximum Security)

**NIST 800-53:** SC-7, SC-8

#### Description

Deploy Serverless Functions within dedicated private networks with static IPs, VPC peering, and network isolation using Vercel Secure Compute.

#### Rationale

**Why This Matters:**

- Dedicated IP pairs not shared with any other customer
- Enables IP allowlisting on backend databases and APIs
- Full network isolation in a private VPC
- Regional failover with active + passive networks

**Attack Prevented:** Shared IP abuse, unauthorized backend access, network-level lateral movement.

#### Critical Architecture Caveats (Primary Source)

Per [Vercel Secure Compute docs](https://vercel.com/docs/connectivity/secure-compute):

- **Edge Runtime is NOT supported.** Routing Middleware and edge functions **do not route through Secure Compute** and will use shared Vercel IP pools. If your backend allowlists only Secure Compute static IPs, middleware traffic will be rejected by the backend — or worse, silently fall back to a shared-IP path you thought was blocked. Design middleware to not require access to backend services allowlisted on Secure Compute, or rewrite middleware logic into Node.js / Python / Ruby runtimes that do route through Secure Compute.
- **Supported runtimes:** Node.js, Python, Ruby only.
- **VPC peering limit:** maximum 50 peering connections per Secure Compute network.
- **Build container inclusion is optional.** Include only if builds access allowlisted data sources; otherwise opt out to save the ~5-second provision delay.
- **Active + Passive networks** provide regional failover per project environment; both must be provisioned explicitly.

#### Prerequisites

- Vercel Enterprise plan
- Secure Compute add-on ($6,500/year + $0.15/GB Secure Connect Data Transfer)
- Backend services supporting IP allowlisting
- Application audit: confirm middleware / edge functions do not require backend services that will be allowlist-restricted to Secure Compute IPs

#### ClickOps Implementation

**Step 1: Audit Application for Edge-Runtime Dependencies**

1. List all middleware files and edge-runtime functions in the project
2. Trace each outbound HTTP/DB call from those surfaces and confirm it does **not** target a service that will be IP-allowlisted to Secure Compute
3. Move any such calls into Node.js/Python/Ruby function runtimes before enabling backend IP allowlisting

**Step 2: Create Secure Compute Network**

1. Navigate to: **Team Settings → Connectivity → Create Network**
2. Select AWS region closest to your backend
3. Configure CIDR block (must not overlap with VPC peer ranges)
4. Select availability zones

**Step 3: Assign Projects**

1. Add projects to the network
2. Configure per-environment (Production, Preview, etc.)
3. Optionally include build container (adds ~5s provisioning delay)

**Step 4: Configure VPC Peering (Optional, max 50 per network)**

1. Create peering connection from Vercel dashboard
2. Accept in AWS VPC dashboard
3. Update route tables in both VPCs
4. Configure security groups to allow Vercel IP ranges

**Step 5: Update Backend Allowlists**

1. Add Vercel dedicated IPs to backend database firewall rules
2. Add to API gateway IP allowlists
3. **Always layer authentication on top of IP filtering** — IP alone is not sufficient

**Step 6: Configure Region Failover**

1. Create Active + Passive networks in different regions
2. Link both to each project environment
3. Vercel automatically switches to the Passive network if the primary region fails

**Time to Complete:** ~90 minutes (including application audit)

{% include pack-code.html vendor="vercel" section="4.1" %}

#### Validation & Testing

1. Functions connect to backend via private network
2. Backend rejects connections from non-Vercel IPs
3. Region failover switches to passive network on outage
4. VPC peering routes traffic correctly (if configured)

**Expected result:** Serverless Functions operate in isolated private network with static egress IPs

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | SC-7, SC-8 | Boundary protection, transmission confidentiality |
| **ISO 27001** | A.13.1.3 | Segregation in networks |
| **PCI DSS** | 1.3 | Network access to the cardholder data environment is restricted |

---

### 4.2 Configure DDoS Protection and Attack Challenge Mode

**Profile Level:** L1 (Baseline)

**NIST 800-53:** SC-5, CP-10

#### Description

Leverage Vercel's automatic DDoS mitigation and configure Attack Challenge Mode for active attack response.

#### Rationale

**Why This Matters:**
- Automatic L3/L4/L7 DDoS mitigation on all plans at no cost
- Blocked DDoS traffic is NOT billed
- Attack Challenge Mode provides additional layer during active targeted attacks
- System Bypass Rules prevent legitimate traffic from being blocked

**Attack Prevented:** Volumetric DDoS, SYN floods, application-layer floods, amplification attacks

#### Attack Challenge Mode — Internal Request Boundary (Primary Source)

Per [Vercel docs](https://vercel.com/docs/vercel-firewall/attack-challenge-mode):

- When Attack Challenge Mode is enabled, requests from **your own Vercel account's Functions, Cron Jobs, and projects** are automatically allowed through without being challenged. Other Vercel accounts cannot bypass your ACM.
- Known verified bots (search engines, webhook providers, services listed in the Vercel bot directory) are auto-allowed.
- All traffic initiated by web browsers is supported, including SPA API traffic between pages of the same Vercel project.
- **Standalone APIs and non-browser clients may fail the JavaScript challenge and be blocked.** If your site serves machine-to-machine APIs from the same deployment, plan bypass paths (WAF Custom Rule with Bypass action) before enabling.
- ACM is **free on all plans, unlimited**, and blocked requests do **not** count toward usage quotas.
- Safe for extended enablement — Googlebot and other verified crawlers remain unaffected, so SEO is not harmed.

#### ClickOps Implementation

**Step 1: Verify DDoS Protection (Automatic)**

1. DDoS protection is always enabled — no configuration required
2. Verify in: **Project → Firewall** — should show traffic monitoring

**Step 2: Configure Attack Challenge Mode (During Attacks)**

1. Navigate to: **Project → Firewall → Bot Management → Attack Challenge Mode**
2. Enable during active attacks — challenges browser traffic with a JS challenge
3. Same-account Vercel requests (your Functions, Cron Jobs, cross-project calls) auto-bypass
4. Verified bots auto-bypass
5. Disable when attack subsides; Vercel recommends ACM as a targeted-attack tool, not a permanent setting
6. For standalone APIs that will be called by non-browser clients, create a WAF Custom Rule with a Bypass action matching an API signature (e.g., `User-Agent` or `x-api-key`) **before** enabling ACM

**Step 3: Configure Spend Management (Pro+)**

1. Navigate to: **Team Settings → Billing → Spend Management**
2. Set usage thresholds with automatic actions
3. Configure webhook notifications for usage spikes
4. Enable auto-pause for non-critical projects — per the Shared Responsibility Model, malicious-traffic costs are customer-owned

**Step 4: Configure System Bypass Rules (L2 — Pro+)**

1. Create rules to ensure essential traffic (trusted proxies, known partner IP ranges) is never blocked
2. Use for business-critical external services

**Time to Complete:** ~10 minutes

{% include pack-code.html vendor="vercel" section="4.2" %}

#### Validation & Testing

1. DDoS mitigation active (always on -- verify via Firewall dashboard)
2. Attack Challenge Mode can be enabled/disabled
3. Spend management alerts configured
4. Blocked traffic not appearing in billing

**Expected result:** Multi-layered DDoS protection with cost controls

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | A1.2 | Environmental protections |
| **NIST 800-53** | SC-5, CP-10 | Denial of service protection, system recovery |
| **ISO 27001** | A.17.2.1 | Availability of information processing facilities |
| **PCI DSS** | 11.4 | Intrusion detection/prevention |

---

## 5. Security Headers

### 5.1 Configure Security Response Headers

**Profile Level:** L1 (Baseline)

**NIST 800-53:** SI-10, SC-28

#### Description

Configure security headers (CSP, X-Frame-Options, Referrer-Policy, etc.) to protect against client-side attacks. Vercel does NOT set these automatically beyond HSTS -- you must configure them.

#### Rationale

**Why This Matters:**
- Vercel auto-configures HSTS but NO other security headers
- Missing CSP enables XSS attacks; missing X-Frame-Options enables clickjacking
- Security headers are the primary defense against client-side attacks
- Headers must be set by the customer per Vercel's shared responsibility model

**Attack Prevented:** Cross-site scripting (XSS), clickjacking, MIME-type sniffing, referrer leakage, unauthorized API embedding

**Real-World Incidents:**
- **Vercel XSS in Clone URL** (2024): Reflected XSS found in Vercel's own clone functionality -- reinforces need for CSP even on trusted platforms

#### ClickOps Implementation

**Step 1: Configure via vercel.json**
1. Add a `headers` configuration block to your `vercel.json`
2. Apply to all routes using `source: "/(.*)"` pattern

**Step 2: Required Security Headers**
1. `Content-Security-Policy`: Define allowed content sources (most impactful header)
2. `X-Frame-Options`: Set to `DENY` or `SAMEORIGIN`
3. `X-Content-Type-Options`: Set to `nosniff`
4. `Referrer-Policy`: Set to `strict-origin-when-cross-origin`
5. `Permissions-Policy`: Restrict browser features (camera, microphone, geolocation, etc.)
6. `X-XSS-Protection`: Set to `1; mode=block` (legacy but still useful)

**Step 3: Validate**
1. Test with SecurityHeaders.com
2. Review CSP reports if using `report-uri` or `report-to` directive

**Time to Complete:** ~20 minutes

{% include pack-code.html vendor="vercel" section="5.1" %}

#### Validation & Testing

1. All six security headers present in response
2. SecurityHeaders.com score of A or A+
3. No CSP violations in browser console for legitimate resources
4. X-Frame-Options prevents iframe embedding

**Expected result:** All security headers configured and validated

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | Security measures against threats |
| **NIST 800-53** | SI-10, SC-28 | Information input validation, protection of information at rest |
| **ISO 27001** | A.14.1.2 | Securing application services on public networks |
| **PCI DSS** | 6.5.7 | Cross-site scripting (XSS) |

---

## 6. Secrets Management

### 6.1 Environment Variable Security

**Profile Level:** L1 (Baseline)

**NIST 800-53:** SC-28, SC-12

#### Description

Implement secure environment variable management with proper scoping, **mandatory Sensitive flag**, and access controls. Post April 2026 incident, the team-wide Enforce Sensitive Environment Variables policy is a baseline L1 control — not L2.

#### Rationale

**Why This Matters:**

- All environment variables are encrypted at rest (AES-256) by Vercel, but **non-sensitive variables can be decrypted and displayed by anyone with team-scope access** via the dashboard or API. Only **Sensitive** variables are stored in a truly unreadable format.
- Variables scoped to production are only accessible to Owner/Member/Project Admin roles
- `NEXT_PUBLIC_` prefixed variables are inlined into the client JavaScript bundle by Next.js — **never use for secrets** (see Section 6.4 for automated lint)
- Preview branches can access production secrets if not properly scoped
- Sensitive variables are **not supported in the Development environment** — local dev secrets must be managed out of band (1Password, HashiCorp Vault, Doppler)
- Total limit: 64 KB per deployment; Edge Functions: 5 KB per variable

**Attack Prevented:** Secret exposure in client bundles, credential leakage via preview deployments, unauthorized production secret access, mass-exposure during platform incidents affecting non-sensitive storage.

**Real-World Incidents:**

- **Vercel April 2026 incident:** The attacker enumerated and decrypted **only non-sensitive** customer environment variables. Variables explicitly marked Sensitive remained unreadable. Customers with the team-wide Sensitive Environment Variable policy enabled were protected. ([Vercel KB Bulletin](https://vercel.com/kb/bulletin/vercel-april-2026-security-incident))

**Attack Scenario:** Developer creates a `NEXT_PUBLIC_API_SECRET` variable, exposing it in the client-side JavaScript bundle. Attacker views page source to extract the API key. See [Cremit research](https://www.cremit.io/blog/vercel-secret-exposure-case-study) — live API keys found in 0.45% of public Vercel deployments via this vector.

#### ClickOps Implementation

**Step 1: Enforce Sensitive Environment Variable Policy (L1 — post April 2026)**

1. Navigate to: **Team Settings → Security & Privacy → Environment Variable Policies**
2. Toggle **Enforce Sensitive Environment Variables** to **Enabled** (requires Owner role)
3. All newly-created Production and Preview environment variables will now default to Sensitive and cannot be read back

**Step 2: Retrofit Existing Variables**

1. Navigate to: **Project Settings → Environment Variables**
2. For any variable holding a secret that is **not** flagged Sensitive: **delete and recreate** it with the Sensitive option enabled. (You cannot mark an existing variable Sensitive in place — you must remove and re-add.)
3. Rotate the underlying secret value at the source system during this process (post-incident hygiene)

**Step 3: Audit for Client-Bundle Leakage**

1. Verify no secrets use `NEXT_PUBLIC_` prefix
2. Add the Section 6.4 lint to CI to enforce this automatically going forward

**Step 4: Scope Variables Properly**

1. Production secrets: Scope to **Production** only
2. Preview/staging secrets: Use **separate, lower-privilege** credentials for Preview — never reuse production credentials
3. Use branch-specific preview variables when different branches need different configs
4. Use shared (team-level) variables for consistent cross-project configuration — mark these Sensitive too

**Step 5: Local Development Secret Handling**

1. Because Sensitive env vars are not available in Development, do **not** store local-dev credentials in Vercel env vars
2. Use an out-of-band secret manager (1Password, HashiCorp Vault, Doppler, `.env.local` via `vercel env pull` for OIDC tokens only)
3. Document the team's local-secrets workflow in an engineering handbook

**Step 6: Implement OIDC Federation (L2)**

1. Replace static cloud credentials with OIDC tokens (see Section 1.4) — eliminates the long-lived credential problem entirely
2. OIDC provides 60-minute TTL tokens; 45-minute function cache to prevent mid-execution expiry

**Time to Complete:** ~30 minutes (initial) + time for rotation

{% include pack-code.html vendor="vercel" section="6.1" %}

#### Validation & Testing

1. **Enforce Sensitive Environment Variables** toggle is **Enabled** at Team level
2. Every environment variable in every project has the Sensitive tag (production + preview)
3. No `NEXT_PUBLIC_` variables contain secret values
4. Production secrets not accessible in preview environment
5. Local dev workflow does not depend on Vercel-stored Development env vars for secrets
6. OIDC federation active for cloud provider access (L2)

**Expected result:** Every secret in every environment is either Sensitive-flagged or replaced by OIDC federation; no secret is readable from the dashboard or API after creation.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC6.7 | Logical access controls, protection of sensitive information |
| **NIST 800-53** | SC-28, SC-12 | Protection of information at rest, cryptographic key management |
| **ISO 27001** | A.10.1.2, A.9.4.3 | Key management, password management system |
| **PCI DSS** | 3.4, 8.2.1 | Render PAN unreadable, strong credential storage |

---

### 6.2 Deployment Retention Policy

**Profile Level:** L2 (Hardened)

**NIST 800-53:** SI-12

#### Description

Configure deployment retention policies to automatically remove old deployments that may contain outdated secrets or vulnerable code.

#### Rationale

**Why This Matters:**
- Old deployments remain accessible with their original environment variables
- Retaining deployments indefinitely increases attack surface
- Compliance frameworks require data retention policies

**Attack Prevented:** Exploitation of outdated deployments with known vulnerabilities or leaked secrets

#### ClickOps Implementation

**Step 1: Configure Retention**
1. Navigate to: **Project Settings → Deployment Retention**
2. Set production retention: 1 year (or per compliance requirement)
3. Set preview retention: 1 month
4. Set errored/canceled retention: 1 week

**Time to Complete:** ~5 minutes

{% include pack-code.html vendor="vercel" section="6.2" %}

#### Validation & Testing

1. Retention policies set per environment type
2. Old deployments automatically cleaned up

**Expected result:** Deployment history managed with appropriate retention limits

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.5 | Disposal of confidential information |
| **NIST 800-53** | SI-12 | Information management and retention |
| **ISO 27001** | A.8.3.2 | Disposal of media |
| **PCI DSS** | 3.1 | Data retention and disposal policies |

---

### 6.3 Rotate Deploy Hooks

**Profile Level:** L1 (Baseline)

**NIST 800-53:** IA-5, SA-15

#### Description

Deploy Hook URLs accept unauthenticated POST requests — the URL **is** the credential. Any actor with the URL can trigger a deployment of the configured branch. Rotate quarterly, on team membership changes, and whenever a hook URL may have been exposed.

#### Rationale

**Why This Matters:**

- Per [Vercel Deploy Hooks docs](https://vercel.com/docs/deploy-hooks): "treat with the same security as any other token or password"
- Deploy hooks committed to a public repo, CI config file, or Slack channel give anyone who reads them the ability to trigger deployments
- Combined with a Vercel GitHub App that has org-wide repo access, a leaked deploy hook becomes a lateral-movement vector: attacker triggers build → build imports from its configured branch → attacker-controlled branch if the app scope was not restricted

**Attack Prevented:** Unauthorized deployment triggering, pipeline poisoning via leaked hook URLs, lateral movement through broad GitHub App scope.

#### Prerequisites

- Vercel API token with project-scope write
- Secrets manager (1Password, HashiCorp Vault, AWS Secrets Manager, Doppler) to store rotated URLs
- Inventory of deploy hooks and their consumers (CI systems, webhook sources)

#### ClickOps Implementation

**Step 1: Inventory**

1. Navigate to: each **Project → Settings → Git → Deploy Hooks**
2. Record every hook ID, name, and ref (branch)
3. Identify the consumer (CI job, partner webhook, internal service) for each hook

**Step 2: Rotate**

1. For each hook: create a **new** hook with the same name + ref, capture the new URL, store in secrets manager
2. Update every consumer to use the new URL
3. Verify consumers are succeeding against the new hook
4. Delete the **old** hook

**Step 3: Harden Vercel GitHub App Scope**

1. Navigate to: **github.com/organizations/<org>/settings/installations**
2. Locate the Vercel GitHub App installation
3. Change repository access from **All repositories** to **Only select repositories** — restrict to the specific repositories that actually deploy to Vercel
4. This limits the blast radius if a deploy hook URL is abused

**Step 4: Scan for Leaked URLs**

1. Search git history, CI configuration files, and documentation for the pattern `api.vercel.com/v1/.+/deploy-hooks/`
2. If any matches are found in files tracked in git, rotate those hooks and remove the URL from git history (`git-filter-repo` or BFG Repo-Cleaner)

**Time to Complete:** ~30 minutes per project

{% include pack-code.html vendor="vercel" section="6.3" %}

#### Validation & Testing

1. Every deploy hook URL is stored only in a secrets manager — not in git-tracked files
2. All deploy hook consumers succeed with rotated URLs
3. Vercel GitHub App is restricted to specific repositories, not org-wide
4. `git log -p -S 'deploy-hooks/' | head` returns only historical, rotated URLs

**Expected result:** Deploy hook URLs behave like credentials — stored in a vault, rotated on schedule, never committed to git.

#### Monitoring & Maintenance

- **Quarterly:** Rotate every active deploy hook
- **On event:** Rotate immediately when any team member with hook URL access leaves
- **On event:** Rotate after any incident that might have exposed CI logs or config files

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC6.7 | Logical access, credential management |
| **NIST 800-53** | IA-5, SA-15 | Authenticator management, development process |
| **ISO 27001** | A.9.2.4, A.9.4.3 | Management of secret authentication information; password management |
| **PCI DSS** | 8.2.4 | Change authentication credentials at least every 90 days |

---

### 6.4 Block NEXT_PUBLIC_ Secret Leaks in CI

**Profile Level:** L1 (Baseline)

**NIST 800-53:** SC-28, SA-11, SA-15

#### Description

Add a CI/pre-commit check that fails the build if any environment variable prefixed `NEXT_PUBLIC_` also carries a secret-shaped name. Because Next.js inlines `NEXT_PUBLIC_*` values into the client JavaScript bundle, any secret accidentally prefixed this way ships to every browser and is indexable by search engines.

#### Rationale

**Why This Matters:**

- [Cremit research (2025)](https://www.cremit.io/blog/vercel-secret-exposure-case-study) identified **live API keys in 0.45% of public Vercel deployments** via exactly this vector
- The mistake is an easy off-by-one from a correct configuration; pre-deploy lint catches it before it ships
- Vercel's own environment variable UI cannot detect this — the `NEXT_PUBLIC_` semantics live in Next.js, not Vercel's validation layer

**Attack Prevented:** Client-side secret exposure, automated secret-scanner-driven credential theft, search-engine-indexed API keys.

#### Prerequisites

- CI system (GitHub Actions, CircleCI, GitLab CI) or pre-commit hook framework
- `grep` or `rg` available in the CI environment (default on all Vercel build containers)

#### ClickOps Implementation

**Step 1: Add the Lint Script to CI**

1. Save the pack script (`hth-vercel-6.04-block-next-public-secret-leaks.sh`) into your repo at `scripts/ci/check-next-public-secrets.sh`
2. Add a required CI step that runs the script **before** `vercel build`
3. Fail the build if the script exits non-zero

**Step 2: Add a Pre-Commit Hook (Developer-side)**

1. Install a pre-commit framework (e.g., `pre-commit.com`)
2. Register the script to run on every commit touching `.env*`, `next.config.*`, or `vercel.json`
3. Developers get immediate local feedback before pushing

**Step 3: Review Compiled Bundle**

1. After every production build, run the script's bundle-scan mode against the `.next/` output
2. Any `NEXT_PUBLIC_*` name matching a secret pattern surfaces in the build log

**Step 4: Quarterly Spot-Check**

1. Fetch the production site's main JavaScript bundle with `curl`
2. `grep -o 'NEXT_PUBLIC_[A-Z0-9_]*'` on the bundle
3. Confirm no secret-shaped names are present

**Time to Complete:** ~15 minutes

{% include pack-code.html vendor="vercel" section="6.4" %}

#### Validation & Testing

1. The lint script exits non-zero when a test commit introduces `NEXT_PUBLIC_SECRET_KEY=foo`
2. CI blocks merges that trigger the failure
3. A fetch of the production bundle shows no secret-named `NEXT_PUBLIC_*` identifiers
4. Pre-commit hook fires on local commits modifying env-var-carrying files

**Expected result:** Secret-shaped `NEXT_PUBLIC_*` variables are structurally blocked from entering the codebase or a production bundle.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC8.1 | Logical access, change management controls |
| **NIST 800-53** | SA-11, SA-15, SC-28 | Developer security testing, development process, information at rest |
| **ISO 27001** | A.14.2.1, A.14.2.5 | Secure development policy, secure system engineering principles |
| **PCI DSS** | 6.3, 6.5 | Secure development, training developers on secure coding |

---

## 7. Domain & Certificate Security

### 7.1 Prevent Subdomain Takeover

**Profile Level:** L1 (Baseline)

**NIST 800-53:** CM-8, SC-20

#### Description

Audit DNS records to prevent subdomain takeover vulnerabilities when CNAME records point to Vercel without active deployments.

#### Rationale

**Why This Matters:**
- Dangling DNS records pointing to Vercel can be claimed by attackers
- Subdomain takeover enables phishing, cookie theft, and CSP bypass
- Security researchers actively scan for Vercel subdomain takeover opportunities

**Attack Prevented:** Subdomain takeover, phishing via legitimate domain, cookie scope exploitation

**Real-World Incidents:**
- Multiple Vercel subdomain takeover reports on HackerOne and Medium demonstrating exploitation of dangling CNAME records

#### ClickOps Implementation

**Step 1: Audit DNS Records**
1. Navigate to: **Team Settings → Domains**
2. Review all configured domains
3. Identify any domains not actively assigned to projects

**Step 2: Clean Up Dangling Records**
1. Remove DNS CNAME records for decommissioned Vercel projects
2. Remove Vercel domain assignments when projects are deleted
3. Verify all domains resolve to active deployments

**Step 3: Monitor Domain Health**
1. Periodically scan for dangling DNS records using DNS auditing tools
2. Set up alerts for domain configuration changes via audit logs

**Time to Complete:** ~15 minutes

{% include pack-code.html vendor="vercel" section="7.1" %}

#### Validation & Testing

1. All DNS records pointing to Vercel have active deployments
2. No orphaned domain entries in Vercel dashboard
3. Domain configuration changes logged in audit log

**Expected result:** No dangling DNS records vulnerable to subdomain takeover

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | CM-8, SC-20 | Component inventory, secure name resolution |
| **ISO 27001** | A.13.1.1 | Network controls |
| **PCI DSS** | 2.4 | Maintain inventory of system components |

---

### 7.2 Harden TLS and Certificate Configuration

**Profile Level:** L1 (Baseline)

**NIST 800-53:** SC-8, SC-13

#### Description

Verify TLS configuration and optionally deploy custom certificates for domains requiring specific certificate authorities.

#### Rationale

**Why This Matters:**
- Vercel automatically provides TLS 1.2/1.3 with strong ciphers and forward secrecy
- HSTS is automatic for all domains but custom domains lack `includeSubDomains` and `preload`
- Post-quantum key exchange (X25519MLKEM768) available for supporting browsers
- Custom certificates needed for CAA/CT policy compliance in some organizations

**Attack Prevented:** Man-in-the-middle attacks, protocol downgrade attacks, certificate impersonation

#### ClickOps Implementation

**Step 1: Verify TLS Configuration**
1. Confirm HTTPS enforced (automatic -- HTTP 308 redirects to HTTPS)
2. Verify TLS 1.2+ in use via SSL Labs test
3. Confirm forward secrecy enabled on all ciphers

**Step 2: Enhance HSTS for Custom Domains (L2)**
1. Add custom header: `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`
2. Submit custom domain to HSTS Preload list at hstspreload.org

**Step 3: Deploy Custom Certificates (L3)**
1. Use `vercel certs issue [domain]` for custom certificate management
2. Upload organization-specific certificates if required by policy

**Time to Complete:** ~10 minutes

{% include pack-code.html vendor="vercel" section="7.2" %}

#### Validation & Testing

1. SSL Labs grade A+ with HSTS preloading
2. No TLS 1.0/1.1 negotiation possible
3. All ciphers support forward secrecy
4. HSTS preload header present on custom domains (L2)

**Expected result:** Strong TLS configuration with HSTS across all domains

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.7 | Encryption of data in transit |
| **NIST 800-53** | SC-8, SC-13 | Transmission confidentiality, cryptographic protection |
| **ISO 27001** | A.10.1.1 | Policy on use of cryptographic controls |
| **PCI DSS** | 4.1 | Strong cryptography for transmission of cardholder data |

---

## 8. Monitoring & Detection

### 8.1 Configure Drains for SIEM

**Profile Level:** L1 (Baseline)

**NIST 800-53:** AU-2, AU-6

#### Description

Forward Vercel runtime, build, and firewall logs to your SIEM via **Drains** (formerly "Log Drains") for security monitoring and incident response. Vercel's Drains pipeline supports four data types with distinct schemas — configure one drain per data type.

#### Rationale

**Why This Matters:**

- Vercel only retains runtime logs short-term — Drains are required for long-term retention and regulatory compliance
- Firewall logs capture blocked/challenged requests, persistent actions, and JA3/JA4 fingerprints for threat intelligence
- Drain payloads are signed with HMAC-SHA1 via the `x-vercel-signature` header; Section 8.4 covers constant-time verification
- SIEM integration enables correlation with other security data sources

**Attack Prevented:** Undetected attacks, delayed incident response, evidence loss, compliance gaps in log retention.

#### Drains Schema Catalog (Primary Source)

Per [Vercel Drains docs](https://vercel.com/docs/drains), each drain handles one data type and schema version:

| Schema name | Version | Data type |
|-------------|---------|-----------|
| `log` | `v1` | Runtime, build, and static logs |
| `trace` | `v1` | Distributed tracing (OpenTelemetry) |
| `analytics` | `v2` | Web Analytics page views and custom events |
| `speed_insights` | `v1` | Performance metrics and web vitals |

Specify the desired schema via the REST API `schemas` property when creating or validating a drain.

#### Prerequisites

- Vercel Pro or Enterprise plan (Hobby not supported; $0.50 per drain volume unit)
- SIEM endpoint accepting HTTPS POST with JSON payloads
- Secrets manager to store the per-drain rotatable HMAC secret

#### ClickOps Implementation

**Step 1: Create a Log Drain**

1. Navigate to: **Team Settings → Drains → Create Drain**
2. Schema: **`log` v1**
3. Destination: custom HTTPS endpoint (or native integration for Dash0 / Braintrust)
4. Environments: **Production** and **Preview**
5. Sources: **static, edge, external, build, lambda, firewall**
6. Generate and record a strong shared secret; store in your secrets manager

**Step 2: Create a Separate Firewall Log Drain (L2)**

1. Because firewall logs are high-signal security events, route them to a dedicated destination (or a security-specific index in your SIEM)
2. Create a second drain with schema `log` v1, sources = `[firewall]`

**Step 3: Configure Trace Drain (L2)**

1. Create a third drain with schema `trace` v1 for distributed tracing (OpenTelemetry format)
2. Useful for latency investigations and correlating security events with application spans

**Step 4: Enable IP Address Visibility Control (GDPR Hardening)**

1. Navigate to: **Team Settings → Security & Privacy → IP Address Visibility**
2. Toggle **Hide IP addresses in Drains** to **Enabled** if IP addresses are classified as personal data under your applicable privacy regime (EU GDPR, UK GDPR)
3. This strips public IPs from drain payloads before delivery

**Step 5: Configure Sampling (Optional)**

1. For high-volume projects, set per-drain sampling
2. Use 1.0 (100%) for security-critical projects (firewall, audit)
3. Lower rates acceptable for development/preview

**Time to Complete:** ~20 minutes

{% include pack-code.html vendor="vercel" section="8.1" %}

#### Validation & Testing

1. Log drain receiving events in SIEM
2. Payload signature verification working
3. Firewall logs appearing for blocked requests
4. All configured environments and sources flowing

**Expected result:** All Vercel logs forwarded to SIEM with cryptographic verification

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2, CC7.3 | System monitoring, anomaly detection |
| **NIST 800-53** | AU-2, AU-6 | Audit events, audit review and analysis |
| **ISO 27001** | A.12.4.1 | Event logging |
| **PCI DSS** | 10.2 | Implement automated audit trails |

---

### 8.2 Enable Audit Logging with SIEM Streaming

**Profile Level:** L2 (Hardened)

**NIST 800-53:** AU-2, AU-3, AU-12

#### Description

Enable enterprise audit logging with real-time SIEM streaming to track all administrative actions, configuration changes, and security events.

#### Rationale

**Why This Matters:**
- Audit logs capture 90 days of immutable administrative activity
- Tracks: member changes, environment variable CRUD, deployment protection changes, domain changes, integration installs, and more
- SIEM streaming enables real-time alerting on security-relevant events
- CSV export available for compliance reporting

**Attack Prevented:** Undetected administrative compromise, unauthorized configuration changes, insider threat

#### Prerequisites

- Vercel Enterprise plan

#### ClickOps Implementation

**Step 1: Access Audit Log**
1. Navigate to: **Team Settings → Security → Audit Log**
2. Review available event types and current activity

**Step 2: Configure SIEM Streaming**
1. Navigate to: **Team Settings → Security & Privacy → Audit Log → Configure**
2. Select SIEM destination: AWS S3, Splunk, Datadog, Google Cloud Storage, or Generic HTTP
3. Configure authentication (API key, header-based, or AWS credentials)
4. Select format: JSON or NDJSON
5. Allowlist Vercel SIEM IPs if endpoint is firewalled

**Step 3: Build Detection Rules**
1. Create alerts for critical events: `team.member.role.updated`, `project.env_variable.created`, `password_protection.disabled`, `saml.updated`
2. Monitor for unusual patterns: bulk member additions, env var decryption events, integration installs

**Time to Complete:** ~30 minutes

{% include pack-code.html vendor="vercel" section="8.2" %}

#### Validation & Testing

1. Audit log shows recent administrative events
2. SIEM receiving streamed audit events in real-time
3. Detection rules firing on test events
4. CSV export produces valid compliance report

**Expected result:** All administrative actions logged, streamed, and alerted on

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | Monitor system components for anomalies |
| **NIST 800-53** | AU-2, AU-3, AU-12 | Audit events, content, generation |
| **ISO 27001** | A.12.4.1, A.12.4.3 | Event logging, administrator and operator logs |
| **PCI DSS** | 10.1, 10.5 | Audit trails, secure audit trails |

---

### 8.3 Cron Job Security

**Profile Level:** L1 (Baseline)

**NIST 800-53:** AC-3, SI-10

#### Description

Secure cron job endpoints with the CRON_SECRET mechanism to prevent unauthorized invocation.

#### Rationale

**Why This Matters:**
- Cron endpoints are publicly accessible URLs without protection
- Without CRON_SECRET verification, anyone can trigger cron jobs
- Compromised cron endpoints enable unauthorized data processing or exfiltration

**Attack Prevented:** Unauthorized cron invocation, data exfiltration via scheduled jobs, resource abuse

#### ClickOps Implementation

**Step 1: Generate Strong CRON_SECRET**
1. Generate: `openssl rand -hex 32` (minimum 16 characters)
2. Add as production environment variable: `CRON_SECRET`

**Step 2: Verify in Application Code**
1. Check `Authorization: Bearer <CRON_SECRET>` header in every cron handler
2. Return 401 for missing or mismatched secrets
3. Vercel automatically sends the bearer token when invoking cron endpoints

**Time to Complete:** ~10 minutes

{% include pack-code.html vendor="vercel" section="8.3" %}

#### Validation & Testing

1. CRON_SECRET set as production environment variable
2. Direct HTTP request without bearer token returns 401
3. Vercel-triggered cron execution succeeds with correct token

**Expected result:** Cron endpoints only accessible via authenticated Vercel invocation

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | AC-3, SI-10 | Access enforcement, information input validation |
| **ISO 27001** | A.9.4.1 | Information access restriction |
| **PCI DSS** | 8.1 | Unique identification for system components |

---

### 8.4 Verify Drain Delivery Signatures

**Profile Level:** L1 (Baseline)

**NIST 800-53:** SC-8, SC-13, AU-9

#### Description

Every drain payload Vercel delivers is signed with HMAC-SHA1 via the `x-vercel-signature` header. The receiver **must** validate this signature with a **constant-time comparison** before processing, and must reject unsigned or tampered payloads. This is the mechanism that distinguishes authentic Vercel traffic from forged SIEM ingestion.

#### Rationale

**Why This Matters:**

- An attacker who can reach your SIEM endpoint can inject fake logs — masking their own activity or triggering noisy alerts — unless every delivery is signed and verified
- Non-constant-time string comparison leaks signature bytes via timing side-channel, enabling forgery over time
- The HMAC secret is per-drain and rotatable from the Drains UI — treat like any other credential

**Attack Prevented:** Log injection, forged audit evidence, timing-attack-driven signature recovery.

#### Prerequisites

- A receiver endpoint you control (cannot validate signatures on a managed SIEM's raw ingest URL — typically stand up a small receiver that validates then forwards)
- Node.js 16+, Python 3.8+, Go 1.18+, or any language with constant-time comparison built-in
- Access to the per-drain HMAC secret from the Drains dashboard

#### ClickOps Implementation

**Step 1: Generate and Store the Drain Secret**

1. Navigate to: **Team Settings → Drains → <your drain> → Settings**
2. Generate a new secret; record it in your secrets manager
3. The receiver will load this secret from an environment variable, never from disk or source

**Step 2: Deploy a Signature-Validating Receiver**

1. Use the reference receiver from the pack below (Node.js) or an equivalent in your stack
2. Receiver reads raw body, computes `hmac_sha1(SECRET, body)`, compares constant-time to `x-vercel-signature`
3. Reject non-matching deliveries with HTTP 401

**Step 3: Validate Delivery Configuration**

1. Call `POST https://api.vercel.com/v1/drains/validate` with the intended schema + delivery URL
2. Confirm Vercel can reach the receiver and the receiver accepts the signature

**Step 4: Configure IP Address Visibility (GDPR)**

1. Navigate to: **Team Settings → Security & Privacy → IP Address Visibility**
2. Confirm the `hideIpAddresses` and `hideIpAddressesInLogDrains` settings match your privacy posture

**Step 5: Rotate Secret Quarterly**

1. From the Drains dashboard, rotate the drain secret
2. Update the receiver's environment variable
3. Allow a short overlap window so in-flight deliveries aren't lost

**Time to Complete:** ~30 minutes (initial deployment)

{% include pack-code.html vendor="vercel" section="8.4" %}

#### Validation & Testing

1. Receiver returns 401 for requests with missing or invalid `x-vercel-signature`
2. Receiver returns 200 for authentic Vercel deliveries
3. A deliberately-modified payload is rejected even if `x-vercel-signature` is present
4. Constant-time comparison is used (Node `crypto.timingSafeEqual`, Python `hmac.compare_digest`, etc.)
5. Secret rotation rehearsal completes within the allowed overlap window

**Expected result:** Only authentic, untampered Vercel drain deliveries reach the SIEM.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2, CC6.1 | System monitoring, logical access |
| **NIST 800-53** | SC-8, SC-13, AU-9 | Transmission confidentiality/integrity, cryptographic protection, protection of audit information |
| **ISO 27001** | A.12.4.2, A.10.1.2 | Protection of log information, key management |
| **PCI DSS** | 10.5, 10.5.5 | Secure audit trails, use file-integrity monitoring on logs |

---

## 9. Framework CVE Management (Next.js)

Vercel-hosted apps overwhelmingly run **Next.js**, a framework Vercel also maintains. Framework vulnerabilities are Vercel-relevant security events because (a) Vercel frequently ships edge-side WAF mitigations before public disclosure, and (b) customers who self-host Next.js elsewhere don't get those automatic mitigations. This section defines an L1 baseline for staying ahead of Next.js CVEs, independent of the platform configurations in earlier sections.

### 9.1 Next.js Patch Management & Edge Header Strip

**Profile Level:** L1 (Baseline)

**NIST 800-53:** SI-2, RA-5, SI-10

#### Description

Maintain a defensive posture against Next.js framework CVEs: pin to a patched version, subscribe to advisories, add edge-side WAF rules that strip internal headers exploited by known attacks, and treat middleware as one authorization layer among several rather than the only one.

#### Rationale

**Why This Matters:**

- Multiple critical Next.js CVEs in the last 24 months have had **active in-the-wild exploitation** within hours of disclosure
- The most impactful class (middleware bypass, RSC deserialization) abuses internal HTTP headers that should never arrive from the public internet
- Self-hosted Next.js forks **do not** receive Vercel's automatic WAF mitigations — customers off-platform must implement the defenses themselves
- Vercel's $1M React2Shell bounty surfaced 20 unique WAF bypasses, confirming that edge protection alone is insufficient — framework patching is mandatory

**Attack Prevented:** Authorization bypass via middleware, RCE via RSC deserialization, SSRF via Server Actions or `/_next/image`, cache poisoning, source code exposure.

**Known Vulnerabilities (verify your pinned version is at or above the fix):**

| CVE | Class | Fix Versions | ITW? | Reference |
|-----|-------|--------------|------|-----------|
| CVE-2025-29927 | Middleware auth bypass | 12.3.5, 13.5.9, 14.2.25, 15.2.3 | Yes (mass scanning <48h) | [NVD](https://nvd.nist.gov/vuln/detail/CVE-2025-29927) |
| CVE-2025-55182 / 66478 ("React2Shell") | RSC RCE (CVSS 10.0) | 15.5.7, 16.0.7 | Yes (Trend Micro) | [Next.js advisory](https://nextjs.org/blog/CVE-2025-66478) |
| CVE-2025-55183 | RSC source exposure | Same as React2Shell | - | [Vercel bulletin](https://vercel.com/kb/bulletin/security-bulletin-cve-2025-55184-and-cve-2025-55183) |
| CVE-2025-55184 | RSC DoS | Same as React2Shell | - | [Vercel bulletin](https://vercel.com/kb/bulletin/security-bulletin-cve-2025-55184-and-cve-2025-55183) |
| CVE-2026-23869 | App Router RSC DoS | 15.5.15, 16.2.3 | - | [Vercel changelog](https://vercel.com/changelog/summary-of-cve-2026-23869) |
| CVE-2025-49826 | 204 cache poisoning DoS | 15.1.8 | - | [GHSA](https://github.com/advisories/GHSA-67rr-84xm-4c7r) |
| CVE-2024-46982 | Pages Router cache poisoning | 13.5.7, 14.2.10 | - | [GHSA](https://github.com/vercel/next.js/security/advisories/GHSA-gp8f-8m3g-qvj9) |
| CVE-2024-34351 | Server Actions SSRF | 14.1.1 | - | [Assetnote](https://www.assetnote.io/resources/research/advisory-next-js-ssrf-cve-2024-34351) |

#### Prerequisites

- Next.js application on Vercel (or self-hosted, in which case **all** controls below are customer-implemented)
- Renovate, Dependabot, or equivalent automated-PR dependency manager
- CI that can run `npm audit` / `pnpm audit` on every build
- WAF Custom Rules available on the plan (Pro+)

#### ClickOps Implementation

**Step 1: Pin Next.js to a Known-Patched Version**

1. Edit `package.json` to pin `next` to an exact version that is at or above the highest fix in the CVE table above (at minimum 15.5.15 or 16.2.3 as of 2026-04)
2. Commit the lockfile; configure Renovate/Dependabot to propose upgrades as they are released

**Step 2: Subscribe to Advisories**

1. Subscribe the security team to `nextjs.org/blog` (security-tagged posts)
2. Watch `github.com/vercel/next.js` **Security Advisories** tab
3. Watch `vercel.com/changelog` (security tag)

**Step 3: Deploy Edge Header-Strip Rules (Defense in Depth)**

1. Use the Section 3.1 firewall workflow to add a **Deny** Custom Rule matching requests containing `x-middleware-subrequest` (CVE-2025-29927 defense in depth, even if you're patched)
2. Add a **Log** Custom Rule for requests containing `x-nextjs-data` or `Next-Action` — these are exploit precursors that should not arrive from the public internet in normal operation
3. Pair with Persistent Actions (Section 3.3) so a single probe triggers a time-boxed block

**Step 4: Measure Mean-Time-to-Patch**

1. Track the number of days between any Next.js security advisory and that version being deployed to production
2. Build time is part of MTTP — per Eduardo Bouças's analysis, teams with >10-minute builds stayed vulnerable to CVE-2025-29927 longer; optimize build pipelines as a security investment
3. Target MTTP ≤ 72 hours for critical (CVSS ≥ 9.0)

**Step 5: Defense-in-Depth on Middleware**

1. Never rely on middleware as the sole authorization boundary — see Section 10.2 for the enforcement pattern in Route Handlers, Server Components, and Server Actions

**Time to Complete:** ~30 minutes (initial) + ongoing

{% include pack-code.html vendor="vercel" section="9.1" %}

#### Validation & Testing

1. `package.json` pins `next` to a version at or above every fix in the CVE table
2. A request with `x-middleware-subrequest` header from the public internet is denied at the Vercel Firewall
3. Requests with `x-nextjs-data` or `Next-Action` are logged and surface in Firewall observability
4. Renovate/Dependabot has proposed the latest Next.js patch; its PR is merged within MTTP target
5. A Next.js security advisory triggered Slack/PagerDuty within an hour of publication

**Expected result:** The team is positioned to patch Next.js CVEs within 72 hours, with edge-side defense in depth protecting against the highest-impact classes.

#### Monitoring & Maintenance

- **On advisory:** Review every advisory on `nextjs.org/blog`; patch critical CVEs within 72 hours
- **Weekly:** Review Firewall logs for `x-middleware-subrequest` / `x-nextjs-data` / `Next-Action` probes
- **Monthly:** Measure MTTP metric; if trending up, invest in faster builds
- **Quarterly:** Review the CVE table against NVD for new entries

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.1, CC7.2 | System change management, detection of security events |
| **NIST 800-53** | SI-2, SI-10, RA-5, SA-11 | Flaw remediation, input validation, vulnerability scanning, developer security testing |
| **ISO 27001** | A.12.6.1, A.14.2.3 | Management of technical vulnerabilities, technical review of applications |
| **PCI DSS** | 6.2, 6.3.3 | Maintain current security patches, bespoke software vulnerability management |

---

## 10. Customer Misconfiguration Anti-Patterns

These are **customer-side misconfigurations**, not Vercel platform vulnerabilities. They are well-documented causes of real-world incidents affecting Vercel customers. Each anti-pattern maps to a detection or enforcement control you can add to CI.

### 10.1 Enforce `/_next/image` remotePatterns Allowlist

**Profile Level:** L1 (Baseline)

**NIST 800-53:** SC-7, SI-10, CM-7

#### Description

Next.js's `/_next/image` endpoint performs server-side `fetch()` against URLs matching `images.remotePatterns` in `next.config.*`. Wildcard or protocol-only patterns enable SSRF — the server can be coerced into fetching internal metadata services, RFC1918 endpoints, or attacker-hosted malicious content.

#### Rationale

**Why This Matters:**

- SSRF via `/_next/image` was disclosed as CVE-2025-57822 and CVE-2025-6087 — Dominik Prodinger identified **5,000+ potentially affected hosts** on the public internet for CVE-2025-57822
- The vulnerability is a **configuration** issue (permissive `remotePatterns`), not a framework bug — patching Next.js alone does not fix it
- `images.domains` (deprecated) is wildcard-prone by default; migrating to `remotePatterns` with explicit `pathname` restrictions is the safe pattern

**Attack Prevented:** Full-read or blind SSRF against internal networks, cloud metadata exfiltration (AWS IMDSv1 `169.254.169.254`), image-optimizer cache poisoning.

#### ClickOps Implementation

**Step 1: Audit `next.config.*`**

1. Open `next.config.js` / `next.config.mjs` / `next.config.ts`
2. Locate `images.remotePatterns`
3. Remove any entries with `hostname: '**'`, `hostname: '*'`, `protocol: '*'`, or `protocol: 'http'`
4. Add explicit `pathname` restrictions (`'/images/**'`, not `'/**'`)
5. Delete any `images.domains` entries (deprecated); migrate to `remotePatterns`

**Step 2: Add the Section-10.1 Lint to CI**

1. Save the pack script (`hth-vercel-10.01-next-image-remotepatterns-audit.sh`) into `scripts/ci/`
2. Add as a required CI step; fail the build on any detected permissive pattern

**Step 3: Add an Edge WAF Rule (Defense in Depth)**

1. Create a WAF Custom Rule (Section 3.1 workflow) that denies requests to `/_next/image` whose decoded `url=` query parameter resolves to RFC1918, link-local, or loopback ranges
2. Confirm the rule is in **Log** mode for 48 hours before switching to **Deny** to avoid blocking legitimate CDN fetches

**Time to Complete:** ~20 minutes

{% include pack-code.html vendor="vercel" section="10.1" %}

#### Validation & Testing

1. Lint script exits non-zero against a synthetic permissive config (`hostname: '**'`)
2. Production `next.config.*` has no wildcard hostnames or protocols
3. WAF rule blocks a test request: `/_next/image?url=http://169.254.169.254/` (from the public internet)
4. Legitimate image fetches from allowlisted CDNs continue to work

**Expected result:** `/_next/image` only fetches from explicit `(protocol, hostname, pathname)` tuples; SSRF against internal endpoints is blocked at two layers.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6, CC7.1 | External threat protection, change management |
| **NIST 800-53** | SC-7, SI-10, CM-7 | Boundary protection, input validation, least functionality |
| **ISO 27001** | A.14.2.1, A.13.1.1 | Secure development policy, network controls |
| **PCI DSS** | 6.3, 1.3 | Secure development, prohibit direct public access |

---

### 10.2 Enforce Authorization Defense in Depth (No Middleware-Only Authz)

**Profile Level:** L1 (Baseline)

**NIST 800-53:** AC-3, SI-10

#### Description

CVE-2025-29927 proved that Next.js middleware **can be bypassed** from the public internet via a spoofed internal header. Any authorization logic that lives only in middleware is therefore bypassable, even after patching. Enforce authorization a second time inside **Route Handlers**, **Server Components**, and **Server Actions** for every protected endpoint.

#### Rationale

**Why This Matters:**

- Every credible external researcher (zhero_web_security, Assetnote, Datadog Security Labs, Praetorian) converges on this conclusion: middleware is not a security boundary
- Defense in depth means a single-layer bypass does not compromise the application
- The pattern is cheap to apply (a few lines per handler) and immune to the next framework-level bypass CVE

**Attack Prevented:** Authorization bypass via middleware-only enforcement, including both CVE-2025-29927-style header smuggling and any future analogous middleware-skip vulnerability.

#### ClickOps Implementation

**Step 1: Inventory Middleware-Gated Paths**

1. Locate `middleware.ts` (or `middleware.js`)
2. Extract every path matched by `config.matcher`
3. For each path, locate the Route Handler, Server Component, or Server Action implementation

**Step 2: Add In-Handler Authorization**

1. For every Route Handler (`app/**/route.ts`), add an explicit `await getSession()` / `await getUser()` check at the top of the handler
2. For every Server Component that renders protected data, repeat the session check inside the component
3. For every Server Action (`"use server"` file), repeat the session check inside the action function — the `Next-Action` header alone is not sufficient authorization

**Step 3: Add the Section-10.2 Lint to CI**

1. Save the pack script (`hth-vercel-10.02-middleware-authz-defense-in-depth.sh`) into `scripts/ci/`
2. CI runs the script on every PR; script flags Route Handlers / Server Actions that lack an apparent in-handler authorization check
3. Treat warnings as blocking for paths covered by `middleware.ts` matcher

**Step 4: Document the Pattern in Code-Review Checklist**

1. Add a line item to your PR review template: "Does every protected endpoint authorize inside the handler, not only in middleware?"
2. Include in engineering onboarding materials

**Time to Complete:** ~1 hour per protected path cluster (initial) + ongoing

{% include pack-code.html vendor="vercel" section="10.2" %}

#### Validation & Testing

1. A simulated `x-middleware-subrequest` probe against a protected Route Handler is rejected by the handler even when middleware is skipped (reproduce in a local test by mocking middleware-skip)
2. Lint script reports zero in-handler warnings for protected paths
3. Code-review checklist is enforced

**Expected result:** Authorization is enforced at every protected boundary. A middleware bypass does not become an application-authorization bypass.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC6.3 | Logical access controls, multi-layer controls |
| **NIST 800-53** | AC-3, SI-10, SC-3 | Access enforcement, input validation, security function isolation |
| **ISO 27001** | A.9.4.1, A.14.2.5 | Information access restriction, secure engineering principles |
| **PCI DSS** | 7.2, 6.5 | Restrict access by job function, secure coding practices |

---

### 10.3 Do Not Stack a Reverse Proxy in Front of Vercel Bot Protection

**Profile Level:** L1 (Baseline)

**NIST 800-53:** SC-7, SI-4

#### Description

Placing a reverse proxy (Cloudflare, Azure Front Door, AWS CloudFront) in front of Vercel breaks Bot Protection. Vercel's Bot Protection Managed Ruleset relies on JA3/JA4 TLS fingerprints and client IP stability — both of which are masked or rotated by upstream proxies. Either use Vercel Firewall directly, or disable Vercel Bot Protection and rely exclusively on the front proxy's WAF — but do **not** run both expecting additive protection.

#### Rationale

**Why This Matters:**

- Per [Vercel Bot Management docs](https://vercel.com/docs/bot-management): "Reverse proxies interfere with Vercel's ability to reliably identify bots... obscured detection signals... frequent re-challenges"
- Teams that layer Cloudflare in front of Vercel frequently experience mysterious legitimate-user blocks and still-present bot traffic — the stack is worse than either tier alone
- The Reverse Proxy detection and challenges-per-IP-change behavior can be tuned in the front WAF instead, providing a single coherent policy

**Attack Prevented:** False negatives in bot classification, false positives blocking legitimate users, operational complexity that masks real security events.

#### ClickOps Implementation

**Step 1: Detect Current Topology**

1. `dig <your-domain>` — if the CNAME resolves to Cloudflare / CloudFront / Azure Front Door before Vercel's edge, you are proxied
2. Confirm via `curl -I https://<your-domain>/` — check for upstream-proxy-specific headers (`cf-ray`, `x-amz-cf-id`, etc.)

**Step 2: Make the Architectural Decision**

- **Option A: Use Vercel Firewall directly.** Remove the upstream proxy; point DNS directly to Vercel. Benefit: JA3/JA4-based Bot Protection works correctly. Downside: dedicated perimeter WAF (Cloudflare, Akamai) is no longer in the path.
- **Option B: Use the upstream proxy's WAF exclusively.** Keep the upstream proxy; disable Vercel's Bot Protection Managed Ruleset; move bot and managed-rule policy to the upstream. Benefit: single coherent WAF policy. Downside: Vercel's $1M-bounty-hardened bot rules are no longer engaged.

**Step 3: Document the Choice**

1. Record the decision and the rationale in the team's architecture documentation
2. Ensure on-call runbooks reflect the chosen topology (e.g., "for bot-related incidents, investigate in \[Cloudflare | Vercel\] first")

**Step 4: Monitor After the Change**

1. Track Bot Protection false-positive rate for 14 days after any topology change
2. Tune challenge actions using the WAF in use — not the other one

**Time to Complete:** ~30 minutes (decision) + application-specific migration time

#### Validation & Testing

1. Either Vercel Bot Protection is enabled AND DNS points directly to Vercel (no upstream proxy), OR Vercel Bot Protection is disabled AND the upstream WAF handles bot classification
2. False-positive rate measured and acceptable for 14 days post-change

**Expected result:** Bot classification is reliable and operational responsibility is unambiguous.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | External threat protection |
| **NIST 800-53** | SC-7, SI-4 | Boundary protection, system monitoring |
| **ISO 27001** | A.13.1.1, A.13.1.2 | Network controls, security of network services |
| **PCI DSS** | 11.4, 1.3 | Intrusion detection/prevention, network segmentation |

---

## Appendix A: Edition Compatibility

| Control | Section | Hobby | Pro | Enterprise |
|---------|---------|-------|-----|------------|
| SAML SSO | 1.1 | ❌ | Add-on | ✅ |
| Directory Sync (SCIM) | 1.2 | ❌ | ❌ | ✅ |
| RBAC (full roles) | 1.3 | Basic | Extended | Full |
| Access Groups | 1.3 | ❌ | Limited | ✅ |
| Security Role | 1.3 | ❌ | ❌ | ✅ |
| OIDC Federation | 1.4 | ✅ | ✅ | ✅ |
| Deployment Protection (Standard) | 2.1 | ✅ | ✅ | ✅ |
| Password Protection | 2.1 | ❌ | Add-on ($150/mo) | ✅ |
| Trusted IPs | 2.1 | ❌ | ❌ | ✅ |
| Git Fork Protection | 2.2 | ✅ | ✅ | ✅ |
| Rolling Releases | 2.3 | ❌ | ✅ | ✅ |
| WAF Custom Rules | 3.1 | 3 rules | 40 rules | 1,000 rules |
| WAF Managed Rulesets | 3.1 | ❌ | ❌ | ✅ |
| IP Blocking (project) | 3.2 | 10 IPs | 100 IPs | Custom |
| IP Blocking (account) | 3.2 | ❌ | ❌ | ✅ |
| Rate Limiting | 3.2 | ❌ | ✅ | ✅ |
| Secure Compute | 4.1 | ❌ | ❌ | ✅ ($6.5K/yr) |
| VPC Peering | 4.1 | ❌ | ❌ | ✅ |
| DDoS Mitigation | 4.2 | ✅ | ✅ | ✅ + dedicated |
| Attack Challenge Mode | 4.2 | ✅ | ✅ | ✅ |
| Spend Management | 4.2 | ❌ | ✅ | ✅ |
| Custom Security Headers | 5.1 | ✅ | ✅ | ✅ |
| Sensitive Env Var Policy | 6.1 | ❌ | ✅ | ✅ |
| Deployment Retention | 6.2 | ✅ | ✅ | ✅ |
| Third-Party Integration Audit | 1.5 | ✅ | ✅ | ✅ |
| Private Production Deployments | 2.4 | ❌ | Add-on ($150/mo) | ✅ |
| Firewall Persistent Actions | 3.3 | ❌ | ✅ | ✅ |
| AI Bots Managed Ruleset | 3.4 | ❌ | ❌ | ✅ |
| Rotate Deploy Hooks | 6.3 | ✅ | ✅ | ✅ |
| Block NEXT_PUBLIC_ Secret Leaks (lint) | 6.4 | ✅ | ✅ | ✅ |
| Drain Signature Verification | 8.4 | ❌ | ✅ | ✅ |
| Next.js CVE Management | 9.1 | ✅ | ✅ | ✅ |
| `/_next/image` remotePatterns Audit | 10.1 | ✅ | ✅ | ✅ |
| Authorization Defense in Depth | 10.2 | ✅ | ✅ | ✅ |
| Reverse-Proxy + Vercel Bot Protection (do not stack) | 10.3 | ✅ | ✅ | ✅ |
| Drains | 8.1 | ❌ | ✅ | ✅ |
| Audit Logs | 8.2 | ❌ | ❌ | ✅ (90 days) |
| SIEM Streaming | 8.2 | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Vercel Documentation:**
- [Vercel Trust Center](https://security.vercel.com/)
- [Vercel Documentation](https://vercel.com/docs)
- [Security Overview](https://vercel.com/docs/security)
- [Shared Responsibility Model](https://vercel.com/docs/security/shared-responsibility)
- [Production Checklist](https://vercel.com/docs/production-checklist)
- [Deployment Protection](https://vercel.com/docs/security/deployment-protection)
- [Vercel Firewall / WAF](https://vercel.com/docs/security/vercel-waf)
- [DDoS Mitigation](https://vercel.com/docs/security/ddos-mitigation)
- [Secure Compute](https://vercel.com/docs/security/secure-compute)
- [Encryption](https://vercel.com/docs/encryption)
- [RBAC Access Roles](https://vercel.com/docs/rbac/access-roles)
- [SAML SSO](https://vercel.com/docs/saml)
- [Directory Sync](https://vercel.com/docs/security/directory-sync)
- [OIDC Federation](https://vercel.com/docs/oidc)
- [Audit Logs](https://vercel.com/docs/audit-log)
- [Log Drains](https://vercel.com/docs/observability/log-drains)
- [Environment Variables](https://vercel.com/docs/projects/environment-variables)
- [Security & Compliance](https://vercel.com/docs/security/compliance)
- [Security Bulletins](https://vercel.com/kb/bulletin)

**CLI & API Documentation:**
- [Vercel CLI Reference](https://vercel.com/docs/cli)
- [REST API Reference](https://vercel.com/docs/rest-api)
- [Vercel SDK (@vercel/sdk)](https://github.com/vercel/sdk)
- [Terraform Provider](https://registry.terraform.io/providers/vercel/vercel/latest/docs)

**Compliance Frameworks:**
- SOC 2 Type II (Security, Confidentiality, Availability)
- ISO 27001:2022
- PCI DSS v4.0 (SAQ-D AOC for Service Providers, SAQ-A AOC for Merchants)
- HIPAA BAA (Enterprise)
- EU-U.S. Data Privacy Framework
- TISAX Assessment Level 2

**Security Incidents (Platform):**

- **2026 — Vercel Platform Supply-Chain Incident (April 2026):** Lumma Stealer infection at Context.ai compromised Google Workspace OAuth tokens. Attacker hijacked a Vercel employee's Workspace account and enumerated customer **non-sensitive** environment variables. Sensitive-flagged variables were **not** affected. Customers with no direct relationship to Context.ai were impacted. See [Vercel KB Bulletin](https://vercel.com/kb/bulletin/vercel-april-2026-security-incident), [Trend Micro analysis](https://www.trendmicro.com/en_us/research/26/d/vercel-breach-oauth-supply-chain.html), [Appendix C](#appendix-c-april-2026-incident-response-playbook).

**Security Incidents (Framework — Next.js, maintained by Vercel):**

- **2026-04 — CVE-2026-23869 (DoS via unsafe RSC deserialization):** Affects Next.js 13.x–16.x App Router. Fix: 15.5.15 / 16.2.3. [Vercel changelog](https://vercel.com/changelog/summary-of-cve-2026-23869).
- **2025-12 — CVE-2025-55182 / 66478 ("React2Shell", CVSS 10.0):** Critical unsafe deserialization in React Server Components enabling unauthenticated RCE. Active in-the-wild exploitation observed by Trend Micro. Fix: Next.js 15.5.7 / 16.0.7. $1M Vercel bounty surfaced 20 WAF bypasses, confirming framework patching is mandatory. [Praetorian advisory](https://www.praetorian.com/blog/critical-advisory-remote-code-execution-in-next-js-cve-2025-66478-with-working-exploit/), [Next.js Advisory](https://nextjs.org/blog/CVE-2025-66478), [Vercel $1M bounty blog](https://vercel.com/blog/our-million-dollar-hacker-challenge-for-react2shell).
- **2025-12 — CVE-2025-55184 (RSC DoS):** Bundled with React2Shell. Fix: same.
- **2025-12 — CVE-2025-55183 (RSC source code disclosure):** Bundled with React2Shell. Fix: same.
- **2025-06 — CVE-2025-49826 (204 response cache poisoning DoS, CVSS 7.5):** Fix: Next.js 15.1.8. [GHSA-67rr-84xm-4c7r](https://github.com/advisories/GHSA-67rr-84xm-4c7r).
- **2025-03 — CVE-2025-29927 (Middleware authorization bypass, CVSS 9.1):** Spoofed `x-middleware-subrequest` bypasses all middleware-enforced checks. Mass scanning within 48 hours. Vercel WAF stripped the header at edge before disclosure. Discovered by [zhero_web_security](https://zhero-web-sec.github.io/research-and-things/nextjs-and-the-corrupt-middleware) + yvvdwf. Fix: 12.3.5 / 13.5.9 / 14.2.25 / 15.2.3.
- **2024-09 — CVE-2024-46982 (Pages Router cache poisoning, CVSS 7.5):** Fix: 13.5.7 / 14.2.10. [GHSA](https://github.com/vercel/next.js/security/advisories/GHSA-gp8f-8m3g-qvj9).
- **2024-04 — CVE-2024-34351 (Server Actions SSRF):** Host-header manipulation in self-hosted Next.js. Vercel-hosted not exploitable in standard configuration. [Assetnote research](https://www.assetnote.io/resources/research/advisory-next-js-ssrf-cve-2024-34351). Fix: Next.js 14.1.1.

**Security Researcher Primary Sources:**

- [zhero_web_security research index](https://zhero-web-sec.github.io/research-and-things/) — primary discoverer of CVE-2025-29927 and related middleware class-bugs
- [Assetnote Research](https://www.assetnote.io/resources/research) — Next.js SSRF, middleware-bypass due-diligence
- [Datadog Security Labs — Understanding CVE-2025-29927](https://securitylabs.datadoghq.com/articles/nextjs-middleware-auth-bypass/) — detection engineering perspective
- [Praetorian — CVE-2025-66478 RCE with working exploit](https://www.praetorian.com/blog/critical-advisory-remote-code-execution-in-next-js-cve-2025-66478-with-working-exploit/)
- [ProjectDiscovery — CVE-2025-29927 technical analysis](https://projectdiscovery.io/blog/nextjs-middleware-authorization-bypass)
- [Zscaler ThreatLabz — CVE-2025-29927](https://www.zscaler.com/blogs/security-research/cve-2025-29927-next-js-middleware-authorization-bypass-flaw)
- [JFrog — CVE-2025-29927 analysis](https://jfrog.com/blog/cve-2025-29927-next-js-authorization-bypass/)
- [Checkmarx Zero — CVE-2025-29927](https://checkmarx.com/zero-post/critical-cve-2025-29927-research-nextjs-middleware-authorization-bypass/)
- [Cremit — Vercel secret exposure case study](https://www.cremit.io/blog/vercel-secret-exposure-case-study) — 0.45% of public Vercel deployments leak API keys via `NEXT_PUBLIC_`
- [GitGuardian — Vercel April 2026 incident analysis](https://blog.gitguardian.com/vercel-april-2026-incident-non-sensitive-environment-variables-need-investigation-too/)
- [Trend Micro — Vercel OAuth supply chain breach](https://www.trendmicro.com/en_us/research/26/d/vercel-breach-oauth-supply-chain.html)

**Industry Commentary (Contrarian Voices):**

- [Shubham Sharma — Next.js Vendor Lock-In Architecture](https://medium.com/@ss-tech/the-next-js-vendor-lock-in-architecture-a0035e66dc18)
- [Eduardo Bouças — You should know this before choosing Next.js](https://eduardoboucas.com/posts/2025-03-25-you-should-know-this-before-choosing-nextjs/) — build time as security metric
- [WAFPlanet — Vercel Firewall independent review](https://wafplanet.com/waf/vercel-firewall/)

**Community Security Research:**

- [Vercel XSS in Clone URL (Medium)](https://medium.com/@n45ht/breaking-vercels-clone-url-with-a-simple-xss-exploit-8f55b21f32eb) — Reflected XSS in clone functionality
- [Vercel Subdomain Takeover (Medium)](https://medium.com/@pentestfox/how-i-took-over-a-vercel-subdomain-e7b03dbf222d) — Dangling CNAME exploitation
- [dSSRF: Deterministic SSRF Protection](https://community.vercel.com/t/introducing-dssrf-deterministic-ssrf-protection-for-vercel-serverless-edge-functions/29838) — Community SSRF protection library
- [Next.js Security Checklist (Arcjet)](https://blog.arcjet.com/next-js-security-checklist/) — Framework-level hardening guide
- [Nosecone Security Headers Library](https://nosecone.com) — Open source security headers for Next.js
- [OpenSourceMalware/vercel-april2026-incident-response](https://github.com/OpenSourceMalware/vercel-april2026-incident-response) — Community-maintained IR playbook

---

## Appendix C: April 2026 Incident Response Playbook

This playbook is applicable to any Vercel customer whose projects existed prior to April 19, 2026. It is derived from Vercel's KB bulletin and community-maintained IR materials. Execute in order; most items can be completed within a single working day.

### C.1 Immediate Triage (First 24 Hours)

1. **Enable team MFA enforcement for all members.** Require authenticator apps or passkeys; disable SMS as a second factor.
2. **Audit account activity logs.** Navigate to **Team Settings → Security → Account Activity** and review all logins, token creations, and deployment actions for the 60 days prior to 2026-04-19. Flag anything unexpected.
3. **Enumerate all environment variables** via the Vercel dashboard or API: `GET /v10/projects/{id}/env`. List each variable's project, environment, and **whether it is marked Sensitive**.
4. **Any variable NOT marked Sensitive is considered exposed.** Rotate the underlying credential at its source system immediately — database passwords, API keys, signing keys, webhook secrets — regardless of whether Vercel notified you directly.
5. **Recreate all rotated secrets in Vercel with the Sensitive flag enabled.** Use Section 6.1's guidance; do not rely on the old un-sensitive entries.
6. **Revoke all Vercel API tokens and regenerate the minimum set needed.** Limit expiry to ≤90 days.

### C.2 Google Workspace / OAuth Audit (Within 48 Hours)

1. `admin.google.com` → **Security → API Controls → Third-party app access**.
2. Search for OAuth app ID `110671459871-30f1spbu0hptbs60cb4vsmv79i7bbvqj.apps.googleusercontent.com` — the Vercel-documented IOC. Revoke if present in any user's granted apps.
3. Review all unrecognized third-party apps and any Drive-permissioned apps that are not business-critical; revoke aggressively, re-grant only on demand.
4. Repeat for GitHub Organization OAuth apps and GitHub Apps (restrict Vercel GitHub App scope per Section 6.3).
5. Repeat for Microsoft Entra Enterprise Applications and Slack Installed Apps.

### C.3 Deployment and Code Investigation

1. List all deployments for the period 2026-04-01 → now. Any deployment initiated by an unusual actor, from an unusual IP, or at an unusual time is a candidate for forensic review.
2. Check Git provider audit logs (GitHub Audit Log, GitLab Audit Events) for suspicious deploy-hook invocations, webhook installs, or GitHub App permission changes.
3. Rotate **all deploy hooks** per Section 6.3. Treat existing hook URLs as burned.
4. Scan the git history of every repo connected to Vercel for leaked deploy hook URLs, long-lived API tokens, or API keys. Rotate anything found and rewrite history.

### C.4 Platform Hardening Follow-Through

1. **Enable Enforce Sensitive Environment Variables (Section 6.1, Step 1).** Make this the permanent baseline.
2. **Enable Deployment Protection (Section 2.1)** at Standard minimum across every project; regenerate any Deployment Protection automation bypass tokens.
3. **Install the Section 6.4 lint** in CI to prevent `NEXT_PUBLIC_` secret regressions.
4. **Configure Drains (Section 8.1 + 8.4)** to forward all logs to a SIEM with signature verification. Without off-platform logs, forensic evidence is lost after Vercel's short-term retention window.
5. **Subscribe to [Vercel KB Bulletin](https://vercel.com/kb/bulletin)** for future incidents and to Next.js security advisories (Section 9.1).

### C.5 Long-Term Program Changes

1. Build a **quarterly third-party OAuth audit** into your control calendar (Section 1.5). Vendor→vendor OAuth trust is now a documented supply-chain vector.
2. Move cloud-provider authentication from long-lived keys to **OIDC Federation (Section 1.4)**. Static credentials were the vector in this incident; eliminating them eliminates the class of attack.
3. **Measure MTTP** (mean time to patch) for Next.js CVEs per Section 9.1. Target ≤72 hours for critical.
4. Add an annual **red-team exercise** focused on supply-chain OAuth trust chains — verify that a compromised vendor OAuth could not pivot into your own Vercel/Google/GitHub environments undetected.

### C.6 Communication and Documentation

1. If your application stores end-user data, assess whether the incident is reportable under GDPR (72-hour notification), HIPAA Breach Notification, or any contractual customer obligations.
2. Publish an internal postmortem referencing this playbook. Future responders need to know what was done.
3. Update the team runbook and onboarding materials with the **"mark everything Sensitive"** rule so new hires inherit the post-incident baseline.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Vercel hardening guide | Claude Code (Opus 4.5) |
| 2026-02-24 | 1.0.0 | draft | [SECURITY] Complete guide revamp: expanded from 4 to 8 sections covering WAF, network security, security headers, domain security; added 20 controls with ClickOps and code pack references; integrated Vercel Shared Responsibility Model, production checklist, Terraform provider v4.6, CLI docs, and API docs; added comprehensive compliance mappings; updated edition compatibility matrix; incorporated security researcher findings and CVE references | Claude Code (Opus 4.6) |
| 2026-04-24 | 1.1.0 | draft | [SECURITY] Post-April-2026-incident integration: added Section 1.5 (Third-Party Integration Audit), 2.4 (Private Production Deployments / Advanced DP), 3.3 (Firewall Persistent Actions), 3.4 (AI Bots Managed Ruleset), 6.3 (Rotate Deploy Hooks), 6.4 (Block NEXT_PUBLIC_ Secret Leaks), 8.4 (Drain Signature Verification); added new top-level Section 9 (Framework CVE Management — Next.js) and Section 10 (Customer Misconfiguration Anti-Patterns) including middleware authz defense in depth, `/_next/image` remotePatterns audit, reverse-proxy + Bot Protection stacking guidance; added Appendix C April 2026 Incident Response Playbook. Updated Section 2.1 Deployment Protection with methods × scopes matrix, Routing Middleware coverage, full Protection Bypass for Automation details, and team-default settings. Updated Section 2.3 Rolling Releases with Skew Protection requirement and 0%-canary security caveat. Updated Section 3.1 WAF with JA3/JA4 fingerprinting, reverse-proxy incompatibility, vercel.json custom-rules limitations, and $1M bounty context. Updated Section 4.1 Secure Compute with Edge Runtime not-supported caveat, VPC peering limit, and active/passive failover. Updated Section 4.2 Attack Challenge Mode with internal-request per-account boundary and standalone-API caveat. Updated Section 6.1 Environment Variables: elevated Enforce Sensitive Environment Variables to L1 baseline; added April 2026 incident rationale; documented sensitive-not-supported-in-development gap. Updated Section 8.1 Drains: rebranded from Log Drains; documented four schema types; added IP Address Visibility toggle. 10 new pack files: `hth-vercel-1.05`, `2.04`, `3.03`, `3.04`, `6.03`, `6.04`, `8.04`, `9.01`, `10.01`, `10.02`. Added `private_production_deployments_enabled` and `production_only_trusted_ips_enabled` to `variables.tf`. | Claude Code (Opus 4.7) |
