---
layout: guide
title: "Okta Hardening Guide"
vendor: "Okta"
slug: "okta"
tier: "1"
category: "Identity"
description: "Identity Provider hardening for SSO, MFA policies, and API token security"
version: "0.3.0"
maturity: "draft"
last_updated: "2026-02-10"
---


## Overview

Okta is an identity and access management (IAM) platform that controls authentication for **18,000+ organizations** with **7,000+ integrations** in its network. As the central authentication provider for enterprise applications, Okta represents the highest-leverage hardening target in most organizations. The 2022 LAPSUS$ breach and October 2023 support system breach (affecting all 18,400 customers via HAR file exfiltration) demonstrated how stolen session tokens grant attackers SSO access to thousands of downstream applications.

### Intended Audience
- Security engineers managing identity infrastructure
- IT administrators configuring Okta tenants
- GRC professionals assessing IAM compliance
- Third-party risk managers evaluating SSO integrations

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Okta-specific security configurations including authentication policies, OAuth/SCIM governance, session management, and integration security. Infrastructure hardening for Okta agents is out of scope.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Network Access Controls](#2-network-access-controls)
3. [OAuth & Integration Security](#3-oauth--integration-security)
4. [Session Management](#4-session-management)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)
7. [Operational Security](#7-operational-security)
8. [Compliance Quick Reference](#8-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Phishing-Resistant MFA (FIDO2/WebAuthn)

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 6.5 |
| NIST 800-53 | IA-2(1), IA-2(6) |
| DISA STIG | V-273190, V-273191, V-273193 (HIGH), V-273194 (HIGH) |

#### Description
Require phishing-resistant authenticators (FIDO2 security keys or platform authenticators) for all users, especially administrators. This eliminates vulnerabilities to real-time phishing proxies that bypass TOTP and push-based MFA.

#### Rationale
**Why This Matters:**
- TOTP and push notifications can be intercepted via real-time phishing (Evilginx, Modlishka)
- The October 2023 Okta breach was enabled by session cookie theft from HAR files
- FIDO2 binds authentication to specific origins, preventing token theft

**Attack Prevented:** Real-time phishing, session hijacking, MFA bypass

**Real-World Incidents:**
- **October 2023 Okta Support Breach:** HAR files containing session cookies were exfiltrated, affecting all 18,400 customers
- **January 2022 LAPSUS$ Breach:** Third-party support engineer compromised via social engineering

#### Prerequisites
- [ ] Okta tenant with MFA capabilities
- [ ] FIDO2-compatible security keys (YubiKey 5 series, Google Titan)
- [ ] Super Admin access for policy configuration
- [ ] User inventory for phased rollout

#### ClickOps Implementation

**Step 1: Enable FIDO2 (WebAuthn) as Authenticator**
1. Navigate to: **Security → Authenticators**
2. Click **Add Authenticator** → Select **FIDO2 (WebAuthn)**
3. Configure:
   - **User verification:** Required
   - **Authenticator attachment:** Cross-platform (for security keys) or Platform (for biometrics)
4. Click **Add**

**Step 2: Create Phishing-Resistant Authentication Policy**
1. Navigate to: **Security → Authentication Policies**
2. Click **Add Policy** → Name: "Phishing-Resistant MFA"
3. Add Rule:
   - **IF:** User is member of "Administrators" group
   - **THEN:** Authentication requires FIDO2 (WebAuthn)
   - **Re-authentication frequency:** Every session
4. **Save** and set priority above default policies

**Step 3: Enforce for All Admin Access**
1. Navigate to: **Security → Global Session Policy**
2. Create rule for Admin Console access requiring FIDO2
3. Apply to Admin groups

**Step 4: Configure Authentication Policy Requirements**
Configure both Okta Dashboard and Admin Console policies:

1. Navigate to: **Security → Authentication Policies**
2. Click the **Okta Dashboard** policy
3. Click **Actions** next to the top rule → **Edit**
4. In "User must authenticate with", select **Password/IdP + Another factor** or **Any 2 factor types**
5. In "Possession factor constraints are" section, check **Phishing resistant**
6. Repeat for the **Okta Admin Console** policy

| Specification | Requirement |
|---------------|-------------|
| DISA STIG V-273190, V-273191 | Phishing resistant box must be checked for Dashboard and Admin Console |
| DISA STIG V-273193, V-273194 (HIGH) | MFA required: "Password/IdP + Another factor" or "Any 2 factor types" |

**Time to Complete:** ~30 minutes (policy) + user enrollment time

#### Code Implementation

{% include pack-code.html vendor="okta" section="1.1" %}

#### Validation & Testing
1. [ ] Attempt admin login with only password - should be blocked
2. [ ] Attempt admin login with TOTP - should be blocked (if FIDO2 required)
3. [ ] Complete admin login with FIDO2 key - should succeed
4. [ ] Review System Log for successful WebAuthn authentications

**Expected result:** Only FIDO2-authenticated sessions can access admin console

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Alert on authentication attempts that fail FIDO2 requirement
- Monitor for users bypassing policy via legacy sessions

**Log query:**
```plaintext
eventType eq "user.authentication.auth_via_mfa" AND debugContext.debugData.factor eq "FIDO2_WEBAUTHN"
```

**Maintenance schedule:**
- **Monthly:** Review FIDO2 enrollment completion rates
- **Quarterly:** Audit policy exceptions and temporary bypasses
- **Annually:** Review authenticator hardware lifecycle (key expiration)

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Users must carry/use security keys |
| **System Performance** | None | No performance impact |
| **Maintenance Burden** | Medium | Key distribution and replacement |
| **Rollback Difficulty** | Easy | Can disable policy rule |

**Potential Issues:**
- Lost security keys require backup authentication method
- Platform authenticators may not work on shared devices

**Rollback Procedure:**
1. Navigate to Authentication Policy
2. Disable or lower priority of FIDO2 requirement rule
3. Enable fallback MFA methods temporarily

---

### 1.2 Implement Admin Role Separation

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-5, AC-6(1) |

#### Description
Separate administrative privileges using Okta's custom admin roles instead of granting Super Admin access. Create role-specific permissions for Help Desk, Application Admins, and Read-Only Auditors.

#### Rationale
**Why This Matters:**
- Super Admin compromise provides complete tenant control
- LAPSUS$ attack leveraged over-privileged support access
- Least privilege limits blast radius of compromised accounts

**Attack Prevented:** Privilege escalation, lateral movement via admin accounts

#### ClickOps Implementation

**Step 1: Create Custom Admin Roles**
1. Navigate to: **Security → Administrators → Roles**
2. Click **Create new role**
3. Create the following roles:

**Help Desk Admin:**
- Reset passwords
- Unlock accounts
- View user profiles
- NO: Edit policies, manage apps, access API tokens

**Application Admin:**
- Manage specific applications
- Configure SAML/OIDC settings
- NO: Manage users, access system settings

**Security Auditor (Read-Only):**
- View all configurations
- Access System Log
- NO: Make any changes

**Step 2: Assign Roles to Specific Groups**
1. Navigate to: **Security → Administrators**
2. Click **Add Administrator**
3. Select user/group and assign custom role
4. Limit scope to specific apps/groups if applicable

#### Code Implementation

{% include pack-code.html vendor="okta" section="1.2" %}

---

### 1.3 Enable Hardware-Bound Session Tokens

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SC-23, IA-11 |

#### Description
Configure Okta to bind session tokens to specific devices using device trust and Okta FastPass, preventing session token theft and replay attacks.

#### Rationale
**Why This Matters:**
- The October 2023 breach exploited stolen session cookies from HAR files
- Device-bound tokens cannot be replayed from different devices
- Okta FastPass provides passwordless + phishing-resistant authentication

**Real-World Incidents:**
- **October 2023:** Attackers exfiltrated HAR files containing session tokens from Okta support portal

#### ClickOps Implementation

**Step 1: Enable Okta Verify with FastPass**
1. Navigate to: **Security → Authenticators**
2. Click **Okta Verify** → **Edit**
3. Enable:
   - **Okta FastPass:** On
   - **User verification with Okta FastPass:** Required
4. Save

**Step 2: Configure Device Trust**
1. Navigate to: **Security → Device Integrations**
2. Configure device trust for managed devices:
   - Jamf Pro for macOS
   - Microsoft Intune for Windows
   - VMware Workspace ONE
3. Create policy requiring managed devices

**Step 3: Create Device-Bound Session Policy**
1. Navigate to: **Security → Authentication Policies**
2. Create rule:
   - **Condition:** Device trust = Not trusted
   - **Action:** Deny access OR require additional verification

---

### 1.4 Configure Password Policy

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | IA-5(1) |
| DISA STIG | V-273195, V-273196, V-273197, V-273198, V-273199, V-273200, V-273201, V-273208, V-273209 |

#### Description
Configure comprehensive password policies with appropriate complexity, age, and history requirements. These controls protect against weak passwords, password reuse, and rapid password cycling.

#### Prerequisites
- [ ] Super Admin access
- [ ] Okta-mastered users (not applicable if using external directory services)

#### Specification Requirements

| Requirement | L1 (Baseline) | L2/L3 (DISA STIG) |
|------------|---------------|-------------------|
| Minimum length | 12 characters | 15 characters |
| Uppercase required | Yes | Yes |
| Lowercase required | Yes | Yes |
| Number required | Yes | Yes |
| Special character required | Yes | Yes |
| Minimum password age | — | 24 hours |
| Maximum password age | 90 days | 60 days |
| Common password check | Recommended | Required |
| Password history | 4 generations | 5 generations |

#### ClickOps Implementation

**Step 1: Access Password Authenticator Settings**
1. Navigate to: **Security → Authenticators**
2. Click the **Actions** button next to **Password**
3. Select **Edit**

**Step 2: Configure Each Password Policy**
For each listed Password Policy, click **Edit** and configure:

**Complexity Requirements:**
- **Minimum Length:** Set to at least **15** characters (L2/L3) or **12** (L1)
- **Upper case letter:** ☑ Checked
- **Lower case letter:** ☑ Checked
- **Number (0-9):** ☑ Checked
- **Symbol (e.g., !@#$%^&*):** ☑ Checked

**Password Age Settings:**
- **Minimum password age is XX hours:** Set to at least **24** (prevents rapid cycling)
- **Password expires after XX days:** Set to **60** (L2/L3) or **90** (L1)

**Password History:**
- **Enforce password history for last XX passwords:** Set to **5**

**Step 3: Enable Common Password Check**
1. Under **Password Settings** section
2. Check **Common Password Check**
3. Click **Save**

#### Code Implementation

{% include pack-code.html vendor="okta" section="1.4" %}

#### Validation
1. Navigate to: **Security → Authenticators → Password → Edit**
2. For each policy, verify all settings match the requirements table above

> **Note:** If Okta relies on external directory services for user sourcing, password policy is managed by the connected directory service.

---

### 1.5 Configure Account Lockout

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-7 |
| DISA STIG | V-273189 |

#### Description
Enforce account lockout after consecutive invalid login attempts to protect against brute-force password attacks. This control significantly reduces the risk of unauthorized access via password guessing.

#### Specification Requirements

| Requirement | L1 (Baseline) | L2/L3 (DISA STIG) |
|------------|---------------|-------------------|
| Lockout threshold | 5 attempts | 3 attempts |
| Lockout duration | 30 minutes | Until admin unlock |

#### ClickOps Implementation

**Step 1: Configure Password Authenticator Lockout**
1. Navigate to: **Security → Authenticators**
2. Click the **Actions** button next to **Password**
3. Select **Edit**

**Step 2: Configure Each Password Policy**
For each listed Password Policy:
1. Click **Edit** on the policy
2. Locate the **Lock Out** section
3. Check **Lock out after X unsuccessful attempts**
4. Set the value to **3** (L2/L3) or **5** (L1)
5. Click **Save**

{% include pack-code.html vendor="okta" section="1.5" %}

#### Validation
1. Navigate to: **Security → Authenticators → Password → Edit**
2. For each policy, verify lockout settings are configured

> **Note:** If Okta relies on external directory services for user sourcing, account lockout is managed by the connected directory service.

---

### 1.6 Configure Account Lifecycle Management

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-2(3) |
| DISA STIG | V-273188 |

#### Description
Automatically disable user accounts after a period of inactivity to reduce the risk of dormant account compromise. Attackers targeting inactive accounts may maintain undetected access since account owners won't notice unauthorized activity.

#### Specification Requirements

| Requirement | L1 (Baseline) | L2/L3 (DISA STIG) |
|------------|---------------|-------------------|
| Inactivity threshold | 90 days | 35 days |
| Action | Suspend | Suspend |

#### Prerequisites
- [ ] Okta Workflows license (required for Automations)
- [ ] Super Admin or Org Admin access

#### ClickOps Implementation

**Step 1: Create Inactivity Automation**
1. Navigate to: **Workflow → Automations**
2. Click **Add Automation**
3. Enter a name (e.g., "User Inactivity - Auto Suspension")

**Step 2: Configure Trigger Condition**
1. Click **Add Condition**
2. Select **User Inactivity in Okta**
3. Set duration to **35 days** (L2/L3) or **90 days** (L1)
4. Click **Save**

**Step 3: Configure Schedule**
1. Click the edit button next to **Select Schedule**
2. Set **Schedule** field to **Run Daily**
3. Set **Time** field to an appropriate time (e.g., 2:00 AM local time)
4. Click **Save**

**Step 4: Configure Scope**
1. Click the edit button next to **Select group membership**
2. In the **Applies to** field, select **Everyone**
3. Click **Save**

**Step 5: Configure Action**
1. Click **Add Action**
2. Select **Change User lifecycle state in Okta**
3. In **Change user state to**, select **Suspended**
4. Click **Save**

**Step 6: Activate Automation**
1. Click the **Inactive** button near the top of the screen
2. Select **Activate**

#### Validation
1. Navigate to: **Workflow → Automations**
2. Verify the automation is listed and shows **Active** status
3. Review the automation history after the first scheduled run

> **Note:** If Okta relies on external directory services (e.g., Active Directory) for user sourcing, this automation may not be applicable. The connected directory service must perform this function instead.

---

### 1.7 Configure PIV/CAC Smart Card Authentication

**Profile Level:** L3 (Maximum Security)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | IA-2(12) |
| DISA STIG | V-273204, V-273207 |

#### Description
Configure Okta to accept Personal Identity Verification (PIV) credentials and Common Access Cards (CAC) for authentication. This enables hardware-based multifactor authentication using approved certificate authorities.

#### Prerequisites
- [ ] Super Admin access
- [ ] Approved certificate chain (root and intermediate CA certificates)
- [ ] Smart Card IdP capability in your Okta edition

#### ClickOps Implementation

**Step 1: Add Smart Card Authenticator**
1. Navigate to: **Security → Authenticators**
2. In the **Setup** tab, click **Add authenticator**
3. Select the configured **Smart Card Identity Provider**
4. Complete the configuration and click **Add**

**Step 2: Configure Smart Card Identity Provider**
1. Navigate to: **Security → Identity Providers**
2. Click **Add identity provider**
3. Select **Smart Card IdP** and click **Next**
4. Enter a name for the identity provider (e.g., "CAC Authentication")

**Step 3: Build Certificate Chain**
1. Click **Browse** to select your root CA certificate file
2. Click **Add Another** to add intermediate CA certificates
3. Continue until the complete certificate chain is uploaded
4. Click **Build certificate chain**
5. Verify the chain builds successfully with all certificates shown
6. If errors occur, verify certificate order and format

**Step 4: Configure User Matching**
1. In **IdP username**, select **idpuser.subjectAltNameUpn**
   - This attribute stores identifiers like the Electronic Data Interchange Personnel Identifier (EDIPI)
2. In **Match Against**, select the Okta Profile Attribute where the identifier is stored
3. Click **Save**

**Step 5: Activate the Identity Provider**
1. Verify the IdP status shows **Active**
2. If inactive, click **Activate**

#### Validation
1. Navigate to: **Security → Identity Providers**
2. Verify Smart Card IdP is listed with **Type** as "Smart Card"
3. Verify **Status** is "Active"
4. Click **Actions → Configure** and verify certificate chain is from approved CA

---

### 1.8 Configure FIPS-Compliant Authenticators

**Profile Level:** L3 (Maximum Security)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SC-13 |
| DISA STIG | V-273205 |

#### Description
Configure Okta Verify to only connect with FIPS-compliant devices. This ensures that authentication uses FIPS 140-2 validated cryptographic modules.

#### Prerequisites
- [ ] Super Admin access
- [ ] Okta Verify authenticator enabled
- [ ] Users with FIPS-compliant devices (devices that support FIPS 140-2 mode)

#### ClickOps Implementation

**Step 1: Edit Okta Verify Settings**
1. Navigate to: **Security → Authenticators**
2. In the **Setup** tab, click **Edit** next to **Okta Verify**

**Step 2: Enable FIPS Compliance**
1. Locate the **FIPS Compliance** field
2. Select **FIPS-compliant devices only**
3. Click **Save**

#### Validation
1. Navigate to: **Security → Authenticators**
2. From the **Setup** tab, select **Edit Okta Verify**
3. Verify **FIPS Compliance** is set to "FIPS-compliant devices only"

> **Note:** Enabling FIPS-compliant devices only will prevent users with non-FIPS compliant devices from enrolling in Okta Verify. Ensure users have compatible devices before enabling this setting.

---

### 1.9 Audit Default Authentication Policy

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3, IA-2 |

#### Description
Audit and mitigate the risk posed by Okta's immutable Default Authentication Policy, which permits password-only login with no MFA requirement. This built-in policy acts as a catch-all backstop and cannot be modified or deleted. Any application or login flow that falls through to the default policy bypasses all MFA enforcement.

#### Rationale
**Why This Matters:**
- Okta ships with a "Default Policy" that allows single-factor (password-only) authentication
- This policy is immutable -- it cannot be edited, deleted, or reordered
- It serves as the final catch-all: any login not matched by a higher-priority policy silently falls through to the default
- New applications added to the tenant are assigned to the default policy unless explicitly moved
- Organizations often believe MFA is enforced globally, unaware that the default backstop allows password-only access

**Attack Prevented:** MFA bypass via policy gap exploitation. An attacker who discovers an application assigned to the default policy can authenticate with stolen credentials alone, completely circumventing phishing-resistant MFA controls configured in other policies.

**Real-World Context:**
- **Obsidian Security Research:** Identified that a significant percentage of Okta tenants have applications inadvertently assigned to the default policy, creating silent MFA gaps in otherwise hardened environments

#### ClickOps Implementation

**Step 1: Identify the Default Authentication Policy**
1. Navigate to: **Security → Authentication Policies**
2. Locate the policy named **"Default Policy"** -- it will be at the bottom of the policy list
3. Click the policy to inspect its rules
4. Note: The default rule permits access with **"Password"** only and cannot be changed

**Step 2: Audit Application Policy Assignments**
1. Navigate to: **Security → Authentication Policies**
2. For **each** authentication policy, click the **Applications** tab
3. Document which applications are assigned to each policy
4. **Critical:** Check the **Default Policy → Applications** tab
5. If ANY applications appear under the Default Policy, they are vulnerable to password-only login

**Step 3: Reassign Applications to Explicit Policies**
1. For each application assigned to the Default Policy:
   - Navigate to: **Applications → Applications → [App Name]**
   - Click the **Sign On** tab
   - Under **Authentication policy**, click **Edit**
   - Select an appropriate custom authentication policy that enforces MFA
   - Click **Save**
2. Repeat until the Default Policy has **zero** applications assigned

**Step 4: Create a Catch-All Deny Rule in Custom Policies**
1. Navigate to: **Security → Authentication Policies**
2. For each custom authentication policy:
   - Click **Add Rule**
   - Name: "Catch-All Deny"
   - **IF:** Any user, any device, any network
   - **THEN:** Access is **Denied**
   - Position this rule as the **second-to-last** rule (above only the default rule)
3. This ensures that any request not explicitly permitted by a higher-priority rule is denied rather than falling through

**Step 5: Establish Ongoing Governance**
1. Create a recurring calendar reminder (monthly) to re-audit policy assignments
2. Document the policy assignment standard in your security runbook
3. Include policy assignment verification in your application onboarding checklist

**Time to Complete:** ~45 minutes (initial audit) + 5 minutes per application reassignment

#### Code Implementation

{% include pack-code.html vendor="okta" section="1.9" %}

#### Validation & Testing
1. [ ] Run API query to list all apps assigned to the Default Policy -- result should be **zero applications**
2. [ ] Attempt login to a test application with password only -- should be denied by catch-all rule
3. [ ] Attempt login to a test application with password + MFA -- should succeed
4. [ ] Add a new test application and verify it is **not** automatically assigned to the Default Policy
5. [ ] Review System Log for `policy.evaluate_sign_on` events referencing the Default Policy -- should show no recent hits
6. [ ] Verify each custom policy has a catch-all deny rule as the second-to-last rule

**Expected result:** Zero applications assigned to the Default Policy; all authentication flows require MFA through explicit custom policies.

#### Monitoring & Maintenance

**Log query -- detect authentications hitting the Default Policy:**
```plaintext
eventType eq "policy.evaluate_sign_on" AND debugContext.debugData.policyType eq "ACCESS_POLICY" AND target.displayName eq "Default Policy"
```

**SIEM alert rule:**
```sql
-- Alert: Authentication via Default Policy (MFA bypass)
SELECT actor.displayName, client.ipAddress, outcome.result, published
FROM okta_system_log
WHERE eventType = 'policy.evaluate_sign_on'
  AND debugContext.debugData.behaviors LIKE '%Default Policy%'
ORDER BY published DESC
```

**Maintenance schedule:**
- **Weekly:** Automated script to check for apps on Default Policy (integrate into CI/CD)
- **Monthly:** Manual review of authentication policy assignments
- **On application onboarding:** Mandatory policy assignment as part of app deployment checklist
- **Quarterly:** Full audit of all policy rules and catch-all deny rule placement

---

### 1.10 Harden Self-Service Recovery

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | IA-5(1), IA-11 |

#### Description
Restrict self-service account recovery to trusted methods and network locations. Remove weak recovery options (SMS, voice call, security questions) that are susceptible to interception, SIM swapping, and social engineering. Limit recovery flows to corporate network zones to prevent account hijacking from untrusted locations.

#### Rationale
**Why This Matters:**
- Self-service password recovery is a primary account takeover vector -- attackers bypass MFA by resetting credentials
- SMS-based recovery is vulnerable to SIM swapping, SS7 interception, and carrier social engineering
- Voice call recovery is susceptible to call forwarding attacks and voicemail compromise
- Security questions can be researched or socially engineered (mother's maiden name, first pet, etc.)
- Recovery flows initiated from untrusted networks allow attackers to reset passwords remotely without triggering network-based controls
- Once an attacker resets a password, they can enroll their own MFA factors and establish persistent access

**Attack Prevented:** Account takeover via password recovery abuse. An attacker with access to a target's phone number (via SIM swap) or personal information (via OSINT) initiates self-service recovery, resets the password, enrolls a new authenticator, and gains persistent access to all SSO-connected applications.

**Real-World Context:**
- **Obsidian Security Research:** Identified that recovery flows from untrusted networks are a top account hijack technique, especially when SMS or security questions are enabled as recovery options

#### Prerequisites
- [ ] Super Admin access
- [ ] Network zones configured (see Section 2.1)
- [ ] Corporate network zone defined with VPN egress IPs
- [ ] Okta Verify or email-based authenticator deployed to users

#### ClickOps Implementation

**Step 1: Remove Weak Recovery Authenticators**
1. Navigate to: **Security → Authenticators**
2. Review the list of active authenticators
3. For **Phone (SMS/Voice)**:
   - Click **Actions → Edit**
   - Under **Used for**, uncheck **Recovery** (leave Authentication if still needed for non-admin users)
   - If SMS/Voice is not needed at all, click **Actions → Deactivate**
4. For **Security Question**:
   - Click **Actions → Deactivate**
   - Confirm deactivation
   - Note: Existing enrolled security questions will be removed from user accounts

**Step 2: Configure Password Recovery Settings**
1. Navigate to: **Security → Authenticators**
2. Click **Actions** next to **Password** → Select **Edit**
3. For each Password Policy listed, click **Edit**:
   - Locate the **Account Recovery** section
   - **Recovery authenticators:** Ensure only **Email** and **Okta Verify** are selected
   - **Phone (SMS/Voice call):** Uncheck / remove
   - **Security question:** Uncheck / remove
4. Click **Save** for each policy

**Step 3: Restrict Recovery to Corporate Network Zones**
1. Navigate to: **Security → Authentication Policies**
2. Select your primary authentication policy (or create a new one for recovery)
3. Click **Add Rule**:
   - **Name:** "Block Recovery from Untrusted Networks"
   - **IF:** Network zone is **NOT** "Corporate Network" (or your defined trusted zone)
   - **AND:** User is attempting self-service recovery
   - **THEN:** Access is **Denied**
4. Position this rule above your general allow rules
5. Click **Save**

**Step 4: Configure Authenticator Enrollment Policy**
1. Navigate to: **Security → Authenticators → Enrollment** tab
2. Edit the enrollment policy:
   - **Okta Verify:** Set to **Required**
   - **Email:** Set to **Required**
   - **Phone:** Set to **Disabled** or **Optional** (not for recovery)
   - **Security Question:** Set to **Disabled**
3. Click **Save**

**Step 5: Test Recovery Flow**
1. From a corporate network IP, initiate a test password recovery
2. Verify only email and authenticator-based options are presented
3. From an external/untrusted IP, attempt recovery -- verify it is blocked or requires step-up

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="okta" section="1.10" %}

#### Validation & Testing
1. [ ] Navigate to **Security → Authenticators** and verify Security Question shows **Inactive**
2. [ ] Navigate to **Security → Authenticators → Password → Edit** and verify SMS, Voice, and Security Question are disabled for recovery
3. [ ] Initiate a password reset from a **corporate network IP** -- verify only Email and Okta Verify options appear
4. [ ] Initiate a password reset from an **external/untrusted IP** -- verify the request is blocked or requires additional verification
5. [ ] Attempt to enroll a security question as a user -- should not be available
6. [ ] Review System Log for `user.account.reset_password` events and verify they originate only from trusted network zones
7. [ ] Verify recovery token lifetime is set to 10 minutes or less

**Expected result:** Self-service recovery limited to email and authenticator-based methods; no SMS, voice, or security question options; recovery blocked from untrusted networks.

#### Monitoring & Maintenance

**Log query -- detect recovery attempts from untrusted networks:**
```plaintext
eventType eq "user.account.reset_password" AND securityContext.isProxy eq true
```

**SIEM alert rules:**
```sql
-- Alert: Password recovery from non-corporate IP
SELECT actor.displayName, client.ipAddress, client.geographicalContext.city,
       client.geographicalContext.country, outcome.result, published
FROM okta_system_log
WHERE eventType IN ('user.account.reset_password', 'user.credential.forgot_password')
  AND client.ipAddress NOT IN (SELECT ip FROM corporate_ip_ranges)
ORDER BY published DESC

-- Alert: SMS/Voice recovery attempt (should not occur after hardening)
SELECT actor.displayName, client.ipAddress, outcome.result, published
FROM okta_system_log
WHERE eventType = 'user.account.reset_password'
  AND debugContext.debugData.factor IN ('SMS', 'CALL', 'QUESTION')
ORDER BY published DESC
```

**Maintenance schedule:**
- **Monthly:** Verify authenticator enrollment policy still disables weak recovery options
- **Quarterly:** Audit recovery events in System Log for anomalies
- **On policy changes:** Re-verify that recovery restrictions remain in place after any authenticator or policy modifications
- **Annually:** Review recovery methods against current threat landscape (new attack techniques against remaining methods)

---

### 1.11 Enable End-User Security Notifications

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SI-4, IR-6 |

#### Description
Enable all five end-user security notification types in Okta so that users receive immediate alerts when security-relevant changes occur on their accounts. Additionally enable Suspicious Activity Reporting to allow users to flag unauthorized actions directly from notification emails, creating actionable system log events for security teams.

#### Rationale
**Why This Matters:**
- End users are often the first to notice unauthorized access to their accounts -- a notification about an unrecognized sign-on or authenticator change prompts immediate reporting
- Without notifications, an attacker who compromises an account can operate undetected for days or weeks while enrolling new factors, changing passwords, and accessing applications
- Authenticator enrolled/reset notifications detect a critical persistence technique: attackers who gain temporary access immediately register their own MFA factors to maintain access after the initial vector is closed
- Suspicious Activity Reporting turns every user into a sensor -- when a user clicks "Report Suspicious Activity" in a notification email, Okta generates a `user.account.report_suspicious_activity_by_enduser` system log event that SIEM can automatically escalate
- These notifications cost nothing to enable and provide significant detection value with no user friction

**Attack Prevented:** Undetected account takeover and persistence. An attacker who compromises credentials and enrolls a new authenticator will trigger an "authenticator enrolled" notification to the legitimate user, who can immediately report the unauthorized change before the attacker establishes persistent access.

**Real-World Context:**
- **Okta HealthInsight:** Flags missing end-user notifications as a security gap in tenant health assessments
- **Obsidian Security Research:** Recommends all five notification types as a low-effort, high-value detection control

#### ClickOps Implementation

**Step 1: Enable End-User Notification Types**
1. Navigate to: **Settings → Account**
2. Scroll to the **End-User Notifications** section
3. Enable **all five** notification types:

| Notification | Description | Enable |
|-------------|-------------|--------|
| **New sign-on notification** | Alerts users when a sign-on occurs from an unrecognized device or browser | Yes |
| **Authenticator enrolled notification** | Alerts users when a new authenticator (MFA factor) is registered to their account | Yes |
| **Authenticator reset notification** | Alerts users when an authenticator is removed or reset on their account | Yes |
| **Password changed notification** | Alerts users when their password is changed | Yes |
| **MFA factor reset notification** | Alerts users when an MFA factor is reset by an administrator | Yes |

4. Click **Save**

**Step 2: Enable Suspicious Activity Reporting**
1. Navigate to: **Security → General**
2. Scroll to the **Suspicious Activity Reporting** section
3. Set to **Enabled**
4. Click **Save**
5. When enabled, notification emails include a **"Report Suspicious Activity"** button
6. User clicks generate a system log event: `user.account.report_suspicious_activity_by_enduser`

**Step 3: Verify Notification Delivery**
1. Using a test user account, perform a sign-on from a new browser or device
2. Verify the test user receives a "New sign-on" notification email
3. Verify the email contains the "Report Suspicious Activity" button (if Suspicious Activity Reporting is enabled)
4. Click "Report Suspicious Activity" and verify the system log event is created

**Step 4: Configure SIEM Alerting for Suspicious Activity Reports**
1. In your SIEM, create a high-priority alert for the event type `user.account.report_suspicious_activity_by_enduser`
2. This event should trigger an immediate incident response workflow
3. Correlate with recent authentication and factor enrollment events for the reporting user

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="okta" section="1.11" %}

#### Validation & Testing
1. [ ] Navigate to **Settings → Account → End-User Notifications** and verify all five notification types are **Enabled**
2. [ ] Navigate to **Security → General → Suspicious Activity Reporting** and verify it is **Enabled**
3. [ ] Sign in with a test user from a new device/browser -- verify "New sign-on" email is received
4. [ ] Enroll a new authenticator for a test user -- verify "Authenticator enrolled" email is received
5. [ ] Reset an authenticator for a test user -- verify "Authenticator reset" email is received
6. [ ] Change a test user's password -- verify "Password changed" email is received
7. [ ] In a notification email, click **"Report Suspicious Activity"** -- verify the system log event `user.account.report_suspicious_activity_by_enduser` is created
8. [ ] Verify SIEM alert fires for the suspicious activity report event

**Expected result:** All five notification types active; users receive timely emails for security-relevant account changes; suspicious activity reports generate system log events that trigger SIEM alerts.

#### Monitoring & Maintenance

**Log query -- suspicious activity reports from end users:**
```plaintext
eventType eq "user.account.report_suspicious_activity_by_enduser"
```

**Log query -- authenticator changes (correlate with user reports):**
```plaintext
eventType sw "user.mfa.factor" OR eventType eq "user.account.update_password"
```

**SIEM alert rules:**
```sql
-- HIGH PRIORITY: User reported suspicious activity
SELECT actor.displayName, actor.alternateId, client.ipAddress,
       client.geographicalContext.city, client.geographicalContext.country,
       outcome.result, published
FROM okta_system_log
WHERE eventType = 'user.account.report_suspicious_activity_by_enduser'
ORDER BY published DESC

-- MEDIUM PRIORITY: Authenticator enrolled from unrecognized location
-- (Correlate with new sign-on notifications)
SELECT actor.displayName, target.displayName AS authenticator_type,
       client.ipAddress, client.userAgent.rawUserAgent, published
FROM okta_system_log
WHERE eventType IN (
  'user.mfa.factor.activate',
  'user.mfa.factor.enroll',
  'system.mfa.factor.activate'
)
ORDER BY published DESC
```

**Incident response workflow for suspicious activity reports:**
1. SIEM receives `user.account.report_suspicious_activity_by_enduser` event
2. Automatically create incident ticket with HIGH priority
3. Pull last 24 hours of authentication and factor events for the reporting user
4. Check for: new factor enrollments, password changes, sign-ons from unusual locations
5. If compromise indicators found: suspend user session, force re-authentication, reset factors

**Maintenance schedule:**
- **Monthly:** Review suspicious activity report volume and response times
- **Quarterly:** Verify all five notification types are still enabled (configuration drift check)
- **Quarterly:** Test notification delivery by performing a controlled sign-on from a new device
- **Annually:** Review notification types against Okta feature updates (new notification types may be added)

---

## 2. Network Access Controls

### 2.1 Configure IP Zones and Network Policies

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.3 |
| NIST 800-53 | AC-3, SC-7 |

#### Description
Define network zones (corporate, VPN, known bad) and enforce authentication policies based on network location. Block or require step-up authentication from untrusted networks.

#### Rationale
**Why This Matters:**
- Attackers often operate from non-corporate infrastructure
- IP-based policies add defense layer even if credentials stolen
- Enables geographic restrictions for compliance

**Attack Prevented:** Credential stuffing from botnets, unauthorized access from foreign locations

#### ClickOps Implementation

**Step 1: Define Network Zones**
1. Navigate to: **Security → Networks**
2. Create zones:

**Corporate Network:**
- Type: IP Zone
- IPs: Your office CIDR ranges
- Gateway IPs: VPN egress IPs

**Blocked Locations:**
- Type: Dynamic Zone
- Block: TOR exit nodes, known-bad IP ranges
- Use threat intelligence feeds

**Step 2: Create Zone-Based Authentication Policy**
1. Navigate to: **Security → Authentication Policies**
2. Add rule:
   - **IF:** Network zone = "Not Corporate"
   - **THEN:** Require MFA + limit session duration
3. Add rule:
   - **IF:** Network zone = "Blocked Locations"
   - **THEN:** Deny access

#### Code Implementation

{% include pack-code.html vendor="okta" section="2.1" %}

---

### 2.2 Restrict Admin Console Access by IP

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3(7) |

#### Description
Limit access to the Okta Admin Console to specific IP ranges (corporate network, VPN, security team IPs).

#### ClickOps Implementation

1. Navigate to: **Security → General**
2. Under **Okta Admin Console**, configure:
   - **Allowed IPs:** Add corporate network ranges
   - **Block all other IPs:** Enable
3. Test access from allowed IP before enforcement

**Warning:** Ensure break-glass procedure for lockout scenarios.

---

### 2.3 Configure Dynamic Network Zones and Anonymizer Blocking

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SC-7, AC-3 |

#### Description
Activate Okta's Enhanced Dynamic Zone to automatically block traffic from anonymizing proxies, Tor exit nodes, and residential proxies. The `DefaultEnhancedDynamicZone` ships inactive by default and must be explicitly activated.

#### Rationale
**Why This Matters:**
- Attackers use anonymizing proxies, Tor, and VPNs to hide their origin during credential stuffing and session replay attacks
- Okta's Enhanced Dynamic Zones leverage IP intelligence to categorize traffic sources automatically
- The default zone exists but is INACTIVE — many organizations don't know it's available
- Blocking anonymizers reduces attack surface without impacting legitimate users

**Attack Prevented:** Credential stuffing via anonymized infrastructure, session replay from Tor/proxy networks

#### ClickOps Implementation

**Step 1: Activate Enhanced Dynamic Zone**
1. Navigate to: **Security → Networks**
2. Locate **DefaultEnhancedDynamicZone** in the zone list
3. Click **Edit**
4. Change **Zone Status** to **Active**
5. Set **Usage** to **Blocklist**
6. Click **Save**

**Step 2: Configure Blocked IP Categories**
1. In the Enhanced Dynamic Zone settings, select categories to block:
   - **Anonymizing Proxies:** ☑ Checked
   - **Tor Exit Nodes:** ☑ Checked
   - **Residential Proxies:** ☑ Checked (optional, may impact remote workers using ISP proxies)
2. Click **Save**

**Step 3: Apply to Authentication Policies**
1. Navigate to: **Security → Authentication Policies**
2. For each policy, add a rule:
   - **IF:** Network zone = "DefaultEnhancedDynamicZone"
   - **THEN:** Deny access
3. Position this rule with higher priority than allow rules

**Step 4: Configure Geographic Restrictions (Optional)**
1. Navigate to: **Security → Networks**
2. Click **Add Zone** → **Dynamic Zone**
3. Configure:
   - **Name:** "Blocked Countries"
   - **Locations:** Select countries where your organization has no users
   - **Usage:** Blocklist
4. Add deny rule in authentication policies for this zone

#### Code Implementation

{% include pack-code.html vendor="okta" section="2.3" %}

#### Validation & Testing
1. [ ] Navigate to **Security → Networks** and verify DefaultEnhancedDynamicZone shows **Active** status
2. [ ] Verify zone usage is set to **Blocklist**
3. [ ] Test access from a Tor exit node or known anonymizing proxy — should be denied
4. [ ] Verify legitimate users on corporate VPN are not affected

#### Monitoring & Maintenance
**Log query:**
```plaintext
eventType eq "security.threat.detected" AND debugContext.debugData.threatSuspected eq "ANONYMIZER"
```

**Maintenance schedule:**
- **Monthly:** Review blocked traffic patterns for false positives
- **Quarterly:** Update geographic restrictions based on business expansion

---

## 3. OAuth & Integration Security

### 3.1 Implement OAuth App Consent Policies

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-6, CM-7 |

#### Description
Control which OAuth applications users can authorize and require admin approval for new app integrations. Prevent shadow IT through unconsented OAuth grants.

#### Rationale
**Why This Matters:**
- Okta's 7,000+ integrations create massive attack surface
- Malicious apps can request broad OAuth scopes
- Unconsented apps bypass security review

**Attack Prevented:** OAuth phishing, malicious app consent, shadow IT

#### ClickOps Implementation

**Step 1: Configure App Integration Policies**
1. Navigate to: **Applications → App Integration Policies**
2. Create policy:
   - **Name:** "Require Admin Approval for New Apps"
   - **Scope:** All users except Admins
   - **Action:** Require admin approval for user-initiated apps

**Step 2: Review Existing App Grants**
1. Navigate to: **Reports → Application Access Audit**
2. Export list of all OAuth grants
3. Review for over-permissioned or suspicious apps
4. Revoke unnecessary grants

**Step 3: Restrict API Token Creation**
1. Navigate to: **Security → API → Tokens**
2. Review existing tokens
3. Configure:
   - Require admin approval for new tokens
   - Set expiration policies (max 90 days)

#### Code Implementation

```bash
# List all OAuth app grants
curl -X GET "https://${OKTA_DOMAIN}/api/v1/apps?filter=status%20eq%20%22ACTIVE%22" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \

  | jq '.[] | {name: .name, signOnMode: .signOnMode, created: .created}'

# Audit OAuth tokens
curl -X GET "https://${OKTA_DOMAIN}/api/v1/authorizationServers/default/clients" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}"
```

{% include pack-code.html vendor="okta" section="3.1" %}

---

### 3.2 Harden SCIM Provisioning Connectors

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-2, IA-4 |

#### Description
Secure SCIM (System for Cross-domain Identity Management) connectors that provision/deprovision users to downstream applications. SCIM tokens enable identity manipulation across connected apps.

#### Rationale
**Why This Matters:**
- SCIM connectors create/delete users in downstream apps
- Compromised SCIM tokens enable backdoor account creation
- Unlimited token validity creates persistent risk

**Attack Scenario:** Attacker steals SCIM token, creates backdoor accounts in connected SaaS apps

#### ClickOps Implementation

**Step 1: Audit SCIM-Enabled Apps**
1. Navigate to: **Applications → Applications**
2. Filter by: Provisioning = Enabled
3. Document all SCIM integrations

**Step 2: Rotate SCIM Tokens**
1. For each SCIM-enabled app:
   - Navigate to app → **Provisioning** tab
   - Regenerate API token
   - Update receiving application
2. Document token rotation schedule (quarterly minimum)

**Step 3: Limit SCIM Scope**
1. Configure provisioning to sync only required attributes
2. Disable "Sync Password" unless required
3. Enable "Group Push" only for necessary groups

#### Monitoring
```plaintext
eventType eq "system.scim.user.create" OR eventType eq "system.scim.user.update"
```

{% include pack-code.html vendor="okta" section="3.2" %}

---

### 3.3 Implement OAuth Application Allowlisting

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | CM-7, AC-6 |

#### Description
Restrict which third-party applications can receive OAuth grants from users. OAuth consent phishing is a growing attack vector where malicious applications request broad scopes to access organizational data through user consent flows.

#### Rationale
**Why This Matters:**
- Over-privileged OAuth tokens from third-party integrations enable supply chain attacks
- Users can unknowingly grant broad access to malicious applications via consent phishing
- SaaS-to-SaaS connections create hidden trust relationships that bypass traditional security controls
- Unsanctioned apps with broad OAuth scopes create persistent backdoors

**Attack Prevented:** OAuth consent phishing, supply chain compromise via over-privileged integrations, shadow IT

#### ClickOps Implementation

**Step 1: Review Existing OAuth Grants**
1. Navigate to: **Applications → Applications**
2. Filter by: Sign-on method = **OpenID Connect** or **OAuth 2.0**
3. For each application, click **Okta API Scopes** tab
4. Document all granted scopes — flag any with `okta.users.manage`, `okta.apps.manage`, or `okta.authorizationServers.manage`

**Step 2: Configure App Integration Policies**
1. Navigate to: **Settings → Account → App Integration Settings**
2. Under **User app requests:**
   - Select **Require admin approval for user-initiated app integrations**
3. Under **Third-party app consent:**
   - Select **Only allow pre-approved applications**
4. Click **Save**

**Step 3: Audit API Scopes for Each Application**
1. Navigate to: **Security → API → Authorization Servers**
2. Select the **default** authorization server
3. Click **Scopes** tab — review all custom scopes
4. Click **Access Policies** tab — verify policies restrict token issuance to approved clients

**Step 4: Create Regular Grant Review Process**
1. Export OAuth grant report monthly
2. Revoke grants for applications no longer in use
3. Alert on new OAuth consent events

#### Code Implementation

```bash
# List all active applications with OAuth/OIDC sign-on
curl -s -X GET "https://${OKTA_DOMAIN}/api/v1/apps?filter=status%20eq%20%22ACTIVE%22" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  | jq '.[] | select(.signOnMode == "OPENID_CONNECT" or .signOnMode == "OAUTH_2_0") | {id: .id, label: .label, signOnMode: .signOnMode}'

# List OAuth grants for a specific user
curl -s -X GET "https://${OKTA_DOMAIN}/api/v1/users/${USER_ID}/grants" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  | jq '.[] | {id: .id, clientId: .clientId, scopeId: .scopeId, status: .status}'

# Revoke a specific OAuth grant
curl -X DELETE "https://${OKTA_DOMAIN}/api/v1/users/${USER_ID}/grants/${GRANT_ID}" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}"

# List all clients on the default authorization server
curl -s -X GET "https://${OKTA_DOMAIN}/api/v1/authorizationServers/default/clients" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  | jq '.[] | {client_id: .client_id, client_name: .client_name}'
```

{% include pack-code.html vendor="okta" section="3.3" %}

#### Validation & Testing
1. [ ] Verify admin approval is required for new app integrations
2. [ ] Attempt to add an unauthorized OAuth application as a standard user — should require admin approval
3. [ ] Confirm no applications have overly broad scopes (`*.manage`, `*.write`) unless justified

#### Monitoring & Maintenance
**Log query:**
```plaintext
eventType eq "app.oauth2.consent.grant" OR eventType eq "app.oauth2.as.consent.grant"
```

**Maintenance schedule:**
- **Monthly:** Review OAuth consent grants across all users
- **Quarterly:** Audit application scopes and remove excessive permissions
- **On new integration:** Require security review before OAuth grant approval

---

### 3.4 Govern Non-Human Identities (NHI)

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | IA-4, IA-5, AC-2 |
| DISA STIG | v1.1 NHI Controls (Feb 2026) |

#### Description
Implement governance for non-human identities: service accounts, API tokens, automation accounts, and machine-to-machine (M2M) integrations. Migrate from static SSWS API tokens to OAuth 2.0 for API access. NHI compromise is a leading cause of identity-based breaches and is now covered by DISA STIG v1.1.

#### Rationale
**Why This Matters:**
- The October 2023 Okta breach was caused by a compromised service account whose credentials were saved to a personal Google profile
- Static SSWS API tokens never expire unless manually revoked, creating persistent access risk
- Service accounts tied to individual admin users become orphaned when that admin leaves
- OAuth 2.0 provides shorter token lifespans, granular scopes, and automatic key rotation vs static SSWS
- DISA STIG v1.1 (Feb 2026) adds five new checks specifically for NHI security

**Attack Prevented:** Service account compromise, API token theft and replay, persistent unauthorized access via stale tokens

**Real-World Incidents:**
- **October 2023:** Compromised service account credentials stored in personal Google profile enabled breach of Okta support system

#### ClickOps Implementation

**Step 1: Audit All API Tokens**
1. Navigate to: **Security → API → Tokens**
2. Document all active tokens:
   - Token name and purpose
   - Created by (which admin)
   - Created date
   - Last used date
   - Network restrictions (if any)
3. Flag tokens with no activity in 90+ days for deactivation
4. Flag tokens created by users who are no longer active

**Step 2: Add IP Restrictions to Existing SSWS Tokens**
1. For each active SSWS token:
   - Navigate to: **Security → API → Tokens**
   - Click the token name
   - Under **Network**, select a specific network zone (e.g., "Corporate Network" or "Automation Servers")
   - Click **Save**
2. This limits where stolen tokens can be replayed from

**Step 3: Create OAuth 2.0 Service Apps (Migration)**
1. Navigate to: **Applications → Applications**
2. Click **Create App Integration**
3. Select **API Services** → **Next**
4. Configure:
   - **App integration name:** "[Service Name] API Access"
   - **Grant type:** Client Credentials
   - **Client authentication:** Public key / Private key (recommended) or Client secret
5. Under **Okta API Scopes**, grant ONLY the minimum required scopes
6. Click **Save**
7. Configure token lifetime: **Security → API → Authorization Servers → default → Access Policies**

**Step 4: Create Dedicated Service Accounts**
1. Navigate to: **Directory → People**
2. Click **Add Person**
3. Create a dedicated service account:
   - **First name:** "SVC"
   - **Last name:** "[Service Name]"
   - **Username:** "svc-[service]@yourdomain.com"
   - **User type:** Set to a custom "Service Account" type if available
4. Assign minimum-required admin role (custom role preferred over built-in)
5. Never use personal admin accounts for service/automation purposes

**Step 5: Establish Token Rotation Policy**
1. Document token rotation schedule:
   - **SSWS tokens (legacy):** Rotate every 90 days maximum
   - **OAuth 2.0 client secrets:** Rotate every 180 days
   - **OAuth 2.0 private keys:** Rotate annually
2. Set calendar reminders for rotation dates
3. Include token rotation in operational runbooks

#### Code Implementation

```bash
# List all active API tokens
curl -s -X GET "https://${OKTA_DOMAIN}/api/v1/api-tokens" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  | jq '.[] | {id: .id, name: .name, userId: .userId, clientName: .clientName, created: .created, lastUpdated: .lastUpdated, network: .network}'

# Create an OAuth 2.0 service app (client credentials)
curl -X POST "https://${OKTA_DOMAIN}/api/v1/apps" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "oidc_client",
    "label": "SVC - Automation API Access",
    "signOnMode": "OPENID_CONNECT",
    "credentials": {
      "oauthClient": {
        "token_endpoint_auth_method": "private_key_jwt",
        "autoKeyRotation": true
      }
    },
    "settings": {
      "oauthClient": {
        "grant_types": ["client_credentials"],
        "response_types": ["token"],
        "application_type": "service"
      }
    }
  }'

# Grant specific API scopes to the service app
curl -X PUT "https://${OKTA_DOMAIN}/api/v1/apps/${APP_ID}/grants" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "scopeId": "okta.users.read",
    "issuer": "https://${OKTA_DOMAIN}"
  }'

# Revoke a stale API token
curl -X DELETE "https://${OKTA_DOMAIN}/api/v1/api-tokens/${TOKEN_ID}" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}"
```

{% include pack-code.html vendor="okta" section="3.4" %}

#### SSWS to OAuth 2.0 Migration Checklist
- [ ] Inventory all active SSWS tokens and their consumers
- [ ] Create OAuth 2.0 service app for each integration
- [ ] Generate and distribute private keys to consuming services
- [ ] Update consuming services to use OAuth 2.0 client credentials flow
- [ ] Test each integration with OAuth 2.0 tokens
- [ ] Add IP restrictions to SSWS tokens during transition (as fallback)
- [ ] Revoke SSWS tokens after successful migration verification
- [ ] Document new OAuth 2.0 credentials and rotation schedule

#### Validation & Testing
1. [ ] Verify all API tokens have network restrictions applied
2. [ ] Confirm no tokens are older than 90 days without documented exception
3. [ ] Test OAuth 2.0 service app authentication using client credentials flow
4. [ ] Verify no SSWS tokens are assigned to personal admin accounts used by humans

#### Monitoring & Maintenance
**Log query:**
```plaintext
eventType eq "system.api_token.create" OR eventType eq "system.api_token.revoke" OR eventType eq "app.oauth2.token.grant"
```

**Maintenance schedule:**
- **Monthly:** Review API token usage (flag tokens with no recent activity)
- **Quarterly:** Rotate SSWS tokens and OAuth 2.0 client secrets
- **On employee departure:** Audit and reassign any tokens created by departing admin
- **Annually:** Rotate OAuth 2.0 private keys

---

## 4. Session Management

### 4.1 Configure Session Timeouts

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-12, SC-10 |
| DISA STIG | V-273186, V-273187, V-273203 |

#### Description
Set session timeouts appropriate to risk level. Reduce maximum session lifetime and enforce re-authentication for sensitive applications.

#### Rationale
**Why This Matters:**
- Long sessions increase window for session hijacking
- October 2023 breach exploited long-lived session cookies
- Idle timeouts reduce exposure from abandoned sessions

#### Specification Requirements

| Setting | L1 (Baseline) | L2 (Hardened) | L3/DISA STIG |
|---------|---------------|---------------|--------------|
| Max session lifetime | 12 hours | 8 hours | 18 hours |
| Max idle time | 1 hour | 30 minutes | 15 minutes |
| Admin Console idle time | 30 minutes | 15 minutes | 15 minutes |
| Persistent sessions | Optional | Disabled | Disabled |

#### ClickOps Implementation

**Step 1: Configure Global Session Policy**
1. Navigate to: **Security → Global Session Policy**
2. Select the **Default Policy**
3. Click **Add rule** (create a custom rule at Priority 1, not the "Default Rule")
4. Configure settings per the specification requirements table above

**Step 2: Configure Admin Console Session Timeout**
1. Navigate to: **Applications → Applications → Okta Admin Console**
2. Click the **Sign On** tab
3. Under "Okta Admin Console session", set:
   - **Maximum app session idle time:** 15 minutes (L2/L3)

**Step 3: Create App-Specific Session Policies**
For sensitive apps (PAM, admin consoles, financial systems):
1. Navigate to app → **Sign On** tab
2. Configure:
   - **Session lifetime:** 2 hours max
   - **Re-authentication:** Required on every access

{% include pack-code.html vendor="okta" section="4.1" %}

---

### 4.2 Disable Session Persistence

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SC-23 |
| DISA STIG | V-273206 |

#### Description
Disable "Remember Me" and persistent session features that increase session hijacking risk. Persistent global session cookies allow sessions to survive browser restarts, which extends the window for session hijacking.

#### ClickOps Implementation

1. Navigate to: **Security → Global Session Policy**
2. Select the **Default Policy**
3. Click **Add rule** (create a custom rule at Priority 1)
4. Disable:
   - **Remember my device for MFA**
   - **Okta global session cookies persist across browser sessions:** Disabled
   - **Stay signed in for:** Set to minimum
5. Navigate to: **Customizations → Other**
6. Disable: **Allow users to remain signed in**

{% include pack-code.html vendor="okta" section="4.2" %}

---

### 4.3 Configure Admin Session Security

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SC-23, AC-12 |

#### Description
Harden admin sessions with ASN binding, IP binding, and Protected Actions. These controls prevent session hijacking by invalidating admin sessions when network characteristics change, and require step-up authentication before critical operations.

#### Rationale
**Why This Matters:**
- The October 2023 breach demonstrated that stolen admin session tokens can be replayed from any network
- Admin Session ASN Binding invalidates sessions when the Autonomous System Number changes (e.g., attacker replays from a different ISP)
- Admin Session IP Binding is more restrictive — invalidates on any IP change
- Protected Actions require step-up authentication before high-impact operations like creating IdPs or resetting MFA factors
- These are post-breach product enhancements specifically designed to prevent session hijacking

**Attack Prevented:** Admin session hijacking, stolen session token replay, unauthorized critical operations

**Real-World Incidents:**
- **October 2023:** Stolen HAR file session tokens replayed from attacker infrastructure to access admin consoles

#### ClickOps Implementation

**Step 1: Verify Admin Session ASN Binding (Enabled by Default)**
1. Navigate to: **Security → General**
2. Scroll to **Admin Session Settings**
3. Verify **Bind admin sessions to ASN** is **ON**
4. If not enabled, toggle it **ON** and click **Save**

**Step 2: Enable Admin Session IP Binding (Recommended for L2+)**
1. Navigate to: **Security → General**
2. Under **Admin Session Settings**:
   - Enable **Bind admin sessions to IP address**
3. Click **Save**

> **Note:** IP binding may cause disruptions for admins on dynamic IP addresses or mobile networks. Test with a pilot group before enforcing broadly.

**Step 3: Enable Protected Actions**
1. Navigate to: **Security → General**
2. Scroll to **Protected Actions**
3. Click **Edit**
4. Enable Protected Actions and select the operations that require step-up authentication:
   - ☑ Activate/deactivate identity providers
   - ☑ Create/modify identity providers
   - ☑ Reset user MFA factors
   - ☑ Modify authentication policies
   - ☑ Create/modify admin role assignments
   - ☑ Modify network zones
5. Set **Authenticator requirement:** Phishing-resistant (FIDO2/WebAuthn)
6. Click **Save**

**Step 4: Disable MFA Device Remembrance for Admin Sessions**
1. Navigate to: **Security → Authentication Policies**
2. Select the **Okta Admin Console** policy
3. Edit the active rule:
   - Set **MFA remember device:** Disabled (require MFA every session)
   - Set **Re-authentication frequency:** Every sign-in attempt
4. Click **Save**

#### Code Implementation

```bash
# Check current admin session settings
curl -s -X GET "https://${OKTA_DOMAIN}/api/v1/org/settings" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  | jq '{adminSessionASNBinding: .adminSessionASNBinding, adminSessionIPBinding: .adminSessionIPBinding}'

# Enable ASN and IP binding
curl -X PUT "https://${OKTA_DOMAIN}/api/v1/org/settings" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "adminSessionASNBinding": "ENABLED",
    "adminSessionIPBinding": "ENABLED"
  }'
```

{% include pack-code.html vendor="okta" section="4.3" %}

#### Validation & Testing
1. [ ] Verify ASN binding is active: Navigate to **Security → General → Admin Session Settings**
2. [ ] Verify IP binding is active (if applicable)
3. [ ] Test Protected Actions: Attempt to modify an IdP — should prompt for step-up authentication
4. [ ] Test session invalidation: Log in as admin, change network (e.g., switch from WiFi to VPN) — session should be invalidated if IP binding is enabled

#### Monitoring & Maintenance
**Log query:**
```plaintext
eventType eq "user.session.invalidate" AND debugContext.debugData.reason eq "ADMIN_SESSION_BINDING"
```

**Log query for Protected Actions:**
```plaintext
eventType eq "system.protected_action.challenge" OR eventType eq "system.protected_action.success"
```

**Maintenance schedule:**
- **Monthly:** Review Protected Actions audit log for any failures or unusual patterns
- **Quarterly:** Review IP binding exceptions for admins on dynamic networks

---

## 5. Monitoring & Detection

### 5.1 Enable Comprehensive System Logging

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AU-2, AU-3, AU-6 |
| DISA STIG | V-273202 (HIGH) |

#### Description
Configure Okta System Log forwarding to SIEM with comprehensive event capture for security monitoring and incident response.

#### ClickOps Implementation

**Step 1: Configure Log Streaming**
1. Navigate to: **Reports → Log Streaming**
2. Click **Add Log Stream**
3. Select integration type:
   - **AWS EventBridge** - For AWS-based SIEM solutions
   - **Splunk Cloud** - For Splunk deployments
4. Complete the required configuration fields
5. Click **Save** and verify the connection is **Active**

**Step 2: Alternative - Okta Log API Integration**
If your SIEM is not directly supported:
1. Navigate to: **Security → API → Tokens**
2. Create an API token with read-only System Log permissions
3. Configure your SIEM to pull logs via the System Log API endpoint

**Step 3: Create Alert Rules (via SIEM)**
```sql
-- Detect impossible travel
SELECT user, sourceIp, geo_country, timestamp
FROM okta_logs
WHERE eventType = 'user.authentication.sso'
  AND geo_country_change_within_1hr = true

-- Detect brute force
SELECT user, count(*) as attempts
FROM okta_logs
WHERE eventType = 'user.authentication.failed'
  AND timestamp > now() - interval '5 minutes'
GROUP BY user
HAVING count(*) > 10

-- Detect admin role changes
SELECT actor, target, eventType, timestamp
FROM okta_logs
WHERE eventType LIKE 'system.role%'
  OR eventType LIKE 'group.user_membership%admin%'
```

{% include pack-code.html vendor="okta" section="5.1" %}

---

### 5.2 Configure ThreatInsight

**Profile Level:** L1 (Baseline)

#### Description
Enable Okta ThreatInsight to automatically block authentication from known-malicious IPs based on Okta's threat intelligence.

#### ClickOps Implementation

1. Navigate to: **Security → General**
2. Under **Okta ThreatInsight**:
   - **Action:** Block
   - **Exempt IPs:** Add known testing IPs if needed
3. Save

{% include pack-code.html vendor="okta" section="5.2" %}

---

### 5.3 Enable Identity Threat Protection (ITP)

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SI-4, RA-5 |

#### Description
Enable Identity Threat Protection with Okta AI for continuous post-authentication risk evaluation. Unlike traditional MFA (authentication-time only), ITP evaluates risk signals during active sessions and can automatically terminate sessions, require step-up MFA, or trigger Workflows responses in real-time.

#### Rationale
**Why This Matters:**
- Traditional authentication is a point-in-time check — once past MFA, an attacker has free access until the session expires
- ITP continuously evaluates risk signals: session anomalies, impossible travel, credential compromise intelligence
- Aligns with NIST 800-63-4's Digital Identity Risk Management (DIRM) framework for continuous risk evaluation
- Can automatically respond to detected threats without human intervention

**Attack Prevented:** Session hijacking detected post-authentication, compromised credential use, anomalous session behavior

#### Prerequisites
- [ ] Okta Identity Threat Protection license (add-on to Okta Identity Engine)
- [ ] Super Admin access
- [ ] SIEM integration configured (to receive ITP events)

#### ClickOps Implementation

**Step 1: Enable Identity Threat Protection**
1. Navigate to: **Security → Identity Threat Protection**
2. Click **Enable ITP**
3. Review the default risk policies

**Step 2: Configure Risk Policies**
1. Navigate to: **Security → Identity Threat Protection → Policies**
2. Configure response actions for each risk level:

| Risk Level | Recommended Action |
|-----------|-------------------|
| Low | Log only |
| Medium | Require step-up MFA |
| High | Terminate session immediately |
| Critical | Terminate session + lock account |

3. Click **Save**

**Step 3: Configure Session Risk Evaluation**
1. Navigate to: **Security → Authentication Policies**
2. Edit rules to include: **Evaluate risk with ITP** = Enabled
3. Set re-authentication triggers based on risk score changes

**Step 4: Integrate with Okta Workflows (Optional)**
1. Navigate to: **Workflow → Flows**
2. Create a flow triggered by **ITP Risk Event**
3. Configure automated response actions:
   - Send Slack/Teams alert to security team
   - Create ticket in ITSM
   - Revoke active sessions for affected user
   - Add source IP to dynamic blocklist

#### Monitoring & Maintenance
**Log query:**
```plaintext
eventType eq "security.threat.detected" OR eventType eq "security.session.risk_change"
```

**SIEM alert rule:**
```sql
SELECT actor.displayName, client.ipAddress, outcome.result,
       debugContext.debugData.riskLevel, debugContext.debugData.riskReasons
FROM okta_system_log
WHERE eventType = 'security.threat.detected'
  AND debugContext.debugData.riskLevel IN ('HIGH', 'CRITICAL')
ORDER BY published DESC
```

{% include pack-code.html vendor="okta" section="5.3" %}

---

### 5.4 Configure Behavior Detection Rules

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SI-4, AC-7 |

#### Description
Configure Okta's Behavior Detection to identify anomalous user behavior patterns and trigger adaptive authentication responses. Detection types include new device, new location, new IP, velocity anomalies (impossible travel), and IP reputation.

#### Rationale
**Why This Matters:**
- Behavioral analytics detect account compromise that static policies miss
- New device/location from an existing user may indicate credential theft
- Impossible travel (logging in from two distant locations within minutes) is a strong indicator of token replay
- Risk-based authentication adapts security requirements to threat level

**Attack Prevented:** Account takeover via stolen credentials, session replay from anomalous locations, impossible travel attacks

#### ClickOps Implementation

**Step 1: Configure Behavior Detection Rules**
1. Navigate to: **Security → Behavior Detection**
2. Review the default behavior types:

| Behavior Type | Recommended Action |
|--------------|-------------------|
| New Device | Challenge with additional factor |
| New IP | Challenge with additional factor |
| New City | Challenge with additional factor |
| New State | Log only |
| New Country | Deny |
| Velocity (impossible travel) | Deny |

3. Click **Edit** for each behavior type
4. Set the **Action** per the table above
5. Click **Save**

**Step 2: Enable Risk Scoring in Authentication Policies**
1. Navigate to: **Security → Authentication Policies**
2. Edit the primary user-facing policy
3. In the rule conditions, enable:
   - **Risk score:** Evaluate risk for each authentication request
4. Configure responses:
   - **Low risk:** Allow with current factors
   - **Medium risk:** Challenge with additional factor
   - **High risk:** Deny access
5. Click **Save**

#### Code Implementation

```bash
# List all configured behavior detection rules
curl -s -X GET "https://${OKTA_DOMAIN}/api/v1/behaviors" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  | jq '.[] | {id: .id, name: .name, type: .type, status: .status}'

# Create a new behavior detection rule for new country
curl -X POST "https://${OKTA_DOMAIN}/api/v1/behaviors" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Country Detection",
    "type": "ANOMALOUS_LOCATION",
    "status": "ACTIVE",
    "settings": {
      "maxEventsUsedForEvaluation": 50
    }
  }'
```

{% include pack-code.html vendor="okta" section="5.4" %}

#### Validation & Testing
1. [ ] Verify all behavior detection rules are active: **Security → Behavior Detection**
2. [ ] Test new device detection: Log in from an unrecognized browser — should trigger MFA challenge
3. [ ] Review risk score evaluation: Check system log for `security.behavior_detection.triggered` events

#### Monitoring & Maintenance
**Log query:**
```plaintext
eventType eq "security.behavior_detection.triggered"
```

---

### 5.5 Monitor for Cross-Tenant Impersonation

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SI-4, AU-6 |

#### Description
Monitor for cross-tenant impersonation attacks where an adversary with admin access configures a malicious Identity Provider (IdP) to impersonate any user without credentials or MFA. This is a high-impact, low-volume attack that should trigger immediate investigation.

#### Rationale
**Why This Matters:**
- An attacker with admin access can create a malicious external IdP
- They then configure routing rules to direct authentication through the malicious IdP
- This allows impersonation of ANY user without knowing their credentials or MFA
- The attack leaves traces in system logs but is difficult to detect without specific monitoring
- IdP lifecycle events are high-impact but low-volume — ideal for alerting

**Attack Prevented:** Cross-tenant impersonation via malicious IdP configuration, unauthorized federation trust establishment

**Real-World Context:**
- **Obsidian Security Research:** Documented this technique as a post-compromise persistence mechanism used against Okta customers

#### ClickOps Implementation

**Step 1: Restrict IdP Configuration Permissions**
1. Navigate to: **Security → Administrators**
2. Review all users with admin roles that include IdP management permissions
3. Limit IdP configuration capability to the absolute minimum number of administrators
4. Create a custom admin role WITHOUT IdP management if possible:
   - Navigate to: **Security → Administrators → Roles → Create new role**
   - Exclude permissions: `okta.idps.manage`, `okta.policies.manage` (for IDP_DISCOVERY type)
5. Reassign administrators to the restricted role

**Step 2: Audit Existing Identity Providers**
1. Navigate to: **Security → Identity Providers**
2. Document all configured IdPs:
   - Name, type, status, created date, created by
3. Flag any IdPs that are unfamiliar or recently created
4. Verify each IdP has a legitimate business purpose

**Step 3: Audit Routing Rules**
1. Navigate to: **Security → Identity Providers → Routing Rules**
2. Review all routing rules:
   - Verify each rule routes to a legitimate IdP
   - Check for overly broad conditions (e.g., "all users" routing to an external IdP)
   - Flag any recently created or modified rules

**Step 4: Create SIEM Alerts for IdP Lifecycle Events**
Configure alerts in your SIEM for these system log events:
- `system.idp.lifecycle.create` — New IdP created
- `system.idp.lifecycle.update` — IdP configuration modified
- `system.idp.lifecycle.activate` — IdP activated
- `system.idp.lifecycle.deactivate` — IdP deactivated
- `policy.lifecycle.create` / `policy.lifecycle.update` (where policy type = IDP_DISCOVERY) — Routing rule changes

#### Code Implementation

```bash
# Audit all configured identity providers
curl -s -X GET "https://${OKTA_DOMAIN}/api/v1/idps" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  | jq '.[] | {id: .id, name: .name, type: .type, status: .status, created: .created, protocol: .protocol.type}'

# Audit IDP discovery (routing) policies
curl -s -X GET "https://${OKTA_DOMAIN}/api/v1/policies?type=IDP_DISCOVERY" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  | jq '.[] | {id: .id, name: .name, status: .status, created: .created, lastUpdated: .lastUpdated}'

# Get rules for each IDP discovery policy
curl -s -X GET "https://${OKTA_DOMAIN}/api/v1/policies/${POLICY_ID}/rules" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  | jq '.[] | {id: .id, name: .name, conditions: .conditions, actions: .actions}'

# Search system log for IdP lifecycle events (last 7 days)
curl -s -X GET "https://${OKTA_DOMAIN}/api/v1/logs?filter=eventType+sw+%22system.idp.lifecycle%22&since=$(date -d '7 days ago' -u +%Y-%m-%dT%H:%M:%S.000Z)" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  | jq '.[] | {eventType: .eventType, actor: .actor.displayName, target: .target[0].displayName, published: .published}'
```

{% include pack-code.html vendor="okta" section="5.5" %}

#### Validation & Testing
1. [ ] Verify IdP management is restricted to minimum necessary administrators
2. [ ] Confirm all existing IdPs have documented business justification
3. [ ] Verify SIEM alerts are configured for `system.idp.lifecycle.*` events
4. [ ] Test alert: Create a test IdP in a sandbox tenant and verify alert fires

#### Monitoring & Maintenance
**SIEM alert rules (CRITICAL — investigate immediately):**
```sql
-- Alert: New Identity Provider Created (CRITICAL)
SELECT actor.displayName, actor.alternateId, target[0].displayName,
       target[0].type, client.ipAddress, published
FROM okta_system_log
WHERE eventType IN (
  'system.idp.lifecycle.create',
  'system.idp.lifecycle.activate'
)

-- Alert: Routing Rule Modified (HIGH)
SELECT actor.displayName, target[0].displayName, published
FROM okta_system_log
WHERE eventType IN ('policy.lifecycle.create', 'policy.lifecycle.update')
  AND debugContext.debugData.policyType = 'IDP_DISCOVERY'
```

**Maintenance schedule:**
- **Weekly:** Review IdP configuration and routing rules for unauthorized changes
- **Monthly:** Verify SIEM alerts for IdP events are functioning (test with log injection)
- **On any alert fire:** Immediately investigate — this is a high-severity indicator

---

### 5.6 Run HealthInsight Security Reviews

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | CA-7, RA-5 |

#### Description
Run Okta HealthInsight regularly to assess your tenant's security posture against Okta's 16 built-in security recommendations. HealthInsight provides a posture score and actionable remediation guidance for common misconfigurations.

#### Rationale
**Why This Matters:**
- HealthInsight is free and built into every Okta admin console — no additional license needed
- Provides automated detection of common security misconfigurations
- Serves as a baseline security checklist aligned with Okta's own best practices
- Posture score tracking over time demonstrates continuous improvement for auditors

#### ClickOps Implementation

**Step 1: Access HealthInsight**
1. Navigate to: **Security → HealthInsight**
2. Review the dashboard showing overall posture score

**Step 2: Review All 16 Recommendations**

| # | HealthInsight Check | Category |
|---|-------------------|----------|
| 1 | Admin MFA enrollment | Authentication |
| 2 | User MFA enrollment | Authentication |
| 3 | Phishing-resistant authenticator enabled | Authentication |
| 4 | Password policy complexity | Password |
| 5 | Password policy age settings | Password |
| 6 | Common password check enabled | Password |
| 7 | Account lockout configured | Account Security |
| 8 | Session timeout configured | Session |
| 9 | Persistent sessions disabled | Session |
| 10 | ThreatInsight enabled and set to block | Threat Protection |
| 11 | Network zones configured | Network |
| 12 | Suspicious Activity Reporting enabled | Monitoring |
| 13 | New sign-on notification enabled | Notifications |
| 14 | Authenticator enrollment notification enabled | Notifications |
| 15 | Password change notification enabled | Notifications |
| 16 | System log forwarding configured | Logging |

**Step 3: Remediate Failed Checks**
1. For each check with **Failed** or **Warning** status:
   - Click the recommendation for detailed remediation steps
   - Follow Okta's guided remediation
   - Mark as resolved after implementation
2. Target: All 16 checks should show **Passed**

**Step 4: Schedule Regular Reviews**
1. Set a monthly calendar reminder to review HealthInsight
2. Document posture score in your security metrics dashboard
3. Include HealthInsight review in your quarterly security review process

#### Validation & Testing
1. [ ] Navigate to **Security → HealthInsight** and verify it loads
2. [ ] Document current posture score as baseline
3. [ ] Verify all 16 checks have been reviewed
4. [ ] Remediate any Failed checks and confirm they move to Passed

#### Monitoring & Maintenance
**Maintenance schedule:**
- **Monthly:** Run HealthInsight review, remediate new findings
- **Quarterly:** Report posture score to security leadership
- **After configuration changes:** Re-run HealthInsight to verify no regression

---

## 6. Third-Party Integration Security

### 6.1 Integration Risk Assessment Matrix

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **OAuth Scopes** | Profile read-only | Read user data | Write users, groups, apps |
| **SCIM Access** | No SCIM | Read-only sync | Create/delete users |
| **Admin API** | No API access | Limited endpoints | Full API access |
| **Data Access** | User profile only | Group membership | Authentication data |

{% include pack-code.html vendor="okta" section="6.1" %}

### 6.2 Common Integrations and Recommended Controls

#### Salesforce
**Risk Level:** High (SSO + Provisioning)
**Controls:**
- ✅ SCIM token rotation quarterly
- ✅ Limit provisioned attributes
- ✅ Enable Salesforce IP restrictions

#### Microsoft 365
**Risk Level:** High (Federation)
**Controls:**
- ✅ Configure federation trust validation
- ✅ Disable legacy authentication
- ✅ Sync conditional access policies

#### GitHub Enterprise
**Risk Level:** High (Code access)
**Controls:**
- ✅ SAML SSO with MFA
- ✅ Disable username/password fallback
- ✅ Sync team membership carefully

{% include pack-code.html vendor="okta" section="6.2" %}

---

## 7. Operational Security

These controls address operational procedures and organizational practices that complement technical hardening. Many are driven by breach post-mortems and SOC 2 audit findings.

### 7.1 Sanitize HAR Files Before Sharing

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SC-28, SI-12 |

#### Description
Establish a mandatory procedure to sanitize HTTP Archive (HAR) files before sharing with Okta support or any third party. HAR files capture all HTTP traffic including session cookies, authorization tokens, and CSRF tokens. The October 2023 Okta breach was caused by unsanitized HAR files uploaded to Okta's support system.

#### Rationale
**Why This Matters:**
- HAR files contain active session tokens that can be replayed to hijack user sessions
- The October 2023 breach affected 134 customers whose HAR files contained valid session cookies
- Okta support regularly requests HAR files for troubleshooting — this is a recurring operational risk
- Automated sanitization reduces human error in the manual stripping process

**Attack Prevented:** Session hijacking via HAR file token exfiltration

**Real-World Incidents:**
- **October 2023:** Threat actor accessed Okta support system and extracted session tokens from HAR files uploaded by 134 customers

#### Implementation

**Step 1: Create Organizational Policy**
Document a formal policy requiring:
- All HAR files MUST be sanitized before sharing with any external party
- Engineers must use the automated sanitization script (below) or approved tooling
- Random audits of support ticket attachments to verify compliance

**Step 2: Manual Sanitization Procedure**
1. Open the HAR file in a text editor
2. Search for and remove all values in these fields:
   - `Cookie` request headers
   - `Authorization` request headers
   - `Set-Cookie` response headers
   - `x-csrf-token` or similar CSRF headers
   - Any `Bearer` token values
3. Save the sanitized file
4. Verify no sensitive tokens remain by searching for common patterns: `sid=`, `sessionToken`, `Bearer`, `SSWS`

**Step 3: Automated Sanitization Script**
```bash
#!/bin/bash
# har-sanitize.sh - Strip sensitive headers from HAR files
# Usage: ./har-sanitize.sh input.har > sanitized.har

INPUT_FILE="$1"
if [ -z "$INPUT_FILE" ]; then
  echo "Usage: $0 <input.har>"
  exit 1
fi

jq '
  .log.entries[].request.headers |= map(
    if (.name | test("^(Cookie|Authorization|X-CSRF-Token|X-Okta-Session)$"; "i"))
    then .value = "[REDACTED]"
    else .
    end
  ) |
  .log.entries[].response.headers |= map(
    if (.name | test("^(Set-Cookie)$"; "i"))
    then .value = "[REDACTED]"
    else .
    end
  ) |
  .log.entries[].request.cookies |= map(.value = "[REDACTED]") |
  .log.entries[].response.cookies |= map(.value = "[REDACTED]")
' "$INPUT_FILE"
```

**Step 4: Alternative Tools**
- **Google HAR Sanitizer Chrome Extension** — browser-based sanitization
- **BurpSuite** — export filtered HAR with token stripping
- **mitmproxy** — can export sanitized HAR during capture

#### Validation & Testing
1. [ ] Sanitization script is available and tested
2. [ ] Policy documented and communicated to all IT/engineering staff
3. [ ] Test: Generate a HAR file, sanitize it, verify no tokens remain by searching for `sid=`, `Bearer`, `SSWS`

---

### 7.2 Monitor Okta Security Advisories

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SI-5, RA-5 |

#### Description
Establish a process to monitor Okta security advisories and ensure all Okta client software (Verify, Browser Plugin) is kept up to date. Recent vulnerabilities include DLL hijacking in Okta Verify, XSS in the Browser Plugin, and iOS push notification bypasses.

#### Rationale
**Why This Matters:**
- Okta Verify for Windows was vulnerable to privilege escalation via DLL hijacking (fixed in 5.0.2)
- Okta Browser Plugin versions 6.5.0-6.31.0 were vulnerable to cross-site scripting
- Okta Verify for iOS had a push bypass allowing responses regardless of user selection
- Downstream dependencies (React/Next.js CVEs) affect Okta-integrated applications
- Okta maintains an active bug bounty program (153 valid issues, $405K paid)

#### Implementation

**Step 1: Subscribe to Security Advisories**
1. Bookmark: [trust.okta.com/security-advisories](https://trust.okta.com/security-advisories/)
2. Subscribe to Okta's security advisory RSS feed or email notifications
3. Add to your security team's weekly monitoring checklist

**Step 2: Establish Client Update Policy**
1. Define maximum patch delay: **Critical** = 48 hours, **High** = 7 days, **Medium** = 30 days
2. Use MDM to enforce Okta client updates:
   - **Jamf Pro (macOS):** Auto-update Okta Verify via patch management
   - **Microsoft Intune (Windows):** Deploy Okta Verify updates via Win32 app
   - **Chrome Enterprise:** Force-update Okta Browser Plugin via policy
3. Block outdated client versions from authenticating (via Device Assurance policies)

**Step 3: Monitor Downstream Dependencies**
1. Track CVEs in frameworks used with Okta authentication:
   - React Server Components (CVE-2025-55182)
   - Next.js middleware (CVE-2025-29927)
   - Auth0 SDK versions
2. Include Okta dependency monitoring in your vulnerability management program

#### Validation & Testing
1. [ ] Security advisory monitoring is assigned to a specific team member
2. [ ] Client update policy is documented and enforced via MDM
3. [ ] Verify all Okta Verify installations are on the latest version

---

### 7.3 Conduct Regular Access Reviews

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-2(3) |
| SOC 2 | CC6.1, CC6.2 |

#### Description
Perform periodic access reviews (recertification campaigns) to verify user access is appropriate and remove orphaned accounts, stale privileges, and excessive permissions. SOC 2 auditors specifically look for documented evidence of regular access reviews.

#### ClickOps Implementation

**Step 1: Review Admin Accounts**
1. Navigate to: **Security → Administrators**
2. Review all admin accounts:
   - Verify each admin is a current employee with legitimate need
   - Count Super Admin accounts — should be **fewer than 5**
   - Remove admin access for anyone who has changed roles
3. Document review with date and reviewer name

**Step 2: Review User Accounts**
1. Navigate to: **Directory → People**
2. Filter by **Status: Active**
3. Cross-reference with HR system for terminated employees
4. Suspend any accounts for users no longer with the organization

**Step 3: Review Application Assignments**
1. Navigate to: **Applications → Applications**
2. For each sensitive application, review assigned users/groups
3. Remove users who no longer need access

**Step 4: Review Group Memberships**
1. Navigate to: **Directory → Groups**
2. Review privileged groups (admin groups, security groups)
3. Remove members who no longer need membership

#### Code Implementation

```bash
# Find active users who haven't logged in for 90+ days
curl -s -X GET "https://${OKTA_DOMAIN}/api/v1/users?filter=status+eq+%22ACTIVE%22&limit=200" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  | jq '[.[] | select(.lastLogin != null) | select((.lastLogin | fromdateiso8601) < (now - 7776000))] | length'

# List all admin role assignments
curl -s -X GET "https://${OKTA_DOMAIN}/api/v1/iam/assignees/users" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  | jq '.[] | {userId: .userId, role: .role, status: .status}'

# Count Super Admin assignments
curl -s -X GET "https://${OKTA_DOMAIN}/api/v1/iam/assignees/users?roleType=SUPER_ADMIN" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  | jq 'length'
```

{% include pack-code.html vendor="okta" section="7.3" %}

#### Quarterly Access Review Checklist
- [ ] All admin accounts verified against current employee list
- [ ] Super Admin count is < 5
- [ ] No orphaned accounts (users who left but weren't deprovisioned)
- [ ] No accounts with last login > 90 days (unless exempted)
- [ ] Privileged group memberships reviewed and justified
- [ ] Sensitive application assignments reviewed
- [ ] Review documented with date, reviewer, and findings

#### Monitoring & Maintenance
**Maintenance schedule:**
- **Monthly:** Review admin accounts for changes
- **Quarterly:** Full access review (all users, groups, applications)
- **On employee termination:** Immediate account deprovisioning (verify within 24 hours)
- **Annually:** Document access review program for SOC 2 auditors

---

### 7.4 Implement Change Management for Okta Configuration

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | CM-3 |
| SOC 2 | CC8.1 |

#### Description
Establish a change management process for Okta configuration changes. All modifications to authentication policies, admin roles, network zones, and integrations should be tracked, approved, and auditable.

#### Implementation

**Step 1: Define Change Categories**

| Change Type | Approval Required | Examples |
|------------|-------------------|---------|
| **Critical** | Security team + management | Authentication policy changes, admin role modifications, IdP configuration |
| **Standard** | Security team | Application integration, group membership changes, network zone updates |
| **Low Risk** | Self-approved (with logging) | User profile updates, non-privileged group changes |

**Step 2: Track Configuration as Code**
1. Export Okta configuration using Terraform:
   ```bash
   # Use okta/okta Terraform provider to manage config as code
   terraform plan -out=okta-changes.plan
   terraform apply okta-changes.plan
   ```
2. Store Terraform state in version control
3. Require pull request review for all Okta Terraform changes
4. Use `terraform plan` diff as the change documentation

**Step 3: Monitor Configuration Changes via System Log**
Key events to track:

| Event Type | Description |
|-----------|-------------|
| `policy.lifecycle.create` | New policy created |
| `policy.lifecycle.update` | Policy modified |
| `policy.lifecycle.delete` | Policy deleted |
| `policy.rule.create` | Policy rule created |
| `policy.rule.update` | Policy rule modified |
| `application.lifecycle.create` | New application added |
| `application.lifecycle.update` | Application modified |
| `group.user_membership.add` | User added to group |
| `group.user_membership.remove` | User removed from group |
| `zone.lifecycle.create` | Network zone created |
| `zone.lifecycle.update` | Network zone modified |
| `system.role.create` | Admin role created |

**Step 4: Implement Separation of Duties**
- No single admin can both propose and approve critical changes
- Require two-person integrity for authentication policy modifications
- Use Okta Workflows to enforce approval gates for critical changes

{% include pack-code.html vendor="okta" section="7.4" %}

#### Validation & Testing
1. [ ] Change management process documented
2. [ ] Configuration tracked in version control (Terraform or equivalent)
3. [ ] SIEM alerts configured for unauthorized configuration changes
4. [ ] Separation of duties enforced for critical changes

---

### 7.5 Establish Identity Incident Response Procedures

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | IR-4, IR-6 |
| SOC 2 | CC7.3 |

#### Description
Document specific response procedures for identity-based security incidents. These runbooks complement your organization's broader incident response plan with Okta-specific actions and API calls.

#### Incident Response Runbooks

**Runbook 1: Compromised Admin Account**
1. **Contain:** Immediately suspend the admin account
   ```bash
   curl -X POST "https://${OKTA_DOMAIN}/api/v1/users/${USER_ID}/lifecycle/suspend" \
     -H "Authorization: SSWS ${OKTA_API_TOKEN}"
   ```
2. **Revoke:** Clear all active sessions
   ```bash
   curl -X DELETE "https://${OKTA_DOMAIN}/api/v1/users/${USER_ID}/sessions" \
     -H "Authorization: SSWS ${OKTA_API_TOKEN}"
   ```
3. **Investigate:** Audit all changes made by the compromised account
   ```bash
   curl -s -X GET "https://${OKTA_DOMAIN}/api/v1/logs?filter=actor.id+eq+%22${USER_ID}%22&since=${INCIDENT_START}" \
     -H "Authorization: SSWS ${OKTA_API_TOKEN}" | jq '.[] | {eventType, target, published}'
   ```
4. **Remediate:** Reset credentials, re-enroll MFA, review all configuration changes
5. **Restore:** Reactivate account only after re-verification of identity

**Runbook 2: Stolen Session Tokens**
1. **Revoke** all active sessions for affected users
2. **Identify** the source of token theft (HAR files, malware, XSS)
3. **Block** the source IPs in network zones
4. **Force** re-authentication for all affected users

**Runbook 3: Malicious IdP Creation**
1. **Deactivate** the malicious IdP immediately
   ```bash
   curl -X POST "https://${OKTA_DOMAIN}/api/v1/idps/${IDP_ID}/lifecycle/deactivate" \
     -H "Authorization: SSWS ${OKTA_API_TOKEN}"
   ```
2. **Audit** all authentications that used the malicious IdP
3. **Revoke** sessions for all users who authenticated via the malicious IdP
4. **Investigate** which admin created it and whether their account is compromised

**Runbook 4: Unauthorized MFA Enrollment**
1. **Remove** the unauthorized factor
   ```bash
   curl -X DELETE "https://${OKTA_DOMAIN}/api/v1/users/${USER_ID}/factors/${FACTOR_ID}" \
     -H "Authorization: SSWS ${OKTA_API_TOKEN}"
   ```
2. **Investigate** how the enrollment occurred (account takeover, social engineering of helpdesk)
3. **Force** password reset and MFA re-enrollment under verified identity
4. **Review** all account activity since the unauthorized enrollment

**Runbook 5: Mass Password Spray Attack**
1. **Activate** IP blocking for source IPs via ThreatInsight and network zones
2. **Review** lockout logs to identify targeted accounts
3. **Communicate** to affected users about potential credential exposure
4. **Force** password reset for accounts that were targeted
5. **Verify** MFA is enforced — password spray is only effective without MFA

#### Validation & Testing
1. [ ] All 5 runbooks documented and accessible to security team
2. [ ] API commands tested in sandbox environment
3. [ ] Security team trained on runbook execution
4. [ ] Runbooks integrated into broader incident response plan

#### Monitoring & Maintenance
**Maintenance schedule:**
- **Quarterly:** Review and update runbooks based on new attack techniques
- **After each incident:** Conduct post-incident review and update relevant runbook
- **Annually:** Conduct tabletop exercise using runbooks

---

## 8. Compliance Quick Reference

### 8.1 SOC 2 Trust Services Criteria

| Control ID | Okta Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | Phishing-resistant MFA | 1.1 |
| CC6.1 | Access reviews & recertification | 7.3 |
| CC6.2 | Admin role separation | 1.2 |
| CC6.6 | Network zone policies | 2.1 |
| CC7.2 | System log monitoring | 5.1 |
| CC7.3 | Identity incident response | 7.5 |
| CC8.1 | Change management | 7.4 |

### 8.2 NIST 800-53 Rev 5

| Control | Okta Control | Guide Section |
|---------|------------------|---------------|
| AC-2 | NHI governance | 3.4 |
| AC-2(3) | Account lifecycle | 1.6 |
| AC-2(3) | Access reviews | 7.3 |
| AC-3 | Default authentication policy audit | 1.9 |
| AC-3 | Dynamic network zones | 2.3 |
| AC-5 | Admin role separation | 1.2 |
| AC-6(1) | Custom admin roles | 1.2 |
| AC-7 | Account lockout | 1.5 |
| AC-12 | Session timeouts | 4.1 |
| AU-2 | System log | 5.1 |
| AU-6 | Cross-tenant impersonation monitoring | 5.5 |
| CA-7 | HealthInsight reviews | 5.6 |
| CM-3 | Change management | 7.4 |
| CM-7 | OAuth app allowlisting | 3.3 |
| IA-2(1) | MFA enforcement | 1.1 |
| IA-2(6) | FIDO2 for admins | 1.1 |
| IA-2(12) | PIV/CAC authentication | 1.7 |
| IA-4 | NHI governance | 3.4 |
| IA-5(1) | Password policy | 1.4 |
| IA-5(1) | Self-service recovery hardening | 1.10 |
| IA-11 | Self-service recovery hardening | 1.10 |
| IR-4 | Identity incident response | 7.5 |
| IR-6 | End-user security notifications | 1.11 |
| RA-5 | Security advisory monitoring | 7.2 |
| RA-5 | Identity Threat Protection | 5.3 |
| SC-7 | Dynamic network zones | 2.3 |
| SC-13 | FIPS compliance | 1.8 |
| SC-23 | Session persistence | 4.2 |
| SC-23 | Admin session security | 4.3 |
| SC-28 | HAR file sanitization | 7.1 |
| SI-4 | End-user security notifications | 1.11 |
| SI-4 | Identity Threat Protection | 5.3 |
| SI-4 | Behavior detection | 5.4 |
| SI-4 | Cross-tenant impersonation monitoring | 5.5 |
| SI-5 | Security advisory monitoring | 7.2 |
| SI-12 | HAR file sanitization | 7.1 |

### 8.3 NIST 800-63-4 AAL Mapping

NIST SP 800-63-4 (final July 2025) defines Authentication Assurance Levels. Map Okta configurations to AAL levels:

| AAL Level | Okta Configuration | Acceptable Authenticators | Guide Reference |
|-----------|-------------------|--------------------------|-----------------|
| AAL1 | Password only | Password (NOT recommended) | 1.4 |
| AAL2 | Password + any MFA | TOTP, Push, FIDO2, Syncable Passkeys | 1.1 |
| AAL2 (phishing-resistant) | Password + FIDO2 | WebAuthn, FastPass, Passkeys | 1.1, 1.3 |
| AAL3 | Hardware-bound authenticator | PIV/CAC, FIDO2 hardware key (non-syncable only) | 1.7 |

**Key NIST 800-63-4 Changes:**
- AAL2 MUST offer a phishing-resistant MFA option (Section 1.1)
- Syncable passkeys are now explicitly accepted at AAL2
- AAL3 requires hardware-bound authenticators (syncable passkeys NOT acceptable)
- Introduces Digital Identity Risk Management (DIRM) framework for continuous risk evaluation (Section 5.3)

### 8.4 DISA STIG Okta IDaaS V1R1

| STIG ID | Severity | Control | Guide Section |
|---------|----------|---------|---------------|
| V-273186 | Medium | Global session idle timeout (15 min) | 4.1 |
| V-273187 | Medium | Admin Console idle timeout (15 min) | 4.1 |
| V-273188 | Medium | Account inactivity auto-disable (35 days) | 1.6 |
| V-273189 | Medium | Account lockout (3 attempts) | 1.5 |
| V-273190 | Medium | Dashboard phishing-resistant auth | 1.1 |
| V-273191 | Medium | Admin Console phishing-resistant auth | 1.1 |
| V-273192 | Medium | DOD warning banner | 8.5 |
| V-273193 | **HIGH** | Admin Console MFA required | 1.1 |
| V-273194 | **HIGH** | Dashboard MFA required | 1.1 |
| V-273195 | Medium | Password min length (15 chars) | 1.4 |
| V-273196 | Medium | Uppercase required | 1.4 |
| V-273197 | Medium | Lowercase required | 1.4 |
| V-273198 | Medium | Number required | 1.4 |
| V-273199 | Medium | Special character required | 1.4 |
| V-273200 | Medium | Min password age (24 hours) | 1.4 |
| V-273201 | Medium | Max password age (60 days) | 1.4 |
| V-273202 | **HIGH** | Centralized audit logging | 5.1 |
| V-273203 | Medium | Global session lifetime (18 hours) | 4.1 |
| V-273204 | Medium | PIV/CAC credential acceptance | 1.7 |
| V-273205 | Medium | FIPS-compliant Okta Verify | 1.8 |
| V-273206 | Medium | Disable persistent session cookies | 4.2 |
| V-273207 | Medium | Approved CA certificates | 1.7 |
| V-273208 | Medium | Common password check | 1.4 |
| V-273209 | Medium | Password history (5 generations) | 1.4 |

> **DISA STIG v1.1 (Feb 2026)** adds five new checks for Non-Human Identity (NHI) security: service account governance, API token lifecycle management, and CC SRG alignment. See Section 3.4 for NHI governance controls.

---

### 8.5 Environment-Specific Requirements

#### DOD Warning Banner (DISA STIG V-273192)

For U.S. Government systems, display the Standard Mandatory DOD Notice and Consent Banner before granting access. Implementation requires customizing the Okta Sign-In Widget—refer to the "Okta DOD Warning Banner Configuration Guide" in the STIG package.

<details>
<summary>DOD Banner Text (1300 characters)</summary>

```plaintext
You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only.

By using this IS (which includes any device attached to this IS), you consent to the following conditions:

-The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), law enforcement (LE), and counterintelligence (CI) investigations.

-At any time, the USG may inspect and seize data stored on this IS.

-Communications using, or data stored on, this IS are not private, are subject to routine monitoring, interception, and search, and may be disclosed or used for any USG-authorized purpose.

-This IS includes security measures (e.g., authentication and access controls) to protect USG interests--not for your personal benefit or privacy.

-Notwithstanding the above, using this IS does not constitute consent to PM, LE or CI investigative searching or monitoring of the content of privileged communications, or work product, related to personal representation or services by attorneys, psychotherapists, or clergy, and their assistants. Such communications and work product are private and confidential. See User Agreement for details.
```

</details>

---

### 8.6 Compliance Checklist

Use this checklist to verify controls are implemented for your compliance requirements.

#### HIGH Priority Controls (DISA STIG)
- [ ] MFA required for Admin Console (V-273193) — Section 1.1
- [ ] MFA required for Dashboard (V-273194) — Section 1.1
- [ ] Audit logs forwarded to SIEM (V-273202) — Section 5.1

#### Authentication Controls
- [ ] Phishing-resistant authentication enabled (1.1)
- [ ] Admin role separation implemented (1.2)
- [ ] Password policy configured per requirements (1.4)
- [ ] Account lockout configured (1.5)
- [ ] Account inactivity automation active (1.6)
- [ ] Default authentication policy audited — zero apps assigned (1.9)
- [ ] Self-service recovery hardened — SMS/voice/questions disabled (1.10)
- [ ] End-user security notifications enabled — all five types (1.11)
- [ ] Suspicious activity reporting enabled (1.11)
- [ ] PIV/CAC Smart Card configured (if applicable) (1.7)
- [ ] FIPS compliance enabled (if applicable) (1.8)

#### Network & Integration Controls
- [ ] Network zones configured (2.1)
- [ ] Admin console access restricted by IP (2.2)
- [ ] Anonymizer/Tor blocking active (2.3)
- [ ] OAuth app allowlisting enforced (3.3)
- [ ] Non-human identity governance implemented (3.4)
- [ ] SSWS to OAuth 2.0 migration planned/completed (3.4)

#### Session Management
- [ ] Global session idle timeout configured (4.1)
- [ ] Admin Console session timeout configured (4.1)
- [ ] Global session lifetime limited (4.1)
- [ ] Persistent session cookies disabled (4.2)
- [ ] Admin session ASN binding verified active (4.3)
- [ ] Protected Actions enabled for critical operations (4.3)

#### Monitoring & Detection
- [ ] Log streaming or API integration active (5.1)
- [ ] ThreatInsight enabled (5.2)
- [ ] Identity Threat Protection configured (5.3) — if licensed
- [ ] Behavior detection rules active (5.4)
- [ ] Cross-tenant impersonation monitoring alerts configured (5.5)
- [ ] HealthInsight reviewed — all 16 checks passed (5.6)

#### Operational Security
- [ ] HAR file sanitization procedure documented (7.1)
- [ ] Security advisory monitoring assigned (7.2)
- [ ] Quarterly access reviews scheduled (7.3)
- [ ] Change management process for Okta config (7.4)
- [ ] Identity incident response procedures documented (7.5)

---

## Appendix A: Edition Compatibility

| Control | Okta Starter | Okta SSO | Okta Adaptive | Okta Identity |
|---------|-------------|----------|--------------|---------------|
| MFA | ✅ | ✅ | ✅ | ✅ |
| FIDO2/WebAuthn | ✅ | ✅ | ✅ | ✅ |
| ThreatInsight | ❌ | ❌ | ✅ | ✅ |
| Device Trust | ❌ | ❌ | ✅ | ✅ |
| FastPass | ❌ | ❌ | ✅ | ✅ |
| Custom Admin Roles | ✅ | ✅ | ✅ | ✅ |
| Log Streaming | Add-on | Add-on | ✅ | ✅ |
| Workflows/Automations | Add-on | Add-on | ✅ | ✅ |
| Identity Threat Protection | ❌ | ❌ | ❌ | Add-on |
| Behavior Detection | ❌ | ❌ | ✅ | ✅ |
| HealthInsight | ✅ | ✅ | ✅ | ✅ |
| Protected Actions | ✅ | ✅ | ✅ | ✅ |
| Enhanced Dynamic Zones | ❌ | ❌ | ✅ | ✅ |
| Identity Governance (OIG) | ❌ | ❌ | ❌ | Add-on |

---

## Appendix B: References

**Official Okta Documentation:**
- [Trust Center](https://trust.okta.com/)
- [Security Trust Center (SafeBase)](https://security.okta.com/)
- [Help Center](https://help.okta.com/en-us/content/index.htm)
- [Security Advisories](https://trust.okta.com/security-advisories/)
- [9 Admin Best Practices](https://www.okta.com/blog/2019/10/9-admin-best-practices-to-keep-your-org-secure/)
- [Securing Admin Accounts](https://support.okta.com/help/s/article/best-practices-for-securing-okta-workforce-identity-cloud-admin-accounts)
- [Secure Identity Commitment Whitepaper (Aug 2025)](https://www.okta.com/sites/default/files/2025-08/OktaSecureIdentityCommitment_0826.pdf)
- [Admin Role Permissions](https://help.okta.com/en-us/Content/Topics/Security/administrators-admin-comparison.htm)
- [HealthInsight Recommendations](https://help.okta.com/oie/en-us/content/topics/security/healthinsight/healthinsight-security-task-recomendations.htm)
- [Suspicious Activity Reporting](https://help.okta.com/oie/en-us/content/topics/security/suspicious-activity-reporting.htm)
- [Protected Actions](https://help.okta.com/oie/en-us/content/topics/security/admin-console-protected-actions.htm)
- [Protecting Admin Sessions](https://sec.okta.com/articles/protectingadminsessions/)
- [Blocking Anonymizers](https://sec.okta.com/blockanonymizers/)
- [Global Session Policies](https://help.okta.com/oie/en-us/content/topics/identity-engine/policies/about-okta-sign-on-policies.htm)
- [Identity Threat Protection](https://www.okta.com/products/identity-threat-protection/)
- [Non-Human Identities](https://www.okta.com/solutions/protect-non-human-identities/)
- [OAuth Migration from SSWS](https://developer.okta.com/blog/2023/09/25/oauth-api-tokens)
- [Identity Security Checklist](https://www.okta.com/sites/default/files/2024-04/Identity%20Security%20Checklist.pdf)
- [Secure Identity Assessment](https://www.okta.com/secure-identity-assessment/)

**API Documentation:**
- [Okta API Reference](https://developer.okta.com/docs/api/)
- [System Log API](https://developer.okta.com/docs/reference/api/system-log/)
- [Policies API](https://developer.okta.com/docs/reference/api/policy/)
- [Identity Providers API](https://developer.okta.com/docs/reference/api/idps/)
- [Network Zones API](https://developer.okta.com/docs/reference/api/zones/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018, FedRAMP High, FedRAMP Moderate, FIPS 140-2, HIPAA, PCI DSS v4.0, CSA STAR, NIST 800-53 Rev 5 — via [Okta Compliance](https://trust.okta.com/compliance/)
- [DISA STIG Library](https://public.cyber.mil/stigs/) — Okta IDaaS STIG V1R1 (March 2025), v1.1 NHI update (Feb 2026)
- [DISA STIG Detail View](https://cyber.trackr.live/stig/Okta_Identity_as_a_Service_(IDaaS)/1/1)
- [CIS Controls v8](https://www.cisecurity.org/controls)
- [NIST 800-53 Rev 5](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
- [NIST SP 800-63-4 Final (July 2025)](https://pages.nist.gov/800-63-4/)

**Third-Party Security Research:**
- [Nudge Security — 6 Critical Okta Configurations](https://www.nudgesecurity.com/post/improve-okta-security-with-these-6-critical-configuration-settings)
- [Obsidian Security — Fortify Okta Against Session Token Compromise](https://www.obsidiansecurity.com/blog/fortify-okta-against-session-token-compromise)
- [Obsidian Security — Cross-Tenant Impersonation in Okta](https://www.obsidiansecurity.com/blog/behind-the-breach-cross-tenant-impersonation-in-okta)
- [AppOmni — Better SaaS Security with Okta Identity Engine](https://appomni.com/blog/better-saas-security-with-appomni-and-okta-identity-engine/)

**CISA & Government:**
- [Okta Secure by Design Pledge](https://sec.okta.com/articles/cisasecurebydesign1/)
- [Okta Secure by Design — One Year On](https://sec.okta.com/articles/2025/05/oktas-secure-by-design-pledge-one-year-on/)

**Security Incidents:**
- **October 2023:** Unauthorized access to Okta support system via compromised service account; HAR files containing session cookies exfiltrated, affecting 134 customers (all 18,400 notified) — [Root Cause](https://sec.okta.com/articles/2023/11/unauthorized-access-oktas-support-case-management-system-root-cause/) | [Investigation Closure](https://sec.okta.com/harfiles/)
- **January 2022:** LAPSUS$ group compromised a Sitel (sub-processor) support engineer for 25 minutes, impacting 2 customers — [Okta Investigation](https://www.okta.com/blog/2022/03/oktas-investigation-of-the-january-2022-compromise/)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-02-10 | 0.3.0 | draft | Comprehensive audit against Okta SIC, DISA STIG v1.1, NIST 800-63-4, Obsidian/Nudge/AppOmni research. Added 15 new controls: Default Auth Policy Backstop (1.9), Self-Service Recovery (1.10), End-User Notifications (1.11), Dynamic Zones (2.3), OAuth Allowlisting (3.3), NHI Governance (3.4), Admin Session Security (4.3), ITP (5.3), Behavior Detection (5.4), Cross-Tenant Impersonation (5.5), HealthInsight (5.6), HAR Sanitization (7.1), Security Advisory Monitoring (7.2), Access Reviews (7.3), Change Management (7.4), Incident Response (7.5). Expanded compliance mappings with NIST 800-63-4 AAL mapping. | Claude Code (Opus 4.6) |
| 2025-12-26 | 0.2.0 | draft | Integrated DISA STIG Okta IDaaS V1R1 controls into functional sections | Claude Code (Opus 4.5) |
| 2025-12-14 | 0.1.0 | draft | Initial Okta hardening guide | Claude Code (Opus 4.5) |

---

**Questions or Improvements?**
- Open an issue: [GitHub Issues](https://github.com/grcengineering/how-to-harden/issues)
- Contribute: [Contributing Guide](/contributing/)
