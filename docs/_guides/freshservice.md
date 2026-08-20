---
layout: guide
title: "Freshservice Hardening Guide"
vendor: "Freshservice"
slug: "freshservice"
tier: "5"
category: "IT Operations"
description: "ITSM security for API tokens, CMDB access, and change management controls"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

Freshservice is an IT service management (ITSM) platform handling IT tickets, asset management, and change management. REST API, OAuth apps, and Freshworks Marketplace integrations access IT infrastructure data. Compromised access exposes asset inventory, configuration data, and potentially privileged access workflows.

### Intended Audience
- Security engineers managing ITSM platforms
- Freshservice administrators
- GRC professionals assessing IT service security
- Third-party risk managers evaluating ITSM integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Freshservice security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Security](#2-api-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML single sign-on and two-factor authentication for all Freshservice agent and admin logins.

#### Rationale
**Why This Matters:**
- Centralizes Freshservice authentication in your corporate IdP, applying MFA and conditional access to every agent and admin login
- Local password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- Enforcing SSO-only login keeps departed agents from retaining standalone credentials that survive IdP deprovisioning
- Agents can read asset inventory, CMDB records, and change workflows, so a single compromised login exposes broad IT infrastructure detail

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access

#### ClickOps Implementation

> **Console path correction:** Freshservice security settings — including SSO, password policy, session timeout, and IP restriction — live under **Admin → Account Settings → Service Desk Security**. On accounts with multiple workspaces the path is **Admin → Global Settings → Account Settings → Service Desk Security**. ([Freshservice password policy documentation](https://support.freshservice.com/support/solutions/articles/218835-setting-up-a-password-policy-in-freshservice), [multi-portal security settings](https://support.freshservice.com/support/solutions/articles/224085-security-settings-for-multi-portal-set-up))

**Step 1: Configure SAML SSO**
1. Navigate to: **Admin → Account Settings → Service Desk Security** (multi-workspace: **Admin → Global Settings → Account Settings → Service Desk Security**)
2. Configure your SAML IdP under the agent-facing login settings
3. Restrict agent login to SSO so local passwords cannot be used as a bypass

**Step 2: Enable 2FA**
1. From the same **Service Desk Security** page, enable two-factor authentication for agent logins
2. Require it for all agents, and confirm the corresponding policy in your IdP for SSO-authenticated sessions

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define least-privilege agent roles so each agent receives only the service-desk, CMDB, or change-management permissions their job requires.

#### Rationale
**Why This Matters:**
- Least-privilege roles limit how much asset, ticket, and configuration data any single agent or integration can reach
- Broad default permissions let a compromised agent account export the full CMDB or alter change workflows
- Separating service-desk, asset-manager, and change-manager duties enforces separation of duties and contains insider misuse
- Scoped requester roles keep end users from viewing or modifying agent-only data

**Attack Prevented:** Privilege escalation, lateral movement, insider data exfiltration, unauthorized configuration changes

#### ClickOps Implementation

**Step 1: Define Roles**

| Role | Permissions |
|------|-------------|
| Admin | Full access |
| SD Agent | Service desk functions |
| Asset Manager | CMDB access |
| Change Manager | Change management |
| Requester | Submit tickets only |

**Step 2: Configure Agent Roles**
1. Navigate to: **Admin → Agent Roles**
2. Create custom roles
3. Assign minimum permissions

---

### 1.3 Configure Service Desk Security Settings

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-7, AC-11, AC-17, IA-5, SC-8

#### Description
Set the account-wide security controls on the Service Desk Security page — password policy, session timeout, IP restriction, and secure connection over SSL — so agent and requester access is governed centrally rather than left at defaults.

#### Rationale
**Why This Matters:**
- Session timeout bounds how long an unattended or hijacked browser session stays usable, limiting the value of a stolen session cookie on a shared or lost device
- A configured password policy (length, complexity, expiry, reuse) raises the cost of credential guessing for any account that still authenticates locally
- IP restriction confines console access to trusted corporate ranges, so stolen credentials alone are not enough from an arbitrary network
- Requiring a secure connection over SSL keeps portal and console traffic — including credentials and ticket contents — from traversing the network in the clear
- These settings apply account-wide, so leaving them unset silently weakens every other identity control in this section

**Attack Prevented:** Session hijacking, credential guessing and brute force, access from untrusted networks, credential interception in transit

#### Prerequisites
- Administrator access to Account Settings
- On multi-workspace accounts, these are Global settings and are configured once for the account

#### ClickOps Implementation

**Step 1: Open Service Desk Security**
1. Navigate to: **Admin → Account Settings → Service Desk Security**
2. On accounts with multiple workspaces, navigate to: **Admin → Global Settings → Account Settings → Service Desk Security**

**Step 2: Set the Global Security Controls**
1. **Session Timeout (Global):** set the shortest interval your agents can tolerate operationally
2. **IP Restriction (Global):** restrict agent and admin access to your corporate egress ranges; validate VPN and remote-worker ranges before enforcing
3. **Password Policy (Global):** configure length, complexity, expiry, and reuse restrictions for any account that can still authenticate locally
4. **Secure Connection using SSL:** enable so portal and console traffic is served over HTTPS

**Step 3: Verify Scope**
1. Confirm each setting applied to every workspace and portal in the account
2. Re-check after adding a new workspace — a new portal should not silently inherit weaker settings

#### Validation & Testing
- Leave an agent session idle past the configured timeout and confirm re-authentication is required
- Attempt a console login from an out-of-range IP and confirm it is refused
- Attempt to set a password that violates the policy and confirm rejection
- Load the portal over `http://` and confirm the request is served over HTTPS

**Sources:** [Setting up a password policy in Freshservice](https://support.freshservice.com/support/solutions/articles/218835-setting-up-a-password-policy-in-freshservice) · [Security settings for multi-portal set up](https://support.freshservice.com/support/solutions/articles/224085-security-settings-for-multi-portal-set-up)

---

## 2. API Security

### 2.1 Secure API Keys

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Manage Freshservice API keys securely.

#### Rationale
**Attack Scenario:** Compromised API key exports CMDB; asset inventory and configuration data enable targeted attacks on infrastructure.

**Why This Matters:**
- Freshservice API keys grant programmatic access to tickets, the CMDB, and asset data without an interactive login or MFA prompt
- A leaked per-agent key inherits that agent's full permissions and can be abused silently until it is rotated
- Dedicated integration accounts with scoped roles limit blast radius and keep API activity attributable
- Regenerating keys when agents leave prevents orphaned credentials from retaining standing access

**Attack Prevented:** API key theft, CMDB exfiltration, orphaned-credential abuse, untraceable automated access

#### ClickOps Implementation

**Step 1: Audit API Keys**
1. Navigate to: **Profile → API Key**
2. Each agent has unique key
3. Limit who needs API access

**Step 2: Key Management**
1. Regenerate keys when agents leave
2. Use dedicated integration accounts
3. Monitor API usage

**Step 3: Prefer Scoped OAuth 2.0 Over Personal API Keys**
1. A personal API key carries the full permission set of the agent it belongs to — there is no way to narrow it
2. The Freshservice API supports OAuth 2.0 with per-endpoint scopes (for example `freshservice.tickets.create`), so an integration can be granted only the operations it actually performs
3. Register integrations to use scoped OAuth 2.0 where the integration supports it, and reserve personal API keys for cases where no OAuth path exists
4. Note that legacy basic authentication against the API was deprecated in May 2023 — integrations still using it should be migrated
5. Source: [Freshservice API reference](https://api.freshservice.com/)

---

### 2.2 OAuth App Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Review the connected OAuth apps and Freshworks Marketplace integrations and remove any that are unused or unnecessary.

#### Rationale
**Why This Matters:**
- Connected OAuth apps and marketplace integrations hold delegated access to Freshservice and can read tickets, assets, and configuration data
- Abandoned or over-permissioned integrations expand the attack surface and are a common supply-chain entry point
- A compromised third-party app becomes a backdoor that bypasses agent authentication and MFA entirely
- Regularly removing unused apps enforces least functionality and reduces standing third-party access

**Attack Prevented:** Supply-chain compromise, OAuth token abuse, data exfiltration via third-party apps, excessive delegated access

#### ClickOps Implementation

**Step 1: Review Connected Apps**
1. Navigate to: **Admin → Apps → Installed Apps**
2. Review all apps
3. Remove unused integrations

---

## 3. Data Security

### 3.1 Protect Asset Data

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Restrict CMDB visibility and ticket access so agents only see the asset records and tickets relevant to their group and role.

#### Rationale
**Why This Matters:**
- The CMDB is a detailed map of IT infrastructure that attackers can use to plan targeted attacks
- Limiting CMDB visibility and restricting sensitive asset types contains exposure if an agent account is compromised
- Ticket-level and agent-group restrictions keep sensitive incident data away from agents who don't need it
- Protecting asset and ticket data supports data-at-rest confidentiality and need-to-know access

**Attack Prevented:** Reconnaissance, sensitive-data disclosure, infrastructure mapping, unauthorized ticket access

#### ClickOps Implementation

**Step 1: Configure CMDB Access**
1. Navigate to: **Admin → Asset Management**
2. Limit CMDB visibility
3. Restrict sensitive asset types

**Step 2: Ticket Security**
1. Configure ticket visibility
2. Limit agent group access
3. Protect sensitive tickets

---

### 3.2 Change Management Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-3

#### Description
Require CAB approval workflows for changes and define a controlled emergency-change process in the Workflow Automator.

#### Rationale
**Why This Matters:**
- Mandatory CAB approval ensures changes are reviewed before they reach production IT systems
- Unapproved or self-approved changes can introduce misconfigurations, outages, or deliberately malicious modifications
- A defined emergency-change path prevents approval controls from being bypassed under time pressure
- Documented approval workflows create an auditable record of who authorized each change

**Attack Prevented:** Unauthorized changes, malicious configuration tampering, change-control bypass, unaudited production modifications

#### ClickOps Implementation

**Step 1: Approval Workflows**
1. Navigate to: **Admin → Workflow Automator**
2. Require CAB approval
3. Configure emergency change process

---

## 4. Monitoring & Detection

### 4.1 Audit Logs

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable and regularly review Freshservice audit logs to track agent activity and configuration changes.

#### Rationale
**Why This Matters:**
- Audit logs provide the forensic record needed to detect and investigate account compromise or insider misuse
- Reviewing configuration changes surfaces unauthorized modifications to roles, workflows, or security settings
- Monitoring agent activity helps catch anomalous access patterns such as bulk CMDB exports
- Without comprehensive logging, breaches go undetected and incident response and compliance evidence are impossible

**Attack Prevented:** Undetected breaches, insider abuse, configuration tampering, repudiation of malicious actions

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Admin → Audit Logs**
2. Review agent activities
3. Monitor configuration changes

#### Detection Focus

---

## Appendix A: Edition Compatibility

| Control | Starter | Growth | Pro | Enterprise |
|---------|---------|--------|-----|------------|
| SAML SSO | ✅ | ✅ | ✅ | ✅ |
| Custom Agent Roles | ✅ | ✅ | ✅ | ✅ |
| Audit Logs | ❌ | ❌ | ❌ | ✅ |
| IP Range Restrictions | ❌ | ❌ | ✅ | ✅ |

Availability per the [Freshservice pricing page](https://www.freshworks.com/freshservice/pricing/). SAML SSO and custom agent roles are available on every plan including Starter; audit logs are Enterprise-only; IP range restrictions start at Pro.

---

## Appendix B: References

**Official Freshservice Hardening Documentation:**
- [Setting up a password policy in Freshservice](https://support.freshservice.com/support/solutions/articles/218835-setting-up-a-password-policy-in-freshservice)
- [Security settings for multi-portal set up](https://support.freshservice.com/support/solutions/articles/224085-security-settings-for-multi-portal-set-up)
- [Freshservice Support Solutions](https://support.freshservice.com/support/solutions)

**API & Developer Documentation:**
- [Freshservice API Reference](https://api.freshservice.com/) — OAuth 2.0 scopes and authentication
- [Freshworks Developer Portal](https://developers.freshworks.com/)

**Plan Availability:**
- [Freshservice pricing and plan feature matrix](https://www.freshworks.com/freshservice/pricing/)

**Third-Party Baselines:**
- No CIS Benchmark, DISA STIG, or CISA SCuBA baseline for Freshservice was established in this pass — the Tier 2 indexes were not surveyed, so absence is not confirmed.

**Security Incidents:**
- No major public security incidents affecting the Freshservice platform directly were surfaced in this pass. Tier 3/4 research sources were not surveyed, so this is not a confirmed negative.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | ai-drafted | Correct security-settings console path to Admin → Account Settings → Service Desk Security; add control 1.3 (session timeout, IP restriction, password policy, SSL); add scoped OAuth 2.0 guidance to 2.1; correct Appendix A plan availability against the pricing page; replace Trust Center references with verified support and API docs | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | ai-drafted | Initial Freshservice hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
