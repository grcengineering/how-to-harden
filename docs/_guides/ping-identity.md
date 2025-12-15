---
layout: guide
title: "Ping Identity Hardening Guide"
vendor: "Ping Identity"
slug: "ping-identity"
tier: "1"
category: "Identity"
description: "Identity federation security for PingFederate, PingOne, and OAuth configurations"
last_updated: "2025-12-14"
---


## Overview

Ping Identity serves **50%+ of Fortune 100** with federation trust relationships connecting enterprise identity to hundreds of downstream applications. OAuth and SAML tokens, if compromised, provide persistent access across the enterprise. The PingOne DaVinci orchestration platform creates automated identity workflows that attackers can exploit for privilege escalation and persistent access.

### Intended Audience
- Security engineers managing identity infrastructure
- IT administrators configuring Ping Identity products
- GRC professionals assessing IAM compliance
- Third-party risk managers evaluating federation security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Ping Identity security configurations including federation hardening, OAuth security, DaVinci orchestration controls, and token lifecycle management.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Federation Security](#2-federation-security)
3. [OAuth & Token Security](#3-oauth--token-security)
4. [DaVinci Orchestration Security](#4-davinci-orchestration-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Phishing-Resistant MFA

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1), IA-2(6)

#### Description
Require FIDO2/WebAuthn authenticators for administrator and high-privilege user authentication.

#### Rationale
**Why This Matters:**
- Federation trust means Ping Identity compromise affects all connected apps
- TOTP/SMS MFA can be bypassed via real-time phishing
- FIDO2 provides origin-bound authentication resistant to phishing

**Attack Scenario:** Attacker phishes admin credentials, generates valid tokens for any connected application via federation trust exploitation.

#### ClickOps Implementation (PingOne)

**Step 1: Enable FIDO2 Authentication**
1. Navigate to: **Authentication → Policies → MFA Policies**
2. Create policy:
   - **Name:** "Phishing-Resistant MFA"
   - **Methods:** FIDO2 Security Key (required)
   - **Fallback:** None for admins
3. Assign to administrator groups

**Step 2: Configure Authentication Policy**
1. Navigate to: **Authentication → Policies → Sign-On Policies**
2. Create rule:
   - **Condition:** User group = "Administrators"
   - **Action:** Require FIDO2 MFA
   - **Session duration:** 2 hours maximum

**Step 3: Disable Legacy Methods for Admins**
1. Navigate to: **Authentication → MFA**
2. For admin accounts:
   - Disable: SMS, Voice, Email OTP
   - Enable only: FIDO2, Mobile app (push with number matching)

#### Code Implementation (PingOne API)

```bash
# Create MFA policy requiring FIDO2
curl -X POST "https://api.pingone.com/v1/environments/${ENV_ID}/mfaPolicies" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Phishing-Resistant MFA",
    "enabled": true,
    "configuration": {
      "fido2": {
        "enabled": true,
        "required": true
      },
      "sms": {
        "enabled": false
      },
      "totp": {
        "enabled": false
      }
    }
  }'

# Assign to admin group
curl -X PUT "https://api.pingone.com/v1/environments/${ENV_ID}/groups/${ADMIN_GROUP_ID}/mfaPolicy" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "mfaPolicyId": "${MFA_POLICY_ID}"
  }'
```

#### Compliance Mappings
| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(6) | MFA for privileged accounts |
| **PCI DSS** | 8.3.1 | MFA for administrative access |

---

### 1.2 Implement Least-Privilege Admin Roles

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-6, AC-6(1)

#### Description
Create granular administrative roles instead of using organization-wide admin access.

#### ClickOps Implementation (PingOne)

**Step 1: Create Custom Admin Roles**
1. Navigate to: **Settings → Roles**
2. Create roles:

**Identity Administrator:**
- Manage users and groups
- Reset passwords
- Assign MFA
- NO: Configure applications, manage policies

**Application Administrator:**
- Configure SAML/OIDC applications
- Manage application policies
- NO: Manage users, access audit logs

**Security Administrator:**
- Configure MFA policies
- Manage authentication policies
- Access audit logs
- NO: Manage applications directly

**Read-Only Auditor:**
- View all configurations
- Access reports and logs
- NO: Make any changes

**Step 2: Assign Roles to Groups**
1. Navigate to: **Identities → Groups**
2. Create admin groups (e.g., "Identity-Admins", "App-Admins")
3. Assign appropriate roles to each group
4. Add users to groups (not direct role assignment)

---

### 1.3 Configure IP-Based Access Restrictions

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-3(7), SC-7

#### Description
Restrict administrative console and API access to known IP ranges.

#### ClickOps Implementation

**Step 1: Configure IP Restrictions (PingOne)**
1. Navigate to: **Settings → IP Restrictions**
2. Add allowed IP ranges:
   - Corporate network CIDRs
   - VPN egress IPs
3. Set default: Deny all not in list

**Step 2: Configure in Sign-On Policy**
1. Navigate to: **Authentication → Policies → Sign-On Policies**
2. Create rule:
   - **Condition:** IP not in trusted ranges
   - **Action:** Deny access OR require additional verification

---

## 2. Federation Security

### 2.1 Harden SAML Federation Trust

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5, SC-23

#### Description
Configure secure SAML settings to prevent assertion manipulation and replay attacks.

#### Rationale
**Why This Matters:**
- SAML assertions can be manipulated if not properly validated
- Weak signature algorithms enable forgery
- Long assertion validity enables replay attacks

**Attack Scenario:** Federation trust exploitation enables attackers to generate valid tokens for any connected application.

#### ClickOps Implementation (PingFederate)

**Step 1: Configure Secure Signature Settings**
1. Navigate to: **System → Server Configuration → Signing & Encryption**
2. Configure:
   - **Signature Algorithm:** RSA-SHA256 (minimum)
   - **Digest Algorithm:** SHA-256 (minimum)
   - **Key Size:** 2048+ bits RSA or P-256 ECDSA
3. Disable: SHA-1 algorithms

**Step 2: Configure Assertion Validation**
1. Navigate to: **Identity Provider → Connection → SAML Settings**
2. Enable:
   - **Verify Signature:** Required
   - **Require Encrypted Assertions:** Yes (L2)
   - **Audience Restriction:** Enforce
3. Set:
   - **Assertion Valid Period:** 5 minutes (maximum)
   - **Session Timeout:** 8 hours

**Step 3: Configure Certificate Validation**
1. Navigate to: **Security → Certificate Management**
2. Enable:
   - **Certificate revocation checking:** CRL or OCSP
   - **Key usage validation:** Enabled
3. Configure: Certificate expiration alerts (30 days)

#### Code Implementation

```xml
<!-- PingFederate SAML Configuration -->
<saml:Assertion>
  <saml:Conditions
    NotBefore="2025-01-15T10:00:00Z"
    NotOnOrAfter="2025-01-15T10:05:00Z">
    <saml:AudienceRestriction>
      <saml:Audience>https://sp.company.com</saml:Audience>
    </saml:AudienceRestriction>
  </saml:Conditions>
</saml:Assertion>
```

---

### 2.2 Implement Federation Monitoring

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-6, SI-4

#### Description
Monitor federation activity for anomalous patterns indicating compromise.

#### Detection Use Cases

```sql
-- Detect unusual federation token issuance
SELECT application_name, COUNT(*) as token_count
FROM federation_events
WHERE event_type = 'TOKEN_ISSUED'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY application_name
HAVING COUNT(*) > 100;

-- Detect new user federation patterns
SELECT user_id, application_name, first_access
FROM (
  SELECT user_id, application_name,
         MIN(timestamp) as first_access
  FROM federation_events
  WHERE timestamp > NOW() - INTERVAL '24 hours'
  GROUP BY user_id, application_name
) new_access
WHERE first_access > NOW() - INTERVAL '24 hours';

-- Detect after-hours admin authentication
SELECT user_id, application_name, timestamp
FROM federation_events
WHERE application_name = 'PingOne Admin Console'
  AND (EXTRACT(HOUR FROM timestamp) < 6
       OR EXTRACT(HOUR FROM timestamp) > 20);
```

---

### 2.3 Certificate Lifecycle Management

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-12

#### Description
Implement proactive certificate management to prevent federation disruption.

#### ClickOps Implementation

**Step 1: Configure Certificate Rotation**
1. Navigate to: **Security → Certificate Management**
2. Enable: **Automatic certificate renewal alerts**
3. Set thresholds:
   - 90 days: Warning
   - 30 days: Critical alert
   - 14 days: Emergency procedures

**Step 2: Implement Dual Certificate**
1. Add new certificate before old expires
2. Configure SP connections to accept both
3. Coordinate rotation with SPs
4. Remove old certificate after validation

---

## 3. OAuth & Token Security

### 3.1 Configure Secure OAuth Settings

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(13), SC-23

#### Description
Harden OAuth authorization server configuration with short token lifetimes and restricted scopes.

#### ClickOps Implementation (PingOne)

**Step 1: Configure Token Lifetimes**
1. Navigate to: **Applications → OAuth Settings**
2. Configure:
   - **Access Token Lifetime:** 1 hour (maximum)
   - **Refresh Token Lifetime:** 7 days (L1) / 24 hours (L2)
   - **ID Token Lifetime:** 1 hour
   - **Authorization Code Lifetime:** 60 seconds

**Step 2: Enable Token Binding**
1. Navigate to: **Applications → [App] → OAuth Settings**
2. Enable:
   - **Require PKCE:** For public clients
   - **Token binding:** Certificate-bound tokens (L2)

**Step 3: Restrict Grant Types**
1. Disable unnecessary grant types:
   - Implicit grant: Disabled (deprecated)
   - Resource Owner Password: Disabled unless required
2. Enable only: Authorization Code with PKCE

#### Code Implementation

```bash
# PingOne - Configure OAuth application
curl -X PUT "https://api.pingone.com/v1/environments/${ENV_ID}/applications/${APP_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Secure App",
    "protocol": "OPENID_CONNECT",
    "tokenEndpointAuthMethod": "CLIENT_SECRET_POST",
    "grantTypes": ["AUTHORIZATION_CODE", "REFRESH_TOKEN"],
    "pkceEnforcement": "S256_REQUIRED",
    "accessTokenValiditySeconds": 3600,
    "refreshTokenValiditySeconds": 86400,
    "refreshTokenRollingEnabled": true
  }'
```

---

### 3.2 Implement Token Revocation

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-2(6)

#### Description
Enable token revocation for user sessions and compromised tokens.

#### ClickOps Implementation

**Step 1: Enable Session Revocation**
1. Navigate to: **Authentication → Session Management**
2. Enable:
   - **Allow session revocation:** Yes
   - **Propagate revocation:** To all connected apps

**Step 2: Configure Revocation on Risk**
1. Navigate to: **Authentication → Risk Policies**
2. Create rule:
   - **Trigger:** High-risk authentication detected
   - **Action:** Revoke all user tokens
   - **Notify:** Security team

**Step 3: Admin Revocation Capability**
1. Verify admin can revoke user sessions
2. Document incident response procedure
3. Test revocation propagation

---

### 3.3 OAuth Consent Management

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-6

#### Description
Control OAuth consent to prevent unauthorized application access.

#### ClickOps Implementation

**Step 1: Enable Admin Consent Requirement**
1. Navigate to: **Applications → Settings**
2. Enable: **Require admin consent for new applications**
3. Configure approval workflow

**Step 2: Review Existing Consents**
1. Navigate to: **Identities → User → Authorized Applications**
2. Audit granted permissions
3. Revoke unnecessary or suspicious consents

---

## 4. DaVinci Orchestration Security

### 4.1 Secure DaVinci Flows

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-3, CM-3

#### Description
Harden PingOne DaVinci orchestration flows to prevent abuse and unauthorized workflow execution.

#### Rationale
**Why This Matters:**
- DaVinci flows automate identity processes
- Misconfigured flows enable privilege escalation
- Compromised flows provide persistent backdoors

#### ClickOps Implementation

**Step 1: Implement Flow Approval Workflow**
1. Navigate to: **DaVinci → Settings**
2. Enable:
   - **Require approval for flow changes:** Yes
   - **Approvers:** Security team

**Step 2: Audit Existing Flows**
1. Navigate to: **DaVinci → Flows**
2. For each flow, verify:
   - Business justification documented
   - Minimal permissions required
   - Error handling doesn't leak information
   - Logging enabled

**Step 3: Restrict Sensitive Connectors**
1. Identify high-risk connectors:
   - User provisioning
   - Group management
   - Password reset
2. Limit to approved flows only
3. Require additional authentication for sensitive actions

**Step 4: Enable Flow Logging**
1. Navigate to: **DaVinci → Settings → Logging**
2. Enable:
   - **Log all flow executions:** Yes
   - **Include input/output:** Masked sensitive data
   - **Retention:** 90 days minimum

---

### 4.2 Version Control for Flows

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-3

#### Description
Implement version control and change management for DaVinci flows.

#### Implementation

1. Export flows regularly to git repository
2. Require pull request for changes
3. Implement staging environment for testing
4. Document rollback procedures

---

## 5. Monitoring & Detection

### 5.1 Configure Comprehensive Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3, AU-6

#### Description
Enable comprehensive audit logging for all identity operations.

#### ClickOps Implementation (PingOne)

**Step 1: Configure Audit Settings**
1. Navigate to: **Settings → Audit**
2. Enable:
   - **Authentication events:** All
   - **Administrative events:** All
   - **API events:** All
   - **DaVinci flow events:** All

**Step 2: Configure Log Export**
1. Navigate to: **Settings → Audit → Export**
2. Configure SIEM integration:
   - S3 bucket export
   - Webhook to SIEM
   - Splunk integration

**Step 3: Configure Alerts**
1. Navigate to: **Settings → Alerts**
2. Create alerts for:
   - Failed admin authentication (>5 in 5 minutes)
   - New application created
   - MFA policy disabled
   - High-privilege role assigned

#### Detection Queries

```sql
-- Detect potential credential stuffing
SELECT ip_address, COUNT(*) as attempts
FROM authentication_events
WHERE result = 'FAILED'
  AND timestamp > NOW() - INTERVAL '5 minutes'
GROUP BY ip_address
HAVING COUNT(*) > 50;

-- Detect privilege escalation
SELECT actor_id, target_user, new_role
FROM admin_events
WHERE event_type = 'ROLE_ASSIGNED'
  AND new_role IN ('Organization Admin', 'Environment Admin')
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect unusual federation patterns
SELECT user_id, application_name, COUNT(*) as access_count
FROM federation_events
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_id, application_name
HAVING COUNT(*) > 100;
```

---

## 6. Third-Party Integration Security

### 6.1 SP Connection Hardening

**Profile Level:** L1 (Baseline)

#### Description
Harden Service Provider (SP) connections in federation.

#### For Each SP Connection:
- ✅ Verify SP certificate validity
- ✅ Configure audience restriction
- ✅ Set minimum assertion validity
- ✅ Enable encryption (L2)
- ✅ Document business owner

### 6.2 API Client Management

| Client Type | Token Lifetime | Scopes | Controls |
|-------------|---------------|--------|----------|
| **SCIM Provisioner** | 1 hour | Users, Groups | IP restriction, audit logging |
| **SSO Application** | 4 hours | OpenID, Profile | Standard validation |
| **Admin API** | 15 minutes | Admin scopes | MFA required, IP restriction |
| **Reporting** | 1 hour | Read-only | Dedicated service account |

---

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Ping Identity Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA enforcement | 1.1 |
| CC6.2 | RBAC | 1.2 |
| CC6.6 | IP restrictions | 1.3 |
| CC7.2 | Audit logging | 5.1 |

### NIST 800-53 Mapping

| Control | Ping Identity Control | Guide Section |
|---------|------------------|---------------|
| IA-2(6) | Phishing-resistant MFA | 1.1 |
| IA-5 | Federation security | 2.1 |
| SC-23 | Token security | 3.1 |
| AU-2 | Audit logging | 5.1 |

---

## Appendix A: Edition Compatibility

| Control | PingOne Essentials | PingOne Plus | PingOne Enterprise |
|---------|-------------------|--------------|-------------------|
| MFA | ✅ | ✅ | ✅ |
| FIDO2 | ❌ | ✅ | ✅ |
| DaVinci | ❌ | Limited | ✅ |
| Risk-Based Auth | ❌ | ❌ | ✅ |
| API Access | Limited | ✅ | ✅ |

---

## Appendix B: References

**Official Ping Identity Documentation:**
- [PingOne Security Guide](https://docs.pingidentity.com/pingone)
- [PingFederate Administration](https://docs.pingidentity.com/pingfederate)
- [API Reference](https://apidocs.pingidentity.com)

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial Ping Identity hardening guide | How to Harden Community |
