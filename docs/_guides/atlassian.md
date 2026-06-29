---
layout: guide
title: "Atlassian Cloud Hardening Guide"
vendor: "Atlassian Cloud"
slug: "atlassian"
tier: "2"
category: "Productivity"
description: "Jira/Confluence security for organization policies, app controls, and data residency"
version: "0.2.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

Atlassian serves **300,000+ customers** with the Atlassian Marketplace hosting **6,000+ apps**. OAuth 2.0, Connect (JWT), and Forge app frameworks create multiple attack vectors. Critical RCE vulnerabilities (CVE-2023-22515, CVSS 10.0; CVE-2022-26134, CVSS 9.8) demonstrated server-side risks. Cloud instances face OAuth token and AppLinks impersonation attacks from compromised Marketplace apps.

### Intended Audience
- Security engineers managing Atlassian products
- IT administrators configuring Jira and Confluence
- GRC professionals assessing collaboration tool security
- Third-party risk managers evaluating Marketplace apps

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Atlassian Cloud and Data Center security configurations including authentication, Marketplace app governance, API security, and AppLinks hardening.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Marketplace App Security](#2-marketplace-app-security)
3. [API & Integration Security](#3-api--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Vulnerability Management](#6-vulnerability-management)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all Atlassian Cloud access, eliminating local password authentication.

#### Rationale
**Why This Matters:**
- Jira contains vulnerability tracking and security issues
- Confluence stores technical documentation and architecture
- Compromised access exposes sensitive project information

**Attack Scenario:** Compromised Marketplace app accesses Jira vulnerability tracking and Confluence technical documentation.

#### ClickOps Implementation (Atlassian Cloud)

**Step 1: Configure SAML SSO**
1. Navigate to: **admin.atlassian.com → Security → SAML single sign-on**
2. Click **Add SAML configuration**
3. Configure:
   - **Identity provider:** Your IdP (Okta, Azure AD, etc.)
   - **Entity ID:** From IdP
   - **SSO URL:** IdP login endpoint
4. Upload IdP certificate

**Step 2: Enforce SSO**
1. Navigate to: **Security → Authentication policies**
2. Create policy:
   - **Name:** "SSO Required"
   - **Members:** All users
   - **Settings:**
     - Require SSO: Enabled
     - Allow local passwords: Disabled

**Step 3: Configure Two-Step Verification**
1. Navigate to: **Security → Two-step verification**
2. Enable: **Require two-step verification for all users**
3. Configure:
   - **Enforcement:** Required
   - **Grace period:** None (L2)

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(1) | MFA for network access |

---

### 1.2 Implement Granular Product Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure product-level and project-level access controls.

#### Rationale
**Why This Matters:**
- Default-open product and project access lets every licensed user read every Jira project and Confluence space, far beyond what their role requires
- Granular permission schemes enforce least privilege so a compromised account or insider only reaches the projects and spaces explicitly granted
- Disabling anonymous Confluence access prevents unauthenticated readers from harvesting internal documentation, architecture diagrams, and secrets pasted into pages
- Limiting browse and comment permissions per project contains the blast radius when a single account is phished

**Attack Prevented:** Lateral movement, privilege creep, insider data harvesting, anonymous information disclosure

#### ClickOps Implementation

**Step 1: Configure Product Access**
1. Navigate to: **admin.atlassian.com → Products**
2. For each product, configure:
   - **Default access:** Disabled (users must be granted access)
   - **User access:** Specific groups only

**Step 2: Configure Jira Project Permissions**
1. Navigate to: **Jira → Project settings → Permissions**
2. Use permission schemes:
   - **Secure Project Scheme:** Limited browse, restricted commenting
   - **Internal Project Scheme:** Standard internal access
   - **Public Project Scheme:** Read-only for wider team

**Step 3: Configure Confluence Space Permissions**
1. Navigate to: **Confluence → Space settings → Permissions**
2. Configure:
   - **Anonymous access:** Disabled
   - **Group permissions:** Specific groups per space
   - **Default permissions:** View only for most users

---

### 1.3 Configure API Token Policies

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Control API token creation and implement expiration policies.

#### Rationale
**Why This Matters:**
- API tokens authenticate as the user and bypass interactive SSO and MFA, so an exposed token is a standing credential carrying the full access of its owner
- Non-expiring tokens linger in scripts, CI systems, and developer laptops indefinitely, granting attackers persistent access long after a credential leaks
- Restricting who can mint tokens and forcing short expiration shrinks the window an exfiltrated token remains valid
- Auditing and revoking unused tokens removes forgotten credentials that attackers routinely find in code repositories and config files

**Attack Prevented:** Token theft, MFA bypass, persistent unauthorized access, credential sprawl

#### ClickOps Implementation

**Step 1: Configure Token Settings**
1. Navigate to: **admin.atlassian.com → Security → API tokens**
2. Configure:
   - **Allow users to create API tokens:** Controlled (Premium/Enterprise)
   - **Token expiration:** 90 days maximum

**Step 2: Audit Existing Tokens**
1. Navigate to: **Security → API tokens → Token controls**
2. Review active tokens
3. Revoke unused or suspicious tokens

---

## 2. Marketplace App Security

### 2.1 Implement App Approval Workflow

**Profile Level:** L1 (Crawl) - CRITICAL
**NIST 800-53:** CM-7

#### Description
Require admin approval for Marketplace app installation. Apps have broad access to Jira/Confluence data.

#### Rationale
**Why This Matters:**
- 6,000+ Marketplace apps with varying security postures
- Apps access project data, user information, and configurations
- Compromised or malicious apps enable data exfiltration

#### ClickOps Implementation

**Step 1: Configure App Installation Policy**
1. Navigate to: **admin.atlassian.com → Security → App policies**
2. Configure:
   - **Who can install apps:** Admins only
   - **User install requests:** Require approval
   - **App block list:** Add prohibited apps

**Step 2: Review Existing Apps**
1. Navigate to: **admin.atlassian.com → Apps**
2. For each app, review:
   - Permissions/scopes requested
   - Last updated date
   - Security certifications
   - User count and reviews
3. Remove unused or suspicious apps

**Step 3: Create App Evaluation Checklist**
Before approving any app:
- Review requested permissions (OAuth scopes)
- Check vendor security certifications (SOC 2, ISO 27001)
- Review app update frequency
- Check for known vulnerabilities
- Evaluate data access requirements
- Document business justification

#### Marketplace App Risk Assessment

| Permission | Risk Level | Questions to Ask |
|------------|------------|------------------|
| Read Jira issues | Medium | Which projects? |
| Write Jira issues | High | Can it delete? |
| Read Confluence content | Medium | Which spaces? |
| Admin access | Critical | Why needed? |
| User management | Critical | Business justification? |
| Act on behalf of users | High | What actions? |

---

### 2.2 Monitor App Activity

**Profile Level:** L2 (Walk)
**NIST 800-53:** AU-6

#### Description
Monitor Marketplace app API calls and data access.

#### Rationale
**Why This Matters:**
- Installed apps run with broad delegated scopes and can read or move large volumes of Jira and Confluence data without a human in the loop
- A compromised or malicious app behaves like a legitimate integration, so its abuse is invisible without monitoring API call patterns
- Baselining normal app data-access volume surfaces sudden bulk reads or exports that indicate exfiltration in progress
- Activity logs give responders the evidence to scope and revoke a rogue app before it drains an entire instance

**Attack Prevented:** Malicious app data exfiltration, supply-chain abuse, undetected bulk export

#### Code Implementation

{% include pack-code.html vendor="atlassian" section="2.2" %}

---

## 3. API & Integration Security

### 3.1 Secure AppLinks Configuration

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-8

#### Description
Harden AppLinks between Atlassian products to prevent impersonation attacks.

#### Rationale
**Why This Matters:**
- AppLinks establish trust between Atlassian products, and a misconfigured link lets one application impersonate users on another
- OAuth 1.0a and unverified trust directions allow an attacker who controls one linked system to forge requests the trusting system accepts as authenticated
- Auditing and removing stale AppLinks eliminates standing trust relationships to systems that are no longer maintained or have changed ownership
- Restricting AppLink creation to administrators prevents an attacker or insider from quietly establishing a trusted impersonation channel

**Attack Prevented:** User impersonation, cross-product request forgery, trust-relationship abuse

#### ClickOps Implementation (Data Center)

**Step 1: Audit Existing AppLinks**
1. Navigate to: **Administration → Application links**
2. Review all configured links
3. Verify each link is still needed

**Step 2: Configure OAuth 2.0 for AppLinks**
1. For each AppLink, configure:
   - **Authentication type:** OAuth 2.0 (not OAuth 1.0a)
   - **Incoming/Outgoing trust:** Verify both directions

**Step 3: Restrict AppLinks Creation**
- Limit AppLinks creation to administrators only
- Document approved integration patterns

---

### 3.2 Configure Webhook Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-8

#### Description
Secure webhook configurations to prevent data leakage.

#### Rationale
**Why This Matters:**
- Webhooks push issue and page data to external URLs automatically, so a hostile or hijacked endpoint receives a continuous feed of internal content
- Without HTTPS, webhook payloads traverse the network in cleartext and can be intercepted in transit
- Missing signature validation lets an attacker spoof webhook calls to downstream services or replay captured payloads
- Scoping events with JQL filters limits each webhook to the minimum data it needs, reducing what leaks if the destination is compromised

**Attack Prevented:** Data leakage, payload interception, webhook spoofing, over-broad data exposure

#### ClickOps Implementation

**Step 1: Audit Webhooks**
1. Navigate to: **System → Webhooks** (Jira)
2. Review all configured webhooks:
   - Destination URLs (should be internal or verified services)
   - Events subscribed
   - JQL filters (limit scope)

**Step 2: Secure Webhook Endpoints**
- Require HTTPS for all webhook URLs
- Implement webhook signature validation
- Limit events to necessary minimum

{% include pack-code.html vendor="atlassian" section="3.2" %}

---

### 3.3 OAuth Token Management

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(13)

#### Description
Manage OAuth tokens for third-party integrations.

#### Rationale
**Why This Matters:**
- OAuth grants let third-party applications act on a user's behalf, and forgotten authorizations remain valid until explicitly revoked
- Over-scoped grants give an integration far more access than it needs, so its compromise exposes data well beyond its function
- Requiring admin approval for new apps and sensitive scopes stops users from authorizing risky integrations that bypass procurement and security review
- Periodically reviewing and revoking connected apps removes dormant grants that attackers exploit through compromised third-party vendors

**Attack Prevented:** OAuth grant abuse, over-privileged integrations, third-party compromise, consent phishing

#### ClickOps Implementation

**Step 1: Review Authorized Applications**
1. Navigate to: **Profile → Security → Connected apps**
2. Review apps with OAuth access
3. Revoke unnecessary authorizations

**Step 2: Configure OAuth App Policies**
1. Navigate to: **admin.atlassian.com → Security → External apps**
2. Configure:
   - **App approval:** Required for new apps
   - **Scope review:** Admin approval for sensitive scopes

---

## 4. Data Security

### 4.1 Configure Data Residency

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-28

#### Description
Configure data residency for compliance with data localization requirements.

#### Rationale
**Why This Matters:**
- Regulations such as GDPR and various data-sovereignty laws require certain data to remain within specific geographic boundaries
- Pinning Atlassian data to an approved realm prevents inadvertent cross-border storage that creates legal and contractual exposure
- Documented residency controls provide the evidence auditors and customers require to demonstrate localization compliance
- Controlling where data lives also limits which jurisdictions' legal processes can compel access to it

**Attack Prevented:** Compliance violations, unauthorized cross-border data transfer, jurisdictional overreach

#### ClickOps Implementation (Enterprise)

**Step 1: Configure Data Residency**
1. Navigate to: **admin.atlassian.com → Data residency**
2. Select realm for data storage:
   - US
   - EU
   - Australia
3. Apply to products

---

### 4.2 Implement Data Classification

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3

#### Description
Use data classification to restrict access to sensitive content.

#### Rationale
**Why This Matters:**
- Without classification, all content is treated the same and sensitive material is protected no better than routine notes
- Labeling spaces and projects by sensitivity drives access decisions so confidential and restricted content is gated to the right audiences
- Classification gives users a clear signal not to paste secrets or regulated data into low-sensitivity, broadly readable spaces
- Consistent labels enable automated policy and DLP enforcement and provide auditable evidence of how sensitive data is handled

**Attack Prevented:** Sensitive data exposure, over-sharing, mishandling of regulated content

#### ClickOps Implementation

**Step 1: Enable Classification (Enterprise)**
1. Navigate to: **admin.atlassian.com → Data classification**
2. Create classification levels:
   - Public
   - Internal
   - Confidential
   - Restricted

**Step 2: Apply to Spaces/Projects**
1. Classify Confluence spaces
2. Classify Jira projects
3. Configure access based on classification

---

## 5. Monitoring & Detection

### 5.1 Enable Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure and monitor Atlassian audit logs.

#### Rationale
**Why This Matters:**
- Audit logs are the primary record of authentication, permission changes, app installs, and data exports needed to detect and investigate abuse
- Without centralized logging, malicious activity such as a quiet permission escalation or bulk export goes unnoticed until damage is done
- Streaming logs to a SIEM preserves evidence beyond the platform's retention window and correlates Atlassian events with the rest of the environment
- Reliable audit trails are required for incident response and for SOC 2, ISO 27001, and similar compliance attestations

**Attack Prevented:** Undetected intrusion, repudiation, delayed incident response, tampering concealment

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **admin.atlassian.com → Security → Audit log**
2. Review events:
   - Authentication events
   - Permission changes
   - App installations
   - Data exports

**Step 2: Configure SIEM Export**
1. Navigate to: **Settings → Audit log streaming** (Enterprise)
2. Configure destination:
   - Splunk
   - Sumo Logic
   - Custom webhook

#### Detection Queries

{% include pack-code.html vendor="atlassian" section="5.1" %}

---

### 5.2 Configure Anomaly Detection

**Profile Level:** L2 (Walk)

#### Description
Enable Atlassian Access anomaly detection (Enterprise).

#### Rationale
**Why This Matters:**
- Anomaly detection flags behavior that static rules miss, such as impossible-travel logins or atypical bulk data access
- Account takeover and insider abuse often look like ordinary activity until viewed against the user's established baseline
- Automated alerts shrink dwell time by surfacing suspicious events in near real time rather than during a periodic log review
- Early warning on permission changes catches an attacker escalating privileges before they reach sensitive projects

**Attack Prevented:** Account takeover, insider abuse, credential stuffing, stealthy privilege escalation

#### ClickOps Implementation

1. Navigate to: **admin.atlassian.com → Security → Anomaly detection**
2. Enable detection for:
   - Unusual login locations
   - Bulk data access
   - Permission changes
3. Configure alert recipients

---

## 6. Vulnerability Management

### 6.1 Critical CVE Response

**Profile Level:** L1 (Crawl)

#### Description
Recent critical vulnerabilities require immediate attention.

#### Rationale
**Why This Matters:**
- Critical Confluence and Jira vulnerabilities have included broken access control and OGNL injection enabling unauthenticated remote code execution and rogue admin account creation
- These flaws are weaponized and actively exploited within days of disclosure, so unpatched Data Center and Server instances are high-value targets
- Prompt patching plus log review for exploitation attempts and unauthorized admin accounts limits both initial compromise and attacker persistence
- A defined CVE response process ensures advisories are acted on immediately instead of waiting for the next maintenance window

**Attack Prevented:** Remote code execution, authentication bypass, unauthorized admin creation, data destruction

#### Recent Critical CVEs

| CVE | CVSS | Product | Description |
|-----|------|---------|-------------|
| CVE-2023-22515 | 10.0 | Confluence DC/Server | Broken access control, admin account creation |
| CVE-2023-22518 | 9.8 | Confluence DC/Server | Auth bypass, data destruction |
| CVE-2022-26134 | 9.8 | Confluence Server/DC | OGNL injection RCE |
| CVE-2021-26084 | 9.8 | Confluence Server/DC | OGNL injection RCE |

#### Response Actions

**For Data Center/Server:**
1. Apply patches immediately
2. Review access logs for exploitation attempts
3. Check for unauthorized admin accounts
4. Consider migration to Cloud

**For Cloud:**
- Atlassian manages patching
- Monitor Atlassian security advisories
- Review audit logs for suspicious activity

---

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Atlassian Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.2 | Product/project permissions | 1.2 |
| CC7.2 | Audit logging | 5.1 |

### NIST 800-53 Mapping

| Control | Atlassian Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | SSO with MFA | 1.1 |
| CM-7 | App approval workflow | 2.1 |
| AU-2 | Audit logging | 5.1 |

---

## Appendix A: Edition Compatibility

| Control | Free | Standard | Premium | Enterprise |
|---------|------|----------|---------|------------|
| SSO (SAML) | ❌ | ❌ | ✅ | ✅ |
| MFA | ✅ | ✅ | ✅ | ✅ |
| Audit Logs | Basic | Basic | ✅ | ✅ |
| App Policies | ❌ | ❌ | ✅ | ✅ |
| Data Classification | ❌ | ❌ | ❌ | ✅ |
| Anomaly Detection | ❌ | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Atlassian Documentation:**
- [Trust Center](https://www.atlassian.com/trust) | [Customer Trust Center](https://customertrust.atlassian.com/) (powered by Conveyor)
- [Atlassian Support](https://support.atlassian.com/)
- [Security Best Practices](https://support.atlassian.com/security-and-access-policies/)
- [Security Practices](https://www.atlassian.com/trust/security/security-practices)
- [Security Measures](https://www.atlassian.com/legal/security-measures)
- [Vulnerability Disclosure](https://www.atlassian.com/trust/data-protection/vulnerabilities)
- [Security Advisories](https://www.atlassian.com/trust/security/advisories)

**API & Developer Tools:**
- [Atlassian Developer Portal](https://developer.atlassian.com/)
- [Jira Cloud REST API](https://developer.atlassian.com/cloud/jira/platform/rest/)
- [Confluence Cloud REST API](https://developer.atlassian.com/cloud/confluence/rest/)
- [Forge App Framework](https://developer.atlassian.com/platform/forge/) (SOC 2 and ISO 27001 compliant)
- [API Security Guide](https://developer.atlassian.com/cloud/jira/platform/security/)
- [GitHub Organization](https://github.com/atlassian)

**Compliance Frameworks:**
- SOC 2 Type II (individual product audits on a regular basis) — via [SOC 2 Compliance](https://www.atlassian.com/trust/compliance/resources/soc2)
- ISO/IEC 27001:2022 (Atlassian Trust Management System) — via [ISO 27001 Compliance](https://www.atlassian.com/trust/compliance/resources/iso27001)
- SOX compliance, PCI DSS
- [Compliance Resource Center](https://www.atlassian.com/trust/compliance/resources) | [Compliance FAQ](https://www.atlassian.com/trust/compliance/compliance-faq)

**Security Incidents:**
- **2023 — Critical Confluence CVEs:** CVE-2023-22515 (CVSS 10.0) and CVE-2023-22518 (CVSS 9.8) affected Confluence Data Center/Server with broken access control and auth bypass vulnerabilities. Actively exploited in the wild. Cloud instances were not affected. ([Security Advisories](https://www.atlassian.com/trust/security/advisories))
- **February 2023 — Employee Data Leak via Envoy:** Hackers leaked Atlassian employee records and office floorplans obtained through a breach of third-party workplace platform Envoy. No customer data was affected. ([SecurityWeek Report](https://www.securityweek.com/atlassian-investigating-security-breach-after-hackers-leak-data/))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.2.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Atlassian hardening guide | Claude Code (Opus 4.5) |
| 2026-02-19 | 0.2.0 | draft | Extract inline code to Code Packs (api, sdk) | Claude Code (Opus 4.6) |
