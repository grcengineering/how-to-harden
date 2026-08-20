---
layout: guide
title: "Outreach Hardening Guide"
vendor: "Outreach"
slug: "outreach"
tier: "2"
category: "Productivity"
description: "Sales engagement platform hardening for Outreach including SAML SSO, user permissions, and data security"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Outreach is a sales engagement platform providing automation and analytics for sales teams. As a platform managing customer communications and sales data, Outreach security configurations directly impact data protection and sales operations.

### Intended Audience
- Security engineers managing sales tools
- IT administrators configuring Outreach
- Sales operations managers
- GRC professionals assessing sales platform security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Outreach security including SAML SSO, user permissions, data access, and integration security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Data Security](#3-data-security)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO for Outreach access.

#### Rationale
**Why This Matters:**
- Routes every Outreach login through your corporate IdP, so centralized password policy, MFA, and conditional access apply on each authentication
- Standalone Outreach passwords sit outside IdP visibility and are prime targets for credential stuffing and phishing against sales teams
- Centralized provisioning and deprovisioning means a terminated rep loses Outreach access the moment their IdP account is disabled, preventing orphaned accounts
- Outreach holds prospect contact data, email sequences, and CRM-synced pipeline intelligence, so a single hijacked login can expose the entire book of business

**Attack Prevented:** Credential stuffing, phishing, orphaned-account access, account takeover

#### Prerequisites
- Outreach admin access
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Administration** → **User management** → **Sign-in**
2. Select **Edit** under **Single sign-on**
3. Toggle single sign-on on ([How to turn on/off SSO](https://support.outreach.io/support/solutions/articles/159000425308-how-to-turn-on-off-sso))

**Step 2: Configure SAML**
1. Configure IdP settings
2. Download Outreach metadata for IdP
3. Test authentication

**Step 3: Configure Advanced Identity Provider Settings**
1. Set the **NameId** format expected from your IdP
2. Decide whether to enable **just-in-time (JIT) provisioning** so IdP-authenticated users are created on first login
3. Document break-glass and fallback procedures for IdP outages

> **Documentation limit:** Outreach documents enabling/disabling SSO plus the NameId and JIT advanced settings; it does not document a separate "enforce SSO / block password login" toggle. Treat password-login suppression as an IdP-side and offboarding control until Outreach documents otherwise. Source: [Advanced settings for identity provider (SSO)](https://support.outreach.io/support/solutions/articles/159000426333-advanced-settings-for-identity-provider-sso-)

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Outreach users.

#### Rationale
**Why This Matters:**
- A second authentication factor blocks attackers who have already obtained a valid username and password
- Sales reps are heavily targeted by phishing because their accounts reach customers, partners, and revenue data
- MFA enforced at the IdP applies uniformly to every Outreach user without relying on individual opt-in
- Without MFA, one reused or leaked password grants full access to customer communications and outbound email automation

**Attack Prevented:** Phishing, credential stuffing, password reuse, automated brute force

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA

---

### 1.3 Provision and Deprovision Users via SCIM

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1, 5.3 |
| NIST 800-53 | AC-2, AC-2(1) |

#### Description
Connect your identity provider to Outreach over SCIM so user accounts and Outreach Teams membership are created, updated, and deactivated from the IdP rather than by hand in the Outreach admin console.

#### Rationale
**Why This Matters:**
- Automated deprovisioning removes a departing rep's Outreach access on the same event that disables their IdP account, closing the window where an orphaned account still reaches prospect data and outbound email
- Manual user administration drifts — SCIM makes the IdP the single authoritative record of who has an Outreach seat and which teams they belong to
- Team membership driven by IdP groups keeps data visibility scoped to the right org unit without an admin remembering to update it after every reorg

**Attack Prevented:** Orphaned-account access, offboarding gaps, unauthorized team-scoped data access, permission drift

#### Prerequisites
- Outreach admin access
- An IdP that supports SCIM 2.0 provisioning

#### ClickOps Implementation

**Step 1: Enable SCIM Provisioning**
1. Configure the Outreach SCIM connector in your identity provider per [Outreach SCIM protocol](https://support.outreach.io/support/solutions/articles/159000426344-outreach-scim-protocol)
2. Map IdP user attributes to Outreach user attributes
3. Enable deactivation-on-deprovision in the IdP

**Step 2: Map Groups**
1. Note that **Outreach Teams** is the only group type Outreach exposes over SCIM — SCIM can create Teams and manage Team membership
2. Map IdP groups to Outreach Teams for the org units that need distinct data scope
3. Do not assume other Outreach grouping constructs are SCIM-manageable

**Step 3: Verify**
1. Deactivate a test user in the IdP and confirm the Outreach account is deactivated
2. Confirm Team membership changes propagate

---

### 1.4 Set the User Session Logout Timer

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.3 |
| NIST 800-53 | AC-11, AC-12 |

#### Description
Set an organization-wide Outreach session logout duration so idle or abandoned sessions expire instead of remaining authenticated indefinitely on shared, lost, or unattended devices.

#### Rationale
**Why This Matters:**
- A long-lived session is a credential that survives the login controls around it — MFA and SSO do nothing for an attacker sitting at an already-authenticated browser
- Sales reps routinely work from laptops in customer sites, coworking spaces, and airports, where an unlocked machine is a realistic exposure path
- Bounding session lifetime also bounds the usefulness of a stolen session cookie obtained through infostealer malware or a session-hijacking phish

**Attack Prevented:** Session hijacking, unattended-device access, stolen session cookie reuse

#### Prerequisites
- Outreach admin access

#### ClickOps Implementation

**Step 1: Open Session Options**
1. Navigate to: **Administration** → **User management** → **Sign-in**
2. Select **Sign-in and password options**
3. Open **Session Options**

**Step 2: Set the Duration**
1. Set the session logout timer — Outreach accepts a value between **1 hour and 1 year**
2. Choose the shortest duration your sales workflow tolerates; treat multi-week and multi-month values as effectively no timeout
3. Save and confirm with a test user that re-authentication is prompted after the interval

> **Note:** Outreach documents the configurable range but does not publish the default value for this setting — read the current value in your own tenant rather than assuming one. Source: [Managing Outreach user session logout timer duration](https://support.outreach.io/support/solutions/articles/159000425314-managing-outreach-user-session-logout-timer-duration)

---

## 2. Access Controls

### 2.1 Configure User Profiles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using profiles.

#### Rationale
**Why This Matters:**
- Profile-based permissions limit each user to only the data and actions their role requires, shrinking the blast radius of any one compromised account
- Default or over-broad profiles let ordinary reps export prospect lists, alter sequences, or view other teams' pipelines
- Least-privilege assignments make insider misuse and accidental data exposure easier to detect and contain
- Regular access reviews catch permission creep before it accumulates into standing risk

**Attack Prevented:** Privilege escalation, insider data exfiltration, lateral movement, excessive data exposure

#### ClickOps Implementation

**Step 1: Review Users and Their Governance Profiles**
1. Navigate to: **Administration** → **User Management** → **Users**
2. Review each user's assigned **governance profile** — governance profiles, not a separate "Profiles" admin page, are where Outreach permissions are defined
3. Understand what each governance profile grants before assigning it

**Step 2: Apply Least Privilege at User Creation**
1. Add users via **Administration** → **User Management** → **Users** → **Add User** ([How to add new Outreach users and assign user admin permissions](https://support.outreach.io/support/solutions/articles/159000425461-how-to-add-new-outreach-users-and-assign-user-admin-permissions))
2. Assign the governance profile with the minimum permissions the role requires
3. Run regular access reviews and re-assign profiles after role changes

---

### 2.2 Configure Governance Controls

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure governance and compliance controls.

#### Rationale
**Why This Matters:**
- Governance and communication policies constrain how reps can contact prospects, reducing regulatory and reputational exposure
- Centralized compliance settings enforce consistent rules across the whole org instead of leaving them to individual discretion
- Documented communication policies create an auditable record that supports SOC 2, GDPR, and similar attestations
- Without governance controls, outbound automation can violate consent and anti-spam requirements at scale

**Attack Prevented:** Compliance violations, unauthorized outreach, regulatory exposure, policy drift

#### ClickOps Implementation

**Step 1: Configure Governance**
1. Review the governance profile settings that constrain what each role can do with prospect and communication data
2. Configure compliance settings to match your consent and anti-spam obligations
3. Set communication policies centrally rather than leaving them to individual reps

**Step 2: Configure Email Safeguards and Sending Limits**
1. Configure per-mailbox send safeguards under **Personal Settings** → *(select mailbox)* → **Show advanced settings** → **Send settings**
2. Documented limits include **Maximum bulk emails this mailbox can send per day from within Outreach**, **Maximum bulk emails this mailbox can send per week from within Outreach**, **Mailbox in/out cut-off limit per day (total regardless of Outreach)**, and **Maximum deliveries allowed within a time period** ([How to configure Outreach user email limits and safeguards](https://support.outreach.io/support/solutions/articles/159000426349-how-to-configure-outreach-user-email-limits-and-safeguards))
3. Cap sending volume so a hijacked mailbox cannot blast the entire prospect database before anyone notices

**Step 3: Configure Sending-Domain Authentication**
1. Publish and maintain **SPF**, **DKIM**, and **DMARC** records for every domain Outreach sends from ([SPF, DKIM, and DMARC overview for Outreach email users](https://support.outreach.io/support/solutions/articles/159000425866-spf-dkim-and-dmarc-overview-for-outreach-email-users))
2. Domain authentication is what prevents a third party from spoofing your sending domain and what keeps legitimate sequences out of spam

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect admin accounts.

#### Rationale
**Why This Matters:**
- Admin accounts can change security settings, manage all users, and access every record, making each one a high-value target
- Reducing the number of admins shrinks both the attack surface and the chance of accidental misconfiguration
- Requiring MFA on admins and monitoring their activity surfaces compromise and abuse quickly
- A single hijacked admin account can disable SSO, exfiltrate the entire prospect database, or weaponize email automation

**Attack Prevented:** Admin account takeover, privilege abuse, configuration tampering, mass data exfiltration

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Navigate to: **Administration** → **User Management** → **Users**
2. Review which accounts carry user-admin permissions and which governance profile each holds
3. Document admin access and its business justification

**Step 2: Apply Restrictions**
1. Limit user-admin permissions to the smallest set of required personnel ([How to add new Outreach users and assign user admin permissions](https://support.outreach.io/support/solutions/articles/159000425461-how-to-add-new-outreach-users-and-assign-user-admin-permissions))
2. Require MFA at the IdP for every admin
3. Monitor admin activity and re-review after every role change

---

## 3. Data Security

### 3.1 Configure Integration Security

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure third-party integrations.

#### Rationale
**Why This Matters:**
- Connected apps and OAuth integrations often hold broad, long-lived access to Outreach data and can become a back door if compromised
- Removing unused integrations eliminates dormant tokens that attackers can abuse without touching user passwords or MFA
- Granting each integration the minimum scope limits what a breached third party can read or change
- Sales data flowing to external tools expands the supply-chain attack surface that bypasses your primary authentication controls

**Attack Prevented:** Supply-chain compromise, OAuth token abuse, third-party data leakage, over-privileged integrations

#### ClickOps Implementation

**Step 1: Review Integrations**
1. Navigate to: **Admin Settings** → **Integrations**
2. Review connected apps
3. Remove unnecessary integrations

**Step 2: Apply Least Privilege**
1. Grant minimum permissions
2. Monitor integration activity

---

### 3.2 Disable Unneeded GenAI and Agentic Features

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.8 |
| NIST 800-53 | CM-7, AC-3 |

#### Description
Turn off the Outreach GenAI and agentic capabilities your organization has not approved — including the **MCP Server** — at the org level, and restrict the remainder per governance profile so AI features only reach the roles cleared to use them.

#### Rationale
**Why This Matters:**
- GenAI and agentic features send prospect records, email content, and deal data into model-backed processing paths that your data-handling policy may not yet cover
- An enabled MCP Server turns Outreach into a tool surface reachable by external AI clients, which is a materially different exposure than a human logging into the web UI
- Disabling features you do not use is the cheapest possible reduction of attack surface — an unused agent that can read the prospect database is pure downside
- Profile-level controls let you pilot AI features with a small group instead of switching them on for the whole sales org at once

**Attack Prevented:** Unapproved data flow to AI processing, over-broad agent access to CRM data, prompt-injection-driven data exposure via connected AI clients, unreviewed feature exposure

#### Prerequisites
- Outreach admin access

#### ClickOps Implementation

**Step 1: Disable at the Org Level**
1. Navigate to: **Administration** → **Organization** → **Org info** → **GenAI**
2. Review and disable the features you have not approved. Documented org-level toggles: **Omni**, **Research Agent**, **Smart Account Assist**, **Meeting Prep Agent**, **Smart Deal Assist**, **AI Topics Explorer**, and **MCP Server**
3. Treat **MCP Server** as a deliberate, separately-justified decision — it exposes Outreach as a tool surface to AI clients

**Step 2: Restrict at the Profile Level**
1. Navigate to: **Administration** → **User management** → **Access control**
2. Disable per-profile access to the features you allow only for specific roles. Documented profile-level toggles: **Omni**, **Smart Account Assist**, **Smart Deal Assist**, **Smart Email Assist**, and **Deal Agent**
3. Re-review after each Outreach release, since new AI capabilities arrive enabled-by-default in some tenants

**Source:** [Disabling GenAI features](https://support.outreach.io/support/solutions/articles/159000431978-disabling-genai-features)

---

### 3.3 Configure Data Retention and Prospect Data Removal

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.5 |
| NIST 800-53 | SI-12, AU-11 |

#### Description
Set Outreach's retention durations for email, voice recordings, and meeting recordings, and use the documented prospect-data controls so communications data is disposed of on a defined schedule instead of accumulating indefinitely.

#### Rationale
**Why This Matters:**
- Data you no longer hold cannot be stolen — bounded retention directly shrinks what a compromised Outreach tenant can leak
- Email bodies, call recordings, and meeting recordings are among the most sensitive artifacts in a sales platform and are the least likely to be needed years later
- GDPR, CCPA, and similar regimes require a defensible deletion story for prospect personal data, and ad-hoc manual deletion does not produce one
- Automated retention removes reliance on an admin remembering to purge, which is the failure mode that produces decade-old prospect archives

**Attack Prevented:** Excessive data exposure on breach, regulatory non-compliance, indefinite retention of prospect PII, insider access to stale communications

#### Prerequisites
- Outreach admin access

#### ClickOps Implementation

**Step 1: Set Retention Durations**
1. Navigate to: **Administration** → **Data and privacy** → **Data retention**
2. Set custom durations for **email retention**, **voice recording retention**, and **meeting recording retention**
3. Note that deletion is permanent and applies instance-wide — Outreach documents that data is deleted within 24 hours of the duration being met and cannot be recovered ([Data retention at Outreach](https://support.outreach.io/support/solutions/articles/159000425912-data-retention-at-outreach))

**Step 2: Configure Prospect-Data Controls**
1. Review the additional documented privacy surfaces and set each per policy:
   - [Outreach email retention](https://support.outreach.io/support/solutions/articles/159000425723-outreach-email-retention)
   - [Automatic Outreach call recording deletion](https://support.outreach.io/support/solutions/articles/159000425690-automatic-outreach-call-recording-deletion)
   - [How to hide prospect emails in Outreach](https://support.outreach.io/support/solutions/articles/159000426193-how-to-hide-prospect-emails-in-outreach)
   - [Enabling granular opt out in Outreach](https://support.outreach.io/support/solutions/articles/159000425885-enabling-granular-opt-out-in-outreach)
2. Document a repeatable [prospect data removal](https://support.outreach.io/support/solutions/articles/159000425496-how-to-remove-prospect-data-from-outreach) procedure for data-subject deletion requests

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Outreach Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | User profiles | [2.1](#21-configure-user-profiles) |

### NIST 800-53 Rev 5 Mapping

| Control | Outreach Control | Guide Section |
|---------|------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-6 | User profiles | [2.1](#21-configure-user-profiles) |

---

## Appendix A: References

**Official Outreach Documentation:**
- [Outreach Support (Help Center)](https://support.outreach.io/support/solutions)
- [How to turn on/off SSO](https://support.outreach.io/support/solutions/articles/159000425308-how-to-turn-on-off-sso)
- [Advanced settings for identity provider (SSO)](https://support.outreach.io/support/solutions/articles/159000426333-advanced-settings-for-identity-provider-sso-)
- [Outreach SCIM protocol](https://support.outreach.io/support/solutions/articles/159000426344-outreach-scim-protocol)
- [Managing Outreach user session logout timer duration](https://support.outreach.io/support/solutions/articles/159000425314-managing-outreach-user-session-logout-timer-duration)
- [How to add new Outreach users and assign user admin permissions](https://support.outreach.io/support/solutions/articles/159000425461-how-to-add-new-outreach-users-and-assign-user-admin-permissions)
- [Governance profile settings overview](https://support.outreach.io/support/solutions/articles/159000425938-outreach-governance-profile-settings-overview)
- [Disabling GenAI features](https://support.outreach.io/support/solutions/articles/159000431978-disabling-genai-features)
- [Data retention at Outreach](https://support.outreach.io/support/solutions/articles/159000425912-data-retention-at-outreach)
- [How to configure Outreach user email limits and safeguards](https://support.outreach.io/support/solutions/articles/159000426349-how-to-configure-outreach-user-email-limits-and-safeguards)
- [SPF, DKIM, and DMARC overview for Outreach email users](https://support.outreach.io/support/solutions/articles/159000425866-spf-dkim-and-dmarc-overview-for-outreach-email-users)

> **Link note (2026-08-08):** Outreach migrated its help center from Zendesk (`support.outreach.io/hc/en-us/...`) to Freshdesk (`support.outreach.io/support/solutions/...`). Any remaining `/hc/en-us/` URL in third-party material is dead — re-find the article under the new root.

**API Documentation:**
- [Outreach API Reference](https://developers.outreach.io/api/)

**Compliance Frameworks:**
- Outreach publicly claims SOC 2 Type II, ISO 27001, ISO 27701, and ISO 42001 (Responsible AI) certifications. Certification attestations are distributed through Outreach's compliance/support channel rather than a hardening document; request current reports directly and do not treat certification pages as configuration guidance.

**Security Incidents:**
- No major public security incidents identified. Outreach runs a private bug bounty program through Bugcrowd and conducts annual penetration testing.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass: repoint all help-center links to the new Freshdesk root (Zendesk `/hc/en-us/` URLs are dead); correct SSO, user-creation, and admin-permission console paths; soften the undocumented SSO-enforcement claim in 1.1; add 1.3 SCIM provisioning, 1.4 session logout timer, 3.2 GenAI/agentic feature disablement (incl. MCP Server), 3.3 data retention and prospect-data removal; add email safeguards and SPF/DKIM/DMARC to 2.2; remove Trust Center and marketing security pages from Appendix A. Tier 3/4 sources not surveyed this pass. | Claude Code (Opus 5) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO and access controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
