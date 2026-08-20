---
layout: guide
title: "Netskope Hardening Guide"
vendor: "Netskope"
slug: "netskope"
tier: "1"
category: "Security"
description: "Security hardening for Netskope CASB, SWG, and ZTNA deployment"
version: "0.2.1"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Netskope is a leading Security Service Edge (SSE) platform providing CASB, Secure Web Gateway (SWG), and Zero Trust Network Access (ZTNA) for cloud security. As a critical security control point for cloud application access, Netskope configurations directly impact data protection and threat prevention across SaaS applications, web traffic, and private applications.

### Intended Audience
- Security engineers managing Netskope deployments
- IT administrators configuring SSE policies
- GRC professionals assessing cloud security
- Third-party risk managers evaluating CASB solutions

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Netskope tenant hardening, CASB policies, DLP configuration, threat protection, steering and Netskope Client configuration, and Private Access (NPA) publisher hardening.

Tier 3/4 sources (independent research, community write-ups) are out of scope for this guide's control text; controls are drawn from Netskope's Tier 1 configuration documentation, with vulnerability context sourced from the NVD.

---

## Table of Contents

1. [Tenant Security](#1-tenant-security)
2. [CASB Policies](#2-casb-policies)
3. [Data Loss Prevention](#3-data-loss-prevention)
4. [Threat Protection](#4-threat-protection)
5. [Steering Configuration](#5-steering-configuration)
6. [Monitoring & Detection](#6-monitoring--detection)
7. [Compliance Quick Reference](#7-compliance-quick-reference)
8. [Private Access & Publisher Hardening](#8-private-access--publisher-hardening)

---

## 1. Tenant Security

### 1.1 Secure Admin Console Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Secure Netskope Admin Console with SSO, MFA, and role-based access controls.

#### Rationale
**Why This Matters:**
- Admin Console controls all security policies
- Compromised admin can disable protection
- Role-based access limits blast radius

**Attack Prevented:** Admin console takeover disabling security policies organization-wide

#### ClickOps Implementation

**Step 1: Configure SSO for Admin Access**
1. Navigate to: **Netskope Admin Console** → **Settings** → **Administration**
2. Click **SSO Configuration**
3. Configure SAML SSO:
   - Upload IdP metadata
   - Configure attribute mapping
   - Test SSO login

**Step 2: Enable MFA**
1. Through SSO, enforce MFA via identity provider
2. Or configure Netskope's native MFA if not using SSO

**Step 3: Configure Admin Roles**
1. Navigate to: **Administration** → **Admins**
2. Review default roles:
   - **Super Admin:** Full access
   - **Tenant Admin:** Manage tenant settings
   - **Policy Admin:** Manage policies only
   - **Read-Only:** View-only access
3. Assign minimum required permissions

**Time to Complete:** ~45 minutes

---

### 1.2 Configure Tenant Hardening

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7 |

#### Description
Apply Netskope's recommended tenant hardening configurations.

#### Rationale
**Why This Matters:**
- Default tenant settings favor ease of setup over security, leaving session timeouts and audit logging weaker than they should be
- Short admin session timeouts limit the window an attacker can ride a hijacked or unattended console session
- Admin audit logging is the forensic record that proves who changed which security policy and when
- IP allowlisting restricts console access to known corporate ranges, blocking admin logins from arbitrary internet locations

**Attack Prevented:** Session hijacking, unauthorized admin access, undetected policy tampering, credential abuse from untrusted networks

#### ClickOps Implementation

**Step 1: Restrict Console Access by IP (L2)**
1. Navigate to: **Settings** → **Administration** → **IP Allowlist**
2. Click **Edit**
3. Enter the IP addresses, ranges, or subnets permitted to reach the Admin Console, separated by commas, then click **+ADD**
4. Change the status from **Disabled** to **Enabled**
5. Click **Save**

**Step 2: Configure Admin Session and Password Settings**
1. Navigate to: **Settings** → **Administration** → **Admins**
2. Click the **Settings** icon in the top right corner
3. Select a value from the **Idle Timeout** dropdown (choose the shortest interval your admins can tolerate)
4. Select a value from the **Password Expiration** dropdown (applies to local admin credentials)
5. Click **Save**

**Step 3: Review Admin Audit Logging**
1. Review admin activity in the tenant's audit events and forward them to a SIEM (see [6.1](#61-configure-logging-and-alerts))

> **Note:** There is no separate "Tenant Settings" page for these controls. IP allowlisting, idle timeout, and password expiration are all configured under **Settings** → **Administration**, per Netskope's [Secure Tenant Configuration and Hardening](https://docs.netskope.com/en/secure-tenant-configuration-and-hardening/) guide.

---

### 1.3 Harden Admin Login Controls

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2, 6.5 |
| NIST 800-53 | AC-7, AC-10, IA-2(1) |

#### Description
Limit failed admin login attempts, prevent concurrent admin sessions, and enable Netskope's native multi-factor authentication for admins who do not authenticate through SSO.

#### Rationale
**Why This Matters:**
- Capping failed login attempts turns online password guessing against the Admin Console into a lockout event instead of an unlimited-attempt exercise
- Disallowing concurrent logins by the same admin means a stolen session or credential cannot ride alongside the legitimate admin unnoticed
- Netskope's native admin Multi-Factor Auth is **Disabled by default** and is set per admin — an admin created outside the SSO path can otherwise hold single-factor access to the full security policy set
- Console admins can disable steering, weaken DLP, and clear policies, so login-layer hardening protects every other control in this guide

**Attack Prevented:** Password spraying and brute force against admin accounts, session hijacking, single-factor admin takeover of the security console

#### ClickOps Implementation

**Step 1: Configure Login Attempt and Session Limits**
1. Navigate to: **Settings** → **Administration** → **Admins**
2. Click the **Settings** icon in the top right corner
3. Enter a value for **Maximum failed login attempts**
4. Enable **Disallow Concurrent Logins by the same Admin**
5. Click **Save**

**Step 2: Enable Native Admin MFA Where SSO Is Not Used**
1. Navigate to: **Settings** → **Administration** → **Admins**
2. Edit each admin who authenticates with local credentials
3. Toggle the **Multi-Factor Auth** radio button from **Disabled** (the default) to **Enabled**
4. Click **Save**

**Step 3: Verify Coverage**
1. Confirm every admin account either authenticates through SSO with IdP-enforced MFA (see [1.1](#11-secure-admin-console-access)) or carries native Multi-Factor Auth set to **Enabled**

---

## 2. CASB Policies

### 2.1 Configure Application Visibility

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.1 |
| NIST 800-53 | CM-8 |

#### Description
Enable comprehensive visibility into all cloud applications in use, including shadow IT discovery.

#### Rationale
**Why This Matters:**
- Shadow IT creates uncontrolled data exposure
- Visibility is prerequisite to security policy
- Risk scoring helps prioritize remediation

**Attack Prevented:** Uncontrolled data exposure through unsanctioned shadow IT applications

#### ClickOps Implementation

**Step 1: Enable Cloud App Discovery**
1. Navigate to: **Netskope Admin Console** → **SkopeIT** → **Application Events**
2. Review discovered applications
3. Identify shadow IT and unsanctioned apps

**Step 2: Configure App Risk Scoring**
1. Navigate to: **SkopeIT** → **Cloud Confidence Index (CCI)**
2. Review risk scores for discovered apps
3. Define risk thresholds:
   - **High Risk:** CCI < 50
   - **Medium Risk:** CCI 50-70
   - **Low Risk:** CCI > 70

**Step 3: Create Application Categories**
1. Group applications by:
   - Business function (Collaboration, Storage, etc.)
   - Risk level (Sanctioned, Tolerated, Unsanctioned)
   - Compliance requirement (HIPAA, PCI, etc.)

---

### 2.2 Configure Real-Time Protection Policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.2 |
| NIST 800-53 | SC-7, AC-4 |

#### Description
Configure real-time protection policies to control access to cloud applications based on user, app, activity, and data.

#### Rationale
**Why This Matters:**
- Inline real-time policies are the enforcement layer that turns application visibility into actual blocking of risky activity
- Without granular policies, users can upload corporate data to personal or high-risk cloud instances unchecked
- Activity-level control (upload, share, download) stops data movement that app-level allow/block alone cannot catch
- Personal-instance detection prevents employees from routing sanctioned-app data into unmanaged personal accounts

**Attack Prevented:** Data exfiltration, shadow IT data leakage, unauthorized uploads to personal cloud accounts, risky-app access

#### ClickOps Implementation

**Step 1: Access Real-Time Protection**
1. Navigate to: **Policies** → **Real-time Protection**
2. Click **New Policy**

**Step 2: Create Block Unsanctioned Apps Policy**
1. Configure:
   - **Name:** Block High-Risk Cloud Apps
   - **Source:** All Users
   - **Destination:** Apps with CCI < 50
   - **Activity:** All
   - **Action:** Block
2. Add user notification explaining policy

**Step 3: Create Data Protection Policy**
1. Configure:
   - **Name:** Block Upload to Personal Cloud
   - **Source:** All Users
   - **Destination:** Personal instances of cloud apps
   - **Activity:** Upload, Share
   - **Action:** Block
2. Enable DLP profile (see Section 3)

**Time to Complete:** ~1 hour

---

### 2.3 Configure API Protection

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SC-28 |

#### Description
Configure API-enabled protection to scan and protect data at rest in sanctioned SaaS applications.

#### Rationale
**Why This Matters:**
- Inline steering only inspects traffic in motion; API scanning reaches data already sitting at rest inside SaaS apps
- Files shared or uploaded before policies existed, or via unmanaged devices, are only discoverable through API connectors
- Continuous API scanning detects externally shared sensitive files and over-permissioned access after the fact
- Out-of-band remediation can quarantine files and revoke external sharing without breaking the user's live session

**Attack Prevented:** Latent sensitive-data exposure, oversharing of SaaS files, external data leakage, malware resident in cloud storage

#### ClickOps Implementation

**Step 1: Connect SaaS Applications**
1. Navigate to: **Settings** → **API-enabled Protection**
2. Click **Configure App**
3. Connect sanctioned applications:
   - Microsoft 365 (OneDrive, SharePoint, Teams)
   - Google Workspace (Drive, Gmail)
   - Slack, Box, Salesforce, etc.
4. Complete OAuth authorization

**Step 2: Configure Scanning Policies**
1. Navigate to: **Policies** → **API Data Protection**
2. Configure scanning:
   - **Scan frequency:** Continuous or scheduled
   - **DLP profile:** Select DLP profile
   - **Malware scan:** Enable
3. Configure remediation actions:
   - Quarantine sensitive files
   - Revoke external sharing
   - Notify owner

---

## 3. Data Loss Prevention

### 3.1 Configure DLP Profiles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.2 |
| NIST 800-53 | SC-8, SC-28 |

#### Description
Configure Data Loss Prevention profiles to detect and protect sensitive data across cloud applications.

#### Rationale
**Why This Matters:**
- Prevents accidental data exposure
- Enforces compliance requirements
- Provides visibility into data flows

**Attack Prevented:** Accidental exposure and leakage of sensitive data across cloud applications

#### ClickOps Implementation

**Step 1: Access DLP Configuration**
1. Navigate to: **Policies** → **DLP** → **Profiles**
2. Review predefined profiles:
   - PCI DSS (Credit cards)
   - HIPAA (Healthcare data)
   - GDPR (Personal data)
   - PII (SSN, Driver's license, etc.)

**Step 2: Create Custom DLP Profile**
1. Click **New Profile**
2. Configure:
   - **Name:** Corporate Sensitive Data
   - **Detection rules:**
     - Credit card numbers
     - Social Security numbers
     - API keys and credentials
     - Custom patterns (project codes, etc.)
3. Set **Severity levels** for each rule

**Step 3: Enable Advanced Detection**
1. Configure detection technologies:
   - **Exact Data Match (EDM):** Match against known data sets
   - **File Fingerprinting:** Detect specific document types
   - **OCR:** Detect text in images
   - **ML Classification:** Detect sensitive documents

**Time to Complete:** ~1 hour

---

### 3.2 Apply DLP to Policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SC-8 |

#### Description
Apply DLP profiles to real-time protection and API protection policies.

#### Rationale
**Why This Matters:**
- A DLP profile detects nothing until it is bound to an enforcement policy that acts on its matches
- Attaching DLP to real-time policies blocks sensitive data in motion before it leaves the organization
- Attaching DLP to API policies catches sensitive data at rest that inline inspection never sees
- Coaching and alert actions balance enforcement with user productivity while still recording every violation

**Attack Prevented:** Accidental and intentional data leakage, compliance violations, unmonitored exfiltration of regulated data

#### ClickOps Implementation

**Step 1: Add DLP to Real-Time Policy**
1. Edit or create real-time protection policy
2. In **Advanced Options**, select DLP profile
3. Configure actions:
   - **Block:** Prevent upload/download of sensitive data
   - **Alert:** Allow but log violation
   - **Coaching:** Warn user, require justification

**Step 2: Add DLP to API Protection**
1. Edit API data protection policy
2. Select DLP profile for scanning
3. Configure remediation actions

---

## 4. Threat Protection

### 4.1 Configure Malware Protection

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.1 |
| NIST 800-53 | SI-3 |

#### Description
Configure Netskope's threat protection to detect and prevent malware in cloud traffic.

#### Rationale
**Why This Matters:**
- Cloud apps are now a primary delivery and distribution channel for malware, bypassing traditional perimeter defenses
- Scanning uploads and downloads stops infected files from spreading through shared cloud storage to other users
- Cloud sandboxing detonates unknown files to catch zero-day and evasive malware that signatures alone miss
- Blocking phishing URLs inline stops credential-harvesting attacks before the user ever reaches the malicious page

**Attack Prevented:** Malware delivery, ransomware propagation, zero-day payloads, phishing and credential theft

#### ClickOps Implementation

**Step 1: Enable Malware Detection**
1. Navigate to: **Policies** → **Threat Protection**
2. Enable malware scanning for:
   - File uploads to cloud apps
   - File downloads from cloud apps
   - Web downloads

**Step 2: Configure Sandboxing**
1. Enable Cloud Sandbox for unknown files
2. Configure:
   - **File types:** Executables, documents, archives
   - **Action:** Quarantine pending analysis
   - **Timeout action:** Block if analysis incomplete

**Step 3: Configure Actions**
1. Set actions for detected threats:
   - **Known malware:** Block
   - **Suspicious files:** Sandbox
   - **Phishing URLs:** Block

---

### 4.2 Configure Threat Protection Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.5 |
| NIST 800-53 | SI-4 |

#### Description
Create comprehensive threat protection policies following Netskope best practices.

#### Rationale
**Why This Matters:**
- Layered threat policies cover the full attack chain — known malware, suspicious categories, and behavioral anomalies
- Blocking newly registered, uncategorized, and parked domains cuts off common command-and-control and phishing infrastructure
- Behavioral analytics surfaces compromised-account and insider activity that signature-based controls cannot detect
- Inline, no-exception enforcement on known threats removes the gaps attackers probe for weak spots

**Attack Prevented:** Malware and C2 communication, phishing via fresh domains, account compromise, insider data exfiltration

#### Best Practice Policy Configuration

**Step 1: Block Known Threats**
1. Create policy blocking all known malware categories
2. Apply to all traffic (inline)
3. No exceptions

**Step 2: Block Suspicious Categories**
1. Create policy for suspicious URLs:
   - Newly registered domains
   - Uncategorized sites
   - Parked domains
2. Action: Block or Coach

**Step 3: Enable Cloud Behavior Analytics**
1. Navigate to: **Settings** → **Security Configurations**
2. Enable behavioral threat detection
3. Configure anomaly detection for:
   - Unusual data exfiltration
   - Compromised account behavior
   - Insider threat indicators

---

## 5. Steering Configuration

### 5.1 Configure Netskope Client Steering

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | SC-7 |

#### Description
Configure Netskope Client steering to ensure traffic is properly routed through the Netskope cloud for inspection.

#### Rationale
**Why This Matters:**
- Steering determines what traffic is inspected
- Misconfiguration can create inspection gaps
- Certificate pinning apps require bypass

**Attack Prevented:** Data exfiltration and threats passing through uninspected steering gaps

#### ClickOps Implementation

**Step 1: Access Steering Configuration**
1. Navigate to: **Settings** → **Security Cloud Platform** → **Traffic Steering**
2. Review steering configuration

**Step 2: Configure App Steering**
1. Review **Steered Apps** list
2. Ensure all cloud apps are steered through Netskope
3. Configure exceptions only when necessary

**Step 3: Configure Certificate Pinned Apps**
1. Review **Do Not Steer** list
2. Add certificate-pinned applications that cannot be inspected:
   - Banking applications
   - Healthcare applications
3. Document all bypass exceptions

**Important:** Do NOT set custom app domains to `*` for certificate pinned apps, as this will bypass all inspection.

**Time to Complete:** ~30 minutes

---

### 5.2 Deploy Netskope Client

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | SC-7 |

#### Description
Deploy Netskope Client to endpoints to enable inline inspection and steering.

#### Rationale
**Why This Matters:**
- The client is what forces endpoint traffic through Netskope; without it, inline inspection and policy enforcement never happen
- Endpoints off the corporate network would otherwise bypass all CASB, DLP, and threat controls entirely
- Fail-close mode ensures traffic is denied rather than passed uninspected when the client cannot reach the cloud
- MDM-managed deployment and certificate installation prevent users from removing or evading the agent

**Attack Prevented:** Inspection bypass, unmonitored off-network traffic, policy evasion, data exfiltration through uncontrolled endpoints

#### ClickOps Implementation

**Step 1: Download Client Installer**
1. Navigate to: **Settings** → **Security Cloud Platform** → **Client Configuration**
2. Download appropriate installer (Windows, macOS, iOS, Android)

**Step 2: Configure Client Settings**
1. Configure default steering mode
2. Enable **Fail Close** for maximum security (or Fail Open for availability)
3. Configure auto-update settings

**Step 3: Deploy via MDM**
1. Deploy via Intune, JAMF, or other MDM
2. Install SSL certificate for inspection
3. Verify client connects to Netskope cloud

---

### 5.3 Enable Netskope Client Tamper Protection

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 10.7 |
| NIST 800-53 | CM-7, SI-7 |

#### Description
Protect the Netskope Client's configuration files and resources on the endpoint, prevent users from disabling the client, and require a password to uninstall it.

#### Rationale
**Why This Matters:**
- The client is the enforcement point for every inline control in this guide; a user or malware that disables or uninstalls it removes CASB, DLP, and threat protection from that endpoint entirely
- Protecting client configuration and resources stops local modification of the files that decide what traffic gets steered and inspected
- Password-protecting uninstallation means removal requires a secret the endpoint user does not hold, so a compromised local session cannot simply uninstall its way out of inspection
- Netskope's Client has been the recurring subject of local privilege and tamper-related CVEs (see [Appendix B](#appendix-b-references)) — tamper protection and prompt client upgrades are the paired mitigations for that class

**Attack Prevented:** Local agent tampering and uninstallation, inspection bypass by end users or malware, exploitation of Client tamper-protection weaknesses (CVE-2025-15641, CVE-2025-15642 class)

#### ClickOps Implementation

**Step 1: Access Client Configuration**
1. Navigate to: **Settings** → **Security Cloud Platform** → **Netskope Client** → **Client Configuration**
2. Open the configuration applied to your managed endpoints

**Step 2: Apply Tamper Protection Settings**
1. Enable **Protect Client configuration and resources**
2. Uncheck **Allow disabling of Clients**
3. Enable **Password protect Client uninstallation** and set the uninstall password
4. Click **Save**

**Step 3: Consider Fail Close**
1. Enabling **Fail Close** automatically enables password-protected uninstallation and disables the ability to disable the client, in addition to denying uninspected traffic when the client cannot reach the Netskope cloud (see [5.2](#52-deploy-netskope-client))

**Step 4: Keep Clients Current**
1. Confirm client auto-upgrade is enabled so endpoints pick up fixes for Client vulnerabilities without manual redeployment

---

### 5.4 Harden Netskope Client Enrollment

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 13.5 |
| NIST 800-53 | IA-3, IA-5, SC-8 |

#### Description
Control how endpoints enroll into the tenant by choosing a hardened enrollment method — one-time token, IdP-based SAML forward proxy authentication, or an Authentication Token with Secure Enrollment.

#### Rationale
**Why This Matters:**
- Enrollment is the moment an endpoint is granted a tenant identity; a weak enrollment path lets an unauthorized device join the tenant and receive steering configuration
- One-time tokens are single-use by design, so an intercepted email invite cannot be replayed to enroll a second device
- IdP-based enrollment through the SAML forward proxy ties device enrollment to the same identity and MFA controls that govern console and application access
- Secure Enrollment with an Authentication Token (a shared secret carried as a JWT) is Netskope's recommendation for strict enforcement, and additionally encrypts the initial configuration file beyond the TLS transport

**Attack Prevented:** Unauthorized device enrollment, replay of enrollment invitations, interception of initial client configuration, tenant-identity spoofing

#### ClickOps Implementation

**Step 1: Choose an Enrollment Method**
1. Review the three supported methods and select the strictest one your deployment tooling supports:
   - **One-time token** — the email invite carries a single-use token
   - **IdP-based authentication** — enrollment authenticated through the SAML forward proxy
   - **Authentication Token** — a shared secret issued as a JWT, used with Secure Enrollment

**Step 2: Enable Secure Enrollment (recommended)**
1. Navigate to: **Settings** → **Security Cloud Platform** → **Netskope Client** → **MDM Distribution** → **Secure Enrollment**
2. Enable **Secure Enrollment** and generate the Authentication Token
3. Distribute the token through your MDM alongside the installer — never by email or a shared document

**Step 3: Validate**
1. Attempt an enrollment without a valid token and confirm it is rejected
2. Confirm enrolled devices appear in the tenant with the expected user identity

---

## 6. Monitoring & Detection

### 6.1 Configure Logging and Alerts

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-6 |

#### Description
Configure comprehensive logging and alerting for security monitoring.

#### Rationale
**Why This Matters:**
- Security controls are only effective if violations are detected and acted on, which requires comprehensive logging
- Real-time alerts on DLP, malware, and admin changes shrink the time between a security event and the response
- Forwarding logs to a SIEM preserves an independent, tamper-resistant record for investigation and compliance
- Admin-change alerts catch unauthorized policy modifications that would otherwise silently weaken protection

**Attack Prevented:** Undetected breaches, delayed incident response, log tampering, stealthy policy weakening

#### ClickOps Implementation

**Step 1: Review SkopeIT Dashboard**
1. Navigate to: **SkopeIT**
2. Review real-time visibility:
   - Application usage
   - User activities
   - Data movement
   - Threat events

**Step 2: Configure Alerts**
1. Navigate to: **Settings** → **Incident Management** → **Alerts**
2. Configure alerts for:
   - DLP violations
   - Malware detection
   - Policy violations
   - Admin changes

**Step 3: Configure SIEM Integration**
1. Navigate to: **Settings** → **Cloud Log Shipper**
2. Configure export to SIEM:
   - Splunk
   - Azure Sentinel
   - Generic syslog/CEF
3. Select log types to export

---

### 6.2 Key Events to Monitor

| Event Type | Detection Use Case |
|------------|-------------------|
| DLP violation | Data exfiltration attempt |
| Malware blocked | Active threat detection |
| Policy bypass | Evasion attempt |
| Unsanctioned app access | Shadow IT usage |
| Anomalous behavior | Compromised account |
| Admin changes | Unauthorized modifications |

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Netskope Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | Admin access control | [1.1](#11-secure-admin-console-access) |
| CC6.6 | CASB policies | [2.2](#22-configure-real-time-protection-policies) |
| CC6.7 | DLP protection | [3.1](#31-configure-dlp-profiles) |
| CC7.1 | Threat protection | [4.1](#41-configure-malware-protection) |
| CC7.2 | Logging | [6.1](#61-configure-logging-and-alerts) |

### NIST 800-53 Rev 5 Mapping

| Control | Netskope Control | Guide Section |
|---------|------------------|---------------|
| AC-6(1) | Admin roles | [1.1](#11-secure-admin-console-access) |
| SC-7 | Steering/policies | [2.2](#22-configure-real-time-protection-policies) |
| SC-8 | DLP | [3.1](#31-configure-dlp-profiles) |
| SI-3 | Malware protection | [4.1](#41-configure-malware-protection) |
| AU-2 | Logging | [6.1](#61-configure-logging-and-alerts) |

---

## 8. Private Access & Publisher Hardening

> Netskope Private Access (NPA) is the ZTNA component of the platform. Its controls are numbered 8.x because sections 1–7 predate them; existing control numbers are never reused or renumbered.

### 8.1 Enforce Periodic Re-authentication for Private App Segments

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | AC-12, IA-11 |

#### Description
Require users to re-authenticate against the identity provider at a fixed interval before continuing to reach private applications through Netskope Private Access.

#### Rationale
**Why This Matters:**
- Without a re-authentication interval, a private-app session established once can persist indefinitely, long after the user's device or IdP posture has changed
- Forcing a fresh IdP authentication re-applies MFA, conditional access, and any risk signals the IdP has accumulated since the original login
- Stolen device sessions and long-lived tokens lose value once the enforced interval expires, shrinking the window for an attacker riding a compromised endpoint
- Private applications reached through ZTNA are typically internal systems with no additional perimeter behind them, so session freshness is the primary time-bound control

**Attack Prevented:** Indefinite session persistence, stolen-session reuse against internal applications, stale authorization after a user's access should have been revoked

#### ClickOps Implementation

**Step 1: Open Client Configuration**
1. Navigate to: **Settings** → **Security Cloud Platform** → **Netskope Client** → **Client Configuration**

**Step 2: Enable Periodic Re-authentication**
1. Enable **Periodic re-authentication for Private App Segments**
2. Select the re-authentication interval
3. Select the grace period
4. Click **Save**

**Step 3: Validate**
1. Establish a private-app session, wait past the configured interval, and confirm the user is prompted to re-authenticate through the IdP

---

### 8.2 Harden Netskope Publishers

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 13.4 |
| NIST 800-53 | CM-7, SC-7, IA-5 |

#### Description
Harden the Publisher hosts that broker Private Access traffic into your network — key-based SSH authentication, a firewall limited to the required ports, and no third-party software.

#### Rationale
**Why This Matters:**
- A Publisher sits inside your network and brokers external user sessions to internal applications, making it one of the highest-value pivot points in the deployment
- Key-based SSH authentication removes password guessing and credential reuse as a path onto the Publisher host
- Restricting inbound traffic to only the ports the Publisher actually needs eliminates every other listening service as an attack surface
- Netskope states that installing third-party software on a Publisher is done at the customer's own risk — added packages expand the host's attack surface outside the supported, hardened baseline

**Attack Prevented:** Publisher host compromise, SSH brute force and credential reuse, lateral movement from the ZTNA broker into internal networks, supply-chain risk from unvetted host software

#### ClickOps Implementation

**Step 1: Use Key-Based SSH Authentication**
1. Configure key based authentication for SSH on each Publisher instead of password based authentication
2. Disable password authentication once key access is confirmed working

**Step 2: Restrict Network Access**
1. Using the native Ubuntu 22.04 firewall or your network firewalls, restrict inbound access to the Publisher to only:
   - **22** (SSH, from administrative ranges only)
   - **53** (DNS)
   - **443** (HTTPS)
2. Deny all other inbound traffic

**Step 3: Keep the Host Clean**
1. Do not install third-party software on Publisher hosts — Netskope documents such installations as being at the customer's own risk
2. Keep Publishers on a current, supported version

---

## Appendix A: Feature Compatibility

| Feature | SSE Starter | SSE Professional | SSE Enterprise |
|---------|-------------|------------------|----------------|
| CASB Inline | ✅ | ✅ | ✅ |
| CASB API | ❌ | ✅ | ✅ |
| DLP | Basic | Full | Full |
| Cloud Sandbox | ❌ | ✅ | ✅ |
| ZTNA | ❌ | ✅ | ✅ |
| Browser Isolation | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Netskope Documentation:**
- [Netskope Security, Compliance and Assurance](https://www.netskope.com/company/security-compliance-and-assurance)
- [Netskope Product Documentation](https://docs.netskope.com/)
- [Secure Tenant Configuration and Hardening](https://docs.netskope.com/en/secure-tenant-configuration-and-hardening/)
- [Threat Protection Best Practices](https://docs.netskope.com/en/netskope-help/data-security/real-time-protection/best-practices-for-real-time-protection-policies/best-practices-for-threat-protection-policies)

**API Documentation:**
- [Netskope REST API Documentation](https://docs.netskope.com/en/rest-api/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO/IEC 27001:2022, ISO/IEC 27017, ISO/IEC 27018, CSA STAR Level II, PCI DSS v4.0.1, FedRAMP High, C5, Cyber Essentials — via [Netskope Compliance Center](https://compliance.netskope.com/)

**Security Incidents & Vulnerabilities:**

The NVD catalogs 22 CVEs affecting Netskope products, 19 of them in the **Netskope Client** and 12 published in 2025–2026 — the Client is the recurring vulnerability surface, not the tenant. Treat client auto-upgrade as a security control, and pair it with the tamper protections in [5.3](#53-enable-netskope-client-tamper-protection).

| CVE | Component | Summary | Published | CVSS |
|-----|-----------|---------|-----------|------|
| [CVE-2025-15641](https://nvd.nist.gov/vuln/detail/CVE-2025-15641) | Netskope Client | Admin IOCTL tamper-protection bypass | 2026-06-17 | 6.8 |
| [CVE-2025-15642](https://nvd.nist.gov/vuln/detail/CVE-2025-15642) | Netskope Client | Weak DACLs on Client resources | 2026-06-17 | 6.8 |
| [CVE-2026-2810](https://nvd.nist.gov/vuln/detail/CVE-2026-2810) | Endpoint DLP driver | Out-of-bounds read | 2026-04-29 | — |
| [CVE-2026-2809](https://nvd.nist.gov/vuln/detail/CVE-2026-2809) | Netskope Client | See NVD entry | 2026 | — |
| [CVE-2025-15584](https://nvd.nist.gov/vuln/detail/CVE-2025-15584) | Netskope Client | See NVD entry | 2025 | — |

- Full list: [NVD keyword search — Netskope](https://nvd.nist.gov/vuln/search/results?query=Netskope)
- Monitor [Netskope Security, Compliance and Assurance](https://www.netskope.com/company/security-compliance-and-assurance) for current advisories.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.1 | ai-drafted | Cheat-sheet cell repair: added missing Attack Prevented line(s) to §1.1, §2.1, §3.1, §5.1 (no content-facts changed) | Claude Code (Fable 5) |
| 2026-08-08 | 0.2.0 | ai-drafted | Correct 1.2 console paths to Settings > Administration (IP Allowlist, Admins > Settings); add 1.3 admin login hardening, 5.3 Client tamper protection, 5.4 hardened Client enrollment, and section 8 Private Access & Publisher hardening; replace the "no incidents" claim in Appendix B with the NVD Netskope Client CVE record | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with CASB, DLP, and threat protection | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
