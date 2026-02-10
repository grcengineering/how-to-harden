---
layout: guide
title: "Zscaler Hardening Guide"
vendor: "Zscaler"
slug: "zscaler"
tier: "1"
category: "Security"
description: "Security hardening for Zscaler ZIA, ZPA, and Client Connector deployment"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Zscaler is a cloud-native security platform providing Zero Trust Network Access (ZTNA) through Zscaler Internet Access (ZIA) and Zscaler Private Access (ZPA). With **40+ million users protected daily**, Zscaler serves as a critical security control point for web traffic inspection, application access, and threat prevention. Properly hardening Zscaler configurations is essential for maximizing security value and preventing bypass.

### Intended Audience
- Security engineers managing Zscaler deployments
- IT administrators configuring ZIA/ZPA policies
- GRC professionals assessing network security
- Third-party risk managers evaluating ZTNA solutions

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML-based SSO for Zscaler Admin Portal and Client Connector authentication through your corporate identity provider.

#### Rationale
**Why This Matters:**
- Centralizes authentication management
- Enables MFA enforcement through IdP
- Provides consistent access policies
- Eliminates standalone Zscaler passwords

#### Prerequisites
- [ ] Zscaler ZIA or ZPA subscription
- [ ] SAML 2.0 compatible identity provider
- [ ] Super Admin access to Zscaler Admin Portal

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

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Configure granular admin roles in Zscaler to limit access based on job responsibilities. Avoid using Super Admin for routine tasks.

#### Rationale
**Why This Matters:**
- Super Admin has unrestricted access to all settings
- Compromised admin accounts have significant impact
- Role-based access supports audit requirements

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

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.2 |
| NIST 800-53 | SC-7, SI-3 |

#### Description
Configure URL filtering policies to block access to malicious, risky, and policy-violating web categories.

#### Rationale
**Why This Matters:**
- URL filtering is foundational web security
- Blocks access to known malicious sites
- Prevents productivity loss and policy violations
- Zscaler provides recommended policy templates

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

---

### 2.2 Enable Advanced Threat Protection

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.1, 10.5 |
| NIST 800-53 | SI-3, SI-4 |

#### Description
Enable Zscaler's advanced threat protection capabilities including cloud sandbox, malware protection, and behavioral analysis.

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

---

### 2.3 Configure Firewall Policies

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.4, 13.4 |
| NIST 800-53 | SC-7, AC-4 |

#### Description
Configure Zscaler Cloud Firewall policies to control non-web traffic including protocols, ports, and applications.

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

---

## 3. ZPA Application Access

### 3.1 Configure Application Segments

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4 |
| NIST 800-53 | AC-4, SC-7 |

#### Description
Define application segments in ZPA to control access to internal applications without network-level connectivity.

#### Rationale
**Why This Matters:**
- ZPA provides Zero Trust access (no network exposure)
- Application segments define what's accessible
- Granular access replaces broad VPN access
- Reduces lateral movement risk

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

---

### 3.2 Create Access Policies

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4, 6.8 |
| NIST 800-53 | AC-3, AC-6 |

#### Description
Create ZPA access policies that define who can access which applications based on user identity, device posture, and context.

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

---

### 3.3 Enable Device Posture Checks

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | AC-2(11) |

#### Description
Configure device posture checks to verify endpoint security status before granting application access.

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

---

## 4. Client Connector Hardening

### 4.1 Deploy Client Connector Securely

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7, SC-7 |

#### Description
Deploy Zscaler Client Connector with security-optimized settings to ensure all traffic is properly tunneled and inspected.

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

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | SC-8, SI-4 |

#### Description
Deploy Zscaler root certificate to enable SSL inspection of encrypted traffic.

#### Rationale
**Why This Matters:**
- Over 90% of web traffic is encrypted
- Without SSL inspection, threats hide in HTTPS
- Certificate must be trusted by endpoints

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

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7 |

#### Description
Lock Client Connector configuration to prevent users from disabling or bypassing Zscaler protection.

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

### 5.1 Enable SSL Inspection

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10, 13.3 |
| NIST 800-53 | SC-8, SI-3 |

#### Description
Enable SSL/TLS inspection to decrypt, inspect, and re-encrypt HTTPS traffic for threat detection and policy enforcement.

#### Rationale
**Why This Matters:**
- Encrypted traffic hides threats from inspection
- SSL inspection enables full visibility
- Required for effective DLP and malware detection

#### Prerequisites
- [ ] SSL certificate deployed to endpoints
- [ ] Certificate pinning exceptions documented
- [ ] Testing plan for application compatibility

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

---

### 5.2 Test SSL Inspection Thoroughly

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | CA-2 |

#### Description
Thoroughly test SSL inspection before production deployment to identify and resolve application compatibility issues.

#### Testing Checklist

**Pre-Deployment Testing:**
- [ ] Test major business applications
- [ ] Verify certificate chain validity
- [ ] Test certificate-pinned applications
- [ ] Validate mobile app functionality

**Post-Deployment Validation:**
- [ ] Monitor for user-reported issues
- [ ] Check for certificate errors in logs
- [ ] Verify malware detection is working
- [ ] Confirm DLP policies are applied

---

## 6. Monitoring & Detection

### 6.1 Configure Logging and Reporting

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-6 |

#### Description
Configure comprehensive logging and integrate with SIEM for security monitoring and incident investigation.

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

**Official Zscaler Documentation:**
- [Zscaler Compliance Center](https://compliance.zscaler.com/)
- [Zscaler Compliance Overview](https://www.zscaler.com/compliance/overview)
- [Zscaler Trust Security Advisories](https://trust.zscaler.com/security-advisories)
- [ZIA Help Portal](https://help.zscaler.com/zia)
- [ZPA Help Portal](https://help.zscaler.com/zpa)
- [Client Connector Help](https://help.zscaler.com/zscaler-client-connector)
- [ZIA Policy Best Practices Guide](https://help.zscaler.com/zscaler-deployments-operations/zia-policy-leading-practices-guide)
- [ZIA Security Policy Best Practices](https://help.zscaler.com/zia/best-practices-security-policy)

**API Documentation:**
- [ZIA API Getting Started](https://help.zscaler.com/zia/getting-started-zia-api)
- [ZPA API Documentation](https://help.zscaler.com/zpa)

**Deployment Guides:**
- [Step-by-Step Configuration Guide for ZIA](https://help.zscaler.com/zia/step-step-configuration-guide-zia)
- [Step-by-Step Configuration Guide for ZPA](https://help.zscaler.com/zpa/step-step-configuration-guide-zpa)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018, ISO 27701, FedRAMP (product-dependent) -- via [Zscaler Compliance Center](https://compliance.zscaler.com/)

**Security Incidents:**
- **August 2025 -- Salesloft Drift Supply-Chain Breach:** Threat actor UNC6395 exploited compromised Salesloft Drift OAuth tokens to access Zscaler's Salesforce instance, exfiltrating contact metadata (names, emails, job titles), product licensing configurations, and plain-text support case content. Part of a broader campaign affecting 700+ organizations. No Zscaler products, services, or infrastructure were compromised. Detected August 28, disclosed August 31, 2025. All affected OAuth tokens were revoked.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with ZIA/ZPA hardening and Client Connector security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
