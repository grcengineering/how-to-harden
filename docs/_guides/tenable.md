---
layout: guide
title: "Tenable Hardening Guide"
vendor: "Tenable"
slug: "tenable"
tier: "2"
category: "Security"
description: "Vulnerability management platform hardening for Tenable One Vulnerability Management and Security Center including user access, scanning security, and agent configuration"
version: "0.2.2"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Tenable is a leading vulnerability management platform protecting **millions of assets** across enterprises worldwide. As a critical security tool with privileged access to infrastructure, Tenable configurations directly impact vulnerability visibility and security posture. Proper hardening ensures vulnerability data integrity and prevents unauthorized access to sensitive security information.

### Intended Audience
- Security engineers managing vulnerability programs
- IT administrators configuring Tenable
- GRC professionals using compliance features
- SOC analysts managing vulnerability data

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers **Tenable One Vulnerability Management** (formerly Tenable.io, and before that Tenable.io Vulnerability Management) and Tenable Security Center security including administrator account protection, SAML SSO, API key management, credential management, and hardening assessment configuration. Tenable's documentation and release notes now use the Tenable One Vulnerability Management name; this guide follows that naming throughout.

---

## Table of Contents

1. [Administrator Security](#1-administrator-security)
2. [Authentication Configuration](#2-authentication-configuration)
3. [Scanning & Credential Security](#3-scanning--credential-security)
4. [Hardening Assessments](#4-hardening-assessments)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Administrator Security

### 1.1 Protect Administrator Accounts

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Administrator accounts have the highest level of access and pose significant security risk if compromised. Proper protection is essential.

#### Rationale
**Why This Matters:**
- Admins can create accounts, modify configs, delete data
- Compromised admin credentials can expose entire security program
- Destructive capabilities require additional protection

**Attack Prevented:** Admin account takeover exposing the entire security program, destructive misuse of admin capabilities

#### ClickOps Implementation

**Step 1: Protect Non-SSO Admin Accounts**
1. Navigate to: **Settings** → **Accounts** → **Users**
2. For non-SSO admin accounts:
   - Use strong passwords (20+ characters)
   - Store passwords in password vault
   - Enable MFA for each admin

**Step 2: Limit Admin Access**
1. Minimize number of administrators (2-3 for redundancy)
2. Use principle of least privilege
3. Create separate accounts for admin vs. daily use

**Step 3: Document Admin Accounts**
1. Maintain list of all admin accounts
2. Document business justification
3. Review quarterly

**Time to Complete:** ~30 minutes

---

### 1.2 Implement Role-Based Access Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Configure granular roles to implement least privilege access. Tenable's Access Control surface now spans user management, role assignment, groups, **API key management**, and resource-level permissions, and it includes a **VM Custom Role** that grants permissions per navigation area and per action rather than through a coarse built-in tier.

#### Rationale
**Why This Matters:**
- Granular roles give each user only the Tenable permissions their job requires, shrinking the blast radius if any account is compromised
- Default Administrator access for everyone lets ordinary analysts modify scan policies, delete findings, or create new accounts
- Separating scan operators, read-only stakeholders, and administrators enforces separation of duties and produces clean audit trails
- The built-in roles are coarse: **Standard User** and above can generate API keys (see [3.4](#34-manage-api-keys)), so role assignment is also an API-credential decision, not just a console-permission one
- Legacy built-in roles were **automatically mapped into the VM Custom Role model**, which means an account's effective permissions may now be expressible more narrowly than the tier it was originally assigned — a re-review opportunity, not a no-op

#### Changes to the RBAC Model

> **VM Custom Role (2026-06-10):** Tenable introduced a VM Custom Role offering granular permissions **per navigation area and per action**. Existing built-in role assignments were automatically mapped into the new model, so no access was lost — but the coarse tier each user carries is now almost certainly broader than what they actually need. Re-review assignments against the custom-role permission set. Source: [Vulnerability Management release notes](https://docs.tenable.com/release-notes/Content/vulnerability-management/2026.htm).

> **New discrete privileges (2026-07-08):** Two permissions became independently assignable — **Exposure Management export** (No Access / Can Use) and **Linked Agents tab** permissions. Grant export deliberately: bulk export of exposure data is the highest-value action a compromised low-privilege account can take. Source: [Vulnerability Management release notes](https://docs.tenable.com/release-notes/Content/vulnerability-management/2026.htm).

**Attack Prevented:** Privilege escalation, insider misuse, lateral movement, unauthorized configuration changes, bulk exposure-data exfiltration via over-granted export rights

#### ClickOps Implementation

**Step 1: Review Built-in Roles**
1. Navigate to: **Settings** → **Access Control**
2. Review available roles:
   - **Administrator:** Full access
   - **Scan Manager:** Scan configuration and management
   - **Standard User:** Scanning and viewing
   - **Scan Operator:** Scanning only
   - **Basic:** Limited view access

**Step 2: Move Users to the VM Custom Role**
1. Create a **VM Custom Role** for each distinct job function
2. Grant permissions per navigation area and per action rather than adopting a built-in tier wholesale
3. Set **Exposure Management export** to *No Access* unless the role has a documented need to export
4. Set **Linked Agents tab** permissions only for the team that operates agents
5. Migrate users off legacy built-in roles onto the narrower custom roles

**Step 3: Govern the Full Access Control Surface**

| Access Control area | What to review |
|---------------------|----------------|
| User management | Active accounts, dormant accounts, joiner/mover/leaver hygiene |
| Role assignment | Every user on the narrowest role that supports their work |
| Groups | Group membership drives inherited access — review as an access grant |
| API key management | Which roles can mint API keys, and which keys exist (see [3.4](#34-manage-api-keys)) |
| Resource-level permissions | Per-object grants that can widen access beyond the assigned role |

**Step 4: Assign Roles Appropriately**
1. Limit Administrator to essential personnel (2-3 for redundancy)
2. Use Scan Operator or a scoped custom role for scanning teams
3. Use Basic or a view-only custom role for stakeholders
4. Re-review assignments quarterly against the custom-role permission set

#### Code Implementation

{% include pack-code.html vendor="tenable" section="1.2" %}

---

### 1.3 Monitor Administrator Activity

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Monitor and audit administrator activities.

#### Rationale
**Why This Matters:**
- Administrator actions like creating users, changing roles, or deleting scan data can hide an attacker covering their tracks if left unrecorded
- Exporting the activity log to a SIEM preserves tamper-evident records outside the platform an attacker may control
- Alerting on configuration and account changes shortens the window between a malicious action and its detection

**Attack Prevented:** Undetected account takeover, audit-log tampering, insider abuse, delayed breach detection

#### ClickOps Implementation

**Step 1: Access Activity Log**
1. Navigate to: **Settings** → **Activity Log**
2. Review logged events for admin users
3. Export logs for SIEM integration

**Step 2: Configure Alerts**
1. Set up alerts for:
   - Admin login events
   - Configuration changes
   - User creation/deletion
   - Role modifications

**Step 3: Regular Reviews**
1. Weekly review of admin activity
2. Investigate anomalies
3. Document findings

#### Code Implementation

{% include pack-code.html vendor="tenable" section="1.3" %}

---

## 2. Authentication Configuration

### 2.1 Configure SAML Single Sign-On

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO for centralized identity management. Tenable's SAML implementation carries two documented constraints that change how you deploy it: there is **no SP-initiated login flow**, and account usernames must match the SSO login exactly in full email format.

#### Rationale
**Why This Matters:**
- SAML centralizes authentication in your IdP so MFA, conditional access, and session policy apply to every Tenable login
- Disabling a user in the IdP immediately revokes their Tenable access, closing the orphaned-account gap
- A vulnerability management console holds a complete map of the organization's weaknesses, so centralizing and hardening its login path is high-leverage
- Centralized identity simplifies access reviews and compliance auditing

**Attack Prevented:** Credential theft, phishing, password reuse, orphaned-account access

#### Documented Constraints

> **No SP-initiated login.** Tenable does not support service-provider-initiated SAML. Users must start authentication from the IdP — the application tile in the IdP portal, or the SP-metadata URL. Communicate this before rollout; users who bookmark the Tenable login page will not get an SSO flow.

> **Usernames must match exactly.** Tenable account usernames must match the SSO login **exactly, in full email format**. A mismatch produces a failed login rather than an auto-provisioned account, so reconcile usernames before enabling SAML.

> **Break-glass warning.** Tenable explicitly warns: **ensure at least one administrator user has access before updating SAML configurations.** A bad SAML change with no reachable local admin locks you out of the platform. Verify the account in [1.1](#11-protect-administrator-accounts) is usable before you touch SAML settings.

Sources: [Add a SAML Configuration](https://docs.tenable.com/vulnerability-management/Content/Settings/SAML/AddSAMLConfiguration.htm) · [Single Sign-On best practices](https://docs.tenable.com/vulnerability-management/best-practices/security/Content/SingleSignOn.htm)

#### ClickOps Implementation

**Step 0: Verify Break-Glass Access**
1. Confirm at least one administrator can sign in **before** changing any SAML setting
2. Confirm that account's credentials are retrievable from your password vault

**Step 1: Configure SAML in Tenable**
1. Navigate to: **Settings** → **SAML**
2. Enable SAML authentication
3. Configure:
   - IdP SSO URL
   - IdP Certificate
   - Entity ID

**Step 2: Configure Identity Provider**
1. Create SAML application in IdP
2. Configure attribute mappings:
   - NameID (email)
   - Groups (for role mapping)
3. Reconcile usernames: every Tenable account username must match its SSO login **exactly, in full email format**
4. Download IdP metadata

**Step 3: Enable for Users**
1. Enable SAML for each user
2. Disable password login option
3. Force SSO authentication
4. Publish the IdP application tile (or SP-metadata URL) as the entry point — there is no SP-initiated flow, so a direct Tenable URL will not start SSO

**Step 4: Test and Enforce**
1. Test SSO authentication **starting from the IdP tile**, not from the Tenable login page
2. Verify role mapping
3. Confirm break-glass administrator access still works
4. Enable enforcement

**Time to Complete:** ~1 hour

---

### 2.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all users, enforced through SSO or native settings, and use **native passkeys** for administrator accounts. Tenable shipped passkey sign-in on **2026-03-31** under its CISA Secure by Design commitment, so phishing-resistant authentication no longer depends on routing through an IdP.

#### Rationale
**Why This Matters:**
- MFA stops attackers who have already obtained a valid Tenable password from completing a login
- A vulnerability management console holds a complete map of the organization's weaknesses, so a single phished password without MFA exposes that map
- **Passkeys are phishing-resistant by construction** — the credential is bound to the origin, so a proxy phishing page cannot relay it and prompt-bombing has nothing to bomb. TOTP and push MFA are both defeatable by adversary-in-the-middle kits; passkeys are not
- Native passkey support removes the previous constraint that phishing-resistant authentication was only reachable through IdP-enforced WebAuthn — organizations without an IdP-side FIDO2 deployment can now reach the same assurance level directly

**Attack Prevented:** Credential stuffing, phishing, adversary-in-the-middle credential relay, MFA prompt-bombing, account takeover

> **New capability (2026-03-31):** Tenable added native **passkey** sign-in as part of its CISA Secure by Design commitment. Passkeys are the target authenticator for administrator accounts at L2 and above. Source: [Vulnerability Management release notes](https://docs.tenable.com/release-notes/Content/vulnerability-management/2026.htm).

#### ClickOps Implementation

**Step 1: Enable Native MFA (Non-SSO)**
1. Navigate to: **Settings** → **Accounts** → **Users**
2. Enable MFA requirement per user
3. Configure supported methods

**Step 2: Register Passkeys for Administrators (L2/L3)**
1. Have every administrator register a **passkey** for their Tenable account
2. Treat passkeys as the required factor for administrators, not an optional alternative to TOTP
3. Register a second passkey (or a hardware security key) per administrator so a lost device does not become a lockout
4. Extend passkey registration to all users at L3 (Run)

**Step 3: Enforce via IdP (SSO)**
1. Configure MFA in IdP
2. Ensure all users subject to MFA
3. Use phishing-resistant methods (FIDO2/WebAuthn) for admins where the IdP is the enforcement point

---

### 2.3 Configure Session Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout and security settings.

#### Rationale
**Why This Matters:**
- Idle and absolute session timeouts limit how long a stolen or abandoned session token stays usable
- Without timeouts, an unlocked workstation or hijacked session grants standing access to sensitive vulnerability data
- Shorter sessions reduce the value of session-cookie theft and force periodic reauthentication

**Attack Prevented:** Session hijacking, unattended-workstation access, stolen-token reuse

#### ClickOps Implementation

**Step 1: Configure Session Timeout**
1. Navigate to: **Settings** → **Security**
2. Configure session settings:
   - Idle timeout: 15-30 minutes
   - Maximum session: 8 hours
3. Apply to all users

---

## 3. Scanning & Credential Security

### 3.1 Secure Scan Credentials

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Securely manage credentials used for authenticated scanning.

#### Rationale
**Why This Matters:**
- Your organization is responsible for securing scan credentials
- Tenable encrypts credentials when stored
- Best practices must align with risk appetite

**Attack Prevented:** Theft and misuse of privileged scan credentials

#### ClickOps Implementation

**Step 1: Create Dedicated Scan Accounts**
1. Create service accounts for scanning
2. Grant minimum required permissions:
   - Read access for vulnerability scanning
   - Local admin only if required for patches
3. Never use domain admin accounts

**Step 2: Configure Credential Vaults**
1. Navigate to: **Scans** → **Credentials**
2. Configure vault integration:
   - CyberArk
   - HashiCorp Vault
   - Thycotic
3. Retrieve credentials dynamically

**Step 3: Credential Rotation**
1. Establish rotation schedule (90 days)
2. Automate rotation if possible
3. Verify scanning after rotation

---

### 3.2 Secure Agent Linking Keys

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 7.1 |
| NIST 800-53 | SC-12 |

#### Description
Securely manage Nessus Agent linking keys.

#### Rationale
**Why This Matters:**
- Linking keys associate agents to your instance
- Once linked, key regeneration doesn't affect existing agents
- Protect keys during initial deployment

**Attack Prevented:** Unauthorized agent linking to your instance via exposed linking keys

#### ClickOps Implementation

**Step 1: Manage Linking Keys**
1. Navigate to: **Settings** → **Sensors** → **Linked Agents**
2. View linking key
3. Regenerate if compromised

**Step 2: Secure Deployment**
1. Use secure methods to distribute keys
2. Deploy via endpoint management
3. Remove keys from deployment scripts after use

**Step 3: Configure Agent Security**
1. Enable FIPS mode if required
2. Configure SSL ciphers
3. Enable local encryption

---

### 3.3 Configure Scan Security Settings

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 7.1 |
| NIST 800-53 | RA-5 |

#### Description
Configure appropriate scan settings for security and performance.

#### Rationale
**Why This Matters:**
- Scan policies scoped to the right targets and intensity prevent scanners from disrupting production systems or triggering outages
- Encrypting all scanner and API communications keeps vulnerability findings and credentials from being intercepted in transit
- Purpose-built, consistent policies make assessments repeatable and stop sensitive results from traversing insecure protocols

**Attack Prevented:** Data interception in transit, denial of service from aggressive scans, exposure of vulnerability findings

#### ClickOps Implementation

**Step 1: Configure Scan Policies**
1. Navigate to: **Scans** → **Policies**
2. Create policies for different use cases:
   - Full vulnerability assessment
   - Authenticated scanning
   - Compliance assessment

**Step 2: Configure Network Settings**
1. Configure appropriate scan intensity
2. Avoid production impact
3. Use maintenance windows

**Step 3: Enable Encryption**
1. Ensure all scanner communications encrypted
2. Use TLS for API communications
3. Configure secure protocols

---

### 3.4 Manage API Keys

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.3 |
| NIST 800-53 | IA-5, AC-2, AC-6 |

#### Description
Tenable API keys are an access key / secret key pair that authenticates API requests independently of the interactive login. Inventory which users hold keys, restrict which roles can generate them, and treat every key as a standing credential — Tenable documents **no expiry mechanism** for API keys.

#### Rationale
**Why This Matters:**
- **API keys have no documented expiry.** Unlike a session, a key remains valid until someone explicitly regenerates or removes it, so a key leaked into a script, a ticket, or a CI log is a permanent credential
- **Key generation is not admin-only.** Users on the **Basic**, **Scan Operator**, **Standard**, **Scan Manager**, and **Administrator** roles can all generate API keys — meaning almost every account in the platform can mint a long-lived credential carrying its own permissions. Role assignment ([1.2](#12-implement-role-based-access-control)) is therefore also an API-credential decision
- **Keys are displayed once.** Tenable shows the secret key only at generation time and does not display it again, so a "lost" key is invariably replaced rather than recovered — which makes the regeneration behaviour below operationally significant
- **Regeneration replaces existing keys immediately.** Generating new keys for a user invalidates that user's previous keys the moment it happens. Any integration still using the old pair breaks instantly, so regeneration must be scheduled, not performed casually during triage
- Tenable recommends **one key per application**, which is what makes revocation surgical: revoking a shared key takes down every consumer at once

**Attack Prevented:** Standing-credential abuse, API access surviving offboarding, credential leakage in CI/CD and scripts, unattributable API activity from shared keys

#### ClickOps Implementation

**Step 1: Inventory Existing Keys**
1. Review which users hold API keys across the platform
2. Map each key to a named application or integration and an accountable owner
3. Remove or regenerate keys with no identified owner or consumer

**Step 2: Restrict Who Can Generate Keys**
1. Recognize that Basic, Scan Operator, Standard, Scan Manager, and Administrator roles can all generate keys
2. Assign the narrowest role that supports each user's work (see [1.2](#12-implement-role-based-access-control)) — every role grant is implicitly an API-key grant
3. Document an approval path for new integrations rather than allowing ad hoc key creation

**Step 3: Generate Keys per Application**
1. Navigate to: **Settings** → **My Account** → **API Keys**
2. Generate **one key pair per application** — never share a pair across integrations
3. Capture the secret key at generation time and store it in a secrets manager; it is not shown again
4. Never commit keys to source control or echo them in pipeline logs

**Step 4: Rotate and Revoke Deliberately**
1. Because there is no expiry, set your own rotation cadence and diary it
2. Before regenerating, identify every consumer of the current key — **regeneration invalidates the existing keys immediately**
3. Schedule regeneration in a maintenance window and update all consumers in the same change
4. Regenerate immediately on suspected exposure or when a key holder leaves

#### Code Implementation

{% include pack-code.html vendor="tenable" section="3.4" %}

#### Validation & Testing
1. Confirm each active key maps to a documented application and owner
2. Confirm a departed user's keys no longer authenticate against the API
3. After a planned rotation, confirm the old key pair is rejected and every consumer is on the new pair

Source: [Generate API Keys](https://docs.tenable.com/vulnerability-management/Content/Settings/my-account/GenerateAPIKey.htm)

---

## 4. Hardening Assessments

### 4.1 Configure CIS Benchmark Audits

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Configure compliance auditing using CIS Benchmarks.

#### Rationale
**Why This Matters:**
- Hardening standards are key to cyber security
- CIS benchmarks are well-documented standards
- Tenable supports CIS audit files

**Attack Prevented:** Exploitation of unhardened configurations drifting from CIS Benchmark standards

#### ClickOps Implementation

**Step 1: Enable Compliance Scanning**
1. Navigate to: **Scans** → **Policies** → **Compliance**
2. Select CIS Benchmark templates
3. Configure for your environment

**Step 2: Configure Audit Files**
1. Select appropriate CIS benchmark:
   - Level 1 (baseline)
   - Level 2 (hardened)
2. Customize for your environment
3. Document exceptions

**Step 3: Schedule Assessments**
1. Schedule compliance scans
2. Configure reporting
3. Track remediation

---

### 4.2 Configure DISA STIG Audits

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Configure DISA STIG assessments for government compliance.

#### Rationale
**Why This Matters:**
- DISA STIG audits measure systems against mandated government hardening baselines, surfacing misconfigurations attackers routinely exploit
- Automated STIG assessment replaces error-prone manual checks and produces the evidence required for an authorization to operate
- Documenting exceptions and severities keeps residual risk visible instead of silently accepted

**Attack Prevented:** Exploitation of unhardened configurations, compliance drift, undocumented risk acceptance

#### ClickOps Implementation

**Step 1: Select STIG Audit Files**
1. Navigate to: **Scans** → **Policies** → **Compliance**
2. Select DISA STIG templates
3. Configure for applicable systems

**Step 2: Customize Settings**
1. Configure applicable findings
2. Document exceptions
3. Set severity levels

---

### 4.3 Monitor Hardening Posture

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Use dashboards to monitor hardening compliance posture.

#### Rationale
**Why This Matters:**
- Continuous dashboards reveal when compliance scores drop or new non-compliant assets appear, catching configuration drift early
- Tracking top failing checks focuses remediation on the weaknesses most likely to be exploited
- Alerting on posture changes turns periodic audits into ongoing monitoring, closing gaps faster

**Attack Prevented:** Configuration drift, unmonitored non-compliant assets, exploitation of newly introduced weaknesses

#### ClickOps Implementation (Security Center)

**Step 1: Configure Dashboards**
1. Navigate to: **Dashboards**
2. Add hardening dashboard components:
   - Compliance score trends
   - Top failing checks
   - Remediation progress

**Step 2: Configure Alerts**
1. Set up alerts for:
   - Compliance score drops
   - Critical findings
   - New non-compliant assets

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Tenable Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | SSO/MFA | [2.1](#21-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [1.2](#12-implement-role-based-access-control) |
| CC6.6 | Admin protection | [1.1](#11-protect-administrator-accounts) |
| CC7.1 | Vulnerability scanning | [3.3](#33-configure-scan-security-settings) |
| CC7.2 | Hardening assessment | [4.1](#41-configure-cis-benchmark-audits) |

### NIST 800-53 Rev 5 Mapping

| Control | Tenable Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | SSO | [2.1](#21-configure-saml-single-sign-on) |
| IA-2(1) | MFA and passkeys | [2.2](#22-enforce-multi-factor-authentication) |
| IA-5 | API key management | [3.4](#34-manage-api-keys) |
| AC-6 | Least privilege | [1.2](#12-implement-role-based-access-control) |
| RA-5 | Vulnerability scanning | [3.3](#33-configure-scan-security-settings) |
| CM-6 | Configuration assessment | [4.1](#41-configure-cis-benchmark-audits) |

---

## Appendix A: References

**Official Tenable Documentation:**
- [Trust and Assurance](https://www.tenable.com/trust/assurance)
- [Tenable Documentation](https://docs.tenable.com/)
- [Harden Nessus](https://docs.tenable.com/nessus/Content/HardenNessus.htm)
- [Tenable Vulnerability Management Security Best Practices Guide](https://docs.tenable.com/vulnerability-management/best-practices/security/Content/PDF/Tenable_Vulnerability_Management_Security_Best_Practices_Guide.pdf)
- [SAML Single Sign-On](https://docs.tenable.com/vulnerability-management/best-practices/security/Content/SingleSignOn.htm)
- [Add a SAML Configuration](https://docs.tenable.com/vulnerability-management/Content/Settings/SAML/AddSAMLConfiguration.htm)
- [Tenable Security Center Best Practices Guide](https://docs.tenable.com/security-center/best-practices/product/Content/PDF/Tenable_Security_Center_Best_Practices_Guide.pdf)

**API & Developer Tools:**
- [Tenable Developer Portal](https://developer.tenable.com/)
- [Tenable One Vulnerability Management API Documentation](https://developer.tenable.com/)
- [Generate API Keys](https://docs.tenable.com/vulnerability-management/Content/Settings/my-account/GenerateAPIKey.htm)
- [Access Control](https://docs.tenable.com/vulnerability-management/Content/Settings/access-control/AccessControl.htm)
- [Vulnerability Management Release Notes (2026)](https://docs.tenable.com/release-notes/Content/vulnerability-management/2026.htm)
- [Security Center API Reference](https://docs.tenable.com/security-center/Content/API.htm)

**Compliance Frameworks:**
- ISO 27001, SOC 2 Type II, FedRAMP (authorized products), CSA STAR -- via [Trust and Assurance](https://www.tenable.com/trust/assurance)
- Tenable supports customer compliance with CIS Controls, NIST, PCI DSS, HIPAA, and DISA STIG through its audit capabilities

**Security Incidents:**
- (2025-09) Tenable confirmed a data breach exposing customer contact details and support case information. Unauthorized actors accessed data in Tenable's Salesforce CRM via a compromised integration with the Salesloft Drift marketing application. Core vulnerability assessment products and the Tenable One platform were not affected. Tenable revoked credentials, rotated tokens, and removed the Drift integration.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.2 | ai-drafted | Cheat-sheet cell repair: added missing Attack Prevented line(s) to §1.1, §3.1, §3.2, §4.1 (no content-facts changed) | Claude Code (Fable 5) |
| 2026-08-08 | 0.2.1 | ai-drafted | Added first Code Packs (Tenable Vulnerability Management REST API): 1.2 user-role audit (GET /users?withRoles=true — permissions tiers, api_permitted, two_factor flags), 1.3 audit-log export for SIEM (GET /audit-log/v1/events with date filters, offset paging, user-target change review), 3.4 API-capable account inventory plus gated key rotation (PUT /users/{user_id}/keys with explicit confirmation, secrets never echoed to logs). All endpoints verified against developer.tenable.com references. | Claude Code (Fable 5) |
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass (Tier 1 only): added 3.4 API key management (all roles from Basic upward can generate keys; regeneration replaces keys immediately; keys shown once; no expiry mechanism); rewrote 1.2 for the VM Custom Role and the 2026-07-08 Exposure Management export and Linked Agents privileges; added native passkey sign-in (2026-03-31) as the L2/L3 target for administrators in 2.2; documented the SAML no-SP-initiated-flow, exact-username-match, and break-glass constraints in 2.1; renamed Tenable.io to Tenable One Vulnerability Management throughout. Tier 3/4 research sweep out of scope this pass. | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with admin security, authentication, and hardening assessments | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
