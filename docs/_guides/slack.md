---
layout: guide
title: "Slack Hardening Guide"
vendor: "Slack"
slug: "slack"
tier: "1"
category: "Productivity"
description: "Enterprise security hardening for Slack workspaces, SSO, DLP, and data governance"
version: "0.1.0"
maturity: "draft"
last_updated: "2026-02-19"
---

## Overview

Slack is used by over **750,000 organizations** worldwide for business communication, with Enterprise Grid serving large enterprises requiring centralized security controls. As a repository of sensitive business communications, intellectual property, and credentials shared in messages, Slack security is critical for preventing data breaches and maintaining compliance.

### Intended Audience
- Security engineers managing Slack Enterprise deployments
- IT administrators configuring workspace security
- GRC professionals assessing collaboration tool compliance
- Third-party risk managers evaluating Slack integrations

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries (HIPAA, FINRA, FedRAMP)

### Scope
This guide covers Slack workspace and Enterprise Grid security configurations including SSO/SAML, data loss prevention, retention policies, app management, and external collaboration controls.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Network Access Controls](#2-network-access-controls)
3. [OAuth & Integration Security](#3-oauth--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enable SAML Single Sign-On (SSO)

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML-based SSO to authenticate Slack users through your corporate identity provider (Okta, Azure AD, OneLogin, Ping Identity). This centralizes authentication and enables MFA enforcement through your IdP.

#### Rationale
**Why This Matters:**
- Centralizes authentication management
- Enables Conditional Access, MFA, and risk-based policies
- Automatic deprovisioning when users leave the organization
- Eliminates standalone Slack passwords

**Attack Prevented:** Credential theft, password reuse, orphaned accounts

#### Prerequisites
- Slack Business+ or Enterprise Grid plan
- SAML 2.0 compatible identity provider
- Workspace Owner or Org Admin access

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Slack Admin** → **Settings** → **Authentication**
2. Click **Configure** next to SAML authentication

**Step 2: Configure SAML Provider**
1. Enter your Identity Provider details:
   - **SAML SSO URL:** Your IdP's SSO endpoint
   - **Identity Provider Issuer:** IdP entity ID
   - **Public Certificate:** X.509 certificate from IdP
2. Configure options:
   - **Sign AuthnRequest:** Yes (recommended)
   - **Service Provider Issuer:** Your Slack workspace URL

**Step 3: Configure IdP (Example: Okta)**
1. In Okta Admin Console: **Applications** → **Add Application** → Search "Slack"
2. Configure SAML settings using Slack's metadata
3. Assign users/groups to the Slack application
4. Enable SCIM provisioning for automatic user management

**Step 4: Enforce SSO**
1. Return to Slack Authentication settings
2. Under **SSO settings**, select **SAML SSO Required**
3. This prevents password-based sign-in

**Time to Complete:** ~1 hour (depending on IdP complexity)

#### Code Implementation

{% include pack-code.html vendor="slack" section="1.1" %}

#### Validation & Testing
**How to verify the control is working:**
1. [ ] Attempt to sign in - should redirect to IdP
2. [ ] Verify MFA prompt from IdP
3. [ ] Confirm password-only sign-in is blocked
4. [ ] Test user deprovisioning from IdP removes Slack access

**Expected result:** All users authenticate via SSO with MFA enforced by IdP

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-2 | Identification and authentication |
| **ISO 27001** | A.9.4.2 | Secure log-on procedures |
| **HIPAA** | 164.312(d) | Person or entity authentication |

---

### 1.2 Configure SCIM User Provisioning

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Enable SCIM (System for Cross-domain Identity Management) to automatically provision and deprovision Slack users based on your identity provider directory.

#### Rationale
**Why This Matters:**
- Automatic user lifecycle management
- Immediate deprovisioning when employees leave
- Eliminates orphaned accounts
- Reduces manual administration

**Attack Prevented:** Orphaned account abuse, unauthorized access after termination

#### Prerequisites
- Slack Enterprise Grid
- SCIM-compatible identity provider
- Org Admin access

#### ClickOps Implementation

**Step 1: Enable SCIM Provisioning**
1. Navigate to: **Enterprise Grid Admin** → **Settings** → **Authentication**
2. Click **Configure** next to SCIM provisioning
3. Generate SCIM API token
4. Copy the SCIM endpoint URL

**Step 2: Configure IdP**
1. In your IdP, configure SCIM integration with:
   - Base URL: `https://api.slack.com/scim/v1`
   - Authentication: Bearer token (from Step 1)
2. Enable provisioning features:
   - Create users
   - Update user attributes
   - Deactivate users
3. Map user attributes (email, displayName, etc.)

**Time to Complete:** ~30 minutes

#### Validation & Testing
1. [ ] Create user in IdP - verify appears in Slack
2. [ ] Update user in IdP - verify changes sync
3. [ ] Deactivate user in IdP - verify Slack access removed
4. [ ] Verify deprovisioned users cannot sign in

---

### 1.3 Restrict Workspace Admin Roles

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Limit Primary Owner and Admin roles to essential personnel. Use granular roles like Workspace Admins and User Groups Admins for delegated administration.

#### Rationale
**Why This Matters:**
- Primary Owners have unrestricted access
- Admins can modify security settings
- Excessive admin privileges increase risk

#### ClickOps Implementation

**Step 1: Audit Current Admins**
1. Navigate to: **Slack Admin** → **Manage members**
2. Filter by **Account type:** Owners and Admins
3. Document current assignments

**Step 2: Implement Least Privilege**
1. Remove unnecessary Admin/Owner assignments
2. Use specific roles for delegated tasks:
   - **Workspace Admin:** Manage workspace settings
   - **User Groups Admin:** Manage user groups only
   - **Billing Admin:** Manage billing only

**Step 3: Enable Admin Approval for Role Changes**
1. Navigate to: **Settings** → **Permissions**
2. Configure approval workflow for admin role assignments

---

### 1.4 Configure Session Management

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.3 |
| NIST 800-53 | AC-11, AC-12 |

#### Description
Configure session duration controls to automatically log out inactive users and limit session lifetime.

#### ClickOps Implementation

**Step 1: Configure Session Duration**
1. Navigate to: **Enterprise Grid Admin** → **Settings** → **Authentication**
2. Under **Session duration**, configure:
   - **Web sessions:** 24 hours (or less for sensitive environments)
   - **Mobile sessions:** 30 days (balance security/usability)
3. Enable **Force logout after duration**

**Step 2: Enable Forced Logout**
1. In Authentication settings
2. Enable **Sign out users from all devices after inactivity**
3. Configure inactivity timeout (e.g., 4 hours)

---

## 2. Network Access Controls

### 2.1 Configure Approved IP Ranges

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17, SC-7 |

#### Description
Restrict Slack access to approved IP ranges (corporate network, VPN) to prevent unauthorized access from unknown locations.

#### Prerequisites
- Slack Enterprise Grid
- Known corporate egress IP ranges

#### ClickOps Implementation

**Step 1: Configure IP Allowlist**
1. Navigate to: **Enterprise Grid Admin** → **Settings** → **Authentication**
2. Click **IP allowlist**
3. Add approved IP ranges (CIDR notation)
4. Enable **Require sign-in from approved IPs only**

**Step 2: Configure Exceptions**
1. Optionally allow specific users (executives, remote workers) bypass
2. Document business justification for exceptions

---

## 3. OAuth & Integration Security

### 3.1 Restrict App Installation and Approval

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | AC-3, CM-7 |

#### Description
Control which Slack apps and integrations can be installed. Require admin approval for new app installations and regularly audit existing apps.

#### Rationale
**Why This Matters:**
- Slack apps can access messages, files, and user data
- Malicious apps can exfiltrate sensitive information
- OAuth tokens provide persistent access

**Attack Prevented:** Malicious app installation, data exfiltration, unauthorized integrations

#### Prerequisites
- Slack Business+ or Enterprise Grid
- Workspace Owner or Admin access
- App approval workflow defined

#### ClickOps Implementation

**Step 1: Configure App Management**
1. Navigate to: **Slack Admin** → **Manage apps**
2. Click **App Management Settings**
3. Configure:
   - **Who can install apps:** Only Admins
   - **App approval:** Require admin approval for all new apps
   - **Pre-approved apps:** Define list of vetted apps

**Step 2: Review Existing Apps**
1. In **Manage apps**, review all installed apps
2. For each app, review:
   - Requested permissions/scopes
   - Data access level
   - Last used date
3. Remove unused or risky apps

**Step 3: Configure App Approval Workflow**
1. Under **App approval settings**
2. Configure reviewers (Security team)
3. Enable notification for new requests
4. Set up app review criteria

**Time to Complete:** ~45 minutes

#### Code Implementation

{% include pack-code.html vendor="slack" section="3.1" %}

#### Validation & Testing
1. [ ] Attempt to install unapproved app - verify blocked
2. [ ] Submit app approval request - verify workflow triggers
3. [ ] Verify pre-approved apps can be installed
4. [ ] Audit existing apps for excessive permissions

---

### 3.2 Manage Slack Connect (External Collaboration)

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-22, SC-7 |

#### Description
Control Slack Connect channels that enable collaboration with external organizations. Require approval for external connections and define allowed organizations.

#### Rationale
**Why This Matters:**
- Slack Connect enables data sharing with external parties
- Unauthorized connections can lead to data leakage
- External parties may have different security postures

#### ClickOps Implementation

**Step 1: Configure Slack Connect Permissions**
1. Navigate to: **Slack Admin** → **Settings** → **Slack Connect**
2. Configure:
   - **Who can create Slack Connect channels:** Only Admins
   - **Require approval for:** All external connections
   - **Allowed organizations:** Whitelist approved partners

**Step 2: Configure Data Loss Prevention for Connect**
1. Apply DLP rules to Slack Connect channels
2. Block sensitive data sharing to external channels

**Step 3: Configure Guest Access**
1. Navigate to: **Settings** → **Guest access**
2. Configure guest account restrictions
3. Limit guest access to specific channels

---

## 4. Data Security

### 4.1 Enable Data Loss Prevention (DLP)

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.2 |
| NIST 800-53 | SC-8, SC-28 |

#### Description
Configure Slack's native DLP to detect and prevent sharing of sensitive information like credit card numbers, SSNs, API keys, and confidential documents.

#### Rationale
**Why This Matters:**
- Credentials and API keys are frequently shared in Slack
- Sensitive PII can be accidentally posted
- DLP provides automated protection

**Limitations:**
- Native DLP does not scan inside files or images
- Cannot redact portions of messages (only delete entire message)
- Consider third-party DLP for advanced capabilities

#### Prerequisites
- Slack Enterprise Grid with GovSlack or Compliance add-on
- DLP Admin role

#### ClickOps Implementation

**Step 1: Access DLP Settings**
1. Navigate to: **Enterprise Grid Admin** → **Security** → **Data Loss Prevention**
2. Click **Create rule**

**Step 2: Create DLP Rule**
1. Configure rule:
   - **Name:** Block credit card sharing
   - **Detection:** Use regex or predefined patterns
   - **Scope:** All workspaces or specific channels
   - **Actions:** Warn user, tombstone message, alert admin
2. Save rule

**Step 3: Configure Predefined Rules**
1. Enable predefined rules for:
   - Credit card numbers
   - Social Security numbers
   - Bank account numbers
   - Custom patterns (API keys, internal project names)

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="slack" section="4.1" %}

#### Validation & Testing
1. [ ] Send test message with fake credit card number
2. [ ] Verify DLP rule triggers
3. [ ] Confirm admin receives alert
4. [ ] Test that legitimate content is not blocked

---

### 4.2 Configure Message Retention Policies

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.4 |
| NIST 800-53 | SI-12, AU-11 |

#### Description
Configure message and file retention policies to balance compliance requirements with data minimization. Enable legal holds for litigation preservation.

#### Rationale
**Why This Matters:**
- Regulatory compliance may require specific retention periods
- Data minimization reduces breach impact
- Legal holds prevent destruction of relevant evidence

#### Prerequisites
- Slack Business+ or Enterprise Grid
- Defined retention requirements per regulation

#### ClickOps Implementation

**Step 1: Configure Default Retention**
1. Navigate to: **Slack Admin** → **Settings** → **Retention & Exports**
2. Configure workspace-wide defaults:
   - **Messages:** Keep all, or delete after X days
   - **Files:** Keep all, or delete after X days
3. Consider compliance requirements:
   - **FINRA:** 3-6 years
   - **HIPAA:** 6 years
   - **SOX:** 7 years

**Step 2: Configure Per-Channel Retention**
1. Override retention for specific channels
2. Shorter retention for informal channels
3. Longer retention for compliance-relevant channels

**Step 3: Enable Legal Holds**
1. Navigate to: **Security** → **Legal holds**
2. Create hold for specific users, channels, or date ranges
3. Legal holds override retention policies

**Time to Complete:** ~30 minutes

---

### 4.3 Enable Enterprise Key Management (EKM)

**Profile Level:** L3 (Maximum Security)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12, SC-28 |

#### Description
Deploy Slack Enterprise Key Management to use your own AWS KMS keys for encrypting Slack messages and files, providing customer-controlled encryption.

#### Prerequisites
- Slack Enterprise Grid
- AWS account with KMS
- Additional licensing for EKM

#### ClickOps Implementation

**Step 1: Set Up AWS KMS**
1. Create KMS key in AWS
2. Configure key policy for Slack access
3. Note key ARN

**Step 2: Configure EKM in Slack**
1. Navigate to: **Enterprise Grid Admin** → **Security** → **Encryption**
2. Click **Configure Enterprise Key Management**
3. Enter AWS KMS key ARN
4. Complete verification process

---

## 5. Monitoring & Detection

### 5.1 Enable Audit Logs

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-3, AU-6 |

#### Description
Enable and export Slack audit logs for security monitoring, incident investigation, and compliance. Integrate with SIEM for automated threat detection.

#### Rationale
**Why This Matters:**
- Audit logs capture admin actions, authentication events, and data access
- Essential for incident investigation
- Required for most compliance frameworks

#### Prerequisites
- Slack Enterprise Grid
- SIEM or log management platform

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Enterprise Grid Admin** → **Security** → **Audit logs**
2. Review available log categories:
   - User actions
   - Workspace settings
   - App installations
   - File access
   - Channel management

**Step 2: Configure Log Export**
1. Click **Export logs**
2. Configure export destination:
   - Amazon S3 bucket
   - Direct API integration with SIEM
3. Set export frequency (real-time or scheduled)

**Step 3: Integrate with SIEM**
1. Use Slack Audit Logs API for real-time streaming
2. Configure alerts for critical events

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="slack" section="5.1" %}

#### Key Events to Monitor

| Event | Description | Detection Use Case |
|-------|-------------|-------------------|
| `user_login_failed` | Failed authentication | Brute force attempts |
| `role_change_to_admin` | Admin role assigned | Privilege escalation |
| `app_installed` | New app installed | Malicious app detection |
| `file_downloaded` | File downloaded | Data exfiltration |
| `channel_created` | New channel created | Shadow IT detection |
| `message_tombstoned` | Message deleted by DLP | Policy violations |

---

## 6. Third-Party Integration Security

### 6.1 Integration Risk Assessment Matrix

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **Data Access** | Read channel list only | Read messages in public channels | Read all messages + files |
| **OAuth Scopes** | Limited scopes | Broad read access | Write access, admin scopes |
| **Data Retention** | No data storage | Temporary storage | Permanent storage |
| **Vendor Security** | SOC 2 Type II + ISO | SOC 2 Type I | No certification |

### 6.2 Common Integrations and Recommended Controls

#### Obsidian Security
**Data Access:** Read (messages, channels, users, audit logs)
**Recommended Controls:**
- ✅ Use dedicated bot user
- ✅ Grant minimum required OAuth scopes
- ✅ Review access quarterly
- ✅ Monitor API usage via audit logs

#### Zoom
**Data Access:** Low (meeting links, calendar)
**Recommended Controls:**
- ✅ Limit to meeting creation only
- ✅ Disable automatic meeting recording sharing

#### Google Drive / Dropbox
**Data Access:** Medium (file sharing)
**Recommended Controls:**
- ✅ Control which files can be shared
- ✅ Apply DLP to file sharing
- ✅ Monitor for sensitive file sharing

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Slack Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | SSO/SAML authentication | [1.1](#11-enable-saml-single-sign-on-sso) |
| CC6.1 | App approval controls | [3.1](#31-restrict-app-installation-and-approval) |
| CC6.2 | Admin role restrictions | [1.3](#13-restrict-workspace-admin-roles) |
| CC6.6 | Slack Connect controls | [3.2](#32-manage-slack-connect-external-collaboration) |
| CC7.2 | Audit logging | [5.1](#51-enable-audit-logs) |

### NIST 800-53 Rev 5 Mapping

| Control | Slack Control | Guide Section |
|---------|---------------|---------------|
| IA-2 | SAML SSO | [1.1](#11-enable-saml-single-sign-on-sso) |
| AC-2 | SCIM provisioning | [1.2](#12-configure-scim-user-provisioning) |
| AC-6(1) | Least privilege admin | [1.3](#13-restrict-workspace-admin-roles) |
| SC-28 | DLP / EKM | [4.1](#41-enable-data-loss-prevention-dlp), [4.3](#43-enable-enterprise-key-management-ekm) |
| AU-2 | Audit logging | [5.1](#51-enable-audit-logs) |

### HIPAA Security Rule Mapping

| Requirement | Slack Control | Guide Section |
|-------------|---------------|---------------|
| 164.312(d) | SSO authentication | [1.1](#11-enable-saml-single-sign-on-sso) |
| 164.312(b) | Audit controls | [5.1](#51-enable-audit-logs) |
| 164.312(c)(1) | Integrity controls | [4.1](#41-enable-data-loss-prevention-dlp) |
| 164.312(e)(1) | Transmission security | [4.3](#43-enable-enterprise-key-management-ekm) |

---

## Appendix A: Edition/Tier Compatibility

| Control | Free | Pro | Business+ | Enterprise Grid |
|---------|------|-----|-----------|-----------------|
| 2FA (local) | ✅ | ✅ | ✅ | ✅ |
| SAML SSO | ❌ | ❌ | ✅ | ✅ |
| SCIM Provisioning | ❌ | ❌ | ❌ | ✅ |
| App Management | Basic | Basic | ✅ | ✅ |
| Data Loss Prevention | ❌ | ❌ | ❌ | ✅ |
| Enterprise Key Management | ❌ | ❌ | ❌ | ✅ |
| Custom Retention | ❌ | ❌ | ✅ | ✅ |
| Audit Logs API | ❌ | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Slack Documentation:**
- [Trust Center / Security](https://slack.com/trust/security)
- [Help Center](https://slack.com/help)
- [Security Tips to Protect Your Workspace](https://slack.com/help/articles/115004155306-Security-tips-to-protect-your-workspace)
- [Security Practices](https://slack.com/security-practices)
- [Manage Single Sign-On Settings](https://slack.com/help/articles/220403548-Manage-single-sign-on-settings)
- [Introduction to Enterprise Grid](https://slack.com/resources/why-use-slack/slack-enterprise-grid)
- [Enterprise Grid Admin Guide](https://slack.com/help/articles/360004150931)

**API & Developer Tools:**
- [Slack API Documentation](https://docs.slack.dev/apis/)
- [Legacy API Reference](https://api.slack.com/)
- [Audit Logs API](https://api.slack.com/admins/audit-logs)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO 27001, ISO 27017, ISO 27018, APEC PRP, APEC CBPR -- via [Trust Center / Compliance](https://slack.com/trust/compliance)
- [HIPAA Compliance on Slack](https://slack.com/trust/compliance/hipaa)
- [FedRAMP Moderate (Slack), FedRAMP High JAB (GovSlack)](https://slack.com/trust/compliance/fedramp)
- GDPR, CCPA/CPRA, FINRA compliant -- via [Compliance Resources](https://slack.com/trust/compliance)

**Security Incidents:**
- (2022-12) Stolen Slack employee tokens used to access externally hosted GitHub repositories. No customer data affected.
- (2022-07) A vulnerability transmitted hashed user passwords to other workspace members; approximately 0.5% of users required password resets.
- (2024-07) Credential-stuffing attack using leaked credentials granted unauthorized access to employee accounts and sensitive corporate data. Disclosed July 12, 2024.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, DLP, retention, and app controls | Claude Code (Opus 4.5) |
| 2026-02-19 | 0.1.1 | draft | Extract inline code to Code Packs (SDK, Terraform, API) | Claude Code (Opus 4.6) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
