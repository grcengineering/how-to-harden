---
layout: guide
title: "ChatGPT Enterprise Hardening Guide"
vendor: "OpenAI"
slug: "chatgpt-enterprise"
tier: "1"
category: "Productivity"
description: "Enterprise AI security hardening for ChatGPT, SSO configuration, data privacy, and admin controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

ChatGPT Enterprise is OpenAI's enterprise-grade AI assistant serving organizations that require enhanced security, privacy, and administrative controls. With AI adoption accelerating across enterprises, properly securing ChatGPT Enterprise is critical to prevent data leakage, maintain compliance, and ensure responsible AI usage. Unlike consumer versions, Enterprise provides SOC 2 Type II compliance, data isolation, and guarantees that prompts and outputs are not used for model training.

### Intended Audience
- Security engineers managing AI tools
- IT administrators configuring ChatGPT Enterprise
- GRC professionals assessing AI compliance
- Third-party risk managers evaluating AI tools

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers ChatGPT Enterprise security configurations including SSO/SAML, user management, data privacy controls, GPT restrictions, and compliance settings.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Data Security & Privacy](#2-data-security--privacy)
3. [GPT & App Controls](#3-gpt--app-controls)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Third-Party Integration Security](#5-third-party-integration-security)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML-based SSO to authenticate ChatGPT Enterprise users through your corporate identity provider (Okta, Azure AD, OneLogin). This centralizes authentication and enables MFA enforcement.

#### Rationale
**Why This Matters:**
- Centralizes authentication and user lifecycle management
- Enables Conditional Access and MFA through IdP
- Automatic deprovisioning when users leave organization
- Eliminates standalone ChatGPT passwords

**Attack Prevented:** Credential theft, unauthorized access, orphaned accounts

#### Prerequisites
- [ ] ChatGPT Enterprise subscription
- [ ] SAML 2.0 compatible identity provider
- [ ] Workspace Owner access

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **ChatGPT Admin Console** → **Settings** → **Authentication**
2. Click **Configure SSO**

**Step 2: Configure SAML**
1. Enter Identity Provider details:
   - **SSO URL:** Your IdP's SSO endpoint
   - **Entity ID:** IdP entity ID
   - **Certificate:** X.509 certificate from IdP
2. Download ChatGPT's Service Provider metadata for IdP configuration
3. Map user attributes (email, name)

**Step 3: Configure IdP (Example: Okta)**
1. In Okta Admin: **Applications** → **Add Application**
2. Select SAML 2.0 integration
3. Enter ChatGPT's ACS URL and Entity ID
4. Configure attribute statements:
   - email → user.email
   - name → user.displayName
5. Assign users/groups

**Step 4: Enable SSO Enforcement**
1. Return to ChatGPT Authentication settings
2. Enable **Require SSO for all users**
3. Test login before enforcing

**Time to Complete:** ~1 hour

#### Validation & Testing
1. [ ] Test SSO sign-in through IdP
2. [ ] Verify MFA is enforced (via IdP)
3. [ ] Confirm direct password login is disabled
4. [ ] Test user deprovisioning from IdP

---

### 1.2 Enable Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Enforce multi-factor authentication for all ChatGPT Enterprise users. With SSO, MFA should be enforced through your identity provider. For non-SSO deployments, enable ChatGPT's native TOTP-based MFA.

#### ClickOps Implementation

**Option A: MFA via SSO (Recommended)**
1. Configure MFA in your identity provider
2. Create Conditional Access policy requiring MFA for ChatGPT app
3. All ChatGPT access will require MFA through IdP

**Option B: Native MFA (Non-SSO)**
1. Navigate to: **Admin Console** → **Settings** → **Authentication**
2. Enable **Require multi-factor authentication**
3. Users will be prompted to enroll in TOTP-based MFA

---

### 1.3 Configure SCIM User Provisioning

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Enable SCIM (System for Cross-domain Identity Management) for automatic user provisioning and deprovisioning synced with your identity provider.

#### Rationale
**Why This Matters:**
- Automatic user lifecycle management
- Immediate deprovisioning when employees leave
- Eliminates orphaned accounts
- Ensures consistent group memberships

#### ClickOps Implementation

**Step 1: Enable SCIM**
1. Navigate to: **Admin Console** → **Settings** → **User provisioning**
2. Click **Enable SCIM**
3. Copy the SCIM endpoint URL and generate API token

**Step 2: Configure IdP**
1. In your IdP, configure SCIM integration
2. Enter ChatGPT's SCIM endpoint URL
3. Enter the API token for authentication
4. Enable provisioning actions:
   - Create users
   - Update users
   - Deactivate users
5. Map user attributes

**Time to Complete:** ~30 minutes

---

### 1.4 Implement Role-Based Access Control

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Configure role-based access using ChatGPT Enterprise's three role types: Owner, Admin, and Member. Limit Owner and Admin roles to essential personnel.

#### Rationale
**Why This Matters:**
- Owners have full access to all settings and data
- Excessive admin privileges increase risk
- Members should be the default role for most users

#### ClickOps Implementation

**Step 1: Review Current Roles**
1. Navigate to: **Admin Console** → **Members**
2. Review current role assignments
3. Document Owners and Admins

**Step 2: Implement Least Privilege**
1. Maintain minimum Owners (1-2 maximum)
2. Assign Admin role only for user management needs
3. Use Member role for all regular users

**Role Definitions:**

| Role | Capabilities |
|------|-------------|
| **Owner** | Full workspace control, billing, SSO configuration |
| **Admin** | User management, usage insights, settings |
| **Member** | Standard ChatGPT access, no admin functions |

---

## 2. Data Security & Privacy

### 2.1 Understand Data Privacy Guarantees

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SC-8, SC-28 |

#### Description
ChatGPT Enterprise provides specific data privacy guarantees that differentiate it from consumer versions. Understanding these guarantees is essential for risk assessment.

#### Key Privacy Features

| Feature | ChatGPT Enterprise | ChatGPT Consumer |
|---------|-------------------|------------------|
| **Training on Data** | ❌ Not used for training | ✅ May be used |
| **Data Encryption at Rest** | ✅ AES-256 | ✅ AES-256 |
| **Data Encryption in Transit** | ✅ TLS 1.2+ | ✅ TLS 1.2+ |
| **SOC 2 Type II** | ✅ Certified | ❌ Not applicable |
| **Enterprise Key Management** | ✅ Available | ❌ Not available |
| **Data Retention Control** | ✅ Configurable | ❌ Standard retention |

#### Data Guarantees
According to OpenAI's Enterprise Privacy commitments:
- **Inputs and outputs are not used for training** OpenAI models
- Organizations **retain ownership** of their data
- Data is encrypted **in transit (TLS 1.2+)** and **at rest (AES-256)**
- Enterprise customers can configure **data retention periods**

---

### 2.2 Configure Data Retention Policies

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.4 |
| NIST 800-53 | SI-12, AU-11 |

#### Description
Configure data retention policies to balance compliance requirements with data minimization principles. Shorter retention reduces breach impact.

#### ClickOps Implementation

**Step 1: Access Retention Settings**
1. Navigate to: **Admin Console** → **Settings** → **Data controls**
2. Click **Retention policy**

**Step 2: Configure Retention**
1. Set conversation retention period:
   - **Indefinite:** Conversations kept until user deletes
   - **90 days:** Auto-delete after 90 days
   - **30 days:** Auto-delete after 30 days (most restrictive)
2. Consider compliance requirements:
   - **FINRA:** May require longer retention for audit trails
   - **GDPR:** Supports data minimization with shorter retention

**Time to Complete:** ~15 minutes

---

### 2.3 Enable Enterprise Key Management (EKM)

**Profile Level:** L3 (Maximum Security)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12, SC-28 |

#### Description
Deploy Enterprise Key Management to use your own encryption keys for ChatGPT data, providing customer-controlled encryption.

#### Prerequisites
- [ ] ChatGPT Enterprise with EKM add-on
- [ ] AWS KMS or compatible key management system

#### ClickOps Implementation

**Step 1: Contact OpenAI**
1. Work with your OpenAI account team to enable EKM
2. Receive EKM configuration instructions

**Step 2: Configure Key Management**
1. Create encryption key in your KMS
2. Configure key policy for OpenAI access
3. Provide key ARN to OpenAI for configuration

---

### 2.4 Establish Acceptable Use Policies

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.2 |
| NIST 800-53 | PL-4 |

#### Description
Create and enforce acceptable use policies that define what data can and cannot be submitted to ChatGPT Enterprise.

#### Rationale
**Why This Matters:**
- Users may inadvertently submit sensitive data
- Even with Enterprise privacy, minimizing exposure is safest
- Clear policies set expectations and enable enforcement

#### Policy Recommendations

**Prohibited Data Types:**
- Personally Identifiable Information (PII)
- Protected Health Information (PHI)
- Payment Card Industry (PCI) data
- Credentials, API keys, passwords
- Proprietary source code (without approval)
- Trade secrets and confidential business records

**Approved Use Cases:**
- General research and information gathering
- Writing assistance (non-confidential content)
- Code explanation and debugging (sanitized)
- Brainstorming and ideation

#### Implementation
1. Document acceptable use policy
2. Require user acknowledgment during onboarding
3. Include in security awareness training
4. Integrate with DLP tools if available

---

## 3. GPT & App Controls

### 3.1 Restrict Third-Party GPT Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | AC-3, CM-7 |

#### Description
Control which GPTs (custom ChatGPT applications) can be used by your organization. By default, all third-party GPTs are disabled in Enterprise.

#### Rationale
**Why This Matters:**
- Third-party GPTs may have different data handling practices
- GPTs can access conversation data based on their configuration
- Restricting to approved GPTs reduces data exposure risk

#### ClickOps Implementation

**Step 1: Access GPT Controls**
1. Navigate to: **Admin Console** → **Settings** → **GPT controls**

**Step 2: Configure GPT Policies**
1. **Third-party GPTs:** Disabled (default, recommended)
2. **Internal GPTs:** Enable for organization-built GPTs only
3. **GPT Store access:** Disabled unless specific need

**Step 3: Whitelist Approved GPTs (if needed)**
1. If specific third-party GPTs are required:
   - Review GPT's privacy policy and data handling
   - Add to approved list
   - Document business justification

**Time to Complete:** ~15 minutes

---

### 3.2 Control App and Plugin Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | AC-3 |

#### Description
Control which ChatGPT features and integrations are available to users. All apps are disabled by default in Enterprise.

#### ClickOps Implementation

**Step 1: Access App Settings**
1. Navigate to: **Admin Console** → **Settings** → **Apps**

**Step 2: Configure App Access**
1. Review each app category:
   - **Code Interpreter:** Enable/disable code execution
   - **Web Browsing:** Enable/disable internet access
   - **Image Generation (DALL-E):** Enable/disable image creation
   - **File Uploads:** Enable/disable file analysis
2. Enable only features required for business use
3. Consider security implications of each:
   - Web browsing may expose queries externally
   - File uploads increase data exposure surface

---

### 3.3 Configure Custom Instructions

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.2 |
| NIST 800-53 | PL-4 |

#### Description
Set organization-wide custom instructions that apply to all conversations, embedding security reminders and usage guidelines.

#### ClickOps Implementation

**Step 1: Access Custom Instructions**
1. Navigate to: **Admin Console** → **Settings** → **Custom instructions**

**Step 2: Configure Organization Instructions**
1. Add security-aware instructions such as:

2. Save and apply to all users

---

## 4. Monitoring & Compliance

### 4.1 Enable Usage Analytics

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-6 |

#### Description
Monitor ChatGPT Enterprise usage through the admin console analytics dashboard for security visibility and compliance reporting.

#### ClickOps Implementation

**Step 1: Access Analytics**
1. Navigate to: **Admin Console** → **Analytics**

**Step 2: Review Key Metrics**
- Active users over time
- Message volume
- Feature usage (code interpreter, web browsing, etc.)
- User adoption trends

**Step 3: Export for Compliance**
1. Export usage data for compliance audits
2. Integrate with enterprise reporting tools

---

### 4.2 Integrate with Microsoft Purview

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SC-8 |

#### Description
For organizations using Microsoft 365, integrate ChatGPT Enterprise with Microsoft Purview for advanced data governance and compliance controls.

#### Prerequisites
- [ ] Microsoft 365 E5 or Purview add-on
- [ ] ChatGPT Enterprise

#### Implementation
1. Configure Purview connector for ChatGPT
2. Apply sensitivity labels to ChatGPT content
3. Enable DLP policies for AI interactions
4. Review Purview compliance dashboard for AI activity

---

### 4.3 Implement Audit Trail Reviews

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | AU-6, AU-7 |

#### Description
Establish regular audit trail reviews to detect policy violations, unusual usage patterns, and potential security incidents.

#### Implementation

**Weekly Reviews:**
- Review analytics for unusual activity spikes
- Check for new user additions outside normal provisioning
- Monitor feature usage trends

**Monthly Reviews:**
- Audit admin role assignments
- Review SSO/SCIM configuration integrity
- Validate retention policy compliance

**Quarterly Reviews:**
- Comprehensive access review
- Policy compliance assessment
- Update acceptable use policies as needed

---

## 5. Third-Party Integration Security

### 5.1 Integration Risk Assessment

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **Data Exposure** | No conversation access | Limited conversation access | Full conversation access |
| **External Services** | No external calls | Limited external APIs | Full internet access |
| **Data Persistence** | No data storage | Temporary storage | Permanent storage |

### 5.2 Approved Integration Patterns

#### Identity Provider Integration (Recommended)
**Data Access:** Authentication only
**Controls:**
- ✅ Configure SAML SSO
- ✅ Enable SCIM provisioning
- ✅ Apply IdP Conditional Access policies

#### Microsoft Purview Integration (Recommended for M365)
**Data Access:** Metadata and classification
**Controls:**
- ✅ Apply sensitivity labels
- ✅ Enable DLP scanning
- ✅ Review compliance reports

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | ChatGPT Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | SSO authentication | [1.1](#11-configure-saml-single-sign-on) |
| CC6.1 | MFA enforcement | [1.2](#12-enable-multi-factor-authentication) |
| CC6.2 | Role-based access | [1.4](#14-implement-role-based-access-control) |
| CC6.6 | Data retention | [2.2](#22-configure-data-retention-policies) |
| CC7.2 | Usage monitoring | [4.1](#41-enable-usage-analytics) |

### NIST 800-53 Rev 5 Mapping

| Control | ChatGPT Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | SAML SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | MFA | [1.2](#12-enable-multi-factor-authentication) |
| AC-2 | User provisioning | [1.3](#13-configure-scim-user-provisioning) |
| AC-6(1) | Least privilege | [1.4](#14-implement-role-based-access-control) |
| SC-28 | Data encryption | [2.1](#21-understand-data-privacy-guarantees) |

### GDPR Considerations

| Requirement | ChatGPT Enterprise Support |
|-------------|---------------------------|
| Data minimization | Configurable retention policies |
| Purpose limitation | Acceptable use policies |
| Data portability | Export functionality |
| Right to erasure | Conversation deletion |
| Security of processing | SOC 2, encryption, access controls |

---

## Appendix A: Edition Comparison

| Feature | ChatGPT Team | ChatGPT Enterprise |
|---------|--------------|-------------------|
| SSO/SAML | ❌ | ✅ |
| SCIM | ❌ | ✅ |
| Data not used for training | ✅ | ✅ |
| Enterprise Key Management | ❌ | ✅ |
| Admin Console | Basic | Full |
| Usage Analytics | Basic | Advanced |
| SOC 2 Type II | ❌ | ✅ |
| Custom data retention | ❌ | ✅ |

---

## Appendix B: References

**Official OpenAI Documentation:**
- [OpenAI Trust Portal](https://trust.openai.com/)
- [Security and Privacy at OpenAI](https://openai.com/security-and-privacy/)
- [Business Data Privacy, Security, and Compliance](https://openai.com/business-data/)
- [ChatGPT Enterprise Help Center](https://help.openai.com/en/collections/5688074-chatgpt-enterprise)
- [Admin Controls: Security and Compliance](https://help.openai.com/en/articles/11509118-admin-controls-security-and-compliance-in-apps-enterprise-edu-and-business)

**API Documentation:**
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference/introduction)
- [Official Python SDK](https://github.com/openai/openai-python)
- [Official Node.js/TypeScript SDK](https://platform.openai.com/docs/libraries)
- [Agents SDK](https://platform.openai.com/docs/guides/agents-sdk)

**Compliance Frameworks:**
- SOC 2 Type II (Security, Availability, Confidentiality, Privacy), ISO 27001:2022, ISO 27017, ISO 27018, ISO 27701 — via [OpenAI Trust Portal](https://trust.openai.com/)

**Security Incidents:**
- **March 2023 — Redis library bug exposed chat titles and payment info.** A bug in the open-source Redis client library allowed some users to see other users' chat history titles and first messages. Payment information of approximately 1.2% of ChatGPT Plus subscribers was also briefly exposed. ([OpenAI Disclosure](https://openai.com/index/march-20-chatgpt-outage/))
- **November 2025 — Vendor (Mixpanel) breach exposed limited business customer data.** Attackers breached OpenAI's third-party analytics vendor Mixpanel, stealing names, emails, locations, and technical system details of business customers. No chat data, API keys, credentials, or payment details were compromised. OpenAI suspended the relationship with Mixpanel and initiated broader vendor security reviews. ([OpenAI Disclosure](https://openai.com/index/mixpanel-incident/))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, data privacy, GPT controls, and compliance | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
