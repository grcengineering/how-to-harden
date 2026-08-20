---
layout: guide
title: "LaunchDarkly Hardening Guide"
vendor: "LaunchDarkly"
slug: "launchdarkly"
tier: "4"
category: "DevOps"
description: "Feature flag security for SDK keys, environment access, and approval workflows"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
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
1. Navigate to: **gear icon (left sidebar) → Organization settings → Security → SSO Management**
2. Click **Configure SAML** and enter your IdP's SSO URL, X.509 certificate, and (if required) the request signing settings
3. Enable: **Require SSO**

**Set the default initial role to "No access."** LaunchDarkly recommends configuring the default initial role for SSO-provisioned members to the lowest privilege available so that a newly federated account cannot read or change flags before an admin grants scoped access. On Developer and Foundation plans the lowest available default is **Reader**; Enterprise plans can set **No access**. ([SSO documentation](https://launchdarkly.com/docs/home/account/sso))

**One identity provider per account.** LaunchDarkly supports a single configured identity provider per account — you cannot federate a second IdP alongside the first, so plan IdP migrations as a cutover with an admin fallback path. ([SSO documentation](https://launchdarkly.com/docs/home/account/sso))

**Step 2: Configure SCIM**
1. Enable SCIM provisioning (Enterprise — see Appendix A)
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
1. Navigate to: **gear icon (left sidebar) → Organization settings → Roles**, then click **New role**
2. Create environment-specific roles
3. Apply least privilege

Custom roles are an Enterprise capability — see Appendix A. ([Creating custom roles](https://launchdarkly.com/docs/home/account/role-create))

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
Inventory LaunchDarkly access tokens, remove unused ones, and issue new tokens scoped with the least-privilege role or inline policy the caller actually needs — choosing personal tokens for human-owned scripts and service tokens for automation that must survive offboarding.

#### Rationale
**Why This Matters:**
- API tokens authenticate automated access to the full LaunchDarkly REST API and can modify flags without a human login or MFA prompt
- Long-lived or unscoped tokens that leak give attackers persistent control over feature configuration
- Scoping tokens to least-privilege base roles, custom roles, or inline policies limits what a stolen token can do
- Service tokens are deliberately member-independent, so they keep working after the person who created them leaves — that durability is why they need a standing inventory and an owner of record

**Attack Prevented:** Token theft, persistent API access, unauthorized flag manipulation, MFA bypass via automation

**Personal tokens and service tokens are not interchangeable.** Personal tokens are bound to the member who created them: they can never exceed that member's own permissions, and LaunchDarkly automatically deactivates them when the member is removed from the account. Service tokens (plan-dependent — see Appendix A) are independent of any member, and their permissions are **fixed at creation and cannot be edited afterward** — to change a service token's access you must create a replacement and revoke the old one. Use service tokens for CI/CD and automation precisely because they survive offboarding, and compensate with an inventory that records each token's owner and purpose. ([Access tokens documentation](https://launchdarkly.com/docs/home/account/api))

#### ClickOps Implementation

**Step 1: Audit Access Tokens**
1. Navigate to: **gear icon (left sidebar) → Organization settings → Authorization**
2. In the **Access tokens** section, review every token, its role, and its owner
3. Remove unused tokens

**Step 2: Create Scoped Tokens and Rotate on a Cadence**
1. In the **Access tokens** section, click **Create token**, give it a human-readable **Name**, and assign the least-privilege **Role** — Reader, Writer, Admin, Owner, a custom role, or an inline policy
2. Select **This is a service token** only for automation that must outlive its creator; leave it unchecked for a personal token
3. LaunchDarkly's token-creation flow does not offer an expiration date, so enforce lifetime yourself: set a written rotation cadence (for example, quarterly), record each token's issue date in your inventory, and reset or delete tokens on schedule rather than relying on a platform expiry ([Creating API access tokens](https://launchdarkly.com/docs/home/account/api-create))

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
1. Navigate to: **Account settings → Audit log** *(LaunchDarkly renamed the account settings area to **Organization settings**, reached via the gear icon in the left sidebar; the audit log documentation page was not publicly resolvable during this pass, so verify the exact path in your own account)*
2. Review changes
3. Configure SIEM export

#### Detection Focus

{% include pack-code.html vendor="launchdarkly" section="4.1" %}

## Appendix A: Edition Compatibility

LaunchDarkly's public pricing page lists three plan tiers — **Developer**, **Foundation**, and **Enterprise**. The "Pro" tier this guide previously referenced no longer appears in LaunchDarkly's plan lineup.

| Control | Developer | Foundation | Enterprise |
|---------|-----------|------------|------------|
| SAML SSO | ✅ | ✅ | ✅ |
| SCIM provisioning | ❌ | ❌ | ✅ |
| Custom Roles | ❌ | ❌ | ✅ |
| Approval Workflows | ❌ | ❌ | ✅ |
| Service tokens | ❌ | ❌ | ✅ |
| Default initial role "No access" | ❌ (Reader) | ❌ (Reader) | ✅ |

**Two LaunchDarkly sources disagree on tier naming — verify against your own contract.** The pricing page lists Developer / Foundation / Enterprise, while the SSO documentation attributes SCIM and team sync to a **"Guardian"** tier that does not appear in the published pricing lineup. Both are first-party LaunchDarkly sources, so this guide records the disagreement rather than resolving it: treat SCIM, custom roles, service tokens, and approvals as **top-tier-only** capabilities and confirm the exact plan name on your contract or with your account team before planning around them. ([Pricing](https://launchdarkly.com/pricing) · [SSO documentation](https://launchdarkly.com/docs/home/account/sso))

---

## Appendix B: References

**Official LaunchDarkly Documentation:**
- [LaunchDarkly Documentation](https://launchdarkly.com/docs/home)
- [Single sign-on (SSO)](https://launchdarkly.com/docs/home/account/sso)
- [API access tokens](https://launchdarkly.com/docs/home/account/api)
- [Creating API access tokens](https://launchdarkly.com/docs/home/account/api-create)
- [Creating custom roles](https://launchdarkly.com/docs/home/account/role-create)
- [Plans and pricing](https://launchdarkly.com/pricing)

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
| 2026-08-08 | 0.2.0 | draft | Currency pass: correct plan tiers to Developer/Foundation/Enterprise with a both-sources note on the "Guardian" naming conflict; update console paths to Organization settings (SSO, Roles, Authorization verified against current docs; audit-log path annotated as unverified); add SSO default-initial-role and single-IdP callouts; distinguish personal vs service tokens and replace the unsupported token-expiration step with a manual rotation cadence; replace Trust Center/security-program links with first-party configuration docs | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial LaunchDarkly hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
