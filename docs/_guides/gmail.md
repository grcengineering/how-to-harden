---
layout: guide
title: "Gmail Hardening Guide"
vendor: "Gmail"
slug: "gmail"
platform: "Google Workspace"
platform_slug: "google-workspace"
product: "Gmail"
tier: "1"
category: "Productivity"
description: "Security hardening for Gmail within Google Workspace — email authentication (SPF/DKIM/DMARC), phishing & malware safety settings, mail-flow compliance rules, legacy-access lockdown, and Gmail log monitoring."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-03"
---

## Overview

Gmail is the email surface of Google Workspace and the primary target for phishing and business email compromise. This guide hardens Gmail-specific surfaces in the Admin console: email authentication (SPF, DKIM, DMARC), the Safety settings that blunt spoofing and malicious attachments, mail-flow compliance and quarantine rules, legacy-protocol and forwarding lockdown, and the logging that turns Gmail into a detection sensor.

This is a **product guide within the [Google Workspace platform](/guides/google-workspace/)**. Platform-wide controls (authentication/MFA, OAuth app allowlisting, the DLP engine, admin audit logging) live in the Google Workspace **Common Controls** hub and are referenced here rather than duplicated.

Most Gmail hardening settings are **ClickOps-only by design**: Google's Cloud Identity Policy API exposes several Gmail settings read-only (audit surface), but none support mutation, and no Admin SDK endpoint sets Safety or Compliance rules. Controls below state their real automation surface honestly — where none exists, none is claimed.

### Intended Audience
- Security engineers and IT administrators managing Gmail in Google Workspace
- GRC professionals mapping email-security posture to CISA SCuBA and BOD 25-01
- Incident responders investigating phishing and mailbox compromise

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Gmail-specific hardening: email authentication (SPF/DKIM/DMARC), Gmail Safety settings (spoofing, attachments, links), spam-filter and allowlist hygiene, compliance/quarantine rules, POP/IMAP and auto-forwarding lockdown, comprehensive mail storage, Gmail log events, confidential mode, and Hosted S/MIME. Platform-wide authentication, OAuth allowlisting, the DLP engine, and admin audit logging are covered in the [Google Workspace guide](/guides/google-workspace/). Google Chat and Google Drive have their own product guides.

The primary compliance mapping used here is the **CISA SCuBA Secure Configuration Baseline for Gmail** ([ScubaGoggles baseline](https://github.com/cisagov/ScubaGoggles/blob/main/scubagoggles/baselines/gmail.md)) — it carries machine-checkable `GWS.GMAIL.x.xvx` policy IDs, many with binding BOD 25-01 requirements, and the [ScubaGoggles](https://github.com/cisagov/ScubaGoggles) tool programmatically assesses them.

---

## Table of Contents

1. [Email Authentication](#1-email-authentication)
2. [Phishing & Malware Protection](#2-phishing--malware-protection)
3. [Mail Flow & Compliance](#3-mail-flow--compliance)
4. [Access & Forwarding](#4-access--forwarding)
5. [Monitoring & Encryption](#5-monitoring--encryption)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Email Authentication

### 1.1 Publish an SPF Record for Every Sending Domain

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.5 |
| NIST 800-53 | SC-8, SI-8 |
| CISA SCuBA | GWS.GMAIL.3.1v1 |

#### Description
Publish an SPF TXT record at every domain and subdomain that sends mail, enumerating the hosts authorized to use it as an envelope sender. SPF is one of the two inputs DMARC alignment depends on.

#### Rationale
**Why This Matters:**
- Without SPF, any host on the internet can send mail claiming your envelope-from domain and receivers have no mechanical way to reject it
- SPF is a prerequisite for DMARC — DMARC cannot pass without SPF or DKIM alignment
- Third-party senders (marketing platforms, ticketing systems) silently break authentication unless enumerated in the record

**Attack Prevented:** Direct domain spoofing / envelope-sender forgery used to launch business email compromise from an unowned host

#### ClickOps Implementation

**Step 1: Publish the Record (at your DNS host — no Admin console setting)**
1. Sign in to your domain host's DNS management page
2. Add a TXT record with Host/Name `@` (root domain)
3. Value: `v=spf1 include:_spf.google.com ~all`
4. Add separate SPF records for each subdomain that sends mail
5. Allow up to 48 hours to activate

> **Hardening note:** Google's own documentation recommends the softfail qualifier `~all`; the CISA SCuBA baseline (GWS.GMAIL.3.1v1) requires the fail-all qualifier `-all`. Once every legitimate sender is enumerated and verified, `-all` is the hardened end state.

**Time to Complete:** ~30 minutes plus DNS propagation

#### Validation & Testing
1. Run `dig TXT yourdomain.com` and confirm exactly one SPF record beginning `v=spf1`
2. Send a message to an external mailbox and inspect the headers: `Received-SPF` should show `pass`
3. Repeat for every sending subdomain

**Expected result:** One SPF record per sending domain; external receivers record SPF pass. ([Set up SPF](https://knowledge.workspace.google.com/admin/security/set-up-spf))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | Boundary protection for transmissions |
| **NIST 800-53** | SI-8 | Spam protection |
| **CISA SCuBA** | GWS.GMAIL.3.1v1 | SPF with fail-all qualifier |

---

### 1.2 Enable DKIM Signing with a 2048-bit Key

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.5 |
| NIST 800-53 | SC-8, SI-8 |
| CISA SCuBA | GWS.GMAIL.2.1v1 |

#### Description
Generate a domain DKIM key in the Admin console, publish it in DNS, and start signing. Google does not sign with your domain key by default — until you do this, outbound mail carries only a generic Google signature that provides no domain-level assurance.

#### Rationale
**Why This Matters:**
- DKIM cryptographically signs outbound mail so receivers can detect tampering and forgery independent of sending IP
- Unlike SPF, DKIM survives forwarding and mailing lists, making it the more durable of the two DMARC inputs
- The default (no domain key) leaves your DMARC posture standing on SPF alone

**Attack Prevented:** Outbound message forgery and in-transit content tampering enabling invoice-fraud and payroll-diversion BEC

#### ClickOps Implementation

**Step 1: Generate and Publish the Key**
1. Navigate to: **Admin console** → **Apps** → **Google Workspace** → **Gmail** → **Authenticate email**
2. Select your domain from the **Selected domain** menu
3. Choose key length **2048-bit** (fall back to 1024-bit only if your DNS host rejects the longer record)
4. Keep the default prefix selector `google` and click **Generate New Record**
5. Publish the generated TXT value at your DNS host with host `google._domainkey`
6. Return to the Admin console and click **Start authentication**
7. Allow up to 48 hours

**Time to Complete:** ~30 minutes plus DNS propagation

#### Validation & Testing
1. Run `dig TXT google._domainkey.yourdomain.com` and confirm the record begins `v=DKIM1`
2. Send a message to an external mailbox and confirm the `DKIM-Signature` header uses `d=yourdomain.com`

**Expected result:** Outbound mail signed with your 2048-bit domain key. ([Set up DKIM](https://knowledge.workspace.google.com/admin/security/set-up-dkim))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | Boundary protection for transmissions |
| **NIST 800-53** | SC-8 | Transmission integrity |
| **CISA SCuBA** | GWS.GMAIL.2.1v1 | DKIM enabled for all sending domains |

---

### 1.3 Publish and Enforce a DMARC Policy

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.5 |
| NIST 800-53 | SI-8, AU-6 |
| CISA SCuBA | GWS.GMAIL.4.1v1–4.4v1 |

#### Description
Publish a DMARC record at `_dmarc.<yourdomain>`, monitor aggregate reports until legitimate senders align, then enforce with `p=reject`. DMARC is the instruction that tells receivers what to do when SPF/DKIM fail — without it, authentication failures are informational only.

#### Rationale
**Why This Matters:**
- SPF and DKIM alone tell a receiver nothing about what to do on failure — DMARC supplies the enforcement instruction
- Leaving a domain at `p=none` indefinitely is the most common failure mode: reporting is on, but spoofed mail still lands
- Aggregate reports are the only reliable inventory of who is sending as your domain, including shadow-IT senders

**Attack Prevented:** Business email compromise and phishing via exact-domain spoofing of your own brand against customers, partners, and staff

#### Prerequisites
- SPF ([1.1](#11-publish-an-spf-record-for-every-sending-domain)) and/or DKIM ([1.2](#12-enable-dkim-signing-with-a-2048-bit-key)) live — Google requires waiting **48 hours** after enabling them before publishing DMARC
- A dedicated group or mailbox for aggregate reports

#### ClickOps Implementation

**Step 1: Start in Monitoring Mode**
1. Confirm every third-party service sending as your domain authenticates via SPF or DKIM
2. Publish a TXT record at `_dmarc.yourdomain.com` starting `v=DMARC1; p=none; rua=mailto:dmarc@yourdomain.com`
3. Monitor aggregate reports until legitimate senders all align

**Step 2: Enforce**
1. Move to `p=quarantine`, then `p=reject`
2. Tighten alignment with `adkim=s; aspf=s` and set `pct=100` — Google's own example enforced record: `v=DMARC1; p=reject; rua=mailto:postmaster@yourdomain.com, mailto:dmarc@yourdomain.com; pct=100; adkim=s; aspf=s`

**Time to Complete:** ~1 hour setup; typically 2–6 weeks of monitoring before full enforcement

#### Validation & Testing
1. Run `dig TXT _dmarc.yourdomain.com` and confirm the published policy
2. Confirm aggregate reports arrive at the `rua` address
3. From a non-authorized host, send a test spoofing your domain to a mailbox you control — it should be rejected or quarantined at `p=reject`/`p=quarantine`

**Expected result:** Enforced DMARC with strict alignment and full-coverage reporting. ([Set up DMARC](https://knowledge.workspace.google.com/admin/security/set-up-dmarc))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | Boundary protection for transmissions |
| **NIST 800-53** | SI-8 | Spam protection |
| **CISA SCuBA** | GWS.GMAIL.4.1v1–4.4v1 | DMARC published, enforced, reporting |

---

## 2. Phishing & Malware Protection

### 2.1 Enable All Spoofing and Authentication Protections

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.7 |
| NIST 800-53 | SI-3, SI-8 |
| CISA SCuBA | GWS.GMAIL.7.1v1–7.7v1 |

#### Description
Enable all five Gmail Safety protections against spoofing and unauthenticated mail, and change each action from the default warn-in-inbox to spam or quarantine. Display-name and lookalike-domain spoofing pass SPF/DKIM/DMARC cleanly — these settings are what catches them.

#### Rationale
**Why This Matters:**
- The default action for every one of these leaves the message in the inbox with a warning banner that users routinely dismiss
- Display-name spoofing ("CEO &lt;attacker@gmail.com&gt;") authenticates the attacker's own domain, so DMARC on your domain never fires — only this setting catches it
- Lookalike-domain detection covers homoglyph and typosquat registrations DMARC cannot address

**Attack Prevented:** Business email compromise via display-name and lookalike-domain spoofing, plus Google Groups injection from forged internal senders

#### ClickOps Implementation

**Step 1: Enable the Protections**
1. Navigate to: **Admin console** → **Apps** → **Google Workspace** → **Gmail** → **Safety**
2. Under **Spoofing and authentication**, enable all five:
   - **Protect against domain spoofing based on similar domain names**
   - **Protect against spoofing of employee names**
   - **Protect against inbound emails spoofing your domain**
   - **Protect against any unauthenticated emails**
   - **Protect Groups from inbound emails spoofing your domain**
3. Change each action from **Keep email in inbox and show warning** to **Move email to spam** or **Quarantine**
4. Check **Apply future recommended settings automatically**
5. Click **Save**

**Time to Complete:** ~20 minutes

#### Validation & Testing
1. Send a display-name-spoofed test (executive name, external free-mail address) and confirm it lands in spam/quarantine
2. Review **Reporting** → **Audit and investigation** → **Gmail log events** for spoofing classifications

**Expected result:** All five protections on with spam/quarantine actions. ([Advanced phishing and malware protection](https://knowledge.workspace.google.com/admin/gmail/advanced/advanced-phishing-and-malware-protection))

> **Automation surface:** read-only audit via Cloud Identity Policy API setting `gmail.spoofing_and_authentication` (`policies.list`); no mutate support — changes are Admin console only.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.8 | Protection against malicious software |
| **NIST 800-53** | SI-8 | Spam protection |
| **CISA SCuBA** | GWS.GMAIL.7.1v1–7.7v1 | Spoofing and authentication protections |

---

### 2.2 Enable Attachment Protection Against Encrypted, Script-Bearing, and Anomalous Files

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.6, 10.1 |
| NIST 800-53 | SI-3 |
| CISA SCuBA | GWS.GMAIL.5.1v1–5.5v1 |

#### Description
Enable Gmail's attachment Safety protections for encrypted attachments from untrusted senders, script-bearing attachments, and anomalous attachment types, with spam/quarantine actions instead of inbox warnings.

#### Rationale
**Why This Matters:**
- Password-protected archives are the standard technique for smuggling malware past content scanners — the scanner cannot open the file, but the user has the password from the email body
- Macro- and script-bearing Office documents remain a primary initial-access vector for ransomware operators
- Anomalous-type detection catches extension mismatches where a payload is renamed to look benign

**Attack Prevented:** Malware and ransomware initial access via encrypted-archive and macro-document email attachments

#### ClickOps Implementation

**Step 1: Enable Attachment Protections**
1. Navigate to: **Gmail** → **Safety** → **Attachments**
2. Enable:
   - **Protect against encrypted attachments from untrusted senders**
   - **Protect against attachment with scripts from untrusted senders**
   - **Protect against anomalous attachment types in emails**
3. Set each action to **Move email to spam** or **Quarantine**
4. Check **Apply future recommended settings automatically**
5. Click **Save**

**Time to Complete:** ~15 minutes

#### Validation & Testing
1. Send a password-protected ZIP from an external test account — confirm spam/quarantine placement
2. Review Gmail log events for attachment-protection classifications

**Expected result:** All three attachment protections on with spam/quarantine actions. ([Advanced phishing and malware protection](https://knowledge.workspace.google.com/admin/gmail/advanced/advanced-phishing-and-malware-protection))

> **Automation surface:** read-only via Policy API setting `gmail.email_attachment_safety`; no mutate support.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.8 | Protection against malicious software |
| **NIST 800-53** | SI-3 | Malicious code protection |
| **CISA SCuBA** | GWS.GMAIL.5.1v1–5.5v1 | Attachment protections |

---

### 2.3 Enable Link and External Image Protection

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.3 |
| NIST 800-53 | SI-3, SC-7 |
| CISA SCuBA | GWS.GMAIL.6.1v1–6.4v1 |

#### Description
Enable Gmail's link Safety protections: resolve shortened URLs, scan linked images, and warn on clicks to untrusted domains.

#### Rationale
**Why This Matters:**
- URL shorteners hide the true destination from both the user and any static reputation check at delivery time
- Linked images are fetched at open time and are a common tracking and payload-delivery channel that bypasses attachment scanning entirely
- The click-time warning is the last line of defense for links that were clean at delivery and weaponized afterwards

**Attack Prevented:** Credential-harvesting phishing via obfuscated shortened URLs and delayed-weaponization (time-of-click) link attacks

#### ClickOps Implementation

**Step 1: Enable Link Protections**
1. Navigate to: **Gmail** → **Safety** → **Links and external images**
2. Enable:
   - **Identify links behind shortened URLs**
   - **Scan linked images**
   - **Show warning prompt for any click on links to untrusted domains**
3. Check **Apply future recommended settings automatically**
4. Click **Save**

**Time to Complete:** ~10 minutes

#### Validation & Testing
1. Send a test with a shortened URL from an external account and confirm classification
2. Click an external-domain link in a delivered test message and confirm the warning prompt appears

**Expected result:** All link protections active. ([Advanced phishing and malware protection](https://knowledge.workspace.google.com/admin/gmail/advanced/advanced-phishing-and-malware-protection))

> **Automation surface:** read-only via Policy API setting `gmail.links_and_external_images`; no mutate support.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.8 | Protection against malicious software |
| **NIST 800-53** | SI-3 | Malicious code protection |
| **CISA SCuBA** | GWS.GMAIL.6.1v1–6.4v1 | Links and external images protections |

---

### 2.4 Turn On Enhanced Pre-Delivery Message Scanning

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.7 |
| NIST 800-53 | SI-3 |
| CISA SCuBA | GWS.GMAIL.15.1v1 |

#### Description
Enable enhanced pre-delivery scanning so Gmail briefly delays suspicious messages while additional phishing analysis completes before delivery.

#### Rationale
**Why This Matters:**
- Without it, borderline messages are delivered first and analyzed later, leaving a window where the user can act on the phish
- The added latency applies only to messages already flagged as suspicious, so the user-experience cost is negligible
- It closes the analysis gap that fast-moving phishing campaigns are engineered to exploit

**Attack Prevented:** Phishing delivered in the analysis gap before Gmail's classifiers reach a verdict

#### ClickOps Implementation

1. Navigate to: **Gmail** → **Spam, Phishing and Malware**
2. Select the top-level organization
3. Check **Enhanced pre-delivery message scanning**
4. Click **Save** and allow up to 24 hours

**Time to Complete:** ~5 minutes

#### Validation & Testing
1. Confirm the checkbox state after propagation
2. Monitor Gmail log events for pre-delivery classification outcomes

**Expected result:** Enhanced scanning active org-wide. ([Pre-delivery message scanning](https://knowledge.workspace.google.com/admin/security/help-prevent-phishing-with-pre-delivery-message-scanning))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.8 | Protection against malicious software |
| **NIST 800-53** | SI-3 | Malicious code protection |
| **CISA SCuBA** | GWS.GMAIL.15.1v1 | Enhanced pre-delivery scanning |

---

### 2.5 Enable Security Sandbox Virtual Execution

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.5 |
| NIST 800-53 | SI-3(1) |
| CISA SCuBA | GWS.GMAIL.16.1v1 |

#### Description
Enable Security Sandbox to detonate attachments (Office documents, PDFs, Windows executables) in a virtual environment before delivery, catching zero-day malware that signature scanning misses.

#### Rationale
**Why This Matters:**
- Sandbox detonation catches zero-day and previously unknown malware that signature-based antivirus misses
- The setting is OFF by default even on editions that include it
- Checking the box scans every attachment, superseding any narrower sandbox rules you may have configured

**Attack Prevented:** Zero-day and polymorphic malware delivery that evades signature-based attachment scanning

#### Prerequisites
- Editions: Frontline Plus, Business Standard/Plus, Enterprise Standard/Plus
- Tolerance for delivery delay of up to ~3 minutes on scanned attachments — flag for latency-sensitive mailflows

#### ClickOps Implementation

1. Navigate to: **Gmail** → **Spam, Phishing and Malware**
2. Select the organizational unit
3. In the **Security sandbox** section, check **Enable virtual execution of attachments in a sandbox environment**
4. Click **Save**

**Time to Complete:** ~10 minutes

#### Validation & Testing
1. Send a benign macro-bearing document and confirm delivery is briefly delayed and logged
2. Review Gmail log events for sandbox verdicts

**Expected result:** Attachments virtually executed before delivery in scoped OUs. ([Security sandbox rules](https://knowledge.workspace.google.com/admin/gmail/advanced/set-up-rules-to-detect-harmful-attachments))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.8 | Protection against malicious software |
| **NIST 800-53** | SI-3(1) | Central malicious-code management |
| **CISA SCuBA** | GWS.GMAIL.16.1v1 | Security sandbox |

---

## 3. Mail Flow & Compliance

### 3.1 Keep External Recipient Warnings Enabled

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 14.2 |
| NIST 800-53 | AC-4, AT-2 |
| CISA SCuBA | GWS.GMAIL.13.1v1 |

#### Description
Confirm the default-on external recipient warning stays enabled: Gmail banners threads that include recipients outside the organization and flags replies to external senders.

#### Rationale
**Why This Matters:**
- The warning catches the classic reply-all-to-the-wrong-recipient data leak before send
- It fires on replies to external senders — precisely the moment a thread-hijacking attacker is counting on the user not noticing a lookalike address
- It is ON by default, so the real control is detecting and reverting anyone who turned it off

**Attack Prevented:** Accidental data disclosure to external recipients and reply-chain hijacking via a lookalike address inserted into an existing thread

#### ClickOps Implementation

1. Navigate to: **Gmail** → **End User Access**
2. Optionally select an organizational unit
3. Scroll to **Warn for external recipients** and confirm the box is checked
4. Click **Save** (or **Override** for an OU; **Inherit** to restore)

**Time to Complete:** ~5 minutes

#### Validation & Testing
1. Compose a message to an external address and confirm the external label/banner appears
2. Alert on admin audit-log changes to this setting (SCuBA classifies this check as log-based)

**Expected result:** Warning enabled everywhere; changes alerted. ([External recipient warnings](https://knowledge.workspace.google.com/admin/gmail/advanced/control-gmail-external-recipient-warnings))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.7 | Restrict transmission of information |
| **NIST 800-53** | AC-4 | Information flow enforcement |
| **CISA SCuBA** | GWS.GMAIL.13.1v1 | Unintended external reply warning |

---

### 3.2 Eliminate Spam-Filter Bypass Lists and Email Allowlists

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.7 |
| NIST 800-53 | SI-8, CM-7 |
| CISA SCuBA | GWS.GMAIL.14.1v1, GWS.GMAIL.18.1v1–18.3v1 |

#### Description
Audit and remove IP allowlist entries and spam-filter bypasses. The SCuBA baseline (GWS.GMAIL.14.1v1) goes further: an email allowlist should not be implemented at all — allowlisted senders bypass spam filtering entirely.

#### Rationale
**Why This Matters:**
- Allowlisted senders bypass spam filtering ENTIRELY, so a single compromised partner domain on the list delivers phishing straight to inboxes with no scanning
- The "hide warnings" bypass variants suppress the visual cues users depend on, converting a partial control into a total blind spot
- Allowlists accumulate silently over years from one-off vendor troubleshooting tickets and are almost never reviewed

**Attack Prevented:** Phishing and malware delivery through a trusted-but-compromised third-party sender that has been exempted from filtering

#### ClickOps Implementation

**Step 1: Audit the Allowlist and Bypasses**
1. Navigate to: **Gmail** → **Spam, Phishing and Malware**
2. Open **Email allowlist** and remove IP addresses not strictly required
3. Open the **Spam** setting and audit every bypass checkbox:
   - **Bypass spam filters for internal senders**
   - **Bypass spam filters for messages from senders or domains in selected lists**
   - **Bypass spam filters and hide warnings for messages from senders or domains in selected lists**
   - **Bypass spam filters and hide warnings for all messages from internal and external senders**
4. Uncheck every bypass you cannot individually justify — particularly the last one

**Step 2: Tighten Filtering**
1. Enable **Be more aggressive when filtering spam** and **Put spam in administrative quarantine** where appropriate
2. Configure **Blocked senders** for known-bad addresses and domains
3. Click **Save**

> **Documented gotchas:** the email allowlist applies organization-wide and cannot be scoped to an OU; an IP already present in an inbound gateway configuration will silently fail to be added to the allowlist.

**Time to Complete:** ~45 minutes

#### Validation & Testing
1. Confirm the allowlist is empty (or each entry has a written justification and owner)
2. Confirm the "hide warnings for all messages" bypass is unchecked
3. Re-review quarterly

**Expected result:** No unjustified bypasses; SCuBA-aligned allowlist posture. ([IP allowlists](https://knowledge.workspace.google.com/admin/gmail/advanced/add-ip-addresses-to-allowlists-in-gmail) · [Custom spam filters](https://knowledge.workspace.google.com/admin/gmail/advanced/add-custom-spam-filters-to-gmail))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | Boundary protection |
| **NIST 800-53** | SI-8 | Spam protection |
| **CISA SCuBA** | GWS.GMAIL.14.1v1, 18.1v1–18.3v1 | Allowlist prohibition; spam filtering |

---

### 3.3 Configure Administrative Quarantines with Named Reviewers

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 17.4 |
| NIST 800-53 | IR-4, SI-3 |

#### Description
Create administrative quarantines with a named reviewers group and deliberate denial consequences, then reference them from Safety and Compliance rules. Quarantine is the destination that makes every other detection control operationally sustainable.

#### Rationale
**Why This Matters:**
- Without a quarantine, your only rule actions are deliver-with-warning or silently reject
- A reviewers group creates accountable ownership; an unmonitored quarantine becomes a black hole that generates pressure to disable the control
- Denial consequences decide whether a blocked sender learns their message was rejected — an operational-security decision worth making deliberately

**Attack Prevented:** Not an attack class itself — the containment and review capability that prevents detection controls from being rolled back under user pressure

#### ClickOps Implementation

1. Navigate to: **Gmail** → **Manage quarantines**
2. Click **Add Quarantine**; set Name, Description, and a **Quarantine reviewers group**
3. Set **Inbound denial consequence** and **Outbound denial consequence** (Drop message, or Send the default reject message)
4. Optionally enable periodic admin notifications and click **Save**
5. Reference the quarantine from Attachment compliance, Content compliance, Objectionable content, Routing, and Spam settings

> Requires super administrator sign-in.

**Time to Complete:** ~30 minutes

#### Validation & Testing
1. Trigger a quarantine-routed rule with a test message and confirm it appears in the quarantine queue
2. Confirm the reviewers group receives notifications and can release/deny

**Expected result:** Named-owner quarantines wired into every detection rule. ([Email quarantine](https://knowledge.workspace.google.com/admin/gmail/advanced/set-up-email-quarantine))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.4 | Incident containment |
| **NIST 800-53** | IR-4 | Incident handling |

---

### 3.4 Block Dangerous File Types with Attachment Compliance

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.6 |
| NIST 800-53 | SI-3, CM-7 |

#### Description
Create Attachment compliance rules that block container and shortcut formats (ISO, IMG, LNK, HTM) Google's default blocklist doesn't cover. Gmail matches on true file type, so renaming a payload does not evade the rule.

#### Rationale
**Why This Matters:**
- Gmail detects TRUE file type rather than trusting the extension, so renamed payloads are still caught
- Google's built-in blocked-file-type list does not cover organization-specific risks such as `.iso`, `.img`, `.lnk`, or `.htm` containers used to bypass mark-of-the-web
- Rules can differ for inbound versus outbound, letting you block risky inbound types while permitting them internally

**Attack Prevented:** Malware delivery via container and shortcut file formats (ISO, IMG, LNK, HTML smuggling) that evade default blocklists

#### ClickOps Implementation

1. Navigate to: **Gmail** → **Compliance**; point at **Attachment compliance** and click **Configure**
2. Select which messages the rule affects — inbound, outbound, or internal
3. Add up to 10 expressions matching on **file type** (predefined or custom comma-separated extensions), **file name**, or **message size**
4. Choose the action: **Reject**, **Quarantine**, or **Modify** (strip attachment, add header, reroute)
5. Use **Show options** to scope by address list, account type, or envelope filter
6. Click **Save**

**Time to Complete:** ~45 minutes

#### Validation & Testing
1. Send a renamed test file of a blocked type from an external account and confirm rejection/quarantine
2. Review quarantine queue and rule-match counts after one week

**Expected result:** Organization-specific dangerous types blocked with true-type matching. ([Attachment compliance](https://knowledge.workspace.google.com/admin/gmail/advanced/filter-messages-with-attachments))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.8 | Protection against malicious software |
| **NIST 800-53** | CM-7 | Least functionality |

---

### 3.5 Configure Content Compliance and Objectionable Content Rules

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.13 |
| NIST 800-53 | AC-4, SC-8 |

#### Description
Use Content compliance (body + text-attachment scanning with predefined regulated-data detectors) and Objectionable content rules to catch outbound sensitive data and inbound malicious patterns, feeding modifications (headers, subject prefixes) to downstream tooling.

#### Rationale
**Why This Matters:**
- Content compliance scans message bodies AND text attachments including `.docx`, `.xlsx`, and `.pdf` — the mechanism for catching outbound data lighter tooling misses
- Predefined content match supplies ready-made detectors for regulated data, so you are not hand-writing regexes for card numbers or national IDs
- Delivery modifications (headers, subject prefixes) are how you feed a downstream SIEM or gateway a reliable signal

**Attack Prevented:** Outbound data exfiltration and regulated-data leakage over email, plus inbound delivery of known-malicious content patterns

#### ClickOps Implementation

**Step 1: Content Compliance**
1. Navigate to: **Gmail** → **Compliance** → **Content compliance** → **Configure**
2. Select inbound/outbound/internal; add up to 10 expressions using **Simple**, **Advanced**, **Metadata**, or **Predefined content match**
3. Set the action: **Reject**, **Quarantine**, or **Deliver with modifications**

**Step 2: Objectionable Content**
1. On the same Compliance page, configure **Objectionable content**: name the rule, choose message type, check **Custom objectionable words** and enter comma-separated terms
2. Choose Reject, Quarantine, or Modify; click **Save** and allow up to 24 hours

> **Documented limitation:** objectionable-content matching is single-word and complete-word only, case-insensitive, and applies only to subject, body, and text attachments — it is not a substring or phrase engine.

**Time to Complete:** ~1 hour

#### Validation & Testing
1. Send a test containing a predefined-detector pattern (test card number) outbound and confirm the rule action fires
2. Confirm modified messages carry the expected header/subject marker in the receiving system

**Expected result:** Regulated-data patterns actioned; downstream signal wired. ([Content compliance](https://knowledge.workspace.google.com/admin/gmail/advanced/set-up-rules-for-advanced-email-content-filtering) · [Objectionable content](https://knowledge.workspace.google.com/admin/gmail/advanced/control-message-delivery-based-on-message-content))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.7 | Restrict transmission of information |
| **NIST 800-53** | AC-4 | Information flow enforcement |

---

## 4. Access & Forwarding

### 4.1 Restrict Third-Party App Access to Gmail Data

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | AC-3, CM-7 |

#### Description
Gmail OAuth scopes are classified RESTRICTED — any app granted them can read, search, and export an entire mailbox continuously. Set unconfigured third-party apps to blocked or basic sign-in only, and explicitly trust only vetted apps. This is the platform-wide API-controls surface applied with Gmail scopes in mind.

#### Rationale
**Why This Matters:**
- The default posture allows every unconfigured third-party app — a user consent prompt is the only thing standing between a malicious app and your mail
- OAuth grants SURVIVE password resets; revoking app access is a separate incident-response action from credential rotation
- Consent-phishing campaigns specifically target Gmail's restricted scopes for persistent, invisible exfiltration

**Attack Prevented:** Consent-phishing (illicit OAuth grant) leading to persistent mailbox exfiltration that survives password changes

#### ClickOps Implementation

1. Navigate to: **Admin console** → **Security** → **Access and data control** → **API controls**
2. Under **Unconfigured third-party apps**, change **Allow all access** to **Allow basic sign-in only** or **Block all access**
3. Click **Manage App Access**; for each business-required app set **Trusted**, **Limited**, **Specific Google data**, or **Blocked**
4. Scope decisions to the appropriate organizational units; click **Save** and allow up to 24 hours

> Platform-wide control — see the [Google Workspace guide's OAuth app allowlisting](/guides/google-workspace/#31-enable-oauth-app-whitelisting) for the full workflow; this control is listed here because Gmail's restricted scopes are the highest-value target.

**Time to Complete:** ~1 hour initial triage

#### Validation & Testing
1. As a standard user, attempt to authorize a non-allowlisted app requesting Gmail scopes — consent should be blocked
2. Review existing grants for Gmail restricted scopes and revoke unjustified ones

**Expected result:** No unvetted app can obtain Gmail scopes. ([Control app access](https://knowledge.workspace.google.com/admin/apps/control-which-apps-access-google-workspace-data))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.3 | Access authorization |
| **NIST 800-53** | AC-3 | Access enforcement |

---

### 4.2 Disable POP and IMAP Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.8 |
| NIST 800-53 | AC-17, IA-2 |
| CISA SCuBA | GWS.GMAIL.9.1v1 |

#### Description
Disable POP and IMAP for all users, or where desktop clients are genuinely required, restrict IMAP to enumerated OAuth client IDs only.

#### Rationale
**Why This Matters:**
- Legacy mail protocols are the standard path for attackers using stolen credentials, because many such clients do not enforce or trigger MFA
- POP and IMAP sessions bypass most of Gmail's in-client protections and produce thinner telemetry than web or Gmail-app access
- The OAuth-client restriction is the middle path when a business unit cannot move off desktop clients — access continues but only from enumerated, revocable client IDs

**Attack Prevented:** Account takeover and mailbox exfiltration via legacy-protocol authentication that circumvents MFA

#### ClickOps Implementation

1. Navigate to: **Gmail** → **End User Access**
2. Optionally select an organizational unit
3. Under **POP and IMAP access**, uncheck **Enable POP access for all users** and **Enable IMAP access for all users**
4. If IMAP is genuinely required: leave it enabled but select **Restrict which mail clients users can use (OAuth mail clients only)** and enter the permitted OAuth client IDs
5. Click **Save**

**Time to Complete:** ~15 minutes

#### Validation & Testing
1. Attempt an IMAP connection as a standard user — it should fail (or succeed only from a permitted OAuth client)
2. Audit via Policy API read (`gmail.pop_access`, `gmail.imap_access`)

**Expected result:** Legacy protocols disabled or OAuth-client-restricted. ([POP and IMAP settings](https://knowledge.workspace.google.com/admin/sync/turn-pop-and-imap-on-or-off-for-users))

> **Automation surface:** read-only via Policy API settings `gmail.pop_access` and `gmail.imap_access`; audit via API, change in console.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | Boundary protection |
| **NIST 800-53** | AC-17 | Remote access |
| **CISA SCuBA** | GWS.GMAIL.9.1v1 | POP/IMAP disabled |

---

### 4.3 Disable User-Configured Automatic Forwarding

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.8 |
| NIST 800-53 | AC-4, SI-4 |
| CISA SCuBA | GWS.GMAIL.11.1v1 |

#### Description
Remove the ability for users to create automatic forwarding rules to external addresses. Auto-forward creation is the single most common post-compromise persistence action, and it survives credential resets.

#### Rationale
**Why This Matters:**
- An attacker-created auto-forward silently exfiltrates every future message even after the password is rotated
- Turning this off removes the forwarding option from the user's Gmail settings entirely, so the rule cannot be created in the first place
- Users can still forward individual messages manually, so the business impact is far smaller than admins expect

**Attack Prevented:** Post-compromise persistence and silent long-term mailbox exfiltration via attacker-created auto-forward rules

#### ClickOps Implementation

1. Navigate to: **Gmail** → **End User Access**
2. Optionally select an organizational unit
3. Click **Automatic forwarding** and uncheck **Allow users to automatically forward email to another address**
4. Click **Save**

> Requires the Gmail Settings administrator privilege.

**Time to Complete:** ~5 minutes

#### Validation & Testing
1. As a standard user, open Gmail Settings → Forwarding — the add-forwarding option should be absent
2. Alert on Gmail log events for forwarding-rule creation in any OU where it remains enabled

**Expected result:** User auto-forwarding unavailable org-wide (or justified per-OU). ([Automatic forwarding](https://knowledge.workspace.google.com/admin/gmail/let-users-automatically-forward-their-own-gmail-emails))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.7 | Restrict transmission of information |
| **NIST 800-53** | AC-4 | Information flow enforcement |
| **CISA SCuBA** | GWS.GMAIL.11.1v1 | Automatic forwarding disabled |

---

## 5. Monitoring & Encryption

### 5.1 Enable Comprehensive Mail Storage and Monitor Gmail Log Events

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 8.9 |
| NIST 800-53 | AU-2, AU-6, AU-11 |
| CISA SCuBA | GWS.GMAIL.17.1v1 |

#### Description
Enable comprehensive mail storage so every sent/received message (including service-generated mail) is stored in associated mailboxes for Vault and eDiscovery, and operationalize Gmail log events for detection — with BigQuery export for long-horizon hunting.

#### Rationale
**Why This Matters:**
- Comprehensive mail storage captures messages that never reach a Gmail mailbox otherwise — including mail generated by Calendar, Drive, Docs, Forms, and Keep — without it, Vault holds and eDiscovery have gaps
- Gmail log events expose 30+ searchable attributes (sender, recipient, attachment details, spam classification, source IP, malware verdicts) and support direct response actions (delete, mark as phishing, quarantine)
- The investigation tool's default view covers only the LAST 7 DAYS — shorter than most detection timelines; BigQuery export makes long-horizon correlation possible

**Attack Prevented:** Not preventive — the detection, investigation, and legal-hold capability that makes email compromise discoverable and reconstructable

#### ClickOps Implementation

**Step 1: Comprehensive Mail Storage**
1. Navigate to: **Gmail** → **Compliance**
2. Select the organization; check **Ensure that a copy of all sent and received mail is stored in associated users' mailboxes**
3. Click **Save**

**Step 2: Gmail Log Events**
1. Navigate to: **Reporting** → **Audit and investigation** → **Gmail log events**
2. Widen or remove the default 7-day date filter
3. Build saved investigations for malware detections, spam classifications by sender, and attachment activity

**Step 3: BigQuery Export (recommended)**
1. Navigate to: **Reporting** → **Data integrations**
2. On the **BigQuery Export** card, click **Edit** and enable export to a billing-enabled BigQuery project (editions: Frontline Standard/Plus, Enterprise Standard/Plus, Education Standard/Plus, Enterprise Essentials Plus; activity logs land within ~10 minutes)

**Time to Complete:** ~1 hour

#### Validation & Testing
1. Confirm a Calendar-generated notification appears in the associated mailbox after enabling storage
2. Query Gmail activity via Admin SDK Reports API: `GET https://admin.googleapis.com/admin/reports/v1/activity/users/all/applications/gmail` — note both `startTime` and `endTime` are mandatory for Gmail and the range cannot exceed 30 days
3. Confirm BigQuery tables receive Gmail activity rows

**Expected result:** Complete mail capture; log events queryable beyond the 7-day window. ([Comprehensive mail storage](https://knowledge.workspace.google.com/admin/gmail/advanced/set-up-comprehensive-mail-storage) · [Gmail log events](https://knowledge.workspace.google.com/admin/reports/gmail-log-events) · [BigQuery export](https://knowledge.workspace.google.com/admin/reports/set-up-service-log-exports-to-bigquery))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | System monitoring |
| **NIST 800-53** | AU-2 | Event logging |
| **CISA SCuBA** | GWS.GMAIL.17.1v1 | Comprehensive mail storage |

---

### 5.2 Govern Confidential Mode and Enable Hosted S/MIME

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | SC-8, SC-13 |

#### Description
Make a deliberate policy decision on Gmail confidential mode (which is NOT encryption and creates archiving gaps), and enable Hosted S/MIME where regulated communications need real cryptographic signing and encryption.

#### Rationale
**Why This Matters:**
- Confidential mode is not an encryption control and Google says so directly: users can still copy or download content with third-party applications
- Confidential mode transmits only a subject line and a link over SMTP, so third-party archiving captures nothing of substance — a real compliance and eDiscovery gap unless Vault covers both parties
- Hosted S/MIME provides actual cryptographic signing and encryption; enabling it at the top-level organization is a prerequisite for the advanced root-certificate controls

**Attack Prevented:** Message interception and sender-identity forgery in regulated communications (S/MIME); for confidential mode, prevention of a false-assurance compliance gap rather than an external attack

#### Prerequisites
- S/MIME editions: Frontline Plus, Enterprise Plus, Education Fundamentals/Standard/Plus
- Certificate issuance process for users (or admin-uploaded certificates)

#### ClickOps Implementation

**Step 1: Decide Confidential Mode Posture**
1. Navigate to: **Gmail** → **User settings**
2. Select the organizational unit; check or uncheck **Enable confidential mode** according to your archiving posture
3. Click **Save**

**Step 2: Enable Hosted S/MIME**
1. On the same **User settings** page, select the TOP-LEVEL organization
2. Check **Enable S/MIME encryption for sending and receiving emails**
3. Optionally check **Allow users to upload their own certificates**
4. Optionally add root certificates for specific domains (**Accept these additional Root Certificates for specific domains**), choosing the encryption level
5. Leave **Allow SHA-1 globally (not recommended)** UNCHECKED
6. Click **Save**

**Time to Complete:** ~30 minutes plus certificate rollout

#### Validation & Testing
1. Exchange a signed/encrypted message between two S/MIME-enabled users and confirm the lock/signature indicators
2. If confidential mode is allowed: confirm your archiving/Vault strategy actually captures both sides of confidential threads

**Expected result:** Deliberate confidential-mode posture; S/MIME live for regulated flows. ([Confidential mode](https://knowledge.workspace.google.com/admin/gmail/advanced/protect-gmail-messages-with-confidential-mode) · [Hosted S/MIME](https://knowledge.workspace.google.com/admin/gmail/advanced/turn-on-hosted-s-mime-for-message-encryption))

> **Automation surface:** read-only via Policy API settings `gmail.confidential_mode`, `gmail.smime_encryption`, `gmail.enhanced_smime_encryption`; no mutate support.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.7 | Transmission protection |
| **NIST 800-53** | SC-8, SC-13 | Transmission confidentiality; cryptographic protection |

---

## 6. Compliance Quick Reference

### CISA SCuBA Gmail Baseline Mapping

The [SCuBA Gmail baseline](https://github.com/cisagov/ScubaGoggles/blob/main/scubagoggles/baselines/gmail.md) is this guide's primary authoritative mapping; the [ScubaGoggles](https://github.com/cisagov/ScubaGoggles) tool assesses these policies programmatically. Many carry binding CISA BOD 25-01 requirements for US federal agencies.

| SCuBA Policy | Guide Section |
|--------------|---------------|
| GWS.GMAIL.2 (DKIM) | [1.2](#12-enable-dkim-signing-with-a-2048-bit-key) |
| GWS.GMAIL.3 (SPF) | [1.1](#11-publish-an-spf-record-for-every-sending-domain) |
| GWS.GMAIL.4 (DMARC) | [1.3](#13-publish-and-enforce-a-dmarc-policy) |
| GWS.GMAIL.5 (Attachment Protections) | [2.2](#22-enable-attachment-protection-against-encrypted-script-bearing-and-anomalous-files) |
| GWS.GMAIL.6 (Links & External Images) | [2.3](#23-enable-link-and-external-image-protection) |
| GWS.GMAIL.7 (Spoofing & Authentication) | [2.1](#21-enable-all-spoofing-and-authentication-protections) |
| GWS.GMAIL.9 (POP/IMAP) | [4.2](#42-disable-pop-and-imap-access) |
| GWS.GMAIL.11 (Automatic Forwarding) | [4.3](#43-disable-user-configured-automatic-forwarding) |
| GWS.GMAIL.13 (External Reply Warning) | [3.1](#31-keep-external-recipient-warnings-enabled) |
| GWS.GMAIL.14 (Email Allowlist) | [3.2](#32-eliminate-spam-filter-bypass-lists-and-email-allowlists) |
| GWS.GMAIL.15 (Pre-Delivery Scanning) | [2.4](#24-turn-on-enhanced-pre-delivery-message-scanning) |
| GWS.GMAIL.16 (Security Sandbox) | [2.5](#25-enable-security-sandbox-virtual-execution) |
| GWS.GMAIL.17 (Comprehensive Mail Storage) | [5.1](#51-enable-comprehensive-mail-storage-and-monitor-gmail-log-events) |
| GWS.GMAIL.18 (Spam Filtering) | [3.2](#32-eliminate-spam-filter-bypass-lists-and-email-allowlists) |

### SOC 2 Trust Services Criteria Mapping

| Control ID | Gmail Control | Guide Section |
|-----------|---------------|---------------|
| CC6.6 | Email authentication (SPF/DKIM/DMARC) | [1.1](#11-publish-an-spf-record-for-every-sending-domain)–[1.3](#13-publish-and-enforce-a-dmarc-policy) |
| CC6.8 | Phishing & malware protections | [2.1](#21-enable-all-spoofing-and-authentication-protections)–[2.5](#25-enable-security-sandbox-virtual-execution) |
| CC6.7 | Data-flow restriction | [3.5](#35-configure-content-compliance-and-objectionable-content-rules), [4.3](#43-disable-user-configured-automatic-forwarding) |
| CC7.2 | Monitoring | [5.1](#51-enable-comprehensive-mail-storage-and-monitor-gmail-log-events) |

> **CIS note:** a CIS Google Workspace Foundations Benchmark (v1.3.0) exists but its Gmail section numbering could not be verified against the PDF at authoring time — SCuBA is used as the primary mapping. Do not add specific CIS Gmail control numbers without confirming them against the downloaded benchmark.

---

## Appendix A: Edition Compatibility

| Control | Business Starter | Business Standard/Plus | Enterprise Standard/Plus |
|---------|------------------|------------------------|--------------------------|
| SPF / DKIM / DMARC | ✅ | ✅ | ✅ |
| Safety settings (2.1–2.3) | ✅ | ✅ | ✅ |
| Enhanced pre-delivery scanning | ✅ | ✅ | ✅ |
| Security sandbox | ❌ | ✅ (Standard/Plus) | ✅ |
| Compliance & quarantine rules | ✅ | ✅ | ✅ |
| BigQuery log export | ❌ | ❌ | ✅ |
| Hosted S/MIME | ❌ | ❌ | ✅ (Enterprise Plus) |

---

## Appendix B: References

**Official Google Workspace Admin Documentation** (Google migrated Workspace admin docs from support.google.com/a to knowledge.workspace.google.com — cite the new host):
- [Set up SPF](https://knowledge.workspace.google.com/admin/security/set-up-spf)
- [Set up DKIM](https://knowledge.workspace.google.com/admin/security/set-up-dkim)
- [Set up DMARC](https://knowledge.workspace.google.com/admin/security/set-up-dmarc)
- [Advanced phishing and malware protection](https://knowledge.workspace.google.com/admin/gmail/advanced/advanced-phishing-and-malware-protection)
- [Email quarantine](https://knowledge.workspace.google.com/admin/gmail/advanced/set-up-email-quarantine)
- [Attachment compliance](https://knowledge.workspace.google.com/admin/gmail/advanced/filter-messages-with-attachments)
- [Content compliance](https://knowledge.workspace.google.com/admin/gmail/advanced/set-up-rules-for-advanced-email-content-filtering)
- [Comprehensive mail storage](https://knowledge.workspace.google.com/admin/gmail/advanced/set-up-comprehensive-mail-storage)
- [Gmail log events](https://knowledge.workspace.google.com/admin/reports/gmail-log-events)
- [BigQuery log export](https://knowledge.workspace.google.com/admin/reports/set-up-service-log-exports-to-bigquery)

**Hardening Baselines:**
- [CISA SCuBA Gmail baseline (ScubaGoggles)](https://github.com/cisagov/ScubaGoggles/blob/main/scubagoggles/baselines/gmail.md) — primary mapping, with the [ScubaGoggles assessment tool](https://github.com/cisagov/ScubaGoggles)
- [CIS Google Workspace Foundations Benchmark](https://www.cisecurity.org/benchmark/google_workspace)

**API Documentation:**
- [Admin SDK Reports API — Gmail activity events](https://developers.google.com/workspace/admin/reports/v1/appendix/activity/gmail)
- [Cloud Identity Policy API supported settings](https://docs.cloud.google.com/identity/docs/concepts/supported-policy-api-settings) — eight Gmail settings, all read-only

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-03 | 0.1.0 | ai-drafted | Authored the full Gmail control set: 18 controls across email authentication (SPF/DKIM/DMARC), Safety protections, mail-flow compliance, access & forwarding lockdown, and monitoring/encryption — each verified against Google's live admin documentation and mapped to CISA SCuBA GWS.GMAIL policy IDs. Replaces the placeholder. | Claude Code (Sonnet 5) † |
| 2026-05-29 | 0.0.1 | ai-drafted | Created Gmail product placeholder as part of the Google Workspace multi-product platform restructure. | Jai (PAI) |

> † Author **inferred**, not recorded. This row predates the Author column, so the value comes from the authoring session's commit window (every other guide authored in that window names the same tool and model, with no dissenting entry). Undaggered rows are attributed from a sibling guide that recorded its author explicitly in the same commit, or from the row's own text.


## Contributing

Want to improve the Gmail control set? Open an issue or PR on [GitHub](https://github.com/grcengineering/how-to-harden). Follow the control structure used in the [Google Chat](/guides/google-chat/) and [Google Drive](/guides/google-drive/) product guides, and keep all code in Code Packs (no inline code blocks). Note the pack-authoring caution: most Gmail settings have no write API — verification-style packs (ScubaGoggles, DNS checks, Reports API queries) are the honest automation surface.
