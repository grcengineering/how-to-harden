---
layout: guide
title: "Drata Hardening Guide"
vendor: "Drata"
slug: "drata"
tier: "2"
category: "Security & Compliance"
description: "Compliance automation platform hardening for Drata including access controls, integration security, and monitoring configuration"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Drata is a leading compliance automation platform helping **thousands of organizations** achieve and maintain SOC 2, ISO 27001, HIPAA, and other compliance certifications. As a central repository for compliance evidence, security controls, and organizational policies, Drata security configurations directly impact the integrity of compliance programs and sensitive audit data.

### Intended Audience
- Security engineers managing compliance programs
- GRC professionals configuring Drata
- IT administrators integrating systems with Drata
- Compliance managers overseeing audit readiness

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Drata platform security including access controls, integration security, policy management, and monitoring configuration.

---

## Table of Contents

1. [Access & Authentication](#1-access--authentication)
2. [Integration Security](#2-integration-security)
3. [Policy & Control Management](#3-policy--control-management)
4. [Monitoring & Auditing](#4-monitoring--auditing)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Access & Authentication

### 1.1 Configure SSO Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication and enforce organizational security policies.

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Settings** → **Security** → **Single Sign-On**
2. Click **Configure SSO**

**Step 2: Configure SAML**
1. Select identity provider type
2. Configure SAML settings:
   - IdP SSO URL
   - IdP Certificate
   - Entity ID
3. Download Drata SP metadata for IdP configuration

**Step 3: Configure IdP**
1. Create SAML application in IdP
2. Configure attribute mappings
3. Assign users/groups

**Step 4: Enable SSO Enforcement**
1. Test SSO authentication
2. Enable **Require SSO** for all users
3. Configure backup admin access

**Time to Complete:** ~1 hour

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all users accessing Drata platform.

#### ClickOps Implementation

**Step 1: Configure MFA Policy**
1. Navigate to: **Settings** → **Security** → **Authentication**
2. Enable **Require MFA for all users**
3. Or enforce MFA through SSO/IdP (recommended)

**Step 2: Verify Admin MFA**
1. Ensure all admin accounts have MFA enabled
2. Verify MFA enrollment status
3. Follow up with non-compliant users

---

### 1.3 Implement Role-Based Access Control

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure role-based access to implement least privilege for Drata users.

#### Rationale
**Why This Matters:**
- Drata contains sensitive compliance evidence
- Limit who can modify controls and policies
- Reduce blast radius of compromised accounts

#### ClickOps Implementation

**Step 1: Review Available Roles**
1. Navigate to: **Settings** → **Team** → **Roles**
2. Review available roles:
   - **Owner:** Full administrative access
   - **Admin:** Administrative functions
   - **Compliance Manager:** Control and policy management
   - **Viewer:** Read-only access

**Step 2: Assign Appropriate Roles**
1. Limit Owner/Admin to essential personnel
2. Use Compliance Manager for GRC team
3. Use Viewer for auditors and stakeholders

**Step 3: Regular Access Reviews**
1. Quarterly review of user access
2. Remove departed employees promptly
3. Document access decisions

---

### 1.4 Restrict Admin Privileges

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Follow CIS Control recommendations for admin privilege management.

#### ClickOps Implementation

**Step 1: Limit Admin Accounts**
1. Identify all users with admin access
2. Reduce to minimum necessary (2-3 admins)
3. Document business justification

**Step 2: Implement MFA for Admins**
1. Ensure all admins have MFA enabled
2. Consider stronger MFA (hardware keys) for admins
3. Verify MFA at every admin login

**Step 3: Monitor Admin Actions**
1. Review admin activity logs regularly
2. Set up alerts for sensitive admin actions
3. Document and analyze admin activities

---

## 2. Integration Security

### 2.1 Configure Integrations with Least Privilege

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-6 |

#### Description
Configure Drata integrations with minimum necessary permissions.

#### Rationale
**Why This Matters:**
- Drata integrates with 200+ systems
- Each integration receives API access to source systems
- Excessive permissions increase risk

#### ClickOps Implementation

**Step 1: Review Integration Permissions**
1. Navigate to: **Integrations** → **Connected**
2. Review each integration's permissions
3. Document required permissions

**Step 2: Configure Minimum Permissions**
1. When connecting integrations:
   - Grant only read permissions when possible
   - Avoid admin-level access unless required
   - Use dedicated service accounts

**Step 3: Regular Integration Audit**
1. Quarterly review of connected integrations
2. Remove unused integrations
3. Re-validate permission requirements

---

### 2.2 Secure Cloud Provider Integrations

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-6 |

#### Description
Securely configure cloud provider (AWS, GCP, Azure) integrations.

#### ClickOps Implementation

**Step 1: Use Dedicated IAM Roles**
1. Create dedicated IAM role for Drata
2. Grant minimum required permissions
3. Enable cross-account access with external ID

**Step 2: AWS Integration Example**
1. Create IAM role with Drata policy
2. Configure trust relationship with Drata account
3. Use external ID for security

**Step 3: Monitor Integration Health**
1. Review integration status regularly
2. Address connection issues promptly
3. Rotate credentials if required

---

### 2.3 Secure Identity Provider Integration

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Securely configure identity provider integrations for user sync and compliance monitoring.

#### ClickOps Implementation

**Step 1: Configure IdP Integration**
1. Navigate to: **Integrations** → **Identity Providers**
2. Connect Okta, Microsoft Entra, Google Workspace, etc.
3. Grant read-only access for user data

**Step 2: Configure User Sync**
1. Enable user synchronization
2. Configure group mappings
3. Set sync frequency

**Step 3: Verify MFA Monitoring**
1. Ensure Drata can read MFA status
2. Configure alerts for MFA compliance
3. Review MFA coverage reports

---

## 3. Policy & Control Management

### 3.1 Manage Policy Templates

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | PL-1 |

#### Description
Properly manage policy templates and maintain version control.

#### ClickOps Implementation

**Step 1: Configure Policies**
1. Navigate to: **Policies**
2. Review pre-built policy templates
3. Customize policies for your organization

**Step 2: Implement Version Control**
1. Use Drata's built-in version history
2. Document policy changes
3. Track policy approvals

**Step 3: Assign Policy Owners**
1. Assign owner to each policy
2. Configure review schedules
3. Track acknowledgments

---

### 3.2 Configure Control Monitoring

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Configure continuous control monitoring for real-time compliance visibility.

#### ClickOps Implementation

**Step 1: Map Controls**
1. Navigate to: **Controls**
2. Review framework-specific controls
3. Map controls to integrations

**Step 2: Configure Tests**
1. Enable automated tests for controls
2. Configure test frequency
3. Set passing thresholds

**Step 3: Configure Remediation**
1. Assign control owners
2. Configure exception workflows
3. Set remediation deadlines

---

### 3.3 Implement Exception Management

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-2 |

#### Description
Properly manage control exceptions and evidence gaps.

#### ClickOps Implementation

**Step 1: Configure Exception Workflow**
1. Navigate to: **Settings** → **Workflows**
2. Configure exception approval workflow
3. Set up required approvers

**Step 2: Document Exceptions**
1. Require justification for exceptions
2. Set expiration dates
3. Configure compensating controls

**Step 3: Track Remediation**
1. Monitor exception remediation
2. Send reminders for approaching deadlines
3. Report on exception trends

---

## 4. Monitoring & Auditing

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs for security events.

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Settings** → **Audit Log**
2. Review logged events:
   - User login/logout
   - Policy changes
   - Control modifications
   - Integration changes

**Step 2: Export Logs**
1. Configure log export
2. Integrate with SIEM if available
3. Set retention policies

**Key Events to Monitor:**
- Admin role changes
- Policy modifications
- Integration configuration changes
- Control status changes
- Exception approvals

---

### 4.2 Configure Alert Notifications

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Configure alerts for compliance and security events.

#### ClickOps Implementation

**Step 1: Configure Alerts**
1. Navigate to: **Settings** → **Notifications**
2. Configure alerts for:
   - Control failures
   - Integration disconnections
   - Evidence gaps
   - Policy acknowledgment due

**Step 2: Configure Recipients**
1. Set notification recipients
2. Configure escalation paths
3. Integrate with Slack/Teams

---

### 4.3 Monitor Compliance Dashboard

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Regularly monitor compliance dashboard for drift and issues.

#### ClickOps Implementation

**Step 1: Review Dashboard**
1. Navigate to: **Dashboard**
2. Review compliance posture
3. Identify failing controls

**Step 2: Track Trends**
1. Monitor compliance score trends
2. Identify recurring issues
3. Prioritize remediation efforts

**Step 3: Prepare for Audits**
1. Use evidence collection
2. Export audit packages
3. Review auditor access

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Drata Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-sso-authentication) |
| CC6.2 | RBAC | [1.3](#13-implement-role-based-access-control) |
| CC6.6 | Integration security | [2.1](#21-configure-integrations-with-least-privilege) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |
| CC7.3 | Control monitoring | [3.2](#32-configure-control-monitoring) |

### NIST 800-53 Rev 5 Mapping

| Control | Drata Control | Guide Section |
|---------|---------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-sso-authentication) |
| IA-2(1) | MFA | [1.2](#12-enforce-multi-factor-authentication) |
| AC-6 | Least privilege | [1.3](#13-implement-role-based-access-control) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |
| CA-7 | Continuous monitoring | [3.2](#32-configure-control-monitoring) |

---

## Appendix A: References

**Official Drata Documentation:**
- [Trust Center (SafeBase)](https://trust.drata.com/)
- [Drata Security](https://drata.com/security)
- [Drata Help Center](https://help.drata.com/en/)
- [System Access Control Policy Guidance](https://help.drata.com/en/articles/7211097-system-access-control-policy-guidance)
- [Platform Overview](https://drata.com/platform)
- [CIS v8.1 Framework Overview](https://help.drata.com/en/articles/11145651-cis-v8-1-framework-overview)

**API & Developer Documentation:**
- [Drata API Documentation](https://developers.drata.com/api-docs/)

**Compliance Frameworks:**
- SOC 3, ISO 27001:2022, ISO 27017, ISO 27018, ISO 42001:2023 — via [Trust Center](https://trust.drata.com/)
- HIPAA, CCPA, GDPR compliant
- CISA Secure-by-Design Pledge holder
- AWS Qualified Software and AWS Security Software Competency Partner

**Security Incidents:**
- No major public security incidents identified affecting the Drata platform.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with access controls, integrations, and monitoring | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
