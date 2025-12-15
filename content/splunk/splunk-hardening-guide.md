# Splunk Hardening Guide

**Version:** 1.0
**Last Updated:** 2025-12-14
**Product Editions Covered:** Splunk Enterprise, Splunk Cloud
**Authors:** How to Harden Community

---

## Overview

Splunk is the core SOC platform with **800+ Splunkbase integrations** aggregating security logs from entire enterprises. API key compromise enables access to detection rules, threat intelligence, and incident response data—providing attackers complete visibility into defensive capabilities. SOAR playbook manipulation can disable automated response.

### Intended Audience
- Security engineers managing SIEM platforms
- SOC administrators configuring Splunk
- GRC professionals assessing security monitoring
- Third-party risk managers evaluating SIEM integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API & App Security](#2-api--app-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SAML SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all Splunk access.

#### Rationale
**Why This Matters:**
- Splunk contains all security telemetry
- Compromised access reveals defensive capabilities
- Detection rules and playbooks are high-value intel

**Attack Scenario:** Compromised API credentials export detection rules; SOAR playbook manipulation disables automated response.

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Settings → Access controls → Authentication method**
2. Select: **SAML**
3. Configure IdP settings

**Step 2: Map Roles**
1. Configure SAML attribute mapping
2. Map IdP groups to Splunk roles

---

### 1.2 Implement Role-Based Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Roles**
| Role | Permissions |
|------|-------------|
| admin | Full access (2-3 users) |
| sc_admin | Splunk Cloud specific |
| power | Search all data, create knowledge objects |
| user | Search assigned indexes only |
| analyst | SOC functions, no admin |

**Step 2: Configure Index Access**
1. Navigate to: **Settings → Access controls → Roles**
2. For each role, configure:
   - Allowed indexes
   - Search restrictions
   - App access

---

## 2. API & App Security

### 2.1 Secure API Tokens

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Manage Splunk API tokens securely.

#### ClickOps Implementation

**Step 1: Audit Existing Tokens**
```bash
# List authentication tokens
curl -k -u admin:password \
  https://splunk:8089/services/authentication/tokens
```

**Step 2: Create Scoped Tokens**
1. Create tokens with minimum permissions
2. Set expiration (90 days max)
3. Bind to specific IP addresses

---

### 2.2 Splunkbase App Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### ClickOps Implementation

**Step 1: Review Installed Apps**
1. Navigate to: **Apps → Manage Apps**
2. Review all installed apps
3. Remove unused apps

**Step 2: Configure App Installation Policy**
1. Restrict app installation to admins
2. Require security review for new apps
3. Update apps regularly

---

## 3. Data Security

### 3.1 Configure Index Access Controls

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3

#### ClickOps Implementation

**Step 1: Segment Indexes**
```
Index Strategy:
├── security (SOC access only)
├── network (network team + SOC)
├── application (app teams)
└── audit (compliance + security)
```

**Step 2: Configure Role-Index Mapping**
1. Navigate to: **Settings → Access controls → Roles**
2. Configure: **Indexes searched by default**
3. Restrict sensitive indexes

---

## 4. Monitoring & Detection

### 4.1 Monitor Splunk Itself

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-6

#### Detection Queries

```spl
# Detect unusual search activity
index=_audit action=search
| stats count by user, search
| where count > 100

# Detect configuration changes
index=_audit action=edit_*
| table _time user action object

# Detect failed authentication
index=_audit action=login status=failure
| stats count by user, src
| where count > 5
```

---

## Appendix A: Edition Compatibility

| Control | Enterprise | Cloud |
|---------|------------|-------|
| SAML SSO | ✅ | ✅ |
| Role-Based Access | ✅ | ✅ |
| API Tokens | ✅ | ✅ |
| Audit Logging | ✅ | ✅ |

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial Splunk hardening guide | How to Harden Community |
