# Okta Hardening Guide

**Version:** 1.0
**Last Updated:** 2025-12-14
**Product Editions Covered:** Okta Identity Cloud (all tiers), Okta Workforce Identity, Okta Customer Identity
**Authors:** How to Harden Community

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

---

## 1. Authentication & Access Controls

### 1.1 Enforce Phishing-Resistant MFA (FIDO2/WebAuthn)

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1), IA-2(6)

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
2. Set:
   - **Max session lifetime:** 12 hours (L1) / 8 hours (L2) / 4 hours (L3)
   - **Max idle time:** 1 hour (L1) / 30 minutes (L2) / 15 minutes (L3)
   - **Persistent sessions:** Disabled for high-security

**Step 2: Create App-Specific Session Policies**
For sensitive apps (PAM, admin consoles, financial systems):
1. Navigate to app → **Sign On** tab
2. Configure:
   - **Session lifetime:** 2 hours max
   - **Re-authentication:** Required on every access

---

### 4.2 Disable Legacy Session Persistence

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-23

#### Description
Disable "Remember Me" and persistent session features that increase session hijacking risk.

#### ClickOps Implementation

1. Navigate to: **Security → Global Session Policy**
2. Disable:
   - **Remember my device for MFA**
   - **Stay signed in for:** Set to minimum
3. Navigate to: **Customizations → Other**
4. Disable: **Allow users to remain signed in**

---

## 5. Monitoring & Detection

### 5.1 Enable Comprehensive System Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3, AU-6

#### Description
Configure Okta System Log forwarding to SIEM with comprehensive event capture for security monitoring and incident response.

#### ClickOps Implementation

**Step 1: Configure Log Streaming**
1. Navigate to: **Reports → System Log**
2. Verify logging enabled for all event types
3. Navigate to: **Settings → Log Streaming**
4. Configure SIEM integration:
   - Splunk (HTTP Event Collector)
   - AWS EventBridge
   - SIEM-specific integrations

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

**Supply Chain Incident Reports:**
- [Okta October 2023 Security Incident](https://sec.okta.com/articles/2023/10/tracking-unauthorized-access-oktas-support-system)
- [LAPSUS$ March 2022 Incident](https://www.okta.com/blog/2022/03/updated-okta-statement-on-lapsus/)

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial Okta hardening guide | How to Harden Community |

---

**Questions or Improvements?**
- Open an issue: [GitHub Issues](https://github.com/grcengineering/how-to-harden/issues)
- Contribute: [CONTRIBUTING.md](../../CONTRIBUTING.md)
