---
layout: guide
title: "Salesforce Hardening Guide"
vendor: "Salesforce"
slug: "salesforce"
tier: "2"
category: "CRM"
description: "CRM platform security for MFA enforcement, Connected Apps, and Shield Event Monitoring"
last_updated: "2025-12-12"
---


**Version:** 1.0
**Last Updated:** 2025-12-12
**Salesforce Editions Covered:** Enterprise, Unlimited, Performance (some controls require Shield add-on)
**Authors:** How to Harden Community

---

## Overview

This guide provides comprehensive security hardening recommendations for Salesforce, organized by control category. Each recommendation includes both **ClickOps** (GUI-based) and **Code** (automation-based) implementation methods.

### Intended Audience
- Security engineers configuring Salesforce security controls
- IT administrators managing Salesforce instances
- GRC professionals assessing Salesforce compliance
- Third-party risk managers evaluating integration security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Salesforce-specific security configurations. For infrastructure hardening (AWS, Azure where Salesforce runs), refer to CIS Benchmarks.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Network Access Controls](#2-network-access-controls)
3. [OAuth & Connected App Security](#3-oauth--connected-app-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Multi-Factor Authentication (MFA) for All Users

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1), IA-2(2)

#### Description
Require all Salesforce users to use MFA for authentication, eliminating single-factor authentication vulnerabilities.

#### Rationale
- **Attack Prevented:** Credential stuffing, password spray, phished passwords
- **Incident Example:** Okta support breach (2023) - attackers used stolen credentials without MFA

#### ClickOps Implementation
1. Navigate to: **Setup → Identity → Multi-Factor Authentication**
2. Enable: **"Require Multi-Factor Authentication (MFA) for all direct UI logins"**
3. Configure allowed authenticator types:
   - ☑ Salesforce Authenticator (recommended)
   - ☑ TOTP-based apps (Google Authenticator, Authy)
   - ☐ SMS (NOT recommended - vulnerable to SIM swapping)
4. Set enforcement date and communicate to users
5. Verify in Login History: **Setup → Security → Login History** (check for MFA column)

#### Code Implementation
```bash
# Using Salesforce CLI
sf org login web --alias prod-org

# Query current MFA settings
sf data query --query "SELECT Id, UserName, MfaEnabled FROM User WHERE IsActive = true" \
  --target-org prod-org

# Enable MFA requirement via Session Settings (requires API)
curl -X PATCH "${SF_INSTANCE_URL}/services/data/v59.0/sobjects/SessionSettings/SYSTEM" \
  -H "Authorization: Bearer ${SF_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "requireMfa": true,
    "requireMfaForAllLogins": true
  }'
```

#### Compliance Mappings
- **SOC 2:** CC6.1 (Logical Access)
- **NIST 800-53:** IA-2(1), IA-2(2)
- **PCI DSS:** 8.3

---

## 2. Network Access Controls

### 2.1 Restrict API Access via IP Allowlisting for Third-Party Integrations

**Profile Level:** L1 (Baseline)
**CIS Controls:** 13.3, 13.6
**NIST 800-53:** AC-3, SC-7

#### Description
Configure Salesforce Network Access to restrict API calls from third-party integrations (like Gainsight, Drift, HubSpot) to their documented static egress IP addresses. This prevents compromised integrations from accessing your data from attacker-controlled infrastructure.

#### Rationale
**Attack Prevented:** Supply chain compromise via OAuth token theft

**Real-World Incidents:**
- **Gainsight Breach (November 2025):** Attackers exfiltrated data from 200+ Salesforce orgs using stolen OAuth tokens from compromised Gainsight infrastructure
- **Salesloft/Drift Breach (August 2025):** 700+ orgs compromised via stolen OAuth tokens
- **Okta Survival:** Okta was targeted but protected because they had IP allowlisting configured

**Why This Works:** Even if integration's OAuth tokens are stolen, attackers cannot use them from infrastructure outside the integration's documented IP ranges.

---

### 2.1.1 IP Allowlisting: Restricting Gainsight

#### Prerequisites
- [ ] Salesforce Enterprise Edition or higher
- [ ] Gainsight's current static egress IP addresses
- [ ] System Administrator access

#### Gainsight IP Addresses
As of 2025-12-12, Gainsight uses these production egress IPs:
- `35.166.202.113/32`
- `52.35.87.209/32`
- `34.221.135.142/32`

⚠️ **Verify before implementing:** Contact your Gainsight CSM or check [Gainsight IP Documentation](https://support.gainsight.com/Gainsight_NXT/Integrations/IP_Addresses)

#### ClickOps Implementation

**Step 1: Navigate to Network Access**
1. Setup (gear icon) → Quick Find: "Network Access" → **Network Access**

**Step 2: Add Gainsight IP Ranges**
For each IP address:
1. Click **"New"** in Trusted IP Ranges section
2. Enter:
   - **Start IP Address:** `35.166.202.113`
   - **End IP Address:** `35.166.202.113`
   - **Description:** `Gainsight Production 1 - verified 2025-12-12`
3. Click **"Save"**
4. Repeat for remaining IPs (`52.35.87.209`, `34.221.135.142`)

**Step 3: Test Integration**
1. Trigger Gainsight manual sync
2. Verify data flows correctly
3. Check Login History for blocked attempts: **Setup → Security → Login History**

**Time to Complete:** ~10 minutes

#### Code Implementation

**Option 1: Salesforce API (bash/curl)**
```bash
ORG_URL="https://your-instance.salesforce.com"
ACCESS_TOKEN="your_oauth_token"

# Gainsight production IPs
GAINSIGHT_IPS=(
  "35.166.202.113:35.166.202.113:Gainsight Production 1"
  "52.35.87.209:52.35.87.209:Gainsight Production 2"
  "34.221.135.142:34.221.135.142:Gainsight Production 3"
)

for ip_entry in "${GAINSIGHT_IPS[@]}"; do
  IFS=':' read -r start end description <<< "$ip_entry"

  curl -X POST "${ORG_URL}/services/data/v59.0/sobjects/LoginIpRange" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
      \"StartAddress\": \"${start}\",
      \"EndAddress\": \"${end}\",
      \"Description\": \"${description} - verified $(date +%Y-%m-%d)\"
    }"
done

# Verify
curl -X GET "${ORG_URL}/services/data/v59.0/query?q=SELECT+StartAddress,Description+FROM+LoginIpRange+WHERE+Description+LIKE+'%Gainsight%'" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Option 2: Terraform**
```hcl
# terraform/salesforce/network-access.tf

locals {
  gainsight_ips = {
    "prod_1" = { start = "35.166.202.113", end = "35.166.202.113" }
    "prod_2" = { start = "52.35.87.209", end = "52.35.87.209" }
    "prod_3" = { start = "34.221.135.142", end = "34.221.135.142" }
  }
}

resource "salesforce_login_ip_range" "gainsight" {
  for_each = local.gainsight_ips

  start_address = each.value.start
  end_address   = each.value.end
  description   = "Gainsight ${each.key} - verified 2025-12-12"
}
```

**Option 3: Python Script**
```python
#!/usr/bin/env python3
# automation/scripts/salesforce/configure-gainsight-ips.py

from simple_salesforce import Salesforce
import os
from datetime import date

sf = Salesforce(
    username=os.environ['SF_USERNAME'],
    password=os.environ['SF_PASSWORD'],
    security_token=os.environ['SF_SECURITY_TOKEN']
)

GAINSIGHT_IPS = [
    {"start": "35.166.202.113", "end": "35.166.202.113", "name": "Production 1"},
    {"start": "52.35.87.209", "end": "52.35.87.209", "name": "Production 2"},
    {"start": "34.221.135.142", "end": "34.221.135.142", "name": "Production 3"},
]

today = date.today().isoformat()

for ip in GAINSIGHT_IPS:
    try:
        sf.LoginIpRange.create({
            'StartAddress': ip['start'],
            'EndAddress': ip['end'],
            'Description': f"Gainsight {ip['name']} - verified {today}"
        })
        print(f"✓ Added: {ip['start']} (Gainsight {ip['name']})")
    except Exception as e:
        print(f"❌ Failed to add {ip['start']}: {e}")
```

#### Monitoring & Maintenance

**Quarterly Review Checklist:**
- [ ] Verify Gainsight IPs haven't changed (contact CSM or check documentation)
- [ ] Update description fields with new verification date
- [ ] Review Event Monitoring logs for blocked attempts
- [ ] Test integration after any changes

**Alert Configuration:**
If using Salesforce Shield Event Monitoring:
```sql
-- Query for blocked Gainsight login attempts
SELECT Id, LoginTime, SourceIp, Status, Application
FROM LoginHistory
WHERE Application = 'Gainsight'
  AND Status = 'Failed'
  AND LoginTime = LAST_N_DAYS:7
```

#### Operational Impact
- **User Experience:** None (users don't interact with integration directly)
- **Integration Functionality:** Low risk if IPs verified with vendor
- **Rollback:** Easy - remove IP ranges from trusted list

#### Compliance Mappings
- **SOC 2:** CC6.6 (Boundary Protection)
- **NIST 800-53:** AC-3, SC-7, SC-7(5)
- **ISO 27001:** A.8.3 (Supplier relationships)

---

### 2.1.2 IP Allowlisting: Restricting Drift

#### Drift IP Addresses
As of 2025-12-12:
- `52.2.219.12/32`
- `54.196.47.40/32`
- `54.82.90.31/32`

Source: [Drift IP Allowlist Documentation](https://gethelp.drift.com/hc/en-us/articles/360019693114-IP-Allowlist)

**Implementation:** Follow same process as Gainsight (Section 2.1.1), replacing IP addresses.

---

### 2.1.3 IP Allowlisting: Restricting HubSpot

#### HubSpot IP Addresses
HubSpot publishes their IP ranges at: https://knowledge.hubspot.com/integrations/what-are-hubspot-s-ip-addresses

**Note:** HubSpot has a larger IP range and may change more frequently. Consider:
- More frequent verification (monthly vs quarterly)
- Monitoring HubSpot status page for infrastructure changes

---

### 2.2 Restrict Login Hours by Profile

**Profile Level:** L2 (Hardened)

#### Description
Limit when users can log into Salesforce based on their role/profile, reducing attack surface during off-hours.

#### ClickOps Implementation
1. **Setup → Users → Profiles → [Select Profile]**
2. Click **"Login Hours"** button
3. Configure allowed hours per day of week
4. Save and test with affected users

#### Use Cases
- Restrict contractor access to business hours only
- Limit admin account login times to reduce exposure
- Geographic-based restrictions (e.g., US-only profiles during US business hours)

---

## 3. OAuth & Connected App Security

### 3.1 Audit and Reduce OAuth Scopes for Connected Apps

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.2 (Least Privilege)
**NIST 800-53:** AC-6

#### Description
Review all Connected Apps (third-party integrations) and ensure they only have minimum required OAuth scopes. Over-permissioned apps increase breach impact.

#### Rationale
**Attack Impact:** When Gainsight was breached, attackers had `full` OAuth scope, allowing complete data exfiltration. Scoped permissions would have limited damage.

#### ClickOps Implementation

**Step 1: Audit Current Connected Apps**
1. **Setup → Apps → Connected Apps → Manage Connected Apps**
2. Review each app's "Selected OAuth Scopes"
3. Document current scopes and business justification

**Step 2: Identify Over-Permissioned Apps**
Look for apps with:
- `full` - Complete access (almost never needed)
- `api` - Full API access (often too broad)
- `refresh_token, offline_access` - Persistent access (risk if breached)

**Step 3: Reduce Scopes**
For each over-permissioned app:
1. Click app name → **Edit Policies**
2. Modify **Selected OAuth Scopes** to minimum required:
   - Example: Change `full` to specific scopes like `chatter_api`, `custom_permissions`
3. **Save**
4. Test integration to ensure functionality maintained

**Step 4: Enable OAuth App Approval**
1. **Setup → Security → Session Settings**
2. Enable: **"Require user authorization for OAuth flows"**
3. This forces users to explicitly approve OAuth apps

#### Recommended Scope Restrictions by Integration Type

| Integration Type | Recommended Scopes | Avoid |
|-----------------|-------------------|-------|
| **Customer Success (Gainsight)** | `api`, `custom_permissions`, specific objects | `full`, `refresh_token` with long expiry |
| **Marketing (HubSpot, Drift)** | `api`, `chatter_api`, limited objects | `full`, `manage_users` |
| **Support (Zendesk, Intercom)** | `api`, `chatter_api`, Case object only | `full`, access to all objects |
| **Analytics (Tableau)** | `api`, read-only specific objects | Write access, `full` |

#### Code Implementation

**Audit Script:**
```python
# automation/scripts/salesforce/audit-connected-apps.py

from simple_salesforce import Salesforce
import os

sf = Salesforce(
    username=os.environ['SF_USERNAME'],
    password=os.environ['SF_PASSWORD'],
    security_token=os.environ['SF_SECURITY_TOKEN']
)

# Query all Connected Apps
query = """
    SELECT Id, Name, CreatedDate, LastModifiedDate
    FROM ConnectedApplication
    WHERE IsActive = true
"""
apps = sf.query(query)

print(f"Found {apps['totalSize']} active Connected Apps:\n")

for app in apps['records']:
    print(f"- {app['Name']}")
    print(f"  Created: {app['CreatedDate']}")
    print(f"  Last Modified: {app['LastModifiedDate']}")
    print()

# For detailed scope analysis, requires Tooling API
# (OAuth scopes stored in PermissionSetAssignment)
```

#### Compliance Mappings
- **SOC 2:** CC6.2 (Least Privilege)
- **NIST 800-53:** AC-6, AC-6(1)
- **ISO 27001:** A.9.2.3

---

### 3.2 Enable Connected App Session-Level Security

**Profile Level:** L2 (Hardened)

#### Description
Configure Connected Apps to inherit session security policies (IP restrictions, timeout) from user's profile.

#### ClickOps Implementation
1. **Setup → Apps → Connected Apps → [App Name]**
2. Edit Policies
3. **Session Timeout:** Set to "2 hours" or less (not "Never expires")
4. **Refresh Token Policy:** "Expire after 30 days" (not "Refresh token valid indefinitely")
5. Enable: **"Enforce IP restrictions"**

---

## 4. Data Security

### 4.1 Enable Field-Level Encryption for Sensitive Data

**Profile Level:** L2 (Hardened)
**Requires:** Salesforce Shield

#### Description
Encrypt sensitive fields (SSN, credit card, health data) at rest using Salesforce Shield Platform Encryption.

#### ClickOps Implementation
1. **Setup → Security → Platform Encryption**
2. Generate tenant secret (store securely!)
3. Select fields to encrypt:
   - Custom fields marked as sensitive
   - Standard fields: SSN, Credit Card, etc.
4. Enable encryption per field
5. Test: Encrypted fields show lock icon

#### Limitations
- Encrypted fields cannot be used in:
  - WHERE clauses (except equality)
  - ORDER BY
  - Formula fields (in some cases)
- Requires Shield add-on (~$25/user/month)

---

## 5. Monitoring & Detection

### 5.1 Enable Event Monitoring for API Anomalies

**Profile Level:** L1 (Baseline)
**Requires:** Salesforce Shield or Event Monitoring add-on

#### Description
Enable Salesforce Event Monitoring to detect anomalous API usage patterns that could indicate compromised integrations.

#### ClickOps Implementation
1. **Setup → Event Monitoring → Event Manager**
2. Enable these event types:
   - **API** (all API calls)
   - **Login** (authentication events)
   - **URI** (page views)
   - **Report Export** (data exfiltration indicator)
3. Configure storage: EventLogFile (24hr) or Event Monitoring Analytics (30 days)

#### Detection Use Cases

**Anomaly 1: Bulk Data Export from Integration**
```sql
-- Query EventLogFile for large API responses
SELECT EventTime, Username, SourceIp, ClientId, RequestedEntities, CPU_TIME
FROM EventLogFile
WHERE EventType = 'API'
  AND CPU_TIME > 10000  -- High CPU indicates large query
  AND EventTime = LAST_N_HOURS:24
ORDER BY CPU_TIME DESC
```

**Anomaly 2: API Access from Unexpected IPs**
```sql
-- Detect API calls from IPs NOT in allowlist
SELECT EventTime, SourceIp, ClientId, Username, Status
FROM LoginHistory
WHERE LoginType = 'Application'
  AND SourceIp NOT IN ('35.166.202.113', '52.35.87.209', '34.221.135.142')  -- Gainsight IPs
  AND EventTime = LAST_N_DAYS:7
```

**Anomaly 3: Unusual Time-of-Day Access**
```sql
-- Detect API activity during off-hours
SELECT EventTime, ClientId, Username, SourceIp
FROM EventLogFile
WHERE EventType = 'API'
  AND HOUR(EventTime) NOT IN (9,10,11,12,13,14,15,16,17)  -- Outside 9am-5pm
```

#### Alert Configuration
**Using Salesforce Shield:**
1. Create custom report with anomaly query
2. Subscribe to report with alert threshold
3. Configure email/Slack notification

**Using Third-Party SIEM:**
Export EventLogFile daily to:
- Splunk
- Datadog
- Sumo Logic
- AWS Security Lake

---

## 6. Third-Party Integration Security

### 6.1 Integration Risk Assessment Matrix

Before allowing any third-party integration, assess risk:

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **Data Access** | Read-only, limited objects | Read most objects | Write access, full API |
| **OAuth Scopes** | Specific scopes only | `api` scope | `full` scope |
| **Session Duration** | <2 hours | 2-8 hours | >8 hours, refresh tokens |
| **IP Restriction** | Static IPs, allowlisted | Some static IPs | Dynamic IPs, no allowlist |
| **Vendor Security** | SOC 2 Type II, recent audit | SOC 2 Type I | No SOC 2 |

**Decision Matrix:**
- **0-5 points:** Approve with standard controls
- **6-10 points:** Approve with enhanced monitoring
- **11-15 points:** Require additional security measures or reject

### 6.2 Common Integrations and Recommended Controls

#### Gainsight (Customer Success Platform)

**Data Access:** High (needs Account, Contact, Case, Custom Objects)
**Recommended Controls:**
- ✅ IP allowlisting (Section 2.1.1)
- ✅ Reduce OAuth scopes from `full` to `api` + specific objects
- ✅ Enable Event Monitoring for bulk queries
- ✅ 30-day refresh token expiration

#### Drift (Marketing/Chat Platform)

**Data Access:** Medium (needs Lead, Contact, Account)
**Recommended Controls:**
- ✅ IP allowlisting (Section 2.1.2)
- ✅ Read-only access to Lead/Contact
- ✅ Restrict to marketing team profile
- ⚠️ Note: Drift was breached in 2025 - high-risk integration

#### HubSpot (Marketing Automation)

**Data Access:** Medium-High
**Recommended Controls:**
- ✅ IP allowlisting (Section 2.1.3) with monthly verification
- ✅ Bidirectional sync monitoring (alert on unexpected write operations)
- ✅ Field-level restrictions (don't sync SSN, financial data)

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Salesforce Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | MFA for all users | 1.1 |
| CC6.2 | OAuth scope reduction | 3.1 |
| CC6.6 | IP allowlisting | 2.1 |
| CC7.2 | Event Monitoring | 5.1 |

### NIST 800-53 Rev 5 Mapping

| Control | Salesforce Control | Guide Section |
|---------|-------------------|---------------|
| AC-3 | IP restrictions | 2.1 |
| AC-6 | Least privilege OAuth | 3.1 |
| IA-2(1) | MFA enforcement | 1.1 |
| AU-6 | Event monitoring | 5.1 |

---

## Appendix A: Edition Compatibility

| Control | Professional | Enterprise | Unlimited | Performance | Shield Required |
|---------|-------------|------------|-----------|-------------|----------------|
| MFA | ✅ | ✅ | ✅ | ✅ | ❌ |
| IP Allowlisting | ❌ | ✅ | ✅ | ✅ | ❌ |
| OAuth Scoping | ✅ | ✅ | ✅ | ✅ | ❌ |
| Event Monitoring | ❌ | Add-on | Add-on | Add-on | ✅ |
| Field Encryption | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Salesforce Documentation:**
- [Network Access (IP Allowlisting)](https://help.salesforce.com/articleView?id=admin_loginipranges.htm)
- [Connected Apps and OAuth](https://help.salesforce.com/articleView?id=connected_app_overview.htm)
- [Event Monitoring](https://help.salesforce.com/articleView?id=event_monitoring.htm)

**Integration Vendor IP Documentation:**
- [Gainsight IP Addresses](https://support.gainsight.com/Gainsight_NXT/Integrations/IP_Addresses)
- [Drift IP Allowlist](https://gethelp.drift.com/hc/en-us/articles/360019693114-IP-Allowlist)
- [HubSpot IP Addresses](https://knowledge.hubspot.com/integrations/what-are-hubspot-s-ip-addresses)

**Supply Chain Incident Reports:**
- [Okta: Salesloft Incident Response](https://www.okta.com/newsroom/articles/the-salesloft-incident--a-wake-up-call-for-saas-security-and-ips/)
- [Mandiant: UNC6395 Campaign Analysis](https://www.mandiant.com/resources/blog/unc6395-supply-chain-compromise)

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-12 | 1.0 | Initial Salesforce hardening guide with focus on integration security | How to Harden Community |

---

**Next Steps:**
1. Review your current Salesforce configuration against L1 (Baseline) controls
2. Implement IP allowlisting for high-risk integrations (Gainsight, Drift, HubSpot)
3. Audit Connected App OAuth scopes and reduce over-permissions
4. Enable Event Monitoring for API anomaly detection
5. Establish quarterly review process for integration security

**Questions or Improvements?**
- Open an issue: [GitHub Issues](https://github.com/yourproject/how-to-harden/issues)
- Contribute: [CONTRIBUTING.md](../../CONTRIBUTING.md)
