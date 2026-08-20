---
layout: guide
title: "HashiCorp Vault Hardening Guide"
vendor: "HashiCorp Vault"
slug: "hashicorp-vault"
tier: "1"
category: "Security"
description: "Secrets management security including auth methods, policies, and audit logging"
version: "0.2.1"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

HashiCorp Vault is the industry-standard secrets management solution used enterprise-wide for database credentials, API keys, PKI certificates, and dynamic secrets. The **Codecov breach (2021)** exposed HashiCorp's GPG signing key through supply chain attack, forcing rotation of all signing keys and validation of all software releases. CI/CD integrations with CircleCI, GitLab, and Jenkins create numerous OAuth and token-based access points.

### Intended Audience
- Security engineers managing secrets infrastructure
- DevOps engineers configuring Vault integrations
- GRC professionals assessing secrets management compliance
- Platform teams implementing zero-trust architectures

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Vault-specific security configurations including authentication methods, secrets engine hardening, audit logging, and CI/CD integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Secrets Engine Security](#2-secrets-engine-security)
3. [Network & API Security](#3-network--api-security)
4. [Audit Logging](#4-audit-logging)
5. [CI/CD Integration Security](#5-cicd-integration-security)
6. [Operational Security](#6-operational-security)
7. [Host & Platform Hardening](#7-host--platform-hardening)
8. [Compliance Quick Reference](#8-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Implement Least-Privilege Auth Methods

**Profile Level:** L1 (Crawl)
**CIS Controls:** 6.3, 6.8
**NIST 800-53:** AC-6, IA-2

#### Description
Configure Vault authentication methods appropriate to each use case. Avoid using root tokens for regular operations; implement workload identity where possible.

#### Rationale
**Why This Matters:**
- Root tokens provide unlimited access
- Long-lived tokens create persistent risk
- Workload identity eliminates stored secrets

**Attack Prevented:** Token theft, credential stuffing, privilege escalation

**Real-World Incidents:**
- **Codecov Breach (2021):** Compromised CI environment extracted secrets, including HashiCorp's GPG signing key

#### Prerequisites
- Vault cluster deployed and initialized
- Authentication backends configured
- Policy structure designed
- Identity provider integration (for OIDC)

#### ClickOps Implementation

**Step 1: Disable Root Token After Initial Setup**
1. Revoke the root token after initial configuration
2. Create an admin-emergency policy for break-glass scenarios
3. Generate emergency tokens with short TTLs and use limits

**Step 2: Configure OIDC for User Authentication**
1. Enable the OIDC auth method
2. Configure OIDC with your identity provider (Okta, Azure AD, etc.)
3. Create role mappings with bound audiences and redirect URIs

**Step 3: Configure AppRole for Applications**
1. Enable the AppRole auth method
2. Create roles with limited TTLs and SecretID constraints
3. Bind roles to specific CIDRs (L2)

#### Validation & Testing
1. Attempt to use root token - should be revoked
2. Login via OIDC - should succeed with appropriate policies
3. AppRole authentication - verify CIDR binding works
4. Check token TTLs are enforced

**Expected result:** Each auth method provides minimal required access

#### Monitoring & Maintenance

**Maintenance schedule:**
- **Weekly:** Review failed authentication attempts
- **Monthly:** Audit auth method configurations
- **Quarterly:** Rotate AppRole SecretIDs

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2, IA-5 | Authentication and token management |
| **ISO 27001** | A.9.2.1 | User registration and de-registration |

---


{% include pack-code.html vendor="hashicorp-vault" section="1.1" %}

### 1.2 Implement Granular Policies

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Create fine-grained policies limiting access to specific paths. Avoid wildcard policies that grant excessive access.

#### Rationale
**Why This Matters:**
- Vault policies are deny-by-default, so a wildcard or overly broad policy silently grants access to every secret path it matches
- A token scoped by a tight policy can only reach the handful of paths it needs, containing the blast radius if it is stolen
- Path-scoped capabilities (read vs. create vs. update vs. sudo) let you grant just enough access rather than full control of a mount
- Separating base, team, and application policies makes access auditable and prevents privilege creep as teams add new secrets
- Identity-templated policies that leaned on glob expansion no longer behave the same way — Vault 2.0.0 rejects them, so a policy that silently over-granted before will now fail closed on upgrade

**Attack Prevented:** Privilege escalation, lateral movement, over-broad secret access, blast-radius expansion

**Changed Default (Vault 2.0.0):** Vault 2.0.0 rejects the `+` and `*` wildcards in the **rendered** path of an identity-templated policy, and rejects uncleaned paths containing `/../`, `/./`, or `//`. A policy such as {% raw %}`path "secret/data/{{identity.entity.name}}/*"`{% endraw %} still works because the wildcard is outside the template, but any policy whose template *expands into* a wildcard, or whose rendered path is not already clean, is refused at write time and breaks on upgrade. Rewrite affected policies to explicit paths before upgrading. ([Important changes](https://developer.hashicorp.com/vault/docs/updates/important-changes))

#### ClickOps Implementation

**Step 1: Create Hierarchical Policy Structure**
1. Create a base read-only policy for all authenticated users
2. Create team-specific policies scoped to team secret paths
3. Create application policies with the most restrictive access

**Step 2: Audit Templated Policies Before Upgrading to 2.0.0**
1. List every policy with `vault policy list` and read each with `vault policy read <name>`
2. Flag any policy containing {% raw %}`{{identity.`{% endraw %} whose substituted value could contain `+`, `*`, `..`, `.`, or an empty segment
3. Flag any path containing `/../`, `/./`, or a doubled `//`
4. Rewrite flagged policies to explicit, fully-qualified paths — one `path` block per real destination rather than one glob standing in for many
5. Re-write each corrected policy with `vault policy write <name> <file>` and confirm it is accepted

#### Validation & Testing
1. `vault policy write` on a rewritten policy succeeds without a path-validation error
2. A token bound to the rewritten policy can still read every path it legitimately needs
3. The same token is denied on a path the old glob would have matched but the new explicit list does not

**Expected result:** No policy depends on wildcard expansion inside a rendered identity template, and no rendered path requires cleaning.

---


{% include pack-code.html vendor="hashicorp-vault" section="1.2" %}

### 1.3 Enable Entity and Group Management

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-2

#### Description
Use Vault's identity system to manage users and groups across auth methods, enabling consistent policy application.

#### Rationale
**Why This Matters:**
- Vault entities tie multiple auth-method aliases (OIDC, LDAP, AppRole) to one identity, so policy is applied consistently no matter how a user logs in
- Group-based policy assignment lets you change or revoke access for many users at once instead of editing tokens individually
- Mapping external IdP groups to Vault groups keeps authorization in sync with joiner-mover-leaver processes, removing orphaned access automatically
- Entity-level audit data attributes every request to a real human or workload, which is essential for investigation and accountability

**Attack Prevented:** Orphaned-account access, inconsistent authorization, privilege drift, untraceable activity

{% include pack-code.html vendor="hashicorp-vault" section="1.3" %}

---

### 1.4 Patch the 2025 Authentication, Identity, and Authorization CVE Class

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 7.1, 7.3 |
| NIST 800-53 | SI-2, AC-6 |

#### Description
In 2025, security research firm Cyata disclosed nine zero-day vulnerabilities in Vault's authentication, identity, and authorization layers -- including the first publicly documented remote code execution in Vault's history. Run a version that carries all of the resulting fixes, then add the compensating detections and surface reductions that limit what a future bug in the same layers can reach.

#### Rationale
**Why This Matters:**
- **CVE-2025-5999** -- a policy name with leading whitespace (`" root"`) was normalized to the reserved `root` policy, letting any operator holding write access to `sys/policies/acl` escalate from admin to full root
- **CVE-2025-6000** -- an audit device's log prefix could be used to write an attacker-controlled executable payload into the `plugin_directory`, which was then loaded as a plugin: Vault's first public RCE
- **CVE-2025-6004, CVE-2025-6010, and CVE-2025-6011** -- normalization mismatches between the lockout tracker and the credential lookup let attackers bypass `userpass` and LDAP lockout entirely and enumerate valid usernames
- **CVE-2025-6016** -- TOTP validation accepted padded values, reducing MFA to a brute-forceable guess
- **CVE-2025-6037** -- certificate auth could be spoofed by presenting a certificate whose Common Name matched a trusted identity without full chain binding
- The common thread is that identity, lockout, and policy names were compared after inconsistent normalization -- so patching matters more than usual here, and so does not leaving unused auth methods enabled as spare attack surface

**Attack Prevented:** Admin-to-root privilege escalation, remote code execution on the Vault node, lockout bypass, username enumeration, MFA brute force, certificate identity spoofing

**Real-World Research:**
- **Cyata "Cracking the Vault" (2025):** Nine zero-days across authentication, identity, and authorization, including Vault's first public RCE ([disclosure writeup](https://cyata.ai/blog/cracking-the-vault-how-we-found-zero-day-flaws-in-authentication-identity-and-authorization-in-hashicorp-vault/))

#### ClickOps Implementation

**Step 1: Confirm You Are on a Patched Release**
1. Run `vault status` (or `vault read sys/health`) on every node and record the version
2. Compare against the HashiCorp security bulletins for the HCSEC-2025 advisories covering CVE-2025-5999 through CVE-2025-6037
3. Upgrade any node behind the fixed release, and treat this as a patch-cadence commitment rather than a one-time action

**Step 2: Hunt for Whitespace-Variant Root Grants**
1. Run `vault policy list` and inspect every name that differs from `root` only by leading or trailing whitespace or by case
2. Delete any such policy with `vault policy delete "<name>"` and investigate who created it
3. Query the audit log for all writes to `sys/policies/acl/*` and confirm each one maps to a known operator and change ticket

**Step 3: Restrict Who Can Write Policies**
1. Grant `create` and `update` on `sys/policies/acl/*` to a single named operator policy, not to general admin policies
2. Confirm no application or CI token holds that capability with `vault token capabilities <token> sys/policies/acl/test`

**Step 4: Disable Unused Auth Methods**
1. Run `vault auth list` and identify every mount with no active production consumer
2. Disable each one with `vault auth disable <path>/`
3. Re-check after every project offboarding -- unused mounts accumulate silently

**Step 5: Protect the Plugin Directory**
1. Confirm `plugin_directory` in the server config is owned by root and is **not** writable by the Vault runtime user
2. Confirm no audit device writes anywhere inside `plugin_directory` (see [4.1](#41-enable-comprehensive-audit-logging))

#### Validation & Testing
1. Attempt `vault policy write " root" /dev/null` -- a patched Vault rejects the whitespace-variant name rather than silently overwriting root
2. `vault auth list` returns only auth methods with a named production consumer
3. A non-operator admin token returns no policy-write capability from `vault token capabilities`
4. The Vault runtime user cannot create a file inside `plugin_directory`

**Expected result:** Every node runs a patched release, no whitespace-variant root policy exists, policy-write access is held by a small operator set, and unused auth surface is disabled.

#### Monitoring & Maintenance

**Maintenance schedule:**
- **Continuous:** Alert on any write to `sys/policies/acl/*` and any policy name that normalizes to `root`
- **Monthly:** Review the auth method inventory against the list of active consumers
- **Per advisory:** Subscribe to HashiCorp security bulletins and evaluate every Vault CVE against your deployed version

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC7.1 | Vulnerability identification and remediation |
| **NIST 800-53** | SI-2, AC-6 | Flaw remediation and least privilege |
| **ISO 27001** | A.12.6.1 | Management of technical vulnerabilities |

---

### 1.5 Enforce the User Lockout Baseline

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 6.2 |
| NIST 800-53 | AC-7 |

#### Description
Vault's `user_lockout` configuration locks out a user after repeated failed logins. It ships enabled with defaults of **5 failed attempts**, a **15-minute lockout duration**, and a **15-minute counter reset**, and it applies only to the `userpass`, `ldap`, and `approle` auth methods. Confirm the defaults are in force, tune them per mount where warranted, and monitor the locked-user list.

#### Rationale
**Why This Matters:**
- Without lockout, Vault's login endpoints accept password guesses as fast as the network allows, which makes any weak `userpass` or LDAP credential a matter of time
- The protection covers only `userpass`, `ldap`, and `approle` -- every other auth method needs a different control, such as the rate-limit quotas in [3.2](#32-implement-request-rate-limiting) or lockout enforced at the identity provider
- Lockout state is queryable at `sys/locked-users`, which turns a burst of failed logins into a monitorable signal rather than a silent event
- The `VAULT_DISABLE_USER_LOCKOUT` environment variable switches the protection off entirely -- and the 2025 lockout-bypass CVEs in [1.4](#14-patch-the-2025-authentication-identity-and-authorization-cve-class) show that even an enabled lockout is only as good as the version implementing it

**Attack Prevented:** Password brute force, credential stuffing, automated login abuse, username enumeration via response timing

#### ClickOps Implementation

**Step 1: Set the Global Baseline in Server Config**
1. Add a `user_lockout "all"` stanza to the Vault server configuration file
2. Set `lockout_threshold` (attempts before lockout), `lockout_duration` (how long the lockout lasts), and `lockout_counter_reset` (how long before the failure counter clears)
3. Keep or tighten the defaults of 5 attempts, `15m` duration, and `15m` reset -- do not loosen them without a documented reason

**Step 2: Tune Per Auth Type Where Needed**
1. Add `user_lockout "userpass"`, `user_lockout "ldap"`, or `user_lockout "approle"` stanzas to override the global values for a specific auth type
2. Reserve `disable_lockout = true` for auth types where an upstream control already enforces lockout, and record the justification

**Step 3: Tune Per Mount at Runtime**
1. Apply a stricter policy to a sensitive mount with `vault auth tune -user-lockout-threshold=3 -user-lockout-duration=30m userpass/`
2. Confirm the applied values with `vault read sys/auth/userpass/tune`

**Step 4: Confirm Lockout Is Never Disabled in Production**
1. Search every environment file, systemd unit, Helm values file, and container spec for `VAULT_DISABLE_USER_LOCKOUT`
2. Remove it wherever it appears outside a disposable test environment -- setting it disables lockout for the entire Vault process

**Step 5: Monitor and Unlock**
1. List currently locked users with `vault list sys/locked-users`
2. Alert when the count rises sharply, which indicates either an attack or a broken integration retrying bad credentials
3. Unlock a specific alias with `vault write -f sys/locked-users/<mount_accessor>/unlock/<alias_identifier>`

#### Validation & Testing
1. Submit five bad passwords for a test `userpass` user, then submit the **correct** password -- it must be refused while the lockout holds
2. `vault list sys/locked-users` shows the locked alias
3. After `lockout_duration` elapses, the correct password succeeds
4. `vault read sys/auth/userpass/tune` reflects the intended per-mount values
5. `VAULT_DISABLE_USER_LOCKOUT` is absent from every production process environment

**Expected result:** Repeated failed logins lock the account, lockouts are visible at `sys/locked-users`, and the protection cannot be silently disabled.

#### Monitoring & Maintenance

**Maintenance schedule:**
- **Continuous:** Alert on locked-user count spikes and on repeated lockouts for the same alias
- **Quarterly:** Re-verify per-mount tune values and confirm no `disable_lockout` override has crept in

**Reference:** [User lockout](https://developer.hashicorp.com/vault/docs/concepts/user-lockout)

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | AC-7 | Unsuccessful logon attempts |
| **ISO 27001** | A.9.4.2 | Secure log-on procedures |

---

## 2. Secrets Engine Security

### 2.1 Use Dynamic Secrets Where Possible

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(7)

#### Description
Configure dynamic secrets engines that generate credentials on-demand with automatic expiration, eliminating static credential risk.

#### Rationale
**Why This Matters:**
- Static credentials never expire without rotation
- Dynamic credentials auto-revoke after TTL
- Limits blast radius of credential theft

**Attack Prevented:** Theft and long-term reuse of static credentials that never expire

---


{% include pack-code.html vendor="hashicorp-vault" section="2.1" %}

### 2.2 Implement Secrets Versioning and Rotation

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(1)

#### Description
Enable KV v2 secrets engine with versioning for audit trail and rollback capability.

#### Rationale
**Why This Matters:**
- KV v2 versioning keeps a history of every secret change, so an accidental or malicious overwrite can be rolled back instead of causing an outage
- Version metadata records when a secret changed, providing the audit trail required to investigate tampering
- Regular rotation reduces the window in which a leaked credential remains valid
- Soft-delete and destroy controls let you remove exposed secret values while retaining the change history for forensics

**Attack Prevented:** Secret tampering, accidental destruction, prolonged credential exposure, undetected modification

{% include pack-code.html vendor="hashicorp-vault" section="2.2" %}

---

### 2.3 Enable Transit Engine for Encryption-as-a-Service

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-28

#### Description
Use Transit secrets engine for application-level encryption without exposing encryption keys.

#### Rationale
**Why This Matters:**
- Transit performs encryption and decryption inside Vault so application servers never hold the raw key material, removing a common theft target
- Centralized key management enables key rotation and re-wrapping without re-encrypting data in every application
- Access to encrypt vs. decrypt vs. rewrap is governed by policy, so a compromised service can be limited to a single operation
- Keeping keys in Vault, backed by audit logging, produces a clear record of every cryptographic operation for compliance

**Attack Prevented:** Encryption-key theft, plaintext data exposure, unauthorized decryption, key sprawl

{% include pack-code.html vendor="hashicorp-vault" section="2.3" %}

---

## 3. Network & API Security

### 3.1 Configure TLS and API Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-8

#### Description
Secure Vault API with TLS, client certificates, and rate limiting.

#### Rationale
**Why This Matters:**
- All Vault traffic carries secrets and tokens; without TLS those values are exposed to network sniffing and man-in-the-middle attacks
- Enforcing strong TLS and client certificates ensures only trusted callers can reach the API, not anyone who can route to the listener
- Rate limiting on the API blunts brute-force and credential-stuffing attempts against authentication endpoints
- A hardened listener prevents downgrade and protocol attacks that could strip transport protection

**Attack Prevented:** Man-in-the-middle interception, token sniffing, credential brute force, protocol downgrade

#### ClickOps Implementation

{% include pack-code.html vendor="hashicorp-vault" section="3.1" %}

---

### 3.2 Implement Request Rate Limiting

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-5

#### Description
Configure rate limiting to prevent abuse and detect anomalous access patterns.

#### Rationale
**Why This Matters:**
- Rate limit quotas cap how fast a client can hit Vault, stopping a single compromised token from enumerating secrets at scale
- Throttling authentication paths slows brute-force and credential-stuffing attacks against login endpoints
- Limiting request volume protects the cluster from resource exhaustion that could deny service to legitimate workloads
- Quota breaches are observable, turning abnormal request spikes into an early signal of abuse or misconfiguration
- Rate limiting is the only throttle available for auth methods outside the `user_lockout` scope in [1.5](#15-enforce-the-user-lockout-baseline) -- JWT/OIDC, Kubernetes, cloud auth, and TLS certificate logins all depend on quotas instead

**Attack Prevented:** Brute-force authentication, secret enumeration, denial of service, automated abuse

#### ClickOps Implementation

**Step 1: Understand What Your Edition Actually Enforces**
1. In **Vault Community**, a rate limit quota is enforced **per client IP address, per node** -- a client behind many source addresses, or a cluster with many nodes, gets a correspondingly higher effective ceiling
2. In **Vault Enterprise**, quotas can group by identity using `group_by` (`ip`, `none`, `entity_then_ip`, `entity_then_none`) and can be enforced **collectively** across the cluster rather than per node
3. Size the limit against the edition you actually run -- a Community quota of 100 requests/second on a five-node cluster is not a 100 request/second ceiling

**Step 2: Create the Quotas**
1. Set a global default with `vault write sys/quotas/rate-limit/global rate=1000 interval=1s`
2. Add a tighter quota on the login surface, for example `vault write sys/quotas/rate-limit/userpass-login path="auth/userpass/login" rate=10 interval=1s`
3. Add per-mount quotas for high-value secret mounts, for example `vault write sys/quotas/rate-limit/pki path="pki/" rate=50 interval=1s`
4. On Enterprise, add `group_by=entity_then_ip` so an authenticated attacker cannot multiply their budget by rotating source addresses
5. Review the resulting set with `vault list sys/quotas/rate-limit` and `vault read sys/quotas/rate-limit/<name>`

**Step 3: Understand Precedence Before You Rely on a Limit**
1. Vault applies the **most granular matching quota**, not the most restrictive one -- a specific path quota overrides a mount quota, which overrides a namespace quota, which overrides the global quota
2. A permissive path-level quota therefore *raises* the ceiling that a stricter mount-level quota would otherwise impose
3. Enumerate quotas from most to least specific and confirm no narrow rule accidentally exempts a sensitive path

**Step 4: Apply Namespace Quotas (Enterprise)**
1. Create a quota in a parent namespace with `inheritable=true` so descendant namespaces are covered without a per-namespace rule
2. Confirm inheritance is what you want -- a non-inheritable namespace quota applies only to that namespace's own paths

**Step 5: Configure Global Quota Behavior and Observability**
1. Set defaults and exemptions at `sys/quotas/config` -- `rate_limit_exempt_paths` (paths excluded from all rate limiting), `enable_rate_limit_audit_logging` (log each rejection to the audit device), and `enable_rate_limit_response_headers` (return the retry hint to clients)
2. Keep the exempt-path list minimal and reviewed; anything listed there has no rate limit at all
3. Turn on audit logging for rejections so quota breaches reach the detections in [4.2](#42-configure-audit-log-alerting)

**Step 6: Cap Lease Volume (Enterprise)**
1. Add a lease count quota with `vault write sys/quotas/lease-count/<name> path="<mount>/" max_leases=<n>`
2. This bounds how many active leases a single mount or role can hold, which limits the damage from a runaway or hostile client generating dynamic credentials in bulk

#### Validation & Testing
1. Exceed a configured quota and confirm Vault returns HTTP 429 with a `Retry-After` header when response headers are enabled
2. Confirm the rejection appears in the audit log when `enable_rate_limit_audit_logging` is on
3. Confirm a path listed in `rate_limit_exempt_paths` is genuinely intended to be unlimited
4. On Enterprise, authenticate as one entity from two source addresses and confirm `entity_then_ip` grouping counts them against a single budget

**Expected result:** Login and high-value secret paths carry explicit quotas, precedence has been checked end to end, and every rejection is observable.

**Reference:** [Resource quotas](https://developer.hashicorp.com/vault/docs/concepts/resource-quotas)

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.6 | Protection against external threats |
| **NIST 800-53** | SC-5 | Denial of service protection |
| **ISO 27001** | A.12.1.3 | Capacity management |

---

## 4. Audit Logging

### 4.1 Enable Comprehensive Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable audit logging to file and SIEM for all Vault operations.

#### Rationale
**Why This Matters:**
- Audit devices record every request and response, giving the tamper-evident trail needed to detect and investigate secret access
- Multiple devices (file, syslog, socket) ensure logging survives a single failure and can stream to a SIEM in real time
- Vault blocks requests if it cannot write to a configured audit device, guaranteeing no secret access goes unrecorded
- Forwarding logs off-box prevents an attacker who compromises the node from quietly erasing their tracks
- Audit devices are not only a detection control -- they are a **privilege-escalation surface**, because enabling one tells Vault to write attacker-influenced content to an operator-chosen filesystem path

**Attack Prevented:** Undetected secret access, log tampering, repudiation, delayed breach discovery, audit-device-mediated code execution

**Security Advisory:** Vault guards audit file destinations so an audit device cannot write into the `plugin_directory` -- but **CVE-2026-5051 / HCSEC-2026-16** showed that the deprecated `path` parameter bypassed that guard, letting anyone with `sys/audit` write access drop a file into the plugin directory and reach code execution. Fixed in Vault **2.0.1, 1.21.6, 1.20.11, and 1.19.17**. ([HCSEC-2026-16](https://discuss.hashicorp.com/t/hcsec-2026-16-vault-audit-device-plugin-directory-guard-bypass-via-legacy-path-option/77536))

#### ClickOps Implementation

1. Enable the file audit device using the **`file_path`** option -- for example `vault audit enable file file_path=/var/log/vault/audit.log`
2. **Never use the legacy `path` option.** It is deprecated and was the vector for the plugin-directory guard bypass; audit any existing device with `vault audit list -detailed` and re-enable anything still configured with `path`
3. Confirm every audit destination resolves **outside** the configured `plugin_directory`, and that `plugin_directory` is not writable by the Vault runtime user
4. Restrict `create`, `update`, `delete`, and `sudo` on `sys/audit/*` to a small, named trusted-operator policy -- audit-device management is root-equivalent in practice, so it does not belong in a general admin policy
5. Enable syslog audit device for centralized log forwarding
6. Enable socket audit device for real-time SIEM streaming
7. Verify all audit devices are active with `vault audit list -detailed`
8. Run a version carrying the CVE-2026-5051 fix (2.0.1, 1.21.6, 1.20.11, or 1.19.17 and later)

#### Validation & Testing
1. `vault audit list -detailed` shows every device configured with `file_path`, and none with the legacy `path` option
2. No audit destination path resolves inside `plugin_directory`
3. `vault token capabilities <non-operator-token> sys/audit/file` returns no write or sudo capability
4. Disabling an audit device produces an audit event that reaches the SIEM before the device stops writing

**Expected result:** Audit devices capture every request, are managed by a small operator set, and cannot be used to write into the plugin directory.

---

{% include pack-code.html vendor="hashicorp-vault" section="4.1" %}

### 4.2 Configure Audit Log Alerting

**Profile Level:** L1 (Crawl)

#### Description
Build detection rules and alerts on Vault audit logs so that suspicious operations -- such as root token use, policy changes, or bulk secret reads -- trigger timely security notifications.

#### Rationale
**Why This Matters:**
- Audit logs only add value if someone acts on them; alerting turns passive records into timely detection of abuse
- Real-time alerts on high-risk events (root token use, policy edits, mass secret reads) shrink attacker dwell time
- Detecting anomalous access patterns surfaces compromised tokens before they are used to exfiltrate large numbers of secrets
- Routing alerts to on-call and SIEM workflows ensures security teams respond during, not after, an incident

**Attack Prevented:** Delayed breach detection, undetected token abuse, silent privilege changes, bulk secret exfiltration

#### Detection Use Cases

{% include pack-code.html vendor="hashicorp-vault" section="4.2" %}

---

## 5. CI/CD Integration Security

### 5.1 Secure Jenkins Integration

**Profile Level:** L1 (Crawl)

#### Description
Configure secure Vault integration for Jenkins with minimal privileges and short-lived tokens.

#### Rationale
**Why This Matters:**
- CI/CD systems are prime targets for supply chain attacks
- CircleCI breach (2023) exposed customer secrets
- Jenkins compromise = access to all pipelines' secrets

**Attack Prevented:** CI/CD supply chain compromise, pipeline-wide secret exposure via compromised Jenkins

#### ClickOps Implementation

**Jenkins Configuration (Jenkinsfile):**

Configure a Jenkinsfile that uses the `withVault` step to securely retrieve secrets during pipeline execution. The Vault URL and AppRole credential ID are injected via environment variables, and secrets are mapped to environment variables within the build step scope only.

{% include pack-code.html vendor="hashicorp-vault" section="5.1" %}

---

### 5.2 Implement OIDC for GitHub Actions

**Profile Level:** L2 (Walk)

#### Description
Use GitHub Actions OIDC to authenticate to Vault without storing long-lived tokens.

Configure JWT authentication for GitHub Actions using OIDC federation. This eliminates long-lived tokens by using GitHub's OIDC provider to authenticate directly to Vault with short-lived JWTs bound to specific repositories and branches.

#### Rationale
**Why This Matters:**
- GitHub Actions OIDC lets workflows authenticate to Vault with short-lived JWTs, eliminating long-lived tokens stored as repository secrets
- Tokens stored in CI are a prime exfiltration target; removing them closes off a common supply-chain attack path
- Binding the Vault role to specific repositories, branches, and claims ensures only the intended pipeline can obtain secrets
- Short-lived credentials expire automatically, so a token leaked from a build log is useless minutes later

**Attack Prevented:** CI secret theft, supply-chain compromise, long-lived token abuse, unauthorized pipeline access

{% include pack-code.html vendor="hashicorp-vault" section="5.2" %}

---

## 6. Operational Security

### 6.1 Configure Auto-Unseal

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-12

#### Description
Configure auto-unseal using cloud KMS to eliminate manual unseal key management.

#### Rationale
**Why This Matters:**
- Auto-unseal stores the unseal key in a cloud KMS, removing the need to distribute and manually enter Shamir key shares on every restart
- Eliminating manual unseal removes the risk of key shares being mishandled, lost, or captured by an operator
- KMS-backed unsealing ties Vault availability to a hardened, access-controlled key service with its own audit trail
- Automated recovery lets clusters restart unattended, avoiding prolonged outages where secrets are unavailable

**Attack Prevented:** Unseal-key compromise, insider key capture, operational key mishandling, prolonged seal outages

{% include pack-code.html vendor="hashicorp-vault" section="6.1" %}

---

### 6.2 Implement Disaster Recovery

**Profile Level:** L2 (Walk)
**NIST 800-53:** CP-9, CP-10

#### Description
Configure Vault disaster recovery and backup procedures.

Use Raft snapshots for backup and restore operations. Create snapshots regularly, verify their integrity, and test restoration procedures. For Enterprise deployments, configure DR replication for automated failover.

#### Rationale
**Why This Matters:**
- Regular Raft snapshots ensure a corrupted, deleted, or ransomware-encrypted Vault can be restored without losing all secrets
- Verifying snapshot integrity and testing restores confirms backups actually work before a real disaster strikes
- DR replication provides automated failover so a region or node loss does not leave applications unable to retrieve credentials
- Off-site, access-controlled backups protect against both accidental loss and an attacker attempting to destroy the only copy of secrets

**Attack Prevented:** Data destruction, ransomware lockout, single-point failure, irrecoverable secret loss

{% include pack-code.html vendor="hashicorp-vault" section="6.2" %}

---

### 6.3 Require Authentication for Rekey and Root-Token Generation

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 6.8 |
| NIST 800-53 | AC-3, SC-5 |

#### Description
Vault 2.0.0 changes `sys/rekey`, `sys/generate-root`, and DR operation-token generation from **unauthenticated** to **authenticated** endpoints, closing an unauthenticated denial-of-service path. Run 2.0.0 or later and confirm the requirement has not been reverted -- the change is revertible by configuration.

#### Rationale
**Why This Matters:**
- Before 2.0.0, any client that could reach the listener could initiate a rekey or root-token generation without credentials, and repeated initialization attempts could deny those operations to legitimate operators (**CVE-2026-5807 / HCSEC-2026-08**)
- These endpoints govern unseal key material and root token issuance -- the two most powerful operations in the cluster -- so anonymous access to even their initialization step is disproportionate
- Because the pre-2.0.0 behavior is **revertible**, an operator restoring an old runbook or automation can silently reopen the exposure long after the upgrade
- Requiring authentication makes every initialization attempt attributable in the audit log rather than an anonymous event

**Attack Prevented:** Unauthenticated denial of service against unseal and root operations, anonymous rekey initialization, unattributable root-token generation attempts

#### ClickOps Implementation

**Step 1: Upgrade and Confirm the Version**
1. Upgrade every node to Vault **2.0.0 or later**
2. Confirm with `vault status` or `vault read sys/health` on each node

**Step 2: Prove the Endpoints Now Require Authentication**
1. From a shell with no `VAULT_TOKEN` set, run `vault operator rekey -init` -- it must fail with a permission error rather than starting a rekey
2. Repeat for `vault operator generate-root -init`
3. On Enterprise DR clusters, repeat for DR operation-token generation

**Step 3: Confirm the Behavior Has Not Been Reverted**
1. Review the server configuration and process environment on every node for any setting that restores unauthenticated access to these endpoints
2. Add this check to your configuration drift detection -- a revert is a one-line change that produces no visible symptom
3. Update any runbook or automation that assumed unauthenticated rekey so no one has a reason to revert it

**Step 4: Scope Who May Call Them**
1. Grant `sys/rekey/*`, `sys/generate-root/*`, and the DR operation-token paths only to a named break-glass operator policy
2. Verify no general admin, application, or CI token holds those capabilities using `vault token capabilities <token> sys/generate-root/attempt`

**Step 5: Alert on Use**
1. Add a detection for any successful write to `sys/rekey/*` or `sys/generate-root/*` and route it to on-call as a high-severity event (see [4.2](#42-configure-audit-log-alerting))

#### Validation & Testing
1. Unauthenticated `vault operator rekey -init` returns a permission error
2. Unauthenticated `vault operator generate-root -init` returns a permission error
3. An authenticated break-glass operator can still complete a rekey, and the attempt appears in the audit log with an identity attached
4. `vault read sys/health` reports version 2.0.0 or later on every node

**Expected result:** No unseal, rekey, or root-generation operation can be initiated anonymously, and every attempt is attributable.

**Reference:** [HCSEC-2026-08](https://discuss.hashicorp.com/t/hcsec-2026-08-vault-vulnerable-to-denial-of-service-via-unauthenticated-root-token-generation-rekey-operations/77345)

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | AC-3, SC-5 | Access enforcement and denial of service protection |
| **ISO 27001** | A.9.4.1 | Information access restriction |

---

## 7. Host & Platform Hardening

### 7.1 Apply the Production Hardening Baseline

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 4.4, 8.4 |
| NIST 800-53 | CM-6, SC-28, AU-8 |

#### Description
Vault's own security model assumes the host is trusted. HashiCorp publishes a production hardening baseline covering the operating system, process isolation, network posture, and operational process around a Vault node. Apply it -- these are the assumptions every control elsewhere in this guide depends on.

#### Rationale
**Why This Matters:**
- Vault's threat model explicitly treats root access on the host as a full compromise: anyone who can read Vault's memory or attach a debugger can read decrypted secrets regardless of policy
- Secrets are decrypted in memory, so swap files and core dumps can write plaintext secret material to disk where it survives a reboot and lands in backups
- Vault should be the **only** service on the machine (single tenancy) -- every co-tenant application is another path to the memory holding your entire secret store
- Outbound firewall rules matter as much as inbound: they are what stops a compromised node from exfiltrating secrets to an attacker-controlled destination
- Vault issues and validates time-bound credentials (leases, TTLs, tokens, certificates), so clock drift directly undermines expiry enforcement

**Attack Prevented:** Host-level secret extraction from memory or swap, plaintext secrets persisted to disk via core dumps, lateral movement from co-tenant services, secret exfiltration from a compromised node, TTL bypass via clock drift

#### ClickOps Implementation

**Step 1: Isolate the Process**
1. Run Vault as a dedicated, unprivileged user (for example `vault`) that owns no other service and has no login shell
2. Enforce **single tenancy** -- no other application, agent, or workload runs on the Vault host
3. Set filesystem permissions so only the Vault user can read the configuration, TLS private keys, and storage directory; keep the binary owned by root and non-writable by the Vault user

**Step 2: Prevent Secrets From Reaching Disk**
1. Disable swap on the host so decrypted secrets in memory are never paged out
2. Disable core dumps for the Vault process so a crash cannot write memory contents to disk
3. Disable shell command history for the Vault operator account so tokens and unseal shares typed at a prompt are not persisted
4. If you run Vault in a container **without** the `IPC_LOCK` capability, you must set `disable_mlock = true` -- Vault cannot lock memory without that capability. Doing so removes Vault's own protection against paging, which makes disabled (or encrypted) swap a hard requirement rather than a recommendation

**Step 3: Control the Network in Both Directions**
1. Restrict **inbound** traffic to the API port (8200) and cluster port (8201) from known client and peer ranges only
2. Restrict **outbound** traffic to the destinations Vault genuinely needs -- storage backend, cloud KMS for auto-unseal, identity provider, log destinations
3. Do not expose the Vault API directly to the internet

**Step 4: Harden Transport and Time**
1. Prefer **TLS 1.3** on the listener, and disable legacy protocol versions and weak cipher suites
2. Synchronize the host clock with NTP and monitor for drift, since token, lease, and certificate expiry all depend on accurate time

**Step 5: Close the Human Loop**
1. Document an **off-boarding process** that revokes departing operators' Vault access, rotates any unseal key shares they held, and rotates credentials they could have read
2. Trigger it from the same HR event that drives IdP deprovisioning, not from a separate manual checklist

#### Validation & Testing
1. `ps -o user= -p $(pgrep vault)` returns the dedicated unprivileged user, not root
2. `swapon --show` returns nothing, or swap is confirmed encrypted
3. The Vault process core dump limit is zero, and no core file appears after a forced crash in a test environment
4. Only Vault-related listeners are bound on the host
5. An outbound connection attempt from the host to an unapproved destination is blocked
6. A TLS scan of the listener negotiates TLS 1.3 and refuses legacy versions and weak ciphers
7. Host clock offset from the NTP source is within tolerance
8. A test off-boarding produces revoked Vault access and a rotation record

**Expected result:** The Vault host runs one unprivileged service, cannot page or dump secrets to disk, talks only to approved destinations in both directions, keeps accurate time, and has a documented operator off-boarding path.

**Reference:** [Production hardening](https://developer.hashicorp.com/vault/docs/concepts/production-hardening)

#### Monitoring & Maintenance

**Maintenance schedule:**
- **Continuous:** Alert on new listeners, new processes, or swap being re-enabled on the Vault host
- **Monthly:** Re-verify firewall rules in both directions against the approved destination list
- **Quarterly:** Re-run the TLS scan and confirm off-boarding was executed for every departure

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.6, CC6.8 | Boundary protection and unauthorized software prevention |
| **NIST 800-53** | CM-6, SC-28, AU-8 | Configuration settings, protection at rest, time stamps |
| **ISO 27001** | A.12.1.2, A.13.1.1 | Change management and network controls |

---

### 7.2 Apply Extended Platform Isolation

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 4.8 |
| NIST 800-53 | CM-7, AC-6(10), SI-7 |

#### Description
Beyond the baseline, HashiCorp documents extended hardening for regulated and high-value deployments: kernel-enforced process confinement, mandatory access control, immutable upgrades, and administrative isolation of the `sys/` surface.

#### Rationale
**Why This Matters:**
- Systemd sandboxing and a tight capability set mean that even a code-execution bug in Vault runs in a process that cannot write to the filesystem or acquire new privileges -- directly limiting the class of attack demonstrated by the audit-device RCE in [1.4](#14-patch-the-2025-authentication-identity-and-authorization-cve-class)
- SELinux or AppArmor enforce confinement the process cannot opt out of, unlike file permissions that root can override
- Immutable upgrades -- replacing nodes rather than patching them in place -- guarantee that a compromised host is destroyed rather than carried forward, and that every running node matches a known-good image
- An administrative namespace (Enterprise) separates the operators who manage `sys/` from the tenants who consume secrets, so tenant admins cannot reach cluster-wide operations

**Attack Prevented:** Post-exploitation persistence on the Vault host, privilege escalation from a Vault process compromise, drift between running nodes and approved images, tenant-to-cluster administrative escalation

#### ClickOps Implementation

**Step 1: Sandbox the Service Unit**
1. In the systemd unit, set `ProtectSystem=full` and `ProtectHome=read-only` so Vault cannot write to system or user directories
2. Set `PrivateTmp=yes` and `PrivateDevices=yes` to isolate temporary files and device access
3. Set `NoNewPrivileges=yes` so the process and its children can never gain privileges
4. Constrain `CapabilityBoundingSet` to `CAP_IPC_LOCK` only -- the single capability Vault needs to lock memory
5. Reload with `systemctl daemon-reload` and restart Vault, then confirm the service still starts and can lock memory

**Step 2: Enforce Mandatory Access Control**
1. Deploy an SELinux policy (or AppArmor profile) confining the Vault process to its configuration, storage, TLS, and audit paths
2. Run in permissive/complain mode first, collect denials, then switch to enforcing
3. Confirm the enforcement mode after every host reboot -- a policy silently left permissive provides no protection

**Step 3: Adopt Immutable Upgrades**
1. Build Vault nodes from a versioned image and upgrade by **replacing** nodes rather than patching in place
2. Disable interactive shell access to running nodes so the image remains the only source of truth
3. Verify each node reports the expected version with `vault status` after replacement

**Step 4: Isolate Administration (Enterprise)**
1. Configure an **administrative namespace** so cluster-wide `sys/` operations live in a dedicated namespace separate from tenant namespaces
2. Grant the administrative namespace only to platform operators, and confirm tenant admins cannot reach `sys/` operations outside their own namespace

#### Validation & Testing
1. `systemctl show vault` reflects the sandboxing directives, and Vault still starts cleanly
2. The Vault process cannot write to a system directory, and a privilege-raising `exec` attempt fails
3. `getenforce` returns `Enforcing` (or the AppArmor profile is in enforce mode), and no unexpected denials appear
4. Replacing a node produces the expected version and no manual post-install steps
5. A tenant-namespace admin token is denied on a cluster-level `sys/` path

**Expected result:** Vault runs confined by both systemd and mandatory access control, nodes are replaced rather than patched, and cluster administration is isolated from tenant administration.

**Reference:** [Production hardening](https://developer.hashicorp.com/vault/docs/concepts/production-hardening)

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.8, CC8.1 | Unauthorized software prevention and change management |
| **NIST 800-53** | CM-7, AC-6(10), SI-7 | Least functionality, privilege restriction, software integrity |
| **ISO 27001** | A.12.5.1, A.12.6.2 | Installation of software and software installation restrictions |

---

## 8. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Vault Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | Auth methods and policies | 1.1 |
| CC6.2 | Granular policies | 1.2 |
| CC6.1 | User lockout baseline | 1.5 |
| CC6.6 | Request rate limiting | 3.2 |
| CC6.6 | Host and network hardening | 7.1 |
| CC7.1 | Vulnerability remediation | 1.4 |
| CC7.2 | Audit logging | 4.1 |
| CC8.1 | Immutable upgrades | 7.2 |

### NIST 800-53 Mapping

| Control | Vault Control | Guide Section |
|---------|------------------|---------------|
| AC-3 | Authenticated rekey and root generation | 6.3 |
| AC-6 | Least privilege policies | 1.2 |
| AC-7 | Unsuccessful logon attempts | 1.5 |
| IA-5 | Token and auth management | 1.1 |
| AU-2 | Audit logging | 4.1 |
| CM-6 | Production hardening baseline | 7.1 |
| CM-7 | Least functionality and process confinement | 7.2 |
| SC-5 | Rate limit quotas | 3.2 |
| SC-28 | Transit encryption | 2.3 |
| SI-2 | Flaw remediation for known Vault CVEs | 1.4 |

---

## Appendix A: Edition Compatibility

| Control | Community | Enterprise | HCP Vault |
|---------|-----------|------------|-----------|
| Auth Methods | ✅ | ✅ | ✅ |
| Audit Logging | ✅ | ✅ | ✅ |
| Dynamic Secrets | ✅ | ✅ | ✅ |
| Namespaces | ❌ | ✅ | ✅ |
| Sentinel Policies | ❌ | ✅ | ✅ |
| DR Replication | ❌ | ✅ | ✅ |
| Performance Replication | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official HashiCorp Documentation:**
- [HashiCorp Security](https://www.hashicorp.com/security)
- [Compliance Overview](https://www.hashicorp.com/en/trust/compliance)
- [Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Production Hardening](https://developer.hashicorp.com/vault/docs/concepts/production-hardening)
- [Security Model](https://developer.hashicorp.com/vault/docs/internals/security)
- [Auth Methods](https://developer.hashicorp.com/vault/docs/auth)
- [Audit Devices](https://developer.hashicorp.com/vault/docs/audit)
- [User Lockout](https://developer.hashicorp.com/vault/docs/concepts/user-lockout)
- [Resource Quotas](https://developer.hashicorp.com/vault/docs/concepts/resource-quotas)
- [Important Changes (upgrade-breaking behavior)](https://developer.hashicorp.com/vault/docs/updates/important-changes)
- [Kubernetes Security Considerations](https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-security-concerns)

**API & Developer Tools:**
- [Vault API Documentation](https://developer.hashicorp.com/vault/api-docs)
- [Vault CLI Reference](https://developer.hashicorp.com/vault/docs/commands)
- [Terraform Vault Provider](https://registry.terraform.io/providers/hashicorp/vault/latest/docs)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018 (for HCP Vault) -- reports available under NDA via [Compliance Overview](https://www.hashicorp.com/en/trust/compliance)

**Security Incidents & Advisories:**
- **Codecov Supply Chain Attack (Apr 2021):** Compromised CI environment at Codecov was used to exfiltrate environment variables from CI builds. HashiCorp's GPG signing key was exposed, forcing rotation of all signing keys and validation of all published software releases.
- **Cyata "Cracking the Vault" (2025):** Nine zero-day vulnerabilities in Vault's authentication, identity, and authorization layers, including Vault's first publicly documented RCE -- [disclosure writeup](https://cyata.ai/blog/cracking-the-vault-how-we-found-zero-day-flaws-in-authentication-identity-and-authorization-in-hashicorp-vault/) (see [1.4](#14-patch-the-2025-authentication-identity-and-authorization-cve-class))
- **HCSEC-2026-08 (CVE-2026-5807):** Denial of service via unauthenticated root token generation and rekey operations -- [advisory](https://discuss.hashicorp.com/t/hcsec-2026-08-vault-vulnerable-to-denial-of-service-via-unauthenticated-root-token-generation-rekey-operations/77345) (see [6.3](#63-require-authentication-for-rekey-and-root-token-generation))
- **HCSEC-2026-16 (CVE-2026-5051):** Audit device plugin directory guard bypass via the legacy `path` option -- [advisory](https://discuss.hashicorp.com/t/hcsec-2026-16-vault-audit-device-plugin-directory-guard-bypass-via-legacy-path-option/77536) (see [4.1](#41-enable-comprehensive-audit-logging))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.1 | draft | Cheat-sheet cell repair: added missing Attack Prevented line(s) to §2.1, §5.1 (no content-facts changed) | Claude Code (Fable 5) |
| 2026-08-03 | 0.2.0 | draft | Add 2025 Cyata CVE-class patching control (1.4), user lockout baseline (1.5), authenticated rekey and root-generation control (6.3), and new Host & Platform Hardening section (7.1, 7.2); update policy control for the Vault 2.0.0 templated-path change, rate limiting with concrete quota implementation, and audit logging for the CVE-2026-5051 `file_path` mandate | Claude Code (Sonnet 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial HashiCorp Vault hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
