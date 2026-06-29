---
layout: guide
title: "Klaviyo Hardening Guide"
vendor: "Klaviyo"
slug: "klaviyo"
tier: "4"
category: "Marketing"
description: "E-commerce marketing security for API keys, profile protection, and export controls"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

Klaviyo is an e-commerce marketing platform managing customer data, email/SMS campaigns, and behavioral analytics. REST API with private/public API keys, webhooks, and e-commerce platform integrations access customer PII and purchase history. Compromised access enables customer database exfiltration or phishing through trusted sender domains.

### Intended Audience
- Security engineers managing marketing platforms
- Klaviyo administrators
- GRC professionals assessing e-commerce marketing compliance
- Third-party risk managers evaluating marketing integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Klaviyo security configurations including authentication, access controls, and integration security.

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
Require SAML single sign-on with multi-factor authentication for all Klaviyo user access, centralizing login through your corporate identity provider.

#### Rationale
**Why This Matters:**
- Centralizes Klaviyo authentication in your corporate IdP so MFA and conditional access apply to every login
- Local password logins bypass IdP controls and are prime targets for credential stuffing and phishing — the same class of vector behind Klaviyo's 2022 support-tool compromise
- SSO with central provisioning lets you deprovision departed staff in one place, eliminating orphaned accounts with standing access to customer data
- Klaviyo accounts hold customer PII, purchase history, and trusted sending domains; a single compromised login can expose the entire subscriber database

**Attack Prevented:** Credential theft, phishing, MFA bypass, account takeover, orphaned-account access

#### ClickOps Implementation

**Step 1: Configure SAML SSO (Enterprise)**
1. Navigate to: **Settings → Security → SSO**
2. Configure SAML IdP
3. Enable SSO enforcement

**Step 2: Enable 2FA**
1. Navigate to: **Settings → Security**
2. Enable: **Require 2FA for all users**
3. Configure backup methods

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Assign each Klaviyo user the least-privileged role required for their job, restricting account settings, campaign creation, and customer data access by function.

#### Rationale
**Why This Matters:**
- Limits the blast radius of a compromised account — an analyst credential cannot export the subscriber list or alter sending domains
- Reserves Owner and Admin rights for the few who genuinely need them, reducing the number of high-value targets an attacker can chase
- Quarterly access reviews catch privilege creep and stale accounts before they become an exploitable attack surface
- View-only and limited support roles keep customer PII away from users who only need campaign metrics

**Attack Prevented:** Privilege escalation, insider misuse, excessive data access, lateral movement after account takeover

#### ClickOps Implementation

**Step 1: Define User Roles**

| Role | Permissions |
|------|-------------|
| Owner | Full access (1 user) |
| Admin | Manage account settings |
| Manager | Create campaigns |
| Analyst | View-only |
| Support | Limited customer access |

**Step 2: Configure Role Permissions**
1. Navigate to: **Settings → Users**
2. Assign appropriate roles
3. Review access quarterly

---

## 2. API Security

### 2.1 Secure API Keys

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Manage Klaviyo API keys securely.

#### Rationale
**Attack Scenario:** Private API key exposure enables full profile database export; customer PII and purchase history exfiltrated for fraud or targeted phishing.

**Why This Matters:**
- Private API keys grant full read/write access to every profile, list, and campaign — they are effectively root credentials for your customer data
- Keys hardcoded in client-side code, mobile apps, or committed to source control are trivially harvested by attackers and bots scanning public repositories
- Rotating keys and scoping them to specific integrations limits how long a leaked key stays useful and which systems it can reach
- Public keys are safe for client-side events, but confusing them with private keys is a common, high-impact misconfiguration

**Attack Prevented:** API key leakage, customer database exfiltration, unauthorized data export, credential harvesting from source control

#### Implementation

**API Key Types:**

| Key Type | Access Level | Exposure Risk |
|----------|--------------|---------------|
| Private API Key | Full read/write | High (never expose) |
| Public API Key | Limited (client events) | Low |

**Step 1: Rotate Private Keys**
1. Navigate to: **Settings → API Keys**
2. Generate new private key
3. Update integrations
4. Revoke old key

**Step 2: API Key Best Practices**
1. Never expose private keys in client code
2. Use environment variables
3. Limit access to production keys
4. Audit key usage

---

### 2.2 Webhook Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-8

#### Description
Secure Klaviyo webhook endpoints with HTTPS, signature validation, and IP allowlisting so only authentic, untampered Klaviyo events are accepted and processed.

#### Rationale
**Why This Matters:**
- Webhooks carry customer event data and trigger downstream automation; an unauthenticated endpoint lets anyone forge events into your systems
- Validating webhook signatures proves each payload genuinely originated from Klaviyo and was not altered in transit
- HTTPS prevents interception or modification of event payloads that may contain customer identifiers
- IP allowlisting narrows the attack surface to Klaviyo's known source ranges, blocking spoofed or replayed requests

**Attack Prevented:** Webhook spoofing, payload tampering, replay attacks, man-in-the-middle interception, forged-event injection

#### Implementation

**Step 1: Secure Webhook Endpoints**
1. Use HTTPS only
2. Validate webhook signatures
3. Implement IP allowlisting

---

## 3. Data Security

### 3.1 Profile Data Protection

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Minimize collected profile data, track consent, and restrict bulk exports so customer PII is limited in scope and tightly controlled both at rest and on export.

#### Rationale
**Why This Matters:**
- Collecting only the profile fields you actually use shrinks the volume of PII exposed if the account is breached
- Consent tracking and suppression-list management keep you compliant with privacy law and prevent messaging people who have opted out
- Restricting and auditing bulk exports stops a single compromised admin from quietly walking off with the entire subscriber database
- Data retention limits ensure stale customer records are purged rather than accumulating as long-term liability

**Attack Prevented:** Mass data exfiltration, unauthorized bulk export, privacy and consent violations, excessive PII retention

#### ClickOps Implementation

**Step 1: Configure Data Handling**
1. Limit profile data collection
2. Configure consent tracking
3. Enable suppression list management

**Step 2: Export Controls**
1. Restrict export permissions
2. Audit bulk exports
3. Configure data retention

---

### 3.2 Email Authentication

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SI-3

#### Description
Configure a dedicated sending domain with DKIM and SPF, then deploy DMARC and move toward an enforcement policy to authenticate all mail sent through Klaviyo.

#### Rationale
**Why This Matters:**
- DKIM and SPF let receiving servers verify that mail claiming to come from your domain was actually authorized, blocking spoofed senders
- DMARC enforcement tells inbox providers to reject or quarantine messages that fail authentication, protecting your customers from impersonation
- A trusted, authenticated sending domain is a high-value phishing target — without DMARC, attackers can spoof it to defraud your subscribers
- Monitoring authentication reports surfaces unauthorized senders abusing your domain before they damage deliverability and reputation

**Attack Prevented:** Email spoofing, domain impersonation, customer phishing, brand abuse, deliverability degradation

#### ClickOps Implementation

**Step 1: Configure Domain Authentication**
1. Navigate to: **Settings → Domains**
2. Configure dedicated sending domain
3. Set up DKIM/SPF records

**Step 2: Enable DMARC**
1. Configure DMARC policy
2. Monitor authentication reports
3. Move toward enforcement

---

## 4. Monitoring & Detection

### 4.1 Activity Monitoring

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Regularly review the Klaviyo activity log to monitor user logins and configuration changes, establishing visibility into account access and administrative actions.

#### Rationale
**Why This Matters:**
- Login and configuration logs are the primary signal for detecting account takeover, anomalous access, or insider misuse
- Reviewing changes to API keys, sending domains, and user roles catches malicious or accidental modifications before they cause harm
- An audit trail is required evidence for incident response, forensics, and compliance frameworks like SOC 2 and ISO 27001
- Without active monitoring, a compromised account — as in Klaviyo's 2022 incident — can exfiltrate data for an extended period undetected

**Attack Prevented:** Undetected account takeover, insider misuse, unauthorized configuration changes, delayed breach detection

#### ClickOps Implementation

**Step 1: Review Account Activity**
1. Navigate to: **Settings → Activity log**
2. Monitor user logins
3. Track configuration changes

#### Detection Focus

---

## Appendix A: Edition Compatibility

| Control | Growth | Enterprise |
|---------|--------|------------|
| SAML SSO | ❌ | ✅ |
| SCIM | ❌ | ✅ |
| Audit Logs | Limited | ✅ |
| Custom Roles | ❌ | ✅ |

---

## Appendix B: References

**Official Klaviyo Documentation:**
- [Klaviyo Trust Center](https://www.klaviyo.com/trust)
- [Klaviyo Help Center](https://help.klaviyo.com/hc/en-us)
- [Account Security Best Practices](https://help.klaviyo.com/hc/en-us/articles/360052448451)
- [Klaviyo Compliance](https://help.klaviyo.com/hc/en-us/sections/14506459013147)

**API & Developer Resources:**
- [Klaviyo Developer Portal](https://developers.klaviyo.com/en)
- [Klaviyo REST API Reference](https://developers.klaviyo.com/en/reference/api-overview)
- [Klaviyo SDKs](https://developers.klaviyo.com/en/docs/sdk-overview)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, PCI DSS -- via [Klaviyo Trust](https://www.klaviyo.com/trust). Reports available upon request through Klaviyo support.

**Security Incidents:**
- **August 2022:** Klaviyo disclosed a phishing attack that compromised an employee's credentials, granting access to internal support tools. Attackers downloaded marketing lists for 38 cryptocurrency-related customer accounts. No passwords, payment data, or credit card numbers were exposed.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Klaviyo hardening guide | Claude Code (Opus 4.5) |
