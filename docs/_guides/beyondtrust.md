---
layout: guide
title: "BeyondTrust Hardening Guide"
vendor: "BeyondTrust"
slug: "beyondtrust"
tier: "1"
category: "Identity"
description: "Remote access security for PRA, session monitoring, and credential injection"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

BeyondTrust is a Privileged Access Management (PAM) platform serving **20,000+ customers including 75% of Fortune 500**. The **December 2024 breach via Chinese APT** compromised the **U.S. Treasury Department** through a stolen Remote Support API key. Zero-day vulnerabilities (CVE-2024-12356, CVSS 9.8; CVE-2024-12686, CVSS 6.6) exposed how PAM solutions become supply chain vectors when API keys are compromised. 17 Remote Support SaaS customers were affected; attackers accessed Treasury workstations and unclassified documents.

### Intended Audience
- Security engineers managing PAM infrastructure
- IT administrators configuring BeyondTrust
- GRC professionals assessing privileged access compliance
- Third-party risk managers evaluating remote access solutions

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for government/regulated industries

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

**Profile Level:** L1 (Baseline) - CRITICAL
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1), IA-2(6)

#### Description
Require MFA for all BeyondTrust console access, remote support sessions, and API authentication where possible.

#### Rationale
**Why This Matters:**
- BeyondTrust provides remote access to sensitive systems
- Compromised console = access to all managed endpoints
- December 2024 breach bypassed authentication via stolen API key

**Attack Prevented:** Credential theft, session hijacking

**Real-World Incidents:**
- **December 2024 BeyondTrust Breach:** Chinese APT (Salt Typhoon suspected) used stolen Remote Support API key to access U.S. Treasury Department workstations and unclassified documents

#### Prerequisites
- [ ] BeyondTrust console admin access
- [ ] MFA provider integration (RADIUS, SAML)
- [ ] User inventory for enrollment

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

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure granular roles separating administrative functions. Avoid using built-in Administrator account for daily operations.

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

**Profile Level:** L1 (Baseline) - CRITICAL (Post-Breach Lesson)
**NIST 800-53:** AC-3(7), SC-7

#### Description
Restrict console and API access to known IP ranges. This control would have limited the December 2024 breach impact.

#### Rationale
**Why This Matters:**
- December 2024: Attackers used stolen API key from unknown IPs
- IP restrictions prevent credential use from attacker infrastructure
- Defense-in-depth for token theft scenarios

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

**Profile Level:** L1 (Baseline) - CRITICAL
**NIST 800-53:** IA-5, SC-12

#### Description
Implement strict API key management including regular rotation, IP binding, and monitoring. The December 2024 breach was enabled by a single unrotated API key.

#### Rationale
**Why This Matters:**
- Stolen API key = full platform access
- December 2024 breach used single compromised key
- Long-lived keys create extended exposure window

**Attack Scenario:** Attacker obtains API key from compromised integration, accesses all managed endpoints, exfiltrates data from Treasury workstations.

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

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-5

#### Description
Configure rate limiting for API endpoints to detect and prevent abuse.

#### ClickOps Implementation

1. Navigate to: **Management → API Configuration → Rate Limiting**
2. Configure:
   - **Requests per minute:** 100 (adjust based on usage)
   - **Burst limit:** 200
   - **Lockout duration:** 5 minutes
3. Enable: **Alert on rate limit exceeded**

---

### 2.3 Monitor API Usage Anomalies

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-6, SI-4

#### Description
Implement monitoring for unusual API activity patterns that may indicate compromise.

#### Detection Use Cases

{% include pack-code.html vendor="beyondtrust" section="2.3" %}

---

## 3. Network Access Controls

### 3.1 Segment Remote Access Infrastructure

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-7

#### Description
Deploy BeyondTrust in a segmented network zone with strict ingress/egress controls.

#### Implementation

**Network Architecture:**

{% include pack-code.html vendor="beyondtrust" section="3.1" %}

**Firewall Rules:**
- Inbound: HTTPS (443) from WAF only
- Outbound: Target systems on specific ports
- Block all other traffic

---

### 3.2 Configure Jump Server Integration

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-17

#### Description
Configure BeyondTrust to work with existing jump server architecture for defense in depth.

---

## 4. Session Security

### 4.1 Enable Comprehensive Session Recording

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-14

#### Description
Record all privileged sessions for forensic analysis and compliance.

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

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-2(6)

#### Description
Require approval for access to sensitive systems.

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

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SI-4

#### Description
Configure alerts for security-relevant events based on lessons from December 2024 breach.

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

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-6

#### Description
Export all audit logs to SIEM for correlation and long-term retention.

---

## 6. Incident Response

### 6.1 December 2024 Breach Response Lessons

**Based on the Treasury Department breach, implement these immediate actions:**

#### Immediate Actions (0-24 hours)
1. [ ] Rotate ALL API keys immediately
2. [ ] Review all API access logs for past 90 days
3. [ ] Identify any access from unusual IPs
4. [ ] Enable IP restrictions on all API keys
5. [ ] Apply CVE-2024-12356 and CVE-2024-12686 patches

#### Short-term Actions (1-7 days)
1. [ ] Audit all sessions for unauthorized access
2. [ ] Review all endpoint access during breach window
3. [ ] Implement API key rotation automation
4. [ ] Enable enhanced logging and alerting
5. [ ] Conduct tabletop exercise

#### Long-term Actions (30+ days)
1. [ ] Implement network segmentation
2. [ ] Deploy API gateway with rate limiting
3. [ ] Establish quarterly API key rotation
4. [ ] Conduct penetration testing
5. [ ] Review third-party integrations

---

### 6.2 Vulnerability Management

**Profile Level:** L1 (Baseline)

#### Recent Critical CVEs

| CVE | CVSS | Description | Remediation |
|-----|------|-------------|-------------|
| CVE-2024-12356 | 9.8 | Command injection in RS | Patch immediately |
| CVE-2024-12686 | 6.6 | Authentication bypass | Patch immediately |

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

**Official BeyondTrust Documentation:**
- [Trust Center — Corporate Security](https://www.beyondtrust.com/trust-center/security)
- [Industry Certifications](https://www.beyondtrust.com/trust-center/industry-certifications)
- [Cloud Security Policies](https://www.beyondtrust.com/trust-center/cloud-security)
- [BeyondTrust Documentation](https://www.beyondtrust.com/docs)
- [Appliance Hardening Guide](https://www.beyondtrust.com/docs/beyondinsight-password-safe/appliance/hardening/index.htm)

**API & Developer Tools:**
- [PRA API Guide](https://docs.beyondtrust.com/pra/reference/api-guide)
- [Remote Support API Documentation](https://www.beyondtrust.com/docs/remote-support/how-to/integrations/api/index.htm)
- [BeyondInsight API](https://www.beyondtrust.com/docs/beyondinsight-password-safe/api/index.htm)

**Compliance Frameworks:**
- SOC 2 Type II (annual audits of corporate practices, product portfolio, and cloud environments) — via [Industry Certifications](https://www.beyondtrust.com/trust-center/industry-certifications)
- ISO/IEC 27001:2022, ISO/IEC 27701 (PIMS) — via [ISO Certification Announcement](https://www.beyondtrust.com/press/iso-270012022-certification)
- PCI DSS, HIPAA, CISA BOD 22-01 compliance support

**Security Incidents:**
- **December 2024 — U.S. Treasury Department Breach (CVE-2024-12356, CVSS 9.8):** Chinese APT group Silk Typhoon (APT27) compromised a BeyondTrust Remote Support SaaS API key, gaining access to Treasury Department workstations and unclassified documents. BeyondTrust detected the compromise on December 5, immediately revoked the API key, and notified affected customers. 17 Remote Support SaaS customers were impacted. CVE-2024-12686 (CVSS 6.6, authentication bypass) was also exploited. ([The Hacker News Report](https://thehackernews.com/2024/12/chinese-apt-exploits-beyondtrust-api.html)) ([CyberArk Analysis](https://www.cyberark.com/resources/blog/the-us-treasury-attack-key-events-and-security-implications))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial guide with Treasury breach lessons | Claude Code (Opus 4.5) |
