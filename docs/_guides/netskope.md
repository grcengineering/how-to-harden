---
layout: guide
title: "Netskope Hardening Guide"
vendor: "Netskope"
slug: "netskope"
tier: "1"
category: "Security"
description: "Security hardening for Netskope CASB, SWG, and ZTNA deployment"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Netskope is a leading Security Service Edge (SSE) platform providing CASB, Secure Web Gateway (SWG), and Zero Trust Network Access (ZTNA) for cloud security. As a critical security control point for cloud application access, Netskope configurations directly impact data protection and threat prevention across SaaS applications, web traffic, and private applications.

### Intended Audience
- Security engineers managing Netskope deployments
- IT administrators configuring SSE policies
- GRC professionals assessing cloud security
- Third-party risk managers evaluating CASB solutions

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Netskope tenant hardening, CASB policies, DLP configuration, threat protection, and steering configuration.

---

## Table of Contents

1. [Tenant Security](#1-tenant-security)
2. [CASB Policies](#2-casb-policies)
3. [Data Loss Prevention](#3-data-loss-prevention)
4. [Threat Protection](#4-threat-protection)
5. [Steering Configuration](#5-steering-configuration)
6. [Monitoring & Detection](#6-monitoring--detection)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Tenant Security

### 1.1 Secure Admin Console Access

**Profile Level:** L1 (Baseline)

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

{% include pack-code.html vendor="netskope" section="1.1" %}

---

### 1.2 Configure Tenant Hardening

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7 |

#### Description
Apply Netskope's recommended tenant hardening configurations.

#### ClickOps Implementation

**Step 1: Access Tenant Settings**
1. Navigate to: **Settings** → **Tenant Settings**
2. Review security settings

**Step 2: Configure Security Options**
1. Enable **Session timeout** (15-30 minutes)
2. Configure **Password policies** (if using local auth)
3. Enable **Audit logging** for admin actions
4. Configure **IP allowlisting** for admin access (L2)

{% include pack-code.html vendor="netskope" section="1.2" %}

---

## 2. CASB Policies

### 2.1 Configure Application Visibility

**Profile Level:** L1 (Baseline)

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

{% include pack-code.html vendor="netskope" section="2.1" %}

---

### 2.2 Configure Real-Time Protection Policies

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.2 |
| NIST 800-53 | SC-7, AC-4 |

#### Description
Configure real-time protection policies to control access to cloud applications based on user, app, activity, and data.

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

{% include pack-code.html vendor="netskope" section="2.2" %}

---

### 2.3 Configure API Protection

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SC-28 |

#### Description
Configure API-enabled protection to scan and protect data at rest in sanctioned SaaS applications.

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

{% include pack-code.html vendor="netskope" section="2.3" %}

---

## 3. Data Loss Prevention

### 3.1 Configure DLP Profiles

**Profile Level:** L1 (Baseline)

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

{% include pack-code.html vendor="netskope" section="3.1" %}

---

### 3.2 Apply DLP to Policies

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SC-8 |

#### Description
Apply DLP profiles to real-time protection and API protection policies.

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

{% include pack-code.html vendor="netskope" section="3.2" %}

---

## 4. Threat Protection

### 4.1 Configure Malware Protection

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.1 |
| NIST 800-53 | SI-3 |

#### Description
Configure Netskope's threat protection to detect and prevent malware in cloud traffic.

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

{% include pack-code.html vendor="netskope" section="4.1" %}

---

### 4.2 Configure Threat Protection Policies

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.5 |
| NIST 800-53 | SI-4 |

#### Description
Create comprehensive threat protection policies following Netskope best practices.

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

{% include pack-code.html vendor="netskope" section="4.2" %}

---

## 5. Steering Configuration

### 5.1 Configure Netskope Client Steering

**Profile Level:** L1 (Baseline)

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

{% include pack-code.html vendor="netskope" section="5.1" %}

---

### 5.2 Deploy Netskope Client

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | SC-7 |

#### Description
Deploy Netskope Client to endpoints to enable inline inspection and steering.

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

{% include pack-code.html vendor="netskope" section="5.2" %}

---

## 6. Monitoring & Detection

### 6.1 Configure Logging and Alerts

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-6 |

#### Description
Configure comprehensive logging and alerting for security monitoring.

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

{% include pack-code.html vendor="netskope" section="6.1" %}

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

**Security Incidents:**
- No major public security incidents identified for Netskope. Monitor [Netskope Security, Compliance and Assurance](https://www.netskope.com/company/security-compliance-and-assurance) for current advisories.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with CASB, DLP, and threat protection | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
