---
layout: guide
title: "LaunchDarkly Hardening Guide"
vendor: "LaunchDarkly"
slug: "launchdarkly"
tier: "4"
category: "DevOps"
description: "Feature flag security for SDK keys, environment access, and approval workflows"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

LaunchDarkly manages feature flags controlling application behavior across environments. REST API, SDK keys, and webhook integrations control feature rollouts. Compromised access enables feature manipulation, environment privilege escalation, or extraction of targeting rules revealing business logic.

### Intended Audience
- Security engineers managing feature flag systems
- DevOps/Platform administrators
- GRC professionals assessing release management
- Third-party risk managers evaluating deployment integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers LaunchDarkly security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [SDK & API Security](#2-sdk--api-security)
3. [Environment Security](#3-environment-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML single sign-on with multi-factor authentication for all LaunchDarkly account access, and provision and deprovision users automatically through SCIM.

#### Rationale
**Why This Matters:**
- Centralizes LaunchDarkly authentication in your corporate IdP so MFA and conditional-access policies apply to every login
- Local or password-only logins bypass IdP controls and are prime targets for credential stuffing and phishing
- SCIM provisioning removes departed users automatically, eliminating orphaned accounts that retain flag-modification rights
- A single compromised LaunchDarkly login can flip feature flags in production, exposing hidden features or disabling security controls

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Account settings → Security → SAML**
2. Configure SAML IdP
3. Enable: **Require SSO**

**Step 2: Configure SCIM**
1. Enable SCIM provisioning
2. Configure user/group sync
3. Set deprovisioning behavior

---


{% include pack-code.html vendor="launchdarkly" section="1.1" %}

### 1.2 Role-Based Access Control

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define custom roles and project- and environment-scoped permissions so each member has only the LaunchDarkly access their job requires.

#### Rationale
**Why This Matters:**
- Least-privilege roles limit who can create, modify, or toggle flags in sensitive environments like production
- Default broad access lets any member change targeting rules that govern application behavior and customer exposure
- Scoping roles to specific projects and environments contains the blast radius of a single compromised account
- Reader-only roles for auditors and observers prevent accidental or malicious flag changes

**Attack Prevented:** Privilege escalation, unauthorized flag changes, lateral movement across projects, insider misuse

#### ClickOps Implementation

**Step 1: Define Custom Roles**

| Role | Permissions |
|------|-------------|
| Admin | Full access |
| Writer | Create/modify flags |
| Reader | View only |
| No access | Blocked |

**Step 2: Configure Project/Environment Access**
1. Navigate to: **Account settings → Roles**
2. Create environment-specific roles
3. Apply least privilege

---


{% include pack-code.html vendor="launchdarkly" section="1.2" %}

## 2. SDK & API Security

### 2.1 Secure SDK Keys

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Protect LaunchDarkly SDK keys.

#### Rationale
**Why This Matters:**
- Server-side SDK keys grant read access to all flags and targeting rules in an environment and must never ship in client code
- Mobile keys and client-side IDs are exposure-safe, but using the wrong key type leaks server-only data to browsers and mobile apps
- Periodic key rotation limits how long a leaked key remains usable by an attacker
- Targeting rules often encode business logic, customer segments, and rollout plans that competitors or attackers can exploit

**Attack Prevented:** SDK key leakage, flag enumeration, targeting-rule extraction, business-logic disclosure

**Attack Scenario:** Exposed SDK key enables flag enumeration; mobile SDK key in client bundle allows targeting rule extraction.

#### Implementation

**SDK Key Types:**

| Key Type | Exposure Risk | Use Case |
|----------|---------------|----------|
| SDK Key | Server-side only | Backend services |
| Mobile Key | Client-side safe | Mobile apps |
| Client-side ID | Client-side safe | Browser apps |

**Step 1: Rotate Keys**
1. Navigate to: **Project settings → Environments**
2. Reset SDK keys periodically
3. Update applications

---


{% include pack-code.html vendor="launchdarkly" section="2.1" %}

### 2.2 API Token Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Inventory LaunchDarkly access tokens, remove unused ones, and issue new tokens scoped to specific roles, projects, environments, and expiration dates.

#### Rationale
**Why This Matters:**
- API tokens authenticate automated access to the full LaunchDarkly REST API and can modify flags without a human login or MFA prompt
- Long-lived or unscoped tokens that leak give attackers persistent control over feature configuration
- Scoping tokens to least-privilege custom roles and specific projects limits what a stolen token can do
- Expiration dates and regular audits ensure forgotten tokens do not become standing backdoors

**Attack Prevented:** Token theft, persistent API access, unauthorized flag manipulation, MFA bypass via automation

#### ClickOps Implementation

**Step 1: Audit Access Tokens**
1. Navigate to: **Account settings → Authorization → Access tokens**
2. Review all tokens
3. Remove unused tokens

**Step 2: Create Scoped Tokens**
1. Create tokens with custom roles
2. Limit to specific projects/environments
3. Set expiration dates

---


{% include pack-code.html vendor="launchdarkly" section="2.2" %}

## 3. Environment Security

### 3.1 Environment Segmentation

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-3

#### Description
Separate LaunchDarkly environments and require comments, review or approval, and change history for changes to production.

#### Rationale
**Why This Matters:**
- Isolating dev, staging, and production prevents test changes from accidentally altering live application behavior
- Required reviews and approvals add a human checkpoint before high-impact production flag changes take effect
- Mandatory comments and change history create an audit trail tying every change to a reason and an author
- Approval workflows stop a single compromised or careless account from unilaterally toggling production features

**Attack Prevented:** Unauthorized production changes, accidental misconfiguration, unreviewed flag flips, change repudiation

#### ClickOps Implementation

**Step 1: Configure Environment Settings**
1. Navigate to: **Project settings → Environments**
2. Configure:
   - Require comments for changes
   - Require review for production
   - Enable change history

**Step 2: Approval Workflows (Enterprise)**
1. Configure approval requirements
2. Set minimum approvers
3. Define bypass conditions

---


{% include pack-code.html vendor="launchdarkly" section="3.1" %}

### 3.2 Flag Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-7

#### Description
Tag flags that control security-sensitive behavior, apply extra review to them, and restrict who can view and change targeting rules.

#### Rationale
**Why This Matters:**
- Flags that gate authentication, authorization, or other security controls can disable protections if flipped maliciously
- Tagging and extra review ensure security-relevant flags receive scrutiny proportional to their impact
- Restricting visibility of targeting rules prevents leakage of customer segments and internal business logic
- Monitoring rule changes detects enumeration or tampering attempts before they affect users

**Attack Prevented:** Security-control bypass, targeting-rule enumeration, business-logic disclosure, unauthorized flag tampering

#### Implementation

**Step 1: Tag Sensitive Flags**
1. Tag flags controlling security features
2. Apply additional review requirements
3. Audit changes

**Step 2: Targeting Rule Protection**
1. Limit who can view targeting rules
2. Audit rule changes
3. Monitor for enumeration

---


{% include pack-code.html vendor="launchdarkly" section="3.2" %}

## 4. Monitoring & Detection

### 4.1 Audit Log

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Review the LaunchDarkly audit log regularly and export it to your SIEM to retain a durable record of all account, role, token, and flag changes.

#### Rationale
**Why This Matters:**
- The audit log records who changed which flag, role, token, or setting and when, enabling investigation and accountability
- Exporting to a SIEM preserves events beyond the platform retention window and correlates them with other security telemetry
- Without centralized monitoring, malicious flag changes and token abuse can go undetected until they cause harm
- Audit evidence supports SOC 2, ISO 27001, and other compliance obligations for change management

**Attack Prevented:** Undetected tampering, repudiation, delayed incident detection, audit-trail gaps

#### ClickOps Implementation

**Step 1: Access Audit Log**
1. Navigate to: **Account settings → Audit log**
2. Review changes
3. Configure SIEM export

#### Detection Focus

{% include pack-code.html vendor="launchdarkly" section="4.1" %}

## Appendix A: Edition Compatibility

| Control | Pro | Enterprise |
|---------|-----|------------|
| SAML SSO | ✅ | ✅ |
| SCIM | ❌ | ✅ |
| Custom Roles | ✅ | ✅ |
| Approval Workflows | ❌ | ✅ |

---

## Appendix B: References

**Official LaunchDarkly Documentation:**
- [LaunchDarkly Security](https://launchdarkly.com/security/)
- [LaunchDarkly Documentation](https://launchdarkly.com/docs/home)
- [Security Program Addendum](https://launchdarkly.com/policies/security-program-addendum/)

**API & Developer Resources:**
- [LaunchDarkly REST API](https://apidocs.launchdarkly.com/)
- [LaunchDarkly SDKs](https://launchdarkly.com/docs/sdk)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27701, FedRAMP Moderate ATO, HIPAA -- compliance reports available upon request via [LaunchDarkly Support](https://support.launchdarkly.com/hc/en-us/articles/37200551039515-How-to-request-LaunchDarkly-s-SOC-2-ISO-27001-and-penetration-testing-reports)

**Security Incidents:**
- No major public security breaches identified as of this writing.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial LaunchDarkly hardening guide | Claude Code (Opus 4.5) |
