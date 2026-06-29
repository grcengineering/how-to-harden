---
layout: guide
title: "Figma Enterprise Hardening Guide"
vendor: "Figma"
slug: "figma"
tier: "2"
category: "Productivity"
description: "Design platform hardening for Figma Enterprise including SSO, access controls, and governance features"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

Figma is the leading collaborative design platform used by **millions of designers** worldwide for UI/UX design, prototyping, and design systems. As a repository for intellectual property including product designs and brand assets, Figma security configurations directly impact data protection and competitive advantage.

### Intended Audience
- Security engineers managing design platforms
- IT administrators configuring Figma Enterprise
- GRC professionals assessing collaboration security
- Design operations teams managing access

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication and enforce organizational security policies.

#### Rationale
**Why This Matters:**
- Centralizes Figma authentication in your corporate IdP so MFA, conditional access, and session policies apply to every login
- Local email-and-password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- Enforcing "Members must log in with SAML SSO" prevents users from creating shadow accounts outside organizational governance
- Figma files hold unreleased product designs, brand assets, and prototypes — a single compromised login can expose your entire design pipeline

**Attack Prevented:** Credential theft, phishing, password reuse, shadow accounts, unauthorized access

#### Prerequisites
- Figma Organization or Enterprise plan
- SAML 2.0 compatible identity provider
- Verified domain in Figma

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for organization members and guests.

#### Rationale
**Why This Matters:**
- A second authentication factor blocks account takeover even when a password is phished, leaked, or reused
- Guests and external collaborators sit outside your IdP, so enforced 2FA is the only MFA control that reaches them
- Enforcement across web, desktop, and mobile closes the gap where a single unprotected client becomes the weakest link
- Design files often contain confidential roadmaps and customer-facing assets that attackers monetize or leak

**Attack Prevented:** Credential stuffing, password reuse, phishing, guest account takeover

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure SCIM for automatic user provisioning and deprovisioning.

#### Rationale
**Why This Matters:**
- Automatic deprovisioning removes a departing employee's Figma access the moment they leave the IdP, eliminating orphaned accounts with standing design access
- Manual offboarding is error-prone and frequently leaves seats active long after a user should retain access
- Provisioning attributes from the IdP keeps roles and group membership consistent, reducing privilege drift
- Orphaned accounts holding editor access to proprietary designs are a quiet, persistent insider and data-loss risk

**Attack Prevented:** Orphaned-account access, insider threat, privilege creep, offboarding gaps

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure team and project permissions following least privilege.

#### Rationale
**Why This Matters:**
- Least-privilege team and project roles limit each user to only the files their work requires, shrinking the blast radius of any compromised account
- Default broad access lets any member view or edit sensitive designs they have no business touching
- Separating Admin, Editor, and Viewer roles prevents accidental or malicious changes to production design systems
- Tight project scoping contains exposure when a single credential is phished or a guest oversteps

**Attack Prevented:** Lateral movement, unauthorized edits, data exposure, privilege abuse

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Implement role-based access for organization administration.

#### Rationale
**Why This Matters:**
- Organization Admins can change SSO, sharing, and security settings, so every excess admin is a high-value target and a single point of failure
- Limiting Organization Admin to a small group and using scoped Team Admin roles enforces separation of duties
- Fewer privileged accounts means fewer credentials whose compromise grants full tenant control
- Documented admin assignments make unauthorized privilege escalation immediately visible during review

**Attack Prevented:** Privilege escalation, admin account takeover, configuration tampering, insider abuse

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Restrict personal account access on corporate networks.

#### Rationale
**Why This Matters:**
- Blocking personal Figma accounts on the corporate network stops employees from moving company designs into accounts you cannot govern or audit
- Personal accounts sit outside SSO, SCIM, activity logging, and DLP, creating an invisible data-exfiltration channel
- Restricting to organization-domain accounts ensures all design work stays within monitored, owned tenancy
- Shadow IT usage of Figma is a common path for intellectual property to leak undetected

**Attack Prevented:** Data exfiltration, shadow IT, unmonitored access, IP leakage

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control how designs can be shared via links.

#### Rationale
**Why This Matters:**
- Open shareable links can expose confidential designs to anyone with the URL, including forwarded recipients and indexing services
- Setting a view-only default and restricting who can create public links prevents accidental oversharing of sensitive files
- Link expiration limits how long a leaked or forwarded URL remains usable
- Public design links are a frequent source of unintended intellectual-property disclosure

**Attack Prevented:** Accidental public exposure, link leakage, unauthorized access, data loss

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control collaboration with external users.

#### Rationale
**Why This Matters:**
- Guests and external collaborators operate outside your IdP and policies, so explicit access limits keep them from over-reaching
- Restricting edit rights and access duration for guests prevents external parties from retaining standing access to internal designs
- Blocking unsanctioned access to external Figma content stops data from flowing into organizations you do not control
- Uncontrolled external collaboration is a direct path for proprietary designs to leave the organization

**Attack Prevented:** Data leakage to third parties, guest over-permissioning, unauthorized external access

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Use sensitivity labels to classify designs.

#### Rationale
**Why This Matters:**
- Classifying designs as Confidential, Internal, or Public makes data sensitivity visible so users handle each file appropriately
- Without labels, collaborators cannot distinguish public marketing assets from unreleased product designs and may overshare
- Labels create the foundation for downstream controls, reviews, and audit decisions tied to classification
- Visual sensitivity cues reduce the human error that leads to confidential material being shared externally

**Attack Prevented:** Accidental disclosure, mishandling of sensitive data, oversharing, classification errors

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Monitor user activity through activity logs.

#### Rationale
**Why This Matters:**
- Activity logs capture file access, permission changes, exports, and logins so suspicious behavior can be detected and investigated
- Without logging, account compromise and insider data theft go unnoticed until the damage is already done
- Exporting logs to a SIEM enables correlation, alerting, and retention beyond the native console
- Monitoring exports and external sharing surfaces the specific actions that precede intellectual-property loss

**Attack Prevented:** Undetected breach, insider data theft, unauthorized exports, audit gaps

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Enable Governance+ for advanced security controls.

#### Rationale
**Why This Matters:**
- Governance+ unlocks advanced activity logs, multiple IdPs, and extended controls needed by regulated and high-sensitivity organizations
- Per-team authentication lets you apply stronger IdP policies to teams handling the most sensitive designs
- Advanced reporting and compliance dashboards provide the evidence auditors and regulators require
- Granular governance reduces the risk that a one-size-fits-all configuration leaves sensitive teams under-protected

**Attack Prevented:** Insufficient monitoring, weak segmentation, compliance gaps, under-protected teams

#### Prerequisites
- Figma Enterprise with Governance+ add-on

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Manage all accounts using company domains.

#### Rationale
**Why This Matters:**
- Registering all company domains lets the organization claim and govern every account created with corporate email addresses
- Unclaimed accounts on your domain operate outside SSO, logging, and admin control, forming a pool of shadow access
- Domain verification is the prerequisite that makes SSO enforcement and centralized policy possible
- Consolidating shadow accounts removes ungoverned editor access to proprietary designs

**Attack Prevented:** Shadow accounts, ungoverned access, SSO bypass, account sprawl

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
- [Trust Center (Conveyor)](https://compliance.figma.com/)
- [Figma Security](https://www.figma.com/security/)
- [Help Center](https://help.figma.com/hc/en-us)
- [Guide to SAML SSO](https://help.figma.com/hc/en-us/articles/360040532333-Guide-to-SAML-SSO)
- [Privacy and Security in Organizations](https://help.figma.com/hc/en-us/articles/360040056294-Privacy-and-security-in-organizations)
- [Governance+ for Figma Enterprise](https://help.figma.com/hc/en-us/articles/31825370509591-Governance-for-Figma-Enterprise)

**API & Developer Documentation:**
- [REST API Reference](https://developers.figma.com/docs/rest-api/)
- [Figma Developer Platform](https://developers.figma.com/)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO 27001:2022, ISO 27018 — via [Trust Center](https://compliance.figma.com/)
- EU Cloud Code of Conduct Level 2 compliant
- Annual CSA Consensus Assessments Initiative Questionnaire (CAIQ) completion
- Annual independent external audits against SOC 2 and ISO 27001

**Security Incidents:**
- No major public security incidents identified affecting the Figma platform.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, access controls, and governance | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
