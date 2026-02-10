---
layout: guide
title: "Vercel Hardening Guide"
vendor: "Vercel"
slug: "vercel"
tier: "5"
category: "Hosting"
description: "Deployment platform security for access tokens, environment variables, and Git integration"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

Vercel is a frontend cloud platform for deployment and hosting. REST API, deployment tokens, and Git integrations access source code and environment variables. Compromised access exposes deployment secrets, environment configuration, and enables malicious deployments.

### Intended Audience
- Security engineers managing deployment platforms
- DevOps administrators
- GRC professionals assessing deployment security
- Third-party risk managers evaluating hosting integrations

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Deployment Security](#2-deployment-security)
3. [Secrets Management](#3-secrets-management)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SAML SSO (Enterprise)**
1. Navigate to: **Team Settings → Security → SAML Single Sign-On**
2. Configure SAML IdP
3. Enable: **Enforce SAML**

**Step 2: Enable 2FA**
1. Navigate to: **Account Settings → Security**
2. Enable: **Two-Factor Authentication**

---

### 1.2 Team Access Controls

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Roles**

| Role | Permissions |
|------|---------|----------|---------|--------|----|
| Owner | Full team access |
| Member | Deploy and manage |
| Developer | Deploy only |
| Viewer | View only (Enterprise) |

**Step 2: Project Access**
1. Navigate to: **Project Settings → Members**
2. Configure project-specific access
3. Limit production deployment

---

## 2. Deployment Security

### 2.1 Secure Deployments

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-3

#### Description
Control deployment access and protect production.

#### Rationale
**Attack Scenario:** Compromised Git integration enables malicious deployments; production environment variables exposed through preview deployments.

#### ClickOps Implementation

**Step 1: Production Protection**
1. Navigate to: **Project Settings → Git**
2. Configure production branch protection
3. Require team member approval

**Step 2: Preview Deployment Security**
1. Configure: **Deployment Protection**
2. Limit preview access
3. Password protect previews

---

### 2.2 Git Integration Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### ClickOps Implementation

**Step 1: Review Integrations**
1. Navigate to: **Team Settings → Integrations**
2. Review connected repositories
3. Limit repository access

---

## 3. Secrets Management

### 3.1 Environment Variables

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### ClickOps Implementation

**Step 1: Configure Environment Variables**
1. Navigate to: **Project Settings → Environment Variables**
2. Mark sensitive values as "Sensitive"
3. Scope to specific environments

**Step 2: Secrets Best Practices**
1. Never commit secrets to Git
2. Use Vercel's encrypted secrets
3. Rotate secrets periodically

---

### 3.2 Access Token Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### ClickOps Implementation

**Step 1: Audit Access Tokens**
1. Navigate to: **Account Settings → Tokens**
2. Review all tokens
3. Remove unused tokens

**Step 2: Token Best Practices**
1. Create tokens with specific scopes
2. Set expiration dates
3. Use for CI/CD only

---

## 4. Monitoring & Detection

### 4.1 Audit Log (Enterprise)

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Access Audit Log**
1. Navigate to: **Team Settings → Audit Log**
2. Review deployment activities
3. Monitor configuration changes

#### Detection Focus

```sql
-- Detect unauthorized deployments
SELECT user_email, project, environment, timestamp
FROM vercel_audit_log
WHERE action = 'deployment.created'
  AND environment = 'production'
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect environment variable changes
SELECT user_email, project, variable_name
FROM vercel_audit_log
WHERE action LIKE '%environment_variable%'
  AND timestamp > NOW() - INTERVAL '7 days';
```

---

## Appendix A: Edition Compatibility

| Control | Hobby | Pro | Enterprise |
|---------|-------|-----|------------|
| SAML SSO | ❌ | ❌ | ✅ |
| SCIM | ❌ | ❌ | ✅ |
| Audit Log | ❌ | ❌ | ✅ |
| Deployment Protection | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official Vercel Documentation:**
- [Vercel Trust Center](https://security.vercel.com/)
- [Vercel Documentation](https://vercel.com/docs)
- [Vercel Security Overview](https://vercel.com/security)
- [Security & Compliance Measures](https://vercel.com/docs/security/compliance)
- [Security Bulletins](https://vercel.com/kb/bulletin)

**API Documentation:**
- [REST API Reference](https://vercel.com/docs/rest-api)
- [Vercel SDK (@vercel/sdk)](https://github.com/vercel/sdk)
- [Vercel CLI](https://www.npmjs.com/package/vercel)

**Compliance Frameworks:**
- SOC 2 Type II (Security, Confidentiality, Availability), ISO 27001:2022, PCI DSS v4.0 (SAQ-D AOC for Service Providers, SAQ-A AOC for Merchants) -- via [Vercel Trust Center](https://security.vercel.com/)

**Security Incidents:**
- **2025 -- Next.js Middleware Authorization Bypass (CVE-2025-29927):** A vulnerability allowed malicious actors to bypass authorization in Next.js Middleware via the x-middleware-subrequest header. Vercel WAF was updated to proactively protect hosted projects.
- **2025 -- React Server Components Vulnerabilities (CVE-2025-55182, CVE-2025-55184, CVE-2025-55183):** Critical-severity vulnerabilities in React Server Components affecting React 19 and Next.js. Vercel deployed WAF rules and urged framework upgrades. No breach of Vercel infrastructure or customer data was reported.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Vercel hardening guide | Claude Code (Opus 4.5) |
