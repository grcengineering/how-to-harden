---
layout: guide
title: "Idira (formerly CyberArk) Hardening Guide"
vendor: "Idira (formerly CyberArk)"
slug: "cyberark"
tier: "1"
category: "Identity"
description: "Privileged access management hardening for vaults, PSM, and credential rotation"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

> **Product naming:** The platform documented here is now branded **Idira**, a Palo Alto Networks identity security platform. Its documentation portal at [docs.cyberark.com](https://docs.cyberark.com/portal/latest/en/docs.htm) presents the product as the "Idira Identity Security Platform," and `cyberark.com` marketing URLs now resolve to [paloaltonetworks.com/idira](https://www.paloaltonetworks.com/idira). Product names in the current docs are **Privilege Cloud**, **Identity**, **Secrets Hub**, **Endpoint Privilege Manager**, and **PAM - Self-Hosted**. This guide retains the `cyberark` URL slug so existing links keep working; console paths and product names below follow the current Idira documentation, with the older CyberArk names noted where the console still shows them.

Idira (formerly CyberArk) is a Privileged Access Management (PAM) platform used across many of the world's largest enterprises. As the central vault for privileged credentials, API tokens, session recordings, and SSH keys, a compromise of this platform enables immediate access to the most sensitive enterprise systems. Secrets management integrations with HashiCorp Vault, AWS Secrets Manager, and Azure Key Vault — brokered through Secrets Hub — extend the attack surface beyond the vault itself.

### Intended Audience
- Security engineers managing PAM infrastructure
- IT administrators configuring Idira (formerly CyberArk)
- GRC professionals assessing privileged access compliance
- Third-party risk managers evaluating secrets management

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Idira/CyberArk-specific security configurations including vault hardening, API security, session management, secrets rotation, and integration security with external secrets managers.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Vault Security](#2-vault-security)
3. [API & Integration Security](#3-api--integration-security)
4. [Session Management](#4-session-management)
5. [Secrets Rotation](#5-secrets-rotation)
6. [Monitoring & Detection](#6-monitoring--detection)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Multi-Factor Authentication for All Access

**Profile Level:** L1 (Crawl)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1), IA-2(6)

#### Description
Require MFA for all console access, including PVWA (Password Vault Web Access), PSM (Privileged Session Manager), and API authentication. The vendor's own Security Fundamentals guidance names multi-factor authentication for all users *and* product administrators as a minimal requirement, and prescribes compensating controls where MFA cannot be applied.

#### Rationale
**Why This Matters:**
- The platform stores the most sensitive credentials in the enterprise, so a single-factor compromise reaches every privileged account at once
- The vendor states MFA mitigates key loggers and plaintext-password harvesting tools — the exact techniques used to pivot into a vault
- Where MFA is genuinely impossible for an access path, the documented fallback is to manage that user as a Privilege Cloud user and force the connection through PSM, never to leave the path unprotected

**Attack Prevented:** Credential theft, phishing, password spray

**Attack Scenario:** Attacker phishes a vault admin's credentials, gains access to the entire credential vault, extracts domain admin passwords.

#### ClickOps Implementation

**Step 1: Configure LDAP/RADIUS MFA Integration**
1. Navigate to: **PVWA → Administration → Options → Authentication Methods**
2. Configure RADIUS integration:
   - **Primary server:** Your MFA RADIUS endpoint
   - **Shared secret:** (stored securely)
   - **Timeout:** 60 seconds
3. Enable for user types: All

**Step 2: Enforce MFA for Specific User Types**
1. Navigate to: **PVWA → Administration → Platform Configuration**
2. For each platform:
   - Enable: **Require MFA for connection**
   - Configure MFA prompt timing

**Step 3: Configure Strong Authentication for the Identity Tenant**

> **Documentation moved.** Idira documentation is now organized into **spaces** (Setup, Manage, Detect and Respond, Access, Audit and Reports) rather than per-service doc sets. Authentication configuration for Identity now lives in the **Setup** space under [Enforce strong authentication](https://docs.cyberark.com/setup/latest/en/content/setup-space/authentication/enforce-strong-authentication.htm). The previous Identity and Identity Administration doc sets remain readable but, per the vendor, [reflect the structure and content as of April 2026 and are no longer updated](https://docs.cyberark.com/find-identity-docs/latest/en/content/getstarted/identity-new-doc-location.htm) — do not treat them as current when validating a setting.

Working from the Setup space's authentication guidance, configure the tenant to:

1. **Require MFA for all users**, using authentication-strength policies rather than per-user exceptions
2. **Prefer passwordless factors** — the current documentation calls out FIDO2/passkeys and modern SSO as supported methods
3. **Scope exceptions narrowly.** The documented model is automated enforcement plus explicit exceptions for low-risk users or applications; every exception should be justified and reviewed, and none should cover an administrative role
4. **Disable "remember device"** for administrative access at L2/L3

Because the space reorganization is recent, confirm the exact console breadcrumb in your own tenant against the Setup space page before writing it into a runbook.

#### Validation & Testing
1. Attempt PVWA login with password only - should fail
2. Complete login with password + MFA - should succeed
3. Verify MFA logged in audit trail
4. Test PSM connection with MFA requirement

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(1), IA-2(6) | MFA for privileged accounts |
| **PCI DSS** | 8.3.1 | MFA for administrative access |
| **SOX** | ITGC | Access control for financial systems |

---

### 1.2 Implement Vault-Level Access Controls

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure granular safe-level permissions ensuring users only access credentials required for their role. Implement approval workflows for sensitive safes.

#### Rationale
**Why This Matters:**
- Safe-level permissions enforce least privilege so a compromised account can reach only the credentials its role requires, not the entire vault
- Without granular scoping, any vault user becomes a path to every privileged credential, collapsing all safes into one blast radius
- Dual-control approval on sensitive safes such as DomainAdmins forces a second authorized human before high-value credentials are released

**Attack Prevented:** Lateral movement, privilege escalation, insider credential abuse, blast-radius expansion

#### ClickOps Implementation

**Step 1: Design Safe Structure**

Organize safes into logical categories (Infrastructure, Applications, Emergency) with appropriate approval requirements for each tier.

**Step 2: Configure Safe Permissions**
1. Navigate to: **PVWA → Policies → Access Control (Safes)**
2. For each safe, configure:
   - **Members:** Specific groups only
   - **Permissions:** Minimum required (Use, Retrieve, List)
   - **Require approval:** For sensitive safes

**Step 3: Create Approval Workflow**
1. Navigate to: **PVWA → Policies → Master Policy**
2. Configure:
   - **Require dual control:** Enabled for DomainAdmins safe
   - **Approvers:** Security team group
   - **Approval timeout:** 4 hours

#### Code Implementation

{% include pack-code.html vendor="cyberark" section="1.2" %}

---

### 1.3 Configure Break-Glass Procedures

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CP-2

#### Description
Implement emergency access procedures for critical scenarios when normal authentication is unavailable.

#### Rationale
**Why This Matters:**
- Emergency access keeps recovery possible during an IdP or MFA outage without leaving a permanent always-on super-admin account
- Dual control, short expiration, and enhanced logging make break-glass use rare, accountable, and quickly detectable
- Splitting credential parts across individuals and physical storage prevents any single person from unilaterally invoking emergency access

**Attack Prevented:** Standing super-admin abuse, single-person insider compromise, undetected emergency-account misuse, lockout-driven outages

#### ClickOps Implementation

**Step 1: Create Break-Glass Safe**
1. Create safe: `Emergency-BreakGlass`
2. Store emergency credentials:
   - Master user recovery credentials
   - Emergency admin accounts
   - Critical infrastructure access

**Step 2: Configure Dual Control**
1. Require approval from 2 different approvers
2. Set expiration: 1 hour
3. Enable enhanced logging

**Step 3: Physical Security**
1. Store break-glass credentials in physical safe
2. Distribute parts to different individuals
3. Document recovery procedure

---

## 2. Vault Security

### 2.1 Harden Vault Server Configuration

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-8, SC-28

#### Description
Configure secure vault server settings including encryption, communication security, and component hardening — and, on Privilege Cloud connectors, verify that the vendor's automated hardening actually applied rather than re-hardening those hosts by hand.

#### Rationale
**Why This Matters:**
- The vault server is the cryptographic root of trust; weak encryption or legacy TLS exposes every stored secret in transit and at rest
- AES-256 at rest and TLS 1.2/1.3 only prevent protocol downgrade and offline decryption of captured vault data
- Connector hardening ships as an automated procedure, so the realistic failure mode is not "nobody hardened the box" but "somebody undid the hardening" — drift detection matters more than manual configuration here

**Attack Prevented:** Protocol downgrade, man-in-the-middle interception, data-at-rest theft, host compromise via exposed services, silent regression of applied hardening

#### ClickOps Implementation

> **Connector hardening is automated — verify it, don't recreate it.** On Privilege Cloud, [the hardening procedure is applied as part of the Connector's deployment step](https://docs.cyberark.com/privilege-cloud-standard/latest/en/content/privilege%20cloud/privcloud-hardening-overview.htm) and has been reviewed by the vendor's R&D and security teams. In an Active Directory domain it is applied from a prepared **Group Policy Object (GPO)** file; out of domain, from an **INF** file. Both run through the **PSM_CPM hardening file**, which executes both the PSM and CPM hardening steps — **PSM settings override CPM settings wherever both refer to the same parameter.** Applied automatically: Windows AppLocker, TLS protocol hardening, IIS lockdown (application pools deleted, registry shares disabled, unnecessary MIME types removed, WebDAV disabled), EventLog size and retention, advanced audit and Remote Desktop Services policy, registry/file-system auditing and permissions, service disabling, and creation of the local Windows user that runs the CPM service. Ad-hoc manual hardening on these hosts risks breaking a supported configuration; the administrator's job is to confirm the automated baseline is intact and detect drift.

**Step 1: Verify Encryption Settings**
1. Check DBParm.ini and verify AES256 encryption is configured with appropriate key age settings.

**Step 2: Confirm Secure Protocols Are In Force**

The vendor requires TLS for specific channels — treat these as non-negotiable rather than as tuning options:

1. **HTTPS** for the Privilege Cloud Portal and for REST APIs
2. **TLS is required for RDP, SMTP, and Syslog** — RDP/TLS for connections to the PSM, and TLS for syslog message forwarding
3. **SSH instead of telnet** for password management
4. Disable legacy protocols and configure certificate validation

**Step 3: Verify Connector Host Baseline (Do Not Re-Harden By Hand)**
1. Confirm the deployment-time GPO/INF hardening applied and has not been reverted by later policy
2. Treat any custom change to out-of-the-box configuration files as your own responsibility — the vendor states such changes may affect security and are outside its control
3. Where you must change AppLocker behaviour, do it through the supported `Applocker.xml` rule file rather than by disabling the control

**Step 4: Constrain Session Lifetime**

Session expiration should be as short as usability allows, and the vendor's documented ceiling is that **sessions must not exceed 12 hours**.

#### Code Implementation

{% include pack-code.html vendor="cyberark" section="2.1" %}

---

### 2.2 Implement Vault High Availability

**Profile Level:** L2 (Walk)
**NIST 800-53:** CP-9, CP-10

#### Description
Configure disaster recovery and high availability for vault infrastructure.

#### Rationale
**Why This Matters:**
- The vault is a single point of failure for all privileged access; losing it can lock administrators out of every critical system during an incident
- DR replication and tested failover keep credentials retrievable when the primary site is down, including during ransomware recovery
- Quarterly failover testing and backup-integrity verification confirm recovery actually works before a real disaster forces the issue

**Attack Prevented:** Ransomware-driven lockout, single-site outage, unrecoverable backups, denial of privileged access during incident response

#### Implementation

**DR Configuration:**
1. Configure vault replication to DR site
2. Test failover quarterly
3. Document recovery procedures
4. Verify backup integrity

Use `PAReplicate.exe` to verify replication status and test DR failover in non-production environments.

---

### 2.3 Treat Connector Servers as Tier 0 Assets

**Profile Level:** L1 (Crawl)
**CIS Controls:** 4.1, 4.8, 13.4
**NIST 800-53:** AC-3, SC-7, CM-7

#### Description
Administer the PSM, CPM, PSM for SSH, and Credential Provider / Central Credential Provider hosts at the same security level as domain controllers. The vendor states plainly that these component servers are Tier 0, and the controls that follow — no third-party software, application allowlisting, restricted domain accounts, firewall and IPsec on inbound administrative traffic — are its stated minimal requirements, not hardening extras.

#### Rationale
**Why This Matters:**
- A connector host brokers live privileged sessions and holds the credentials needed to rotate accounts, so compromising one is equivalent to compromising the credentials it serves — the vendor puts these servers at the same tier as domain controllers
- Installing non-Idira applications on a component server actively prevents the server from being hardened, turning a convenience install into a permanent weakening of the platform's most sensitive host
- Domain accounts used to reach connector servers become a bridge if they can also reach domain controllers, member servers, or workstations; severing that reachability is what stops a connector compromise from becoming a domain compromise

**Attack Prevented:** Tier-0 pivot from a connector host, credential-theft techniques including pass-the-hash, lateral movement via shared administrative accounts, unauthorized software execution on session-broker hosts

#### ClickOps Implementation

**Step 1: Classify and Isolate the Component Servers**
1. Record the PSM, CPM, PSM for SSH, and Credential Provider / Central Credential Provider hosts as Tier 0 assets in your asset inventory
2. Apply Microsoft's guidance for mitigating credential theft and securing Active Directory to these hosts as you would to a domain controller

**Step 2: Restrict What Runs on Them**
1. **Do not install non-Idira applications** on component servers
2. Deploy **application allowlisting** and limit execution to authorized applications
3. Apply Microsoft security updates on a regular, tracked cadence

**Step 3: Restrict Who Reaches Them**
1. Limit the set of accounts that can access component servers, and keep the number of domain credentials able to reach them as small as possible
2. Ensure that any domain accounts used to access these servers **cannot** access domain controllers, other member servers, or workstations
3. Use **network-based firewalls and IPsec** to restrict, encrypt, and authenticate inbound administrative traffic
4. Use the **PSM and the local administrator account** to access component servers, rather than interactive domain logons

**Step 4: Constrain Administrator Privilege**
1. Eliminate unnecessary administrative accounts on the platform and reduce the privileges of those that remain
2. Restrict personal accounts to business-as-usual permissions justified by role — per the vendor, platform administrators have no justification to access all credentials
3. Route administrative access to the platform itself through PSM so it is isolated and monitored

#### Validation & Testing
1. From a connector server's service account, attempt an authenticated connection to a domain controller — it should fail
2. Attempt to launch an unapproved binary on a connector host — allowlisting should block it
3. Review installed programs on each component server; anything outside the platform's own components is a finding
4. Confirm inbound administrative traffic to the connectors is filtered and authenticated at the network layer

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.6 | Logical access boundaries for sensitive infrastructure |
| **NIST 800-53** | SC-7 | Boundary protection |
| **NIST 800-53** | CM-7 | Least functionality on high-value hosts |
| **CIS Controls** | 4.8 | Uninstall or disable unnecessary services on enterprise assets |

---

## 3. API & Integration Security

### 3.1 Secure API Authentication

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5, SC-8

#### Description
Secure Idira (formerly CyberArk) API access using certificate-based authentication, API key rotation, and IP restrictions.

#### Rationale
**Why This Matters:**
- API tokens provide programmatic access to credential vault
- Stolen API tokens enable mass credential extraction
- Long-lived tokens create persistent risk

**Attack Prevented:** API token theft, mass credential extraction via automation, replay of long-lived tokens, unauthorized programmatic vault access

**Attack Scenario:** Stolen API token accessing credential vault enables extraction of all privileged passwords and SSH keys.

#### ClickOps Implementation

**Step 1: Enable Certificate-Based API Authentication**
1. Navigate to: **PVWA → Administration → Options → API Settings**
2. Configure:
   - **Certificate authentication:** Enabled
   - **Client certificate required:** Yes
   - **CA validation:** Enabled

**Step 2: Create API-Specific Application Identity**
1. Navigate to: **PVWA → Applications → Application Identity**
2. Create application with:
   - **Allowed machines:** Specific IPs/hostnames
   - **Certificate:** Required
   - **Hash:** Enable for script authentication

**Step 3: Configure API Rate Limiting**

Configure rate limiting in PVConfiguration.xml to limit concurrent requests, set request timeouts, and enable rate limiting for API endpoints.

#### Code Implementation

{% include pack-code.html vendor="cyberark" section="3.1" %}

---

### 3.2 Restrict Integration Permissions

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-6

#### Description
Limit integration accounts to minimum required permissions. Service accounts should only access specific safes needed for their function.

#### Rationale
**Why This Matters:**
- Automation accounts such as Jenkins, Ansible, Terraform, and SIEM run continuously and are rarely watched, making them attractive footholds
- Scoping each integration to only the safes it needs prevents one compromised pipeline from draining the entire vault
- UseAccounts-only permissions stop integrations from holding admin rights they can use to read or export credentials beyond their function

**Attack Prevented:** Supply-chain pipeline compromise, over-privileged service-account abuse, mass credential extraction via automation

#### ClickOps Implementation

**Step 1: Create Purpose-Specific Integration Users**

Create dedicated service accounts for each integration (Jenkins, Ansible, Terraform, SIEM) with access restricted to only the safes required for their function.

**Step 2: Configure Minimal Permissions**
For each integration:
1. Grant access to specific safes only
2. Limit to `UseAccounts` permission (no admin rights)
3. Enable audit logging for all actions

---

### 3.3 Integrate with External Secrets Managers

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-5(7)

#### Description
Securely configure integrations with HashiCorp Vault, AWS Secrets Manager, and Azure Key Vault.

#### Rationale
**Why This Matters:**
- Cross-platform secret integrations extend trust boundaries; a misconfigured connector can leak vault-managed secrets into a less-protected store
- Mutual authentication and scoped trust between the vault and external managers prevent an attacker from impersonating either side of the link
- Centralizing rotation and audit across managers avoids stale, unmanaged copies of credentials drifting outside the vault's controls

**Attack Prevented:** Secret sprawl, connector impersonation, credential leakage across trust boundaries, unrotated shadow copies

{% include pack-code.html vendor="cyberark" section="3.3" %}

---

## 4. Session Management

### 4.1 Configure PSM Session Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-12, AU-14

#### Description
Secure Privileged Session Manager (PSM) sessions with recording, monitoring, and termination controls.

#### Rationale
**Why This Matters:**
- Session recording creates tamper-evident forensic evidence of exactly what privileged users did during each connection
- Real-time monitoring and immediate termination let security stop a malicious or hijacked session before damage spreads
- Idle and absolute timeouts close abandoned privileged sessions that an attacker could otherwise resume from an unlocked workstation

**Attack Prevented:** Insider misuse, session hijacking, unattended-session takeover, untraceable privileged activity

#### ClickOps Implementation

**Step 1: Enable Session Recording**
1. Navigate to: **PVWA → Administration → Platform Configuration**
2. For each platform:
   - **Enable recording:** Yes
   - **Recording format:** Universal (searchable)
   - **Storage:** Secure location with encryption

**Step 2: Configure Session Monitoring**
1. Navigate to: **PSM → Live Sessions**
2. Enable:
   - **Real-time monitoring:** Security team access
   - **Session suspension:** On suspicious activity
   - **Session termination:** Immediate capability

**Step 3: Set Session Timeouts**

Configure session duration limits (8 hours maximum), idle timeouts (30 minutes), and warning intervals (5 minutes before timeout) in the platform configuration.

#### Code Implementation

{% include pack-code.html vendor="cyberark" section="4.1" %}

---

### 4.2 Implement Just-In-Time Access

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-2(6)

#### Description
Configure time-limited access requests with automatic credential rotation after use.

#### Rationale
**Why This Matters:**
- Standing privileged access is the most exploited PAM weakness; just-in-time access grants credentials only for the moment they are needed
- One-time passwords and auto-rotation after retrieval render any captured credential useless once the session ends
- Approval-gated, time-boxed requests ensure every privileged grant carries a justification and a hard expiry

**Attack Prevented:** Standing-privilege abuse, credential replay, persistent access, unapproved privilege use

#### ClickOps Implementation

**Step 1: Configure Time-Limited Access**
1. Navigate to: **PVWA → Policies → Master Policy**
2. Enable:
   - **Exclusive access:** Enabled
   - **One-time password:** Enabled
   - **Auto-rotate after retrieval:** Enabled

**Step 2: Configure Access Request Workflow**
1. Create request workflow:
   - User requests access
   - Approver reviews justification
   - Time-limited access granted
   - Credentials rotate after session

---

## 5. Secrets Rotation

### 5.1 Configure Automatic Password Rotation

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(1)

#### Description
Enable CPM (Central Policy Manager) to automatically rotate privileged credentials based on policy.

#### Rationale
**Why This Matters:**
- Frequent automatic rotation limits the useful lifetime of any credential an attacker manages to capture
- Strong complexity and length requirements defeat brute-force and offline cracking of rotated passwords
- Policy-driven CPM rotation removes error-prone manual processes and eliminates long-lived static passwords on privileged accounts

**Attack Prevented:** Credential replay, password cracking, long-lived static-credential abuse, stale-password persistence

#### ClickOps Implementation

**Step 1: Configure Rotation Policy**
1. Navigate to: **PVWA → Policies → Platform Configuration**
2. For each platform, configure:
   - **Password change interval:** 30 days (L1) / 7 days (L2)
   - **Verification interval:** Daily
   - **Reconcile interval:** Weekly

**Step 2: Configure Password Complexity**

Set minimum length to 20 characters, require uppercase, lowercase, numbers, and special characters. Exclude characters that may cause parsing issues in scripts.

#### Code Implementation

{% include pack-code.html vendor="cyberark" section="5.1" %}

---

### 5.2 Monitor Rotation Failures

**Profile Level:** L1 (Crawl)

#### Description
Alert on password rotation failures to prevent credential staleness.

Query for rotation failures via SIEM or direct database reporting to identify accounts where CPM status indicates failure, ordered by most recent failure date.

#### Rationale
**Why This Matters:**
- A failed rotation silently leaves a privileged password static and potentially known to former staff or a prior intruder
- Alerting on CPM failures surfaces accounts that have fallen out of the rotation lifecycle before they become long-term exposure
- Failure monitoring also reveals broken integrations or changed dependencies that could mask an attacker disabling rotation

**Attack Prevented:** Stale-credential exposure, rotation tampering, undetected lifecycle gaps, persistence via disabled rotation

{% include pack-code.html vendor="cyberark" section="5.2" %}

---

## 6. Monitoring & Detection

### 6.1 Enable Comprehensive Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure platform audit logging and forward to SIEM for security monitoring.

#### Rationale
**Why This Matters:**
- The vault is a top-priority target, so detecting abuse early depends entirely on complete, forwarded audit logs
- SIEM correlation surfaces credential-harvesting patterns, after-hours retrieval, and brute-force spikes that single events hide
- Forwarding logs off the vault preserves evidence even if an attacker gains access and tries to erase local traces

**Attack Prevented:** Undetected credential harvesting, log tampering, slow breach detection, anti-forensics

#### Detection Use Cases

**Anomaly 1: Mass Credential Retrieval** -- Detect users retrieving more than 20 passwords within a one-hour window, indicating potential credential harvesting.

**Anomaly 2: After-Hours Access** -- Flag logon and password retrieval events occurring outside business hours (before 6 AM or after 8 PM) and on weekends.

**Anomaly 3: Failed Authentication Spike** -- Identify brute force attempts by detecting more than 5 failed logon attempts from a single user or IP within a 15-minute window.

{% include pack-code.html vendor="cyberark" section="6.1" %}

---

### 6.2 Use Identity Insights to Close MFA and Configuration Gaps

**Profile Level:** L2 (Walk)
**CIS Controls:** 6.5, 8.11
**NIST 800-53:** CA-7, IA-2(1), RA-5

#### Description
Use Identity Insights, in the Detect and Respond space, to monitor multi-factor authentication coverage and triage identity risk from consolidated alerts. Each alert card carries severity, finding counts, age and type, and the date findings were last checked, along with remediation guidance and a recheck after you apply a fix — turning MFA coverage from a periodic manual audit into a tracked, re-verified state.

#### Rationale
**Why This Matters:**
- MFA enforcement drifts silently: new users, new applications, and exception policies erode coverage without generating any single obvious event, and Identity Insights measures the coverage rather than the intent
- Consolidating identity findings into severity-ranked alerts with finding counts and age gives a defensible triage order instead of an undifferentiated list of misconfigurations
- The recheck step after remediation is what distinguishes a closed finding from an assumed one — without it, a fix that failed to apply looks identical to a fix that worked

**Attack Prevented:** Exploitation of un-enrolled or MFA-exempt identities, slow remediation of known identity misconfigurations, silent drift in authentication coverage, unverified remediation

#### ClickOps Implementation

**Step 1: Open Identity Insights**
1. In the Idira documentation's space structure, Identity Insights lives under **Detect and Respond**; open **Identity Insights** from that area of the console
2. Review the alert list — each entry summarizes severity, finding counts, age and type, and when findings were last checked

**Step 2: Review MFA Coverage**
1. Work the MFA coverage findings first — they measure whether the enforcement configured in [1.1](#11-enforce-multi-factor-authentication-for-all-access) is actually reaching every identity
2. Treat any administrative identity appearing in an MFA coverage finding as an L1 exception requiring same-day remediation

**Step 3: Remediate and Recheck**
1. Open an alert card to see its remediation guidance, and apply the change it describes
2. Run the **recheck** so the finding's state reflects the applied fix rather than your assumption about it
3. Track alert age as its own metric — an old finding that is still open is a standing exposure, not a backlog item

#### Validation & Testing
1. Deliberately create a low-risk test identity outside MFA enforcement and confirm it surfaces as an MFA coverage finding
2. Remediate that finding, run the recheck, and confirm the alert closes
3. Confirm no open alert of high severity exceeds your organization's remediation SLA

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC7.1 | Detection of configuration changes and vulnerabilities |
| **NIST 800-53** | CA-7 | Continuous monitoring |
| **NIST 800-53** | IA-2(1) | MFA for privileged accounts (coverage assurance) |
| **NIST 800-53** | RA-5 | Vulnerability monitoring and remediation tracking |

---

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Idira Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA enforcement | 1.1 |
| CC6.2 | Safe permissions | 1.2 |
| CC6.6 | Tier 0 connector isolation | 2.3 |
| CC7.1 | Identity Insights monitoring | 6.2 |
| CC7.2 | Audit logging | 6.1 |

### NIST 800-53 Mapping

| Control | Idira Control | Guide Section |
|---------|------------------|---------------|
| IA-2(6) | MFA for privileged | 1.1 |
| AC-6 | Least privilege safes | 1.2 |
| SC-7 | Connector boundary protection | 2.3 |
| IA-5(1) | Password rotation | 5.1 |
| AU-14 | Session recording | 4.1 |
| CA-7 | Continuous identity monitoring | 6.2 |

---

## Appendix A: References

**Official Idira (formerly CyberArk) Documentation:**
- [Idira Documentation Portal (All Products)](https://docs.cyberark.com/portal/latest/en/docs.htm)
- [Privilege Cloud Security Fundamentals](https://docs.cyberark.com/privilege-cloud-standard/latest/en/content/security/security%20fundamentals-introduction.htm)
- [Privilege Cloud Connector Hardening](https://docs.cyberark.com/privilege-cloud-standard/latest/en/content/privilege%20cloud/privcloud-hardening-overview.htm)
- [Technical Best Practices](https://docs.cyberark.com/privilege-cloud-standard/latest/en/content/getstarted/best-pactices.htm)
- [Setup Space — Enforce Strong Authentication](https://docs.cyberark.com/setup/latest/en/content/setup-space/authentication/enforce-strong-authentication.htm)
- [Manage Identity Insights](https://docs.cyberark.com/detect-and-respond/latest/en/Content/identity/security-insights/manage-security-insights.htm)
- [Where Identity Documentation Moved (Spaces Migration)](https://docs.cyberark.com/find-identity-docs/latest/en/content/getstarted/identity-new-doc-location.htm)

**Product Naming:**
- [Idira — Palo Alto Networks](https://www.paloaltonetworks.com/idira) — where `cyberark.com` marketing URLs now resolve

**Security Research:**
- [Unit 42](https://unit42.paloaltonetworks.com/) — the former CyberArk Labs advisory URL (`labs.cyberark.com`) now redirects here

> **Removed in this revision (link rot / source standard).** Six previously cited links no longer resolve to usable hardening content and have been dropped rather than silently redirected: `cyberark.com/trust/`, `cyberark.com/product-security/`, `cyberark.com/trust/compliance/`, and `cyberark.com/rest-api/` all now land on the Idira marketing page (and were Trust Center / marketing pages excluded by this project's source standard regardless); `trust.cyberark.com` is a SafeBase trust portal, not configuration documentation; `api-docs.cyberark.com` redirect-loops into a SwaggerHub login; and the CVE Details vendor listing returns HTTP 403 to any automated check. Two vendor white-paper links and a vendor blog post were removed for the same reason — two now resolve to the Idira marketing page and none are configuration documentation. For compliance evidence, use your own tenant's audit reports and the framework mappings above rather than a vendor assurance page.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Rename to Idira (formerly CyberArk) throughout per the current Palo Alto Networks documentation portal — URL slug deliberately unchanged to preserve inbound links; reframe 2.1 connector hardening as automated-at-deployment (GPO in-domain / INF out-of-domain via the PSM_CPM file) with the vendor's required-TLS channels; add 2.3 Tier 0 connector isolation and 6.2 Identity Insights; update 1.1 Step 3 for the Identity docs "spaces" migration (previous doc sets frozen as of April 2026); add missing Attack Prevented to 3.1; remove six rotted or bright-line Appendix A links | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial CyberArk hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
