---
layout: guide
title: "Docker Hub Hardening Guide"
vendor: "Docker Hub"
slug: "dockerhub"
tier: "3"
category: "Container"
description: "Container registry security for access tokens, image signing, and repository controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

Docker Hub is the largest public container registry with millions of images. Research in 2024 found **10,456 images exposing secrets** including 4,000 AI model API keys. The 2019 breach affected 190,000 accounts, and OAuth tokens for autobuilds remain perpetual attack vectors. TeamTNT attacks (2021-2022) used compromised accounts to distribute cryptomining malware with 150,000+ malicious image pulls.

### Intended Audience
- Security engineers managing container security
- DevOps engineers configuring container registries
- GRC professionals assessing container supply chain
- Platform teams managing Docker infrastructure

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls (use private registry)

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Image Security](#2-image-security)
3. [Repository Security](#3-repository-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce MFA and SSO

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### Description
Require MFA for Docker Hub accounts, especially those with push access.

#### Rationale
**Why This Matters:**
- 2019 breach affected 190,000 accounts
- Compromised accounts distribute malicious images
- TeamTNT used compromised accounts for cryptomining malware

#### ClickOps Implementation

**Step 1: Enable MFA**
1. Navigate to: **Account Settings → Security**
2. Enable: **Two-Factor Authentication**
3. Configure TOTP or security key

**Step 2: Configure SSO (Business)**
1. Navigate to: **Organization → Settings → Security**
2. Configure SAML SSO
3. Enforce SSO for all members

---

### 1.2 Implement Access Tokens

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Use personal access tokens instead of passwords for automation.

#### ClickOps Implementation

**Step 1: Create Scoped Tokens**
1. Navigate to: **Account Settings → Security → Access Tokens**
2. Create tokens with minimum permissions:
   - **Read-only:** For CI/CD pulls
   - **Read/Write:** For builds (specific repos)

**Step 2: Rotate Tokens**

| Token Type | Rotation |
||------|---------|----------|---------|--------|---|----------|
| CI/CD pull | Quarterly |
| Build/push | Monthly |

---

## 2. Image Security

### 2.1 Enable Docker Scout

**Profile Level:** L1 (Baseline)
**NIST 800-53:** RA-5

#### Description
Use Docker Scout for vulnerability scanning.

#### Implementation

```bash
# Enable Scout for repository
docker scout recommendations myimage:latest

# Check for vulnerabilities
docker scout cves myimage:latest
```

---

### 2.2 Image Signing (Content Trust)

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SI-7

#### Description
Enable Docker Content Trust for image signing.

```bash
# Enable content trust
export DOCKER_CONTENT_TRUST=1

# Sign and push image
docker push myorg/myimage:latest
```

---

## 3. Repository Security

### 3.1 Private Repository Configuration

**Profile Level:** L1 (Baseline)

#### ClickOps Implementation

1. Set repositories to **Private** by default
2. Configure team access (not individual)
3. Audit repository permissions quarterly

---

### 3.2 Prevent Secret Exposure

**Profile Level:** L1 (Baseline)

#### Implementation

1. Scan images for secrets before push
2. Use multi-stage builds
3. Never include credentials in Dockerfiles

```dockerfile
# Good: Use build arguments
ARG API_KEY
RUN --mount=type=secret,id=api_key ./configure

# Bad: Never do this
ENV API_KEY=secret123
```

---

## 4. Monitoring & Detection

### 4.1 Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2

#### Detection Focus

```sql
-- Detect unusual push activity
SELECT user, repository, COUNT(*) as push_count
FROM docker_audit_log
WHERE action = 'push'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user, repository
HAVING COUNT(*) > 10;
```

---

## Appendix A: Recommendation for High-Security

For high-security environments, consider:
- Private container registry (Harbor, ECR, GCR, ACR)
- Air-gapped registry for production
- Image signing with Sigstore/Cosign
- Supply chain attestations (SLSA)

---

## Appendix B: References

**Official Docker Documentation:**
- [Docker Trust Center](https://www.docker.com/trust/)
- [Docker Security](https://www.docker.com/trust/security/)
- [Docker Compliance](https://www.docker.com/trust/compliance/)
- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [Docker Engine Security](https://docs.docker.com/engine/security/)
- [Security Announcements](https://docs.docker.com/security/security-announcements/)

**API & Developer Documentation:**
- [Docker Hub API Reference](https://docs.docker.com/reference/api/hub/latest/)
- [Docker Scout](https://docs.docker.com/scout/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001 — via [Docker Compliance](https://www.docker.com/trust/compliance/)
- Annual penetration testing of Docker Hub, Desktop, Scout, and Build Cloud
- GDPR and CCPA compliant

**Security Incidents:**
- **2019 Docker Hub Breach:** Unauthorized access exposed usernames, hashed passwords, and GitHub/Bitbucket tokens for approximately 190,000 accounts.
- **2024 Secret Exposure Research:** Flare discovered 10,456 Docker Hub images exposing secrets including API keys, cloud credentials, and CI/CD tokens.
- **2025 Desktop Vulnerabilities:** CVE-2025-13743 (expired Hub PATs in diagnostics logs) and CVE-2025-9164 (Windows installer DLL hijacking for local privilege escalation).
- **TeamTNT Campaigns (2021-2022):** Compromised Docker Hub accounts used to distribute cryptomining malware with 150,000+ malicious image pulls.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Docker Hub hardening guide | Claude Code (Opus 4.5) |
