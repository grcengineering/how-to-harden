---
layout: guide
title: "Figma Enterprise Hardening Guide"
vendor: "Figma"
slug: "figma"
tier: "2"
category: "Productivity"
description: "Design platform hardening for Figma Enterprise including SSO, access controls, and governance features"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
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
Deliver member MFA through the identity provider, because Figma does not document an org-wide member 2FA enforcement setting, and license the Governance+ add-on where guest 2FA must also be enforced.

#### Rationale
**Why This Matters:**
- A second authentication factor blocks account takeover even when a password is phished, leaked, or reused
- Figma documents no organization-wide setting that forces two-factor authentication on members — member MFA is inherited from the identity provider, which makes SAML SSO enforcement (1.1) the load-bearing control rather than an optional convenience
- Guests and external collaborators sit outside your IdP entirely, so the Governance+ **Enforced 2FA** capability is the only MFA control that reaches them
- Design files often contain confidential roadmaps and customer-facing assets that attackers monetize or leak

**Attack Prevented:** Credential stuffing, password reuse, phishing, guest account takeover

#### Prerequisites
- Members: SAML SSO configured and enforced (see 1.1), with MFA required by IdP policy
- Guests: Figma Enterprise with the **Governance+** add-on — Figma scopes "Enforced 2FA — requires two-factor authentication for guest access" to Governance+, not to base Organization or Enterprise

#### ClickOps Implementation

**Step 1: Enforce MFA for Members at the IdP**
1. Enforce SAML SSO for members in Figma (1.1, Step 4) so no member authenticates with a local password
2. In your identity provider, require MFA (preferably phishing-resistant) on the Figma application
3. Treat the IdP policy as the system of record — do not expect a member-facing 2FA toggle in the Figma admin console

**Step 2: Enforce 2FA for Guests (Governance+)**
1. Confirm the **Governance+** add-on is active on your Enterprise plan
2. Navigate to: **Admin** → **Settings** → **Login and provisioning**
3. Enable **Enforced 2FA** so guest access requires two-factor authentication
4. Guests who have not enrolled a second factor lose access until they do

#### Validation & Testing
- Attempt a member login with SSO enforced and confirm the IdP challenges for a second factor; there is no Figma-side member 2FA report to rely on
- Invite a test guest and confirm the guest is prompted to enroll a second factor before content loads
- If **Enforced 2FA** is absent from the console, the org does not hold Governance+ — record that as an accepted gap rather than assuming the setting was disabled

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
1. First SSO/SCIM login triggers a verification email
2. Users enter a one-time code from that email to complete first login
3. One-time security measure

> **Unverified detail:** earlier revisions of this guide specified a "6-digit PIN from SendGrid" for first login. That specific code length and mail-delivery vendor were not re-verified against Figma's current documentation in the 2026-08 pass; treat the mechanism (an emailed one-time verification code) as the reliable part and confirm the specifics in your own tenant.

---

### 1.4 Set an Idle Session Timeout

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-11, AC-12 |

#### Description
Shorten Figma's idle session lifetime from its 21-day default so that unattended or stolen sessions expire on a timescale that matches the sensitivity of the design work they can reach.

#### Rationale
**Why This Matters:**
- Figma's default idle session timeout is **21 days**, which means an unlocked laptop, a stolen session cookie, or a shared device retains working access to design files for three weeks without re-authentication
- Shortening the timeout forces re-authentication through the IdP, so revoked accounts and changed conditional-access posture take effect on a bounded schedule instead of waiting for a session to age out
- The setting applies to members only — guests are not covered, which makes guest lifetime (3.2) a separate control rather than a duplicate of this one
- Timeout enforcement spans web, desktop, mobile, and embeds, closing the gap where one long-lived client undoes the policy

**Attack Prevented:** Session hijacking, unattended-session abuse, stolen-cookie replay, delayed effect of deprovisioning

#### Prerequisites
- Figma Enterprise (org admin role required)
- Floors differ by entitlement: base Enterprise allows a minimum of **12 hours**; the **Governance+** add-on ("Extended idle session timeout") lowers the floor to **15 minutes**

#### ClickOps Implementation

**Step 1: Open the Setting**
1. Navigate to: **Admin** → **Settings** → **Login and provisioning**
2. Locate **Session timeout**

**Step 2: Choose a Timeout**
1. On base Enterprise, select a value within the supported range of **12 hours to 14 days** — the default of 21 days is above this range and should be replaced
2. On Enterprise with **Governance+**, the extended control permits values as short as **15 minutes**; pick the shortest interval your designers will tolerate for the teams handling the most sensitive work
3. Save and communicate the change — a sharp reduction re-prompts every member at once

**Step 3: Account for Coverage Gaps**
1. Confirm the policy is understood to apply to **members only**, not guests
2. Verify behavior on desktop and mobile clients as well as the web app and embeds

#### Validation & Testing
- Leave an authenticated session idle past the configured interval and confirm the next action forces re-authentication through the IdP
- Repeat on the desktop app and on an embed, which are the surfaces most likely to be assumed out of scope
- Re-check the setting after any plan or add-on change — losing Governance+ raises the minimum back to 12 hours

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

### 2.3 Configure Network Access Restrictions (NAR)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Use network access restrictions (NAR) to prevent personal Figma accounts from being used on the corporate network, confining design work to the tenancy you govern.

#### Rationale
**Why This Matters:**
- Blocking personal Figma accounts on the corporate network stops employees from moving company designs into accounts you cannot govern or audit
- Personal accounts sit outside SSO, SCIM, activity logging, and DLP, creating an invisible data-exfiltration channel
- Restricting to organization-domain accounts ensures all design work stays within monitored, owned tenancy
- Shadow IT usage of Figma is a common path for intellectual property to leak undetected

**Attack Prevented:** Data exfiltration, shadow IT, unmonitored access, IP leakage

#### Prerequisites
- Figma **Governance+** — Figma lists network access restrictions as a Governance+ capability (Enterprise and Figma for Government), not a base Enterprise feature. Earlier revisions of this guide implied base Enterprise availability; that was incorrect.

#### ClickOps Implementation

**Step 1: Enable Network Access Restrictions**
1. Confirm the **Governance+** add-on is active
2. Navigate to: **Admin** → **Settings** → **Security**
3. Enable network access restrictions for your corporate network

**Step 2: Confirm the Restriction Scope**
1. On the corporate network, users may access only:
   - Accounts associated with the organization's verified domains
   - Guest access to organization content
2. Personal-account sign-in on that network is blocked

#### Validation & Testing
- From inside the corporate network, attempt to sign in with a personal (non-domain) Figma account and confirm the attempt is refused
- Confirm the same account signs in normally off-network — NAR governs the network, not the account, and is therefore a containment control rather than an account ban

---

### 2.4 Restrict Organization Access by IP Allowlist

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17, SC-7 |

#### Description
Restrict access to organization content to a defined set of source IP ranges, so stolen credentials and stolen session material are only usable from network locations you control.

#### Rationale
**Why This Matters:**
- IP allowlisting is a distinct control from network access restrictions (2.3): NAR governs which *accounts* may be used on your network, while an IP allowlist governs which *networks* may reach your organization's content
- An attacker holding valid credentials or a live session from an arbitrary residential or hosting IP is stopped at the network boundary before authentication outcomes matter
- Pairing the two controls closes both directions — personal accounts cannot be used inside, and organization content cannot be reached from outside
- Allowlisting is the practical enforcement point for "corporate device or VPN only" policies that are otherwise unenforceable in a browser-first product

**Attack Prevented:** Credential replay from attacker infrastructure, session hijacking from unmanaged networks, off-network data exfiltration

#### Prerequisites
- Figma **Governance+** add-on
- A stable, enumerated set of egress IP ranges (corporate egress, VPN concentrators, managed cloud workspaces)

#### ClickOps Implementation

**Step 1: Enumerate Allowed Ranges**
1. Collect every egress range users legitimately originate from, including VPN, split-tunnel exceptions, and contractor gateways
2. Confirm each range is static — dynamic ranges cause lockouts

**Step 2: Configure the Allowlist**
1. Navigate to: **Admin** → **Settings** → **Security**
2. Add the approved IP ranges to the organization's allowlist
3. Preserve a break-glass path for admins before enforcing

#### Validation & Testing
- Attempt access from an address outside the allowlist and confirm the request is refused
- Verify a break-glass admin can still recover the org if the allowlist is misconfigured, before you rely on this control
- Re-review the ranges whenever network egress changes; a stale allowlist fails closed and is indistinguishable from an outage to your users

---

### 2.5 Manage AI Settings and Content Training

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3, SC-7 |

#### Description
Review Figma's AI features and the content-training setting at the organization level, and pin both to a deliberate decision rather than the plan default.

#### Rationale
**Why This Matters:**
- **Changed/differing default:** Figma's content training is **on by default on Starter and Professional plans, and off by default on Organization and Enterprise plans** — a team that graduates from Professional into an org, or an unmanaged Professional team running alongside your org, has been contributing content by default
- Design files are pre-release intellectual property; content training and AI feature availability are data-flow decisions, not productivity preferences
- On Starter, enabling AI features is a **one-way door** — once turned on they are permanently enabled, so the decision must be made before the fact, not audited after it
- Enterprise organizations with **Governance+** can additionally constrain where AI processing happens through AI hosting controls (AWS-only routing), which is the control regulated tenants actually need

**Attack Prevented:** Unintended disclosure of pre-release designs through model training, ungoverned data egress to AI processing, irreversible feature exposure on unmanaged plans

#### Prerequisites
- Organization or Enterprise admin for org-level settings
- Figma **Governance+** for AI hosting controls (AWS-only routing)

#### ClickOps Implementation

**Step 1: Set the Org Position on Content Training**
1. Navigate to: **Admin** → **Settings** → **AI**
2. Confirm the content-training setting explicitly rather than trusting the plan default
3. Record the decision — auditors will ask whether it was chosen or inherited

**Step 2: Address Unmanaged Teams**
1. Inventory Starter and Professional teams using corporate domains (see 4.3) — these default to content training **on**
2. Bring them into the organization, where the default inverts, rather than fixing each team individually
3. Treat any Starter team with AI features already enabled as permanent — plan around it instead of expecting a rollback

**Step 3: Constrain AI Hosting (Governance+)**
1. With Governance+, configure AI hosting controls to route AI processing to AWS only
2. Map the resulting data-flow to your existing cloud and residency commitments

#### Validation & Testing
- Confirm the org-level AI settings page reflects your intended state, not the default
- Re-check after any plan change or team migration — the default differs by plan, so the effective state can move without anyone touching the setting
- For Starter teams, verify before enabling anything that you accept the permanence

---

### 2.6 Govern Personal Access Tokens

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 3.3 |
| NIST 800-53 | AC-6, IA-5 |

#### Description
Treat Figma personal access tokens as full-account credentials, hold integrations to one token each, and compensate in policy for the admin controls Figma does not document.

#### Rationale
**Why This Matters:**
- Figma's own documentation warns that personal access tokens "allow third-party programs to access all of your files and data" and that it is **not possible to restrict** that access — a token is therefore equivalent to the user's whole Figma footprint, not a scoped integration credential
- The absence is itself the finding: Figma documents token creation and management only at the **user** level (**Settings** → **Security** → **Personal access tokens**), with no documented administrator capability to enumerate, restrict, or revoke tokens held by members. You cannot centrally clean up after a compromised integration, so prevention and offboarding discipline carry the whole load
- One token per integration is the only way to make revocation meaningful — a shared token cannot be retired without breaking every consumer at once
- A leaked token in a CI log, a script, or a compromised vendor grants file-wide read access with no org-side kill switch

**Attack Prevented:** Token leakage granting full account file access, over-shared integration credentials, undetected third-party data access, orphaned tokens surviving offboarding

#### ClickOps Implementation

**Step 1: Set Token Policy**
1. Require a **separate token per integration**, named for its consumer
2. Prohibit tokens in shared vaults, CI logs, or source control; require secret storage with rotation
3. Because no admin revoke path is documented, make token inventory a user-attested obligation and require it as part of offboarding

**Step 2: Manage Tokens (User-Level)**
1. Each user navigates to: **Settings** → **Security** → **Personal access tokens**
2. Users generate, review, and delete their own tokens there
3. Departing users must revoke their tokens **before** their account is deprovisioned — treat this as a checklist item, not an assumption

**Step 3: Prefer Governed Alternatives**
1. Where an integration supports OAuth or an app-level credential, use it instead of a personal access token so the credential is not bound to an individual's full access
2. Reserve personal access tokens for cases with no alternative, and document each one

#### Validation & Testing
- Sample members and confirm their token list matches the documented integration inventory
- Confirm offboarding runbooks include token revocation performed while the account is still active
- Note this control's residual risk explicitly in your risk register: without a documented admin revoke capability, detection and prevention are the only available layers

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
- Guest access without an expiration date becomes permanent by default — the contractor who needed two weeks of access still holds it two years later, because nothing forces a review

**Attack Prevented:** Data leakage to third parties, guest over-permissioning, unauthorized external access, indefinite standing access by former collaborators

#### Prerequisites
- Base guest permissions are available to Organization and Enterprise
- **Guest expiration** (a default lifetime applied to new guests) requires the **Governance+** add-on

#### ClickOps Implementation

**Step 1: Configure Guest Access**
1. Navigate to: **Admin** → **Settings** → **Guests**
2. Configure guest permissions:
   - Can edit vs. view only
   - Access duration
   - Require 2FA (Governance+, see 1.2)

**Step 2: Set a Default Guest Lifetime (Governance+)**
1. With Governance+, set a **default expiration for new guests** so external access has a built-in end date
2. Choose a lifetime that matches typical engagement length; renewals should be a deliberate act
3. Note that this applies to guests created after the setting is enabled — audit and clear the existing guest backlog separately

**Step 3: Configure External Content**
1. Restrict access to external Figma content
2. Prevent data loss to external organizations
3. Block unauthorized external collaboration

#### Validation & Testing
- Invite a test guest and confirm the expiration date is populated automatically
- Review the current guest roster for accounts predating the setting — those never expire on their own

---

### 3.3 Restrict File Exporting

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3, AC-4 |

#### Description
Turn off file exporting for the organization so that view-only access cannot be converted into a local copy of the design.

#### Rationale
**Why This Matters:**
- Without an export restriction, "view only" is advisory — any viewer can save, copy, or export the file contents and walk away with the asset the sharing control was meant to protect
- The people most likely to hold view-only access are the ones you trust least with a permanent copy: guests, contractors, and cross-team reviewers
- Combined with guest expiration (3.2) and link controls (3.1), the export restriction is what makes time-bounded access actually time-bounded — access that produced a local export never really ends
- Export events are also among the highest-signal entries in the activity log (4.1); restricting exports reduces both the volume and the ambiguity of what remains

**Attack Prevented:** Intellectual-property exfiltration by authorized viewers, view-only bypass through copy and save, retention of design assets past access expiry

#### Prerequisites
- Figma **Governance+** add-on

#### ClickOps Implementation

**Step 1: Enable the Restriction**
1. Confirm the **Governance+** add-on is active
2. Navigate to: **Admin** → **Settings** → **Security**
3. Enable the restriction on file exporting for the organization

**Step 2: Plan for Legitimate Export Needs**
1. Identify workflows that genuinely require export (handoff to print, external agencies, archival) and route them through a documented exception rather than leaving the control off
2. Pair the restriction with export monitoring in the activity log so the remaining exports are reviewable

#### Validation & Testing
- With a view-only account, attempt to export or save a file and confirm the action is unavailable
- Confirm exports by permitted roles still appear in the activity log — the control reduces export volume, it does not replace monitoring

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
- **Activity for a member cannot be reviewed after that member is removed from the organization** — the investigation window closes at offboarding, which is precisely when you most want to look

**Attack Prevented:** Undetected breach, insider data theft, unauthorized exports, audit gaps, loss of evidence at offboarding

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

**Step 3: Export Before Offboarding (Ordering Requirement)**
1. Because a removed member's activity is no longer reviewable in Figma, **export that member's activity before removing them from the organization**
2. Wire the export step into the offboarding runbook ahead of the removal step — after removal, the data is not retrievable through the console
3. Continuous export to a SIEM (Step 2) is the durable fix; the pre-offboarding export is the fallback when continuous export is not yet in place

**Key Events to Monitor:**
- Design exports
- Permission changes
- External sharing
- Admin actions

#### Validation & Testing
- Confirm the offboarding runbook orders log export before account removal, and test the sequence on a departing test account
- Verify SIEM ingestion is current — a broken pipeline is invisible until you need the data

---

### 4.2 Configure Governance+ Features

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Enable the Governance+ add-on and configure the specific capabilities it unlocks: multiple identity providers, enterprise key management, the discovery pipeline, internal policy agreements, and the Developer Logs API.

#### Rationale
**Why This Matters:**
- **Enterprise key management (EKM)** backs Figma content with keys you hold in AWS KMS, so revoking the key revokes access to the data independently of Figma's own access controls — an L3-grade control for regulated tenants
- The **Discovery pipeline** logs text-edit activity, which is the only mechanism that shows what was actually changed inside a file rather than merely who opened it; this is the difference between "a departing designer viewed 40 files" and evidence of what they did there
- **Multiple identity providers** let teams with different risk profiles authenticate against different IdPs, so a stricter policy can be applied to the teams handling the most sensitive designs without imposing it org-wide
- **Internal policies** gate access behind a custom policy agreement, giving you an enforceable acknowledgment step rather than an assumed one
- The **Developer Logs API** turns activity monitoring from a console-review chore into a pipeline, which is what makes continuous SIEM export (4.1) practical at scale

**Attack Prevented:** Insufficient monitoring, unattributable file changes, weak segmentation between sensitive and general teams, key-custody gaps, compliance evidence gaps

> Earlier revisions of this control described "advanced activity logs," "per-team authentication," "advanced reporting," and "compliance dashboards" as the Governance+ feature set. Those descriptions did not match Figma's documented capability list and have been replaced with the capabilities Figma actually names.

#### Prerequisites
- Figma Enterprise with the **Governance+** add-on
- EKM additionally requires an AWS KMS key you control
- Note that several controls elsewhere in this guide also depend on Governance+: enforced 2FA for guests (1.2), extended idle session timeout (1.4), network access restrictions (2.3), IP allowlisting (2.4), AI hosting controls (2.5), guest expiration (3.2), and the file-export restriction (3.3)

#### ClickOps Implementation

**Step 1: Acquire Governance+**
1. Engage Figma to add Governance+ to the Enterprise plan
2. Inventory which of the dependent controls above you intend to enable — the add-on is the gate for most of this guide's L2/L3 surface

**Step 2: Configure Identity and Policy**
1. Configure **multiple identity providers** where teams require distinct authentication policies
2. Configure **internal policies** so users must agree to your custom policy before access is granted

**Step 3: Configure Key Management (L3)**
1. Provision an **AWS KMS** key under your own control
2. Configure **enterprise key management** so Figma content is protected by that key
3. Document and test the revocation path — an EKM key you cannot actually revoke provides assurance you do not have

**Step 4: Configure Logging Depth**
1. Enable the **Discovery pipeline** to capture text-edit activity
2. Wire the **Developer Logs API** into your SIEM so activity export is continuous rather than manual

#### Validation & Testing
- Confirm each dependent control listed under Prerequisites is actually present in the console — their absence indicates the add-on is not active, not that the setting was disabled
- Test EKM revocation in a non-production context and confirm the expected loss of access
- Confirm Discovery pipeline records appear for a test edit, and that the Developer Logs API is returning data on the expected schedule

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

| Feature | Professional | Organization | Enterprise | Enterprise + Governance+ |
|---------|--------------|--------------|------------|--------------------------|
| SAML SSO | ❌ | ✅ | ✅ | ✅ |
| SCIM | ❌ | ❌ | ✅ | ✅ |
| Org-wide member 2FA enforcement | ❌ | ❌ | ❌ | ❌ (not documented — member MFA comes from the IdP) |
| Enforced 2FA for guest access | ❌ | ❌ | ❌ | ✅ |
| Idle session timeout | ❌ | ❌ | ✅ (floor 12 hours) | ✅ (floor 15 minutes) |
| Activity logs | ❌ | Basic | ✅ | ✅ + Discovery pipeline, Developer Logs API |
| Network access restrictions (NAR) | ❌ | ❌ | ❌ | ✅ |
| IP allowlist | ❌ | ❌ | ❌ | ✅ |
| Guest expiration | ❌ | ❌ | ❌ | ✅ |
| Restrict file exporting | ❌ | ❌ | ❌ | ✅ |
| AI hosting controls (AWS-only) | ❌ | ❌ | ❌ | ✅ |
| Multiple IdPs | ❌ | ❌ | ❌ | ✅ |
| Enterprise key management (AWS KMS) | ❌ | ❌ | ❌ | ✅ |
| Internal policies | ❌ | ❌ | ❌ | ✅ |
| Governance+ | ❌ | ❌ | Add-on | — |

**Content training default differs by plan:** on by default on Starter and Professional; off by default on Organization and Enterprise (see 2.5).

---

## Appendix B: References

**Official Figma Documentation:**
- [Help Center](https://help.figma.com/hc/en-us)
- [Guide to SAML SSO](https://help.figma.com/hc/en-us/articles/360040532333-Guide-to-SAML-SSO)
- [Privacy and Security in Organizations](https://help.figma.com/hc/en-us/articles/360040056294-Privacy-and-security-in-organizations)
- [Governance for Figma](https://help.figma.com/hc/en-us/articles/31825370509591-Governance-for-Figma)
- [Set an Idle Session Timeout](https://help.figma.com/hc/en-us/articles/14376092335127-Set-an-idle-session-timeout)
- [Manage AI Settings and Content Training](https://help.figma.com/hc/en-us/articles/17725942479127-Manage-AI-settings-and-content-training-for-your-team-or-organization)
- [Manage Personal Access Tokens](https://help.figma.com/hc/en-us/articles/8085703771159-Manage-personal-access-tokens)
- [View and Export Activity Logs](https://help.figma.com/hc/en-us/articles/360040449533-View-and-export-activity-logs)

**API & Developer Documentation:**
- [REST API Reference](https://developers.figma.com/docs/rest-api/)
- [Figma Developer Platform](https://developers.figma.com/)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO 27001:2022, ISO 27018
- EU Cloud Code of Conduct Level 2 compliant
- Annual CSA Consensus Assessments Initiative Questionnaire (CAIQ) completion
- Annual independent external audits against SOC 2 and ISO 27001

**Security Incidents:**
- No major public security incidents identified affecting the Figma platform.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass against Tier 1 Figma Help Center. **Removed fabricated control 3.3 "Configure Sensitivity Labels"** — no Figma documentation names this feature, the Governance+ capability list omits it, and its prose described an unrelated app-builder product; 3.3 is now "Restrict File Exporting". Corrected 1.2 (Figma documents no org-wide member 2FA enforcement; "Enforced 2FA" is a Governance+ guest-access capability, not base Org/Enterprise) and 2.3 (renamed to Network Access Restrictions (NAR), re-tiered to Governance+). Rewrote 4.2 against Figma's actual Governance+ list (multiple IdPs, EKM via AWS KMS, Discovery pipeline, Internal policies, Developer Logs API) and added the pre-offboarding log-export requirement to 4.1. New controls: 1.4 idle session timeout, 2.4 IP allowlist, 2.5 AI settings and content training (plan-dependent default), 2.6 personal access tokens; guest expiration added to 3.2. Rebuilt the plan matrix around Governance+ entitlement and pruned Trust Center and marketing security pages from References. Annotated 1.3's unverified first-login code detail. Tier 2 (CIS/DISA/CISA) and Tier 3/4 expert sources not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with SSO, access controls, and governance | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
