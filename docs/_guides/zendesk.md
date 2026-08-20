---
layout: guide
title: "Zendesk Hardening Guide"
vendor: "Zendesk"
slug: "zendesk"
tier: "4"
category: "Productivity"
description: "Support platform security for API tokens, app marketplace, and ticket redaction"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

Zendesk handles customer support data including tickets, chat transcripts, and customer PII. OAuth apps, webhooks, and Zendesk Marketplace integrations extend functionality but increase attack surface. API tokens enable bulk ticket export; compromised integrations access customer communication history.

### Intended Audience
- Security engineers managing support platforms
- Zendesk administrators
- GRC professionals assessing customer data compliance
- Third-party risk managers evaluating support integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Zendesk security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API & App Security](#2-api--app-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML single sign-on and two-factor authentication for all Zendesk account access, routing every agent and admin login through your corporate identity provider.

#### Rationale
**Why This Matters:**
- Centralizes Zendesk authentication in your IdP, enforcing MFA, conditional access, and centralized deprovisioning on every login
- Local username and password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- Agent and admin accounts can read every customer ticket, chat transcript, and PII record, so a single compromised login exposes the entire support history
- Requiring SSO plus 2FA closes the gap where a leaked password alone is enough to take over an account

**Attack Prevented:** Credential theft, phishing, password reuse and credential stuffing, MFA bypass

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Admin Center → Account → Security → Single sign-on**
2. Configure SAML settings
3. Enable: **Require SSO**

**Step 2: Enable 2FA**
1. Navigate to: **Admin Center → Account → Security → Two-factor authentication**
2. Enable: **Require two-factor authentication**
3. Configure backup codes

---

### 1.2 Implement Role-Based Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define custom roles and grant each agent the minimum permissions their job requires, restricting full admin access to a small number of users.

#### Rationale
**Why This Matters:**
- Least-privilege roles ensure agents can only perform the ticket actions their job needs, limiting what a compromised account can do
- Light agents and scoped roles keep contractors and read-only staff from modifying or exporting customer data
- Keeping the admin population small reduces the number of accounts that can change security settings, install apps, or bulk-export tickets
- Granular roles create clear accountability and make audit-log review meaningful

**Attack Prevented:** Privilege escalation, insider misuse, lateral movement from a compromised low-privilege account, over-provisioned access

#### ClickOps Implementation

**Step 1: Define Custom Roles**

| Role | Permissions |
|------|-------------|
| Admin | Full access (limited users) |
| Team Lead | Manage team, view reports |
| Agent | Handle tickets only |
| Light Agent | Comment only (no ticket actions) |

**Step 2: Configure Role Permissions**
1. Navigate to: **Admin Center → People → Team → Roles**
2. Create custom roles
3. Assign minimum permissions

---

### 1.3 Configure IP Restrictions

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-6

#### Description
Restrict Zendesk Admin Center and agent access to an allowlist of trusted corporate or VPN IP ranges.

#### Rationale
**Why This Matters:**
- Limiting access to known network ranges blocks login attempts originating from attacker infrastructure and anonymizing proxies
- Even with valid stolen credentials, an attacker outside the allowlisted network cannot reach the instance
- Network-layer restriction adds defense in depth on top of SSO and MFA
- Constraining admin access to corporate egress reduces exposure of high-value configuration and bulk-export functions

**Attack Prevented:** Credential-based remote access, account takeover from untrusted networks, automated credential stuffing

#### ClickOps Implementation

**Step 1: Enable IP Restrictions**
1. Navigate to: **Admin Center → Account → Security → Advanced**
2. Configure: **IP restrictions**
3. Add allowed IP ranges

---

## 2. API & App Security

### 2.1 Migrate API Authentication to OAuth Access Tokens

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Authenticate Zendesk API integrations with OAuth access tokens, and treat existing API tokens as legacy credentials to inventory and migrate off.

> **Deprecated mechanism:** Zendesk's API authentication reference now titles the API token method **"API token (deprecated)"** and instructs developers to migrate to OAuth access tokens ([Security and authentication](https://developer.zendesk.com/api-reference/introduction/security-and-auth/)). A guide that presents API tokens as the primary mechanism is describing a path the vendor is retiring.

#### Rationale
**Attack Scenario:** Stolen API token enables bulk ticket export; customer PII and support history exfiltrated for social engineering.

**Why This Matters:**
- API tokens grant programmatic access that can read and bulk-export every ticket, comment, and customer record without a browser login
- **A Zendesk API token has no expiration and no scope**: it does not expire on its own, and it can act as any user on the account — including administrators. There is no setting that limits either property, so the only controls available are inventory, custody, and deletion
- OAuth access tokens are scoped to the permissions the integration was granted, so a leaked OAuth credential exposes a bounded slice of the account rather than all of it
- Auditing and removing unused tokens eliminates forgotten standing access that attackers actively hunt for — and with non-expiring tokens, deletion is the only expiry that exists

**Attack Prevented:** Token theft, bulk data exfiltration, leaked-credential abuse, impersonation of administrators via a stolen token, orphaned-token access

#### ClickOps Implementation

**Step 1: Register OAuth Clients for Integrations**
1. Navigate to: **Admin Center → Apps and integrations → APIs → OAuth clients**
2. Register an OAuth client per integration and request only the scopes that integration needs
3. Use OAuth access tokens as the credential for all new and migrated integrations

**Step 2: Inventory and Retire API Tokens**
1. Navigate to: **Admin Center → Apps and integrations → APIs → Zendesk API**
2. List every active API token and identify its owning integration and custodian. **Do not look for an expiration setting — none exists.** A token remains valid until it is deleted
3. Delete every token with no identified owner or no current use; an unowned non-expiring token that can impersonate an administrator is standing account-level access
4. For the tokens that remain, record the migration plan to OAuth and re-review on the same cadence as your access reviews

**Step 3: Enforce Transport Security**
1. Ensure all API clients connect using **TLS 1.2 or higher** — Zendesk requires TLS 1.2 as the minimum for API connections
2. Reject or upgrade any integration still negotiating an older protocol version

Source: [Security and authentication](https://developer.zendesk.com/api-reference/introduction/security-and-auth/)

---

### 2.2 Marketplace App Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Review installed Zendesk Marketplace apps and integrations, require admin approval for new installs, and remove apps that are no longer used.

#### Rationale
**Why This Matters:**
- Marketplace apps and integrations request OAuth scopes that can read tickets and customer data, expanding the attack surface beyond Zendesk itself
- A compromised or malicious third-party app inherits its granted permissions and can quietly exfiltrate support data
- Requiring admin approval prevents agents from installing unvetted apps that introduce supply-chain risk
- Regularly auditing and removing unused apps closes standing integration access that is easy to forget
- **Zendesk's Developer Terms prohibit credential sharing**, and require app distributors to authenticate through a **global OAuth client** rather than reusing a credential across customers — so an app or vendor asking your team for an API token, or for the credentials of an admin user, is asking you to violate the platform's own terms and is a supply-chain red flag on its face

**Attack Prevented:** Malicious or over-permissioned third-party apps, supply-chain compromise, OAuth scope abuse, credential sharing with vendors, data exfiltration through integrations

#### ClickOps Implementation

**Step 1: Review Installed Apps**
1. Navigate to: **Admin Center → Apps and integrations → Apps → Zendesk Support apps**
2. Review all installed apps
3. Remove unused apps

**Step 2: Configure App Permissions**
1. Review OAuth scopes per app
2. Require admin approval for new apps
3. Audit app access regularly

**Step 3: Refuse Shared Credentials**
1. Reject any vendor integration that requests an API token or a named user's credentials — distributed apps are required to use a global OAuth client
2. Where a vendor already holds such a credential, rotate it out and move the integration to OAuth ([2.1](#21-migrate-api-authentication-to-oauth-access-tokens))

Source: [Security and authentication](https://developer.zendesk.com/api-reference/introduction/security-and-auth/)

---

## 3. Data Security

### 3.1 Configure Data Redaction

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Enable automatic redaction of sensitive data such as credit card numbers in tickets, and configure deletion, archiving, and GDPR erasure workflows for retained support data.

#### Rationale
**Why This Matters:**
- Tickets and chat transcripts routinely capture payment card numbers, credentials, and PII that should never persist in plaintext
- Automatic redaction removes sensitive values before they accumulate across thousands of tickets and agent views
- Defined deletion and archiving schedules enforce data minimization, shrinking the volume exposed in any breach
- GDPR deletion workflows satisfy data-subject erasure rights and reduce compliance and regulatory risk

**Attack Prevented:** PII and cardholder data exposure, data hoarding, over-retention amplifying breach impact, regulatory non-compliance

#### ClickOps Implementation

**Step 1: Enable Ticket Redaction**
1. Navigate to: **Admin Center → Account → Security → Advanced**
2. Configure: **Redaction**
3. Enable automatic credit card redaction

**Step 2: Configure Deletion Schedules**
1. Set up ticket archiving
2. Configure attachment deletion
3. Enable GDPR deletion workflows

---

### 3.2 Secure Attachments

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Control ticket attachment file types and sizes, enable malware scanning, and require authentication with expiring URLs for attachment access.

#### Rationale
**Why This Matters:**
- Customer-submitted attachments are an untrusted upload channel that can carry malware onto agent workstations
- Malware scanning and file-type restrictions block weaponized attachments before agents open them
- Requiring authentication and expiring links prevents unauthenticated retrieval of attachments containing sensitive customer data
- Secure attachment URLs stop link-sharing and URL guessing from exposing files outside the intended ticket

**Attack Prevented:** Malware delivery, unauthenticated attachment access, data leakage via shared or guessable URLs, attachment enumeration

#### ClickOps Implementation

**Step 1: Configure Attachment Settings**
1. Limit attachment file types
2. Set size limits
3. Enable malware scanning

**Step 2: Access Control**
1. Require authentication for attachments
2. Configure secure attachment URLs
3. Set expiration on attachment links

---

## 4. Monitoring & Detection

### 4.1 Enable Audit Logs

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable and regularly review Zendesk audit logs to track authentication events, configuration changes, and administrative actions — and use the Audit Logs API to pull them into a SIEM rather than reviewing them only in the Admin Center.

#### Rationale
**Why This Matters:**
- Audit logs provide the authoritative record needed to detect account takeover, unauthorized configuration changes, and bulk data access
- Zendesk states audit log records are **saved indefinitely**, so the constraint on investigation is not retention but access — an incident from a year ago is still reconstructable if someone can query the log
- Without an API-based export, review depends on an administrator remembering to open a console page; the Audit Logs API is what turns that into monitoring
- Monitoring authentication and admin events surfaces suspicious behavior such as new API tokens, app installs, or permission changes — the Discord and Internet Archive incidents in Appendix B both began with credential abuse that these events would record

**Attack Prevented:** Undetected account takeover, unauthorized configuration changes, insider data access, delayed breach detection

#### Prerequisites
- **Zendesk Suite Enterprise** (or Enterprise Plus) — the Audit Logs API is Enterprise-only

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Admin Center → Account → Audit logs**
2. Review authentication events
3. Monitor configuration changes

**Step 2: Establish the API Export Path**
1. Authenticate an integration with an OAuth access token ([2.1](#21-migrate-api-authentication-to-oauth-access-tokens))
2. Pull records from `GET /api/v2/audit_logs`, retrieve a single record with `GET /api/v2/audit_logs/{id}`, and request bulk exports with `POST /api/v2/audit_logs/export`
3. Note the export rate limit — **one export request per minute** — and schedule the job accordingly rather than retrying on failure
4. Forward the retrieved records to your SIEM on a fixed cadence

Source: [Audit Logs API](https://developer.zendesk.com/api-reference/ticketing/account-configuration/audit_logs/)

#### Detection Focus

The Audit Logs API supports filtering, and those filters are the query surface a detection is built on:

| Filter | Values / form | Detection use |
|--------|---------------|---------------|
| `action` | `create`, `destroy`, `exported`, `login`, `update` | `exported` is the highest-signal value — it marks bulk data leaving the account; `destroy` marks records being removed |
| `actor_id` | User ID | Scope a detection to a single account during an investigation, or watch service accounts for out-of-pattern activity |
| `created_at` | Timestamp range | Bound queries to the review window; also isolates off-hours administrative activity |
| `ip_address` | Source IP | Surfaces administrative actions from unexpected origins — the earliest visible sign of a compromised session |
| `source_*` | Source type, ID, and label | Identifies which object class was acted on (user, app, setting), separating routine ticket work from configuration change |

**Detections worth building:**
1. **Bulk export** — `action=exported`, alert on any occurrence outside a known scheduled job
2. **Administrative change from a new IP** — `action=update` correlated against the historical `ip_address` set for that `actor_id`
3. **Destructive action** — `action=destroy` on configuration or user objects, alert on any occurrence
4. **Off-hours administration** — `action` in (`create`, `update`, `destroy`) with `created_at` outside business hours for the actor's region
5. **Login anomalies** — `action=login` from an unexpected `ip_address`, especially for accounts holding admin roles or belonging to outsourced support providers

---

## Appendix A: Edition Compatibility

| Control | Team | Growth | Professional | Enterprise |
|---------|------|--------|--------------|------------|
| SAML SSO | ❌ | ❌ | ✅ | ✅ |
| IP Restrictions | ❌ | ❌ | ✅ | ✅ |
| Audit Logs | ❌ | ❌ | ❌ | ✅ |
| Custom Roles | ❌ | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Zendesk Documentation:**
- [Zendesk Help Center](https://support.zendesk.com/hc/en-us)
- [Zendesk Suite Actionable Security Guide](https://support.zendesk.com/hc/en-us/articles/5001315170074-Zendesk-Suite-Actionable-Security-Guide) -- **customer sign-in required as of 2026-08**; automated fetchers receive a sign-in wall
- [Managing SSO Configurations](https://support.zendesk.com/hc/en-us/articles/4408882188570-Managing-single-sign-on-SSO-configurations)
- [Managing Security Settings in Admin Center](https://support.zendesk.com/hc/en-us/articles/4408846853274-Managing-security-settings-in-Admin-Center) -- **customer sign-in required as of 2026-08**; automated fetchers receive a sign-in wall
- [General Security Best Practices](https://support.zendesk.com/hc/en-us/articles/4408888782618-General-security-best-practices)
- [Zendesk Secure-by-Design Cloud Solution](https://support.zendesk.com/hc/en-us/articles/4408837948698-Zendesk-s-secure-by-design-cloud-solution)

**API Documentation:**
- [Zendesk Developer API Reference](https://developer.zendesk.com/api-reference/)
- [Security and authentication](https://developer.zendesk.com/api-reference/introduction/security-and-auth/) -- OAuth vs deprecated API tokens, TLS minimum, Developer Terms on credential sharing
- [Audit Logs API](https://developer.zendesk.com/api-reference/ticketing/account-configuration/audit_logs/) -- filters, export endpoint, retention
- [Zendesk SDKs and Integrations](https://developer.zendesk.com/)

**Compliance Frameworks:**
- Zendesk publicly claims SOC 2 Type II, ISO 27001, ISO 27018, ISO 27701, and ISO 42001 (AI Governance). The Trust Center page that carried those claims is compliance marketing rather than configuration documentation and was removed from this appendix under the repo source standard; the certification set is **unverified in this pass** -- request current attestation documents from Zendesk before citing them in an assessment.

**Security Incidents:**
- **October 2024 -- Email Spoofing Vulnerability:** A security researcher demonstrated that Zendesk's email handling could be exploited to spoof support emails, enabling access to support tickets and downstream SSO abuse (e.g., Slack via "Login with Apple"). Zendesk initially dismissed the report as ineligible for their bug bounty.
- **Late 2024 / Early 2025 -- Email Bomb Campaign Exploitation:** Attackers leveraged Zendesk's default anonymous ticket submission combined with lax email validation to launch email bomb campaigns against Zendesk instances worldwide.
- **September 2025 -- Discord Zendesk Support Breach:** Threat actors accessed Discord's Zendesk instance for 58 hours via a compromised BPO support agent account, exfiltrating 1.6 TB of support ticket data affecting 5.5 million users. Attributed to compromised outsourced credentials, not a Zendesk platform vulnerability.
- **October 2024 -- Internet Archive Zendesk Breach:** Threat actors used a stolen Zendesk access token to email Internet Archive users from the organization's support address.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass: invert 2.1 to OAuth-first and mark API tokens deprecated, non-expiring, and impersonation-capable; add TLS 1.2 minimum and the Developer Terms credential-sharing prohibition to 2.1/2.2; expand 4.1 with the Enterprise-only Audit Logs API (endpoints, filters, export rate limit, indefinite retention) and populate the empty Detection Focus heading; remove the 404 account-security-best-practices link, annotate two sign-in-walled help articles, and re-source the compliance mapping honestly. Tier 3/4 sources not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Zendesk hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
