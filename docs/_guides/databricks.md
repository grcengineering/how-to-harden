---
layout: guide
title: "Databricks Hardening Guide"
vendor: "Databricks"
slug: "databricks"
tier: "2"
category: "Data"
description: "Data platform security for workspace access, Unity Catalog, and secrets management"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-02-19"
---


## Overview

Databricks serves **10,000+ customers** with Unity Catalog governing data lake access. OAuth federation with Snowflake, service principal credentials, and cluster access tokens create attack vectors. Databricks workspaces contain raw enterprise data, ML models, and training datasets making them high-value targets for data exfiltration and IP theft.

### Intended Audience
- Security engineers hardening data platforms
- Data engineers configuring Databricks
- GRC professionals assessing data governance
- Third-party risk managers evaluating analytics integrations

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Databricks security configurations including authentication, Unity Catalog governance, cluster security, and secrets management.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Unity Catalog Security](#2-unity-catalog-security)
3. [Cluster Security](#3-cluster-security)
4. [Secrets Management](#4-secrets-management)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all Databricks access.

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Admin Settings → Identity and Access → Single Sign-On**
2. Configure:
   - **IdP Entity ID:** From your identity provider
   - **SSO URL:** IdP login endpoint
   - **Certificate:** Upload IdP certificate

**Step 2: Enforce SSO**
1. Enable: **Require users to log in with SSO**
2. Disable: **Allow local password login**

**Step 3: Configure SCIM Provisioning**
1. Navigate to: **Admin Settings → Identity and Access → SCIM Provisioning**
2. Configure connector with your IdP
3. Enable: **Automatic user provisioning**

{% include pack-code.html vendor="databricks" section="1.1" %}

---

### 1.2 Implement Service Principal Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Secure service principals used for automation and integrations.

#### Rationale
**Why This Matters:**
- Service principals enable programmatic access
- OAuth tokens for service principals can have long validity
- Compromised service principal = bulk data access

**Attack Scenario:** Compromised service principal accesses data lakehouse; malicious notebook executes data exfiltration.

#### ClickOps Implementation

**Step 1: Create Purpose-Specific Service Principals**
1. Navigate to: **Admin Settings → Identity and Access → Service Principals**
2. Create principals for each integration:
   - `svc-etl-pipeline` (ETL jobs)
   - `svc-ml-training` (ML workloads)
   - `svc-reporting` (BI tools)

**Step 2: Assign Minimal Permissions**
1. Navigate to: **Unity Catalog → Grants**
2. For each service principal:
   - Grant only required catalogs
   - Grant only required schemas
   - Prefer SELECT over ALL PRIVILEGES

**Step 3: Configure OAuth Tokens**
1. Generate OAuth tokens for service principals
2. Set appropriate token lifetime
3. Store tokens in secrets manager
4. Rotate tokens quarterly

{% include pack-code.html vendor="databricks" section="1.2" %}

---

### 1.3 Configure IP Access Lists

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-3(7)

#### Description
Restrict Databricks access to known IP ranges.

#### ClickOps Implementation

**Step 1: Configure IP Access Lists**
1. Navigate to: **Admin Settings → Security → IP Access Lists**
2. Add allowed IP ranges:
   - Corporate network
   - VPN egress
   - Approved integration IPs
3. Enable: **Block public access** (L2)

{% include pack-code.html vendor="databricks" section="1.3" %}

---

## 2. Unity Catalog Security

### 2.1 Implement Data Governance

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3

#### Description
Configure Unity Catalog for centralized data governance.

#### ClickOps Implementation

**Step 1: Create Catalog Structure**

Create catalogs by environment (production, staging, development) and schemas by domain. See the DB Query Code Pack below for the full SQL.

**Step 2: Configure Granular Permissions**

Grant specific catalog, schema, and table permissions to functional roles. See the DB Query Code Pack below for permission examples.

**Step 3: Enable Column-Level Security**

Create row filter functions to restrict data visibility by group membership and apply them to tables. See the DB Query Code Pack below.

{% include pack-code.html vendor="databricks" section="2.1" %}

---

### 2.2 Configure Data Masking

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-28

#### Description
Implement dynamic data masking for sensitive columns. Create masking functions that return the full value for privileged roles and masked values for all others, then apply them to sensitive columns.

{% include pack-code.html vendor="databricks" section="2.2" %}

---

### 2.3 Audit Logging for Data Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable comprehensive audit logging for data access.

#### ClickOps Implementation

**Step 1: Enable System Tables**
1. Navigate to: **Admin Settings → System Tables**
2. Enable: **Access audit logs**
3. Configure retention period

**Step 2: Query Audit Logs**

Query the `system.access.audit` table to review data access events. See the DB Query Code Pack below for the full audit log query.

{% include pack-code.html vendor="databricks" section="2.3" %}

---

## 3. Cluster Security

### 3.1 Configure Cluster Policies

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### Description
Implement cluster policies to enforce security configurations.

#### ClickOps Implementation

**Step 1: Create Secure Cluster Policy**
1. Navigate to: **Compute --> Policies --> Create Policy**
2. Configure the cluster policy JSON to restrict allowed Spark versions, node types, auto-termination, and init scripts. See the Code Pack below for the full policy definition.

**Step 2: Assign Policy to Users**
1. Navigate to: **Admin Settings → Workspace → Cluster Policies**
2. Assign policy to appropriate groups
3. Set as default for users

{% include pack-code.html vendor="databricks" section="3.1" %}

---

### 3.2 Network Isolation

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-7

#### Description
Deploy Databricks with network isolation.

#### Implementation

**VPC/VNet Deployment:**
1. Deploy workspace in customer-managed VPC
2. Configure private endpoints
3. Disable public IP addresses for clusters

The account-level Terraform example for private workspace deployment with VPC isolation is included in the Code Pack below.

{% include pack-code.html vendor="databricks" section="3.2" %}

---

## 4. Secrets Management

### 4.1 Use Databricks Secret Scopes

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### Description
Store credentials in Databricks secret scopes rather than notebooks.

#### ClickOps Implementation

**Step 1: Create Secret Scope**
1. Navigate to: **Databricks CLI** or **Admin Settings → Secrets**
2. Create a Databricks-backed secret scope for your environment
3. Add required secrets (database passwords, API keys)

**Step 2: Configure Access Controls**
1. Set ACLs on the secret scope
2. Grant READ access to groups that need credential access
3. Restrict MANAGE access to administrators only

**Step 3: Use Secrets in Notebooks**

Access secrets via `dbutils.secrets.get()` in notebooks. Secret values are automatically redacted in logs. See the SDK Code Pack below for an example.

{% include pack-code.html vendor="databricks" section="4.1" %}

---

### 4.2 External Secret Store Integration

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-28

#### Description
Integrate with external secrets managers.

#### Azure Key Vault Integration

Create an Azure Key Vault-backed secret scope so secrets are fetched directly from Key Vault at runtime rather than stored in Databricks. This provides centralized secret lifecycle management and audit logging through Azure.

{% include pack-code.html vendor="databricks" section="4.2" %}

---

## 5. Monitoring & Detection

### 5.1 Security Monitoring

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SI-4

#### Detection Queries

Detection queries for bulk data access, unusual exports, and service principal anomalies are provided in the DB Query Code Pack below.

{% include pack-code.html vendor="databricks" section="5.1" %}

---

## 6. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Databricks Control | Guide Section |
|------------|--------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.2 | Unity Catalog permissions | 2.1 |
| CC6.7 | Data masking | 2.2 |

---

## Appendix A: Edition Compatibility

| Control | Standard | Premium | Enterprise |
|---------|----------|---------|------------|
| SSO (SAML) | ❌ | ✅ | ✅ |
| Unity Catalog | ✅ | ✅ | ✅ |
| IP Access Lists | ❌ | ✅ | ✅ |
| Customer-Managed VPC | ❌ | ✅ | ✅ |
| Private Link | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Databricks Documentation:**
- [Databricks Trust Center](https://www.databricks.com/trust)
- [Databricks Trust & Compliance](https://www.databricks.com/trust/compliance)
- [Databricks Documentation (AWS)](https://docs.databricks.com/aws/en/)
- [Security Best Practices](https://docs.databricks.com/aws/en/lakehouse-architecture/security-compliance-and-privacy/best-practices)
- [Security and Trust Center Report](https://www.databricks.com/trust/report)

**API Documentation:**
- [Databricks REST API](https://docs.databricks.com/api/workspace/introduction)
- [Databricks CLI](https://docs.databricks.com/dev-tools/cli/index.html)
- [Databricks SDKs](https://docs.databricks.com/dev-tools/sdks/index.html) (Python, Java, Go)
- [Terraform Provider](https://registry.terraform.io/providers/databricks/databricks/latest/docs)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001:2022, HIPAA, PCI DSS, FedRAMP Moderate (AWS SQL Serverless), HITRUST CSF (Azure) — via [Databricks Compliance](https://www.databricks.com/trust/compliance)

**Security Incidents:**
- No major public data breaches affecting Databricks customers have been identified. A platform vulnerability discovered by Orca Security in April 2023 was promptly remediated. Databricks maintains annual third-party penetration testing and a documented security incident response program.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Databricks hardening guide | Claude Code (Opus 4.5) |
| 2026-02-19 | 0.2.0 | draft | Migrate all remaining inline code to Code Packs (sections 2.1, 2.2, 2.3, 3.1, 3.2, 4.1, 5.1); zero inline code blocks remain | Claude Code (Opus 4.6) |
| 2026-02-19 | 0.1.1 | draft | Migrate inline CLI code in sections 4.1, 4.2 to Code Pack files | Claude Code (Opus 4.6) |
