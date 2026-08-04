---
layout: guide
title: "Cloudflare Zero Trust Hardening Guide"
vendor: "Cloudflare"
slug: "cloudflare"
tier: "1"
category: "Security"
description: "Security hardening for Cloudflare Zero Trust, Access, Gateway, and WARP deployment"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-03"
---

## Overview

Cloudflare Zero Trust is a comprehensive security platform providing secure access to applications, DNS filtering, and endpoint protection. With **billions of DNS queries processed daily** and protection for millions of users, Cloudflare's Zero Trust services are critical infrastructure for modern security architectures. This guide covers hardening Access (ZTNA), Gateway (SWG/CASB), and WARP (endpoint agent).

### Intended Audience
- Security engineers managing Cloudflare Zero Trust deployments
- IT administrators configuring access policies
- GRC professionals assessing Zero Trust compliance
- Third-party risk managers evaluating security tools

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Cloudflare Zero Trust components including Access, Gateway, WARP client, and Tunnel configurations. CDN and DDoS protection are covered in separate guides.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Access Application Policies](#2-access-application-policies)
3. [Gateway Security Policies](#3-gateway-security-policies)
4. [WARP Client Hardening](#4-warp-client-hardening)
5. [Tunnel Security](#5-tunnel-security)
6. [Monitoring & Detection](#6-monitoring--detection)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Configure Identity Provider Integration

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Integrate Cloudflare Zero Trust with your corporate identity provider to enable SSO authentication for Access applications and WARP enrollment.

#### Rationale
**Why This Matters:**
- Centralizes authentication management
- Enables MFA through your IdP
- Provides consistent identity across all Zero Trust services
- Enables user and group-based policies

#### Prerequisites
- Cloudflare Zero Trust account
- Identity provider with OIDC or SAML support
- Admin access to Zero Trust dashboard

#### ClickOps Implementation

**Step 1: Add Identity Provider**
1. Navigate to: **Zero Trust Dashboard** → **Settings** → **Authentication**
2. Click **Add new**
3. Select your IdP type:
   - **Okta, Azure AD, OneLogin:** Use preconfigured templates
   - **Generic OIDC/SAML:** Manual configuration
4. Configure IdP settings:
   - **Client ID/Secret:** From IdP application
   - **Authorization URL:** IdP OAuth endpoint
   - **Token URL:** IdP token endpoint

**Step 2: Configure IdP (Example: Okta)**
1. In Okta Admin: **Applications** → **Create App Integration**
2. Select OIDC - Web Application
3. Configure:
   - **Sign-in redirect:** `https://<team-name>.cloudflareaccess.com/cdn-cgi/access/callback`
   - **Sign-out redirect:** `https://<team-name>.cloudflareaccess.com`
4. Assign users/groups
5. Copy Client ID and Secret to Cloudflare

**Step 3: Test Authentication**
1. In Cloudflare, click **Test** on IdP configuration
2. Verify successful authentication
3. Enable the IdP for production use

**Time to Complete:** ~45 minutes

---


{% include pack-code.html vendor="cloudflare" section="1.1" %}

### 1.2 Configure Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Ensure MFA is enforced for all Access application authentications through IdP policies or Cloudflare's additional MFA requirements.

#### Rationale
**Why This Matters:**
- Passwords alone are routinely defeated by phishing, credential stuffing, and reuse — MFA adds a second factor an attacker is far less likely to possess
- Cloudflare Access sits in front of internal and SaaS applications, so a single bypassed login can expose every protected resource
- Enforcing MFA at the IdP or in the Access policy guarantees the requirement applies to every authentication, not just the logins users choose to protect
- Phishing-resistant factors (FIDO2/WebAuthn) defeat real-time relay attacks that one-time codes cannot stop

**Attack Prevented:** Credential theft, phishing, credential stuffing, password reuse, account takeover

#### ClickOps Implementation

**Option A: Enforce MFA via IdP (Recommended)**
1. Configure MFA requirement in your identity provider
2. Create IdP policy requiring MFA for Cloudflare application
3. All Access authentications will require MFA

**Option B: Cloudflare Access Policy Requirement**
1. In Access application policy, add requirement:
   - **Rule type:** Require
   - **Selector:** Login Methods
   - **Value:** Select IdPs with MFA configured
2. Optionally add additional authentication factor via policy

---


{% include pack-code.html vendor="cloudflare" section="1.2" %}

### 1.3 Harden Device Enrollment

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 1.4, 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure device enrollment policies to control which devices can enroll in WARP and access your Zero Trust network.

#### Rationale
**Why This Matters:**
- Once enrolled, devices join your Zero Trust network
- Uncontrolled enrollment creates security risk
- Enrollment policies prevent unauthorized device access

#### ClickOps Implementation

**Step 1: Configure Enrollment Policies**
1. Navigate to: **Settings** → **WARP Client** → **Device enrollment permissions**
2. Click **Manage** → **Add a rule**
3. Configure enrollment restrictions:
   - **Emails ending in:** @yourdomain.com
   - **Identity provider groups:** Specific groups only
   - **Country:** Allowed countries only

**Step 2: Require IdP Authentication**
1. In enrollment rule, require authentication via IdP
2. Add additional conditions:
   - Specific IdP login method (e.g., Okta with MFA)
   - Geographic restrictions
3. Save rule

**Time to Complete:** ~20 minutes

---


{% include pack-code.html vendor="cloudflare" section="1.3" %}

### 1.4 Configure Admin Role Restrictions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Configure granular admin roles in Cloudflare to limit dashboard access based on job responsibilities.

#### Rationale
**Why This Matters:**
- Super Administrator access grants full control over Zero Trust policies, DNS, and account settings — a compromised admin account can disable every protection at once
- Assigning least-privilege roles limits the blast radius if any single admin credential is phished or stolen
- Scoped roles such as Zero Trust Admin and Audit Log Viewer let teams do their jobs without holding billing or account-wide change rights
- Fewer privileged accounts means a smaller, more defensible attack surface for adversaries to target

**Attack Prevented:** Privilege escalation, insider misuse, account takeover, unauthorized configuration change

#### ClickOps Implementation

**Step 1: Review Member Access**
1. Navigate to: **Cloudflare Dashboard** → **Manage Account** → **Members**
2. Review current member roles
3. Document Super Administrator assignments

**Step 2: Implement Least Privilege**
1. Available roles:
   - **Super Administrator:** Full access (limit to 2-3)
   - **Administrator:** Most settings, no billing
   - **Zero Trust Admin:** Zero Trust only
   - **Audit Log Viewer:** Read-only logs
2. Assign appropriate roles per responsibility
3. Remove unnecessary Super Administrator access

---


{% include pack-code.html vendor="cloudflare" section="1.4" %}

### 1.5 Retire the Global API Key and Enforce Scoped API Tokens

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-6(1), IA-5 |

#### Description
Eliminate use of the Global API Key — a single credential with full account-wide privileges that never expires — and replace it with scoped API tokens that carry explicit permissions, an expiry (TTL), and client IP restrictions. For automation, CI/CD, and Terraform, use Account-Owned API Tokens so credentials belong to the account rather than to an individual member. Cloudflare states directly that the Global API Key is not recommended and that customers should migrate to API tokens ([Cloudflare API keys documentation](https://developers.cloudflare.com/fundamentals/api/get-started/keys/)).

#### Rationale
**Why This Matters:**
- The Global API Key grants full control of every zone and account setting the user can reach, so a single leaked key is equivalent to a full account takeover with no way to limit the damage short of rotating it
- The Global API Key has no scope, no expiry, and no IP restriction, which means a key pasted into a script, log, or support ticket stays valid indefinitely — Cloudflare rotated 104 API tokens after the 2025 Salesloft Drift incident precisely because credentials end up in support case text
- Scoped API tokens grant only the specific permissions a task needs (for example, DNS edit on one zone) and support a TTL and Client IP Address Filtering, so a stolen token is time-bound and usable only from expected networks
- Member-owned tokens die when the member is offboarded, silently breaking production automation; Account-Owned API Tokens (generally available since November 2024) are scoped to the account rather than to a person, so Terraform and CI/CD credentials survive admin turnover and are managed centrally by Super Administrators ([Cloudflare blog: account-owned tokens](https://blog.cloudflare.com/account-owned-tokens-automated-actions-zaraz/))

**Attack Prevented:** Full-account takeover via leaked credentials, unlimited credential lifetime, lateral privilege escalation, orphaned automation credentials surviving offboarding

#### ClickOps Implementation

**Step 1: Inventory Global API Key Usage**
1. Navigate to: **Cloudflare Dashboard** → **My Profile** → **API Tokens**
2. Under **API Keys**, note whether the Global API Key has been viewed or distributed
3. Search internal scripts, CI/CD secret stores, Terraform variable files, and runbooks for the header names `X-Auth-Email` and `X-Auth-Key` — these indicate Global API Key usage that must be migrated

**Step 2: Create a Scoped User API Token**
1. Navigate to: **My Profile** → **API Tokens** → **Create Token**
2. Start from a template or select **Create Custom Token**
3. Under **Permissions**, grant only the specific product, scope, and level required (for example, **Zone** → **DNS** → **Edit**)
4. Under **Zone Resources** / **Account Resources**, restrict the token to the exact zones or accounts it needs — never "All zones" unless genuinely required
5. Under **Client IP Address Filtering**, add the egress IP or CIDR of the system that will use the token
6. Under **TTL**, set an explicit start and expiry date rather than leaving the token permanent
7. Click **Continue to summary** → **Create Token** and store the value in a secrets manager immediately (it is displayed only once)

**Step 3: Create Account-Owned Tokens for Automation (L2)**
1. Navigate to: **Manage Account** → **API Tokens** (account scope, not profile scope)
2. Click **Create Token** and configure permissions, resources, IP filtering, and TTL as above
3. Use these tokens for Terraform, CI/CD pipelines, and any integration that must outlive an individual employee
4. Restrict who can create and view account-owned tokens to Super Administrators

**Step 4: Decommission the Global API Key**
1. Migrate every remaining consumer to a scoped token
2. Navigate to: **My Profile** → **API Tokens** → **API Keys** → **Global API Key** → **Change** to roll the key, invalidating any copies that remain in circulation
3. Repeat the roll for every account member who has ever retrieved their Global API Key

**Time to Complete:** ~60 minutes plus migration effort

#### Validation & Testing
1. Confirm no running system authenticates with `X-Auth-Email` / `X-Auth-Key` headers — all callers should send an `Authorization: Bearer` token instead
2. Verify each token's restrictions by calling the token verification endpoint from an IP outside the allowlist; the request must fail
3. Attempt an action outside the token's granted permissions (for example, editing a zone the token does not cover) and confirm it is rejected
4. Review **Audit Logs** for token creation events and confirm every token has a named owner and documented purpose
5. Set a calendar reminder ahead of each token's TTL expiry so rotation is planned rather than reactive

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| CIS Controls v8 | 5.4 | Restrict administrator privileges to dedicated administrator accounts |
| CIS Controls v8 | 6.8 | Define and maintain role-based access control |
| NIST 800-53 Rev 5 | AC-6(1) | Authorize access to security functions on a least-privilege basis |
| NIST 800-53 Rev 5 | IA-5 | Authenticator management, including lifetime and rotation |
| SOC 2 | CC6.1 | Logical access credentials are restricted and managed |

---

### 1.6 Enforce Two-Factor Authentication for Account Members

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Turn on account-level 2FA Enforcement so that every Cloudflare account member must have two-factor authentication enabled before they can accept an invitation or continue using the account. This control protects the administrators of the platform itself and is distinct from the MFA you require of end users through Access policies (section 1.2) ([Cloudflare two-factor authentication documentation](https://developers.cloudflare.com/fundamentals/account/account-security/2fa/)).

#### Rationale
**Why This Matters:**
- Access policies enforce MFA for the people using protected applications, but they do nothing for the administrators who log into the Cloudflare dashboard — those accounts control DNS, WAF, Zero Trust policy, and tunnel configuration for the entire estate
- A single compromised administrator password without 2FA lets an attacker disable Gateway policies, publish a tunnel hostname without an Access application, or repoint DNS, defeating every other control in this guide at once
- Relying on individual members to enable 2FA voluntarily produces uneven coverage; account-level enforcement makes it a condition of membership, so a member who has not enrolled cannot accept an invite or keep using the account
- Enforcement applies continuously rather than only at invitation time, so members who disable 2FA later are prompted back into compliance instead of silently dropping below the baseline

**Attack Prevented:** Administrator credential theft, phishing of dashboard logins, password reuse leading to platform-wide configuration compromise, account takeover

#### ClickOps Implementation

**Step 1: Enable 2FA on Your Own Account First**
1. Navigate to: **My Profile** → **Authentication**
2. Under **Two-Factor Authentication**, click **Manage**
3. Enrol an authenticator app or security key and complete verification
4. Download and securely store the backup codes — enforcement will lock out an unenrolled Super Administrator

**Step 2: Turn On Account-Level 2FA Enforcement**
1. Navigate to: **Manage Account** → **Configurations** → **Authentication**
2. Locate **Two-Factor Authentication Enforcement** (available to Super Administrators)
3. Enable enforcement for the account
4. Members without 2FA are required to enable it before accepting an invitation or continuing to use the account

**Step 3: Communicate and Remediate**
1. Notify members ahead of enabling enforcement so they can enrol without disruption
2. Review **Manage Account** → **Members** for anyone in a pending or non-compliant state
3. Prefer hardware security keys (WebAuthn) over one-time codes for Super Administrators, since keys resist real-time phishing relay

**Step 4: Pair with SSO Where Available (L2)**
1. On Enterprise plans, configure SSO for dashboard login so administrator authentication inherits the IdP's phishing-resistant factors and conditional access rules
2. Keep 2FA enforcement enabled as a backstop for any account not covered by SSO

**Time to Complete:** ~30 minutes

#### Validation & Testing
1. From **Manage Account** → **Members**, confirm every member shows a compliant 2FA status
2. Invite a test member and confirm the invitation cannot be accepted until 2FA is configured
3. Attempt a dashboard login with a valid password on a test account without 2FA and confirm the second factor is demanded
4. Review **Audit Logs** for `2fa` and membership events to confirm enforcement was enabled and by whom
5. Re-check member compliance on a recurring schedule (at least quarterly) as part of access review

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| CIS Controls v8 | 6.5 | Require MFA for administrative access |
| NIST 800-53 Rev 5 | IA-2(1) | Multi-factor authentication to privileged accounts |
| SOC 2 | CC6.1 | Authentication controls restrict access to authorized users |
| ISO 27001:2022 | A.5.17 | Authentication information management |

---

## 2. Access Application Policies

### 2.1 Create Secure Application Policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4 |
| NIST 800-53 | AC-3, AC-6 |

#### Description
Create Access policies that protect applications with identity-based, context-aware access controls.

#### Rationale
**Why This Matters:**
- Access policies define who can access each application
- Granular controls enable Zero Trust access
- Policies can require specific device posture
- Replaces VPN with identity-aware access

#### ClickOps Implementation

**Step 1: Add Application**
1. Navigate to: **Access** → **Applications**
2. Click **Add an application**
3. Select application type:
   - **Self-hosted:** Applications behind Cloudflare Tunnel
   - **SaaS:** Third-party SaaS applications
   - **Private network:** Internal IP ranges

**Step 2: Configure Application Settings**
1. Enter application details:
   - **Name:** Descriptive application name
   - **Domain:** Application URL
   - **Session duration:** 24 hours (adjust as needed)

**Step 3: Create Access Policy**
1. Click **Add a policy**
2. Configure policy rules:
   - **Policy name:** "Allow Engineering Team"
   - **Action:** Allow
   - **Include rules:**
     - **Emails ending in:** @yourdomain.com
     - **IdP Groups:** Engineering
   - **Require rules:**
     - **Login methods:** Your IdP
     - **Device posture:** WARP running

**Step 4: Harden Policy (L2)**
1. Add additional require rules:
   - **WARP:** Require WARP client
   - **Device Posture:** Require compliant device
   - **Location:** Restrict to specific countries
2. Add block rules for exceptions if needed

**Time to Complete:** ~30 minutes per application

---


{% include pack-code.html vendor="cloudflare" section="2.1" %}

### 2.2 Require WARP for Application Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 6.4 |
| NIST 800-53 | AC-2(11) |

#### Description
Configure Access policies to require WARP client for application access, enabling device posture checks and additional security controls.

#### Rationale
**Why This Matters:**
- Requiring WARP ensures every request to a protected application originates from a managed, enrolled device rather than an arbitrary browser
- WARP routes traffic through Gateway, so all access is subject to DNS, HTTP, and network inspection instead of bypassing security controls
- Device posture signals such as encryption, OS version, and security agents can only be evaluated when the WARP client is present and connected
- Blocking non-WARP access closes the gap where stolen credentials alone would otherwise be sufficient to reach sensitive apps

**Attack Prevented:** Unmanaged-device access, credential-only access, security-control bypass, data exfiltration

#### ClickOps Implementation

**Step 1: Enable WARP Requirement in Policy**
1. Edit Access application policy
2. Add **Require** rule:
   - **Selector:** Require WARP
   - **Value:** Enabled
3. Save policy

**Step 2: Configure WARP-Only Access**
1. For sensitive applications, block non-WARP access
2. This ensures all traffic passes through Gateway for inspection

---


{% include pack-code.html vendor="cloudflare" section="2.2" %}

### 2.3 Configure Device Posture Checks

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | AC-2(11) |

#### Description
Define device posture checks to verify endpoint security status before granting application access.

#### Rationale
**Why This Matters:**
- Verified identity alone does not prove the device is safe — a legitimate user on a compromised or non-compliant laptop is still a threat
- Posture checks for disk encryption, firewall, screen lock, and OS version enforce a minimum security baseline before access is granted
- Service-provider checks confirm endpoint security tools such as EDR and anti-malware are actually running, not merely installed
- Blocking access on posture failure prevents malware-infected or out-of-date endpoints from reaching internal applications and data

**Attack Prevented:** Compromised-endpoint access, malware lateral movement, data exposure from unencrypted devices

#### ClickOps Implementation

**Step 1: Create Device Posture Rules**
1. Navigate to: **Settings** → **WARP Client** → **Device posture**
2. Click **Add new**
3. Configure posture checks:
   - **OS version:** Minimum required version
   - **Disk encryption:** Required (FileVault/BitLocker)
   - **Firewall:** Enabled
   - **Screen lock:** Enabled

**Step 2: Create Service Provider Check (Optional)**
1. Add checks for security tools:
   - **CrowdStrike running**
   - **Carbon Black installed**
   - **Custom certificate present**

**Step 3: Apply to Access Policy**
1. Edit application Access policy
2. Add posture checks as Require rules
3. Block access if checks fail

---


{% include pack-code.html vendor="cloudflare" section="2.3" %}

### 2.4 Replace Long-Lived SSH Keys with Access for Infrastructure

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4, 8.5 |
| NIST 800-53 | AC-17, IA-5(2), AU-14 |

#### Description
Use Cloudflare Access for Infrastructure to broker SSH sessions with short-lived certificates issued at login rather than long-lived private keys distributed to engineers. Targets are registered in Zero Trust, policies bind an identity to a specific target and Unix username, and session commands can be recorded and stored encrypted ([Cloudflare SSH with Access for Infrastructure documentation](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/use-cases/ssh/ssh-infrastructure-access/)).

#### Rationale
**Why This Matters:**
- Long-lived SSH private keys sit on laptops, in build agents, and in backup archives indefinitely; anyone who obtains a copy has persistent access that no identity provider decision can revoke
- Short-lived certificates are minted only after a successful Access login, so revoking a user in the IdP or failing a device posture check immediately ends their ability to obtain new SSH sessions
- Per-target and per-Unix-username policies stop the common pattern where a single shared key grants root-equivalent access to a whole fleet, limiting what one compromised identity can reach
- Encrypted SSH command logging produces a per-session record of what was actually executed, which is essential for insider-threat investigation and for demonstrating privileged-session accountability to auditors
- Because the target is reached through a Cloudflare Tunnel, the SSH port never needs to be exposed to the internet, removing it from the reach of credential-stuffing and scanning bots

**Attack Prevented:** Stolen or copied SSH private keys, persistent access after offboarding, lateral movement via shared keys, unaudited privileged sessions, internet-exposed SSH brute forcing

#### Prerequisites
- A Cloudflare Tunnel connecting the target network (see section 5.1)
- WARP deployed and enrolled on the client devices that will connect
- An identity provider configured (see section 1.1)

#### ClickOps Implementation

**Step 1: Route the Target Network Through a Tunnel**
1. Navigate to: **Zero Trust** → **Networks** → **Tunnels**
2. Select or create the tunnel serving the environment that hosts the SSH servers
3. Under **Private Network**, add the CIDR range containing the target hosts

**Step 2: Register Infrastructure Targets**
1. Navigate to: **Zero Trust** → **Networks** → **Targets**
2. Click **Add a target**
3. Enter the target hostname, IP address, and the virtual network it belongs to
4. Repeat for each server that should be reachable over SSH

**Step 3: Create an Infrastructure Application**
1. Navigate to: **Zero Trust** → **Access controls** → **Applications**
2. Click **Add an application** and select **Infrastructure**
3. Select the targets to include and set the protocol to **SSH** with port 22
4. Add a policy: set **Action** to Allow, include your IdP group (for example, Platform Engineering), and add **Require** rules for login method and device posture
5. Under the policy's connection context, specify the exact Unix usernames the group may assume — avoid granting `root` where a named account will do

**Step 4: Configure the Server to Trust the Cloudflare SSH CA**
1. In the application configuration, download the Cloudflare SSH CA public key for your account
2. On each target host, install the CA public key and point `TrustedUserCAKeys` at it in the SSH daemon configuration
3. Restart the SSH daemon and confirm certificate-based authentication succeeds
4. Once verified, disable password authentication and remove distributed `authorized_keys` entries that are no longer needed

**Step 5: Enable SSH Command Logging (L3)**
1. In the Infrastructure application settings, enable SSH command logging
2. Provide the public key used to encrypt session logs and store the corresponding private key in your secrets manager
3. Configure a Logpush job to deliver the encrypted session logs to your SIEM or object storage

**Time to Complete:** ~90 minutes for the first target, ~15 minutes per additional target

#### Validation & Testing
1. Connect to a target as an authorized user and confirm the session succeeds without any local private key present
2. Remove the test user from the IdP group and confirm a new connection attempt is denied while no long-lived key remains that would still work
3. Attempt to connect as a Unix username not listed in the policy and confirm the session is refused
4. Attempt to reach port 22 on the target directly from the public internet and confirm there is no listener
5. Retrieve an encrypted session log, decrypt it with the stored private key, and confirm the executed commands are recorded

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| CIS Controls v8 | 6.4 | Require MFA for remote network access |
| CIS Controls v8 | 8.5 | Collect detailed audit logs for privileged activity |
| NIST 800-53 Rev 5 | AC-17 | Remote access authorization, monitoring, and control |
| NIST 800-53 Rev 5 | IA-5(2) | Public key-based authentication |
| NIST 800-53 Rev 5 | AU-14 | Session audit and recording |
| SOC 2 | CC6.6 | Access to infrastructure is restricted to authorized personnel |

---

### 2.5 Gate Access Policies on User Risk Score

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.1 |
| NIST 800-53 | AC-2(12) |

#### Description
Enable Cloudflare's behavioural risk scoring and use the resulting Low, Medium, or High score as a condition in Access policies, so that users exhibiting suspicious behaviour are blocked or forced to reauthenticate rather than continuing with the access their group membership would normally grant ([Cloudflare user risk score documentation](https://developers.cloudflare.com/cloudflare-one/team-and-resources/users/risk-score/)).

#### Rationale
**Why This Matters:**
- Static policies evaluate identity and device at the moment of login, so an account that is compromised after enrolment keeps its access until someone notices and intervenes manually
- Risk behaviours such as impossible travel, repeated DLP policy violations, and contact with known malware infrastructure are strong signals that an account or endpoint is under adversary control
- Binding a High risk score to a Block or reauthentication action turns detection into enforcement automatically, closing the gap between an alert firing and an analyst responding
- Every risk behaviour is disabled by default, so an organisation that assumes risk scoring is on out of the box is operating with no behavioural signal at all — the behaviours must be explicitly enabled to produce scores
- Scores are per-user and visible in the dashboard, giving investigators a prioritised queue rather than an undifferentiated stream of Gateway and Access logs

**Attack Prevented:** Session hijacking and account takeover after initial login, insider data exfiltration, continued access by a compromised endpoint, credential sharing across geographies

#### Prerequisites
- Cloudflare Zero Trust Enterprise plan
- WARP deployed with Gateway logging enabled so behavioural signals are collected
- Identity provider integration configured (see section 1.1)

#### ClickOps Implementation

**Step 1: Enable Risk Behaviours**
1. Navigate to: **Zero Trust** → **Teams & Resources** → **Users** → **Risk score**
2. Review the available behaviours — all are disabled by default
3. Enable the behaviours relevant to your environment, such as impossible travel, high number of DLP policy violations, and contact with known malware or command-and-control destinations
4. Set the risk level each behaviour contributes (Low, Medium, or High) to match your tolerance

**Step 2: Reference Risk Score in Access Policies**
1. Navigate to: **Zero Trust** → **Access controls** → **Applications** and edit a sensitive application
2. Add a policy with **Action** set to Block and an include rule using the **User Risk Score** selector set to High
3. Order the block policy above the allow policies so it is evaluated first
4. For lower-sensitivity applications, use a Medium score to trigger reauthentication rather than an outright block

**Step 3: Extend Risk Gating to Gateway (L3)**
1. Navigate to: **Gateway** → **Firewall Policies** and add policies matching on user risk score
2. Restrict high-risk users from reaching sensitive SaaS destinations or from uploading data

**Step 4: Define the Response Runbook**
1. Document who reviews the risk score dashboard and how often
2. Define the criteria for clearing a user's risk score after investigation, and record who is authorised to clear it
3. Feed risk score changes into your SIEM through Logpush so they correlate with other alerts

**Time to Complete:** ~60 minutes

#### Validation & Testing
1. Confirm the behaviours you intended to enable show as enabled on the risk score page — verify rather than assume, since the default is off
2. Trigger a test behaviour in a controlled way (for example, a deliberate DLP policy violation by a test account) and confirm the user's score changes
3. Attempt to reach a protected application as the elevated-risk test user and confirm the block or reauthentication policy fires
4. Confirm the block appears in Access logs with the risk score as the reason
5. Clear the test user's risk score and confirm normal access is restored

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| CIS Controls v8 | 13.1 | Centralize security event alerting and response |
| NIST 800-53 Rev 5 | AC-2(12) | Account monitoring for atypical usage |
| NIST 800-53 Rev 5 | SI-4 | System monitoring and automated response |
| SOC 2 | CC7.2 | Anomalies are detected and evaluated |

---

## 3. Gateway Security Policies

### 3.1 Configure DNS Filtering

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.2 |
| NIST 800-53 | SC-7, SI-3 |

#### Description
Configure Gateway DNS policies to block access to malicious and policy-violating domains.

#### Rationale
**Why This Matters:**
- DNS filtering blocks threats at the resolution layer
- Prevents access to malware, phishing, and C2 domains
- Works for all traffic, not just HTTP(S)
- Cloudflare's threat intelligence provides real-time protection

#### ClickOps Implementation

**Step 1: Create DNS Policy**
1. Navigate to: **Gateway** → **Firewall Policies** → **DNS**
2. Click **Add a policy**
3. Configure blocking rules:

**Step 2: Block Security Threats**
1. Create rule: "Block Security Threats"
2. Configure:
   - **Selector:** Security Categories
   - **Operator:** in
   - **Value:** Malware, Phishing, Spyware, Botnet, Cryptomining, Command and Control
   - **Action:** Block
3. Save

**Step 3: Block Content Categories (Policy)**
1. Create additional rules for policy enforcement:
   - Adult Content
   - Gambling
   - Illegal Activities
2. Configure action: Block or Override (with warning)

**Time to Complete:** ~30 minutes

---


{% include pack-code.html vendor="cloudflare" section="3.1" %}

### 3.2 Configure HTTP Filtering

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.2, 13.3 |
| NIST 800-53 | SC-7, SI-4 |

#### Description
Configure Gateway HTTP policies for deeper inspection and control of web traffic.

#### Rationale
**Why This Matters:**
- DNS filtering alone cannot see inside HTTP(S) sessions — Layer 7 inspection is needed to block malicious downloads and specific URLs
- HTTP policies stop malware and botnet content even when delivered from otherwise-reputable or newly-categorized domains
- Inline file inspection and antivirus scanning intercept malicious payloads before they reach the endpoint
- Web-layer control reduces the chance that a single drive-by download or malicious file leads to endpoint compromise

**Attack Prevented:** Malware downloads, drive-by compromise, botnet communication, malicious file delivery

#### ClickOps Implementation

**Step 1: Create HTTP Policy**
1. Navigate to: **Gateway** → **Firewall Policies** → **HTTP**
2. Click **Add a policy**

**Step 2: Block Malicious Content**
1. Create rule: "Block Malware Downloads"
2. Configure:
   - **Selector:** Content Categories
   - **Operator:** in
   - **Value:** Malware, Botnet
   - **Action:** Block

**Step 3: Inspect File Downloads (L2)**
1. Create rule for file inspection
2. Configure AV scanning for downloads
3. Block or quarantine detected threats

---


{% include pack-code.html vendor="cloudflare" section="3.2" %}

### 3.3 Configure Network Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.4, 13.4 |
| NIST 800-53 | SC-7, AC-4 |

#### Description
Configure Gateway network policies to control non-HTTP traffic based on IP, port, and protocol.

#### Rationale
**Why This Matters:**
- Threats and data exfiltration frequently use non-HTTP channels that web and DNS filtering never inspect
- Blocking risky ports, tunneling, and P2P protocols removes covert paths attackers use for command-and-control and lateral movement
- Identity-based controls on the private network range (100.96.0.0/12) prevent any enrolled user from freely reaching internal systems
- Logging private network access creates the audit trail needed to detect and investigate unauthorized internal connections

**Attack Prevented:** Command-and-control over non-HTTP ports, data exfiltration, lateral movement, unauthorized internal access

#### ClickOps Implementation

**Step 1: Create Network Policy**
1. Navigate to: **Gateway** → **Firewall Policies** → **Network**
2. Click **Add a policy**

**Step 2: Block Risky Protocols**
1. Create rules blocking:
   - Known malicious ports
   - Tunneling protocols (if not allowed)
   - P2P protocols
2. Configure action: Block

**Step 3: Control Private Network Access**
1. If using WARP-to-WARP (private network):
   - Create policies for 100.96.0.0/12 range
   - Restrict access by user identity
   - Log all private network access

---


{% include pack-code.html vendor="cloudflare" section="3.3" %}

### 3.4 Enable Browser Isolation (L3)

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.5 |
| NIST 800-53 | SI-3 |

#### Description
Enable Cloudflare Browser Isolation to execute web sessions in a secure cloud environment, preventing malware execution on endpoints.

#### Rationale
**Why This Matters:**
- Running web sessions in a remote cloud browser means active web code never executes on the endpoint, neutralizing browser-borne malware and zero-days
- Isolating uncategorized and newly-registered domains contains the highest-risk browsing where threat intelligence has not yet caught up
- Disabling copy/paste, printing, and uploads/downloads on sensitive sites prevents data from leaving controlled sessions
- Isolation protects against exploit kits and malicious scripts even when users click links that slip past other filters

**Attack Prevented:** Browser-based malware, drive-by downloads, zero-day exploits, web-based data exfiltration

#### Prerequisites
- Browser Isolation add-on license

#### ClickOps Implementation

**Step 1: Create Isolation Policy**
1. Navigate to: **Gateway** → **Firewall Policies** → **HTTP**
2. Create rule with **Action:** Isolate
3. Configure targets:
   - Uncategorized domains
   - Newly registered domains
   - High-risk categories

**Step 2: Configure Isolation Settings**
1. In Settings → Browser Isolation
2. Configure:
   - **Disable copy/paste:** For sensitive sites
   - **Disable printing:** For sensitive sites
   - **Disable uploads/downloads:** Based on policy

---


{% include pack-code.html vendor="cloudflare" section="3.4" %}

### 3.5 Configure Gateway Data Loss Prevention Profiles

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.13 |
| NIST 800-53 | AC-4, SC-7(10) |

#### Description
Use Gateway DLP profiles to inspect HTTP and SaaS traffic for sensitive data and block or log transfers that match. Two predefined profiles — Financial Information, and Social Security, Insurance, and Tax Identification Numbers — are available even on Free and Pay-as-you-go plans; custom profiles and additional detection entries require the Enterprise DLP add-on ([Cloudflare data loss prevention documentation](https://developers.cloudflare.com/cloudflare-one/policies/data-loss-prevention/)).

#### Rationale
**Why This Matters:**
- Gateway HTTP filtering blocks what is coming in, but without DLP nothing inspects what is leaving — payment card numbers, national identifiers, and source code can be pasted into a personal cloud drive or an AI chat interface with no record and no control
- Two predefined profiles are usable on Free and Pay-as-you-go plans, so the common assumption that DLP requires an Enterprise purchase leaves basic coverage unused at no additional cost
- DLP policies match on the payload rather than the destination category, catching exfiltration to a newly registered or uncategorised domain that reputation-based filtering would allow
- DLP detections feed the user risk score (see section 2.5), so a user repeatedly triggering DLP policies can be automatically escalated and blocked rather than merely logged
- Running DLP in log-only mode first produces the evidence needed to tune profiles before enforcement, avoiding the false-positive backlash that causes teams to disable DLP entirely

**Attack Prevented:** Data exfiltration by insiders or compromised accounts, unintentional disclosure of regulated data to unsanctioned SaaS, sensitive data pasted into third-party AI or file-sharing services

#### Prerequisites
- Gateway HTTP filtering enabled with TLS inspection configured (see section 3.2)
- WARP deployed with the Cloudflare root certificate installed on managed devices

#### ClickOps Implementation

**Step 1: Enable TLS Inspection**
1. Navigate to: **Zero Trust** → **Settings** → **Network**
2. Enable **TLS decryption** — DLP cannot inspect payloads inside encrypted sessions without it
3. Confirm the Cloudflare root certificate is deployed to managed devices, and document any inspection bypasses required for banking or healthcare sites

**Step 2: Review the Predefined Profiles**
1. Navigate to: **Zero Trust** → **DLP** → **DLP profiles**
2. Open **Financial Information** and review its detection entries (payment card numbers and similar)
3. Open **Social Security, Insurance, and Tax Identification Numbers** and review its entries
4. Set the confidence threshold and minimum match count on each entry to reduce false positives

**Step 3: Create a Log-Only HTTP Policy**
1. Navigate to: **Gateway** → **Firewall Policies** → **HTTP**
2. Add a policy with the **DLP Profile** selector set to the profiles enabled above
3. Set **Action** to Allow with logging so matches are recorded without blocking
4. Run for one to two weeks and review matches in Gateway HTTP logs

**Step 4: Move to Enforcement**
1. After tuning, change the action to Block for the highest-confidence profiles
2. Scope enforcement by destination where appropriate — for example, block uploads of matched data to personal file-sharing and unsanctioned AI services while allowing sanctioned applications
3. Configure a custom block page explaining why the upload was stopped and how to request an exception

**Step 5: Add Custom Profiles (L3, Enterprise DLP add-on)**
1. Navigate to: **DLP** → **DLP profiles** → **Create profile**
2. Define custom detection entries for organisation-specific identifiers such as customer account number formats or internal project codenames
3. Apply the same log-then-enforce progression before blocking

**Time to Complete:** ~60 minutes to configure, plus one to two weeks of tuning

#### Validation & Testing
1. From a WARP-enrolled test device, upload a file containing synthetic test data matching a predefined profile (use documented test values, never real customer data) and confirm the match appears in Gateway HTTP logs
2. After enforcement is enabled, repeat the upload and confirm it is blocked and the block page is displayed
3. Confirm that traffic on documented TLS inspection bypass lists is not inspected, and that this exposure is accepted and recorded
4. Review one week of DLP matches and calculate the false-positive rate before widening enforcement
5. Confirm DLP match events reach your SIEM through Logpush

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| CIS Controls v8 | 3.13 | Deploy a data loss prevention solution |
| NIST 800-53 Rev 5 | AC-4 | Information flow enforcement |
| NIST 800-53 Rev 5 | SC-7(10) | Prevent exfiltration of information |
| SOC 2 | CC6.7 | Transmission of sensitive data is restricted and monitored |
| PCI DSS v4.0 | 3.2 | Limit storage and transmission of cardholder data |

---

## 4. WARP Client Hardening

### 4.1 Configure WARP Client Settings

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7, SC-7 |

#### Description
Configure WARP client settings to ensure consistent security posture across all enrolled devices.

#### Rationale
**Why This Matters:**
- Consistent global settings ensure every enrolled device enforces the same Zero Trust protections rather than relying on per-user configuration
- Auto-connect and captive-portal detection keep WARP active across reboots and untrusted WiFi, closing windows where traffic would bypass inspection
- Locking the WARP switch prevents users from disabling protection to evade filtering or reach blocked content
- A defined default service mode (Gateway with WARP) guarantees traffic is routed through inspection by default, not left to user choice

**Attack Prevented:** Protection bypass, unfiltered traffic on untrusted networks, inconsistent endpoint posture

#### ClickOps Implementation

**Step 1: Access WARP Settings**
1. Navigate to: **Settings** → **WARP Client**
2. Click **Manage** under Global settings

**Step 2: Configure Global Settings**
1. **Auto connect:** Enable (reconnect after disconnection)
2. **Captive portal detection:** Enable (for WiFi networks)
3. **Mode switch:** Configure default mode (Gateway with WARP)

**Step 3: Configure Lock Settings (L2)**
1. **Lock WARP switch:** Enable (prevent user disable)
2. **Allow admin override:** Enable with codes (for troubleshooting)
3. **Disable for WiFi:** Configure trusted network exception

---


{% include pack-code.html vendor="cloudflare" section="4.1" %}

### 4.2 Lock WARP Client

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7 |

#### Description
Lock WARP client to prevent users from disabling Zero Trust protection.

#### Rationale
**Why This Matters:**
- If users can freely disable WARP, all Gateway filtering and Access posture checks can be bypassed at will, defeating the Zero Trust model
- Locking the switch keeps every device continuously inspected, including when malware or a user actively tries to evade controls
- Admin override codes preserve a controlled, time-limited path for legitimate troubleshooting without leaving the switch open to everyone
- Enforcing Gateway with WARP service mode ensures all traffic remains filtered rather than silently falling back to an unprotected path

**Attack Prevented:** Security-control evasion, unfiltered malicious traffic, posture-check bypass

#### ClickOps Implementation

**Step 1: Enable Lock Settings**
1. Navigate to: **Settings** → **WARP Client** → **Device settings**
2. Create or edit device profile
3. Enable **Lock WARP switch**

**Step 2: Configure Override Codes (Optional)**
1. Enable **Allow admin override codes**
2. Admins can generate temporary disable codes
3. Codes can be time-limited

**Step 3: Configure Service Mode**
1. Set **Service mode:** Gateway with WARP
2. This ensures all traffic is filtered
3. Alternative modes available for specific needs

---


{% include pack-code.html vendor="cloudflare" section="4.2" %}

### 4.3 Configure Split Tunnel Settings

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | SC-7 |

#### Description
Configure split tunnel settings to control which traffic passes through WARP and which bypasses.

#### Rationale
**Why This Matters:**
- By default, all traffic goes through WARP (full tunnel)
- Split tunnel can improve performance for specific apps
- Excessive split tunnel reduces security visibility
- Document all exceptions with business justification

#### ClickOps Implementation

**Step 1: Access Split Tunnel Settings**
1. Navigate to: **Settings** → **WARP Client** → **Device settings**
2. Select device profile
3. Click **Configure** under Split Tunnels

**Step 2: Configure Minimum Exceptions**
1. **Mode:** Exclude IPs and domains (default is include all)
2. Add only necessary exceptions:
   - Video conferencing (Zoom, Teams IPs)
   - Local network access (RFC1918)
3. Document each exception

**Step 3: Prefer Include Mode (L3)**
1. For maximum security, use **Include** mode
2. Only specified traffic goes through WARP
3. Everything else uses local network

---


{% include pack-code.html vendor="cloudflare" section="4.3" %}

## 5. Tunnel Security

### 5.1 Secure Cloudflare Tunnel Configuration

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 12.1 |
| NIST 800-53 | SC-7, SC-8 |

#### Description
Configure Cloudflare Tunnel (formerly Argo Tunnel) securely to expose internal applications without opening inbound ports.

#### Rationale
**Why This Matters:**
- Tunnels eliminate inbound firewall rules
- Misconfigured tunnels can expose internal services
- Access policies must protect tunnel endpoints
- Tunnel credentials must be secured

#### ClickOps Implementation

**Step 1: Create Tunnel**
1. Navigate to: **Access** → **Tunnels**
2. Click **Create a tunnel**
3. Name the tunnel descriptively
4. Install cloudflared on origin server

**Step 2: Configure Public Hostname**
1. Add public hostname routing
2. Configure:
   - **Subdomain:** app.yourdomain.com
   - **Service:** http://localhost:8080
3. **Always create Access policy before exposing**

**Step 3: Secure Tunnel Credentials**
1. Tunnel token should be treated as secret
2. Store securely (vault, secrets manager)
3. Rotate if compromised

---


{% include pack-code.html vendor="cloudflare" section="5.1" %}

### 5.2 Protect Tunnels with Access Policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4 |
| NIST 800-53 | AC-3 |

#### Description
Always protect tunnel endpoints with Access policies before exposing them publicly.

#### Rationale
**Why This Matters:**
- A tunnel hostname published without an Access policy exposes the internal application directly to the entire internet
- Creating the Access application first ensures the endpoint is never reachable during the window between publishing and securing it
- Identity-based Access policies require authenticated, authorized users before any request reaches the origin service
- Unprotected tunnels are quickly discovered by automated scanners, making an Access gate the difference between private and publicly exploitable

**Attack Prevented:** Unauthenticated access to internal apps, exposure of internal services, automated scanning and exploitation

#### ClickOps Implementation

**Step 1: Create Access Application First**
1. Before configuring tunnel hostname, create Access application
2. Configure appropriate access policy
3. Test policy with test users

**Step 2: Then Configure Tunnel**
1. Add public hostname to tunnel
2. Point to internal service
3. Access policy automatically protects endpoint

**Never expose tunnel endpoints without Access protection.**

---


{% include pack-code.html vendor="cloudflare" section="5.2" %}

### 5.3 Detect and Block TryCloudflare Quick Tunnel Abuse

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.8, 13.3 |
| NIST 800-53 | CM-7(2), SI-4 |

#### Description
TryCloudflare quick tunnels create an ephemeral `*.trycloudflare.com` hostname without requiring a Cloudflare account. Proofpoint has tracked threat actors abusing this since February 2024 to stage and deliver remote access trojans through what looks like legitimate Cloudflare infrastructure. Block outbound access to `trycloudflare.com` through Gateway and alert on unauthorized `cloudflared` execution on managed endpoints ([Proofpoint threat research](https://www.proofpoint.com/us/blog/threat-insight/threat-actor-abuses-cloudflare-tunnels-deliver-rats)).

#### Rationale
**Why This Matters:**
- Quick tunnels require no Cloudflare account, no domain, and no payment, so an attacker can stand up a delivery or command-and-control endpoint in seconds with no attributable registration trail
- The resulting hostname sits on a Cloudflare domain with a valid TLS certificate, so reputation and category filtering that would flag a newly registered domain often lets the traffic through
- Proofpoint has observed campaigns using these tunnels to deliver AsyncRAT, Xworm, VenomRAT, and similar remote access trojans through malicious LNK and shortcut files that fetch payloads over the tunnel
- The same technique works in reverse for exfiltration and unauthorized remote access: an insider or an attacker who lands on an endpoint can run `cloudflared` to expose an internal service outbound, bypassing every inbound firewall rule
- Because your organisation almost certainly uses named, authenticated tunnels (section 5.1) rather than anonymous quick tunnels, blocking the quick tunnel domain outright costs nothing operationally while removing a live abuse channel

**Attack Prevented:** RAT delivery over trusted infrastructure, command-and-control tunnelling, unauthorized outbound exposure of internal services, data exfiltration through anonymous tunnels

#### ClickOps Implementation

**Step 1: Block the Quick Tunnel Domain in Gateway DNS**
1. Navigate to: **Gateway** → **Firewall Policies** → **DNS**
2. Click **Add a policy** and name it "Block TryCloudflare Quick Tunnels"
3. Configure the rule:
   - **Selector:** Domain
   - **Operator:** is
   - **Value:** trycloudflare.com
4. Set **Action** to Block and save
5. Confirm the policy is ordered so no broader allow rule precedes it

**Step 2: Add an HTTP Policy for Defence in Depth**
1. Navigate to: **Gateway** → **Firewall Policies** → **HTTP**
2. Add a policy matching the **Host** selector against `trycloudflare.com` and any subdomain
3. Set **Action** to Block so requests that bypass DNS resolution are still stopped

**Step 3: Restrict cloudflared Execution on Endpoints**
1. In your endpoint management or EDR platform, create an application control rule permitting `cloudflared` to run only on the servers where a named tunnel is intentionally deployed
2. Alert on any `cloudflared` process starting on a user workstation
3. Alert on command lines containing quick tunnel invocation flags, since a legitimate named tunnel is run as a service with a credentials file rather than an ad-hoc URL flag

**Step 4: Hunt for Existing Abuse**
1. Review Gateway DNS and HTTP logs for historical resolutions of `trycloudflare.com` before the block was applied
2. Review endpoint telemetry for `cloudflared` binaries in user-writable directories such as download and temporary folders
3. Investigate any LNK or shortcut file execution that preceded a quick tunnel connection, which matches the documented delivery chain

**Step 5: Sanction the Legitimate Path**
1. Confirm every business-justified tunnel is a named tunnel owned by the account and protected by an Access policy (see sections 5.1 and 5.2)
2. Document the exception process for developers who previously used quick tunnels for local testing, and point them at named tunnels instead

**Time to Complete:** ~30 minutes for blocking, plus hunting effort

#### Validation & Testing
1. From a WARP-enrolled test device, attempt to resolve and reach a `trycloudflare.com` hostname and confirm the Gateway block page or NXDOMAIN response is returned
2. Confirm the block event appears in Gateway DNS logs with the correct policy name
3. Run `cloudflared` on a test workstation and confirm the endpoint alert fires within your expected detection window
4. Verify that named tunnels serving production applications continue to function and were not affected by the block
5. Re-run the historical log hunt after 30 days to confirm no further quick tunnel activity

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| CIS Controls v8 | 4.8 | Uninstall or disable unnecessary services on enterprise assets |
| CIS Controls v8 | 13.3 | Deploy network intrusion detection |
| NIST 800-53 Rev 5 | CM-7(2) | Prevent program execution contrary to policy |
| NIST 800-53 Rev 5 | SI-4 | System monitoring for unauthorized connections |
| SOC 2 | CC7.2 | Anomalous network activity is detected and evaluated |

---

## 6. Monitoring & Detection

### 6.1 Configure Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-6 |

#### Description
Configure comprehensive logging for Zero Trust activities and integrate with SIEM for security monitoring.

#### Rationale
**Why This Matters:**
- Without comprehensive Access, Gateway, and audit logs, malicious activity and policy violations go undetected and uninvestigable
- Exporting via Logpush to a SIEM enables correlation, alerting, and long-term retention beyond the dashboard's limited window
- Logs of admin changes, posture failures, and denied access provide the evidence needed for incident response and forensics
- Audit trails support compliance obligations and demonstrate that Zero Trust controls are operating as designed

**Attack Prevented:** Undetected intrusion, delayed breach discovery, repudiation, unnoticed configuration tampering

#### ClickOps Implementation

**Step 1: Review Default Logs**
1. Navigate to: **Logs** → **Access**
2. Review available log types:
   - Access requests
   - Gateway DNS
   - Gateway HTTP
   - Gateway Network

**Step 2: Configure Log Export**
1. Navigate to: **Settings** → **Logpush**
2. Click **Create Logpush job**
3. Select destination:
   - Splunk
   - Azure Blob Storage
   - Amazon S3
   - Google Cloud Storage
4. Configure log fields and filters

**Step 3: Enable Real-Time Logs**
1. Navigate to: **Logs** → **Gateway**
2. Review real-time activity
3. Configure dashboards for monitoring

---


{% include pack-code.html vendor="cloudflare" section="6.1" %}

### 6.2 Key Events to Monitor

| Event | Log Source | Detection Use Case |
|-------|------------|-------------------|
| Access denied | Access Logs | Unauthorized access attempts |
| Policy block | Gateway DNS/HTTP | Malware/policy violations |
| Device posture fail | Access Logs | Compromised devices |
| Admin changes | Audit Logs | Unauthorized modifications |
| Tunnel disconnection | Tunnel Logs | Service availability |
| Isolation triggered | Gateway HTTP | High-risk browsing |
| API token created or rolled | Audit Logs | Unauthorized credential creation |
| trycloudflare.com resolution | Gateway DNS/HTTP | Quick tunnel abuse, RAT delivery |
| DLP profile match | Gateway HTTP | Sensitive data exfiltration |
| User risk score elevated | Risk Score / Access Logs | Account compromise, insider activity |

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Cloudflare Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | IdP authentication | [1.1](#11-configure-identity-provider-integration) |
| CC6.1 | MFA enforcement | [1.2](#12-configure-multi-factor-authentication) |
| CC6.1 | Scoped API tokens | [1.5](#15-retire-the-global-api-key-and-enforce-scoped-api-tokens) |
| CC6.1 | Account 2FA enforcement | [1.6](#16-enforce-two-factor-authentication-for-account-members) |
| CC6.2 | Admin roles | [1.4](#14-configure-admin-role-restrictions) |
| CC6.6 | Access policies | [2.1](#21-create-secure-application-policies) |
| CC6.6 | SSH infrastructure access | [2.4](#24-replace-long-lived-ssh-keys-with-access-for-infrastructure) |
| CC6.7 | Gateway DLP | [3.5](#35-configure-gateway-data-loss-prevention-profiles) |
| CC7.1 | Gateway filtering | [3.1](#31-configure-dns-filtering) |
| CC7.2 | Logging | [6.1](#61-configure-logging) |
| CC7.2 | User risk score gating | [2.5](#25-gate-access-policies-on-user-risk-score) |
| CC7.2 | Quick tunnel abuse detection | [5.3](#53-detect-and-block-trycloudflare-quick-tunnel-abuse) |

### NIST 800-53 Rev 5 Mapping

| Control | Cloudflare Control | Guide Section |
|---------|-------------------|---------------|
| IA-2 | IdP integration | [1.1](#11-configure-identity-provider-integration) |
| IA-2(1) | MFA | [1.2](#12-configure-multi-factor-authentication) |
| IA-2(1) | Account member 2FA | [1.6](#16-enforce-two-factor-authentication-for-account-members) |
| IA-5 | API token lifetime and rotation | [1.5](#15-retire-the-global-api-key-and-enforce-scoped-api-tokens) |
| AC-3 | Access policies | [2.1](#21-create-secure-application-policies) |
| AC-2(11) | Device posture | [2.3](#23-configure-device-posture-checks) |
| AC-2(12) | User risk score gating | [2.5](#25-gate-access-policies-on-user-risk-score) |
| AC-4 | Gateway DLP | [3.5](#35-configure-gateway-data-loss-prevention-profiles) |
| AC-17 | SSH infrastructure access | [2.4](#24-replace-long-lived-ssh-keys-with-access-for-infrastructure) |
| SC-7 | Gateway policies | [3.1](#31-configure-dns-filtering) |
| CM-7(2) | Quick tunnel blocking | [5.3](#53-detect-and-block-trycloudflare-quick-tunnel-abuse) |
| AU-2 | Logging | [6.1](#61-configure-logging) |

---

## Appendix A: Plan Compatibility

| Feature | Free | Teams | Enterprise |
|---------|------|-------|------------|
| Access (50 users) | ✅ | ✅ | ✅ |
| Gateway DNS filtering | ✅ | ✅ | ✅ |
| Gateway HTTP filtering | ❌ | ✅ | ✅ |
| Device posture | ❌ | ✅ | ✅ |
| Browser Isolation | ❌ | Add-on | ✅ |
| CASB | ❌ | Add-on | ✅ |
| Logpush | ❌ | ✅ | ✅ |
| Support | Community | Standard | Enterprise |

---

## Appendix B: References

**Official Cloudflare Documentation:**
- [Cloudflare Trust Hub](https://www.cloudflare.com/trust-hub/)
- [Cloudflare Developer Docs](https://developers.cloudflare.com/)
- [Security Best Practices](https://developers.cloudflare.com/fundamentals/security/)
- [Zero Trust Documentation](https://developers.cloudflare.com/cloudflare-one/)
- [Access Documentation](https://developers.cloudflare.com/cloudflare-one/policies/access/)
- [Gateway Documentation](https://developers.cloudflare.com/cloudflare-one/policies/gateway/)
- [WARP Client Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/)

**API Documentation:**
- [Cloudflare API Reference](https://developers.cloudflare.com/api/)
- [Terraform Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Cloudflare SDKs](https://developers.cloudflare.com/fundamentals/api/reference/sdks/)

**Compliance Frameworks:**
- SOC 2 Type II (Security, Confidentiality, Availability), ISO 27001:2022, ISO 27018, ISO 27701, PCI DSS Level 1 (Merchant and Service Provider), FedRAMP (In Process, Moderate Baseline) — via [Cloudflare Trust Hub](https://www.cloudflare.com/trust-hub/compliance-resources/)

**Security Incidents:**
- **November 2023 — Nation-state actor accessed internal Atlassian systems.** Using credentials stolen during the October 2023 Okta breach that Cloudflare failed to rotate, attackers accessed Cloudflare's self-hosted Atlassian Confluence, Jira, and Bitbucket between November 14-24, 2023. No customer data or systems were impacted. Cloudflare rotated over 5,000 production credentials, reimaged all machines across its global network, and physically segmented test/staging systems. ([Cloudflare Blog](https://blog.cloudflare.com/thanksgiving-2023-security-incident/))
- **August 2025 — Salesloft Drift supply chain compromise exposed Cloudflare's Salesforce data.** The threat actor tracked as GRUB1 abused the Salesloft Drift integration with Salesforce to access Cloudflare's Salesforce tenant between August 12-17, 2025, exfiltrating support case data — including the text customers had typed into those cases. Cloudflare found 104 API tokens in the exposed data and rotated all of them as a precaution; no core infrastructure or services were compromised. Cloudflare disclosed the incident on September 2, 2025, disconnected Salesloft, rotated every credential shared through support cases, and moved to enforce least privilege and IP restrictions on third-party application connections. ([Cloudflare Blog](https://blog.cloudflare.com/response-to-salesloft-drift-incident/))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-03 | 0.2.0 | draft | Add API token/Global API Key retirement (1.5), account 2FA enforcement (1.6), Access for Infrastructure SSH (2.4), user risk score gating (2.5), Gateway DLP (3.5), TryCloudflare quick tunnel abuse detection (5.3); correct the Salesloft Drift incident entry to the August 2025 Salesforce compromise with Cloudflare's own disclosure | Claude Code (Sonnet 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with Access, Gateway, and WARP hardening | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
