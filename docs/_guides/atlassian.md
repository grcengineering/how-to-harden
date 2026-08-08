---
layout: guide
title: "Atlassian Cloud Hardening Guide"
vendor: "Atlassian Cloud"
slug: "atlassian"
platform: "Atlassian"
platform_slug: "atlassian"
product: "Common Controls"
tier: "2"
category: "Productivity"
description: "Platform-wide security hardening for Atlassian Cloud — the Common Controls hub (organization authentication, Atlassian Guard, Marketplace app governance, data security policies, org audit logging) shared by the Jira Cloud and Bitbucket product guides."
version: "0.4.0"
maturity: "draft"
last_updated: "2026-08-08"
---


## Overview

Atlassian serves **300,000+ customers** with the Atlassian Marketplace hosting **6,000+ apps**. OAuth 2.0, Connect (JWT), and Forge app frameworks create multiple attack vectors. Critical RCE vulnerabilities (CVE-2023-22515, CVSS 10.0; CVE-2022-26134, CVSS 9.8) demonstrated server-side risks. Cloud instances face OAuth token and AppLinks impersonation attacks from compromised Marketplace apps.

### Intended Audience
- Security engineers managing Atlassian products
- IT administrators configuring Jira and Confluence
- GRC professionals assessing collaboration tool security
- Third-party risk managers evaluating Marketplace apps

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide is the **Common Controls hub** for the Atlassian platform. It covers the organization-wide Atlassian Cloud (and, where noted, Data Center) configurations that apply across every Atlassian product: authentication and Atlassian Guard, Marketplace app governance, API and integration security, data residency and data security policies, and organization audit logging. Product-specific hardening lives in the product guides listed below.

Confluence has no separate product guide yet, so Confluence-specific settings (space permissions, anonymous access) remain in this hub.

### A Note on Licensing: Atlassian Guard

Many of the controls below are delivered by **Atlassian Guard**, the identity and data-security add-on that was previously named **Atlassian Access**. The product was renamed and split into two subscription levels, so older documentation and console screenshots referring to "Access" describe what is now Guard:

- **Guard Standard** — SSO enforcement, SCIM user provisioning and deprovisioning, mobile app policies, API token controls, and the organization-wide audit log.
- **Guard Premium** — everything in Standard plus data classification, anomalous activity detection, content scanning, and SIEM webhook forwarding.

Guard is licensed per unique billable user across the organization and is independent of the Jira or Confluence product edition, so a Premium product plan alone does not grant these capabilities. Source: [Atlassian Guard pricing](https://www.atlassian.com/software/access/pricing)

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Marketplace App Security](#2-marketplace-app-security)
3. [API & Integration Security](#3-api--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Vulnerability Management](#6-vulnerability-management)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## Products in This Platform

Atlassian is a multi-product platform. This guide is the **Common Controls hub** — the organization-wide controls configured once at `admin.atlassian.com` and inherited by every Atlassian product. Product-specific controls live in their own guides:

| Product | Guide | Covers |
|---------|-------|--------|
| **Common Controls** (this guide) | — | Organization authentication & Atlassian Guard, IP allowlisting, Marketplace app governance, API tokens & OAuth, data residency & data security policies, organization audit log and anomaly detection |
| **Jira Cloud** | [Jira Cloud guide](/guides/jira-cloud/) | Permission schemes, work item security schemes, global permissions, public/anonymous space exposure, guest access, automation rule egress |
| **Bitbucket** | [Bitbucket guide](/guides/bitbucket/) | Workspace membership & invitations, project permissions, workspace app access rules, forking, branch restrictions & merge checks, signed commits, Pipelines secrets and deployments |
| **Confluence** | — | No product guide yet — Confluence space permissions and anonymous access are covered in this hub (§1.2) |

> **Moved controls:** organization-level controls that previously appeared in the product guides now live here and are not duplicated. From the former Jira Cloud guide: SAML SSO (§1.1), authentication policies (§1.1), two-step verification (§1.1), SAML JIT/SCIM provisioning (§1.1), domain verification (§1.1), Atlassian Guard licensing (§1.1 and *A Note on Licensing* above), organization admin roles (§1.2), third-party app access (§2.1, §3.3), audit logging (§5.1), and security alerting (§5.2). From the former Bitbucket guide: two-step verification and SAML SSO (§1.1), IP allowlisting (§1.4), and organization audit logging (§5.1).

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all Atlassian Cloud access, eliminating local password authentication. SAML configuration and enforced authentication policies are Atlassian Guard Standard capabilities (formerly sold as Atlassian Access) and are not tied to the Jira or Confluence product edition. Source: [Atlassian Guard pricing](https://www.atlassian.com/software/access/pricing)

#### Prerequisites
- Atlassian organization with at least one verified domain
- Atlassian Guard Standard subscription (SAML SSO and enforced authentication policies are Guard capabilities, not product-edition features)
- Organization admin access
- SAML 2.0 compatible identity provider

#### Rationale
**Why This Matters:**
- Centralizing Atlassian authentication in your corporate IdP means MFA, conditional access, and session policy are enforced on every login to every Atlassian product, instead of product by product
- Configuring SSO alone does not force anyone to use it — without an authentication policy, a managed user can still sign in with a local Atlassian password and bypass every IdP control
- Domain verification is the prerequisite that turns accounts on your domain into *managed* accounts; unclaimed accounts are shadow identities that sit outside your authentication policy and your offboarding process
- Jira holds vulnerability tickets, roadmaps, and customer issues, and Confluence holds architecture documentation and credentials pasted into pages, so one compromised login exposes a great deal
- SSO plus directory provisioning gives one place to revoke access instantly when someone leaves, eliminating standing access through local credentials

**Attack Prevented:** Credential stuffing, phishing, password reuse, SSO bypass via local passwords, shadow accounts on your own domain, offboarding gaps

#### ClickOps Implementation (Atlassian Cloud)

**Step 1: Verify Your Domains**
1. Navigate to: **admin.atlassian.com → Directory → Domains**
2. Add each domain your organization owns and complete DNS verification
3. Claim the existing Atlassian accounts on those domains into organization management — until an account is claimed, no authentication policy applies to it
4. Repeat for every domain and subdomain in use, including domains acquired through mergers, which are the ones most often missed

**Step 2: Configure SAML SSO**
1. Navigate to: **admin.atlassian.com → Security → SAML single sign-on**
2. Click **Add SAML configuration**
3. Configure:
   - **Identity provider:** Your IdP (Okta, Entra ID, etc.)
   - **Entity ID:** From IdP
   - **SSO URL:** IdP login endpoint
4. Upload IdP certificate

**Step 3: Enforce SSO with an Authentication Policy**
1. Navigate to: **Security → Authentication policies**
2. Create policy:
   - **Name:** "SSO Required"
   - **Members:** All managed users from verified domains
   - **Settings:**
     - Require SSO: Enabled
     - Allow local passwords: Disabled
3. Create a **separate break-glass policy** covering two or three dedicated organization-admin accounts that are exempt from SSO enforcement, so an IdP outage or misconfiguration cannot lock every administrator out. Protect those accounts with their own strong two-step verification and monitor every use of them in the audit log (§5.1)

**Step 4: Configure Two-Step Verification**
1. Navigate to: **Security → Two-step verification**
2. Enable: **Require two-step verification for all users**
3. Configure:
   - **Enforcement:** Required
   - **Grace period:** None (L2)
4. Where the IdP is authoritative, enforce phishing-resistant factors (FIDO2 security keys or passkeys) there for administrators rather than relying on TOTP alone

**Step 5: Automate Provisioning and Deprovisioning**
1. Connect a directory and enable **SCIM user provisioning** so accounts, group membership, and — critically — *deactivation* flow from the IdP automatically
2. Where SCIM is not available for a given IdP, enable **SAML Just-In-Time (JIT) provisioning** so accounts are created from authoritative IdP attributes on first SSO login rather than by hand
3. Map IdP attributes and groups to Atlassian groups, then verify that the mapped groups are the same ones your product access grants and permission schemes rely on
4. Test the full lifecycle end to end: create a test identity in the IdP, confirm it appears and receives the right product access, then disable it in the IdP and confirm Atlassian access is revoked

> **JIT is not deprovisioning.** JIT provisioning only creates accounts at login; it never removes them. An organization relying on JIT alone accumulates active accounts for departed employees. Use SCIM where the IdP supports it, and where it does not, pair JIT with a scheduled manual deactivation review.

#### Validation & Testing

1. From a browser with no existing session, sign in as a managed user and confirm you are redirected to the IdP and cannot reach a local Atlassian password prompt
2. Attempt a password reset for a managed user and confirm the flow is unavailable or has no effect on access
3. Confirm every verified domain lists zero unclaimed accounts under **Directory → Managed accounts**
4. Deactivate a test identity in the IdP and confirm the corresponding Atlassian account loses access without any admin action
5. Confirm the break-glass policy contains only the intended accounts and that every sign-in using it appears in the organization audit log

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(1) | MFA for network access |

---

### 1.2 Implement Granular Product Access and Limit Organization Admins

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6, AC-6(1)

#### Description
Configure who receives access to each Atlassian product at the organization level, and hold the organization administrator role to the smallest workable set of accounts. Product access is granted at **admin.atlassian.com → Products**; administrator roles are managed at **admin.atlassian.com → Directory → Administrators**. Within-product authorization (Jira permission schemes, Bitbucket workspace and project permissions) is configured in each product and is covered in the product guides.

#### Rationale
**Why This Matters:**
- Default-open product access lets every licensed user reach every Jira space and Confluence space, far beyond what their role requires
- Organization admins can change SSO configuration, authentication policies, product access grants, and billing across every Atlassian product, which makes the role the single highest-value target in the tenant — an attacker who phishes one org admin owns everything downstream
- Product admins can perform most day-to-day administration without organization-wide authority, so most people currently holding org admin almost certainly do not need it
- Disabling anonymous Confluence access prevents unauthenticated readers from harvesting internal documentation, architecture diagrams, and secrets pasted into pages
- Reviewing admin rosters on a cadence stops the privilege accumulation that follows reorganizations and offboarding gaps

**Attack Prevented:** Lateral movement, privilege creep, organization-admin account takeover, excessive standing privilege, insider data harvesting, anonymous information disclosure

#### ClickOps Implementation

**Step 1: Configure Product Access**
1. Navigate to: **admin.atlassian.com → Products**
2. For each product, configure:
   - **Default access:** Disabled (users must be granted access)
   - **User access:** Specific groups only
3. Grant access through IdP-synced groups rather than to individuals, so access follows the joiner/mover/leaver process automatically

**Step 2: Limit Organization Administrators**
1. Navigate to: **admin.atlassian.com → Directory → Administrators**
2. Record every account holding the organization admin role and the business reason for each
3. Reduce the roster to the minimum that still supports coverage — two or three accounts is typical, and those should be dedicated admin identities rather than the everyday accounts of the same people
4. Move anyone whose work is confined to one product to a product admin role instead
5. Re-review the roster on a fixed cadence and alert on organization admin role grants in the audit log (§5.1), since a self-granted admin role is a hallmark of an in-progress compromise

**Step 3: Configure Confluence Space Permissions**
1. Navigate to: **Confluence → Space settings → Permissions**
2. Configure:
   - **Anonymous access:** Disabled
   - **Group permissions:** Specific groups per space
   - **Default permissions:** View only for most users

> **Within-product authorization lives in the product guides.** Jira permission schemes, work item security schemes, and global permissions are covered in the [Jira Cloud guide](/guides/jira-cloud/). Bitbucket workspace membership, project permissions, and branch restrictions are covered in the [Bitbucket guide](/guides/bitbucket/). Grant product access here first; scope it inside the product there.

---

### 1.3 Configure API Token Policies

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Control API token creation and set an organization expiration policy that is shorter than the platform ceiling. Since **15 December 2024**, every newly created Atlassian account API token must carry an expiry date between **1 day and 1 year**, and tokens created before that date without an expiry were force-expired in batches between **March and May 2026**. The platform therefore guarantees only a one-year maximum lifetime — a shorter organizational standard is a policy decision you still have to make and enforce. Source: [Manage API tokens for your Atlassian account](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/)

#### Rationale
**Why This Matters:**
- API tokens authenticate as the user and bypass interactive SSO and MFA, so an exposed token is a standing credential carrying the full access of its owner
- The mandatory-expiry change removes the worst case of a token that never dies, but a token living the full one-year platform maximum still gives an attacker a very long window of persistent access
- Long-lived tokens linger in scripts, CI systems, and developer laptops, and a one-year rotation cadence rarely matches the pace at which contractors leave and repositories get forked
- Restricting who can mint tokens and setting a shorter internal expiration standard shrinks the window an exfiltrated token remains valid
- Auditing and revoking unused tokens removes forgotten credentials that attackers routinely find in code repositories and config files
- Tokens that silently expire on the platform's schedule can break production integrations, so tracking expiry dates is an availability concern as much as a security one

**Attack Prevented:** Token theft, MFA bypass, persistent unauthorized access, credential sprawl

#### ClickOps Implementation

**Step 1: Configure Token Settings**
1. Navigate to: **admin.atlassian.com → Security → API tokens**
2. Configure:
   - **Allow users to create API tokens:** Controlled (requires Atlassian Guard)
   - **Token expiration:** Choose the shortest interval your integrations tolerate. Atlassian accepts **1 day to 1 year**; a **90-day** organizational standard is a policy choice well inside that ceiling, not the platform maximum

**Step 2: Audit Existing Tokens**
1. Navigate to: **Security → API tokens → Token controls**
2. Review active tokens, recording the expiry date on each one
3. Revoke unused or suspicious tokens
4. Flag any token whose expiry sits near the one-year ceiling for early rotation and for migration to a scoped OAuth 2.0 integration where one exists

**Step 3: Plan for Forced Expiry**
1. Inventory every automation, CI job, and script that authenticates with a personal API token
2. Assign each an owner responsible for rotation ahead of the expiry date
3. Alert on authentication failures from service integrations so an expired token surfaces as a tracked incident rather than a silent outage

---

### 1.4 Restrict Product Access with IP Allowlisting

**Profile Level:** L3 (Run)

| Framework | Control ID |
|-----------|------------|
| **CIS Controls** | 12.7, 13.4 |
| **NIST 800-53** | AC-3, AC-17, SC-7 |
| **ISO 27001:2022** | A.8.20, A.8.21 |

#### Description
Restrict browser and REST API access to Jira, Jira Service Management, and Confluence so that only requests originating from approved IP ranges — corporate egress, VPN concentrators, or managed CI runners — are accepted. IP allowlisting is configured per product under **Product settings → Security → IP allowlist** and is available on Premium and Enterprise product plans. Source: [What is the scope of IP allowlists in Atlassian Cloud?](https://support.atlassian.com/atlassian-cloud/kb/what-is-the-scope-of-ip-allowlists-in-atlassian-cloud/)

#### Rationale
**Why This Matters:**
- A stolen password or session cookie is useless from an attacker's own infrastructure if the product rejects the connection before authentication is evaluated
- The allowlist applies to both interactive site login and REST API calls, so it constrains scripted data harvesting with a leaked API token as effectively as it constrains browser logins
- Network-level filtering runs independently of the identity provider, giving a second, non-credential control that survives an IdP compromise or an MFA-fatigue attack
- Bulk exfiltration campaigns typically run from cloud hosting or residential proxy ranges that never appear in a corporate egress allowlist, so the restriction cuts off the exfiltration path even after account takeover

**Important scope limitation:** the product IP allowlist does **not** cover `admin.atlassian.com`. Organization administration — user management, authentication policies, product access grants, and billing — remains reachable from any IP address. Treat administrator accounts as still fully internet-exposed and protect them with phishing-resistant MFA and dedicated authentication policies rather than assuming the allowlist covers them. The allowlist also does not filter mobile app traffic in the same way as browser traffic, so validate mobile access before enforcing.

**Attack Prevented:** Credential-stuffing from attacker infrastructure, session hijacking replayed off-network, API-token-driven bulk export, unmanaged-device access

#### ClickOps Implementation

**Step 1: Inventory Legitimate Source Ranges**
1. Collect corporate office egress IPs, VPN concentrator IPs, and the static egress ranges of any CI/CD system, integration platform, or monitoring tool that calls the Atlassian REST API
2. Confirm each range is static — dynamic residential or auto-scaling cloud IPs will break access unpredictably
3. Document the business owner for every range so stale entries can be removed later

**Step 2: Configure the Allowlist per Product**
1. Navigate to: **Product settings → Security → IP allowlist** for Jira
2. Add each approved IP address or CIDR range with a description identifying its owner
3. Repeat for Jira Service Management and Confluence — the allowlist is configured separately for each product and is not inherited across them
4. Review whether customer-facing Jira Service Management portals need to remain publicly reachable before enforcing on that product

**Step 3: Compensate for the Admin Console Gap**
1. Apply a dedicated authentication policy to organization administrators requiring phishing-resistant MFA
2. Keep the count of organization admins minimal and review it on a fixed cadence
3. Alert on any administrative action in the audit log originating from an IP outside the allowlist, since the console itself will not block it

#### Validation & Testing

1. From an approved network, log in to each product and confirm normal access
2. From an unapproved network — a mobile hotspot or a cloud VM — attempt to load the same site and confirm the request is refused
3. From the unapproved network, issue an authenticated REST API call with a valid API token and confirm it is also refused, proving the allowlist covers the API surface and not just the browser
4. From the unapproved network, load `admin.atlassian.com` and confirm it **is** reachable, documenting this as an accepted residual risk with its compensating controls
5. Verify every allowlisted integration still functions after enforcement, particularly CI jobs that run on a schedule rather than on demand
6. Re-run the external-network test after each allowlist change to confirm no entry silently widened the perimeter

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls restrict access to authorized sources |
| **SOC 2** | CC6.6 | Boundary protection for external access points |
| **NIST 800-53** | AC-17 | Remote access restrictions and monitoring |
| **NIST 800-53** | SC-7 | Boundary protection |
| **ISO 27001:2022** | A.8.20 | Network security controls |
| **CIS Controls** | 12.7 | Manage network infrastructure access |

---

## 2. Marketplace App Security

### 2.1 Implement App Approval Workflow

**Profile Level:** L1 (Crawl) - CRITICAL
**NIST 800-53:** CM-7

#### Description
Require admin approval for Marketplace app installation. Apps have broad access to Jira/Confluence data.

#### Rationale
**Why This Matters:**
- 6,000+ Marketplace apps with varying security postures
- Apps access project data, user information, and configurations
- Compromised or malicious apps enable data exfiltration
- The app framework matters as much as the vendor: Connect apps run on vendor-controlled infrastructure and hold broad JWT-scoped access, while Forge apps run on Atlassian-hosted infrastructure with tighter, declared permission scoping
- Connect is being retired on a published timeline, so approving a new Connect app today buys a dependency with a known end date

**Attack Prevented:** Malicious app installation, data exfiltration through over-scoped integrations, supply-chain compromise via unmaintained vendor infrastructure

#### ClickOps Implementation

**Step 1: Configure App Installation Policy**
1. Navigate to: **admin.atlassian.com → Security → App policies**
2. Configure:
   - **Who can install apps:** Admins only
   - **User install requests:** Require approval
   - **App block list:** Add prohibited apps

**Step 2: Review Existing Apps**
1. Navigate to: **admin.atlassian.com → Apps**
2. For each app, review:
   - Permissions/scopes requested
   - Last updated date
   - Security certifications
   - User count and reviews
3. Remove unused or suspicious apps

**Step 3: Create App Evaluation Checklist**
Before approving any app:
- Review requested permissions (OAuth scopes)
- Check vendor security certifications (SOC 2, ISO 27001)
- Review app update frequency
- Check for known vulnerabilities
- Evaluate data access requirements
- Confirm which framework the app is built on — prefer Forge, and treat Connect as legacy (see below)
- Document business justification

#### Connect Framework Sunset — Prefer Forge

Atlassian has published an end-of-support timeline for the Connect app framework, and it changes how new app approvals should be evaluated:

| Milestone | Date | Effect |
|-----------|------|--------|
| No new Connect listings | September 2025 | New Connect apps can no longer be published to the Marketplace |
| Descriptor updates stop | March 2026 | Existing Connect apps can no longer change their descriptor, freezing scopes and endpoints |
| End of support | 31 January 2027 | Connect apps cease to be supported on the platform |

Source: [Announcing Connect end of support timeline and next steps](https://www.atlassian.com/blog/development/announcing-connect-end-of-support-timeline-and-next-steps)

**What this means for app governance:**

- Treat any Connect-based app as a legacy dependency with a hard expiry, not a durable integration, and require a documented migration or replacement plan before approving it
- Prefer Forge apps, which run on Atlassian-hosted infrastructure with declared, granular permission scopes and no vendor-operated servers holding your data in transit
- Because Connect descriptors freeze in March 2026, a Connect app cannot narrow its own scopes or repoint its endpoints after that date — any scope concern you have with it becomes permanent
- Inventory your installed Connect apps now and track vendor migration commitments; apps whose vendors have not announced a Forge migration path should be scheduled for removal rather than carried toward the 2027 deadline
- Frozen, unmaintained apps still holding live tokens against your instance are an attractive supply-chain target, so shrink that inventory ahead of end-of-support rather than at it

#### Marketplace App Risk Assessment

| Permission | Risk Level | Questions to Ask |
|------------|------------|------------------|
| Read Jira issues | Medium | Which projects? |
| Write Jira issues | High | Can it delete? |
| Read Confluence content | Medium | Which spaces? |
| Admin access | Critical | Why needed? |
| User management | Critical | Business justification? |
| Act on behalf of users | High | What actions? |

---

### 2.2 Monitor App Activity

**Profile Level:** L2 (Walk)
**NIST 800-53:** AU-6

#### Description
Monitor Marketplace app API calls and data access.

#### Rationale
**Why This Matters:**
- Installed apps run with broad delegated scopes and can read or move large volumes of Jira and Confluence data without a human in the loop
- A compromised or malicious app behaves like a legitimate integration, so its abuse is invisible without monitoring API call patterns
- Baselining normal app data-access volume surfaces sudden bulk reads or exports that indicate exfiltration in progress
- Activity logs give responders the evidence to scope and revoke a rogue app before it drains an entire instance

**Attack Prevented:** Malicious app data exfiltration, supply-chain abuse, undetected bulk export

#### Code Implementation

{% include pack-code.html vendor="atlassian" section="2.2" %}

---

## 3. API & Integration Security

### 3.1 Secure AppLinks Configuration

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-8

#### Description
Harden AppLinks between Atlassian products to prevent impersonation attacks.

#### Rationale
**Why This Matters:**
- AppLinks establish trust between Atlassian products, and a misconfigured link lets one application impersonate users on another
- OAuth 1.0a and unverified trust directions allow an attacker who controls one linked system to forge requests the trusting system accepts as authenticated
- Auditing and removing stale AppLinks eliminates standing trust relationships to systems that are no longer maintained or have changed ownership
- Restricting AppLink creation to administrators prevents an attacker or insider from quietly establishing a trusted impersonation channel

**Attack Prevented:** User impersonation, cross-product request forgery, trust-relationship abuse

#### ClickOps Implementation (Data Center)

**Step 1: Audit Existing AppLinks**
1. Navigate to: **Administration → Application links**
2. Review all configured links
3. Verify each link is still needed

**Step 2: Configure OAuth 2.0 for AppLinks**
1. For each AppLink, configure:
   - **Authentication type:** OAuth 2.0 (not OAuth 1.0a)
   - **Incoming/Outgoing trust:** Verify both directions

**Step 3: Restrict AppLinks Creation**
- Limit AppLinks creation to administrators only
- Document approved integration patterns

---

### 3.2 Configure Webhook Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-8

#### Description
Secure webhook configurations to prevent data leakage.

#### Rationale
**Why This Matters:**
- Webhooks push issue and page data to external URLs automatically, so a hostile or hijacked endpoint receives a continuous feed of internal content
- Without HTTPS, webhook payloads traverse the network in cleartext and can be intercepted in transit
- Missing signature validation lets an attacker spoof webhook calls to downstream services or replay captured payloads
- Scoping events with JQL filters limits each webhook to the minimum data it needs, reducing what leaks if the destination is compromised

**Attack Prevented:** Data leakage, payload interception, webhook spoofing, over-broad data exposure

#### ClickOps Implementation

**Step 1: Audit Webhooks**
1. Navigate to: **System → Webhooks** (Jira)
2. Review all configured webhooks:
   - Destination URLs (should be internal or verified services)
   - Events subscribed
   - JQL filters (limit scope)

**Step 2: Secure Webhook Endpoints**
- Require HTTPS for all webhook URLs
- Implement webhook signature validation
- Limit events to necessary minimum

{% include pack-code.html vendor="atlassian" section="3.2" %}

---

### 3.3 OAuth Token Management

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(13)

#### Description
Manage OAuth tokens for third-party integrations.

#### Rationale
**Why This Matters:**
- OAuth grants let third-party applications act on a user's behalf, and forgotten authorizations remain valid until explicitly revoked
- Over-scoped grants give an integration far more access than it needs, so its compromise exposes data well beyond its function
- Requiring admin approval for new apps and sensitive scopes stops users from authorizing risky integrations that bypass procurement and security review
- Periodically reviewing and revoking connected apps removes dormant grants that attackers exploit through compromised third-party vendors

**Attack Prevented:** OAuth grant abuse, over-privileged integrations, third-party compromise, consent phishing

#### ClickOps Implementation

**Step 1: Review Authorized Applications**
1. Navigate to: **Profile → Security → Connected apps**
2. Review apps with OAuth access
3. Revoke unnecessary authorizations

**Step 2: Configure OAuth App Policies**
1. Navigate to: **admin.atlassian.com → Security → External apps**
2. Configure:
   - **App approval:** Required for new apps
   - **Scope review:** Admin approval for sensitive scopes

---

## 4. Data Security

### 4.1 Configure Data Residency

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-28

#### Description
Configure data residency for compliance with data localization requirements.

#### Rationale
**Why This Matters:**
- Regulations such as GDPR and various data-sovereignty laws require certain data to remain within specific geographic boundaries
- Pinning Atlassian data to an approved realm prevents inadvertent cross-border storage that creates legal and contractual exposure
- Documented residency controls provide the evidence auditors and customers require to demonstrate localization compliance
- Controlling where data lives also limits which jurisdictions' legal processes can compel access to it

**Attack Prevented:** Compliance violations, unauthorized cross-border data transfer, jurisdictional overreach

#### ClickOps Implementation (Enterprise)

**Step 1: Configure Data Residency**
1. Navigate to: **admin.atlassian.com → Data residency**
2. Select realm for data storage:
   - US
   - EU
   - Australia
3. Apply to products

---

### 4.2 Implement Data Classification

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3

#### Description
Use data classification to restrict access to sensitive content.

#### Rationale
**Why This Matters:**
- Without classification, all content is treated the same and sensitive material is protected no better than routine notes
- Labeling spaces and projects by sensitivity drives access decisions so confidential and restricted content is gated to the right audiences
- Classification gives users a clear signal not to paste secrets or regulated data into low-sensitivity, broadly readable spaces
- Consistent labels enable automated policy and DLP enforcement and provide auditable evidence of how sensitive data is handled

**Attack Prevented:** Sensitive data exposure, over-sharing, mishandling of regulated content

#### ClickOps Implementation

**Step 1: Enable Classification (Atlassian Guard Premium)**
1. Navigate to: **admin.atlassian.com → Data classification**
2. Create classification levels:
   - Public
   - Internal
   - Confidential
   - Restricted

**Step 2: Apply to Spaces/Projects**
1. Classify Confluence spaces
2. Classify Jira projects
3. Configure access based on classification

---

### 4.3 Enforce Data Security Policies

**Profile Level:** L2 (Walk)

| Framework | Control ID |
|-----------|------------|
| **CIS Controls** | 3.3, 3.12, 14.4 |
| **NIST 800-53** | AC-3, AC-4, AC-21, SC-7(10) |
| **ISO 27001:2022** | A.5.14, A.8.12 |

#### Description
Data security policies are organization-level rules that constrain what can be done with content in covered Jira projects and Confluence spaces, regardless of the permissions individual users hold. A policy can block content export, block Confluence public link sharing, restrict anonymous and external access, and restrict which apps may reach covered content. Policies are configured at **admin.atlassian.com → Security → Data security policies** and scope to specific spaces and projects or to a data classification level. Source: [What is a data security policy?](https://support.atlassian.com/security-and-access-policies/docs/what-is-a-data-security-policy/)

#### Rationale
**Why This Matters:**
- Permission schemes control who can *read* content, but they do not control what a legitimate reader can then *do* with it — export, public link, or app-mediated extraction all remain available to anyone with view access
- Blocking export closes the single highest-volume exfiltration path, turning a one-click full-space download into a page-by-page manual effort that is slow, noisy, and visible in audit logs
- Confluence public links bypass authentication entirely, and a single link shared from an internal space silently publishes that page to anyone who receives the URL — including anyone who finds it indexed
- Restricting app access by space, project, or classification means a compromised or over-scoped Marketplace app cannot reach your most sensitive content even though it holds an org-wide grant, which directly limits Marketplace supply-chain blast radius
- Binding policies to classification levels rather than to individual spaces makes the control scale: newly created content inherits protection from its label instead of waiting for an admin to remember to add it
- Policies are enforced organization-wide and cannot be overridden by a space or project administrator, so they hold even when local permissions drift

**Attack Prevented:** Bulk data exfiltration via export, unauthenticated disclosure through public links, third-party app data harvesting, insider mass download, over-sharing with external collaborators

#### ClickOps Implementation

**Step 1: Create a Baseline Policy**
1. Navigate to: **admin.atlassian.com → Security → Data security policies**
2. Select **Create policy** and give it a name that states its intent, such as "Restricted Content — No Export, No Public Links"
3. Choose coverage: specific Confluence spaces and Jira projects, or — if data classification is in use — a classification level so coverage follows the label

**Step 2: Select the Rules**
1. **Block export:** prevents downloading covered content as PDF, Word, CSV, XML, or via bulk space export
2. **Block public links:** prevents Confluence pages in scope from being shared through anonymous, unauthenticated URLs
3. **Restrict anonymous and external access:** blocks anonymous viewing and limits guest or external collaborator reach into covered spaces
4. **Restrict app access:** choose whether covered content is reachable by all apps, by an approved subset, or by none — this is the control that contains a compromised Marketplace app

**Step 3: Stage the Rollout**
1. Start with the highest-sensitivity spaces and projects — security, legal, HR, finance, and anything holding regulated data
2. Communicate the change before enforcing; export blocking will visibly break existing reporting and offboarding workflows
3. Identify legitimate export use cases and route them to an approved alternative such as a scoped API integration rather than granting broad exemptions
4. Extend coverage outward once the first policy is stable, and prefer classification-based scoping so new content is covered automatically

**Step 4: Review on a Cadence**
1. Re-review policy coverage quarterly against the current space and project inventory
2. Confirm no high-sensitivity area was created outside every policy's scope
3. Re-verify the app allowance list after each new app approval

#### Validation & Testing

1. As a user with full view permission on a covered space, attempt a PDF and a space export and confirm both are refused
2. Attempt to create a public link on a covered Confluence page and confirm the option is unavailable or blocked
3. Attempt to access a covered space anonymously in a logged-out browser session and confirm access is refused
4. Using an app that is not on the allowance list, attempt to read covered content through its integration and confirm the request fails
5. Repeat the export test on an *uncovered* space to confirm the policy is scoped as intended and has not silently blocked more than planned
6. If policies are scoped by classification, apply the classification label to a new test space and confirm the restrictions take effect without any further admin action
7. Review the audit log to confirm policy creation and modification events are recorded and attributable

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls over protected information |
| **SOC 2** | CC6.7 | Restrictions on transmission and movement of information |
| **NIST 800-53** | AC-4 | Information flow enforcement |
| **NIST 800-53** | AC-21 | Information sharing restrictions |
| **ISO 27001:2022** | A.5.14 | Information transfer controls |
| **ISO 27001:2022** | A.8.12 | Data leakage prevention |
| **CIS Controls** | 3.3 | Configure data access control lists |

---

## 5. Monitoring & Detection

### 5.1 Enable Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure and monitor Atlassian audit logs.

#### Rationale
**Why This Matters:**
- Audit logs are the primary record of authentication, permission changes, app installs, and data exports needed to detect and investigate abuse
- Without centralized logging, malicious activity such as a quiet permission escalation or bulk export goes unnoticed until damage is done
- Streaming logs to a SIEM preserves evidence beyond the platform's retention window and correlates Atlassian events with the rest of the environment
- Reliable audit trails are required for incident response and for SOC 2, ISO 27001, and similar compliance attestations

**Attack Prevented:** Undetected intrusion, repudiation, delayed incident response, tampering concealment

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **admin.atlassian.com → Security → Audit log**
2. Review events:
   - Authentication events
   - Permission changes
   - App installations
   - Data exports

**Step 2: Configure SIEM Export**
1. Navigate to: **Settings → Audit log streaming** (SIEM webhook forwarding requires Atlassian Guard Premium)
2. Configure destination:
   - Splunk
   - Sumo Logic
   - Custom webhook

**Step 3: Correlate with Product-Level Logs**
1. The organization audit log records identity, policy, app, and product-access events across the whole tenant — it is the authoritative record for the controls in this hub
2. Individual products keep their own narrower logs (the Bitbucket workspace audit log, the Jira automation audit log) that record activity the organization log does not. Forward those alongside the organization log rather than in place of it — see the [Bitbucket guide](/guides/bitbucket/) §5.1 and the [Jira Cloud guide](/guides/jira-cloud/) §3.1
3. Confirm your SIEM retention exceeds each source's native retention, since product-level logs expire far sooner than an investigation timeline

---

### 5.2 Configure Anomaly Detection

**Profile Level:** L2 (Walk)

#### Description
Enable anomalous activity detection, which is delivered by **Atlassian Guard Premium** (the product formerly sold as Atlassian Access). It is a Guard subscription capability rather than a Jira or Confluence product-edition feature, so a Premium or Enterprise product plan alone does not enable it. Source: [Atlassian Guard pricing](https://www.atlassian.com/software/access/pricing)

#### Rationale
**Why This Matters:**
- Anomaly detection flags behavior that static rules miss, such as impossible-travel logins or atypical bulk data access
- Account takeover and insider abuse often look like ordinary activity until viewed against the user's established baseline
- Automated alerts shrink dwell time by surfacing suspicious events in near real time rather than during a periodic log review
- Early warning on permission changes catches an attacker escalating privileges before they reach sensitive projects

**Attack Prevented:** Account takeover, insider abuse, credential stuffing, stealthy privilege escalation

#### ClickOps Implementation

1. Navigate to: **admin.atlassian.com → Security → Anomaly detection**
2. Enable detection for:
   - Unusual login locations
   - Bulk data access
   - Permission changes
3. Configure alert recipients

---

## 6. Vulnerability Management

### 6.1 Critical CVE Response

**Profile Level:** L1 (Crawl)

#### Description
Recent critical vulnerabilities require immediate attention.

#### Rationale
**Why This Matters:**
- Critical Confluence and Jira vulnerabilities have included broken access control and OGNL injection enabling unauthenticated remote code execution and rogue admin account creation
- These flaws are weaponized and actively exploited within days of disclosure, so unpatched Data Center and Server instances are high-value targets
- Prompt patching plus log review for exploitation attempts and unauthorized admin accounts limits both initial compromise and attacker persistence
- A defined CVE response process ensures advisories are acted on immediately instead of waiting for the next maintenance window

**Attack Prevented:** Remote code execution, authentication bypass, unauthorized admin creation, data destruction

#### Recent Critical CVEs

| CVE | CVSS | Product | Description |
|-----|------|---------|-------------|
| CVE-2023-22515 | 10.0 | Confluence DC/Server | Broken access control, admin account creation |
| CVE-2023-22518 | 9.8 | Confluence DC/Server | Auth bypass, data destruction |
| CVE-2022-26134 | 9.8 | Confluence Server/DC | OGNL injection RCE |
| CVE-2021-26084 | 9.8 | Confluence Server/DC | OGNL injection RCE |

#### Response Actions

**For Data Center/Server:**
1. Apply patches immediately
2. Review access logs for exploitation attempts
3. Check for unauthorized admin accounts
4. Consider migration to Cloud

**For Cloud:**
- Atlassian manages patching
- Monitor Atlassian security advisories
- Review audit logs for suspicious activity

---

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Atlassian Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement, domain verification, 2SV | 1.1 |
| CC6.2 | Product access and organization admin roles | 1.2 |
| CC6.3 | SCIM/JIT provisioning and deprovisioning | 1.1 |
| CC6.6 | IP allowlisting | 1.4 |
| CC6.7 | Data security policies | 4.3 |
| CC7.2 | Audit logging | 5.1 |

### NIST 800-53 Mapping

| Control | Atlassian Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | SSO with MFA | 1.1 |
| AC-2 | SCIM/JIT provisioning and deprovisioning | 1.1 |
| AC-6(1) | Organization admin role limitation | 1.2 |
| AC-17 | IP allowlisting | 1.4 |
| CM-7 | App approval workflow | 2.1 |
| AU-2 | Audit logging | 5.1 |

---

## Appendix A: Edition Compatibility

Atlassian licensing splits across two independent axes, and conflating them is a common planning error. The **product edition** (Free, Standard, Premium, Enterprise) governs Jira and Confluence features. **Atlassian Guard** — formerly Atlassian Access — is a separate per-user subscription that governs identity and data-security capabilities across the whole organization. Buying Jira Premium does not grant Guard capabilities, and buying Guard does not grant product-edition features.

### Product Edition Capabilities

| Control | Free | Standard | Premium | Enterprise |
|---------|------|----------|---------|------------|
| MFA (individual two-step verification) | ✅ | ✅ | ✅ | ✅ |
| Project/space permission schemes | ✅ | ✅ | ✅ | ✅ |
| Basic product audit log | Basic | Basic | ✅ | ✅ |
| IP allowlisting (1.4) | ❌ | ❌ | ✅ | ✅ |
| Data residency (4.1) | ❌ | ❌ | ✅ | ✅ |

### Atlassian Guard Capabilities

| Control | No Guard | Guard Standard | Guard Premium |
|---------|----------|----------------|---------------|
| SAML SSO enforcement (1.1) | ❌ | ✅ | ✅ |
| Enforced authentication policies (1.1) | ❌ | ✅ | ✅ |
| SCIM user provisioning and deprovisioning | ❌ | ✅ | ✅ |
| Mobile app policies | ❌ | ✅ | ✅ |
| API token controls (1.3) | ❌ | ✅ | ✅ |
| Organization audit log (5.1) | ❌ | ✅ | ✅ |
| Data classification (4.2) | ❌ | ❌ | ✅ |
| Data security policies (4.3) | ❌ | Limited | ✅ |
| Anomalous activity detection (5.2) | ❌ | ❌ | ✅ |
| Content scanning | ❌ | ❌ | ✅ |
| SIEM webhook forwarding (5.1) | ❌ | ❌ | ✅ |

Source: [Atlassian Guard pricing](https://www.atlassian.com/software/access/pricing)

---

## Appendix B: References

**Official Atlassian Documentation:**
- [Trust Center](https://www.atlassian.com/trust) | [Customer Trust Center](https://customertrust.atlassian.com/) (powered by Conveyor)
- [Atlassian Support](https://support.atlassian.com/)
- [Security Best Practices](https://support.atlassian.com/security-and-access-policies/)
- [Security Practices](https://www.atlassian.com/trust/security/security-practices)
- [Security Measures](https://www.atlassian.com/legal/security-measures)
- [Vulnerability Disclosure](https://www.atlassian.com/trust/data-protection/vulnerabilities)
- [Security Advisories](https://www.atlassian.com/trust/security/advisories)
- [Atlassian Guard Pricing and Capabilities](https://www.atlassian.com/software/access/pricing) (product formerly named Atlassian Access)
- [Manage API Tokens for Your Atlassian Account](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/) (mandatory token expiry, 1 day to 1 year)
- [What Is a Data Security Policy?](https://support.atlassian.com/security-and-access-policies/docs/what-is-a-data-security-policy/)
- [Scope of IP Allowlists in Atlassian Cloud](https://support.atlassian.com/atlassian-cloud/kb/what-is-the-scope-of-ip-allowlists-in-atlassian-cloud/)

**API & Developer Tools:**
- [Atlassian Developer Portal](https://developer.atlassian.com/)
- [Jira Cloud REST API](https://developer.atlassian.com/cloud/jira/platform/rest/)
- [Confluence Cloud REST API](https://developer.atlassian.com/cloud/confluence/rest/)
- [Forge App Framework](https://developer.atlassian.com/platform/forge/) (SOC 2 and ISO 27001 compliant; preferred over Connect)
- [Connect End-of-Support Timeline](https://www.atlassian.com/blog/development/announcing-connect-end-of-support-timeline-and-next-steps) (descriptor freeze March 2026, end of support 31 January 2027)
- [API Security Guide](https://developer.atlassian.com/cloud/jira/platform/security/)
- [GitHub Organization](https://github.com/atlassian)

**Compliance Frameworks:**
- SOC 2 Type II (individual product audits on a regular basis) — via [SOC 2 Compliance](https://www.atlassian.com/trust/compliance/resources/soc2)
- ISO/IEC 27001:2022 (Atlassian Trust Management System) — via [ISO 27001 Compliance](https://www.atlassian.com/trust/compliance/resources/iso27001)
- SOX compliance, PCI DSS
- [Compliance Resource Center](https://www.atlassian.com/trust/compliance/resources) | [Compliance FAQ](https://www.atlassian.com/trust/compliance/compliance-faq)

**Security Incidents:**
- **2023 — Critical Confluence CVEs:** CVE-2023-22515 (CVSS 10.0) and CVE-2023-22518 (CVSS 9.8) affected Confluence Data Center/Server with broken access control and auth bypass vulnerabilities. Actively exploited in the wild. Cloud instances were not affected. ([Security Advisories](https://www.atlassian.com/trust/security/advisories))
- **February 2023 — Employee Data Leak via Envoy:** Hackers leaked Atlassian employee records and office floorplans obtained through a breach of third-party workplace platform Envoy. No customer data was affected. ([SecurityWeek Report](https://www.securityweek.com/atlassian-investigating-security-breach-after-hackers-leak-data/))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.4.0 | draft | Convert to the Atlassian platform Common Controls hub: add `platform`/`platform_slug`/`product` frontmatter, add "Products in This Platform" section and moved-controls callout. Merge org-level controls in from the product guides — domain verification, SSO enforcement policy with break-glass, and SCIM/JIT provisioning into §1.1; organization admin role limitation into §1.2. Point Jira project permissions at the Jira Cloud guide and note product-level log correlation in §5.1; remove empty Detection Queries heading | Claude Code (Opus 5) |
| 2026-08-03 | 0.3.0 | draft | Rename Atlassian Access to Atlassian Guard and split edition table into product vs Guard tiers; correct API token expiry to the 1-day-to-1-year platform ceiling with forced expiry of legacy tokens; add 1.4 IP allowlisting; add 4.3 data security policies; flag Connect framework end-of-support and prefer Forge | Claude Code (Sonnet 5) |
| 2026-06-29 | 0.2.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Atlassian hardening guide | Claude Code (Opus 4.5) |
| 2026-02-19 | 0.2.0 | draft | Extract inline code to Code Packs (api, sdk) | Claude Code (Opus 4.6) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
