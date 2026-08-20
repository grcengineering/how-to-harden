---
layout: guide
title: "Postman Enterprise Hardening Guide"
vendor: "Postman"
slug: "postman"
tier: "2"
category: "DevOps"
description: "API platform security hardening for Postman Enterprise including SSO, team policies, and API key management"
version: "0.2.1"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Postman is the leading API platform used by **over 30 million developers** for API design, testing, documentation, and collaboration. Enterprise deployments store sensitive API endpoints, authentication tokens, and test data. Proper security configuration prevents credential leakage and unauthorized access to development resources.

### Intended Audience
- Security engineers managing developer tools
- IT administrators configuring Postman Enterprise
- GRC professionals assessing API development security
- DevOps engineers implementing secure API workflows

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Postman Enterprise security configurations including team management, SSO, API key management, and workspace security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Team & Workspace Security](#2-team--workspace-security)
3. [API Key & Secret Management](#3-api-key--secret-management)
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
Configure SAML SSO to centralize authentication and enforce organizational security policies.

#### Rationale
**Why This Matters:**
- Centralizing authentication in your IdP means MFA, conditional access, and session policy apply to every Postman login instead of only to members who opted in
- Local Postman passwords bypass those IdP controls entirely and are the credentials attackers target with stuffing and phishing kits
- Postman accounts reach collections and environments that map an organization's internal API surface, so one unfederated login is a direct path to endpoint and token disclosure
- SSO gives you a single place to cut access during an incident or at offboarding, rather than chasing accounts per tool

**Attack Prevented:** Credential stuffing, phishing, account takeover, orphaned-account access after offboarding

#### Prerequisites
- Postman Enterprise plan
- SAML 2.0 compatible identity provider

#### ClickOps Implementation

**Step 1: Access Authentication Settings**
1. Navigate to: **Organization or Team Settings** → **Authentication**
2. Click **Add Authentication Method**
3. Select **SAML** authentication type

**Step 2: Configure SAML**
1. Enter authentication name (identifiable to your organization)
2. Click **Continue** to configure IdP details
3. Note Postman SAML details:
   - ACS URL
   - Entity ID
   - Relay State

**Step 3: Configure Identity Provider**
1. Create SAML application in your IdP
2. Configure attribute mappings:
   - Email (required)
   - Name (optional)
3. Upload IdP metadata to Postman or enter manually:
   - SSO URL
   - Certificate

**Step 4: Configure Enhanced Security (Optional)**
1. For stricter security requirements:
   - Enable SAML signing certificates
   - Enable encryption certificates
2. Note: Not supported by all IdPs

**Step 5: Enforce SSO**
1. Test SSO authentication
2. Enable **Enforce SSO** after successful testing
3. Configure recovery options for admin access

**Time to Complete:** ~1 hour

---

### 1.2 Configure SCIM Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure SCIM for automatic user provisioning and deprovisioning synced with your identity provider.

#### Rationale
**Why This Matters:**
- Manual deprovisioning is routinely missed, leaving departed employees with live access to collections, environments, and any credentials stored in them
- SCIM removes access on the same clock as the IdP, closing the window in which a terminated user or a compromised former account can still reach team data
- Group sync keeps workspace membership tied to authoritative HR/IdP groups instead of ad-hoc invitations that drift out of alignment
- Automating the lifecycle removes the manual-entry errors that silently over-provision members

**Attack Prevented:** Orphaned-account access, insider misuse after termination, privilege drift, unauthorized workspace membership

#### ClickOps Implementation

**Step 1: Enable SCIM**
1. Navigate to: **Organization Settings** → **Authentication** → **SCIM provisioning**
2. Generate SCIM API key
3. Note SCIM endpoint URL

**Step 2: Configure IdP SCIM**
1. In your IdP, enable SCIM provisioning
2. Enter Postman SCIM endpoint
3. Enter SCIM API key
4. Configure provisioning settings:
   - Create users
   - Update users
   - Deactivate users
   - Sync groups

**Step 3: Configure JIT Provisioning (Alternative)**
1. If SCIM not available, enable JIT provisioning
2. Navigate to: **Authentication** → **SSO Settings**
3. Enable **Just-in-Time provisioning**
4. Users auto-provisioned on first SSO login

---

### 1.3 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for team members accessing Postman.

#### Rationale
**Why This Matters:**
- MFA stops attackers who have stolen or phished a Postman password from logging in with credentials alone
- Postman accounts hold collections, environments, and tokens that map an organization's entire API attack surface
- Enforcing MFA for both SSO and non-SSO members closes the gap left by local password logins that bypass IdP controls

**Attack Prevented:** Credential stuffing, phishing, password reuse, account takeover

#### ClickOps Implementation

**Step 1: Enforce MFA via SSO**
1. Configure MFA enforcement in your IdP
2. All users authenticating via SSO will require MFA
3. Verify MFA is enforced before SSO login

**Step 2: Enforce MFA for Non-SSO Users**
1. Navigate to: **Team Settings** → **Authentication**
2. Enable **Require MFA** for team members
3. Set compliance deadline

**Step 3: Communicate Requirements**
1. Notify team members of MFA requirement
2. Provide setup documentation
3. Monitor compliance status

---

## 2. Team & Workspace Security

### 2.1 Configure Workspace Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure workspace-level permissions following least privilege principles.

#### Rationale
**Why This Matters:**
- Workspaces hold collections, environments, and saved requests that often embed real endpoints and credentials
- Default-broad visibility lets any member read or modify sensitive API definitions they have no need to access
- Scoping each workspace to Personal, Private, or Team and assigning Viewer/Editor/Admin roles limits the blast radius of a compromised account
- Least-privilege roles prevent accidental edits or deletions of shared API assets

**Attack Prevented:** Privilege escalation, unauthorized data access, lateral movement, insider misuse

#### ClickOps Implementation

**Step 1: Create Workspace Structure**
1. Navigate to: **Workspaces** → **Create Workspace**
2. Create workspaces by:
   - Team/project
   - Security level (public APIs, internal APIs, sensitive APIs)

**Step 2: Configure Workspace Visibility**
1. **Personal:** Only owner can access
2. **Private:** Invited members only
3. **Team:** All team members can view
4. **Public:** Anyone can view (avoid for sensitive work)

**Step 3: Configure Member Roles**
1. Navigate to: **Workspace Settings** → **Members**
2. Assign roles:
   - **Viewer:** Can only send requests
   - **Editor:** Can add and modify elements
   - **Admin:** Full workspace control
3. Apply principle of least privilege

---

### 2.2 Configure Team Member Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Implement role-based access control for team administration.

#### Rationale
**Why This Matters:**
- Team-level Admin rights can change SSO, billing, security policy, and membership for the entire organization
- Limiting Admin to a small set of essential personnel reduces the number of high-value accounts an attacker can target
- Separating billing and developer duties enforces separation of duties and prevents over-provisioned standing access

**Attack Prevented:** Privilege escalation, admin account takeover, insider abuse, unauthorized policy changes

#### ClickOps Implementation

**Step 1: Review Team Roles**
1. Navigate to: **Team Settings** → **Members**
2. Review available roles:
   - **Admin:** Full team management
   - **Billing:** Billing management only
   - **Developer:** Standard access

**Step 2: Assign Minimum Required Roles**
1. Limit Admin role to essential personnel (2-3)
2. Use Developer role for most team members
3. Separate billing responsibilities

**Step 3: Create Custom Roles (Enterprise)**
1. For Enterprise plans with custom roles
2. Create role-based on specific needs
3. Apply to members as appropriate

---

### 2.3 Control Invitation Settings

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Control who can invite new members to the team.

#### Rationale
**Why This Matters:**
- Unrestricted invitations let any member add outsiders, growing the team's access footprint without oversight
- Restricting invites to admins and approved email domains keeps untrusted accounts out of workspaces holding API secrets
- Domain capture consolidates users under managed identities so shadow accounts cannot accumulate access

**Attack Prevented:** Unauthorized access, account sprawl, social engineering, shadow IT

#### ClickOps Implementation

**Step 1: Configure Invitation Policies**
1. Navigate to: **Team Settings** → **Security** → **Invitations**
2. Configure:
   - Restrict who can send invitations (Admins only)
   - Allow invitations only to specific email domains
3. Require admin approval for new members

**Step 2: Domain Capture (Enterprise)**
1. Navigate to: **Organization Settings** → **Domains**
2. Claim and verify your organization's domain
3. Enable domain capture to consolidate all users

---

### 2.4 Restrict Public Workspaces

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Restrict the creation of public workspaces to prevent accidental data exposure.

#### Rationale
**Why This Matters:**
- Public workspaces are discoverable by anyone on the internet, including automated secret-harvesting bots
- Collections and environments frequently contain live API keys, access tokens, and internal endpoint URLs
- Misconfigured workspace visibility is the leading cause of Postman data leaks, not a platform flaw — restricting creation removes the human-error path
- Requiring approval gives security teams a chance to review content before anything is exposed publicly

**Attack Prevented:** Credential leakage, data exposure, token harvesting, accidental disclosure

#### ClickOps Implementation

**Step 1: Configure Workspace Policies**
1. Navigate to: **Team Settings** → **Security**
2. Under workspace settings:
   - Restrict public workspace creation
   - Require approval for public workspaces

**Step 2: Audit Existing Public Workspaces**
1. Review all existing public workspaces
2. Verify no sensitive data is exposed
3. Convert to private if necessary

#### Code Implementation

{% include pack-code.html vendor="postman" section="2.4" %}

---

## 3. API Key & Secret Management

### 3.1 Configure API Key Expiration

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Limit how long a Postman API key stays valid, and restrict who can mint one, by setting an organization-wide expiry policy and turning off unrestricted key generation.

#### Rationale
**Why This Matters:**
- A Postman API key authenticates programmatic access to the account's collections, environments, and team data without an interactive login or an MFA prompt
- Keys with no expiry become permanent credentials: one leaked into a repository, a CI log, or a public workspace stays usable indefinitely unless someone notices and revokes it
- An organization-wide expiry policy overrides what individual users set on future keys, so lifetime stops depending on each developer's judgment
- Restricting who can generate keys shrinks the population of standing credentials an attacker can hunt for

**Attack Prevented:** Credential leakage, long-lived token abuse, unauthorized programmatic access, credential sprawl

**Two organization toggles do most of the work here.** Postman exposes an org-level **"Allow anyone in your team to generate API keys"** setting — turning it off restricts key minting to the roles you designate — and a **"Set expiry for API keys"** policy that applies organization-wide and **overrides user-set expirations on future keys**. Set both before auditing individual keys; otherwise every cleanup pass is undone by the next developer who mints a non-expiring key. ([Managing API keys](https://learning.postman.com/docs/administration/managing-your-team/managing-api-keys/))

#### ClickOps Implementation

**Step 1: Set an Organization-Wide Expiry Policy**
1. As an Admin or Super Admin, open **Organization** → **Postman Keys** from the Postman header
2. Enable the organization-wide **Set expiry for API keys** policy and choose the shortest lifetime your workflows tolerate — this policy overrides user-set expirations on keys created afterward
3. Communicate the change before enforcing it, since existing automation will need to rotate

**Step 2: Restrict Who Can Generate Keys**
1. In the same organization settings, turn off **Allow anyone in your team to generate API keys**
2. Grant key generation only to the roles that genuinely need programmatic access
3. Re-review the allowed set on the same cadence as your admin-role review

**Step 3: Enable Automatic Revocation of Exposed Keys**
1. Enable the organization setting to **auto revoke exposed Postman API keys**, which revokes a key Postman detects as publicly exposed rather than waiting for a human to act
2. This is the direct control for the failure mode behind the December 2024 CloudSEK findings (see Appendix B), where keys and tokens sat readable in public workspaces long enough for scrapers to harvest them
3. Pair it with an alerting path so revocation is investigated, not just absorbed by whatever automation breaks

---

### 3.2 Centralize API Key Management

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Centrally manage team API keys with visibility and revocation capabilities.

#### Rationale
**Why This Matters:**
- Postman API keys can read and modify collections, environments, and team data programmatically
- Without central visibility, departed-employee and forgotten keys persist as unmonitored standing access
- Centralized management lets admins audit every active key and revoke compromised or orphaned credentials immediately
- Enforced duration and approval policies prevent long-lived keys from accumulating across the team

**Attack Prevented:** Orphaned-credential access, API key abuse, unauthorized automation, standing access

#### Prerequisites
- Postman Enterprise plan
- Admin or Super Admin role

#### ClickOps Implementation

**Step 1: Open the Postman Keys Dashboard**
1. From the Postman header, navigate to: **Organization** → **Postman Keys**
2. The dashboard lists every key in the organization with its usage, creation date, and last-used date
3. Treat a key with no recent use and no documented owner as a revocation candidate, not a mystery to leave alone

**Step 2: Apply the Organization Key Policies**
1. Confirm the org-wide expiry policy and generation restrictions from [3.1](#31-configure-api-key-expiration) are enabled
2. Confirm auto-revocation of exposed keys is on
3. Record which roles are permitted to mint keys

**Step 3: Audit and Revoke Keys**
1. Review active keys on a fixed cadence using the creation and last-used columns
2. Use **single or bulk revocation** from the dashboard to remove keys belonging to departed employees in one pass
3. Revoke compromised keys immediately, then rotate whatever they had access to

Source: [Managing API keys](https://learning.postman.com/docs/administration/managing-your-team/managing-api-keys/)

---

### 3.3 Use Postman Vault for Secrets

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Use Postman Local Vault to store sensitive credentials locally, never syncing to cloud.

#### Rationale
**Why This Matters:**
- Environment variables sync to Postman's cloud and travel with any workspace share, so a secret pasted into one is a secret that can leave with a workspace visibility change
- Vault secrets stay on the local machine and are never synced, which removes the workspace-exposure path entirely rather than mitigating it
- Referencing secrets by vault key means collections can be shared, forked, and exported without the credential riding along in the artifact
- Integrations with 1Password, AWS Secrets Manager, Azure Key Vault, and HashiCorp Vault let developers use real credentials without ever holding a copy in Postman

**Attack Prevented:** Credential leakage through synced environments, secret exposure via workspace sharing, token harvesting from exported collections

#### ClickOps Implementation

**Step 1: Configure Postman Vault**
1. Navigate to: **Settings** → **Vault**
2. Add secrets to local vault
3. Reference secrets using `{% raw %}{{vault:secret_name}}{% endraw %}`

**Step 2: Configure Vault Integrations**
1. Available integrations:
   - 1Password
   - AWS Secrets Manager
   - Azure Key Vault
   - HashiCorp Vault
2. Configure integration for enterprise secrets

**Step 3: Train Team on Vault Usage**
1. Document vault best practices
2. Never store secrets in environment variables (synced)
3. Use vault for all sensitive credentials

---

### 3.4 Enable Secret Scanner

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.4 |
| NIST 800-53 | IA-5 |

#### Description
Use Postman's secret scanning to detect exposed credentials — Cloud Secret Detection covers public workspaces by default and extends to Internal and Partner workspaces with the Enterprise Advanced Security Administration add-on, while Local Secret Protection covers every workspace type including connected Git projects.

#### Rationale
**Why This Matters:**
- Developers routinely paste real tokens into collections and environments while testing APIs
- Once a secret reaches a public workspace, automated scrapers can find and abuse it within minutes
- The Secret Scanner provides continuous detection so exposed credentials are caught and can be rotated before attackers use them
- Alerting and response procedures turn a silent leak into an actionable security event

**Attack Prevented:** Credential leakage, token harvesting, secret exposure, supply chain compromise

**Know exactly which workspaces are covered.** The two scanning surfaces have different reach, and assuming blanket coverage is how secrets in Internal workspaces go unnoticed:

| Capability | Coverage | Plan requirement |
|------------|----------|------------------|
| Cloud Secret Detection | Public workspaces | Included by default |
| Cloud Secret Detection | Internal and Partner workspaces | Enterprise + Advanced Security Administration add-on |
| Local Secret Protection | All workspace types, including connected Git projects | Included |
| Secret scanner dashboard, custom detection patterns, reports, findings API | Organization-wide | Enterprise + Advanced Security Administration add-on |

([Secret scanner overview](https://learning.postman.com/docs/administration/managing-your-team/secret-scanner/overview/))

#### ClickOps Implementation

**Step 1: Verify Scanner Coverage**
1. Navigate to: **Team Settings** → **Security**
2. Confirm Cloud Secret Detection is active, and determine whether your plan extends it beyond public workspaces
3. Confirm Local Secret Protection is in place for Git-connected projects

**Step 2: Configure Alerts**
1. Configure notification recipients
2. Set up incident response procedures
3. Respond promptly to detected secrets

**Step 3: Rotate Detected Secrets**
1. When secret detected, rotate immediately
2. Document incident
3. Update storage practices

**Step 4: Use the Dashboard and Custom Patterns (Enterprise + add-on)**
1. Review findings centrally in the secret scanner dashboard
2. Add custom detection patterns for credential formats unique to your organization
3. Pull findings programmatically through the findings API to feed your existing secret-response workflow

#### Code Implementation

{% include pack-code.html vendor="postman" section="3.4" %}

---

### 3.5 Enable BYOK Encryption

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12, SC-28 |

#### Description
Bring Your Own Key (BYOK) encryption lets an Enterprise organization encrypt a defined set of Postman-stored data with an AWS KMS key it controls, so revoking the key removes Postman's ability to decrypt that data.

#### Rationale
**Why This Matters:**
- Holding the encryption key means access to the covered data can be cut off unilaterally, without depending on the vendor's deletion process or timeline
- Key custody is frequently a hard requirement in regulated environments and in enterprise contracts that mandate customer-controlled cryptographic material
- The covered surfaces — request history, environments, globals, monitor runs, and collection runs — are exactly where developers most often leave live credentials and real response payloads
- Knowing precisely what BYOK does **not** cover prevents the dangerous assumption that everything in Postman is protected by your key

**Attack Prevented:** Unauthorized data access at rest, vendor-side data exposure, loss of cryptographic control over sensitive request and response data

**BYOK does not cover everything — state this accurately in your risk assessment.** Postman's BYOK encryption covers request history, environments, globals, monitor runs, and collection runs. It does **not** cover workspaces or collections themselves. Treat collection contents as outside the BYOK boundary and keep secrets out of them regardless ([3.3](#33-use-postman-vault-for-secrets) is the control that handles that). ([BYOK encryption](https://learning.postman.com/docs/administration/managing-your-team/byok-encryption/))

#### Prerequisites
- Postman Enterprise plan with the Advanced Security Administration add-on
- An AWS KMS key your organization controls
- BYOK is not self-service — it is configured through your Customer Success Manager or Postman support

#### ClickOps Implementation

**Step 1: Provision the KMS Key**
1. Create a dedicated AWS KMS key for Postman, with key rotation enabled and an access policy limited to the principals that need it
2. Document the key's owner, region, and rotation schedule in your key inventory
3. Ensure your break-glass process accounts for the fact that revoking or deleting the key makes covered Postman data unrecoverable

**Step 2: Engage Postman to Enable BYOK**
1. Contact your Customer Success Manager or Postman support to begin BYOK enablement — there is no self-service toggle
2. Provide the KMS key details through the process Postman specifies
3. Confirm in writing which data categories the enablement covers

**Step 3: Record the Boundary**
1. Record in your data-flow documentation that workspaces and collections fall outside BYOK coverage
2. Reinforce vault usage ([3.3](#33-use-postman-vault-for-secrets)) for anything sensitive that would otherwise live in a collection
3. Re-verify coverage after any significant Postman platform change

#### Validation & Testing
Confirm with Postman that the organization's covered data is encrypted under your KMS key, and verify key usage appears in your AWS CloudTrail KMS logs. Absence of KMS decrypt events where you expect them is a signal that enablement did not complete as understood.

---

## 4. Monitoring & Compliance

### 4.1 Review Audit Logs

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Regularly review audit logs for security events and compliance.

#### Rationale
**Why This Matters:**
- Audit logs are the primary record of sign-ins, role changes, API key events, and SSO configuration changes
- Without regular review, account compromise and privilege abuse go undetected until damage is done
- Streaming logs to a SIEM enables alerting on failed logins, new public workspaces, and admin changes in near real time
- Retained logs provide the forensic trail needed for incident response and compliance evidence

**Attack Prevented:** Undetected intrusion, privilege abuse, delayed incident response, audit gaps

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Team Settings** → **Audit logs**
2. Review logged events:
   - User sign-in events
   - Team membership changes
   - Workspace changes
   - API key events
   - Billing events

**Step 2: Configure SIEM Integration**
1. Navigate to: **Integrations** → **Audit Logs**
2. Configure audit log export via API
3. Stream to SIEM for alerting

**Key Events to Monitor:**
- Failed login attempts
- API key creation/revocation
- Public workspace creation
- Admin role changes
- SSO configuration changes

#### Code Implementation

{% include pack-code.html vendor="postman" section="4.1" %}

---

### 4.2 Configure Allowed Domains

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 12.8 |
| NIST 800-53 | AC-20 |

#### Description
Restrict API requests to approved domains to prevent data exfiltration.

#### Rationale
**Why This Matters:**
- Postman clients can send requests carrying tokens and data to any destination by default
- A malicious or compromised collection could quietly forward secrets to an attacker-controlled endpoint
- Allowlisting approved API domains blocks requests to unapproved hosts, cutting off the exfiltration path
- A documented exception process keeps the control enforceable without breaking legitimate integrations

**Attack Prevented:** Data exfiltration, token leakage, malicious collection abuse, command-and-control callbacks

**Verify this setting still exists before relying on it.** An **Allowed Domains** control no longer appears in Postman's current Team Security documentation index, which covers SSO, Domain Capture, SCIM, the secret scanner, public element management, audit logs, and BYOK. The setting may have been removed or renamed — and it should not be confused with **Domain Capture**, which consolidates user identities under a claimed email domain and is not an egress control. Confirm in your own team settings before treating outbound domain restriction as an enforced control. ([Team security](https://learning.postman.com/docs/administration/security/team-security/))

#### ClickOps Implementation

**Step 1: Configure Domain Allowlist**
1. Navigate to: **Team Settings** → **Security** → **Allowed Domains**
2. Add approved API domains
3. Block requests to unapproved domains

**Step 2: Test Configuration**
1. Verify approved domains work
2. Verify blocked domains are denied
3. Document exception process

---

### 4.3 Implement Data Governance

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Implement data governance policies for collections and workspaces.

#### Rationale
**Why This Matters:**
- Collections and workspaces accumulate sensitive endpoint, payload, and credential data over time without consistent handling rules
- Data classification ensures Confidential and Restricted assets receive stronger access controls than public examples
- Mapping workspaces to classification levels prevents sensitive API definitions from landing in loosely governed spaces
- Training and regular reviews keep handling practices aligned with regulatory and contractual obligations

**Attack Prevented:** Data mishandling, unauthorized exposure, compliance violations, inconsistent access control

#### ClickOps Implementation

**Step 1: Define Data Classification**
1. Establish data classification levels:
   - Public
   - Internal
   - Confidential
   - Restricted
2. Document handling requirements

**Step 2: Implement Workspace Policies**
1. Create workspaces by classification level
2. Apply appropriate access controls
3. Regular data reviews

**Step 3: Training**
1. Train team on data handling
2. Document approved workflows
3. Regular compliance reminders

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Postman Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Role-based access | [2.2](#22-configure-team-member-roles) |
| CC6.6 | Workspace permissions | [2.1](#21-configure-workspace-permissions) |
| CC7.2 | Audit logging | [4.1](#41-review-audit-logs) |
| CC6.7 | Vault secrets | [3.3](#33-use-postman-vault-for-secrets) |

### NIST 800-53 Rev 5 Mapping

| Control | Postman Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | MFA | [1.3](#13-enforce-multi-factor-authentication) |
| AC-2 | SCIM provisioning | [1.2](#12-configure-scim-provisioning) |
| AC-6 | Least privilege | [2.1](#21-configure-workspace-permissions) |
| SC-12 | Key management | [3.1](#31-configure-api-key-expiration) |
| SC-28 | BYOK encryption at rest | [3.5](#35-enable-byok-encryption) |
| AU-2 | Audit logging | [4.1](#41-review-audit-logs) |

---

## Appendix A: Plan Compatibility

| Feature | Free | Basic | Professional | Enterprise |
|---------|------|-------|--------------|------------|
| SSO | ❌ | ❌ | ❌ | ✅ |
| SCIM | ❌ | ❌ | ❌ | ✅ |
| Central API Key Management | ❌ | ❌ | ❌ | ✅ |
| Audit Logs | ❌ | ❌ | ❌ | ✅ |
| Domain Capture | ❌ | ❌ | ❌ | ✅ |
| Workspace Roles | Basic | Basic | ✅ | ✅ |
| Postman Vault | ✅ | ✅ | ✅ | ✅ |
| Cloud Secret Detection (public workspaces) | ✅ | ✅ | ✅ | ✅ |
| Cloud Secret Detection (Internal/Partner workspaces) | ❌ | ❌ | ❌ | Enterprise + Advanced Security Administration add-on |
| Local Secret Protection (all workspace types) | ✅ | ✅ | ✅ | ✅ |
| Secret scanner dashboard, custom patterns, findings API | ❌ | ❌ | ❌ | Enterprise + Advanced Security Administration add-on |
| BYOK encryption | ❌ | ❌ | ❌ | Enterprise + Advanced Security Administration add-on |

---

## Appendix B: References

**Official Postman Documentation:**
- [Team Security](https://learning.postman.com/docs/administration/security/team-security/)
- [Managing API keys](https://learning.postman.com/docs/administration/managing-your-team/managing-api-keys/)
- [Secret scanner overview](https://learning.postman.com/docs/administration/managing-your-team/secret-scanner/overview/)
- [BYOK encryption](https://learning.postman.com/docs/administration/managing-your-team/byok-encryption/)
- [Learning Center](https://learning.postman.com/docs/introduction/overview/)
- [Postman Enterprise Overview](https://learning.postman.com/docs/administration/enterprise/enterprise-overview)
- [Configure SSO](https://learning.postman.com/docs/administration/sso/admin-sso/)
- [Intro to SSO](https://learning.postman.com/docs/administration/sso/intro-sso)
- [How to Securely Deploy Postman at Scale](https://blog.postman.com/how-to-securely-deploy-postman-at-scale-user-management/)

**API Documentation:**
- [Postman API Reference](https://learning.postman.com/docs/developer/postman-api/intro-api)

**Security Resources:**
- [Securely Manage Team API Keys](https://blog.postman.com/securely-manage-your-teams-postman-api-keys/)
- [How to Use API Keys Securely](https://blog.postman.com/how-to-use-api-keys/)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO 27001, PCI DSS, CSA STAR, GDPR — compliance reports available from Postman on request

**Security Incidents:**
- **December 2024:** CloudSEK researchers discovered over 30,000 publicly accessible Postman workspaces leaking API keys, access tokens, and refresh tokens across organizations in healthcare, finance, and other industries. The root cause was user misconfiguration (improper workspace visibility settings), not a platform vulnerability. Postman responded by introducing secret-protection policies to prevent public workspaces from exposing sensitive information. — [CloudSEK Report](https://www.cloudsek.com/blog/postman-data-leaks-the-hidden-risks-lurking-in-your-workspaces)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.1 | ai-drafted | Add first Code Packs (api): 2.4 public-workspace audit (GET /workspaces?type=public), 3.4 unresolved Secret Scanner findings export (POST /detected-secrets-queries, Enterprise + Advanced Security Administration), 4.1 audit-log JSONL export for SIEM (GET /audit/logs) — all endpoints verified against the Postman API OpenAPI reference; wire Code Implementation includes into 2.4, 3.4, and 4.1 | Claude Code (Fable 5) |
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass: added 3.5 BYOK encryption (Enterprise + Advanced Security Administration, AWS KMS, with an honest coverage boundary); added the org-level auto-revoke-exposed-keys, key-generation restriction, and org-wide expiry policy to 3.1 and corrected 3.2 to the Organization → Postman Keys dashboard; rewrote 3.4 to distinguish Cloud Secret Detection from Local Secret Protection by workspace type and plan; softened the unconfirmed 30/60/180-day expiry menu and annotated 4.2 Allowed Domains as absent from current team-security docs; repaired the cheat-parser contract for 1.1, 1.2, 3.1, and 3.3 and replaced their marketing-register rationale bullets with threat statements; replaced Trust Center links with verified first-party configuration docs | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with SSO, team security, and API key management | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
