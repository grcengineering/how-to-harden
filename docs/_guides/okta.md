---
layout: guide
title: "Okta Hardening Guide"
vendor: "Okta"
slug: "okta"
tier: "1"
category: "Identity"
description: "Identity Provider hardening for SSO, MFA policies, and API token security"
last_updated: "2025-12-26"
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
7. [Compliance Quick Reference](#7-compliance-quick-reference)
8. [DISA STIG Compliance](#8-disa-stig-compliance)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Phishing-Resistant MFA (FIDO2/WebAuthn)

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1), IA-2(6)
**DISA STIG:** V-273190, V-273191, V-273193, V-273194

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

**Step 4: Configure Phishing-Resistant Authentication Policies (DISA STIG)**
For DOD compliance, configure both Okta Dashboard and Admin Console policies:

1. Navigate to: **Security → Authentication Policies**
2. Click the **Okta Dashboard** policy
3. Click **Actions** next to the top rule → **Edit**
4. In "User must authenticate with", select **Password/IdP + Another factor** or **Any 2 factor types**
5. In "Possession factor constraints are" section, check **Phishing resistant**
6. Repeat for the **Okta Admin Console** policy

> **DISA STIG Requirement (V-273190, V-273191):** Both Okta Dashboard and Admin Console must be configured to allow authentication only via non-phishable authenticators (Phishing resistant box checked).

> **DISA STIG Requirement (V-273193, V-273194 - HIGH):** Both Admin Console and Dashboard must require multifactor authentication with "Password/IdP + Another factor" or "Any 2 factor types".

**Time to Complete:** ~30 minutes (policy) + user enrollment time

#### Code Implementation

**Option 1: Okta API**
```bash
# Create FIDO2 authenticator policy
curl -X POST "https://${OKTA_DOMAIN}/api/v1/policies" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "ACCESS_POLICY",
    "name": "Phishing-Resistant MFA Policy",
    "description": "Requires FIDO2 for sensitive applications",
    "priority": 1,
    "conditions": {
      "people": {
        "groups": {
          "include": ["ADMIN_GROUP_ID"]
        }
      }
    }
  }'

# Create policy rule requiring WebAuthn
curl -X POST "https://${OKTA_DOMAIN}/api/v1/policies/${POLICY_ID}/rules" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Require FIDO2",
    "priority": 1,
    "conditions": {
      "network": {
        "connection": "ANYWHERE"
      }
    },
    "actions": {
      "signon": {
        "access": "ALLOW",
        "requireFactor": true,
        "factorPromptMode": "ALWAYS",
        "primaryFactor": "PASSWORD_IDP_ANY_FACTOR",
        "factorLifetime": 0
      }
    }
  }'
```

**Option 2: Terraform**
```hcl
# terraform/okta/phishing-resistant-mfa.tf

resource "okta_authenticator" "fido2" {
  name   = "FIDO2 WebAuthn"
  key    = "webauthn"
  status = "ACTIVE"
  settings = jsonencode({
    userVerification = "REQUIRED"
    attachment       = "ANY"
  })
}

resource "okta_policy_signon" "phishing_resistant" {
  name        = "Phishing-Resistant MFA Policy"
  status      = "ACTIVE"
  description = "Requires FIDO2 for all admin access"
  priority    = 1

  groups_included = [okta_group.admins.id]
}

resource "okta_policy_rule_signon" "require_fido2" {
  policy_id          = okta_policy_signon.phishing_resistant.id
  name               = "Require FIDO2"
  status             = "ACTIVE"
  priority           = 1
  access             = "ALLOW"
  mfa_required       = true
  mfa_prompt         = "ALWAYS"
  primary_factor     = "PASSWORD_IDP_ANY_FACTOR"
  session_lifetime   = 120
  session_persistent = false
}
```

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
```
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

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(6) | Access to privileged accounts |
| **ISO 27001** | A.9.4.2 | Secure log-on procedures |
| **PCI DSS** | 8.3.1 | MFA for administrative access |

---

### 1.2 Implement Admin Role Separation

**Profile Level:** L1 (Baseline)
**CIS Controls:** 5.4, 6.8
**NIST 800-53:** AC-5, AC-6(1)

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

```bash
# Create custom admin role via API
curl -X POST "https://${OKTA_DOMAIN}/api/v1/iam/roles" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "label": "Help Desk Admin",
    "description": "Limited admin for password resets and account unlocks",
    "permissions": [
      "okta.users.read",
      "okta.users.credentials.resetPassword",
      "okta.users.lifecycle.unlock"
    ]
  }'
```

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2 | Role-based access |
| **NIST 800-53** | AC-6(1) | Least privilege |
| **ISO 27001** | A.9.2.3 | Management of privileged access |

---

### 1.3 Enable Hardware-Bound Session Tokens

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-23, IA-11

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

## 2. Network Access Controls

### 2.1 Configure IP Zones and Network Policies

**Profile Level:** L1 (Baseline)
**CIS Controls:** 13.3
**NIST 800-53:** AC-3, SC-7

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

```bash
# Create network zone
curl -X POST "https://${OKTA_DOMAIN}/api/v1/zones" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "IP",
    "name": "Corporate Network",
    "status": "ACTIVE",
    "gateways": [
      {"type": "CIDR", "value": "203.0.113.0/24"},
      {"type": "CIDR", "value": "198.51.100.0/24"}
    ]
  }'

# Create block zone for TOR
curl -X POST "https://${OKTA_DOMAIN}/api/v1/zones" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "DYNAMIC_V2",
    "name": "Blocked - TOR and Anonymizers",
    "status": "ACTIVE",
    "proxyType": "TorAnonymizer",
    "usage": "BLOCKLIST"
  }'
```

---

### 2.2 Restrict Admin Console Access by IP

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3(7)

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

## 3. OAuth & Integration Security

### 3.1 Implement OAuth App Consent Policies

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.2
**NIST 800-53:** AC-6, CM-7

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

---

### 3.2 Harden SCIM Provisioning Connectors

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-2, IA-4

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
```
eventType eq "system.scim.user.create" OR eventType eq "system.scim.user.update"
```

---

## 4. Session Management

### 4.1 Configure Aggressive Session Timeouts

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-12, SC-10
**DISA STIG:** V-273186, V-273187, V-273203

#### Description
Set session timeouts appropriate to risk level. Reduce maximum session lifetime and enforce re-authentication for sensitive applications.

#### Rationale
**Why This Matters:**
- Long sessions increase window for session hijacking
- October 2023 breach exploited long-lived session cookies
- Idle timeouts reduce exposure from abandoned sessions

#### ClickOps Implementation

**Step 1: Configure Global Session Policy**
1. Navigate to: **Security → Global Session Policy**
2. Select the **Default Policy**
3. Click **Add rule** (create a custom rule at Priority 1, not the "Default Rule")
4. Set:
   - **Max session lifetime:** 12 hours (L1) / 8 hours (L2) / 4 hours (L3)
   - **Max idle time:** 1 hour (L1) / 30 minutes (L2) / 15 minutes (L3)
   - **Persistent sessions:** Disabled for high-security

> **DISA STIG Requirement (V-273186, V-273203):** For DOD compliance, set:
> - **Maximum Okta global session idle time:** 15 minutes
> - **Maximum Okta global session lifetime:** 18 hours

**Step 2: Configure Admin Console Session Timeout**
1. Navigate to: **Applications → Applications → Okta Admin Console**
2. Click the **Sign On** tab
3. Under "Okta Admin Console session", set:
   - **Maximum app session idle time:** 15 minutes

> **DISA STIG Requirement (V-273187):** Admin Console must log out after 15-minute idle period.

**Step 3: Create App-Specific Session Policies**
For sensitive apps (PAM, admin consoles, financial systems):
1. Navigate to app → **Sign On** tab
2. Configure:
   - **Session lifetime:** 2 hours max
   - **Re-authentication:** Required on every access

---

### 4.2 Disable Legacy Session Persistence

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-23
**DISA STIG:** V-273206

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

> **DISA STIG Requirement (V-273206):** Set "Okta global session cookies persist across browser sessions" to **Disabled** to prevent cached authentication information from persisting.

---

## 5. Monitoring & Detection

### 5.1 Enable Comprehensive System Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3, AU-6
**DISA STIG:** V-273202 (HIGH Severity)

#### Description
Configure Okta System Log forwarding to SIEM with comprehensive event capture for security monitoring and incident response. DISA STIG requires off-loading audit records to a central log server to protect against data loss and ensure audit integrity.

#### ClickOps Implementation

**Step 1: Configure Log Streaming**
1. Navigate to: **Reports → Log Streaming**
2. Click **Add Log Stream**
3. Select integration type:
   - **AWS EventBridge** - For AWS-based SIEM solutions
   - **Splunk Cloud** - For Splunk deployments
4. Complete the required configuration fields
5. Click **Save** and verify the connection is **Active**

> **DISA STIG Requirement (V-273202 - HIGH):** Okta must off-load audit records to a central log server. If Log Streaming is unavailable for your SIEM, use the Okta Log API to export system logs in real time.

**Step 2: Alternative - Okta Log API Integration**
If your SIEM is not directly supported:
1. Navigate to: **Security → API → Tokens**
2. Create an API token with read-only System Log permissions
3. Configure your SIEM to pull logs via the System Log API endpoint

**Step 2: Create Alert Rules (via SIEM)**
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

---

## 6. Third-Party Integration Security

### 6.1 Integration Risk Assessment Matrix

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **OAuth Scopes** | Profile read-only | Read user data | Write users, groups, apps |
| **SCIM Access** | No SCIM | Read-only sync | Create/delete users |
| **Admin API** | No API access | Limited endpoints | Full API access |
| **Data Access** | User profile only | Group membership | Authentication data |

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

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Okta Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | Phishing-resistant MFA | 1.1 |
| CC6.2 | Admin role separation | 1.2 |
| CC6.6 | Network zone policies | 2.1 |
| CC7.2 | System log monitoring | 5.1 |

### NIST 800-53 Rev 5 Mapping

| Control | Okta Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | MFA enforcement | 1.1 |
| IA-2(6) | FIDO2 for admins | 1.1 |
| AC-6(1) | Custom admin roles | 1.2 |
| AU-2 | System log | 5.1 |

### DISA STIG Okta IDaaS V1R1 Mapping

| STIG ID | Control | Guide Section |
|---------|---------|---------------|
| V-273186, V-273187, V-273203 | Session timeouts | 4.1 |
| V-273188 | Account inactivity auto-disable | 8.1 |
| V-273189 | Account lockout | 8.2 |
| V-273190, V-273191 | Phishing-resistant authentication | 1.1 |
| V-273192 | DOD warning banner | 8.3 |
| V-273193, V-273194 | MFA requirements (HIGH) | 1.1 |
| V-273195-V-273201, V-273208-V-273209 | Password policy | 8.4 |
| V-273202 | Centralized logging (HIGH) | 5.1 |
| V-273204, V-273207 | PIV/CAC authentication | 8.5 |
| V-273205 | FIPS compliance | 8.6 |
| V-273206 | Persistent session cookies | 4.2 |

---

## 8. DISA STIG Compliance

This section provides comprehensive implementation guidance for the DISA Security Technical Implementation Guide (STIG) for Okta Identity as a Service (IDaaS), Version 1, Release 1 (April 2025). These controls are mandatory for DOD systems and represent security best practices for all organizations.

### DISA STIG Control Summary

| STIG ID | Title | Severity | Section |
|---------|-------|----------|---------|
| V-273186 | Global session 15-min idle timeout | Medium | 4.1 |
| V-273187 | Admin Console 15-min idle timeout | Medium | 4.1 |
| V-273188 | Disable accounts after 35-day inactivity | Medium | 8.1 |
| V-273189 | Limit 3 invalid login attempts | Medium | 8.2 |
| V-273190 | Dashboard phishing-resistant MFA | Medium | 1.1 |
| V-273191 | Admin Console phishing-resistant MFA | Medium | 1.1 |
| V-273192 | DOD Warning Banner | Medium | 8.3 |
| V-273193 | Admin Console MFA required | **HIGH** | 1.1 |
| V-273194 | Dashboard MFA required | **HIGH** | 1.1 |
| V-273195 | 15-character minimum password | Medium | 8.4 |
| V-273196 | Uppercase character required | Medium | 8.4 |
| V-273197 | Lowercase character required | Medium | 8.4 |
| V-273198 | Numeric character required | Medium | 8.4 |
| V-273199 | Special character required | Medium | 8.4 |
| V-273200 | 24-hour minimum password age | Medium | 8.4 |
| V-273201 | 60-day maximum password lifetime | Medium | 8.4 |
| V-273202 | Off-load audit records to SIEM | **HIGH** | 5.1 |
| V-273203 | 18-hour global session lifetime | Medium | 4.1 |
| V-273204 | PIV/CAC credential acceptance | Medium | 8.5 |
| V-273205 | FIPS-compliant Okta Verify | Medium | 8.6 |
| V-273206 | Disable persistent session cookies | Medium | 4.2 |
| V-273207 | DOD-approved CA certificates | Medium | 8.5 |
| V-273208 | Common password check | Medium | 8.4 |
| V-273209 | 5 password history generations | Medium | 8.4 |

---

### 8.1 Configure Account Inactivity Auto-Disable

**DISA STIG:** V-273188
**Severity:** Medium
**NIST 800-53:** AC-2(3)

#### Description
Automatically disable user accounts after 35 days of inactivity to reduce the risk of dormant account compromise. Attackers targeting inactive accounts may maintain undetected access since account owners won't notice unauthorized activity.

#### Prerequisites
- [ ] Okta Workflows license (required for Automations)
- [ ] Super Admin or Org Admin access

#### ClickOps Implementation

**Step 1: Create Inactivity Automation**
1. Navigate to: **Workflow → Automations**
2. Click **Add Automation**
3. Enter a name (e.g., "User Inactivity - 35 Day Suspension")

**Step 2: Configure Trigger Condition**
1. Click **Add Condition**
2. Select **User Inactivity in Okta**
3. Set duration to **35 days**
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

> **Note:** If Okta relies on external directory services (e.g., Active Directory) for user sourcing, this automation may not be applicable. The connected directory service must perform this function instead.

#### Validation
1. Navigate to: **Workflow → Automations**
2. Verify the automation is listed and shows **Active** status
3. Review the automation history after the first scheduled run

---

### 8.2 Configure Account Lockout Policy

**DISA STIG:** V-273189
**Severity:** Medium
**NIST 800-53:** AC-7

#### Description
Enforce account lockout after three consecutive invalid login attempts to protect against brute-force password attacks. This control significantly reduces the risk of unauthorized access via password guessing.

#### Prerequisites
- [ ] Super Admin access
- [ ] Okta-mastered users (not applicable if using external directory services)

#### ClickOps Implementation

**Step 1: Configure Password Authenticator Lockout**
1. Navigate to: **Security → Authenticators**
2. Click the **Actions** button next to **Password**
3. Select **Edit**

**Step 2: Configure Each Password Policy**
For each listed Password Policy:
1. Click **Edit** on the policy
2. Locate the **Lock Out** section
3. Check **Lock out after 3 unsuccessful attempts**
4. Set the value to **3**
5. Click **Save**

#### Validation
1. Navigate to: **Security → Authenticators → Password → Edit**
2. For each policy, verify:
   - "Lock out after 3 unsuccessful attempts" is checked
   - Value is set to "3"

> **Note:** If Okta relies on external directory services for user sourcing, this control is not applicable. The connected directory service must enforce account lockout.

---

### 8.3 Configure DOD Warning Banner

**DISA STIG:** V-273192
**Severity:** Medium
**NIST 800-53:** AC-8

#### Description
Display the Standard Mandatory DOD Notice and Consent Banner before granting access to the Okta tenant. This ensures users acknowledge that the system is for authorized use only and that their activity is subject to monitoring.

#### DOD Banner Text (1300 characters)
```
You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only.

By using this IS (which includes any device attached to this IS), you consent to the following conditions:

-The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), law enforcement (LE), and counterintelligence (CI) investigations.

-At any time, the USG may inspect and seize data stored on this IS.

-Communications using, or data stored on, this IS are not private, are subject to routine monitoring, interception, and search, and may be disclosed or used for any USG-authorized purpose.

-This IS includes security measures (e.g., authentication and access controls) to protect USG interests--not for your personal benefit or privacy.

-Notwithstanding the above, using this IS does not constitute consent to PM, LE or CI investigative searching or monitoring of the content of privileged communications, or work product, related to personal representation or services by attorneys, psychotherapists, or clergy, and their assistants. Such communications and work product are private and confidential. See User Agreement for details.
```

#### Short Banner (for character-limited displays)
```
I've read & consent to terms in IS user agreem't.
```

#### ClickOps Implementation

> **Note:** Follow the supplemental instructions in the "Okta DOD Warning Banner Configuration Guide" provided with the DISA STIG package for detailed implementation steps. The banner implementation typically involves customizing the Okta Sign-In Widget or using Okta's customization options.

**General Steps:**
1. Navigate to: **Customizations → Branding**
2. Access sign-in page customization options
3. Add the DOD warning banner text before the login form
4. Configure acknowledgment mechanism (checkbox or button)
5. Test banner display at login

#### Validation
1. Open an incognito/private browser window
2. Navigate to your Okta tenant login URL
3. Verify the DOD warning banner is displayed in full
4. Verify users must acknowledge the banner before proceeding

---

### 8.4 Configure Password Policy Settings

**DISA STIG:** V-273195, V-273196, V-273197, V-273198, V-273199, V-273200, V-273201, V-273208, V-273209
**Severity:** Medium
**NIST 800-53:** IA-5(1)

#### Description
Configure comprehensive password policies that meet DOD requirements for password complexity, age, and history. These controls protect against weak passwords, password reuse, and rapid password cycling.

#### Prerequisites
- [ ] Super Admin access
- [ ] Okta-mastered users (not applicable if using external directory services)

#### STIG Password Requirements Summary

| Requirement | STIG ID | Value |
|------------|---------|-------|
| Minimum length | V-273195 | 15 characters |
| Uppercase required | V-273196 | Yes |
| Lowercase required | V-273197 | Yes |
| Number required | V-273198 | Yes |
| Special character required | V-273199 | Yes |
| Minimum password age | V-273200 | 24 hours |
| Maximum password age | V-273201 | 60 days |
| Common password check | V-273208 | Enabled |
| Password history | V-273209 | 5 generations |

#### ClickOps Implementation

**Step 1: Access Password Authenticator Settings**
1. Navigate to: **Security → Authenticators**
2. Click the **Actions** button next to **Password**
3. Select **Edit**

**Step 2: Configure Each Password Policy**
For each listed Password Policy, click **Edit** and configure:

**Complexity Requirements:**
- **Minimum Length:** Set to at least **15** characters
- **Upper case letter:** ☑ Checked
- **Lower case letter:** ☑ Checked
- **Number (0-9):** ☑ Checked
- **Symbol (e.g., !@#$%^&*):** ☑ Checked

**Password Age Settings:**
- **Minimum password age is XX hours:** Set to at least **24**
- **Password expires after XX days:** Set to **60**

**Password History:**
- **Enforce password history for last XX passwords:** Set to **5**

**Step 3: Enable Common Password Check**
1. Under **Password Settings** section
2. Check **Common Password Check**
3. Click **Save**

#### Code Implementation

```bash
# Update password policy via API
curl -X PUT "https://${OKTA_DOMAIN}/api/v1/policies/${POLICY_ID}" \
  -H "Authorization: SSWS ${OKTA_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "password": {
        "complexity": {
          "minLength": 15,
          "minLowerCase": 1,
          "minUpperCase": 1,
          "minNumber": 1,
          "minSymbol": 1
        },
        "age": {
          "maxAgeDays": 60,
          "minAgeMinutes": 1440,
          "historyCount": 5
        }
      }
    }
  }'
```

#### Validation
1. Navigate to: **Security → Authenticators → Password → Edit**
2. For each policy, verify all settings match the requirements table above

---

### 8.5 Configure PIV/CAC Smart Card Authentication

**DISA STIG:** V-273204, V-273207
**Severity:** Medium
**NIST 800-53:** IA-2(12)

#### Description
Configure Okta to accept Personal Identity Verification (PIV) credentials and DOD Common Access Cards (CAC) for authentication. This enables hardware-based multifactor authentication using DOD-approved certificate authorities.

#### Prerequisites
- [ ] Super Admin access
- [ ] DOD-approved certificate chain (root and intermediate CA certificates)
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
4. Enter a name for the identity provider (e.g., "DOD CAC Authentication")

**Step 3: Build Certificate Chain**
1. Click **Browse** to select your root CA certificate file
2. Click **Add Another** to add intermediate CA certificates
3. Continue until the complete DOD certificate chain is uploaded
4. Click **Build certificate chain**
5. Verify the chain builds successfully with all certificates shown
6. If errors occur, verify certificate order and format

**Step 4: Configure User Matching**
1. In **IdP username**, select **idpuser.subjectAltNameUpn**
   - This attribute stores the Electronic Data Interchange Personnel Identifier (EDIPI) on the CAC
2. In **Match Against**, select the Okta Profile Attribute where EDIPI is stored
3. Click **Save**

**Step 5: Activate the Identity Provider**
1. Verify the IdP status shows **Active**
2. If inactive, click **Activate**

#### Validation
1. Navigate to: **Security → Identity Providers**
2. Verify Smart Card IdP is listed with **Type** as "Smart Card"
3. Verify **Status** is "Active"
4. Click **Actions → Configure** and verify certificate chain is from DOD-approved CA

---

### 8.6 Configure FIPS-Compliant Okta Verify

**DISA STIG:** V-273205
**Severity:** Medium
**NIST 800-53:** SC-13

#### Description
Configure Okta Verify to only connect with FIPS-compliant devices. This ensures that authentication uses FIPS 140-2 validated cryptographic modules, which is required for DOD systems.

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

### 8.7 DISA STIG Compliance Checklist

Use this checklist to verify all DISA STIG controls are implemented:

#### HIGH Severity Controls (Implement First)
- [ ] **V-273193:** Admin Console requires MFA (Password/IdP + Another factor or Any 2 factor types)
- [ ] **V-273194:** Dashboard requires MFA (Password/IdP + Another factor or Any 2 factor types)
- [ ] **V-273202:** Audit logs off-loaded to central SIEM (Log Streaming or API integration active)

#### Session Management
- [ ] **V-273186:** Global session idle timeout set to 15 minutes
- [ ] **V-273187:** Admin Console session idle timeout set to 15 minutes
- [ ] **V-273203:** Global session lifetime limited to 18 hours
- [ ] **V-273206:** Persistent session cookies disabled

#### Authentication
- [ ] **V-273189:** Account lockout after 3 failed attempts configured
- [ ] **V-273190:** Okta Dashboard requires phishing-resistant authentication
- [ ] **V-273191:** Admin Console requires phishing-resistant authentication
- [ ] **V-273204:** Smart Card Authenticator active for PIV/CAC
- [ ] **V-273205:** Okta Verify FIPS compliance enabled
- [ ] **V-273207:** Smart Card IdP uses DOD-approved CA certificates

#### Password Policy
- [ ] **V-273195:** Minimum password length 15 characters
- [ ] **V-273196:** Uppercase character required
- [ ] **V-273197:** Lowercase character required
- [ ] **V-273198:** Numeric character required
- [ ] **V-273199:** Special character required
- [ ] **V-273200:** Minimum password age 24 hours
- [ ] **V-273201:** Maximum password age 60 days
- [ ] **V-273208:** Common password check enabled
- [ ] **V-273209:** Password history 5 generations

#### Account Management
- [ ] **V-273188:** Inactive accounts auto-disabled after 35 days
- [ ] **V-273192:** DOD warning banner displayed at login

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

---

## Appendix B: References

**Official Okta Documentation:**
- [Security Best Practices](https://help.okta.com/en-us/Content/Topics/Security/security-best-practices.htm)
- [Admin Role Permissions](https://help.okta.com/en-us/Content/Topics/Security/administrators-admin-comparison.htm)
- [System Log API](https://developer.okta.com/docs/reference/api/system-log/)

**DISA STIG Documentation:**
- [DISA STIG Library](https://public.cyber.mil/stigs/)
- Okta IDaaS STIG V1R1 (April 2025) - U_Okta_IDaaS_STIG_V1R1_Manual-xccdf.xml

**Supply Chain Incident Reports:**
- [Okta October 2023 Security Incident](https://sec.okta.com/articles/2023/10/tracking-unauthorized-access-oktas-support-system)
- [LAPSUS$ March 2022 Incident](https://www.okta.com/blog/2022/03/updated-okta-statement-on-lapsus/)

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-26 | 1.1 | Added DISA STIG Okta IDaaS V1R1 compliance section with all 24 controls | How to Harden Community |
| 2025-12-14 | 1.0 | Initial Okta hardening guide | How to Harden Community |

---

**Questions or Improvements?**
- Open an issue: [GitHub Issues](https://github.com/grcengineering/how-to-harden/issues)
- Contribute: [CONTRIBUTING.md](../../CONTRIBUTING.md)
