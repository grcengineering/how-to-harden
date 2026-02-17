---
layout: guide
title: "Postman Enterprise Hardening Guide"
vendor: "Postman"
slug: "postman"
tier: "2"
category: "DevOps"
description: "API platform security hardening for Postman Enterprise including SSO, team policies, and API key management"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Postman is the leading API platform used by **over 30 million developers** for API design, testing, documentation, and collaboration. Enterprise deployments store sensitive API endpoints, authentication tokens, and test data. Proper security configuration prevents credential leakage and unauthorized access to development resources.

### Intended Audience
- Security engineers managing developer tools
- IT administrators configuring Postman Enterprise
- GRC professionals assessing API development security
- DevOps engineers implementing secure API workflows

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication and enforce organizational security policies.

#### Rationale
**Why This Matters:**
- Centralizes identity management
- Enables enforcement of corporate MFA policies
- Provides seamless sign-in experience
- Supports regulatory compliance requirements

#### Prerequisites
- [ ] Postman Enterprise plan
- [ ] SAML 2.0 compatible identity provider

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

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure SCIM for automatic user provisioning and deprovisioning synced with your identity provider.

#### Rationale
**Why This Matters:**
- Automates user lifecycle management
- Quick offboarding when employees leave
- Reduces manual user management errors
- Syncs group memberships

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

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for team members accessing Postman.

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

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure workspace-level permissions following least privilege principles.

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

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Implement role-based access control for team administration.

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

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Control who can invite new members to the team.

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

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Restrict the creation of public workspaces to prevent accidental data exposure.

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

---

## 3. API Key & Secret Management

### 3.1 Configure API Key Expiration

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Configure Postman API key expiration to limit credential lifetime.

#### Rationale
**Why This Matters:**
- API keys give access to all Postman data
- Shorter expiration limits exposure from compromised keys
- Encourages regular key rotation

#### ClickOps Implementation

**Step 1: Configure Personal API Key Expiration**
1. Navigate to: **Account Settings** → **Postman API keys**
2. When generating new key, set expiration:
   - **30 days:** Most secure
   - **60 days:** Balanced
   - **180 days:** Maximum (not recommended)

**Step 2: Enforce Team Key Policies (Enterprise)**
1. Navigate to: **Team Settings** → **Security**
2. Enable **Manage Postman Keys** feature
3. Configure team-wide expiration policies
4. Set maximum key lifetime

---

### 3.2 Centralize API Key Management

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Centrally manage team API keys with visibility and revocation capabilities.

#### Prerequisites
- [ ] Postman Enterprise plan

#### ClickOps Implementation

**Step 1: Enable Central Key Management**
1. Navigate to: **Team Settings** → **Security** → **API Keys**
2. Enable **Manage Postman Keys**
3. View all team member API keys

**Step 2: Configure Key Policies**
1. Set maximum key duration
2. Configure approval requirements
3. Enable notifications for key creation

**Step 3: Audit and Revoke Keys**
1. Regularly review active keys
2. Revoke keys for departed employees
3. Revoke compromised keys immediately

---

### 3.3 Use Postman Vault for Secrets

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Use Postman Local Vault to store sensitive credentials locally, never syncing to cloud.

#### Rationale
**Why This Matters:**
- Vault secrets remain local only
- Never synced to Postman cloud servers
- Enables safe API testing with real credentials

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

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.4 |
| NIST 800-53 | IA-5 |

#### Description
Use Postman's Secret Scanner to detect exposed credentials in public workspaces.

#### ClickOps Implementation

**Step 1: Verify Secret Scanner Status**
1. Navigate to: **Team Settings** → **Security**
2. Verify Secret Scanner is enabled
3. Review scanner findings

**Step 2: Configure Alerts**
1. Configure notification recipients
2. Set up incident response procedures
3. Respond promptly to detected secrets

**Step 3: Rotate Detected Secrets**
1. When secret detected, rotate immediately
2. Document incident
3. Update storage practices

---

## 4. Monitoring & Compliance

### 4.1 Review Audit Logs

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Regularly review audit logs for security events and compliance.

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

---

### 4.2 Configure Allowed Domains

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 12.8 |
| NIST 800-53 | AC-20 |

#### Description
Restrict API requests to approved domains to prevent data exfiltration.

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

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Implement data governance policies for collections and workspaces.

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
| Secret Scanner | ✅ | ✅ | ✅ | ✅ |

---

## Appendix B: References

**Official Postman Documentation:**
- [Trust Center (Compliance)](https://www.postman.com/trust/compliance/)
- [Customer Trust Portal](https://security.postman.com/)
- [Postman Security Features](https://www.postman.com/trust/postman-security-features/)
- [Learning Center](https://learning.postman.com/docs/introduction/overview/)
- [Postman Enterprise Overview](https://learning.postman.com/docs/administration/enterprise/enterprise-overview)
- [Configure SSO](https://learning.postman.com/docs/administration/sso/admin-sso/)
- [Intro to SSO](https://learning.postman.com/docs/administration/sso/intro-sso)
- [Team Security](https://learning.postman.com/docs/administration/security/team-security/)
- [How to Securely Deploy Postman at Scale](https://blog.postman.com/how-to-securely-deploy-postman-at-scale-user-management/)

**API Documentation:**
- [Postman API Reference](https://learning.postman.com/docs/developer/postman-api/intro-api)

**Security Resources:**
- [Securely Manage Team API Keys](https://blog.postman.com/securely-manage-your-teams-postman-api-keys/)
- [How to Use API Keys Securely](https://blog.postman.com/how-to-use-api-keys/)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO 27001, PCI DSS, CSA STAR, GDPR — via [Compliance Page](https://www.postman.com/trust/compliance/)

**Security Incidents:**
- **December 2024:** CloudSEK researchers discovered over 30,000 publicly accessible Postman workspaces leaking API keys, access tokens, and refresh tokens across organizations in healthcare, finance, and other industries. The root cause was user misconfiguration (improper workspace visibility settings), not a platform vulnerability. Postman responded by introducing secret-protection policies to prevent public workspaces from exposing sensitive information. — [CloudSEK Report](https://www.cloudsek.com/blog/postman-data-leaks-the-hidden-risks-lurking-in-your-workspaces)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, team security, and API key management | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
