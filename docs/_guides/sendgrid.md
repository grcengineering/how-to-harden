---
layout: guide
title: "SendGrid Hardening Guide"
vendor: "SendGrid"
slug: "sendgrid"
tier: "2"
category: "Marketing"
description: "Email delivery platform hardening for Twilio SendGrid including API key management, two-factor authentication, and SSO configuration"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Twilio SendGrid is a leading email delivery platform used by **millions of senders** for transactional and marketing email. As a service that handles email communications on behalf of organizations, SendGrid security configurations directly impact email deliverability, sender reputation, and protection against unauthorized access.

### Intended Audience
- Security engineers managing email infrastructure
- IT administrators configuring SendGrid
- DevOps engineers securing email APIs
- GRC professionals assessing communication security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Twilio SendGrid security including two-factor authentication, API key management, SSO configuration, and IP access management.

---

## Table of Contents

1. [Authentication & Access](#1-authentication--access)
2. [API Security](#2-api-security)
3. [Account Security](#3-account-security)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & Access

### 1.1 Enable Two-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Enable and enforce two-factor authentication for all SendGrid users.

#### Rationale
**Why This Matters:**
- SendGrid requires 2FA for all accounts (required since Q4 2020)
- 2FA prevents unauthorized account access
- Protects against credential theft
- API endpoints reject basic auth without 2FA

#### Prerequisites
- Phone number for SMS or Authy app installed

#### ClickOps Implementation

**Step 1: Access 2FA Settings**
1. Navigate to: **Settings** → **Two-Factor Authentication**
2. Review current 2FA status
3. Click **Add Two-Factor Authentication**

**Step 2: Configure Authentication Method**
1. Select authentication method:
   - **Authy App:** Mobile authenticator (recommended)
   - **SMS:** Text messages
2. Enter country code and phone number
3. Verify with code

**Step 3: Backup Codes**
1. Save backup codes securely
2. Store in password vault
3. Use if phone unavailable

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="sendgrid" section="1.1" lang="terraform" %}

---

### 1.2 Configure SAML Single Sign-On

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO for centralized authentication.

#### Prerequisites
- SendGrid Email API Pro, Premier, or Marketing Campaigns Advanced plan
- Account administrator credentials
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Log in as account administrator
2. Navigate to: **Settings** → **SSO Settings**
3. Click **Add SSO Configuration**

**Step 2: Configure SAML Settings**
1. Enter IdP metadata:
   - IdP Entity ID
   - IdP SSO URL
   - X.509 Certificate
2. Download SendGrid SP metadata

**Step 3: Configure Identity Provider**
1. Create SAML application in IdP:
   - Okta
   - Microsoft Entra ID
   - Duo Security
2. Configure attribute mappings
3. Assign users/groups

**Step 4: Test and Enable**
1. Test SSO authentication
2. Verify user login works
3. Enable SSO for teammates

#### Code Implementation

{% include pack-code.html vendor="sendgrid" section="1.2" lang="terraform" %}

---

### 1.3 Configure SSO Teammates

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Manage teammates through SSO for centralized access control.

#### ClickOps Implementation

**Step 1: Add SSO Teammates**
1. Navigate to: **Settings** → **Teammates**
2. Click **Add Teammate**
3. Select **SSO Teammate** type

**Step 2: Configure Teammate Types**
1. **SSO Teammates:** Authenticate via IdP
   - 2FA managed in IdP
   - No SendGrid password
2. **Password Teammates:** Use SendGrid auth
   - Requires SendGrid 2FA
   - Username/password login

**Step 3: Manage Teammate Access**
1. Assign appropriate permissions
2. Review teammate access regularly
3. Remove inactive teammates

#### Code Implementation

{% include pack-code.html vendor="sendgrid" section="1.3" lang="terraform" %}

---

### 1.4 Configure IP Access Management

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Restrict account access to approved IP addresses.

#### ClickOps Implementation

**Step 1: Access IPAM Settings**
1. Navigate to: **Settings** → **IP Access Management**
2. Review current IP allowlist

**Step 2: Configure Allowlist**
1. Add approved IP addresses
2. Add CIDR blocks for ranges
3. Include all necessary locations:
   - Office IPs
   - VPN endpoints
   - CI/CD systems

**Step 3: Enable Enforcement**
1. Enable IP access management
2. Login rejected from non-listed IPs
3. Test from approved location

#### Code Implementation

{% include pack-code.html vendor="sendgrid" section="1.4" lang="terraform" %}

---

## 2. API Security

### 2.1 Use API Keys Instead of Passwords

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Use API keys for all API and SMTP authentication.

#### Rationale
**Why This Matters:**
- API keys are separate from account credentials
- Can be revoked without affecting other integrations
- Support granular permissions
- Required since 2FA mandate

#### ClickOps Implementation

**Step 1: Generate API Key**
1. Navigate to: **Settings** → **API Keys**
2. Click **Create API Key**
3. Name the key descriptively

**Step 2: Configure Permissions**
1. Select permission level:
   - **Full Access:** All permissions (avoid)
   - **Restricted Access:** Specific permissions
   - **Billing Access:** Billing only
2. Grant minimum required permissions:
   - Mail Send
   - Marketing (if needed)
   - Stats (if needed)

**Step 3: Secure the Key**
1. Copy key immediately (shown once)
2. Store in secure vault
3. Never commit to code repositories

#### Code Implementation

{% include pack-code.html vendor="sendgrid" section="2.1" lang="terraform" %}

---

### 2.2 Implement API Key Best Practices

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure API key storage and management.

#### ClickOps Implementation

**Step 1: Secure Key Storage**
1. Store keys in secret manager:
   - AWS Secrets Manager
   - HashiCorp Vault
   - Azure Key Vault
2. Use environment variables
3. Never store in code

**Step 2: Prevent Key Exposure**
1. Add SendGrid to .gitignore patterns
2. Scan repos for exposed keys
3. Set up secret scanning alerts

**Step 3: Rotate Keys Regularly**
1. Establish rotation schedule (90 days)
2. Create new key before deleting old
3. Update all integrations

#### Code Implementation

{% include pack-code.html vendor="sendgrid" section="2.2" lang="terraform" %}

---

### 2.3 Implement Least Privilege API Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Grant minimum necessary API permissions.

#### ClickOps Implementation

**Step 1: Audit Existing Keys**
1. Navigate to: **Settings** → **API Keys**
2. Review all existing keys
3. Identify over-privileged keys

**Step 2: Create Purpose-Specific Keys**
1. Create separate keys for:
   - Transactional email sending
   - Marketing campaigns
   - Statistics retrieval
   - Webhook management
2. Grant only required permissions

**Step 3: Remove Unnecessary Keys**
1. Delete unused keys
2. Replace full access keys with restricted
3. Document key purposes

#### Code Implementation

{% include pack-code.html vendor="sendgrid" section="2.3" lang="terraform" %}

---

### 2.4 Configure API Key Alerts

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | SI-4 |

#### Description
Monitor API key usage for anomalies.

#### ClickOps Implementation

**Step 1: Monitor Usage**
1. Review API statistics regularly
2. Check for unusual patterns
3. Identify unauthorized usage

**Step 2: Configure Alerts**
1. Set up alerts for:
   - Unusual send volumes
   - Failed authentication
   - New API key creation

**Step 3: Respond to Compromised Keys**
1. Delete compromised key immediately
2. Create replacement key
3. Update affected integrations
4. Review audit logs

#### Code Implementation

{% include pack-code.html vendor="sendgrid" section="2.4" lang="terraform" %}

---

## 3. Account Security

### 3.1 Secure Administrator Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Protect administrator account access.

#### ClickOps Implementation

**Step 1: Protect Admin Credentials**
1. Use strong passwords (20+ characters)
2. Store in password vault
3. Enable 2FA (required)

**Step 2: Limit Admin Access**
1. Minimize admin accounts (2-3 for redundancy)
2. Use teammates for regular users
3. Grant minimum necessary permissions

**Step 3: Regular Access Reviews**
1. Review admin access quarterly
2. Remove inactive admins
3. Document access justification

#### Code Implementation

{% include pack-code.html vendor="sendgrid" section="3.1" lang="terraform" %}

---

### 3.2 Configure Teammate Permissions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure granular permissions for teammates.

#### ClickOps Implementation

**Step 1: Review Permission Types**
1. Navigate to: **Settings** → **Teammates**
2. Available permission categories:
   - Admin
   - Marketing
   - Developer
   - Stats
   - Templates

**Step 2: Create Role-Based Access**
1. Define permission sets by role
2. Assign minimum necessary access
3. Document standard configurations

**Step 3: Regular Permission Reviews**
1. Review teammate access monthly
2. Remove unused permissions
3. Update as roles change

#### Code Implementation

{% include pack-code.html vendor="sendgrid" section="3.2" lang="terraform" %}

---

### 3.3 Configure Sender Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.2 |
| NIST 800-53 | SC-8 |

#### Description
Configure domain authentication for email security.

#### ClickOps Implementation

**Step 1: Authenticate Domain**
1. Navigate to: **Settings** → **Sender Authentication**
2. Click **Authenticate Your Domain**
3. Add DNS records:
   - DKIM records
   - SPF records
   - Domain link branding

**Step 2: Verify Authentication**
1. Complete DNS verification
2. Verify records propagated
3. Test email delivery

**Step 3: Enable Link Branding**
1. Configure branded links
2. Improves deliverability
3. Builds sender reputation

#### Code Implementation

{% include pack-code.html vendor="sendgrid" section="3.3" lang="terraform" %}

---

## 4. Monitoring & Compliance

### 4.1 Monitor Email Activity

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Monitor email sending activity and statistics.

#### ClickOps Implementation

**Step 1: Review Activity Feed**
1. Navigate to: **Activity** → **Feed**
2. Review email events:
   - Delivered
   - Opened
   - Clicked
   - Bounced
   - Spam reports

**Step 2: Monitor Statistics**
1. Navigate to: **Stats**
2. Review key metrics:
   - Delivery rate
   - Bounce rate
   - Spam complaint rate
3. Set up alerts for anomalies

**Step 3: Export Reports**
1. Export activity data
2. Integrate with analytics
3. Retain for compliance

#### Code Implementation

{% include pack-code.html vendor="sendgrid" section="4.1" lang="terraform" %}

---

### 4.2 Configure Event Webhooks

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-6 |

#### Description
Configure webhooks for real-time event notification.

#### ClickOps Implementation

**Step 1: Create Webhook**
1. Navigate to: **Settings** → **Mail Settings** → **Event Webhook**
2. Enter webhook URL
3. Select events to track:
   - Processed
   - Dropped
   - Delivered
   - Bounce
   - Open
   - Click
   - Spam report

**Step 2: Secure Webhook**
1. Use HTTPS endpoint
2. Verify webhook signatures
3. Implement authentication

**Step 3: Process Events**
1. Store events for analysis
2. Set up alerting
3. Monitor for anomalies

#### Code Implementation

{% include pack-code.html vendor="sendgrid" section="4.2" lang="terraform" %}

---

### 4.3 Monitor for Compromised Accounts

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Detect and respond to account compromise.

#### ClickOps Implementation

**Step 1: Monitor Indicators**
1. Watch for suspicious activity:
   - Unusual send volumes
   - Spike in bounces
   - Spam complaints
   - Unknown API keys
2. Review activity regularly

**Step 2: Respond to Compromise**
1. Rotate all API keys immediately
2. Change account password
3. Review teammate access
4. Check for unauthorized settings

**Step 3: Implement Prevention**
1. Enable 2FA on all accounts
2. Use IP access management
3. Monitor for exposed credentials

#### Code Implementation

{% include pack-code.html vendor="sendgrid" section="4.3" lang="terraform" %}

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | SendGrid Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | 2FA/SSO | [1.1](#11-enable-two-factor-authentication) |
| CC6.2 | Permissions | [3.2](#32-configure-teammate-permissions) |
| CC6.6 | IP access management | [1.4](#14-configure-ip-access-management) |
| CC6.7 | API key security | [2.1](#21-use-api-keys-instead-of-passwords) |
| CC7.2 | Activity monitoring | [4.1](#41-monitor-email-activity) |

### NIST 800-53 Rev 5 Mapping

| Control | SendGrid Control | Guide Section |
|---------|------------------|---------------|
| IA-2 | SSO | [1.2](#12-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.1](#11-enable-two-factor-authentication) |
| AC-6 | Least privilege | [2.3](#23-implement-least-privilege-api-access) |
| SC-12 | API key management | [2.1](#21-use-api-keys-instead-of-passwords) |
| AU-2 | Activity monitoring | [4.1](#41-monitor-email-activity) |

---

## Appendix A: Plan Compatibility

| Feature | Free | Essentials | Pro | Premier |
|---------|------|------------|-----|---------|
| 2FA | ✅ | ✅ | ✅ | ✅ |
| API Keys | ✅ | ✅ | ✅ | ✅ |
| SSO | ❌ | ❌ | ✅ | ✅ |
| IP Access Management | ❌ | ❌ | ✅ | ✅ |
| Teammates | ❌ | Limited | ✅ | ✅ |

---

## Appendix B: References

**Official Twilio SendGrid Documentation:**
- [SendGrid Documentation](https://www.twilio.com/docs/sendgrid)
- [Two-Factor Authentication](https://sendgrid.com/docs/ui/account-and-settings/two-factor-authentication/)
- [Single Sign-On](https://www.twilio.com/docs/sendgrid/ui/account-and-settings/sso)
- [API Key Management](https://docs.sendgrid.com/for-developers/sending-email/upgrade-your-authentication-method-to-api-keys)
- [Secure Your Account](https://www.twilio.com/docs/sendgrid/concepts/security/secure-account)
- [7 Best Practices to Protect Your SendGrid Account](https://sendgrid.com/en-us/blog/7-best-practices-to-protect-your-twilo-sendgrid-account-and-sending-reputation)

**API & Developer Resources:**
- [SendGrid API Reference](https://www.twilio.com/docs/sendgrid/api-reference)

**Trust & Compliance:**
- [SendGrid Security](https://sendgrid.com/en-us/policies/security)
- [Twilio Trust Center](https://www.twilio.com/en-us/trust-center)
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018, PCI DSS -- via [Twilio Compliance Documents](https://www.twilio.com/en-us/trust-center/compliance-documents)

**Security Incidents:**
- No major public security breaches specific to SendGrid's infrastructure have been identified in recent years. Parent company Twilio experienced a phishing attack in August 2022 that exposed limited customer data. SendGrid accounts are frequently targeted by credential stuffing and account takeover attacks, which is why 2FA has been mandatory since Q4 2020.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with 2FA, API key security, and SSO configuration | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
