---
layout: guide
title: "Datadog Hardening Guide"
vendor: "Datadog"
slug: "datadog"
tier: "2"
category: "Observability"
description: "Observability platform security for API keys, log pipelines, and sensitive data"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

Datadog serves **28,000+ customers** with **800+ integrations** collecting application metrics, security signals, and log data enterprise-wide. API keys and OAuth tokens (security_monitoring scopes) provide broad access to operational telemetry. Datadog proactively monitors GitHub for leaked keys, but organizations must implement their own controls for API key lifecycle management.

### Intended Audience
- Security engineers managing observability platforms
- SRE/DevOps teams configuring Datadog
- GRC professionals assessing monitoring compliance
- Third-party risk managers evaluating telemetry integrations

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Datadog security configurations including authentication, API key management, agent security, and log/APM data protection.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Key Management](#2-api-key-management)
3. [Agent Security](#3-agent-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SAML SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all Datadog access.

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Organization Settings → SAML Login**
2. Configure:
   - **Identity Provider:** Your IdP (Okta, Azure AD, etc.)
   - **Entity ID:** Datadog entity ID
   - **SSO URL:** IdP login endpoint
   - **Certificate:** Upload IdP certificate

**Step 2: Enforce SAML**
1. Enable: **Require SAML**
2. Configure: **Default role for new users**
3. Disable: **Allow password login**

**Step 3: Configure Just-In-Time Provisioning**
1. Enable: **JIT provisioning**
2. Map SAML attributes to Datadog roles
3. Configure team assignments

---

### 1.2 Implement Role-Based Access Control

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure Datadog roles with granular permissions.

#### ClickOps Implementation

**Step 1: Design Role Structure**

| Role | Permissions |
|------|---------|----------|---------|--------|----|
| Admin | Full organization access (2-3 users) |
| Standard | View all data, create dashboards |
| Read-Only | View only, no modifications |
| Security Analyst | Security Monitoring, logs |
| APM Developer | APM data, traces |

**Step 2: Create Custom Roles**
1. Navigate to: **Organization Settings → Roles**
2. Create roles with specific permissions:
   - Dashboards: Read/Write
   - Monitors: Read/Write
   - Logs: Read (specific indexes)
   - APM: Read

**Step 3: Configure Teams**
1. Navigate to: **Organization Settings → Teams**
2. Create teams by function
3. Assign appropriate roles to teams

---

## 2. API Key Management

### 2.1 Implement API Key Best Practices

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Secure Datadog API keys with proper lifecycle management.

#### Rationale
**Why This Matters:**
- API keys provide write access to metrics/logs
- Application keys enable full API access
- Leaked keys enable data exfiltration or manipulation

**Hardening Priority:** One-Time Read (OTR) mode for application keys; IP-based access controls.

#### ClickOps Implementation

**Step 1: Audit Existing Keys**
1. Navigate to: **Organization Settings → API Keys**
2. Document all keys:
   - Creation date
   - Purpose/integration
   - Owner
3. Navigate to: **Organization Settings → Application Keys**
4. Repeat audit for app keys

**Step 2: Implement Key Separation**
```
Key Strategy:
├── API Keys (one per agent deployment)
│   ├── prod-us-east-agents
│   ├── prod-us-west-agents
│   └── staging-agents
└── Application Keys (one per integration)
    ├── terraform-readonly
    ├── ci-cd-pipeline
    └── security-automation
```

**Step 3: Enable One-Time Read (OTR)**
1. For new application keys, key value is shown only once
2. Store in secrets manager immediately
3. Document key purpose before creation

**Step 4: Configure Key Scopes (Application Keys)**
1. Navigate to: **Organization Settings → Application Keys**
2. For each key, configure scopes:
   - `dashboards_read` (for BI tools)
   - `monitors_read` (for alerting)
   - Avoid broad scopes unless required

---

### 2.2 API Key Rotation

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(1)

#### Description
Implement regular API key rotation.

#### Implementation

| Key Type | Rotation Frequency |
|----------|-------------------|
| API Keys (agents) | Semi-annually |
| Application Keys | Quarterly |
| Compromised keys | Immediately |

```bash
#!/bin/bash
# Key rotation script

# Create new API key
NEW_KEY=$(curl -X POST "https://api.datadoghq.com/api/v1/api_key" \
  -H "DD-API-KEY: ${CURRENT_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${APP_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"name": "prod-agents-'$(date +%Y%m%d)'"}' \

  | jq -r '.api_key.key')

# Update agents with new key
# Deploy configuration with new key

# Verify metrics flowing with new key

# Revoke old key
curl -X DELETE "https://api.datadoghq.com/api/v1/api_key/${OLD_KEY_ID}" \
  -H "DD-API-KEY: ${NEW_KEY}" \
  -H "DD-APPLICATION-KEY: ${APP_KEY}"
```

---

### 2.3 Configure IP Allowlisting for API

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-3(7)

#### Description
Restrict API access to known IP ranges.

#### ClickOps Implementation

1. Navigate to: **Organization Settings → Access → Login Methods**
2. Configure: **IP Allowlist** for UI access
3. For API: Use network policies/firewalls to restrict source IPs

---

## 3. Agent Security

### 3.1 Secure Agent Configuration

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### Description
Harden Datadog Agent deployment.

#### Implementation

```yaml
# datadog.yaml - Security hardened configuration

# API key from environment variable (not hardcoded)
api_key: ${DD_API_KEY}

# Restrict local listening
bind_host: localhost
cmd_port: 5001

# Disable unnecessary features
apm_config:
  enabled: false  # Enable only if using APM

# Log collection (if enabled)
logs_enabled: true
logs_config:
  # Mask sensitive data
  processing_rules:
    - type: mask_sequences
      name: mask_credit_cards
      pattern: '\b(?:\d{4}[-\s]?){3}\d{4}\b'
      replace_placeholder: "[MASKED_CC]"
    - type: mask_sequences
      name: mask_ssn
      pattern: '\b\d{3}-\d{2}-\d{4}\b'
      replace_placeholder: "[MASKED_SSN]"

# Security settings
security_config:
  runtime_security_config:
    enabled: false  # Enable for CWS
```

**Step 2: Secure Agent Credentials**
1. Use secrets management for API keys
2. Never commit keys to version control
3. Use environment variables or secret stores

---

### 3.2 Network Policy for Agents

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-7

#### Description
Restrict agent network communications.

#### Kubernetes NetworkPolicy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: datadog-agent-egress
spec:
  podSelector:
    matchLabels:
      app: datadog-agent
  policyTypes:
    - Egress
  egress:
    # Allow Datadog intake endpoints
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
      ports:
        - protocol: TCP
          port: 443
```

---

## 4. Data Security

### 4.1 Configure Log Data Masking

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### Description
Mask sensitive data in logs before ingestion.

#### ClickOps Implementation

**Step 1: Configure Pipeline Processors**
1. Navigate to: **Logs → Configuration → Pipelines**
2. Create processor for sensitive data:
   - **Type:** Grok Parser + Remapper
   - **Pattern:** Match sensitive fields
   - **Action:** Mask or remove

**Step 2: Configure Sensitive Data Scanner**
1. Navigate to: **Compliance → Sensitive Data Scanner**
2. Enable rules for:
   - Credit card numbers
   - Social Security Numbers
   - API keys/passwords
3. Action: Mask or redact

---

### 4.2 Log Retention and Access

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SI-12

#### Description
Configure appropriate log retention and access controls.

#### ClickOps Implementation

**Step 1: Configure Log Indexes**
1. Navigate to: **Logs → Configuration → Indexes**
2. Create separate indexes:
   - `security-logs` (longer retention)
   - `application-logs` (standard retention)
   - `debug-logs` (short retention)

**Step 2: Configure Index Permissions**
1. Navigate to: **Organization Settings → Roles**
2. Configure role permissions for log indexes
3. Restrict sensitive indexes to security team

---

## 5. Monitoring & Detection

### 5.1 Security Monitoring

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SI-4

#### Description
Configure Datadog Security Monitoring for threat detection.

#### ClickOps Implementation

**Step 1: Enable Cloud SIEM**
1. Navigate to: **Security → Security Monitoring**
2. Enable: **Cloud SIEM**
3. Configure log sources

**Step 2: Enable Detection Rules**
1. Navigate to: **Security → Detection Rules**
2. Enable relevant rules:
   - AWS CloudTrail
   - GCP Audit Logs
   - Azure Activity Logs

**Step 3: Configure Security Signals**
1. Create monitors for high-severity signals
2. Configure notification channels
3. Set up automated response (if using Workflow Automation)

---

### 5.2 Audit Trail

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable and monitor Datadog audit trail.

#### ClickOps Implementation

**Step 1: Access Audit Trail**
1. Navigate to: **Organization Settings → Audit Trail**
2. Review events:
   - Authentication
   - Configuration changes
   - API key operations

**Step 2: Export to SIEM**
1. Enable: **Audit Trail Logs**
2. Forward to log index for retention
3. Create monitors for critical events

---

## 6. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Datadog Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.2 | RBAC | 1.2 |
| CC7.2 | Audit trail | 5.2 |

---

## Appendix A: References

**Official Datadog Documentation:**
- [Security Best Practices](https://docs.datadoghq.com/security/)
- [API Key Management](https://docs.datadoghq.com/account_management/api-app-keys/)
- [Sensitive Data Scanner](https://docs.datadoghq.com/sensitive_data_scanner/)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Datadog hardening guide | Claude Code (Opus 4.5) |
