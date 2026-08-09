---
layout: guide
title: "Rapid7 Hardening Guide"
vendor: "Rapid7"
slug: "rapid7"
tier: "2"
category: "Security"
description: "Vulnerability management platform hardening for Rapid7 InsightVM and Command Platform including SSO, console security, and user management"
version: "0.2.2"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

Rapid7 is a leading cybersecurity platform providing vulnerability management, SIEM, and threat detection for **thousands of organizations** worldwide. As a critical security tool with privileged access to infrastructure vulnerability data, Rapid7 configurations directly impact security visibility and incident response capabilities.

### Intended Audience
- Security engineers managing vulnerability programs
- IT administrators configuring Rapid7 products
- GRC professionals using compliance features
- SOC analysts managing InsightVM and InsightIDR

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Rapid7 Insight Platform and InsightVM Security Console security including SAML SSO, user management, console hardening, and Command Platform administration.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Console Security](#2-console-security)
3. [User & Access Management](#3-user--access-management)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure Command Platform SSO

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO for centralized authentication to the Rapid7 Command Platform.

#### Rationale
**Why This Matters:**
- Centralizes identity management across Rapid7 products
- Enforces organizational MFA policies
- Simplifies user provisioning and deprovisioning
- Required for enterprise security compliance

**Attack Prevented:** Credential theft, phishing, password reuse, MFA bypass via local accounts, orphaned-account access after offboarding

#### Prerequisites
- Rapid7 Insight Platform subscription
- Command Platform Administrator role
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Command Platform** → **Administration** → **Platform Settings**
2. Click **SSO Settings** tab
3. Locate Authentication Settings section

**Step 2: Upload SAML Certificate**
1. Obtain X.509 certificate from your IdP
2. Certificate must be base64-encoded with DER encoding
3. Upload certificate to Command Platform

**Step 3: Configure Identity Provider**
1. Create SAML application in IdP (Okta, Azure, etc.)
2. Configure required attribute mappings:
   - **FirstName:** User's first name
   - **LastName:** User's last name
   - **Email:** User's email address
3. Map these labels exactly as shown
4. Optionally add the **rbacGroups** attribute, which carries Command Platform **User Group** names in the assertion. Populating it from IdP group membership makes the IdP the authority for platform RBAC: a user's groups — and therefore their permissions — are recalculated at every login, and removing them from an IdP group revokes the corresponding platform access without a separate console change. Pair this with the role design in [3.1](#31-implement-role-based-access-control) so the group names you emit map to genuinely least-privilege roles.

**Step 4: Complete Configuration**
1. Enter IdP SSO URL
2. Enter Entity ID
3. Test SSO authentication
4. Enable SSO enforcement

**Time to Complete:** ~1 hour

---

### 1.2 Configure InsightVM Console SSO

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO directly on InsightVM Security Console for local authentication.

#### Rationale
**Why This Matters:**
- Routing console logins through your corporate IdP enforces MFA, conditional access, and centralized session policy on a host that aggregates enterprise-wide vulnerability data
- Local console accounts bypass IdP controls and become standing targets for credential stuffing and brute force, especially on an internet-reachable console
- SAML-based authorization ties console access to IdP group membership, so deprovisioning a user in the IdP immediately removes their access to scan results and exploitable-asset inventories
- Disabling local authentication after the grace period eliminates the parallel password login path that attackers prefer

**Attack Prevented:** Credential stuffing, password brute force, MFA bypass via local accounts, orphaned-account access

#### ClickOps Implementation

**Step 1: Access SAML Configuration**
1. Navigate to: **Administration** → **Authentication: 2FA and SSO**
2. Click **Configure SAML Source**

**Step 2: Upload IdP Metadata**
1. Download IdP metadata XML file
2. Click **Choose File** and select metadata
3. Click **Save**

**Step 3: Configure Base Entity URL**
1. If ACS URL includes hostname/FQDN:
   - Set Base Entity URL: `https://<console-hostname>:3780`
2. Restart console services after applying

**Step 4: Enable SAML Authorization**
1. Navigate to: **Administration** → **User Management**
2. For each user, set **SAML Authorization Method** → **SAML**
3. Ensure email addresses match exactly (case-sensitive)

**Important:** Enabling Command Platform Login disables local authentication after 60-day grace period.

---

### 1.3 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Rapid7 platform users.

#### Rationale
**Why This Matters:**
- MFA stops an attacker who has already stolen a valid password from logging in, the single most effective control against account takeover
- Rapid7 accounts expose the organization's full vulnerability posture and exploitable-asset map, exactly the reconnaissance data an attacker wants
- Phishing-resistant MFA for administrators blocks real-time proxy phishing and push-fatigue attacks that defeat weaker second factors
- Enforcing MFA at both the IdP and the console layer closes any local login path that would otherwise skip the second factor

**Attack Prevented:** Credential theft, phishing, password reuse, account takeover, push-bombing

#### ClickOps Implementation

**Step 1: Configure via IdP (Recommended)**
1. Enable MFA in your identity provider
2. All SSO users subject to IdP MFA policies
3. Use phishing-resistant methods for admins

**Step 2: Enable Console 2FA**
1. Navigate to: **Administration** → **Authentication: 2FA and SSO**
2. Configure two-factor authentication settings
3. Require 2FA for all console users

**Step 3: Verify Enforcement**
1. Test login with MFA
2. Verify no bypass is possible
3. Document MFA methods

---

## 2. Console Security

### 2.1 Secure Console Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Secure network access to the InsightVM Security Console.

#### Rationale
**Why This Matters:**
- The Security Console aggregates every discovered vulnerability across the estate, so limiting who can reach it on the network shrinks a high-value attack surface
- A valid TLS certificate prevents man-in-the-middle interception and the certificate-warning fatigue that trains users to ignore trust errors
- Restricting ports 3780 and 40814 to management networks blocks internet-based attackers from reaching the console and scan-engine channels
- Session timeouts and lockouts limit the window for hijacked sessions and slow online password guessing

**Attack Prevented:** Network reconnaissance, man-in-the-middle, session hijacking, brute force, unauthorized internet exposure

#### ClickOps Implementation

**Step 1: Configure HTTPS**
1. Console uses HTTPS by default on port 3780
2. Install valid TLS certificate
3. Replace self-signed certificate

**Step 2: Restrict Network Access**
1. Limit console access to management networks
2. Use firewall rules to restrict:
   - Port 3780 (Web interface)
   - Port 40814 (Scan engine communication)
3. Allow the outbound flows the console genuinely needs, and only those:
   - Outbound TCP 443 to `updates.rapid7.com` (product and content updates — blocking it silently ages your vulnerability content)
   - Outbound UDP 31400 (agent UUID correlation)
4. Block public internet access
5. If you deploy Scan Assistant on targets to avoid distributing scan credentials (see [4.1](#41-configure-vulnerability-scanning-security)), permit only engine-to-target traffic on the Scan Assistant listener and confirm the port your deployment uses in the console before opening it

**Step 3: Configure Session Settings**
1. Navigate to: **Administration** → **Security Console Configuration**
2. Review the session timeout. The shipped default is **600 seconds (10 minutes)** — keep it, or set a value no higher than 30 minutes. A shorter timeout is what limits the window in which an unattended or hijacked console session can be used against an interface that exposes the entire vulnerability inventory.
3. **Vendor/hardening conflict — read before changing:** Rapid7's Security Console best-practices documentation recommends *increasing* the timeout (commonly to 1800 or 3600 seconds) so that long-running console operations do not expire mid-task. That is a usability and compatibility recommendation, not a security one: raising the timeout to one hour extends the exploitable window for session hijacking and walk-up access by six times over the default. Raise it only if a documented operational need exists, restrict the change to the accounts that need it, and compensate with strict network access (Step 2) and MFA (see [1.3](#13-enforce-multi-factor-authentication)). Source: [Security Console Best Practices](https://docs.rapid7.com/insightvm/security-console-best-practices/).
4. Enable session lockout after failed attempts

---

### 2.2 Harden Console Installation

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Apply hardening configurations to the Security Console server.

#### Rationale
**Why This Matters:**
- Timely updates close known vulnerabilities in the console software before they can be exploited against a security-critical system
- Enforcing TLS 1.2 or higher and disabling weak ciphers prevents downgrade attacks and decryption of administrative traffic
- Removing unnecessary OS services and patching the host reduces the lateral-movement and privilege-escalation paths available after any initial foothold
- A hardened console protects the integrity of the vulnerability data that downstream remediation and compliance decisions depend on

**Attack Prevented:** Exploitation of unpatched software, TLS downgrade, weak-cipher decryption, host-level lateral movement

#### ClickOps Implementation

**Step 1: Update Console Regularly**
1. Navigate to: **Administration** → **Updates**
2. Check for available updates
3. Apply updates during maintenance windows

**Step 2: Configure TLS Settings**
1. Disable weak ciphers
2. Enforce TLS 1.2 or higher
3. Configure strong cipher suites

**Step 3: Secure Operating System**
1. Apply OS security patches
2. Disable unnecessary services
3. Configure host-based firewall

---

### 2.3 Configure Scan Engine Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 7.1 |
| NIST 800-53 | RA-5 |

#### Description
Secure scan engine configurations and communications.

#### Rationale
**Why This Matters:**
- Scan engines hold privileged credentials and reach deep into network segments, so compromising one can give an attacker broad access to scan targets
- Encrypted console-to-engine communication prevents interception of scan results and credentials in transit
- Unique, rotatable pairing keys ensure a leaked key cannot be reused to register a rogue engine or impersonate a trusted one
- Removing inactive engines and placing engines in the correct segments limits the standing footprint an attacker could hijack

**Attack Prevented:** Rogue engine registration, credential interception, man-in-the-middle on scan traffic, lateral movement via compromised engines

#### ClickOps Implementation

**Step 1: Secure Engine Communication**
1. Navigate to: **Administration** → **Scan Engines**
2. Review all connected engines
3. Ensure encrypted communication

**Step 2: Manage Pairing Keys**
1. Generate unique pairing keys for each engine
2. Rotate keys if compromised
3. Remove inactive engines

**Step 3: Configure Engine Placement**
1. Deploy engines in appropriate network segments
2. Ensure engines can reach scan targets
3. Use distributed engines for segmented networks

---

### 2.4 Protect the Console Keystore and Private Keys

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11, 8.5 |
| NIST 800-53 | SC-12, SC-28, SI-7 |

#### Description
Protect the Security Console's Java keystore and its encryption key on disk with file integrity monitoring and filesystem or full-disk encryption, and ensure the console certificate's Subject Alternative Name carries the console FQDN.

#### Rationale
**Why This Matters:**
- The console keystore at `/opt/rapid7/nexpose/nsc/keystores/nsc.ks` holds the private key that authenticates the console to every browser and scan engine that trusts it; anyone who reads that file can impersonate the console or decrypt intercepted administrative traffic
- The keystore's encryption key lives separately at `/opt/rapid7/nexpose/shared/conf/creds.kspw`, so an attacker with host-level file read on both paths has everything needed to unlock it — the separation only helps if both files are protected and monitored
- File integrity monitoring on these paths converts a silent key theft or key replacement into an alertable event, since neither file changes during normal operation
- Filesystem or full-disk encryption (LUKS, BitLocker, EFS) protects the same material at rest against offline access to a stolen disk, a snapshot, or a decommissioned VM image
- A certificate whose Subject Alternative Name does not include the console FQDN forces administrators past a browser trust warning on every login, which trains exactly the behavior an attacker needs for a man-in-the-middle to go unnoticed

**Attack Prevented:** Private key theft, console impersonation, man-in-the-middle on administrative sessions, offline extraction from disk images or snapshots, undetected key substitution

#### ClickOps Implementation

**Step 1: Restrict and monitor the key material**
1. Confirm the keystore and its encryption key are present at the documented paths:
   - Keystore: `/opt/rapid7/nexpose/nsc/keystores/nsc.ks`
   - Keystore encryption key: `/opt/rapid7/nexpose/shared/conf/creds.kspw`
2. Restrict filesystem permissions so only the Rapid7 service account and host administrators can read either file
3. Add both paths to your file integrity monitoring tooling and alert on any read-permission change, modification, or replacement

**Step 2: Encrypt the underlying storage**
1. Enable filesystem or full-disk encryption on the console host — LUKS on Linux, BitLocker or EFS on Windows
2. Confirm snapshots, backups, and cloned images of the console host inherit that encryption
3. Wipe or securely destroy decommissioned console disks rather than reusing them

**Step 3: Validate the console certificate**
1. Ensure the certificate presented on port 3780 lists the console FQDN in its **Subject Alternative Name**, not only in the Common Name
2. Confirm administrators reach the console by that FQDN so no trust warning is ever expected
3. Re-verify the SAN after every certificate renewal or console hostname change

---

## 3. User & Access Management

### 3.1 Implement Role-Based Access Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure granular roles for least privilege access.

#### Rationale
**Why This Matters:**
- Least-privilege roles ensure a compromised or insider account can only touch the sites, scans, and reports it genuinely needs, limiting blast radius
- Granular custom roles prevent over-provisioning, where every analyst inherits configuration or administrative rights they will never use
- Restricting Global Administrator to a handful of users reduces the number of accounts that, if taken over, could reconfigure scanning or exfiltrate the full vulnerability inventory
- Documented assignments make access reviews and audits enforceable rather than guesswork

**Attack Prevented:** Privilege escalation, insider abuse, lateral movement, excessive standing access

#### ClickOps Implementation

**Step 1: Review Built-in Roles**
1. Navigate to: **Administration** → **User Management**
2. Review available roles:
   - **Global Administrator:** Full platform access
   - **Asset Owner:** View assigned assets
   - **User:** Standard scanning capabilities
   - **Security Manager:** Security configuration

**Step 2: Create Custom Roles**
1. Navigate to: **Administration** → **Roles**
2. Click **Create Role**
3. Configure permissions:
   - Site access
   - Scan management
   - Report access
   - Configuration rights

**Step 3: Assign Minimum Required Roles**
1. Limit Global Administrator to 2-3 users
2. Use custom roles for specific functions
3. Document role assignments

#### Code Implementation

{% include pack-code.html vendor="rapid7" section="3.1" %}

---

### 3.2 Manage Administrator Accounts

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Protect and limit administrator account access.

#### Rationale
**Why This Matters:**
- Admin accounts can modify all configurations
- Compromised admin access exposes vulnerability data
- Minimize admin accounts to reduce risk

**Attack Prevented:** Administrator account takeover, privilege escalation, unauthorized configuration change, credential reuse between daily-driver and privileged accounts

#### ClickOps Implementation

**Step 1: Inventory Admin Accounts**
1. Navigate to: **Administration** → **User Management**
2. Filter by administrator roles
3. Document all admin accounts

**Step 2: Apply Least Privilege**
1. Remove unnecessary admin access
2. Create separate accounts for admin vs. daily tasks
3. Review quarterly

**Step 3: Protect Admin Credentials**
1. Use strong, unique passwords (20+ characters)
2. Store in password vault
3. Enable MFA for all admins

#### Code Implementation

{% include pack-code.html vendor="rapid7" section="3.2" %}

---

### 3.3 Configure Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs for security events.

#### Rationale
**Why This Matters:**
- Audit logs are the primary evidence trail for detecting account compromise, unauthorized configuration changes, and abnormal scan activity on the platform
- Forwarding logs to a SIEM enables correlation and alerting that surfaces attacks the console alone would never flag
- A minimum 90-day retention preserves the forensic window needed to reconstruct an incident, since attackers often dwell for weeks before discovery
- Logging provisioning, role changes, and admin logins catches privilege abuse and stealthy backdoor accounts early

**Attack Prevented:** Undetected account compromise, log tampering, privilege abuse, delayed breach detection

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Administration** → **Audit Log**
2. Review logged events:
   - User logins
   - Configuration changes
   - Scan activities
   - Report generation

**Step 2: Configure Log Retention**
1. Set retention period (minimum 90 days)
2. Export logs for long-term storage
3. Integrate with SIEM

**Step 3: Monitor Key Events**
1. Admin login events
2. User provisioning/deprovisioning
3. Role modifications
4. Console configuration changes

---

## 4. Monitoring & Compliance

### 4.1 Configure Vulnerability Scanning Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 7.1 |
| NIST 800-53 | RA-5 |

#### Description
Secure vulnerability scanning configurations.

#### Rationale
**Why This Matters:**
- Scan credentials are high-value secrets that, if stolen, grant authenticated access to every asset they were meant to scan
- Using least-privilege scan accounts instead of domain admin ensures a compromised credential cannot be used to take over the entire domain
- Vaulting and rotating credentials via CyberArk or HashiCorp Vault removes long-lived static secrets and limits the value of any single leak
- Auditing and restricting who can view or edit credentials prevents insiders from harvesting privileged accounts from the scanner

**Attack Prevented:** Credential theft, domain compromise via over-privileged scan accounts, insider credential harvesting, lateral movement

#### ClickOps Implementation

**Step 1: Secure Scan Credentials**
1. Navigate to: **Administration** → **Shared Credentials**
2. Use least privilege for scan accounts
3. Never use domain admin credentials

**Step 2: Configure Credential Vault Integration**
1. Integrate with CyberArk or HashiCorp Vault
2. Retrieve credentials dynamically
3. Rotate credentials regularly

**Step 3: Protect Credential Storage**
1. Rapid7 encrypts stored credentials
2. Limit who can view/edit credentials
3. Audit credential access

**Step 4: Prefer Scan Assistant Over Distributed Credentials**
1. Where supported, deploy **Scan Assistant** on scan targets instead of storing and distributing privileged scan credentials in the console. Scan Assistant authenticates the scan engine to the target using a digital certificate, so authenticated scanning happens without an administrative password ever being held by the console or replayed across the estate.
2. This removes the single highest-value secret in the platform from circulation: a credential that is never stored cannot be stolen from the console, harvested by an insider, or rotated late.
3. Where Scan Assistant is not an option, keep the least-privilege shared credentials above — but scope each credential to the smallest set of sites and assets that genuinely needs it.
4. Allow the Scan Assistant listener only from your scan engines (see [2.1](#21-secure-console-access)) and confirm the port in your own console before opening firewall rules.

---

### 4.2 Configure Compliance Assessment

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Enable policy compliance scanning for hardening verification.

#### Rationale
**Why This Matters:**
- Policy compliance scans continuously verify that hardening baselines like CIS Benchmarks and DISA STIGs are actually applied, catching configuration drift before attackers exploit it
- Automated assessment surfaces insecure defaults and misconfigurations that manual reviews routinely miss across a large fleet
- Tracking remediation converts findings into accountable, time-bound fixes instead of unaddressed risk
- Scheduled assessments provide auditable evidence of an ongoing control rather than a point-in-time snapshot

**Attack Prevented:** Exploitation of configuration drift, insecure-default abuse, compliance gaps, unremediated misconfigurations

#### ClickOps Implementation

**Step 1: Configure Policy Scans**
1. Navigate to: **Policies** → **Create Policy**
2. Select compliance framework:
   - CIS Benchmarks
   - DISA STIGs
   - Custom policies

**Step 2: Schedule Assessments**
1. Configure scan schedules
2. Target appropriate assets
3. Set up notifications

**Step 3: Track Remediation**
1. Review compliance results
2. Assign remediation tasks
3. Monitor improvement trends

---

### 4.3 Configure InsightIDR Integration

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | SI-4 |

#### Description
Integrate InsightVM with InsightIDR for security monitoring.

#### Rationale
**Why This Matters:**
- Sharing vulnerability context with InsightIDR lets detection rules prioritize alerts on assets that are both exposed and actually exploitable, cutting attacker dwell time
- Combining vulnerability and detection data closes the gap between knowing a weakness exists and seeing it being exploited in real time
- Alerts on critical vulnerabilities drive faster response before a known exploit is weaponized against the environment
- Automated responses contain threats at machine speed, shrinking the window an attacker has to act

**Attack Prevented:** Delayed threat detection, exploitation of known vulnerabilities, extended attacker dwell time, missed lateral movement

#### ClickOps Implementation

**Step 1: Enable Platform Integration**
1. Both products use Command Platform
2. Data automatically shared
3. Verify integration status

**Step 2: Configure Alerts**
1. Set up alerts for critical vulnerabilities
2. Configure detection rules
3. Enable automated responses

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Rapid7 Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-command-platform-sso) |
| CC6.2 | RBAC | [3.1](#31-implement-role-based-access-control) |
| CC6.6 | Console security | [2.1](#21-secure-console-access) |
| CC7.1 | Vulnerability scanning | [4.1](#41-configure-vulnerability-scanning-security) |
| CC7.2 | Audit logging | [3.3](#33-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Rapid7 Control | Guide Section |
|---------|----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-command-platform-sso) |
| IA-2(1) | MFA | [1.3](#13-enforce-multi-factor-authentication) |
| AC-6 | Least privilege | [3.1](#31-implement-role-based-access-control) |
| RA-5 | Vulnerability scanning | [4.1](#41-configure-vulnerability-scanning-security) |
| CM-6 | Compliance assessment | [4.2](#42-configure-compliance-assessment) |

---

## Appendix A: References

**Official Rapid7 Documentation:**
- [Rapid7 Documentation Hub](https://documentation.rapid7.com/home/home.htm) — current documentation entry point
- [Rapid7 Documentation (legacy docs.rapid7.com)](https://docs.rapid7.com/) — still live; the deep links below resolve here
- [Exposure Command Documentation](https://documentation.rapid7.com/exposure-command/) — the platform InsightVM capabilities are being consolidated into
- [Configure SSO access to InsightVM Security Console](https://docs.rapid7.com/insightvm/configuring-sso/)
- [Configure SSO for Command Platform](https://docs.rapid7.com/insight/single-sign-on/)
- [Configure Azure as SAML source](https://docs.rapid7.com/insightvm/azure-saml-config/)
- [Troubleshooting SAML SSO](https://docs.rapid7.com/insightvm/troubleshooting-sso/)
- [Security Console Best Practices](https://docs.rapid7.com/insightvm/security-console-best-practices/)

**API & Developer Resources:**
- [Insight Platform API Overview](https://docs.rapid7.com/insight/api-overview/)

**Release Notes:**
- InsightVM release notes on `docs.rapid7.com` are frozen as of 2025-05-23. Newer release notes are published in the Command Platform Help on the [documentation hub](https://documentation.rapid7.com/home/home.htm) — check there, not the legacy site, when verifying whether a setting or default has changed.

**Security Incidents:**
- **Codecov Supply Chain Breach (2021):** Attackers accessed a small subset of Rapid7 source code repositories via a compromised Codecov Bash Uploader. Some internal credentials and alert-related data for a subset of MDR customers were exposed. No direct breach of Rapid7 infrastructure in 2024-2025 has been publicly reported.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.2 | draft | First Code Packs: `hth-rapid7-3.01` (role/privilege audit via GET /api/3/roles and /api/3/users) and `hth-rapid7-3.02` (Global Administrator inventory, admin-count ceiling, and console 2FA status via GET /api/3/users/{id}/2FA), both read-only scripts verified against the InsightVM Security Console API v3 OpenAPI spec; wired 3.1 and 3.2 pack includes | Claude Code (Fable 5) |
| 2026-08-08 | 0.2.1 | draft | Add missing Attack Prevented lines to 1.1 and 3.2 so every cheat-sheet cell is populated | Claude Code (Opus 4.8) |
| 2026-08-08 | 0.2.0 | draft | Currency pass: new 2.4 console keystore and private-key protection; corrected 2.1 session timeout to the shipped 600s default with a documented vendor-conflict callout; added updates.rapid7.com and UDP 31400 to the 2.1 port list; added Scan Assistant as the credential-less scanning path in 4.1; documented the SAML rbacGroups attribute in 1.1; refreshed references to the documentation.rapid7.com hub and dropped trust-center links. Tier 3/4 research sweep out of scope this pass | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, console security, and user management | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
