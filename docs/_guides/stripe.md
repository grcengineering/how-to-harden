---
layout: guide
title: "Stripe Hardening Guide"
vendor: "Stripe"
slug: "stripe"
tier: "1"
category: "Productivity"
description: "Payment platform hardening for Stripe including SSO configuration, team permissions, and API key security"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

Stripe is a leading payment processing platform serving **millions of businesses** for online transactions. As a platform handling sensitive payment data, Stripe security configurations directly impact PCI compliance and financial data protection.

### Intended Audience
- Security engineers managing payment platforms
- IT administrators configuring Stripe
- Finance teams managing payment processing
- GRC professionals assessing payment security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Stripe Dashboard security including SSO, team permissions, API key management, and webhook security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [API Security](#3-api-security)
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
Configure SAML SSO for Stripe Dashboard access.

#### Rationale
**Why This Matters:**
- Centralizes Stripe Dashboard authentication in your corporate IdP, applying MFA, conditional access, and device posture checks to every login
- Local email-and-password logins bypass IdP controls and are prime targets for phishing and credential stuffing
- IdP-driven deprovisioning removes Dashboard access the moment an employee leaves, eliminating orphaned accounts with standing access to payment data
- The Dashboard exposes live payment flows, payout settings, customer PII, and API key management — a single compromised login can redirect funds or exfiltrate cardholder data

**Attack Prevented:** Credential theft, phishing, account takeover, orphaned-account access

#### Prerequisites
- Stripe account with SSO support
- Account owner access
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Dashboard** → **Settings** → **Team and security**
2. Find Single Sign-On section

**Step 2: Configure SAML**
1. Enable SAML SSO
2. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
3. Download Stripe metadata for IdP

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Configure admin fallback

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Stripe team members.

#### Rationale
**Why This Matters:**
- Adds a second authentication factor so a stolen or guessed password alone cannot grant Dashboard access
- Brute-force, password-spray, and credential-stuffing attacks that succeed against reused passwords are blocked at the second factor
- Hardware security keys for admins resist phishing and adversary-in-the-middle proxy attacks that defeat SMS or TOTP
- Stripe accounts control real money movement and customer financial data, making single-factor access an unacceptable risk

**Attack Prevented:** Password reuse compromise, credential stuffing, brute force, phishing

#### ClickOps Implementation

**Step 1: Enable 2FA Requirement**
1. Navigate to: **Settings** → **Team and security**
2. Enable **Require two-step authentication**
3. All team members must configure 2FA

**Step 2: Configure Methods**
1. Support authenticator apps
2. Support SMS (backup)
3. Use hardware keys for admins

---

### 1.3 Configure Session Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout settings.

#### Rationale
**Why This Matters:**
- Idle session timeouts limit the window an unattended or hijacked Dashboard session stays usable
- Automatic logout protects against walk-up access on shared, lost, or unlocked devices
- Shorter session lifetimes reduce the value of a stolen session cookie or token to an attacker
- Because the Dashboard can initiate payouts and refunds, a lingering authenticated session is a direct path to financial fraud

**Attack Prevented:** Session hijacking, cookie theft, unattended-workstation abuse

#### ClickOps Implementation

**Step 1: Configure Timeout**
1. Navigate to: **Settings** → **Team and security**
2. Configure session timeout
3. Enable automatic logout

---

## 2. Access Controls

### 2.1 Configure Team Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Stripe roles.

#### Rationale
**Why This Matters:**
- Assigning the minimum necessary role limits what any single account can do if it is compromised
- View-only and analyst roles let staff do their jobs without the ability to move money, change payout settings, or manage keys
- Least-privilege role assignment contains the blast radius of insider mistakes and account takeover
- Over-permissioned accounts hand an attacker who phishes one user full control over payments, refunds, and customer data

**Attack Prevented:** Privilege escalation, insider misuse, lateral movement, blast-radius expansion

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Settings** → **Team**
2. Review available roles:
   - Administrator
   - Developer
   - Analyst
   - Support specialist
   - View only
3. Assign minimum necessary role

**Step 2: Apply Least Privilege**
1. Use View only for read access
2. Limit Administrator access
3. Regular access reviews

---

### 2.2 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### Rationale
**Why This Matters:**
- Administrator accounts can change payout bank details, manage API keys, and add or remove team members — the highest-value targets in the account
- Keeping admins to a small, monitored set reduces the attack surface for account takeover
- Requiring 2FA and monitoring admin activity makes compromise harder and detection faster
- A single compromised admin can silently redirect payouts or grant persistent access, so minimizing their number is critical

**Attack Prevented:** Admin account takeover, payout redirection, unauthorized privilege grants

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review administrator accounts
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit admins to 2-3 users
2. Require 2FA for admins
3. Monitor admin activity

---

## 3. API Security

### 3.1 Configure API Key Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure Stripe API keys.

#### Rationale
**Why This Matters:**
- Secret API keys can charge cards, issue refunds, and read customer data, so a leaked key is equivalent to full programmatic account access
- Restricted keys scoped to minimum permissions limit what a leaked key can do
- Separating test and live keys prevents accidental real-money operations during development
- Regular rotation and prompt revocation shrink the window an exposed key remains useful to an attacker

**Attack Prevented:** API key leakage, unauthorized charges and refunds, data exfiltration

#### ClickOps Implementation

**Step 1: Review API Keys**
1. Navigate to: **Developers** → **API keys**
2. Review all API keys
3. Document key purposes

**Step 2: Apply Best Practices**
1. Use restricted keys with minimum permissions
2. Never expose secret keys
3. Use test keys for development

**Step 3: Key Rotation**
1. Rotate keys regularly
2. Roll keys if compromised
3. Update integrations

---


{% include pack-code.html vendor="stripe" section="3.1" %}

### 3.2 Configure Webhook Security

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-8 |

#### Description
Secure webhook endpoints.

#### Rationale
**Why This Matters:**
- Verifying Stripe's webhook signature ensures events actually originate from Stripe and were not forged by an attacker
- Without signature verification, an attacker can POST fake events to mark orders paid, trigger fulfillment, or corrupt application state
- Storing webhook secrets securely and rejecting unverified events prevents replay and spoofing of payment notifications
- Webhooks often drive critical business logic, so a forged event can translate directly into fraud or free goods

**Attack Prevented:** Webhook spoofing, forged payment events, replay attacks, fulfillment fraud

#### ClickOps Implementation

**Step 1: Configure Webhooks**
1. Navigate to: **Developers** → **Webhooks**
2. Review webhook endpoints
3. Verify endpoint security

**Step 2: Verify Signatures**
1. Always verify webhook signatures
2. Use webhook secrets securely
3. Reject unverified events

---


{% include pack-code.html vendor="stripe" section="3.2" %}

### 3.3 Configure Restricted Keys

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Use restricted API keys for specific functions.

#### Rationale
**Why This Matters:**
- Restricted keys grant only the specific permissions an integration needs, so a compromised key cannot perform unrelated actions
- Per-integration keys isolate failures — revoking one leaked key does not break every other integration
- Scoping keys to read-only or single-resource access limits the damage from a leak in third-party code or logs
- Using one all-powerful secret key everywhere means any single leak exposes the entire account

**Attack Prevented:** Over-privileged key compromise, lateral abuse across integrations, full-account exposure from a single leak

#### ClickOps Implementation

**Step 1: Create Restricted Keys**
1. Navigate to: **Developers** → **API keys**
2. Create restricted key
3. Select minimum permissions

**Step 2: Apply Per-Integration**
1. Use separate keys per integration
2. Document key purposes
3. Audit key usage

---


{% include pack-code.html vendor="stripe" section="3.3" %}

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Stripe Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Team roles | [2.1](#21-configure-team-roles) |
| CC6.7 | API key security | [3.1](#31-configure-api-key-security) |

### PCI DSS v4.0 Mapping

| Requirement | Stripe Control | Guide Section |
|-------------|----------------|---------------|
| 7 | Team roles | [2.1](#21-configure-team-roles) |
| 8 | Authentication | [1.1](#11-configure-saml-single-sign-on) |

---

## Appendix A: References

**Official Stripe Documentation:**
- [Security at Stripe](https://docs.stripe.com/security)
- [Support Center](https://support.stripe.com/)
- [Team Management](https://docs.stripe.com/account/team)
- [API Keys](https://docs.stripe.com/keys)

**API & Developer Tools:**
- [API Reference](https://docs.stripe.com/api)
- [Stripe CLI](https://docs.stripe.com/stripe-cli)
- [Stripe.js & SDKs](https://docs.stripe.com/development)
- [Webhook Security](https://docs.stripe.com/webhooks/signatures)

**Compliance Frameworks:**
- PCI DSS Level 1 (Service Provider -- most stringent level), SOC 1 Type II, SOC 2 Type II, SOC 3 -- via [Security at Stripe](https://docs.stripe.com/security)
- EMVCo Level 1 & 2 (Stripe Terminal), PCI PA-DSS (Terminal)
- [Payments Security and Compliance Guide](https://stripe.com/guides/payments-security-and-compliance)

**Security Incidents:**
- (2024) Evolve Bank & Trust (a Stripe banking partner) was breached by LockBit ransomware. Customer data from Stripe and other fintechs may have been exposed, including names, SSNs, and bank account numbers. This was not a direct Stripe platform breach.
- (2024-2025) Web skimming campaign exploited legacy Stripe API endpoints to validate stolen credit card data across approximately 49 merchant sites. Stripe infrastructure was not compromised.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO and API security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
