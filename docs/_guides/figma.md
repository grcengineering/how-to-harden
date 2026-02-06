---
layout: guide
title: "Figma Enterprise Hardening Guide"
vendor: "Figma"
slug: "figma"
tier: "2"
category: "Collaboration & Productivity"
description: "Design platform hardening for Figma Enterprise including SSO, access controls, and governance features"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Figma is the leading collaborative design platform used by **millions of designers** worldwide for UI/UX design, prototyping, and design systems. As a repository for intellectual property including product designs and brand assets, Figma security configurations directly impact data protection and competitive advantage.

### Intended Audience
- Security engineers managing design platforms
- IT administrators configuring Figma Enterprise
- GRC professionals assessing collaboration security
- Design operations teams managing access

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Figma Organization and Enterprise security including SAML SSO, access controls, sharing settings, and Governance+ features.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Sharing & Collaboration](#3-sharing--collaboration)
4. [Monitoring & Governance](#4-monitoring--governance)
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

#### Prerequisites
- [ ] Figma Organization or Enterprise plan
- [ ] SAML 2.0 compatible identity provider
- [ ] Verified domain in Figma

#### ClickOps Implementation

**Step 1: Verify Domain**
1. Navigate to: **Admin** → **Settings** → **Domains**
2. Add your organization's domain
3. Verify via DNS TXT record

**Step 2: Configure SAML SSO**
1. Navigate to: **Admin** → **Settings** → **SAML SSO**
2. Click **Set up SAML SSO**
3. Select your identity provider:
   - Google Workspace
   - Okta
   - OneLogin
   - Microsoft Entra ID
   - Custom configuration

**Step 3: Configure IdP Settings**
1. Download Figma SP metadata
2. Configure IdP application with:
   - ACS URL
   - Entity ID
3. Upload IdP metadata to Figma

**Step 4: Enforce SSO**
1. Test SSO authentication
2. Select **Members must log in with SAML SSO** (mandatory)
3. Or **Members may log in with any method** (optional)

**Time to Complete:** ~1 hour

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for organization members and guests.

#### ClickOps Implementation

**Step 1: Enable 2FA for Members**
1. Configure MFA through your identity provider
2. All SSO users subject to IdP MFA policies

**Step 2: Enforce 2FA for Guests**
1. Navigate to: **Admin** → **Settings** → **Security**
2. Enable **Enforced 2FA** for guests
3. Guests without 2FA cannot access content
4. Applies across web, desktop, and mobile

---

### 1.3 Configure User Provisioning (SCIM)

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure SCIM for automatic user provisioning and deprovisioning.

#### ClickOps Implementation

**Step 1: Enable JIT Provisioning**
1. All SAML SSO configurations support JIT
2. Users created on first login
3. Attributes mapped from SAML response:
   - Email
   - First name
   - Last name

**Step 2: Configure SCIM (Enterprise)**
1. Navigate to: **Admin** → **Settings** → **SCIM**
2. Generate SCIM token
3. Configure IdP SCIM integration
4. Set member seats via SCIM

**Step 3: Initial Login Verification**
1. First SSO/SCIM login triggers verification email
2. Users enter 6-digit PIN from SendGrid
3. One-time security measure

---

## 2. Access Controls

### 2.1 Configure Team and Project Permissions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure team and project permissions following least privilege.

#### ClickOps Implementation

**Step 1: Create Team Structure**
1. Navigate to: **Admin** → **Teams**
2. Create teams by:
   - Department
   - Project
   - Access level

**Step 2: Configure Team Permissions**
1. Set team member roles:
   - **Admin:** Full team control
   - **Editor:** Can edit files
   - **Viewer:** Read-only access
2. Apply minimum necessary permissions

**Step 3: Configure Project Access**
1. Set project-level permissions
2. Control who can access projects
3. Configure default access levels

---

### 2.2 Configure Admin Roles

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Implement role-based access for organization administration.

#### ClickOps Implementation

**Step 1: Review Admin Access**
1. Navigate to: **Admin** → **Members**
2. Filter by admin role
3. Review all organization admins

**Step 2: Assign Minimum Roles**
1. Limit Organization Admin to essential personnel (2-3)
2. Use Team Admin for team management
3. Document admin assignments

**Step 3: Configure Multiple IdPs (Enterprise+)**
1. With Governance+, configure multiple IdPs
2. Different auth for different teams
3. Federated access management

---

### 2.3 Restrict Network Access

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Restrict personal account access on corporate networks.

#### ClickOps Implementation

**Step 1: Enable Network Restrictions**
1. Navigate to: **Admin** → **Settings** → **Security**
2. Enable **Restrict personal access on this network**

**Step 2: Configure Restrictions**
1. Users on corporate network can only access:
   - Accounts associated with organization's domain
   - Guest access to organization content
2. Prevents shadow IT usage

---

## 3. Sharing & Collaboration

### 3.1 Configure Link Sharing Controls

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control how designs can be shared via links.

#### ClickOps Implementation

**Step 1: Configure Organization Sharing**
1. Navigate to: **Admin** → **Settings** → **Sharing**
2. Configure link sharing options:
   - **Allow link sharing:** On/Off
   - **Default access level:** View only

**Step 2: Restrict External Sharing**
1. Configure who can create public links
2. Set expiration for shared links
3. Control embed permissions

---

### 3.2 Configure External Collaboration

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control collaboration with external users.

#### ClickOps Implementation

**Step 1: Configure Guest Access**
1. Navigate to: **Admin** → **Settings** → **Guests**
2. Configure guest permissions:
   - Can edit vs. view only
   - Access duration
   - Require 2FA

**Step 2: Configure External Content**
1. Restrict access to external Figma content
2. Prevent data loss to external organizations
3. Block unauthorized external collaboration

---

### 3.3 Configure Sensitivity Labels

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Use sensitivity labels to classify designs.

#### ClickOps Implementation

**Step 1: Configure Labels**
1. Navigate to: **Admin** → **Settings** → **Sensitivity labels**
2. Create custom labels:
   - Confidential
   - Internal
   - Public
3. Configure label colors

**Step 2: Apply Labels**
1. Builders add labels to apps
2. Labels appear in navigation
3. Visual cue for data sensitivity

---

## 4. Monitoring & Governance

### 4.1 Configure Activity Logs

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Monitor user activity through activity logs.

#### ClickOps Implementation

**Step 1: Access Activity Logs**
1. Navigate to: **Admin** → **Activity logs**
2. Review logged events:
   - File access
   - Permission changes
   - Export actions
   - Login events

**Step 2: Export Logs**
1. Export logs for analysis
2. Integrate with SIEM if needed
3. Set up regular reviews

**Key Events to Monitor:**
- Design exports
- Permission changes
- External sharing
- Admin actions

---

### 4.2 Configure Governance+ Features

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Enable Governance+ for advanced security controls.

#### Prerequisites
- [ ] Figma Enterprise with Governance+ add-on

#### ClickOps Implementation

**Step 1: Enable Governance+**
1. Contact Figma sales for Governance+
2. Enable advanced features:
   - Multiple IdPs
   - Advanced activity logs
   - Extended controls

**Step 2: Configure Advanced Controls**
1. Configure per-team authentication
2. Enable advanced reporting
3. Set up compliance dashboards

---

### 4.3 Domain Management

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Manage all accounts using company domains.

#### ClickOps Implementation

**Step 1: Register Domains**
1. Navigate to: **Admin** → **Settings** → **Domains**
2. Register all official company domains
3. This must be done before SSO setup

**Step 2: Claim Existing Accounts**
1. Identify existing accounts using company domain
2. Migrate to organization
3. Consolidate shadow accounts

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Figma Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Admin roles | [2.2](#22-configure-admin-roles) |
| CC6.6 | Sharing controls | [3.1](#31-configure-link-sharing-controls) |
| CC6.7 | Network restrictions | [2.3](#23-restrict-network-access) |
| CC7.2 | Activity logs | [4.1](#41-configure-activity-logs) |

### NIST 800-53 Rev 5 Mapping

| Control | Figma Control | Guide Section |
|---------|---------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-enforce-two-factor-authentication) |
| AC-2 | SCIM | [1.3](#13-configure-user-provisioning-scim) |
| AC-3 | Sharing controls | [3.1](#31-configure-link-sharing-controls) |
| AU-2 | Activity logs | [4.1](#41-configure-activity-logs) |

---

## Appendix A: Plan Compatibility

| Feature | Professional | Organization | Enterprise |
|---------|--------------|--------------|------------|
| SAML SSO | ❌ | ✅ | ✅ |
| SCIM | ❌ | ❌ | ✅ |
| Enforced 2FA for Guests | ❌ | ✅ | ✅ |
| Activity Logs | ❌ | Basic | Advanced |
| Network Restrictions | ❌ | ❌ | ✅ |
| Governance+ | ❌ | ❌ | Add-on |

---

## Appendix B: References

**Official Figma Documentation:**
- [Guide to SAML SSO](https://help.figma.com/hc/en-us/articles/360040532333-Guide-to-SAML-SSO)
- [Privacy and Security in Organizations](https://help.figma.com/hc/en-us/articles/360040056294-Privacy-and-security-in-organizations)
- [Governance+ for Figma Enterprise](https://help.figma.com/hc/en-us/articles/31825370509591-Governance-for-Figma-Enterprise)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, access controls, and governance | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
