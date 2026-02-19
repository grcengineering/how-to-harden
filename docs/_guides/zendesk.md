---
layout: guide
title: "Zendesk Hardening Guide"
vendor: "Zendesk"
slug: "zendesk"
tier: "4"
category: "Productivity"
description: "Support platform security for API tokens, app marketplace, and ticket redaction"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

Zendesk handles customer support data including tickets, chat transcripts, and customer PII. OAuth apps, webhooks, and Zendesk Marketplace integrations extend functionality but increase attack surface. API tokens enable bulk ticket export; compromised integrations access customer communication history.

### Intended Audience
- Security engineers managing support platforms
- Zendesk administrators
- GRC professionals assessing customer data compliance
- Third-party risk managers evaluating support integrations


### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries


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

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

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

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

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

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-6

#### ClickOps Implementation

**Step 1: Enable IP Restrictions**
1. Navigate to: **Admin Center → Account → Security → Advanced**
2. Configure: **IP restrictions**
3. Add allowed IP ranges

---

## 2. API & App Security

### 2.1 Secure API Token Management

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Manage Zendesk API tokens securely.

#### Rationale
**Attack Scenario:** Stolen API token enables bulk ticket export; customer PII and support history exfiltrated for social engineering.

#### ClickOps Implementation

**Step 1: Audit API Tokens**
1. Navigate to: **Admin Center → Apps and integrations → APIs → Zendesk API**
2. Review all active tokens
3. Remove unused tokens

**Step 2: Create Scoped Tokens**
1. Use OAuth apps for granular permissions
2. Set token expiration
3. Document token purposes

---

### 2.2 Marketplace App Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### ClickOps Implementation

**Step 1: Review Installed Apps**
1. Navigate to: **Admin Center → Apps and integrations → Apps → Zendesk Support apps**
2. Review all installed apps
3. Remove unused apps

**Step 2: Configure App Permissions**
1. Review OAuth scopes per app
2. Require admin approval for new apps
3. Audit app access regularly

---

## 3. Data Security

### 3.1 Configure Data Redaction

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

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

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

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

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Admin Center → Account → Audit logs**
2. Review authentication events
3. Monitor configuration changes

#### Detection Focus

{% include pack-code.html vendor="zendesk" section="4.1" %}

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
- [Zendesk Trust Center](https://www.zendesk.com/trust-center/)
- [Zendesk Help Center](https://support.zendesk.com/hc/en-us)
- [Zendesk Suite Actionable Security Guide](https://support.zendesk.com/hc/en-us/articles/5001315170074-Zendesk-Suite-Actionable-Security-Guide)
- [Account Security Best Practices](https://support.zendesk.com/hc/en-us/articles/4408883094554-Best-practices-for-Zendesk-account-security)
- [Managing SSO Configurations](https://support.zendesk.com/hc/en-us/articles/4408882188570-Managing-single-sign-on-SSO-configurations)
- [Managing Security Settings in Admin Center](https://support.zendesk.com/hc/en-us/articles/4408846853274-Managing-security-settings-in-Admin-Center)
- [General Security Best Practices](https://support.zendesk.com/hc/en-us/articles/4408888782618-General-security-best-practices)
- [Zendesk Secure-by-Design Cloud Solution](https://support.zendesk.com/hc/en-us/articles/4408837948698-Zendesk-s-secure-by-design-cloud-solution)

**API Documentation:**
- [Zendesk Developer API Reference](https://developer.zendesk.com/api-reference/)
- [Zendesk SDKs and Integrations](https://developer.zendesk.com/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27018, ISO 27701, ISO 42001 (AI Governance) -- via [Zendesk Trust Center](https://www.zendesk.com/trust-center/)

**Security Incidents:**
- **October 2024 -- Email Spoofing Vulnerability:** A security researcher demonstrated that Zendesk's email handling could be exploited to spoof support emails, enabling access to support tickets and downstream SSO abuse (e.g., Slack via "Login with Apple"). Zendesk initially dismissed the report as ineligible for their bug bounty.
- **Late 2024 / Early 2025 -- Email Bomb Campaign Exploitation:** Attackers leveraged Zendesk's default anonymous ticket submission combined with lax email validation to launch email bomb campaigns against Zendesk instances worldwide.
- **September 2025 -- Discord Zendesk Support Breach:** Threat actors accessed Discord's Zendesk instance for 58 hours via a compromised BPO support agent account, exfiltrating 1.6 TB of support ticket data affecting 5.5 million users. Attributed to compromised outsourced credentials, not a Zendesk platform vulnerability.
- **October 2024 -- Internet Archive Zendesk Breach:** Threat actors used a stolen Zendesk access token to email Internet Archive users from the organization's support address.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Zendesk hardening guide | Claude Code (Opus 4.5) |
