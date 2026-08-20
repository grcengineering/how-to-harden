---
layout: guide
title: "MongoDB Atlas Hardening Guide"
vendor: "MongoDB"
slug: "mongodb-atlas"
tier: "1"
category: "Data"
description: "Database-as-a-Service security hardening for MongoDB Atlas network access, authentication, and encryption"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

MongoDB Atlas is the leading cloud database platform, serving **millions of developers** with fully managed MongoDB deployments across AWS, Azure, and Google Cloud. As a critical data store for applications, Atlas security configurations directly impact data protection. By default, all access is blocked and must be explicitly enabled, but misconfigurations can expose databases to unauthorized access.

### Intended Audience
- Security engineers managing database infrastructure
- Database administrators configuring Atlas clusters
- GRC professionals assessing data security
- DevOps engineers implementing secure deployments

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers MongoDB Atlas security configurations including network access, authentication, encryption, and monitoring. Self-managed MongoDB deployments are covered in a separate guide.

---

## Table of Contents

1. [Network Security](#1-network-security)
2. [Authentication & Access](#2-authentication--access)
3. [Encryption & Data Protection](#3-encryption--data-protection)
4. [Monitoring & Auditing](#4-monitoring--auditing)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Network Security

### 1.1 Configure IP Access List

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | SC-7 |

#### Description
Configure IP access lists to restrict which IP addresses can connect to your Atlas clusters. By default, all access is blocked.

#### Rationale
**Why This Matters:**
- Default-deny ensures no unauthorized network access — Atlas blocks everything until you explicitly open it, so every entry on this list is a deliberate exposure decision
- IP allowlisting limits exposure to known addresses, so a stolen database credential is unusable from anywhere but your own network egress points
- A `0.0.0.0/0` entry, however temporary, publishes the cluster to the entire internet and turns a credential-strength problem into an internet-facing exposure — this is the single most common Atlas misconfiguration
- Expiring entries for developer access prevent temporary home or coffee-shop IPs from becoming permanent standing access

**Attack Prevented:** Internet-wide database exposure, credential reuse from attacker infrastructure, automated internet-scan discovery, standing access via stale temporary entries

#### ClickOps Implementation

**Step 1: Access Network Configuration**
1. Navigate to: **MongoDB Atlas** → **Project** → **Network Access**
2. Review current IP access list

**Step 2: Configure IP Access**
1. Click **Add IP Address**
2. Configure allowed IPs:
   - **Development:** Individual developer IPs (temporary)
   - **Production:** Application server IPs/CIDR ranges only
   - **NEVER:** 0.0.0.0/0 (allows any IP)
3. Add description for each entry
4. Set expiration for temporary access

**Best Practices:**

| Environment | Recommended Configuration |
|-------------|--------------------------|
| Development | Individual IPs with expiration |
| Staging | Application server IPs only |
| Production | Smallest CIDR possible, VPC peering preferred |

> **Do not pin literal Atlas IP addresses in your own outbound firewall rules.** MongoDB began rotating the public IPv4 addresses of AWS dedicated clusters on **2025-01-21**. Any egress allowlist, security group, or connection string built on hard-coded Atlas IPs will break as addresses rotate. Connect with the `mongodb+srv://` connection string, which resolves current endpoints automatically, and allowlist by hostname or use private connectivity (control 1.2) where your firewall supports it.

**Time to Complete:** ~15 minutes

---


{% include pack-code.html vendor="mongodb-atlas" section="1.1" %}

### 1.2 Configure VPC Peering or Private Endpoints

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 12.1 |
| NIST 800-53 | SC-7 |

#### Description
Configure private connectivity via VPC peering or private endpoints to eliminate public internet exposure.

#### Rationale
**Why This Matters:**
- Private endpoints eliminate public internet exposure entirely — the cluster has no reachable public listener to attack, rather than a public listener guarded by an allowlist
- Traffic stays within the cloud provider network, removing exposure to internet-path interception and to the operational fragility of maintaining IP allowlists across a changing fleet
- More secure than IP allowlisting alone: an allowlist still fails open if someone adds a broad CIDR, while a private-only cluster cannot be reached from an attacker's network no matter what the list says
- Private connectivity also survives the Atlas public-IP rotation described in control 1.1, removing an entire class of brittle firewall configuration

**Attack Prevented:** Internet-facing exposure, network eavesdropping, allowlist misconfiguration, credential use from attacker-controlled networks

#### Prerequisites
- A **Dedicated** cluster (M10 or higher). Private endpoints and VPC peering are **not** available on Free or Flex clusters — see [Appendix A](#appendix-a-tier-compatibility)
- AWS VPC, Azure VNet, or GCP VPC configured

#### ClickOps Implementation

**Step 1: Configure VPC Peering**
1. Navigate to: **Network Access** → **Peering**
2. Click **Add Peering Connection**
3. Select cloud provider and region
4. Enter VPC/VNet details:
   - VPC ID
   - CIDR block
   - Account/Project ID
5. Accept peering from your cloud provider console

**Step 2: Configure Private Endpoints (Recommended)**
1. Navigate to: **Network Access** → **Private Endpoint**
2. Click **Add Private Endpoint**
3. Select cloud provider and region
4. Follow provider-specific instructions:
   - **AWS:** Create VPC endpoint
   - **Azure:** Create private endpoint
   - **GCP:** Create private service connect

**Step 3: Update IP Access List**
1. Private endpoints are automatically added
2. Remove public IP entries if no longer needed
3. Verify connectivity through private endpoint

> **Connection rate limit (announced November 2025):** M10 and M20 clusters cap new connections at **15 per second per node**. Applications that open connections aggressively — serverless functions without connection reuse, or a deployment that restarts every pod at once — will be throttled, and the resulting failures look like a network or endpoint problem rather than a rate limit. Use pooled connections and staggered restarts, and size up if your legitimate connection rate genuinely exceeds the cap.

**Time to Complete:** ~1 hour

---

### 1.3 Enforce Atlas Resource Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-2, CM-6, CM-7 |

#### Description
Use Atlas Resource Policies — generally available, Cedar-based, and set at the organization level — to make the hardening decisions in this guide structurally unbreakable across every project, so that a project owner cannot open a cluster to the internet or stand one up without auditing and customer-managed keys.

#### Rationale
**Why This Matters:**
- Every other control in this guide is a setting a sufficiently privileged project user can undo; a resource policy is an organization-level guardrail that they cannot, which converts hardening from a recurring audit chore into an enforced invariant
- The highest-severity Atlas incidents come from a single project drifting — one `0.0.0.0/0` entry, one cluster created without auditing, one deployment in an unapproved region — and policies stop the drift at creation time rather than at the next review
- Policies enforce controls across projects that do not exist yet, so newly created projects inherit the posture instead of starting unhardened and waiting for someone to notice
- Non-compliance is queryable, so you get a concrete remediation list rather than an assertion that everything is fine

**Attack Prevented:** Configuration drift, unauthorized internet exposure, unaudited clusters, data residency violations, privilege misuse by project-level administrators

#### Prerequisites
- Organization Owner role (policies are managed at the organization level)

#### ClickOps Implementation

**Step 1: Review Available Policy Types**

Atlas Resource Policies can enforce, among others:

| Policy | Effect |
|--------|--------|
| Prohibit `0.0.0.0/0` CIDR | Blocks the internet-open IP access-list entry outright (control 1.1) |
| Require empty IP access list | Forces private-connectivity-only clusters (control 1.2) |
| Block IP access-list modification | Prevents project users from changing network exposure at all |
| Restrict cloud providers | Limits deployments to approved providers |
| Restrict regions | Enforces data-residency requirements |
| Require database auditing | Makes auditing non-optional on every cluster (control 4.1) |
| Require customer-managed keys | Makes CMK encryption non-optional (control 3.2) |
| Minimum TLS version and cipher suites | Prevents downgrade to weaker transport settings |
| Maintenance window constraints | Keeps disruptive maintenance inside approved windows |
| Cluster topology and tier limits | Constrains what shapes and sizes can be deployed |

**Step 2: Author and Apply Policies**
1. Navigate to: **Organization** → **Settings** → **Resource Policies**
2. Create a policy using the Cedar policy language
3. Scope it to the organization or to specific projects
4. Apply, then confirm existing projects surface as compliant or non-compliant

**Step 3: Monitor Non-Compliance**
1. Query the Administration API endpoint `/orgs/{ORG-ID}/nonCompliantResources` for resources that violate an active policy
2. Wire that query into your existing configuration-drift alerting rather than checking it by hand
3. Remediate or grant a documented exception for each result

Reference: [Atlas Resource Policies](https://www.mongodb.com/docs/atlas/atlas-resource-policies/)

#### Validation & Testing
1. In a test project, attempt to add a `0.0.0.0/0` IP access-list entry and confirm the policy refuses it
2. Attempt to create a cluster without auditing enabled and confirm creation is blocked
3. Confirm `/orgs/{ORG-ID}/nonCompliantResources` returns an empty result set for your production organization

---

## 2. Authentication & Access

### 2.1 Configure Database Users with Least Privilege

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Create database users with role-based access control (RBAC) following the principle of least privilege.

#### Rationale
**Why This Matters:**
- Limits blast radius of compromised credentials — a leaked application credential scoped to `read` on one database cannot be used to enumerate, modify, or drop the rest of the deployment
- Supports compliance requirements by producing defensible, per-purpose access grants rather than a small number of shared all-powerful users
- Enables audit of access patterns: when each application has its own database user, audit logs attribute every query to a specific workload instead of to a shared identity
- `atlasAdmin` and the `*AnyDatabase` roles are effectively deployment-wide access — every additional holder is another credential whose compromise is a total compromise

**Attack Prevented:** Credential compromise escalating to full-deployment access, lateral movement between databases, unauthorized data modification or deletion, repudiation through shared credentials

#### ClickOps Implementation

**Step 1: Access Database Users**
1. Navigate to: **Database Access** → **Database Users**
2. Review existing users

**Step 2: Create Least Privilege Users**
1. Click **Add New Database User**
2. Configure authentication:
   - **SCRAM:** Password-based (most common)
   - **X.509 Certificate:** Certificate-based (recommended for machine-to-machine — see control 2.3)
   - **AWS IAM:** For AWS workloads
   - **OIDC / OAuth 2.0 Workforce or Workload Identity Federation:** Federated authentication — the documented modern replacement for LDAP (see the callout below)
   - **LDAP:** Deprecated — see the callout below
3. Configure privileges:
   - **Built-in Role:** Select appropriate role
   - **Custom Role:** Create granular permissions
4. Restrict to specific database if possible

**Recommended Roles:**

| Use Case | Recommended Role |
|----------|-----------------|
| Application read | readAnyDatabase or read on specific DB |
| Application write | readWriteAnyDatabase or readWrite on specific DB |
| Admin operations | dbAdmin on specific DB |
| Full admin | atlasAdmin (limit to 1-2 users) |

**Step 3: Create Separate Service Accounts**
1. Create dedicated users for each application
2. Avoid shared credentials
3. Document user purpose

**Step 4: Plan the Move Off LDAP**

> **LDAP is deprecated.** MongoDB's documentation states: *"Starting with MongoDB 8.0, LDAP authentication and authorization are deprecated."* Deprecated means still operational for the lifetime of MongoDB 8, with removal in a future major release — not immediately broken. Treat it as a migration you schedule rather than an emergency, but do schedule it: the removal release will arrive, and LDAP-authenticated workloads will stop connecting when it does.

The documented replacement is **OIDC / OAuth 2.0 federated authentication**, in two forms:

| Mode | Use for |
|------|---------|
| **Workforce Identity Federation** | Human users authenticating to databases through your corporate IdP |
| **Workload Identity Federation** | Applications and services authenticating with short-lived tokens instead of stored secrets |

1. Inventory every database user and workload currently authenticating via LDAP
2. Choose Workforce or Workload federation per identity type
3. Configure the OIDC provider in **Database Access** → **Federated Authentication**
4. Migrate and validate one workload at a time, then remove the LDAP configuration

> **OIDC and LDAP authorization cannot coexist.** You cannot run OIDC authentication alongside LDAP authorization on the same deployment, so plan a clean cutover for authorization rather than a gradual dual-run.

References: [Set up LDAPS](https://www.mongodb.com/docs/atlas/security-ldaps/) · [Configure database authentication](https://www.mongodb.com/docs/atlas/security/config-db-auth/)

**Time to Complete:** ~30 minutes

---


{% include pack-code.html vendor="mongodb-atlas" section="2.1" %}

### 2.2 Enable Multi-Factor Authentication for Atlas Console

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all users accessing the MongoDB Atlas console.

#### Rationale
**Why This Matters:**
- The Atlas console controls network access lists, database users, encryption keys, and cluster configuration — a single compromised admin login can expose or destroy all data
- Passwords alone are vulnerable to phishing, credential stuffing, and reuse from prior breaches; MFA adds a second factor an attacker cannot obtain with the password alone
- MongoDB's own December 2023 corporate breach began with a phishing attack, underscoring that console and identity compromise is a realistic threat
- Security keys and biometrics (FIDO2) are phishing-resistant — they will not release a credential to a lookalike domain, which is exactly the failure mode that defeats one-time codes
- Enrolling a second factor method protects against lockout: losing your only enrolled device on an MFA-required organization is a support ticket, not a login

**Attack Prevented:** Credential theft, phishing, credential stuffing, account takeover, real-time one-time-code relay

#### ClickOps Implementation

**Step 1: Configure Organization MFA**
1. Navigate to: **Organization** → **Settings** → **Require Multi-Factor Authentication**
2. Enable MFA requirement for all organization members

**Step 2: Configure Personal MFA**
1. Each user: **Account** → **Security** → **Multi-Factor Authentication**
2. Configure MFA methods in this order of preference:

| Method | Recommendation |
|--------|----------------|
| FIDO2 security key or biometric | **Preferred** — phishing-resistant |
| Okta Verify | Strong; use where Okta is already your IdP |
| Authenticator app (TOTP) | Acceptable baseline |
| Email | Weakest supported option; use only as a fallback |
| SMS | **Deprecated** — see callout below |

3. Enroll **at least two** methods per account so a lost device does not lock the user out

> **SMS is deprecated and closed to new registrations.** As of **2025-03-12**, MongoDB no longer accepts new SMS factor registrations. Existing SMS enrollments continue to function as a legacy method, but SMS is vulnerable to SIM-swap and interception and should be replaced. Migrate any account still relying on SMS to FIDO2 or an authenticator app.

Reference: [Atlas multi-factor authentication](https://www.mongodb.com/docs/atlas/security-multi-factor-authentication/)

---

### 2.3 Configure X.509 Certificate Authentication

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2 |

#### Description
Configure X.509 certificate authentication for stronger machine-to-machine authentication.

#### Rationale
**Why This Matters:**
- Certificate-based authentication removes static database passwords that leak through source code, config files, logs, and environment variables
- X.509 credentials are bound to a private key the client holds, making them far harder to phish or replay than a shared secret
- Certificates carry an explicit expiration, forcing periodic rotation and limiting the useful lifetime of a stolen credential
- Atlas-managed or self-managed CA issuance enables centralized revocation when a host or service is decommissioned or compromised

**Attack Prevented:** Credential leakage, password reuse, credential replay, orphaned-credential access

#### ClickOps Implementation

**Step 1: Enable X.509 Authentication**
1. Navigate to: **Database Access** → **Database Users**
2. Click **Add New Database User**
3. Select **Certificate** authentication
4. Choose:
   - **Atlas-managed:** Atlas manages certificates
   - **Self-managed:** You provide CA and certificates

**Step 2: Configure Atlas-Managed X.509**
1. Download client certificate for your application
2. Configure application connection string with certificate
3. Rotate certificates before expiration

---

### 2.4 Configure Organization and Project Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Configure granular roles for Atlas console access at organization and project levels.

#### Rationale
**Why This Matters:**
- Granular org and project roles enforce least privilege so each user holds only the access their job requires, shrinking the blast radius of any compromised account
- Limiting Organization Owner assignments prevents broad, unchecked control over billing, clusters, and security settings
- Separating data-access administration from cluster management enforces separation of duties for sensitive operations
- Read-only roles let auditors and stakeholders review configuration without the ability to change it

**Attack Prevented:** Privilege escalation, lateral movement, insider misuse, excessive standing access

#### ClickOps Implementation

**Step 1: Review Organization Roles**
1. Navigate to: **Organization** → **Access Manager**
2. Review user assignments
3. Available roles:

| Organization Role | Grants |
|-------------------|--------|
| Organization Owner | Full control of the organization, including resource policies and org settings — limit to 2-3 |
| Organization Project Creator | Can create new projects and becomes their owner — a broad grant, because a new project starts outside your existing review |
| Organization Billing Admin | Billing management |
| Organization Billing Viewer | Read-only billing |
| Organization Stream Processing Admin | Administers Atlas Stream Processing across the organization |
| Organization Member | Basic organization access |
| Organization Read Only | View only |

**Step 2: Review Project Roles**
1. Navigate to: **Project** → **Access Manager**
2. Assign project-specific roles:

| Project Role | Grants |
|--------------|--------|
| Project Owner | Full control of the project |
| Project Cluster Manager | Create, modify, and manage clusters |
| Project Data Access Admin | Full database-user administration |
| Project Data Access Read/Write | Read and write to project data |
| Project Data Access Read Only | Read project data |
| Project Stream Processing Owner | Full control of stream processing instances |
| Project Read Only | View only |

> **Watch the Project Access Manager role.** Project Access Manager can create both **API keys and service accounts** for the project. That makes it a privilege-escalation path: a holder who cannot directly perform an action can mint a programmatic credential with roles they choose and act through it, and the resulting activity is attributed to the credential rather than to them. Treat Project Access Manager as a privileged grant on par with Project Owner, review its holders on the same cadence, and audit newly created API keys and service accounts against the person who created them.

References: [Atlas user roles](https://www.mongodb.com/docs/atlas/reference/user-roles/)

---

### 2.5 Harden Administration API Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.5 |
| NIST 800-53 | AC-3, IA-5 |

#### Description
Access the Atlas Administration API with service accounts using OAuth 2.0 client credentials and expiring tokens rather than legacy API keys, and require an IP access list for Administration API use at the organization level.

#### Rationale
**Why This Matters:**
- Legacy Atlas API keys authenticate with HTTP Digest and **do not expire** — a leaked key in a CI log, a git history, or a decommissioned developer's password manager stays valid indefinitely until someone notices and revokes it
- Service accounts use the OAuth 2.0 client-credentials flow and issue **expiring access tokens**, so a captured token has a bounded useful lifetime and secret rotation is a documented, supported operation rather than a manual scramble
- The Administration API can create and delete clusters, edit the IP access list, manage database users, and change encryption settings — it is a control-plane credential, and control-plane compromise is broader than any single database credential
- Requiring an IP access list for Administration API calls means a stolen credential is unusable from the attacker's own infrastructure, adding a network condition to a credential that otherwise works from anywhere

**Attack Prevented:** Control-plane takeover via leaked API credentials, indefinite validity of exposed secrets, API abuse from attacker-controlled networks, unauthorized cluster and access-list modification

#### ClickOps Implementation

**Step 1: Migrate to Service Accounts**
1. Navigate to: **Organization** → **Access Manager** → **Applications** (service accounts) or the project-level equivalent
2. Create a service account per integration, scoped with the minimum organization or project roles it needs
3. Record the client ID and client secret in your secrets manager
4. Repoint each automation at the OAuth 2.0 client-credentials flow to obtain short-lived access tokens

**Step 2: Retire Legacy API Keys**
1. Inventory existing API keys at both organization and project level
2. Confirm each has a documented owner and purpose; delete the rest
3. Replace remaining keys with service accounts, then delete the keys

**Step 3: Require an IP Access List for the API**
1. Navigate to: **Organization** → **Settings**
2. Enable **Require IP Access List for the Atlas Administration API**
3. Add the egress addresses of your CI/CD systems and administrative jump hosts to each credential's access list

> **The IP access list gates API *use*, not credential *creation*.** Enabling it does not stop someone from creating a new API key or service account — it constrains where credentials can be used from. Pair this control with the Project Access Manager review in control 2.4, which is the surface that governs credential creation.

**Step 4: Rotate on a Schedule**
1. Document a rotation interval for each service-account secret
2. Rotate immediately on any suspected exposure, and whenever a person with access to the secret leaves

Reference: [Configure Atlas Administration API access](https://www.mongodb.com/docs/atlas/configure-api-access/)

#### Validation & Testing
1. Confirm no legacy API keys remain in **Access Manager** for production organizations
2. Call the Administration API from an address outside the access list and confirm the request is refused
3. Confirm access tokens issued to service accounts expire as expected

---

## 3. Encryption & Data Protection

### 3.1 Verify Default Encryption

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-8, SC-28 |

#### Description
Verify that default encryption at rest and in transit is enabled (cannot be disabled in Atlas).

#### Rationale
**Why This Matters:**
- Encryption at rest (AES-256) protects data on disk, in backups, and in snapshots if the underlying storage media is stolen, mishandled, or improperly decommissioned
- Encryption in transit (TLS 1.2+) prevents interception or tampering of data as it travels between applications and the cluster
- Verifying these defaults provides documented evidence for SOC 2, PCI DSS, HIPAA, and ISO 27001 audits
- Confirming TLS is enforced ensures no client can negotiate an unencrypted or downgraded connection

**Attack Prevented:** Data theft at rest, network eavesdropping, man-in-the-middle, TLS downgrade

#### Atlas Default Security

| Feature | Default Setting | Can Disable? |
|---------|-----------------|--------------|
| Encryption at Rest (AES-256) | ✅ Enabled | ❌ No |
| Encryption in Transit (TLS 1.2+) | ✅ Enabled | ❌ No |
| TLS 1.3 Support | ✅ Available | N/A |

#### Validation
1. Navigate to: **Clusters** → Select cluster → **Security**
2. Verify encryption indicators show enabled
3. Test connection requires TLS

---

### 3.2 Configure Customer Key Management (CMK)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Configure customer-managed encryption keys for additional control over data encryption.

#### Rationale
**Why This Matters:**
- Provides customer control over encryption keys — you hold the key material in your own KMS, so MongoDB cannot decrypt your data without a key you continue to grant access to
- Revoking or disabling the key in your KMS renders the stored data unreadable, giving you a unilateral kill switch that does not depend on the provider acting on your behalf
- Supports compliance requirements (PCI DSS, HIPAA) that expect demonstrable customer control and separation of duties over encryption keys
- Enables key rotation policies on your own schedule, bounding how much data any single key version protects

**Attack Prevented:** Provider-side data exposure, unauthorized access to at-rest data after cluster or snapshot compromise, inability to revoke access to stored data, key-lifetime sprawl

#### Prerequisites
- A **Dedicated** cluster (M10 or higher). Customer key management is **not** available on Free or Flex clusters — see [Appendix A](#appendix-a-tier-compatibility)
- Cloud provider KMS (AWS KMS, Azure Key Vault, GCP Cloud KMS)

#### ClickOps Implementation

**Step 1: Configure Cloud Provider KMS**
1. Create KMS key in your cloud provider
2. Configure key policy for Atlas access
3. Note key ARN/ID

**Step 2: Enable CMK in Atlas**
1. Navigate to: **Project** → **Security** → **Encryption at Rest**
2. Click **Configure Encryption at Rest**
3. Select cloud provider
4. Enter KMS key details
5. Configure role/credentials for Atlas access
6. Enable encryption

**Step 3: Verify CMK Configuration**
1. Check cluster shows CMK-encrypted
2. Test key rotation capability

**Time to Complete:** ~1 hour

---


{% include pack-code.html vendor="mongodb-atlas" section="3.2" %}

### 3.3 Configure Client-Side Field Level Encryption

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-28 |

#### Description
Configure Client-Side Field Level Encryption (CSFLE) to encrypt sensitive fields before they leave the application.

#### Rationale
**Why This Matters:**
- Encrypts PII and sensitive data at the field level before it ever leaves the application, so the plaintext never reaches the database server, its memory, its logs, or its backups
- Data remains encrypted in the database, which means a database administrator, a compromised cluster, or a stolen snapshot yields ciphertext rather than customer records
- Only clients holding the data encryption keys can decrypt, moving the trust boundary from "who can reach the database" to "who holds the key" — the strongest available separation between infrastructure access and data access
- Field-level scope lets you protect the handful of genuinely sensitive fields without paying the query and operational cost of encrypting everything

**Attack Prevented:** Insider access to sensitive fields by database or cloud administrators, plaintext exposure through snapshots and backups, data theft following full cluster compromise, sensitive data leakage into logs

#### Implementation
1. Configure encryption schema defining fields to encrypt
2. Generate data encryption keys
3. Configure application driver with encryption settings
4. Test encryption/decryption of sensitive fields

---

### 3.4 Enable Backup Compliance Policy

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 11.1, 11.3 |
| NIST 800-53 | CP-9, CP-10, SI-1 |

#### Description
Enable Backup Compliance Policy on Dedicated (M10+) clusters to make cloud backup snapshots immutable — once the policy is active, no role in your organization, including Organization Owner, can delete a snapshot, shorten its retention, or disable backup.

#### Rationale
**Why This Matters:**
- Every other backup control assumes the person holding admin rights is acting in good faith; ransomware operators and rogue administrators both begin by destroying backups, and a backup an administrator can delete is not a recovery guarantee
- Backup Compliance Policy removes that capability entirely — there is no role that can delete snapshots or reduce retention while the policy is active, so credential compromise at the highest privilege level still leaves your recovery points intact
- Disabling the policy requires a designated security or legal representative plus **MongoDB Support approval** (a process MongoDB hardened further in February 2026), which means an attacker cannot unwind it inside an incident window
- Project deletion is blocked until the snapshots expire, closing the obvious workaround of deleting the whole project to get rid of the backups
- This is the control that turns "we have backups" into a defensible recovery position for regulators and cyber-insurance underwriters

**Attack Prevented:** Ransomware destruction of recovery points, rogue-administrator backup deletion, retention tampering to hide activity, backup destruction via project deletion

#### Prerequisites
- A **Dedicated** cluster (M10 or higher) with cloud backup enabled
- A designated security or legal representative recorded in the policy — this contact is required to request that the policy ever be disabled

#### ClickOps Implementation

**Step 1: Decide the Policy Before Enabling It**

> **This is a one-way door by design.** Once enabled, the policy cannot be disabled or weakened by anyone in your organization. Removing it requires the designated security/legal representative to go through MongoDB Support. Set retention periods you can live with — over-long retention becomes an unavoidable storage cost and an unavoidable data-retention obligation.

1. Agree the minimum retention period and backup frequency with your legal, security, and finance stakeholders
2. Identify the designated security or legal representative

**Step 2: Enable the Policy**
1. Navigate to: **Organization** → **Settings** → **Backup Compliance Policy**
2. Enter the designated security or legal representative's details
3. Configure the minimum backup schedule, retention periods, and point-in-time recovery window
4. Enable the policy and confirm

**Step 3: Verify Enforcement**
1. As an Organization Owner, attempt to delete a snapshot and confirm the operation is refused
2. Attempt to reduce a retention period below the policy floor and confirm it is refused
3. Confirm the policy applies to the projects and clusters you intended

References: [Backup Compliance Policy](https://www.mongodb.com/docs/atlas/backup/cloud-backup/backup-compliance-policy/)

---

## 4. Monitoring & Auditing

### 4.1 Enable Database Auditing

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable database auditing to log authentication attempts and data access.

#### Rationale
**Why This Matters:**
- Audit logs capture authentication attempts and data access, providing the forensic trail needed to detect and investigate unauthorized activity
- Without auditing, a breach or insider abuse can occur with no record of who accessed what data and when
- Exporting audit events to a SIEM or object storage enables real-time alerting and tamper-resistant long-term retention
- Comprehensive audit trails are required to demonstrate compliance with frameworks such as SOC 2, PCI DSS, and HIPAA

**Attack Prevented:** Undetected data exfiltration, insider abuse, repudiation, delayed breach detection

#### ClickOps Implementation

**Step 1: Enable Auditing**
1. Navigate to: **Project** → **Database Deployments**
2. Select cluster → **Auditing**
3. Enable auditing
4. Configure audit filter for events of interest

**Step 2: Configure Log Push to External Storage or a SIEM**

Atlas push-based log delivery now covers a broader set of destinations than object storage alone:

| Destination | Notes |
|-------------|-------|
| AWS S3 | Supports server-side encryption with **your own KMS key (SSE-KMS)** as of February 2026 — use it, so the log archive carries the same key control as your data (control 3.2) |
| Google Cloud Storage | Added March 2026 |
| Azure Blob Storage | Added March 2026 |
| Datadog | Added March 2026 |
| Splunk | Added March 2026 |
| OpenTelemetry | Added March 2026 — use where you want a vendor-neutral pipeline into an existing collector |
| Atlas Data Federation | Query logs in place without moving them |

1. Navigate to: **Project** → **Integrations**
2. Select the destination and provide its credentials or role
3. For S3, configure SSE-KMS with a customer-managed key rather than accepting default encryption
4. Confirm logs arrive at the destination before you rely on the pipeline — a silently failing export is worse than no export, because it looks like coverage

---


{% include pack-code.html vendor="mongodb-atlas" section="4.1" %}

### 4.2 Monitor Atlas Activity Feed

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | AU-6 |

#### Description
Monitor Atlas Activity Feed for administrative and security events.

#### Rationale
**Why This Matters:**
- The Activity Feed records administrative actions — user logins, configuration changes, and access-list edits — that signal account compromise or misconfiguration
- Alerting on failed authentication attempts surfaces brute-force and credential-stuffing attempts before they succeed
- Alerting on configuration changes catches unauthorized modifications such as opening the IP access list or adding privileged users
- Continuous monitoring shortens detection and response time, limiting an attacker's dwell time

**Attack Prevented:** Account takeover, unauthorized configuration change, brute-force attempts, delayed incident response

#### ClickOps Implementation

**Step 1: Access Activity Feed**
1. Navigate to: **Project** → **Activity Feed**
2. Review recent events:
   - User authentication
   - Configuration changes
   - Alerts

**Step 2: Configure Alerts**
1. Navigate to: **Project** → **Alerts**
2. Create alerts for:
   - Failed authentication attempts
   - Configuration changes
   - Resource threshold violations

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Atlas Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | MFA for console | [2.2](#22-enable-multi-factor-authentication-for-atlas-console) |
| CC6.1 | Database users | [2.1](#21-configure-database-users-with-least-privilege) |
| CC6.6 | Network access | [1.1](#11-configure-ip-access-list) |
| CC6.7 | Encryption | [3.1](#31-verify-default-encryption) |
| CC7.2 | Auditing | [4.1](#41-enable-database-auditing) |

### NIST 800-53 Rev 5 Mapping

| Control | Atlas Control | Guide Section |
|---------|---------------|---------------|
| SC-7 | Network security | [1.1](#11-configure-ip-access-list), [1.2](#12-configure-vpc-peering-or-private-endpoints) |
| AC-6 | Least privilege | [2.1](#21-configure-database-users-with-least-privilege) |
| IA-2(1) | MFA | [2.2](#22-enable-multi-factor-authentication-for-atlas-console) |
| SC-28 | Encryption at rest | [3.1](#31-verify-default-encryption) |
| AU-2 | Auditing | [4.1](#41-enable-database-auditing) |

---

## Appendix A: Tier Compatibility

MongoDB has restructured the Atlas tier model. The current tiers are **Free**, **Flex**, and **Dedicated**:

- **Free** — the tier previously known as M0, now branded "Free cluster"
- **Flex** — supersedes the former M2 and M5 shared tiers
- **Dedicated** — M10 and above
- **Serverless** — creation of new Serverless instances was **removed on 2025-10-22**; Flex is the replacement for that workload shape

| Feature | Free | Flex | Dedicated (M10+) |
|---------|------|------|------------------|
| IP Access List | ✅ | ✅ | ✅ |
| Atlas Resource Policies (org-level) | ✅ | ✅ | ✅ |
| VPC Peering | ❌ | ❌ | ✅ |
| Private Endpoints | ❌ | ❌ | ✅ |
| CMK Encryption | ❌ | ❌ | ✅ |
| Database Auditing | ❌ | ❌ | ✅ |
| Database Access Tracking | ❌ | ❌ | ✅ |
| Backup Compliance Policy | ❌ | ❌ | ✅ |
| X.509 Certificate Authentication | ❌ | ❌ | ✅ |

> **Flex clusters do not support the private-connectivity, key-management, or auditing controls in this guide.** If a workload requires controls 1.2, 3.2, 3.4, or 4.1, it requires a Dedicated cluster — the hardening posture is a tier decision, not only a configuration decision.

References: [Free cluster limitations](https://www.mongodb.com/docs/atlas/reference/free-shared-limitations/) · [Flex cluster limitations](https://www.mongodb.com/docs/atlas/reference/flex-limitations/)

---

## Appendix B: References

**Official MongoDB Documentation:**
- [MongoDB Atlas Product Documentation](https://www.mongodb.com/docs/atlas/)
- [Atlas Security Features](https://www.mongodb.com/docs/atlas/setup-cluster-security/)
- [Network Security Guidance](https://www.mongodb.com/docs/atlas/architecture/current/network-security/)
- [Security Checklist](https://www.mongodb.com/docs/manual/administration/security-checklist/)
- [Atlas Resource Policies](https://www.mongodb.com/docs/atlas/atlas-resource-policies/)
- [Backup Compliance Policy](https://www.mongodb.com/docs/atlas/backup/cloud-backup/backup-compliance-policy/)
- [Configure Atlas Administration API Access](https://www.mongodb.com/docs/atlas/configure-api-access/)
- [Multi-Factor Authentication](https://www.mongodb.com/docs/atlas/security-multi-factor-authentication/)
- [Configure Database Authentication](https://www.mongodb.com/docs/atlas/security/config-db-auth/)
- [Atlas User Roles](https://www.mongodb.com/docs/atlas/reference/user-roles/)

**API Documentation:**
- [MongoDB Atlas Administration API](https://www.mongodb.com/docs/atlas/api/)
- [MongoDB Drivers and SDKs](https://www.mongodb.com/docs/drivers/)

**Compliance Frameworks:**
- MongoDB states Atlas holds SOC 2 Type II, ISO/IEC 27001:2022, ISO 27017, ISO 27018, ISO 9001, PCI DSS v4.0, and CSA STAR Level 2. Obtain current attestation reports directly from MongoDB under NDA — certifications describe MongoDB's own posture, not your configuration.
- [MongoDB Atlas Compliance Features](https://www.mongodb.com/docs/atlas/architecture/current/compliance/) — the configurable features that support your compliance obligations

**Hardening Benchmarks:**
- [CIS MongoDB 8 Benchmark v1.0.0](https://www.cisecurity.org/benchmark/mongodb)

  > **Scope note:** the CIS MongoDB benchmark targets the **self-managed MongoDB server** — operating-system hardening, `mongod` configuration file settings, filesystem permissions, and process-level auditing. It does **not** cover the Atlas control plane, and most of its recommendations are either not applicable to a managed deployment or already enforced by Atlas. Use it for self-managed MongoDB; use this guide for Atlas.

**Security Incidents:**
- **Corporate Systems Breach (December 2023):** MongoDB detected unauthorized access to corporate systems on December 13, 2023 via a phishing attack. Customer names, phone numbers, email addresses, and account metadata were exposed. One customer's system logs were accessed. MongoDB Atlas cluster data was NOT affected — the attackers never accessed Atlas clusters or the Atlas authentication system. — [MongoDB Security Incident Update](https://www.mongodb.com/company/blog/news/mongodb-security-incident-update-december-20-2023)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass. Repaired the cheat-sheet parser contract by adding missing Attack Prevented lines to 1.1, 1.2, 2.1, 3.2, and 3.3. New controls: 1.3 Atlas Resource Policies, 2.5 Administration API hardening, 3.4 Backup Compliance Policy (section 3 retitled Encryption & Data Protection to host it). Corrected 2.2 for SMS deprecation and the current factor list, 2.1 for the MongoDB 8.0 LDAP deprecation plus OIDC Workforce/Workload Identity Federation, and 2.4 with the full org/project role tables and the Project Access Manager escalation path. Added AWS public-IPv4 rotation and M10/M20 connection-rate callouts, expanded 4.1 log push destinations, rewrote Appendix A for the Free/Flex/Dedicated tier model, removed Trust Center and compliance-report-request references, and re-cited CIS as the MongoDB 8 Benchmark v1.0.0 with an Atlas scope note. Tier 3/4 research not surveyed this pass. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with network, authentication, and encryption controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
