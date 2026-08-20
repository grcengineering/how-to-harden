---
layout: guide
title: "BeyondTrust Hardening Guide"
vendor: "BeyondTrust"
slug: "beyondtrust"
tier: "1"
category: "Identity"
description: "Remote access security for PRA, session monitoring, and credential injection"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

BeyondTrust is a Privileged Access Management (PAM) platform serving **20,000+ customers including 75% of Fortune 500**. The **December 2024 breach via a Chinese state-linked APT** compromised the **U.S. Treasury Department** through a stolen Remote Support API key. Zero-day vulnerabilities (CVE-2024-12356, CVSS 9.8; CVE-2024-12686, CVSS 6.6) exposed how PAM solutions become supply chain vectors when API keys are compromised. 17 Remote Support SaaS customers were affected; attackers accessed Treasury workstations and unclassified documents.

### The Pathfinder Platform Changes the Blast Radius

BeyondTrust's SaaS products now sit behind the **Pathfinder platform**, which BeyondTrust describes as "a single pane of glass view into all of your BeyondTrust SaaS products," where "all applications share the same user login for easy single sign-on" and a shared navigation menu supports cross-product navigation.

This is a hardening-relevant fact, not a marketing one: a compromised Pathfinder login is no longer scoped to one product. Where an organization runs several BeyondTrust SaaS products, the identity controls in [1.1](#11-enforce-multi-factor-authentication-for-all-access) and [1.2](#12-implement-role-based-access-control) should be assessed against the **platform** login, and role separation should be verified to hold across products rather than only within one. Source: [Welcome to the Pathfinder platform](https://docs.beyondtrust.com/bt-docs/docs/welcome-to-the-pathfinder-platform)

### Intended Audience
- Security engineers managing PAM infrastructure
- IT administrators configuring BeyondTrust
- GRC professionals assessing privileged access compliance
- Third-party risk managers evaluating remote access solutions

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for government/regulated industries

### Scope
This guide covers BeyondTrust-specific security configurations with emphasis on API key security, remote access hardening, and lessons learned from the December 2024 Treasury breach.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Security](#2-api-security)
3. [Network Access Controls](#3-network-access-controls)
4. [Session Security](#4-session-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Incident Response](#6-incident-response)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Multi-Factor Authentication for All Access

**Profile Level:** L1 (Crawl) — CRITICAL

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 6.5 |
| NIST 800-53 | IA-2(1), IA-2(6) |

#### Description
Require MFA for all BeyondTrust console access, remote support sessions, and API authentication where possible. Where products are consumed through the shared **Pathfinder** login, enforce MFA at that platform login — it fronts every BeyondTrust SaaS product the organization uses.

#### Rationale
**Why This Matters:**
- BeyondTrust provides remote access to sensitive systems
- Compromised console = access to all managed endpoints
- The shared Pathfinder login means one compromised platform credential can reach every BeyondTrust SaaS product in use
- December 2024 breach bypassed authentication via stolen API key

**Attack Prevented:** Credential theft, session hijacking

**Real-World Incidents:**
- **December 2024 BeyondTrust Breach:** A Chinese state-linked APT — reported attribution **Silk Typhoon (also tracked as APT27)** — used a stolen Remote Support API key to access U.S. Treasury Department workstations and unclassified documents

#### Prerequisites
- BeyondTrust console admin access
- MFA provider integration (RADIUS, SAML)
- User inventory for enrollment

#### ClickOps Implementation

**Step 1: Configure SAML/OIDC Authentication**
1. Navigate to: **Management → Security Providers**
2. Click **Add Security Provider**
3. Configure:
   - **Type:** SAML 2.0 or OIDC
   - **IdP Entity ID:** From your identity provider
   - **SSO URL:** IdP login URL
   - **Certificate:** IdP signing certificate
4. Enable: **Require MFA at IdP**

**Step 2: Configure Local MFA (Backup)**
1. Navigate to: **Management → Security → Authentication**
2. Enable: **Two-Factor Authentication**
3. Configure:
   - **Provider:** TOTP or RADIUS
   - **Enforcement:** All users
   - **Grace period:** None (L2/L3)

**Step 3: Require MFA for Remote Sessions**
1. Navigate to: **Configuration → Options → Security**
2. Enable: **Require two-factor for representatives**
3. Enable: **Require two-factor for customers** (if applicable)

#### Code Implementation

{% include pack-code.html vendor="beyondtrust" section="1.1" %}

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(1), IA-2(6) | MFA for privileged access |
| **PCI DSS** | 8.3.1 | MFA for administrative access |
| **CISA BOD 22-01** | MFA | Required for internet-facing systems |

---

### 1.2 Implement Role-Based Access Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3, AC-6 |

#### Description
Configure granular roles separating administrative functions. Avoid using built-in Administrator account for daily operations.

#### Rationale
**Why This Matters:**
- Separating help-desk, support, security-admin, and API-admin functions enforces least privilege so no single account can both run sessions and change security settings
- The built-in Administrator account is a known, shared target — named accounts create an audit trail and remove a high-value standing credential
- Over-privileged operators expand the blast radius of any single compromised representative login across every managed endpoint

**Attack Prevented:** Privilege escalation, insider abuse, lateral movement, shared-account compromise

#### ClickOps Implementation

**Step 1: Create Functional Roles**
1. Navigate to: **Management → User Accounts → Roles**
2. Create roles:

**Help Desk Representative:**
- Start remote sessions
- View session history (own only)
- NO: Configure systems, access API

**Senior Support:**
- All Help Desk permissions
- View all session recordings
- Access knowledge base

**Security Administrator:**
- Manage users and roles
- Configure security settings
- Access audit logs
- NO: Start remote sessions

**API Administrator:**
- Manage API credentials
- View API usage logs
- NO: Start sessions, access recordings

**Step 2: Disable/Rename Default Admin**
1. Navigate to: **Management → User Accounts**
2. Rename or disable built-in Administrator account
3. Create named admin accounts with audit trail

---

### 1.3 Configure IP-Based Access Restrictions

**Profile Level:** L1 (Crawl) — CRITICAL (Post-Breach Lesson)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3(7), SC-7 |

#### Description
Restrict console and API access to known IP ranges. This control would have limited the December 2024 breach impact.

#### Rationale
**Why This Matters:**
- December 2024: Attackers used stolen API key from unknown IPs
- IP restrictions prevent credential use from attacker infrastructure
- Defense-in-depth for token theft scenarios

**Attack Prevented:** Stolen-credential reuse from attacker infrastructure, unauthorized API access from unknown networks, console access from untrusted locations

#### ClickOps Implementation

**Step 1: Configure Console IP Restrictions**
1. Navigate to: **Management → Security → Network Restrictions**
2. Add allowed IP ranges:
   - Corporate network CIDRs
   - VPN egress IPs
   - Trusted partner IPs
3. Set default action: **Deny**

**Step 2: Configure API IP Restrictions (Critical)**
1. Navigate to: **Management → API Configuration → Access Control**
2. For each API credential:
   - Assign specific allowed IPs
   - Enable: **Reject requests from unlisted IPs**
3. Block: All public internet (unless required)

{% include pack-code.html vendor="beyondtrust" section="1.3" %}

---

## 2. API Security

### 2.1 API Key Management and Rotation

**Profile Level:** L1 (Crawl) — CRITICAL

| Framework | Control |
|-----------|---------|
| NIST 800-53 | IA-5, SC-12 |

#### Description
Implement strict API key management including regular rotation, IP binding, and monitoring. The December 2024 breach was enabled by a single unrotated API key.

#### Rationale
**Why This Matters:**
- Stolen API key = full platform access
- December 2024 breach used single compromised key
- Long-lived keys create extended exposure window

**Attack Prevented:** Long-lived API key abuse, stolen-integration-credential access to all managed endpoints, bulk data exfiltration via a valid key (the December 2024 pattern)

#### ClickOps Implementation

**Step 1: Audit Existing API Keys**
1. Navigate to: **Management → API Configuration → API Keys**
2. Export list of all active API keys
3. Document for each key:
   - Creation date
   - Last used date
   - Purpose/integration
   - IP restrictions (if any)
   - Assigned permissions

**Step 2: Implement Key Rotation Schedule**

| Key Type | Rotation Frequency | Maximum Age |
|----------|-------------------|-------------|
| Production integration | Quarterly | 90 days |
| Development/Test | Monthly | 30 days |
| Emergency/Break-glass | After each use | Single use |

**Step 3: Rotate All Existing Keys**
1. For each API key:
   - Generate new key
   - Update integration configuration
   - Verify integration works
   - Revoke old key
   - Document rotation

**Step 4: Enable Key Expiration**
1. Navigate to: **API Configuration → Settings**
2. Enable: **Automatic key expiration**
3. Set maximum age: 90 days
4. Enable: **Expiration warning notifications**

#### Code Implementation

{% include pack-code.html vendor="beyondtrust" section="2.1" %}

---

### 2.2 Implement API Rate Limiting

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SC-5 |

#### Description
Configure rate limiting for API endpoints to detect and prevent abuse.

#### Rationale
**Why This Matters:**
- A stolen API key enables high-volume automated enumeration and bulk data exfiltration — rate limits cap how much an attacker can pull before detection
- Lockouts on excessive requests blunt brute-force and credential-spraying attempts against API authentication
- Rate-limit thresholds double as a tripwire: a sudden spike from a legitimate integration's key signals possible compromise

**Attack Prevented:** API abuse, bulk data exfiltration, brute-force enumeration, denial of service

#### ClickOps Implementation

1. Navigate to: **Management → API Configuration → Rate Limiting**
2. Configure:
   - **Requests per minute:** 100 (adjust based on usage)
   - **Burst limit:** 200
   - **Lockout duration:** 5 minutes
3. Enable: **Alert on rate limit exceeded**

---

### 2.3 Monitor API Usage Anomalies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AU-6, SI-4 |

#### Description
Implement monitoring for unusual API activity patterns that may indicate compromise.

#### Rationale
**Why This Matters:**
- The December 2024 breach used a valid stolen key, so behavioral anomalies — new source IPs, off-hours calls, unusual endpoint access — were the only available signal of abuse
- Detecting anomalous API patterns shrinks attacker dwell time between key theft and discovery
- Baselining normal integration behavior turns subtle deviations into actionable alerts before bulk data loss occurs

**Attack Prevented:** Stolen-credential abuse, undetected API compromise, data exfiltration, extended dwell time

#### Detection Use Cases

Baseline each integration's normal behavior first, then alert on deviation. The December 2024 pattern — a valid key used from new infrastructure — is only visible as a behavioral change, so these use cases are the detection surface:

| Use case | Signal | Why it matters |
|----------|--------|----------------|
| **New source IP for an existing key** | API call from an IP never previously seen for that credential | The primary indicator available when the key itself is valid |
| **Off-hours API activity** | Calls outside the integration's normal operating window | Automated integrations have predictable schedules; humans using a stolen key do not |
| **New endpoint access for a key** | A credential begins calling API endpoints it has never used | Indicates exploration rather than the integration's fixed function |
| **Request-volume spike** | Sustained call rate materially above the key's baseline | Bulk enumeration or exfiltration in progress |
| **Credential lifecycle events** | API key created, modified, or permissions expanded | Attacker persistence — a foothold being made durable |
| **Repeated authorization failures** | A key generating 401/403 responses at volume | Probing for permissions the credential does not hold |

Route these to the SIEM (see [5.2](#52-forward-logs-to-siem)) and alert per the thresholds in [5.1](#51-configure-security-alerting).

---

## 3. Network Access Controls

### 3.1 Segment Remote Access Infrastructure

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SC-7 |

#### Description
Deploy BeyondTrust in a segmented network zone with strict ingress/egress controls.

#### Rationale
**Why This Matters:**
- BeyondTrust brokers privileged access to critical systems, making it a high-value pivot point — segmentation contains an appliance compromise to a controlled zone
- Strict ingress/egress rules prevent a breached appliance from reaching arbitrary internal hosts or attacker-controlled infrastructure
- Limiting inbound traffic to a WAF and outbound traffic to defined targets removes the open network paths attackers rely on for lateral movement

**Attack Prevented:** Lateral movement, network pivoting, command-and-control egress, unrestricted east-west traffic

#### Implementation

**Network Architecture:**

Place the appliance in a dedicated DMZ segment that neither the general corporate network nor the target estate can reach directly:

| Zone | Contents | Reaches |
|------|----------|---------|
| **Internet edge** | WAF / reverse proxy terminating inbound HTTPS | The BeyondTrust segment only, on 443 |
| **BeyondTrust segment (DMZ)** | Appliance / session broker | Defined target hosts on defined ports; identity provider; SIEM collector |
| **Management segment** | Administrative console access | The BeyondTrust segment, from named admin sources only |
| **Target estate** | Systems reached through brokered sessions | Nothing back toward the BeyondTrust segment (no return paths) |

The BeyondTrust segment must have **no general east-west reachability** into the corporate network and no unrestricted outbound internet egress — those are the two paths that turn an appliance compromise into estate-wide movement.

**Firewall Rules:**
- Inbound: HTTPS (443) from WAF only
- Outbound: Target systems on specific ports
- Block all other traffic

---

### 3.2 Configure Jump Server Integration

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-17 |

#### Description
Configure BeyondTrust to work with existing jump server architecture for defense in depth.

#### Rationale
**Why This Matters:**
- Routing privileged access through a jump server adds an independent enforcement and logging layer, so a BeyondTrust compromise alone does not grant direct target access
- Defense in depth forces an attacker to defeat multiple controls rather than a single platform to reach sensitive systems
- A consolidated jump host concentrates session logging and monitoring, improving forensic visibility into who reached what

**Attack Prevented:** Single-point-of-failure compromise, direct target access, unmonitored privileged connections

---

## 4. Session Security

### 4.1 Enable Comprehensive Session Recording

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AU-14 |

#### Description
Record all privileged sessions for forensic analysis and compliance.

#### Rationale
**Why This Matters:**
- Full session recordings provide the forensic record needed to reconstruct exactly what an attacker did during an incident like the Treasury breach
- Tamper-evident, encrypted recordings deter insider abuse and preserve evidentiary integrity for investigations and audits
- Without comprehensive recording, privileged actions on managed endpoints are invisible after the fact, crippling incident response and compliance reporting

**Attack Prevented:** Insider abuse, undetected malicious activity, evidence tampering, post-incident blind spots

#### ClickOps Implementation

**Step 1: Configure Recording Settings**
1. Navigate to: **Configuration → Recording**
2. Enable:
   - **Record all sessions:** Yes
   - **Record audio:** Per policy
   - **Record keystrokes:** Yes (for forensics)
   - **Storage encryption:** AES-256

**Step 2: Configure Retention**
1. Set retention period: Minimum 1 year
2. Configure secure storage location
3. Enable: Tamper-evident logging

---

### 4.2 Implement Session Approval Workflows

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-2(6) |

#### Description
Require approval for access to sensitive systems.

#### Rationale
**Why This Matters:**
- Just-in-time approval ensures access to sensitive systems is granted only with explicit, justified authorization rather than standing privilege
- Time-boxed sessions with required justification create accountability and shrink the window in which a compromised account can reach critical assets
- Security-team approval introduces a human checkpoint that can stop anomalous or unauthorized access requests before they execute

**Attack Prevented:** Standing-privilege abuse, unauthorized access, insider misuse, privilege creep

#### ClickOps Implementation

1. Navigate to: **Configuration → Jump Policies**
2. Create policy for sensitive systems:
   - **Approval required:** Yes
   - **Approvers:** Security team
   - **Maximum duration:** 4 hours
   - **Justification required:** Yes

---

## 5. Monitoring & Detection

### 5.1 Configure Security Alerting

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SI-4 |

#### Description
Configure alerts for security-relevant events based on lessons from December 2024 breach.

#### Rationale
**Why This Matters:**
- The Treasury breach persisted long enough to access data because security-relevant events were not alerted in real time
- Alerts on API access from new IPs, key creation, and security-setting changes surface the exact indicators the December 2024 attack would have triggered
- Real-time notification to security teams and SIEM compresses detection-to-response time, limiting attacker dwell and data loss

**Attack Prevented:** Delayed breach detection, stolen-key abuse, unauthorized configuration changes, extended dwell time

#### Critical Alerts

| Alert | Threshold | Priority |
|-------|-----------|----------|
| Failed login attempts | >5 in 5 minutes | High |
| API access from new IP | Any | High |
| After-hours admin access | Any | Medium |
| Bulk session access | >10 in 10 minutes | High |
| API key created/modified | Any | High |
| Security setting changed | Any | Critical |

#### ClickOps Implementation

1. Navigate to: **Management → Alerts → Alert Rules**
2. Create rules for each scenario
3. Configure notification channels:
   - Email to security team
   - SIEM integration
   - PagerDuty for critical

---

### 5.2 Forward Logs to SIEM

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AU-6 |

#### Description
Export all audit logs to SIEM for correlation and long-term retention.

#### Rationale
**Why This Matters:**
- Centralizing BeyondTrust logs in a SIEM enables cross-source correlation, linking PAM activity to identity, network, and endpoint signals an attacker would otherwise scatter across systems
- Long-term off-platform retention preserves evidence even if an attacker tampers with or deletes local logs on a compromised appliance
- SIEM-based detection rules turn raw audit events into automated alerts on the access patterns seen in the Treasury breach

**Attack Prevented:** Log tampering, anti-forensics, undetected multi-stage attacks, evidence destruction

---

## 6. Incident Response

### 6.1 December 2024 Breach Response Lessons

**Based on the Treasury Department breach, implement these immediate actions:**

#### Immediate Actions (0-24 hours)
1. Rotate ALL API keys immediately
2. Review all API access logs for past 90 days
3. Identify any access from unusual IPs
4. Enable IP restrictions on all API keys
5. Apply CVE-2024-12356 and CVE-2024-12686 patches

#### Short-term Actions (1-7 days)
1. Audit all sessions for unauthorized access
2. Review all endpoint access during breach window
3. Implement API key rotation automation
4. Enable enhanced logging and alerting
5. Conduct tabletop exercise

#### Long-term Actions (30+ days)
1. Implement network segmentation
2. Deploy API gateway with rate limiting
3. Establish quarterly API key rotation
4. Conduct penetration testing
5. Review third-party integrations

---

### 6.2 Vulnerability Management

**Profile Level:** L1 (Crawl)

#### Description
Establish a process to track, prioritize, and rapidly patch BeyondTrust security vulnerabilities, applying critical fixes such as CVE-2024-12356 and CVE-2024-12686 without delay.

#### Rationale
**Why This Matters:**
- The December 2024 Treasury breach exploited known BeyondTrust CVEs — unpatched internet-facing PAM appliances are directly targeted by nation-state and criminal actors
- Command-injection and authentication-bypass flaws in remote-access software grant attackers a foothold into every system the platform brokers
- A defined patch SLA closes the exposure window between disclosure and exploitation, which for actively exploited CVEs is measured in days

**Attack Prevented:** Exploitation of known CVEs, command injection, authentication bypass, supply-chain compromise

#### Recent Critical CVEs

CVSS values below are the **CNA-assigned** scores from the CVE records. Where NVD has published a differing score, the CNA value is used — the vendor CNA is the authoritative assigner for its own products.

| CVE | CVSS | Published | Affected | Description | Remediation |
|-----|------|-----------|----------|-------------|-------------|
| CVE-2026-40139 | 9.2 (v4.0) | 2026-07-06 | Remote Support / PRA ≤ 25.3.2 | Pre-authentication authentication bypass | Upgrade beyond 25.3.2 immediately |
| CVE-2026-40138 | 9.2 (v4.0) | 2026-07-06 | Remote Support / PRA ≤ 25.3.2 | Critical flaw in the same disclosure cluster | Upgrade beyond 25.3.2 immediately |
| CVE-2026-40141 | 8.5 (v4.0) | 2026-07-06 | Remote Support / PRA ≤ 25.3.2 | High-severity flaw in the same cluster (NVD's score differs from the CNA's; the CNA value is shown) | Upgrade beyond 25.3.2 immediately |
| CVE-2026-1731 | 9.9 | 2026-02-06 | Remote Support ≤ 25.3.1; PRA ≤ 24.3.4 | Pre-authentication remote code execution | Patch immediately |
| CVE-2025-5309 | 8.6 | 2025-06-16 | Remote Support / PRA | Server-side template injection in the chat feature leading to remote code execution | Patch immediately |
| CVE-2024-12356 | 9.8 | 2024-12 | Remote Support / PRA | Command injection in RS — exploited in the Treasury breach | Patch immediately |
| CVE-2024-12686 | 6.6 | 2025-01 | Remote Support / PRA | Authentication bypass — also exploited | Patch immediately |

**Fixed version for the July 2026 cluster:** releases **later than 25.3.2** address CVE-2026-40139, CVE-2026-40138, and CVE-2026-40141. If you are on 25.3.2 or earlier, treat this as an emergency-patch condition — all three are pre-authentication-reachable on an internet-facing appliance.

CVE records verified against the CVE Program's authoritative API (`cveawg.mitre.org/api/cve/{ID}`).

#### Patch SLAs

BeyondTrust publishes the following remediation timelines for its U-Series appliances. Use them as the floor for your own SLA, not the ceiling:

| Vulnerability class | Vendor-stated SLA |
|---------------------|-------------------|
| Critical OS/database vulnerability, unmitigated | 7 days from patch release |
| Critical OS/database vulnerability, mitigated by appliance hardening | 90 days from patch release |
| Critical BeyondTrust product vulnerability | 30 days from identification |

**Appliance hardening baseline (Tier 1 claim, Tier 2 framing).** BeyondTrust states the U-Series appliance is hardened to the **CIS Benchmark for Windows Server 2022, Level 2 Member Server** profile, and reports a **99% DISA STIG v1.2.3** assessment score (218 findings passed, four Category II findings open, covering deny-all policies, host-based intrusion detection, and file-integrity-monitoring baselines). These are the vendor's own compliance assertions about its appliance image, not an independent CIS or DISA certification — treat them as useful evidence for a control narrative and as a reason to request the current assessment artifact during vendor review, rather than as a substitute for your own verification. Source: [U-Series Appliance best practices](https://docs.beyondtrust.com/bips/docs/u-series-best-practices)

{% include pack-code.html vendor="beyondtrust" section="6.2" %}

---

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | BeyondTrust Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA enforcement | 1.1 |
| CC6.2 | RBAC | 1.2 |
| CC6.6 | IP restrictions | 1.3 |
| CC7.2 | Session recording | 4.1 |

### NIST 800-53 Mapping

| Control | BeyondTrust Control | Guide Section |
|---------|------------------|---------------|
| IA-2(6) | MFA for privileged | 1.1 |
| IA-5 | API key management | 2.1 |
| AC-3(7) | IP-based access | 1.3 |
| AU-14 | Session recording | 4.1 |

### CISA Guidance (Post-Treasury Breach)

Following the December 2024 incident:
- Immediately apply all security patches
- Rotate API credentials
- Implement IP allowlisting for API access
- Enable comprehensive audit logging
- Review all third-party integrations

---

## Appendix A: References

> **Doc-host migration.** BeyondTrust's documentation moved from `www.beyondtrust.com/docs/*` to `docs.beyondtrust.com`. The old paths are cited nowhere below; `www.beyondtrust.com` additionally returns HTTP 403 to automated fetchers, so `docs.beyondtrust.com` is the verifiable surface.

**Official BeyondTrust Documentation:**
- [BeyondTrust Documentation](https://docs.beyondtrust.com/)
- [U-Series Appliance Best Practices](https://docs.beyondtrust.com/bips/docs/u-series-best-practices) — the appliance hardening reference: patch SLAs, OS hardening, encryption, and the CIS/STIG baseline claims
- [Welcome to the Pathfinder Platform](https://docs.beyondtrust.com/bt-docs/docs/welcome-to-the-pathfinder-platform) — shared SSO and cross-product navigation across BeyondTrust SaaS products

**API & Developer Tools:**
- [Privileged Remote Access API Guide](https://docs.beyondtrust.com/pra/reference/api-guide)
- [Remote Support API Guide](https://docs.beyondtrust.com/rs/reference/api-guide)
- [Password Safe / BeyondInsight Public API](https://docs.beyondtrust.com/bips/reference/)

**Vulnerability References:**
- CVE records verified via the CVE Program API (`https://cveawg.mitre.org/api/cve/{CVE-ID}`) — see [6.2](#62-vulnerability-management)

**Compliance Frameworks:**

BeyondTrust publishes SOC 2 Type II, ISO/IEC 27001:2022, and ISO/IEC 27701 attestations. Those certifications are asserted on the vendor's trust-center and press pages, which are not hardening documentation and are therefore not cited here — request the current attestation reports directly from BeyondTrust under NDA as part of vendor review, and use the [U-Series Appliance Best Practices](https://docs.beyondtrust.com/bips/docs/u-series-best-practices) page for the configuration-level baseline claims that are actually assessable.

**Security Incidents:**
- **December 2024 — U.S. Treasury Department Breach (CVE-2024-12356, CVSS 9.8):** A Chinese state-linked APT — reported attribution **Silk Typhoon (also tracked as APT27)** — compromised a BeyondTrust Remote Support SaaS API key, gaining access to Treasury Department workstations and unclassified documents. BeyondTrust detected the compromise on December 5, immediately revoked the API key, and notified affected customers. 17 Remote Support SaaS customers were impacted. CVE-2024-12686 (CVSS 6.6, authentication bypass) was also exploited. ([The Hacker News Report](https://thehackernews.com/2024/12/chinese-apt-exploits-beyondtrust-api.html)) ([CyberArk Analysis](https://www.cyberark.com/resources/blog/the-us-treasury-attack-key-events-and-security-implications))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass. Added five verified CVEs to 6.2 — CVE-2026-40139 (pre-auth authentication bypass, ≤25.3.2, CVSS 9.2 v4.0, 2026-07-06), CVE-2026-40138 (9.2), CVE-2026-40141 (8.5; CNA score used where NVD differs), CVE-2026-1731 (pre-auth RCE, RS ≤25.3.1 / PRA ≤24.3.4, 9.9, 2026-02-06), CVE-2025-5309 (chat SSTI to RCE, 8.6, 2025-06-16) — with the fixed-version line for the July 2026 cluster, all verified against the CVE Program API. Added the vendor patch SLAs (7 days unmitigated critical OS, 90 days if mitigated by hardening, 30 days for BeyondTrust vulnerabilities) and the U-Series CIS Windows Server 2022 L2 / DISA STIG v1.2.3 baseline claims as a labeled vendor-assertion note rather than an independent certification. Corrected the internal APT-attribution contradiction (Overview said "Salt Typhoon suspected" while Appendix A said Silk Typhoon/APT27) — both now read as reported attribution to Silk Typhoon (APT27). Added the Pathfinder platform to the Overview and 1.1: shared SSO and cross-product navigation across BeyondTrust SaaS products changes console-compromise blast radius. Removed the three beyondtrust.com trust-center links and the press-release ISO citation from Appendix A per the repo source standard, and repointed the rotted `www.beyondtrust.com/docs/*` links to `docs.beyondtrust.com` (documentation root, U-Series best practices, Remote Support API guide, Password Safe/BeyondInsight public API) — each fetch-verified. Populated the previously empty "Detection Use Cases" block in 2.3 and the bare "Network Architecture:" label in 3.1. Parser repairs: added **Attack Prevented:** to 1.3 and renamed 2.1's **Attack Scenario:** to **Attack Prevented:** so both render in the cheat sheet. Normalized the inline **CIS Controls:** / **NIST 800-53:** lines across all controls to the Framework/Control table style. **Open question:** whether any of these BeyondTrust CVEs appear in the CISA KEV catalog is unresolved — the KEV surface was not reachable this pass and no claim is made either way; this needs a real-browser check on a later pass. Tier 3/4 not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | ai-drafted | Initial guide with Treasury breach lessons | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
