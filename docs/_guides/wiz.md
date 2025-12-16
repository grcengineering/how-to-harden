---
layout: guide
title: "Wiz Hardening Guide"
vendor: "Wiz"
slug: "wiz"
tier: "2"
category: "Security"
description: "Cloud security platform hardening for connector security and RBAC controls"
last_updated: "2025-12-14"
---


## Overview

Wiz provides agentless cloud security to **40-50% of Fortune 100** through API access to cloud environments. While the agentless architecture minimizes agent-based risks, OAuth tokens and cloud connector credentials could expose comprehensive cloud security posture data and SBOM information across major financial institutions and enterprises. Wiz's deep visibility into cloud configurations makes it a high-value target.

### Intended Audience
- Security engineers managing CSPM tools
- Cloud security architects
- GRC professionals assessing cloud security
- Third-party risk managers evaluating security tools

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Wiz-specific security configurations including authentication, cloud connector security, API access controls, and data protection.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Cloud Connector Security](#2-cloud-connector-security)
3. [API Security](#3-api-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all Wiz console access.

#### Rationale
**Why This Matters:**
- Wiz has visibility into all cloud infrastructure
- Compromised access exposes vulnerability data
- Attack planning facilitated by exposed security posture

**Attack Scenario:** Compromised OAuth token reveals infrastructure vulnerabilities and misconfigurations across customer's entire cloud estate.

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Settings → Authentication → SAML Configuration**
2. Configure:
   - **IdP Entity ID:** From your identity provider
   - **SSO URL:** IdP login endpoint
   - **Certificate:** Upload IdP certificate
3. Enable: **Enforce SAML authentication**

**Step 2: Disable Local Accounts**
1. Navigate to: **Settings → Authentication**
2. Disable: **Allow local authentication**
3. Keep 1 break-glass account (documented, monitored)

**Step 3: Configure Session Security**
1. Navigate to: **Settings → Authentication → Session Settings**
2. Configure:
   - **Session timeout:** 4 hours
   - **Idle timeout:** 30 minutes

---

### 1.2 Implement Role-Based Access Control

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure Wiz roles with least-privilege access.

#### ClickOps Implementation

**Step 1: Define Role Strategy**

| Role | Permissions |
|------|-------------|
| Admin | Full platform access (limit to 2-3) |
| Security Analyst | View issues, run queries, NO settings |
| Developer | View assigned projects only |
| Auditor | Read-only access, reports |
| Integration | API access for specific use cases |

**Step 2: Configure Custom Roles**
1. Navigate to: **Settings → Access Control → Roles**
2. Create custom roles with minimum permissions
3. Assign to user groups

**Step 3: Implement Project-Based Access**
1. Navigate to: **Settings → Projects**
2. Create projects for different teams/environments
3. Assign users to specific projects only

---

## 2. Cloud Connector Security

### 2.1 Secure Cloud Connector Configuration

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5, AC-6

#### Description
Harden cloud connector IAM permissions to minimum required.

#### Rationale
**Why This Matters:**
- Wiz connectors have read access to cloud resources
- Over-privileged connectors expand attack surface
- Compromised connector credentials enable reconnaissance

#### AWS Connector Best Practices

**Step 1: Use Read-Only Policy**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "s3:GetBucketLocation",
        "s3:GetBucketPolicy",
        "s3:ListAllMyBuckets",
        "iam:GetAccountSummary",
        "iam:ListRoles"
      ],
      "Resource": "*"
    }
  ]
}
```

**Step 2: Enable AWS CloudTrail for Connector**
1. Monitor Wiz connector API calls
2. Alert on unusual patterns
3. Review access regularly

**Step 3: Use External ID**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::WIZ_ACCOUNT_ID:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "YOUR_UNIQUE_EXTERNAL_ID"
        }
      }
    }
  ]
}
```

#### Azure Connector Best Practices

**Step 1: Use Reader Role**
1. Assign Reader role at management group level
2. Avoid Contributor or Owner roles
3. Use managed identity where possible

**Step 2: Restrict App Registration Permissions**
1. Create dedicated app registration
2. Grant only Microsoft Graph read permissions
3. Document and monitor app usage

#### GCP Connector Best Practices

**Step 1: Use Viewer Role**
1. Assign Viewer role at organization level
2. Create service account with minimal permissions
3. Enable service account key rotation

---

### 2.2 Connector Credential Rotation

**Profile Level:** L2 (Hardened)
**NIST 800-53:** IA-5(1)

#### Description
Implement regular rotation of cloud connector credentials.

#### Implementation

| Cloud | Credential Type | Rotation |
|-------|----------------|----------|
| AWS | IAM Role | External ID rotation annually |
| Azure | App Registration | Secret rotation quarterly |
| GCP | Service Account Key | Key rotation quarterly |

---

## 3. API Security

### 3.1 Service Account Management

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Secure Wiz API service accounts.

#### ClickOps Implementation

**Step 1: Create Purpose-Specific Service Accounts**
1. Navigate to: **Settings → Service Accounts**
2. Create accounts for:
   - SIEM integration (read-only)
   - Ticketing integration (limited write)
   - Automation (specific scopes)

**Step 2: Configure Minimum Scopes**

| Integration | Required Scopes |
|-------------|----------------|
| SIEM | `read:issues`, `read:vulnerabilities` |
| Ticketing | `read:issues`, `write:comments` |
| Automation | Specific to use case |

**Step 3: Rotate Credentials**
1. Set rotation schedule: Quarterly
2. Update integrations with new credentials
3. Revoke old credentials

---

### 3.2 API Access Monitoring

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AU-6

#### Description
Monitor API usage for anomalies.

#### Implementation

```graphql
# Example Wiz GraphQL query for audit
query {
  auditLogs(
    first: 100
    orderBy: {field: TIMESTAMP, direction: DESC}
    filterBy: {actionType: [API_REQUEST]}
  ) {
    nodes {
      timestamp
      actionType
      user {
        email
      }
      sourceIP
      requestDetails
    }
  }
}
```

---

## 4. Data Security

### 4.1 Configure Data Export Controls

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-3

#### Description
Control export of security findings and vulnerability data.

#### ClickOps Implementation

**Step 1: Restrict Export Permissions**
1. Limit bulk export to Admin role only
2. Log all export activities
3. Alert on large exports

**Step 2: Configure Report Sharing**
1. Navigate to: **Settings → Reports**
2. Configure:
   - Internal sharing only
   - Expiration on shared links
   - Password protection

---

## 5. Monitoring & Detection

### 5.1 Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Settings → Audit Log**
2. Review:
   - Authentication events
   - Configuration changes
   - API access

**Step 2: Export to SIEM**
1. Configure webhook or API integration
2. Forward all audit events
3. Create correlation rules

#### Detection Queries

```sql
-- Detect unusual data access
SELECT user_email, COUNT(*) as query_count
FROM wiz_audit_log
WHERE action_type = 'QUERY'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_email
HAVING COUNT(*) > 100;

-- Detect API access from new IPs
SELECT service_account, source_ip, COUNT(*) as requests
FROM wiz_audit_log
WHERE action_type = 'API_REQUEST'
  AND source_ip NOT IN (SELECT DISTINCT source_ip FROM historical_ips)
  AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY service_account, source_ip;
```

---

## 6. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Wiz Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.2 | RBAC | 1.2 |
| CC6.7 | Data export controls | 4.1 |

---

## Appendix A: References

**Official Wiz Documentation:**
- [Security Best Practices](https://docs.wiz.io/security)
- [Cloud Connector Setup](https://docs.wiz.io/connectors)
- [API Reference](https://docs.wiz.io/api)

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial Wiz hardening guide | How to Harden Community |
