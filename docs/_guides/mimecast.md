---
layout: guide
title: "Mimecast Hardening Guide"
vendor: "Mimecast"
slug: "mimecast"
tier: "2"
category: "Security"
description: "Email security hardening for Mimecast including targeted threat protection, impersonation policies, and gateway configuration"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

Mimecast is a leading cloud-based email security platform protecting **millions of mailboxes** against phishing, malware, and business email compromise (BEC). As the gateway for all organizational email, Mimecast configurations directly impact protection against the #1 attack vector. Proper hardening ensures maximum protection while minimizing false positives.

### Intended Audience
- Security engineers managing email security
- IT administrators configuring Mimecast
- GRC professionals assessing email protection
- SOC analysts monitoring email threats

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Mimecast Email Security Gateway configuration including targeted threat protection, impersonation protection, URL protection, and policy optimization.

---

## Table of Contents

1. [Gateway Configuration](#1-gateway-configuration)
2. [Targeted Threat Protection](#2-targeted-threat-protection)
3. [Impersonation Protection](#3-impersonation-protection)
4. [Admin & Access Security](#4-admin--access-security)
5. [Monitoring & Compliance](#5-monitoring--compliance)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Gateway Configuration

### 1.1 Verify MX Record Configuration

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.2 |
| NIST 800-53 | SC-7 |

#### Description
Ensure MX records are properly configured to route all email through Mimecast.

#### Rationale
**Why This Matters:**
- Incorrect MX priorities can bypass Mimecast protection
- Email must route through Mimecast before reaching mail server
- Misconfiguration leaves organization exposed

**Attack Prevented:** Gateway bypass, direct-to-mailbox delivery of unfiltered phishing and malware

#### Validation

**Step 1: Check MX Records**

**Step 2: Verify Configuration**
1. MX records should point to Mimecast servers
2. Priority should be lowest number (e.g., 10)
3. No direct mail server MX records should exist

**Step 3: Configure Email Server**
1. Configure mail server to only accept from Mimecast IPs
2. Block direct delivery attempts
3. Document allowed IP ranges

---

### 1.2 Configure Email Authentication (SPF, DKIM, DMARC)

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.5 |
| NIST 800-53 | SC-8 |

#### Description
Configure email authentication to prevent spoofing and verify sender identity.

#### Rationale
**Why This Matters:**
- SPF, DKIM, and DMARC let receiving servers verify that mail claiming to come from your domain actually originated from authorized senders
- Without an enforcing DMARC policy, attackers can spoof your exact domain in phishing and BEC campaigns that pass basic filters
- A published DMARC reject policy stops unauthorized senders from delivering mail as your brand and protects domain reputation
- Inbound authentication checking lets Mimecast quarantine or reject spoofed inbound mail before it reaches users

**Attack Prevented:** Domain spoofing, phishing, business email compromise, brand impersonation

#### ClickOps Implementation

**Step 1: Configure SPF**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **DNS Authentication - Outbound**
2. Verify SPF record includes Mimecast. See the Code Pack below for the recommended SPF and DMARC records.

**Step 2: Configure DKIM**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **DNS Authentication - Outbound**
2. Enable DKIM signing
3. Generate DKIM keys
4. Publish DKIM DNS records

**Step 3: Configure DMARC**
1. Publish DMARC record (see Code Pack below for recommended record format)
2. Start with `p=none` for monitoring
3. Progress to `p=quarantine` then `p=reject`

**Step 4: Configure Inbound Checking**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **DNS Authentication - Inbound**
2. Configure actions for SPF/DKIM/DMARC failures

---

### 1.3 Configure Secure Communication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | SC-8 |

#### Description
Configure TLS and secure communication for email transmission.

#### Rationale
**Why This Matters:**
- TLS encrypts email in transit so messages and credentials cannot be read or modified by network eavesdroppers
- Plaintext LDAP and POP3 expose directory credentials and journaled mail to interception on the wire
- Enforced TLS for sensitive domains prevents silent downgrade to cleartext delivery
- Encrypting directory sync and journaling protects the integrity of the data Mimecast relies on for policy and compliance

**Attack Prevented:** Man-in-the-middle interception, credential sniffing, eavesdropping, TLS downgrade

#### ClickOps Implementation

**Step 1: Configure TLS**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **Secure Messaging**
2. Configure TLS settings:
   - Enable opportunistic TLS
   - Require TLS for sensitive domains (L2)
   - Configure TLS version requirements

**Step 2: Configure Directory Sync Security**
1. Use LDAPS instead of LDAP
2. Navigate to: **Administration** → **Services** → **Directory Sync**
3. Configure LDAPS for encrypted sync

**Step 3: Configure Journaling Security**
1. Use POP3S instead of POP3
2. Ensure encrypted communication

---

## 2. Targeted Threat Protection

### 2.1 Configure URL Protection

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.6 |
| NIST 800-53 | SI-3 |

#### Description
Configure URL Protection to detect and block malicious links.

#### Rationale
**Why This Matters:**
- Malicious links are the most common phishing payload, and URLs that look clean at delivery are frequently weaponized after the email lands
- Scan-on-click (time-of-click) rewriting re-checks every link at the moment a user clicks, catching delayed-activation and newly weaponized URLs
- Newly observed domain detection adds scrutiny to throwaway domains attackers register hours before a campaign
- Blocking malicious downloads and scanning internal URLs limits both initial compromise and lateral spread

**Attack Prevented:** Phishing, credential harvesting, drive-by malware, delayed-weaponization links

#### ClickOps Implementation

**Step 1: Access URL Protection**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **URL Protection**

**Step 2: Configure Definition**
1. Click **New Definition** or edit existing
2. Configure URL scanning:
   - **Enable URL rewriting:** Yes
   - **Scan on click:** Yes (critical)
   - **Block malicious URLs:** Yes
   - **Check against browser isolation:** Consider for L2

**Step 3: Enable All URL Options**
1. Enable:
   - Scan internal URLs
   - Check file downloads
   - Advanced similarity checks
   - Newly observed domain detection

**Step 4: Configure User Notification**
1. Configure block page messaging
2. Enable user reporting for false positives
3. Set up admin notifications

**Time to Complete:** ~30 minutes

---

### 2.2 Configure Attachment Protection

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.1 |
| NIST 800-53 | SI-3 |

#### Description
Configure attachment scanning and sandboxing for malware protection.

#### Rationale
**Why This Matters:**
- Email attachments remain a primary delivery vehicle for malware, ransomware, and macro-based loaders
- Sandbox detonation of suspicious files catches zero-day and evasive malware that signature-only scanning misses
- Blocking high-risk executable, script, and macro-enabled file types removes the most commonly weaponized formats by default
- Converting attachments to safe formats before delivery neutralizes embedded active content while preserving usability

**Attack Prevented:** Malware delivery, ransomware, macro-based attacks, zero-day exploits

#### ClickOps Implementation

**Step 1: Access Attachment Protection**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **Attachment Protection**

**Step 2: Configure Attachment Scanning**
1. Configure definition:
   - **Enable attachment scanning:** Yes
   - **Sandbox suspicious files:** Yes
   - **Block password-protected archives:** Consider
   - **Block dangerous file types:** Yes

**Step 3: Configure File Type Restrictions**
1. Block high-risk file types:
   - Executable files (.exe, .scr, .bat, .cmd)
   - Script files (.js, .vbs, .ps1)
   - Macro-enabled documents (.docm, .xlsm)
2. Consider blocking by default, allow by exception

**Step 4: Configure Safe File Viewing**
1. Enable **Preemptive protection**
2. Convert to safe formats before delivery
3. Allow download of original if needed

---

### 2.3 Configure Internal Email Protection

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.6 |
| NIST 800-53 | SI-3 |

#### Description
Enable scanning of internal email for compromised account detection.

#### Rationale
**Why This Matters:**
- Compromised internal accounts can spread malware
- Internal phishing can bypass perimeter controls
- Lateral movement detection

**Attack Prevented:** Internal phishing from a compromised mailbox, lateral malware spread, perimeter-only inspection gaps

#### ClickOps Implementation

**Step 1: Configure Internal Email Protect**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **Internal Email Protect**
2. Enable internal email scanning
3. Configure threat detection

**Step 2: Configure Policies**
1. Apply URL Protection to internal mail
2. Apply Attachment Protection
3. Monitor for suspicious patterns

---

## 3. Impersonation Protection

### 3.1 Configure Standard Impersonation Policy

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.6 |
| NIST 800-53 | SI-3 |

#### Description
Configure impersonation protection to detect business email compromise attempts.

#### Rationale
**Why This Matters:**
- BEC attacks cause billions in losses annually
- Impersonation of executives is primary attack vector
- Requires multiple detection layers

**Attack Prevented:** Business email compromise, display-name spoofing, reply-to redirection fraud

#### ClickOps Implementation

**Step 1: Configure Impersonation Protection**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **Impersonation Protection**
2. Create new definition

**Step 2: Configure Standard 2-Hit Policy**
1. Configure "2-hit" detection:
   - Display name matches + suspicious indicators
   - Reply-to mismatch + urgency language
2. Set action: Tag, hold, or block

**Step 3: Configure Newly Observed Domain Policy**
1. Flag emails from newly registered domains
2. Increased scrutiny for new senders
3. Configure age threshold (e.g., 30 days)

---

### 3.2 Configure VIP Protection

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.6 |
| NIST 800-53 | SI-3 |

#### Description
Configure enhanced protection for high-value targets (executives, finance).

#### Rationale
**Why This Matters:**
- Executives and finance staff are the highest-value impersonation and wire-fraud targets because of their authority to approve payments and access
- Lower flagging thresholds and additional display-name variants catch lookalike and name-spoofing attempts aimed at these users
- External-sender warnings and out-of-band verification reduce the chance a fraudulent payment request is acted on
- Concentrating stricter controls on a defined VIP group raises protection where the financial impact of a successful attack is greatest

**Attack Prevented:** CEO fraud, executive impersonation, wire transfer fraud, spear phishing

#### ClickOps Implementation

**Step 1: Define VIP List**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Definitions** → **Profile Groups**
2. Create VIP profile group
3. Add executives and high-risk users:
   - CEO, CFO, C-suite
   - Finance team
   - HR team
   - Legal team

**Step 2: Configure VIP Policy**
1. Create dedicated impersonation definition for VIPs
2. Configure stricter detection:
   - Lower threshold for flagging
   - Additional display name variations
   - External sender warnings

**Step 3: Configure User Awareness**
1. Add warning banners for impersonation attempts
2. Train VIPs on threat awareness
3. Establish out-of-band verification procedures

---

### 3.3 Configure Advanced Business Email Compromise (ABEC)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.6 |
| NIST 800-53 | SI-3 |

#### Description
Enable advanced BEC detection using AI-powered analysis.

#### Rationale
**Why This Matters:**
- Payload-less BEC emails contain no malicious link or attachment, so they evade traditional URL and attachment scanning
- AI-based analysis of tone, intent, urgency, and relationship anomalies detects social-engineering attempts that rule-based filters miss
- Monitor Mode lets you tune sensitivity against real traffic before enforcement, minimizing disruption from false positives
- Catching BEC at the gateway prevents fraudulent payment and data-disclosure requests from ever reaching the targeted user

**Attack Prevented:** Business email compromise, payload-less phishing, invoice fraud, social engineering

#### ClickOps Implementation

**Step 1: Enable ABEC**
1. Navigate to: **Administration** → **Gateway** → **Policies** → **Email Policies**
2. Edit policy → **Phishing & Impersonation**
3. Enable **Advanced BEC** settings

**Step 2: Configure ABEC Options**
1. Enable AI-based detection
2. Configure sensitivity level
3. Consider Monitor Mode for testing

**Step 3: Tune and Validate**
1. Review detections
2. Adjust false positive rates
3. Move from monitor to enforcement

---

## 4. Admin & Access Security

### 4.1 Configure Admin Access Controls

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege for Mimecast administration by restricting who holds the Protected and Security permission classes, not merely by counting administrators.

#### Rationale
**Why This Matters:**
- Mimecast admins can change security policies, release held mail, and access message content, so over-privileged accounts are a high-value target
- **Protected** permissions gate the highest-impact capabilities — viewing and exporting email content, delegate mailbox access, and retention — so an account holding them can read the organization's mail, not just administer the gateway
- **Security** permissions determine whether an admin can grant privileges to others (**Cannot Manage Roles** / **Manage Application Roles** / **Protected Roles**); an admin who can manage Protected roles can escalate themselves or anyone else
- Restricting these two classes is what actually contains an account takeover — limiting the count of admins without limiting their permission classes leaves the same capability in fewer hands

**Attack Prevented:** Privilege escalation via role management, mass mail-content exfiltration, insider misuse, unauthorized policy changes

#### ClickOps Implementation

**Step 1: Review the Default Admin Roles**
1. Navigate to: **Account** | **Admin Roles**
2. Review the default roles, which include **Super Administrator**, **Partner Administrator**, and **Full Administrator** among others
3. Note that **Super Administrator** and **Full Administrator** are themselves protected roles: their membership can only be managed by Mimecast Support, so plan changes to them in advance

**Step 2: Constrain the Permission Classes**
1. For each role, review the three permission classes:
   - **Application** — which console functions the role can use
   - **Protected** — viewing and exporting email content, delegate mailbox access, and retention
   - **Security** — role-management rights: **Cannot Manage Roles**, **Manage Application Roles**, or **Protected Roles**
2. Grant **Protected** permissions only to the small set of people with a documented need to access message content
3. Set **Security** to **Cannot Manage Roles** for every role that does not exist specifically to administer entitlements

**Step 3: Limit Membership and Review**
1. Restrict Super Administrator and Full Administrator membership to essential personnel
2. Use separate accounts for administrative work
3. Review role membership and permission classes together on a regular cadence — a role's membership list alone does not tell you what it can do

#### Validation & Testing
- For each admin role, confirm the Protected and Security permission settings match the documented intent.
- Confirm no role outside the entitlement-management set carries **Protected Roles** under Security.

**Source:** [Account: Admin Roles](https://mimecastsupport.zendesk.com/hc/en-us/articles/34000745394963)

---

### 4.2 Enforce MFA for Admin Accounts

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2-Step Authentication for administrative access by configuring an Authentication Profile and binding it to the relevant Application Setting.

#### Rationale
**Why This Matters:**
- Admin passwords alone are insufficient protection because credentials are routinely phished, reused, or leaked in breaches
- A second authentication factor blocks attackers who obtain a valid admin password from logging in
- Admin access controls the email security gateway itself, so a single compromised admin login could disable protection for the whole organization
- Enforced enrollment ensures no privileged account is left protected by password only

**Attack Prevented:** Credential theft, phishing, password reuse, admin account takeover

#### ClickOps Implementation

**Step 1: Create an Authentication Profile**
1. Navigate to the **Administration Console** → **Users & Groups** | **Applications** → **Authentication Profiles**
2. Create or edit a profile and enable **2-Step Authentication**

**Step 2: Choose the Second Factor**
1. Select the method:
   - **3rd party Authentication (TOTP) app** — Mimecast's recommended option
   - **Email**
   - **SMS**
2. Prefer the TOTP app; email and SMS inherit the weaknesses of the mailbox and the mobile carrier respectively

**Step 3: Bind the Profile to an Application Setting**
1. A profile takes effect only when it is bound to an **Application Setting**, which is scoped to a group
2. Bind the admin profile to the group containing your administrators
3. Confirm the group membership is accurate — an admin outside the bound group is not covered

**Step 4: Consider Adaptive Enforcement**
1. 2-Step Authentication supports **location-based (adaptive) enforcement**, challenging for the second factor only when the user is outside trusted networks
2. For administrators, prefer unconditional enforcement; use adaptive enforcement only where a documented trusted-network boundary genuinely holds

> **SAML takes precedence.** If a single Authentication Profile sets both **Enforce SAML** and 2-Step Authentication, SAML wins and the 2SA setting will not apply as configured. Enforce the second factor in the identity provider when you use SAML, rather than assuming the profile's 2SA setting is active. — [Authentication Profiles](https://mimecastsupport.zendesk.com/hc/en-us/articles/34000822265619)

#### Validation & Testing
- Sign in as a test administrator from an untrusted network and confirm the second factor is demanded.
- Confirm the **Account_Administrators_Authentication_Profile** has 2-Step Authentication enabled ([4.5](#45-maintain-a-backup-administrator-account)) — it governs and overrides authentication for all admin accounts.

**Sources:** [Authentication Profiles](https://mimecastsupport.zendesk.com/hc/en-us/articles/34000822265619) · [Configuring 2-Step Authentication](https://mimecastsupport.zendesk.com/hc/en-us/articles/34000822544147)

---

### 4.3 Manage User Access and Lifecycle

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Implement proper user lifecycle management.

#### Rationale
**Why This Matters:**
- Directory sync ties Mimecast accounts to an authoritative source so disabled or deleted users lose access automatically
- Orphaned accounts for departed employees retain standing access to mail and can be exploited if not removed
- Automatic disabling on AD changes closes the window between offboarding and access revocation
- Regular access reviews catch accounts with excessive or stale permissions before they are abused

**Attack Prevented:** Orphaned-account access, unauthorized access by former employees, privilege creep

#### ClickOps Implementation

**Step 1: Configure Directory Sync**
1. Navigate to: **Administration** → **Services** → **Directory Sync**
2. Configure sync with Active Directory
3. Enable automatic disabling on AD deletion/disable

**Step 2: Regular Access Review**
1. Review user accounts quarterly
2. Remove inactive accounts
3. Verify access levels appropriate

---

### 4.4 Restrict Administration Console Access by IP Range

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4, 12.5 |
| NIST 800-53 | AC-3, AC-17 |

#### Description
Limit Administration Console sign-in to known corporate and VPN egress ranges, while understanding that this restriction no longer covers API access.

#### Rationale
**Why This Matters:**
- An IP allowlist means a stolen admin credential is unusable from an arbitrary internet host, converting a pure credential attack into one that also requires network position
- Combined with 2-Step Authentication ([4.2](#42-enforce-mfa-for-admin-accounts)), it forces an attacker to defeat two independent controls to reach the console
- A misconfigured allowlist locks out the administrators who maintain the email security gateway, so incremental testing and a documented emergency-access procedure are part of the control, not optional extras

**Attack Prevented:** Remote credential-replay against the admin console, opportunistic admin login from attacker infrastructure

> **Changed default — IP restrictions no longer cover the API.** Effective **2025-09-16**, Mimecast Admin IP allow and block lists **no longer apply to public Mimecast API endpoints** (OAuth2). IP ranges are therefore **not** a compensating control over API access: an attacker holding valid API credentials reaches the API from any address regardless of your allowlist. Protect the API through credential hygiene and scope instead. — [Changes to Admin IP Allow and Block Lists](https://mimecastsupport.zendesk.com/hc/en-us/articles/44764533235347)

#### ClickOps Implementation

**Step 1: Document the Authorized Ranges**
1. Inventory the corporate egress and VPN ranges administrators legitimately connect from
2. Record the owner and business justification for each range before adding it

**Step 2: Configure the Allowlist**
1. Navigate to: **Account Settings** → **User Access and Permissions**
2. Configure **Admin IP Ranges** in CIDR notation
3. Review **Cloud Password Rules** on the same page while you are there, so console password policy and network restriction are set as a pair

**Step 3: Roll Out Incrementally**
1. Add and test one range at a time rather than committing a full list in a single change
2. Verify administrator access after each addition before proceeding
3. Ensure **at least two administrators remain reachable from different IP ranges**, so a single office or VPN outage cannot lock out the console

**Step 4: Maintain an Emergency Path**
1. Document an emergency-access procedure before enforcing the restriction
2. Audit the allowlist periodically and remove ranges that no longer correspond to an active office, VPN, or provider

#### Validation & Testing
- Attempt an administrator login from an address outside the allowlist and confirm it is refused.
- Confirm at least two administrators can each reach the console from distinct authorized ranges.
- Confirm your API protections do not depend on the IP allowlist, per the callout above.

**Source:** [Admin IP Ranges and Cloud Password Rules](https://mimecastsupport.zendesk.com/hc/en-us/articles/49581922337555)

---

### 4.5 Maintain a Backup Administrator Account

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1, 6.2 |
| NIST 800-53 | AC-2, CP-2 |

#### Description
Keep more than one account in the highest administrative roles so the tenant cannot be locked out, and verify that the profile governing all admin authentication enforces a second factor.

#### Rationale
**Why This Matters:**
- If the sole administrator's account is lost, disabled, or offboarded, recovering administrative access **requires Mimecast approval** — an availability incident on the control plane of your email security at the worst possible moment
- Mimecast's email gateway is inline with all mail flow, so a lockout is not merely inconvenient: policy changes, mail release, and incident response all stop until access is restored
- The **Account_Administrators_Authentication_Profile** governs authentication for **all** administrator accounts and **overrides any other profile**, so a backup admin created without checking it can inherit weaker authentication than you intended

**Attack Prevented:** Tenant lockout and loss of control-plane availability; a weakly-authenticated backup admin becoming the easiest path into the console

#### ClickOps Implementation

**Step 1: Add a Second Administrator**
1. Navigate to: **Account** | **Admin Roles**
2. Add a second trusted user to **Super Administrator** (primary choice) or **Full Administrator** (secondary choice)
3. Remember these are protected roles managed with Mimecast Support involvement — plan the change rather than attempting it during an incident

**Step 2: Verify the Governing Authentication Profile**
1. Confirm **Account_Administrators_Authentication_Profile** has 2-Step Authentication enabled ([4.2](#42-enforce-mfa-for-admin-accounts))
2. Because this profile overrides any other profile for admin accounts, checking a different profile is not sufficient evidence that admins are protected

**Step 3: Operationalize It**
1. Assign the backup account to a named individual with recorded ownership — never an unowned shared mailbox
2. Ensure the backup admin is reachable from a different authorized IP range than the primary ([4.4](#44-restrict-administration-console-access-by-ip-range))
3. Verify the backup account can actually sign in on a scheduled basis; an untested break-glass account is an assumption, not a control

#### Validation & Testing
- Confirm at least two accounts hold Super Administrator or Full Administrator, each owned by a named individual.
- Perform a scheduled sign-in test with the backup account and record the result.
- Confirm 2-Step Authentication is enabled on **Account_Administrators_Authentication_Profile**.

**Source:** [Creating a Backup Administrator Account](https://mimecastsupport.zendesk.com/hc/en-us/articles/48467143796499)

---

## 5. Monitoring & Compliance

### 5.1 Configure Audit Logging and Event Push

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Review audit events in the console and stream Mimecast telemetry to your SIEM using **Event Push**, the current delivery mechanism.

#### Rationale
**Why This Matters:**
- Audit logs of admin actions, policy changes, and authentication events provide the record needed to detect and investigate misuse
- Without export, malicious or mistaken policy changes can go unnoticed and unattributable beyond the console's own view
- Event Push delivers threat, DLP, message release/rejection, and audit telemetry to your SIEM, enabling alerting and correlation with the rest of your security data
- Mimecast's inline position means its events are frequently the earliest signal of a phishing or BEC campaign against the organization

**Attack Prevented:** Undetected policy tampering, insider misuse, delayed breach detection, repudiation

#### ClickOps Implementation

**Step 1: Review Audit Events in the Console**
1. Navigate to: **Administration** → **Account** → **Audit Events**
2. Review logged events:
   - Admin actions
   - Policy changes
   - Authentication events

**Step 2: Configure Event Push**
1. Configure **Event Push** as the delivery mechanism to your SIEM — it replaces any older SIEM-integration menu path and was enhanced on **2025-11-18**
2. Choose a delivery format and destination:
   - **HEC batch JSON** (Splunk HTTP Event Collector)
   - **NDJSON**
   - **Webhook**
   - **AWS S3**
3. Select the event types to push, which include **Audit**, **TTP protections**, **DLP**, **Message Release/Rejection**, **MTA**, **Threat**, and **Remediation**

**Step 3: Secure the Channel**
1. Authenticate the destination using **OAuth 2.0**, **static headers with secret masking**, or **IP-based** authorization
2. Deliver over **HTTPS on port 443** with a publicly valid certificate on the receiving endpoint — self-signed certificates will not be accepted
3. Configure the retry behavior and the error notification email so a silently failing push is surfaced rather than discovered during an investigation

> **API 1.0 is end-of-life.** Creation of new API 1.0 applications was **removed in June 2025**, and existing 1.0 applications are slated for expiry. Migrate any integration still using API 1.0 keys — including log-collection scripts — to **API 2.0**. Also note that Admin IP allow/block lists no longer restrict public API endpoints ([4.4](#44-restrict-administration-console-access-by-ip-range)). — [API 1.0 End of Life](https://mimecastsupport.zendesk.com/hc/en-us/articles/39704312201235)

**Key Events to Monitor:**
- Policy modifications
- Admin login events and 2-Step Authentication changes
- Admin role and permission-class changes ([4.1](#41-configure-admin-access-controls))
- Admin IP range changes ([4.4](#44-restrict-administration-console-access-by-ip-range))
- URL/Attachment blocks
- Impersonation detections
- Message release and rejection events

#### Validation & Testing
- Make a benign policy change and confirm the corresponding audit event arrives in the SIEM within the expected delivery window.
- Deliberately break and restore the destination endpoint to confirm the retry behavior and error email work as configured.
- Confirm no integration is still authenticating with an API 1.0 key.

**Sources:** [Event Push](https://mimecastsupport.zendesk.com/hc/en-us/articles/46464059376147) · [API 1.0 End of Life](https://mimecastsupport.zendesk.com/hc/en-us/articles/39704312201235)

**Key Events to Monitor:**
- Policy modifications
- Admin login events
- Permission changes
- URL/Attachment blocks
- Impersonation detections

---

### 5.2 Conduct Quarterly Policy Review

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Regularly audit and review Mimecast policies for effectiveness.

#### Rationale
**Why This Matters:**
- Security policies drift over time as exceptions accumulate, threats evolve, and configurations are changed ad hoc
- Periodic review catches weakened or obsolete settings, stale permitted-sender entries, and outdated VIP lists before attackers exploit them
- Reviewing detection effectiveness and false-positive rates keeps protection tuned without users routing around controls
- Scheduled audits ensure new threat-protection features are adopted rather than left at insecure defaults

**Attack Prevented:** Configuration drift, stale allowlist abuse, control degradation, coverage gaps

#### Process

**Step 1: Audit Core Security Policies**
1. Review 18 core security policies
2. Verify configurations are current
3. Check for policy drift

**Step 2: Review Profile Groups**
1. Audit email/domain/IP lists
2. Remove obsolete entries
3. Document approved exceptions

**Step 3: Review Detection Effectiveness**
1. Analyze blocked threats
2. Review false positive rates
3. Tune policies as needed

**Quarterly Checklist:**
- Review impersonation protection settings
- Verify VIP list is current
- Audit permitted sender lists
- Review URL/Attachment block rates
- Check admin access list
- Verify MX record configuration

---

### 5.3 Monitor Threat Dashboard

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Actively monitor threat dashboard for emerging threats.

#### Rationale
**Why This Matters:**
- The threat dashboard surfaces blocked-threat trends and targeted-user patterns that indicate active campaigns against your organization
- Active monitoring shortens detection and response time for emerging attacks rather than discovering them after impact
- Alerts on unusual block volume or VIP-targeted attacks flag campaigns in progress while they can still be contained
- Visibility into top targeted users informs where to focus additional awareness training and protective controls

**Attack Prevented:** Undetected attack campaigns, delayed incident response, targeted attacks on key users

#### ClickOps Implementation

**Step 1: Access Dashboard**
1. Navigate to: **Monitoring** → **Threat Dashboard**
2. Review:
   - Blocked threats by category
   - Detection trends
   - Top targeted users

**Step 2: Configure Alerts**
1. Set up alerts for:
   - Unusual volume of blocks
   - New threat campaigns
   - Targeted attacks on VIPs

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Mimecast Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | Admin MFA | [4.2](#42-enforce-mfa-for-admin-accounts) |
| CC6.6 | URL Protection | [2.1](#21-configure-url-protection) |
| CC6.8 | Attachment Protection | [2.2](#22-configure-attachment-protection) |
| CC6.7 | Admin network restriction | [4.4](#44-restrict-administration-console-access-by-ip-range) |
| CC7.1 | Email Authentication | [1.2](#12-configure-email-authentication-spf-dkim-dmarc) |
| CC7.2 | Audit logging and Event Push | [5.1](#51-configure-audit-logging-and-event-push) |
| A1.2 | Administrative availability | [4.5](#45-maintain-a-backup-administrator-account) |

### NIST 800-53 Rev 5 Mapping

| Control | Mimecast Control | Guide Section |
|---------|------------------|---------------|
| SC-7 | Gateway configuration | [1.1](#11-verify-mx-record-configuration) |
| SC-8 | TLS/Encryption | [1.3](#13-configure-secure-communication) |
| SI-3 | Threat Protection | [2.1](#21-configure-url-protection), [2.2](#22-configure-attachment-protection) |
| AC-6 | Least privilege | [4.1](#41-configure-admin-access-controls) |
| AC-17 | Remote admin access restriction | [4.4](#44-restrict-administration-console-access-by-ip-range) |
| AU-2 | Audit logging | [5.1](#51-configure-audit-logging-and-event-push) |
| CP-2 | Contingency planning (admin lockout) | [4.5](#45-maintain-a-backup-administrator-account) |

---

## Appendix A: Default Policy Review

| Policy Area | Default Setting | Recommended Change |
|-------------|-----------------|-------------------|
| URL Protection | Basic | Enable all options |
| Attachment Protection | Basic | Enable sandboxing |
| Impersonation Protection | Disabled | Enable with VIP list |
| DMARC | None | p=quarantine minimum |
| Internal Email Protection | Disabled | Enable for L2 |

---

## Appendix B: References

**Official Mimecast Documentation:**
- [Security Efficacy: Security Recommendations](https://mimecastsupport.zendesk.com/hc/en-us/articles/34000390489235-Security-Efficacy-Security-Recommendations)
- [Targeted Threat Protection Optimization](https://mimecastsupport.zendesk.com/hc/en-us/articles/34000726395155-Targeted-Threat-Protection-Optimization)
- [TTP Impersonation Protection](https://mimecastsupport.zendesk.com/hc/en-us/articles/34000781880723)
- [Account: Admin Roles](https://mimecastsupport.zendesk.com/hc/en-us/articles/34000745394963)
- [Authentication Profiles](https://mimecastsupport.zendesk.com/hc/en-us/articles/34000822265619)
- [Configuring 2-Step Authentication](https://mimecastsupport.zendesk.com/hc/en-us/articles/34000822544147)
- [Admin IP Ranges and Cloud Password Rules](https://mimecastsupport.zendesk.com/hc/en-us/articles/49581922337555)
- [Changes to Admin IP Allow and Block Lists (2025-09-16)](https://mimecastsupport.zendesk.com/hc/en-us/articles/44764533235347)
- [Creating a Backup Administrator Account](https://mimecastsupport.zendesk.com/hc/en-us/articles/48467143796499)
- [Event Push](https://mimecastsupport.zendesk.com/hc/en-us/articles/46464059376147)

**API Documentation:**
- [API 1.0 End of Life](https://mimecastsupport.zendesk.com/hc/en-us/articles/39704312201235)

**Security Incidents:**
- **SolarWinds Supply Chain Attack (January 2021):** Mimecast confirmed that a certificate used for Microsoft 365 Exchange Web Services authentication was compromised by the same nation-state actors (APT29) behind the SolarWinds attack. Approximately 10% of customers (~3,900) used the affected connection type, and fewer than 10 were specifically targeted. Attackers potentially exfiltrated encrypted service account credentials and accessed some source code. — [Mimecast Certificate Compromise (TechTarget)](https://www.techtarget.com/searchsecurity/news/252495395/Mimecast-certificate-compromised-by-SolarWinds-hackers)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass: correct 4.1 (default Admin Roles at Account \| Admin Roles and the Application/Protected/Security permission classes, replacing invented custom-role names), 4.2 (2-Step Authentication via Authentication Profiles bound to an Application Setting; SAML precedence), and 5.1 (Event Push replaces the unverifiable SIEM Integration path; API 1.0 end-of-life callout). Add 4.4 Admin Console IP restrictions with the 2025-09-16 changed default that IP lists no longer apply to public API endpoints, and 4.5 backup administrator account. Fix Appendix B link rot (docs.mimecast.com dead, community.mimecast.com articles moved to Zendesk) and purge Trust Center pages. Add missing Attack Prevented lines to 1.1, 2.3, 3.1. Tier 3/4 research sweep out of scope for this pass (search budget) | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with gateway, TTP, and impersonation protection | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
