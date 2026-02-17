---
layout: guide
title: "Google Workspace Hardening Guide"
vendor: "Google"
slug: "google-workspace"
tier: "1"
category: "Productivity"
description: "Comprehensive security hardening for Google Workspace, Gmail, Drive, and Google Admin Console"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Google Workspace is used by over **9 million organizations** worldwide for email, document collaboration, and cloud storage. As a primary target for phishing and credential theft, Google Workspace security is critical—phishing was responsible for financially devastating data breaches for 9/10 organizations in 2024. According to CISA, accounts with MFA enabled are 99% less likely to be compromised.

### Intended Audience
- Security engineers managing Google Workspace environments
- IT administrators configuring Admin Console security
- GRC professionals assessing cloud productivity compliance
- Third-party risk managers evaluating Google integrations

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Google Workspace Admin Console security configurations including authentication policies, OAuth app controls, Drive sharing settings, Gmail protection, and device management. Google Cloud Platform (GCP) infrastructure is covered in a separate guide.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Network Access Controls](#2-network-access-controls)
3. [OAuth & Integration Security](#3-oauth--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Multi-Factor Authentication for All Users

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 6.5 |
| NIST 800-53 | IA-2(1), IA-2(6) |
| CIS Google Workspace | 1.1 |

#### Description
Require 2-Step Verification (2SV) for all users with enforcement, not just enrollment. Microsoft found that enabling MFA prevents 99.9% of automated attacks on cloud accounts.

#### Rationale
**Why This Matters:**
- Phishing remains the #1 attack vector against Google Workspace
- Password reuse and credential stuffing are common attack methods
- Accounts with MFA are 99% less likely to be compromised (CISA)

**Attack Prevented:** Credential theft, phishing, password spray, account takeover

**Real-World Incidents:**
- **Twitter (2020):** Compromised employee credentials led to high-profile account takeover
- **Colonial Pipeline (2021):** VPN credentials without MFA enabled ransomware deployment

#### Prerequisites
- [ ] Super Admin access to Google Admin Console
- [ ] User communication plan for 2SV enrollment
- [ ] Security keys for privileged users (recommended)

#### ClickOps Implementation

**Step 1: Enable 2-Step Verification Enrollment**
1. Navigate to: **Admin Console** → **Security** → **Authentication** → **2-Step Verification**
2. Check **Allow users to turn on 2-Step Verification**
3. Set **Enforcement** to **On** for all organizational units
4. Configure **New user enrollment period:** 7 days (grace period)
5. Click **Save**

**Step 2: Configure Allowed Methods**
1. In the same section, click **Allowed methods**
2. Select **Any except verification codes via text or phone call** (recommended)
3. This forces users to use authenticator apps or security keys instead of vulnerable SMS

**Step 3: Enforce Security Keys for Admins**
1. Navigate to: **Security** → **Authentication** → **2-Step Verification**
2. Select the Admin organizational unit
3. Set **Allowed methods** to **Only security key**
4. Click **Save**

**Time to Complete:** ~30 minutes

#### Code Implementation

**Option 1: Google Admin SDK (Python)**
```python
# Enable 2SV enforcement via Admin SDK
from googleapiclient.discovery import build
from google.oauth2 import service_account

SCOPES = ['https://www.googleapis.com/auth/admin.directory.user']
SERVICE_ACCOUNT_FILE = 'service-account.json'

credentials = service_account.Credentials.from_service_account_file(
    SERVICE_ACCOUNT_FILE, scopes=SCOPES)
credentials = credentials.with_subject('admin@yourdomain.com')

service = build('admin', 'directory_v1', credentials=credentials)

# Check 2SV enrollment status for users
results = service.users().list(
    customer='my_customer',
    maxResults=100,
    orderBy='email',
    projection='full'
).execute()

users = results.get('users', [])
for user in users:
    email = user['primaryEmail']
    is_enrolled = user.get('isEnrolledIn2Sv', False)
    is_enforced = user.get('isEnforcedIn2Sv', False)
    print(f"{email}: Enrolled={is_enrolled}, Enforced={is_enforced}")
```

**Option 2: GAM (Google Workspace Admin CLI)**
```bash
# Install GAM: https://github.com/GAM-team/GAM

# List users not enrolled in 2SV
gam print users query "isEnrolledIn2Sv=false"

# Generate report of 2SV status
gam report users parameters accounts:is_2sv_enrolled,accounts:is_2sv_enforced

# Send reminder to users not enrolled
gam print users query "isEnrolledIn2Sv=false" | \
  gam csv - gam user ~primaryEmail sendemail subject "MFA Enrollment Required" \
  message "Please enroll in 2-Step Verification within 7 days."
```

**Option 3: Terraform (unofficial provider)**
```hcl
# Note: Google Workspace Terraform provider has limited support
# Use GAM or Admin SDK for comprehensive configuration

# Example using google-beta provider for basic settings
resource "google_organization_policy" "enforce_2sv" {
  org_id     = var.org_id
  constraint = "constraints/iam.allowedPolicyMemberDomains"

  list_policy {
    allow {
      values = [var.allowed_domain]
    }
  }
}
```

#### Validation & Testing
**How to verify the control is working:**
1. [ ] Sign in as test user - 2SV prompt should appear
2. [ ] Check Admin Console → Reports → User Reports → Security
3. [ ] Verify 2SV enrollment percentage approaches 100%
4. [ ] Attempt sign-in with only password - should fail after enforcement

**Expected result:** All users prompted for second factor, enforcement active

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Monitor Security → Investigation Tool for failed 2SV attempts
- Alert on suspicious sign-in attempts
- Track 2SV enrollment completion

**Admin Console Query:**
```text
Navigate to: Security → Investigation Tool
Event: Login
Filter: 2SV method = None, Login result = Success
```

**Maintenance schedule:**
- **Weekly:** Review new user 2SV enrollment
- **Monthly:** Audit 2SV enforcement exceptions
- **Quarterly:** Review and rotate Super Admin security keys

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Low-Medium | Initial enrollment required; subsequent logins add ~5 seconds |
| **System Performance** | None | No performance impact |
| **Maintenance Burden** | Low | Minimal after initial rollout |
| **Rollback Difficulty** | Easy | Disable enforcement in Admin Console |

**Potential Issues:**
- Users without smartphones: Provide hardware security keys
- Shared device environments: Use security keys instead of mobile apps

**Rollback Procedure:**
1. Navigate to Admin Console → Security → 2-Step Verification
2. Set Enforcement to **Off**
3. Note: This leaves accounts vulnerable; use only for emergency troubleshooting

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-2(1) | Multi-factor authentication |
| **ISO 27001** | A.9.4.2 | Secure log-on procedures |
| **CIS Google Workspace** | 1.1 | Ensure 2-Step Verification is enforced |

---

### 1.2 Restrict Super Admin Account Usage

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1), AC-6(5) |
| CIS Google Workspace | 1.2 |

#### Description
Limit Super Admin privileges to 2-4 dedicated accounts, enforce security keys for authentication, and use delegated admin roles for day-to-day administration.

#### Rationale
**Why This Matters:**
- Super Admin accounts have unrestricted access to all data and settings
- Compromised Super Admin = complete organization compromise
- Delegated roles follow principle of least privilege

**Attack Prevented:** Privilege escalation, lateral movement, admin account compromise

#### Prerequisites
- [ ] Inventory of current Super Admin accounts
- [ ] Security keys for all Super Admins
- [ ] Defined delegated admin roles

#### ClickOps Implementation

**Step 1: Audit Current Super Admins**
1. Navigate to: **Admin Console** → **Account** → **Admin roles**
2. Click **Super Admin** role
3. Review assigned users - should be 2-4 maximum
4. Document and remove unnecessary assignments

**Step 2: Create Delegated Admin Roles**
1. Navigate to: **Admin Console** → **Account** → **Admin roles**
2. Click **Create new role**
3. Create role-specific admins:
   - **User Admin:** Manage users, reset passwords
   - **Groups Admin:** Manage groups and memberships
   - **Help Desk Admin:** Reset passwords, view user info
4. Assign appropriate permissions for each role

**Step 3: Enforce Security Keys for Super Admins**
1. Create organizational unit: **Super Admins**
2. Move Super Admin accounts to this OU
3. Navigate to: **Security** → **2-Step Verification**
4. Select Super Admins OU
5. Set **Allowed methods** to **Only security key**

**Time to Complete:** ~45 minutes

#### Code Implementation

**Option 1: GAM**
```bash
# List all Super Admins
gam print admins role "Super Admin"

# Create delegated admin role
gam create adminrole "Help Desk Admin" privileges \
  USERS_RETRIEVE,USERS_UPDATE,USERS_ALIAS

# Assign delegated role
gam create admin user helpdesk@domain.com role "Help Desk Admin"

# Remove Super Admin from non-essential users
gam delete admin user bob@domain.com role "Super Admin"
```

#### Validation & Testing
1. [ ] Verify only 2-4 Super Admin accounts exist
2. [ ] Confirm all Super Admins use security keys
3. [ ] Test delegated admin can perform assigned tasks only
4. [ ] Verify delegated admin cannot access Super Admin functions

---

### 1.3 Configure Context-Aware Access

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4, 13.5 |
| NIST 800-53 | AC-2(11), AC-6(1) |

#### Description
Implement context-aware access policies that evaluate device, location, and user risk before granting access to Google Workspace applications.

#### Rationale
**Why This Matters:**
- Allows enforcement of device compliance before access
- Can block access from high-risk locations
- Provides additional layer beyond authentication

#### Prerequisites
- [ ] Google Workspace Enterprise Standard or Plus
- [ ] BeyondCorp Enterprise (for advanced features)
- [ ] Endpoint Verification deployed to managed devices

#### ClickOps Implementation

**Step 1: Deploy Endpoint Verification**
1. Navigate to: **Admin Console** → **Devices** → **Mobile & endpoints** → **Settings**
2. Enable **Endpoint Verification**
3. Deploy Chrome extension to managed devices
4. Or use Google's Endpoint Verification app for unmanaged devices

**Step 2: Create Access Level**
1. Navigate to: **Security** → **Access and data control** → **Context-Aware Access**
2. Click **Access Levels** → **Create Access Level**
3. Configure conditions:
   - Device must have Endpoint Verification
   - Device must be encrypted
   - Device must have screen lock
4. Save access level

**Step 3: Assign Access Level to Apps**
1. In Context-Aware Access, click **Assign Access Levels**
2. Select apps (Gmail, Drive, etc.)
3. Assign the created access level
4. Enable enforcement after testing

**Time to Complete:** ~1 hour

---

## 2. Network Access Controls

### 2.1 Configure Allowed IP Ranges for Admin Console

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17, SC-7 |

#### Description
Restrict Admin Console access to specific IP ranges (corporate network, VPN) to prevent unauthorized administrative access.

#### ClickOps Implementation

**Step 1: Configure Allowed IPs**
1. Navigate to: **Admin Console** → **Security** → **Access and data control** → **Context-Aware Access**
2. Create access level with IP conditions
3. Specify corporate egress IP ranges
4. Apply to Admin Console access

**Step 2: Alternative - Session Control**
1. Navigate to: **Security** → **Google Cloud session control**
2. Configure reauthentication frequency for sensitive apps

---

## 3. OAuth & Integration Security

### 3.1 Enable OAuth App Whitelisting

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | AC-3, CM-7 |
| CIS Google Workspace | 2.1 |

#### Description
Restrict which third-party applications can access Google Workspace data via OAuth. Block unverified apps and require admin approval for new integrations.

#### Rationale
**Why This Matters:**
- OAuth consent phishing is a growing attack vector
- Malicious apps can gain persistent access to email and files
- Users often grant excessive permissions without understanding risks

**Attack Prevented:** OAuth consent phishing, malicious app installation, data exfiltration

**Real-World Incidents:**
- **Google Docs Phishing (2017):** Fake "Google Docs" app tricked users into granting email access
- Multiple incidents of data-stealing apps masquerading as productivity tools

#### Prerequisites
- [ ] Inventory of currently authorized OAuth apps
- [ ] Business justification for each approved app
- [ ] User communication about approval process

#### ClickOps Implementation

**Step 1: Review Current OAuth Apps**
1. Navigate to: **Admin Console** → **Security** → **API controls** → **App access control**
2. Click **Manage Third-Party App Access**
3. Review list of apps with access to organizational data
4. Document apps that should be allowed

**Step 2: Configure App Whitelisting**
1. In **App access control**, click **Settings**
2. Set default policy: **Block all third-party API access** or **Block unconfigured third-party apps**
3. Configure trusted apps list
4. Click **Save**

**Step 3: Whitelist Approved Apps**
1. Click **Add app** → **OAuth App Name or Client ID**
2. Search for app or enter Client ID
3. Configure access level:
   - **Trusted:** Full access to requested scopes
   - **Limited:** Access to only non-sensitive scopes
   - **Blocked:** No access
4. Add business justification
5. Click **Configure**

**Time to Complete:** ~1 hour (initial configuration), ongoing for new app requests

#### Code Implementation

**Option 1: GAM**
```bash
# List all OAuth tokens in use
gam all users print tokens

# List apps with specific scopes
gam all users print tokens scopes "https://mail.google.com/"

# Revoke tokens for specific app
gam all users deprovision token clientid 1234567890.apps.googleusercontent.com

# Block unverified apps (via Admin SDK)
# Note: Use Admin Console for comprehensive control
```

**Option 2: Admin SDK (Python)**
```python
# List OAuth tokens for a user
from googleapiclient.discovery import build

service = build('admin', 'directory_v1', credentials=credentials)

tokens = service.tokens().list(userKey='user@domain.com').execute()

for token in tokens.get('items', []):
    print(f"App: {token['displayText']}")
    print(f"Client ID: {token['clientId']}")
    print(f"Scopes: {token['scopes']}")
    print("---")
```

#### Validation & Testing
1. [ ] Verify blocked apps cannot access data
2. [ ] Test app approval workflow
3. [ ] Review Security Investigation Tool for blocked app attempts
4. [ ] Confirm whitelisted apps function correctly

**Expected result:** Only approved apps can access organizational data

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | AC-3 | Access enforcement |
| **CIS Google Workspace** | 2.1 | Ensure third-party apps are audited and controlled |

---

### 3.2 Disable Less Secure Apps

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.2 |
| NIST 800-53 | IA-2 |

#### Description
Disable "Less Secure Apps" access which allows applications to authenticate with just username/password, bypassing 2-Step Verification.

#### Rationale
**Why This Matters:**
- Less Secure Apps bypass MFA completely
- Legacy protocols are targets for password spray
- Google has deprecated this feature, but some tenants may still have it enabled

#### ClickOps Implementation

**Step 1: Disable Less Secure Apps**
1. Navigate to: **Admin Console** → **Security** → **Less secure apps**
2. Select **Disable access to less secure apps (Recommended)**
3. Click **Save**

> **Note:** This should be disabled by default for most tenants as of recent Google updates.

---

## 4. Data Security

### 4.1 Configure External Drive Sharing Restrictions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3, AC-22 |
| CIS Google Workspace | 3.1 |

#### Description
Restrict external sharing of Google Drive files to prevent unauthorized data exposure. Configure default sharing settings to "Restricted" and control "Anyone with the link" sharing.

#### Rationale
**Why This Matters:**
- Oversharing is one of the biggest security risks in Google Workspace
- "Anyone with the link" files can be accessed by anyone who discovers the URL
- Data exposure from misconfigured sharing is common

**Attack Prevented:** Data exfiltration, accidental data exposure, insider threats

#### Prerequisites
- [ ] Inventory of current sharing policies
- [ ] Business requirements for external collaboration

#### ClickOps Implementation

**Step 1: Configure Organization-Wide Sharing**
1. Navigate to: **Admin Console** → **Apps** → **Google Workspace** → **Drive and Docs**
2. Click **Sharing settings**
3. Configure **Sharing options**:
   - **Sharing outside of [organization]:** Off or Allowlisted domains only
   - **Default link sharing:** Restricted (only people added)
4. Click **Save**

**Step 2: Configure Sharing for Specific OUs**
1. Select organizational unit from left panel
2. Override settings for teams requiring external collaboration
3. Use most restrictive settings possible

**Step 3: Disable "Anyone with the link"**
1. In Sharing settings, find **Link sharing default**
2. Set to **Restricted** (not "Anyone with the link")
3. Optionally block "Anyone with the link" entirely

**Time to Complete:** ~30 minutes

#### Code Implementation

**Option 1: GAM**
```bash
# Audit files shared externally
gam all users print filelist query "visibility='anyoneWithLink' or visibility='anyoneCanFind'"

# Find files shared with specific external domains
gam all users print filelist query "sharedWithExternalUsers"

# Generate sharing report
gam report drive user all parameters doc_type,visibility,shared_with_user_accounts
```

#### Validation & Testing
1. [ ] Create test file and verify default sharing is Restricted
2. [ ] Attempt to share externally - verify appropriate restrictions apply
3. [ ] Audit existing files with external sharing
4. [ ] Confirm allowed external sharing still functions

---

### 4.2 Enable Data Loss Prevention (DLP)

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.2 |
| NIST 800-53 | SC-8, SC-28 |

#### Description
Configure Google Workspace DLP rules to detect and prevent sharing of sensitive information like credit cards, SSNs, and confidential documents.

#### Prerequisites
- [ ] Google Workspace Enterprise Standard or Plus
- [ ] Defined sensitive data types for your organization

#### ClickOps Implementation

**Step 1: Access DLP Settings**
1. Navigate to: **Admin Console** → **Security** → **Access and data control** → **Data protection**
2. Click **Manage Rules**

**Step 2: Create DLP Rule**
1. Click **Create rule**
2. Configure:
   - **Name:** Block sharing of PII
   - **Scope:** Entire organization or specific OUs
   - **Apps:** Drive, Chat
   - **Conditions:** Content matches predefined detectors (SSN, Credit Card, etc.)
   - **Actions:** Block external sharing, warn user, alert admin
3. Save and enable rule

---

## 5. Monitoring & Detection

### 5.1 Enable Audit Logging and Investigation Tool

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-3, AU-6 |
| CIS Google Workspace | 5.1 |

#### Description
Enable and configure audit logging across all Google Workspace services. Use the Security Investigation Tool for threat detection and incident response.

#### Rationale
**Why This Matters:**
- Audit logs are essential for incident investigation
- Provides visibility into admin actions, file access, and sign-in events
- Required for compliance with most security frameworks

#### ClickOps Implementation

**Step 1: Verify Audit Logging**
1. Navigate to: **Admin Console** → **Reporting** → **Audit and investigation**
2. Verify logs are being captured for:
   - Admin activities
   - Login activities
   - Drive activities
   - Token activities
   - Rules activities

**Step 2: Configure Audit Log Exports**
1. Navigate to: **Reporting** → **Audit and investigation** → **Export to BigQuery**
2. Enable export to BigQuery for long-term retention
3. Configure retention period

**Step 3: Create Alert Rules**
1. Navigate to: **Security** → **Alert center** → **Configure alerts**
2. Enable critical alerts:
   - Suspicious login
   - Government-backed attack
   - Device compromised
   - Super Admin added

**Time to Complete:** ~30 minutes

#### Key Events to Monitor

| Event | Log Source | Detection Use Case |
|-------|------------|-------------------|
| `CHANGE_PASSWORD` | Admin | Unauthorized password resets |
| `GRANT_ADMIN_ROLE` | Admin | Privilege escalation |
| `CREATE_APPLICATION_SETTING` | Admin | OAuth app approval |
| `LOGIN_FAILURE` | Login | Brute force attempts |
| `SUSPICIOUS_LOGIN` | Login | Account compromise |
| `DOWNLOAD` | Drive | Data exfiltration |

#### Code Implementation

**Option 1: GAM Reports**
```bash
# Generate login report
gam report login start -7d end today

# Generate admin audit report
gam report admin start -7d end today

# Export Drive audit events
gam report drive start -7d end today event download

# Find suspicious logins
gam report login filter "is_suspicious==True"
```

**Option 2: BigQuery Queries**
```sql
-- Find failed login attempts by user
SELECT
  actor.email,
  COUNT(*) as failed_attempts
FROM `project.dataset.login_logs`
WHERE event_name = 'login_failure'
  AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY actor.email
HAVING failed_attempts > 10
ORDER BY failed_attempts DESC;

-- Find external file sharing
SELECT
  actor.email,
  doc_title,
  target_user
FROM `project.dataset.drive_logs`
WHERE event_name = 'change_user_access'
  AND target_user NOT LIKE '%@yourdomain.com'
  AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR);
```

---

## 6. Third-Party Integration Security

### 6.1 Integration Risk Assessment Matrix

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **Data Access** | Read-only, limited scope | Read most data | Write access, full API |
| **OAuth Scopes** | Specific scopes | Broad API access | Full admin/Gmail access |
| **Session Duration** | Short-lived tokens | Refresh tokens | Offline access |
| **Vendor Security** | SOC 2 Type II + ISO | SOC 2 Type I | No certification |

### 6.2 Common Integrations and Recommended Controls

#### Obsidian Security
**Data Access:** Read (Gmail metadata, Drive metadata, audit logs)
**Recommended Controls:**
- ✅ Use dedicated service account
- ✅ Grant minimum required OAuth scopes
- ✅ Review access quarterly
- ✅ Monitor API usage via Reports

#### Slack
**Data Access:** Medium (Google Calendar, Drive file links)
**Recommended Controls:**
- ✅ Approve specific scopes only
- ✅ Limit to approved workspaces
- ✅ Monitor for unusual activity

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Google Workspace Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA for all users | [1.1](#11-enforce-multi-factor-authentication-for-all-users) |
| CC6.1 | OAuth app controls | [3.1](#31-enable-oauth-app-whitelisting) |
| CC6.2 | Super Admin restrictions | [1.2](#12-restrict-super-admin-account-usage) |
| CC6.6 | External sharing restrictions | [4.1](#41-configure-external-drive-sharing-restrictions) |
| CC7.2 | Audit logging | [5.1](#51-enable-audit-logging-and-investigation-tool) |

### NIST 800-53 Rev 5 Mapping

| Control | Google Workspace Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | MFA enforcement | [1.1](#11-enforce-multi-factor-authentication-for-all-users) |
| AC-6(1) | Least privilege admin | [1.2](#12-restrict-super-admin-account-usage) |
| AC-3 | OAuth app control | [3.1](#31-enable-oauth-app-whitelisting) |
| AU-2 | Audit logging | [5.1](#51-enable-audit-logging-and-investigation-tool) |

### CIS Google Workspace Foundations Benchmark Mapping

| Recommendation | Google Workspace Control | Guide Section |
|---------------|------------------|---------------|
| 1.1 | Ensure 2SV is enforced | [1.1](#11-enforce-multi-factor-authentication-for-all-users) |
| 1.2 | Limit Super Admin accounts | [1.2](#12-restrict-super-admin-account-usage) |
| 2.1 | Control third-party apps | [3.1](#31-enable-oauth-app-whitelisting) |
| 3.1 | Restrict external sharing | [4.1](#41-configure-external-drive-sharing-restrictions) |

---

## Appendix A: Edition/Tier Compatibility

| Control | Business Starter | Business Standard | Business Plus | Enterprise Standard | Enterprise Plus |
|---------|------------------|-------------------|---------------|---------------------|-----------------|
| 2-Step Verification | ✅ | ✅ | ✅ | ✅ | ✅ |
| Security Keys enforcement | ✅ | ✅ | ✅ | ✅ | ✅ |
| OAuth app whitelisting | ❌ | ✅ | ✅ | ✅ | ✅ |
| Context-Aware Access | ❌ | ❌ | ✅ | ✅ | ✅ |
| Data Loss Prevention | ❌ | ❌ | ❌ | ❌ | ✅ |
| Security Investigation Tool | ❌ | ❌ | ❌ | ✅ | ✅ |
| BigQuery export | ❌ | ❌ | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official Google Documentation:**
- [Google Workspace Admin Help](https://support.google.com/a)
- [Security Best Practices](https://support.google.com/a/answer/7587183)
- [Google Cloud MFA Requirement](https://docs.cloud.google.com/docs/authentication/mfa-requirement)
- [Data Protection and Compliance](https://business.safety.google/compliance/)
- [Compliance Reports Manager](https://cloud.google.com/security/compliance/compliance-reports-manager)

**API & Developer Tools:**
- [Google Workspace Developer Hub](https://developers.google.com/workspace)
- [Admin SDK API Reference](https://developers.google.com/admin-sdk)
- [GAM - Google Workspace Admin CLI](https://github.com/GAM-team/GAM)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO/IEC 27001:2022, ISO 27017, ISO 27018, ISO 27701, FedRAMP (High), BSI C5, MTCS -- via [Compliance Reports Manager](https://cloud.google.com/security/compliance/compliance-reports-manager)
- [ISO/IEC 27001 Compliance](https://cloud.google.com/security/compliance/iso-27001)
- [SOC 2 Compliance](https://cloud.google.com/security/compliance/soc-2)

**Security Incidents:**
- Google Workspace has not had a major platform-level breach. Notable ecosystem incidents include the **Google Docs OAuth Phishing Attack (2017)**, where a fake "Google Docs" app tricked users into granting email access via OAuth consent.

**Third-Party Security Guides:**
- [CISA Google Common Controls](https://www.cisa.gov/resources-tools/services/gws-commoncontrols)
- [CIS Google Workspace Benchmark](https://www.cisecurity.org/benchmark/google_workspace)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with authentication, OAuth, data security, and monitoring controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
