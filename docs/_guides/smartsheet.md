---
layout: guide
title: "Smartsheet Hardening Guide"
vendor: "Smartsheet"
slug: "smartsheet"
tier: "5"
category: "Productivity"
description: "Work management security for sharing defaults, connector controls, and activity logging"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

Smartsheet is a collaborative work management platform for projects, workflows, and data collection. REST API, OAuth apps, and connectors access project data and business processes. Compromised access exposes project timelines, resource allocation, and potentially sensitive form submissions.

### Intended Audience
- Security engineers managing work management platforms
- Smartsheet administrators
- GRC professionals assessing project management security
- Third-party risk managers evaluating workflow integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Smartsheet security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Sharing & Permissions](#2-sharing--permissions)
3. [Integration Security](#3-integration-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML single sign-on with multi-factor authentication for all Smartsheet access so every login is brokered through your corporate identity provider.

#### Rationale
**Why This Matters:**
- Routing every Smartsheet login through your IdP enforces MFA, conditional access, and central session policy on each authentication attempt
- Native email-and-password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- SSO with automated provisioning deprovisions departed users centrally, eliminating orphaned accounts that retain access to project data
- Smartsheet workspaces hold project plans, resource and budget data, and form submissions, so a single compromised login can expose all of it

**Attack Prevented:** Credential theft, phishing, MFA bypass, password reuse, orphaned-account access

#### ClickOps Implementation

**Step 1: Configure SAML SSO (Enterprise)**
1. Navigate to: **Admin Center → Security Controls → SAML**
2. Configure SAML IdP
3. Enable: **Require SAML**

**Step 2: Enable MFA**
1. Configure MFA through IdP
2. Or enable Smartsheet MFA
3. Require for all users

---

### 1.2 User Types and Roles

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define Smartsheet user types and group-based roles so each account holds only the administrative and licensing privileges its job actually requires.

#### Rationale
**Why This Matters:**
- Least-privilege role assignment limits what a compromised or misused account can reach and change
- Reserving System Admin for a small, deliberate set of accounts shrinks the blast radius of an admin takeover
- Group-based permissions make access reviews and offboarding consistent and auditable instead of ad hoc
- Over-provisioned admin or licensed accounts let an attacker alter sharing, integrations, and security settings across the whole organization

**Attack Prevented:** Privilege escalation, lateral movement, insider misuse, excessive standing access

#### ClickOps Implementation

**Step 1: Define User Types**

| Type | Permissions |
|------|-------------|
| System Admin | Full admin access |
| Group Admin | Manage specific groups |
| Licensed User | Create and share |
| Resource Viewer | View resources only |

**Step 2: Configure Groups**
1. Navigate to: **Admin Center → User Management → Groups**
2. Create department groups
3. Assign permissions by group

---

## 2. Sharing & Permissions

### 2.1 Configure Sharing Defaults

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-21

#### Description
Control sheet and workspace sharing.

#### Rationale
**Attack Scenario:** Public links to project sheets expose sensitive timelines; form submissions accessible to unauthorized users.

**Why This Matters:**
- Restrictive default sharing prevents sheets and workspaces from being exposed beyond their intended audience by accident
- Published items and public links bypass account-level access controls and are reachable by anyone who holds the URL
- Workspace-scoped sharing defaults contain external collaboration to the teams that need it instead of the entire organization
- Project sheets and form responses often hold schedules, budgets, and personal data that should never be world-readable

**Attack Prevented:** Data exposure via public links, unauthorized external sharing, accidental data leakage, oversharing

#### ClickOps Implementation

**Step 1: Global Sharing Settings**
1. Navigate to: **Admin Center → Security Controls**
2. Configure:
   - **Published item restrictions**
   - **External sharing policies**
   - **Default sharing permissions**

**Step 2: Workspace Controls**
1. Create workspaces per team
2. Set workspace sharing defaults
3. Restrict external sharing

---

### 2.2 Form Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-21

#### Description
Restrict who can view form submissions, limit form sharing, and configure submission notifications so collected responses reach only authorized recipients.

#### Rationale
**Why This Matters:**
- Forms often collect sensitive intake data such as requests, approvals, contact details, and internal reporting that must not be visible to unauthorized users
- Limiting submission visibility and form sharing keeps response data scoped to the team that owns the process
- Submission notifications give owners timely awareness of new entries and of unexpected or anomalous activity
- Unrestricted forms and their result sheets are an easy path for harvesting business or personal data at scale

**Attack Prevented:** Unauthorized data access, data harvesting, information disclosure, oversharing of submissions

#### ClickOps Implementation

**Step 1: Form Access Controls**
1. Limit who can view form submissions
2. Restrict form sharing
3. Configure submission notifications

---

## 3. Integration Security

### 3.1 Connector Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Review connected apps and connectors in the Admin Center, remove unused ones, and audit personal API access tokens, revoking any that are no longer needed.

#### Rationale
**Why This Matters:**
- Every connector and API token is a standing, often long-lived credential that can read or modify project data outside the SSO and MFA path
- Unused or forgotten integrations expand the attack surface and are rarely monitored, making them ideal footholds for attackers
- Auditing and revoking stale tokens enforces least privilege and limits damage if a token is leaked or a third party is breached
- A single over-scoped connector compromise can exfiltrate or alter data across many sheets and workspaces

**Attack Prevented:** Token abuse, third-party and supply-chain compromise, data exfiltration, stale credential exploitation

#### ClickOps Implementation

**Step 1: Review Connectors**
1. Navigate to: **Admin Center → Integrations**
2. Review all connected apps
3. Remove unused connectors

**Step 2: API Access**
1. Navigate to: **Personal Settings → API Access**
2. Audit access tokens
3. Revoke unused tokens

---

### 3.2 Premium App Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-7

#### Description
Control which Smartsheet premium apps (such as Dynamic View, Control Center, and Data Shuttle) are enabled and configure their access permissions to match genuine business need.

#### Rationale
**Why This Matters:**
- Premium apps extend data access and data-movement capabilities, so each enabled app widens what an attacker or misconfiguration can reach
- Enabling apps only where there is a clear business need keeps the platform's functionality and data-flow surface minimal
- Scoped access permissions prevent premium apps from exposing or moving data beyond the teams authorized to use them
- Apps such as Data Shuttle move data in and out of Smartsheet, so unmanaged enablement can create unmonitored data egress paths

**Attack Prevented:** Unauthorized data movement, data exfiltration, excessive feature exposure, misconfiguration abuse

#### ClickOps Implementation

**Step 1: Control Premium Apps**
1. Navigate to: **Admin Center → Premium Apps**
2. Enable/disable by app
3. Configure access permissions

---

## 4. Monitoring & Detection

### 4.1 Activity Log (Enterprise)

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable and review the Enterprise Activity Log and export its events to your SIEM so administrative and user actions are recorded and monitored.

#### Rationale
**Why This Matters:**
- Comprehensive activity logging is what makes account compromise, data exfiltration, and insider misuse detectable rather than silent
- Exporting events to a SIEM enables correlation, alerting, and retention beyond the platform's native console
- An audit trail of sharing changes, logins, and admin actions is essential for incident investigation and forensics
- Without centralized logging, attacker actions and policy changes go unnoticed until after the damage is done

**Attack Prevented:** Undetected compromise, insider misuse, delayed incident response, audit gaps

#### ClickOps Implementation

**Step 1: Access Activity Log**
1. Navigate to: **Admin Center → Security Controls → Activity Log**
2. Review user activities
3. Export for SIEM integration

#### Detection Focus

---

## Appendix A: Edition Compatibility

| Control | Pro | Business | Enterprise |
|---------|-----|----------|------------|
| SAML SSO | ❌ | ❌ | ✅ |
| Activity Log | ❌ | ❌ | ✅ |
| Group Admin | ❌ | ❌ | ✅ |
| External Sharing Controls | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official Smartsheet Documentation:**
- [Trust Center](https://www.smartsheet.com/trust)
- [Security](https://www.smartsheet.com/trust/security)
- [Help Center](https://help.smartsheet.com/)
- [Security Practices](https://www.smartsheet.com/legal/security)

**API & Developer Tools:**
- [Developer Portal](https://developers.smartsheet.com/)
- [API Introduction](https://developers.smartsheet.com/api/smartsheet/introduction)
- SDKs available for C#, Java, Node.js, and Python -- via [Developer Portal](https://developers.smartsheet.com/)

**Compliance Frameworks:**
- SOC 1, SOC 2 Type II, SOC 3, ISO 27001:2022, ISO 27018:2019, ISO 27701:2019 -- via [Trust Center / Compliance](https://www.smartsheet.com/trust/compliance)
- [SOC Reports](https://www.smartsheet.com/trust/compliance/soc)
- [ISO Certification](https://www.smartsheet.com/trust/compliance/iso)

**Security Incidents:**
- No major direct Smartsheet data breach publicly reported. In the October 2023 Okta support system compromise, a Smartsheet service account credential was stolen and later used by threat actors to access Cloudflare's Atlassian environment (not a Smartsheet platform breach). Separately, Smartsheet patched an account-hijacking vulnerability before any known exploitation.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Smartsheet hardening guide | Claude Code (Opus 4.5) |
