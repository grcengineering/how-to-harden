---
layout: guide
title: "Databricks Hardening Guide"
vendor: "Databricks"
slug: "databricks"
tier: "2"
category: "Data"
description: "Data platform security for workspace access, Unity Catalog, and secrets management"
version: "0.3.0"
maturity: "draft"
last_updated: "2026-08-03"
---


## Overview

Databricks serves **10,000+ customers** with Unity Catalog governing data lake access. OAuth federation with Snowflake, service principal credentials, and cluster access tokens create attack vectors. Databricks workspaces contain raw enterprise data, ML models, and training datasets making them high-value targets for data exfiltration and IP theft.

### Intended Audience
- Security engineers hardening data platforms
- Data engineers configuring Databricks
- GRC professionals assessing data governance
- Third-party risk managers evaluating analytics integrations

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Databricks security configurations including authentication, Unity Catalog governance, cluster security, and secrets management.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Unity Catalog Security](#2-unity-catalog-security)
3. [Cluster Security](#3-cluster-security)
4. [Secrets Management](#4-secrets-management)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | IA-2(1) |

#### Description
Require SAML SSO with MFA for all Databricks access.

#### Rationale
**Why This Matters:**
- Centralizes Databricks authentication in your corporate IdP, enforcing MFA and conditional access on every login
- Local password logins bypass IdP controls and are a prime target for credential stuffing and phishing
- SCIM provisioning deprovisions departed users automatically, eliminating orphaned accounts with standing data access
- Workspaces hold raw enterprise data, ML models, and training datasets — a single compromised login can expose all of it

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Admin Settings → Identity and Access → Single Sign-On**
2. Configure:
   - **IdP Entity ID:** From your identity provider
   - **SSO URL:** IdP login endpoint
   - **Certificate:** Upload IdP certificate

**Step 2: Enforce SSO**
1. Enable: **Require users to log in with SSO**
2. Disable: **Allow local password login**

**Step 3: Configure SCIM Provisioning**
1. Navigate to: **Admin Settings → Identity and Access → SCIM Provisioning**
2. Configure connector with your IdP
3. Enable: **Automatic user provisioning**

{% include pack-code.html vendor="databricks" section="1.1" %}

---

### 1.2 Implement Service Principal Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | IA-5 |

#### Description
Secure the machine identities and API tokens used for automation and integrations. Authenticate service principals with OAuth rather than personal access tokens (PATs), and where a PAT is unavoidable, restrict it to the API scopes the workload actually needs.

#### Rationale
**Why This Matters:**
- Service principals hold standing programmatic access to the lakehouse, so a leaked credential is a bulk data-access credential
- Personal access tokens are bearer credentials with no built-in expiry discipline, while OAuth machine-to-machine credentials are short-lived and issued against a client secret you can rotate centrally
- An unscoped PAT can call every workspace API its owner can reach, so a token leaked from a CI log grants far more than the job it was issued for
- Scoped PATs confine a stolen token to a named set of APIs, turning a full-workspace compromise into a narrow one
- Tokens outlive their purpose silently — an enforced maximum lifetime and a periodic review are what stop the sprawl

**Attack Prevented:** Service principal credential theft, token replay against unrelated APIs, privilege escalation via over-scoped tokens, bulk exfiltration through a compromised automation identity

**Attack Scenario:** Compromised service principal accesses data lakehouse; malicious notebook executes data exfiltration.

#### ClickOps Implementation

**Step 1: Create Purpose-Specific Service Principals**
1. Navigate to: **Admin Settings → Identity and Access → Service Principals**
2. Create principals for each integration:
   - `svc-etl-pipeline` (ETL jobs)
   - `svc-ml-training` (ML workloads)
   - `svc-reporting` (BI tools)

**Step 2: Assign Minimal Permissions**
1. Navigate to: **Unity Catalog → Grants**
2. For each service principal:
   - Grant only required catalogs
   - Grant only required schemas
   - Prefer SELECT over ALL PRIVILEGES

**Step 3: Prefer OAuth Over Personal Access Tokens**
1. Issue OAuth machine-to-machine credentials to each service principal and use those for automation. Databricks positions OAuth as the preferred mechanism and personal access tokens as the legacy path ([PAT authentication](https://docs.databricks.com/aws/en/dev-tools/auth/pat)).
2. Where a PAT is genuinely unavoidable, create it as a **scoped** PAT (GA April 2026) limited to the named API scopes the workload calls — for example `sql` for warehouse queries, `unity-catalog` for catalog operations, or `scim` for directory sync.
3. Grant the `authentication` scope sparingly. A token holding it can mint further credentials, which collapses the benefit of scoping everything else.
4. Tokens created with a lifetime of 30 days or more are auto-scoped by the platform, so long-lived tokens no longer carry unrestricted API access by default. Do not rely on this alone — set the scopes explicitly.
5. Store every token in a secrets manager (Section 4) and rotate on a documented schedule.

**Step 4: Constrain Token Lifetime and Availability**
1. Navigate to: **Workspace admin settings → Advanced** and set the maximum personal access token lifetime so no token can outlive your rotation window.
2. Once every workload has migrated to OAuth, disable personal access token authentication for the workspace entirely. This removes PATs as an attack path rather than merely shrinking it.
3. The platform automatically revokes any PAT unused for 90 days. Treat that as a backstop against forgotten tokens, not as a lifecycle policy.
4. Review the token inventory each quarter and revoke anything without a named owner and a documented purpose.

#### Validation & Testing
1. Enumerate active tokens and confirm each maps to a named owner, a workload, and an expiry inside your rotation window
2. Confirm the workspace maximum token lifetime is set, then attempt to create a token exceeding it and verify the request is rejected
3. Call an API outside a scoped PAT's granted scopes (for example a SCIM call with a `sql`-only token) and confirm it is refused
4. Confirm no service principal is still authenticating with a PAT by reviewing `system.access.audit` for token-based authentication events attributed to machine identities
5. Verify each service principal's Unity Catalog grants match the minimum required for its workload

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| CIS Controls v8 | 5.4 | Restrict administrator privileges to dedicated administrator accounts |
| CIS Controls v8 | 6.8 | Define and maintain role-based access control |
| NIST 800-53 Rev 5 | IA-5 | Authenticator management, including lifetime and rotation |
| NIST 800-53 Rev 5 | AC-6(1) | Authorize access to security functions on a least-privilege basis |
| SOC 2 | CC6.1 | Logical access credentials are restricted and managed |

{% include pack-code.html vendor="databricks" section="1.2" %}

---

### 1.3 Configure IP Access Lists

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3(7) |

#### Description
Restrict Databricks access to known IP ranges.

#### Rationale
**Why This Matters:**
- Restricting access to known corporate, VPN, and integration IP ranges blocks logins from unexpected networks even when credentials are valid
- Public workspace endpoints are continuously scanned and brute-forced by automated attackers
- IP allowlists add a network-layer control that complements identity-layer SSO/MFA (defense in depth)
- Stolen tokens or API keys are far less useful to an attacker operating outside the allowed network

**Attack Prevented:** Credential reuse from untrusted networks, token replay, automated endpoint scanning

#### ClickOps Implementation

**Step 1: Configure IP Access Lists**
1. Navigate to: **Admin Settings → Security → IP Access Lists**
2. Add allowed IP ranges:
   - Corporate network
   - VPN egress
   - Approved integration IPs
3. Enable: **Block public access** (L2)

{% include pack-code.html vendor="databricks" section="1.3" %}

---

## 2. Unity Catalog Security

### 2.1 Implement Data Governance

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3 |

#### Description
Configure Unity Catalog for centralized data governance.

#### Rationale
**Why This Matters:**
- Unity Catalog provides a single, centralized permission model across all workspaces, replacing inconsistent per-workspace ACLs
- Without centralized governance, access grants sprawl and over-permissioning goes undetected
- Catalog-, schema-, and table-level grants enforce least privilege and make access reviews tractable
- Row- and column-level controls limit the blast radius if an account or query is compromised

**Attack Prevented:** Over-permissioned access, privilege sprawl, unauthorized data exposure, lateral movement across data domains

#### ClickOps Implementation

**Step 1: Create Catalog Structure**

Create catalogs by environment (production, staging, development) and schemas by domain. See the DB Query Code Pack below for the full SQL.

**Step 2: Configure Granular Permissions**

Grant specific catalog, schema, and table permissions to functional roles. See the DB Query Code Pack below for permission examples.

**Step 3: Enable Column-Level Security**

Create row filter functions to restrict data visibility by group membership and apply them to tables. See the DB Query Code Pack below.

{% include pack-code.html vendor="databricks" section="2.1" %}

---

### 2.2 Configure Data Masking

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SC-28 |

#### Description
Implement dynamic data masking for sensitive columns. Create masking functions that return the full value for privileged roles and masked values for all others, then apply them to sensitive columns.

#### Rationale
**Why This Matters:**
- Dynamic masking returns real values only to privileged roles, so analysts and BI tools can work without exposing PII/PHI
- Sensitive columns (SSNs, card numbers, health data) are a primary exfiltration target and a regulatory liability
- Masking enforced in Unity Catalog applies consistently across every query path, not just curated dashboards
- Reduces the impact of a compromised low-privilege account or an overly broad query

**Attack Prevented:** PII/PHI exposure, data exfiltration via ad-hoc queries, insider snooping

#### Scale Enforcement with Unity Catalog ABAC

Row filters and column masks attached table-by-table are correct but they do not scale: every new table is unprotected until someone remembers to attach the function, and coverage drifts the moment a data engineer ships a table you did not know about.

Unity Catalog **attribute-based access control (ABAC)** reached GA in April 2026 and fixes that structurally. A `CREATE POLICY` statement defines a row filter or a column mask once and attaches it at the **catalog, schema, or table** level, where it evaluates governed tags rather than named columns. Tag a new column as PII and the existing policy masks it automatically — enforcement follows the data classification instead of the table inventory. Full syntax and the supported tag predicates are in the [Unity Catalog ABAC documentation](https://docs.databricks.com/aws/en/data-governance/unity-catalog/abac/).

**Step 1: Establish Governed Tags**
1. Define the governed tags that describe your sensitive data classes (for example a PII or PHI tag with a controlled set of allowed values).
2. Apply the tags to sensitive columns, and make tagging part of the table-creation workflow so new columns arrive already classified.

**Step 2: Attach Policies at the Highest Sensible Level**
1. Create the row filter or column mask policy with `CREATE POLICY`, attached at the catalog or schema that covers the whole data domain rather than at each table.
2. Scope the policy's exemptions to the privileged groups that legitimately need unmasked values, mirroring the function-based grants you already use.
3. Retain the per-table functions until the equivalent policy is verified in place, then remove them so there is one enforcement path rather than two.

**Step 3: Note the Coverage Gap**
1. `GRANT` policies for **models** remain in Beta — do not treat ABAC as complete coverage for registered models, and keep explicit model grants in place until that reaches GA.

{% include pack-code.html vendor="databricks" section="2.2" %}

---

### 2.3 Audit Logging for Data Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AU-2, AU-3 |

#### Description
Enable comprehensive audit logging for data access.

#### Rationale
**Why This Matters:**
- Audit logs of data access are required to detect bulk exports, unusual query patterns, and credential misuse
- Without logging, a breach is invisible and forensic reconstruction after an incident is impossible
- System tables provide a queryable trail for compliance evidence (SOC 2, HIPAA, PCI DSS)
- Retained logs support anomaly detection and alerting on service-principal and human access alike

**Attack Prevented:** Undetected data exfiltration, insider abuse, post-incident evidence gaps

#### ClickOps Implementation

**Step 1: Enable System Tables**
1. Navigate to: **Admin Settings → System Tables**
2. Enable: **Access audit logs**
3. Configure retention period

**Step 2: Enable Verbose Audit Logs**
1. Navigate to: **Workspace admin settings → Advanced** and enable **Verbose Audit Logs** (the `enableVerboseAuditLogs` setting).
2. Without it, the audit trail records **that** a notebook command or SQL query ran but not **what it did** — you can see a user queried a warehouse at 02:14 and never learn which table they read. With it enabled, Databricks emits additional notebook, jobs, and SQL command events carrying the `commandText` field ([verbose audit logs](https://docs.databricks.com/aws/en/admin/account-settings/verbose-logs)).
3. Plan for the consequences: event volume rises, and `commandText` can itself contain sensitive values (literals in `WHERE` clauses, inline credentials in ad-hoc code). Restrict read access to the audit tables accordingly and account for the extra retention cost.

**Step 3: Query Audit Logs**

Query the `system.access.audit` table to review data access events. See the DB Query Code Pack below for the full audit log query.

{% include pack-code.html vendor="databricks" section="2.3" %}

---

## 3. Cluster Security

### 3.1 Configure Cluster Policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | CM-7 |

#### Description
Implement cluster policies to enforce security configurations.

#### Rationale
**Why This Matters:**
- Cluster policies constrain Spark versions, node types, and init scripts so users cannot spin up insecure or unapproved compute
- Unrestricted init scripts are an arbitrary-code-execution path into the data plane
- Enforced auto-termination limits the window an idle, credential-bearing cluster stays exposed
- Policies make secure configuration the default, removing reliance on individual user discipline

**Attack Prevented:** Malicious init-script execution, unapproved or insecure compute, runaway-cluster credential exposure

#### ClickOps Implementation

**Step 1: Create Secure Cluster Policy**
1. Navigate to: **Compute --> Policies --> Create Policy**
2. Configure the cluster policy JSON to restrict allowed Spark versions, node types, auto-termination, and init scripts. See the Code Pack below for the full policy definition.

**Step 2: Assign Policy to Users**
1. Navigate to: **Admin Settings → Workspace → Cluster Policies**
2. Assign policy to appropriate groups
3. Set as default for users

{% include pack-code.html vendor="databricks" section="3.1" %}

---

### 3.2 Network Isolation

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SC-7 |

#### Description
Deploy Databricks with network isolation.

#### Rationale
**Why This Matters:**
- Customer-managed VPC/VNet deployment keeps the data plane off the public internet, shrinking the external attack surface
- Private endpoints ensure traffic to storage and the control plane never traverses public networks
- Disabling public cluster IPs prevents direct inbound access to compute nodes
- Network isolation contains lateral movement if a single workload is compromised

**Attack Prevented:** Public-internet exposure of compute, data-plane interception, lateral movement

#### Implementation

**VPC/VNet Deployment:**
1. Deploy workspace in customer-managed VPC
2. Configure private endpoints
3. Disable public IP addresses for clusters

The account-level Terraform example for private workspace deployment with VPC isolation is included in the Code Pack below.

{% include pack-code.html vendor="databricks" section="3.2" %}

---

### 3.3 Enable the Compliance Security Profile

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 7.3 |
| NIST 800-53 | CM-6, SC-13, SI-2 |

#### Description
Turn on the compliance security profile so the workspace runs a CIS-hardened base image with FIPS 140-2 validated cryptography, AWS Nitro instance types, and TLS 1.2 or higher. Enabling it also switches on enhanced security monitoring and automatic cluster update, and lets you attach the compliance standards your data requires. This is an Enterprise-tier capability (the Enhanced Security and Compliance add-on).

#### Rationale
**Why This Matters:**
- A default workspace runs stock compute images with no hardening baseline; the compliance security profile replaces them with CIS-hardened images and enforces FIPS 140-2 validated encryption for data in transit and at rest
- Enhanced security monitoring adds antivirus, file integrity monitoring, and behaviour-based intrusion detection inside the compute plane — telemetry you cannot reconstruct after an incident
- Automatic cluster update restarts long-running compute inside a maintenance window so hosts actually take platform patches; a cluster left up for months is an unpatched host holding live data credentials
- Attaching a standard (HIPAA, PCI-DSS, FedRAMP, IRAP, C5, TISAX, or IL5) is what makes the workspace eligible to hold that class of regulated data — without it the platform offers no such assurance, however well configured the workspace is otherwise
- Restricting compute to Nitro instance types removes older virtualisation from the data plane, where memory isolation guarantees are weaker

**Attack Prevented:** Exploitation of unpatched long-running compute, downgrade to weak or non-validated cryptography, undetected malware and file tampering inside the compute plane

#### ClickOps Implementation

**Step 1: Validate Compatibility Before You Commit**
1. Enabling the compliance security profile is intended to be **permanent** — Databricks does not support turning it back off on a workspace, so treat it as a one-way door ([enhanced security and compliance](https://docs.databricks.com/aws/en/security/privacy/enhanced-security-compliance)).
2. Test in a non-production workspace first. Confirm your jobs run on the Databricks Runtime versions the profile permits and that no workload depends on an instance type outside the Nitro family.
3. Inventory anything pinned to an old runtime or a legacy instance type and migrate it before you enable.

**Step 2: Enable on a Workspace**
1. Navigate to: **Account Console → Workspaces → [workspace] → Security and compliance**.
2. Enable the **compliance security profile**. Enhanced security monitoring and automatic cluster update are enabled with it.
3. Add the compliance standards that apply to the data the workspace holds — HIPAA, PCI-DSS, FedRAMP, IRAP, C5, TISAX, HITRUST, or IL5. Attach only the standards you actually need; each one adds constraints.
4. Restart existing clusters so they relaunch on the hardened image.

**Step 3: Set the Account-Wide Default**
1. Navigate to: **Account Console → Security → Enhanced security and compliance**.
2. Set the compliance security profile as the account-wide default so newly created workspaces inherit it rather than starting unhardened and waiting for someone to remember.
3. Record which standards the default applies, and review that list whenever your regulatory scope changes.

**Step 4: Operate Automatic Cluster Update**
1. Configure the maintenance window so forced restarts land outside your critical job schedules.
2. Make jobs restart-tolerant — checkpoint long-running streams rather than assuming a cluster lives forever.

#### Validation & Testing
1. Reopen **Account Console → Workspaces → [workspace] → Security and compliance** and confirm the profile shows as enabled with exactly the standards you intended
2. Launch a cluster and confirm it starts on a permitted runtime and a Nitro instance type; attempt to launch on a non-Nitro type and confirm it is rejected
3. Confirm enhanced security monitoring events are arriving at your configured log delivery destination and are being ingested by your SIEM
4. Confirm the automatic cluster update maintenance window is set, then observe a scheduled restart complete without job failures
5. Re-run a representative production job after enabling and compare runtime and results against the pre-enablement baseline

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| CIS Controls v8 | 4.1 | Establish and maintain a secure configuration process |
| CIS Controls v8 | 7.3 | Perform automated operating system patch management |
| NIST 800-53 Rev 5 | CM-6 | Configuration settings enforced against a hardened baseline |
| NIST 800-53 Rev 5 | SC-13 | Use of FIPS-validated cryptographic modules |
| NIST 800-53 Rev 5 | SI-2 | Flaw remediation through timely patching |
| SOC 2 | CC6.8 | Controls to prevent or detect unauthorized or malicious software |

---

### 3.4 Disable Legacy Features

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.8 |
| NIST 800-53 | CM-7, CM-7(1) |

#### Description
Turn off the legacy platform surfaces that sit outside the Unity Catalog governance model: DBFS root and mounts, the legacy Hive metastore, no-isolation shared clusters, and Databricks Runtime versions below 13.3 LTS.

#### Rationale
**Why This Matters:**
- DBFS root and mounts store data and credentials outside Unity Catalog, so anything reachable through a mount is readable by every user of the workspace regardless of the catalog grants configured in Section 2
- The legacy Hive metastore has no fine-grained access control — leaving it available is a standing bypass around the entire permission model this guide builds
- No-isolation shared clusters run every user's code in one JVM under a single identity, so one user can read another user's credentials and data straight out of memory
- Databricks Runtime versions below 13.3 LTS are out of support and do not enforce current isolation and credential behaviour, so they are the runtime an attacker will choose if you let them
- Legacy paths are rarely used deliberately; they are used accidentally, which is exactly why an account-level block beats a policy document

**Attack Prevented:** Governance bypass through ungoverned mounts and Hive tables, cross-user credential and data theft on shared compute, exploitation of unsupported runtimes

#### ClickOps Implementation

**Step 1: Check Whether the Setting Applies to You**
1. Accounts created after **19 December 2025** ship with legacy features already disabled and do not expose this setting — verify the state rather than trying to configure it ([disable legacy features](https://docs.databricks.com/aws/en/admin/account-settings/legacy-features)).
2. For older accounts, continue with Step 2.

**Step 2: Disable Legacy Features Account-Wide**
1. Navigate to: **Account Console → Settings → Feature enablement**.
2. Enable the legacy feature disablement setting. Workspaces created after this point block DBFS root and mounts, the Hive metastore, no-isolation shared clusters, and Databricks Runtime versions below 13.3 LTS.
3. Note the limit clearly: this governs **new** workspaces. Existing workspaces are untouched, which is what Step 3 is for.

**Step 3: Disable DBFS Root and Mounts on Existing Workspaces**
1. Inventory the notebooks, jobs, and init scripts that reference `dbfs:/` paths, and migrate them to Unity Catalog volumes or external locations first. Enabling this before migration breaks those workloads.
2. For each existing workspace, navigate to: **Workspace admin settings → Security** and enable **Disable DBFS root and mounts**.

**Step 4: Retire the Remaining Legacy Surfaces**
1. Migrate Hive metastore tables into Unity Catalog and repoint the jobs that read them.
2. Convert any cluster using the **No isolation shared** access mode to a standard or dedicated access mode.
3. Set the cluster policies from Section 3.1 to permit only Databricks Runtime 13.3 LTS and above, so new compute cannot select an unsupported runtime even where the account setting does not reach.

#### Validation & Testing
1. Confirm the legacy feature disablement setting reads as enabled under **Account Console → Settings → Feature enablement** (or confirm your account post-dates the cutover and has it off by default)
2. From a notebook in a workspace where DBFS is disabled, attempt `dbutils.fs.ls("dbfs:/")` and confirm the call is rejected
3. Attempt to create a cluster with the **No isolation shared** access mode and confirm the option is unavailable
4. Attempt to create a cluster on a Databricks Runtime below 13.3 LTS and confirm it is blocked
5. Review job definitions and query history for any remaining reference to `hive_metastore` and confirm each has an owner and a migration date

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| CIS Controls v8 | 4.8 | Uninstall or disable unnecessary services on enterprise assets |
| NIST 800-53 Rev 5 | CM-7 | Least functionality — prohibit unnecessary services and functions |
| NIST 800-53 Rev 5 | CM-7(1) | Periodic review to disable unnecessary functions and services |
| NIST 800-53 Rev 5 | AC-6 | Least privilege enforced through the governed access path |
| SOC 2 | CC6.1 | Logical access controls restrict access to authorized users |

---

### 3.5 Restrict Serverless Egress with Network Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 12.2, 13.4 |
| NIST 800-53 | SC-7, SC-7(5), AC-4 |

#### Description
Apply an account-level serverless network policy that sets internet access to `RESTRICTED_ACCESS`, allowlisting Unity Catalog external locations and a named set of FQDNs. Serverless compute does not run in your VPC, so the customer-managed VPC and private endpoints in Section 3.2 do not constrain it — a network policy is the **only** egress control that applies to serverless SQL warehouses, jobs, and notebooks.

#### Rationale
**Why This Matters:**
- The default internet access mode is `FULL_ACCESS`, meaning serverless notebook and job code can reach any destination on the internet — an exfiltration path that bypasses every network control you built for the classic compute plane
- A single compromised library, or one line in a notebook, can post query results to an attacker-controlled endpoint with no network device anywhere in the path to observe or stop it
- `RESTRICTED_ACCESS` denies general internet egress while still permitting access to Unity Catalog-governed storage, so ordinary analytics continues to work
- Allowlisting named FQDNs turns every external dependency into an explicit, reviewable decision instead of an assumption
- Teams frequently harden classic compute and forget serverless entirely, leaving the newest and fastest-growing compute surface as the least controlled one

**Attack Prevented:** Data exfiltration from serverless compute, command-and-control callbacks from malicious or compromised libraries, unreviewed third-party data flows

#### ClickOps Implementation

**Step 1: Create or Edit the Network Policy**
1. Navigate to: **Account Console → Settings → Network Policies**.
2. Every account has a `default-policy` that applies to workspaces with no explicit policy assigned. Either create a dedicated policy for the workspaces you are restricting, or tighten the default.
3. Set internet access to `RESTRICTED_ACCESS`. The shipped default is `FULL_ACCESS` ([serverless network policies](https://docs.databricks.com/aws/en/security/network/serverless-network-security/network-policies)).

**Step 2: Allowlist the Destinations You Actually Need**
1. Enable access to your Unity Catalog external locations so serverless compute can still read governed cloud storage.
2. Add each remaining destination as a named FQDN — a package registry, a partner API, an internal service. Enumerate hosts rather than reaching for broad ranges.
3. Keep the list short and reviewed. Every entry is a permitted exfiltration destination as well as a permitted dependency.

**Step 3: Dry-Run Before Enforcing**
1. Put the policy in dry-run mode first. Databricks logs what would have been blocked without actually breaking anything.
2. Run a full cycle of serverless jobs, dashboards, and interactive notebooks — including month-end and other infrequent workloads — then review what the dry run flagged.
3. Add the legitimate destinations that surfaced, and investigate anything you cannot account for before you allowlist it.
4. Switch to enforcement once a dry-run cycle comes back clean.

**Step 4: Bind the Policy to Every Workspace**
1. Assign the policy to each workspace running serverless workloads. A workspace with no explicit assignment falls back to the account default, so confirm that default is also restricted.
2. Add policy assignment to your workspace provisioning checklist so new workspaces do not start with unrestricted egress.

#### Validation & Testing
1. From a serverless notebook, attempt an outbound request to a host that is not allowlisted and confirm it fails
2. Attempt a request to an allowlisted FQDN and confirm it succeeds — this distinguishes a working policy from a broken network
3. Run a serverless SQL warehouse query against a Unity Catalog external location and confirm governed storage access is unaffected
4. Enumerate workspaces and confirm each one running serverless workloads has an explicitly assigned policy rather than relying on an unreviewed default
5. Re-run dry-run mode after onboarding any new serverless workload, and review the findings before widening the allowlist

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| CIS Controls v8 | 12.2 | Establish and maintain a secure network architecture |
| CIS Controls v8 | 13.4 | Perform traffic filtering between network segments |
| NIST 800-53 Rev 5 | SC-7 | Boundary protection at managed interfaces |
| NIST 800-53 Rev 5 | SC-7(5) | Deny network traffic by default and allow by exception |
| NIST 800-53 Rev 5 | AC-4 | Information flow enforcement between connected systems |
| SOC 2 | CC6.6 | Logical access controls restrict connections from outside system boundaries |

---

## 4. Secrets Management

### 4.1 Use Databricks Secret Scopes

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SC-28 |

#### Description
Store credentials in Databricks secret scopes rather than notebooks.

#### Rationale
**Why This Matters:**
- Hardcoding credentials in notebooks leaks them into source control, notebook revision history, and shared exports
- Secret scopes centralize credentials with ACLs and automatically redact values in cell output and logs
- Scope ACLs enforce least privilege so only the groups that need a credential can read it
- Centralized secrets enable rotation without editing every notebook that uses them

**Attack Prevented:** Credential leakage via notebooks and logs, secret sprawl, unauthorized credential access

#### ClickOps Implementation

**Step 1: Create Secret Scope**
1. Navigate to: **Databricks CLI** or **Admin Settings → Secrets**
2. Create a Databricks-backed secret scope for your environment
3. Add required secrets (database passwords, API keys)

**Step 2: Configure Access Controls**
1. Set ACLs on the secret scope
2. Grant READ access to groups that need credential access
3. Restrict MANAGE access to administrators only

**Step 3: Use Secrets in Notebooks**

Access secrets via `dbutils.secrets.get()` in notebooks. Secret values are automatically redacted in logs. See the SDK Code Pack below for an example.

{% include pack-code.html vendor="databricks" section="4.1" %}

---

### 4.2 External Secret Store Integration

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SC-28 |

#### Description
Integrate with external secrets managers.

#### Rationale
**Why This Matters:**
- Key Vault-backed scopes fetch secrets at runtime, so credentials are never stored inside Databricks
- Centralizing secrets in an enterprise vault gives one place for rotation, expiry, and access auditing
- External KMS/HSM-backed stores meet stricter compliance and key-custody requirements
- Revoking a secret in the vault instantly cuts access across every workspace that references it

**Attack Prevented:** Standing credential storage, fragmented secret management, delayed revocation

#### Azure Key Vault Integration

Create an Azure Key Vault-backed secret scope so secrets are fetched directly from Key Vault at runtime rather than stored in Databricks. This provides centralized secret lifecycle management and audit logging through Azure.

{% include pack-code.html vendor="databricks" section="4.2" %}

---

### 4.3 Configure Customer-Managed Encryption Keys

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12, SC-13, SC-28(1) |

#### Description
Supply your own cloud KMS keys for the two encryption scopes Databricks exposes: **managed services**, which covers control-plane data Databricks stores on your behalf, and **workspace storage**, which covers the workspace bucket. This is an Enterprise-tier capability.

#### Rationale
**Why This Matters:**
- The managed services key covers the highest-sensitivity artifacts on the platform — notebook source and results, secrets held in Databricks-backed scopes, SQL query history, dashboards, and Git personal access tokens — all of which live in the control plane rather than in your account
- The workspace storage key covers the workspace bucket including the DBFS root and job results, and can optionally extend to cluster EBS volumes
- Holding the key means you can revoke unilaterally: disabling it renders the data unreadable even to the platform, which is the specific assurance regulators and enterprise customers ask for
- Key rotation and key-usage logging happen in your own KMS, producing an audit trail of cryptographic operations that does not depend on the vendor's word
- Unity Catalog default storage and Model Serving reached GA for customer-managed keys in April 2026, closing the two coverage gaps that previously forced exceptions ([customer-managed keys](https://docs.databricks.com/aws/en/security/keys/customer-managed-keys))

**Attack Prevented:** Exposure of control-plane-held notebooks, secrets, and query history; inability to revoke platform access after a compromise; key-custody audit findings in regulated environments

#### ClickOps Implementation

**Step 1: Create the Keys in Your Cloud KMS**
1. Create a symmetric key in the same region as the workspace (AWS KMS, Azure Key Vault, or Google Cloud KMS depending on your deployment).
2. Grant the Databricks service principal or role only the key operations the documented use case requires, and keep the key policy narrow — a permissive key policy undoes the point of holding the key.
3. Enable automatic key rotation and key-usage logging before the key is put into service.

**Step 2: Add the Managed Services Key**
1. Navigate to: **Account Console → Workspaces → [workspace] → Encryption**, or configure the key at workspace creation.
2. Add the managed services key. It encrypts notebook source and results, Databricks-backed secrets, SQL query history, dashboards, and stored Git credentials.

**Step 3: Add the Workspace Storage Key**
1. Add the workspace storage key to encrypt the workspace bucket, including the DBFS root and job results.
2. Optionally extend the same key to cluster EBS volumes. Clusters must be restarted before the change takes effect, so plan the restart alongside the change.

**Step 4: Make Revocation an Operable Lever**
1. Document the revocation procedure explicitly. Disabling the key or scheduling its deletion makes the workspace unusable — that is an incident-response action, not routine maintenance, and it needs a named approver.
2. Alert on key policy changes and on disable or scheduled-deletion events in your KMS. An attacker who can alter the key policy has neutralised the control.
3. Confirm the key's rotation schedule matches your cryptographic policy and that rotation does not require a workspace outage.

#### Validation & Testing
1. Confirm the workspace's Encryption page lists both keys with the key identifiers you expect
2. Create a notebook and a secret, then confirm your KMS key-usage log shows decrypt operations from the Databricks principal
3. If EBS encryption is enabled, restart a cluster and confirm the new volumes are created under the configured key
4. In a non-production workspace, revoke the key, confirm access fails, then restore it — proving the revocation lever works before the day you need it
5. Confirm alerting fires on a test key-policy change

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| CIS Controls v8 | 3.11 | Encrypt sensitive data at rest |
| NIST 800-53 Rev 5 | SC-12 | Cryptographic key establishment and management |
| NIST 800-53 Rev 5 | SC-28(1) | Cryptographic protection of information at rest |
| SOC 2 | CC6.1 | Encryption protects stored data from unauthorized access |
| ISO 27001:2022 | A.8.24 | Use of cryptography, including key management |

---

## 5. Monitoring & Detection

### 5.1 Security Monitoring

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SI-4 |

#### Description
Continuously monitor Databricks for security-relevant events — bulk data access, unusual exports, and service-principal anomalies — and alert on suspicious activity.

#### Rationale
**Why This Matters:**
- Audit logs only provide value when actively monitored and alerted on; passive retention does not stop an in-progress breach
- Bulk-access and large-export patterns are the clearest signal of data exfiltration
- Service principals run unattended, so anomalous machine activity must be baselined and watched
- Early detection shrinks attacker dwell time and limits the volume of data lost

**Attack Prevented:** Undetected exfiltration, service-principal abuse, slow data theft

#### Detection Queries

Detection queries for bulk data access, unusual exports, and service principal anomalies are provided in the DB Query Code Pack below.

{% include pack-code.html vendor="databricks" section="5.1" %}

---

### 5.2 Run the Security Analysis Tool as a Recurring Self-Assessment

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 7.1 |
| NIST 800-53 | CA-7, RA-5 |

#### Description
Deploy the Databricks **Security Analysis Tool (SAT)** as a scheduled job that compares your account and workspace configuration against Databricks security best practices and reports the gaps.

#### Rationale
**Why This Matters:**
- Every control in this guide can be turned off by an administrator in a few clicks, and nothing in the platform tells you it happened — a recurring automated self-assessment is how configuration drift gets caught
- SAT is maintained by Databricks Industry Solutions and checks the same account and workspace settings this guide configures, so its findings map onto your control set rather than a generic benchmark
- Version 0.8.0 adds egress testing, which verifies the network restrictions in 3.2 and 3.5 actually block what you believe they block — the difference between a configured control and an effective one
- The same release adds per-user permissions analysis, surfacing individually granted permissions that quietly bypass your group-based access model, and expanded secret scanning for credentials sitting in notebooks instead of secret scopes
- Scheduled runs produce dated evidence for SOC 2, ISO, and internal audit without anyone assembling screenshots by hand

**Attack Prevented:** Silent control drift and unauthorized configuration change, undetected over-permissioning of individual users, credentials left in notebooks, egress restrictions that were never actually effective

#### ClickOps Implementation

**Step 1: Deploy SAT**
1. Deploy SAT from the [Databricks Security Analysis Tool repository](https://github.com/databricks-industry-solutions/security-analysis-tool) into a dedicated workspace, following the installation steps for your cloud.
2. Run it under a service principal with **read-only** access to the account and workspace configuration APIs. SAT does not need write access, and granting it write access creates a new privileged identity to defend.
3. Treat SAT as an advisory Industry Solutions project rather than a supported Databricks product — its findings inform your control review, they do not replace it.

**Step 2: Schedule and Triage**
1. Schedule the SAT job to run at least weekly.
2. Review the SAT dashboard after each run and triage findings against the control sections in this guide.
3. Track accepted findings formally with an owner and a review date. A finding that is silently ignored is indistinguishable from one that was never seen.

**Step 3: Turn On the v0.8.0 Checks**
1. Enable egress testing to validate the classic and serverless network restrictions from 3.2 and 3.5.
2. Enable per-user permissions analysis to find permissions granted directly to individuals outside your group model.
3. Enable expanded secret scanning to detect credentials in notebooks that belong in the secret scopes configured in Section 4.1.

#### Validation & Testing
1. Confirm the SAT job completed for the current period and produced a dashboard
2. Deliberately misconfigure a low-risk setting in a test workspace and confirm the next SAT run flags it — this proves the assessment is live rather than stale
3. Confirm the SAT service principal holds no write permissions on any workspace or account API
4. Confirm every open finding has a named owner and a target remediation date
5. Compare consecutive runs and confirm resolved findings stay resolved

#### Compliance Mappings

| Framework | Control | Requirement |
|-----------|---------|-------------|
| CIS Controls v8 | 4.1 | Establish and maintain a secure configuration process |
| CIS Controls v8 | 7.1 | Establish and maintain a vulnerability management process |
| NIST 800-53 Rev 5 | CA-7 | Continuous monitoring of security control effectiveness |
| NIST 800-53 Rev 5 | RA-5 | Vulnerability monitoring and scanning |
| SOC 2 | CC4.1 | Ongoing evaluations determine whether controls are operating effectively |

---

## 6. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Databricks Control | Guide Section |
|------------|--------------------|---------------|
| CC4.1 | Security Analysis Tool self-assessment | 5.2 |
| CC6.1 | SSO enforcement | 1.1 |
| CC6.1 | Token scoping and lifetime | 1.2 |
| CC6.1 | Customer-managed encryption keys | 4.3 |
| CC6.1 | Legacy feature disablement | 3.4 |
| CC6.2 | Unity Catalog permissions | 2.1 |
| CC6.6 | Serverless egress network policy | 3.5 |
| CC6.7 | Data masking and ABAC policies | 2.2 |
| CC6.8 | Compliance security profile | 3.3 |

---

## Appendix A: Edition Compatibility

| Control | Standard | Premium | Enterprise |
|---------|----------|---------|------------|
| SSO (SAML) | ❌ | ✅ | ✅ |
| Unity Catalog | ✅ | ✅ | ✅ |
| IP Access Lists | ❌ | ✅ | ✅ |
| Customer-Managed VPC | ❌ | ✅ | ✅ |
| Private Link | ❌ | ❌ | ✅ |
| Compliance Security Profile | ❌ | ❌ | ✅ |
| Customer-Managed Keys | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Databricks Documentation:**
- [Databricks Trust Center](https://www.databricks.com/trust)
- [Databricks Trust & Compliance](https://www.databricks.com/trust/compliance)
- [Databricks Documentation (AWS)](https://docs.databricks.com/aws/en/)
- [Security Best Practices](https://docs.databricks.com/aws/en/lakehouse-architecture/security-compliance-and-privacy/best-practices)
- [Security and Trust Center Report](https://www.databricks.com/trust/report)

**Platform Security Configuration:**
- [Enhanced Security and Compliance](https://docs.databricks.com/aws/en/security/privacy/enhanced-security-compliance) — compliance security profile, enhanced security monitoring, automatic cluster update
- [Disable Legacy Features](https://docs.databricks.com/aws/en/admin/account-settings/legacy-features) — DBFS root and mounts, Hive metastore, no-isolation clusters, runtime floor
- [Serverless Network Policies](https://docs.databricks.com/aws/en/security/network/serverless-network-security/network-policies) — egress control for serverless compute
- [Customer-Managed Keys](https://docs.databricks.com/aws/en/security/keys/customer-managed-keys) — managed services and workspace storage encryption
- [Unity Catalog ABAC](https://docs.databricks.com/aws/en/data-governance/unity-catalog/abac/) — tag-driven row filter and column mask policies
- [Personal Access Token Authentication](https://docs.databricks.com/aws/en/dev-tools/auth/pat) — OAuth versus PATs, scoped tokens, lifetime settings
- [Verbose Audit Logs](https://docs.databricks.com/aws/en/admin/account-settings/verbose-logs) — command-level audit events including `commandText`

**Security Assessment Tooling:**
- [Databricks Security Analysis Tool (SAT)](https://github.com/databricks-industry-solutions/security-analysis-tool) — recurring configuration self-assessment against Databricks best practices

**API Documentation:**
- [Databricks REST API](https://docs.databricks.com/api/workspace/introduction)
- [Databricks CLI](https://docs.databricks.com/dev-tools/cli/index.html)
- [Databricks SDKs](https://docs.databricks.com/dev-tools/sdks/index.html) (Python, Java, Go)
- [Terraform Provider](https://registry.terraform.io/providers/databricks/databricks/latest/docs)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001:2022, HIPAA, PCI DSS, FedRAMP Moderate (AWS SQL Serverless), HITRUST CSF (Azure) — via [Databricks Compliance](https://www.databricks.com/trust/compliance)

**Security Incidents:**
- No major public data breaches affecting Databricks customers have been identified. A platform vulnerability discovered by Orca Security in April 2023 was promptly remediated. Databricks maintains annual third-party penetration testing and a documented security incident response program.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-03 | 0.3.0 | draft | Currency update: compliance security profile + enhanced security monitoring, disable-legacy-features toggles, serverless network policies, customer-managed keys, Unity Catalog ABAC, scoped PATs + OAuth-first token guidance, verbose audit logs, Security Analysis Tool baseline | Claude Code (Sonnet 5) |
| 2026-06-29 | 0.2.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Databricks hardening guide | Claude Code (Opus 4.5) |
| 2026-02-19 | 0.2.0 | draft | Migrate all remaining inline code to Code Packs (sections 2.1, 2.2, 2.3, 3.1, 3.2, 4.1, 5.1); zero inline code blocks remain | Claude Code (Opus 4.6) |
| 2026-02-19 | 0.1.1 | draft | Migrate inline CLI code in sections 4.1, 4.2 to Code Pack files | Claude Code (Opus 4.6) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
