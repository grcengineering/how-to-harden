---
layout: guide
title: "Jira Cloud Hardening Guide"
vendor: "Jira Cloud"
slug: "jira-cloud"
tier: "2"
category: "Productivity"
description: "Issue tracking platform hardening for Atlassian Jira Cloud including SAML SSO, organization security, and access controls"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

Atlassian Jira is a leading issue tracking and project management platform used by **millions of users** for software development, IT service management, and business operations. As a repository for project data and development workflows, Jira security configurations directly impact operational security and compliance.

### Intended Audience
- Security engineers managing Atlassian products
- IT administrators configuring Jira Cloud
- GRC professionals assessing collaboration security
- Organization administrators managing access controls

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Atlassian Jira Cloud security including SAML SSO, organization policies, user provisioning, and access controls via Atlassian Administration.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Organization Security](#2-organization-security)
3. [Access Controls](#3-access-controls)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Jira Cloud users.

#### Rationale
**Why This Matters:**
- Centralizes Jira Cloud authentication in your corporate IdP so MFA, conditional access, and session policies are enforced on every login
- Atlassian-native password logins bypass your IdP controls and are a prime target for credential stuffing and phishing
- Jira projects hold roadmaps, vulnerability tickets, customer issues, and internal workflows that a single compromised login can expose
- SSO gives one place to revoke access instantly when an employee leaves, eliminating standing access through local credentials

**Attack Prevented:** Credential stuffing, phishing, password reuse, MFA bypass

#### Prerequisites
- Atlassian organization with verified domain
- Atlassian Guard Standard subscription
- Organization admin access
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Verify Domain**
1. Navigate to: **admin.atlassian.com**
2. Select your organization
3. Add and verify your domain
4. Domain verification required before SSO setup

**Step 2: Configure Identity Provider**
1. Navigate to: **Security** → **Identity Providers**
2. Select your IdP (Okta, Azure, etc.)
3. Select your Directory

**Step 3: Configure SAML SSO**
1. Under Authenticate users, select **Set up SAML single sign-on**
2. Configure IdP with Atlassian metadata
3. Upload IdP metadata to Atlassian

**Step 4: Test and Enable**
1. Test SSO on smaller group first
2. Verify authentication works
3. Roll out across organization

**Time to Complete:** ~2 hours

---

### 1.2 Configure Authentication Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Create authentication policies to enforce SSO.

#### Rationale
**Why This Matters:**
- Configuring SSO alone does not force users to use it; without a policy, managed users can still authenticate with a local Atlassian password
- Authentication policies bind users from your verified domains to SSO so the IdP controls cannot be sidestepped
- A separate admin fallback policy preserves break-glass recovery so a misconfigured IdP never locks every administrator out
- Policy-level enforcement turns SSO from an option into a guarantee across the whole organization

**Attack Prevented:** SSO bypass, password-based account takeover, IdP-control circumvention, admin lockout

#### ClickOps Implementation

**Step 1: Access Authentication Policies**
1. Navigate to: **Security** → **User security** → **Authentication policies**
2. Review existing policies

**Step 2: Create SSO Policy**
1. Create policy for SSO enforcement
2. Apply to managed users from verified domains
3. Configure policy settings

**Step 3: Configure Admin Fallback**
1. Set up different policy for admin accounts
2. Allows troubleshooting SSO issues
3. Use separate admin accounts for recovery

---

### 1.3 Configure Two-Step Verification

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require two-step verification for all users.

#### Rationale
**Why This Matters:**
- A stolen or guessed password alone is not enough to access Jira when a second factor is required
- Two-step verification is among the most effective controls against automated credential-stuffing and phishing campaigns
- Phishing-resistant factors for administrators raise the bar against real-time proxy and prompt-bombing attacks
- Enforcing 2SV organization-wide closes the gap left by users who would otherwise opt out

**Attack Prevented:** Credential stuffing, phishing, password spraying, account takeover

#### ClickOps Implementation

**Step 1: Configure via Organization**
1. Navigate to: **Security** → **Authentication policies**
2. Enable two-step verification requirement

**Step 2: Configure via IdP**
1. Enable MFA in your identity provider
2. All SSO users subject to IdP MFA
3. Use phishing-resistant methods for admins

**Step 3: Test Configuration**
1. Test on smaller group first
2. Verify before organization-wide rollout
3. Document exceptions

---

### 1.4 Configure SAML JIT Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Enable Just-In-Time provisioning for automatic account creation.

#### Rationale
**Why This Matters:**
- JIT provisioning creates accounts from authoritative IdP identity data rather than manual entry, reducing misconfigured or duplicate accounts
- Attribute and group mapping at login keeps Jira access aligned with the IdP's current role assignments
- Provisioning through SSO means users never receive standalone credentials that could be phished or reused
- Consistent, automated account creation reduces the manual errors that lead to over-privileged or orphaned accounts

**Attack Prevented:** Orphaned accounts, privilege creep, manual provisioning errors, shadow accounts

#### ClickOps Implementation

**Step 1: Enable JIT Provisioning**
1. Configure in SAML settings
2. Users provisioned on first SSO login
3. Accounts created automatically

**Step 2: Configure Attribute Mapping**
1. Map IdP attributes to Atlassian fields
2. Configure group membership
3. Test provisioning flow

---

## 2. Organization Security

### 2.1 Configure Atlassian Guard

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Enable Atlassian Guard for enhanced security features.

#### Rationale
**Why This Matters:**
- Atlassian Guard is the subscription that unlocks SAML SSO, enforced 2SV, audit logging, and data security policies for the organization
- Without Guard, the organization cannot centrally enforce authentication or monitor administrative activity across Jira Cloud
- Guard's security policies let you detect and respond to risky configuration changes and account activity
- It establishes the foundation that nearly every other hardening control in this guide depends on

**Attack Prevented:** Unmonitored access, unenforced authentication, undetected configuration tampering

#### ClickOps Implementation

**Step 1: Subscribe to Atlassian Guard**
1. Navigate to: **admin.atlassian.com**
2. Subscribe to Atlassian Guard Standard
3. Enables SSO and advanced security

**Step 2: Configure Guard Features**
1. Enable security policies
2. Configure audit logging
3. Enable data security features

---

### 2.2 Configure Domain Verification

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Verify domains to claim and manage user accounts.

#### Rationale
**Why This Matters:**
- Domain verification is the prerequisite for claiming employee accounts into organization management and applying SSO and 2SV to them
- Unclaimed accounts on your domain are unmanaged shadow accounts that sit outside your security policies and offboarding process
- Once verified, the organization controls password resets, authentication policy, and deprovisioning for those identities
- Claiming accounts consolidates fragmented identities and eliminates blind spots in your user inventory

**Attack Prevented:** Shadow accounts, unmanaged identities, offboarding gaps, policy evasion

#### ClickOps Implementation

**Step 1: Add Domain**
1. Navigate to: **Directory** → **Domains**
2. Add your organization's domain
3. Complete DNS verification

**Step 2: Claim Accounts**
1. Claim existing accounts using your domain
2. Migrate to organization management
3. Consolidate shadow accounts

---

### 2.3 Configure Organization Admin Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Manage organization administrator access.

#### Rationale
**Why This Matters:**
- Organization admins can change SSO, authentication policies, billing, and user access across every Atlassian product, making the role the highest-value target
- Limiting org admins to a small set and using product admins for narrower tasks applies least privilege and shrinks the blast radius of a compromise
- Regularly reviewing and removing unnecessary admin access prevents privilege accumulation over time
- Fewer highly-privileged accounts means fewer credentials an attacker can phish to seize full control

**Attack Prevented:** Privilege escalation, admin account takeover, excessive standing privilege, insider misuse

#### ClickOps Implementation

**Step 1: Review Organization Admins**
1. Navigate to: **admin.atlassian.com**
2. Review organization administrators
3. Document all admins

**Step 2: Apply Least Privilege**
1. Limit org admins to 2-3 users
2. Use product admins for product-specific management
3. Remove unnecessary admin access

---

## 3. Access Controls

### 3.1 Configure Project Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure project-level permissions for least privilege.

#### Rationale
**Why This Matters:**
- Default permission schemes are often broad, granting users more access to projects, issues, and workflows than their role requires
- Least-privilege permission schemes ensure users can see and modify only the projects relevant to their work
- Assigning permissions through groups rather than individuals keeps access consistent and auditable as people change roles
- Regular access reviews catch permission drift before it becomes a data exposure or tampering risk

**Attack Prevented:** Unauthorized data access, privilege creep, lateral movement, insider data exposure

#### ClickOps Implementation

**Step 1: Review Permission Schemes**
1. Navigate to: **Jira Settings** → **System** → **Permission Schemes**
2. Review default and custom schemes
3. Audit project assignments

**Step 2: Configure Least Privilege**
1. Assign minimum necessary permissions
2. Use groups for permission assignment
3. Regular access reviews

---

### 3.2 Configure External User Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control access for external users and guests.

#### Rationale
**Why This Matters:**
- External users and guests sit outside your identity controls, so unbounded access can expose internal project data to third parties
- Limiting guest capabilities to the minimum needed reduces the data an external account can reach if it is compromised
- Enforcing authentication for Jira Service Management portal customers prevents anonymous or weakly-authenticated access to support data
- Using a separate IdP for external customers keeps their authentication isolated from internal employee identities

**Attack Prevented:** Data leakage to third parties, unauthorized external access, guest-account abuse

#### ClickOps Implementation

**Step 1: Configure Guest Access**
1. Review external user access
2. Configure appropriate permissions
3. Limit capabilities

**Step 2: Configure JSM Portal Access (if applicable)**
1. Configure portal-only customer SSO
2. Enforce authentication for external customers
3. Use separate IdP if needed

---

### 3.3 Configure App Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Control third-party app access and permissions.

#### Rationale
**Why This Matters:**
- Marketplace and third-party apps run with OAuth scopes that can read and modify Jira data, extending your attack surface to each app vendor's security
- A compromised or malicious app with broad scopes can exfiltrate issues, attachments, and user data
- Removing unused apps and limiting scopes to what each app actually needs enforces least privilege on integrations
- Regular app audits catch over-permissioned or abandoned integrations before they become a supply-chain entry point

**Attack Prevented:** Supply-chain compromise, OAuth scope abuse, data exfiltration via integrations, third-party data exposure

#### ClickOps Implementation

**Step 1: Review Installed Apps**
1. Navigate to: **Apps** → **Manage apps**
2. Review all installed apps
3. Remove unnecessary apps

**Step 2: Configure App Permissions**
1. Review app scopes
2. Limit app access to necessary data
3. Audit regularly

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs (requires Atlassian Guard).

#### Rationale
**Why This Matters:**
- Audit logs are the primary record for detecting unauthorized access, privilege changes, and configuration tampering in Jira Cloud
- Without logging of provisioning, permission, and SSO changes, malicious or accidental actions go unnoticed until damage is done
- Exporting logs to external analysis preserves evidence for incident response and meets compliance retention requirements
- Monitoring admin actions and authentication changes provides early warning of an account compromise in progress

**Attack Prevented:** Undetected intrusion, configuration tampering, insider misuse, loss of forensic evidence

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **admin.atlassian.com** → **Security** → **Audit log**
2. Review logged events
3. Export for analysis

**Step 2: Monitor Key Events**
1. User provisioning/deprovisioning
2. Permission changes
3. Admin actions
4. SSO configuration changes

---

### 4.2 Configure Security Alerts

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Configure alerts for security events.

#### Rationale
**Why This Matters:**
- Logs alone are passive; real-time alerts on critical events ensure the security team is notified while a threat can still be contained
- Alerting on admin changes, failed authentication, and policy modifications shortens the window between compromise and response
- Integrating alerts with a SIEM correlates Jira events with the rest of your environment to catch coordinated attacks
- Regular review of alerts ensures findings are acted on rather than accumulating unaddressed

**Attack Prevented:** Delayed incident response, undetected account takeover, slow breach containment

#### ClickOps Implementation

**Step 1: Configure Notifications**
1. Set up alerts for critical events
2. Notify security team
3. Integrate with SIEM if available

**Step 2: Regular Reviews**
1. Weekly security review
2. Address findings promptly
3. Document security posture

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Jira Cloud Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | SSO/2SV | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Admin roles | [2.3](#23-configure-organization-admin-roles) |
| CC6.6 | Authentication policies | [1.2](#12-configure-authentication-policies) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Jira Cloud Control | Guide Section |
|---------|-------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2SV | [1.3](#13-configure-two-step-verification) |
| AC-2 | JIT provisioning | [1.4](#14-configure-saml-jit-provisioning) |
| AC-6 | Permissions | [3.1](#31-configure-project-permissions) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: Plan Compatibility

| Feature | Free | Standard | Premium | Enterprise |
|---------|------|----------|---------|------------|
| SAML SSO | ❌ | ❌ | Requires Guard | ✅ |
| SCIM | ❌ | ❌ | Requires Guard | ✅ |
| Audit Logs | ❌ | ❌ | Requires Guard | ✅ |
| Domain Verification | ❌ | ❌ | ✅ | ✅ |

**Note:** Advanced security features require Atlassian Guard subscription.

---

## Appendix B: References

**Official Atlassian Documentation:**
- [Atlassian Trust Center](https://www.atlassian.com/trust)
- [Jira Software Cloud Support](https://support.atlassian.com/jira-software-cloud/)
- [How to Keep Your Organization Secure](https://support.atlassian.com/security-and-access-policies/docs/how-to-keep-my-organization-secure/)
- [Security Best Practices for Jira](https://support.atlassian.com/jira/kb/how-to-configure-jira-applications-for-security-best-practices/)
- [Understand Atlassian Guard](https://support.atlassian.com/security-and-access-policies/docs/understand-atlassian-guard/)
- [Configure SAML SSO](https://support.atlassian.com/security-and-access-policies/docs/configure-saml-single-sign-on-with-an-identity-provider/)
- [Manage API Tokens](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/)
- [Atlassian Security Advisories](https://www.atlassian.com/trust/security/advisories)

**API & Developer Resources:**
- [Jira Cloud REST API v3](https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/)
- [Security Overview (Developer)](https://developer.atlassian.com/cloud/jira/platform/security-overview/)
- [Atlassian Developer Documentation](https://developer.atlassian.com/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27018 -- via [Atlassian Compliance Resource Center](https://www.atlassian.com/trust/compliance/resources)

**Security Incidents:**
- **CVE-2023-22523 (CVSS 9.8):** Remote code execution in Assets Discovery for Jira Service Management (2023).
- **Credential-stuffing campaigns (2024):** Multiple organizations experienced Jira account takeovers via compromised credentials, with attackers using integrated tools to scrape data. Six public breaches were reported in five months across various Jira customers.
- Atlassian publishes security advisories at [atlassian.com/trust/security/advisories](https://www.atlassian.com/trust/security/advisories).

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, organization security, and access controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
