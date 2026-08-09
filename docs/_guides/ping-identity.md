---
layout: guide
title: "Ping Identity Hardening Guide"
vendor: "Ping Identity"
slug: "ping-identity"
tier: "1"
category: "Identity"
description: "Identity federation security for PingFederate, PingOne, and OAuth configurations"
version: "0.2.1"
maturity: "draft"
last_updated: "2026-08-08"
---


## Overview

Ping Identity serves **50%+ of Fortune 100** with federation trust relationships connecting enterprise identity to hundreds of downstream applications. OAuth and SAML tokens, if compromised, provide persistent access across the enterprise. The PingOne DaVinci orchestration platform creates automated identity workflows that attackers can exploit for privilege escalation and persistent access.

### Intended Audience
- Security engineers managing identity infrastructure
- IT administrators configuring Ping Identity products
- GRC professionals assessing IAM compliance
- Third-party risk managers evaluating federation security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Ping Identity security configurations including federation hardening, OAuth security, DaVinci orchestration controls, and token lifecycle management.

**Products covered:** PingFederate (self-managed federation server), PingOne (cloud identity platform), PingOne Protect (risk-based authentication), PingOne DaVinci (orchestration), and PingOne Advanced Identity Cloud — the ForgeRock-lineage platform comprising PingAM (access management), PingIDM (identity management), PingDS (directory services), and PingGateway (identity gateway). Controls written for Advanced Identity Cloud tenants generally apply to self-managed PingAM and PingGateway deployments as well, with the caveat that self-managed operators own patching, agent currency, and secret storage themselves.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Federation Security](#2-federation-security)
3. [OAuth & Token Security](#3-oauth--token-security)
4. [DaVinci Orchestration Security](#4-davinci-orchestration-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Phishing-Resistant MFA

**Profile Level:** L1 (Crawl)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1), IA-2(6)

#### Description
Require FIDO2/WebAuthn authenticators for administrator and high-privilege user authentication.

#### Rationale
**Why This Matters:**
- Federation trust means Ping Identity compromise affects all connected apps
- TOTP/SMS MFA can be bypassed via real-time phishing
- FIDO2 provides origin-bound authentication resistant to phishing

**Attack Prevented:** Real-time phishing of admin credentials, federation-wide token forgery from IdP compromise

**Attack Scenario:** Attacker phishes admin credentials, generates valid tokens for any connected application via federation trust exploitation.

#### ClickOps Implementation (PingOne)

**Step 1: Enable FIDO2 Authentication**
1. Navigate to: **Authentication → Policies → MFA Policies**
2. Create policy:
   - **Name:** "Phishing-Resistant MFA"
   - **Methods:** FIDO2 Security Key (required)
   - **Fallback:** None for admins
3. Assign to administrator groups

**Step 2: Configure Authentication Policy**
1. Navigate to: **Authentication → Policies → Sign-On Policies**
2. Create rule:
   - **Condition:** User group = "Administrators"
   - **Action:** Require FIDO2 MFA
   - **Session duration:** 2 hours maximum

**Step 3: Disable Legacy Methods for Admins**
1. Navigate to: **Authentication → MFA**
2. For admin accounts:
   - Disable: SMS, Voice, Email OTP
   - Enable only: FIDO2, Mobile app (push with number matching)

#### Code Implementation (PingOne API)

See the API pack below for MFA policy creation and assignment commands.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(6) | MFA for privileged accounts |
| **PCI DSS** | 8.3.1 | MFA for administrative access |

{% include pack-code.html vendor="ping-identity" section="1.1" %}

---

### 1.2 Implement Least-Privilege Admin Roles

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-6, AC-6(1)

#### Description
Create granular administrative roles instead of using organization-wide admin access.

#### Rationale
**Why This Matters:**
- Organization-wide admin access means a single compromised account can reconfigure federation, mint tokens, and read every audit log
- Granular roles enforce separation of duties so identity, application, and security functions cannot all be abused from one account
- Scoped roles shrink the blast radius of phishing, insider misuse, or session hijacking against any single administrator
- Group-based assignment makes access reviews and offboarding auditable instead of relying on scattered direct grants

**Attack Prevented:** Privilege escalation, lateral movement, insider abuse, blast-radius expansion from one compromised admin

#### ClickOps Implementation (PingOne)

**Step 1: Create Custom Admin Roles**
1. Navigate to: **Settings → Roles**
2. Create roles:

**Identity Administrator:**
- Manage users and groups
- Reset passwords
- Assign MFA
- NO: Configure applications, manage policies

**Application Administrator:**
- Configure SAML/OIDC applications
- Manage application policies
- NO: Manage users, access audit logs

**Security Administrator:**
- Configure MFA policies
- Manage authentication policies
- Access audit logs
- NO: Manage applications directly

**Read-Only Auditor:**
- View all configurations
- Access reports and logs
- NO: Make any changes

**Step 2: Assign Roles to Groups**
1. Navigate to: **Identities → Groups**
2. Create admin groups (e.g., "Identity-Admins", "App-Admins")
3. Assign appropriate roles to each group
4. Add users to groups (not direct role assignment)

{% include pack-code.html vendor="ping-identity" section="1.2" %}

---

### 1.3 Configure IP-Based Access Restrictions

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3(7), SC-7

#### Description
Restrict administrative console and API access to known IP ranges.

#### Rationale
**Why This Matters:**
- Restricting admin and API access to corporate or VPN egress ranges blocks login attempts originating from attacker infrastructure
- IP allowlisting adds a network-layer control that holds even when credentials are stolen or MFA is phished
- Concentrating administrative reach onto known networks turns any anomalous source IP into a high-fidelity detection signal
- Reduces exposure of the management plane to internet-wide credential stuffing and automated scanning

**Attack Prevented:** Credential stuffing from untrusted networks, remote console takeover, stolen-credential reuse, automated API abuse

#### ClickOps Implementation

**Step 1: Configure IP Restrictions (PingOne)**
1. Navigate to: **Settings → IP Restrictions**
2. Add allowed IP ranges:
   - Corporate network CIDRs
   - VPN egress IPs
3. Set default: Deny all not in list

**Step 2: Configure in Sign-On Policy**
1. Navigate to: **Authentication → Policies → Sign-On Policies**
2. Create rule:
   - **Condition:** IP not in trusted ranges
   - **Action:** Deny access OR require additional verification

{% include pack-code.html vendor="ping-identity" section="1.3" %}

---

### 1.4 Enable Risk-Based Adaptive Authentication with PingOne Protect

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5, 13.1 |
| NIST 800-53 | AC-2(12), IA-2(1), SI-4 |

#### Description
Deploy PingOne Protect risk policies so that every sign-on is scored against signals such as bot detection, device trust, IP reputation, and behavioral anomaly, and route high-risk sessions to step-up MFA or denial instead of allowing them through on a valid password alone.

#### Rationale
**Why This Matters:**
- Static MFA policies treat every sign-in identically, so a session replayed from attacker infrastructure with a phished factor looks exactly like a legitimate one
- Risk predictors (new device, impossible travel, anomalous IP reputation, bot signals) catch credential-stuffing and session-hijacking attempts that authenticate "successfully" by every binary check
- Step-up rather than blanket denial keeps friction proportional, which is what makes strong authentication survivable for a large user base instead of being disabled after complaints
- Risk evaluations are logged per authentication, producing a high-fidelity detection feed that binary allow/deny logs cannot provide
- Ping Identity fronts federation for hundreds of downstream applications, so a single unchallenged high-risk sign-on converts into tokens for every connected app

**Attack Prevented:** Credential stuffing, bot-driven account takeover, session hijacking from unfamiliar devices or networks, MFA-fatigue and real-time phishing follow-through

#### ClickOps Implementation

**Step 1: Review Risk Predictors**
1. Sign in to the PingOne admin console as an environment administrator
2. Navigate to: **Threat Protection → Predictors** (labeled **Risk → Predictors** in some tenants)
3. Review the built-in predictors and enable those relevant to your environment:
   - **Bot Detection** — flags automated sign-in attempts
   - **IP Reputation** — flags addresses associated with malicious activity
   - **New Device** — flags authentication from an unrecognized device
   - **Anonymous Network Detection** — flags Tor, proxy, and anonymizing VPN egress
   - **Impossible Travel / User Location Anomaly** — flags geographically implausible sequences
   - **User-Based Risk Behavior** — flags deviation from the user's own baseline
4. Add custom predictors for any organization-specific signals (for example, allowlisted corporate IP ranges as a mitigating predictor)

**Step 2: Build the Risk Policy**
1. Navigate to: **Threat Protection → Risk Policies** (labeled **Risk → Policies** in some tenants)
2. Create a new risk policy, or copy the default policy so the default remains available for rollback
3. Assign each enabled predictor to a risk result — **High**, **Medium**, or **Low** — reflecting how strongly that signal should influence the score
4. Save the policy and set it as the default for the environment only after the pilot in Step 4 is complete

**Step 3: Bind Risk Results to Authentication Outcomes**
1. Navigate to: **Authentication → Policies → Sign-On Policies**
2. Add a **PingOne Protect** step to the policy that precedes the authentication step
3. Configure the outcomes:
   - **High risk:** Deny access, or require FIDO2 step-up plus notification to the security team
   - **Medium risk:** Require MFA step-up
   - **Low risk:** Continue without additional challenge
4. Apply the policy to administrator applications and populations first, then to high-value business applications

**Step 4: Pilot Before Enforcing**
1. Run the risk policy in a monitoring posture against a pilot population and review the resulting risk evaluations
2. Tune predictor weights where legitimate traffic (VPN egress, shared kiosk devices, travelling executives) scores High
3. Only then promote the policy to the full population, keeping the previous policy available for rollback

#### Validation & Testing
1. Sign in from an anonymizing network or an unenrolled device and confirm the risk evaluation returns **High** and that the configured step-up or denial actually fires
2. Sign in from a known corporate device and network and confirm the session completes without unnecessary challenge
3. Navigate to the risk evaluation records in the admin console and confirm each test authentication produced a scored evaluation with the expected contributing predictors
4. Confirm risk evaluation events reach your SIEM through the audit export configured in control 5.1
5. Verify the fallback path: temporarily disable the risk policy binding in a test environment and confirm the sign-on policy still enforces baseline MFA rather than failing open

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **SOC 2** | CC7.2 | Monitoring for anomalous activity |
| **NIST 800-53** | AC-2(12) | Account monitoring for atypical usage |
| **NIST 800-53** | SI-4 | System monitoring |
| **PCI DSS** | 8.4.2 | MFA for access to the cardholder data environment |

**Vendor Reference:** [Threat protection using PingOne Protect](https://docs.pingidentity.com/pingone/threat_protection_using_pingone_protect/p1_protect_introduction.html)

---

### 1.5 Harden PingFederate Administrative API and Console Authentication

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.5 |
| NIST 800-53 | AC-3, AC-10, IA-5 |

#### Description
Move the PingFederate administrative API off its default native HTTP Basic authentication onto OAuth 2.0 bearer tokens by setting `pf.admin.api.authentication` in `run.properties`, and restrict administrators to a single concurrent console session with `pf.console.login.mode`.

#### Rationale
**Why This Matters:**
- The administrative API can create and modify connections, adapters, and OAuth clients, so it is a full compromise path to every federation trust the server holds — not a secondary management surface
- Native authentication sends reusable administrator credentials on every API call, meaning any logged proxy, script, CI variable, or captured request yields standing admin access
- OAuth 2.0 bearer tokens are short-lived and independently revocable, so a leaked token expires on its own and can be cut off without rotating administrator passwords
- Scoped tokens let automation hold only the administrative rights it actually needs, instead of every caller sharing one all-powerful account
- Restricting each administrator account to a single console session makes credential sharing and parallel attacker sessions visible instead of silent
- IP restriction (control 1.3) is a network-layer control that does nothing once an attacker is inside a permitted range; this control hardens the authentication layer itself

**Attack Prevented:** Administrative API takeover with replayed Basic credentials, standing access from leaked automation secrets, undetected concurrent attacker sessions on a shared admin account, federation reconfiguration by an insider on a trusted network

#### ClickOps Implementation

**Step 1: Prepare the OAuth 2.0 Authorization Server**
1. Sign in to the PingFederate administrative console
2. Configure the OAuth 2.0 authorization server that will issue administrative API access tokens, following the vendor procedure linked below
3. Register a dedicated client for each administrative API consumer (provisioning automation, CI pipelines, monitoring) rather than sharing one client
4. Map token scopes to the least-privileged administrative roles each consumer requires

**Step 2: Switch the Administrative API to OAuth 2.0**
1. On each PingFederate node, open `<pf_install>/pingfederate/bin/run.properties` in a text editor
2. Locate the `pf.admin.api.authentication` property, which ships set to native authentication
3. During migration, set it to `OAuth2,native` so existing native callers keep working while consumers are cut over
4. Once every consumer authenticates with bearer tokens, set the property to `OAuth2` so native Basic authentication is no longer accepted

**Step 3: Restrict Concurrent Administrative Sessions**
1. In the same `run.properties` file, set `pf.console.login.mode` to `single` so one administrator account cannot hold multiple concurrent console sessions
2. Confirm each administrator has an individually named account — this control provides no separation if administrators share one login

**Step 4: Apply Consistently Across the Cluster**
1. Repeat Steps 2 and 3 on every node in the cluster; `run.properties` is a per-node file and is not distributed by configuration replication
2. Restart the PingFederate service on each node so the changes take effect
3. Record the settings in configuration management so node rebuilds and version upgrades do not silently restore the defaults

#### Validation & Testing
1. Call an administrative API endpoint using HTTP Basic administrator credentials — after Step 2 completes, the call must be rejected rather than returning data
2. Call the same endpoint with a bearer token from the registered client and confirm it succeeds
3. Request an endpoint outside the client's mapped scopes and confirm it is refused, proving scope-to-role mapping is enforced rather than nominal
4. Sign in to the administrative console with one account, then attempt a second concurrent session with the same account from another browser and confirm the second session is refused or the first is terminated
5. Inspect `run.properties` on every cluster node and confirm the values match; a single unhardened node leaves the old authentication path reachable
6. Confirm administrative API authentication events appear in the audit log export configured in control 5.1

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **SOC 2** | CC6.6 | Restriction of access to system components |
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | AC-10 | Concurrent session control |
| **NIST 800-53** | IA-5 | Authenticator management |

**Vendor Reference:** [Enabling OAuth 2.0 authentication for the PingFederate administrative API](https://docs.pingidentity.com/pingfederate/12.3/developers_reference_guide/pf_enable_native_auth_for_admin_api.html)

---

### 1.6 Harden PingOne Advanced Identity Cloud Tenants

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2, 6.3, 6.5 |
| NIST 800-53 | AC-10, IA-2(1), IA-5(1), CM-7, SC-28 |

#### Description
Apply the baseline tenant hardening Ping publishes for PingOne Advanced Identity Cloud (the ForgeRock-lineage platform): mandatory 2-step verification for tenant administrators, short admin session expiry, a strong password policy, deactivation of unused journeys and realms, and secrets held in Environment Secrets and Variables rather than plaintext configuration.

#### Rationale
**Why This Matters:**
- Advanced Identity Cloud tenant administrators can rewrite authentication journeys, so a single compromised tenant admin can silently insert a bypass that authenticates anyone as anyone
- Journeys are executable authentication logic, and every unused journey or hosted page left active is a reachable code path nobody is reviewing — deactivating them removes attack surface that provides no business value
- A 15-minute admin session expiry limits how long an unattended or hijacked browser session remains usable against the highest-privilege console in the identity stack
- Password minimums with reuse blocking matter specifically here because directory credentials protected by this policy often gate downstream federation for the whole enterprise
- Secrets pasted into scripts, connector configuration, or journey nodes end up in configuration exports, promotion artifacts, and version control; ESVs keep them out of every one of those copies
- This entire product family is absent from most Ping hardening baselines, which is precisely why unhardened tenants persist

**Attack Prevented:** Tenant administrator takeover, malicious journey modification and authentication bypass, credential reuse across compromised systems, secret disclosure through configuration export or promotion artifacts, exploitation of forgotten sample journeys and dormant realms

#### ClickOps Implementation

**Step 1: Require 2-Step Verification for Tenant Administrators**
1. Sign in to the Advanced Identity Cloud admin UI as a tenant administrator
2. Navigate to: **Tenant settings → Global settings** (exact labels vary by release — see the vendor security-planning reference below)
3. Require 2-step verification for every tenant administrator account, with no exemptions for service or break-glass accounts beyond a documented and monitored exception
4. Confirm each administrator has enrolled a factor from their account profile, and remove or disable administrator accounts that have not enrolled

**Step 2: Shorten Administrative Session Expiry**
1. In tenant settings, set the administrative session expiry to **15 minutes**
2. Confirm the setting applies to the admin UI rather than only to end-user journeys

**Step 3: Strengthen the Password Policy**
1. Open the identity management console for the tenant (**Native Consoles → Identity Management**) and go to the password policy configuration
2. Set the minimum password length to **12 characters**
3. Block reuse of the previous **3** passwords
4. Communicate the change before enforcement so a forced reset does not arrive unannounced to the whole user base

**Step 4: Deactivate Unused Journeys, Pages, and Realms**
1. Navigate to: **Journeys** and inventory every journey in each realm
2. Deactivate or delete journeys with no documented business owner, including sample and template journeys shipped with the tenant
3. Deactivate unused hosted pages
4. Deactivate realms that are not in active use, keeping only those with a documented purpose
5. Record the surviving inventory so future additions are reviewable against a known baseline

**Step 5: Move Secrets into ESVs**
1. Navigate to the tenant's **Environment Secrets and Variables** configuration
2. Create an ESV for every API key, service credential, and password currently held in journey nodes, connector configuration, or scripts
3. Replace each plaintext value with its ESV placeholder reference
4. Apply the change to the environment and confirm the dependent journeys and connectors still function
5. Establish a rotation cadence for each ESV and record the owner

#### Validation & Testing
1. Sign in as a tenant administrator and confirm the 2-step verification prompt appears; attempt an administrator sign-in with an account that has not enrolled and confirm it cannot proceed
2. Leave an admin session idle past 15 minutes and confirm re-authentication is required rather than the session silently continuing
3. Attempt to set an 11-character password and a recently used password, and confirm both are rejected
4. Export the tenant configuration and search it for credential-like strings; only ESV placeholder references should appear, with no plaintext secret values
5. List active journeys per realm and confirm every one maps to a documented business owner
6. Confirm deactivating the unused journeys did not break a live authentication path by running each documented journey end to end in a staging tenant first

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **SOC 2** | CC6.3 | Least privilege and removal of unnecessary access |
| **NIST 800-53** | IA-2(1) | MFA for privileged accounts |
| **NIST 800-53** | IA-5(1) | Password-based authenticator management |
| **NIST 800-53** | CM-7 | Least functionality |
| **NIST 800-53** | SC-28 | Protection of information at rest |

**Vendor Reference:** [PingOne Advanced Identity Cloud — plan for security](https://docs.pingidentity.com/pingoneaic/latest/planning/plan-security.html)

---

## 2. Federation Security

### 2.1 Harden SAML Federation Trust

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5, SC-23

#### Description
Configure secure SAML settings to prevent assertion manipulation and replay attacks.

#### Rationale
**Why This Matters:**
- SAML assertions can be manipulated if not properly validated
- Weak signature algorithms enable forgery
- Long assertion validity enables replay attacks

**Attack Prevented:** SAML assertion forgery, manipulation, and replay across federation trust

**Attack Scenario:** Federation trust exploitation enables attackers to generate valid tokens for any connected application.

#### ClickOps Implementation (PingFederate)

**Step 1: Configure Secure Signature Settings**
1. Navigate to: **System → Server Configuration → Signing & Encryption**
2. Configure:
   - **Signature Algorithm:** RSA-SHA256 (minimum)
   - **Digest Algorithm:** SHA-256 (minimum)
   - **Key Size:** 2048+ bits RSA or P-256 ECDSA
3. Disable: SHA-1 algorithms

**Step 2: Configure Assertion Validation**
1. Navigate to: **Identity Provider → Connection → SAML Settings**
2. Enable:
   - **Verify Signature:** Required
   - **Require Encrypted Assertions:** Yes (L2)
   - **Audience Restriction:** Enforce
3. Set:
   - **Assertion Valid Period:** 5 minutes (maximum)
   - **Session Timeout:** 8 hours

**Step 3: Configure Certificate Validation**
1. Navigate to: **Security → Certificate Management**
2. Enable:
   - **Certificate revocation checking:** CRL or OCSP
   - **Key usage validation:** Enabled
3. Configure: Certificate expiration alerts (30 days)

#### Code Implementation

{% include pack-code.html vendor="ping-identity" section="2.1" %}

---

### 2.2 Implement Federation Monitoring

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-6, SI-4

#### Description
Monitor federation activity for anomalous patterns indicating compromise.

#### Rationale
**Why This Matters:**
- Federation is the trust hub connecting enterprise identity to hundreds of downstream applications, so abuse there cascades everywhere
- Anomalous assertion volumes, new SP relationships, or off-hours token issuance are early indicators of trust exploitation
- Without monitoring, attackers minting valid tokens through federation leave little obvious trace at the application tier
- Timely detection shrinks dwell time and enables revocation before a compromised trust relationship is fully weaponized

**Attack Prevented:** Federation trust exploitation, token forgery, undetected persistence, rogue SP registration

#### Detection Use Cases

See the DB pack below for federation monitoring queries.

---

### 2.3 Certificate Lifecycle Management

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-12

#### Description
Implement proactive certificate management to prevent federation disruption.

#### Rationale
**Why This Matters:**
- Expired signing or encryption certificates break federation, causing outages that pressure teams into insecure emergency workarounds
- Proactive rotation with dual-certificate overlap keeps SAML/OIDC trust intact without service interruption
- Tracking certificate expiry and key usage prevents silent failures and weak or stale keys lingering in trust relationships
- Coordinated rotation with service providers avoids rushed manual changes that frequently introduce misconfigurations

**Attack Prevented:** Federation outage-driven misconfiguration, stale-key compromise, emergency bypass of validation controls

#### ClickOps Implementation

**Step 1: Configure Certificate Rotation**
1. Navigate to: **Security → Certificate Management**
2. Enable: **Automatic certificate renewal alerts**
3. Set thresholds:
   - 90 days: Warning
   - 30 days: Critical alert
   - 14 days: Emergency procedures

**Step 2: Implement Dual Certificate**
1. Add new certificate before old expires
2. Configure SP connections to accept both
3. Coordinate rotation with SPs
4. Remove old certificate after validation

{% include pack-code.html vendor="ping-identity" section="2.3" %}

---

## 3. OAuth & Token Security

### 3.1 Configure Secure OAuth Settings

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(13), SC-23

#### Description
Harden OAuth authorization server configuration with short token lifetimes and restricted scopes.

#### Rationale
**Why This Matters:**
- Short access and authorization code lifetimes limit the window an intercepted or leaked token can be replayed
- Requiring PKCE and disabling implicit and password grants closes well-known OAuth flows that leak tokens or enable credential theft
- Scoped, least-privilege tokens ensure a stolen token grants minimal access rather than broad enterprise reach
- Token binding ties credentials to a client so exfiltrated tokens cannot be used from attacker-controlled machines

**Attack Prevented:** Token replay, authorization code interception, token theft via implicit grant, scope over-provisioning

#### ClickOps Implementation (PingOne)

**Step 1: Configure Token Lifetimes**
1. Navigate to: **Applications → OAuth Settings**
2. Configure:
   - **Access Token Lifetime:** 1 hour (maximum)
   - **Refresh Token Lifetime:** 7 days (L1) / 24 hours (L2)
   - **ID Token Lifetime:** 1 hour
   - **Authorization Code Lifetime:** 60 seconds

**Step 2: Enable Token Binding**
1. Navigate to: **Applications → [App] → OAuth Settings**
2. Enable:
   - **Require PKCE:** For public clients
   - **Token binding:** Certificate-bound tokens (L2)

**Step 3: Restrict Grant Types**
1. Disable unnecessary grant types:
   - Implicit grant: Disabled (deprecated)
   - Resource Owner Password: Disabled unless required
2. Enable only: Authorization Code with PKCE

#### Code Implementation

See the API pack below for OAuth application configuration.

{% include pack-code.html vendor="ping-identity" section="3.1" %}

---

### 3.2 Implement Token Revocation

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-2(6)

#### Description
Enable token revocation for user sessions and compromised tokens.

#### Rationale
**Why This Matters:**
- OAuth and session tokens grant standing access until they expire, so revocation is the only way to immediately cut off a compromised credential
- Propagating revocation to all connected applications ensures one terminate action closes every federated session
- Automatic revocation on detected high-risk authentication contains account takeover before attackers act on access
- Verified, tested revocation procedures are essential for fast, reliable incident response

**Attack Prevented:** Persistent access with stolen tokens, account takeover continuation, session hijacking, delayed incident containment

#### ClickOps Implementation

**Step 1: Enable Session Revocation**
1. Navigate to: **Authentication → Session Management**
2. Enable:
   - **Allow session revocation:** Yes
   - **Propagate revocation:** To all connected apps

**Step 2: Configure Revocation on Risk**
1. Navigate to: **Authentication → Risk Policies**
2. Create rule:
   - **Trigger:** High-risk authentication detected
   - **Action:** Revoke all user tokens
   - **Notify:** Security team

**Step 3: Admin Revocation Capability**
1. Verify admin can revoke user sessions
2. Document incident response procedure
3. Test revocation propagation

{% include pack-code.html vendor="ping-identity" section="3.2" %}

---

### 3.3 OAuth Consent Management

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-6

#### Description
Control OAuth consent to prevent unauthorized application access.

#### Rationale
**Why This Matters:**
- Unrestricted user consent lets attackers trick users into authorizing malicious applications that gain long-lived API access
- Requiring admin consent for new applications interrupts illicit consent grant attacks before tokens are issued
- Periodic review and revocation of granted permissions removes dormant or over-scoped third-party access
- Centralized consent governance prevents shadow integrations from quietly accumulating access to enterprise data

**Attack Prevented:** Illicit consent grant (consent phishing), malicious OAuth app authorization, over-permissioned third-party access

#### ClickOps Implementation

**Step 1: Enable Admin Consent Requirement**
1. Navigate to: **Applications → Settings**
2. Enable: **Require admin consent for new applications**
3. Configure approval workflow

**Step 2: Review Existing Consents**
1. Navigate to: **Identities → User → Authorized Applications**
2. Audit granted permissions
3. Revoke unnecessary or suspicious consents

{% include pack-code.html vendor="ping-identity" section="3.3" %}

---

## 4. DaVinci Orchestration Security

### 4.1 Secure DaVinci Flows

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3, CM-3

#### Description
Harden PingOne DaVinci orchestration flows to prevent abuse and unauthorized workflow execution.

#### Rationale
**Why This Matters:**
- DaVinci flows automate identity processes
- Misconfigured flows enable privilege escalation
- Compromised flows provide persistent backdoors

**Attack Prevented:** Privilege escalation and persistent backdoors via misconfigured or compromised orchestration flows

#### ClickOps Implementation

**Step 1: Implement Flow Approval Workflow**
1. Navigate to: **DaVinci → Settings**
2. Enable:
   - **Require approval for flow changes:** Yes
   - **Approvers:** Security team

**Step 2: Audit Existing Flows**
1. Navigate to: **DaVinci → Flows**
2. For each flow, verify:
   - Business justification documented
   - Minimal permissions required
   - Error handling doesn't leak information
   - Logging enabled

**Step 3: Restrict Sensitive Connectors**
1. Identify high-risk connectors:
   - User provisioning
   - Group management
   - Password reset
2. Limit to approved flows only
3. Require additional authentication for sensitive actions

**Step 4: Enable Flow Logging**
1. Navigate to: **DaVinci → Settings → Logging**
2. Enable:
   - **Log all flow executions:** Yes
   - **Include input/output:** Masked sensitive data
   - **Retention:** 90 days minimum

{% include pack-code.html vendor="ping-identity" section="4.1" %}

---

### 4.2 Version Control for Flows

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-3

#### Description
Implement version control and change management for DaVinci flows.

#### Rationale
**Why This Matters:**
- DaVinci flows orchestrate authentication and provisioning, so an unreviewed change can silently weaken identity controls
- Git-backed version control with pull-request review enforces peer approval and creates an auditable change history
- A staging environment lets flow changes be tested before they touch production authentication paths
- Documented rollback restores a known-good flow quickly if a change introduces a vulnerability or outage

**Attack Prevented:** Unauthorized flow tampering, backdoor injection into orchestration, untracked privilege-escalation changes, change-induced outages

#### Implementation

1. Export flows regularly to git repository
2. Require pull request for changes
3. Implement staging environment for testing
4. Document rollback procedures

{% include pack-code.html vendor="ping-identity" section="4.2" %}

---

## 5. Monitoring & Detection

### 5.1 Configure Comprehensive Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3, AU-6

#### Description
Enable comprehensive audit logging for all identity operations.

#### Rationale
**Why This Matters:**
- Comprehensive logs of authentication, administrative, API, and DaVinci events are the foundation for detecting and investigating compromise
- Exporting logs to a SIEM preserves evidence beyond the platform and enables correlation across the enterprise
- Real-time alerts on high-risk events such as disabled MFA policies or new high-privilege grants catch attacker activity as it happens
- Without durable audit trails, breaches go undetected and forensic reconstruction after an incident is impossible

**Attack Prevented:** Undetected intrusion, audit-trail tampering, delayed breach discovery, repudiation of malicious admin actions

#### ClickOps Implementation (PingOne)

**Step 1: Configure Audit Settings**
1. Navigate to: **Settings → Audit**
2. Enable:
   - **Authentication events:** All
   - **Administrative events:** All
   - **API events:** All
   - **DaVinci flow events:** All

**Step 2: Configure Log Export**
1. Navigate to: **Settings → Audit → Export**
2. Configure SIEM integration:
   - S3 bucket export
   - Webhook to SIEM
   - Splunk integration

**Step 3: Configure Alerts**
1. Navigate to: **Settings → Alerts**
2. Create alerts for:
   - Failed admin authentication (>5 in 5 minutes)
   - New application created
   - MFA policy disabled
   - High-privilege role assigned

#### Detection Queries

See the DB pack below for SIEM detection queries.

{% include pack-code.html vendor="ping-identity" section="5.1" %}

---

### 5.2 Maintain Patch Currency for Servers, Agents, and Adapters

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.2, 7.3, 7.4 |
| NIST 800-53 | SI-2, RA-5, CM-8 |

#### Description
Inventory every deployed Ping component — including policy agents, adapters, and integration kits that ship on their own release cadence — and patch them against known CVEs on a defined SLA.

#### Rationale
**Why This Matters:**
- Policy agents enforce authorization in front of protected applications, so an agent vulnerability is an authorization bypass rather than a contained server bug — CVE-2025-20059 (CVSS 9.1, CRITICAL) is a relative path traversal in the PingAM Java Policy Agent that allows policy-enforcement bypass and parameter injection
- Agents and adapters are the components most often missed, because they are installed on application servers by application teams and then tracked separately from — or not at all alongside — the identity platform itself
- Adapters can fail in ways that take down authentication for everyone: CVE-2025-22854 (CVSS 6.9) is a thread-exhaustion flaw in the PingFederate Google Adapter triggered by non-200 responses, turning a dependency outage into an identity outage
- Identity infrastructure is the highest-value target in the estate, so the exploitation window for a public identity CVE is short and generic monthly patch cycles are too slow for the critical ones
- Without a version inventory, "are we affected?" cannot be answered during an advisory response, and the default answer becomes an untested assumption

**Attack Prevented:** Policy-enforcement bypass via path traversal in unpatched agents, parameter injection against protected applications, denial of service through adapter thread exhaustion, exploitation of known CVEs during the window between disclosure and patching

#### ClickOps Implementation

**Step 1: Build the Component Inventory**
1. Record every deployed Ping component with its version and host: PingFederate and PingAM servers, PingOne Advanced Identity Cloud tenants, policy agents, PingGateway instances, adapters, connectors, and integration kits
2. Name an owner for each entry — agents installed on application servers frequently have a different owner than the identity platform itself
3. Keep the inventory in your CMDB or asset register rather than a spreadsheet nobody updates after the first pass

**Step 2: Remediate the Known Critical Agent Vulnerability**
1. Identify every PingAM Java Policy Agent deployment and check its version
2. Versions through **5.10.3**, **2023.11.1**, and **2024.9** are affected by CVE-2025-20059
3. Upgrade to **5.10.4**, **2023.11.2**, or **2024.11** as appropriate for your branch
4. Restart the protected application's web or application server so the patched agent loads
5. Repeat for every agent instance — a single unpatched agent leaves its protected application bypassable regardless of how current the PingAM server is

**Step 3: Update Adapters and Integration Kits**
1. Check the version of every deployed PingFederate adapter, including the Google Adapter affected by CVE-2025-22854
2. Update each adapter to the current release from the vendor's integration directory
3. Treat adapters as independently versioned software with their own upgrade testing, not as part of the PingFederate server upgrade

**Step 4: Define and Enforce Patch SLAs**
1. Set remediation deadlines by severity — for example, Critical within 7 days, High within 30 days, and same-day for anything actively exploited
2. Require an approved, time-bound exception with compensating controls for anything that will miss its deadline
3. Review outstanding items at a recurring security cadence rather than only during audits

#### Validation & Testing
1. Verify the reported version of each policy agent on its host and confirm it is at or above the patched release; do not rely on the version recorded at install time
2. From a staging environment, send a request containing encoded relative path traversal segments to a policy-protected URI and confirm the agent enforces policy rather than passing the request through
3. Confirm the PingFederate administrative console reports the expected server and adapter versions after each upgrade
4. Exercise an authentication flow that depends on the updated adapter and confirm it completes successfully
5. Reconcile the component inventory against what is actually running at least quarterly, and treat any host in one but not the other as a finding
6. Confirm each open advisory item has an owner and a due date consistent with the SLA

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC7.1 | Detection and monitoring of configuration changes and vulnerabilities |
| **SOC 2** | CC8.1 | Change management |
| **NIST 800-53** | SI-2 | Flaw remediation |
| **NIST 800-53** | RA-5 | Vulnerability monitoring and scanning |
| **NIST 800-53** | CM-8 | System component inventory |
| **PCI DSS** | 6.3.3 | Installation of applicable security patches |

**Vendor Reference:** [CVE-2025-20059 — NVD detail](https://nvd.nist.gov/vuln/detail/cve-2025-20059) · [CVE-2025-22854 — vulnerability database entry](https://www.wiz.io/vulnerability-database/cve/cve-2025-22854)

---

### 5.3 Monitor Ping Security Advisories

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 7.1 |
| NIST 800-53 | SI-5, SI-2, RA-5 |

#### Description
Assign an owner to Ping's per-product security advisory index and review it on a defined cadence, rather than relying on NVD or CISA KEV feeds to surface Ping and ForgeRock vulnerabilities.

#### Rationale
**Why This Matters:**
- Ping and ForgeRock advisories are not reliably mirrored into the feeds most vulnerability programs actually watch, so an organization monitoring only NVD and CISA KEV can miss a critical identity advisory entirely
- The vendor advisory index is where affected version ranges and fixed releases are stated authoritatively — that is exactly the information needed to answer "are we affected?" during a response
- Advisories cover the whole product family including PingAM, PingFederate, PingOne, and the agents and adapters that vulnerability scanners rarely fingerprint correctly
- An unowned feed is an unread feed; naming an owner and a cadence is what converts a bookmark into a control
- Advisory monitoring is the input to patch currency (control 5.2) — without it, the patch SLA has nothing to trigger it

**Attack Prevented:** Exploitation of disclosed vulnerabilities that never surfaced in general vulnerability feeds, delayed response to critical identity advisories, blind spots on agents and adapters that scanners do not detect

#### ClickOps Implementation

**Step 1: Subscribe to the Advisory Sources**
1. Bookmark the Ping security advisory index for every product in use — PingAM, PingFederate, PingOne, PingOne Advanced Identity Cloud, PingGateway, PingIDM, and PingDS
2. Subscribe to vendor security notifications through the Ping support portal for the accounts associated with your deployments
3. Route notifications to a monitored team mailbox or ticket queue, never to an individual's inbox

**Step 2: Assign Ownership and Cadence**
1. Name the accountable owner for advisory review — typically the identity platform owner, with the vulnerability management team as backup
2. Set a review cadence of at least weekly, with an out-of-band path for advisories marked Critical
3. Include the on-call rotation in the distribution so a Critical advisory arriving outside business hours is seen

**Step 3: Triage Each Advisory**
1. For each new advisory, compare the affected version ranges against the component inventory from control 5.2
2. Open a tracked remediation ticket for anything that applies, with a due date drawn from the patch SLA
3. Record a dated "not applicable" determination for advisories that do not apply, so the review is evidenced either way

**Step 4: Supplement, Do Not Replace, Your Existing Feeds**
1. Keep NVD and CISA KEV monitoring in place for cross-coverage
2. Treat the vendor index as authoritative for affected and fixed version numbers where the two disagree

#### Validation & Testing
1. Confirm a dated record exists showing the advisory index was reviewed within the current cadence window
2. Select a known advisory — CVE-2025-20059 is a good test case — and confirm it was triaged, with either a remediation ticket or a documented not-applicable determination
3. Send a test message to the notification distribution and confirm it reaches the monitored queue and the on-call rotation
4. Confirm the named owner and backup are current after any team change; an advisory routed to a departed employee is an unmonitored feed
5. Spot-check that at least one advisory-driven ticket was closed within its SLA, demonstrating the review connects to remediation rather than ending at triage

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC7.1 | Vulnerability identification |
| **SOC 2** | CC3.2 | Risk identification and analysis |
| **NIST 800-53** | SI-5 | Security alerts, advisories, and directives |
| **NIST 800-53** | SI-2 | Flaw remediation |
| **NIST 800-53** | RA-5 | Vulnerability monitoring and scanning |

**Vendor Reference:** [PingAM security advisories index](https://docs.pingidentity.com/pingam/release-notes/security-advisories.html)

---

## 6. Third-Party Integration Security

### 6.1 SP Connection Hardening

**Profile Level:** L1 (Crawl)

#### Description
Harden Service Provider (SP) connections in federation.

#### Rationale
**Why This Matters:**
- Each SP connection is a trust relationship that, if loosely configured, can be abused to replay or redirect assertions
- Verifying SP certificates and enforcing audience restriction ensures assertions are only accepted by their intended recipient
- Minimal assertion validity and encryption reduce the value and reusability of intercepted federation tokens
- A documented business owner per connection enables timely review and decommissioning of stale or risky integrations

**Attack Prevented:** Assertion replay, audience confusion / token redirection, stale SP trust abuse, assertion interception

#### For Each SP Connection:
- ✅ Verify SP certificate validity
- ✅ Configure audience restriction
- ✅ Set minimum assertion validity
- ✅ Enable encryption (L2)
- ✅ Document business owner

{% include pack-code.html vendor="ping-identity" section="6.1" %}

### 6.2 API Client Management

| Client Type | Token Lifetime | Scopes | Controls |
|-------------|---------------|--------|----------|
| **SCIM Provisioner** | 1 hour | Users, Groups | IP restriction, audit logging |
| **SSO Application** | 4 hours | OpenID, Profile | Standard validation |
| **Admin API** | 15 minutes | Admin scopes | MFA required, IP restriction |
| **Reporting** | 1 hour | Read-only | Dedicated service account |

{% include pack-code.html vendor="ping-identity" section="6.2" %}

---

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Ping Identity Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA enforcement | 1.1 |
| CC6.2 | RBAC | 1.2 |
| CC6.6 | IP restrictions | 1.3 |
| CC6.1 | Risk-based adaptive authentication | 1.4 |
| CC6.6 | Admin API authentication hardening | 1.5 |
| CC6.3 | Advanced Identity Cloud tenant hardening | 1.6 |
| CC7.2 | Audit logging | 5.1 |
| CC7.1 | Patch currency for servers, agents, adapters | 5.2 |
| CC7.1 | Security advisory monitoring | 5.3 |

### NIST 800-53 Mapping

| Control | Ping Identity Control | Guide Section |
|---------|------------------|---------------|
| IA-2(6) | Phishing-resistant MFA | 1.1 |
| AC-2(12) | Risk-based adaptive authentication | 1.4 |
| AC-10 | Concurrent admin session control | 1.5 |
| CM-7 | Deactivate unused journeys and realms | 1.6 |
| IA-5 | Federation security | 2.1 |
| SC-23 | Token security | 3.1 |
| AU-2 | Audit logging | 5.1 |
| SI-2 | Flaw remediation / patch currency | 5.2 |
| SI-5 | Security alerts and advisories | 5.3 |

---

## Appendix A: Edition Compatibility

| Control | PingOne Essentials | PingOne Plus | PingOne Enterprise |
|---------|-------------------|--------------|-------------------|
| MFA | ✅ | ✅ | ✅ |
| FIDO2 | ❌ | ✅ | ✅ |
| DaVinci | ❌ | Limited | ✅ |
| Risk-Based Auth | ❌ | ❌ | ✅ |
| API Access | Limited | ✅ | ✅ |

---

## Appendix B: References

**Official Ping Identity Documentation:**
- [Trust Center](https://www.pingidentity.com/en/legal/trust-center.html)
- [Security Exhibits](https://www.pingidentity.com/en/legal/security-exhibit.html)
- [Documentation Portal](https://docs.pingidentity.com/)
- [PingOne Security Guide](https://docs.pingidentity.com/pingone)
- [PingFederate Administration](https://docs.pingidentity.com/pingfederate)
- [Security Best Practices](https://docs.pingidentity.com/pingoneforenterprise/pingone_for_enterprise/p14e_security_best_practices.html)

**API Documentation:**
- [PingOne API Reference](https://apidocs.pingidentity.com/pingone/main/v1/api/)
- [API Documentation Portal](https://apidocs.pingidentity.com)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27018, CSA STAR Level 2 — via [Trust Center](https://www.pingidentity.com/en/legal/trust-center.html)

**Security Advisories:**
- [PingAM Security Advisories Index](https://docs.pingidentity.com/pingam/release-notes/security-advisories.html) — authoritative source for affected and fixed versions across the Ping and ForgeRock product family. Ping and ForgeRock advisories are not reliably mirrored into NVD or the CISA KEV catalog, so this index should be monitored directly (see control 5.3).

**Known Vulnerabilities:**

There have been no publicly disclosed breaches of Ping Identity's own corporate or SaaS infrastructure, and Ping Identity operates a bug bounty program through HackerOne. Product vulnerabilities affecting customer deployments have been disclosed, however, and the most significant are below.

| CVE | CVSS | Component | Impact | Fixed In |
|-----|------|-----------|--------|----------|
| [CVE-2025-20059](https://nvd.nist.gov/vuln/detail/cve-2025-20059) | ~9.1 (Critical) | PingAM Java Policy Agent (through 5.10.3, 2023.11.1, 2024.9) | Relative path traversal allowing policy-enforcement bypass and parameter injection against protected applications | 5.10.4, 2023.11.2, 2024.11 |
| [CVE-2025-22854](https://www.wiz.io/vulnerability-database/cve/cve-2025-22854) | 6.9 (Medium) | PingFederate Google Adapter | Thread exhaustion triggered by non-200 responses, causing denial of service | Current adapter release |

Both affect components customers deploy and patch themselves rather than vendor-hosted infrastructure, which is why component-level patch currency (control 5.2) and direct advisory monitoring (control 5.3) matter more here than vendor incident history.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.1 | draft | Cheat-sheet cell repair: added missing Attack Prevented line(s) to §1.1, §2.1, §4.1 (no content-facts changed) | Claude Code (Fable 5) |
| 2026-08-03 | 0.2.0 | draft | Correct false "no major incidents" claim (CVE-2025-20059, CVE-2025-22854); add controls 1.4 PingOne Protect risk-based auth, 1.5 PingFederate admin API hardening, 1.6 Advanced Identity Cloud tenant hardening, 5.2 patch currency, 5.3 advisory monitoring; expand Overview product scope | Claude Code (Sonnet 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Ping Identity hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
