---
layout: guide
title: "SendGrid Hardening Guide"
vendor: "SendGrid"
slug: "sendgrid"
tier: "2"
category: "Marketing"
description: "Email delivery platform hardening for Twilio SendGrid including API key management, two-factor authentication, and SSO configuration"
version: "0.2.1"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

Twilio SendGrid is a leading email delivery platform used by **millions of senders** for transactional and marketing email. As a service that handles email communications on behalf of organizations, SendGrid security configurations directly impact email deliverability, sender reputation, and protection against unauthorized access.

### Intended Audience
- Security engineers managing email infrastructure
- IT administrators configuring SendGrid
- DevOps engineers securing email APIs
- GRC professionals assessing communication security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Enable and enforce two-factor authentication for every SendGrid user, including each teammate who logs in with a SendGrid password rather than through your IdP.

#### Rationale
**Why This Matters:**
- Twilio SendGrid requires two-factor authentication on all accounts — it is not an optional hardening step, and an account without it cannot authenticate normally
- Because 2FA is mandatory, the platform also rejects basic authentication (username and password) on the API and SMTP relay, which is what forces every integration onto revocable API keys instead of shared account credentials
- A second factor blocks the credential-stuffing and phishing attacks that routinely target email-sending platforms, where a single working login can send mail as your brand
- A time-based one-time password app resists SIM-swap and SMS-interception attacks that defeat text-message codes, so prefer an authentication app over SMS wherever the user has the choice

**Attack Prevented:** Credential stuffing, phishing, account takeover, password reuse, basic-auth credential abuse

#### Prerequisites
- An authentication app (recommended) or a phone number able to receive SMS

#### ClickOps Implementation

**Step 1: Access 2FA Settings**
1. Navigate to: **Settings** → **Two-Factor Authentication**
2. Review current 2FA status
3. Click **Add Two-Factor Authentication**

**Step 2: Configure Authentication Method**
1. Select an authentication method — SendGrid supports two:
   - **Authentication app:** a TOTP app on a mobile device (recommended)
   - **SMS:** codes sent as text messages (use only where an app is not possible)
2. Enter the country code and phone number
3. Verify with the code SendGrid sends or the app generates

**Step 3: Plan for Lost-Device Recovery**
1. Do not assume self-service recovery codes exist — SendGrid documents no downloadable backup-code set for 2FA
2. Record more than one enrolled method or device per account where the user has a second phone available
3. Document that recovery from a lost or unavailable second factor runs through Twilio SendGrid Support, and make sure at least one other administrator can act while that request is open

**Time to Complete:** ~15 minutes

---

### 1.2 Configure SAML Single Sign-On

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO for centralized authentication.

#### Rationale
**Why This Matters:**
- Centralizes SendGrid authentication in your corporate IdP, applying MFA, conditional access, and session policies to every login
- Local SendGrid passwords bypass IdP controls and linger after an employee departs, leaving standing access to email-sending infrastructure
- SSO lets you deprovision a departed user's access instantly by disabling a single IdP account
- API keys created in SendGrid can send mail as your domain, so tightening who can ever reach those controls protects sender reputation

**Attack Prevented:** Credential theft, phishing, orphaned-account access, password reuse

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

---

### 1.3 Configure SSO Teammates

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Manage teammates through SSO for centralized access control.

#### Rationale
**Why This Matters:**
- Provisioning teammates through SSO ties access to IdP group membership rather than ad-hoc SendGrid invitations
- SSO teammates have no separate SendGrid password to phish, and their MFA is enforced centrally by the IdP
- Access is revoked the moment an IdP account is disabled, eliminating lingering email-platform accounts after offboarding
- Fewer independent credentials can send mail as your brand, shrinking the takeover surface

**Attack Prevented:** Orphaned-account access, credential theft, unauthorized access, privilege creep

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

---

### 1.4 Configure IP Access Management

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Restrict account access to approved IP addresses.

#### Rationale
**Why This Matters:**
- Limits SendGrid console and API access to known networks such as offices, VPNs, and CI/CD, so stolen credentials are useless from an attacker's location
- Adds a network-layer control that blocks logins even when a password and 2FA token are compromised
- Shrinks the attack surface for credential stuffing and account takeover against an internet-exposed account
- Protects high-value email-sending controls that can damage sender reputation if abused

**Attack Prevented:** Credential stuffing, account takeover, unauthorized remote access, stolen-credential reuse

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
2. Understand the full blast radius before you save: the allowlist governs **all three** access paths — the SendGrid web interface, the API, and the SMTP relay. It is not a console-only control
3. **Warning:** any integration whose egress addresses are not on the list stops working the moment enforcement is on — application servers, serverless functions with rotating egress, marketing tools, and CI/CD jobs all send from their own IPs, not yours. Inventory and add every sending system's egress range before enabling
4. Test from an approved location, and confirm a known integration still sends successfully

#### Code Implementation

{% include pack-code.html vendor="sendgrid" section="1.4" %}

---

## 2. API Security

### 2.1 Use API Keys Instead of Passwords

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Authenticate every API and SMTP relay integration with a SendGrid API key rather than the account username and password.

#### Rationale
**Why This Matters:**
- API keys are credentials distinct from the account login, so an integration never needs to hold the password that also controls security settings, teammates, and billing
- Any single key can be deleted the moment it leaks without disturbing every other integration, which is impossible when systems share one account password
- Keys carry per-scope permissions, so a key that only needs to send mail can be issued with exactly that and nothing else
- Because two-factor authentication is mandatory on SendGrid accounts, the API and SMTP relay reject basic authentication outright — an API key is the only supported way for an integration to authenticate

**Attack Prevented:** Shared-credential abuse, account-wide compromise from one leaked secret, unrevocable credential sprawl, basic-auth credential harvesting

#### ClickOps Implementation

**Step 1: Generate API Key**
1. Navigate to: **Settings** → **API Keys**
2. Click **Create API Key**
3. Name the key descriptively

**Step 2: Configure Permissions**
1. Select the key type — SendGrid offers three:
   - **Full Access:** every endpoint except billing (avoid for integrations)
   - **Custom Access:** you set each permission scope individually (use this)
   - **Billing Access:** billing endpoints only
2. For a Custom Access key, set each scope to the least level the integration needs. Every scope offers three settings:
   - **No Access:** the default — leave scopes here unless the integration needs them
   - **Read Access:** retrieve only
   - **Full Access:** read and write
3. Typical least-privilege picks:
   - Mail Send — Full Access, for a transactional sender
   - Marketing — only when the integration manages campaigns
   - Stats — Read Access, for a reporting job

**Step 3: Secure the Key**
1. Copy key immediately (shown once)
2. Store in secure vault
3. Never commit to code repositories

---

### 2.2 Implement API Key Best Practices

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure API key storage and management.

#### Rationale
**Why This Matters:**
- API keys that send mail as your domain are high-value secrets, so storing them in a secret manager keeps them out of source code and config files
- Keeping keys out of repositories closes the most common leak path, where committed secrets are harvested by automated scanners within minutes
- Scheduled rotation limits how long a leaked or stolen key remains usable
- Secret-scanning alerts catch accidental exposure before an attacker can abuse a key to send phishing or spam from your sending reputation

**Attack Prevented:** Secret leakage, credential harvesting from repos, long-lived key abuse, phishing and spam via stolen keys

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

---

### 2.3 Implement Least Privilege API Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Grant minimum necessary API permissions.

#### Rationale
**Why This Matters:**
- Restricted, purpose-scoped keys ensure a leaked transactional-send key cannot also manage teammates, billing, or marketing data
- Scoping permissions limits the blast radius of any single compromised key to the narrow function it was issued for
- Separate keys per integration let you revoke one without disrupting every other service
- Full-access keys hand attackers control over the entire account if exposed

**Attack Prevented:** Privilege escalation, lateral movement, excessive blast radius from key compromise

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

{% include pack-code.html vendor="sendgrid" section="2.3" %}

---

### 2.4 Configure API Key Alerts

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | SI-4 |

#### Description
Monitor API key usage for anomalies.

#### Rationale
**Why This Matters:**
- Monitoring send volumes and authentication patterns surfaces a compromised key before it burns your sender reputation
- Alerting on new API key creation catches attackers who establish persistence by minting their own keys
- Early detection shortens the window in which a stolen key can send phishing or spam as your domain
- Continuous visibility is the difference between catching abuse in minutes versus discovering it from blocklist complaints

**Attack Prevented:** Undetected key compromise, takeover persistence, phishing and spam abuse, sender-reputation damage

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

---

## 3. Account Security

### 3.1 Secure Administrator Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Protect administrator account access.

#### Rationale
**Why This Matters:**
- Admin accounts can change every security setting, mint API keys, and manage all teammates, so compromise of one is full account takeover
- Strong passwords plus enforced 2FA make admin credentials resistant to phishing and credential stuffing
- Minimizing the number of admins reduces the count of high-value targets an attacker can pursue
- Quarterly access reviews remove standing admin rights that are no longer justified

**Attack Prevented:** Account takeover, privilege abuse, credential theft, orphaned-admin access

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

---

### 3.2 Configure Teammate Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure granular permissions for teammates.

#### Rationale
**Why This Matters:**
- Role-scoped permissions ensure each teammate can only touch the functions their job requires
- A compromised low-privilege teammate account cannot reach billing, security settings, or full mail-send controls
- Least-privilege assignment limits the damage of both insider misuse and external takeover of any single account
- Regular permission reviews prevent privilege creep as roles change over time

**Attack Prevented:** Privilege escalation, insider misuse, excessive blast radius, privilege creep

#### ClickOps Implementation

**Step 1: Review Permission Types**
1. Navigate to: **Settings** → **Teammates**
2. Understand the two ways a teammate can be scoped:
   - **Administrator:** holds ALL scopes. This is the maximum grant, not a job title — treat every administrator as a full-account credential
   - **Individual permissions:** each scope granted one at a time for a non-administrator teammate
3. For SSO teammates, SendGrid additionally offers four preset personas, each a fixed bundle of permissions:
   - **Accountant**
   - **Developer**
   - **Marketer**
   - **Observer**
4. Note the hard boundary in the model: **billing permissions are mutually exclusive from all other permissions.** A teammate with billing access can hold no other scope, and a teammate with any other scope cannot also be given billing. Plan for a dedicated billing teammate rather than trying to bolt billing onto an existing role

**Step 2: Create Role-Based Access**
1. Define permission sets by role
2. Assign minimum necessary access
3. Document standard configurations

**Step 3: Regular Permission Reviews**
1. Review teammate access monthly
2. Remove unused permissions
3. Update as roles change

#### Code Implementation

{% include pack-code.html vendor="sendgrid" section="3.2" %}

---

### 3.3 Configure Sender Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.2 |
| NIST 800-53 | SC-8 |

#### Description
Configure domain authentication for email security.

#### Rationale
**Why This Matters:**
- SPF, DKIM, and DMARC cryptographically tie your outbound mail to your domain so receivers can detect and reject forgeries
- Domain authentication stops attackers from spoofing your brand in phishing campaigns sent to your customers
- Authenticated, branded sending improves deliverability and protects long-term sender reputation
- Without these records, anyone can impersonate your domain and recipients have no way to tell legitimate mail from fraud

**Attack Prevented:** Email spoofing, domain impersonation, phishing, business email compromise

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

---

### 3.4 Publish and Enforce a DMARC Policy

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.2 |
| NIST 800-53 | SC-8, SI-8 |

#### Description
Publish a DMARC record for every domain you send from, begin in monitoring mode to collect aggregate reports, then move the policy to quarantine and finally to reject once legitimate mail is passing.

#### Rationale
**Why This Matters:**
- DMARC is what turns SPF and DKIM from advisory signals into an enforced decision: it tells receiving mail servers what to do with mail that fails authentication for your domain, and the major mailbox providers act on that instruction
- Without a DMARC policy, an attacker can send mail claiming to be your domain and receivers have no published instruction to reject it, which is the mechanic behind brand-impersonation phishing and business email compromise
- Aggregate reports sent to the address in the record reveal every system sending as your domain, including shadow senders and forwarders you did not know about — this is why you start at monitoring rather than enforcement
- DMARC only protects domains you actually control, so it must be paired with SendGrid domain authentication on a domain you own rather than a shared or borrowed sending domain

**Attack Prevented:** Domain spoofing, brand impersonation, phishing, business email compromise

#### Prerequisites
- A domain you control, already authenticated in SendGrid (see [3.3](#33-configure-sender-authentication))
- Access to the domain's DNS to publish TXT records
- A mailbox or reporting service able to receive DMARC aggregate reports

#### ClickOps Implementation

**Step 1: Authenticate the Domain First**
1. Complete SendGrid sender authentication for a domain that you do control, so SPF and DKIM are already aligned and passing
2. Do not publish a DMARC policy for a domain whose mail streams you cannot see — enforcement on an unauthenticated domain blocks your own mail

**Step 2: Publish a Monitoring Record**
1. Create a DNS TXT record on the `_dmarc` subdomain of your sending domain
2. The record is a semicolon-separated tag list. The three tags that matter for a starting policy are:
   - `v=DMARC1` — the version tag, required and always first
   - `p=` — the policy applied to mail that fails authentication: `none`, `quarantine`, or `reject`
   - `rua=mailto:` — the address that receives aggregate reports
3. Start with `p=none`. This asks receivers to take no action but still send you reports, which is how you collect a complete picture of who sends as your domain before anything is blocked

**Step 3: Read Reports, Then Tighten the Policy**
1. Review the aggregate reports arriving at your `rua` address and identify every legitimate sender that is failing SPF or DKIM alignment
2. Fix or retire those senders — a forgotten marketing tool or on-premises relay is the usual cause
3. Once legitimate mail passes consistently, move the policy to `p=quarantine`, monitor again, then to `p=reject` for full enforcement
4. Keep the `rua` address monitored after enforcement — reports remain the only visibility into new senders and impersonation attempts

---

## 4. Monitoring & Compliance

### 4.1 Monitor Email Activity

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Monitor email sending activity and statistics.

#### Rationale
**Why This Matters:**
- Tracking delivery, bounce, and spam-complaint rates surfaces account abuse and compromise early
- A sudden spike in volume or bounces is often the first sign a key has been stolen and is sending phishing or spam
- Retained activity logs provide the audit trail needed for incident investigation and compliance evidence
- Continuous monitoring protects sender reputation before blocklists and ISPs throttle your mail

**Attack Prevented:** Undetected account compromise, spam and phishing abuse, sender-reputation damage, audit gaps

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

---

### 4.2 Configure Event Webhooks

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-6 |

#### Description
Configure webhooks for real-time event notification.

#### Rationale
**Why This Matters:**
- Real-time event delivery enables automated detection and response far faster than manual dashboard review
- Streaming events into your SIEM or analytics gives security teams immediate visibility into anomalous sending
- HTTPS-only delivery with verified signatures ensures event data cannot be forged or intercepted in transit
- Without webhook signature verification, an attacker could spoof events and poison downstream monitoring

**Attack Prevented:** Delayed incident detection, event forgery, man-in-the-middle interception, monitoring blind spots

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

---

### 4.3 Monitor for Compromised Accounts

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Detect and respond to account compromise.

#### Rationale
**Why This Matters:**
- Watching for unusual send volumes, bounce spikes, and unknown API keys catches takeover before major damage
- A documented response, rotating keys and resetting passwords and reviewing teammate access, shortens attacker dwell time
- Preventive controls such as enforced 2FA and IP access management reduce the likelihood of compromise in the first place
- Compromised SendGrid accounts are routinely abused to send phishing and spam under your trusted domain

**Attack Prevented:** Account takeover, credential theft, phishing and spam abuse, sender-reputation damage

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
| SC-8 | Sender authentication and DMARC | [3.3](#33-configure-sender-authentication), [3.4](#34-publish-and-enforce-a-dmarc-policy) |
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
- [Two-Factor Authentication](https://www.twilio.com/docs/sendgrid/ui/account-and-settings/two-factor-authentication)
- [Single Sign-On](https://www.twilio.com/docs/sendgrid/ui/account-and-settings/sso)
- [API Keys](https://www.twilio.com/docs/sendgrid/ui/account-and-settings/api-keys)
- [Teammate Permissions](https://www.twilio.com/docs/sendgrid/ui/account-and-settings/teammate-permissions)
- [IP Access Management](https://www.twilio.com/docs/sendgrid/ui/account-and-settings/ip-access-management)
- [DMARC](https://www.twilio.com/docs/sendgrid/ui/sending-email/dmarc)
- [Upgrade Your Authentication Method to API Keys](https://www.twilio.com/docs/sendgrid/for-developers/sending-email/upgrade-your-authentication-method-to-api-keys)
- [Secure Your Account](https://www.twilio.com/docs/sendgrid/concepts/security/secure-account)

**API & Developer Resources:**
- [SendGrid API Reference](https://www.twilio.com/docs/sendgrid/api-reference)

**Security Incidents:**
- No major public security breaches specific to SendGrid's infrastructure have been identified in recent years. Parent company Twilio experienced a phishing attack in August 2022 that exposed limited customer data. SendGrid accounts are frequently targeted by credential stuffing and account takeover attacks, which is the context for the platform's mandatory two-factor authentication.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.1 | draft | Add first Code Packs via the SendGrid v3 REST API (api/ type — SendGrid has no standalone first-party CLI): 1.4 IP Access Management allowlist audit and enforcement (`GET`/`POST /v3/access_settings/whitelist`), 2.3 least-privilege API key audit, scoped-key creation, and retirement (`/v3/api_keys` list/fetch-scopes/create-with-scopes/delete), 3.2 teammate permissions audit flagging Administrator grants (`GET /v3/teammates`). All endpoints fetch-verified this session against the Twilio SendGrid API reference; pack yml keys pending central sync | Claude Code (Fable 5) |
| 2026-08-08 | 0.2.0 | draft | Currency pass against Twilio SendGrid docs: corrected API key types to Full/Custom/Billing Access with per-scope No/Read/Full levels (2.1), corrected the teammate model to Administrator plus four SSO personas with billing mutually exclusive (3.2), removed the retired Authy branding and the unsourced backup-codes step from 2FA (1.1), documented that IP Access Management also governs the API and SMTP relay (1.4), added DMARC policy control (3.4), repaired two redirecting reference links and removed Trust Center and marketing-blog sources. Tier 2 (CIS/DISA/CISA SCuBA) confirmed zero applicable baselines for SendGrid; Tier 3/4 incident sourcing blocked, so the Appendix B incident note carries over unverified | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with 2FA, API key security, and SSO configuration | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
