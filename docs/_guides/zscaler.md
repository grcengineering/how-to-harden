---
layout: guide
title: "Zscaler Hardening Guide"
vendor: "Zscaler"
slug: "zscaler"
tier: "1"
category: "Security"
description: "Security hardening for Zscaler ZIA, ZPA, and Client Connector deployment"
version: "0.1.2"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

Zscaler is a cloud-native security platform providing Zero Trust Network Access (ZTNA) through Zscaler Internet Access (ZIA) and Zscaler Private Access (ZPA). With **40+ million users protected daily**, Zscaler serves as a critical security control point for web traffic inspection, application access, and threat prevention. Properly hardening Zscaler configurations is essential for maximizing security value and preventing bypass.

### Intended Audience
- Security engineers managing Zscaler deployments
- IT administrators configuring ZIA/ZPA policies
- GRC professionals assessing network security
- Third-party risk managers evaluating ZTNA solutions

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Zscaler Internet Access (ZIA), Zscaler Private Access (ZPA), and Zscaler Client Connector security configurations. Cloud infrastructure and DLP-specific configurations are covered in related sections.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [ZIA Web Security Policies](#2-zia-web-security-policies)
3. [ZPA Application Access](#3-zpa-application-access)
4. [Client Connector Hardening](#4-client-connector-hardening)
5. [SSL Inspection](#5-ssl-inspection)
6. [Monitoring & Detection](#6-monitoring--detection)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Configure SAML SSO Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML-based SSO for Zscaler Admin Portal and Client Connector authentication through your corporate identity provider.

#### Rationale
**Why This Matters:**
- Centralizes authentication management so every admin and user login is subject to one set of corporate controls
- Enables MFA enforcement through the IdP, which is where conditional access and device signals already live
- Provides consistent access policies across the ZIA portal, the ZPA portal, and Client Connector enrollment
- Eliminates standalone Zscaler passwords, which survive offboarding and are invisible to IdP-based deprovisioning

**Attack Prevented:** Credential stuffing and password reuse against local accounts, phishing-driven admin takeover, orphaned-account access after offboarding, MFA bypass through a standalone login path

#### Prerequisites
- Zscaler ZIA or ZPA subscription
- SAML 2.0 compatible identity provider
- Super Admin access to Zscaler Admin Portal

#### ClickOps Implementation

**Step 1: Configure Admin Portal SSO**
1. Navigate to: **ZIA Admin Portal** → **Administration** → **Authentication Settings**
2. Select **SAML** as authentication method
3. Configure:
   - **IdP URL:** Your IdP's SSO endpoint
   - **Entity ID:** IdP entity ID
   - **Certificate:** Upload X.509 certificate
   - **Name ID Format:** Email or UPN

**Step 2: Configure IdP**
1. Create SAML application for Zscaler in your IdP
2. Configure attributes:
   - NameID → user.email
   - department → user.department (optional)
3. Assign admin users/groups

**Step 3: Configure User Authentication for Client Connector**
1. Navigate to: **Administration** → **Authentication Settings** → **User Authentication**
2. Select SAML for user authentication
3. Configure IdP-initiated or SP-initiated SSO

**Time to Complete:** ~1 hour

---

### 1.2 Implement Role-Based Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Configure granular admin roles in Zscaler to limit access based on job responsibilities. Avoid using Super Admin for routine tasks.

#### Rationale
**Why This Matters:**
- Super Admin has unrestricted access to all settings, including the policies and SSL inspection scope that every other control in this guide depends on
- Compromised admin accounts have significant impact — an attacker holding Super Admin can disable inspection or add bypass rules rather than having to evade the controls
- Role-based access supports audit requirements and makes each configuration change attributable to a person with a defined function
- Reserving Super Admin for emergencies keeps the standing privilege pool small, so routine work does not run at the blast radius of the whole tenant

**Attack Prevented:** Admin account takeover, policy tampering and inspection disablement, privilege abuse by over-scoped operators, unattributable configuration changes

#### ClickOps Implementation

**Step 1: Review Current Admins**
1. Navigate to: **Administration** → **Administrator Management**
2. Review current admin accounts and roles
3. Document Super Admin assignments

**Step 2: Create Functional Roles**
1. Navigate to: **Role Management**
2. Create custom roles for different functions:
   - **Security Analyst:** View-only access to logs and reports
   - **Policy Admin:** Manage web and firewall policies
   - **User Admin:** Manage user groups and authentication
3. Assign minimum required permissions

**Step 3: Implement Least Privilege**
1. Limit Super Admin to 2-3 accounts maximum
2. Assign functional roles for daily operations
3. Document role assignments

| Role | Recommended Access |
|------|-------------------|
| Super Admin | Full control (emergency only) |
| Security Admin | Policy management, reporting |
| Help Desk | User management, basic troubleshooting |
| Auditor | Read-only access to logs and configs |

---

## 2. ZIA Web Security Policies

### 2.1 Configure URL Filtering Policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.2 |
| NIST 800-53 | SC-7, SI-3 |

#### Description
Configure URL filtering policies to block access to malicious, risky, and policy-violating web categories.

#### Rationale
**Why This Matters:**
- URL filtering is foundational web security and the cheapest place to stop an attack chain — before a payload is ever fetched
- Blocks access to known malicious sites, including the phishing and malware-hosting categories that carry most initial access
- Prevents productivity loss and policy violations, and denies the anonymizer and remote-access categories attackers use to route around controls
- Zscaler provides recommended policy templates, so the hardened baseline does not have to be assembled category by category from scratch

**Attack Prevented:** Phishing page delivery, malware and cryptomining site access, botnet command-and-control callbacks, inspection evasion via anonymizers and unapproved remote-access tools

#### ClickOps Implementation

**Step 1: Access Recommended Policy**
1. Navigate to: **ZIA Admin Portal** → **Policy** → **URL & Cloud App Control**
2. Click **Recommended Policy** link in upper-right corner
3. Review Zscaler's industry best practice recommendations

**Step 2: Configure Block Categories**
1. Create/edit URL filtering rule
2. Block high-risk categories:
   - **Security:** Malware, Phishing, Botnet, Cryptomining
   - **Legal:** Adult, Gambling, Illegal Activities
   - **Risk:** P2P, Anonymizers, Remote Access Tools
3. Configure action: **Block**
4. Enable for all users/locations

**Step 3: Configure Caution Categories**
1. Create rule for medium-risk categories:
   - Uncategorized, Newly Registered Domains
   - File Sharing, Online Storage (if not business-approved)
2. Configure action: **Caution** (user override with acknowledgment)

**Time to Complete:** ~45 minutes

{% include pack-code.html vendor="zscaler" section="2.1" %}

---

### 2.2 Enable Advanced Threat Protection

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.1, 10.5 |
| NIST 800-53 | SI-3, SI-4 |

#### Description
Enable Zscaler's advanced threat protection capabilities including cloud sandbox, malware protection, and behavioral analysis.

#### Rationale
**Why This Matters:**
- Cloud sandbox detonates unknown files in an isolated environment, catching zero-day and evasive malware that signature-only engines miss
- Inline malware blocking stops known and suspected threats before they reach the endpoint, removing the dwell time of post-infection cleanup
- Behavioral analysis flags payloads that look benign at download but act maliciously, closing the gap that staged and drive-by downloads exploit
- As a cloud proxy in the traffic path, Zscaler can quarantine threats for every user and location without per-device agents

**Attack Prevented:** Zero-day malware, ransomware delivery, drive-by downloads, evasive/polymorphic payloads, command-and-control callbacks

#### ClickOps Implementation

**Step 1: Configure Malware Protection**
1. Navigate to: **Policy** → **Malware Protection**
2. Configure protection settings:
   - **Block known malware:** Enabled
   - **Block suspected malware:** Enabled (L2)
   - **Block adware/spyware:** Enabled
3. Set scan limits appropriately (100MB+)

**Step 2: Enable Cloud Sandbox**
1. Navigate to: **Policy** → **Sandbox Policy**
2. Configure:
   - **File types:** Executables, documents, archives
   - **Action on unknown:** Quarantine pending analysis
   - **Timeout action:** Block (for sensitive environments)

**Step 3: Enable Inline Prevention**
1. Configure real-time threat blocking
2. Enable browser isolation for high-risk categories (if licensed)

{% include pack-code.html vendor="zscaler" section="2.2" %}

---

### 2.3 Configure Firewall Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.4, 13.4 |
| NIST 800-53 | SC-7, AC-4 |

#### Description
Configure Zscaler Cloud Firewall policies to control non-web traffic including protocols, ports, and applications.

#### Rationale
**Why This Matters:**
- A default-deny posture ensures only explicitly approved protocols and ports leave the environment, shrinking the egress attack surface
- Many threats and exfiltration channels ride non-web protocols (DNS tunneling, raw TCP, SSH) that URL filtering alone never inspects
- Blocking unencrypted and tunneling protocols prevents users and malware from routing around inspection and corporate controls
- Cloud-delivered firewall rules apply consistently to remote and on-network users without backhauling traffic to a datacenter appliance

**Attack Prevented:** Data exfiltration over non-web protocols, DNS tunneling, command-and-control over arbitrary ports, inspection bypass via VPN/SSH tunnels

#### ClickOps Implementation

**Step 1: Define Default Deny Policy**
1. Navigate to: **Policy** → **Firewall Control**
2. Review existing rules
3. Ensure default rule is **Block** (deny by exception)

**Step 2: Create Allow Rules**
1. Create explicit allow rules for required traffic:
   - Business-approved applications
   - Required protocols (HTTPS, DNS, etc.)
2. Apply to specific user groups/locations

**Step 3: Block Risky Protocols**
1. Create explicit block rules for:
   - Unencrypted protocols (FTP, Telnet, HTTP without upgrade)
   - Tunneling protocols (SSH tunnels, VPN bypass)
   - Remote access tools (unless approved)

{% include pack-code.html vendor="zscaler" section="2.3" %}

---

## 3. ZPA Application Access

> **Primary reference for this section:** Zscaler's [ZPA Leading Practices Guide](https://help.zscaler.com/zpa/zpa-leading-practices-guide) is the current first-party guidance for ZPA design and policy. URL sitemap-verified 2026-08 (`help.zscaler.com/sitemap.xml`, lastmod 2026-06-05); the help portal is client-rendered and its content is not retrievable by automated fetchers, so read it in a browser.

### 3.1 Configure Application Segments

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4 |
| NIST 800-53 | AC-4, SC-7 |

#### Description
Define application segments in ZPA to control access to internal applications without network-level connectivity.

#### Rationale
**Why This Matters:**
- ZPA provides Zero Trust access with no network exposure — applications are never reachable at the network layer, so they cannot be scanned or attacked by an unauthorized client
- Application segments define exactly what is accessible; a segment defined as a wide port range or subnet quietly recreates the flat network ZPA is meant to replace
- Granular access replaces broad VPN access, so a single credential no longer implies reachability of everything behind the tunnel
- Precise segment definitions reduce lateral movement risk by ensuring a compromised session reaches one application rather than an entire environment

**Attack Prevented:** Internal application exposure and scanning, lateral movement from a compromised endpoint, over-broad access from wide port or subnet definitions, VPN-style flat-network reachability

#### ClickOps Implementation

**Step 1: Create Application Segment**
1. Navigate to: **ZPA Admin Portal** → **Administration** → **Application Segments**
2. Click **Add Application Segment**
3. Configure:
   - **Name:** Descriptive name (e.g., "Finance ERP")
   - **Domain/IP:** Application FQDN or IP
   - **Port:** Specific ports (avoid 0-65535)
   - **Segment Group:** Group by security classification

**Step 2: Define Segment Groups**
1. Group applications by:
   - Security classification (Confidential, Internal, Public)
   - Business function (Finance, HR, Engineering)
   - Compliance scope (PCI, HIPAA)

**Time to Complete:** ~30 minutes per application

{% include pack-code.html vendor="zscaler" section="3.1" %}

---

### 3.2 Create Access Policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4, 6.8 |
| NIST 800-53 | AC-3, AC-6 |

#### Description
Create ZPA access policies that define who can access which applications based on user identity, device posture, and context.

#### Rationale
**Why This Matters:**
- Identity- and context-aware access enforces least privilege so users reach only the specific applications their role requires
- A default-deny model means no application is reachable until access is explicitly granted, unlike flat VPNs that expose everything once connected
- Binding access to device posture and IdP group membership blocks compromised or non-compliant endpoints from reaching sensitive apps
- Per-application policies eliminate the lateral movement that follows a single VPN credential compromise

**Attack Prevented:** Lateral movement, over-privileged access, compromised-credential application access, unauthorized internal app exposure

#### ClickOps Implementation

**Step 1: Create Access Policy Rule**
1. Navigate to: **Policy** → **Access Policy**
2. Click **Add Rule**
3. Configure conditions:
   - **User/Group:** Specify IdP groups
   - **SAML Attributes:** Department, role
   - **Device Posture:** Require device compliance
   - **Client Type:** ZPA client required

**Step 2: Map to Application Segments**
1. In rule, select target application segments
2. Apply principle of least privilege
3. Avoid "All Applications" access

**Step 3: Configure Default Deny**
1. Ensure default rule blocks access
2. All access must be explicitly permitted
3. Review and document exceptions

{% include pack-code.html vendor="zscaler" section="3.2" %}

---

### 3.3 Enable Device Posture Checks

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | AC-2(11) |

#### Description
Configure device posture checks to verify endpoint security status before granting application access.

#### Rationale
**Why This Matters:**
- Posture checks confirm a device is encrypted, patched, and running active endpoint protection before it is trusted with application access
- Without posture validation, a stolen credential on an unmanaged or jailbroken device can reach internal applications directly
- Tying access to OS version, disk encryption, firewall, and antivirus state continuously enforces the organization's endpoint baseline
- Non-compliant devices are blocked automatically, removing reliance on users to self-report or remediate

**Attack Prevented:** Access from compromised/unmanaged endpoints, credential theft on insecure devices, malware-resident device access, endpoint policy drift

#### ClickOps Implementation

**Step 1: Create Posture Profile**
1. Navigate to: **Administration** → **Posture Profiles**
2. Click **Add Posture Profile**
3. Configure checks:
   - **OS Version:** Minimum supported version
   - **Disk Encryption:** Required
   - **Firewall:** Enabled
   - **Antivirus:** Running and updated

**Step 2: Apply to Access Policy**
1. Edit access policy rules
2. Add posture profile as condition
3. Block access if posture requirements not met

{% include pack-code.html vendor="zscaler" section="3.3" %}

---

## 4. Client Connector Hardening

### 4.1 Deploy Client Connector Securely

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7, SC-7 |

#### Description
Deploy Zscaler Client Connector with security-optimized settings to ensure all traffic is properly tunneled and inspected.

#### Rationale
**Why This Matters:**
- Routing all traffic through Z-Tunnel 2.0 guarantees web, firewall, and DLP policies apply everywhere the user works, not just on the corporate network
- Always-On enforcement prevents users from disabling the connector and browsing unprotected, a common way threats enter
- Tightly scoped split-tunnel rules stop sensitive traffic from leaking around inspection while still allowing approved optimizations
- Auto-update keeps the connector patched against known vulnerabilities without manual rollout effort

**Attack Prevented:** Protection bypass, uninspected traffic, off-network compromise, man-in-the-middle on untrusted networks

#### ClickOps Implementation

**Step 1: Configure Client Connector Settings**
1. Navigate to: **ZIA Admin Portal** → **Policy** → **Client Connector Portal**
2. Configure settings:
   - **Tunnel mode:** Z-Tunnel 2.0 (recommended)
   - **Fallback:** On-Net or Off-Net based on requirements
   - **Auto-update:** Enabled

**Step 2: Enable Always-On**
1. Configure **Always-On** settings
2. Prevent users from disabling Client Connector
3. Set fallback behavior for connectivity issues

**Step 3: Configure Split Tunnel (if required)**
1. If split tunnel needed, explicitly define:
   - Office 365 optimization routes
   - Video conferencing (Zoom, Teams)
2. Minimize split tunnel scope
3. Document exceptions

---

### 4.2 Install SSL Certificate for Inspection

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | SC-8, SI-4 |

#### Description
Deploy Zscaler root certificate to enable SSL inspection of encrypted traffic.

#### Rationale
**Why This Matters:**
- The overwhelming majority of web traffic is encrypted, so without decryption the proxy sees destinations but not content
- Without SSL inspection, threats hide in HTTPS — malware delivery, command-and-control, and data exfiltration all ride the same encrypted channel as legitimate traffic
- The certificate must be trusted by endpoints, and a partial rollout produces certificate errors that push users toward disabling protection or requesting bypasses
- Deploying the root CA through MDM makes trust a managed, verifiable state rather than a per-user action

**Attack Prevented:** Malware and payload delivery hidden in TLS, encrypted command-and-control, exfiltration over HTTPS, user-driven bypass caused by certificate errors

#### ClickOps Implementation

**Step 1: Download Zscaler Certificate**
1. Navigate to: **Administration** → **SSL Policy** → **SSL Inspection**
2. Download Zscaler root CA certificate

**Step 2: Deploy via MDM**
1. Deploy certificate to managed devices via Intune, JAMF, etc.
2. Add to Trusted Root CA store
3. Verify certificate installation

**Step 3: Enable Certificate for Client Connector**
1. In Client Connector settings, enable "Install Zscaler SSL Certificate"
2. This auto-installs during Client Connector installation

---

### 4.3 Lock Client Connector Settings

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7 |

#### Description
Lock Client Connector configuration to prevent users from disabling or bypassing Zscaler protection.

#### Rationale
**Why This Matters:**
- Locking the ZIA/ZPA switches prevents users from turning off protection to reach blocked sites or evade inspection
- Password-protecting uninstall stops malware and users alike from removing the connector to operate unmonitored
- Removing admin override codes (L3) closes the temporary-bypass window that attackers and insiders exploit
- Enforced configuration means security coverage does not depend on user cooperation or discipline

**Attack Prevented:** Protection tampering, agent uninstall/disable, inspection evasion, insider bypass, malware persistence

#### ClickOps Implementation

**Step 1: Configure App Profile**
1. Navigate to: **ZIA** → **Policy** → **Client Connector Portal** → **App Profiles**
2. Create/edit app profile
3. Configure restrictions:
   - **Lock ZIA switch:** Enabled (prevent disable)
   - **Lock ZPA switch:** Enabled
   - **Password protect uninstall:** Enabled

**Step 2: Remove Admin Override (L3)**
1. For maximum security, disable admin override codes
2. Users cannot bypass even temporarily
3. Implement support process for legitimate issues

---

## 5. SSL Inspection

> **Primary reference for this section:** Zscaler's [ZIA SSL Inspection Leading Practices Guide](https://help.zscaler.com/zia/zia-ssl-inspection-leading-practices-guide) is the current first-party guidance for inspection scope, bypass handling, and rollout. URL sitemap-verified 2026-08 (`help.zscaler.com/sitemap.xml`, lastmod 2026-07-31); the help portal is client-rendered and its content is not retrievable by automated fetchers, so read it in a browser.

### 5.1 Enable SSL Inspection

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10, 13.3 |
| NIST 800-53 | SC-8, SI-3 |

#### Description
Enable SSL/TLS inspection to decrypt, inspect, and re-encrypt HTTPS traffic for threat detection and policy enforcement.

#### Rationale
**Why This Matters:**
- Encrypted traffic hides threats from inspection, so an uninspected TLS session is a control gap regardless of how well URL filtering and firewall rules are tuned
- SSL inspection enables full visibility, which is what makes the sandbox, malware, and behavioral engines effective rather than nominal
- It is required for effective DLP and malware detection — neither can act on content it cannot read
- A carefully justified bypass list keeps the exception set small and reviewable instead of letting broad categories accumulate outside inspection

**Attack Prevented:** Threat delivery inside encrypted sessions, encrypted command-and-control, data exfiltration over TLS, silent policy gaps created by unreviewed bypass exceptions

#### Prerequisites
- SSL certificate deployed to endpoints
- Certificate pinning exceptions documented
- Testing plan for application compatibility

#### ClickOps Implementation

**Step 1: Configure SSL Inspection Policy**
1. Navigate to: **Policy** → **SSL Inspection**
2. Enable SSL inspection globally
3. Configure inspection scope:
   - **Inspect all traffic:** Recommended for most traffic
   - **Bypass categories:** Privacy-sensitive (healthcare, banking - evaluate risk)

**Step 2: Configure Do Not Inspect List**
1. Add applications with certificate pinning:
   - Mobile banking apps
   - Healthcare applications
   - Government services
2. Document each exception with business justification

**Step 3: Configure Client Connector SSL**
1. Navigate to: **Policy for Zscaler Client Connector**
2. Enable SSL inspection for Client Connector users
3. Add certificate pinning apps to "Do Not Inspect" list

**Time to Complete:** ~2-4 hours (including testing)

{% include pack-code.html vendor="zscaler" section="5.1" %}

---

### 5.2 Test SSL Inspection Thoroughly

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | CA-2 |

#### Description
Thoroughly test SSL inspection before production deployment to identify and resolve application compatibility issues.

#### Rationale
**Why This Matters:**
- Validating applications before rollout prevents broken certificate-pinned apps from driving users to disable or bypass inspection
- Confirming malware detection and DLP fire on decrypted traffic proves the control actually works rather than silently failing open
- Catching certificate-chain and pinning issues in testing avoids emergency bypass exceptions that permanently weaken coverage
- A documented test and validation pass provides auditable evidence that inspection was deployed without degrading critical services

**Attack Prevented:** Inspection gaps from broken apps, silent fail-open, unmanaged bypass exceptions, undetected threats in encrypted traffic

#### Testing Checklist

**Pre-Deployment Testing:**
- Test major business applications
- Verify certificate chain validity
- Test certificate-pinned applications
- Validate mobile app functionality

**Post-Deployment Validation:**
- Monitor for user-reported issues
- Check for certificate errors in logs
- Verify malware detection is working
- Confirm DLP policies are applied

---

## 6. Monitoring & Detection

### 6.1 Configure Logging and Reporting

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-6 |

#### Description
Configure comprehensive logging and integrate with SIEM for security monitoring and incident investigation.

#### Rationale
**Why This Matters:**
- Streaming web, firewall, DNS, and sandbox logs to a SIEM gives security teams the visibility to detect and investigate threats in real time
- Without centralized logging, malicious activity and bypass attempts go unnoticed and post-incident forensic reconstruction is impossible
- Alerting on malware hits, admin changes, and authentication failures shortens the time to detect account compromise and configuration tampering
- Retained, exported logs satisfy audit and compliance evidence requirements that on-console retention alone cannot meet

**Attack Prevented:** Undetected intrusions, delayed incident response, admin account abuse, audit-trail gaps, log tampering

#### ClickOps Implementation

**Step 1: Enable Logging**
1. Navigate to: **Administration** → **Log Settings**
2. Enable all log types:
   - Web logs
   - Firewall logs
   - DNS logs
   - Sandbox logs

**Step 2: Configure SIEM Integration**
1. Navigate to: **Administration** → **Nanolog Streaming Service**
2. Configure log streaming to SIEM:
   - Splunk
   - Azure Sentinel
   - QRadar
   - Other (syslog)
3. Configure log format (JSON recommended)

**Step 3: Set Up Alerts**
1. Configure alerts for critical events:
   - Malware detection
   - Policy violations
   - Admin changes
   - Authentication failures

---

### 6.2 Key Events to Monitor

| Event | Log Source | Detection Use Case |
|-------|------------|-------------------|
| Malware blocked | Web Logs | Active threat detection |
| Policy bypass attempt | Firewall Logs | Evasion attempts |
| Admin login | Admin Audit | Unauthorized access |
| SSL bypass | SSL Logs | Inspection gaps |
| Sandbox detonation | Sandbox Logs | Zero-day threats |
| DLP violation | DLP Logs | Data exfiltration |

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Zscaler Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | SSO authentication | [1.1](#11-configure-saml-sso-authentication) |
| CC6.2 | Role-based access | [1.2](#12-implement-role-based-admin-access) |
| CC6.6 | URL filtering | [2.1](#21-configure-url-filtering-policies) |
| CC7.1 | Threat protection | [2.2](#22-enable-advanced-threat-protection) |
| CC7.2 | Logging | [6.1](#61-configure-logging-and-reporting) |

### NIST 800-53 Rev 5 Mapping

| Control | Zscaler Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | SSO authentication | [1.1](#11-configure-saml-sso-authentication) |
| AC-6(1) | Admin roles | [1.2](#12-implement-role-based-admin-access) |
| SC-7 | Firewall policies | [2.3](#23-configure-firewall-policies) |
| SI-3 | Malware protection | [2.2](#22-enable-advanced-threat-protection) |
| SC-8 | SSL inspection | [5.1](#51-enable-ssl-inspection) |

---

## Appendix A: Component Compatibility

| Feature | ZIA Standard | ZIA Advanced | ZPA |
|---------|-------------|--------------|-----|
| URL Filtering | ✅ | ✅ | N/A |
| Cloud Firewall | ✅ | ✅ | N/A |
| SSL Inspection | ✅ | ✅ | N/A |
| Cloud Sandbox | ❌ | ✅ | N/A |
| Browser Isolation | ❌ | ✅ | N/A |
| Application Access | N/A | N/A | ✅ |
| Device Posture | Limited | ✅ | ✅ |

---

## Appendix B: References

> **How these URLs were verified.** `help.zscaler.com` is a client-rendered application that returns HTTP 200 for paths that do not exist, so response status proves nothing about a link. Every `help.zscaler.com` URL below was confirmed against the server-rendered sitemap at `https://help.zscaler.com/sitemap.xml` in August 2026. Page *content* is not retrievable by automated fetchers — open these in a browser.

**Official Zscaler Documentation:**
- [ZIA Help Portal](https://help.zscaler.com/zia)
- [ZPA Help Portal](https://help.zscaler.com/zpa)
- [Client Connector Help](https://help.zscaler.com/zscaler-client-connector)
- [ZIA Policy Leading Practices Guide](https://help.zscaler.com/zscaler-deployments-operations/zia-policy-leading-practices-guide)
- [ZIA SSL Inspection Leading Practices Guide](https://help.zscaler.com/zia/zia-ssl-inspection-leading-practices-guide) — sitemap-verified 2026-08 (lastmod 2026-07-31); maps to [§5 SSL Inspection](#5-ssl-inspection)
- [ZPA Leading Practices Guide](https://help.zscaler.com/zpa/zpa-leading-practices-guide) — sitemap-verified 2026-08 (lastmod 2026-06-05); maps to [§3 ZPA Application Access](#3-zpa-application-access)
- [Zscaler Trust Security Advisories](https://trust.zscaler.com/security-advisories) — JavaScript-rendered; not retrievable by automated fetchers

**API Documentation:**
- [Getting Started with the ZIA API](https://help.zscaler.com/legacy-apis/getting-started-zia-api) — sitemap-verified 2026-08; the previous `/zia/getting-started-zia-api` path is no longer in the sitemap
- [ZPA API Documentation](https://help.zscaler.com/zpa)

**Deployment Guides:**
- [Step-by-Step Configuration Guide for Private Access](https://help.zscaler.com/zpa/step-step-configuration-guide-private-access) — sitemap-verified 2026-08; the previous `/zpa/step-step-configuration-guide-zpa` path is no longer in the sitemap
- A ZIA step-by-step configuration guide was previously linked here at `/zia/step-step-configuration-guide-zia`; that path is absent from the current sitemap and no replacement could be verified, so it has been removed rather than left as a plausible-looking dead link. The same applies to the former `/zia/best-practices-security-policy` link — use the ZIA Policy Leading Practices Guide above instead.

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018, ISO 27701, FedRAMP (product-dependent). Zscaler publishes these attestations through its compliance portal, which is not linked here: it is compliance marketing rather than hardening documentation, and the former `zscaler.com/compliance/overview` URL now redirects to `compliance.zscaler.com`, which returned HTTP 403 on verification.

**Security Incidents:**
- **August 2025 -- Salesloft Drift Supply-Chain Breach:** Threat actor UNC6395 exploited compromised Salesloft Drift OAuth tokens to access Zscaler's Salesforce instance, exfiltrating contact metadata (names, emails, job titles), product licensing configurations, and plain-text support case content. Part of a broader campaign affecting 700+ organizations. No Zscaler products, services, or infrastructure were compromised. Detected August 28, disclosed August 31, 2025. All affected OAuth tokens were revoked.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.1.2 | draft | Link-rot and rationale pass. Appendix B: corrected the ZIA API path to `/legacy-apis/getting-started-zia-api` and the ZPA step-by-step guide to `/zpa/step-step-configuration-guide-private-access`; removed the ZIA step-by-step and ZIA security-policy best-practices links (both absent from the current sitemap, no verifiable replacement); removed the `zscaler.com/compliance/overview` link (301s to `compliance.zscaler.com`, which 403s, and is compliance marketing regardless); annotated the trust.zscaler.com advisories page as JavaScript-rendered. Added the two current Tier 1 leading-practices guides — ZIA SSL Inspection (§5) and ZPA (§3) — as references, with pointers from those sections. All `help.zscaler.com` URLs are sitemap-verified via `help.zscaler.com/sitemap.xml`, since the help host returns HTTP 200 for nonexistent paths and status codes prove nothing there; page content is not renderable to fetchers. Added **Attack Prevented** to 1.1, 1.2, 2.1, 3.1, 4.2, and 5.1. Several apparent doc-surface changes (unified cross-service admin RBAC, a ZIA-API-to-OneAPI migration) were noted but not applied pending content verification — the help host is fetcher-opaque. Tier 3/4 research out of scope for this pass. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with ZIA/ZPA hardening and Client Connector security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
