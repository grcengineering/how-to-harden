---
layout: guide
title: "Mailchimp Hardening Guide"
vendor: "Mailchimp"
slug: "mailchimp"
tier: "4"
category: "Marketing"
description: "Email marketing security for API keys, audience protection, and domain authentication"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

Mailchimp manages email marketing with audience data, campaign history, and customer engagement metrics. API keys, OAuth apps, and integrations access subscriber lists and behavioral data. Compromised access enables mass phishing distribution through trusted sender reputation, or exfiltration of subscriber databases.

### Intended Audience
- Security engineers managing marketing platforms
- Marketing administrators
- GRC professionals assessing email marketing compliance
- Third-party risk managers evaluating marketing integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Mailchimp security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Security](#2-api-security)
3. [Audience Security](#3-audience-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Turn on two-factor authentication as an Owner or Admin, which is the mechanism that forces every other user in the account to enrol, and preserve the backup code offline before you leave the setup screen.

#### Rationale
**Why This Matters:**
- Passwords are routinely phished, reused, and leaked; a second factor blocks login even when the password is known
- Mailchimp's repeated account compromises began with stolen or phished employee credentials — 2FA on every user raises the bar against that exact playbook
- A compromised marketing account can blast phishing from a trusted sender domain and export subscriber data
- Mailchimp documents **no SSO or SAML** for account login, so 2FA is the ceiling of login hardening on this platform — there is no identity provider to inherit conditional access, session policy, or phishing-resistant factors from. Plan detection and access review accordingly rather than waiting for an IdP integration to close the gap

**Attack Prevented:** Credential theft, password reuse, phishing, account takeover

#### ClickOps Implementation

> **Correction — there is no "require 2FA for all users" toggle.** Earlier revisions of this guide instructed administrators to enable an account-wide enforcement setting. Mailchimp has no such setting. Enforcement is **cascading**: when an **Owner or Admin enables two-factor authentication on their own login**, Mailchimp requires every other user in the account to set up two-factor authentication at their next login. The admin's own enrolment *is* the enforcement action. Source: [Set up a two-factor authentication app at login](https://mailchimp.com/help/set-up-a-two-factor-authentication-app-at-login/).

**Step 1: Enable two-factor authentication as an Owner or Admin**
1. Navigate to: click the **profile icon → Account → Settings → Security → 2-factor authentication**
2. Choose **Authenticator app** and click **Enable**
3. Scan the code with your authenticator app and confirm. Mailchimp supports an **authenticator app** or **SMS** — prefer the authenticator app; SMS is subject to SIM-swap and interception
4. Source: [Set account security options](https://mailchimp.com/help/set-account-security-options/)

**Step 2: Save the backup code offline before leaving the screen**
1. Mailchimp issues a **backup code** during setup. Store it offline — in a password manager or a physical safe — not in email, not in the Mailchimp account itself
2. Losing both the authenticator and the backup code means account recovery through Mailchimp support, which is exactly the social-engineering surface that produced Mailchimp's historical breaches

**Step 3: Confirm the cascade actually landed**
1. After enabling, verify with each user that they were prompted to enrol at their next login
2. Because enforcement is a consequence of the admin's own setting rather than a policy you can read back, the only reliable verification is per-user confirmation — treat the user list as the checklist

---

### 1.2 Implement Access Levels

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Assign each Mailchimp user the minimum access level (Owner, Admin, Manager, Author, or Viewer) required for their role and review those assignments regularly.

#### Rationale
**Why This Matters:**
- Least-privilege access limits what a compromised or malicious account can do — a Viewer cannot export audiences or send campaigns
- **Admin carries the same permissions as Owner.** Every Admin you grant is effectively a second account owner, so the Admin count — not the Owner count — is the real measure of how many full-privilege identities an attacker can target
- Separating roles keeps content authors from changing security settings, API keys, or user permissions
- Quarterly review catches privilege creep and orphaned accounts left over from role changes or departures

**Attack Prevented:** Privilege escalation, insider misuse, lateral movement, orphaned-account access

#### ClickOps Implementation

**Step 1: Define User Levels**

| Level | Permissions |
|-------|-------------|
| Owner | Full access, including billing |
| Admin | Same permissions as Owner — treat as a full-privilege identity |
| Manager | Create campaigns and manage audiences; **cannot export audiences** |
| Author | Create content only |
| Viewer | Read-only |

Source: [Manage user levels in your account](https://mailchimp.com/help/manage-user-levels-in-your-account/)

**Step 2: Configure User Access**
1. Navigate to: **Account → Settings → Users**
2. Assign the minimum required level. Because Admin equals Owner, the review question is not "is this person trusted?" but "does this person need billing-and-security-level authority?"
3. Review access quarterly, and immediately on departure or role change

**Step 3: Control the invitation surface**
1. Pending invitations **expire after 7 days** — re-check the pending list rather than assuming an unaccepted invite is harmless indefinitely, and cancel invites that were sent in error
2. Mailchimp caps invitations at **25 per 24 hours**; a burst approaching that cap is worth investigating as possible account abuse
3. Audit pending invitations alongside active users — an accepted invite to an attacker-controlled mailbox is a full user account

---

### 1.3 Enable Account Verification for Unusual Logins

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-2, SI-4

#### Description
Turn on Mailchimp's account verification so an SMS challenge is issued when a login looks unusual, adding a second detection-and-blocking layer on top of two-factor authentication.

#### Rationale
**Why This Matters:**
- Account verification challenges logins Mailchimp assesses as unusual, catching sessions that reach the login page from an unfamiliar context even when the attacker holds valid credentials
- With no SSO available on Mailchimp, there is no identity provider applying conditional access — this is the only login-context signal the platform offers
- The challenge doubles as an alert: an unexpected verification message tells the account holder that someone else has their password, which is the earliest warning available
- Mailchimp's breaches all ended in attacker-operated logins to real accounts, so any control that adds friction to a credential-valid login is aimed at the actual observed attack

**Attack Prevented:** Credential-stuffing logins, account takeover from unfamiliar locations, undetected use of stolen passwords

#### Prerequisites

Two-factor authentication must be enabled first — Mailchimp gates account verification behind 2FA. Complete [1.1](#11-enforce-mfa) before attempting this control; the setting is not available otherwise.

#### ClickOps Implementation

**Step 1: Enable account verification**
1. Complete two-factor authentication setup per [1.1](#11-enforce-mfa)
2. Navigate to: click the **profile icon → Account → Settings → Security**
3. Enable account verification and register the mobile number that will receive the SMS challenge
4. Source: [Set account security options](https://mailchimp.com/help/set-account-security-options/)

**Step 2: Brief users on what a challenge means**
1. Tell users that an unexpected verification SMS means someone is attempting to log in with their password
2. Define the response: do not approve, change the password immediately, and report it — an unapproved challenge is a reportable security event, not a glitch

---

## 2. API Security

### 2.1 Secure API Keys

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Generate each integration's Mailchimp API key from a dedicated, least-privilege Manager user — because a Mailchimp key has no scopes of its own and simply inherits the permissions of whoever created it.

#### Rationale
**Attack Scenario:** Compromised API key exports entire subscriber list; enables mass phishing through trusted sending domain.

**Why This Matters:**
- **Mailchimp API keys carry no scopes.** A key inherits the role of the user who generated it, so a key created by an Owner or Admin is an Owner-or-Admin credential with no login prompt in front of it. The only way to limit a key is to limit the user who minted it
- Only **Manager** and **Admin** users can generate API keys; generating from a purpose-built Manager account is therefore the narrowest available key, and Manager cannot export audiences — which is precisely the action the historical Mailchimp breaches ended in
- API keys grant programmatic access that bypasses the login two-factor prompt, so a leaked key is a standing backdoor
- Deleting unused keys removes credentials no one is monitoring that attackers can quietly abuse

**Attack Prevented:** API key leakage, subscriber data exfiltration, mass phishing via trusted domain, persistent unauthorized access

#### ClickOps Implementation

> **Correction — there are no scoped keys to create.** Earlier revisions of this guide instructed administrators to "create scoped keys per integration." Mailchimp offers no scope selection: the key's authority *is* the creating user's role. Per-integration separation is achieved by creating a separate least-privilege **user** per integration and generating that integration's key from it. Source: [About API keys](https://mailchimp.com/help/about-api-keys/).

**Step 1: Audit existing keys and who owns them**
1. Navigate to: click the **profile icon → Profile → Extras → API keys**
2. For every active key, identify the user who generated it — that user's role is the key's effective permission level
3. Any key generated by an Owner or Admin is a full-privilege credential; plan its replacement

**Step 2: Re-mint keys from dedicated Manager users**
1. Create a dedicated user per integration at the **Manager** level (the lowest level that can generate a key), named for the integration rather than a person
2. Generate that integration's key from that user
3. Never issue an integration a key generated from an Owner or Admin login

**Step 3: Revoke keys you no longer need**
1. On the API keys page, use **Revoke** and confirm by typing `REVOKE`
2. Revocation is the removal path — an unused key left in place is a live credential

**Step 4: Use offboarding as a revocation lever, and know its limit**
1. When a user is removed from the account, Mailchimp removes **any API keys that user generated**. Offboarding is therefore the primary bulk-revocation mechanism
2. **The caveat that breaks production:** if integrations share a key generated by a departing user, removing that user silently kills every one of those integrations. This is the direct argument for one dedicated integration user per key — it makes offboarding safe and revocation surgical
3. Source: [About API keys](https://mailchimp.com/help/about-api-keys/)

---

### 2.2 OAuth App Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Review and prune OAuth-connected apps and integrations so only necessary, trusted third parties retain access to your Mailchimp data.

#### Rationale
**Why This Matters:**
- Every connected app holds a token that can read or modify audience data without a fresh login or MFA prompt
- Abandoned or forgotten integrations become an unmonitored access path if that vendor is later breached
- Excessive integration permissions widen the data exposed if any single third party is compromised
- Documenting and auditing authorizations makes unexpected or rogue connected apps easy to spot and revoke

**Attack Prevented:** Third-party and supply-chain compromise, OAuth token abuse, unauthorized data access, integration scope creep

#### ClickOps Implementation

> **Verify this path before relying on it.** The **Account → Settings → Connected apps** pane described below could not be corroborated against Mailchimp's current help documentation (checked 2026-08); the documentation describes disabling connected applications from the **API keys** page rather than from a separate connected-apps settings pane. Confirm where connected apps are managed in your own account, and treat the API keys page as the more likely location. Source: [About API keys](https://mailchimp.com/help/about-api-keys/).

**Step 1: Review Connected Apps**
1. Navigate to: **Account → Settings → Connected apps** (see the verification note above)
2. Review all OAuth authorizations
3. Revoke unused apps

**Step 2: Integration Audit**
1. Review integration permissions
2. Remove unnecessary access
3. Document all integrations

---

## 3. Audience Security

### 3.1 Protect Subscriber Data

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Restrict and monitor subscriber-list exports and segment access so audience data cannot be quietly bulk-exported.

#### Rationale
**Why This Matters:**
- Subscriber lists are the crown-jewel asset — full of customer PII and the basis of sender reputation
- The most damaging Mailchimp incidents ended in mass export of audience data, so limiting and alerting on exports is the direct countermeasure
- Restricting export rights to a small set of users reduces who can walk away with the entire list
- Segmenting access keeps sensitive audiences out of reach of users who have no need for them

**Attack Prevented:** Bulk subscriber data exfiltration, PII exposure, unauthorized export, insider data theft

#### ClickOps Implementation

**Step 1: Use user level as the export control**
1. Mailchimp's documented export boundary is the user level: **Manager cannot export audiences**, while Owner and Admin can. There is no separate export-permission switch to configure — the role assignment in [1.2](#12-implement-access-levels) *is* the export control
2. Keep day-to-day marketing staff at Manager or below so audience export requires deliberately using an Owner or Admin login
3. Audit the Owner and Admin roster on the understanding that it is exactly the list of people who can walk off with the subscriber database
4. Source: [Manage user levels in your account](https://mailchimp.com/help/manage-user-levels-in-your-account/)

**Step 2: Segment Access**
1. Use audience segments
2. Limit access by user level
3. Protect sensitive segments

---

### 3.2 Email Authentication

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SI-3

#### Description
Authenticate your sending domain in Mailchimp by publishing the two DKIM CNAME records and the DMARC TXT record Mailchimp generates, so receiving mail servers can verify that messages genuinely originate from your domain.

#### Rationale
**Why This Matters:**
- DKIM and DMARC let receiving servers reject mail that spoofs your domain
- Without an enforced DMARC policy, attackers can impersonate your brand to phish your own subscribers
- Domain authentication protects the sender reputation and deliverability that spoofing and abuse would erode
- A monitored DMARC policy surfaces who is sending mail as your domain, exposing abuse early
- Gmail and Yahoo require a DMARC record from senders exceeding **5,000 messages to their users in any 24-hour period** — for most Mailchimp accounts this is not an aspiration but a delivery prerequisite

**Attack Prevented:** Email spoofing, domain impersonation, phishing of subscribers, brand and reputation abuse

#### ClickOps Implementation

> **Correction — Mailchimp does not have you publish SPF.** Earlier revisions of this guide instructed administrators to "set up SPF records" as part of Mailchimp domain authentication. Mailchimp's authentication flow generates **three** records: **two CNAME records for DKIM** and **one TXT record for DMARC**. SPF is not part of the records Mailchimp asks you to publish for this flow. Source: [Set up email domain authentication](https://mailchimp.com/help/set-up-email-domain-authentication/).

**Step 1: Start domain authentication**
1. Navigate to: click the **profile icon → Account & billing → Domains**
2. Find your sending domain and click **Start authentication**
3. Mailchimp generates the records to publish

**Step 2: Publish the records at your DNS provider**
1. Publish the **two CNAME records** — these carry DKIM signing
2. Publish the **one TXT record** — this is your DMARC policy
3. Return to Mailchimp and confirm the domain shows as authenticated; propagation is not instantaneous

**Step 3: Move DMARC toward enforcement and monitor**
1. Start at a monitoring policy, read the aggregate reports, then tighten toward quarantine and reject once legitimate senders are accounted for
2. If you send more than **5,000 messages per 24 hours** to Gmail or Yahoo recipients, a DMARC record is required by those providers — verify yours resolves rather than assuming
3. Source: [About email authentication](https://mailchimp.com/help/about-email-authentication/)

---

## 4. Monitoring & Detection

### 4.1 Account Activity

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Regularly review Mailchimp login history and account activity to detect unauthorized or suspicious access.

#### Rationale
**Why This Matters:**
- Login and activity logs are the primary signal that an account has been taken over
- Reviewing for unfamiliar locations, devices, or times catches intrusions before data is exported
- Mailchimp's breaches involved attacker access to support and admin tools — activity monitoring shortens detection time
- Without routine review, a compromised account can operate undetected for extended periods

**Attack Prevented:** Undetected account takeover, unauthorized access, delayed breach detection

#### ClickOps Implementation

> **Verify this before building a process on it.** The **Account → Settings → Security** login-activity review described below could not be corroborated against Mailchimp's current help documentation (checked 2026-08), and no Mailchimp audit-log article was found at any plan tier. Confirm what login history your own account actually exposes before designing a monitoring cadence around it, and do not assume an audit log exists to fall back on.

**Step 1: Review Login History**
1. Navigate to: **Account → Settings → Security** (see the verification note above)
2. Review login activity
3. Investigate suspicious logins

#### Detection Focus

- **Assume thin native telemetry.** Mailchimp's monitoring surface could not be verified as including an audit log, so build detection around signals you control rather than around a log you may not have
- **Account verification challenges are your highest-value alert.** Per [1.3](#13-enable-account-verification-for-unusual-logins), an unexpected SMS challenge means someone is logging in with a valid password — route those reports somewhere they are actually triaged
- **Watch the API side.** Because keys inherit the creating user's role and carry no scopes ([2.1](#21-secure-api-keys)), unusual volume or timing against the Marketing API is the practical proxy for bulk export. Instrument this at your own integration layer, where you have the logs
- **Treat user and invitation changes as events.** New Admins (equivalent to Owner), newly generated API keys, and pending invitations near the 25-per-24-hour cap are all worth reviewing on a fixed cadence
- **Domain and sending changes.** An attacker who reaches an Admin login can alter sending domains; re-check the authenticated domain list per [3.2](#32-email-authentication) during every review

---

## Appendix A: Edition Compatibility

| Control | Essentials | Standard | Premium |
|---------|------------|----------|---------|
| 2FA | ✅ | ✅ | ✅ |
| Account verification (requires 2FA) | ✅ | ✅ | ✅ |
| User levels | ✅ | ✅ | ✅ |
| API access | ✅ | ✅ | ✅ |
| SSO / SAML | ❌ | ❌ | ❌ |
| Audit logs | ⚠ Unverified | ⚠ Unverified | ⚠ Unverified |

**Notes:** Mailchimp documents no SSO or SAML for account login at any plan tier. The "Audit Logs — Premium only" claim carried by earlier revisions of this guide **could not be verified against current help documentation (checked 2026-08)** — no audit-log article was found for any tier. Confirm availability in your own account rather than assuming it by plan.

---

## Appendix B: References

**Official Mailchimp Documentation:**
- [Set account security options](https://mailchimp.com/help/set-account-security-options/) — 2FA methods and account verification
- [Set up a two-factor authentication app at login](https://mailchimp.com/help/set-up-a-two-factor-authentication-app-at-login/) — the cascading enforcement mechanism
- [About API keys](https://mailchimp.com/help/about-api-keys/) — key permissions, revocation, offboarding behaviour
- [Manage user levels in your account](https://mailchimp.com/help/manage-user-levels-in-your-account/)
- [Set up email domain authentication](https://mailchimp.com/help/set-up-email-domain-authentication/)
- [About email authentication](https://mailchimp.com/help/about-email-authentication/)
- [Mailchimp Help Center](https://mailchimp.com/help/)

**API & Developer Resources:**
- [Mailchimp Developer Portal](https://mailchimp.com/developer/)
- [Mailchimp Marketing API](https://mailchimp.com/developer/marketing/)
- [Mailchimp Transactional API](https://mailchimp.com/developer/transactional/)

**Note on sources:** Mailchimp's "best practices for account security" article is written for end users and is not adequate as a primary hardening reference — the operative details in this guide come from the task-specific help articles listed above. Compliance-marketing and trust pages are deliberately not cited; request attestation reports from Mailchimp directly and assess them yourself.

**Security Incidents:**
- **March 2022:** Social engineering attack compromised employee credentials; 319 accounts were viewed and audience data was exported from 102 accounts, primarily targeting cryptocurrency and finance customers.
- **August 2022:** Employees fell victim to an Okta phishing campaign (0ktapus); 214 Mailchimp accounts were accessed, again focused on cryptocurrency-related customers.
- **January 2023:** Third social engineering breach in under 12 months; unauthorized access to customer support and admin tools via phished employee credentials, affecting 133 customer accounts.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass against mailchimp.com/help. Corrected 1.1: **there is no "require 2FA for all users" toggle** — enforcement is cascading, an Owner or Admin enabling 2FA on their own login forces every other user to enrol at next login; added the authenticator/SMS method list, the exact console path, the backup-code step, and the honest statement that Mailchimp documents no SSO/SAML. Corrected 2.1: Mailchimp API keys have **no scopes** and inherit the creating user's role (Manager or Admin only) — replaced "create scoped keys" with generating each integration's key from a dedicated least-privilege Manager user, and documented offboarding auto-revocation plus the shared-key breakage caveat and the type-REVOKE flow. Corrected 3.2: domain authentication publishes two DKIM CNAMEs and one DMARC TXT — Mailchimp does not have you publish SPF — and added the Gmail/Yahoo 5,000-per-24-hour DMARC threshold. Added 1.3 account verification (gated behind 2FA). Sharpened 1.2 (Admin has the same permissions as Owner; 7-day invite expiry; 25-invite/24h cap) and 3.1 (Manager cannot export audiences — user level *is* the export control). Annotated as unverified: the Premium-only audit-log claim, 4.1's login-activity path, and 2.2's connected-apps pane. Populated 4.1 Detection Focus. Rebuilt Appendix B on task-specific help articles and removed security-marketing, Intuit compliance, and SOC-request links. Tier 2: no CIS Benchmark, DISA STIG, or CISA SCuBA baseline covers Mailchimp. Tier 3/4 not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Mailchimp hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
