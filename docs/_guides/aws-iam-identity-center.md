---
layout: guide
title: "AWS IAM Identity Center Hardening Guide"
vendor: "Amazon Web Services"
slug: "aws-iam-identity-center"
tier: "1"
category: "Identity & Access Management"
description: "AWS identity management hardening for IAM Identity Center including MFA, permission sets, and account access"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

AWS IAM Identity Center (formerly AWS SSO) is the recommended service for managing workforce access to AWS accounts and applications. As the central identity service for AWS Organizations, IAM Identity Center security configurations directly impact cloud access security.

### Intended Audience
- Security engineers managing AWS access
- Cloud administrators configuring IAM Identity Center
- Platform engineers managing AWS Organizations
- GRC professionals assessing cloud identity

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers AWS IAM Identity Center security including MFA enforcement, permission sets, identity sources, and session policies.

---

## Table of Contents

1. [Authentication & MFA](#1-authentication--mfa)
2. [Identity Source Configuration](#2-identity-source-configuration)
3. [Permission Management](#3-permission-management)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & MFA

### 1.1 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all IAM Identity Center users.

#### Prerequisites
- [ ] IAM Identity Center enabled in management account
- [ ] AWS Organizations configured
- [ ] Admin access to IAM Identity Center

#### ClickOps Implementation

**Step 1: Access MFA Settings**
1. Navigate to: **IAM Identity Center** → **Settings** → **Authentication**
2. Find MFA configuration

**Step 2: Configure MFA Requirement**
1. Select **Require MFA**
2. Configure enforcement:
   - Every sign-in (recommended)
   - Context-aware
3. Save changes

**Step 3: Configure MFA Types**
1. Enable authenticator apps
2. Enable hardware TOTP devices
3. Enable FIDO2 security keys (recommended)
4. Disable SMS if possible

**Time to Complete:** ~30 minutes

---

### 1.2 Configure Session Duration

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure appropriate session duration limits.

#### ClickOps Implementation

**Step 1: Configure Portal Session**
1. Navigate to: **Settings** → **Authentication**
2. Set session duration
3. Balance security with usability

**Step 2: Configure Permission Set Session**
1. Edit permission set
2. Set session duration
3. Apply shorter duration for privileged access

---

### 1.3 Configure Attribute-Based Access Control

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.8 |
| NIST 800-53 | AC-3 |

#### Description
Enable ABAC for fine-grained access control.

#### ClickOps Implementation

**Step 1: Enable ABAC**
1. Navigate to: **Settings** → **Attributes for access control**
2. Enable attributes
3. Configure attribute mappings

**Step 2: Use in Permission Sets**
1. Create ABAC-aware policies
2. Reference user attributes
3. Implement tag-based access

---

## 2. Identity Source Configuration

### 2.1 Configure External Identity Provider

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Connect to external IdP for centralized identity.

#### ClickOps Implementation

**Step 1: Change Identity Source**
1. Navigate to: **Settings** → **Identity source**
2. Click **Change identity source**
3. Select external identity provider

**Step 2: Configure SAML/SCIM**
1. Configure SAML 2.0 settings
2. Enable automatic provisioning (SCIM)
3. Configure attribute mappings

**Step 3: Test and Migrate**
1. Test authentication
2. Migrate users from Identity Center directory
3. Verify access preserved

---

### 2.2 Configure Automatic Provisioning

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Enable SCIM for automatic user provisioning.

#### ClickOps Implementation

**Step 1: Enable SCIM**
1. Navigate to: **Settings** → **Identity source**
2. Enable automatic provisioning
3. Generate SCIM endpoint and token

**Step 2: Configure IdP**
1. Configure SCIM in identity provider
2. Map user attributes
3. Enable group sync

---

## 3. Permission Management

### 3.1 Configure Permission Sets

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Create least-privilege permission sets.

#### ClickOps Implementation

**Step 1: Review Permission Sets**
1. Navigate to: **Permission sets**
2. Review existing permission sets
3. Identify overly permissive sets

**Step 2: Create Least-Privilege Sets**
1. Create custom permission sets
2. Use AWS managed policies where possible
3. Apply inline policies for restrictions

**Step 3: Configure Permissions Boundary**
1. Apply permissions boundaries
2. Limit maximum permissions
3. Prevent privilege escalation

---

### 3.2 Configure Account Assignments

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Assign access to AWS accounts.

#### ClickOps Implementation

**Step 1: Review Assignments**
1. Navigate to: **AWS accounts**
2. Review current assignments
3. Identify unnecessary access

**Step 2: Apply Least Privilege**
1. Assign minimum required accounts
2. Use groups for assignments
3. Regular access reviews

---

### 3.3 Protect Privileged Access

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Additional controls for privileged access.

#### ClickOps Implementation

**Step 1: Create Privileged Permission Sets**
1. Create separate admin permission sets
2. Apply shorter session duration
3. Require MFA for every session

**Step 2: Limit Admin Assignments**
1. Restrict admin access to required users
2. Use groups for admin access
3. Regular privileged access reviews

---

## 4. Monitoring & Compliance

### 4.1 Configure CloudTrail Logging

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable CloudTrail for IAM Identity Center events.

#### ClickOps Implementation

**Step 1: Verify CloudTrail**
1. Ensure organization trail enabled
2. Verify IAM Identity Center events captured
3. Configure log retention

**Step 2: Monitor Key Events**
1. Authentication events
2. Permission changes
3. Account assignments

---

### 4.2 Configure Access Analyzer

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Use IAM Access Analyzer for policy validation.

#### ClickOps Implementation

**Step 1: Enable Access Analyzer**
1. Create analyzer for organization
2. Review findings
3. Remediate external access

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | IAM Identity Center Control | Guide Section |
|-----------|----------------------------|---------------|
| CC6.1 | MFA enforcement | [1.1](#11-enforce-multi-factor-authentication) |
| CC6.2 | Permission sets | [3.1](#31-configure-permission-sets) |
| CC6.6 | Session duration | [1.2](#12-configure-session-duration) |
| CC7.2 | CloudTrail logging | [4.1](#41-configure-cloudtrail-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | IAM Identity Center Control | Guide Section |
|---------|----------------------------|---------------|
| IA-2(1) | MFA | [1.1](#11-enforce-multi-factor-authentication) |
| IA-8 | External IdP | [2.1](#21-configure-external-identity-provider) |
| AC-2 | SCIM provisioning | [2.2](#22-configure-automatic-provisioning) |
| AC-6 | Permission sets | [3.1](#31-configure-permission-sets) |
| AU-2 | CloudTrail | [4.1](#41-configure-cloudtrail-logging) |

---

## Appendix A: References

**Official AWS Documentation:**
- [IAM Identity Center User Guide](https://docs.aws.amazon.com/singlesignon/latest/userguide/)
- [Best Practices](https://docs.aws.amazon.com/singlesignon/latest/userguide/best-practices.html)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with MFA, permission sets, and monitoring | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
