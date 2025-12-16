---
layout: guide
title: "ServiceNow Hardening Guide"
vendor: "ServiceNow"
slug: "servicenow"
tier: "1"
category: "Enterprise IT"
description: "Enterprise IT platform security for workflows, integrations, and access control lists"
last_updated: "2025-12-14"
---


## Overview

ServiceNow is the dominant IT Service Management (ITSM) platform, commanding **44.4% market share** with **85% of Fortune 500** as customers. The ServiceNow Store hosts hundreds of certified apps with deep platform access, while the Configuration Management Database (CMDB) provides attackers with complete infrastructure mapping for lateral movement. Integration credentials stored in IntegrationHub create concentrated supply chain risk.

### Intended Audience
- Security engineers hardening ServiceNow instances
- IT administrators managing ServiceNow configurations
- GRC professionals assessing ITSM security
- Third-party risk managers evaluating ServiceNow integrations

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers ServiceNow-specific security configurations including authentication, OAuth governance, Store app security, CMDB access controls, and IntegrationHub hardening.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Network Access Controls](#2-network-access-controls)
3. [OAuth & Integration Security](#3-oauth--integration-security)
4. [CMDB Security](#4-cmdb-security)
5. [Store App Security](#5-store-app-security)
6. [Monitoring & Detection](#6-monitoring--detection)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1), IA-2(2)

#### Description
Require MFA for all ServiceNow user authentication, especially for administrators and users with elevated CMDB access.

#### Rationale
**Why This Matters:**
- ServiceNow contains infrastructure blueprints (CMDB) valuable for attack planning
- Credential stuffing attacks target ITSM platforms for initial access
- Admin accounts control workflow automation affecting entire organizations

**Attack Prevented:** Credential stuffing, password spray, account takeover

**Attack Scenario:** Compromised ServiceNow admin account modifies change workflows to auto-approve malicious changes

#### ClickOps Implementation

**Step 1: Configure MFA Plugin**
1. Navigate to: **System Definition → Plugins**
2. Search for: "Multi-Factor Authentication"
3. Activate the plugin
4. Navigate to: **Multi-Factor Authentication → Properties**

**Step 2: Configure MFA Policies**
1. Navigate to: **Multi-Factor Authentication → MFA Policies**
2. Create policy:
   - **Name:** "Require MFA for All Users"
   - **Condition:** All users
   - **Factors:** TOTP, Push notification, or FIDO2
3. Create stricter policy for admins:
   - **Name:** "Admin MFA"
   - **Condition:** User has admin role
   - **Factors:** FIDO2 required

**Step 3: Enable for SSO (if using IdP)**
1. Navigate to: **Multi-Provider SSO → Identity Providers**
2. Edit your IdP configuration
3. Enable: **Enforce MFA through IdP**

#### Code Implementation

```javascript
// ServiceNow Script Include - Enforce MFA Check
var MFAEnforcement = Class.create();
MFAEnforcement.prototype = {
    initialize: function() {},

    requireMFA: function(userId) {
        var gr = new GlideRecord('sys_user');
        if (gr.get(userId)) {
            // Check if user has admin role
            if (gr.hasRole('admin')) {
                return this._enforceFIDO2(userId);
            }
            return this._enforceStandardMFA(userId);
        }
        return false;
    },

    _enforceFIDO2: function(userId) {
        // Implementation for FIDO2 enforcement
        gs.info('FIDO2 MFA required for admin: ' + userId);
        return true;
    },

    type: 'MFAEnforcement'
};
```

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(1) | Multi-factor authentication |
| **ISO 27001** | A.9.4.2 | Secure log-on procedures |

---

### 1.2 Implement Role-Based Access Control for CMDB

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.8
**NIST 800-53:** AC-3, AC-6

#### Description
Restrict CMDB access using granular ACLs. Users should only access configuration items relevant to their role.

#### Rationale
**Why This Matters:**
- CMDB contains complete infrastructure topology
- Attackers use CMDB data to identify high-value targets
- Unrestricted CMDB access enables reconnaissance

**Attack Scenario:** Compromised Store app accesses CMDB to identify privileged systems; stolen integration credentials enable pivot to connected security tools.

#### ClickOps Implementation

**Step 1: Audit Current CMDB ACLs**
1. Navigate to: **System Security → Access Control (ACL)**
2. Filter by: Table = "cmdb_ci" and related tables
3. Document current permissions

**Step 2: Create Restrictive CMDB Roles**
1. Navigate to: **User Administration → Roles**
2. Create roles:
   - `cmdb_read_network` - Read network CIs only
   - `cmdb_read_servers` - Read server CIs only
   - `cmdb_write_owned` - Write to owned CIs only

**Step 3: Apply ACLs**
1. Create ACL for cmdb_ci table:
   - **Operation:** Read
   - **Role:** cmdb_read_network OR cmdb_read_servers
   - **Condition:** Script-based filtering by CI class
2. Remove `itil` role from broad CMDB access

```javascript
// ACL Script for CMDB CI visibility
// Only show CIs the user is authorized to see
answer = (function() {
    var userRoles = gs.getUser().getRoles();
    if (userRoles.indexOf('cmdb_admin') > -1) {
        return true; // Admins see all
    }
    if (userRoles.indexOf('cmdb_read_network') > -1) {
        return current.sys_class_name.toString().startsWith('cmdb_ci_network');
    }
    return false;
})();
```

---

### 1.3 Restrict High-Privilege Roles

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-6(1), AC-6(5)

#### Description
Limit assignment of high-privilege roles (admin, security_admin, workflow_admin) and implement approval workflows.

#### ClickOps Implementation

**Step 1: Audit High-Privilege Role Assignments**
1. Navigate to: **User Administration → Users**
2. Export users with admin roles:
```javascript
var gr = new GlideRecord('sys_user_has_role');
gr.addQuery('role.name', 'CONTAINS', 'admin');
gr.query();
while (gr.next()) {
    gs.info(gr.user.user_name + ' has role: ' + gr.role.name);
}
```

**Step 2: Create Role Request Workflow**
1. Navigate to: **Workflow → Workflow Editor**
2. Create approval workflow for admin role requests
3. Require multiple approvers for high-privilege roles
4. Link to role request catalog item

**Step 3: Enable Role Separation**
1. Prevent users from having conflicting roles:
   - `security_admin` + `system_admin` = Conflict
   - `workflow_admin` + `impersonator` = Conflict
2. Implement via Business Rule on sys_user_has_role

---

## 2. Network Access Controls

### 2.1 Configure IP Access Control Lists

**Profile Level:** L1 (Baseline)
**CIS Controls:** 13.3
**NIST 800-53:** AC-3, SC-7

#### Description
Restrict ServiceNow access to known IP ranges (corporate network, VPN, approved integration IPs).

#### ClickOps Implementation

**Step 1: Enable IP Access Control**
1. Navigate to: **System Properties → Security**
2. Set `glide.security.ip.acl.enabled` = true

**Step 2: Configure IP Ranges**
1. Navigate to: **System Security → IP Address Access Control**
2. Add rules:
   - **Corporate Network:** Allow
   - **VPN Egress:** Allow
   - **Integration IPs:** Allow (per-integration)
   - **Default:** Deny

**Step 3: Create Integration-Specific Rules**
For each third-party integration:
1. Document integration's egress IPs
2. Create specific ACL rule
3. Apply to integration user account

#### Code Implementation

```javascript
// Script Include for IP Validation
var IPAccessControl = Class.create();
IPAccessControl.prototype = {
    initialize: function() {},

    validateAccess: function(clientIP, integrationType) {
        var allowedIPs = this._getIntegrationIPs(integrationType);
        return allowedIPs.indexOf(clientIP) > -1;
    },

    _getIntegrationIPs: function(integrationType) {
        var ips = [];
        var gr = new GlideRecord('x_integration_ips');
        gr.addQuery('integration_type', integrationType);
        gr.addActiveQuery();
        gr.query();
        while (gr.next()) {
            ips.push(gr.getValue('ip_address'));
        }
        return ips;
    },

    type: 'IPAccessControl'
};
```

---

## 3. OAuth & Integration Security

### 3.1 Audit and Restrict IntegrationHub Connections

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.2
**NIST 800-53:** AC-6, CM-7

#### Description
Review all IntegrationHub connections (spokes) and restrict to minimum required permissions. IntegrationHub stores credentials for external systems.

#### Rationale
**Why This Matters:**
- IntegrationHub contains credentials for connected systems
- Over 300+ pre-built spokes available
- Compromised IntegrationHub = access to all connected systems

**Attack Scenario:** Attacker compromises ServiceNow, extracts IntegrationHub credentials, pivots to AWS, Azure, and Jira.

#### ClickOps Implementation

**Step 1: Inventory IntegrationHub Connections**
1. Navigate to: **IntegrationHub → Connections**
2. Export all active connections
3. Document:
   - Connected system
   - Credential type (OAuth, API key, basic auth)
   - Last used date
   - Business owner

**Step 2: Remove Unused Connections**
1. Identify connections not used in 90+ days
2. Validate with business owners
3. Deactivate or delete unused connections

**Step 3: Rotate All Credentials**
1. For each active connection:
   - Generate new credentials in target system
   - Update ServiceNow connection
   - Verify integration functionality
2. Document rotation in change management

**Step 4: Restrict Connection Access**
1. Navigate to: **IntegrationHub → Connection Aliases**
2. Configure role-based access:
   - Only specific roles can use specific connections
   - Prevent developers from accessing production connections

#### Code Implementation

```javascript
// Audit IntegrationHub Connections
var gr = new GlideRecord('sys_connection');
gr.addActiveQuery();
gr.query();

var report = [];
while (gr.next()) {
    report.push({
        name: gr.getValue('name'),
        credential_alias: gr.credential_alias.getDisplayValue(),
        connection_url: gr.getValue('connection_url'),
        sys_updated_on: gr.getValue('sys_updated_on')
    });
}

gs.info('IntegrationHub Connections: ' + JSON.stringify(report, null, 2));
```

---

### 3.2 Implement OAuth Token Policies

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(13)

#### Description
Configure OAuth token expiration and refresh policies for external integrations accessing ServiceNow APIs.

#### ClickOps Implementation

**Step 1: Review OAuth Applications**
1. Navigate to: **System OAuth → Application Registry**
2. Document all OAuth clients
3. Identify clients with `refresh_token` grant

**Step 2: Configure Token Expiration**
1. Edit each OAuth application:
   - **Access Token Lifespan:** 3600 (1 hour)
   - **Refresh Token Lifespan:** 604800 (7 days max)
   - **Code Lifespan:** 300 (5 minutes)
2. Disable `refresh_token` for clients that don't need persistent access

**Step 3: Implement Token Monitoring**
```javascript
// Monitor for unusual OAuth token patterns
var gr = new GlideRecord('oauth_access_token');
gr.addQuery('sys_created_on', '>', gs.daysAgo(1));
gr.query();

var tokenCounts = {};
while (gr.next()) {
    var clientId = gr.getValue('client_id');
    tokenCounts[clientId] = (tokenCounts[clientId] || 0) + 1;
}

// Alert if any client has excessive tokens
for (var client in tokenCounts) {
    if (tokenCounts[client] > 100) {
        gs.warn('Excessive OAuth tokens for client: ' + client);
    }
}
```

---

## 4. CMDB Security

### 4.1 Enable CMDB Query Business Rules

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-3

#### Description
Implement query business rules to filter CMDB results based on user authorization, preventing unauthorized infrastructure discovery.

#### ClickOps Implementation

**Step 1: Create Before Query Business Rule**
1. Navigate to: **System Definition → Business Rules**
2. Create new rule:
   - **Table:** cmdb_ci
   - **When:** Before
   - **Action:** Query
3. Script:

```javascript
(function executeRule(current, previous) {
    // Skip for admins
    if (gs.hasRole('cmdb_admin')) {
        return;
    }

    // Get user's authorized CI groups
    var authorizedGroups = getUserAuthorizedCIGroups();

    // Add query condition
    current.addQuery('support_group', 'IN', authorizedGroups);

})(current, previous);

function getUserAuthorizedCIGroups() {
    var groups = [];
    var gr = new GlideRecord('sys_user_grmember');
    gr.addQuery('user', gs.getUserID());
    gr.query();
    while (gr.next()) {
        groups.push(gr.group.toString());
    }
    return groups.join(',');
}
```

---

### 4.2 Audit CMDB Relationship Queries

**Profile Level:** L2 (Hardened)

#### Description
Log and monitor queries against CMDB relationship tables (cmdb_rel_ci) which reveal infrastructure dependencies.

#### Rationale
**Attack Scenario:** Attacker queries CMDB relationships to map dependencies between applications and databases, identifying high-value targets.

#### ClickOps Implementation

**Step 1: Enable Query Logging**
1. Navigate to: **System Diagnostics → Session Debug**
2. Enable: Database query logging for cmdb_rel_ci
3. Configure log rotation and SIEM forwarding

**Step 2: Create Alert for Bulk Queries**
1. Create scheduled job to analyze query patterns
2. Alert on:
   - Queries returning >1000 relationships
   - Queries from non-CMDB-admin users
   - Queries during off-hours

---

## 5. Store App Security

### 5.1 Implement Store App Approval Workflow

**Profile Level:** L1 (Baseline)
**CIS Controls:** 2.3
**NIST 800-53:** CM-7

#### Description
Require security review and approval before installing ServiceNow Store applications. Store apps have deep platform access.

#### Rationale
**Why This Matters:**
- Store apps run with elevated privileges
- 300+ certified apps with varying security postures
- Malicious or compromised app = full instance access

#### ClickOps Implementation

**Step 1: Enable Store App Governance**
1. Navigate to: **System Applications → Applications**
2. Configure: **Require approval for Store installations**
3. Create approval workflow with security team review

**Step 2: Create App Security Checklist**
Before approving any Store app:
- [ ] Review requested permissions/scopes
- [ ] Check vendor security certifications (SOC 2)
- [ ] Review app's update frequency
- [ ] Check for known vulnerabilities
- [ ] Evaluate data access requirements

**Step 3: Monitor Installed Apps**
1. Navigate to: **System Applications → All Available Applications**
2. Create scheduled report of installed Store apps
3. Track: Last update, permissions, usage

---

### 5.2 Restrict App Scope Access

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-6

#### Description
Limit Store app access to specific application scopes, preventing apps from accessing data outside their purpose.

#### ClickOps Implementation

**Step 1: Configure Application Scope**
1. When installing Store app, review requested scopes
2. Create separate scope for each app
3. Configure scope ACLs to limit table access

**Step 2: Disable Cross-Scope Access**
1. Navigate to: **System Applications → Studio**
2. For each app, configure:
   - **Accessible from:** This application scope only
   - **Caller access:** Restricted

---

## 6. Monitoring & Detection

### 6.1 Enable Security Incident Response

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IR-4, IR-5

#### Description
Configure ServiceNow's Security Operations module or integrate with SIEM for comprehensive audit logging and alerting.

#### Detection Use Cases

**Anomaly 1: Bulk CMDB Export**
```javascript
// Alert on large CMDB exports
var gr = new GlideRecord('sys_audit');
gr.addQuery('tablename', 'cmdb_ci');
gr.addQuery('action', 'export');
gr.addQuery('sys_created_on', '>', gs.hoursAgo(1));
gr.query();

if (gr.getRowCount() > 10) {
    gs.eventQueue('security.cmdb.bulk_export', current,
        gr.getRowCount() + ' CMDB exports in last hour');
}
```

**Anomaly 2: IntegrationHub Credential Access**
```javascript
// Alert on credential alias access outside normal hours
var hour = new GlideDateTime().getLocalTime().getHour();
if (hour < 6 || hour > 20) {
    gs.eventQueue('security.integration.offhours', current,
        'IntegrationHub access during off-hours');
}
```

**Anomaly 3: Admin Role Changes**
```javascript
// Alert on any admin role assignment
current.addAfterBusinessRule(function() {
    if (current.role.name.toString().indexOf('admin') > -1) {
        gs.eventQueue('security.role.admin_assigned', current,
            'Admin role assigned to: ' + current.user.user_name);
    }
});
```

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | ServiceNow Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA enforcement | 1.1 |
| CC6.2 | CMDB role-based access | 1.2 |
| CC6.6 | IP access control | 2.1 |
| CC7.2 | Security monitoring | 6.1 |

### NIST 800-53 Rev 5 Mapping

| Control | ServiceNow Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | MFA | 1.1 |
| AC-3 | CMDB ACLs | 1.2, 4.1 |
| AC-6 | Role restrictions | 1.3 |
| CM-7 | Store app approval | 5.1 |

---

## Appendix A: Edition Compatibility

| Control | Standard | Professional | Enterprise |
|---------|----------|--------------|------------|
| MFA | ✅ | ✅ | ✅ |
| IP ACLs | ✅ | ✅ | ✅ |
| IntegrationHub | Add-on | ✅ | ✅ |
| Security Operations | ❌ | Add-on | ✅ |
| Advanced CMDB | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official ServiceNow Documentation:**
- [Security Best Practices](https://docs.servicenow.com/bundle/security-best-practices)
- [IntegrationHub](https://docs.servicenow.com/bundle/integrationhub)
- [ACL Rules](https://docs.servicenow.com/bundle/access-control)

**Supply Chain Considerations:**
- Store apps should be treated as supply chain risk
- IntegrationHub credentials are high-value targets
- CMDB data exposure enables attack planning

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial ServiceNow hardening guide | How to Harden Community |
