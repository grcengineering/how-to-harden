---
layout: guide
title: "JFrog Hardening Guide"
vendor: "JFrog"
slug: "jfrog"
tier: "2"
category: "DevOps"
description: "Artifact management security for repository permissions, Xray policies, and access tokens"
version: "0.2.1"
maturity: "draft"
last_updated: "2026-08-08"
---


## Overview

JFrog Artifactory is a universal binary repository supporting **40+ package formats** across CI/CD pipelines. CVE-2024-6915 (CVSS 9.3) cache corruption vulnerability and research finding **70 cases of anonymous write permissions** demonstrate artifact poisoning risks. As the central artifact repository, compromise enables supply chain attacks through dependency confusion and malicious package injection.

### Intended Audience
- Security engineers hardening artifact repositories
- DevOps engineers configuring Artifactory
- GRC professionals assessing supply chain security
- Platform teams managing binary repositories

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all Artifactory access.

#### Rationale
**Why This Matters:**
- Centralizes Artifactory authentication in your corporate IdP so MFA and conditional access apply to every login
- Local password and anonymous logins bypass IdP controls and are prime targets for credential stuffing and phishing
- SSO with provisioning deprovisions departed users automatically, eliminating orphaned accounts with standing access to artifacts
- Artifactory is the central distribution point for build artifacts and dependencies, so a single compromised login can poison everything downstream

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access

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
2. Set expiry deliberately on every token issued — the default expiry is **3600 seconds (one hour)**, and an expiry of **0 creates a non-expirable token**, which should be treated as a finding wherever it appears
3. Scope each token to the minimum repositories and actions required

> **Correction — there is no "90-day maximum" token policy in Artifactory.** An earlier revision of this guide described a 90-day expiration policy surface; that does not exist as written. The real controls are: the default expiry is 3600 seconds (one hour); the ceiling is an administrator configuration parameter, `token.max-expiry`, set (from version 7.21.1) in `$JFROG_HOME/artifactory/var/etc/access/access.config.latest.yml` rather than in the UI; project admin tokens carry a hard maximum expiration of 24 hours (1440 minutes); and setting expiry to zero produces a token that never expires. Enforce a bounded lifetime by setting `token.max-expiry`, not by relying on a UI policy that isn't there. Source: [JFrog access tokens documentation](https://docs.jfrog.com/administration/docs/access-tokens).

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="1.1" %}

---

### 1.2 Implement Permission Targets

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure granular permissions for repository access.

#### Rationale
**Why This Matters:**
- Research found 70 cases of anonymous write permissions
- Write access enables artifact poisoning
- Dependency confusion attacks require upload capability
- Granular permission targets confine each group to the repositories and actions it actually needs, so no single compromised account can deploy to every repository

**Attack Prevented:** Artifact poisoning via anonymous or over-broad write access, dependency confusion uploads to internal repositories, cache poisoning that replaces legitimate artifacts, unauthorized artifact deletion

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

> **Automation surface:** [JFrog CLI](https://docs.jfrog.com/integrations/docs/jfrog-cli) is the vendor's first-party command-line tool for driving the platform, and is the natural place to codify permission management rather than clicking it per repository. The specific permission-target subcommands and JSON template format were **not fetch-verified during this revision**, so no commands are reproduced here — verify against the current JFrog CLI command reference before scripting against it. The Code Pack below instead uses the fetch-verified [Access REST API v2 permissions endpoints](https://docs.jfrog.com/administration/reference/createPermission) (Artifactory 7.72.0+).

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="1.2" %}

---

### 1.3 Secure API Keys and Tokens

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Manage API keys and access tokens securely.

#### Rationale
**Why This Matters:**
- Long-lived, broadly scoped tokens are bearer credentials that grant standing access if leaked in CI logs, source, or config files
- Auditing and revoking unused tokens removes forgotten credentials that attackers can quietly reuse
- Scoping tokens to the minimum repositories and actions limits blast radius if one is compromised
- Regular rotation bounds the window an exposed token remains valid

**Attack Prevented:** Token leakage, credential reuse, privilege escalation, persistent unauthorized access

#### ClickOps Implementation

**Step 1: Audit Existing Keys**
1. Navigate to: **Administration → Identity and Access → Access Tokens**
2. Review all active tokens
3. Revoke unused tokens

**Step 2: Create Scoped Tokens**

See the CLI pack below for scoped token creation commands.

**Step 3: Rotate Tokens**

| Token Type | Rotation Frequency |
|------------|--------------------|
| CI/CD tokens | Quarterly |
| User API keys | Semi-annually |
| Admin tokens | Quarterly |

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="1.3" %}

---

### 1.4 Govern Token Types by Blast Radius

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-6, IA-5

#### Description
Inventory which JFrog access token types are in use and govern each according to what it can reach, because "an Artifactory token" spans several distinct credential classes with very different blast radii.

#### Rationale
**Why This Matters:**
- JFrog issues admin tokens, user-scoped tokens, group-scoped tokens, project admin tokens (Artifactory 7.89 and later), pairing tokens, binding tokens, and identity tokens — treating them as one category means governing all of them at the weakest policy
- An admin token grants admin-level permissions across the platform, while a project admin token is confined to project resources and capped at a 24-hour lifetime; the same rotation and storage rules should not apply to both
- Group-scoped tokens are attractive for CI because they survive individual staff changes, which is exactly why they escape user-deprovisioning controls and need their own review cadence
- Pairing tokens establish trust between microservices and binding tokens establish bi-directional trust between JFrog Platform Deployments — these are infrastructure trust anchors, not user credentials, and a leaked one compromises a trust relationship rather than an account
- **Reference tokens (7.38.4 and later) change the secret-scanning story:** they are shortened 128-character aliases standing in for a token whose payload can run to 4,000 characters. Detection rules written against the long JWT-shaped token will not match a reference token, so a repository or log scanner tuned only to the full form will miss them entirely

**Attack Prevented:** Over-privileged token issuance, undetected credential leakage past format-specific secret scanners, persistence via group-scoped tokens surviving user deprovisioning, compromise of inter-service trust anchors

#### ClickOps Implementation

**Step 1: Inventory by Type**
1. Navigate to: **Administration → Identity and Access → Access Tokens**
2. Classify every active token by type: admin, user, group, project admin, pairing, binding, identity
3. Record the owner and purpose of each — an unattributable token is a revocation candidate

**Step 2: Apply Differentiated Policy**
1. Admin tokens: shortest practical lifetime, named owner, highest rotation frequency
2. Group-scoped tokens: add an explicit periodic review, since user offboarding will not retire them
3. Project admin tokens: confirm the 24-hour maximum expiry is understood by the teams issuing them
4. Pairing and binding tokens: treat as infrastructure configuration, not user credentials, and change-control them accordingly

**Step 3: Fix Secret Scanning for Reference Tokens**
1. Confirm your secret-scanning rules match the 128-character reference token form, not only the full token payload
2. Test the detection against a sample of each form before relying on it

**Reference:** [JFrog access tokens documentation](https://docs.jfrog.com/administration/docs/access-tokens)

---

## 2. Repository Security

### 2.1 Configure Repository Layout Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Harden repository configurations to prevent unauthorized access.

#### Rationale
**Why This Matters:**
- Anonymous access and open content browsing let unauthenticated users enumerate and pull internal artifacts
- Ordering internal repositories ahead of remote ones in virtual repositories blocks dependency confusion substitution
- Disabling file listing and properties search reduces the reconnaissance surface for attackers mapping the repository
- Include/exclude patterns constrain which paths can be resolved, preventing accidental exposure of sensitive artifacts

**Attack Prevented:** Unauthorized artifact access, dependency confusion, repository reconnaissance, data exposure

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-7

#### Description
Secure remote repository (proxy) configurations.

#### Rationale
**Why This Matters:**
- Remote repositories proxy untrusted public registries, so unvalidated content can introduce malicious or tampered packages
- Checksum validation and MIME-type blocking detect artifacts that have been swapped or corrupted in transit or at the source
- Exclude patterns stop the proxy from fetching internal package names from public registries, closing a dependency confusion path
- Storing artifacts locally creates a stable, auditable copy that survives upstream deletion or compromise

**Attack Prevented:** Malicious package injection, artifact tampering, dependency confusion, upstream compromise

#### ClickOps Implementation

**Step 1: Configure Remote Repository Settings**
1. Navigate to: **Repositories → Remote**
2. For each remote repository:
   - **Hard fail:** Enable for security artifacts
   - **Store artifacts locally:** Enable
   - **Block mismatching MIME types:** Enable

**Step 2: Configure Exclude Patterns**

See the CLI pack below for recommended exclude patterns.

**Step 3: Enable Checksum Validation**
1. Configure: **Checksum policy:** Fail (L2)
2. Validate checksums for all downloaded artifacts

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="2.2" %}

---

### 2.3 Prevent Dependency Confusion

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SI-7

#### Description
Configure Artifactory to prevent dependency confusion attacks.

#### Rationale
**Why This Matters:**
- Dependency confusion exploits resolvers that prefer a public package over an internal one with the same name
- Prioritizing internal repositories in resolution order ensures trusted packages always win over public look-alikes
- Reserving internal package names in public proxies blocks attackers from registering matching names externally
- A single confused dependency can execute attacker-controlled code inside every build that resolves it

**Attack Prevented:** Dependency confusion, namespace squatting, malicious package substitution, build-time code execution

#### Implementation

**Step 1: Configure Virtual Repository Priority**

See the CLI pack below for virtual repository configuration.

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

**Profile Level:** L2 (Walk)
**NIST 800-53:** SI-7

#### Description
Require artifact signing for production deployments.

#### Rationale
**Why This Matters:**
- Cryptographic signatures bind each artifact to a trusted producer, proving it was not altered after build
- Verifying signatures on download lets consumers reject artifacts that were tampered with or injected into the repository
- Signing combined with Xray enforcement blocks unsigned or unverified artifacts from reaching production
- Without signatures, a compromised repository or man-in-the-middle can substitute artifacts undetected

**Attack Prevented:** Artifact tampering, supply chain injection, unsigned-artifact deployment, build integrity loss

#### Implementation

**Step 1: Configure GPG Signing**

See the CLI pack below for signing and verification commands.

**Step 2: Verify Signatures on Download**

See the CLI pack below for download verification commands.

**Step 3: Enforce Signing Policy**
1. Use Xray policies to block unsigned artifacts
2. Document signing requirements

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="3.1" %}

---

### 3.2 Immutable Artifacts

**Profile Level:** L2 (Walk)
**NIST 800-53:** SI-7

#### Description
Make release artifacts immutable to prevent tampering.

#### Rationale
**Why This Matters:**
- Immutable release versions prevent silent replacement of a published artifact with a malicious one under the same coordinates
- Blocking re-deployment guarantees that what was tested and approved is exactly what ships
- Restricting delete permissions to admins stops attackers from removing and re-uploading tampered versions
- Mutable releases break reproducibility and let supply chain attacks hide behind unchanged version numbers

**Attack Prevented:** Artifact tampering, version overwrite, supply chain substitution, reproducibility loss

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** RA-5

#### Description
Configure JFrog Xray for vulnerability and license scanning.

#### Rationale
**Why This Matters:**
- Automated scanning surfaces known CVEs and risky licenses in dependencies before they propagate into builds
- Blocking download of critical-severity artifacts stops vulnerable components from entering the pipeline by default
- Watches tie policies to specific repositories so production paths are continuously enforced, not just scanned once
- Unscanned artifacts let known-vulnerable and non-compliant components ship into production unnoticed

**Attack Prevented:** Vulnerable dependency introduction, known-CVE exploitation, license compliance violations, supply chain risk

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

---

### 4.2 CVE Remediation Workflow

**Profile Level:** L1 (Crawl)

#### Description
Establish a repeatable workflow to triage, track, and remediate the vulnerabilities Xray detects, including alerting, ticketing, and blocking of affected artifacts.

#### Rationale
**Why This Matters:**
- Detection without a remediation process leaves known vulnerabilities sitting in the repository indefinitely
- Routing CVE alerts into ticketing with assigned owners ensures findings are actioned rather than ignored
- Blocking affected artifacts prevents continued distribution of components with unpatched critical flaws
- A bounded remediation SLA limits the window attackers have to exploit a publicly known vulnerability

**Attack Prevented:** Known-CVE exploitation, unpatched dependency distribution, vulnerability backlog, supply chain risk

#### Implementation

**Step 1: Monitor CVE Alerts**
1. Configure Xray notifications
2. Integrate with ticketing system
3. Assign remediation owners

**Step 2: Block Vulnerable Artifacts**

See the CLI pack below for Xray policy configuration.

#### Code Implementation

{% include pack-code.html vendor="jfrog" section="4.2" %}

---

## 5. Monitoring & Detection

### 5.1 Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure comprehensive audit logging.

#### Rationale
**Why This Matters:**
- Audit logs of authentication, permission changes, and artifact deploys are the primary evidence for detecting and investigating abuse
- Shipping logs to a SIEM enables correlation and alerting that local logs alone cannot provide
- Adequate retention ensures records survive long enough to investigate slow-moving supply chain compromises
- Without comprehensive logging, artifact tampering and unauthorized access can occur with no forensic trail

**Attack Prevented:** Undetected intrusion, repudiation, delayed breach discovery, forensic blind spots

#### ClickOps Implementation

**Step 1: Enable Audit Log**
1. Navigate to: **Administration → Security → Settings**
2. Enable: **Audit log**
3. Configure retention

**Step 2: Export to SIEM**
1. Configure log shipping to SIEM
2. Parse Artifactory access logs

#### Detection Queries

See the DB pack below for SIEM detection queries.

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

> **Doc host migration:** JFrog retired `jfrog.com/help/r/*` in favour of `docs.jfrog.com/{product}/docs/{slug}`. All links below were re-verified on the new host during this revision. Note that `docs.jfrog.com` returns HTTP 200 with the "Welcome to JFrog Docs" homepage for some nonexistent paths while returning a real 404 for others, so verification there requires a content check, not a status check.

**Official JFrog Documentation:**
- [Getting Started with JFrog Artifactory](https://docs.jfrog.com/artifactory/docs/getting-started)
- [Security Configuration](https://docs.jfrog.com/administration/docs/security-configuration)
- [Permissions (access control)](https://docs.jfrog.com/administration/docs/permissions)
- [Access Tokens](https://docs.jfrog.com/administration/docs/access-tokens)
- [JFrog Xray](https://docs.jfrog.com/security/docs/xray)
- [JFrog Security Advisories](https://docs.jfrog.com/releases/docs/jfrog-security-advisories)

*The former "Security Best Practices" page (`jfrog.com/help/r/jfrog-artifactory-documentation/security-best-practices`) now 301-redirects to `docs.jfrog.com/artifactory/docs/security-best-practices`, which returns 404 — the page did not survive the migration and no equivalent was locatable on the new host during this revision. Its role as this guide's primary hardening citation is carried by the Security Configuration and Permissions pages above.*

**API & Developer Resources:**
- [JFrog API](https://docs.jfrog.com/integrations/docs/jfrog-api)
- [JFrog CLI](https://docs.jfrog.com/integrations/docs/jfrog-cli)

**Compliance Frameworks:**
- JFrog publishes its SOC 2 / ISO attestation status through its Trust Center, which is a vendor assurance surface rather than a hardening source and is therefore not cited in this guide. Verify JFrog's current certification scope directly with the vendor or through your procurement process; this guide makes no claim about which certifications are currently held.

**Security Incidents:**
- **CVE-2025-14830 (Medium, published 2026-01-04):** DOM-based cross-site scripting in JFrog Artifactory, affecting versions 7.94.0 through 7.117.10. Listed on the [JFrog security advisories page](https://docs.jfrog.com/releases/docs/jfrog-security-advisories).
- **CVE-2024-6915 (CVSS 9.3):** Cache poisoning vulnerability in JFrog Artifactory allowing attackers to corrupt cached artifacts in the software supply chain. Affects versions below 7.90.6 and corresponding LTS releases. Cloud environments were patched automatically; on-premise instances require manual upgrade.
- **CVE-2024-4142 (Critical):** Improper input validation in the token creation flow enabling privilege escalation.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.1 | draft | Close the 1.2 E4 follow-up: new `hth-jfrog-1.02` api pack (Access REST API v2 — POST /access/api/v2/permissions least-privilege create using the documented READ/ANNOTATE action strings, plus a read-only audit of anonymous and over-broad grants via GET /access/api/v2/permissions and /permissions/{name}); JFrog CLI permission-target subcommands remain unverified and are still not asserted | Claude Code (Fable 5) |
| 2026-08-08 | 0.2.0 | draft | Currency pass: correct 1.1 Step 3 — the "90-day maximum" token expiration policy does not exist; the real controls are a 3600s default, the `token.max-expiry` admin config parameter, a 24-hour cap on project admin tokens, and expiry 0 meaning non-expirable. Add 1.4 (token taxonomy by blast radius, including reference tokens whose 128-character alias form defeats secret scanners tuned to the full payload). Migrate all Appendix B links from the retired `jfrog.com/help/r/*` host to `docs.jfrog.com`; the Security Best Practices page 301s to a 404 and was removed with an explicit annotation. Remove Trust Center links per the SOURCES.md bright line. Add CVE-2025-14830 and CVE-2024-4142 from the relocated advisories page (which WAS located this pass, at `docs.jfrog.com/releases/docs/jfrog-security-advisories`). Follow-up (E4 candidate): JFrog CLI permission-target commands and JSON templates were not fetch-verified — no Code Pack authored, and no commands asserted in 1.2. Tier 2 not surveyed this pass (the CIS index was not checked); Tier 3/4 not surveyed. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial JFrog Artifactory hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
