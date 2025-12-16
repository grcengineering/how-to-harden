---
layout: guide
title: "CyberArk Hardening Guide"
vendor: "CyberArk"
slug: "cyberark"
tier: "1"
category: "PAM"
description: "Privileged access management hardening for vaults, PSM, and credential rotation"
last_updated: "2025-12-14"
---


## Overview

CyberArk is a Privileged Access Management (PAM) platform that protects credentials for **half of Fortune 500 companies** across 10,000+ organizations. As the central vault for privileged credentials, API tokens, session recordings, and SSH keys, CyberArk compromise enables immediate access to the most sensitive enterprise systems. Secrets management integrations with HashiCorp Vault, AWS Secrets Manager, and Azure Key Vault extend the attack surface beyond the vault itself.

### Intended Audience
- Security engineers managing PAM infrastructure
- IT administrators configuring CyberArk
- GRC professionals assessing privileged access compliance
- Third-party risk managers evaluating secrets management

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers CyberArk-specific security configurations including vault hardening, API security, session management, secrets rotation, and integration security with external secrets managers.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Vault Security](#2-vault-security)
3. [API & Integration Security](#3-api--integration-security)
4. [Session Management](#4-session-management)
5. [Secrets Rotation](#5-secrets-rotation)
6. [Monitoring & Detection](#6-monitoring--detection)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Multi-Factor Authentication for All Access

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1), IA-2(6)

#### Description
Require MFA for all CyberArk console access, including PVWA (Password Vault Web Access), PSM (Privileged Session Manager), and API authentication.

#### Rationale
**Why This Matters:**
- CyberArk stores the most sensitive credentials in the enterprise
- Single-factor compromise = access to all privileged accounts
- MFA is mandatory for compliance (PCI DSS, SOX, HIPAA)

**Attack Prevented:** Credential theft, phishing, password spray

**Attack Scenario:** Attacker phishes CyberArk admin credentials, gains access to entire credential vault, extracts domain admin passwords.

#### ClickOps Implementation

**Step 1: Configure LDAP/RADIUS MFA Integration**
1. Navigate to: **PVWA → Administration → Options → Authentication Methods**
2. Configure RADIUS integration:
   - **Primary server:** Your MFA RADIUS endpoint
   - **Shared secret:** (stored securely)
   - **Timeout:** 60 seconds
3. Enable for user types: All

**Step 2: Enforce MFA for Specific User Types**
1. Navigate to: **PVWA → Administration → Platform Configuration**
2. For each platform:
   - Enable: **Require MFA for connection**
   - Configure MFA prompt timing

**Step 3: Configure for Privilege Cloud**
1. Navigate to: **Identity Administration → Authentication**
2. Configure:
   - **MFA enforcement:** Required
   - **Factors:** TOTP, Push, FIDO2
   - **Remember device:** Disabled (L2/L3)

#### Code Implementation

**CyberArk REST API:**
```bash
# Configure authentication method via API
curl -X PUT "https://${PVWA_URL}/PasswordVault/API/Configuration/AuthenticationMethods/radius" \
  -H "Authorization: ${AUTH_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "radius",
    "displayName": "RADIUS MFA",
    "enabled": true,
    "settings": {
      "server": "mfa.company.com",
      "port": 1812,
      "timeout": 60
    }
  }'
```

#### Validation & Testing
1. [ ] Attempt PVWA login with password only - should fail
2. [ ] Complete login with password + MFA - should succeed
3. [ ] Verify MFA logged in audit trail
4. [ ] Test PSM connection with MFA requirement

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(1), IA-2(6) | MFA for privileged accounts |
| **PCI DSS** | 8.3.1 | MFA for administrative access |
| **SOX** | ITGC | Access control for financial systems |

---

### 1.2 Implement Vault-Level Access Controls

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure granular safe-level permissions ensuring users only access credentials required for their role. Implement approval workflows for sensitive safes.

#### ClickOps Implementation

**Step 1: Design Safe Structure**
```
Safes/
├── Infrastructure/
│   ├── Windows-DomainAdmins (requires approval)
│   ├── Linux-Root
│   └── Network-Devices
├── Applications/
│   ├── Database-Credentials
│   └── API-Keys
└── Emergency/
    └── Break-Glass (requires dual approval)
```

**Step 2: Configure Safe Permissions**
1. Navigate to: **PVWA → Policies → Access Control (Safes)**
2. For each safe, configure:
   - **Members:** Specific groups only
   - **Permissions:** Minimum required (Use, Retrieve, List)
   - **Require approval:** For sensitive safes

**Step 3: Create Approval Workflow**
1. Navigate to: **PVWA → Policies → Master Policy**
2. Configure:
   - **Require dual control:** Enabled for DomainAdmins safe
   - **Approvers:** Security team group
   - **Approval timeout:** 4 hours

#### Code Implementation

```bash
# Create safe with restricted access via REST API
curl -X POST "https://${PVWA_URL}/PasswordVault/API/Safes" \
  -H "Authorization: ${AUTH_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "safeName": "Windows-DomainAdmins",
    "description": "Domain Administrator credentials - requires approval",
    "olacEnabled": true,
    "managingCPM": "PasswordManager",
    "numberOfVersionsRetention": 10,
    "numberOfDaysRetention": 30
  }'

# Add member with limited permissions
curl -X POST "https://${PVWA_URL}/PasswordVault/API/Safes/Windows-DomainAdmins/Members" \
  -H "Authorization: ${AUTH_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "memberName": "WindowsAdmins",
    "memberType": "Group",
    "permissions": {
      "useAccounts": true,
      "retrieveAccounts": true,
      "listAccounts": true,
      "addAccounts": false,
      "updateAccountContent": false,
      "deleteAccounts": false,
      "manageSafe": false,
      "requestsAuthorizationLevel1": true
    }
  }'
```

---

### 1.3 Configure Break-Glass Procedures

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CP-2

#### Description
Implement emergency access procedures for critical scenarios when normal authentication is unavailable.

#### ClickOps Implementation

**Step 1: Create Break-Glass Safe**
1. Create safe: `Emergency-BreakGlass`
2. Store emergency credentials:
   - Master user recovery credentials
   - Emergency admin accounts
   - Critical infrastructure access

**Step 2: Configure Dual Control**
1. Require approval from 2 different approvers
2. Set expiration: 1 hour
3. Enable enhanced logging

**Step 3: Physical Security**
1. Store break-glass credentials in physical safe
2. Distribute parts to different individuals
3. Document recovery procedure

---

## 2. Vault Security

### 2.1 Harden Vault Server Configuration

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-8, SC-28

#### Description
Configure secure vault server settings including encryption, communication security, and component hardening.

#### ClickOps Implementation

**Step 1: Verify Encryption Settings**
1. Check DBParm.ini:
```ini
[MAIN]
EncryptionMethod=AES256
ServerKeyAge=365
BackupKeyAge=365
```

**Step 2: Configure Secure Communication**
1. Enable TLS 1.2/1.3 only
2. Disable legacy protocols
3. Configure certificate validation

**Step 3: Harden Operating System**
- Remove unnecessary services
- Configure Windows Firewall
- Enable audit logging

---

### 2.2 Implement Vault High Availability

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CP-9, CP-10

#### Description
Configure disaster recovery and high availability for vault infrastructure.

#### Implementation

**DR Configuration:**
1. Configure vault replication to DR site
2. Test failover quarterly
3. Document recovery procedures
4. Verify backup integrity

```bash
# Verify vault replication status
PAReplicate.exe Status

# Test DR failover (non-production)
PAReplicate.exe Failover /target:DR_VAULT
```

---

## 3. API & Integration Security

### 3.1 Secure API Authentication

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5, SC-8

#### Description
Secure CyberArk API access using certificate-based authentication, API key rotation, and IP restrictions.

#### Rationale
**Why This Matters:**
- API tokens provide programmatic access to credential vault
- Stolen API tokens enable mass credential extraction
- Long-lived tokens create persistent risk

**Attack Scenario:** Stolen API token accessing credential vault enables extraction of all privileged passwords and SSH keys.

#### ClickOps Implementation

**Step 1: Enable Certificate-Based API Authentication**
1. Navigate to: **PVWA → Administration → Options → API Settings**
2. Configure:
   - **Certificate authentication:** Enabled
   - **Client certificate required:** Yes
   - **CA validation:** Enabled

**Step 2: Create API-Specific Application Identity**
1. Navigate to: **PVWA → Applications → Application Identity**
2. Create application with:
   - **Allowed machines:** Specific IPs/hostnames
   - **Certificate:** Required
   - **Hash:** Enable for script authentication

**Step 3: Configure API Rate Limiting**
```ini
# In PVConfiguration.xml
<WebService>
  <MaxConcurrentRequests>50</MaxConcurrentRequests>
  <RequestTimeoutSeconds>120</RequestTimeoutSeconds>
  <EnableRateLimiting>true</EnableRateLimiting>
</WebService>
```

#### Code Implementation

```python
#!/usr/bin/env python3
# Secure CyberArk API authentication using certificate

import requests

PVWA_URL = "https://pvwa.company.com"
CERT_FILE = "/path/to/client.crt"
KEY_FILE = "/path/to/client.key"
CA_FILE = "/path/to/ca.crt"

def get_api_token():
    """Authenticate to CyberArk using certificate"""
    response = requests.post(
        f"{PVWA_URL}/PasswordVault/API/Auth/CyberArk/Logon",
        cert=(CERT_FILE, KEY_FILE),
        verify=CA_FILE,
        json={
            "username": "APIUser",
            "password": ""  # Certificate-based, no password
        }
    )
    return response.text.strip('"')

def get_credential(token, safe, account):
    """Retrieve credential securely"""
    response = requests.get(
        f"{PVWA_URL}/PasswordVault/API/Accounts?filter=safeName eq {safe}",
        headers={"Authorization": token},
        cert=(CERT_FILE, KEY_FILE),
        verify=CA_FILE
    )
    return response.json()
```

---

### 3.2 Restrict Integration Permissions

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-6

#### Description
Limit integration accounts to minimum required permissions. Service accounts should only access specific safes needed for their function.

#### ClickOps Implementation

**Step 1: Create Purpose-Specific Integration Users**
```
Integration Users:
├── Svc-Jenkins: Access to Application-Secrets only
├── Svc-Ansible: Access to Infrastructure-Credentials only
├── Svc-Terraform: Access to Cloud-Credentials only
└── Svc-SIEM: Audit log access only
```

**Step 2: Configure Minimal Permissions**
For each integration:
1. Grant access to specific safes only
2. Limit to `UseAccounts` permission (no admin rights)
3. Enable audit logging for all actions

---

### 3.3 Integrate with External Secrets Managers

**Profile Level:** L2 (Hardened)
**NIST 800-53:** IA-5(7)

#### Description
Securely configure integrations with HashiCorp Vault, AWS Secrets Manager, and Azure Key Vault.

#### HashiCorp Vault Integration

```bash
# Configure Vault to retrieve from CyberArk
vault write auth/approle/role/cyberark \
    token_policies="cyberark-read" \
    token_ttl=1h \
    token_max_ttl=4h

# CyberArk Secrets Hub configuration
# Sync secrets to Vault while maintaining CyberArk as source of truth
```

#### AWS Secrets Manager Integration

```python
# Sync CyberArk credentials to AWS Secrets Manager
import boto3
from cyberark import CyberArkClient

def sync_to_aws_secrets(cyberark_client, aws_region):
    secrets_client = boto3.client('secretsmanager', region_name=aws_region)

    credentials = cyberark_client.get_credentials(safe="AWS-Credentials")

    for cred in credentials:
        secrets_client.update_secret(
            SecretId=cred['name'],
            SecretString=cred['password']
        )
```

---

## 4. Session Management

### 4.1 Configure PSM Session Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-12, AU-14

#### Description
Secure Privileged Session Manager (PSM) sessions with recording, monitoring, and termination controls.

#### ClickOps Implementation

**Step 1: Enable Session Recording**
1. Navigate to: **PVWA → Administration → Platform Configuration**
2. For each platform:
   - **Enable recording:** Yes
   - **Recording format:** Universal (searchable)
   - **Storage:** Secure location with encryption

**Step 2: Configure Session Monitoring**
1. Navigate to: **PSM → Live Sessions**
2. Enable:
   - **Real-time monitoring:** Security team access
   - **Session suspension:** On suspicious activity
   - **Session termination:** Immediate capability

**Step 3: Set Session Timeouts**
```ini
# Platform configuration
MaxSessionDuration=480  # 8 hours maximum
IdleSessionTimeout=30   # 30 minutes idle
WarningBeforeTimeout=5  # 5 minute warning
```

---

### 4.2 Implement Just-In-Time Access

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-2(6)

#### Description
Configure time-limited access requests with automatic credential rotation after use.

#### ClickOps Implementation

**Step 1: Configure Time-Limited Access**
1. Navigate to: **PVWA → Policies → Master Policy**
2. Enable:
   - **Exclusive access:** Enabled
   - **One-time password:** Enabled
   - **Auto-rotate after retrieval:** Enabled

**Step 2: Configure Access Request Workflow**
1. Create request workflow:
   - User requests access
   - Approver reviews justification
   - Time-limited access granted
   - Credentials rotate after session

---

## 5. Secrets Rotation

### 5.1 Configure Automatic Password Rotation

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(1)

#### Description
Enable CPM (Central Policy Manager) to automatically rotate privileged credentials based on policy.

#### ClickOps Implementation

**Step 1: Configure Rotation Policy**
1. Navigate to: **PVWA → Policies → Platform Configuration**
2. For each platform, configure:
   - **Password change interval:** 30 days (L1) / 7 days (L2)
   - **Verification interval:** Daily
   - **Reconcile interval:** Weekly

**Step 2: Configure Password Complexity**
```ini
# Platform password policy
MinLength=20
RequireUppercase=true
RequireLowercase=true
RequireNumbers=true
RequireSpecial=true
ExcludedCharacters='"<>;
```

---

### 5.2 Monitor Rotation Failures

**Profile Level:** L1 (Baseline)

#### Description
Alert on password rotation failures to prevent credential staleness.

```sql
-- Query for rotation failures (via SIEM or reporting)
SELECT AccountName, SafeName, LastFailReason, LastFailDate
FROM PasswordVault_Accounts
WHERE CPMStatus = 'FAILED'
ORDER BY LastFailDate DESC;
```

---

## 6. Monitoring & Detection

### 6.1 Enable Comprehensive Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure CyberArk audit logging and forward to SIEM for security monitoring.

#### Detection Use Cases

**Anomaly 1: Mass Credential Retrieval**
```sql
SELECT UserName, COUNT(*) as RetrievalCount
FROM AuditLog
WHERE Action = 'Retrieve Password'
  AND Timestamp > DATEADD(hour, -1, GETDATE())
GROUP BY UserName
HAVING COUNT(*) > 20;
```

**Anomaly 2: After-Hours Access**
```sql
SELECT *
FROM AuditLog
WHERE Action IN ('Logon', 'Retrieve Password')
  AND (DATEPART(hour, Timestamp) < 6 OR DATEPART(hour, Timestamp) > 20)
  AND DATEPART(dw, Timestamp) IN (1, 7);  -- Weekends
```

**Anomaly 3: Failed Authentication Spike**
```sql
SELECT UserName, SourceIP, COUNT(*) as FailedAttempts
FROM AuditLog
WHERE Action = 'Logon'
  AND Status = 'Failed'
  AND Timestamp > DATEADD(minute, -15, GETDATE())
GROUP BY UserName, SourceIP
HAVING COUNT(*) > 5;
```

---

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | CyberArk Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA enforcement | 1.1 |
| CC6.2 | Safe permissions | 1.2 |
| CC7.2 | Audit logging | 6.1 |

### NIST 800-53 Mapping

| Control | CyberArk Control | Guide Section |
|---------|------------------|---------------|
| IA-2(6) | MFA for privileged | 1.1 |
| AC-6 | Least privilege safes | 1.2 |
| IA-5(1) | Password rotation | 5.1 |
| AU-14 | Session recording | 4.1 |

---

## Appendix A: References

**Official CyberArk Documentation:**
- [Security Best Practices](https://docs.cyberark.com/security-best-practices)
- [REST API Guide](https://docs.cyberark.com/rest-api)
- [CPM Configuration](https://docs.cyberark.com/cpm)

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial CyberArk hardening guide | How to Harden Community |
