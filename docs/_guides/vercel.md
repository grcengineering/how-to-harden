---
layout: guide
title: "Vercel Hardening Guide"
vendor: "Vercel"
slug: "vercel"
tier: "5"
category: "DevOps"
description: "Comprehensive platform security for authentication, WAF, deployment protection, secrets, network isolation, security headers, and monitoring"
version: "1.0.0"
maturity: "draft"
last_updated: "2026-02-24"
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

- [ ] Vercel Enterprise plan (or Pro with SSO add-on)
- [ ] SAML-compatible IdP (Okta, Entra ID, Google, OneLogin, etc. -- 24+ supported)
- [ ] Team Owner access in Vercel

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

1. [ ] Attempt login without SAML -- should be blocked when enforcement is ON
2. [ ] Login via IdP -- should succeed and land on team dashboard
3. [ ] Remove user from IdP group -- should lose Vercel access within sync interval

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

- [ ] Vercel Enterprise plan
- [ ] SAML SSO configured (Section 1.1)
- [ ] IdP supports SCIM (Okta, Entra ID, etc.)

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

1. [ ] Add a test user in IdP -- should appear in Vercel team within sync interval
2. [ ] Remove test user from IdP group -- should lose Vercel access
3. [ ] Change user role in IdP -- should reflect in Vercel

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

1. [ ] Developer role cannot modify production environment variables
2. [ ] Security role can manage firewall but cannot deploy
3. [ ] Viewer role has read-only access with no deploy capability
4. [ ] Contributor role has no access until explicitly assigned to a project

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

1. [ ] No tokens exist with unlimited expiration
2. [ ] OIDC federation provides short-lived credentials (60-min TTL)
3. [ ] All CI/CD pipelines use scoped tokens or OIDC
4. [ ] Token creation requires 2FA

**Expected result:** No long-lived, overly-scoped tokens; OIDC for cloud provider access

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-5 | Authenticator management |
| **ISO 27001** | A.9.2.4 | Management of secret authentication information |
| **PCI DSS** | 8.2.4 | Change user passwords/passphrases at least every 90 days |

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

#### ClickOps Implementation

**Step 1: Enable Standard Protection (All Plans)**
1. Navigate to: **Project Settings → Deployment Protection**
2. Set protection level to **Standard Protection** (protects all except production custom domains)
3. Enable **Vercel Authentication** -- requires team login for preview access

**Step 2: Add Password Protection (L2 -- Enterprise/Pro Add-on)**
1. Enable **Password Protection** for preview deployments
2. Set a strong, unique password and distribute via secure channel
3. Consider enabling for all deployments in sensitive projects

**Step 3: Configure Trusted IPs (L3 -- Enterprise)**
1. Add office and VPN egress IP ranges as trusted IPs
2. Set protection mode to **Trusted IP Required**
3. Apply to **All Deployments** for maximum protection

**Step 4: Harden Protection Bypass**
1. Review **Protection Bypass for Automation** settings
2. If used: ensure `VERCEL_AUTOMATION_BYPASS_SECRET` is a strong 32-character random value
3. L3: Disable automation bypass entirely if not required

**Time to Complete:** ~15 minutes

{% include pack-code.html vendor="vercel" section="2.1" %}

#### Validation & Testing

1. [ ] Unauthenticated access to preview URL returns login prompt
2. [ ] Password-protected deployment requires correct password
3. [ ] Access from non-trusted IP is blocked (Enterprise)
4. [ ] Automation bypass secret is 32+ characters if enabled

**Expected result:** All non-production deployments require authentication

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

1. [ ] Fork deployment is blocked without explicit approval
2. [ ] Unsigned commits fail deployment (when verified commits enabled)
3. [ ] Only authorized repositories are connected
4. [ ] Deployment creation restricted to production-only (L2)

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

Enable progressive deployment rollouts to limit blast radius of production changes.

#### Rationale

**Why This Matters:**
- Full instant deployments expose 100% of traffic to potential issues
- Rolling releases enable canary-style testing with real production traffic
- Manual approval gates add human verification before full rollout

**Attack Prevented:** Blast radius of compromised deployments, rapid exploitation of deployed vulnerabilities

#### ClickOps Implementation

**Step 1: Configure Rolling Release**
1. Navigate to: **Project Settings → Rolling Releases**
2. Choose **Manual Approval** for production deployments
3. Configure stages (e.g., 10% → 50% → 100%)
4. Set duration for automatic advancement if using automatic mode

**Time to Complete:** ~10 minutes

{% include pack-code.html vendor="vercel" section="2.3" %}

#### Validation & Testing

1. [ ] New deployment starts at first stage percentage
2. [ ] Manual approval required before advancing (if configured)
3. [ ] Rollback available at any stage

**Expected result:** Production deployments roll out progressively with approval gates

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC8.1 | Change management process |
| **NIST 800-53** | CM-3(2) | Testing, validation, and documentation of changes |
| **ISO 27001** | A.14.2.9 | System acceptance testing |
| **PCI DSS** | 6.4.5 | Change control procedures |

---

## 3. Web Application Firewall

### 3.1 Enable WAF with Managed Rulesets

**Profile Level:** L2 (Hardened)

**NIST 800-53:** SC-7, SI-3

#### Description

Enable the Vercel Web Application Firewall with OWASP managed rulesets, bot protection, and AI bot filtering.

#### Rationale

**Why This Matters:**
- Vercel WAF cannot be bypassed once enabled -- all traffic passes through it
- Managed rulesets protect against OWASP Top 10 without custom rule writing
- Vercel paid $1M+ to 116 security researchers for WAF bypass testing
- Rules propagate globally in under 300ms with instant rollback capability

**Attack Prevented:** SQL injection, XSS, command injection, path traversal, remote file inclusion, bot abuse, AI scraping

**Real-World Incidents:**
- **CVE-2025-29927:** Next.js middleware authorization bypass via `x-middleware-subrequest` header -- Vercel WAF updated proactively
- **React2Shell (CVE-2025-55182):** Critical RCE in React Server Components -- Vercel WAF rules deployed before disclosure

#### Prerequisites

- [ ] Vercel Enterprise plan for managed rulesets
- [ ] Pro plan for custom rules (up to 40)

#### ClickOps Implementation

**Step 1: Enable Firewall**
1. Navigate to: **Project → Firewall**
2. Toggle firewall to **Enabled**

**Step 2: Enable OWASP Managed Rulesets (Enterprise)**
1. Navigate to: **Firewall → Managed Rulesets**
2. Enable **OWASP Core Ruleset** in **Log** mode first
3. Monitor for 48-72 hours for false positives
4. Switch to **Deny** mode after tuning

**Step 3: Enable Bot Protection (Enterprise)**
1. Enable **Bot Protection Managed Ruleset** in **Challenge** mode
2. Enable **AI Bots Managed Ruleset** in **Deny** mode (unless AI crawling desired)

**Step 4: Configure Custom Rules (Pro+)**
1. Create rules for application-specific protection
2. Always test in **Log** mode before promoting to Deny/Challenge

**Time to Complete:** ~30 minutes

{% include pack-code.html vendor="vercel" section="3.1" %}

#### Validation & Testing

1. [ ] WAF is enabled and processing traffic (check Firewall tab)
2. [ ] OWASP rules detecting common attack patterns in logs
3. [ ] Bot protection challenging automated requests
4. [ ] AI bots blocked (if configured)

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

1. [ ] Blocked IPs return 403/challenge response
2. [ ] Rate-limited endpoints enforce configured thresholds
3. [ ] Persistent actions block repeat offenders
4. [ ] Rules show in Firewall activity logs

**Expected result:** Malicious and abusive traffic blocked at the edge

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | Security measures against external threats |
| **NIST 800-53** | SC-5, SI-4 | Denial of service protection, system monitoring |
| **ISO 27001** | A.13.1.2 | Security of network services |
| **PCI DSS** | 11.4 | Intrusion-detection/prevention techniques |

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

**Attack Prevented:** Shared IP abuse, unauthorized backend access, network-level lateral movement

#### Prerequisites

- [ ] Vercel Enterprise plan
- [ ] Secure Compute add-on ($6,500/year + $0.15/GB data transfer)
- [ ] Backend services supporting IP allowlisting

#### ClickOps Implementation

**Step 1: Create Secure Compute Network**
1. Navigate to: **Team Settings → Connectivity → Create Network**
2. Select AWS region closest to your backend
3. Configure CIDR block (must not overlap with VPC peer ranges)
4. Select availability zones

**Step 2: Assign Projects**
1. Add projects to the network
2. Configure per-environment (Production, Preview, etc.)
3. Optionally include build container (adds ~5s provisioning delay)

**Step 3: Configure VPC Peering (Optional)**
1. Create peering connection from Vercel dashboard
2. Accept in AWS VPC dashboard
3. Update route tables in both VPCs
4. Configure security groups to allow Vercel IP ranges

**Step 4: Update Backend Allowlists**
1. Add Vercel dedicated IPs to backend database firewall rules
2. Add to API gateway IP allowlists
3. Always layer authentication on top of IP filtering

**Time to Complete:** ~60 minutes

{% include pack-code.html vendor="vercel" section="4.1" %}

#### Validation & Testing

1. [ ] Functions connect to backend via private network
2. [ ] Backend rejects connections from non-Vercel IPs
3. [ ] Region failover switches to passive network on outage
4. [ ] VPC peering routes traffic correctly (if configured)

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

#### ClickOps Implementation

**Step 1: Verify DDoS Protection (Automatic)**
1. DDoS protection is always enabled -- no configuration required
2. Verify in: **Project → Firewall** -- should show traffic monitoring

**Step 2: Configure Attack Challenge Mode (During Attacks)**
1. Navigate to: **Project → Firewall → Bot Management → Attack Challenge Mode**
2. Enable during active attacks -- challenges ALL visitors with JS security check
3. Known bots (Googlebot, webhooks) auto-bypass
4. Cron jobs from your account auto-bypass
5. Disable when attack subsides

**Step 3: Configure Spend Management (Pro+)**
1. Navigate to: **Team Settings → Billing → Spend Management**
2. Set usage thresholds with automatic actions
3. Configure webhook notifications for usage spikes
4. Enable auto-pause for non-critical projects

**Step 4: Configure System Bypass Rules (L2 -- Pro+)**
1. Create rules to ensure essential traffic (proxies, shared networks) is never blocked
2. Use for business-critical external services

**Time to Complete:** ~10 minutes

{% include pack-code.html vendor="vercel" section="4.2" %}

#### Validation & Testing

1. [ ] DDoS mitigation active (always on -- verify via Firewall dashboard)
2. [ ] Attack Challenge Mode can be enabled/disabled
3. [ ] Spend management alerts configured
4. [ ] Blocked traffic not appearing in billing

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

1. [ ] All six security headers present in response
2. [ ] SecurityHeaders.com score of A or A+
3. [ ] No CSP violations in browser console for legitimate resources
4. [ ] X-Frame-Options prevents iframe embedding

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

Implement secure environment variable management with proper scoping, sensitivity flags, and access controls.

#### Rationale

**Why This Matters:**
- All environment variables are encrypted at rest (AES-256) by Vercel
- Variables scoped to production are only accessible to Owner/Member/Project Admin roles
- `NEXT_PUBLIC_` prefixed variables are exposed to client-side code -- never use for secrets
- Preview branches can access production secrets if not properly scoped
- Total limit: 64 KB per deployment; Edge Functions: 5 KB per variable

**Attack Prevented:** Secret exposure in client bundles, credential leakage via preview deployments, unauthorized production secret access

**Attack Scenario:** Developer creates a `NEXT_PUBLIC_API_SECRET` variable, exposing it in the client-side JavaScript bundle. Attacker views page source to extract the API key.

#### ClickOps Implementation

**Step 1: Audit Environment Variables**
1. Navigate to: **Project Settings → Environment Variables**
2. Review all variables for proper environment scoping
3. Verify no secrets use `NEXT_PUBLIC_` prefix
4. Ensure sensitive variables are scoped to production only (not preview)

**Step 2: Enable Sensitive Variable Policy (L2)**
1. Navigate to: **Team Settings → General → Sensitive Environment Variable Policy**
2. Enable to enforce sensitive flag on all new variables
3. Sensitive values cannot be read back from dashboard after creation

**Step 3: Scope Variables Properly**
1. Production secrets: Scope to **Production** only
2. Preview/staging secrets: Use separate, lower-privilege credentials for Preview
3. Use branch-specific preview variables when different branches need different configs
4. Use shared (team-level) variables for consistent cross-project configuration

**Step 4: Implement OIDC Federation (L2)**
1. Replace static cloud credentials with OIDC tokens (see Section 1.4)
2. OIDC provides 60-minute TTL tokens -- no static secrets needed

**Time to Complete:** ~15 minutes

{% include pack-code.html vendor="vercel" section="6.1" %}

#### Validation & Testing

1. [ ] No `NEXT_PUBLIC_` variables contain secret values
2. [ ] Production secrets not accessible in preview environment
3. [ ] Sensitive variable policy enforced at team level (L2)
4. [ ] OIDC federation active for cloud provider access (L2)

**Expected result:** Secrets properly scoped, flagged sensitive, and not exposed client-side

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | SC-28, SC-12 | Protection of information at rest, cryptographic key management |
| **ISO 27001** | A.10.1.2 | Key management |
| **PCI DSS** | 3.4 | Render PAN unreadable anywhere it is stored |

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

1. [ ] Retention policies set per environment type
2. [ ] Old deployments automatically cleaned up

**Expected result:** Deployment history managed with appropriate retention limits

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.5 | Disposal of confidential information |
| **NIST 800-53** | SI-12 | Information management and retention |
| **ISO 27001** | A.8.3.2 | Disposal of media |
| **PCI DSS** | 3.1 | Data retention and disposal policies |

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

1. [ ] All DNS records pointing to Vercel have active deployments
2. [ ] No orphaned domain entries in Vercel dashboard
3. [ ] Domain configuration changes logged in audit log

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

1. [ ] SSL Labs grade A+ with HSTS preloading
2. [ ] No TLS 1.0/1.1 negotiation possible
3. [ ] All ciphers support forward secrecy
4. [ ] HSTS preload header present on custom domains (L2)

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

### 8.1 Configure Log Drains for SIEM

**Profile Level:** L1 (Baseline)

**NIST 800-53:** AU-2, AU-6

#### Description

Forward Vercel runtime, build, and firewall logs to your SIEM via log drains for security monitoring and incident response.

#### Rationale

**Why This Matters:**
- Vercel only retains runtime logs short-term -- log drains required for long-term retention
- Firewall logs capture blocked/challenged requests for threat intelligence
- Log drain payloads can be cryptographically verified via shared secret
- SIEM integration enables correlation with other security data sources

**Attack Prevented:** Undetected attacks, delayed incident response, evidence loss, compliance gaps in log retention

#### Prerequisites

- [ ] Vercel Pro or Enterprise plan
- [ ] SIEM endpoint accepting HTTPS POST with JSON payloads

#### ClickOps Implementation

**Step 1: Create Log Drain**
1. Navigate to: **Team Settings → Log Drains**
2. Create new drain with your SIEM endpoint URL
3. Select delivery format: **JSON** or **NDJSON**
4. Select environments: **Production** and **Preview**
5. Select sources: **static, edge, external, build, lambda, firewall**
6. Set a strong shared secret for payload verification

**Step 2: Include Firewall Logs (L2)**
1. Add **firewall** source to log drain
2. Critical for detecting blocked attacks and WAF activity
3. Consider separate drain for firewall logs if volume is high

**Step 3: Configure Sampling (Optional)**
1. Set sampling rate for high-volume applications
2. Use 1.0 (100%) for security-critical projects
3. Lower rates acceptable for development/preview

**Time to Complete:** ~15 minutes

{% include pack-code.html vendor="vercel" section="8.1" %}

#### Validation & Testing

1. [ ] Log drain receiving events in SIEM
2. [ ] Payload signature verification working
3. [ ] Firewall logs appearing for blocked requests
4. [ ] All configured environments and sources flowing

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

- [ ] Vercel Enterprise plan

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

1. [ ] Audit log shows recent administrative events
2. [ ] SIEM receiving streamed audit events in real-time
3. [ ] Detection rules firing on test events
4. [ ] CSV export produces valid compliance report

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

1. [ ] CRON_SECRET set as production environment variable
2. [ ] Direct HTTP request without bearer token returns 401
3. [ ] Vercel-triggered cron execution succeeds with correct token

**Expected result:** Cron endpoints only accessible via authenticated Vercel invocation

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | AC-3, SI-10 | Access enforcement, information input validation |
| **ISO 27001** | A.9.4.1 | Information access restriction |
| **PCI DSS** | 8.1 | Unique identification for system components |

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
| Log Drains | 8.1 | ❌ | ✅ | ✅ |
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

**Security Incidents:**
- **2025 -- Next.js Middleware Authorization Bypass (CVE-2025-29927):** Vulnerability allowed bypassing authorization in Next.js Middleware via the `x-middleware-subrequest` header. Vercel WAF was updated proactively to protect hosted projects.
- **2025 -- React2Shell (CVE-2025-55182, CVSS 10.0):** Critical unsafe deserialization in React Server Components enabling Remote Code Execution. Vercel deployed WAF rules before public disclosure. China-nexus threat groups observed exploiting in the wild.
- **2025 -- React Server Components DoS (CVE-2025-55184, CVSS 7.5):** Infinite loop via crafted Server Function request.
- **2025 -- React Server Components Source Disclosure (CVE-2025-55183, CVSS 5.3):** Source code leakage under specific conditions.
- **2024 -- Next.js SSRF (CVE-2024-34351):** Server-Side Request Forgery in Server Actions via Host header manipulation. Vercel routing mitigates by default.

**Community Security Research:**
- [Vercel XSS in Clone URL (Medium)](https://medium.com/@n45ht/breaking-vercels-clone-url-with-a-simple-xss-exploit-8f55b21f32eb) -- Reflected XSS in clone functionality
- [Vercel Subdomain Takeover (Medium)](https://medium.com/@pentestfox/how-i-took-over-a-vercel-subdomain-e7b03dbf222d) -- Dangling CNAME exploitation
- [dSSRF: Deterministic SSRF Protection](https://community.vercel.com/t/introducing-dssrf-deterministic-ssrf-protection-for-vercel-serverless-edge-functions/29838) -- Community SSRF protection library
- [Next.js Security Checklist (Arcjet)](https://blog.arcjet.com/next-js-security-checklist/) -- Framework-level hardening guide
- [Nosecone Security Headers Library](https://nosecone.com) -- Open source security headers for Next.js

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Vercel hardening guide | Claude Code (Opus 4.5) |
| 2026-02-24 | 1.0.0 | draft | [SECURITY] Complete guide revamp: expanded from 4 to 8 sections covering WAF, network security, security headers, domain security; added 20 controls with ClickOps and code pack references; integrated Vercel Shared Responsibility Model, production checklist, Terraform provider v4.6, CLI docs, and API docs; added comprehensive compliance mappings; updated edition compatibility matrix; incorporated security researcher findings and CVE references | Claude Code (Opus 4.6) |
