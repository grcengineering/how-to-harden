---
layout: guide
title: "Fivetran Hardening Guide"
vendor: "Fivetran"
slug: "fivetran"
tier: "2"
category: "Data"
description: "Data integration platform hardening for Fivetran including SSO configuration, role-based access, and connector security"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

Fivetran is a leading data integration platform that automates data pipelines for **thousands of organizations** worldwide. As a tool that moves data between systems including databases, SaaS applications, and data warehouses, Fivetran security configurations directly impact data confidentiality and integrity across your data ecosystem.

### Intended Audience
- Security engineers managing data platforms
- IT administrators configuring Fivetran
- Data engineers securing data pipelines
- GRC professionals assessing data integration security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Fivetran Dashboard security including SAML SSO, role-based access control, connector security, and session management.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Connector Security](#3-connector-security)
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
Configure SAML SSO to centralize authentication for Fivetran users.

#### Rationale
**Why This Matters:**
- Centralizes identity management
- Enables enforcement of organizational MFA policies
- Supports just-in-time provisioning
- Simplifies user lifecycle management

#### Prerequisites
- Fivetran account with Account Administrator role
- SAML 2.0 compatible identity provider
- IdP SuperAdmin or AppAdmin access

#### ClickOps Implementation

**Step 1: Access SSO Configuration**
1. Navigate to: **Account Settings** → **General**
2. Locate **Authentication Settings** section
3. Review current authentication configuration

**Step 2: Configure Identity Provider**
1. Create SAML application in your IdP:
   - Okta
   - Microsoft Entra ID
   - Google Workspace
   - PingOne
   - CyberArk Identity
2. Configure attribute mappings

**Step 3: Configure Fivetran SSO**
1. Navigate to: **Account Settings** → **SSO**
2. Enable SAML authentication
3. Enter IdP metadata:
   - IdP SSO URL
   - IdP Entity ID
   - X.509 Certificate
4. Save configuration

**Step 4: Test and Enforce**
1. Test SSO authentication
2. Verify user can sign in via IdP
3. Enable SSO enforcement (see 1.2)

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="fivetran" section="1.1" %}

---

### 1.2 Restrict Authentication to SSO

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Require all users to authenticate via SSO only.

#### Rationale
**Why This Matters:**
- Forcing SAML-only authentication closes the local password login path that bypasses IdP-enforced MFA and conditional access
- Password logins are vulnerable to credential stuffing, phishing, and reuse of breached credentials
- Centralizing every login through the IdP means deprovisioning a user in the IdP instantly revokes Fivetran access
- Fivetran holds the credentials and data flows for your entire pipeline, so any non-SSO login is a high-value bypass

**Attack Prevented:** Credential stuffing, phishing, MFA bypass, password reuse, orphaned-account access

#### ClickOps Implementation

**Step 1: Configure Authentication Restriction**
1. Navigate to: **Account Settings** → **General**
2. Go to **Account Settings** tab
3. Find **Authentication Settings** section

**Step 2: Set Required Authentication**
1. Set **Required authentication type** to **SAML**
2. This prevents password login
3. All users must use SSO

**Step 3: Verify Enforcement**
1. Test login with password (should fail)
2. Verify SSO login works
3. Document emergency access procedures

#### Code Implementation

{% include pack-code.html vendor="fivetran" section="1.2" %}

---

### 1.3 Configure Just-In-Time Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Enable automatic user provisioning on first login.

#### Rationale
**Why This Matters:**
- JIT provisioning creates accounts only when an IdP-authenticated user signs in for the first time, eliminating pre-created dormant accounts
- New users are created with no permissions by default, enforcing least privilege until roles are explicitly assigned
- Tying account creation to the IdP keeps the user lifecycle authoritative in one place rather than scattered across manual Fivetran account creation
- Manual account creation is error-prone and tends to leave stale, over-privileged accounts behind

**Attack Prevented:** Orphaned-account access, privilege creep, manual provisioning errors, dormant account abuse

#### ClickOps Implementation

**Step 1: Enable JIT Provisioning**
1. Navigate to: **Account Settings** → **SSO**
2. Enable **Enable SAML authentication**
3. Enable **Enable user provisioning**

**Step 2: Configure SAML Attributes**
1. Configure IdP to send:
   - Email address
   - First name
   - Last name
2. New users created automatically on SAML sign-on

**Step 3: Configure Default Permissions**
1. Note: JIT users created with no permissions by default
2. Enable SCIM for role provisioning
3. Or manually assign roles after creation

#### Code Implementation

{% include pack-code.html vendor="fivetran" section="1.3" %}

---

### 1.4 Configure Session Timeout

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout for dashboard access.

#### Rationale
**Why This Matters:**
- Bounded session lifetimes limit the window in which a stolen or hijacked session token can be reused
- Shorter timeouts protect against unattended-workstation access to the dashboard and its connector configurations
- Aligning timeout length to data sensitivity forces re-authentication in high-risk environments
- A default 24-hour session is a long exposure window for an admin console that controls data movement

**Attack Prevented:** Session hijacking, token replay, unattended-session abuse, idle-session takeover

#### Prerequisites
- Enterprise or Business Critical plan (for custom timeout)

#### ClickOps Implementation

**Step 1: Access Session Settings**
1. Navigate to: **Account Settings** → **General**
2. Find session timeout settings

**Step 2: Configure Timeout Duration**
1. Select session timeout:
   - 15 minutes
   - 30 minutes
   - 1 hour
   - 4 hours
   - 1 day
   - 2 weeks
2. Default is 1 day (24 hours)

**Step 3: Apply Restrictions**
1. Shorter timeouts for sensitive data
2. Sessions end when browser closes
3. Document timeout policy

#### Code Implementation

{% include pack-code.html vendor="fivetran" section="1.4" %}

---

## 2. Access Controls

### 2.1 Configure Role-Based Access Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement role-based permissions for Fivetran access.

#### Rationale
**Why This Matters:**
- Assigning the least-privileged role to each user limits the blast radius if any single account is compromised
- Restricting Account Administrator to a small number of users reduces the count of high-value targets
- Read-only Analyst roles let users see status without the ability to alter connectors, credentials, or destinations
- Over-broad administrative access lets a single compromised account reconfigure pipelines or exfiltrate source and destination data

**Attack Prevented:** Privilege escalation, lateral movement, insider misuse, blast-radius expansion

#### ClickOps Implementation

**Step 1: Review Account Roles**
1. Navigate to: **Account Settings** → **Users**
2. Review available roles:
   - **Account Administrator:** Full account control
   - **Account Analyst:** View-only access
   - **Account Billing:** Billing management
   - **Team Manager:** Team administration

**Step 2: Assign Appropriate Roles**
1. Limit Account Administrator to 2-3 users
2. Use Analyst for read-only needs
3. Use custom roles when possible

**Step 3: Configure Destination/Connector Roles**
1. Assign connector-level permissions
2. Assign destination-level permissions
3. Apply minimum necessary access

#### Code Implementation

{% include pack-code.html vendor="fivetran" section="2.1" %}

---

### 2.2 Configure Team Structure

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Organize users into teams for granular access control.

#### Rationale
**Why This Matters:**
- Teams scope connector and destination access to the users who actually need it, enforcing need-to-know
- Inherited team permissions make access consistent and auditable rather than ad hoc per user
- Limiting Team Manager assignments controls who can grant access to pipelines and data
- Without segmentation, every user can potentially reach every connector and destination across the account

**Attack Prevented:** Over-broad data access, lateral movement, unauthorized pipeline changes, insider misuse

#### ClickOps Implementation

**Step 1: Create Teams**
1. Navigate to: **Account Settings** → **Teams**
2. Click **Create Team**
3. Name team by function or project

**Step 2: Assign Team Managers**
1. Only Team Managers and Account Admins can manage teams
2. Assign Team Manager role
3. Limit managers to necessary personnel

**Step 3: Configure Team Permissions**
1. Assign connectors to teams
2. Assign destinations to teams
3. Users inherit team permissions

#### Code Implementation

{% include pack-code.html vendor="fivetran" section="2.2" %}

---

### 2.3 Configure SCIM Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure SCIM for automated user and group provisioning.

#### Rationale
**Why This Matters:**
- SCIM automates account creation, updates, and deprovisioning from the IdP so access mirrors employment status in near real time
- Automatic deprovisioning removes departed users immediately, eliminating orphaned accounts with standing data access
- Group-to-team mapping keeps role assignments consistent and removes manual permission drift
- Manual offboarding is slow and easily missed, leaving credentials that can be abused after a user leaves

**Attack Prevented:** Orphaned-account access, offboarding gaps, privilege drift, manual provisioning errors

#### ClickOps Implementation

**Step 1: Enable SCIM**
1. Navigate to: **Account Settings** → **SCIM**
2. Generate SCIM API token
3. Copy SCIM base URL

**Step 2: Configure IdP SCIM**
1. Add SCIM integration in IdP
2. Enter Fivetran SCIM endpoint
3. Enter API token

**Step 3: Configure User/Group Sync**
1. Map IdP groups to Fivetran teams
2. Configure provisioning rules
3. Test user synchronization

#### Code Implementation

{% include pack-code.html vendor="fivetran" section="2.3" %}

---

## 3. Connector Security

### 3.1 Secure Connector Credentials

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure credentials used for data source connections.

#### Rationale
**Why This Matters:**
- Fivetran stores credentials for data sources
- Compromised credentials expose source systems
- Apply least privilege to connector accounts

#### ClickOps Implementation

**Step 1: Create Dedicated Service Accounts**
1. Create service accounts for each connector
2. Grant minimum required permissions:
   - Read access for data extraction
   - SELECT only for database connectors
3. Never use admin credentials

**Step 2: Use SSH Tunnels**
1. For database connectors, enable SSH tunnels
2. More secure than direct connections
3. Encrypt data in transit

**Step 3: Rotate Credentials**
1. Establish rotation schedule (90 days)
2. Update credentials in Fivetran
3. Verify connector after rotation

#### Code Implementation

{% include pack-code.html vendor="fivetran" section="3.1" %}

---

### 3.2 Configure Network Security

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Secure network access for Fivetran connections.

#### Rationale
**Why This Matters:**
- IP allowlisting restricts source-system access to known Fivetran addresses, shrinking the attack surface to a defined set of origins
- PrivateLink and private networking keep data off the public internet, removing exposure to interception and internet-facing scanning
- Requiring SSL/TLS with certificate validation protects pipeline data in transit and defends against man-in-the-middle attacks
- Source databases exposed to the public internet are routinely scanned and brute-forced by attackers

**Attack Prevented:** Man-in-the-middle interception, network eavesdropping, unauthorized source access, internet-exposed database attacks

#### ClickOps Implementation

**Step 1: Configure IP Allowlisting**
1. Get Fivetran IP addresses
2. Allowlist only Fivetran IPs on source systems
3. Block other external access

**Step 2: Enable Private Networking**
1. Use Fivetran PrivateLink if available
2. Connect via private networks
3. Avoid public internet

**Step 3: Configure Database Security**
1. Enable SSL/TLS for database connections
2. Require encrypted connections
3. Verify certificate validation

#### Code Implementation

{% include pack-code.html vendor="fivetran" section="3.2" %}

---

### 3.3 Configure Destination Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-8 |

#### Description
Secure data warehouse and destination configurations.

#### Rationale
**Why This Matters:**
- Dedicated least-privilege service accounts for the destination limit what a compromised Fivetran connection can write or alter
- Encryption in transit and at rest protects the consolidated warehouse data, which is often more sensitive than any single source
- Restricting who can change destination settings prevents redirection of data or weakening of warehouse controls
- The destination aggregates data from many sources, making it a concentrated, high-value target

**Attack Prevented:** Data exfiltration, unauthorized warehouse writes, data redirection, eavesdropping on data in transit and at rest

#### ClickOps Implementation

**Step 1: Secure Destination Credentials**
1. Use service accounts for destinations
2. Grant minimum write permissions
3. Avoid using admin credentials

**Step 2: Enable Encryption**
1. Ensure destination supports encryption
2. Enable TLS for connections
3. Verify data encrypted at rest

**Step 3: Configure Access Controls**
1. Limit who can modify destination settings
2. Restrict data access in destination
3. Apply column-level security if needed

#### Code Implementation

{% include pack-code.html vendor="fivetran" section="3.3" %}

---

## 4. Monitoring & Compliance

### 4.1 Configure Activity Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Monitor user and connector activity.

#### Rationale
**Why This Matters:**
- Activity logs provide the audit trail needed to detect unauthorized logins, permission changes, and connector tampering
- Exporting logs to a SIEM enables correlation, alerting, and retention beyond the dashboard's native view
- Monitoring credential and SSO configuration changes catches attacker attempts to weaken authentication controls
- Without logging, account compromise and configuration drift go undetected and forensic investigation is impossible

**Attack Prevented:** Undetected account compromise, configuration tampering, insider misuse, post-incident blind spots

#### ClickOps Implementation

**Step 1: Access Activity Logs**
1. Navigate to: **Account Settings** → **Activity Log**
2. Review logged events:
   - User logins
   - Configuration changes
   - Connector modifications
   - Sync activities

**Step 2: Export Logs**
1. Export logs for analysis
2. Integrate with SIEM
3. Set up regular exports

**Step 3: Monitor Key Events**
1. User provisioning/deprovisioning
2. SSO configuration changes
3. Connector credential updates
4. Permission modifications

#### Code Implementation

{% include pack-code.html vendor="fivetran" section="4.1" %}

---

### 4.2 Configure Sync Monitoring

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | CA-7 |

#### Description
Monitor data sync status and errors.

#### Rationale
**Why This Matters:**
- Sync failure alerts surface broken or tampered pipelines quickly, protecting data freshness and integrity
- Webhook integration with monitoring systems enables automated detection and response to abnormal sync behavior
- Prompt investigation of errors distinguishes routine failures from credential revocation or malicious interference
- Silent sync failures can mask data manipulation, exfiltration, or a compromised source connection

**Attack Prevented:** Undetected pipeline tampering, data integrity loss, silent connector compromise, delayed incident response

#### ClickOps Implementation

**Step 1: Configure Notifications**
1. Navigate to: **Notification Settings**
2. Enable sync failure alerts
3. Configure email recipients

**Step 2: Monitor Sync Health**
1. Review sync dashboard
2. Identify failed syncs
3. Investigate errors promptly

**Step 3: Configure Webhooks**
1. Set up webhooks for events
2. Integrate with monitoring systems
3. Automate incident response

#### Code Implementation

{% include pack-code.html vendor="fivetran" section="4.2" %}

---

### 4.3 Data Governance

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Implement data governance controls for sensitive data.

#### Rationale
**Why This Matters:**
- Column blocking prevents sensitive fields such as PII from ever being replicated into the destination, reducing the data footprint
- Column hashing protects sensitive values while preserving referential integrity for analytics
- Documented data flows and lineage support compliance audits and rapid scoping during an incident
- Replicating unnecessary sensitive data expands breach impact and regulatory exposure across every destination

**Attack Prevented:** PII over-exposure, sensitive-data sprawl, compliance violations, expanded breach blast radius

#### ClickOps Implementation

**Step 1: Configure Column Blocking**
1. Navigate to connector settings
2. Block sensitive columns from sync
3. Prevent PII replication

**Step 2: Configure Hashing**
1. Enable column hashing for sensitive data
2. Hash PII columns
3. Maintain referential integrity

**Step 3: Document Data Flows**
1. Inventory all connectors
2. Document data destinations
3. Maintain data lineage

#### Code Implementation

{% include pack-code.html vendor="fivetran" section="4.3" %}

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Fivetran Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO/SAML | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [2.1](#21-configure-role-based-access-control) |
| CC6.6 | Session timeout | [1.4](#14-configure-session-timeout) |
| CC6.7 | Encryption | [3.3](#33-configure-destination-security) |
| CC7.2 | Activity logging | [4.1](#41-configure-activity-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Fivetran Control | Guide Section |
|---------|------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-2 | SCIM provisioning | [2.3](#23-configure-scim-provisioning) |
| AC-6 | Least privilege | [2.1](#21-configure-role-based-access-control) |
| SC-12 | Credential security | [3.1](#31-secure-connector-credentials) |
| AU-2 | Audit logging | [4.1](#41-configure-activity-logging) |

---

## Appendix A: Plan Compatibility

| Feature | Standard | Enterprise | Business Critical |
|---------|----------|------------|-------------------|
| SAML SSO | ✅ | ✅ | ✅ |
| Custom Session Timeout | ❌ | ✅ | ✅ |
| SCIM Provisioning | ❌ | ✅ | ✅ |
| Private Networking | ❌ | Add-on | Add-on |
| Advanced Security | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Fivetran Documentation:**
- [Trust Center (SafeBase)](https://trust.fivetran.com/)
- [Fivetran Security](https://www.fivetran.com/security)
- [Fivetran Security Documentation](https://fivetran.com/docs/security)
- [Getting Started](https://fivetran.com/docs/getting-started)
- [Single Sign-On](https://fivetran.com/docs/using-fivetran/fivetran-dashboard/account-settings/sso)
- [Account Settings](https://fivetran.com/docs/using-fivetran/fivetran-dashboard/account-settings)
- [SSO with Okta](https://fivetran.com/docs/using-fivetran/fivetran-dashboard/account-settings/sso/okta-saml-sso)
- [SSO with Microsoft Entra ID](https://fivetran.com/docs/getting-started/account/azure-saml-sso)

**API & Developer Documentation:**
- [REST API Reference](https://fivetran.com/docs/rest-api/api-reference)
- [Compliance Standards](https://fivetran.com/docs/trust/compliance)

**Compliance Frameworks:**
- SOC 1, SOC 2 Type II, ISO 27001, PCI DSS, HITRUST i1, CyberEssentials — via [Trust Center](https://trust.fivetran.com/)
- [Fivetran Security Whitepaper](https://resources.fivetran.com/datasheets/fivetran-security-whitepaper)

**Security Incidents:**
- No major public security incidents identified affecting the Fivetran platform.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, access controls, and connector security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
