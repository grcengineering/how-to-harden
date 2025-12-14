# CircleCI Hardening Guide

**Version:** 1.0
**Last Updated:** 2025-12-14
**Product Editions Covered:** CircleCI Cloud, CircleCI Server
**Authors:** How to Harden Community

---

## Overview

CircleCI serves **200,000+ DevOps teams** with integrated CI/CD pipelines. The **January 2023 breach** demonstrated how session cookie theft bypasses MFA—attackers exfiltrated customer **OAuth tokens, SSH keys, and environment variables** from production systems via infostealer malware on an engineer's laptop. All customers were forced to immediately rotate secrets across all connected services.

### Intended Audience
- Security engineers hardening CI/CD infrastructure
- DevOps engineers configuring secure pipelines
- GRC professionals assessing supply chain security
- Platform teams managing CircleCI deployments

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers CircleCI security configurations including authentication, context security, secrets management, and lessons learned from the January 2023 breach.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Context & Secrets Security](#2-context--secrets-security)
3. [Pipeline Security](#3-pipeline-security)
4. [Runner Security](#4-runner-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Incident Response](#6-incident-response)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all CircleCI access. The January 2023 breach demonstrated that SSO session tokens remain high-value targets.

#### Rationale
**Why This Matters:**
- CircleCI stores OAuth tokens, SSH keys, and environment secrets
- Session cookie theft bypassed 2FA in the 2023 breach
- SSO enables centralized access control and session management

**Real-World Incidents:**
- **January 2023 CircleCI Breach:** Infostealer malware on engineer laptop led to 2FA bypass via SSO session hijacking. Customer OAuth tokens, SSH keys, and environment variables exfiltrated.

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Organization Settings → Security → SAML SSO**
2. Configure:
   - **IdP Entity ID:** From your identity provider
   - **SSO URL:** IdP login endpoint
   - **Certificate:** IdP signing certificate
3. Enable: **Require SSO for all members**

**Step 2: Configure Session Security**
1. Navigate to: **Organization Settings → Security → Session Management**
2. Configure:
   - **Session timeout:** 8 hours maximum
   - **Require re-authentication:** For sensitive operations

**Step 3: Enable IP Allowlisting (L2)**
1. Navigate to: **Organization Settings → Security → IP Ranges**
2. Add corporate network and VPN egress IPs
3. Enable: **Restrict access to allowed IPs**

#### Compliance Mappings
| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(1) | MFA for network access |

---

### 1.2 Implement Role-Based Access Control

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Use CircleCI's organization roles to limit access based on job function.

#### ClickOps Implementation

**Step 1: Configure Organization Roles**
1. Navigate to: **Organization Settings → People**
2. Assign appropriate roles:

| Role | Permissions |
|------|-------------|
| **Admin** | Full organization control (limit to 2-3 users) |
| **Contributor** | Trigger pipelines, view builds |
| **Viewer** | Read-only access to builds |

**Step 2: Configure Project-Level Permissions**
1. Navigate to: **Project Settings → Permissions**
2. Configure:
   - **Who can trigger pipelines:** Team members only
   - **Who can view build logs:** Project members

---

### 1.3 Rotate Personal API Tokens

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Implement regular rotation of personal API tokens and audit existing tokens.

#### ClickOps Implementation

**Step 1: Audit Existing Tokens**
1. Navigate to: **User Settings → Personal API Tokens**
2. Review all active tokens
3. Delete unused tokens

**Step 2: Create Scoped Tokens**
- Create tokens with minimum required scopes
- Document purpose for each token
- Set calendar reminder for 90-day rotation

**Step 3: Organization Token Audit**
1. Navigate to: **Organization Settings → API Tokens**
2. Review project tokens
3. Rotate tokens quarterly

---

## 2. Context & Secrets Security

### 2.1 Implement Secure Contexts

**Profile Level:** L1 (Baseline) - CRITICAL
**NIST 800-53:** SC-28, AC-3

#### Description
Use CircleCI contexts with security restrictions to limit secret exposure. Contexts were the primary target in the 2023 breach.

#### Rationale
**Why This Matters:**
- Contexts contain environment variables with secrets
- 2023 breach exfiltrated context secrets
- Unrestricted contexts expose secrets to all projects

#### ClickOps Implementation

**Step 1: Create Restricted Contexts**
1. Navigate to: **Organization Settings → Contexts**
2. Create environment-specific contexts:
   - `production-secrets` (most restricted)
   - `staging-secrets`
   - `shared-tools`

**Step 2: Configure Security Groups**
1. For each context, click **Security Group**
2. Configure restrictions:
   - **All members:** ❌ (Never for production)
   - **Security Groups:** Select specific teams
   - **Add restrictions:** Enable

**Step 3: Limit Context to Specific Branches**
```yaml
# .circleci/config.yml
workflows:
  deploy:
    jobs:
      - deploy_production:
          context:
            - production-secrets
          filters:
            branches:
              only: main  # Only main branch can access production context
```

---

### 2.2 Environment Variable Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### Description
Configure environment variables with appropriate protection.

#### ClickOps Implementation

**Step 1: Use Contexts Over Project Variables**
- Store secrets in contexts (centralized management)
- Reserve project variables for non-sensitive config
- Never store secrets in repository

**Step 2: Minimize Environment Variable Exposure**
```yaml
# .circleci/config.yml
jobs:
  build:
    docker:
      - image: cimg/base:2024.01
    steps:
      - run:
          name: Build
          # Only use environment variables when needed
          command: |
            # Don't echo secrets
            # Don't pass secrets as command arguments (visible in ps)
            ./build.sh
```

**Step 3: Rotate All Secrets Post-Breach**
Following the 2023 breach, CircleCI recommended:
1. Rotate ALL secrets stored in contexts
2. Rotate ALL project environment variables
3. Review audit logs for unauthorized access
4. Rotate OAuth tokens for connected services

---

### 2.3 OIDC Token Authentication

**Profile Level:** L2 (Hardened)
**NIST 800-53:** IA-5

#### Description
Use OIDC tokens instead of static credentials for cloud provider authentication.

#### Implementation

```yaml
# .circleci/config.yml - AWS OIDC authentication
jobs:
  deploy_to_aws:
    docker:
      - image: cimg/aws:2024.01
    steps:
      - run:
          name: Configure AWS credentials via OIDC
          command: |
            # No static credentials needed
            # CircleCI OIDC token is automatically available
            aws sts assume-role-with-web-identity \
              --role-arn arn:aws:iam::123456789:role/CircleCI-Deploy \
              --role-session-name circleci-${CIRCLE_BUILD_NUM} \
              --web-identity-token ${CIRCLE_OIDC_TOKEN} \
              --duration-seconds 3600
```

**AWS IAM Trust Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789:oidc-provider/oidc.circleci.com/org/ORG_ID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.circleci.com/org/ORG_ID:aud": "ORG_ID"
        },
        "StringLike": {
          "oidc.circleci.com/org/ORG_ID:sub": "org/ORG_ID/project/*/user/*"
        }
      }
    }
  ]
}
```

---

## 3. Pipeline Security

### 3.1 Restrict Pipeline Triggers

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### Description
Control who can trigger pipelines and from which sources.

#### ClickOps Implementation

**Step 1: Configure Trigger Permissions**
1. Navigate to: **Project Settings → Advanced**
2. Configure:
   - **Only build pull requests:** Enable for public repos
   - **Build forked pull requests:** Disable or restrict

**Step 2: Implement Branch Restrictions**
```yaml
# .circleci/config.yml
workflows:
  build_and_test:
    jobs:
      - build
      - test:
          requires:
            - build

  deploy:
    jobs:
      - deploy_staging:
          filters:
            branches:
              only: develop
      - approve_production:
          type: approval
          requires:
            - deploy_staging
          filters:
            branches:
              only: main
      - deploy_production:
          requires:
            - approve_production
          filters:
            branches:
              only: main
```

---

### 3.2 Implement Pipeline Security Scanning

**Profile Level:** L1 (Baseline)
**NIST 800-53:** RA-5

#### Description
Include security scanning in CI/CD pipeline.

```yaml
# .circleci/config.yml
jobs:
  security_scan:
    docker:
      - image: cimg/base:2024.01
    steps:
      - checkout
      - run:
          name: Dependency vulnerability scan
          command: |
            # Install and run dependency scanner
            npm audit --audit-level=high
            # Or use Snyk, OWASP Dependency-Check, etc.
      - run:
          name: Secret detection
          command: |
            # Detect secrets in code
            trufflehog filesystem . --only-verified
      - run:
          name: SAST scan
          command: |
            # Static analysis
            semgrep --config=auto .

workflows:
  security:
    jobs:
      - security_scan:
          # Run on all branches
          filters:
            branches:
              ignore: []
```

---

### 3.3 Secure Docker Image Usage

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### Description
Use verified, pinned Docker images in CI/CD pipelines.

```yaml
# .circleci/config.yml
jobs:
  build:
    docker:
      # Good: Use CircleCI convenience images with specific version
      - image: cimg/node:20.10.0
      # Better: Pin to digest for immutability
      - image: cimg/node@sha256:abc123...

      # Bad: Never use :latest
      # - image: node:latest

    steps:
      - checkout
      - run: npm ci  # Use ci instead of install for reproducibility
```

---

## 4. Runner Security

### 4.1 Self-Hosted Runner Hardening

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-7

#### Description
Secure self-hosted runners for sensitive workloads.

#### Implementation

**Step 1: Runner Isolation**
```yaml
# Runner configuration
resource_class: company/secure-runner

# Use dedicated runners for production deployments
jobs:
  deploy_production:
    machine:
      image: ubuntu-2204:current
    resource_class: company/production-runner
```

**Step 2: Runner Security Configuration**
```bash
# Runner machine hardening
# - Run as non-root user
# - Enable audit logging
# - Network isolation
# - Ephemeral storage

# Example Docker runner setup
docker run -d \
  --name circleci-runner \
  --security-opt no-new-privileges \
  --read-only \
  --tmpfs /tmp \
  -e CIRCLECI_RESOURCE_CLASS="company/secure-runner" \
  -e CIRCLECI_RUNNER_API_AUTH_TOKEN="${RUNNER_TOKEN}" \
  circleci/runner:latest
```

---

## 5. Monitoring & Detection

### 5.1 Enable Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure and monitor CircleCI audit logs for security events.

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Organization Settings → Security → Audit Log**
2. Review events for:
   - Context modifications
   - Environment variable changes
   - User permission changes
   - API token creation

**Step 2: Export to SIEM**
```bash
# CircleCI API - Export audit logs
curl -X GET "https://circleci.com/api/v2/organization/${ORG_ID}/audit-log?start-time=${START}" \
  -H "Circle-Token: ${API_TOKEN}" \
  | jq '.items[]'
```

#### Detection Use Cases

```sql
-- Detect context secret access outside normal hours
SELECT *
FROM circleci_audit_log
WHERE action = 'context.env_var.accessed'
  AND (EXTRACT(HOUR FROM timestamp) < 6
       OR EXTRACT(HOUR FROM timestamp) > 20);

-- Detect bulk secret access (potential exfiltration)
SELECT user_id, COUNT(*) as access_count
FROM circleci_audit_log
WHERE action LIKE '%secret%' OR action LIKE '%env_var%'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_id
HAVING COUNT(*) > 50;

-- Detect new API token creation
SELECT *
FROM circleci_audit_log
WHERE action = 'api_token.created'
  AND timestamp > NOW() - INTERVAL '24 hours';
```

---

## 6. Incident Response

### 6.1 Post-Breach Checklist (Based on 2023 Incident)

If you suspect CircleCI compromise:

#### Immediate Actions (0-4 hours)
1. [ ] Rotate ALL secrets stored in CircleCI contexts
2. [ ] Rotate ALL project environment variables
3. [ ] Rotate OAuth tokens for connected services (GitHub, AWS, etc.)
4. [ ] Rotate SSH keys stored in CircleCI
5. [ ] Review audit logs for unauthorized access

#### Short-term Actions (24-48 hours)
1. [ ] Review all pipeline runs during suspected window
2. [ ] Audit all API token usage
3. [ ] Check for unauthorized context or project changes
4. [ ] Rotate personal API tokens
5. [ ] Review connected service audit logs

#### Long-term Actions
1. [ ] Implement OIDC for cloud provider auth (eliminate static creds)
2. [ ] Enable context restrictions by security group
3. [ ] Implement IP allowlisting
4. [ ] Configure session timeout policies
5. [ ] Establish regular secret rotation schedule

---

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | CircleCI Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.2 | Context restrictions | 2.1 |
| CC7.2 | Audit logging | 5.1 |

### NIST 800-53 Mapping

| Control | CircleCI Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | SSO with MFA | 1.1 |
| SC-28 | Context security | 2.1 |
| AU-2 | Audit logging | 5.1 |

---

## Appendix A: Plan Compatibility

| Control | Free | Performance | Scale | Server |
|---------|------|-------------|-------|--------|
| SSO | ❌ | ❌ | ✅ | ✅ |
| Contexts | ✅ | ✅ | ✅ | ✅ |
| Context Restrictions | ❌ | ❌ | ✅ | ✅ |
| IP Allowlisting | ❌ | ❌ | ✅ | ✅ |
| Audit Logs | ❌ | ❌ | ✅ | ✅ |
| Self-Hosted Runners | ❌ | ✅ | ✅ | ✅ |

---

## Appendix B: References

**Official CircleCI Documentation:**
- [Security Best Practices](https://circleci.com/docs/security-recommendations/)
- [OIDC Token Authentication](https://circleci.com/docs/openid-connect-tokens/)
- [Context Security](https://circleci.com/docs/contexts/)

**Incident Reports:**
- [January 2023 Security Incident](https://circleci.com/blog/january-4-2023-security-alert/)

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial CircleCI hardening guide with 2023 breach lessons | How to Harden Community |
