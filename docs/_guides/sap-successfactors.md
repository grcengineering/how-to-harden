---
layout: guide
title: "SAP SuccessFactors Hardening Guide"
vendor: "SAP SuccessFactors"
slug: "sap-successfactors"
tier: "3"
category: "HR/Finance"
description: "HCM security for permission groups, integration center, data protection, and the SAP security-recommendations baseline"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---


## Overview

SAP SuccessFactors is a global enterprise HCM with deep SAP ecosystem integration. OData and SOAP APIs, OAuth client configurations, and SAP Business Technology Platform connections handle employee master data, payroll, and performance records across multinationals. Sub-processor data flows create complex third-party risk.

### Intended Audience
- Security engineers managing HCM systems
- SAP administrators configuring SuccessFactors
- GRC professionals assessing HR compliance
- Third-party risk managers evaluating SAP integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers SAP SuccessFactors security configurations including authentication, access controls, API security, data protection, monitoring, and the platform-hardening settings SAP ships disabled by default.

### Migration Notice — Identity Authentication, Deadline November 2026

SAP is retiring SuccessFactors' native SAML SSO. **SAP's stated final deadline for completing migration to SAP Cloud Identity Services — Identity Authentication (IAS) is November 2026 — roughly three months from this revision.** Identity Authentication is the target-state identity provider for SuccessFactors, and several controls in this guide (notably [1.3](#13-require-transactional-verification-for-critical-transactions) and the OIDC path in [2.3](#23-adopt-oidc-for-api-authentication)) are only available once it is in place. Treat the migration as the prerequisite project, not an optional modernization. See [1.1](#11-configure-sso-with-mfa).

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Security](#2-api-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)
5. [Platform Hardening](#5-platform-hardening)

---

## 1. Authentication & Access Controls

### 1.1 Configure SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Route all SuccessFactors authentication through SAP Cloud Identity Services — Identity Authentication (IAS) with multi-factor authentication enforced there, migrating off SuccessFactors' native SAML SSO before SAP's November 2026 deadline rather than continuing to configure the legacy path.

#### Rationale
**⚠ Deprecation — act before November 2026:**
SAP is retiring SuccessFactors' native SAML SSO in favour of SAP Cloud Identity Services — Identity Authentication. **SAP states that the final deadline for completing migration to Identity Authentication is November 2026**, which is approximately three months from this revision. Organizations still authenticating through the native SuccessFactors SAML configuration should treat this as an in-flight deadline, not a roadmap item: after migration, IAS becomes the identity provider of record and is the prerequisite for the transactional-verification step-up MFA in [1.3](#13-require-transactional-verification-for-critical-transactions) and for OIDC-based API authentication in [2.3](#23-adopt-oidc-for-api-authentication). Source: [Migration to SAP Cloud Identity Services — Identity Authentication](https://help.sap.com/docs/successfactors-platform/setting-up-sap-successfactors-with-identity-authentication-and-identity-provisioning-services/migration-to-sap-cloud-identity-services-identity-authentication-service).

**Why This Matters:**
- Centralizes SuccessFactors authentication in a single identity provider, applying MFA and conditional access to every login to the HCM platform
- Local SuccessFactors password logins bypass IdP controls and are prime targets for credential stuffing and phishing of HR and payroll staff
- SuccessFactors holds employee master data, payroll, and performance records for the entire workforce, so a single compromised admin login can expose the whole organization's PII
- Enforcing SSO ensures departed employees lose access the moment they are deprovisioned in the IdP, eliminating orphaned accounts with standing data access
- Migrating to Identity Authentication before the deadline avoids an authentication cutover executed under time pressure — the failure mode of a rushed identity migration is a temporary fallback to local passwords, which is precisely the exposure SSO exists to remove

**Attack Prevented:** Credential theft, phishing, MFA bypass, password spraying, orphaned-account access, fallback-to-local-password exposure during a rushed identity migration

#### ClickOps Implementation

**Step 1 (target state): Migrate to Identity Authentication**
1. Follow SAP's migration path to SAP Cloud Identity Services — Identity Authentication; complete it before the **November 2026** deadline
2. Establish the trust between Identity Authentication and your corporate IdP, and confirm SuccessFactors authenticates through IAS
3. Enforce MFA in Identity Authentication (or in the corporate IdP behind it) for all users, with phishing-resistant factors for administrators
4. Confirm the IAS-mediated login path works for every user population — including any that previously used a separate native SSO configuration — before disabling the legacy path

**Step 2 (legacy path — being retired): Native SuccessFactors SAML**
1. The current admin surface for the native configuration is **Admin Center → Manage SAML SSO Settings**
2. Configure IdP metadata and enable SSO enforcement here only to keep an existing deployment running while the IAS migration is in flight
3. Do not build new integrations or new user populations on this path — it is on a dated retirement track

**Step 3: Attribute Mapping and Sessions**
1. Map assertions to SuccessFactors users and configure attribute mapping in whichever provider is authoritative
2. Configure session management, and pair it with the concurrent-session restriction in [5.4](#54-restrict-concurrent-sessions-sf-hxm-0003)
3. Verify that local password login is not available as a fallback once SSO enforcement is active

#### Code Implementation

{% include pack-code.html vendor="sap-successfactors" section="1.1" %}

---

### 1.2 Role-Based Permissions (RBP)

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Implement SuccessFactors Role-Based Permissions so each user receives only the access their job requires, scoping permission roles and groups to defined target populations rather than broad system-wide access.

#### Rationale
**Why This Matters:**
- Least-privilege permission roles limit how much employee data any single account can reach, containing the blast radius of a compromised or misused login
- Target population scoping ensures managers and HR admins see only their assigned employees, not the entire workforce's sensitive records
- Over-provisioned System Admin accounts are high-value targets, so minimizing their number shrinks the attack surface for privilege abuse
- Properly scoped roles enforce separation of duties across payroll, performance, and personal-data functions, supporting audit and compliance requirements

**Attack Prevented:** Privilege escalation, insider data harvesting, unauthorized access to employee PII, separation-of-duties violations

#### ClickOps Implementation

**Step 1: Define Permission Roles**

| Role | Permissions |
|------|-------------|
| System Admin | Full access (limit users) |
| HR Admin | Employee data management |
| Manager | Team access only |
| Employee | Self-service only |

**Step 2: Configure Permission Groups**
1. Navigate to: **Admin Center → Manage Permission Roles**
2. Create permission groups
3. Assign target populations

#### Code Implementation

{% include pack-code.html vendor="sap-successfactors" section="1.2" %}

---

### 1.3 Require Transactional Verification for Critical Transactions

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-2(1), IA-11, AC-3

#### Description
Enable Identity Authentication transactional verification so that a user must pass an additional TOTP challenge at the moment they perform a designated critical transaction — specifically updating payment information in Employee Central and registering a new OIDC OAuth client in Security Center — rather than relying on the authentication they passed at the start of the session.

#### Rationale
**Why This Matters:**
- Session-level authentication proves who opened the session, not who is driving it now; a hijacked session, an unlocked workstation, or a phished session cookie all present as an already-authenticated user right up to the moment money moves
- Updating payment information in Employee Central is the single highest-value fraudulent action available in an HCM platform — direct-deposit redirection is the payoff for most HR-targeted phishing — and a step-up challenge at that exact transaction is a control the attacker cannot satisfy with a stolen session alone
- Registering a new OIDC OAuth client in Security Center is the persistence equivalent: a client registered by an attacker is a durable, non-interactive API credential that survives password resets and session revocation, so gating client registration behind step-up verification blocks the pivot from a single session to standing API access
- Binding the second factor to the transaction rather than the login means the protection scales with risk instead of friction: routine self-service is unaffected, and only the two actions that cause irreversible harm carry an extra prompt

**Attack Prevented:** Direct-deposit / payroll diversion fraud, session hijacking escalated into a financial transaction, unauthorized OAuth client registration for persistent API access

#### Prerequisites
- SAP Cloud Identity Services — Identity Authentication in place (see [1.1](#11-configure-sso-with-mfa)); transactional verification is an IAS capability, not a native SuccessFactors one
- **Admin Center → Manage SAML SSO Settings** access to enable the feature on the SuccessFactors side
- Users enrolled in a TOTP authenticator

#### ClickOps Implementation

**Step 1: Confirm the Identity Authentication Prerequisite**
1. Verify SuccessFactors authenticates through Identity Authentication — this control is unavailable on the legacy native SAML path
2. Confirm the affected users are enrolled in TOTP in Identity Authentication, since an unenrolled user cannot satisfy the challenge and will be blocked from the transaction

**Step 2: Enable Transactional Verification**
1. In **Admin Center → Manage SAML SSO Settings**, enable multi-factor transactional verification for critical transactions
2. Enable it for **updating payment information in Employee Central**
3. Enable it for **registering new OIDC OAuth clients in Security Center**

**Step 3: Communicate and Support**
1. Tell employees the extra prompt on payment-information changes is expected, so a genuine challenge is not mistaken for a broken workflow — and so an *absent* challenge becomes a reportable anomaly
2. Establish a support path for users who lose their TOTP device, since payment changes will be blocked until they re-enrol

#### Validation & Testing
- Attempt a payment-information change in Employee Central and confirm the TOTP challenge is presented before the change commits
- Attempt to register an OIDC OAuth client in Security Center and confirm the same
- Confirm that cancelling or failing the challenge leaves the original values unchanged

**Source:** [Enable Transactional Verification for Critical Transactions Using Multi-Factor Authentication](https://help.sap.com/docs/successfactors-platform/setting-up-sap-successfactors-with-identity-authentication-and-identity-provisioning-services/enable-transactional-verification-for-critical-transactions-using-multi-factor-authentication)

---

## 2. API Security

### 2.1 Secure OData API Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Harden OData API integrations.

#### Rationale
**Attack Scenario:** Compromised OAuth client accesses Compound Employee API; sub-processor data flows expose global workforce data.

**Why This Matters:**
- OData and Compound Employee APIs can return bulk employee master data, so a single over-permissioned OAuth client can exfiltrate the entire workforce dataset
- Dedicated OAuth clients per integration with minimum permissions limit each credential's reach and make abuse easier to detect and revoke
- Field-level and entity-level restrictions stop integrations from reading sensitive fields such as SSN or compensation they do not need
- Audit logging on API access provides the evidence trail needed to detect and investigate anomalous bulk extraction

**Attack Prevented:** Compromised OAuth client abuse, bulk employee-data exfiltration, sub-processor data leakage, over-broad API access

**⚠ Deprecation — Basic Authentication is being retired:**
SAP publishes an explicit order of preference for OData API authentication, and Basic Authentication is at the bottom of it and on the way out. SAP's documented precedence is:

| Preference | Mechanism | Status |
|-----------|-----------|--------|
| 1 (preferred) | OpenID Connect (OIDC) | Available where SAP Cloud Identity Services — Identity Authentication is in place; see [2.3](#23-adopt-oidc-for-api-authentication) |
| 2 | OAuth 2.0 with SAML Bearer Assertion | Supported; the correct target for integrations that cannot use OIDC |
| 3 (avoid) | Basic Authentication | SAP states it **has been deprecated and will soon be retired** |

Inventory every integration still presenting a username and password to the OData API and schedule its migration now — a retirement with no fixed public date is a worse planning position than a dated one, not a better one. Source: [SAP SuccessFactors API Reference Guide (OData V2) — Authentication](https://help.sap.com/docs/successfactors-platform/sap-successfactors-api-reference-guide-odata-v2/authentication).

#### Implementation

**Step 1: Create Integration Users**
1. Navigate to: **Admin Center → Manage OAuth2 Client Applications**
2. Create dedicated OAuth clients per integration
3. Assign minimum required permissions

**Step 2: Configure API Permissions**
1. Limit OData entity access
2. Configure field-level restrictions
3. Enable audit logging (see [5.5](#55-enable-api-audit-logs-sf-hxm-0007))

**Step 3: Retire Basic Authentication**
1. Inventory integrations authenticating with Basic Authentication
2. Migrate each to OIDC where Identity Authentication is available, otherwise to OAuth 2.0 with SAML bearer assertion
3. Remove the underlying API user credentials once the migration is verified, so the deprecated path cannot be silently re-used

#### Code Implementation

{% include pack-code.html vendor="sap-successfactors" section="2.1" %}

---

### 2.2 OAuth Token Management

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(13)

#### Description
Govern SuccessFactors API tokens through the levers SAP actually exposes — one dedicated OAuth client per integration, tightly bounded SAML assertion validity, and controlled token reissue — because the access-token lifetime itself is fixed by the platform and is not an administrator setting.

#### Rationale
**⚠ Correction — token lifetimes are fixed, not configurable:**
Earlier revisions of this guide presented an access-token / refresh-token expiration table as though the values were tunable per profile level. They are not. SuccessFactors issues API access tokens with a **fixed lifetime of 24 hours** (the token response reports `"expires_in": 86399`), and the **OAuth 2.0 SAML bearer assertion flow issues no refresh token at all** — a client obtains a new access token by presenting a new assertion, not by refreshing. There is no administrator setting, and no SuccessFactors API, that shortens this. Any control text, table, or automation claiming to set a SuccessFactors token lifetime is describing a different product surface. Source: [Requesting an Access Token](https://help.sap.com/docs/successfactors-platform/sap-successfactors-hcm-suite-sfapi-developer-guide/requesting-access-token).

**Why This Matters:**
- Because the 24-hour access-token lifetime cannot be shortened, the compensating controls are the ones that decide blast radius: what the token can reach, how many exist, and how fast one can be killed
- A dedicated OAuth client per integration means a leaked token is scoped to one integration's permissions and can be revoked by deleting that one client, instead of taking every integration down with it
- SAML assertion validity is the part of the chain you *do* control — a short assertion lifetime limits how long a captured assertion can be exchanged for fresh tokens, which is the actual replay path in this flow
- Since there is no refresh token to revoke, revocation means removing the client or its permissions; knowing that in advance is the difference between a five-minute containment and an hour spent looking for a setting that does not exist
- Requesting reissue explicitly (`new_token=true`) rather than reusing a cached token keeps integration behaviour predictable and avoids long-lived tokens accumulating in logs and configuration files

**Attack Prevented:** Token replay, stolen-assertion reuse, blast-radius expansion through shared integration credentials, slow revocation during incident response

#### Implementation

**Step 1: One OAuth Client Per Integration**
1. In **Admin Center → Manage OAuth2 Client Applications**, register a separate client for each integration rather than sharing one
2. Grant each client only the permissions its integration uses (see [2.1](#21-secure-odata-api-access))
3. Record which client belongs to which integration so revocation does not require guesswork under incident pressure

**Step 2: Bound the SAML Assertion**
1. Set the shortest assertion validity period the integration can tolerate — this is the controllable lifetime in the OAuth SAML bearer flow
2. Protect the signing key used to mint assertions with the same care as a long-lived credential, because that is effectively what it is

**Step 3: Control Token Reissue and Handling**
1. Have integrations request a fresh token explicitly (`new_token=true`) rather than depending on cached tokens of unknown age
2. Expect a 24-hour access-token lifetime and no refresh token; design retry and re-authentication logic around presenting a new assertion
3. Keep tokens out of logs, source control, and support tickets — with a fixed 24-hour lifetime, a leaked token is usable for the remainder of that window regardless of what you configure

**Step 4: Plan Revocation**
1. Document that revocation is performed by removing or de-permissioning the OAuth client, not by revoking a refresh token
2. Rehearse it, so an incident does not begin with a search for a nonexistent token-expiry control

#### Validation & Testing
- Request a token and confirm the response reports an `expires_in` value of approximately 86399 seconds and contains no refresh token
- Confirm each live integration maps to its own OAuth client
- Confirm that deleting a test client immediately stops that client's API access

---

### 2.3 Adopt OIDC for API Authentication

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-5, IA-8, AC-3

#### Description
Where SAP Cloud Identity Services — Identity Authentication is in place, authenticate OData API integrations with OpenID Connect, which SAP names as the preferred mechanism, and register those OIDC OAuth clients in Security Center behind transactional verification.

#### Rationale
**Why This Matters:**
- SAP's documented order of preference for OData API authentication puts OIDC first, ahead of OAuth 2.0 with SAML bearer assertion, and well ahead of Basic Authentication, which SAP states has been deprecated and will soon be retired — so OIDC is the only choice that is not already on a retirement track or a second-best fallback
- OIDC ties API authentication to the same Identity Authentication tenant that governs interactive login, so one identity provider governs both human and machine access instead of two parallel trust chains drifting apart
- Registering OIDC clients in Security Center concentrates machine credentials in one auditable place, which is what makes client registration a meaningful control point rather than a scattered configuration detail
- That concentration is why client registration itself deserves step-up MFA: a client registered by an attacker is durable, non-interactive API access that outlives a password reset — see [1.3](#13-require-transactional-verification-for-critical-transactions)
- Migrating now, alongside the November 2026 Identity Authentication deadline in [1.1](#11-configure-sso-with-mfa), avoids doing the identity migration and the API-authentication migration as two separate cutovers

**Attack Prevented:** Reliance on deprecated Basic Authentication, credential-based API access without identity-provider governance, unauthorized OAuth client registration, divergent human and machine trust chains

#### Prerequisites
- SAP Cloud Identity Services — Identity Authentication in place; OIDC is unavailable without it
- Security Center access to register OIDC OAuth clients
- Transactional verification enabled for client registration ([1.3](#13-require-transactional-verification-for-critical-transactions))

#### Implementation

**Step 1: Inventory Current API Authentication**
1. List every integration against the OData API and record which mechanism it uses today
2. Rank them: Basic Authentication first (deprecated, retiring), then OAuth 2.0 SAML bearer assertion, then anything already on OIDC
3. Migrate the Basic Authentication integrations first — they have a deadline someone else controls

**Step 2: Register OIDC Clients**
1. Register the integration as an OIDC OAuth client in Security Center
2. Expect a transactional-verification challenge at registration if [1.3](#13-require-transactional-verification-for-critical-transactions) is enabled; an *absent* challenge is a finding, not a convenience
3. Grant the client only the permissions the integration exercises, one client per integration ([2.2](#22-oauth-token-management))

**Step 3: Cut Over and Retire**
1. Move the integration to the OIDC flow and verify it in a non-production environment first
2. Remove the previous credentials — a deprecated Basic Authentication user left in place is an open path regardless of what the integration now uses
3. Record the client in your integration inventory so revocation is a lookup, not an investigation

#### Validation & Testing
- Confirm no integration still authenticates to the OData API with Basic Authentication
- Confirm each OIDC client appears in Security Center and maps to exactly one integration
- Confirm registering a new OIDC client prompts for transactional verification

**Source:** [SAP SuccessFactors API Reference Guide (OData V2) — Authentication](https://help.sap.com/docs/successfactors-platform/sap-successfactors-api-reference-guide-odata-v2/authentication)

---

## 3. Data Security

### 3.1 Configure Data Privacy

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Configure SuccessFactors Data Protection & Privacy features — personal-data handling, consent management, data retention, and field-level masking — to limit exposure of sensitive employee identifiers such as SSN and Tax ID.

#### Rationale
**Why This Matters:**
- Field-level masking of identifiers like SSN and Tax ID prevents broad internal exposure of the most sensitive employee data
- Consent management and retention controls reduce the volume of personal data held, shrinking breach impact and supporting GDPR and similar mandates
- Auditing access to sensitive fields creates the evidence needed to detect snooping or misuse by insiders
- Restricting who can view sensitive data enforces purpose limitation and least privilege over the most regulated data in the platform

**Attack Prevented:** Sensitive PII exposure, insider snooping, privacy and regulatory non-compliance, excessive data retention risk

#### ClickOps Implementation

**Step 1: Enable Data Protection**
1. Navigate to: **Admin Center → Data Protection & Privacy**
2. Configure:
   - Personal data handling
   - Consent management
   - Data retention

**Step 2: Field-Level Security**
1. Configure sensitive field masking
2. Restrict SSN/Tax ID visibility
3. Enable audit for sensitive data access

#### Code Implementation

{% include pack-code.html vendor="sap-successfactors" section="3.1" %}

---

## 4. Monitoring & Detection

### 4.1 Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable comprehensive SuccessFactors audit logging with appropriate retention so administrative actions, data access, and configuration changes are recorded for monitoring and investigation.

#### Rationale
**Why This Matters:**
- Comprehensive audit trails are the primary source of evidence for detecting unauthorized access to employee and payroll data
- Without retained logs, incidents go undetected and forensic investigation of a breach becomes impossible
- Recording administrative and configuration changes surfaces privilege misuse and tampering with security settings
- Retained logs support compliance attestations such as SOC 2 and ISO 27001 and meet breach-notification timelines

**Attack Prevented:** Undetected data access, repudiation, configuration tampering, delayed breach detection

#### ClickOps Implementation

**Step 1: Enable Audit Trail**
1. Navigate to: **Admin Center → Audit Logging**
2. Enable comprehensive logging
3. Configure retention

**Step 2: Enable Read Audit on Sensitive Personal Data**

Change auditing records what was modified; it says nothing about who *looked*. Read Audit closes that gap by logging read access to sensitive personal data — the only way to detect the most common insider pattern in an HCM system, which is browsing rather than editing.

1. Navigate to: **Admin Center → Read Audit Config**
2. Select the sensitive personal-data fields and the user populations to audit — Read Audit is opt-in per configuration, so nothing is logged until you scope it
3. Include Compound Employee API reads where the integration surface is in scope: read access through that API is supported by Read Audit, and it is the API most capable of bulk employee-data extraction ([2.1](#21-secure-odata-api-access))
4. Exclude technical/integration accounts deliberately and document why — a high-volume integration account will otherwise flood the audit with routine reads and bury the human activity you enabled the control to find. Excluding it is only defensible because that account's activity is governed separately by API audit logs ([5.5](#55-enable-api-audit-logs-sf-hxm-0007)) and per-integration OAuth clients ([2.2](#22-oauth-token-management))
5. Retrieve Read Audit reports on a defined cadence, not only after an incident

**Source:** [Setting Up Read Audit](https://help.sap.com/docs/successfactors-platform/implementing-and-managing-data-protection-and-privacy/setting-up-read-audit)

#### Detection Focus

{% include pack-code.html vendor="sap-successfactors" section="4.1" %}

---

### 4.2 Export Audit Logs to Your SIEM

**Profile Level:** L2 (Walk)
**NIST 800-53:** AU-6, AU-9, SI-4

#### Description
Retrieve SuccessFactors audit data through the SAP Audit Log Service — via its user interface for ad-hoc review and its API for scheduled retrieval — and forward it to your SIEM, mapping each SuccessFactors module to the corresponding audit category so events land in the right detection pipeline.

#### Rationale
**Why This Matters:**
- Audit data that stays inside SuccessFactors is only examined when somebody already suspects something; forwarded to a SIEM, it correlates with identity, endpoint, and network telemetry and can fire on its own
- The API retrieval path is what makes this durable — a control that depends on an administrator remembering to open a UI is a control that lapses quietly, whereas a scheduled export either runs or alerts
- Exporting to a system SuccessFactors administrators do not control preserves the audit trail against tampering by exactly the privileged accounts most worth auditing, and supports retention beyond what the platform holds
- Getting the module-to-category mapping right determines whether events are searchable at all: audit data filed under an unexpected category is functionally invisible to a SIEM rule written against the category you assumed
- Payroll and identity events in particular need to sit alongside IdP and endpoint data to detect the multi-stage sequences — session compromise, then permission change, then payment change — that no single system sees end to end

**Attack Prevented:** Delayed breach detection, audit-trail tampering by privileged insiders, undetected multi-stage attacks spanning identity and HCM, evidence loss through short in-platform retention

#### Prerequisites
- SAP Audit Log Service available for the SuccessFactors environment
- A SIEM ingestion path and credentials for the audit log retrieval API

#### Implementation

**Step 1: Identify What to Export**
1. Map each in-scope SuccessFactors module to its corresponding audit log category — this mapping determines where events appear on retrieval, and getting it wrong is the most common reason an expected event "isn't logged"
2. Confirm coverage of the highest-value categories: authentication and SSO, permission and role changes, payroll and payment-information changes, API access ([5.5](#55-enable-api-audit-logs-sf-hxm-0007)), and Read Audit output ([4.1](#41-audit-logging))

**Step 2: Retrieve**
1. Use the SAP Audit Log Service user interface for ad-hoc investigation and to validate that the expected events are present
2. Use the audit log retrieval API for scheduled, automated export into the SIEM — the UI is for humans, the API is the control
3. Alert on export failure; a silent gap in the feed is indistinguishable from a quiet week

**Step 3: Detect**
1. Write detections for the events in the Detection Focus above and in [4.1](#41-audit-logging)
2. Correlate SuccessFactors identity events with IdP events from Identity Authentication ([1.1](#11-configure-sso-with-mfa)) so a suspicious login and a subsequent permission or payment change are one alert, not two
3. Set retention in the SIEM to satisfy your investigation and regulatory window independent of platform retention

#### Validation & Testing
- Perform a known auditable action and confirm it appears in the SIEM within the expected interval
- Confirm the export job alerts on failure and on an unexpected drop in event volume
- Confirm SuccessFactors administrators cannot delete or alter the exported copy

---

## 5. Platform Hardening

SAP publishes a security-recommendations baseline for SuccessFactors — a numbered set of platform settings with recommended values. Several of the highest-value entries are **disabled by default**, so a tenant that has never been reviewed against the baseline is not merely unmapped; it is running without them. The controls below adopt those defaults-off gaps.

**Scope note on the identifiers:** the baseline covers more than the HXM suite. `SF-HXM-*` identifiers apply to SAP SuccessFactors HXM and are the ones referenced here. `SF-SR-*` identifiers apply to SmartRecruiters and `SF-PAY-*` to Employee Central Payroll — both out of scope for this guide, so do not assume an `SF-` recommendation applies to your SuccessFactors tenant without checking its prefix.

**Source for this section:** [SAP SuccessFactors Security Recommendations](https://help.sap.com/docs/successfactors-platform/implementing-security-features-for-sap-successfactors/sap-successfactors-security-recommendations)

---

### 5.1 Strengthen the Password Policy (SF-HXM-0006)

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(1)

#### Description
Configure the SuccessFactors password policy to meet SAP's own recommended values rather than leaving the shipped defaults in place — SAP rates this recommendation **critical**, the highest severity in its SuccessFactors baseline.

#### Rationale
**Why This Matters:**
- SAP classifies the password policy recommendation as critical, which is a strong signal from the vendor about which unreviewed default causes the most harm in practice
- Even in an SSO-first deployment, local passwords persist on break-glass accounts, integration-adjacent users, and populations that have not yet migrated — and those are precisely the accounts an attacker looks for when SSO blocks the front door
- A weak policy makes password spraying viable against an HCM tenant holding the entire workforce's PII and banking details, where a single successful guess is a data breach rather than a nuisance
- Password policy is a control that costs nothing to apply and is invisible until it is tested by an attack, so it is routinely left at default in tenants that are otherwise well managed

**Attack Prevented:** Password spraying, brute force, credential stuffing against non-SSO and break-glass accounts

#### ClickOps Implementation

**Step 1: Assess Against the Baseline**
1. Retrieve the current password policy configuration
2. Compare each parameter against the recommended value in SAP's security-recommendations baseline (SF-HXM-0006)
3. Record every deviation and whether it is deliberate

**Step 2: Apply**
1. Set each parameter to at least SAP's recommended value
2. Verify the policy applies to every user population, including administrators and any account exempt from SSO
3. Re-check after any tenant upgrade or migration, which is when policy values are most likely to be reset or bypassed

#### Validation & Testing
- Attempt to set a password that violates each tightened parameter and confirm rejection
- Confirm break-glass and non-SSO accounts are in scope of the policy

---

### 5.2 Enable Content Security Policy (SF-HXM-0001)

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-18, SI-10

#### Description
Enable the SuccessFactors Content Security Policy, which is **disabled by default**, so the browser refuses to execute or load resources from origins the policy does not allow.

#### Rationale
**Why This Matters:**
- CSP is off by default, so every SuccessFactors tenant that has never been reviewed against SAP's baseline is running without browser-side script controls entirely
- CSP is the control that converts a successful content-injection attempt into a blocked resource load — it does not prevent injection, it prevents the injected payload from reaching an attacker-controlled origin
- SuccessFactors pages render employee master data, compensation, and payroll information, so script executing in that context reads exactly what the logged-in user can read, on behalf of whoever injected it
- Because CSP is enforced by the browser rather than the application, it keeps working against injection paths the application's own input handling missed

**Attack Prevented:** Cross-site scripting, malicious resource injection, exfiltration of rendered HR data to attacker-controlled origins

#### ClickOps Implementation

**Step 1: Enable and Scope**
1. Enable Content Security Policy per SAP's security-recommendations baseline (SF-HXM-0001)
2. Enumerate the legitimate external origins your tenant genuinely requires — custom branding assets, embedded content, and integrated third-party tools are the usual sources of breakage
3. Allow those origins explicitly and nothing broader

**Step 2: Roll Out Carefully**
1. Validate in a test instance first: an over-tight policy breaks page rendering, and an over-broad one is theatre
2. Review the policy whenever new embedded content or a new integration is introduced

#### Validation & Testing
- Confirm the response carries the expected Content-Security-Policy header
- Confirm a resource from a non-allowed origin is blocked by the browser
- Confirm business-critical pages and any embedded content still render

---

### 5.3 Enable the Clickjacking Filter (SF-HXM-0002)

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-18

#### Description
Enable the SuccessFactors clickjacking protection filter so the application cannot be framed by an attacker-controlled page and used to trick an authenticated user into performing actions they cannot see.

#### Rationale
**Why This Matters:**
- Clickjacking requires nothing from the victim but a click on a page they already trust — the attacker borrows the victim's live SuccessFactors session rather than stealing a credential
- In an HCM context, the actions worth hijacking are approvals and personal-data changes, including the payment-information changes that [1.3](#13-require-transactional-verification-for-critical-transactions) is designed to protect; frame-based attacks are one of the routes that tries to reach them
- The filter is a platform setting in SAP's baseline rather than something an application team can add, so it is easy for it to belong to nobody and stay off
- It pairs with CSP ([5.2](#52-enable-content-security-policy-sf-hxm-0001)): both are browser-enforced and both fail silently when absent, which is why they need explicit verification rather than assumption

**Attack Prevented:** Clickjacking, UI redress attacks, framed-session abuse of approvals and personal-data changes

#### ClickOps Implementation

**Step 1: Enable**
1. Enable the clickjacking filter per SAP's security-recommendations baseline (SF-HXM-0002)
2. Identify any legitimate embedding of SuccessFactors in a portal or intranet frame before enabling, and allow only those specific origins
3. Validate in a test instance first

#### Validation & Testing
- Attempt to load SuccessFactors inside an iframe from an unapproved origin and confirm it is refused
- Confirm any approved embedding still works

---

### 5.4 Restrict Concurrent Sessions (SF-HXM-0003)

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-10

#### Description
Enable the SuccessFactors restriction on concurrent sessions so a single user account cannot hold multiple simultaneous logins.

#### Rationale
**Why This Matters:**
- Concurrent-session restriction turns account sharing and session theft into a visible event: the legitimate user is displaced instead of coexisting silently with the attacker
- Without it, a stolen session can run indefinitely alongside the real user's, and neither the user nor the audit trail gives an obvious signal that two parties are using one identity
- It is an especially cheap control for administrator and payroll accounts, where the population is small, genuine multi-device use is rare, and the value of the account is highest
- It complements session timeout rather than duplicating it: timeout bounds how long a session lives, concurrency bounds how many exist

**Attack Prevented:** Session hijacking, credential sharing, undetected parallel use of a compromised account

#### ClickOps Implementation

**Step 1: Enable**
1. Enable the concurrent-session restriction per SAP's security-recommendations baseline (SF-HXM-0003)
2. Apply it at minimum to administrator, HR, and payroll populations
3. Identify legitimate multi-session workflows first — shared kiosk or shift-based access patterns are the usual conflict — and resolve them with separate accounts rather than by disabling the control

#### Validation & Testing
- Log in as a test user, then log in again from a second browser or device, and confirm the platform enforces the restriction
- Confirm no business-critical workflow depends on one account holding two live sessions

---

### 5.5 Enable API Audit Logs (SF-HXM-0007)

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3, AU-12

#### Description
Enable SuccessFactors API audit logging so OData and SFAPI calls are recorded, giving integration activity the same evidentiary trail as interactive administration.

#### Rationale
**Why This Matters:**
- API access is the highest-volume, lowest-visibility path to employee data in SuccessFactors: the Compound Employee API can return the entire workforce in a single well-formed request, and without API audit logs that request leaves no trace distinguishable from routine integration traffic
- Interactive audit logging covers what administrators do in the UI; a compromised OAuth client does not use the UI, so UI-scoped logging is blind to precisely the attack path [2.1](#21-secure-odata-api-access) and [2.2](#22-oauth-token-management) exist to constrain
- API audit logs are what make the per-integration OAuth client model useful for detection as well as containment — one client per integration only helps identify the culprit if calls are attributed
- They also provide the baseline that makes anomalous volume legible: without a record of normal integration behaviour, a bulk extraction has nothing to look abnormal against

**Attack Prevented:** Undetected bulk data extraction via API, unattributed OAuth client abuse, evidence gaps in integration-borne incidents

#### ClickOps Implementation

**Step 1: Enable**
1. Enable API audit logs per SAP's security-recommendations baseline (SF-HXM-0007)
2. Confirm coverage of both OData and SFAPI surfaces in use
3. Configure retention to match your investigation window

**Step 2: Route and Monitor**
1. Export the logs to your SIEM ([4.2](#42-export-audit-logs-to-your-siem))
2. Alert on request volume or entity access outside each integration's established pattern, and on calls from a client outside its expected schedule or source

#### Validation & Testing
- Make a test API call and confirm it appears in the audit log attributed to the correct OAuth client
- Confirm a Compound Employee API read is captured
- Confirm the logs reach the SIEM

---

### 5.6 Enable Interstitial Redirect Pages and Active Content Detection (SF-HXM-0009, SF-HXM-0010)

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-18, SI-3, SI-10

#### Description
Enable the interstitial page shown before SuccessFactors redirects a user to an external destination (SF-HXM-0009), and enable active content detection on uploaded content (SF-HXM-0010) so files carrying executable content are identified rather than served as-is.

#### Rationale
**Why This Matters:**
- Open or unannounced redirects let an attacker borrow SuccessFactors' trusted domain to launch a phishing page: the victim clicks a link inside the HR system they trust and lands somewhere else, with no moment of doubt in between — the interstitial supplies exactly that moment
- SuccessFactors is an unusually effective launch point for that trick because employees are conditioned to act on links from HR about pay, benefits, and required actions
- Attachments and uploaded content in an HCM platform — résumés, forms, supporting documents — arrive routinely from outside the organization, so an upload path without active content detection is an externally reachable file-delivery channel
- Both settings are baseline items rather than defaults, so absence is the normal state and has to be corrected deliberately

**Attack Prevented:** Phishing via trusted-domain redirect, open-redirect abuse, delivery of malicious active content through document upload

#### ClickOps Implementation

**Step 1: Enable Interstitial Redirect Pages**
1. Enable interstitial redirect pages per SAP's security-recommendations baseline (SF-HXM-0009)
2. Confirm that redirects to genuinely external destinations present the interstitial

**Step 2: Enable Active Content Detection**
1. Enable active content detection per SAP's security-recommendations baseline (SF-HXM-0010)
2. Test with a benign file containing active content to confirm detection behaves as expected
3. Confirm legitimate document workflows — attachments, résumé uploads, supporting documentation — still function

#### Validation & Testing
- Follow a link to an external destination and confirm the interstitial appears
- Upload a benign file containing active content and confirm it is detected
- Confirm normal uploads are unaffected

---

### 5.7 Enable Input Security Scan on Pre-July-2023 Systems (SF-HXM-0004)

**Profile Level:** L2 (Walk)
**NIST 800-53:** SI-10

#### Description
Confirm that input security scanning is enabled — for systems provisioned **before July 2023**, this is an explicit action, because those tenants were not created with it on.

#### Rationale
**Why This Matters:**
- This is an age-dependent gap: newer tenants are covered, older ones are not, and nothing in the running system distinguishes the two — which makes it precisely the kind of setting a security review skips because the platform "looks the same"
- The tenants affected are the long-lived ones, which are also the ones carrying the most accumulated employee data and the most custom configuration
- Input scanning is a server-side control, so it covers injection paths that browser-enforced controls like CSP ([5.2](#52-enable-content-security-policy-sf-hxm-0001)) cannot reach
- Verification is cheap and one-off; the cost of assuming it is on is an injection surface nobody is watching

**Attack Prevented:** Injection through unscanned user input on legacy tenants

#### ClickOps Implementation

**Step 1: Determine Applicability**
1. Establish when your SuccessFactors instance was provisioned
2. If it predates July 2023, treat input security scan as off until proven otherwise

**Step 2: Enable and Verify**
1. Enable input security scan per SAP's security-recommendations baseline (SF-HXM-0004)
2. Validate in a test instance first — input scanning can reject content that existing custom configuration or data-load processes previously accepted
3. Recheck after migrations between instances, which can carry legacy configuration forward

#### Validation & Testing
- Confirm the setting is enabled in every instance provisioned before July 2023, including non-production copies
- Confirm existing data-load and custom-field workflows still succeed

---

## Appendix B: References

**Official SAP SuccessFactors Documentation:**
- [SAP SuccessFactors Platform Documentation](https://help.sap.com/docs/SAP_SUCCESSFACTORS_PLATFORM)
- [SAP SuccessFactors Security Recommendations](https://help.sap.com/docs/successfactors-platform/implementing-security-features-for-sap-successfactors/sap-successfactors-security-recommendations) — the 41-row platform baseline behind [section 5](#5-platform-hardening)
- [Migration to SAP Cloud Identity Services — Identity Authentication](https://help.sap.com/docs/successfactors-platform/setting-up-sap-successfactors-with-identity-authentication-and-identity-provisioning-services/migration-to-sap-cloud-identity-services-identity-authentication-service) — the November 2026 migration deadline in [1.1](#11-configure-sso-with-mfa)
- [Enable Transactional Verification for Critical Transactions Using Multi-Factor Authentication](https://help.sap.com/docs/successfactors-platform/setting-up-sap-successfactors-with-identity-authentication-and-identity-provisioning-services/enable-transactional-verification-for-critical-transactions-using-multi-factor-authentication) — source for [1.3](#13-require-transactional-verification-for-critical-transactions)
- [Setting Up Read Audit](https://help.sap.com/docs/successfactors-platform/implementing-and-managing-data-protection-and-privacy/setting-up-read-audit) — read-access logging in [4.1](#41-audit-logging)

**API & Developer Resources:**
- [SAP SuccessFactors APIs](https://api.sap.com/products/SAPSuccessFactors/apis/all)
- [OData V2 API Reference — Authentication](https://help.sap.com/docs/successfactors-platform/sap-successfactors-api-reference-guide-odata-v2/authentication) — the OIDC > OAuth SAML assertion > Basic Authentication precedence and the Basic Authentication deprecation
- [Requesting an Access Token](https://help.sap.com/docs/successfactors-platform/sap-successfactors-hcm-suite-sfapi-developer-guide/requesting-access-token) — the fixed 24-hour access-token lifetime and the absence of a refresh token in the SAML bearer flow

**Compliance & Certifications:**
- SAP's attestation status is published through the SAP Trust Center, which is a compliance-attestation surface rather than hardening documentation and is deliberately not cited here as a control source. Request current attestations directly from SAP.
- No Tier 2 baseline covers SAP SuccessFactors: no CIS Benchmark, DISA STIG, or CISA SCuBA baseline exists for the platform. SAP's own security-recommendations baseline ([section 5](#5-platform-hardening)) is the closest equivalent and is a Tier 1 vendor source.

**Security Incidents:**
- No major public security breaches specific to SAP SuccessFactors have been identified. SAP was designated a Critical ICT Third-Party Service Provider (CTPP) by European Supervisory Authorities in November 2025, reflecting its systemic importance to financial sector digital infrastructure.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Major currency pass. **Deprecations:** rewrote 1.1 around SAP's retirement of native SuccessFactors SAML SSO — SAP's final deadline for completing migration to SAP Cloud Identity Services — Identity Authentication is November 2026, roughly three months out — demoting the legacy path and correcting the admin surface to **Manage SAML SSO Settings**; added SAP's documented OData authentication precedence to 2.1 (OIDC > OAuth 2.0 SAML bearer assertion > Basic Authentication, which SAP states has been deprecated and will soon be retired). **Error correction:** 2.2 previously presented a 1h access / 24h–8h refresh token table as if those were tunable SuccessFactors settings. They are not — SuccessFactors issues access tokens with a fixed 24-hour lifetime (`"expires_in": 86399`) and the OAuth SAML bearer flow issues no refresh token at all. The control was rewritten around what is actually controllable: per-integration OAuth clients, SAML assertion validity, explicit `new_token=true` reissue, and client-deletion revocation. **Pack deletion (fabrication-class):** `packs/sap-successfactors/terraform/hth-sap-successfactors-2.02-oauth-token-management.tf` encoded those same fabricated lifetimes as SAP BTP XSUAA service-instance parameters — the wrong product surface entirely, automating a setting SuccessFactors does not expose. It was deleted rather than rescoped because no documented SuccessFactors token-lifetime API exists to rescope it to; 2.2's Code Implementation heading and include were removed with it, and `docs/_data/packs/sap-successfactors.yml` was regenerated. **New controls:** 1.3 (Identity Authentication transactional verification — step-up TOTP before updating payment information in Employee Central and before registering new OIDC OAuth clients in Security Center), 2.3 (OIDC adoption for API authentication), 4.2 (SAP Audit Log Service export to SIEM via UI and API, with module-to-category mapping), and a new **section 5, Platform Hardening**, adopting the defaults-off gaps from SAP's own 41-row security-recommendations baseline: 5.1 password policy (SF-HXM-0006, SAP-rated critical), 5.2 Content Security Policy (SF-HXM-0001, disabled by default), 5.3 clickjacking filter (SF-HXM-0002), 5.4 restrict concurrent sessions (SF-HXM-0003), 5.5 API audit logs (SF-HXM-0007), 5.6 interstitial redirect pages and active content detection (SF-HXM-0009, SF-HXM-0010), 5.7 input security scan for pre-July-2023 systems (SF-HXM-0004), with a scope note that `SF-SR-*` is SmartRecruiters and `SF-PAY-*` is EC Payroll. **Additions:** Read Audit (read-access logging on sensitive personal data, Compound Employee API support, deliberate technical-account exclusion) added to 4.1. **References:** purged the two sap.com Trust Center links; kept the live security-recommendations reference and added the OData authentication, access-token, migration, transactional-verification, and Read Audit sources. **Convention fix:** removed the forbidden `lang="terraform"` parameter from the pack includes at 1.1, 1.2, 2.1, and 3.1. Tier 2 bodies surveyed with zero coverage confirmed: no CIS Benchmark, DISA STIG, or CISA SCuBA baseline exists for SAP SuccessFactors. Tier 3/4 product-specific research not surveyed this pass. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial SAP SuccessFactors hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
