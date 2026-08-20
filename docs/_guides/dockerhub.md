---
layout: guide
title: "Docker Hub Hardening Guide"
vendor: "Docker Hub"
slug: "dockerhub"
tier: "3"
category: "DevOps"
description: "Container registry security for access tokens, image signing, and repository controls"
version: "0.3.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

Docker Hub is the largest public container registry with millions of images. Research in 2024 found **10,456 images exposing secrets** including 4,000 AI model API keys. The 2019 breach affected 190,000 accounts, and OAuth tokens for autobuilds remain perpetual attack vectors. TeamTNT attacks (2021-2022) used compromised accounts to distribute cryptomining malware with 150,000+ malicious image pulls.

### Intended Audience
- Security engineers managing container security
- DevOps engineers configuring container registries
- GRC professionals assessing container supply chain
- Platform teams managing Docker infrastructure

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls (use private registry)


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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require MFA for Docker Hub accounts, especially those with push access, and enforce SSO at the organization or company level where a Docker Business subscription is in place.

#### Rationale
**Why This Matters:**
- 2019 breach affected 190,000 accounts
- Compromised accounts distribute malicious images
- TeamTNT used compromised accounts for cryptomining malware
- SSO enforcement moves account lifecycle into the IdP, so a departing employee loses push access when they are deprovisioned rather than whenever someone remembers to remove them from Docker Hub

**Attack Prevented:** Account takeover via credential stuffing or password reuse, malicious image publication from a compromised maintainer account, and persistent access by former employees whose Docker Hub accounts outlive their employment

#### Prerequisites
- **SSO requires a Docker Business subscription.** It can be configured "for an entire company, including all associated organizations, or for a single organization that has a Docker Business subscription."
- Domain verification is the first step — you must add and verify the email domain your users sign in with before SSO can be configured.

#### ClickOps Implementation

**Step 1: Enable MFA**
1. Navigate to: **Account Settings → Security**
2. Enable: **Two-Factor Authentication**
3. Configure TOTP or security key

**Step 2: Configure and enforce SSO (Business)**
1. Add and verify your company's email domain — this establishes your identity in Docker's system and is a prerequisite for everything that follows
2. Configure your SAML/OIDC identity provider connection
3. Enforce SSO so that all members must authenticate through the IdP

> **CRITICAL — enforcing SSO breaks every password-based CLI login.** Docker states: **"When SSO is enforced, CLI password-based sign-in is no longer supported."** Users and automation must "use a personal access token (PAT) for CLI access." Before you flip enforcement, inventory every place a Docker Hub username and password is used to `docker login` — CI/CD pipelines, build servers, Kubernetes image-pull secrets, developer workstations — and replace each with a PAT (see 1.2) or, for org-owned automation, an Organization Access Token (see 1.3). Enforcing SSO without doing this will break builds and deploys at the moment of cutover.

Note that enforcing SSO is the **only** mechanism that restricts Docker CLI access. Enforcing Docker Desktop sign-in (see 1.4) does not.

---

### 1.2 Implement Access Tokens

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Use personal access tokens (PATs) instead of passwords for automation. PATs are tied to an individual user account — for CI/CD and other org-owned automation, prefer Organization Access Tokens (see 1.3), which survive the individual's departure.

#### Rationale
**Why This Matters:**
- Personal access tokens can be scoped to read-only or to specific repositories, so a leaked CI token cannot push or delete images
- Tokens are individually revocable and rotatable without changing the account password or disrupting other automation
- An account password unlocks the full Docker Hub UI, MFA settings, and every repository, so a single leaked password is a total account compromise
- Docker Hub secret-exposure research repeatedly finds credentials baked into public image layers, so push credentials must be narrowly scoped and easy to revoke

**Attack Prevented:** Credential theft, password reuse, over-privileged CI tokens, full-account takeover from a leaked secret

#### ClickOps Implementation

**Step 1: Create Scoped Tokens**
1. Navigate to: **Docker Home → avatar → Account settings → Personal access tokens → Generate new token**
2. Set a description, an expiration date, and the minimum permission level. Docker Hub PATs have **three** permission levels — not two:

| Permission | Grants | Use for |
|------------|--------|---------|
| **Read** | Pull images | CI/CD pulls, Kubernetes image-pull secrets, developer workstations |
| **Write** | Pull and push images | Build/publish pipelines (implies Read) |
| **Delete** | Pull, push, and delete images and tags | Rarely justified — grant only to a dedicated cleanup job, never to a general build token |

3. Copy the token immediately — Docker Hub displays it only once

**Step 2: Rotate Tokens**

> **Rotation on Docker Hub means replacement, not extension.** Docker states: **"You can't edit the expiration date on an existing personal access token. You must create a new PAT if you need to set a new expiration date."** Build the rotation runbook around create-new → update consumer → revoke old, and set the expiration at creation time to match the intended rotation interval below so the token expires on its own if the runbook is missed.

| Token Type | Permission | Expiration set at creation | Rotation |
|------------|-----------|----------------------------|----------|
| CI/CD pull | Read | 90 days | Quarterly |
| Build/push | Write | 30 days | Monthly |
| Cleanup/retention job | Delete | 30 days | Monthly, and audit each use |

---

### 1.3 Use Organization Access Tokens for CI/CD Credentials

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5, AC-2

#### Description
Organization access tokens (OATs) are Docker Hub credentials owned by the organization rather than by an individual user. Docker describes them as providing "secure, programmatic access to Docker Hub for automated systems, CI/CD pipelines, and other business-critical tasks," and — critically — they are "not tied to individual users who might leave the company." Every pipeline that pushes or pulls on behalf of the organization should authenticate with an OAT, not with a maintainer's personal access token.

#### Rationale
**Why This Matters:**
- A PAT inherits its owner's account lifecycle: when that person leaves and the account is deactivated, every pipeline authenticating with their token breaks — and the usual "fix" is a new PAT from whoever is on call, which quietly re-creates the problem
- Personal tokens are invisible to organization owners. An OAT is created and revoked by organization owners, so push credentials appear in an org-level inventory that can actually be audited
- OAT repository scope is explicit — up to 50 repositories per token, each with Image Pull or Image Push — so a build token for one product cannot push to another team's repositories
- Expiration is **required** on an OAT, so there is no such thing as a permanent organization token
- Org-management scopes (Member, Invite, and Group read/edit) are separate from repository scopes, so an automation token that manages membership need not also hold push rights

**Attack Prevented:** Orphaned push credentials surviving an employee's departure, unaudited personal tokens holding organization-wide push access, blast-radius expansion from one leaked CI token to every repository in the organization, and indefinite credential lifetime

#### Prerequisites
- Organization owner role — "All organization owners can create and manage OATs"
- Token count is capped per subscription: **up to 10 OATs** on a Team subscription, **up to 100 OATs** on a Business subscription. Plan the token-per-pipeline split against that ceiling before rolling out.

#### ClickOps Implementation

**Step 1: Create the token**
1. Navigate to: **Docker Home → select your organization → Identity & auth → Access tokens → Generate access token**
2. Give it a description that names the consuming pipeline, so a future audit can map every token to a system

**Step 2: Scope it**
1. Add only the repositories that pipeline touches (maximum 50 per token)
2. Set each repository to **Image Pull** or **Image Push** — deploy and runtime pull credentials get Pull only
3. Leave the organization-management scopes (**Member Edit/Read**, **Invite Edit/Read**, **Group Edit/Read**) unset unless the token exists specifically to automate membership

**Step 3: Set expiration and register the rotation**
1. Set an expiration date — it is mandatory, so choose one that matches your rotation interval rather than the maximum
2. Record the token, its owner team, and its expiry in your secrets inventory
3. Rotate by creating a replacement, cutting the consumer over, then revoking the old token

**Step 4: Retire personal tokens from shared automation**
1. Inventory every pipeline currently authenticating with a maintainer's PAT
2. Replace each with a scoped OAT
3. Revoke the personal tokens that are no longer needed

#### Validation & Testing
- The organization's **Identity & auth → Access tokens** list accounts for every push credential in use, and each entry maps to a named pipeline
- No CI/CD system authenticates with a token created under an individual's **Account settings**
- Every OAT has a future expiration date recorded in the secrets inventory
- Revoking a test OAT causes the corresponding pipeline to fail authentication, confirming the pipeline actually uses it

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **SOC 2** | CC6.3 | Access removal on termination |
| **NIST 800-53** | IA-5 | Authenticator management |
| **NIST 800-53** | AC-2 | Account management |

---

### 1.4 Enforce Docker Desktop Sign-In

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3, CM-6

#### Description
Enforcing sign-in requires Docker Desktop users to authenticate as members of your organization before they can use the application. This is distinct from enforcing SSO: sign-in enforcement is what makes a developer's local Docker Desktop actually subject to your organization's policies.

#### Rationale
**Why This Matters:**
- Docker states plainly that when "users don't sign in as organization members, they miss out on subscription benefits and **can bypass security features configured for your organization**" — every Hardened Desktop control in 3.3 is inert against an unauthenticated Docker Desktop
- Enforcement is evaluated at application start and re-evaluated on restart, and non-member accounts are automatically signed out, so it holds against a developer who signs in with a personal account
- Configuration is deployable through the same MDM channels you already use for endpoints, so it does not depend on developer cooperation
- Without it, an organization can believe registry restrictions and settings management are in force while a portion of the fleet is running entirely outside them

**Attack Prevented:** Silent bypass of organization-wide Docker Desktop policy (registry restrictions, settings management, container isolation), use of unmanaged personal accounts to pull from or publish to unapproved registries, and policy drift across developer endpoints

#### Prerequisites
- Ability to deploy configuration to developer endpoints (MDM, Group Policy, or equivalent)
- Users must be members of your Docker organization

#### ClickOps Implementation

Docker documents four configuration methods; choose per platform:

1. **`registry.json` method** — works on all platforms; the portable option when you have a single deployment channel
2. **Registry key method** — Windows only
3. **Configuration profiles method** — macOS only, and the preferred macOS route where you already run an MDM
4. **`.plist` method** — macOS only

Deploy the chosen method to every developer endpoint, then confirm Docker Desktop shows the **Sign in required!** prompt to an unauthenticated user and signs out accounts that are not organization members.

> **Limitation — this does not restrict the Docker CLI.** Docker states: **"Enforcing sign-in for Docker Desktop doesn't affect Docker CLI access. CLI access is only restricted for organizations that enforce single sign-on (SSO)."** Sign-in enforcement and SSO enforcement (1.1) are complementary, not substitutes: you need both to cover the GUI and the command line.

#### Validation & Testing
- On a managed endpoint, sign out of Docker Desktop and confirm the **Sign in required!** prompt blocks use
- Sign in with a personal account that is not an organization member and confirm it is signed out automatically
- Restart Docker Desktop and confirm enforcement re-applies
- Confirm on a test endpoint that `docker login` from the CLI still succeeds with a PAT, documenting the CLI gap so it is closed by SSO enforcement rather than assumed covered

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **SOC 2** | CC6.8 | Prevention of unauthorized software |
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | CM-6 | Configuration settings |

---

## 2. Image Security

### 2.1 Enable Docker Scout

**Profile Level:** L1 (Crawl)
**NIST 800-53:** RA-5

#### Description
Use Docker Scout for vulnerability scanning.

#### Rationale
**Why This Matters:**
- Continuous CVE scanning surfaces known-vulnerable packages and base images before they reach production
- Docker Hub hosts millions of images at widely varying patch levels, so unscanned pulls silently inherit upstream vulnerabilities
- Scout maps findings to specific layers and remediation paths, shortening the window between disclosure and patch
- Policy gates can fail a build when critical vulnerabilities are present, keeping vulnerable images out of the deploy pipeline

**Attack Prevented:** Exploitation of known CVEs, vulnerable base images, outdated dependencies, unpatched components

#### Implementation

{% include pack-code.html vendor="dockerhub" section="2.1" %}

---

### 2.2 Image Signing (Content Trust)

**Profile Level:** L2 (Walk)
**NIST 800-53:** SI-7

#### Description
Enable Docker Content Trust for image signing.

**Important:** Docker is officially retiring DCT (Docker Content Trust) for Docker Official Images. For new deployments, use Cosign/Sigstore (Section 2.4) instead. DCT is documented here for existing deployments.

#### Rationale
**Why This Matters:**
- Signature enforcement requires images to carry a valid cryptographic signature before they will pull or run, proving they were published by a trusted key holder
- Without signing, anyone with push access or a stolen token can replace an image and clients accept it silently
- Any tampering in transit or at rest in the registry invalidates the signature, so modified images are detected and rejected
- For new pipelines, Cosign/Sigstore (Section 2.4) is the recommended successor, but enforcing a trusted signature is the underlying control either way

**Attack Prevented:** Image tampering, malicious image substitution, man-in-the-middle registry attacks, unsigned-image deployment

{% include pack-code.html vendor="dockerhub" section="2.2" %}

---

### 2.3 Pin Images by Digest, Not Tag

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SI-7, SA-12
**CIS Controls:** 2.5

#### Description
Reference container images by their immutable SHA256 digest instead of mutable tags. Docker Hub tags (including `latest`, version tags like `0.69.3`, and semver tags like `v1`) are mutable pointers that can be silently replaced by anyone with push access.

#### Rationale
**Why This Matters:**
- A tag is a mutable pointer. Pinning by digest means the bytes you audited are the bytes you run, regardless of what happens to the tag afterwards
- Digest pinning protects you as a **consumer** of images you do not control — you cannot set an immutability policy on someone else's Docker Hub repository, but you can pin their digest
- It protects against upstream compromise, not just your own: if a base image's maintainer is breached and a tag is repointed, a digest-pinned build is unaffected
- Digests are verifiable offline and travel with the manifest, so the guarantee holds across mirrors, proxies, and air-gapped transfers

> **Correction (2026-08):** A previous revision of this guide stated that Docker Hub has no tag immutability feature and that digest pinning is therefore the only defense. **That is no longer accurate.** Docker Hub now supports repository-level tag immutability — see **2.7**. Publishers should enable immutability on their own repositories *and* consumers should still pin by digest; the two controls cover different threats and neither replaces the other. Immutability protects the repositories you own; digest pinning protects you from every repository you don't.

**Attack Prevented:** Tag mutation — an attacker with push access force-pushes a malicious image over an existing tag, or creates new tags (for example `0.69.5`, `0.69.6`) that appear to be legitimate version increments, and every consumer pulling by tag silently receives the malicious image

**Real-World Incident:**
- **trivy Docker Hub compromise (March 2026):** After poisoning `trivy-action` GitHub Actions tags, the attacker pushed Docker Hub images `aquasec/trivy:0.69.5` and `aquasec/trivy:0.69.6` — neither had corresponding GitHub releases. Version `0.69.6` was tagged as `latest`, meaning any `docker pull aquasec/trivy` without a pinned digest received the compromised image containing the TeamPCP Cloud Stealer. The malicious payload read `/proc/*/mem` to harvest cloud credentials and exfiltrated them to `scan.aquasecurtiy.org`.

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
1. All Dockerfiles use `@sha256:` references (no mutable tags)
2. docker-compose files use digest-pinned images
3. CI/CD workflows pin container images by digest
4. Renovate or Dependabot configured for automated digest updates

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC8.1 | Change management |
| **NIST 800-53** | SI-7, SA-12 | Software integrity, supply chain protection |
| **SLSA** | Build L2 | Pinned dependencies |
| **CIS Controls** | 2.5 | Allowlist authorized software |

---

### 2.4 Verify Images with Cosign/Sigstore

**Profile Level:** L2 (Walk)
**NIST 800-53:** SI-7, SA-12

#### Description
Use Sigstore Cosign for keyless image signing and verification. Cosign is the recommended replacement for Docker Content Trust (DCT), providing OIDC-based identity binding, transparency logging via Rekor, and OCI artifact storage for signatures.

#### Rationale
**Why This Matters:**
- Verification binds an image to the identity that produced it, so "did the right pipeline build this?" becomes a question you can answer mechanically rather than by trust
- Cosign is the forward path: DCT is being retired by Docker for Official Images, so signing schemes built on it are on a deprecation clock
- Keyless signing removes the key-management burden that caused DCT deployments to stall — there is no root key to escrow, rotate, or lose
- Signatures are tied to an OIDC identity (a specific CI/CD workflow, not just an account), so a stolen account password does not yield a valid signature
- The Rekor transparency log makes signing events publicly auditable, so a rogue signature leaves evidence even if the signing identity was legitimate
- Cosign works across all OCI registries, so the same verification policy covers Docker Hub and any registry you migrate to

**Attack Prevented:** Malicious image substitution by an attacker holding push credentials. In the Trivy Docker Hub compromise, Cosign verification with identity pinning would have detected the malicious images immediately — the attacker's push would not carry a valid signature from the legitimate Aqua Security CI/CD pipeline.

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
1. Build pipeline signs images with Cosign after push
2. Deployment pipeline verifies signatures before pull
3. Signature identity is pinned to expected OIDC issuer and subject
4. Unsigned images are rejected by deployment policies

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC8.1 | Change management |
| **NIST 800-53** | SI-7, SA-12 | Software integrity, supply chain protection |
| **SLSA** | Build L3 | Non-falsifiable provenance |
| **CIS Controls** | 2.6 | Allowlist authorized libraries |

---

### 2.5 Generate Build Provenance and SBOM Attestations

**Profile Level:** L2 (Walk)
**NIST 800-53:** SA-12, SI-7

#### Description
Generate SLSA provenance attestations and Software Bill of Materials (SBOM) for container images during build. Provenance proves where, when, and how an image was built. SBOM enumerates all components inside the image.

#### Rationale
**Why This Matters:**
- Provenance attestations prove the image was built by a trusted CI system from a specific source commit — a hand-pushed image cannot produce one
- SBOM attestations enable consumers to check for vulnerable components without pulling the full image
- Docker BuildKit generates provenance by default (minimum mode) since BuildKit 0.11, so the cost of adopting this is largely the cost of *verifying* it
- Attestations turn "this image looks like it came from our pipeline" into a checkable claim, which is what closes the ghost-image gap in 4.2

**Attack Prevented:** Directly-pushed images masquerading as pipeline builds. In the Trivy Docker Hub compromise, the "ghost" images (`0.69.5`, `0.69.6`) had no build provenance — they were pushed directly, not built by CI/CD. Provenance verification would have immediately flagged them as suspicious since they lacked attestations from Aqua Security's build pipeline.

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

### 2.6 Adopt Docker Hardened Images for Base Layers

**Profile Level:** L2 (Walk)
**NIST 800-53:** SI-2, SI-7, SA-12

#### Description
Docker Hardened Images (DHI) are minimal, non-root, continuously patched base images, Helm charts, and system packages maintained by Docker, published with signed SBOMs, VEX statements, and SLSA Build Level 3 provenance. Where your services build on a general-purpose base image from Docker Hub, replacing that base with a hardened variant removes most of the software you were never running in the first place.

#### Rationale
**Why This Matters:**
- Distroless variants strip components you do not execute — Docker claims this reduces attack surface "by up to 95%" — which removes both exploitable code and the shell an attacker would use post-breakout
- Containers run as **non-root by default**, so a container escape starts from an unprivileged position rather than root
- Images are "continuously scanned and patched to maintain minimal known vulnerabilities," which shifts base-image patching from a task your team schedules to one the publisher performs
- Every image ships a **signed SBOM** and **VEX statements**, so vulnerability triage can distinguish "present in the image" from "actually exploitable" instead of drowning teams in unreachable CVEs
- **SLSA Build Level 3 provenance** means the base layer itself carries the attestation guarantees you are building for your own images in 2.5

**Attack Prevented:** Exploitation of unused packages, interpreters, and shells that a general-purpose base image drags into production; privilege escalation from a container running as root; and prolonged exposure windows where a base image sits unpatched between manual refreshes

#### Prerequisites
- Understand the tiering before committing: **Community** (free, Apache 2.0) provides distroless variants, hardened system packages, SLSA Level 3 provenance, and signed SBOMs. **Select** adds FIPS and STIG variants, up to 5 customizations, and SLA-backed patching with "critical CVE fixes < 7 days." **Enterprise** adds unlimited customizations, full catalog and hardened-package-repository access, and an Extended Lifecycle Support add-on providing "5 years of hardened updates" past end of life.
- If you are subject to FIPS or DISA STIG requirements, the Community tier will not satisfy them — that is a Select-tier feature.

#### ClickOps Implementation

**Step 1: Identify candidate base images**
1. Inventory the `FROM` lines across your Dockerfiles and group them by base image and language runtime
2. Prioritise images that are internet-facing, hold credentials, or run as root today

**Step 2: Pilot the replacement**
1. Substitute the hardened equivalent for one non-critical service's base image
2. Expect breakage where the build or runtime assumed a shell, package manager, or debugging tool — distroless variants deliberately omit these. Move those steps into a builder stage (see 3.2) rather than reaching for a fatter base
3. Compare the vulnerability count against the previous base to quantify the benefit before proposing wider rollout

**Step 3: Consume the attestations rather than just inheriting them**
1. Verify the signed SBOM and SLSA provenance on the hardened base as part of your build, using the same verification tooling as 2.4 and 2.5
2. Feed VEX statements into your vulnerability triage so unreachable CVEs are suppressed with evidence rather than by hand
3. Pin the hardened base by digest (2.3) as you would any other image

**Step 4: Roll out and keep current**
1. Convert the remaining services, highest-risk first
2. Track base-image updates on a schedule — continuous patching only helps if you rebuild

#### Validation & Testing
- Confirm containers built on the hardened base run as a non-root user
- Confirm the running image has no shell or package manager where a distroless variant was selected
- Verify the SBOM signature and SLSA provenance of the base image resolve successfully in CI
- Compare the pre- and post-migration CVE counts for the same service and record the delta

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.1 | Vulnerability identification and management |
| **NIST 800-53** | SI-2 | Flaw remediation |
| **NIST 800-53** | SI-7 | Software integrity |
| **NIST 800-53** | SA-12 | Supply chain protection |
| **SLSA** | Build L3 | Non-falsifiable provenance |

---

### 2.7 Enforce Tag Immutability on Repositories You Publish

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SI-7, CM-5

#### Description
Docker Hub supports repository-level tag immutability. Once enabled, Docker states that **"tags cannot be updated to point to a different image after creation."** This closes the tag-mutation attack at the registry, for the repositories you own, without requiring every consumer downstream to have adopted digest pinning.

#### Rationale
**Why This Matters:**
- Digest pinning (2.3) is a *consumer-side* control and depends on every downstream consumer having adopted it. Immutability is a *publisher-side* control that protects consumers who pull by tag — which, realistically, is most of them
- The Trivy compromise turned on exactly this: `0.69.6` was moved onto `latest`, and every unpinned `docker pull` inherited the malicious image. Immutability makes that repoint impossible
- It removes an entire class of accident as well as attack — a mistaken force-push over a released tag becomes a failed push instead of a silent supply-chain event
- Immutability also makes 4.2's ghost-image detection cleaner: with tags immutable, a *new* tag is the only remaining anomaly to detect, rather than new tags plus silent digest changes on existing ones
- It is configured per repository, so it can be rolled out incrementally starting with your published, externally-consumed images

**Attack Prevented:** Tag mutation and tag hijacking — an attacker with push credentials repointing an existing tag (including `latest`) at a malicious image, and accidental overwriting of a released version by a misconfigured pipeline

**Real-World Incident:**
- **trivy Docker Hub compromise (March 2026):** `aquasec/trivy:0.69.6` was tagged as `latest`, so every unpinned pull received the TeamPCP credential stealer. An immutable `latest` would have rejected that repoint at the registry.

#### Prerequisites
- Repository admin rights on each repository you intend to configure
- Confirm no build process currently depends on overwriting an existing tag. A pipeline that pushes a rolling `dev` or `nightly` tag will start failing — plan whether that tag is excluded via the specific-tags option or the pipeline is changed to push unique tags

#### ClickOps Implementation

**Step 1: Open the repository's tag mutability settings**
1. Navigate to: **Docker Hub → My Hub → Repositories → *select the repository* → Settings → General**
2. Locate the tag mutability setting

**Step 2: Choose the policy**

| Option | Behaviour | When to use |
|--------|-----------|-------------|
| **All tags are mutable (Default)** | Any tag can be repointed at any time | The insecure default — treat any repository still on this as unhardened |
| **All tags are immutable** | No tag can be repointed after creation, **including `latest`** | Published release repositories where every tag represents a released artifact |
| **Specific tags are immutable** | Tag patterns you define (regex, Go `regexp`/RE2 syntax) are immutable; others remain mutable | Repositories that must keep a rolling tag such as `nightly` — make version tags immutable and leave only the rolling tag mutable |

**Step 3: Handle the `latest` tag deliberately**
- Choosing **All tags are immutable** covers `latest`, which means `latest` can no longer be moved to point at each new release. If your consumers rely on `latest` tracking the newest version, use **Specific tags are immutable** to lock the version tags and leave `latest` mutable — and compensate with 4.2 monitoring on `latest` digest changes.

**Step 4: Roll out and verify**
1. Start with repositories consumed outside your organization, where a tag repoint has the widest blast radius
2. Attempt to re-push an existing immutable tag and confirm the push is rejected
3. Record the policy per repository so drift is detectable

#### Validation & Testing
- Re-pushing an existing image tag on a repository set to immutable fails rather than silently succeeding
- The `latest` tag's digest is unchanged after an attempted repoint, where the policy covers it
- Where **Specific tags are immutable** is used, confirm the regex matches your actual release-tag format — test with a tag that should be locked and one that should not
- Every externally-consumed repository has a non-default tag mutability policy recorded

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC8.1 | Change management |
| **NIST 800-53** | SI-7 | Software integrity |
| **NIST 800-53** | CM-5 | Access restrictions for change |
| **SLSA** | Build L2 | Immutable, verifiable artifacts |

---

## 3. Repository Security

### 3.1 Private Repository Configuration

**Profile Level:** L1 (Crawl)

#### Description
Default Docker Hub repositories to private, grant access through teams rather than individual users, and review repository permissions on a regular schedule.

#### Rationale
**Why This Matters:**
- Public repositories expose image contents, including any secrets accidentally baked into layers, to the entire internet
- Team-based access keeps permissions consistent and lets you deprovision a departing user in one place instead of per repository
- Quarterly permission audits catch stale grants and orphaned accounts that accumulate standing push access over time
- Docker Hub secret-exposure research has found thousands of public images leaking API keys and cloud credentials, often from repositories that were never meant to be public

**Attack Prevented:** Inadvertent source and secret disclosure, unauthorized image access, permission creep, orphaned-account access

#### ClickOps Implementation

1. Set repositories to **Private** by default
2. Configure team access (not individual)
3. Audit repository permissions quarterly

---

### 3.2 Prevent Secret Exposure

**Profile Level:** L1 (Crawl)

#### Description
Scan images for embedded secrets before pushing, use multi-stage builds to keep build-time credentials out of final layers, and never hardcode credentials in Dockerfiles.

#### Rationale
**Why This Matters:**
- Secrets copied into an image persist in its layer history even if a later layer deletes them, so they remain extractable from the published image
- Pre-push secret scanning catches leaked API keys, cloud credentials, and tokens before they ever reach a public or shared registry
- Multi-stage builds discard build-time secrets and tooling, shrinking both the attack surface and the chance of credential leakage
- Once a secret is pushed to Docker Hub it must be treated as compromised and rotated, which is far costlier than preventing the leak

**Attack Prevented:** Secret leakage in image layers, hardcoded-credential exposure, credential harvesting from public images, supply chain credential theft

#### Implementation

1. Scan images for secrets before push
2. Use multi-stage builds
3. Never include credentials in Dockerfiles

---

### 3.3 Restrict Registries, Image Types, and Personal-Namespace Publishing

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-4, CM-7, SC-7

#### Description
Docker's Hardened Desktop feature set lets an organization control which registries developers may pull from, which categories of image they may use, and — critically — whether they may publish to their **personal** Docker Hub namespaces at all. Together these turn "we ask people not to pull random images" into an enforced boundary on the developer endpoint.

#### Rationale
**Why This Matters:**
- **Registry Access Management** and **Image Access Management** "prevent access to unauthorized container registries and image types, reducing exposure to malicious payloads" — this is the control that stops a developer pulling a typosquatted or unvetted image in the first place, rather than detecting it afterwards
- **Namespace Access Controls** restrict whether team members can publish images to their personal Docker Hub namespaces. This is a direct data-exfiltration mitigation: a container image is an arbitrary archive, and a push to a personal namespace is an unmonitored egress channel that bypasses every control on your organization's repositories
- Docker frames the namespace control as preventing "inadvertent release of proprietary images outside approved channels" — but the same mechanism denies a deliberate one
- These are endpoint-enforced, so they apply to work that never reaches CI/CD, where most registry-hygiene controls live
- They depend on sign-in enforcement (1.4) to be effective — an unauthenticated Docker Desktop is not subject to them

**Attack Prevented:** Pulling malicious or typosquatted images from unapproved registries, execution of unvetted community images on developer endpoints, and exfiltration of proprietary code or data by pushing it as a container image to a personal Docker Hub namespace

#### Prerequisites
- **Sign-in enforcement (1.4) must be in place first.** Docker states that users who don't sign in as organization members "can bypass security features configured for your organization" — these controls are exactly those features.
- A Docker organization with the developers in scope as members. Subscription requirements are not stated on Docker's Hardened Desktop overview page; confirm entitlement for your specific plan with Docker before planning a rollout. *(Per-feature subscription tiers not verified as of 2026-08.)*

#### ClickOps Implementation

**Step 1: Define the approved registry set**
1. Inventory the registries your builds legitimately pull from — your Docker Hub organization, any private registry, and specific upstream vendors
2. Configure **Registry Access Management** to permit only those registries
3. Expect and plan for breakage: builds pulling from an unlisted registry will fail, which is the control working

**Step 2: Restrict image categories**
1. Configure **Image Access Management** to limit which categories of Docker Hub image developers may pull — for example permitting Docker Official and Verified Publisher images while excluding arbitrary community images
2. Pair this with 2.6 so that the permitted set is one your teams can actually build on

**Step 3: Block personal-namespace publishing**
1. Configure **Namespace Access Controls** to prevent members from pushing to their personal Docker Hub namespaces
2. Route all publishing through organization repositories, where 2.7 immutability, 1.3 org tokens, and 4.1/4.2 monitoring apply

**Step 4: Layer the remaining Hardened Desktop controls**
- **Enhanced Container Isolation** runs containers in a Linux user namespace without root privileges, limiting damage from a compromised container; **Air-Gapped Containers** applies network restrictions preventing containers from reaching internal network resources; and **Settings Management** locks Docker Desktop configuration so developers cannot reintroduce insecure settings. Enable Settings Management alongside the above, or the restrictions can be locally undone.

#### Validation & Testing
- Attempt `docker pull` from a registry outside the approved list on a managed endpoint and confirm it is denied
- Attempt to pull a community image excluded by Image Access Management and confirm it is denied
- Attempt to push an image to a personal Docker Hub namespace from a managed endpoint and confirm it is rejected
- Sign out of Docker Desktop and confirm sign-in enforcement (1.4) blocks use, rather than the restrictions silently lapsing
- Attempt to change the restricted settings locally in Docker Desktop and confirm Settings Management prevents it

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | Boundary protection |
| **SOC 2** | CC6.7 | Restriction of information movement |
| **NIST 800-53** | AC-4 | Information flow enforcement |
| **NIST 800-53** | CM-7 | Least functionality |
| **NIST 800-53** | SC-7 | Boundary protection |

---

## 4. Monitoring & Detection

### 4.1 Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2

#### Description
Enable and regularly review Docker Hub activity logs so authentication events and image pushes are recorded and monitored for anomalies such as unexpected accounts, unfamiliar IP addresses, or off-schedule tag changes.

#### Rationale
**Why This Matters:**
- Activity logs are the primary evidence trail for detecting a compromised account or stolen push token before damage spreads
- Without log review, malicious pushes, tag moves, and ghost-image releases go unnoticed until downstream consumers are already affected
- Correlating push events against expected CI/CD schedules and source releases distinguishes legitimate automation from attacker activity
- Retained activity logs are essential for incident response, forensics, and demonstrating monitoring controls to auditors

**Attack Prevented:** Undetected account compromise, unauthorized image pushes, tag manipulation, delayed incident response

#### Detection Focus

Monitor Docker Hub activity logs for:
- Image push events from unexpected accounts or IP addresses
- New tags created outside normal CI/CD schedules
- The `latest` tag being moved
- Push events without corresponding GitHub release/tag events

---

### 4.2 Detect Unauthorized and Ghost Image Pushes

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SI-4, AU-6
**CIS Controls:** 8.5

#### Description
Detect "ghost" image pushes — Docker Hub images that have no corresponding source code release, tag, or build pipeline run. Ghost images indicate either a compromised push credential or a supply chain attack.

#### Rationale
**Why This Matters:**
- Tag immutability (2.7) stops an existing tag being repointed, but it does not stop an attacker creating a *new* tag — so once immutability is enabled, new-tag creation becomes the primary remaining registry-side anomaly
- Consumers infer legitimacy from version sequence, not from evidence: a `0.69.5` following `0.69.4` reads as a release even when no release exists
- Comparing registry tags against source releases is the cheapest signal that a push credential has been compromised, and it works even when the attacker's image is otherwise well-formed
- The window between a malicious push and downstream propagation is short, so detection has to be scheduled and automated rather than performed on review

**Attack Prevented:** Ghost image push — an attacker with push access creates new image tags that have no corresponding GitHub release, source tag, or CI/CD build record. Because the version number increments naturally (for example `0.69.5` after `0.69.4`), consumers assume the new version is legitimate and pull it.

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
1. Script detects Docker Hub tags with no matching GitHub release
2. Monitoring alerts configured for unexpected `latest` tag changes
3. Push credential rotation procedure documented and tested
4. Downstream distribution channels (Homebrew, Helm) included in response plan

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
- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [Immutable Tags](https://docs.docker.com/docker-hub/repos/manage/hub-images/immutable-tags/)
- [Personal Access Tokens](https://docs.docker.com/security/access-tokens/)
- [Organization Access Tokens](https://docs.docker.com/enterprise/security/access-tokens/)
- [Single Sign-On](https://docs.docker.com/enterprise/security/single-sign-on/)
- [Enforce Sign-In](https://docs.docker.com/enterprise/security/enforce-sign-in/)
- [Hardened Docker Desktop](https://docs.docker.com/security/for-admins/hardened-desktop/)
- [Docker Hardened Images](https://docs.docker.com/dhi/)
- [Docker Engine Security](https://docs.docker.com/engine/security/)
- [Security Announcements](https://docs.docker.com/security/security-announcements/)

**API & Developer Documentation:**
- [Docker Hub API Reference](https://docs.docker.com/reference/api/hub/latest/)
- [Docker Scout](https://docs.docker.com/scout/)

**Third-Party Benchmarks:**
- The **CIS Docker Benchmark covers Docker Engine — the container runtime and daemon — not Docker Hub the SaaS registry.** Its recommendations do not map to Docker Hub organization, token, or repository settings, and this guide does not cite it for Docker Hub controls. Use it for host and daemon hardening alongside this guide, not in place of it.
- No DISA STIG or CISA SCuBA baseline exists for Docker Hub as of 2026-08. Compliance mappings in this guide are to NIST 800-53, SOC 2 criteria, and SLSA build levels by name.
- Tier 3/4 independent research beyond the incidents recorded below was not re-surveyed in the 2026-08 currency pass.

**Compliance Frameworks:**
- Docker publishes its certification status (SOC 2 Type II, ISO 27001), penetration-testing cadence, and privacy-regulation posture on its trust and compliance marketing pages. Those pages are not hardening documentation and are excluded from this reference list under the repository's source standard; confirm current attestation scope and report availability directly with Docker rather than relying on a marketing claim reproduced here. *(Attestation scope not independently verified as of 2026-08.)*

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
| 2026-08-08 | 0.3.0 | draft | **Correct 2.3: Docker Hub now supports tag immutability** — the prior claim that no such feature exists is withdrawn, and the control is promoted to 2.7 (All/Specific/Mutable policies, regex, `latest` coverage); digest pinning retained as the complementary consumer-side control. Correct 1.2 PAT permissions (Read/Write/Delete) and note expiration cannot be edited after creation. Correct 1.1 SSO (Docker Business, company-wide or single-org, domain verification first) and add the critical callout that enforcing SSO ends CLI password sign-in. Add 1.3 Organization Access Tokens, 1.4 enforce Docker Desktop sign-in, 2.6 Docker Hardened Images, 3.3 Registry/Image/Namespace Access Management. Parser repairs: add **Attack Prevented** to 1.1; rename Attack Vector/Prevention/Detection to **Attack Prevented** in 2.3, 2.4, 2.5, 4.2, and restore **Why This Matters** to 2.4. Remove Trust Center and compliance marketing references; add CIS Docker Benchmark scope note | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.2.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2026-03-23 | 0.2.0 | draft | Add digest pinning, Cosign verification, build provenance, ghost image detection controls (Trivy Docker Hub supply chain attack) | Claude Code (Opus 4.6) |
| 2025-12-14 | 0.1.0 | draft | Initial Docker Hub hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
