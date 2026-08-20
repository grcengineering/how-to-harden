---
layout: guide
title: "ADP Hardening Guide"
vendor: "ADP"
slug: "adp"
tier: "3"
category: "HR/Finance"
description: "Payroll platform security for federated SSO, security roles, registration codes, third-party delegations, and security reporting"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

ADP processes payroll for **640,000+ companies** worldwide with access to W-2 data, SSN, salary, and bank account information. The 2024 Broadcom/BSH breach and 2016 credential stuffing incident ("flowjacking") demonstrate partner ecosystem and registration code vulnerabilities. Regional partner compromise exposed employee data; attackers used stolen W-2 data for tax fraud.

### Intended Audience
- Security engineers managing payroll systems
- HR technology administrators
- GRC professionals assessing payroll compliance
- Third-party risk managers evaluating HR integrations

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers ADP security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API & Integration Security](#2-api--integration-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce MFA at the Identity Provider via Federated SSO

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Federate ADP access to your corporate identity provider and enforce multi-factor authentication there — ADP's administrator security console is built around federated SSO, not a tenant-level MFA switch.

#### Rationale
**Why This Matters:**
- ADP contains the highest-value PII an employer holds — SSN, wages, and direct-deposit bank details — and the payroll-fraud payoff makes these accounts a standing credential-theft target
- The 2016 "flowjacking" campaign against ADP customers ran on stolen credentials, which is precisely the step a second factor breaks
- Enforcing the second factor at the IdP means one policy covers ADP alongside the rest of your estate, and revoking the identity revokes ADP access with it
- Administrator and payroll-processor accounts can create users, reset passwords, and reach every employee record, so they warrant phishing-resistant factors rather than SMS or push

**Attack Prevented:** Credential stuffing, phishing, password reuse, administrator account takeover, payroll-redirect fraud following account compromise

**Real-World Incidents:**
- **2016 Flowjacking:** Attackers used stolen credentials and registration codes to steal W-2 data for tax fraud
- **2024 BSH Breach:** Regional partner compromise exposed Broadcom employee data

> **Correction — there is no native "Require MFA for all users" toggle.** Earlier revisions of this guide instructed administrators to enable ADP-native MFA at *Admin Portal → Security → Multi-Factor Authentication*. That path and that setting do not appear in ADP's administrator documentation: the [ADP Security Management Service online help](https://support.adp.com/netsecure/pages/pub/docs/9.0/en_us/ADP_Security_Management_OnlineHelp.pdf) contains no multi-factor, two-factor, or MFA guidance at all, while discussing federated single sign-on throughout. Administrators work in the **ADP Security Management Service** console at `netsecure.adp.com`; the multi-factor decision belongs to the identity provider that ADP federates to. If your ADP service or region offers additional authentication options, confirm them with ADP directly rather than assuming the toggle exists.

#### ClickOps Implementation

**Step 1: Federate ADP to Your Identity Provider**
1. Work with your ADP service team to enable federated single sign-on for your ADP services
2. Complete the SAML configuration on the IdP side (entity ID, ACS URL, certificate) as supplied by ADP

**Step 2: Enforce MFA in the Identity Provider**
1. Apply a conditional-access or authentication policy to the ADP application that requires MFA on every sign-in
2. Require phishing-resistant factors for practitioners holding elevated ADP security roles (see [1.2](#12-implement-role-based-access))
3. Confirm the policy has no exemption group that includes payroll or administrator accounts

**Step 3: Close the Non-Federated Paths**
1. Inventory accounts that can still authenticate to ADP outside the federated path and reduce them to a documented break-glass set
2. Apply the lockout, suspension, and password rules in [1.4](#14-verify-lockout-suspension-and-password-defaults) to whatever remains

#### Validation & Testing
- Attempt an ADP sign-in from an account subject to the IdP policy and confirm the second factor is demanded
- Confirm no exemption or bypass group in the IdP includes ADP administrators or payroll processors
- Re-verify after any change to your ADP service configuration

---

### 1.2 Implement Role-Based Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Assign ADP security roles against the platform's own six-role model, keeping the two roles that can create administrators and reset passwords to a named minimum, and layer payroll segregation of duties on top.

#### Rationale
**Why This Matters:**
- Payroll functions span sensitive operations — running payroll, changing tax withholding, and editing bank account details — that no single person should control end to end
- Segregation of duties ensures one individual cannot both create a fraudulent payee and approve payment to it
- Least-privilege roles confine each user to the data they need, so a compromised HR account cannot also manipulate payroll runs
- Dual approval on large payrolls and bank-account changes adds a human checkpoint against insider fraud and account takeover

**Attack Prevented:** Insider payroll fraud, privilege escalation, unauthorized bank-account redirection, fraudulent payee creation

#### ClickOps Implementation

**Step 1: Map Users to ADP's Security Role Model**

ADP's Security Management Service defines a fixed hierarchy of security roles rather than free-form custom roles. Assign against these, most privileged first:

| ADP Security Role | What it can do |
|-------------------|----------------|
| Security Master | The top of the hierarchy — full security administration, including creating and managing other administrators, resetting passwords, and adding third-party delegated access |
| Security Administrator | Administers users and security settings, including creating administrators, resetting passwords, and adding third-party delegated access |
| User Master | Manages users within its assigned scope; does **not** create administrators, reset administrator passwords, or add third-party delegates |
| User Administrator | Day-to-day user administration within a narrower scope |
| Product User | Uses the ADP products assigned to them; no security administration |
| Self Service User | Access to their own employee record only |

> **Only the top two roles carry the dangerous capabilities.** Creating or managing other administrators, resetting passwords, and adding third-party delegated access are confined to **Security Master** and **Security Administrator**. Everything below them can be handed out far more freely. Treat those two roles as your privileged tier: name every holder, keep the count minimal, and review it on a fixed cadence. Source: [ADP Security Management Service online help](https://support.adp.com/netsecure/pages/pub/docs/9.0/en_us/ADP_Security_Management_OnlineHelp.pdf).

1. Navigate to: **People → User Security Roles** to review and assign roles
2. Navigate to: **People → Manage Users** to review the user list and their assignments
3. Record every holder of Security Master and Security Administrator, with a business justification for each

**Step 2: Implement Segregation of Duties**
- Separate payroll setup from payroll approval
- Separate bank account changes from payroll processing
- Require dual approval for large payrolls
- Keep the security-administration tier (Security Master / Security Administrator) separate from the people who run payroll, so no single person can both grant themselves access and move money

#### Validation & Testing
- Pull the current role assignments from **People → User Security Roles** and confirm the Security Master / Security Administrator list matches your documented privileged-user register
- Confirm no ordinary payroll or HR practitioner holds either of the top two roles
- Re-verify after every joiner, mover, and leaver cycle

---

### 1.3 Require Personal Registration Codes and Identity Verification

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-4, IA-12

#### Description
Register employees for ADP self-service using personal, single-use registration codes bound to the individual rather than the single shared organization code, and enable the identity-verification settings that govern how registrants prove who they are.

#### Rationale
**Why This Matters:**
- An organization registration code is one string that unlocks self-service registration for anyone who knows it — this is the exact registration weakness behind the 2016 "flowjacking" campaign, where attackers registered accounts on behalf of employees who had not yet claimed theirs and harvested their W-2 data
- Personal registration codes are issued to a named individual, expire on first use or after roughly 15 days, and arrive from ADP's `SecurityServices_NoReply@adp.com` sender — a code that only works once, only for one person, and only briefly is a far smaller target than a standing shared secret
- ADP itself marks the personal-code option "(Recommended)" over the shared organization code
- Identity verification adds a second gate: a registrant who fails the public-records identity questions is locked out of registration, and only an administrator-issued personal code releases them — which converts a failed impersonation attempt into an administrator-visible event
- Terminated employees still need access to W-2s; issuing them personal codes is what avoids leaving the shared organization code in circulation as the alumni access path

**Attack Prevented:** Fraudulent self-service registration ("flowjacking"), W-2 and tax-refund fraud, account pre-registration by an attacker, shared-secret abuse by former employees

**Real-World Incidents:**
- **2016 Flowjacking:** Attackers combined stolen personal data with publicly circulating registration codes to register accounts and steal W-2 data for tax fraud at multiple ADP customer companies

#### ClickOps Implementation

**Step 1: Turn On Personal-Code Enforcement**
1. Navigate to: **Setup → Profile → Identity Verification**
2. Enable the option requiring personal registration codes for new registrants, in place of the shared organization code
3. Enable the option that issues registration codes to terminated employees, so alumni W-2 access does not depend on the shared code

**Step 2: Issue and Track Personal Codes**
1. Navigate to: **People → Personal Registration Codes** to issue codes to named individuals
2. Communicate that codes arrive from `SecurityServices_NoReply@adp.com`, expire on first use or after roughly 15 days, and should never be forwarded
3. Re-issue rather than extend when a code lapses

**Step 3: Handle Identity-Verification Failures as Security Events**
1. Treat a registrant locked out by failed identity questions as a potential impersonation attempt, not merely a helpdesk ticket
2. Verify the person's identity out of band before issuing the administrator-issued personal code that unlocks registration

#### Validation & Testing
- Attempt a self-service registration using the organization code and confirm it is refused once personal-code enforcement is on
- Confirm an issued code stops working after first use
- Review the log of administrator-issued codes for unlock requests against your out-of-band verification records

---

### 1.4 Verify Lockout, Suspension, and Password Defaults

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-7, AC-2(3), IA-5(1)

#### Description
Confirm and document ADP's account lockout, inactivity-suspension, deletion, and password rules so your access reviews and offboarding process are built on the platform's actual behaviour rather than assumptions.

#### Rationale
**Why This Matters:**
- These rules are platform behaviour, not switches you configure — an offboarding process that assumes an unused account disappears immediately, or that a locked account stays locked, will be wrong in ways that only surface during an audit or an incident
- Lockout on repeated bad passwords is the control that blunts password guessing against accounts that are not behind the identity provider; knowing the threshold tells you how much guessing an attacker gets per account
- The inactivity-suspension and deletion windows tell you the real maximum lifetime of a forgotten account, which is what your dormant-account review needs to beat
- Documented password composition and expiry rules let you show an auditor what the platform enforces and where your identity provider has to make up the difference

**Attack Prevented:** Password guessing against non-federated accounts, dormant-account abuse, unmonitored stale administrator access, offboarding gaps

> **Documented platform behaviour — verify against your own service.** ADP's Security Management Service documents a lockout after **3** consecutive bad passwords with a roughly **5-minute** lock (a fourth failure on an administrator account requires an administrator reset); inactivity suspension for administrators after roughly **15 days** with no login from account creation, **365 days** from last login, or **15 days** with an unused temporary password, and for self-service users after roughly **480 / 480 / 30 days** on the same three conditions; and deletion roughly **180 days** after suspension. The documented password policy is **8–64** characters with at least **two** character classes, no more than **3** repeated or sequential characters, no user ID, name, or SSN content, a **4**-password history, and a **180-day** expiry. Confirm the values that apply to your ADP service before writing them into a control document. Source: [ADP Security Management Service online help](https://support.adp.com/netsecure/pages/pub/docs/9.0/en_us/ADP_Security_Management_OnlineHelp.pdf).

#### ClickOps Implementation

**Step 1: Align Your Reviews to the Real Windows**
1. Set your dormant-account review cadence shorter than the suspension window that applies to your user population, so you catch stale access before the platform does
2. Record the deletion window in your evidence-retention plan — a deleted account takes its administrative trail out of the live console

**Step 2: Make Offboarding Explicit**
1. Remove access deliberately at **People → Manage Users** rather than relying on inactivity suspension
2. Where terminated employees retain W-2 access, use the personal registration codes in [1.3](#13-require-personal-registration-codes-and-identity-verification)

**Step 3: Close the Gap at the Identity Provider**
1. Where the documented ADP password rules are weaker than your corporate standard, enforce the stronger standard at the identity provider ([1.1](#11-enforce-mfa-at-the-identity-provider-via-federated-sso))
2. Monitor administrator password resets as privileged activity

#### Validation & Testing
- Confirm your dormant-account review interval is shorter than the applicable suspension window
- Confirm terminated users are removed explicitly rather than left to age out
- Spot-check that administrator password resets appear in your privileged-activity review

---

## 2. API & Integration Security

### 2.1 Govern Third-Party Delegated Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, PS-7, SR-3

#### Description
Treat ADP's Delegations feature — the mechanism by which an outside firm is granted access to your ADP data — as a privileged-access decision with a named owner, a documented business reason, and a recurring review.

#### Rationale
**Why This Matters:**
- Delegated third parties read the same W-2, salary, SSN, and bank data your own staff do, so a delegation is functionally an account handed to another company's security programme
- The 2024 BSH compromise is exactly this failure mode: a regional ADP partner was breached by ransomware and employee payroll data was exposed even though ADP itself was not breached — the exposure travelled through the partner relationship
- Adding a third party is confined to the **Security Master** and **Security Administrator** roles ([1.2](#12-implement-role-based-access)), which means the control is enforceable: a short, named list of people can create this exposure
- Delegations do not expire on their own — an accountant, benefits broker, or consultancy engaged years ago retains access until somebody removes it, so periodic review is the only thing that ends them

**Attack Prevented:** Third-party partner compromise, standing access by disengaged vendors, bulk PII exfiltration through a delegated firm, unreviewed privileged grants

> **Correction — this is delegation, not OAuth scoping.** Earlier revisions of this guide described limiting "OAuth scopes" for ADP Marketplace integrations under an *Admin Portal → Integrations* path. ADP's administrator documentation describes third-party access through **Delegations**: a third party is added by their **client ID**, access is expressed through **Delegated Service Profiles**, and only the Security Master and Security Administrator roles may do it. Govern the delegation, not an imagined scope picker. Source: [ADP Security Management Service online help](https://support.adp.com/netsecure/pages/pub/docs/9.0/en_us/ADP_Security_Management_OnlineHelp.pdf).

#### ClickOps Implementation

**Step 1: Inventory Existing Delegations**
1. Navigate to: **Setup → Delegations**
2. List every delegated third party, the client ID used to add them, and the Delegated Service Profile assigned
3. Record a named internal owner and the business reason for each — any delegation without both is a candidate for removal

**Step 2: Constrain New Delegations**
1. Confirm only Security Master and Security Administrator holders can add delegations, and keep that list minimal ([1.2](#12-implement-role-based-access))
2. Require a documented approval before a delegation is created, and assign the narrowest Delegated Service Profile that supports the engagement

**Step 3: Review and Revoke**
1. Re-review every delegation on a fixed cadence and immediately at contract end
2. Revoke on notification of a partner security incident, then re-establish deliberately rather than leaving access live during the partner's investigation

#### Validation & Testing
- Reconcile the **Setup → Delegations** list against your active third-party contracts; investigate every entry with no matching contract
- Confirm each delegation's owner can state what the third party does with the access
- Confirm your vendor-incident runbook names ADP delegation revocation as a step

---

## 3. Data Security

### 3.1 Protect W-2 and Tax Data

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Implement controls to prevent W-2 data theft.

#### Rationale
**Why This Matters:**
- W-2 forms contain the SSN, wages, and address an attacker needs to file fraudulent tax returns and claim refunds in an employee's name
- The 2016 "flowjacking" attack stole W-2 data through the self-service registration workflow and used it for tax-refund fraud
- Restricting W-2 access to authorized personnel and alerting on generation and download limits both insider abuse and credential-theft impact
- Heightened auditing during tax season catches abnormal access patterns when W-2 fraud risk peaks

**Attack Prevented:** W-2 theft, tax-refund fraud, identity theft, unauthorized PII access

#### Implementation

1. Restrict W-2 access to authorized personnel only
2. Enable alerts for W-2 generation and download
3. Audit W-2 access during tax season
4. Configure fraud alerts for unusual W-2 patterns

---

## 4. Monitoring & Detection

### 4.1 Run and Retain the ADP Security Reports

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-6, AU-11

#### Description
Run ADP's built-in security reports on a schedule, export them promptly, and retain the exports yourself — ADP's security audit surface is scheduled reporting, not a streaming event feed.

#### Rationale
**Why This Matters:**
- Security oversight of ADP depends on someone actually running and reading these reports; nothing arrives in your monitoring stack unless you put it there
- Report output is retained for a limited window (roughly 30 days), so an export cadence shorter than that window is what gives you a durable trail for SOX, SOC 2, and tax-fraud investigations
- Reviewing user, role, and access reports is how you detect the drift that access reviews are supposed to catch — a new Security Administrator, an unexpected delegation, an account that should have been removed
- Reviewing them close to real time is the only compensating control available for the absence of live alerting, so cadence matters more here than it would on a platform with an event stream

**Attack Prevented:** Undetected privilege escalation, insider fraud, unnoticed third-party delegation, loss of audit evidence through report expiry

> **Correction — ADP does not offer a SIEM log stream here.** Earlier revisions of this guide instructed administrators to "forward the logs to your SIEM." ADP's Security Management Service documents a set of named security **reports** run from the console, with report output retained for a limited period — it does not document a log-streaming or SIEM-export mechanism for this surface. Plan for scheduled reporting and self-managed retention, and do not build a detection programme that assumes a live ADP event feed. If your ADP service offers an event-export capability, confirm it with ADP directly. Source: [ADP Security Management Service online help](https://support.adp.com/netsecure/pages/pub/docs/9.0/en_us/ADP_Security_Management_OnlineHelp.pdf).

#### ClickOps Implementation

**Step 1: Run the Security Reports**
1. Navigate to: **Reports → Run & View Reports**
2. Run the available security reports covering user accounts, security-role assignments, registration and access status, and administrator activity
3. Record which reports your ADP service exposes — availability varies by service and region

**Step 2: Export Before Expiry**
1. Export report output to your own evidence store on a cadence shorter than the roughly 30-day retention window
2. Store exports where your normal log-retention and access controls apply

**Step 3: Review Against a Baseline**
1. Diff each run against the previous one and investigate new or removed privileged users, new delegations ([2.1](#21-govern-third-party-delegated-access)), and unexpected registration activity ([1.3](#13-require-personal-registration-codes-and-identity-verification))
2. Assign a named reviewer — an unread report is not a control

#### Validation & Testing
- Confirm the most recent export is newer than the retention window
- Confirm a named owner signs off each review cycle
- Seed a benign change (for example, a role assignment) and confirm it appears in the next report run and is caught by the diff

---

## 5. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | ADP Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA enforcement via federated SSO | 1.1 |
| CC6.2 | Role-based access; registration and identity verification | 1.2, 1.3 |
| CC6.3 | Account lockout, suspension, and password rules | 1.4 |
| CC6.7 | Third-party delegated access governance | 2.1 |
| CC7.2 | Security reporting and review | 4.1 |

---

## Appendix B: References

**Official ADP Administrator Documentation (fetch-verified):**
- [ADP Security Management Service — Online Help](https://support.adp.com/netsecure/pages/pub/docs/9.0/en_us/ADP_Security_Management_OnlineHelp.pdf) — the administrator guide for the security console at `netsecure.adp.com`: security roles, user management, registration codes, delegations, lockout and password rules, and security reports
- [ADP Registration Best Practices — Identity Verification and W-2 Access](https://support.adp.com/netsecure/pages/pub/docs/9.0/en_us/ADP_Registration_Best_Practices_AVS_W2.pdf)
- [ADP Registration Best Practices](https://support.adp.com/netsecure/pages/pub/docs/9.0/en_us/ADP_Registration_Best_Practices.pdf)
- [Administrator Access — Quick Reference Card for New Administrators](https://support.adp.com/netsecure/pages/pub/docs/9.0/en_us/Administrator_Access_QRC_for_New_Administrators.pdf)
- [ADP Support](https://support.adp.com/)

**API & Developer Tools:**
- [ADP Developer Resources](https://developers.adp.com/) — note: this host is a client-rendered single-page application with no server-rendered content, so individual article URLs cannot be fetch-verified
- [ADP Marketplace](https://apps.adp.com/)

**Compliance Frameworks:**
- ADP publishes its certification and audit posture (SOC 1 / SOC 2 Type II, ISO 9001, ISO/IEC 27001, ISO/IEC 27701, PCI DSS) through its corporate data-security pages. Those pages describe ADP's own attestations rather than administrator-configurable controls, so this guide does not cite them as hardening sources. Request the current reports from your ADP service team under NDA and validate their scope against your own control requirements.

**Security Incidents:**
- **2016 — Flowjacking / W-2 Tax Fraud:** Attackers used stolen credentials and publicly available registration codes to access employee W-2 data at multiple ADP customer companies for tax fraud. ADP itself was not breached; the attack exploited the self-service registration workflow. ([Norton Rose Fulbright Analysis](https://www.nortonrosefulbright.com/en-us/knowledge/publications/52719313/security-issue-could-impact-adp-customers))
- **September 2024 — BSH Partner Ransomware (Broadcom):** El Dorado ransomware group compromised Business Systems House (BSH), a Middle Eastern ADP partner, exposing Broadcom employee payroll data. ADP stated only "a small subset" of clients in certain Middle Eastern countries were affected. ([The Register Report](https://www.theregister.com/2025/05/16/broadcom_employee_data_stolen_by/))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass and expansion against ADP's administrator documentation on support.adp.com. Corrected 1.1: the "Require MFA for all users" toggle this guide previously instructed administrators to enable does not appear in ADP's administrator documentation — MFA is enforced at the identity provider through federated SSO, and the console is the ADP Security Management Service at netsecure.adp.com. Replaced invented console paths throughout with the documented ones (People → Manage Users, People → Personal Registration Codes, People → User Security Roles, Setup → Profile, Setup → Delegations, Reports → Run & View Reports). Replaced 1.2's invented role table with ADP's six-role security model and identified the two roles that can create administrators, reset passwords, and add third-party delegates. Added 1.3 (personal registration codes and identity verification) and 1.4 (lockout, suspension, deletion, and password defaults). Rewrote 2.1 around Delegations and Delegated Service Profiles, replacing an OAuth-scope framing that does not match ADP, and tied it to the 2024 BSH partner compromise. Rewrote 4.1: ADP's audit surface here is scheduled security reporting with limited report retention, not a SIEM event stream — the prior "forward logs to your SIEM" instruction had no basis in ADP's documentation. Purged the adp.com marketing security links from Appendix B in favour of the fetch-verified support.adp.com administrator PDFs. Tier 2 bodies (CIS, DISA STIG, CISA SCuBA) confirmed to publish no ADP baseline; Tier 3/4 research not surveyed this pass. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial ADP hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
