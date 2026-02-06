---
layout: guide
title: "Workato Hardening Guide"
vendor: "Workato"
slug: "workato"
tier: "2"
category: "Automation & Integration"
description: "Integration platform hardening for Workato including SSO configuration, role-based access control, and connection security"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Workato is a leading enterprise automation platform enabling **thousands of organizations** to automate workflows and integrate applications without coding. As a platform that connects to critical business systems and handles sensitive data flows, Workato security configurations directly impact data protection and workflow integrity.

### Intended Audience
- Security engineers managing automation platforms
- IT administrators configuring Workato
- Integration teams securing workflows
- GRC professionals assessing automation security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Workato workspace security including SAML SSO, role-based access control, connection security, and audit logging.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Connection Security](#3-connection-security)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Workato users.

#### Rationale
**Why This Matters:**
- Centralizes identity management
- Enforces organizational MFA policies
- Simplifies password management
- Supports just-in-time provisioning

#### Prerequisites
- [ ] Workato workspace with admin access
- [ ] SAML 2.0 compatible identity provider
- [ ] Workspace handle configured

#### ClickOps Implementation

**Step 1: Access SSO Configuration**
1. Navigate to: **Workspace admin** → **Settings** → **Login methods**
2. Select **SAML based SSO** in Authentication method menu

**Step 2: Configure Workspace Handle**
1. Enter workspace handle (max 20 characters)
2. Workato converts uppercase to lowercase
3. This becomes your SSO URL identifier

**Step 3: Configure Identity Provider**
1. Create SAML application in IdP:
   - Microsoft Entra ID
   - Okta
   - OneLogin
   - CyberArk Identity
2. Configure attribute mappings
3. Download IdP metadata

**Step 4: Complete Configuration**
1. Upload IdP metadata to Workato
2. Configure SAML settings
3. Test SSO authentication
4. Enable enforcement

**Time to Complete:** ~1 hour

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require two-factor authentication for all workspace users.

#### ClickOps Implementation

**Step 1: Enable Organization 2FA**
1. Navigate to: **Workspace admin** → **Settings** → **Security**
2. Enable **Require two-factor authentication**
3. Users must configure 2FA on next login

**Step 2: Configure Supported Methods**
1. Workato supports authenticator apps:
   - Google Authenticator
   - Microsoft Authenticator
   - Authy
2. Users configure in account settings

**Step 3: Enforce via IdP (SSO)**
1. If using SSO, configure MFA in IdP
2. All SSO users subject to IdP policies
3. Use phishing-resistant methods for admins

---

### 1.3 Configure Just-In-Time Provisioning

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Enable automatic user creation on first SSO login.

#### ClickOps Implementation

**Step 1: Enable JIT Provisioning**
1. Navigate to: **Workspace admin** → **Settings** → **Login methods**
2. Configure SAML with JIT enabled
3. Users created automatically on first login

**Step 2: Configure Default Roles**
1. Set default environment role for new users
2. Configure via SAML attributes
3. Or assign manually after creation

**Step 3: Configure SAML Attributes**
1. Configure IdP to send:
   - Email
   - First name
   - Last name
2. User accounts created from assertion

---

### 1.4 Configure Session Security

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout for workspace access.

#### ClickOps Implementation

**Step 1: Access Session Settings**
1. Navigate to: **Workspace admin** → **Settings** → **General**
2. Find **Session timeout duration**

**Step 2: Configure Timeout**
1. Select appropriate timeout:
   - Shorter for sensitive workspaces
   - Balance security with usability
2. Apply to all users

---

## 2. Access Controls

### 2.1 Configure Role-Based Access Control

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege access using Workato's RBAC model.

#### Rationale
**Why This Matters:**
- Workato follows principle of least privilege
- RBAC minimizes risk of data exposure
- Separates environment and project permissions
- Essential for compliance

#### ClickOps Implementation

**Step 1: Understand Role Types**
1. **Environment roles:** Control access to projects, tools, and admin settings
2. **Project roles:** Control actions within individual projects
3. Both types work together for granular control

**Step 2: Configure Environment Roles**
1. Navigate to: **Workspace admin** → **Collaborators**
2. Review available environment roles
3. Assign minimum necessary access

**Step 3: Configure Project Roles**
1. Navigate to project settings
2. Assign project-level permissions:
   - Create assets
   - Edit assets
   - Deploy assets
   - Delete assets
3. Apply per-project access

---

### 2.2 Configure SAML Role Sync

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Automatically sync roles from IdP via SAML attributes.

#### ClickOps Implementation

**Step 1: Configure SAML Attributes (Legacy Model)**
1. Configure IdP to send role attributes:
   - `workato_role`: Workspace-level role
   - `workato_role_test`: TEST environment role
   - `workato_role_prod`: PROD environment role

**Step 2: Configure SAML Attributes (New Model)**
1. For new permissions model:
   - Same attributes for environment roles
   - `workato_user_groups`: Assign to collaborator groups
2. Groups provide project-level access

**Step 3: Verify Sync**
1. Test user login
2. Verify role assignment
3. Document role mappings

---

### 2.3 Configure Collaborator Groups

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Organize collaborators into groups for easier management.

#### ClickOps Implementation

**Step 1: Create Groups**
1. Navigate to: **Workspace admin** → **Collaborator groups**
2. Create groups by function:
   - Developers
   - Analysts
   - Administrators
3. Define group permissions

**Step 2: Assign Users to Groups**
1. Add collaborators to groups
2. Users inherit group permissions
3. Use for project access

**Step 3: Configure Group Project Access**
1. Assign groups to projects
2. Configure project roles per group
3. Apply minimum necessary access

---

### 2.4 Limit Admin Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect workspace administrator accounts.

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Navigate to: **Workspace admin** → **Collaborators**
2. Filter by admin role
3. Document all administrators

**Step 2: Limit Admin Accounts**
1. Reduce to 2-3 for redundancy
2. Remove unnecessary admins
3. Review quarterly

**Step 3: Protect Admin Accounts**
1. Require MFA for admins
2. Use strong passwords
3. Monitor admin activity

---

## 3. Connection Security

### 3.1 Secure Connection Credentials

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure credentials used for app connections.

#### Rationale
**Why This Matters:**
- Connections store credentials for external apps
- All data encrypted in transit and at rest
- Workato staff cannot access encrypted data
- Apply least privilege to connection accounts

#### ClickOps Implementation

**Step 1: Create Least Privilege Accounts**
1. Create service accounts for connections
2. Grant minimum required permissions
3. Never use admin credentials

**Step 2: Use OAuth When Available**
1. Prefer OAuth over API keys
2. Token-based access more secure
3. Easier to revoke

**Step 3: Rotate Credentials**
1. Establish rotation schedule (90 days)
2. Update connections after rotation
3. Verify recipes after updates

---

### 3.2 Configure Connection Permissions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control who can use and manage connections.

#### ClickOps Implementation

**Step 1: Configure Connection Sharing**
1. Navigate to connection settings
2. Configure who can use connection:
   - Project members only
   - Specific collaborators
   - All workspace users

**Step 2: Limit Connection Management**
1. Restrict who can edit connections
2. Restrict who can view credentials
3. Apply least privilege

**Step 3: Organize Connections**
1. Organize connections by project
2. Remove unused connections
3. Document connection purposes

---

### 3.3 Configure On-Prem Agents

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Secure on-premises agent configurations for private network access.

#### ClickOps Implementation

**Step 1: Deploy Agents Securely**
1. Install agents on secure servers
2. Configure firewall rules
3. Limit agent network access

**Step 2: Configure Agent Authentication**
1. Generate unique agent keys
2. Protect agent credentials
3. Rotate keys if compromised

**Step 3: Monitor Agent Activity**
1. Review agent connection status
2. Monitor data transfer
3. Alert on anomalies

---

## 4. Monitoring & Compliance

### 4.1 Configure Activity Audit Log

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor activity audit logs.

#### Rationale
**Why This Matters:**
- Audit log records significant user actions
- Enables deeper analysis
- Required for compliance
- Can stream to external destinations

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Workspace admin** → **Activity audit log**
2. Review logged events:
   - User logins
   - Recipe changes
   - Connection modifications
   - Job executions

**Step 2: Configure Log Streaming**
1. Stream logs to external destination
2. Enable long-term retention
3. Integrate with SIEM

**Step 3: Monitor Key Events**
1. Admin actions
2. Recipe deployments
3. Connection changes
4. Failed authentications

---

### 4.2 Configure Recipe Security

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | CA-7 |

#### Description
Secure recipe development and deployment.

#### ClickOps Implementation

**Step 1: Configure Development Controls**
1. Require recipe review before deployment
2. Implement change management
3. Document recipe purposes

**Step 2: Configure Production Protection**
1. Separate DEV/TEST/PROD environments
2. Limit who can deploy to PROD
3. Enable deployment approvals

**Step 3: Monitor Recipe Execution**
1. Review job history
2. Monitor for errors
3. Alert on failures

---

### 4.3 Configure Data Masking

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Protect sensitive data in job history and logs.

#### ClickOps Implementation

**Step 1: Enable Data Masking**
1. Configure data masking for sensitive fields
2. Mask PII in logs
3. Protect credentials in job history

**Step 2: Configure Retention**
1. Set job history retention
2. Balance debugging vs. security
3. Purge sensitive data appropriately

---

### 4.4 Configure Automation HQ Security

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Secure multi-workspace Automation HQ environments.

#### ClickOps Implementation

**Step 1: Configure AHQ SSO**
1. Enable SSO for AHQ workspace
2. Enable SSO for child workspaces separately
3. Workato recommends SSO for all workspaces

**Step 2: Configure Workspace Access**
1. Control who can access each workspace
2. Apply consistent policies
3. Centralize administration

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Workato Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [2.1](#21-configure-role-based-access-control) |
| CC6.6 | Session timeout | [1.4](#14-configure-session-security) |
| CC6.7 | Encryption | [3.1](#31-secure-connection-credentials) |
| CC7.2 | Audit logging | [4.1](#41-configure-activity-audit-log) |

### NIST 800-53 Rev 5 Mapping

| Control | Workato Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-enforce-two-factor-authentication) |
| AC-2 | User provisioning | [1.3](#13-configure-just-in-time-provisioning) |
| AC-6 | Least privilege | [2.1](#21-configure-role-based-access-control) |
| AU-2 | Audit logging | [4.1](#41-configure-activity-audit-log) |

---

## Appendix A: References

**Official Workato Documentation:**
- [Security](https://docs.workato.com/security.html)
- [Enable Single Sign-On](https://docs.workato.com/user-accounts-and-teams/single-sign-on.html)
- [SAML Role Sync](https://docs.workato.com/user-accounts-and-teams/saml-role-sync.html)
- [SAML Role Sync in Microsoft Entra ID](https://docs.workato.com/saml-role-sync-azure.html)
- [SAML Role Sync in Okta](https://docs.workato.com/saml-role-sync-okta.html)
- [Troubleshoot Single Sign-On](https://docs.workato.com/en/user-accounts-and-teams/troubleshoot-sso.html)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, RBAC, and connection security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
