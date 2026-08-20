---
layout: guide
title: "NetSuite Hardening Guide"
vendor: "NetSuite"
slug: "netsuite"
tier: "2"
category: "Data"
description: "ERP security for role-based access, SuiteScript controls, and integration hardening"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

NetSuite serves **43,000+ customers** with the SuiteCloud platform hosting **600+ SuiteApp integrations**. Token-based authentication (TBA) for third-party apps, if not rotated quarterly, creates persistent access to financial records, customer payment data, and inventory systems. As a cloud ERP containing financial data, NetSuite is a high-value target for attackers seeking billing fraud or financial data exfiltration.

### Intended Audience
- Security engineers hardening ERP systems
- Finance IT administrators
- GRC professionals assessing financial system compliance
- Third-party risk managers evaluating SuiteApp integrations

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers NetSuite security configurations including authentication, SuiteApp governance, token management, and financial data protection.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Token-Based Authentication Security](#2-token-based-authentication-security)
3. [SuiteApp & Integration Security](#3-suiteapp--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require 2FA for all NetSuite users, especially those with financial data access.

#### Rationale
**Why This Matters:**
- 2FA blocks account takeover even when a NetSuite password is phished, reused, or leaked in a breach
- Administrator and Financial Controller roles can move money, alter records, and export financial data, so a single compromised login is catastrophic
- A short session timeout limits the window an attacker has on an unattended or hijacked session

**Attack Prevented:** Credential stuffing, phishing, password reuse, session hijacking

> **Changed default (2026.1) — multiple concurrent sessions are opt-in and 2FA-gated.** NetSuite's Multiple Sessions per User capability is not enabled automatically: an administrator must turn it on explicitly, and once it is on, every role in the account must be configured as 2FA-required. Treat it as a deliberate risk decision rather than a convenience toggle — more simultaneously live sessions per user means more sessions an attacker can ride, and the 2FA prerequisite is the only thing holding that surface closed. ([NetSuite 2026.1 Release Notes — Authentication](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_158921905537.html))

#### ClickOps Implementation

**Step 1: Configure 2FA**
1. Navigate to: **Setup → Company → Two-Factor Authentication**
2. Enable: **Require 2FA for all roles**
3. Configure methods:
   - Authenticator app (recommended)
   - SMS (not recommended)
   - Email (backup only)

**Step 2: Role-Based 2FA**
1. Navigate to: **Setup → Users/Roles → Manage Roles**
2. For each role, configure:
   - **Require Two-Factor Authentication:** Yes

**Step 3: Configure Session Timeout**
1. Navigate to: **Setup → Company → General Preferences**
2. Set: **Session timeout:** 30 minutes (L1) / 15 minutes (L2)

---

### 1.2 Implement Role-Based Access Control

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure NetSuite roles with least-privilege access to financial data.

#### Rationale
**Why This Matters:**
- Least-privilege roles limit the blast radius when any single account is compromised
- Segregation of duties prevents one user from both creating and approving payments or journal entries, closing off fraud paths
- Subsidiary and report restrictions stop lateral access to financial data outside a user's responsibility

**Attack Prevented:** Privilege escalation, insider fraud, unauthorized financial data access, lateral movement

#### ClickOps Implementation

**Step 1: Design Role Structure**
1. Inventory the roles currently assigned in your account and the users holding each one
2. Map each role to a single job function, and record the minimum permissions that function actually requires
3. Identify the conflicting permission pairs you must never combine in one role — payment creation with payment approval, journal entry creation with posting
4. Record which subsidiaries and reports each role legitimately needs, so restrictions can be applied in Step 2

**Step 2: Configure Role Permissions**
1. Navigate to: **Setup → Users/Roles → Manage Roles**
2. For each role:
   - Select specific permissions
   - Restrict subsidiary access
   - Limit report access

**Step 3: Implement Segregation of Duties**
- Separate payment creation from approval
- Separate journal entry creation from posting
- Document and monitor conflicting roles

---

### 1.3 Configure IP Address Rules

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3(7)

#### Description
Restrict NetSuite access to known IP addresses.

#### Rationale
**Why This Matters:**
- IP allowlisting blocks logins from unexpected geographies and networks even when valid credentials are stolen
- Restricting sensitive roles to corporate or VPN egress IPs adds a network-layer control on top of authentication
- Approved integration IPs ensure API access only originates from sanctioned systems

**Attack Prevented:** Stolen-credential reuse, remote brute force, unauthorized API access from rogue hosts

#### ClickOps Implementation

**Step 1: Configure IP Address Rules**
1. Navigate to: **Setup → Company → Company Information → Access**
2. Add IP address rules:
   - Corporate network ranges
   - VPN egress IPs
   - Approved integration IPs

**Step 2: Role-Based IP Restrictions**
1. Navigate to: **Setup → Users/Roles → Manage Roles**
2. For sensitive roles (Administrator, Financial Controller):
   - Configure specific IP restrictions

---

### 1.4 Display a Login Notification and Track Acknowledgements

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-8, AU-2

#### Description
Use the Login Notification feature introduced in NetSuite 2026.1 to present a compliance or acceptable-use message that users must acknowledge at login, and use the recorded acknowledgements as evidence.

#### Rationale
**Why This Matters:**
- A pre-access notice establishes that use of the account is monitored and governed, which is what makes later enforcement and disciplinary action defensible
- NetSuite records each acknowledgement with its date and time in the Login Audit Trail, turning a policy statement into per-user, timestamped evidence for auditors
- Regulated finance environments are routinely asked to demonstrate that users were informed of monitoring and handling obligations before touching financial records — this control produces that proof as a by-product of normal logins

**Attack Prevented:** Repudiation of policy awareness, unmonitored-use claims during investigation, audit evidence gaps

#### ClickOps Implementation

**Step 1: Enable and Author the Notification**
1. Navigate to: **Setup → Company → General Preferences**
2. Enable the Login Notification and enter the message users must acknowledge
3. Keep the text aligned with the acceptable-use and monitoring language your legal or compliance team has approved

**Step 2: Verify Acknowledgements Are Being Recorded**
1. Confirm the Login Audit Trail is enabled ([4.2](#42-audit-trail-configuration))
2. Confirm acknowledgement entries appear there with their date and time
3. Retain the audit trail export alongside your other access-control evidence

> **Availability:** Login Notification ships in NetSuite 2026.1. Confirm your account is on 2026.1 or later before writing this control into a runbook. ([NetSuite 2026.1 Release Notes — Authentication](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_158921905537.html))

---

## 2. Token-Based Authentication Security

### 2.1 Secure TBA Configuration

**Profile Level:** L1 (Crawl) - CRITICAL
**NIST 800-53:** IA-5

#### Description
Harden Token-Based Authentication (TBA) for API integrations.

#### Rationale
**Why This Matters:**
- TBA tokens provide persistent API access that survives password changes and does not expire on its own
- Static tokens stay valid indefinitely without a rotation process, so a token leaked into a config file, a script, or a ticket keeps working for years
- A single compromised integration token is enough to extract financial statements, customer records, and payment data through SuiteTalk or a RESTlet

**Attack Prevented:** Persistent token compromise, unauthorized API access to financial records, credential replay, data exfiltration via integration accounts

> **Deprecation — new integrations lose TBA in 2027.1.** As of NetSuite 2027.1, **newly created integrations cannot use Token-based Authentication** with SOAP web services, REST web services, or RESTlets. Existing integrations already using TBA continue to work, and this control still governs them; but every new integration must be built on OAuth 2.0 ([2.2](#22-oauth-20-for-suiteapps)), and Oracle recommends migrating existing TBA integrations to OAuth 2.0 rather than waiting. Treat any TBA integration you build today as work you have already committed to redo. ([NetSuite 2026.1 Release Notes — Authentication](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_158921905537.html))

#### ClickOps Implementation

**Step 1: Audit Existing Tokens**
1. Navigate to: **Setup → Users/Roles → Access Tokens**
2. Review all active tokens:
   - Creation date
   - Associated user/role
   - Integration purpose
3. Identify tokens older than 90 days

**Step 2: Create Role-Specific Integration Users**
1. Create dedicated integration users:
   - `INT-Salesforce` (CRM sync)
   - `INT-Payroll` (payroll export)
   - `INT-Reporting` (BI tool)
2. Assign minimal required permissions

**Step 3: Implement Token Rotation**

| Token Type | Rotation Frequency |
|------------|--------------------|
| Production integrations | Quarterly |
| Development tokens | Monthly |
| One-time exports | Immediately after use |

**Step 4: Configure TBA Settings**
1. Navigate to: **Setup → Company → Enable Features → SuiteCloud**
2. Review: **Token-Based Authentication**
3. Limit: Who can create tokens (Administrators only)

---

### 2.2 OAuth 2.0 for SuiteApps

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(13)

#### Description
Build every new NetSuite integration on OAuth 2.0 rather than Token-based Authentication, and migrate existing TBA integrations onto OAuth 2.0.

#### Rationale
**Why This Matters:**
- OAuth 2.0 issues short-lived access tokens, shrinking the value and lifespan of any leaked credential
- Token refresh enables revocation without re-provisioning the integration, unlike static TBA tokens
- Scoped authorization grants limit each SuiteApp to only the data and actions it needs
- From NetSuite 2027.1 this is no longer a preference: new integrations cannot be created with TBA against SOAP web services, REST web services, or RESTlets, so any new integration built on TBA today is committed rework

**Attack Prevented:** Persistent token compromise, over-privileged integrations, credential replay

> **This is now the required path for new integrations.** NetSuite 2027.1 ends support for creating new TBA integrations against SOAP, REST, and RESTlets; existing TBA integrations keep working but Oracle recommends migrating them to OAuth 2.0. ([NetSuite 2026.1 Release Notes — Authentication](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_158921905537.html))

#### Implementation

For new integrations:
1. Use the OAuth 2.0 authorization code grant flow — with PKCE, which becomes mandatory in 2027.1 ([2.3](#23-require-pkce-on-the-oauth-20-authorization-code-flow))
2. Configure short token lifetimes
3. Implement token refresh

For existing TBA integrations:
1. Inventory every integration record still authenticating with TBA (see [2.1](#21-secure-tba-configuration) Step 1)
2. Schedule each one for OAuth 2.0 migration ahead of 2027.1, prioritising integrations that touch financial or payment data
3. Retire the TBA tokens once the OAuth 2.0 path is verified in production

---

### 2.3 Require PKCE on the OAuth 2.0 Authorization Code Flow

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-5(13), SC-8

#### Description
Implement PKCE (Proof Key for Code Exchange) parameters on every OAuth 2.0 authorization code grant integration, ahead of NetSuite 2027.1 making PKCE mandatory for all newly created integrations — public and confidential clients alike.

#### Rationale
**Why This Matters:**
- Without PKCE, an intercepted authorization code can be redeemed by anyone who captures it; PKCE binds the code to the client that requested it, so a stolen code is useless on its own
- NetSuite 2027.1 requires PKCE for all newly created OAuth 2.0 authorization code integrations, including confidential clients that historically relied on a client secret alone — an integration built without it will simply not be creatable
- Adopting PKCE before the cutover removes a forced, deadline-driven change to production integrations that hold access to financial data

**Attack Prevented:** Authorization code interception and replay, malicious client impersonation during the OAuth handshake

#### Implementation

1. In your integration's authorization request, generate a per-request code verifier and send its transformed value as the code challenge
2. Send the original code verifier on the token exchange so NetSuite can bind the code to your client
3. Apply this to confidential clients too — the 2027.1 requirement does not exempt them because they hold a client secret
4. Re-test each integration end to end before 2027.1 rather than after

> **Effective 2027.1 for newly created integrations.** Existing integrations are not retroactively broken, but any integration created after the cutover must supply PKCE parameters. ([NetSuite 2026.1 Release Notes — Authentication](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_158921905537.html))

---

### 2.4 Manage Integration Record Certificates and Rotation

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-5, SC-12

#### Description
Govern the client credentials certificates attached to each integration record — NetSuite 2026.1 caps them at five active certificates per record — and automate rotation through the Client Credentials Certificate Rotation Endpoint instead of managing certificates by hand.

#### Rationale
**Why This Matters:**
- Certificates accumulate silently on integration records; a five-certificate cap means an unmanaged record can reach its limit and block a legitimate rotation at exactly the wrong moment
- Every active certificate on a record is an independent way to authenticate as that integration, so stale certificates that were never revoked are standing credentials nobody is watching
- The Client Credentials Certificate Rotation Endpoint gives this control a real programmatic surface — listing, creating, and revoking certificates can run on a schedule, which is what makes a rotation policy hold over time rather than lapsing after the first quarter

**Attack Prevented:** Abuse of stale or orphaned integration certificates, unrevoked credential persistence, failed rotation due to hitting the certificate cap

#### Implementation

**Step 1: Inventory Certificates per Integration Record**
1. Enumerate the active certificates on each integration record and record their issue dates and owners
2. Flag any record at or near the five active certificate limit — it cannot accept a new certificate until one is revoked

**Step 2: Rotate Programmatically**
1. Use the Client Credentials Certificate Rotation Endpoint to list, create, and revoke certificates for a given integration record
2. Create the replacement certificate first, cut the integration over, then revoke the old one — never revoke before the new certificate is proven in production
3. Schedule the rotation job on the same cadence as the token rotation table in [2.1](#21-secure-tba-configuration), so certificates and tokens do not drift onto different schedules

**Step 3: Keep the Cap Clear**
1. Revoke superseded certificates as part of every rotation rather than leaving them active
2. Alert when any record reaches four active certificates, before a rotation is blocked

> **Availability:** the five active certificates per integration record limit and the Client Credentials Certificate Rotation Endpoint both ship in NetSuite 2026.1. ([NetSuite 2026.1 Release Notes — Authentication](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_158921905537.html))

---

### 2.5 Govern Dynamic Client Registration and Redirect URIs

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-7, AC-3

#### Description
Restrict who may register OAuth 2.0 clients now that NetSuite 2026.1 supports Dynamic Client Registration (DCR), and review the redirect URIs on every integration record — 2026.1 also allows multiple redirect URIs per authorization code grant integration.

#### Rationale
**Why This Matters:**
- Dynamic Client Registration lets clients register themselves rather than waiting on an administrator, which is convenient and also means new OAuth clients can appear in the account without anyone deciding they should exist
- Multiple redirect URIs per integration widen where an authorization code can legitimately be sent; each additional URI is another destination an attacker would find useful to add, and a permissive or forgotten entry turns the OAuth flow into a code-delivery service for someone else
- Both changes expand the OAuth surface at the same time, so the countermeasure is inventory and review — knowing which clients exist, who registered them, and exactly which URIs each one is allowed to redirect to

**Attack Prevented:** Unauthorized OAuth client registration, authorization code redirection to attacker-controlled endpoints, silent expansion of integration access

#### Implementation

**Step 1: Restrict Who May Register Clients**
1. Limit the roles and users permitted to create integration records or use Dynamic Client Registration to a named administrative group
2. Require the same change-management approval for a dynamically registered client that you require for a SuiteApp installation ([3.1](#31-suiteapp-approval-workflow))

**Step 2: Enumerate and Review Redirect URIs**
1. List the redirect URIs configured on every OAuth 2.0 authorization code grant integration record
2. Confirm each URI is a host you control, uses HTTPS, and is still in use — remove entries that exist only because someone was testing
3. Re-run this review on the same cadence as your integration access review, and after any integration change

**Step 3: Alert on New Registrations**
1. Monitor for newly created integration records and treat an unexpected one as a security event, not a housekeeping item (see [5.1](#51-security-alerts))

> **Availability:** Dynamic Client Registration and support for multiple redirect URIs both ship in NetSuite 2026.1. ([NetSuite 2026.1 Release Notes — Authentication](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_158921905537.html))

---

## 3. SuiteApp & Integration Security

### 3.1 SuiteApp Approval Workflow

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Implement approval process for SuiteApp installations.

#### Rationale
**Why This Matters:**
- SuiteApps run with the permissions you grant them, so an unvetted bundle can read or exfiltrate financial and customer data
- A review gate catches excessive permission requests and untrusted vendors before code reaches production
- Restricting installation to Administrators and requiring change approval prevents silent introduction of malicious or vulnerable code

**Attack Prevented:** Supply chain compromise, malicious bundle installation, over-privileged third-party access

#### ClickOps Implementation

**Step 1: Review Installed SuiteApps**
1. Navigate to: **Customization → SuiteBundler → Search & Install Bundles**
2. Review installed bundles:
   - Installation date
   - Permissions required
   - Business justification

**Step 2: Create Approval Process**
Before installing any SuiteApp:
- Review bundle permissions
- Check vendor security certifications
- Evaluate data access requirements
- Document business justification
- Test in sandbox first

**Step 3: Restrict Installation**
1. Limit bundle installation to Administrators
2. Require change management approval
3. Document all installations

---

### 3.2 RESTlet and SuiteScript Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-7

#### Description
Secure custom RESTlets and SuiteScripts.

#### Rationale
**Why This Matters:**
- RESTlets are internet-facing endpoints that, if unauthenticated or poorly validated, expose financial records directly
- Custom SuiteScript that trusts user input can leak data or perform unauthorized actions under elevated governance
- Scoping scripts to least privilege limits what a compromised or buggy customization can reach

**Attack Prevented:** Injection through custom endpoints, unauthorized data access, privilege abuse via scripts

#### Best Practices

{% include pack-code.html vendor="netsuite" section="3.2" %}

---

## 4. Data Security

### 4.1 Field-Level Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3

#### Description
Restrict access to sensitive financial fields.

#### Rationale
**Why This Matters:**
- Field-level restrictions keep credit card numbers, bank details, SSNs, and salary data hidden from roles that don't need them
- Limiting exposure reduces both insider misuse and the data available to any compromised account
- Encrypting sensitive fields protects data at rest and supports PCI DSS and privacy obligations

**Attack Prevented:** Sensitive data exposure, insider data theft, PCI/PII compliance violations

#### ClickOps Implementation

**Step 1: Identify Sensitive Fields**
- Credit card numbers
- Bank account details
- SSN/Tax IDs
- Salary information

**Step 2: Configure Field Restrictions**
1. Navigate to: **Customization → Forms → Entry Forms**
2. For sensitive fields:
   - Hide from unauthorized roles
   - Enable encryption where available

---

### 4.2 Audit Trail Configuration

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2

#### Description
Enable comprehensive audit trails for financial transactions.

#### Rationale
**Why This Matters:**
- System notes and login audit trails create the forensic record needed to investigate fraud and unauthorized changes
- Comprehensive logging is a SOX and SOC 2 requirement for financial systems
- Tamper-evident history deters insider manipulation and supports accountability for every transaction change

**Attack Prevented:** Undetected tampering, repudiation of fraudulent changes, audit and compliance gaps

#### ClickOps Implementation

**Step 1: Configure System Notes**
1. Navigate to: **Setup → Company → General Preferences**
2. Enable: **System Notes for all transactions**

**Step 2: Configure Login Audit Trail**
1. Navigate to: **Setup → Company → Enable Features → SuiteCloud**
2. Enable: **Login Audit Trail**

---

## 5. Monitoring & Detection

### 5.1 Security Alerts

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SI-4

#### Description
Configure NetSuite saved searches to alert on suspicious activity such as failed logins, privilege changes, and anomalous data access.

#### Rationale
**Why This Matters:**
- Detection turns NetSuite's audit data into actionable alerts so incidents are caught in time to respond
- Monitoring failed logins, permission changes, and token usage surfaces account compromise and privilege abuse early
- Without alerting, fraudulent transactions and data exfiltration can continue undetected for long periods

**Attack Prevented:** Undetected account compromise, slow-burn fraud, unmonitored data exfiltration

#### ClickOps Implementation

**Step 1: Build the Detection Saved Searches**
1. Create saved searches over the Login Audit Trail for failed login bursts against a single user and for successful logins from unexpected locations ([4.2](#42-audit-trail-configuration) enables the underlying data)
2. Create saved searches over System Notes for permission and role changes, and for the creation of new integration records or access tokens ([2.5](#25-govern-dynamic-client-registration-and-redirect-uris))
3. Scope each search to the roles and subsidiaries that matter rather than the whole account, so the alert volume stays readable

**Step 2: Route the Alerts**
1. Configure each saved search to email or notify a monitored security address on a schedule
2. Assign an owner for each alert and define what a real response looks like — an unowned alert is not detection

---

## 6. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | NetSuite Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | 2FA enforcement | 1.1 |
| CC6.2 | Role-based access | 1.2 |
| CC8.1 | Change management | 3.1 |

### SOX Compliance

- Implement segregation of duties
- Enable comprehensive audit trails
- Document access approvals
- Regular access reviews

---

## Appendix A: References

**Official NetSuite Documentation:**
- [NetSuite Product Documentation](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/index.html)
- [Account Administration — Authentication](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/book_4299752196.html) — password policy, session management, IP address rules, 2FA, SAML/OIDC SSO, TBA, and OAuth 2.0 configuration
- [Getting Started with Token-based Authentication](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_4247337262.html)
- [NetSuite 2026.1 Release Notes — Authentication](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_158921905537.html) — Login Notification, certificate limits and rotation endpoint, multiple sessions 2FA requirement, DCR, multiple redirect URIs, PKCE and TBA end-of-support dates

**API Documentation:**
- [SuiteTalk REST Web Services](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/book_1559132836.html)
- [SuiteScript 2.x API Reference](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/set_1502135122.html)

**Compliance Frameworks:**
- NetSuite is assessed against SOC 1 Type II, SOC 2 Type II, ISO 27001, ISO 27018, PCI DSS, and TX-RAMP. Attestation reports are obtained from Oracle under NDA rather than from a public page; request them through your account team.

**Security Incidents:**
- No major public security incidents specific to Oracle NetSuite identified. NetSuite operates within Oracle's broader security infrastructure. Monitor Oracle's [Security Alerts](https://www.oracle.com/security-alerts/) for current advisories.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | ai-drafted | 2026.1/2027.1 currency pass: TBA end-of-support callout in 2.1 and 2.2 promoted to L1 as the required path for new integrations; new controls 1.4 (Login Notification), 2.3 (PKCE), 2.4 (integration certificate limits and rotation endpoint), 2.5 (Dynamic Client Registration and redirect URIs); multiple-sessions 2FA callout in 1.1; fixed 2.1's Rationale so the control renders in the cheat sheet again; populated the empty 1.2 role-design and 5.1 detection steps; replaced the 404 Security Best Practices link with the Authentication book and removed Trust Center/marketing references. Tier 2: no CIS Benchmark, DISA STIG, or CISA SCuBA baseline covers NetSuite — the scope of the CIS Oracle Cloud/SaaS Applications work relative to NetSuite remains unresolved and is worth re-checking next pass. Tier 3/4 not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | ai-drafted | Initial NetSuite hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
