---
layout: guide
title: "Cloudflare Zero Trust Hardening Guide"
vendor: "Cloudflare"
slug: "cloudflare"
tier: "1"
category: "Security"
description: "Security hardening for Cloudflare Zero Trust, Access, Gateway, and WARP deployment"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
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

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Cloudflare Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | IdP authentication | [1.1](#11-configure-identity-provider-integration) |
| CC6.1 | MFA enforcement | [1.2](#12-configure-multi-factor-authentication) |
| CC6.2 | Admin roles | [1.4](#14-configure-admin-role-restrictions) |
| CC6.6 | Access policies | [2.1](#21-create-secure-application-policies) |
| CC7.1 | Gateway filtering | [3.1](#31-configure-dns-filtering) |
| CC7.2 | Logging | [6.1](#61-configure-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Cloudflare Control | Guide Section |
|---------|-------------------|---------------|
| IA-2 | IdP integration | [1.1](#11-configure-identity-provider-integration) |
| IA-2(1) | MFA | [1.2](#12-configure-multi-factor-authentication) |
| AC-3 | Access policies | [2.1](#21-create-secure-application-policies) |
| AC-2(11) | Device posture | [2.3](#23-configure-device-posture-checks) |
| SC-7 | Gateway policies | [3.1](#31-configure-dns-filtering) |
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
- **March 2025 — Third-party vendor breaches (Salesloft/Drift) exposed limited customer data.** Attackers compromised Cloudflare's marketing vendors, gaining indirect access to a subset of customer information. Cloudflare's core infrastructure was not affected. ([The Register](https://www.theregister.com/2024/02/02/cloudflare_okta_atlassian/))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with Access, Gateway, and WARP hardening | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
