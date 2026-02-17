---
layout: guide
title: "Workato Hardening Guide"
vendor: "Workato"
slug: "workato"
tier: "2"
category: "IaC"
description: "Comprehensive security hardening for Workato including SSO, RBAC, encryption key management, API security, secrets management, environment separation, and audit logging"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-02-10"
---

## Overview

Workato is a leading enterprise automation platform (iPaaS) enabling organizations to automate workflows and integrate applications across cloud and on-premises systems. As a platform that connects to critical business systems — CRMs, ERPs, ITSM, HRIS, databases — and orchestrates sensitive data flows between them, Workato security configurations directly impact data protection, workflow integrity, and supply chain risk. A compromised Workato workspace could expose credentials for dozens of connected systems.

### Intended Audience
- Security engineers managing automation platforms
- IT administrators configuring Workato workspaces
- Integration teams securing recipes and connections
- GRC professionals assessing automation security posture

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations — start here
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries (healthcare, finance, government)

### Scope
This guide covers Workato workspace security including SAML SSO, role-based access control, encryption key management, connection security, API platform security, secrets management, environment separation with recipe lifecycle management, and audit logging. It applies to Workato's cloud-hosted platform across all plan tiers, with plan-specific features noted.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Data Protection & Encryption](#3-data-protection--encryption)
4. [Connection Security](#4-connection-security)
5. [API Security](#5-api-security)
6. [Secrets Management](#6-secrets-management)
7. [Environment & Deployment Security](#7-environment--deployment-security)
8. [Monitoring & Compliance](#8-monitoring--compliance)
9. [Compliance Quick Reference](#9-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.1 |
| NIST 800-53 | IA-2, IA-8 |
| ISO 27001 | A.9.4.2 |
| PCI DSS | 8.3 |

#### Description
Configure SAML 2.0 SSO to centralize authentication for all Workato workspace users through your organization's identity provider.

#### Rationale
**Why This Matters:**
- Centralizes identity management and enforces organizational authentication policies
- Enables enforcement of IdP-level MFA, conditional access, and session policies
- Eliminates standalone Workato passwords that could be phished or reused
- Supports just-in-time provisioning to automate user lifecycle

**Attack Prevented:** Credential stuffing, password spray, phishing attacks against standalone Workato accounts.

#### Prerequisites
- [ ] Workato workspace with admin access
- [ ] SAML 2.0 compatible identity provider (Okta, Microsoft Entra ID, OneLogin, CyberArk Identity)
- [ ] Workspace handle configured (max 20 characters, lowercase)
- [ ] IdP metadata XML or manual configuration values

#### ClickOps Implementation

**Step 1: Access SSO Configuration**
1. Navigate to: **Workspace admin** → **Settings** → **Login methods**
2. Select **SAML based SSO** in the Authentication method menu

**Step 2: Configure Workspace Handle**
1. Enter workspace handle (max 20 characters)
2. Workato converts uppercase to lowercase automatically
3. This becomes your SSO URL identifier: `https://www.workato.com/saml_init?workspace_handle=YOUR_HANDLE`

**Step 3: Configure Identity Provider**
1. Create a SAML application in your IdP for Workato
2. Configure the following in your IdP:
   - **ACS URL:** Provided by Workato in the configuration screen
   - **Entity ID:** Provided by Workato
   - **Name ID format:** Email address
3. Configure attribute mappings:
   - `email` (required)
   - `first_name` (optional, for JIT provisioning)
   - `last_name` (optional, for JIT provisioning)
4. Download IdP metadata XML

**Step 4: Complete Configuration**
1. Upload IdP metadata XML to Workato (or enter SSO URL, Entity ID, and Certificate manually)
2. Test SSO authentication with a test user
3. Once verified, enable enforcement to require SSO for all users

**Time to Complete:** ~1 hour

#### Code Implementation

**Option 1: Workato API — List Users to Verify SSO Status**
```bash
# List all workspace members and check their authentication method
curl -s "https://www.workato.com/api/managed_users" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" \
  -H "Content-Type: application/json" | \
  jq '.result[] | {id: .id, email: .email, name: .name}'
```

> **Note:** SAML SSO configuration itself is performed through the Workato admin UI. The API can be used to manage users post-SSO setup.

#### Validation & Testing
1. [ ] Navigate to SSO login URL and verify redirect to IdP
2. [ ] Complete authentication and verify redirect back to Workato
3. [ ] Verify user attributes (name, email) are populated correctly
4. [ ] Test with a user NOT in the IdP — verify access is denied
5. [ ] Verify SSO enforcement blocks direct password login

**Expected result:** All users authenticate exclusively through the IdP. Direct password login is disabled when enforcement is active.

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Monitor for users bypassing SSO (should be none with enforcement)
- Review IdP SAML application access assignments quarterly
- Monitor certificate expiration dates

**Maintenance schedule:**
- **Monthly:** Review SSO login failures in audit log
- **Quarterly:** Verify IdP SAML certificate validity
- **Annually:** Rotate SAML signing certificate

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Low | Users redirected through IdP — standard SSO flow |
| **System Performance** | None | No impact on recipe execution or API performance |
| **Maintenance Burden** | Low | Certificate rotation annually; IdP attribute mapping maintenance |
| **Rollback Difficulty** | Easy | Disable enforcement to restore direct login |

**Potential Issues:**
- IdP outage prevents all Workato access — maintain emergency access account
- Certificate expiration breaks SSO — calendar certificate renewal dates

**Rollback Procedure:**
Disable SSO enforcement in **Workspace admin** → **Settings** → **Login methods** to restore password-based authentication.

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.1 |
| NIST 800-53 | IA-2(1) |
| ISO 27001 | A.9.4.2 |
| PCI DSS | 8.4 |

#### Description
Require two-factor authentication (2FA) for all workspace users. When SSO is configured, MFA should be enforced at the IdP level; when SSO is not in use, enforce Workato's built-in 2FA.

#### Rationale
**Why This Matters:**
- Prevents unauthorized access even if passwords are compromised
- Required by most compliance frameworks
- Workato workspaces store credentials to connected systems — a compromise cascades to all integrations

**Attack Prevented:** Account takeover via credential theft, phishing, or password reuse.

#### Prerequisites
- [ ] Workato workspace with admin access
- [ ] Users have authenticator app installed (Google Authenticator, Microsoft Authenticator, Authy)

#### ClickOps Implementation

**Step 1: Enable Organization 2FA**
1. Navigate to: **Workspace admin** → **Settings** → **Security**
2. Enable **Require two-factor authentication**
3. All users must configure 2FA on their next login

**Step 2: Configure Supported Methods**
1. Workato supports TOTP authenticator apps:
   - Google Authenticator
   - Microsoft Authenticator
   - Authy
2. Users configure 2FA in their personal account settings

**Step 3: Enforce via IdP (When Using SSO)**
1. If using SSO, configure MFA in your IdP (Okta, Entra ID, etc.)
2. All SSO users are subject to IdP MFA policies
3. Use phishing-resistant methods (FIDO2/WebAuthn) for admin accounts

#### Validation & Testing
1. [ ] Attempt login without 2FA configured — verify 2FA setup prompt appears
2. [ ] Complete 2FA setup and verify successful login
3. [ ] Verify 2FA requirement applies to all collaborators

**Expected result:** No user can access the workspace without completing 2FA.

#### Monitoring & Maintenance
- Review audit log for failed 2FA attempts (may indicate credential compromise)
- Track 2FA enrollment completion across all collaborators
- Monitor for accounts with 2FA exemptions (should be zero)

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Low | One-time setup; additional 10 seconds per login |
| **System Performance** | None | No impact |
| **Maintenance Burden** | Low | Handle occasional 2FA recovery requests |
| **Rollback Difficulty** | Easy | Disable requirement in security settings |

---

### 1.3 Enforce SSO-Only Login

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.1 |
| NIST 800-53 | IA-2(12) |
| ISO 27001 | A.9.4.2 |

#### Description
After configuring SAML SSO (Control 1.1), enforce SSO as the **only** authentication method, disabling direct email/password login for all workspace users.

#### Rationale
**Why This Matters:**
- Eliminates password-based attack surface entirely
- Forces all authentication through your IdP's security controls (conditional access, device compliance, risk-based authentication)
- Ensures offboarded users lose Workato access immediately when disabled in IdP

**Attack Prevented:** Password-based attacks, orphaned accounts retaining access after offboarding.

#### Prerequisites
- [ ] SAML SSO configured and tested (Control 1.1)
- [ ] All active users can authenticate via SSO
- [ ] Emergency break-glass access procedure documented

#### ClickOps Implementation

**Step 1: Verify SSO Readiness**
1. Navigate to: **Workspace admin** → **Collaborators**
2. Confirm all active users have logged in via SSO at least once
3. Identify any service accounts or API-only users that may need exceptions

**Step 2: Enable SSO Enforcement**
1. Navigate to: **Workspace admin** → **Settings** → **Login methods**
2. Toggle **Require SSO for login** to enabled
3. Confirm the enforcement warning

**Step 3: Document Break-Glass Procedure**
1. Designate 1-2 admin accounts as emergency access
2. Store emergency credentials in a secure vault (not in Workato)
3. Document the procedure to temporarily disable SSO enforcement

#### Validation & Testing
1. [ ] Attempt direct password login — verify it is blocked
2. [ ] Verify SSO login still works for all user roles
3. [ ] Test break-glass procedure

**Expected result:** All login attempts redirect through the IdP. Direct password login returns an error.

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Low | No change for users already using SSO |
| **System Performance** | None | No impact |
| **Maintenance Burden** | Low | Maintain break-glass documentation |
| **Rollback Difficulty** | Easy | Disable enforcement to restore password login |

---

### 1.4 Configure Just-In-Time Provisioning

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.2 |
| NIST 800-53 | AC-2 |
| ISO 27001 | A.9.2.1 |

#### Description
Enable automatic user account creation on first SSO login, eliminating manual user provisioning and ensuring all users are sourced from the IdP.

#### ClickOps Implementation

**Step 1: Enable JIT Provisioning**
1. Navigate to: **Workspace admin** → **Settings** → **Login methods**
2. In SAML configuration, enable JIT provisioning
3. Users are created automatically on first SSO login

**Step 2: Configure Default Roles**
1. Set the default environment role for JIT-provisioned users (use the most restrictive role)
2. Configure via SAML attributes or assign manually after creation

**Step 3: Configure SAML Attributes for JIT**
1. Configure IdP to send in the SAML assertion:
   - `email` (required)
   - `first_name` (optional)
   - `last_name` (optional)
   - Role attributes (see Control 2.2 for SAML role sync)
2. User accounts are created from the assertion data

#### Validation & Testing
1. [ ] Remove a test user from Workato workspace
2. [ ] Have the user log in via SSO — verify account is auto-created
3. [ ] Verify the default role assignment is correct

**Expected result:** New users gain workspace access through SSO without manual admin provisioning.

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | None | Seamless — users don't notice JIT vs. pre-provisioned |
| **Maintenance Burden** | Low | Reduces admin work by eliminating manual provisioning |
| **Rollback Difficulty** | Easy | Disable JIT; revert to manual provisioning |

---

### 1.5 Configure SCIM Provisioning

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.2 |
| NIST 800-53 | AC-2(1) |
| ISO 27001 | A.9.2.1 |

#### Description
Configure SCIM (System for Cross-domain Identity Management) provisioning to automate user lifecycle management — creation, updates, and deactivation — from your IdP.

#### Rationale
**Why This Matters:**
- Automates complete user lifecycle (create, update, deactivate, delete)
- Ensures immediate deprovisioning when users are removed from IdP
- Eliminates orphaned accounts — critical for security in an iPaaS that stores credentials to dozens of connected systems
- Complements JIT provisioning with full lifecycle management

**Attack Prevented:** Orphaned account exploitation, unauthorized access via stale credentials.

#### Prerequisites
- [ ] SAML SSO configured and operational (Control 1.1)
- [ ] IdP that supports SCIM 2.0 (Okta, Microsoft Entra ID, OneLogin)
- [ ] Workato plan that supports SCIM provisioning

#### ClickOps Implementation

**Step 1: Generate SCIM Token**
1. Navigate to: **Workspace admin** → **Settings** → **API keys** (or Provisioning section)
2. Generate a SCIM provisioning token
3. Copy and store the token securely — it is only shown once

**Step 2: Configure SCIM in IdP**
1. In your IdP, add Workato as a SCIM application
2. Enter:
   - **SCIM Base URL:** `https://www.workato.com/scim/v2`
   - **Bearer Token:** The token from Step 1
3. Configure attribute mappings:
   - `userName` → email
   - `name.givenName` → first name
   - `name.familyName` → last name
4. Enable provisioning actions:
   - Create Users
   - Update User Attributes
   - Deactivate Users

**Step 3: Assign Users**
1. Assign users/groups to the Workato SCIM application in your IdP
2. Trigger initial provisioning sync
3. Verify users appear in Workato workspace

#### Code Implementation

**Option 1: Workato API — Manage Users Programmatically**
```bash
# List all managed users
curl -s "https://www.workato.com/api/managed_users" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, name, email, external_id}'

# Add a managed user
curl -s -X POST "https://www.workato.com/api/managed_users" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Doe",
    "email": "jane.doe@company.com",
    "external_id": "ext-12345",
    "role_name": "Analyst"
  }'

# Delete a managed user (deprovision)
curl -s -X DELETE "https://www.workato.com/api/managed_users/USER_ID" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN"
```

#### Validation & Testing
1. [ ] Create a test user in IdP — verify it appears in Workato within sync interval
2. [ ] Update user attributes in IdP — verify changes propagate
3. [ ] Deactivate user in IdP — verify Workato access is revoked
4. [ ] Verify no orphaned accounts exist in Workato that aren't in IdP

**Expected result:** User lifecycle is fully managed from the IdP. Deactivated IdP users cannot access Workato.

#### Monitoring & Maintenance
- Monitor SCIM provisioning logs in your IdP for sync failures
- Review Workato collaborator list monthly for accounts not managed by SCIM
- Alert on SCIM token expiration

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | None | Transparent to end users |
| **Maintenance Burden** | Low | Eliminates manual user management |
| **Rollback Difficulty** | Easy | Disable SCIM in IdP; revert to manual management |

---

### 1.6 Configure Session Security

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.6 |
| NIST 800-53 | AC-12 |
| ISO 27001 | A.9.4.2 |

#### Description
Configure session timeout duration to limit the window of opportunity for session hijacking on unattended workstations.

#### ClickOps Implementation

**Step 1: Access Session Settings**
1. Navigate to: **Workspace admin** → **Settings** → **General**
2. Find **Session timeout duration**

**Step 2: Configure Timeout**
1. Workato supports timeout durations from 15 minutes to 14 days (default: 7 days)
2. Set timeout based on environment sensitivity:
   - **L1:** 12 hours
   - **L2:** 4 hours
   - **L3:** 1 hour (or 15 minutes for highest sensitivity)
3. Apply to all users in the workspace

#### Validation & Testing
1. [ ] Log in, wait past timeout duration, verify session expires
2. [ ] Verify re-authentication is required after timeout

**Expected result:** Sessions expire after the configured duration; users must re-authenticate.

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Low-Medium | More frequent re-authentication at shorter timeouts |
| **Rollback Difficulty** | Easy | Increase timeout duration in settings |

---

## 2. Access Controls

### 2.1 Configure Role-Based Access Control

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.2, CC6.3 |
| NIST 800-53 | AC-6 |
| ISO 27001 | A.9.2.3 |
| PCI DSS | 7.1 |

#### Description
Implement least privilege access using Workato's two-level RBAC model: **environment roles** (workspace-wide access) and **project roles** (actions within specific projects).

#### Rationale
**Why This Matters:**
- Workato connects to critical business systems — excessive permissions let users access connections, credentials, and data across all integrations
- Separating environment and project roles provides granular control
- Essential for compliance and reduces blast radius of a compromised account

**Attack Prevented:** Privilege escalation, unauthorized data access through overpermissioned integration accounts.

#### Prerequisites
- [ ] Workato workspace with admin access
- [ ] Understanding of team structure and responsibilities

#### ClickOps Implementation

**Step 1: Understand Role Types**
1. **Environment roles** control access to workspace-level resources:
   - Admin, Analyst, Operator, custom roles
   - Control access to projects, tools, connections, and admin settings
2. **Project roles** control actions within individual projects:
   - Create, edit, deploy, delete assets
   - Manage connections within projects

**Step 2: Configure Environment Roles**
1. Navigate to: **Workspace admin** → **Collaborators**
2. For each collaborator, assign the minimum environment role:
   - **Admin:** Only 2-3 administrators (see Control 2.5)
   - **Analyst:** Users who build and test recipes
   - **Operator:** Users who monitor and run recipes
3. Avoid the Admin role for day-to-day users

**Step 3: Configure Project Roles**
1. Navigate to the project → **Settings** → **Collaborators**
2. Assign project-specific permissions:
   - **Create assets:** Who can create new recipes/connections
   - **Edit assets:** Who can modify existing recipes
   - **Deploy assets:** Who can promote to production (restrict tightly)
   - **Delete assets:** Who can remove assets (restrict to admins)
3. Apply least privilege per project

#### Code Implementation

**Option 1: Workato API — Manage Roles**
```bash
# List all custom roles in the workspace
curl -s "https://www.workato.com/api/roles" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, name, description}'

# Get details of a specific role
curl -s "https://www.workato.com/api/roles/ROLE_ID" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.'

# Create a custom role with specific permissions
curl -s -X POST "https://www.workato.com/api/roles" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Recipe Developer",
    "description": "Can build and test recipes but not deploy to production"
  }'
```

#### Validation & Testing
1. [ ] Log in as a non-admin user — verify restricted features are inaccessible
2. [ ] Attempt to access a project without assignment — verify access denied
3. [ ] Verify deploy permissions are limited to authorized roles only
4. [ ] Audit all collaborators and confirm minimum necessary roles

**Expected result:** Each user has only the permissions needed for their role. No user has admin access unless required.

#### Monitoring & Maintenance
- Review role assignments monthly
- Monitor audit log for permission escalation events
- Trigger review when team structure changes

---

### 2.2 Configure SAML Role Sync

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.2 |
| NIST 800-53 | AC-2(1) |
| ISO 27001 | A.9.2.3 |

#### Description
Automatically synchronize Workato roles from your IdP via SAML attributes, ensuring role assignments are centrally managed and automatically updated on each login.

#### ClickOps Implementation

**Step 1: Configure SAML Attributes (New Permissions Model)**
1. Configure your IdP to send the following attributes in the SAML assertion:
   - `workato_role` — Workspace-level environment role (e.g., `Admin`, `Analyst`, `Operator`)
   - `workato_role_test` — TEST environment role
   - `workato_role_prod` — PROD environment role
   - `workato_user_groups` — Comma-separated list of collaborator group names

**Step 2: Configure SAML Attributes (Legacy Model)**
1. If using the legacy permissions model:
   - `workato_role` — Workspace-level role
   - `workato_role_test` — TEST environment role
   - `workato_role_prod` — PROD environment role

**Step 3: Verify Sync**
1. Test user login via SSO
2. Verify role assignment matches IdP attribute values
3. Change role in IdP, re-login, verify role updates in Workato
4. Document IdP attribute-to-Workato role mappings

#### Validation & Testing
1. [ ] Login as user with assigned SAML role attribute — verify role in Workato matches
2. [ ] Change role attribute in IdP, re-login — verify Workato role updates
3. [ ] Remove role attribute — verify user gets default role

**Expected result:** Workato roles are fully managed from the IdP. No manual role assignment needed in Workato.

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | None | Transparent to users |
| **Maintenance Burden** | Low | Centralized role management reduces admin work |
| **Rollback Difficulty** | Easy | Remove SAML attributes; assign roles manually |

---

### 2.3 Configure Collaborator Groups

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.3 |
| NIST 800-53 | AC-6(1) |
| ISO 27001 | A.9.2.3 |

#### Description
Organize collaborators into groups aligned with team functions, and grant project access through group membership rather than individual assignments.

#### ClickOps Implementation

**Step 1: Create Groups**
1. Navigate to: **Workspace admin** → **Collaborator groups**
2. Create groups aligned with your organization:
   - `integration-developers` — Build and test recipes
   - `integration-operators` — Monitor and run recipes
   - `security-reviewers` — Review recipes and connections
   - `workspace-admins` — Full admin access (small group)
3. Define group-level environment roles

**Step 2: Assign Users to Groups**
1. Add collaborators to appropriate groups
2. Users inherit group permissions automatically
3. A user can belong to multiple groups (permissions are additive)

**Step 3: Configure Group Project Access**
1. Navigate to each project → **Settings** → **Collaborators**
2. Add groups (not individuals) to projects
3. Assign project roles per group:
   - `integration-developers`: Create and Edit
   - `integration-operators`: View and Run
   - `security-reviewers`: View only

#### Validation & Testing
1. [ ] Add user to a group — verify they gain project access
2. [ ] Remove user from group — verify project access is revoked
3. [ ] Verify no individual project assignments exist (all through groups)

---

### 2.4 Configure Custom Roles

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.3 |
| NIST 800-53 | AC-6(1) |
| ISO 27001 | A.9.2.3 |

#### Description
Create custom environment roles with granular permissions tailored to your organization's needs, going beyond the built-in roles (Admin, Analyst, Operator).

#### Rationale
**Why This Matters:**
- Built-in roles may be too broad or too narrow for your team structure
- Custom roles enable precise least-privilege access
- Separate deployment permissions from development permissions

#### ClickOps Implementation

**Step 1: Plan Custom Roles**
1. Map your team responsibilities to required Workato permissions
2. Example custom roles:
   - **Recipe Developer:** Create/edit recipes, manage test connections, no prod access
   - **Connection Manager:** Manage connections only, no recipe editing
   - **Deployment Approver:** Deploy to production, no recipe editing
   - **Auditor:** Read-only access to audit logs and recipe history

**Step 2: Create Custom Roles**
1. Navigate to: **Workspace admin** → **Roles**
2. Click **Create custom role**
3. Name the role descriptively
4. Select granular permissions for each category:
   - Recipe management
   - Connection management
   - Folder/project access
   - Admin tool access
   - API platform access

#### Code Implementation

**Option 1: Workato API — Create Custom Roles**
```bash
# Create a custom role with specific permissions
curl -s -X POST "https://www.workato.com/api/roles" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Deployment Approver",
    "description": "Can approve and execute deployments to production environments only"
  }'
```

#### Validation & Testing
1. [ ] Create a test user with the custom role
2. [ ] Verify the user can access permitted features
3. [ ] Verify the user cannot access restricted features
4. [ ] Test each permission boundary

---

### 2.5 Limit Admin Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.1, CC6.3 |
| NIST 800-53 | AC-6(5) |
| ISO 27001 | A.9.2.3 |
| PCI DSS | 7.1 |

#### Description
Minimize the number of workspace administrator accounts and implement strict controls around admin access.

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Navigate to: **Workspace admin** → **Collaborators**
2. Filter by admin role
3. Document all administrators and their business justification

**Step 2: Limit Admin Accounts**
1. Reduce to 2-3 admin accounts for redundancy
2. Remove admin access from users who don't require it
3. Use custom roles (Control 2.4) to grant specific admin-like permissions without full admin

**Step 3: Protect Admin Accounts**
1. Require phishing-resistant MFA (FIDO2/WebAuthn) for admin accounts at the IdP
2. Enable conditional access policies (e.g., restrict admin login to corporate network)
3. Monitor admin activity closely (see Control 8.1)

#### Code Implementation

**Option 1: Workato API — Audit Admin Users**
```bash
# List all workspace collaborators and filter for admins
curl -s "https://www.workato.com/api/managed_users" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '[.result[] | select(.role_name == "Admin")] |
    "Admin count: \(length)", .[] | {id, name, email}'
```

#### Validation & Testing
1. [ ] Count admin accounts — should be 2-3 maximum
2. [ ] Verify each admin has documented business justification
3. [ ] Verify admin accounts have enhanced MFA at IdP level
4. [ ] Review quarterly

**Expected result:** Admin count is minimal (2-3) with documented justification and enhanced authentication.

#### Monitoring & Maintenance
- Trigger admin access review when any admin role is assigned
- Review admin roster quarterly
- Alert when a new admin account is created

---

### 2.6 Implement Privilege Access Reviews

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.2 |
| NIST 800-53 | AC-2(3) |
| ISO 27001 | A.9.2.5 |

#### Description
Establish a recurring access review process to verify all Workato workspace collaborators have appropriate roles and remove stale or excessive access.

#### Code Implementation

**Option 1: Workato API — Generate Access Review Report**
```bash
# Export all collaborators with roles for access review
curl -s "https://www.workato.com/api/managed_users" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq -r '["Name","Email","Role","External ID"],
    (.result[] | [.name, .email, .role_name, .external_id]) |
    @csv' > workato_access_review_$(date +%Y%m%d).csv

echo "Access review export complete. Review and verify each entry."
```

#### ClickOps Implementation

**Step 1: Schedule Quarterly Reviews**
1. Navigate to: **Workspace admin** → **Collaborators**
2. Export the full collaborator list
3. Compare against HR active employee list
4. Identify:
   - Accounts for departed employees (remove immediately)
   - Accounts with roles exceeding job requirements (downgrade)
   - Service accounts with unclear ownership (investigate)

**Step 2: Execute the Review**
1. For each collaborator, verify role justification with their manager
2. Remove or downgrade access as needed
3. Document review results and actions taken
4. File as evidence for SOC 2 / ISO 27001 audits

#### Validation & Testing
1. [ ] Access review completed with documented results
2. [ ] All identified issues remediated
3. [ ] No accounts for departed employees remain

---

## 3. Data Protection & Encryption

### 3.1 Enable Encryption Key Management (EKM)

**Profile Level:** L3 (Maximum Security)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.7 |
| NIST 800-53 | SC-12, SC-28 |
| ISO 27001 | A.10.1.1 |
| PCI DSS | 3.5 |

#### Description
Enable Workato's Encryption Key Management (EKM) feature to use your own encryption keys (BYOK — Bring Your Own Key) for encrypting data at rest, including connection credentials, recipe data, and job history. By default, Workato manages encryption keys; EKM lets you control and revoke them.

#### Rationale
**Why This Matters:**
- Workato stores credentials for dozens of connected systems — if Workato's default encryption is compromised, ALL connected systems are exposed
- EKM gives you the "kill switch" — revoking your key makes all workspace data unreadable
- Required by many regulated industries (finance, healthcare, government)
- Meets NIST 800-53 SC-12 cryptographic key management requirements

**Attack Prevented:** Data exposure from infrastructure breach at Workato's cloud layer, insider threat at the platform provider level.

#### Prerequisites
- [ ] Workato Enterprise plan with EKM add-on
- [ ] AWS KMS key (Workato EKM uses AWS KMS)
- [ ] Key administrator access in AWS

#### ClickOps Implementation

**Step 1: Create AWS KMS Key**
1. In AWS Console → **KMS** → **Create key**
2. Choose **Symmetric** key type
3. Configure key policy to allow Workato's AWS account to use the key (Workato provides their AWS account ID during EKM setup)
4. Enable key rotation (recommended annually)

**Step 2: Configure EKM in Workato**
1. Contact Workato support or your CSM to enable EKM for your workspace
2. Provide the AWS KMS key ARN
3. Workato configures the workspace to use your key for encryption
4. All new data is encrypted with your key; existing data is re-encrypted during migration

**Step 3: Verify EKM Status**
1. Navigate to: **Workspace admin** → **Settings** → **Security**
2. Verify EKM is active and the correct key ARN is displayed

#### Code Implementation

**Option 1: AWS CLI — Create and Configure KMS Key**
```bash
# Create a KMS key for Workato EKM
aws kms create-key \
  --description "Workato EKM - Workspace encryption key" \
  --key-usage ENCRYPT_DECRYPT \
  --origin AWS_KMS \
  --tags TagKey=Application,TagValue=Workato TagKey=Environment,TagValue=Production

# Enable automatic key rotation
aws kms enable-key-rotation --key-id KEY_ID

# Verify key rotation is enabled
aws kms get-key-rotation-status --key-id KEY_ID
```

**Option 2: Terraform — AWS KMS Key for Workato EKM**
```hcl
resource "aws_kms_key" "workato_ekm" {
  description             = "Workato EKM - Workspace encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowKeyAdmin"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::YOUR_ACCOUNT_ID:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowWorkatoAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::WORKATO_ACCOUNT_ID:root"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Application = "Workato"
    Purpose     = "EKM-BYOK"
  }
}

resource "aws_kms_alias" "workato_ekm" {
  name          = "alias/workato-ekm"
  target_key_id = aws_kms_key.workato_ekm.key_id
}
```

#### Validation & Testing
1. [ ] Verify EKM status in Workato admin settings
2. [ ] Create a test connection — verify data is encrypted with your key
3. [ ] Temporarily disable the KMS key — verify Workato workspace becomes inaccessible (test in non-production)
4. [ ] Re-enable the key — verify workspace recovers

**Expected result:** All workspace data at rest is encrypted with your AWS KMS key. Revoking the key renders the workspace inoperable.

#### Monitoring & Maintenance
- Monitor AWS KMS key usage via CloudTrail
- Set CloudWatch alarms on key deletion or disablement
- Monitor key rotation schedule
- Review KMS key policy quarterly

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | None | Transparent to users |
| **System Performance** | Low | Minimal latency from KMS calls |
| **Maintenance Burden** | Medium | Key rotation, policy management, monitoring |
| **Rollback Difficulty** | Complex | Disabling EKM requires Workato support involvement |

**Potential Issues:**
- Accidental key deletion makes all workspace data permanently unrecoverable — use key deletion protection
- KMS region outage may temporarily impact Workato — use multi-region key configuration if available

---

### 3.2 Configure Data Masking

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.5 |
| NIST 800-53 | AC-3, SI-19 |
| ISO 27001 | A.8.11 |

#### Description
Protect sensitive data visible in job history, recipe logs, and debug output by configuring data masking for sensitive fields.

#### Rationale
**Why This Matters:**
- Job history displays input/output data for every recipe step — this can include PII, credentials, and financial data
- Any user with recipe access can view job history unless data masking is configured
- Compliance frameworks (GDPR, HIPAA, PCI DSS) require masking sensitive data in logs

#### ClickOps Implementation

**Step 1: Enable Data Masking for Recipes**
1. In recipe editor, identify steps that handle sensitive data
2. For each sensitive field, enable **data masking** in the field configuration
3. Masked fields show `****` in job history instead of actual values

**Step 2: Configure Job History Retention**
1. Navigate to: **Workspace admin** → **Settings**
2. Set job history retention period:
   - **L1:** 90 days (default)
   - **L2:** 30 days
   - **L3:** 7 days (or disable job history for sensitive recipes)
3. Shorter retention limits exposure window for sensitive data

**Step 3: Restrict Job History Access**
1. Configure project roles to limit who can view job history
2. Only users who need to debug recipes should have job history access
3. Use custom roles (Control 2.4) to separate debugging from monitoring

#### Validation & Testing
1. [ ] Run a recipe with masked fields — verify job history shows `****`
2. [ ] Verify non-admin users cannot see unmasked values
3. [ ] Verify job history retention aligns with policy

**Expected result:** Sensitive data is not visible in plain text in job history or debug logs.

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Low | Debugging requires extra steps when data is masked |
| **Maintenance Burden** | Medium | Must identify and mask new sensitive fields in each recipe |
| **Rollback Difficulty** | Easy | Remove masking per field |

---

### 3.3 Configure Data Retention Policies

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.5 |
| NIST 800-53 | SI-12 |
| ISO 27001 | A.8.10 |

#### Description
Configure data retention policies for job history, recipe versions, and audit logs to minimize data exposure while meeting compliance retention requirements.

#### ClickOps Implementation

**Step 1: Configure Job History Retention**
1. Navigate to: **Workspace admin** → **Settings**
2. Set retention period based on compliance needs:
   - PCI DSS: Minimum 1 year for audit logs
   - SOC 2: Retain for audit period
   - HIPAA: 6 years for audit logs
3. For job history (operational data): 30-90 days is typical

**Step 2: Archive Before Purge**
1. If long-term retention is needed, configure audit log streaming (Control 8.4) to export logs to your SIEM or data lake before Workato's retention window expires
2. This separates operational data (short retention in Workato) from compliance data (long retention in SIEM)

#### Validation & Testing
1. [ ] Verify job history retention is set to organizational policy
2. [ ] Verify audit log streaming captures events before retention expiry
3. [ ] Test that old job history is purged after retention period

---

### 3.4 Protect Environment Properties

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.7 |
| NIST 800-53 | SC-28 |
| ISO 27001 | A.10.1.1 |

#### Description
Secure sensitive values stored as Workato environment properties (account properties), which are workspace-level key-value pairs used in recipes.

#### Rationale
**Why This Matters:**
- Environment properties often store API keys, endpoints, and configuration values shared across recipes
- Properties marked as sensitive are encrypted and hidden in the UI
- Properties NOT marked sensitive are visible to all workspace collaborators

#### ClickOps Implementation

**Step 1: Audit Existing Properties**
1. Navigate to: **Workspace admin** → **Properties** (or **Settings** → **Properties**)
2. Review all properties for sensitive values
3. Any property containing a credential, API key, or secret should be marked sensitive

**Step 2: Mark Sensitive Properties**
1. For each sensitive property, enable the **Sensitive** toggle
2. Sensitive properties:
   - Are encrypted at rest
   - Display as `****` in the UI
   - Cannot be read back once set (write-only)
3. Non-sensitive properties: Use for non-secret configuration (e.g., environment URLs, feature flags)

#### Code Implementation

**Option 1: Workato API — Manage Properties**
```bash
# List all environment properties
curl -s "https://www.workato.com/api/properties" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {name, sensitive}'

# Create or update a sensitive property
curl -s -X POST "https://www.workato.com/api/properties" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "API_SECRET_KEY",
    "value": "sk-abc123...",
    "sensitive": true
  }'
```

#### Validation & Testing
1. [ ] Verify all properties containing secrets are marked as sensitive
2. [ ] Verify sensitive properties display as `****` in the UI
3. [ ] Verify non-admin users cannot read sensitive property values

---

## 4. Connection Security

### 4.1 Secure Connection Credentials

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.7 |
| NIST 800-53 | SC-12, IA-5 |
| ISO 27001 | A.10.1.1, A.9.4.3 |
| PCI DSS | 3.5, 8.6 |

#### Description
Secure credentials used for connections to external applications. Connections are the attack surface multiplier in Workato — each connection stores credentials to an external system.

#### Rationale
**Why This Matters:**
- A single Workato workspace may contain 50+ connections to business-critical systems (Salesforce, SAP, AWS, databases)
- If connection credentials are compromised, the attacker gains access to ALL connected systems
- All connection credentials are encrypted at rest by Workato (AES-256), but access controls and credential hygiene are your responsibility

**Attack Prevented:** Credential theft cascading to connected systems, lateral movement via compromised integration credentials.

#### ClickOps Implementation

**Step 1: Use Service Accounts for Connections**
1. Create dedicated service accounts in each connected application for Workato
2. Name them clearly: `svc-workato-salesforce`, `svc-workato-jira`
3. Grant minimum required permissions on the connected system
4. Never use admin or personal credentials for connections

**Step 2: Prefer OAuth Over API Keys**
1. When the connected application supports OAuth 2.0, use OAuth connections
2. OAuth advantages:
   - Token-based, automatically refreshed
   - Scoped permissions (limit access surface)
   - Easier to revoke without rotating API keys
   - Better audit trail in the connected system
3. Avoid long-lived API keys/passwords when OAuth is available

**Step 3: Establish Credential Rotation Schedule**
1. For API key connections: rotate every 90 days
2. For OAuth connections: revoke and re-authorize annually
3. After rotation, update the connection in Workato and verify all dependent recipes

#### Code Implementation

**Option 1: Workato API — Audit Connections**
```bash
# List all connections with their status
curl -s "https://www.workato.com/api/connections" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, name, provider, connected: .authorized}'

# List connections in a specific folder/project
curl -s "https://www.workato.com/api/connections?folder_id=FOLDER_ID" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, name, provider}'
```

#### Validation & Testing
1. [ ] All connections use service accounts (not personal credentials)
2. [ ] OAuth is used where available instead of API keys
3. [ ] Credential rotation schedule is documented and enforced
4. [ ] Each connection's service account has least-privilege access in the connected system

**Expected result:** Every connection uses a dedicated service account with minimum permissions. OAuth is preferred over static credentials.

#### Monitoring & Maintenance
- Review connection health weekly (disconnected connections may indicate expired credentials)
- Track credential rotation dates in a secrets manager
- Alert when connections become unauthorized/disconnected

---

### 4.2 Configure Connection Permissions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.3 |
| NIST 800-53 | AC-6 |
| ISO 27001 | A.9.4.1 |

#### Description
Control who can view, use, and manage connections within the workspace to prevent unauthorized access to connected system credentials.

#### ClickOps Implementation

**Step 1: Configure Connection Sharing Scope**
1. Navigate to connection settings for each connection
2. Set sharing scope:
   - **Project members only** (recommended — most restrictive)
   - **Specific collaborators** (when cross-project sharing is needed)
   - **All workspace users** (avoid for sensitive connections)

**Step 2: Restrict Connection Management**
1. Limit who can edit connections (change credentials) to connection owners and admins
2. Limit who can view connection configuration to those who need it
3. Regular recipe developers should only need to **use** connections, not **manage** them

**Step 3: Organize Connections by Project**
1. Keep connections within the project that uses them
2. Remove unused connections
3. Document the purpose and owner for each connection

#### Validation & Testing
1. [ ] Log in as a non-admin user — verify limited connection visibility
2. [ ] Verify connection credentials are not viewable by unauthorized users
3. [ ] Audit connection sharing — no connections shared workspace-wide unless justified

---

### 4.3 Configure On-Premises Agents (OPA)

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.6 |
| NIST 800-53 | AC-17, SC-7 |
| ISO 27001 | A.13.1.1 |

#### Description
Deploy and secure Workato On-Premises Agents (OPA) for accessing applications and databases behind firewalls without exposing them to the internet.

#### Rationale
**Why This Matters:**
- OPA creates an outbound-only connection from your network to Workato's cloud — no inbound firewall rules needed
- Without OPA, connecting to on-premises systems would require exposing them to the internet
- OPA agents handle sensitive data in transit between your network and Workato's cloud

**Attack Prevented:** Exposure of on-premises systems to the internet, unauthorized network access.

#### Prerequisites
- [ ] On-premises server or VM for the agent (Linux or Windows)
- [ ] Outbound HTTPS (443) access to Workato's cloud
- [ ] Workato plan that includes OPA feature

#### ClickOps Implementation

**Step 1: Deploy Agents Securely**
1. Install the OPA on a hardened server (not a user workstation)
2. Use a dedicated service account for the agent process
3. Restrict the agent's network access to only the systems it needs to reach
4. Place the agent in a DMZ or dedicated network segment

**Step 2: Configure Agent Groups for High Availability**
1. Deploy 2+ agents in an agent group for redundancy
2. Navigate to: **Workspace admin** → **On-prem agents**
3. Create an agent group and add both agents
4. Workato load-balances across agents in the group

**Step 3: Harden the Agent Host**
1. Keep the agent software updated to the latest version
2. Enable OS-level firewall — allow only outbound 443 to Workato's cloud endpoints
3. Restrict local access to the agent configuration directory
4. Protect the agent key file (contains authentication credentials)

#### Code Implementation

**Option 1: Docker — Deploy OPA in Container**
```bash
# Pull the Workato OPA Docker image
docker pull workato/agent:latest

# Run the agent with configuration
docker run -d \
  --name workato-opa \
  --restart unless-stopped \
  -v /opt/workato/conf:/opt/workato/conf:ro \
  -v /opt/workato/data:/opt/workato/data \
  workato/agent:latest

# Verify agent is running and connected
docker logs workato-opa | grep -i "connected"
```

**Option 2: Linux — Agent Configuration**
```bash
# Agent configuration file (/opt/workato/conf/config.yml)
# Set connection profiles for on-prem databases
# Key security settings:

# Restrict agent to specific connection profiles only
# Do not use wildcard access
```

#### Validation & Testing
1. [ ] Verify agent status shows "Active" in Workato admin
2. [ ] Test a connection through the agent — verify data flows correctly
3. [ ] Verify agent host firewall blocks all inbound connections
4. [ ] Verify agent group failover works (stop one agent, verify the other handles traffic)

#### Monitoring & Maintenance
- Monitor agent connection status in Workato admin
- Set alerts for agent disconnections
- Update agent software within 30 days of new releases
- Review agent host security patches monthly

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | None | Transparent to recipe developers |
| **System Performance** | Low | Agent adds minimal latency for on-prem connections |
| **Maintenance Burden** | Medium | Agent host patching, agent updates, monitoring |
| **Rollback Difficulty** | Moderate | Removing agent breaks on-prem connections |

---

### 4.4 Configure IP Allowlisting

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.6 |
| NIST 800-53 | AC-3, SC-7 |
| ISO 27001 | A.13.1.1 |

#### Description
Restrict Workato workspace access to specific IP addresses or CIDR ranges, limiting where users and API clients can connect from.

#### ClickOps Implementation

**Step 1: Enable IP Allowlisting**
1. Navigate to: **Workspace admin** → **Settings** → **Security**
2. Enable **IP allowlisting**
3. Add your corporate network IP ranges (CIDR notation)

**Step 2: Add Required IP Ranges**
1. Add your corporate office IP ranges
2. Add VPN exit node IPs
3. Add any CI/CD system IPs that call Workato APIs
4. Do NOT add overly broad ranges (e.g., `/8` blocks)

**Step 3: Test Before Enforcing**
1. Add your current IP to the allowlist first
2. Enable enforcement
3. Test from an allowed IP — verify access works
4. Test from a non-allowed IP — verify access is blocked

#### Validation & Testing
1. [ ] Access workspace from allowed IP — succeeds
2. [ ] Access workspace from non-allowed IP — blocked
3. [ ] API calls from allowed IPs — succeed
4. [ ] API calls from non-allowed IPs — blocked

**Expected result:** Only connections from explicitly allowed IP ranges can access the workspace.

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Remote workers need VPN; mobile access may be blocked |
| **Maintenance Burden** | Medium | Must update when office IPs change or VPN infrastructure changes |
| **Rollback Difficulty** | Easy | Disable IP allowlisting in settings |

**Potential Issues:**
- Locking yourself out — always add your current IP before enabling enforcement
- Remote workers without VPN lose access — plan for VPN or conditional exceptions

---

### 4.5 Secure Webhook Endpoints

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.6 |
| NIST 800-53 | SC-8, SI-10 |
| ISO 27001 | A.14.1.2 |

#### Description
Secure webhook-triggered recipes by implementing signature verification, IP allowlisting, and input validation to prevent unauthorized recipe triggering.

#### Rationale
**Why This Matters:**
- Webhook URLs are publicly accessible endpoints that trigger recipe execution
- An attacker who discovers a webhook URL can trigger recipes with arbitrary payloads
- Without verification, webhook-triggered recipes are vulnerable to injection and abuse

**Attack Prevented:** Unauthorized recipe triggering, webhook payload injection, denial-of-service via webhook flooding.

#### ClickOps Implementation

**Step 1: Enable Webhook Signature Verification**
1. In the webhook trigger configuration, enable signature verification
2. Workato generates a unique signature key for the webhook
3. The sending system must include a valid HMAC signature in the request header
4. Configure the webhook to reject requests with invalid or missing signatures

**Step 2: Restrict Webhook Source IPs**
1. If the sending system has static IPs, add IP allowlisting to the webhook trigger
2. Configure the webhook to only accept requests from known source IPs
3. Document the expected source IP addresses

**Step 3: Validate Webhook Payloads**
1. Add input validation steps at the beginning of webhook-triggered recipes
2. Validate expected fields, data types, and value ranges
3. Reject and log payloads that don't match expected schema
4. Never use webhook payload data directly in database queries or system commands

#### Validation & Testing
1. [ ] Send a webhook with valid signature — recipe triggers successfully
2. [ ] Send a webhook with invalid signature — recipe does not trigger
3. [ ] Send a webhook from non-allowed IP — request is rejected
4. [ ] Send a malformed payload — recipe handles gracefully without processing

---

## 5. API Security

### 5.1 Configure API Platform Security

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.1, CC6.6 |
| NIST 800-53 | AC-3, SC-8 |
| ISO 27001 | A.14.1.2 |

#### Description
Secure the Workato API Platform, which allows you to expose recipes as API endpoints for external consumers. Configure authentication, access control, and rate limiting for exposed APIs.

#### Rationale
**Why This Matters:**
- The API Platform exposes internal automation as external endpoints — misconfiguration creates a direct attack surface
- API endpoints may expose sensitive data or trigger critical business processes
- Without proper access control, anyone who discovers the API URL can access it

#### Prerequisites
- [ ] Workato plan that includes API Platform feature
- [ ] Understanding of which recipes need to be exposed as APIs

#### ClickOps Implementation

**Step 1: Create API Collections**
1. Navigate to: **API Platform** → **API Collections**
2. Create collections to organize related endpoints
3. Map recipe endpoints to collections logically (e.g., by business domain)

**Step 2: Configure Access Profiles**
1. Navigate to: **API Platform** → **Clients**
2. Create API clients for each consumer
3. Choose authentication method:
   - **Auth Token:** Simple bearer token (default)
   - **OAuth 2.0:** For delegated authorization flows
   - **JWT (JSON Web Tokens):** For service-to-service authentication
   - **OIDC (OpenID Connect):** For identity-aware API authentication
   - **mTLS (Mutual TLS):** For highest-security machine-to-machine communication (L3)
4. Assign clients to specific API collections (least privilege — only the collections they need)

**Step 3: Configure API Policies**
1. Navigate to: **API Platform** → **Policies**
2. Create policies for:
   - Rate limiting (requests per second/minute)
   - IP allowlisting (restrict to consumer's IP range)
   - Request size limits

#### Code Implementation

**Option 1: Workato API — Manage API Clients**
```bash
# List all API clients
curl -s "https://www.workato.com/api/api_clients" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, name, created_at}'

# Create a new API client
curl -s -X POST "https://www.workato.com/api/api_clients" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "partner-system-prod",
    "description": "Production API access for Partner System"
  }'

# List API access profiles
curl -s "https://www.workato.com/api/api_access_profiles" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, name, api_client_id, api_collection_ids}'
```

#### Validation & Testing
1. [ ] Call API endpoint with valid client token — succeeds
2. [ ] Call API endpoint with invalid/missing token — returns 401
3. [ ] Call API endpoint from non-allowed IP — returns 403
4. [ ] Exceed rate limit — returns 429

---

### 5.2 Implement API Rate Limiting

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.6 |
| NIST 800-53 | SC-5 |
| ISO 27001 | A.14.1.2 |

#### Description
Configure rate limiting on API Platform endpoints to prevent abuse, denial-of-service, and excessive resource consumption.

#### ClickOps Implementation

**Step 1: Define Rate Limits per Client**
1. Navigate to: **API Platform** → **Policies**
2. Set rate limits based on expected usage:
   - **Standard clients:** 100 requests/minute
   - **High-volume clients:** 500 requests/minute (with justification)
   - **Internal tools:** Adjust based on actual usage patterns
3. Apply policies to API access profiles

**Step 2: Monitor Rate Limit Usage**
1. Review API Platform dashboard for usage patterns
2. Identify clients approaching limits
3. Adjust limits based on legitimate usage patterns

#### Validation & Testing
1. [ ] Send requests at normal rate — all succeed
2. [ ] Exceed rate limit — requests return HTTP 429
3. [ ] Verify rate limits are per-client, not global

---

### 5.3 Manage Workato Platform API Keys

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.1 |
| NIST 800-53 | IA-5, SC-12 |
| ISO 27001 | A.9.4.2 |

#### Description
Securely manage Workato Platform API keys (used to call Workato's own management API for managing recipes, connections, deployments, etc.).

#### Rationale
**Why This Matters:**
- Workato API keys provide full programmatic access to workspace management — recipes, connections, users, deployments
- A leaked API key allows an attacker to exfiltrate all connection credentials, modify recipes, or deploy malicious automations
- API keys are workspace-scoped and carry the permissions of the user who created them

#### ClickOps Implementation

**Step 1: Minimize API Key Count**
1. Navigate to: **Workspace admin** → **Settings** → **API keys**
2. Audit all existing API keys
3. Delete keys that are unused or whose purpose is unknown
4. Document the purpose and owner of each active key

**Step 2: Secure API Key Storage**
1. Never store API keys in:
   - Source code repositories
   - Recipe text fields
   - Environment properties (unless marked sensitive)
   - Email or chat messages
2. Store API keys in:
   - Organization secrets manager (HashiCorp Vault, AWS Secrets Manager)
   - CI/CD platform secret storage (GitHub Actions secrets, GitLab CI variables)

**Step 3: Rotate API Keys**
1. Rotate API keys every 90 days
2. Update all integrations using the old key before deactivating it
3. Deactivate the old key only after verifying all integrations use the new key

> **Deprecation Notice:** Workato deprecated legacy API keys in July 2025. Workspaces should migrate to the newer authentication method (workspace-level API tokens). The v1 API Platform was also deprecated in December 2025 — migrate to the v2 API Platform for API client management. Verify your workspace is using current authentication methods.

#### Validation & Testing
1. [ ] All API keys have documented owners and purposes
2. [ ] No API keys exist in source code or configuration files
3. [ ] API key rotation schedule is documented and followed
4. [ ] No legacy (deprecated) API keys remain — all migrated to current tokens

---

## 6. Secrets Management

### 6.1 Configure External Secrets Manager Integration

**Profile Level:** L3 (Maximum Security)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.7 |
| NIST 800-53 | SC-12, IA-5(7) |
| ISO 27001 | A.10.1.2 |
| PCI DSS | 3.5 |

#### Description
Integrate Workato with an external secrets manager (HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, or GCP Secret Manager) to store and retrieve connection credentials dynamically instead of storing them directly in Workato.

#### Rationale
**Why This Matters:**
- Eliminates credential storage in Workato entirely — Workato retrieves credentials at runtime from your vault
- Centralizes credential management across all tools, not just Workato
- Enables automated credential rotation without updating Workato connections
- Provides a complete audit trail of credential access in your vault's logs

**Attack Prevented:** Credential exposure from Workato platform compromise, credential sprawl across multiple systems.

#### Prerequisites
- [ ] External secrets manager deployed and configured (HashiCorp Vault, AWS Secrets Manager, etc.)
- [ ] Workato plan that supports secrets manager integration
- [ ] Network connectivity between Workato (or OPA) and the secrets manager

#### ClickOps Implementation

**Step 1: Configure Secrets Manager Connection**
1. Navigate to: **Workspace admin** → **Settings** → **Secrets management**
2. Select your secrets manager provider
3. Configure connection details:
   - **HashiCorp Vault:** Vault URL, authentication method, role
   - **AWS Secrets Manager:** IAM role or access key, region
   - **Azure Key Vault:** Tenant ID, client ID, vault URL
4. Test the connection

**Step 2: Migrate Connection Credentials**
1. Store existing connection credentials in your secrets manager
2. Update Workato connections to reference secrets manager paths instead of inline credentials
3. Verify each connection works with the external secret reference
4. Remove inline credentials once external references are confirmed working

#### Code Implementation

**Option 1: AWS CLI — Store Workato Connection Secrets**
```bash
# Store a connection credential in AWS Secrets Manager
aws secretsmanager create-secret \
  --name "workato/connections/salesforce-prod" \
  --description "Workato Salesforce production connection credentials" \
  --secret-string '{
    "client_id": "3MVG9...",
    "client_secret": "...",
    "refresh_token": "..."
  }' \
  --tags Key=Application,Value=Workato Key=Connection,Value=Salesforce

# Enable automatic rotation (90-day cycle)
aws secretsmanager rotate-secret \
  --secret-id "workato/connections/salesforce-prod" \
  --rotation-rules AutomaticallyAfterDays=90
```

**Option 2: Terraform — AWS Secrets Manager for Workato**
```hcl
resource "aws_secretsmanager_secret" "workato_salesforce" {
  name        = "workato/connections/salesforce-prod"
  description = "Workato Salesforce production connection credentials"

  tags = {
    Application = "Workato"
    Connection  = "Salesforce"
    Environment = "Production"
  }
}

resource "aws_secretsmanager_secret_rotation" "workato_salesforce" {
  secret_id           = aws_secretsmanager_secret.workato_salesforce.id
  rotation_lambda_arn = aws_lambda_function.secret_rotation.arn

  rotation_rules {
    automatically_after_days = 90
  }
}
```

#### Validation & Testing
1. [ ] Verify connections using secrets manager references work correctly
2. [ ] Rotate a secret in the vault — verify Workato connection continues working with new credential
3. [ ] Remove vault access — verify Workato connection fails (no fallback to cached credentials)
4. [ ] Verify vault audit logs show Workato credential access events

**Expected result:** No credentials stored directly in Workato. All credentials retrieved at runtime from external secrets manager.

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | None | Transparent to recipe developers |
| **System Performance** | Low | Additional latency for secret retrieval at connection time |
| **Maintenance Burden** | Medium | Vault infrastructure management, rotation configuration |
| **Rollback Difficulty** | Moderate | Must re-enter credentials directly into Workato connections |

---

### 6.2 Secure Environment Properties

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.7 |
| NIST 800-53 | SC-28 |
| ISO 27001 | A.10.1.1 |

#### Description
Ensure all sensitive values stored as Workato environment properties (account properties) are properly classified and protected. See Control 3.4 for detailed implementation.

> This control cross-references Control 3.4 (Protect Environment Properties) for the full implementation procedure. Ensure sensitive properties are marked as sensitive, which encrypts them at rest and hides them in the UI.

---

## 7. Environment & Deployment Security

### 7.1 Configure Environment Separation

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC8.1 |
| NIST 800-53 | CM-3, SA-10 |
| ISO 27001 | A.14.2.1 |
| PCI DSS | 6.4 |

#### Description
Configure separate Workato environments (DEV, TEST, PROD) to isolate recipe development from production execution, preventing untested changes from impacting live business processes.

#### Rationale
**Why This Matters:**
- Without environment separation, recipe changes go directly to production — a misconfigured recipe can corrupt data across connected systems in real time
- Separation enables proper testing and change management
- Required by PCI DSS, SOC 2, and most enterprise security policies

#### Prerequisites
- [ ] Workato plan that supports multiple environments (Workspace plan or higher)
- [ ] Environments provisioned by Workato (DEV, TEST, PROD)

#### ClickOps Implementation

**Step 1: Verify Environment Setup**
1. Navigate to: **Workspace admin** → **Environments**
2. Confirm you have at least DEV and PROD environments
3. Verify each environment has its own connections (different credentials per environment)

**Step 2: Configure Environment-Specific Connections**
1. In each environment, create connections that point to the correct system:
   - DEV: Development/sandbox instances of connected apps
   - TEST: Staging/test instances
   - PROD: Production instances
2. Never use production credentials in DEV/TEST environments

**Step 3: Restrict Environment Access**
1. Configure environment roles (see Control 2.1):
   - **DEV:** Developers have full access
   - **TEST:** Developers can deploy; testers can run
   - **PROD:** Only authorized deployers can deploy; operators monitor
2. Use SAML role sync (Control 2.2) to automate environment role assignment

#### Validation & Testing
1. [ ] Verify DEV and PROD environments use different connections
2. [ ] Verify developers cannot deploy directly to PROD
3. [ ] Verify PROD environment has restricted access

**Expected result:** Recipe changes flow DEV → TEST → PROD through a controlled deployment process. No direct production changes.

---

### 7.2 Configure Recipe Lifecycle Management (RLCM)

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC8.1 |
| NIST 800-53 | CM-3, SA-10 |
| ISO 27001 | A.14.2.2 |
| PCI DSS | 6.5 |

#### Description
Configure Workato's Recipe Lifecycle Management (RLCM) to enforce a formal deployment pipeline with version control, deployment packages, and approval workflows.

#### Rationale
**Why This Matters:**
- RLCM provides Git-like version control and deployment management for recipes
- Deployment packages create auditable, repeatable deployments
- Approval workflows prevent unauthorized production changes
- Essential for SOC 2 change management controls

#### ClickOps Implementation

**Step 1: Enable RLCM**
1. Navigate to: **Workspace admin** → **Settings** → **Recipe lifecycle management**
2. Enable RLCM for the workspace
3. Configure the deployment pipeline: DEV → TEST → PROD

**Step 2: Configure Deployment Packages**
1. In the DEV environment, create a deployment package
2. Select recipes, connections, and lookup tables to include
3. Add a description of changes (like a commit message)
4. Submit the package for deployment

**Step 3: Configure Deployment Approvals**
1. In **Workspace admin** → **Settings** → **RLCM**
2. Enable deployment approvals for PROD environment
3. Designate approval roles (e.g., only workspace admins or designated deployment approvers)
4. Require at least one approval before PROD deployment

#### Code Implementation

**Option 1: Workato API — Manage Deployments**
```bash
# List deployment packages
curl -s "https://www.workato.com/api/deployments" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, name, state, created_at}'

# Create a deployment package
curl -s -X POST "https://www.workato.com/api/packages/export/MANIFEST_ID" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" \
  -H "Content-Type: application/json"

# Import a package into target environment
curl -s -X POST "https://www.workato.com/api/packages/import/FOLDER_ID" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @package.zip
```

#### Validation & Testing
1. [ ] Create a deployment package in DEV — verify it's created successfully
2. [ ] Attempt to deploy to PROD without approval — verify it's blocked
3. [ ] Approve and deploy to PROD — verify successful deployment
4. [ ] Verify deployment history shows complete audit trail

#### Monitoring & Maintenance
- Review deployment logs for unauthorized deployment attempts
- Monitor for recipes modified directly in PROD (should be zero with RLCM)
- Alert on deployment failures

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Developers must use the deployment pipeline, not direct edits |
| **System Performance** | None | No runtime impact |
| **Maintenance Burden** | Low | Approval workflow is lightweight |
| **Rollback Difficulty** | Easy | Re-deploy a previous package version |

---

### 7.3 Implement CI/CD Pipeline Integration

**Profile Level:** L3 (Maximum Security)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC8.1 |
| NIST 800-53 | SA-10, CM-3 |
| ISO 27001 | A.14.2.2 |

#### Description
Integrate Workato's deployment process with your CI/CD pipeline to automate testing, approval, and deployment of recipe packages using the Workato API and CLI.

#### Code Implementation

**Option 1: GitHub Actions — Workato CI/CD Pipeline**
```yaml
# .github/workflows/workato-deploy.yml
name: Workato Recipe Deployment
on:
  push:
    branches: [main]
    paths: ['workato/**']

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate recipe package
        run: |
          # Verify the export manifest exists and is valid
          curl -sf "https://www.workato.com/api/packages/export/${{ vars.MANIFEST_ID }}" \
            -H "Authorization: Bearer ${{ secrets.WORKATO_DEV_TOKEN }}" \
            -o package.zip
          # Verify package is not empty
          test -s package.zip || exit 1

  deploy:
    needs: validate
    runs-on: ubuntu-latest
    environment: production  # Requires manual approval in GitHub
    steps:
      - uses: actions/checkout@v4

      - name: Export package from DEV
        run: |
          curl -sf -X POST \
            "https://www.workato.com/api/packages/export/${{ vars.MANIFEST_ID }}" \
            -H "Authorization: Bearer ${{ secrets.WORKATO_DEV_TOKEN }}" \
            -o package.zip

      - name: Import package to PROD
        run: |
          curl -sf -X POST \
            "https://www.workato.com/api/packages/import/${{ vars.PROD_FOLDER_ID }}" \
            -H "Authorization: Bearer ${{ secrets.WORKATO_PROD_TOKEN }}" \
            -H "Content-Type: application/octet-stream" \
            --data-binary @package.zip

      - name: Verify deployment
        run: |
          # Check that recipes in the target folder are active
          curl -sf "https://www.workato.com/api/recipes?folder_id=${{ vars.PROD_FOLDER_ID }}" \
            -H "Authorization: Bearer ${{ secrets.WORKATO_PROD_TOKEN }}" | \
            jq '.result[] | {name, running, updated_at}'
```

**Option 2: Workato CLI — Connector Development & Testing**
```bash
# Install Workato CLI (Ruby gem)
gem install workato

# Generate a new connector scaffold
workato generate connector my-connector

# Validate connector code locally
workato exec actions.my_action \
  --connector my-connector \
  --input '{"key": "value"}'

# Run connector test suite
workato generate test --connector my-connector
workato exec triggers.my_trigger --connector my-connector

# Push validated connector to Workato workspace
workato push --connector my-connector --token $WORKATO_API_TOKEN
```

**Option 3: Workato API — Recipe Management for CI/CD**
```bash
# List all recipes in a project folder
curl -s "https://www.workato.com/api/recipes?folder_id=FOLDER_ID" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, name, running, version}'

# Stop a recipe before deployment
curl -s -X PUT "https://www.workato.com/api/recipes/RECIPE_ID/stop" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN"

# Start a recipe after deployment
curl -s -X PUT "https://www.workato.com/api/recipes/RECIPE_ID/start" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN"

# Get recipe versions (audit trail)
curl -s "https://www.workato.com/api/recipes/RECIPE_ID/versions" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {version, created_at, comment}'
```

> **Note on Terraform:** As of early 2026, there is no official Workato Terraform provider. For IaC, use the Workato API via the [Mastercard/restapi](https://registry.terraform.io/providers/Mastercard/restapi/latest) generic REST Terraform provider, or manage deployments through the API-based CI/CD pipeline shown above.

#### Validation & Testing
1. [ ] CI/CD pipeline triggers on code push
2. [ ] Package is exported from DEV environment
3. [ ] Deployment requires manual approval for production
4. [ ] Package is imported to PROD environment
5. [ ] Pipeline fails gracefully on errors (doesn't corrupt PROD)
6. [ ] Post-deployment verification confirms recipes are active

---

## 8. Monitoring & Compliance

### 8.1 Configure Activity Audit Log

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC7.2 |
| NIST 800-53 | AU-2, AU-3 |
| ISO 27001 | A.12.4.1 |
| PCI DSS | 10.2 |

#### Description
Enable and actively monitor Workato's Activity Audit Log, which records significant user actions including logins, recipe changes, connection modifications, and admin operations.

#### Rationale
**Why This Matters:**
- The audit log is your primary visibility into who did what in Workato
- Required for SOC 2, PCI DSS, HIPAA, and ISO 27001 compliance
- Essential for incident investigation and forensics
- Workato records events automatically — but reviewing and acting on them is your responsibility

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Workspace admin** → **Activity audit log**
2. Review logged events including:
   - User logins (success and failure)
   - Recipe create/edit/delete/start/stop
   - Connection create/edit/delete
   - Collaborator add/remove/role change
   - API key create/revoke
   - Admin setting changes
   - Deployment events

**Step 2: Configure Log Retention**
1. Workato retains audit logs for a defined period based on your plan
2. For compliance, stream logs to external storage before retention expires (see Control 8.4)

**Step 3: Establish Monitoring Routine**
1. Review audit logs weekly for anomalies:
   - Logins from unusual locations or times
   - Bulk recipe modifications
   - Admin role assignments
   - Connection credential changes
   - Failed authentication attempts

#### Code Implementation

**Option 1: Workato API — Query Audit Logs**
```bash
# Retrieve recent audit log events
curl -s "https://www.workato.com/api/activity_logs?page=1&per_page=100" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {
    timestamp: .created_at,
    user: .user_name,
    event: .event_type,
    resource: .resource_type,
    details: .details
  }'

# Filter for admin actions only
curl -s "https://www.workato.com/api/activity_logs?event_type=admin_action" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {timestamp: .created_at, user: .user_name, details: .details}'

# Export audit logs for compliance archive
curl -s "https://www.workato.com/api/activity_logs?page=1&per_page=500" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result' > audit_log_$(date +%Y%m%d).json
```

#### Validation & Testing
1. [ ] Perform a logged action (e.g., start/stop a recipe) — verify it appears in audit log
2. [ ] Verify login events are recorded with IP address and timestamp
3. [ ] Verify admin actions are recorded with details

**Expected result:** All significant workspace actions are recorded in the audit log with user, timestamp, event type, and details.

#### Monitoring & Maintenance
**Alert on these events:**
- Admin role granted to a user
- API key created or revoked
- SSO settings changed
- Multiple failed login attempts from same user
- Recipe deployed to PROD outside business hours
- Connection credentials changed

---

### 8.2 Configure Audit Log Streaming

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC7.2, CC7.3 |
| NIST 800-53 | AU-4, AU-6 |
| ISO 27001 | A.12.4.1, A.12.4.3 |
| PCI DSS | 10.5 |

#### Description
Configure real-time streaming of Workato audit logs to an external SIEM or log aggregation platform for long-term retention, correlation, and alerting.

#### Rationale
**Why This Matters:**
- Workato's built-in audit log has limited retention and search capabilities
- Streaming to a SIEM enables correlation with events from other systems
- Long-term log retention is required for compliance (PCI DSS: 1 year, HIPAA: 6 years)
- External log storage prevents log tampering by compromised admin accounts

#### ClickOps Implementation

**Step 1: Configure Log Streaming Destination**
1. Navigate to: **Workspace admin** → **Settings** → **Activity audit log** → **Streaming**
2. Select your destination:
   - Amazon S3
   - Sumo Logic
   - Datadog
   - Splunk
   - Custom webhook endpoint
3. Configure the connection credentials for your destination

**Step 2: Verify Streaming**
1. Perform a test action in Workato
2. Verify the event appears in your destination
3. Confirm timestamp and event details match

**Step 3: Configure SIEM Alerts**
1. In your SIEM, create detection rules for Workato events:
   - Admin role escalation
   - Bulk recipe modifications
   - Connection credential changes outside change windows
   - API key creation
   - SSO configuration changes

#### Code Implementation

**Option 1: Splunk — Workato Event Detection Queries**
```plaintext
# Detect admin role changes
index=workato sourcetype=workato:audit event_type="collaborator_role_change"
| where new_role="Admin"
| table _time, user_name, target_user, old_role, new_role

# Detect recipe deployments outside business hours
index=workato sourcetype=workato:audit event_type="deployment"
| where date_hour<8 OR date_hour>18
| table _time, user_name, resource_name, details

# Detect multiple failed logins
index=workato sourcetype=workato:audit event_type="login_failed"
| stats count by user_name, src_ip
| where count > 5
```

#### Validation & Testing
1. [ ] Verify events stream within expected latency (< 5 minutes)
2. [ ] Verify all event types appear in the destination
3. [ ] Verify SIEM detection rules trigger on test events
4. [ ] Verify log retention meets compliance requirements

---

### 8.3 Configure Recipe Error Monitoring

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC7.2 |
| NIST 800-53 | CA-7 |
| ISO 27001 | A.12.1.3 |

#### Description
Configure monitoring for recipe execution errors to detect integration failures, data processing issues, and potential security events.

#### ClickOps Implementation

**Step 1: Configure Error Notifications**
1. For each critical recipe, configure error notifications:
   - Navigate to recipe → **Settings** → **Notifications**
   - Enable email notifications for job errors
   - Configure the notification recipients (integration team and security team)

**Step 2: Set Up Systematic Monitoring**
1. Create a monitoring recipe that periodically checks for failed jobs across the workspace
2. Alert to Slack, email, or PagerDuty for critical recipe failures
3. Classify recipe criticality:
   - **Critical:** Financial transactions, user provisioning, security workflows
   - **Standard:** Data sync, notifications, non-critical automation

**Step 3: Monitor for Security-Relevant Errors**
1. Watch for authentication failures in connections (may indicate credential expiration or compromise)
2. Watch for permission errors (may indicate privilege changes in connected systems)
3. Watch for rate limiting errors from connected APIs (may indicate abuse)

#### Code Implementation

**Option 1: Workato API — Check Recipe Job Errors**
```bash
# List recipes with recent errors
curl -s "https://www.workato.com/api/recipes?active=true" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | select(.last_run_at != null) | {
    id, name,
    last_run: .last_run_at,
    running: .running
  }'

# Get recent job history for a specific recipe
curl -s "https://www.workato.com/api/recipes/RECIPE_ID/jobs?status=failed" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, started_at, completed_at, error}'
```

#### Validation & Testing
1. [ ] Intentionally trigger a recipe error — verify notification is received
2. [ ] Verify error details include useful diagnostic information
3. [ ] Verify critical recipe failures trigger within SLA

---

### 8.4 Secure Automation HQ

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| SOC 2 | CC6.1 |
| NIST 800-53 | AC-6 |
| ISO 27001 | A.9.2.3 |

#### Description
Secure multi-workspace Automation HQ (AHQ) environments by enforcing SSO, consistent RBAC, and centralized governance across all managed workspaces.

#### ClickOps Implementation

**Step 1: Configure AHQ-Level SSO**
1. Enable SSO for the AHQ management workspace
2. Enable SSO independently for each child workspace
3. Use the same IdP across all workspaces for consistency

**Step 2: Centralize Governance**
1. Define a consistent security baseline across all child workspaces
2. Apply the same RBAC model (environment roles, project roles) to each workspace
3. Use AHQ's central view to monitor compliance across workspaces

**Step 3: Restrict AHQ Admin Access**
1. AHQ admins have visibility into all child workspaces — limit to 2-3 trusted administrators
2. Apply the same admin controls as individual workspaces (MFA, conditional access)
3. Monitor AHQ admin activity in the audit log

#### Validation & Testing
1. [ ] Verify SSO is enabled on all child workspaces
2. [ ] Verify AHQ admin count is minimal
3. [ ] Verify consistent security policies across all workspaces

---

## 9. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Workato Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | SSO, 2FA, Session Security | [1.1](#11-configure-saml-single-sign-on), [1.2](#12-enforce-two-factor-authentication), [1.6](#16-configure-session-security) |
| CC6.2 | RBAC, User Provisioning, Access Reviews | [2.1](#21-configure-role-based-access-control), [1.5](#15-configure-scim-provisioning), [2.6](#26-implement-privilege-access-reviews) |
| CC6.3 | Collaborator Groups, Custom Roles, Connection Permissions | [2.3](#23-configure-collaborator-groups), [2.4](#24-configure-custom-roles), [4.2](#42-configure-connection-permissions) |
| CC6.5 | Data Masking, Data Retention | [3.2](#32-configure-data-masking), [3.3](#33-configure-data-retention-policies) |
| CC6.6 | IP Allowlisting, On-Prem Agents, API Security | [4.4](#44-configure-ip-allowlisting), [4.3](#43-configure-on-premises-agents-opa), [5.1](#51-configure-api-platform-security) |
| CC6.7 | EKM/BYOK, Connection Credential Security | [3.1](#31-enable-encryption-key-management-ekm), [4.1](#41-secure-connection-credentials) |
| CC7.2 | Audit Logging, Log Streaming, Error Monitoring | [8.1](#81-configure-activity-audit-log), [8.2](#82-configure-audit-log-streaming), [8.3](#83-configure-recipe-error-monitoring) |
| CC8.1 | Environment Separation, RLCM, CI/CD | [7.1](#71-configure-environment-separation), [7.2](#72-configure-recipe-lifecycle-management-rlcm), [7.3](#73-implement-cicd-pipeline-integration) |

### NIST 800-53 Rev 5 Mapping

| Control | Workato Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | SAML SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA Enforcement | [1.2](#12-enforce-two-factor-authentication) |
| IA-2(12) | SSO-Only Enforcement | [1.3](#13-enforce-sso-only-login) |
| AC-2 | JIT/SCIM Provisioning | [1.4](#14-configure-just-in-time-provisioning), [1.5](#15-configure-scim-provisioning) |
| AC-2(1) | Automated Provisioning (SCIM) | [1.5](#15-configure-scim-provisioning) |
| AC-2(3) | Privilege Access Reviews | [2.6](#26-implement-privilege-access-reviews) |
| AC-6 | RBAC, Least Privilege | [2.1](#21-configure-role-based-access-control) |
| AC-6(1) | Custom Roles, Collaborator Groups | [2.4](#24-configure-custom-roles), [2.3](#23-configure-collaborator-groups) |
| AC-6(5) | Limit Admin Access | [2.5](#25-limit-admin-access) |
| AC-12 | Session Timeout | [1.6](#16-configure-session-security) |
| AC-17 | On-Premises Agents | [4.3](#43-configure-on-premises-agents-opa) |
| AU-2, AU-3 | Activity Audit Log | [8.1](#81-configure-activity-audit-log) |
| AU-4, AU-6 | Audit Log Streaming | [8.2](#82-configure-audit-log-streaming) |
| CM-3 | Environment Separation, RLCM | [7.1](#71-configure-environment-separation), [7.2](#72-configure-recipe-lifecycle-management-rlcm) |
| SC-7 | IP Allowlisting, OPA | [4.4](#44-configure-ip-allowlisting), [4.3](#43-configure-on-premises-agents-opa) |
| SC-12 | EKM/BYOK, API Key Management | [3.1](#31-enable-encryption-key-management-ekm), [5.3](#53-manage-workato-platform-api-keys) |
| SC-28 | Encryption at Rest, Sensitive Properties | [3.1](#31-enable-encryption-key-management-ekm), [3.4](#34-protect-environment-properties) |

### ISO 27001:2022 Mapping

| Control | Workato Control | Guide Section |
|---------|-----------------|---------------|
| A.8.10 | Data Retention | [3.3](#33-configure-data-retention-policies) |
| A.8.11 | Data Masking | [3.2](#32-configure-data-masking) |
| A.9.2.1 | User Provisioning (SCIM/JIT) | [1.4](#14-configure-just-in-time-provisioning), [1.5](#15-configure-scim-provisioning) |
| A.9.2.3 | RBAC, Custom Roles | [2.1](#21-configure-role-based-access-control), [2.4](#24-configure-custom-roles) |
| A.9.2.5 | Access Reviews | [2.6](#26-implement-privilege-access-reviews) |
| A.9.4.2 | SSO, 2FA, Session Security | [1.1](#11-configure-saml-single-sign-on), [1.2](#12-enforce-two-factor-authentication), [1.6](#16-configure-session-security) |
| A.10.1.1 | EKM/BYOK | [3.1](#31-enable-encryption-key-management-ekm) |
| A.12.4.1 | Audit Logging | [8.1](#81-configure-activity-audit-log) |
| A.13.1.1 | IP Allowlisting, OPA | [4.4](#44-configure-ip-allowlisting), [4.3](#43-configure-on-premises-agents-opa) |
| A.14.1.2 | API Security, Webhooks | [5.1](#51-configure-api-platform-security), [4.5](#45-secure-webhook-endpoints) |
| A.14.2.1 | Environment Separation | [7.1](#71-configure-environment-separation) |
| A.14.2.2 | RLCM, CI/CD | [7.2](#72-configure-recipe-lifecycle-management-rlcm), [7.3](#73-implement-cicd-pipeline-integration) |

### PCI DSS v4.0.1 Mapping

| Requirement | Workato Control | Guide Section |
|-------------|-----------------|---------------|
| 3.5 | EKM/BYOK, Secrets Manager | [3.1](#31-enable-encryption-key-management-ekm), [6.1](#61-configure-external-secrets-manager-integration) |
| 6.4 | Environment Separation | [7.1](#71-configure-environment-separation) |
| 6.5 | RLCM Deployment Pipeline | [7.2](#72-configure-recipe-lifecycle-management-rlcm) |
| 7.1 | RBAC, Admin Limits | [2.1](#21-configure-role-based-access-control), [2.5](#25-limit-admin-access) |
| 8.3 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| 8.4 | 2FA | [1.2](#12-enforce-two-factor-authentication) |
| 10.2 | Audit Logging | [8.1](#81-configure-activity-audit-log) |
| 10.5 | Log Streaming (tamper-resistant storage) | [8.2](#82-configure-audit-log-streaming) |

---

## Appendix A: Workato Plan Feature Availability

| Control | Community | Professional | Business | Business Plus | Enterprise |
|---------|-----------|-------------|----------|---------------|------------|
| SAML SSO | ❌ | ❌ | ✅ | ✅ | ✅ |
| 2FA | ✅ | ✅ | ✅ | ✅ | ✅ |
| SCIM | ❌ | ❌ | ❌ | ✅ | ✅ |
| Custom Roles | ❌ | ❌ | ✅ | ✅ | ✅ |
| EKM (BYOK) | ❌ | ❌ | ❌ | ❌ | ✅ (add-on) |
| On-Prem Agents | ❌ | ❌ | ✅ | ✅ | ✅ |
| API Platform | ❌ | ❌ | ✅ | ✅ | ✅ |
| Audit Log Streaming | ❌ | ❌ | ❌ | ✅ | ✅ |
| RLCM | ❌ | ❌ | ✅ | ✅ | ✅ |
| Environments | ❌ | ❌ | ✅ | ✅ | ✅ |
| IP Allowlisting | ❌ | ❌ | ❌ | ✅ | ✅ |
| Secrets Manager | ❌ | ❌ | ❌ | ❌ | ✅ |
| Automation HQ | ❌ | ❌ | ❌ | ❌ | ✅ |

> **Note:** Plan names and feature availability may change. Verify current plan features on [Workato's pricing page](https://www.workato.com/pricing) or with your Workato account team.

---

## Appendix B: References

**Official Workato Documentation:**
- [Workato Security Overview](https://docs.workato.com/security.html)
- [Recipe Security](https://docs.workato.com/recipes/recipe-security.html)
- [API Management Security](https://docs.workato.com/api-mgmt/api-security.html)
- [Platform CLI Reference](https://docs.workato.com/en/platform-cli/command-reference.html)
- [Workato Developer API](https://docs.workato.com/en/workato-api.html)
- [Security Compliance](https://docs.workato.com/security/security-compliance.html)
- [Enable Single Sign-On](https://docs.workato.com/user-accounts-and-teams/single-sign-on.html)
- [SAML Role Sync](https://docs.workato.com/user-accounts-and-teams/saml-role-sync.html)
- [SAML Role Sync in Microsoft Entra ID](https://docs.workato.com/saml-role-sync-azure.html)
- [SAML Role Sync in Okta](https://docs.workato.com/saml-role-sync-okta.html)
- [On-Premises Agent](https://docs.workato.com/on-prem.html)
- [Recipe Lifecycle Management](https://docs.workato.com/recipe-development-lifecycle.html)
- [API Platform](https://docs.workato.com/api-management.html)
- [Activity Audit Log](https://docs.workato.com/workspace-admin/activity-audit-log.html)
- [Encryption Key Management](https://docs.workato.com/security/encryption-key-management.html)
- [Secrets Management](https://docs.workato.com/security/data-protection/secrets-management/secrets-management.html)
- [SCIM Provisioning](https://docs.workato.com/scim.html)
- [Data Retention](https://docs.workato.com/security/data-protection/data-retention/)
- [Environments Best Practices](https://docs.workato.com/features/environments/best-practices.html)
- [mTLS for API Platform](https://docs.workato.com/en/api-mgmt/mtls.html)
- [Community Connectors](https://docs.workato.com/developing-connectors/community/community.html)
- [Troubleshoot Single Sign-On](https://docs.workato.com/en/user-accounts-and-teams/troubleshoot-sso.html)

**Workato Security & Compliance:**
- [Workato Security Page](https://www.workato.com/security)
- [Automation Governance and Data Security](https://www.workato.com/platform/security)
- [PCI DSS v4.0.1 Level 1 Certification (Feb 2025)](https://www.businesswire.com/news/home/20250225502055/en/Workato-Strengthens-Commitment-to-Elevating-Enterprise-Security-with-Payment-Card-Industry-Certifications-and-Compliance)
- SOC 1 Type II, SOC 2 Type II (including Privacy Trust Principle), SOC 3
- ISO/IEC 27001:2022, ISO/IEC 27701:2019
- HIPAA (BAA available)
- NIST 800-171A Rev 2
- IRAP (Australian ISM PROTECTED level)
- CSA Star Level 1
- GDPR
- [HackerOne Bug Bounty Program](https://www.workato.com/security) (linked from security page)

**API & Developer Documentation:**
- [OEM API Reference](https://docs.workato.com/oem/oem-api.html)
- [Workato API Reference](https://docs.workato.com/en/workato-api.html)
- [Platform CLI Installation](https://docs.workato.com/en/platform-cli.html)
- [Connector SDK](https://docs.workato.com/developing-connectors/sdk.html)

**Workato Governance & Best Practices:**
- [Best Practices for Advanced Security & Governance (Part I)](https://www.workato.com/product-hub/best-practices-for-advanced-security-and-governance-i/)
- [Best Practices for Workspace Governance (Part II)](https://www.workato.com/product-hub/best-practices-for-workspace-governance-and-security-ii/)
- [Automation Governance Guide](https://www.workato.com/the-connector/automation-governance-guide/)
- [Scaling with Confidence: Advanced Governance (White Paper)](https://cxociety.com/wp-content/uploads/2025/06/Scaling-with-Confidence-Advanced-Governance-Security-with-Workato.pdf)

**Third-Party Security Assessments:**
- [Nudge Security — Workato Security Profile](https://security-profiles.nudgesecurity.com/app/workato-com)
- [UpGuard — Workato Security Rating](https://www.upguard.com/security-report/workato)
- [Valence Security — SaaS Integration Governance](https://www.valencesecurity.com/use-cases/saas-integration-governance)
- [Adaptive Shield — Workato SaaS Security](https://www.adaptive-shield.com/integrations/workato)
- [Obsidian Security — Workato Monitoring](https://www.obsidiansecurity.com/integrations/)

**Analyst Reports:**
- [Gartner Magic Quadrant 2025 — Leader for 7th consecutive year](https://www.workato.com/the-connector/gartner-magic-quadrant-2025/)
- [Forrester Wave Q3 2025 — Leader](https://www.workato.com/the-connector/2025-forrester-wave-for-ipaas/)

**Security Incidents:**
- No major public security incidents identified as of early 2026. Workato maintains a bug bounty program through HackerOne. Responsible disclosure: vulnerability@workato.com.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-02-10 | 0.2.0 | draft | [SECURITY] Comprehensive expansion: 14 → 34 controls across 8 sections. Added Data Protection & Encryption (EKM/BYOK, data masking, retention), API Security (platform security, rate limiting, API key management), Secrets Management (external vault integration), Environment & Deployment Security (RLCM, CI/CD). Added Code implementations (Workato API, AWS CLI, Terraform, GitHub Actions). Added compliance mappings (SOC 2, NIST 800-53, ISO 27001, PCI DSS v4.0). Added plan feature availability matrix. | Claude Code (Opus 4.6) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, RBAC, and connection security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
