---
layout: guide
title: "UKG Pro Hardening Guide"
vendor: "UKG"
slug: "ukg"
tier: "2"
category: "HR/Finance"
description: "HCM platform hardening for UKG Pro including SAML SSO configuration, authentication upgrade features, and access controls"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

UKG (Ultimate Kronos Group) Pro is a leading cloud-based human capital management platform serving **thousands of organizations** worldwide. As a repository for sensitive employee data, payroll, and workforce management, UKG Pro security configurations directly impact data protection and compliance.

### Intended Audience
- Security engineers managing HR systems
- HR administrators configuring UKG Pro
- IT administrators managing SSO integration
- GRC professionals assessing HCM security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers UKG Pro security including SAML SSO, authentication features, role-based access control, and session security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Data Protection](#3-data-protection)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Integration & API Security](#5-integration--api-security)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for UKG Pro users.

#### Rationale
**Why This Matters:**
- Centralizes UKG Pro authentication in your corporate IdP, enforcing MFA and conditional access on every login
- Local UKG passwords bypass IdP controls and are a prime target for credential stuffing and phishing
- IdP-driven lifecycle (SCIM/provisioning) deprovisions departed employees automatically, closing standing access to payroll and HR data
- UKG Pro holds SSNs, salaries, and direct-deposit banking details — a single compromised login can expose an entire workforce

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access

#### Prerequisites
- Contact UKG Pro support to enable SAML SSO
- Include UFSSO@ukg.com in communications
- Obtain ACS URL and Entity ID from UKG

#### ClickOps Implementation

**Step 1: Request SSO Enablement**
1. Contact your UKG Pro SSO Engineer
2. Include UFSSO@ukg.com in recipient list
3. If no assigned engineer, email UFSSO@ukg.com
4. Request SAML SSO enablement and configuration values

**Step 2: Configure Identity Provider**
1. Create SAML application in IdP (Okta, Entra, etc.)
2. Configure with UKG-provided ACS URL and Entity ID
3. Download IdP certificate and metadata

**Step 3: Send Configuration to UKG**
1. Send Certificate (Base64) to UKG support
2. Send SSO URL and configuration
3. UKG configures SAML SSO connection on their side

**Step 4: Test and Verify**
1. Test SSO authentication
2. Verify proper user mapping
3. Enable for production users

**Time to Complete:** ~1-2 weeks (includes UKG support coordination)

---

### 1.2 Configure Multiple Identity Providers

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Configure multiple IdPs for different user populations.

#### Rationale
**Why This Matters:**
- Organizations formed by merger or operating across separate legal entities often run more than one IdP; forcing them through a single federation usually ends in a local-password exception that bypasses IdP-enforced MFA entirely
- UKG's Authentication Upgrade supports multiple IdPs, each reached by its own vanity URL, so each population authenticates against the directory that actually governs its lifecycle — joiners and leavers are deprovisioned by the right system
- Every additional IdP is also an additional trusted issuer: an unowned or over-scoped IdP connection is a full authentication bypass, so each one needs a named owner, documented user population, and the same MFA and conditional-access baseline as the primary

**Attack Prevented:** SSO bypass via local-password exceptions, orphaned access from unmanaged directories, authentication bypass through an over-scoped or unowned IdP trust

#### ClickOps Implementation

**Step 1: Plan IdP Structure**
1. Identify user populations
2. Determine IdP requirements per population
3. Document vanity URL needs

**Step 2: Configure Additional IdPs**
1. Work with UKG SSO team
2. Configure each IdP separately
3. Test each configuration

---

### 1.3 Configure Single Logout (SLO)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Enable IdP-initiated Single Logout (SLO) so signing out of UKG Pro terminates the underlying identity provider session as well, rather than leaving it live.

#### Rationale
**Why This Matters:**
- UKG supports IdP Single Logout for SAML 2.0; without it, "logging out" of UKG Pro ends only the application session while the IdP session stays authenticated, so anyone at that browser can sign straight back in
- On shared and kiosk workstations — common in healthcare, retail, and manufacturing where UKG is heavily deployed — a surviving IdP session hands the next person at the terminal another user's payroll, banking, and PII access
- Complete logout across systems is also what makes session termination a usable incident-response action: during a suspected compromise you need one action that actually ends access, not one that ends a single tab

**Attack Prevented:** Session reuse on shared workstations, incomplete-logout session hijacking, persistence after a revocation or offboarding action

> **Terminology correction (2026-08-08):** an earlier revision of this control expanded SLO as "Service Level Objective." In this context SLO is **Single Logout**, the SAML 2.0 profile — a Service Level Objective is an unrelated reliability metric.

#### ClickOps Implementation

**Step 1: Configure SLO in IdP**
1. Enable SLO in identity provider
2. Configure logout URL
3. Test logout functionality

**Step 2: Verify SLO**
1. Test complete logout flow
2. Verify IdP session terminated
3. Verify UKG session terminated

---

### 1.4 Configure SAML Response Signing

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Sign the SAML response as well as the assertion, using strong algorithms, so the identity provider's messages cannot be forged or tampered with in transit.

#### Rationale
**Why This Matters:**
- An unsigned SAML response is unauthenticated data the service provider is asked to trust: an attacker who can modify the browser-relayed message can alter or substitute identity claims and authenticate as another user
- Signing the assertion alone still leaves the enclosing response mutable, which is why signing both closes the gap that assertion-only signing leaves open — UKG Workforce Central v8.1.2+ required exactly this
- Weak signature algorithms undermine the whole mechanism; SHA-256 or stronger is the floor, and certificate expiry must be tracked because an expired signing certificate breaks federated sign-in and pressures teams into re-enabling password fallback

**Attack Prevented:** SAML response forgery and tampering, authentication bypass via assertion substitution, downgrade to weak signature algorithms

> **Product-scope note (2026-08-08):** the specific version requirement above comes from **UKG Workforce Central**, which no longer appears in UKG's current product documentation surface. If your organization runs Workforce Central, verify these steps against your own version's documentation. The underlying principle — sign both the response and the assertion, with SHA-256 or stronger — is product-neutral and applies to any SAML federation, including UKG Pro; configure it at the identity provider.

#### ClickOps Implementation

**Step 1: Configure IdP Signing** (applies to any SAML federation, UKG Pro included)
1. Enable SAML response signing in IdP
2. Enable SAML assertion signing
3. Use strong signing algorithms (SHA-256 or stronger)
4. Track the signing certificate's expiry date outside the IdP so renewal is scheduled rather than discovered as an outage

**Step 2: Verify Configuration**
1. Test authentication flow
2. Verify signatures validated
3. Document configuration

---

## 2. Access Controls

### 2.1 Configure Role-Based Access Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using UKG's role model.

#### Rationale
**Why This Matters:**
- Least-privilege roles ensure each user sees only the employee data and functions their job actually requires
- Over-broad roles let ordinary users reach payroll, compensation, and PII far beyond their need to know
- Separating HR and Payroll administrative duties prevents any single account from both editing pay rates and approving disbursements
- Regular access reviews catch role creep and stale access from transfers and terminations before it becomes a breach path

**Attack Prevented:** Privilege escalation, insider data misuse, excessive data exposure, payroll fraud

#### ClickOps Implementation

**Step 1: Review Security Roles**
1. Review predefined roles
2. Understand role capabilities
3. Document role assignments

**Step 2: Apply Least Privilege**
1. Assign minimum necessary access
2. Separate HR and Payroll admin functions
3. Avoid over-assigning admin roles

**Step 3: Regular Access Reviews**
1. Quarterly access reviews
2. Review terminated employees
3. Update role assignments

---

### 2.2 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### Rationale
**Why This Matters:**
- Administrator accounts can alter security settings, reassign roles, and access every employee record in the tenant
- Each additional admin widens the attack surface and the blast radius of a single compromised credential
- Requiring MFA on all admins blocks takeover from phished or reused passwords
- Monitoring admin activity surfaces unauthorized configuration changes and suspicious bulk data access early

**Attack Prevented:** Account takeover, privilege abuse, unauthorized configuration change, lateral movement

#### ClickOps Implementation

**Step 1: Inventory Admin Users**
1. Review all admin accounts
2. Document admin access levels
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit admin accounts to 2-3 users
2. Require MFA for all admins
3. Monitor admin activity

---

### 2.3 Configure System Settings Security

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Configure system security settings.

#### Rationale
**Why This Matters:**
- System security settings govern SSO enforcement, session behavior, and tenant-wide authentication policy
- Insecure or default settings can leave password fallback paths and weak session controls active alongside SSO
- Restricting SuperUser-level configuration access prevents unauthorized changes to the platform's security posture
- A hardened baseline reduces drift and keeps security controls enforced after upgrades and changes

**Attack Prevented:** Security misconfiguration, SSO bypass, unauthorized settings change, weak session handling

#### ClickOps Implementation

> **Product-scope note (2026-08-08):** the console path below is **UKG Workforce Central**, which no longer appears in UKG's current product documentation surface. If your organization runs Workforce Central, verify these steps against your own version. For UKG Pro and UKG Workforce Management tenants, the equivalent security-configuration surface is reached through **System Configuration** → **Security**, which is also where the integration controls in [section 5](#5-integration--api-security) live — start there.

**Product-neutral requirement:** review the tenant's security settings on a schedule, restrict who can change them to a named, minimal group, and confirm after every upgrade that SSO enforcement and session controls survived the change. Configuration drift after upgrades is the common failure mode.

**For UKG Workforce Central:**
1. Log on as SuperUser
2. Navigate to: **Setup** → **System Configuration** → **System Settings**
3. Click **Security** tab
4. Configure SSO and security settings

**For UKG Pro / Workforce Management:**
1. Navigate to: **System Configuration** → **Security**
2. Review the security settings available to your tenant, including service account and web services administration (see [5.1](#51-harden-web-service-accounts) and [5.3](#53-inventory-every-authentication-mechanism))
3. Restrict who holds configuration access, and re-review after each release

---

## 3. Data Protection

### 3.1 Configure Data Access Controls

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control access to sensitive employee data.

#### Rationale
**Why This Matters:**
- UKG Pro stores highly sensitive fields including SSNs, salaries, and direct-deposit banking details
- Field-level and role-based restrictions ensure users only see the data their role legitimately requires
- Classifying data by sensitivity drives proportionate controls and supports privacy and compliance obligations
- Auditing data access creates accountability and detects unusual viewing of high-value PII

**Attack Prevented:** Sensitive data exposure, PII leakage, insider snooping, privacy violations

#### ClickOps Implementation

**Step 1: Classify Data**
1. Identify sensitive fields (SSN, salary, etc.)
2. Classify by sensitivity level
3. Document classification

**Step 2: Apply Access Controls**
1. Restrict access based on role
2. Limit sensitive data visibility
3. Audit data access

---

### 3.2 Configure Report Security

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control access to HR reports and analytics.

#### Rationale
**Why This Matters:**
- Reports and analytics can aggregate sensitive HR and payroll data into a single exportable view
- Unrestricted report access lets users assemble and exfiltrate large datasets beyond their day-to-day need
- Limiting export capabilities reduces the risk of bulk PII leaving the platform via spreadsheets and downloads
- Monitoring report generation detects abnormal extraction patterns that signal data theft

**Attack Prevented:** Bulk data exfiltration, unauthorized reporting, mass PII export, insider data theft

#### ClickOps Implementation

**Step 1: Review Report Access**
1. Audit report permissions
2. Identify sensitive reports
3. Restrict as needed

**Step 2: Configure Controls**
1. Apply role-based access
2. Limit export capabilities
3. Monitor report generation

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs.

#### Rationale
**Why This Matters:**
- Audit logs of authentication, data access, and configuration changes are the primary evidence for detecting and investigating incidents
- Without comprehensive logging, account compromise and insider misuse can go unnoticed for long periods
- Capturing admin actions and config changes supports tamper detection and change accountability
- Retained logs satisfy SOC 2, ISO 27001, and similar compliance evidence requirements

**Attack Prevented:** Undetected breach, log tampering, concealed insider activity, delayed incident response

#### ClickOps Implementation

**Step 1: Provision Audit Retrieval Access**
1. Create a dedicated web service account for audit retrieval (see [5.1](#51-harden-web-service-accounts)) — do not reuse an integration account that already carries write permissions.
2. Grant it access to the **personnel** API only, read methods only.
3. Record the account, its API key, and its owner in your integration inventory.

**Step 2: Retrieve Audit Records Programmatically**

UKG Pro exposes audit data through the personnel v1 API rather than through a console log viewer. The [`/personnel/v1/audit-details`](https://developer.ukg.com/hcm/docs/web-service-account) endpoint returns audit records for retrieval by a web service account with the appropriate permission.

1. Call `/personnel/v1/audit-details` with the audit-retrieval account's credentials and its `US-Customer-Api-Key` header.
2. Schedule regular pulls and forward the results into your SIEM — the API is the collection mechanism; retention and correlation are yours.
3. Alert on the event classes below rather than reviewing raw pulls by hand.

**Step 3: Monitor These Event Classes**
1. Authentication events — especially repeated failures and successes from new locations
2. Sensitive data access — SSN, compensation, and direct-deposit fields
3. Configuration and security-setting changes
4. Administrative actions and role assignments
5. Web service account activity, including volume anomalies against the baseline for each integration

#### Validation & Testing
Make a known change (for example, a test role assignment), then confirm it appears in a subsequent `/personnel/v1/audit-details` pull and in your SIEM.

---

## 5. Integration & API Security

### 5.1 Harden Web Service Accounts

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-6, IA-5 |

#### Description
Create purpose-scoped web service accounts for every UKG Pro integration, grant each one only the API resources and methods it actually calls, and inventory the endpoints those accounts can reach.

#### Rationale
**Why This Matters:**
- Web service accounts are how integrations read UKG Pro data programmatically, and each one carries its own API key plus a five-character `US-Customer-Api-Key` header value — a leaked pair is standing, unattended access to employee records at machine speed
- Permissions are granted **per resource and per method**, so an account provisioned for a single read can be — and often is — handed far broader reach than the integration needs; UKG's own guidance is to "only grant access to the API resources and actions a web service account will use"
- Shared or undocumented service accounts make revocation guesswork: when a vendor relationship ends or a key leaks, you cannot disable what you cannot attribute, and disabling a shared account breaks unrelated integrations

**Attack Prevented:** Bulk PII exfiltration via a leaked API key, over-permissioned integration abuse, unattributable standing access, supply-chain pivot from a compromised integration partner

#### ClickOps Implementation

**Step 1: Create a Dedicated Account per Integration**
1. Navigate to: **System Configuration** → **Security** → **Service Account Administration**
2. Create one account per integration — never one shared account across several
3. Record the owner, business purpose, and vendor for each

**Step 2: Apply Per-Resource, Per-Method Permissions**
1. For each account, grant only the API resources the integration calls
2. Within each resource, grant only the methods it uses — read-only wherever the integration does not write
3. Re-verify against the vendor's actual call list rather than the permissions they request

**Step 3: Protect the Credentials**
1. Each account has its own API key; the `US-Customer-Api-Key` header carries a five-character customer key
2. Store both in a secrets manager, never in code, tickets, or vendor email
3. Rotate on a schedule and immediately on staff or vendor change

**Step 4: Inventory the Exposed Endpoints**
1. Navigate to: **System Configuration** → **Security** → **Web Services**
2. Record which endpoints are enabled and which accounts can reach them
3. Disable anything no live integration depends on

#### Validation & Testing
For each account, attempt a call to a resource it should not reach and confirm the request is refused. Review the endpoint inventory quarterly against the live integration list.

---

### 5.2 Manage the WFM OAuth Token Lifecycle

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.8 |
| NIST 800-53 | AC-12, IA-5(13) |

#### Description
Understand and operationalize UKG Workforce Management's OAuth token lifetimes and revocation semantics — in particular that revoking an access token does **not** revoke its paired refresh token.

#### Rationale
**Why This Matters:**
- **The revocation asymmetry is the control:** revoking an access token does **not** revoke the refresh token paired with it, while revoking a refresh token **does** revoke the access tokens issued from it. An incident responder who revokes access tokens has not contained anything — the refresh token mints new ones. Revoke refresh tokens.
- Refresh tokens are valid for **7 days** (**8 hours** for federated accounts), so a stolen refresh token is a week of unattended access unless it is explicitly revoked; access tokens follow the `expires_in` value returned at issuance (documented example: roughly 30 minutes)
- A user may hold **multiple tokens simultaneously**, and each requires its own revocation call — a single revoke leaves the others live, which is the quiet way a containment action fails

**Attack Prevented:** Failed incident containment via incomplete revocation, refresh-token abuse, persistent API access after credential compromise or offboarding

#### ClickOps Implementation

**Step 1: Document the Lifetimes**
1. Record, per integration, the `expires_in` value returned with its access tokens
2. Record refresh-token validity: 7 days standard, 8 hours for federated accounts
3. Confirm that anyone on the incident rotation knows these numbers before they need them

**Step 2: Write the Revocation Runbook**
1. **Revoke refresh tokens first** — this revokes the access tokens issued from them
2. Enumerate **all** tokens held by the affected user or integration and issue a separate revocation call for each
3. Verify containment by confirming subsequent API calls fail, not by assuming the first revoke succeeded
4. For federated accounts, note the shorter 8-hour refresh window when scoping the exposure period

**Step 3: Reduce Standing Token Exposure**
1. Prefer OAuth over Basic authentication for every integration that supports it (see [5.3](#53-inventory-every-authentication-mechanism))
2. Revoke refresh tokens as part of vendor offboarding, not only during incidents
3. Rotate client credentials on the same schedule as web service account keys ([5.1](#51-harden-web-service-accounts))

#### Validation & Testing
In a test tenant, revoke an access token and confirm a new one can still be obtained with the refresh token; then revoke the refresh token and confirm both paths fail. Rehearse this before you need it in an incident.

---

### 5.3 Inventory Every Authentication Mechanism

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 1.1, 6.3 |
| NIST 800-53 | CM-8, IA-2 |

#### Description
Inventory all of the authentication mechanisms UKG exposes simultaneously across its APIs, decide which are live in your tenant, and reduce reliance on the weaker ones.

#### Rationale
**Why This Matters:**
- UKG's developer documentation describes **four authentication mechanisms operating in parallel**: HCM REST (Basic authentication plus the `US-Customer-Api-Key` header), OAuth 2.0 for Recruiting and Onboarding, the SOAP Login Service issuing XML tokens, and RaaS `BIDataService` XML — hardening the one you know about leaves the other three untouched
- Basic authentication sends a reusable credential on every call and has no revocation semantics beyond changing the password, so a captured header is durable access; SOAP and RaaS surfaces are frequently older, less monitored, and outside whatever logging was built for the REST integrations
- You cannot revoke, rotate, or monitor a mechanism you have not enumerated — the inventory is what makes every other control in this section actually cover the tenant

**Attack Prevented:** Access via an unmonitored legacy authentication surface, credential replay against Basic-authenticated endpoints, gaps in revocation and logging coverage

#### ClickOps Implementation

**Step 1: Enumerate What Is Live**

| Mechanism | Where it is used | Action |
|-----------|------------------|--------|
| HCM REST — Basic auth + `US-Customer-Api-Key` header | UKG Pro HCM REST integrations | Inventory every consuming integration; scope per [5.1](#51-harden-web-service-accounts); rotate credentials on a schedule |
| OAuth 2.0 | Recruiting and Onboarding APIs | Prefer for new integrations; apply the token lifecycle in [5.2](#52-manage-the-wfm-oauth-token-lifecycle) |
| SOAP Login Service (XML tokens) | Legacy SOAP integrations | Confirm whether any live integration still requires it; disable or restrict if not |
| RaaS `BIDataService` (XML) | Report-as-a-Service data extracts | Treat as a bulk-export surface; restrict which accounts can reach it and monitor extract volume |

**Step 2: Reduce the Surface**
1. Prefer OAuth wherever the API supports it
2. Limit Basic-authenticated and SOAP integrations to those with a documented business need and a named owner
3. Ensure every mechanism you keep is covered by the audit collection in [4.1](#41-configure-audit-logging)

**Step 3: Keep the Inventory Current**
1. Re-run the enumeration whenever an integration is added, replaced, or retired
2. Include the mechanism type in your integration inventory so revocation runbooks know which procedure applies

#### Validation & Testing
For each mechanism you believe is disabled, attempt an authenticated call and confirm it fails. For each you keep, confirm its activity appears in your SIEM.

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | UKG Pro Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [2.1](#21-configure-role-based-access-control) |
| CC6.6 | SLO | [1.3](#13-configure-single-logout-slo) |
| CC6.1 | Web service account scoping | [5.1](#51-harden-web-service-accounts) |
| CC6.3 | OAuth token revocation | [5.2](#52-manage-the-wfm-oauth-token-lifecycle) |
| CC7.1 | Authentication mechanism inventory | [5.3](#53-inventory-every-authentication-mechanism) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | UKG Pro Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-6 | RBAC | [2.1](#21-configure-role-based-access-control) |
| AC-12 | SLO | [1.3](#13-configure-single-logout-slo) |
| SC-12 | SAML signing | [1.4](#14-configure-saml-response-signing) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |
| IA-5 | Web service account credentials | [5.1](#51-harden-web-service-accounts) |
| AC-12 | OAuth token lifetime and revocation | [5.2](#52-manage-the-wfm-oauth-token-lifecycle) |
| CM-8 | Authentication mechanism inventory | [5.3](#53-inventory-every-authentication-mechanism) |

---

## Appendix A: References

**Official UKG Documentation:**
- [Web Service Account (UKG HCM developer docs)](https://developer.ukg.com/hcm/docs/web-service-account) -- service account creation, per-resource/per-method permissions, API key and `US-Customer-Api-Key` header handling; the primary verified source for [5.1](#51-harden-web-service-accounts)
- [Authentication and Security (UKG WFM developer docs)](https://developer.ukg.com/wfm/docs/authentication-and-security-doc) -- OAuth token lifetimes and revocation semantics; the primary verified source for [5.2](#52-manage-the-wfm-oauth-token-lifecycle)
- [Authentication and Authorization (UKG developer docs)](https://developer.ukg.com/general/docs/authentication-and-authorization) -- the parallel authentication mechanisms enumerated in [5.3](#53-inventory-every-authentication-mechanism)
- [UKG Developer Hub](https://developer.ukg.com/)
- [UKG Community Portal](https://community.ukg.com/)
- Contact: UFSSO@ukg.com for SSO configuration
- [UKG Pro SSO Documentation](https://library.ukg.com/a/183581) -- serves a PDF binary; the document is live but its contents could not be text-verified in this pass
- [Microsoft Entra Integration](https://learn.microsoft.com/en-us/entra/identity/saas-apps/ultipro-tutorial) -- verified live and corroborates the SAML SSO configuration flow in [1.1](#11-configure-saml-single-sign-on); note that it still lists a legacy `ultimatesoftware.com` support contact, whereas this guide uses UFSSO@ukg.com

> **Documentation access note (2026-08-08):** `developer.ukg.com` is UKG's open first-party documentation surface and is the Tier 1 source for this guide's integration controls. `library.ukg.com` serves PDF binaries rather than HTML, `community.ukg.com` is a Salesforce single-page-application shell that returns no article content to fetchers, and `www.ukg.com` returns HTTP 403.

**Compliance Frameworks:**
- UKG publishes SOC and ISO attestations for its own services. Scope and currency change over time and are stated in the attestation reports themselves -- request the current reports from UKG or your account team rather than relying on a summarized list. A vendor attestation does not evidence any of the tenant-side controls in this guide.

**Security Incidents:**
- **December 2021 -- Kronos Private Cloud Ransomware Attack:** UKG suffered a ransomware attack on its Kronos Private Cloud (KPC) platform, disrupting payroll and workforce management services for over 8,000 organizations including hospitals and Fortune 500 companies (MGM Resorts, PepsiCo, Tesla). The outage lasted several weeks. UKG agreed to a $6 million class action settlement and committed to expanded scanning, monitoring, and cold storage backup improvements.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass against UKG's developer documentation. Added section 5 Integration & API Security with 5.1 web service accounts (Service Account Administration, per-resource/per-method permissions, API key plus the five-character `US-Customer-Api-Key` header, endpoint inventory under Web Services), 5.2 WFM OAuth token lifecycle (7-day refresh tokens, 8 hours for federated accounts, and the revocation asymmetry — revoking an access token does not revoke its paired refresh token, while revoking a refresh token does revoke its access tokens; multiple tokens require separate calls), and 5.3 the inventory of UKG's four parallel authentication mechanisms (HCM REST Basic + API-key header, Recruiting/Onboarding OAuth 2.0, SOAP Login Service XML tokens, RaaS `BIDataService`). Compliance Quick Reference renumbered 5 → 6. Rewrote 4.1 around the real programmatic audit surface (`/personnel/v1/audit-details`, reachable via a web service account) in place of abstract steps. **Error fixed:** 1.3 expanded SLO as "Service Level Objective"; corrected to Single Logout (SAML 2.0). Annotated 1.4 and 2.3 as UKG Workforce Central scope — WFC no longer appears in UKG's current product documentation, so both now carry a verify-against-your-version note and product-neutral guidance for UKG Pro/WFM tenants; no EOL date asserted. Added the missing **Attack Prevented** lines to 1.2, 1.3, and 1.4 and upgraded their feature-note rationale bullets into risk rationale. Appendix A: removed trustcenter.ukg.com and both ukg.com ESG links, re-sourced the compliance claim honestly, added the three verified developer.ukg.com references, and annotated the library.ukg.com PDF and Entra tutorial with their verification status. Tier 2 survey: no CIS Benchmark, DISA STIG, or CISA SCuBA baseline exists for UKG (confirmed zero). Tier 3/4 not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with SSO, RBAC, and security controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
