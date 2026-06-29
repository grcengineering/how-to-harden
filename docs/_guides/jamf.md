---
layout: guide
title: "Jamf Pro Hardening Guide"
vendor: "Jamf"
slug: "jamf"
tier: "2"
category: "IT Operations"
description: "MDM hardening for Jamf Pro macOS and iOS device management"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

Jamf Pro is the leading Apple device management platform used by **over 70,000 organizations** to manage macOS, iOS, iPadOS, and tvOS devices. As a critical infrastructure component for device security, Jamf Pro configurations directly impact endpoint security posture across Apple fleets. Proper hardening ensures devices are configured securely while maintaining user productivity.

### Intended Audience
- Security engineers managing Apple device fleets
- IT administrators configuring Jamf Pro
- GRC professionals assessing MDM security
- Third-party risk managers evaluating device management

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Jamf Pro server security, configuration profiles, CIS benchmark implementation, and managed device hardening.

---

## Table of Contents

1. [Jamf Pro Server Security](#1-jamf-pro-server-security)
2. [Device Security Policies](#2-device-security-policies)
3. [CIS Benchmark Implementation](#3-cis-benchmark-implementation)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Jamf Pro Server Security

### 1.1 Secure Jamf Pro Console Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Secure Jamf Pro console access with SSO, MFA, and role-based access controls.

#### Rationale
**Why This Matters:**
- Jamf Pro controls all managed device configurations
- Compromised admin can push malicious profiles/scripts
- Role-based access limits blast radius

#### ClickOps Implementation

**Step 1: Configure SSO**
1. Navigate to: **Jamf Pro** → **Settings** → **System** → **SSO**
2. Click **Edit**
3. Configure SAML SSO:
   - Upload IdP metadata
   - Configure attribute mappings
   - Set group mappings to Jamf roles
4. Test SSO authentication

**Step 2: Configure User Accounts**
1. Navigate to: **Settings** → **User Accounts & Groups**
2. Review existing accounts
3. Remove unnecessary admin accounts
4. Convert local accounts to SSO where possible

**Step 3: Configure Privilege Sets**
1. Navigate to: **Settings** → **User Accounts** → **Privilege Sets**
2. Create granular privilege sets:
   - **Help Desk:** Device lookup, basic actions
   - **Deployment:** Profile and app management
   - **Security:** Full security policy access
   - **Administrator:** Full access (limit to 2-3)
3. Assign minimum required privileges

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="jamf" section="1.1" lang="terraform" %}

---

### 1.2 Secure API Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure Jamf Pro API access with dedicated accounts and token-based authentication.

#### Rationale
**Why This Matters:**
- The Jamf Pro API can read and modify every managed device, push profiles and scripts, and pull full inventory — an exposed API token is effectively full MDM admin
- Dedicated, least-privilege API accounts keep a compromised integration from inheriting human-admin power and make revocation surgical
- Bearer tokens with rotation and short expiry shrink the window a leaked credential stays useful, unlike long-lived basic-auth passwords
- API audit logging exposes credential abuse and automated reconnaissance that the console UI never surfaces

**Attack Prevented:** API token theft, credential stuffing, over-privileged integration abuse, undetected programmatic tampering

#### ClickOps Implementation

**Step 1: Create API Accounts**
1. Navigate to: **Settings** → **User Accounts & Groups**
2. Create dedicated API accounts (not personal admin accounts)
3. Assign minimum required privilege set

**Step 2: Configure API Token Authentication**
1. Use bearer token authentication (not basic auth)
2. Implement token rotation
3. Monitor API usage

**Step 3: Enable API Audit Logging**
1. Navigate to: **Settings** → **Server** → **Logging**
2. Enable API request logging
3. Export to SIEM for monitoring

**Best Practices:**
- Use separate API accounts per integration
- Store tokens in secure vault
- Set token expiration policies
- Audit API access regularly

#### Code Implementation

{% include pack-code.html vendor="jamf" section="1.2" lang="terraform" %}

---

## 2. Device Security Policies

### 2.1 Configure Password Policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2 |
| NIST 800-53 | IA-5 |

#### Description
Configure device password policies through configuration profiles.

#### Rationale
**Why This Matters:**
- Device passcodes are the first barrier against physical access to a lost or stolen Mac before FileVault unlock
- Weak or short passcodes fall quickly to brute-force and shoulder-surfing, exposing local data and cached credentials
- Enforced length, complexity, history, and auto-lock remove the user's ability to opt out of baseline protection
- Centralized profile enforcement guarantees the policy applies fleet-wide instead of relying on per-user discipline

**Attack Prevented:** Brute-force passcode guessing, physical device access, shoulder-surfing, credential reuse

#### ClickOps Implementation

**Step 1: Create Password Policy Profile**
1. Navigate to: **Computers** → **Configuration Profiles**
2. Click **+ New**
3. Select **Password** payload
4. Configure:
   - **Minimum length:** 12+ characters (14+ for L2)
   - **Require alphanumeric:** Yes
   - **Minimum complex characters:** 1+
   - **Maximum passcode age:** 90 days (or disable for L3)
   - **Passcode history:** Remember 5-10 passwords
   - **Auto-lock:** 5 minutes (or less for L2)

**Step 2: Scope Profile**
1. Configure scope:
   - All computers
   - Or specific groups
2. Deploy profile

**Time to Complete:** ~20 minutes

#### Code Implementation

{% include pack-code.html vendor="jamf" section="2.1" lang="terraform" %}

---

### 2.2 Configure FileVault Encryption

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-28 |

#### Description
Enforce FileVault full disk encryption on all managed macOS devices.

#### Rationale
**Why This Matters:**
- Protects data on lost/stolen devices
- Required for most compliance frameworks
- Jamf can escrow recovery keys

#### ClickOps Implementation

**Step 1: Create FileVault Profile**
1. Navigate to: **Computers** → **Configuration Profiles**
2. Click **+ New**
3. Select **Security & Privacy** → **FileVault** payload
4. Configure:
   - **Enable FileVault:** Yes
   - **Defer to user:** Enable (if not already encrypted)
   - **Recovery key type:** Institutional or Personal
   - **Escrow to Jamf:** Yes

**Step 2: Configure Recovery Key Escrow**
1. Enable **Escrow Personal Recovery Key**
2. Configure key rotation (optional)
3. Store institutional key securely

**Step 3: Create Remediation Policy**
1. Create Smart Group: Computers without FileVault
2. Create policy to enforce or notify

#### Code Implementation

{% include pack-code.html vendor="jamf" section="2.2" lang="terraform" %}

---

### 2.3 Configure Firewall

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.4 |
| NIST 800-53 | SC-7 |

#### Description
Enable and configure macOS firewall on all managed devices.

#### Rationale
**Why This Matters:**
- The macOS application firewall blocks unsolicited inbound connections to listening services on the endpoint
- Stealth mode stops the device from responding to network probes, reducing its visibility to attackers scanning the LAN or untrusted Wi-Fi
- Endpoints roam onto hostile networks (cafes, airports, hotels) where host-based filtering is the only perimeter the device has
- Centrally enforcing the firewall stops users from disabling it and closes the gap for lateral movement and remote service exploitation

**Attack Prevented:** Network-based exploitation, port scanning, lateral movement, unsolicited inbound connections

#### ClickOps Implementation

**Step 1: Create Firewall Profile**
1. Navigate to: **Computers** → **Configuration Profiles**
2. Click **+ New**
3. Select **Security & Privacy** → **Firewall** payload
4. Configure:
   - **Enable firewall:** Yes
   - **Block all incoming connections:** No (or Yes for L3)
   - **Enable stealth mode:** Yes
   - **Automatically allow built-in software:** Yes
   - **Automatically allow signed software:** Yes (or No for L3)

**Step 2: Scope and Deploy**
1. Scope to all computers
2. Deploy profile

#### Code Implementation

{% include pack-code.html vendor="jamf" section="2.3" lang="terraform" %}

---

### 2.4 Configure Software Updates

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 7.3 |
| NIST 800-53 | SI-2 |

#### Description
Configure automatic software updates and patch management.

#### Rationale
**Why This Matters:**
- Unpatched macOS and application vulnerabilities are among the most reliably exploited paths to endpoint compromise
- Automatic update enforcement closes the window between a security fix shipping and devices actually applying it
- Rapid security responses address actively exploited zero-days that attackers weaponize within days of disclosure
- Patch compliance monitoring surfaces the long tail of devices that silently fall behind and become the weakest link

**Attack Prevented:** Exploitation of known vulnerabilities, zero-day weaponization, drive-by malware, outdated-component compromise

#### ClickOps Implementation

**Step 1: Create Software Update Profile**
1. Navigate to: **Computers** → **Configuration Profiles**
2. Click **+ New**
3. Select **Software Update** payload
4. Configure:
   - **Automatic update check:** Yes
   - **Download updates in background:** Yes
   - **Install app updates:** Yes
   - **Install macOS updates:** Yes
   - **Install security responses:** Yes (Critical)

**Step 2: Configure Update Deferral (L2)**
1. For controlled environments:
   - Defer major OS updates: 30-90 days
   - Defer security updates: 0-7 days (test first)

**Step 3: Create Patch Policies**
1. Use Jamf Pro patch management
2. Configure automatic patching for critical apps
3. Monitor patch compliance

#### Code Implementation

{% include pack-code.html vendor="jamf" section="2.4" lang="terraform" %}

---

## 3. CIS Benchmark Implementation

### 3.1 Deploy CIS Benchmark Profiles

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Deploy CIS macOS Benchmark security configurations using Jamf Compliance Editor.

#### Rationale
**Why This Matters:**
- CIS Benchmarks are industry-standard security baselines
- Jamf Compliance Editor generates MDM-ready profiles
- Supports both Level 1 and Level 2 hardening

#### Prerequisites
- Download Jamf Compliance Editor from GitHub
- Review CIS macOS Benchmark requirements
- Test in non-production environment

#### Implementation

**Step 1: Generate CIS Profiles**
1. Download [Jamf Compliance Editor](https://github.com/jamf/Jamf-Compliance-Editor)
2. Open application
3. Select CIS Benchmark level:
   - **Level 1:** Baseline security
   - **Level 2:** Enhanced security
4. Generate configuration profiles

**Step 2: Review and Customize**
1. Review generated settings
2. Customize based on business needs
3. Document any deviations

**Step 3: Deploy Profiles**
1. Upload profiles to Jamf Pro
2. Create test scope first
3. Validate functionality
4. Deploy to production

**Key CIS Controls:**

| CIS Control | Description | Implementation |
|-------------|-------------|----------------|
| 2.1.1 | Enable FileVault | Configuration Profile |
| 2.1.2 | Enable Gatekeeper | Configuration Profile |
| 2.3.1 | Set screen saver | Configuration Profile |
| 2.5.1 | Enable Firewall | Configuration Profile |
| 3.3 | Disable Remote Login | Configuration Profile |

**Time to Complete:** ~4 hours (testing included)

#### Code Implementation

{% include pack-code.html vendor="jamf" section="3.1" lang="terraform" %}

---

### 3.2 Monitor CIS Compliance

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Monitor device compliance with CIS Benchmark configurations.

#### Rationale
**Why This Matters:**
- Deploying a benchmark profile is not the same as devices staying compliant — drift, user tampering, and failed installs erode the baseline over time
- Smart groups and extension attributes give continuous, evidence-based visibility into which devices have actually fallen out of policy
- Early detection of non-compliant devices lets you remediate before an attacker exploits the missing control
- Compliance reports provide audit-ready proof of control effectiveness for SOC 2, ISO 27001, and regulatory assessments

**Attack Prevented:** Configuration drift, silent control failure, undetected non-compliance, audit evidence gaps

#### ClickOps Implementation

**Step 1: Create Smart Groups**
1. Create smart groups for compliance monitoring:
   - FileVault not enabled
   - Firewall not enabled
   - OS not updated
   - Non-compliant configurations

**Step 2: Configure Compliance Reporting**
1. Navigate to: **Settings** → **Computer Management** → **Extension Attributes**
2. Create extension attributes for CIS checks
3. Use in smart groups for compliance tracking

**Step 3: Generate Compliance Reports**
1. Use Jamf Pro reporting
2. Export for compliance documentation
3. Track compliance trends

#### Code Implementation

{% include pack-code.html vendor="jamf" section="3.2" lang="terraform" %}

---

## 4. Monitoring & Compliance

### 4.1 Enable Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable comprehensive audit logging for Jamf Pro activities.

#### Rationale
**Why This Matters:**
- Jamf Pro admin actions — profile pushes, script runs, MDM commands, and account changes — are high-impact and must be attributable to a specific actor
- Without comprehensive logs, a compromised admin account or malicious insider can tamper with the fleet undetected and without forensic trail
- Forwarding logs to a SIEM enables real-time alerting on anomalous activity and preserves evidence beyond the console's local retention
- Audit trails are a hard requirement for SOC 2, ISO 27001, and most regulatory frameworks

**Attack Prevented:** Insider abuse, undetected admin compromise, repudiation, evidence tampering

#### ClickOps Implementation

**Step 1: Configure Server Logs**
1. Navigate to: **Settings** → **Server** → **Logging**
2. Configure log retention
3. Enable all relevant log types

**Step 2: Configure SIEM Integration**
1. Configure syslog forwarding to SIEM
2. Or use Jamf Pro webhooks for events
3. Monitor for security events

#### Code Implementation

{% include pack-code.html vendor="jamf" section="4.1" lang="terraform" %}

---

### 4.2 Key Events to Monitor

| Event | Detection Use Case |
|-------|-------------------|
| Admin login | Unauthorized access |
| Profile deployment | Unauthorized configuration |
| Script execution | Malicious scripts |
| Policy changes | Configuration drift |
| Failed enrollment | Enrollment issues |
| MDM command | Unauthorized commands |

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Jamf Control | Guide Section |
|-----------|--------------|---------------|
| CC6.1 | Console access control | [1.1](#11-secure-jamf-pro-console-access) |
| CC6.6 | Device policies | [2.1](#21-configure-password-policies) |
| CC6.7 | Encryption | [2.2](#22-configure-filevault-encryption) |
| CC7.1 | Firewall | [2.3](#23-configure-firewall) |
| CC7.2 | Audit logging | [4.1](#41-enable-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Jamf Control | Guide Section |
|---------|--------------|---------------|
| AC-6(1) | Admin roles | [1.1](#11-secure-jamf-pro-console-access) |
| IA-5 | Password policy | [2.1](#21-configure-password-policies) |
| SC-28 | FileVault encryption | [2.2](#22-configure-filevault-encryption) |
| SC-7 | Firewall | [2.3](#23-configure-firewall) |
| CM-6 | CIS Benchmarks | [3.1](#31-deploy-cis-benchmark-profiles) |

---

## Appendix A: Plan Compatibility

| Feature | Jamf Now | Jamf Pro | Jamf Connect |
|---------|----------|----------|--------------|
| Configuration Profiles | Basic | Full | N/A |
| Scripts | ❌ | ✅ | N/A |
| Extension Attributes | ❌ | ✅ | N/A |
| Patch Management | ❌ | ✅ | N/A |
| SSO | ❌ | ✅ | N/A |
| API Access | Limited | Full | N/A |
| SIEM Integration | ❌ | ✅ | N/A |

---

## Appendix B: References

**Official Jamf Documentation:**
- [Trust Center - Compliance](https://www.jamf.com/trust-center/compliance/)
- [Security Portal](https://security.jamf.com/)
- [Information Security](https://www.jamf.com/trust-center/information-security/)
- [Product Documentation](https://www.jamf.com/resources/product-documentation/)
- [Jamf Pro Documentation](https://learn.jamf.com)
- [Jamf Pro Security Recommendations](https://learn.jamf.com/en-US/bundle/technical-articles/page/Jamf_Pro_Security_Recommendations.html)
- [Third-Party Audits](https://learn.jamf.com/en-US/bundle/jamf-pro-security-overview/page/Third-Party_Audits.html)

**API & Developer Tools:**
- [Jamf Developer Portal](https://developer.jamf.com/)
- [Jamf Pro API Reference](https://developer.jamf.com/jamf-pro/reference/classic-api)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27701 -- via [Trust Center](https://www.jamf.com/trust-center/compliance/) and [Security Portal](https://security.jamf.com/)

**Security Incidents:**
- No major public security incidents affecting Jamf's hosted infrastructure identified as of February 2026. Product-level CVEs (e.g., broken access control in Jamf Pro Server before 10.46.1) have been patched through standard release cycles.

**Community Resources:**
- [Jamf Compliance Editor (GitHub)](https://github.com/jamf/Jamf-Compliance-Editor)
- [CIS macOS Benchmark](https://www.cisecurity.org/benchmark/apple_os)
- [macOS Security Checklist for CIS](https://resources.jamf.com/documents/white-papers/macos-security-checklist-for-cis-benchmark.pdf)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with server security, device policies, and CIS implementation | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
