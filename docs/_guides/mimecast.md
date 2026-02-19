---
layout: guide
title: "Mimecast Hardening Guide"
vendor: "Mimecast"
slug: "mimecast"
tier: "2"
category: "Security"
description: "Email security hardening for Mimecast including targeted threat protection, impersonation policies, and gateway configuration"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Mimecast is a leading cloud-based email security platform protecting **millions of mailboxes** against phishing, malware, and business email compromise (BEC). As the gateway for all organizational email, Mimecast configurations directly impact protection against the #1 attack vector. Proper hardening ensures maximum protection while minimizing false positives.

### Intended Audience
- Security engineers managing email security
- IT administrators configuring Mimecast
- GRC professionals assessing email protection
- SOC analysts monitoring email threats

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Mimecast Email Security Gateway configuration including targeted threat protection, impersonation protection, URL protection, and policy optimization.

---

## Table of Contents

1. [Gateway Configuration](#1-gateway-configuration)
2. [Targeted Threat Protection](#2-targeted-threat-protection)
3. [Impersonation Protection](#3-impersonation-protection)
4. [Admin & Access Security](#4-admin--access-security)
5. [Monitoring & Compliance](#5-monitoring--compliance)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Gateway Configuration

### 1.1 Verify MX Record Configuration

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.2 |
| NIST 800-53 | SC-7 |

#### Description
Ensure MX records are properly configured to route all email through Mimecast.

#### Rationale
**Why This Matters:**
- Incorrect MX priorities can bypass Mimecast protection
- Email must route through Mimecast before reaching mail server
- Misconfiguration leaves organization exposed

#### Validation

**Step 1: Check MX Records**

{% include pack-code.html vendor="mimecast" section="1.1" %}

**Step 2: Verify Configuration**
1. MX records should point to Mimecast servers
2. Priority should be lowest number (e.g., 10)
3. No direct mail server MX records should exist

**Step 3: Configure Email Server**
1. Configure mail server to only accept from Mimecast IPs
2. Block direct delivery attempts
3. Document allowed IP ranges

---

### 1.2 Configure Email Authentication (SPF, DKIM, DMARC)

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.5 |
| NIST 800-53 | SC-8 |

#### Description
Configure email authentication to prevent spoofing and verify sender identity.

#### ClickOps Implementation

**Step 1: Configure SPF**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **DNS Authentication - Outbound**
2. Verify SPF record includes Mimecast. See the Code Pack below for the recommended SPF and DMARC records.

**Step 2: Configure DKIM**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **DNS Authentication - Outbound**
2. Enable DKIM signing
3. Generate DKIM keys
4. Publish DKIM DNS records

**Step 3: Configure DMARC**
1. Publish DMARC record (see Code Pack below for recommended record format)
2. Start with `p=none` for monitoring
3. Progress to `p=quarantine` then `p=reject`

{% include pack-code.html vendor="mimecast" section="1.2" %}

**Step 4: Configure Inbound Checking**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **DNS Authentication - Inbound**
2. Configure actions for SPF/DKIM/DMARC failures

---

### 1.3 Configure Secure Communication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | SC-8 |

#### Description
Configure TLS and secure communication for email transmission.

#### ClickOps Implementation

**Step 1: Configure TLS**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **Secure Messaging**
2. Configure TLS settings:
   - Enable opportunistic TLS
   - Require TLS for sensitive domains (L2)
   - Configure TLS version requirements

**Step 2: Configure Directory Sync Security**
1. Use LDAPS instead of LDAP
2. Navigate to: **Administration** → **Services** → **Directory Sync**
3. Configure LDAPS for encrypted sync

**Step 3: Configure Journaling Security**
1. Use POP3S instead of POP3
2. Ensure encrypted communication

---

## 2. Targeted Threat Protection

### 2.1 Configure URL Protection

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.6 |
| NIST 800-53 | SI-3 |

#### Description
Configure URL Protection to detect and block malicious links.

#### ClickOps Implementation

**Step 1: Access URL Protection**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **URL Protection**

**Step 2: Configure Definition**
1. Click **New Definition** or edit existing
2. Configure URL scanning:
   - **Enable URL rewriting:** Yes
   - **Scan on click:** Yes (critical)
   - **Block malicious URLs:** Yes
   - **Check against browser isolation:** Consider for L2

**Step 3: Enable All URL Options**
1. Enable:
   - Scan internal URLs
   - Check file downloads
   - Advanced similarity checks
   - Newly observed domain detection

**Step 4: Configure User Notification**
1. Configure block page messaging
2. Enable user reporting for false positives
3. Set up admin notifications

**Time to Complete:** ~30 minutes

---

### 2.2 Configure Attachment Protection

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.1 |
| NIST 800-53 | SI-3 |

#### Description
Configure attachment scanning and sandboxing for malware protection.

#### ClickOps Implementation

**Step 1: Access Attachment Protection**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **Attachment Protection**

**Step 2: Configure Attachment Scanning**
1. Configure definition:
   - **Enable attachment scanning:** Yes
   - **Sandbox suspicious files:** Yes
   - **Block password-protected archives:** Consider
   - **Block dangerous file types:** Yes

**Step 3: Configure File Type Restrictions**
1. Block high-risk file types:
   - Executable files (.exe, .scr, .bat, .cmd)
   - Script files (.js, .vbs, .ps1)
   - Macro-enabled documents (.docm, .xlsm)
2. Consider blocking by default, allow by exception

**Step 4: Configure Safe File Viewing**
1. Enable **Preemptive protection**
2. Convert to safe formats before delivery
3. Allow download of original if needed

---

### 2.3 Configure Internal Email Protection

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.6 |
| NIST 800-53 | SI-3 |

#### Description
Enable scanning of internal email for compromised account detection.

#### Rationale
**Why This Matters:**
- Compromised internal accounts can spread malware
- Internal phishing can bypass perimeter controls
- Lateral movement detection

#### ClickOps Implementation

**Step 1: Configure Internal Email Protect**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **Internal Email Protect**
2. Enable internal email scanning
3. Configure threat detection

**Step 2: Configure Policies**
1. Apply URL Protection to internal mail
2. Apply Attachment Protection
3. Monitor for suspicious patterns

---

## 3. Impersonation Protection

### 3.1 Configure Standard Impersonation Policy

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.6 |
| NIST 800-53 | SI-3 |

#### Description
Configure impersonation protection to detect business email compromise attempts.

#### Rationale
**Why This Matters:**
- BEC attacks cause billions in losses annually
- Impersonation of executives is primary attack vector
- Requires multiple detection layers

#### ClickOps Implementation

**Step 1: Configure Impersonation Protection**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **Impersonation Protection**
2. Create new definition

**Step 2: Configure Standard 2-Hit Policy**
1. Configure "2-hit" detection:
   - Display name matches + suspicious indicators
   - Reply-to mismatch + urgency language
2. Set action: Tag, hold, or block

**Step 3: Configure Newly Observed Domain Policy**
1. Flag emails from newly registered domains
2. Increased scrutiny for new senders
3. Configure age threshold (e.g., 30 days)

---

### 3.2 Configure VIP Protection

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.6 |
| NIST 800-53 | SI-3 |

#### Description
Configure enhanced protection for high-value targets (executives, finance).

#### ClickOps Implementation

**Step 1: Define VIP List**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **Profile Groups**
2. Create VIP profile group
3. Add executives and high-risk users:
   - CEO, CFO, C-suite
   - Finance team
   - HR team
   - Legal team

**Step 2: Configure VIP Policy**
1. Create dedicated impersonation definition for VIPs
2. Configure stricter detection:
   - Lower threshold for flagging
   - Additional display name variations
   - External sender warnings

**Step 3: Configure User Awareness**
1. Add warning banners for impersonation attempts
2. Train VIPs on threat awareness
3. Establish out-of-band verification procedures

---

### 3.3 Configure Advanced Business Email Compromise (ABEC)

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.6 |
| NIST 800-53 | SI-3 |

#### Description
Enable advanced BEC detection using AI-powered analysis.

#### ClickOps Implementation

**Step 1: Enable ABEC**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Email Policies**
2. Edit policy → **Phishing & Impersonation**
3. Enable **Advanced BEC** settings

**Step 2: Configure ABEC Options**
1. Enable AI-based detection
2. Configure sensitivity level
3. Consider Monitor Mode for testing

**Step 3: Tune and Validate**
1. Review detections
2. Adjust false positive rates
3. Move from monitor to enforcement

---

## 4. Admin & Access Security

### 4.1 Configure Admin Access Controls

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege for Mimecast administration.

#### ClickOps Implementation

**Step 1: Review Admin Roles**
1. Navigate to: **Administration** → **Account** → **Roles**
2. Review built-in roles
3. Create custom roles for specific functions

**Step 2: Implement Role-Based Access**
1. Create roles:
   - **Security Admin:** Policy management
   - **Report Viewer:** Read-only reporting
   - **Help Desk:** User support only
2. Assign minimum required permissions

**Step 3: Limit Full Admin Access**
1. Restrict full admin to essential personnel
2. Use separate accounts for admin work
3. Regular access reviews

---

### 4.2 Enforce MFA for Admin Accounts

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all administrative access to Mimecast.

#### ClickOps Implementation

**Step 1: Configure 2-Step Authentication**
1. Navigate to: **Administration** → **Account** → **Authentication**
2. Enable **2-Step Verification**
3. Apply to all admin accounts

**Step 2: Configure Authentication Methods**
1. Supported methods:
   - Authenticator app (recommended)
   - Email verification
2. Enforce enrollment

---

### 4.3 Manage User Access and Lifecycle

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Implement proper user lifecycle management.

#### ClickOps Implementation

**Step 1: Configure Directory Sync**
1. Navigate to: **Administration** → **Services** → **Directory Sync**
2. Configure sync with Active Directory
3. Enable automatic disabling on AD deletion/disable

**Step 2: Regular Access Review**
1. Review user accounts quarterly
2. Remove inactive accounts
3. Verify access levels appropriate

---

## 5. Monitoring & Compliance

### 5.1 Configure Audit Logging

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs for security events.

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Administration** → **Account** → **Audit Events**
2. Review logged events:
   - Admin actions
   - Policy changes
   - Authentication events

**Step 2: Configure SIEM Integration**
1. Navigate to: **Administration** → **Services** → **SIEM Integration**
2. Configure log export to SIEM
3. Configure real-time streaming

**Key Events to Monitor:**
- Policy modifications
- Admin login events
- Permission changes
- URL/Attachment blocks
- Impersonation detections

---

### 5.2 Conduct Quarterly Policy Review

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Regularly audit and review Mimecast policies for effectiveness.

#### Process

**Step 1: Audit Core Security Policies**
1. Review 18 core security policies
2. Verify configurations are current
3. Check for policy drift

**Step 2: Review Profile Groups**
1. Audit email/domain/IP lists
2. Remove obsolete entries
3. Document approved exceptions

**Step 3: Review Detection Effectiveness**
1. Analyze blocked threats
2. Review false positive rates
3. Tune policies as needed

**Quarterly Checklist:**
- [ ] Review impersonation protection settings
- [ ] Verify VIP list is current
- [ ] Audit permitted sender lists
- [ ] Review URL/Attachment block rates
- [ ] Check admin access list
- [ ] Verify MX record configuration

---

### 5.3 Monitor Threat Dashboard

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Actively monitor threat dashboard for emerging threats.

#### ClickOps Implementation

**Step 1: Access Dashboard**
1. Navigate to: **Monitoring** → **Threat Dashboard**
2. Review:
   - Blocked threats by category
   - Detection trends
   - Top targeted users

**Step 2: Configure Alerts**
1. Set up alerts for:
   - Unusual volume of blocks
   - New threat campaigns
   - Targeted attacks on VIPs

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Mimecast Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | Admin MFA | [4.2](#42-enforce-mfa-for-admin-accounts) |
| CC6.6 | URL Protection | [2.1](#21-configure-url-protection) |
| CC6.8 | Attachment Protection | [2.2](#22-configure-attachment-protection) |
| CC7.1 | Email Authentication | [1.2](#12-configure-email-authentication-spf-dkim-dmarc) |
| CC7.2 | Audit logging | [5.1](#51-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Mimecast Control | Guide Section |
|---------|------------------|---------------|
| SC-7 | Gateway configuration | [1.1](#11-verify-mx-record-configuration) |
| SC-8 | TLS/Encryption | [1.3](#13-configure-secure-communication) |
| SI-3 | Threat Protection | [2.1](#21-configure-url-protection), [2.2](#22-configure-attachment-protection) |
| AC-6 | Least privilege | [4.1](#41-configure-admin-access-controls) |
| AU-2 | Audit logging | [5.1](#51-configure-audit-logging) |

---

## Appendix A: Default Policy Review

| Policy Area | Default Setting | Recommended Change |
|-------------|-----------------|-------------------|
| URL Protection | Basic | Enable all options |
| Attachment Protection | Basic | Enable sandboxing |
| Impersonation Protection | Disabled | Enable with VIP list |
| DMARC | None | p=quarantine minimum |
| Internal Email Protection | Disabled | Enable for L2 |

---

## Appendix B: References

**Official Mimecast Documentation:**
- [Mimecast Trust Center](https://www.mimecast.com/company/mimecast-trust-center/)
- [Mimecast Product Documentation](https://docs.mimecast.com/)
- [Targeted Threat Protection Optimization](https://mimecastsupport.zendesk.com/hc/en-us/articles/34000726395155-Targeted-Threat-Protection-Optimization)
- [TTP Impersonation Protect Guide](https://community.mimecast.com/s/article/email-security-cloud-gateway-ttp-impersonation-protection-guides)
- [Email Security Cloud Gateway Best Practices](https://community.mimecast.com/s/article/email-security-cloud-gateway-security-best-practice)

**API Documentation:**
- [Mimecast Developer Portal](https://developer.services.mimecast.com/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO/IEC 27001:2022, ISO/IEC 27701:2019, ISO 22301:2019, ISO/IEC 42001:2023, Cyber Essentials Plus — via [Mimecast Certification and Attestation](https://www.mimecast.com/company/mimecast-trust-center/certification-and-attestation/)
- [Mimecast Trust Center (SafeBase)](https://trust.mimecast.com/)

**Security Incidents:**
- **SolarWinds Supply Chain Attack (January 2021):** Mimecast confirmed that a certificate used for Microsoft 365 Exchange Web Services authentication was compromised by the same nation-state actors (APT29) behind the SolarWinds attack. Approximately 10% of customers (~3,900) used the affected connection type, and fewer than 10 were specifically targeted. Attackers potentially exfiltrated encrypted service account credentials and accessed some source code. — [Mimecast Certificate Compromise (TechTarget)](https://www.techtarget.com/searchsecurity/news/252495395/Mimecast-certificate-compromised-by-SolarWinds-hackers)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with gateway, TTP, and impersonation protection | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
