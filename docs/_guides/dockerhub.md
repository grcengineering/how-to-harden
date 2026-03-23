---
layout: guide
title: "Docker Hub Hardening Guide"
vendor: "Docker Hub"
slug: "dockerhub"
tier: "3"
category: "DevOps"
description: "Container registry security for access tokens, image signing, and repository controls"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-03-23"
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


### Scope
This guide covers Docker Hub security configurations including authentication, access controls, and integration security.

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
|------------|----------|
| CI/CD pull | Quarterly |
| Build/push | Monthly |

#### Code Implementation

{% include pack-code.html vendor="dockerhub" section="1.2" %}

---

## 2. Image Security

### 2.1 Enable Docker Scout

**Profile Level:** L1 (Baseline)
**NIST 800-53:** RA-5

#### Description
Use Docker Scout for vulnerability scanning.

#### Implementation

{% include pack-code.html vendor="dockerhub" section="2.1" %}

---

### 2.2 Image Signing (Content Trust)

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SI-7

#### Description
Enable Docker Content Trust for image signing.

**Important:** Docker is officially retiring DCT (Docker Content Trust) for Docker Official Images. For new deployments, use Cosign/Sigstore (Section 2.4) instead. DCT is documented here for existing deployments.

{% include pack-code.html vendor="dockerhub" section="2.2" %}

---

### 2.3 Pin Images by Digest, Not Tag

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SI-7, SA-12
**CIS Controls:** 2.5

#### Description
Reference container images by their immutable SHA256 digest instead of mutable tags. Docker Hub tags (including `latest`, version tags like `0.69.3`, and semver tags like `v1`) are mutable pointers that can be silently replaced by anyone with push access.

#### Rationale
**Attack Vector:** Tag mutation — an attacker with push access force-pushes a malicious image to an existing tag, or creates new tags (e.g., `0.69.5`, `0.69.6`) that appear to be legitimate version increments.

**Real-World Incident:**
- **trivy Docker Hub compromise (March 2026):** After poisoning `trivy-action` GitHub Actions tags, the attacker pushed Docker Hub images `aquasec/trivy:0.69.5` and `aquasec/trivy:0.69.6` — neither had corresponding GitHub releases. Version `0.69.6` was tagged as `latest`, meaning any `docker pull aquasec/trivy` without a pinned digest received the compromised image containing the TeamPCP Cloud Stealer. The malicious payload read `/proc/*/mem` to harvest cloud credentials and exfiltrated them to `scan.aquasecurtiy.org`.

**Why This Matters:** Unlike AWS ECR, Google Artifact Registry, and Azure Container Registry, Docker Hub has **no tag immutability feature**. Tags are always mutable. Digest pinning is the only defense against tag manipulation on Docker Hub.

#### ClickOps Implementation

**Step 1: Find the Digest of a Trusted Image**
1. Go to Docker Hub and navigate to the image's **Tags** tab
2. Click on the specific tag to see its digest (starts with `sha256:`)
3. Or run: `docker manifest inspect <image>:<tag>` locally

**Step 2: Update References to Use Digests**
1. In **Dockerfiles**: Change `FROM image:tag` to `FROM image@sha256:<digest>`
2. In **docker-compose.yml**: Change `image: name:tag` to `image: name@sha256:<digest>`
3. In **CI/CD workflows**: Pin container images in `jobs.*.container.image`
4. In **Kubernetes manifests**: Pin `spec.containers[].image` to digests

**Step 3: Automate Digest Updates**
1. Use Renovate Bot or Dependabot to automatically propose digest updates when upstream images change
2. Configure a weekly schedule for digest update PRs
3. Review digest updates before merging — verify they correspond to legitimate releases

**Time to Complete:** ~15 minutes per repository

#### Code Implementation

{% include pack-code.html vendor="dockerhub" section="2.3" %}

#### Validation & Testing
1. [ ] All Dockerfiles use `@sha256:` references (no mutable tags)
2. [ ] docker-compose files use digest-pinned images
3. [ ] CI/CD workflows pin container images by digest
4. [ ] Renovate or Dependabot configured for automated digest updates

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC8.1 | Change management |
| **NIST 800-53** | SI-7, SA-12 | Software integrity, supply chain protection |
| **SLSA** | Build L2 | Pinned dependencies |
| **CIS Controls** | 2.5 | Allowlist authorized software |

---

### 2.4 Verify Images with Cosign/Sigstore

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SI-7, SA-12

#### Description
Use Sigstore Cosign for keyless image signing and verification. Cosign is the recommended replacement for Docker Content Trust (DCT), providing OIDC-based identity binding, transparency logging via Rekor, and OCI artifact storage for signatures.

#### Rationale
**Why Cosign Over DCT:**
- DCT is being retired by Docker for Official Images
- Cosign supports keyless signing (no key management burden)
- Signatures are tied to OIDC identity (specific CI/CD workflow, not just an account)
- Transparency log (Rekor) provides public auditability
- Works across all OCI registries, not just Docker Hub

**Attack Prevention:** In the Trivy Docker Hub compromise, Cosign verification with identity pinning would have detected the malicious images immediately — the attacker's push would not have a valid signature from the legitimate Aqua Security CI/CD pipeline.

#### ClickOps Implementation

**Step 1: Install Cosign**
1. macOS: `brew install cosign`
2. Linux: Download from GitHub releases
3. CI: Use `sigstore/cosign-installer` GitHub Action

**Step 2: Sign Images in CI/CD**
1. Add `id-token: write` permission to your workflow
2. Install cosign via `sigstore/cosign-installer@v3`
3. After `docker push`, run `cosign sign <image>@<digest>`
4. Keyless signing automatically uses the workflow's OIDC identity

**Step 3: Verify Before Deployment**
1. Add a verification step before any `docker pull` or deployment
2. Pin the expected signer identity and OIDC issuer
3. Fail the pipeline if verification fails

**Time to Complete:** ~30 minutes for CI/CD integration

#### Code Implementation

{% include pack-code.html vendor="dockerhub" section="2.4" %}

#### Validation & Testing
1. [ ] Build pipeline signs images with Cosign after push
2. [ ] Deployment pipeline verifies signatures before pull
3. [ ] Signature identity is pinned to expected OIDC issuer and subject
4. [ ] Unsigned images are rejected by deployment policies

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC8.1 | Change management |
| **NIST 800-53** | SI-7, SA-12 | Software integrity, supply chain protection |
| **SLSA** | Build L3 | Non-falsifiable provenance |
| **CIS Controls** | 2.6 | Allowlist authorized libraries |

---

### 2.5 Generate Build Provenance and SBOM Attestations

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SA-12, SI-7

#### Description
Generate SLSA provenance attestations and Software Bill of Materials (SBOM) for container images during build. Provenance proves where, when, and how an image was built. SBOM enumerates all components inside the image.

#### Rationale
**Attack Detection:** In the Trivy Docker Hub compromise, the "ghost" images (`0.69.5`, `0.69.6`) had no build provenance — they were pushed directly, not built by CI/CD. Provenance verification would have immediately flagged them as suspicious since they lacked attestations from Aqua Security's build pipeline.

**Why This Matters:**
- Provenance attestations prove the image was built by a trusted CI system from a specific source commit
- SBOM attestations enable consumers to check for vulnerable components without pulling the full image
- Docker BuildKit generates provenance by default (minimum mode) since BuildKit 0.11

#### ClickOps Implementation

**Step 1: Enable Provenance in Builds**
1. Use `docker buildx build` with `--provenance=mode=max` for full provenance
2. Add `--sbom=true` to generate SBOM attestations
3. Push to registry — attestations are stored as OCI artifacts alongside the image

**Step 2: Inspect Attestations**
1. Run `docker buildx imagetools inspect <image>` to view provenance
2. Use `cosign verify-attestation` for cryptographic verification

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="dockerhub" section="2.5" %}

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC8.1 | Change management |
| **NIST 800-53** | SA-12, SI-7 | Supply chain protection, software integrity |
| **SLSA** | Build L2/L3 | Signed provenance |

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

---

## 4. Monitoring & Detection

### 4.1 Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2

#### Detection Focus

Monitor Docker Hub activity logs for:
- Image push events from unexpected accounts or IP addresses
- New tags created outside normal CI/CD schedules
- The `latest` tag being moved
- Push events without corresponding GitHub release/tag events

---

### 4.2 Detect Unauthorized and Ghost Image Pushes

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SI-4, AU-6
**CIS Controls:** 8.5

#### Description
Detect "ghost" image pushes — Docker Hub images that have no corresponding source code release, tag, or build pipeline run. Ghost images indicate either a compromised push credential or a supply chain attack.

#### Rationale
**Attack Vector:** Ghost image push — an attacker with push access creates new image tags that have no corresponding GitHub release, source tag, or CI/CD build record. Because the version number increments naturally (e.g., `0.69.5` after `0.69.4`), consumers assume the new version is legitimate.

**Real-World Incident:**
- **trivy Docker Hub compromise (March 2026):** The attacker pushed `aquasec/trivy:0.69.5` and `aquasec/trivy:0.69.6` to Docker Hub — neither version had a corresponding GitHub release, tag, or source commit. Version `0.69.6` was tagged as `latest`. The attack exploited the assumption that Docker Hub images always correspond to source releases.

**Anti-Incident-Response TTPs observed:**
- Attacker deleted the original incident disclosure discussion (#10265) to slow community awareness
- 17+ spam bot accounts flooded the replacement discussion within 1 second with generic praise messages to bury legitimate alerts
- Taunting messages ("teampcp owns you") served as both attribution and disruption

**Cross-Channel Propagation:** The same poisoned binary cascaded through GitHub Releases, GitHub Actions, Docker Hub, Homebrew, and Helm charts simultaneously — compromising the source artifact once and letting distribution automation amplify the attack.

#### ClickOps Implementation

**Step 1: Establish Source-to-Image Mapping**
1. Document which CI/CD pipeline builds and pushes each Docker Hub image
2. Ensure every image push is triggered by a GitHub release or tag event
3. Verify that the `latest` tag is only moved by your CI/CD pipeline, never manually

**Step 2: Set Up Monitoring**
1. Compare Docker Hub tags against GitHub releases on a schedule (daily minimum)
2. Alert on any Docker Hub tag that has no corresponding GitHub release
3. Alert when the `latest` tag digest changes outside of a CI/CD run
4. Monitor for unexpected version increments (e.g., `0.69.5` when the latest release is `0.69.4`)

**Step 3: Respond to Ghost Images**
1. If a ghost image is detected, immediately check if push credentials are compromised
2. Rotate all Docker Hub access tokens
3. Remove the ghost image tags
4. Notify consumers that the tags may have been malicious
5. Check Homebrew, Helm charts, and other downstream distributors for automatic propagation

**Time to Complete:** ~20 minutes for initial setup; ongoing monitoring

#### Code Implementation

{% include pack-code.html vendor="dockerhub" section="4.2" %}

#### Validation & Testing
1. [ ] Script detects Docker Hub tags with no matching GitHub release
2. [ ] Monitoring alerts configured for unexpected `latest` tag changes
3. [ ] Push credential rotation procedure documented and tested
4. [ ] Downstream distribution channels (Homebrew, Helm) included in response plan

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2, CC7.3 | Detection and monitoring, incident response |
| **NIST 800-53** | SI-4, AU-6 | System monitoring, audit review |
| **CIS Controls** | 8.5 | Collect detailed audit logs |

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
- **Trivy Docker Hub Compromise (March 2026):** TeamPCP pushed `aquasec/trivy:0.69.5` and `0.69.6` to Docker Hub with no corresponding GitHub releases. Version `0.69.6` was tagged as `latest`. The images contained a three-stage credential stealer that read `/proc/*/mem` and exfiltrated cloud credentials to `scan.aquasecurtiy.org`. This was part of a broader supply chain attack that also poisoned 75 `trivy-action` GitHub Actions tags, Homebrew packages, and Helm charts. See Sections 2.3, 2.4, 2.5, and 4.2 for hardening controls.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-03-23 | 0.2.0 | draft | Add digest pinning, Cosign verification, build provenance, ghost image detection controls (Trivy Docker Hub supply chain attack) | Claude Code (Opus 4.6) |
| 2025-12-14 | 0.1.0 | draft | Initial Docker Hub hardening guide | Claude Code (Opus 4.5) |
