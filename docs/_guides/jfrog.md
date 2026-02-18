---
layout: guide
title: "JFrog Hardening Guide"
vendor: "JFrog"
slug: "jfrog"
tier: "2"
category: "DevOps"
description: "Artifact management security for repository permissions, Xray policies, and access tokens"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

JFrog Artifactory is a universal binary repository supporting **40+ package formats** across CI/CD pipelines. CVE-2024-6915 (CVSS 9.3) cache corruption vulnerability and research finding **70 cases of anonymous write permissions** demonstrate artifact poisoning risks. As the central artifact repository, compromise enables supply chain attacks through dependency confusion and malicious package injection.

### Intended Audience
- Security engineers hardening artifact repositories
- DevOps engineers configuring Artifactory
- GRC professionals assessing supply chain security
- Platform teams managing binary repositories

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers JFrog Artifactory security configurations including authentication, repository permissions, Xray integration, and artifact integrity controls.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Repository Security](#2-repository-security)
3. [Artifact Integrity](#3-artifact-integrity)
4. [Xray Security Scanning](#4-xray-security-scanning)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all Artifactory access.

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Administration → Security → Settings → SSO**
2. Configure:
   - **IdP Login URL:** Your IdP endpoint
   - **IdP Certificate:** Upload certificate
   - **Service Provider ID:** Artifactory URL

**Step 2: Disable Local Authentication**
1. Navigate to: **Administration → Security → Settings**
2. Disable: **Allow anonymous access**
3. Configure: **Require SSO for all users**

**Step 3: Configure Access Tokens**
1. Navigate to: **Administration → Identity and Access → Access Tokens**
2. Configure token policies:
   - **Expiration:** 90 days maximum
   - **Scopes:** Minimum required

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="1.1" %}

---

### 1.2 Implement Permission Targets

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure granular permissions for repository access.

#### Rationale
**Why This Matters:**
- Research found 70 cases of anonymous write permissions
- Write access enables artifact poisoning
- Dependency confusion attacks require upload capability

**Attack Scenario:** Dependency confusion attack uploads malicious package to internal repository; cache poisoning replaces legitimate artifacts.

#### ClickOps Implementation

**Step 1: Create Permission Targets**
1. Navigate to: **Administration → Identity and Access → Permissions**
2. Create permission targets:

**Production-Read:**
- Repositories: `libs-release-local`
- Actions: Read, Annotate
- Groups: All developers

**Production-Write:**
- Repositories: `libs-release-local`
- Actions: Deploy, Delete
- Groups: Release managers only

**Build-Upload:**
- Repositories: `libs-snapshot-local`
- Actions: Deploy
- Groups: CI/CD service accounts

**Step 2: Disable Anonymous Access**
1. Navigate to: **Administration → Security → Settings**
2. Disable: **Allow anonymous access**
3. Audit all repositories for anonymous permissions

**Step 3: Restrict Admin Access**
1. Limit admin role to 2-3 users
2. Create separate roles for different functions
3. Audit admin access quarterly

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="1.2" %}

---

### 1.3 Secure API Keys and Tokens

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Manage API keys and access tokens securely.

#### ClickOps Implementation

**Step 1: Audit Existing Keys**
1. Navigate to: **Administration → Identity and Access → Access Tokens**
2. Review all active tokens
3. Revoke unused tokens

**Step 2: Create Scoped Tokens**
```bash
# Create scoped token via CLI
jf rt access-token-create \
  --groups readers \
  --scope applied-permissions/groups:readers \
  --expiry 7776000  # 90 days
```

**Step 3: Rotate Tokens**

| Token Type | Rotation Frequency |
|------------|--------------------|
| CI/CD tokens | Quarterly |
| User API keys | Semi-annually |
| Admin tokens | Quarterly |

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="1.3" %}

---

## 2. Repository Security

### 2.1 Configure Repository Layout Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### Description
Harden repository configurations to prevent unauthorized access.

#### ClickOps Implementation

**Step 1: Review Repository Settings**
1. Navigate to: **Administration → Repositories**
2. For each repository, verify:
   - Anonymous access: Disabled
   - Include/Exclude patterns: Configured
   - Allow content browsing: Restricted

**Step 2: Configure Virtual Repository Security**
1. For virtual repositories, configure resolution order:
   - Internal repositories first
   - Remote repositories second
2. This prevents dependency confusion

**Step 3: Disable Unused Features**
1. Disable: File listing for remote repositories
2. Disable: Properties search (if not needed)

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="2.1" %}

---

### 2.2 Remote Repository Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-7

#### Description
Secure remote repository (proxy) configurations.

#### ClickOps Implementation

**Step 1: Configure Remote Repository Settings**
1. Navigate to: **Repositories → Remote**
2. For each remote repository:
   - **Hard fail:** Enable for security artifacts
   - **Store artifacts locally:** Enable
   - **Block mismatching MIME types:** Enable

**Step 2: Configure Exclude Patterns**
```text
# Block potentially dangerous artifacts
*.exe
*.dll
*.msi
```

**Step 3: Enable Checksum Validation**
1. Configure: **Checksum policy:** Fail (L2)
2. Validate checksums for all downloaded artifacts

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="2.2" %}

---

### 2.3 Prevent Dependency Confusion

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SI-7

#### Description
Configure Artifactory to prevent dependency confusion attacks.

#### Implementation

**Step 1: Configure Virtual Repository Priority**
```yaml
# Virtual repository configuration
virtual_repository:
  repositories:
    - internal-libs     # First priority (internal)
    - remote-maven     # Second priority (external)
  default_deployment_repo: internal-libs
```

**Step 2: Reserve Internal Package Names**
1. Create placeholder packages in remote proxies
2. Block external packages with internal names

**Step 3: Enable Priority Resolution**
1. Navigate to: **Virtual Repository → Advanced**
2. Configure: **Priority Resolution:** Enabled
3. Set internal repositories higher priority

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="2.3" %}

---

## 3. Artifact Integrity

### 3.1 Enable Artifact Signing

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SI-7

#### Description
Require artifact signing for production deployments.

#### Implementation

**Step 1: Configure GPG Signing**
```bash
# Sign artifact during deployment
jf rt upload --gpg-key=/path/to/key.asc artifact.jar libs-release-local/
```

**Step 2: Verify Signatures on Download**
```bash
# Verify artifact signature
jf rt download libs-release-local/artifact.jar --gpg-key=/path/to/public.asc
```

**Step 3: Enforce Signing Policy**
1. Use Xray policies to block unsigned artifacts
2. Document signing requirements

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="3.1" %}

---

### 3.2 Immutable Artifacts

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SI-7

#### Description
Make release artifacts immutable to prevent tampering.

#### ClickOps Implementation

**Step 1: Configure Repository Settings**
1. Navigate to: **Repository → Advanced**
2. Enable: **Handle releases** (for release repos)
3. Disable: **Handle snapshots** (for release repos)
4. Enable: **Suppress POM consistency checks:** No

**Step 2: Create Immutable Policy**
1. Use release repository for production artifacts
2. Block re-deployment of existing versions
3. Delete permissions restricted to admins

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="3.2" %}

---

## 4. Xray Security Scanning

### 4.1 Configure Xray Policies

**Profile Level:** L1 (Baseline)
**NIST 800-53:** RA-5

#### Description
Configure JFrog Xray for vulnerability and license scanning.

#### ClickOps Implementation

**Step 1: Create Security Policy**
1. Navigate to: **Xray → Policies → New Policy**
2. Configure:
   - **Type:** Security
   - **Rules:**
     - Critical CVE: Block download
     - High CVE: Warn
   - **Actions:** Block release, notify

**Step 2: Create Watch**
1. Navigate to: **Xray → Watches → New Watch**
2. Configure:
   - **Resources:** Production repositories
   - **Policy:** Security policy created above

**Step 3: Enable Automatic Scanning**
1. Enable scanning on upload
2. Configure periodic rescanning
3. Set up notifications

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="4.1" %}

---

### 4.2 CVE Remediation Workflow

**Profile Level:** L1 (Baseline)

#### Implementation

**Step 1: Monitor CVE Alerts**
1. Configure Xray notifications
2. Integrate with ticketing system
3. Assign remediation owners

**Step 2: Block Vulnerable Artifacts**
```yaml
# Xray policy - Block critical vulnerabilities
policy:
  name: block-critical-cves
  type: security
  rules:
    - name: critical-cve-block
      criteria:
        min_severity: critical
      actions:
        block_download:
          active: true
        fail_build: true
```

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="4.2" %}

---

## 5. Monitoring & Detection

### 5.1 Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure comprehensive audit logging.

#### ClickOps Implementation

**Step 1: Enable Audit Log**
1. Navigate to: **Administration → Security → Settings**
2. Enable: **Audit log**
3. Configure retention

**Step 2: Export to SIEM**
1. Configure log shipping to SIEM
2. Parse Artifactory access logs

#### Detection Queries

```sql
-- Detect unusual upload patterns
SELECT user, repo, COUNT(*) as upload_count
FROM artifactory_access_log
WHERE action = 'DEPLOY'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user, repo
HAVING COUNT(*) > 50;

-- Detect downloads of vulnerable artifacts
SELECT user, path, xray_status
FROM artifactory_access_log a
JOIN xray_scan_results x ON a.path = x.artifact_path
WHERE a.action = 'DOWNLOAD'
  AND x.severity = 'critical'
  AND a.timestamp > NOW() - INTERVAL '24 hours';

-- Detect anonymous access attempts
SELECT source_ip, path, COUNT(*) as attempts
FROM artifactory_access_log
WHERE user = 'anonymous'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY source_ip, path
HAVING COUNT(*) > 10;
```

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="5.1" %}

---

## 6. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Artifactory Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.2 | Permission targets | 1.2 |
| CC8.1 | Artifact integrity | 3.1 |

### Supply Chain Security (SLSA)

| Level | Requirements | Artifactory Controls |
|-------|--------------|---------------------|
| SLSA 1 | Build provenance | Build info capture |
| SLSA 2 | Signed provenance | GPG signing |
| SLSA 3 | Security controls | Xray scanning, access control |

---

## Appendix A: Edition Compatibility

| Control | OSS | Pro | Enterprise |
|---------|-----|-----|------------|
| SSO (SAML) | ❌ | ✅ | ✅ |
| Access Tokens | Basic | ✅ | ✅ |
| Xray | ❌ | Add-on | ✅ |
| Audit Log | Basic | ✅ | ✅ |
| HA/DR | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official JFrog Documentation:**
- [JFrog Trust Center](https://jfrog.com/trust/)
- [JFrog Help Center](https://jfrog.com/help/)
- [Security Best Practices](https://jfrog.com/help/r/jfrog-artifactory-documentation/security-best-practices)
- [Security Configuration](https://jfrog.com/help/r/jfrog-platform-administration-documentation/security-configuration)
- [Access Control](https://jfrog.com/help/r/jfrog-artifactory-documentation/managing-permissions)
- [Xray Documentation](https://jfrog.com/help/r/jfrog-xray-documentation)
- [JFrog Security Advisories](https://jfrog.com/help/r/jfrog-release-information/jfrog-security-advisories)

**API & Developer Resources:**
- [JFrog REST APIs](https://jfrog.com/help/r/jfrog-rest-apis/jfrog-rest-apis)
- [JFrog CLI](https://jfrog.com/help/r/jfrog-cli)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27701 -- via [JFrog Trust Center](https://jfrog.com/trust/certificate-program/)

**Security Incidents:**
- **CVE-2024-6915 (CVSS 9.3):** Cache poisoning vulnerability in JFrog Artifactory allowing attackers to corrupt cached artifacts in the software supply chain. Affects versions below 7.90.6 and corresponding LTS releases. Cloud environments were patched automatically; on-premise instances require manual upgrade.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial JFrog Artifactory hardening guide | Claude Code (Opus 4.5) |
