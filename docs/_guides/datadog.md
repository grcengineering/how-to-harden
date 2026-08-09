---
layout: guide
title: "Datadog Hardening Guide"
vendor: "Datadog"
slug: "datadog"
tier: "1"
category: "Security"
description: "Observability platform hardening for Datadog including SAML SSO, role-based access control, sensitive data redaction, cloud integration security, and organization security settings"
version: "0.2.1"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

Datadog is a leading observability and security platform used by **thousands of organizations** for infrastructure monitoring, APM, log management, and security monitoring. As a platform with access to sensitive operational data and infrastructure metrics, Datadog security configurations directly impact data protection and operational security.

### Intended Audience
- Security engineers managing observability platforms
- IT administrators configuring Datadog
- DevOps teams securing monitoring infrastructure
- GRC professionals assessing observability security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Datadog organization security including SAML SSO, role-based access control, API and application key management, session security, sensitive data redaction, cloud integration credentials, agent control plane configuration, and network-layer access restrictions.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [API & Key Security](#3-api--key-security)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Data Protection](#5-data-protection)
6. [Integration & Agent Security](#6-integration--agent-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Datadog users.

#### Rationale
**Why This Matters:**
- Centralizes identity management
- Enables enforcement of organizational MFA policies
- Simplifies user lifecycle management
- Required for SAML strict mode

**Attack Prevented:** Password-based account takeover, access by accounts outside centralized MFA and lifecycle management

#### Prerequisites
- Datadog Administrator access
- SAML 2.0 compatible identity provider
- IdP admin credentials

#### ClickOps Implementation

**Step 1: Access SAML Configuration**
1. Navigate to: **Organization Settings** → **Login Methods**
2. Click on **SAML** settings
3. Enable SAML configuration

**Step 2: Configure Identity Provider**
1. Create SAML application in IdP:
   - Active Directory
   - Auth0
   - Google
   - LastPass
   - Microsoft Entra ID
   - Okta
   - SafeNet
2. Configure required attributes

**Step 3: Upload IdP Metadata**
1. Download IdP metadata XML
2. Upload to Datadog SAML settings
3. Verify configuration

**Step 4: Configure Datadog Settings**
1. Datadog supports HTTP-POST binding
2. NameIDPolicy format: emailAddress
3. Assertions must be signed

**Time to Complete:** ~1 hour

{% include pack-code.html vendor="datadog" section="1.1" %}

---

### 1.2 Enable SAML Strict Mode

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Require SAML authentication for all users.

#### Rationale
**Why This Matters:**
- Strict mode disables local password and social logins, forcing every login through your corporate IdP and its MFA and conditional-access policies
- Leaving password or Google login enabled creates a parallel authentication path that bypasses SSO controls and is a prime target for credential stuffing and phishing
- Centralized IdP authentication ensures departed employees lose Datadog access the moment they are deprovisioned, eliminating orphaned standing access
- Datadog holds infrastructure telemetry, logs, and security signals that map your environment for anyone who gets in

**Attack Prevented:** Credential stuffing, phishing, MFA bypass, orphaned-account access

#### ClickOps Implementation

**Step 1: Navigate to Login Methods**
1. Navigate to: **Organization Settings** → **Login Methods**
2. Review enabled authentication methods

**Step 2: Configure Strict Mode**
1. Set Password login: **Disabled**
2. Set Google login: **Disabled**
3. Set SAML login: **Enabled by Default**

**Step 3: Configure User Overrides**
1. Allow per-user overrides if needed
2. Configure individual exceptions carefully

{% include pack-code.html vendor="datadog" section="1.2" %}

---

### 1.3 Configure Session Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout and security settings.

#### Rationale
**Why This Matters:**
- Bounded session duration and idle timeout limit the window in which a stolen or hijacked session token remains valid
- Without an idle timeout, an unattended or unlocked workstation leaves an authenticated Datadog session open indefinitely for anyone with physical or remote access
- Shorter sessions force periodic re-authentication, reducing the value of exfiltrated session cookies
- Datadog dashboards expose sensitive operational and security data, so a lingering session is a direct path to that data

**Attack Prevented:** Session hijacking, cookie theft, unattended-workstation access

#### ClickOps Implementation

**Step 1: Configure Session Duration**
1. Navigate to: **Organization Settings** → **Security**
2. Set **Maximum session duration**
3. Applies to all new web sessions

**Step 2: Configure Idle Timeout**
1. Enable **Idle time session timeout**
2. Users signed out after 30 minutes inactivity

{% include pack-code.html vendor="datadog" section="1.3" %}

---

## 2. Access Controls

### 2.1 Configure Role-Based Access Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Datadog's RBAC model.

#### Rationale
**Why This Matters:**
- Least-privilege roles ensure each user can only see and change what their job requires, containing the blast radius if an account is compromised
- Broad default roles grant more access than most users need, expanding the attack surface across dashboards, monitors, and integrations
- Custom roles let you gate sensitive permissions such as key management, billing, and user administration to a small set of trusted operators
- Datadog aggregates logs and metrics from across your infrastructure, so over-privileged accounts can expose data from systems the user never works on
- Role permissions alone are all-or-nothing for log data: any role holding `logs_read_data` can read every indexed log unless you attach a restriction query, so one over-broad role exposes payment, healthcare, and production secrets logged anywhere in the org
- A restriction query narrows `logs_read_data` to a filter such as `team:acme`, meaning members of that role see only logs matching the filter and nothing else, which contains the blast radius of a compromised standard user

**Attack Prevented:** Privilege escalation, lateral movement, insider data access, over-exposure of telemetry, cross-team log snooping

#### ClickOps Implementation

**Step 1: Review Managed Roles**
1. Navigate to: **Organization Settings** → **Roles**
2. Review default managed roles:
   - **Admin:** Full access
   - **Standard:** Read/write on assets
   - **Read Only:** Read data only

**Step 2: Create Custom Roles**
1. Click **Create Role**
2. Configure specific permissions
3. Pay attention to sensitive permissions

**Step 3: Review Sensitive Permissions**
1. Sensitive permissions are flagged in UI
2. Review carefully before assigning

**Step 4: Attach Logs Restriction Queries to Roles**
1. Navigate to: **Organization Settings** → **Roles**
2. Select a role that holds the **`logs_read_data`** permission
3. Add a **restriction query** expressing the subset of logs that role may read, for example `team:acme` or `env:staging`
4. Confirm that members of the role now see only logs matching the query — everything else is filtered out of Log Explorer, dashboards, monitors, and the API for that role
5. Treat the **Unrestricted Access** allowlist as the deliberate exception: grant it only to roles that genuinely need to read every log (for example a security operations role), and record the business justification
6. Re-check restriction queries whenever tagging conventions change, since a renamed tag silently widens or empties the filter
7. Reference: [How to Set Up RBAC for Logs](https://docs.datadoghq.com/logs/guide/logs-rbac/)

{% include pack-code.html vendor="datadog" section="2.1" %}

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
- Admin accounts can modify org-wide security settings, manage users, and rotate keys, making them the highest-value target in the organization
- Each additional admin multiplies the number of accounts an attacker can phish or compromise to gain full control
- Keeping admin to a small, named set makes anomalous admin activity easier to detect and audit
- A single compromised Datadog admin can disable logging, exfiltrate data, and weaken every other control in this guide

**Attack Prevented:** Admin account takeover, privilege escalation, audit tampering, security-control bypass

#### ClickOps Implementation

**Step 1: Inventory Admin Users**
1. Navigate to: **Organization Settings** → **Users**
2. Filter by Admin role
3. Document all admin accounts

**Step 2: Apply Least Privilege**
1. Limit Admin to 2-3 users
2. Remove unnecessary admin access
3. Use custom roles for specific needs

---

### 2.3 Restrict Access with the IP Allowlist

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 12.5, 13.4 |
| NIST 800-53 | AC-17, SC-7 |

#### Description
Restrict access to your Datadog organization to a defined set of IP ranges using the IP Allowlist, available on the Enterprise plan. Once enabled, requests originating outside the allowlisted ranges are rejected for the web UI, the mobile app, the public API, OAuth-based integrations, and the Datadog MCP Server. Configured at **Organization Settings** → **Security** → **IP Allowlist**. Reference: [IP Allowlist](https://docs.datadoghq.com/account_management/org_settings/ip_allowlist/).

#### Rationale
**Why This Matters:**
- The IP Allowlist is the only network-layer control Datadog offers — every other control in this guide operates at the identity or permission layer, so this is the single place you can say "no request from outside our egress ranges, full stop"
- A stolen session cookie, leaked application key, or phished SSO credential is useless to an attacker who cannot reach the org from an allowlisted address, turning a credential compromise into a non-event
- Coverage extends beyond the UI to the public API and OAuth integrations, closing the common gap where a hardened console sits next to a wide-open programmatic surface
- Datadog is a read-through window into your entire estate — logs, traces, infrastructure topology, and security signals — so restricting where that window can be opened from meaningfully shrinks the attack surface
- Because the allowlist also governs the MCP Server, it constrains AI agent and automation access to the same approved ranges rather than letting a new integration surface bypass your network policy

**Attack Prevented:** Credential replay from attacker infrastructure, session hijacking from unapproved networks, API abuse with leaked keys, unauthorized OAuth and MCP access

#### Prerequisites
- Datadog Enterprise plan
- Administrator access with the `org_management` permission
- A complete inventory of egress IP ranges: corporate networks, VPN concentrators, CI/CD runners, and any SaaS that calls the Datadog API

#### ClickOps Implementation

**Step 1: Inventory Source Ranges Before Enabling**
1. Collect every CIDR range that legitimately reaches Datadog: office and VPN egress, cloud NAT gateways, CI/CD runner pools, and third-party integrations that call the public API
2. Include mobile-app users' expected networks, or accept that mobile access will be blocked off-network
3. Missing a range here locks out real users and breaks running automation, so treat this inventory as the actual work

**Step 2: Configure the Allowlist**
1. Navigate to: **Organization Settings** → **Security**
2. Open **IP Allowlist**
3. Add each approved CIDR range with a description identifying its owner and purpose
4. Verify your own current IP is included before enabling, so you do not lock yourself out

**Step 3: Enable and Communicate**
1. Enable the allowlist
2. Notify users and integration owners of the change and the process for requesting an added range
3. Document the approved ranges in your change management system

**Step 4: Review on a Schedule**
1. Re-review the allowlist quarterly and after any network change (new office, VPN migration, cloud region addition)
2. Remove ranges tied to decommissioned offices, retired VPN endpoints, or terminated vendors

#### Validation & Testing
1. From an allowlisted network, sign in to the Datadog UI and confirm normal access
2. From a non-allowlisted network (for example a mobile hotspot), attempt to load the Datadog UI and confirm the request is rejected
3. Issue an authenticated public API call from a non-allowlisted address and confirm it fails, proving the allowlist covers the programmatic surface and not just the console
4. Confirm CI/CD pipelines, Terraform runs, and any OAuth integrations still function after enabling — a silent pipeline failure is the most common post-enablement regression
5. Re-run these checks after every allowlist edit

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| SOC 2 | CC6.1 | Logical access is restricted to authorized users and approved sources |
| SOC 2 | CC6.6 | Access from outside system boundaries is restricted |
| NIST 800-53 | AC-17 | Remote access is monitored and controlled |
| NIST 800-53 | SC-7 | Boundary protection restricts external connections |
| CIS Controls | 12.5 | Centralize network authentication and access enforcement |
| CIS Controls | 13.4 | Perform traffic filtering between network segments |
| ISO 27001 | A.8.20 | Networks are secured and access is controlled |

---

## 3. API & Key Security

### 3.1 Secure API Keys

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure Datadog API keys used for data ingestion.

#### Rationale
**Why This Matters:**
- API keys authorize data ingestion and programmatic access, so a leaked key lets an attacker submit false telemetry or pull organizational data
- Purpose-specific, descriptively named keys let you revoke a single compromised integration without breaking everything else
- Storing keys in a secret manager and keeping them out of source code prevents the most common leak vector — credentials committed to repositories
- Unused or orphaned keys are standing credentials an attacker can exploit undetected

**Attack Prevented:** API key leakage, credential exposure in source code, telemetry poisoning, unauthorized data access

#### ClickOps Implementation

**Step 1: Review API Keys**
1. Navigate to: **Organization Settings** → **API Keys**
2. Review all existing keys
3. Identify purpose of each key

**Step 2: Implement Key Management**
1. Create purpose-specific keys
2. Name keys descriptively
3. Remove unused keys

**Step 3: Secure Key Storage**
1. Store keys in secret manager
2. Use environment variables
3. Never commit to code

{% include pack-code.html vendor="datadog" section="3.1" %}

---

### 3.2 Secure Application Keys

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure application keys used for API access.

#### Rationale
**Why This Matters:**
- Application keys inherit the full permissions of the user who created them, so a leaked key grants an attacker that user's entire level of access
- Scoping keys to the minimum required permissions limits what a compromised key can read or change
- Regular rotation shortens the lifespan of any key that is exposed before the leak is detected
- Tying a privileged user's app key to a broad scope effectively turns a key leak into an account takeover
- Application keys do not expire natively — Datadog issues them without a built-in lifetime, so a key leaked today stays valid indefinitely unless you revoke it, which makes authorization scoping plus a deliberate rotation schedule the real control rather than an optional nicety
- Keys owned by individual employees become orphaned credentials when that person changes teams or leaves; a service account owns the key instead, so integrations keep running through employee departure and the key's ownership is an org asset rather than a personal one
- Service accounts are non-interactive by design — they cannot log in to the UI — which means a compromised automation key cannot be used to browse the console interactively

**Attack Prevented:** Application key leakage, over-scoped access, credential reuse, account impersonation, orphaned credentials surviving offboarding

#### ClickOps Implementation

**Step 1: Review Application Keys**
1. Navigate to: **Organization Settings** → **Application Keys**
2. Application keys inherit user permissions

**Step 2: Configure Key Scopes**
1. Create keys with limited scopes
2. Grant minimum required permissions
3. Use **authorization scopes** to bound what each key can do: navigate to **Organization Settings** → **Application Keys**, open the key, and select only the scopes the integration actually calls
4. An unscoped key inherits the owning user's full permissions, so scoping is what separates "this key reads monitors" from "this key can do anything its owner can"
5. Reference: [API and Application Keys](https://docs.datadoghq.com/account_management/api-app-keys/)

**Step 3: Own Automation Keys with Service Accounts**
1. Navigate to: **Organization Settings** → **Service Accounts**
2. Create a service account for each integration or automation workload rather than issuing the key from a named employee's account
3. Assign the service account a role carrying only the permissions that workload needs
4. Generate the application key from the service account, then store it in your secret manager
5. Service accounts are non-interactive — they cannot sign in to the Datadog UI — so the credential is usable only for the programmatic access it was created for
6. Because the account is owned by the organization rather than a person, the integration survives employee departure and offboarding no longer silently breaks or leaves orphaned keys behind
7. Reference: [Service Accounts](https://docs.datadoghq.com/account_management/org_settings/service_accounts/)

**Step 4: Rotate Keys Regularly**
1. Establish rotation schedule (90 days)
2. Update integrations before deleting
3. Application keys never expire on their own, so rotation must be a scheduled operational task with an owner — there is no platform-side expiry to fall back on
4. Audit the Application Keys page for keys with no recent use and revoke them

{% include pack-code.html vendor="datadog" section="3.2" %}

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logs

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Monitor administrative and security events.

#### Rationale
**Why This Matters:**
- The audit trail records configuration changes, logins, and sensitive operations, providing the evidence needed to detect and investigate abuse
- Without alerting on sensitive events, malicious changes such as disabling SSO or creating new admin accounts go unnoticed
- Exporting logs to a SIEM with independent retention preserves evidence even if an attacker tampers with the Datadog console
- Detection and forensic readiness are the backstop for every preventive control — they catch what slips through

**Attack Prevented:** Undetected configuration tampering, insider abuse, delayed breach detection, log destruction

#### ClickOps Implementation

**Step 1: Access Audit Trail**
1. Navigate to: **Organization Settings** → **Audit Trail**
2. Review logged events

**Step 2: Configure Alerts**
1. Create monitors for audit events
2. Alert on sensitive operations

**Step 3: Export Logs**
1. Export audit logs for retention
2. Integrate with SIEM

{% include pack-code.html vendor="datadog" section="4.1" %}

---

## 5. Data Protection

### 5.1 Redact Sensitive Data with the Sensitive Data Scanner

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.11 |
| NIST 800-53 | SC-28, SI-19 |

#### Description
Configure the Sensitive Data Scanner to identify and redact, hash, or partially mask sensitive values — personally identifiable information, payment card numbers, API keys, and other secrets — inside telemetry as it streams through Datadog, before it lands in Logs, APM spans, or RUM events. Configured at **Organization Settings** → **Sensitive Data Scanner**. Reference: [Sensitive Data Scanner](https://docs.datadoghq.com/sensitive_data_scanner/).

#### Rationale
**Why This Matters:**
- Application logs and traces routinely capture things nobody intended to store: request bodies with customer PII, authorization headers carrying bearer tokens, stack traces embedding connection strings, and form submissions containing card numbers
- Once that data is indexed, every person and every application key holding log read access can retrieve it, which quietly turns your observability platform into an unmanaged secondary copy of your most regulated data
- Scanning at ingestion means the sensitive value is redacted or hashed before it reaches the index, so there is no sensitive copy to leak, subpoena, or accidentally export — a materially stronger position than detecting the exposure afterward
- Secrets that appear in logs are live credentials: an attacker with log read access harvests API keys and tokens without touching your secret manager at all, and redaction at ingestion breaks that path
- Hashing rather than deleting preserves the operational value of the field — engineers can still correlate on a consistent hash during an incident without ever seeing the underlying value
- Regulated data in an observability platform expands the scope of PCI DSS, HIPAA, and GDPR assessments to cover Datadog itself; redacting at ingestion keeps that scope contained

**Attack Prevented:** Secret harvesting from logs, PII exposure through telemetry, regulated-data scope creep, insider data browsing, downstream leakage via log exports

#### Prerequisites
- Datadog Administrator access
- Knowledge of which services emit sensitive fields and in what shape
- An inventory of the data classifications your organization must protect (PII, PCI, PHI, credentials)

#### ClickOps Implementation

**Step 1: Review Predefined Scanning Rules**
1. Navigate to: **Organization Settings** → **Sensitive Data Scanner**
2. Review the library of predefined rules covering common patterns: credit card numbers, email addresses, national identifiers, cloud provider credentials, and API keys
3. Start from the predefined library rather than writing custom expressions, since the shipped rules are maintained by Datadog

**Step 2: Create a Scanning Group**
1. Create a scanning group and define its filter — the subset of telemetry the group applies to, such as a service, environment, or tag
2. Scope groups deliberately: a group filtered too broadly scans everything and costs performance, one filtered too narrowly misses the noisy service that actually leaks

**Step 3: Add Rules and Choose an Action**
1. Add rules to the group from the predefined library, or define custom rules for organization-specific formats such as internal account identifiers
2. For each rule, choose the action applied on match:
   - **Redact** — replace the matched value with a placeholder
   - **Partially redact** — retain a fragment (for example the last four digits) for troubleshooting
   - **Hash** — replace the value with a consistent hash so correlation remains possible without exposure
3. Prefer hashing where engineers need to join on the field during incidents, and full redaction where the value has no operational use

**Step 4: Extend Coverage Beyond Logs**
1. Apply scanning groups to APM spans and RUM events, not only Logs — traces and browser events carry the same sensitive payloads and are frequently overlooked
2. Confirm each telemetry type your organization ingests is covered by at least one group

**Step 5: Tune and Monitor**
1. Review scanner match volume after enabling to confirm rules fire where expected
2. Investigate services with unexpectedly high match counts — a service redacting thousands of card numbers per minute is telling you about a logging defect that should be fixed at the source
3. Re-review rules whenever new services onboard

#### Validation & Testing
1. Send a test log containing a synthetic value matching each configured rule (for example a test card number and a fake API key) and confirm the indexed event shows the redacted or hashed form, not the original
2. Query Log Explorer for the original plaintext value and confirm zero results — this is the check that proves nothing sensitive reached the index
3. Repeat the same test against an APM span and a RUM event to confirm coverage extends beyond Logs
4. Verify that a hashed field produces the same hash across two separate events with the same input, confirming correlation still works
5. Review scanner match metrics weekly for the first month, then on a regular cadence, to catch newly onboarded services emitting unscanned sensitive data

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| SOC 2 | CC6.1 | Sensitive information is protected from unauthorized disclosure |
| SOC 2 | C1.1 | Confidential information is identified and protected |
| NIST 800-53 | SC-28 | Information at rest is protected |
| NIST 800-53 | SI-19 | De-identification is applied to sensitive data |
| CIS Controls | 3.1 | Establish and maintain a data management process |
| CIS Controls | 3.11 | Encrypt or protect sensitive data at rest |
| PCI DSS | 3.3 | Mask or render unreadable primary account numbers |
| ISO 27001 | A.8.11 | Data masking is applied in accordance with access control policy |

---

## 6. Integration & Agent Security

### 6.1 Use IAM Role Delegation for the AWS Integration

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-3, IA-5 |

#### Description
Connect the Datadog AWS integration using cross-account IAM role delegation with an external ID, rather than embedding static AWS access keys in the integration configuration. Static keys remain necessary only for AWS China and for GovCloud accounts monitored from a commercial Datadog site. Reference: [Amazon Web Services Integration](https://docs.datadoghq.com/integrations/amazon_web_services/).

#### Rationale
**Why This Matters:**
- Static AWS access keys handed to a third party are long-lived bearer credentials that never expire on their own — if the integration configuration is ever exposed, the key works until someone notices and rotates it
- Role delegation issues short-lived STS credentials on each assume-role call, so there is no durable secret sitting in Datadog's configuration to steal in the first place
- The external ID binds the trust relationship to your specific Datadog organization, defeating the confused deputy attack where another Datadog customer could otherwise induce the shared Datadog principal to assume your role
- The delegated role's IAM policy is yours to write and yours to tighten: you grant exactly the read permissions the integration needs and can revoke or narrow them from your own console at any time, without waiting on the vendor
- Revocation is instant and unilateral — deleting the trust relationship cuts access immediately, whereas a leaked static key requires you to find and rotate it everywhere it was used
- The Datadog AWS integration reads across your entire account inventory, so the credential backing it is one of the highest-value pieces of your cloud attack surface

**Attack Prevented:** Long-lived cloud credential theft, confused deputy attacks, unrevocable third-party access, over-permissioned integration roles

#### Prerequisites
- AWS account access with IAM role creation permissions
- Datadog Administrator access
- The Datadog-provided AWS account ID and generated external ID

#### ClickOps Implementation

**Step 1: Start the Integration in Datadog**
1. Navigate to: **Integrations** → **Amazon Web Services**
2. Begin adding an AWS account and select role delegation as the access method
3. Copy the generated **external ID** — it is specific to your organization and must be used in the trust policy

**Step 2: Create the Cross-Account Role in AWS**
1. In the AWS IAM console, create a role for cross-account access
2. Set the trusted entity to the Datadog AWS account ID
3. Require the external ID from Step 1 in the trust policy condition — do not omit this, since the external ID is what prevents another tenant from assuming your role
4. Attach a policy granting only the read permissions the integration requires for the services you actually monitor

**Step 3: Complete the Connection**
1. Return to Datadog and supply the role name
2. Confirm the integration validates and begins collecting metrics
3. Select only the AWS services and regions you intend to monitor, keeping both the IAM policy and the collected data scoped

**Step 4: Handle the Static-Key Exceptions Explicitly**
1. Use access keys only where role delegation is unavailable: AWS China, and GovCloud accounts monitored from a commercial Datadog site
2. Where a static key is unavoidable, create a dedicated IAM user with a minimal read-only policy, document the exception, and put the key on a rotation schedule with a named owner

**Step 5: Review Periodically**
1. Re-review the role's attached policy quarterly and remove permissions for services you no longer monitor
2. Remove trust relationships for Datadog organizations or AWS accounts that are no longer in use

#### Validation & Testing
1. Inspect the IAM role's trust policy and confirm the external ID condition is present — a trust policy naming the Datadog account without an external ID condition is the failure mode to look for
2. Confirm the Datadog AWS integration page shows the account connected and metrics arriving
3. Audit the integration configuration for any remaining static access keys and confirm each is either removed or a documented China/GovCloud exception
4. Review the role's attached policy for wildcard actions or write permissions the integration does not need
5. Test revocation in a non-production account by removing the trust relationship and confirming metric collection stops

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| SOC 2 | CC6.1 | Access to systems is restricted to authorized entities |
| SOC 2 | CC6.3 | Credentials are managed and access is revocable |
| NIST 800-53 | AC-3 | Access enforcement is applied to third-party integrations |
| NIST 800-53 | IA-5 | Authenticator management, including avoiding static shared secrets |
| CIS Controls | 5.4 | Restrict administrator privileges to dedicated accounts |
| CIS Controls | 6.8 | Define and maintain role-based access control |
| ISO 27001 | A.5.19 | Information security in supplier relationships |

---

### 6.2 Use Service Account Impersonation for the Google Cloud Integration

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-3, IA-5 |

#### Description
Connect the Datadog Google Cloud integration using service account impersonation with automatic project discovery, rather than generating and uploading a downloadable service account key file. Reference: [Google Cloud Platform Integration](https://docs.datadoghq.com/integrations/google_cloud_platform/).

#### Rationale
**Why This Matters:**
- A downloaded service account key is a JSON file containing a private key that never expires, and every copy of it — in a config directory, a chat message, a ticket attachment, a backup — is a working credential to your cloud environment
- Impersonation replaces that file with a trust relationship: Datadog's principal is granted permission to impersonate your service account, and short-lived tokens are minted per request, so there is no key file to leak
- Google itself treats downloaded key files as a discouraged pattern precisely because their lifecycle is unmanageable at scale; organizations frequently cannot say how many copies of a given key exist
- Automatic project discovery means new projects are picked up without minting a new credential for each one, removing the operational pressure that leads teams to create and share long-lived keys
- Revocation is a single IAM change on your side — remove the impersonation grant and access stops immediately, with no need to hunt down distributed copies of a key file
- The integration reads across your GCP estate, so this credential is a high-value target and deserves the strongest available binding

**Attack Prevented:** Service account key file leakage, unrevocable cloud access, credential sprawl across projects, long-lived private key compromise

#### Prerequisites
- Google Cloud project access with IAM administration permissions
- Datadog Administrator access
- The Datadog principal identifier provided during integration setup

#### ClickOps Implementation

**Step 1: Begin Setup in Datadog**
1. Navigate to: **Integrations** → **Google Cloud Platform**
2. Start adding a Google Cloud account and select the service account impersonation method
3. Note the Datadog principal that will be granted impersonation rights

**Step 2: Create the Service Account in Google Cloud**
1. In the Google Cloud console, create a service account dedicated to Datadog monitoring
2. Grant it the roles the integration requires for the telemetry you want, keeping to read-level roles
3. Do not generate or download a key for this service account — the whole point of the pattern is that no key file exists

**Step 3: Grant Impersonation to Datadog**
1. On the service account, add the Datadog principal with the role permitting token creation and impersonation
2. Complete the connection in Datadog and confirm it validates

**Step 4: Enable Automatic Project Discovery**
1. Enable automatic project discovery so newly created projects are monitored without provisioning additional credentials
2. Review the discovered project list and exclude projects that should not be monitored

**Step 5: Retire Existing Key Files**
1. Inventory any existing Datadog Google Cloud integrations still configured with uploaded key files
2. Migrate them to impersonation, then delete the corresponding service account keys in Google Cloud so the retired credential cannot be reused
3. Deleting the key in Google Cloud is the step that actually revokes it — removing it from Datadog alone leaves the key valid

#### Validation & Testing
1. In the Google Cloud console, confirm the Datadog service account has zero user-managed keys — any key present is a credential that can leak
2. Confirm the IAM policy shows the Datadog principal granted impersonation on the service account
3. Verify in Datadog that Google Cloud metrics are arriving and the integration reports healthy
4. Create a test project and confirm automatic discovery picks it up without any new credential being issued
5. Test revocation in a non-production project by removing the impersonation binding and confirming collection stops

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| SOC 2 | CC6.1 | Access to systems is restricted to authorized entities |
| SOC 2 | CC6.3 | Credentials are managed and access is revocable |
| NIST 800-53 | AC-3 | Access enforcement is applied to third-party integrations |
| NIST 800-53 | IA-5 | Authenticator management, including avoiding downloadable private keys |
| CIS Controls | 5.4 | Restrict administrator privileges to dedicated accounts |
| CIS Controls | 6.8 | Define and maintain role-based access control |
| ISO 27001 | A.5.19 | Information security in supplier relationships |

---

### 6.3 Review Remote Configuration Enablement

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 4.8 |
| NIST 800-53 | CM-6, CM-7 |

#### Description
Remote Configuration lets Datadog push configuration changes from the platform down to running Datadog Agents and tracing libraries without a local deployment. It is **enabled by default at the organization level**. Review whether your organization actually uses it, and disable it at **Organization Settings** → **Remote Configuration** if not. Toggling this setting requires the `org_management` permission. Reference: [Remote Configuration](https://docs.datadoghq.com/agent/remote_config/).

#### Rationale
**Why This Matters:**
- Remote Configuration is a control plane reaching into every host running the Datadog Agent, which means a compromise of that plane or of a sufficiently privileged Datadog account translates into configuration changes pushed across your fleet
- Because it is on by default, most organizations have this channel open without having made a decision about it — the default is the exposure, and reviewing it is the control
- If you do not use remote-configured features, leaving the channel open is standing capability with no offsetting benefit, which is exactly what least-functionality principles say to remove
- Disabling it forces agent configuration back through your normal deployment pipeline, where changes are version controlled, peer reviewed, and auditable — properties a platform-side push does not inherently have
- Where the capability is genuinely needed, the mitigation shifts to tightly controlling who holds `org_management` and the permissions governing remote config, and to alerting on changes through the audit trail

**Attack Prevented:** Fleet-wide agent configuration tampering, control plane abuse, unaudited configuration drift, over-broad standing capability

#### Prerequisites
- Datadog Administrator access with the `org_management` permission
- An inventory of which Datadog features your organization uses that depend on Remote Configuration

#### ClickOps Implementation

**Step 1: Determine Whether You Actually Use It**
1. Identify which Datadog capabilities in use rely on Remote Configuration to push settings to agents and tracing libraries
2. If no team depends on remote-pushed configuration, the capability is unused standing exposure

**Step 2: Review the Organization Setting**
1. Navigate to: **Organization Settings** → **Remote Configuration**
2. Note the current state — it is enabled by default, so an untouched organization will show it on
3. Confirm which users and roles hold `org_management` and can therefore change this setting

**Step 3: Disable If Unneeded**
1. If your organization does not use remote-configured features, disable Remote Configuration at the org level
2. Record the decision and its rationale in your change management system, so a future enablement is a deliberate reviewed action rather than a silent default

**Step 4: Harden If Retained**
1. Where Remote Configuration is required, restrict the `org_management` permission to the minimum set of administrators
2. Create a monitor against the audit trail alerting on changes to Remote Configuration state and on remote configuration pushes
3. Re-review the decision on your regular access review cycle

#### Validation & Testing
1. Load **Organization Settings** → **Remote Configuration** and confirm the state matches your documented decision rather than the platform default
2. Enumerate the users and roles holding `org_management` and confirm the list matches your approved administrator inventory
3. If disabled, confirm agents continue reporting normally and that no team reports a broken feature that silently depended on remote configuration
4. If retained, verify the audit trail monitor fires by making a benign configuration change in a non-production organization
5. Re-verify the setting after any organization migration or plan change, since defaults reassert on newly created organizations

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| SOC 2 | CC6.1 | Access to configuration capabilities is restricted |
| SOC 2 | CC8.1 | Changes to system configuration are authorized and tracked |
| NIST 800-53 | CM-6 | Configuration settings are established and enforced |
| NIST 800-53 | CM-7 | Least functionality — unnecessary capabilities are disabled |
| CIS Controls | 4.1 | Establish and maintain a secure configuration process |
| CIS Controls | 4.8 | Uninstall or disable unnecessary services and capabilities |
| ISO 27001 | A.8.9 | Configuration management |

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Datadog Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | SSO/SAML | [1.1](#11-configure-saml-single-sign-on) |
| CC6.1 | IP Allowlist | [2.3](#23-restrict-access-with-the-ip-allowlist) |
| CC6.2 | RBAC | [2.1](#21-configure-role-based-access-control) |
| CC6.3 | Cloud integration credentials | [6.1](#61-use-iam-role-delegation-for-the-aws-integration) |
| CC6.6 | Session security | [1.3](#13-configure-session-security) |
| CC6.7 | Key security | [3.1](#31-secure-api-keys) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logs) |
| CC8.1 | Remote Configuration review | [6.3](#63-review-remote-configuration-enablement) |
| C1.1 | Sensitive data redaction | [5.1](#51-redact-sensitive-data-with-the-sensitive-data-scanner) |

### NIST 800-53 Rev 5 Mapping

| Control | Datadog Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-6 | Least privilege | [2.1](#21-configure-role-based-access-control) |
| AC-17 | Network-restricted access | [2.3](#23-restrict-access-with-the-ip-allowlist) |
| SC-12 | Key management | [3.1](#31-secure-api-keys) |
| IA-5 | Authenticator management | [3.2](#32-secure-application-keys) |
| SC-28 | Protection of data at rest | [5.1](#51-redact-sensitive-data-with-the-sensitive-data-scanner) |
| SI-19 | De-identification | [5.1](#51-redact-sensitive-data-with-the-sensitive-data-scanner) |
| AC-3 | Third-party access enforcement | [6.2](#62-use-service-account-impersonation-for-the-google-cloud-integration) |
| CM-7 | Least functionality | [6.3](#63-review-remote-configuration-enablement) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logs) |

---

## Appendix A: References

**Official Datadog Documentation:**
- [Trust Hub](https://www.datadoghq.com/trust/)
- [Trust Center (SafeBase)](https://trust.datadoghq.com/)
- [Safety Center / Hardening](https://docs.datadoghq.com/account_management/safety_center/)
- [Single Sign On With SAML](https://docs.datadoghq.com/account_management/saml/)
- [Access Control (RBAC)](https://docs.datadoghq.com/account_management/rbac/)
- [How to Set Up RBAC for Logs](https://docs.datadoghq.com/logs/guide/logs-rbac/)
- [Datadog Security](https://docs.datadoghq.com/security/)
- [Role Permissions](https://docs.datadoghq.com/account_management/rbac/permissions/)
- [Sensitive Data Scanner](https://docs.datadoghq.com/sensitive_data_scanner/)
- [Service Accounts](https://docs.datadoghq.com/account_management/org_settings/service_accounts/)
- [API and Application Keys](https://docs.datadoghq.com/account_management/api-app-keys/)
- [IP Allowlist](https://docs.datadoghq.com/account_management/org_settings/ip_allowlist/)
- [Remote Configuration](https://docs.datadoghq.com/agent/remote_config/)
- [Amazon Web Services Integration](https://docs.datadoghq.com/integrations/amazon_web_services/)
- [Google Cloud Platform Integration](https://docs.datadoghq.com/integrations/google_cloud_platform/)
- [Privacy at Datadog](https://www.datadoghq.com/privacy/)

**API & Developer Documentation:**
- [REST API Reference](https://docs.datadoghq.com/api/latest/)
- [Product Documentation](https://docs.datadoghq.com/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018, ISO 27701 — via [Trust Center](https://trust.datadoghq.com/)
- HIPAA-compliant Log Management available
- CSA Security, Trust & Assurance Registry (STAR) registered
- Annual penetration testing by NCC Group

**Security Incidents:**
- No major public security incidents identified affecting the Datadog platform directly.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.1 | draft | Cheat-sheet cell repair: added missing Attack Prevented line(s) to §1.1 (no content-facts changed) | Claude Code (Fable 5) |
| 2026-08-03 | 0.2.0 | draft | Add IP Allowlist (2.3), Data Protection section with Sensitive Data Scanner (5.1), Integration & Agent Security section with AWS role delegation (6.1), GCP service account impersonation (6.2), and Remote Configuration review (6.3); extend RBAC with Logs Restriction Queries and application keys with service accounts and authorization scopes | Claude Code (Sonnet 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, RBAC, and key security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
