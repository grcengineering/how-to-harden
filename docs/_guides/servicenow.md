---
layout: guide
title: "ServiceNow Hardening Guide"
vendor: "ServiceNow"
slug: "servicenow"
tier: "1"
category: "IT Operations"
description: "IT service management platform hardening for ServiceNow including SSO configuration, Security Center, and high-security plugins"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

ServiceNow is a leading IT service management and business workflow platform used by **thousands of enterprises** worldwide. As a platform managing critical IT operations and business processes, ServiceNow security configurations directly impact operational integrity.

### Intended Audience
- Security engineers managing ITSM platforms
- IT administrators configuring ServiceNow
- GRC professionals assessing IT operations security
- Platform administrators managing instance security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers ServiceNow instance security including SAML SSO, Security Center, high-security plugins, and RBAC.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Security Center & Hardening](#2-security-center--hardening)
3. [Access Controls](#3-access-controls)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for ServiceNow users.

#### Rationale
**Why This Matters:**
- ServiceNow recommends SSO with SAML or OIDC
- Enables organizational MFA enforcement
- Required for enterprise security

**Attack Prevented:** Credential theft against local instance logins, phishing, password reuse, orphaned-account access after IdP deprovisioning

#### Prerequisites
- ServiceNow admin access
- SAML 2.0 or OIDC compatible IdP
- Multi-Provider SSO plugin activated

#### ClickOps Implementation

**Step 1: Activate Multi-Provider SSO**
1. Navigate to: **System Definition** → **Plugins**
2. Search for Multi-Provider SSO
3. Activate plugin if not enabled

**Step 2: Create SAML Configuration**
1. Navigate to: **Multi-Provider SSO** → **Identity Providers**
2. Click **New**
3. Select **SAML** as the type

**Step 3: Configure IdP Settings**
1. Enter IdP metadata
2. Use your own certificates (recommended)
3. FIPS mode requires separate Encryption and Signing certificates

**Step 4: Disable Local Login for SSO Users**
1. ServiceNow's instance security hardening settings include **"Disable local login for users with SSO enabled"**
2. Enable it so an SSO-governed user cannot fall back to a local instance password, which would bypass your IdP's MFA and conditional access
3. Confirm your Account Recovery administrator (see [1.2](#12-configure-account-recovery-administrator)) is registered first — it is the intended break-glass path once local login is disabled

**Time to Complete:** ~2 hours

**Source:** [ServiceNow instance security hardening settings](https://www.servicenow.com/docs/r/platform-security/instance-security-hardening-settings/security-hardening-settings.html)

---


{% include pack-code.html vendor="servicenow" section="1.1" %}

### 1.2 Configure Account Recovery Administrator

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure Account Recovery (ACR) administrator for SSO fallback.

#### Rationale
**Why This Matters:**
- ACR provides fallback when SSO fails
- Must be registered before SSO activation

**Attack Prevented:** Permanent lockout during an IdP outage, unmanaged break-glass credentials, unauthorized use of an unrestricted recovery account

#### ClickOps Implementation

**Step 1: Register ACR Administrator**
1. Before enabling SSO, register ACR admin
2. Navigate to: **System Security** → **Account Recovery**

**Step 2: Configure ACR Settings**
1. Enable MFA for ACR users
2. Restrict ACR to authorized personnel only
3. Document ACR procedures

---

### 1.3 Enable Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Enforce MFA for all authentication methods.

#### Rationale
**Why This Matters:**
- Passwords alone are routinely compromised through phishing, credential stuffing, and reuse — a second factor blocks the overwhelming majority of automated account-takeover attempts
- ServiceNow instances hold sensitive ITSM data, change records, and privileged workflows, so a single stolen admin credential without MFA grants an attacker full platform control
- Phishing-resistant methods (FIDO2, PIV/CAC) for administrators defeat real-time phishing and push-fatigue attacks that weaker OTP or push MFA cannot stop

**Attack Prevented:** Credential stuffing, phishing, password reuse, account takeover, MFA-prompt bombing

#### ClickOps Implementation

> **The "MFA on by default" claim is narrower than it sounds.** ServiceNow's MFA enforcement applies only from the **Yokohama** release onward, only to **internal** users (not `snc_external`), and only to **local and LDAP authentication** — SSO-authenticated logins are not covered and must get MFA from the IdP. Pre-existing users also receive an administrator-configurable **30-day grace period** before enforcement bites, so an instance can appear enforced while a population of legacy accounts is still exempt. Do not treat the default as coverage. ([MFA enforcement FAQ](https://raw.githubusercontent.com/ServiceNow/ServiceNowDocs/australia/markdown/platform-security/authentication/faq-mfa-enforcement.md))

**Step 1: Verify MFA Settings and Actual Scope**
1. Navigate to: **System Security** → **Multi-factor Authentication**
2. Confirm the instance is on Yokohama or later — earlier releases have no default enforcement at all
3. Enumerate users still inside the 30-day grace period and users on `snc_external`, and confirm each has a deliberate MFA path
4. Confirm SSO-authenticated users are covered by IdP-side MFA, since platform enforcement does not reach them

**Step 2: Enable Role-Based MFA for Privileged Roles**
1. Set the **`glide.authenticate.multifactor`** property to `true`
2. This enforces MFA for the `admin`, `security_admin`, and `user_admin` roles — the accounts whose compromise is worth the most to an attacker
3. ServiceNow's hardening catalog recommends `true` and rates leaving it unset at **CVSS 7.2**; it appears as **Security Center hardening item 1.3**
4. Verify the item reports compliant in ServiceNow Security Center

**Step 3: Configure via IdP (SSO)**
1. Enable MFA in the identity provider
2. Use phishing-resistant methods for admins (PIV/CAC, FIDO2)

#### Validation & Testing
- Confirm Security Center hardening item 1.3 reports compliant
- Log in as a test `admin`-roled account and confirm a second factor is demanded
- Confirm no internal user remains permanently outside enforcement once the grace period elapses

**Sources:** [MFA enforcement FAQ](https://raw.githubusercontent.com/ServiceNow/ServiceNowDocs/australia/markdown/platform-security/authentication/faq-mfa-enforcement.md) · [Activate role-based multi-factor authentication](https://raw.githubusercontent.com/ServiceNow/ServiceNowDocs/australia/markdown/platform-security/instance-security-hardening-settings/sc-activate-role-based-multi-factor-authentication.md)

---

## 2. Security Center & Hardening

### 2.1 Configure ServiceNow Security Center

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Use ServiceNow Security Center (SSC) to monitor and improve instance security.

#### Rationale
**Why This Matters:**
- ServiceNow Security Center surfaces misconfigurations and a hardening compliance score, giving administrators a single place to find drift from ServiceNow's recommended secure baseline
- Without continuous visibility, insecure default settings and configuration drift accumulate silently until they are exploited
- Prioritizing and remediating findings closes gaps before attackers discover them, and documenting accepted risks creates an auditable security baseline

**Attack Prevented:** Security misconfiguration, configuration drift, exploitation of insecure defaults, unmonitored attack surface

#### ClickOps Implementation

> **Naming:** the product is **ServiceNow Security Center (SSC)**. The older **Instance Security Center (ISC)** reached end of sales in September 2024 — if your runbooks or audit evidence still say "ISC", update them, and expect older third-party write-ups to use the retired name. ([Instance security center hardening](https://raw.githubusercontent.com/ServiceNow/ServiceNowDocs/australia/markdown/platform-security/instance-sec-center-hardening.md))

**Step 1: Access ServiceNow Security Center**
1. Navigate to: **Security Center**
2. Review overall security score

**Step 2: Review Hardening Settings**
1. Review hardening compliance score
2. Determine alignment with SSC recommendations

**Step 3: Address Findings**
1. Test fixes in sub-production first
2. Document accepted risks

---

### 2.2 Enable High-Security Plugins

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Activate high-security plugins for enhanced protection.

#### Rationale
**Why This Matters:**
- The High Security Settings plugin switches ACL evaluation to default-deny, so any table or field without an explicit allow rule is protected instead of inadvertently exposed
- Centralized security settings and the dedicated security administrator role separate security configuration from general admin duties, supporting separation of duties
- Default-deny is the only safe posture on a platform with thousands of tables, since an allow-by-default model leaves new and custom records unprotected by oversight

**Attack Prevented:** Unauthorized data access, privilege escalation, insecure-default exposure, broken access control

#### ClickOps Implementation

**Step 1: Verify Plugin Status**
1. Navigate to: **System Definition** → **Plugins**
2. Search for high-security plugins

**Step 2: Enable High-Security Settings**
1. Plugin enables:
   - Centralized security settings
   - Security administrator role
   - Default deny for ACLs

---


{% include pack-code.html vendor="servicenow" section="2.2" %}

---

### 2.3 Apply Baseline Instance Hardening Settings

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 4.3 |
| NIST 800-53 | AC-7, AC-12, AC-17, CM-6, IA-5 |

#### Description
Work through the named settings in ServiceNow's instance security hardening catalog that this guide's other controls do not cover — failed-login lockout, absolute session timeout, IP allowlist scope, SOAP and API authorization requirements, password policy enforcement at login, and high-assurance session length — and set each deliberately rather than leaving the platform default.

#### Rationale
**Why This Matters:**
- ServiceNow ships a catalog of named hardening settings whose defaults are chosen for compatibility, not security, so an untouched instance is by definition unhardened
- A failed-login lockout limit is what turns a password policy into a defense against online brute force; without it, an attacker gets unlimited attempts against a valid username
- An absolute session timeout bounds the lifetime of any session regardless of activity, capping the value of a stolen session token even when the attacker keeps it active
- Narrowing the IP allowlist scope means stolen credentials alone are insufficient from an arbitrary network, and shrinks the surface reachable by automated credential-stuffing infrastructure
- Requiring authorization on SOAP and inbound API access closes the integration path, which is frequently left more permissive than the UI and is exactly where attackers look after the console is hardened
- Enforcing the password policy at login catches accounts whose passwords predate the current policy and would otherwise remain non-compliant indefinitely
- Constraining high-assurance session length limits how long an elevated, step-up-authenticated session stays elevated

**Attack Prevented:** Online password brute force, session token replay, access from untrusted networks, unauthenticated or under-authorized API access, indefinite privilege elevation

#### Prerequisites
- `security_admin` role (elevated privilege) to change security properties
- A sub-production instance to test in first — several of these settings can lock out users or break integrations if applied without validation

#### ClickOps Implementation

**Step 1: Open the Hardening Catalog**
1. Review ServiceNow's [instance security hardening settings](https://www.servicenow.com/docs/r/platform-security/instance-security-hardening-settings/security-hardening-settings.html) reference, which lists each setting with its property and recommended value
2. Compare against your instance's current values via **Security Center** (see [2.1](#21-configure-servicenow-security-center))

**Step 2: Set Each Baseline Control**
1. **Failed-login lockout limit:** set a maximum number of failed attempts before lockout
2. **Absolute session timeout:** set a maximum total session lifetime independent of activity
3. **IP allowlist scope:** narrow the address ranges permitted to reach the instance, including for integration traffic
4. **SOAP and API authorization requirements:** require authorization for SOAP requests and inbound API access
5. **Password policy enforcement at login:** enforce the active password policy when users authenticate, not only when they set a password
6. **High-assurance session length:** cap how long an elevated, high-assurance session remains valid

**Step 3: Roll Out Safely**
1. Apply in a sub-production instance and exercise your integrations and login flows
2. Record any setting you deliberately leave at a weaker value as an accepted risk with a business justification
3. Promote to production and re-check the hardening compliance score in Security Center

#### Validation & Testing
- Exceed the failed-login limit against a test account and confirm lockout
- Hold a session active past the absolute timeout and confirm it terminates
- Issue an unauthenticated SOAP or API request and confirm it is rejected
- Attempt access from an out-of-scope IP and confirm it is refused
- Confirm the Security Center hardening compliance score reflects the changes

**Source:** [ServiceNow instance security hardening settings](https://www.servicenow.com/docs/r/platform-security/instance-security-hardening-settings/security-hardening-settings.html)

---

### 2.4 Harden AI and Agentic Capabilities

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 6.5 |
| NIST 800-53 | AC-3, IA-2(1), CM-7 |

#### Description
Enable the AI-specific settings in ServiceNow's instance security hardening catalog — Guardian for external agents, multi-factor authentication for the AI Voice Agent, and the prohibition on knowledge-based answers as a single factor for AI Voice — so AI and agentic surfaces authenticate and authorize to the same standard as the rest of the platform.

#### Rationale
**Why This Matters:**
- AI agents and voice channels are authentication surfaces that reach the same records as the console, but they are newer and are frequently left at defaults after the human-facing surfaces have been hardened
- Requiring MFA for the AI Voice Agent removes a channel through which a caller could otherwise reach account actions with weaker verification than a UI login demands
- Knowledge-based answers (address, manager, hire date) are attacker-researchable and are unfit as a sole authentication factor; prohibiting them as a single factor for AI Voice closes a social-engineering path into account recovery and privileged actions
- Guardian for external agents applies controls to agents originating outside the instance, which are the least trustworthy participants in an agentic workflow
- Now Assist Guardian's guardrails — offensiveness, prompt injection, and sensitive topics — **only log by default**; blocking is a separate explicit choice, so an instance can pass a "Guardian is on" check while every detected prompt injection still executes
- Governing agents as tracked assets through AI Control Tower, with a named steward reviewing them, is what turns one-time enablement into an ongoing control rather than a launch-day checkbox
- The BodySnatcher research (below) demonstrated that AI-agent surfaces were exploitable to impersonate users while bypassing MFA and SSO — the fix is to treat these surfaces as authentication boundaries, not conveniences

**Attack Prevented:** Impersonation via AI agent surfaces, MFA and SSO bypass through the voice channel, social-engineering of knowledge-based verification, unauthorized action by untrusted external agents

**Real-World Incidents:**
- **BodySnatcher / CVE-2025-12420 (disclosed October 2025):** AppOmni's research described a vulnerability affecting `sn_aia` versions 5.0.24 through 5.2.18 and `sn_va_as_service` versions up to 3.15.1 and 4.0.0 through 4.0.3, patched by ServiceNow on 2025-10-30, that allowed impersonation of arbitrary users while bypassing MFA and SSO. ([AppOmni: BodySnatcher](https://appomni.com/ao-labs/bodysnatcher-agentic-ai-security-vulnerability-in-servicenow/))

#### Prerequisites
- `security_admin` role for the hardening settings
- The `sn_aict` (AI Control Tower) application, and the `sn_ai_governance.ai_steward` role for whoever performs steward review
- Instance patched past the fixed versions listed above before relying on any AI agent capability

#### ClickOps Implementation

**Step 1: Enable the AI Hardening Settings**
1. From the [instance security hardening settings](https://www.servicenow.com/docs/r/platform-security/instance-security-hardening-settings/security-hardening-settings.html) catalog, enable:
   - **Enable Guardian for External Agents** — property **`sn_aia.external_agent_guardian_check`**, an Access control category setting rated **CVSS 4.1 (Medium)** when left unset
   - **Require Multi-Factor Authentication for AI Voice Agent**
   - **Prohibit Use of KBA as Single Factor for AI Voice**
2. Verify each shows as compliant in ServiceNow Security Center

**Step 2: Switch Now Assist Guardian Guardrails From Logging to Blocking**
1. Navigate to: **AI Agent Studio** → **Settings**
2. Review the Now Assist Guardian guardrails — **offensiveness**, **prompt injection**, and **sensitive topics**
3. **Default behavior is log-only.** Detection without blocking means a prompt-injection attempt is recorded and then still carried out — explicitly enable blocking for each guardrail you intend to enforce
4. Record any guardrail deliberately left in log-only mode as an accepted risk with a justification

**Step 3: Confirm Patch Level**
1. Confirm `sn_aia` and `sn_va_as_service` are on versions at or beyond ServiceNow's 2025-10-30 fix

**Step 4: Govern Agents as Assets in AI Control Tower**
1. Navigate to: **Workspaces** → **AI Control Tower** (the `sn_aict` application)
2. Assign the **`sn_ai_governance.ai_steward`** role to the named person accountable for AI asset review — this is the vendor-documented steward-review lifecycle, not an informal practice
3. Route agent-initiated actions through steward review rather than letting agents act unreviewed
4. De-provision dormant agents through the asset lifecycle rather than leaving unused agent identities enabled
5. Per AppOmni's analysis, additionally require MFA when a user account is linked to an AI agent, preferring an authenticator app over SMS

> **Attribution note:** steps 1–4 are vendor-documented (hardening catalog, Now Assist Guardian, AI Control Tower). Only the MFA-on-account-linking item in Step 4.5 is drawn from AppOmni's writeup rather than ServiceNow documentation.

#### Validation & Testing
- Confirm each of the three named settings reports as compliant in ServiceNow Security Center
- Confirm `sn_aia.external_agent_guardian_check` is set
- Submit a known prompt-injection string and confirm it is **blocked**, not merely logged
- Attempt an AI Voice Agent interaction without a second factor and confirm it is refused
- Attempt verification using only knowledge-based answers on AI Voice and confirm it is refused
- Review the AI Control Tower asset inventory and confirm every agent has a steward and no dormant agent remains enabled

**Sources:** [Instance security hardening settings](https://www.servicenow.com/docs/r/platform-security/instance-security-hardening-settings/security-hardening-settings.html) · [Enable Guardian for external agents](https://raw.githubusercontent.com/ServiceNow/ServiceNowDocs/australia/markdown/platform-security/instance-security-hardening-settings/sc-enable-guardian-for-external-agents.md) · [Now Assist Guardian](https://raw.githubusercontent.com/ServiceNow/ServiceNowDocs/australia/markdown/platform-security/now-assist-guardian.md) · [AI Control Tower — complete AI asset lifecycle](https://raw.githubusercontent.com/ServiceNow/ServiceNowDocs/australia/markdown/intelligent-experiences/ai-control-tower/complete-ai-asset-lifecycle.md) · [AppOmni: BodySnatcher](https://appomni.com/ao-labs/bodysnatcher-agentic-ai-security-vulnerability-in-servicenow/)

---

## 3. Access Controls

### 3.1 Configure Role-Based Access Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using ServiceNow's role model.

#### Rationale
**Why This Matters:**
- Granting users only the roles required for their job limits the blast radius if any single account is phished or compromised
- Over-assigned admin roles turn ordinary user accounts into high-value targets and violate separation of duties
- Explicit allow ACLs layered on default-deny ensure access to records and fields is intentional and auditable rather than accidental
- Bundling roles are the quiet risk: a single grant such as the Now Assist admin role silently carries several other admin roles with it, so the assignment an administrator thinks they made is narrower than the access the user receives

**Attack Prevented:** Privilege escalation, lateral movement, insider misuse, broken access control

#### ClickOps Implementation

**Step 1: Review Role Structure**
1. Navigate to: **User Administration** → **Roles**
2. Review role hierarchy

**Step 2: Apply Least Privilege**
1. Create custom roles for specific functions
2. Avoid over-assigning admin roles
3. Use role contains for hierarchies

**Step 3: Audit Bundling Roles Before Granting Them**
1. Expand any role that contains other roles and confirm the full inherited set before assignment — ServiceNow's own guidance is to avoid granting an admin role when more specialized roles are available
2. The Now Assist admin role is the worked example: **`sn_na_center.nac_admin`** carries **`sn_aia.admin`**, **`sn_data_kit.admin`**, **`sn_agent_miner.app_ui`**, and **`sn_nowassist_admin.nsa_admin`**
3. Where a user needs only one of those capabilities, grant the specific constituent role instead of the bundle
4. Re-audit bundling roles after each upgrade — the constituent set can change between releases

**Step 4: Configure ACLs**
1. Use default deny (high-security plugin)
2. Create explicit allows

**Source:** [Roles installed with Now Assist Admin](https://raw.githubusercontent.com/ServiceNow/ServiceNowDocs/australia/markdown/intelligent-experiences/roles-installed-with-now-assist-admin.md)

---

### 3.2 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### Rationale
**Why This Matters:**
- Each admin account is a high-value target, so reducing the count to a small set of authorized personnel shrinks the attack surface for account takeover
- Using the dedicated security_admin role for security tasks enforces separation of duties so no single account holds unchecked power
- Fewer privileged accounts are easier to monitor, MFA-protect, and review during audits, making anomalous admin activity stand out

**Attack Prevented:** Admin account takeover, privilege abuse, insider threat, excessive standing privilege

#### ClickOps Implementation

**Step 1: Inventory Admin Users**
1. Navigate to: **User Administration** → **Users**
2. Filter by admin roles

**Step 2: Apply Least Privilege**
1. Limit admin to 2-3 users
2. Use security_admin for security tasks

---


{% include pack-code.html vendor="servicenow" section="3.2" %}

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs for security events.

#### Rationale
**Why This Matters:**
- Audit logs on critical tables, configuration changes, and user management create the forensic record needed to detect and investigate unauthorized activity
- Without comprehensive logging and alerting, attacker actions and privilege changes go unnoticed until damage is done
- Dashboards and alerts on suspicious activity turn passive logs into active detection, shortening the window between compromise and response

**Attack Prevented:** Undetected intrusion, insider data tampering, repudiation, delayed incident response

#### ClickOps Implementation

**Step 1: Review Audit Configuration**
1. Navigate to: **System Logs** → **Audit**
2. Verify auditing enabled

**Step 2: Configure Audit Policies**
1. Audit critical tables
2. Audit configuration changes
3. Audit user management

**Step 3: Monitor Audit Logs**
1. Create audit dashboards
2. Set up alerts for suspicious activity

---


{% include pack-code.html vendor="servicenow" section="4.1" %}

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | ServiceNow Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [3.1](#31-configure-role-based-access-control) |
| CC7.1 | ServiceNow Security Center | [2.1](#21-configure-servicenow-security-center) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | ServiceNow Control | Guide Section |
|---------|-------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | MFA | [1.3](#13-enable-multi-factor-authentication) |
| AC-6 | Least privilege | [3.1](#31-configure-role-based-access-control) |
| CM-6 | Security hardening | [2.2](#22-enable-high-security-plugins), [2.3](#23-apply-baseline-instance-hardening-settings) |
| AC-7, AC-12 | Login lockout and session timeout | [2.3](#23-apply-baseline-instance-hardening-settings) |
| CM-7 | AI and agentic surface hardening | [2.4](#24-harden-ai-and-agentic-capabilities) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: References

**Official ServiceNow Hardening Documentation:**
- [Instance Security Hardening Settings](https://www.servicenow.com/docs/r/platform-security/instance-security-hardening-settings/security-hardening-settings.html) — release-agnostic catalog of named hardening settings and recommended values
- [Enable Guardian for external agents](https://raw.githubusercontent.com/ServiceNow/ServiceNowDocs/australia/markdown/platform-security/instance-security-hardening-settings/sc-enable-guardian-for-external-agents.md) — `sn_aia.external_agent_guardian_check`
- [Activate role-based multi-factor authentication](https://raw.githubusercontent.com/ServiceNow/ServiceNowDocs/australia/markdown/platform-security/instance-security-hardening-settings/sc-activate-role-based-multi-factor-authentication.md) — `glide.authenticate.multifactor`
- [MFA enforcement FAQ](https://raw.githubusercontent.com/ServiceNow/ServiceNowDocs/australia/markdown/platform-security/authentication/faq-mfa-enforcement.md) — release, user-type, auth-method, and grace-period scope
- [Now Assist Guardian](https://raw.githubusercontent.com/ServiceNow/ServiceNowDocs/australia/markdown/platform-security/now-assist-guardian.md) — guardrails and log-vs-block behavior
- [Instance security center hardening](https://raw.githubusercontent.com/ServiceNow/ServiceNowDocs/australia/markdown/platform-security/instance-sec-center-hardening.md) — ISC end-of-sales, SSC naming
- [AI Control Tower — complete AI asset lifecycle](https://raw.githubusercontent.com/ServiceNow/ServiceNowDocs/australia/markdown/intelligent-experiences/ai-control-tower/complete-ai-asset-lifecycle.md) — `sn_aict`, `sn_ai_governance.ai_steward`
- [Roles installed with Now Assist Admin](https://raw.githubusercontent.com/ServiceNow/ServiceNowDocs/australia/markdown/intelligent-experiences/roles-installed-with-now-assist-admin.md) — `sn_na_center.nac_admin` role bundle
- [ServiceNow Documentation](https://docs.servicenow.com/)

> **On these URLs.** `servicenow.com/docs` renders as a JavaScript shell to non-browser clients. ServiceNow publishes the same documentation as markdown in its official `ServiceNow/ServiceNowDocs` GitHub repository, where each file carries a `canonical_url` pointing back at the `servicenow.com/docs` page — so the `raw.githubusercontent.com` links above are first-party vendor documentation, just served in a fetchable form. Read them in either place.
>
> The previous Washington DC-pinned hardening and SAML URLs are dead. Use the release-agnostic `/docs/r/` form and avoid re-pinning to a named release — the current release family is **Australia**, which supersedes Zurich.

**Other References:**
- [ServiceNow Security Best Practices whitepaper (PDF)](https://www.servicenow.com/content/dam/servicenow-assets/public/en-us/doc-type/resource-center/white-paper/instance-security-best-practice.pdf) — returns 403 to automated fetchers; requires browser access
- [Security hardening and Security Center](https://www.servicenow.com/community/developer-blog/servicenow-security-hardening-security-center/ba-p/2982684) — ServiceNow **Community** developer blog post, not first-party product documentation

**API & Developer Resources:**
- [ServiceNow Developer Reference](https://developer.servicenow.com/dev.do#!/reference)

**Third-Party Research:**
- [AppOmni: BodySnatcher — agentic AI security vulnerability in ServiceNow](https://appomni.com/ao-labs/bodysnatcher-agentic-ai-security-vulnerability-in-servicenow/)

**Third-Party Baselines:**
- No CIS Benchmark or CISA SCuBA baseline for ServiceNow was established in this pass — those Tier 2 indexes were not surveyed, so absence is not confirmed.
- DISA STIG coverage for ServiceNow could not be verified: the DoD cyber exchange sits behind an authentication wall. Treat as unknown, not absent.

**Security Incidents:**
- **BodySnatcher / CVE-2025-12420 (October 2025):** A critical vulnerability in the ServiceNow Virtual Agent API and Now Assist AI Agents allowed unauthenticated attackers to impersonate any user (including admins) using only an email address, bypassing MFA and SSO. Affected `sn_aia` 5.0.24–5.2.18 and `sn_va_as_service` up to 3.15.1 and 4.0.0–4.0.3. Patched by ServiceNow on October 30, 2025. No evidence of exploitation in the wild. — [AppOmni analysis](https://appomni.com/ao-labs/bodysnatcher-agentic-ai-security-vulnerability-in-servicenow/) · see [2.4](#24-harden-ai-and-agentic-capabilities)
- **Template Injection CVEs (May 2024):** Three vulnerabilities (CVE-2024-4879, CVE-2024-5178, CVE-2024-5217) were patched same day of disclosure but saw in-the-wild exploitation attempts across 6,000+ sites before patching was complete, primarily targeting financial services.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Add 2.4 AI and agentic hardening — Guardian for external agents (`sn_aia.external_agent_guardian_check`), AI Voice MFA, KBA-as-single-factor prohibition, Now Assist Guardian log-vs-block default, and AI Control Tower steward governance (`sn_aict`, `sn_ai_governance.ai_steward`) — with cited BodySnatcher/CVE-2025-12420 context; add 2.3 baseline hardening-catalog settings; scope the "MFA by default" claim in 1.3 (Yokohama+, internal users, local/LDAP only, 30-day grace) and add role-based MFA via `glide.authenticate.multifactor`; add `sn_na_center.nac_admin` role-bundle audit to 3.1; correct Instance Security Center to ServiceNow Security Center (ISC end-of-sales Sept 2024); add "disable local login for SSO users" to 1.1; replace dead Washington DC-pinned URLs with release-agnostic and GitHub-mirror first-party sources; add Attack Prevented to 1.1 and 1.2; drop Trust Center references and label the community blog and 403ing whitepaper honestly | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, Security Center, and access controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
