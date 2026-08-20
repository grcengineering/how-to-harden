---
layout: guide
title: "Snowflake Hardening Guide"
vendor: "Snowflake"
slug: "snowflake"
tier: "1"
category: "Data"
description: "Data warehouse security including network policies, MFA enforcement, and access controls"
version: "0.4.1"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

Snowflake is a cloud data platform whose **2024 breach affecting 165+ organizations** (AT&T, Ticketmaster, Santander) demonstrated catastrophic supply chain risk. Over **500+ million individuals** had data exposed via credential stuffing attacks on accounts without MFA. OAuth integrations with Tableau, Looker, and Power BI create broad access chains to sensitive data. AT&T paid $370,000 ransom, and 32 consolidated lawsuits are pending.

### Intended Audience
- Security engineers managing Snowflake security
- Data engineers configuring access controls
- GRC professionals assessing data platform compliance
- Third-party risk managers evaluating BI tool integrations

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries (VPS deployment)

### Scope
This guide covers Snowflake-specific security configurations including authentication, network policies, data sharing governance, and BI tool integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Network Access Controls](#2-network-access-controls)
3. [OAuth & Integration Security](#3-oauth--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce MFA for All Users

**Profile Level:** L1 (Crawl) - CRITICAL
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1), IA-2(2)

#### Description
Require multi-factor authentication for ALL Snowflake users. The 2024 breach was enabled by credential stuffing against accounts without MFA.

MFA is enforced through an **authentication policy** object, not through a standalone Snowsight toggle. Create the policy with `MFA_ENROLLMENT = 'REQUIRED'`, then attach it to the account. Snowflake's [authentication policy documentation](https://docs.snowflake.com/en/user-guide/authentication-policies) is the authoritative reference for the syntax and the allowed property values.

**Mandatory MFA rollout — this is an enforced default, not a recommendation.** Snowflake's [MFA rollout](https://docs.snowflake.com/en/user-guide/security-mfa-rollout) reaches **Phase 3 between August and October 2026**, at which point every human user must present a second factor with no exceptions available. Any users still carrying `TYPE = LEGACY_SERVICE` are automatically migrated to `TYPE = SERVICE` during this phase. Plan enrollment ahead of the phase window rather than waiting for enforcement to break logins.

#### Rationale
**Why This Matters:**
- 165+ organizations breached via simple credential stuffing
- No MFA = trivial account takeover
- MFA would have prevented 100% of 2024 breach victims
- Snowflake now enforces MFA for human users platform-wide, so an unenrolled workforce becomes a login outage rather than only a risk acceptance

**Attack Prevented:** Credential stuffing, password spray, account takeover

**Real-World Incidents:**
- **2024 Snowflake Breach:** UNC5537 threat actor used stolen credentials to access 165+ customer accounts. AT&T, Ticketmaster, Santander, LendingTree, and others affected. $370,000 ransom paid by AT&T. 500+ million individuals had data exposed.

#### Prerequisites
- ACCOUNTADMIN role access
- User inventory for enrollment tracking
- Communication plan for MFA rollout

#### ClickOps Implementation

> **Outdated path:** earlier versions of this guide pointed at an **Admin → Security → Authentication** toggle in Snowsight. That toggle is no longer the enforcement mechanism. MFA is enforced by creating an authentication policy object and attaching it to the account, as described below. Source: [Authentication policies](https://docs.snowflake.com/en/user-guide/authentication-policies).

**Step 1: Create the MFA Authentication Policy**
1. Navigate to: **Projects → Worksheets** (Snowsight) and open a worksheet running as ACCOUNTADMIN.
2. Create the policy: `CREATE AUTHENTICATION POLICY require_mfa MFA_ENROLLMENT = 'REQUIRED' MFA_POLICY = (ENFORCE_MFA_ON_EXTERNAL_AUTHENTICATION = 'ALL');`
3. `MFA_ENROLLMENT = 'REQUIRED'` forces every user the policy covers to enrol a second factor; `ENFORCE_MFA_ON_EXTERNAL_AUTHENTICATION = 'ALL'` extends the MFA requirement to federated and external-IdP logins so SSO does not become an MFA bypass.

**Step 2: Confirm the Policy Allows the Snowsight UI**
1. Review the policy's client list: `DESCRIBE AUTHENTICATION POLICY require_mfa;`
2. Ensure `CLIENT_TYPES` includes the Snowsight web UI — MFA enrollment happens there, so excluding it leaves users unable to enrol: `ALTER AUTHENTICATION POLICY require_mfa SET CLIENT_TYPES = ('SNOWFLAKE_UI', 'DRIVERS', 'SNOWSQL');`
3. `SNOWFLAKE_UI` is the value that covers Snowsight. If you scope `CLIENT_TYPES` down to drivers only, enrollment becomes impossible and the policy will lock the workforce out.

**Step 3: Attach the Policy to the Account**
1. Apply the policy account-wide: `ALTER ACCOUNT SET AUTHENTICATION POLICY require_mfa;`
2. Confirm the attachment: `SHOW PARAMETERS LIKE 'AUTHENTICATION_POLICY' IN ACCOUNT;`
3. To exempt a specific service identity, attach a narrower policy to that user with `ALTER USER svc_user SET AUTHENTICATION POLICY svc_policy;` rather than weakening the account-level policy.

**Step 4: Verify MFA Enrollment**

Run the MFA enrollment verification query from the DB Query Code Pack below to check all active users.

**Time to Complete:** ~15 minutes (policy) + user enrollment time

#### Leaked Password Protection (Always On)

Snowflake runs [leaked password protection](https://docs.snowflake.com/en/user-guide/leaked-password-protection) on every account and **it cannot be disabled**. When a user's password appears in a confirmed credential leak, Snowflake automatically unsets that password, forcing an administrator-mediated reset before the user can authenticate with a password again.

Plan for the failure mode: if the **only** account administrator's password is the one Snowflake unsets, no one inside the account can perform the reset and recovery requires opening a case with Snowflake Support. Maintain at least two ACCOUNTADMIN identities with independent credentials, and prefer federated or key-pair authentication for break-glass admins so a leaked password never severs administrative access.

#### Validation & Testing
1. Confirm the policy exists and reads as expected: `SHOW AUTHENTICATION POLICIES;` then `DESCRIBE AUTHENTICATION POLICY require_mfa;`
2. Confirm it is bound to the account: `SHOW PARAMETERS LIKE 'AUTHENTICATION_POLICY' IN ACCOUNT;`
3. Attempt login without MFA - should be blocked
4. Complete login with MFA - should succeed
5. Run enrollment query - all active users should show MFA enabled
6. Verify service accounts carry `TYPE = 'SERVICE'` and key-pair, PAT, or workload-identity authentication (see 1.2, 1.4, 1.5)

**Expected result:** No human user can authenticate with password-only, and the policy is visible as an account-level parameter

#### Monitoring & Maintenance

**Ongoing monitoring:** Use the MFA bypass alert and weekly compliance check queries from the DB Query Code Pack below.

**Maintenance schedule:**
- **Weekly:** Review MFA enrollment compliance
- **Monthly:** Audit MFA bypass exceptions
- **Quarterly:** Review authentication policies

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|--------------|---------|
| **User Experience** | Low | Users enroll once, authenticate via app |
| **System Performance** | None | No performance impact |
| **Maintenance Burden** | Low | Self-service enrollment |
| **Rollback Difficulty** | Easy | Can disable policy (not recommended) |

**Rollback Procedure:** Emergency MFA disable is available via the DB Query Code Pack below (not recommended).

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(1), IA-2(2) | MFA for network/local access |
| **PCI DSS** | 8.3.1 | MFA for all access |
| **HIPAA** | 164.312(d) | Person or entity authentication |

---


{% include pack-code.html vendor="snowflake" section="1.1" %}

### 1.2 Implement Service Account Key-Pair Authentication

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Replace password authentication for service accounts with RSA key-pair authentication, and declare every service account as `TYPE = 'SERVICE'`. Eliminates credential stuffing risk for automated processes.

**Every service account must carry an explicit user type.** Per [CREATE USER](https://docs.snowflake.com/en/sql-reference/sql/create-user), setting `TYPE = 'SERVICE'` disallows password and interactive authentication by design — a service user can only authenticate via key pair, programmatic access token, or workload identity. Leaving `TYPE` unset defaults the user to `PERSON`, which wrongly subjects an automated identity to human MFA rules and will break the integration once mandatory MFA enforcement lands. `TYPE = 'LEGACY_SERVICE'` is deprecated and is auto-migrated to `SERVICE` by October 2026, so set `SERVICE` now rather than absorbing the migration unplanned.

#### Rationale
**Why This Matters:**
- Service accounts can't use interactive MFA
- Password-based service accounts were compromised in 2024 breach
- Key-pair authentication is immune to credential stuffing
- An untyped service account defaults to `PERSON` and inherits human MFA enforcement, which either breaks the automation or forces a dangerous MFA exemption
- `TYPE = 'SERVICE'` makes password authentication structurally impossible for the identity, so a leaked password is not a usable attack path

**Attack Prevented:** Credential stuffing against automation accounts, password reuse, MFA-exemption abuse, unattended-account takeover

#### ClickOps Implementation

**Step 1: Generate RSA Key Pair** using OpenSSL to create a 2048-bit private key and extract the public key in Snowflake format.

**Step 2: Declare the User as a Service Account**
1. Set the type on every automated identity: `ALTER USER svc_user SET TYPE = 'SERVICE';`
2. Inventory anything still on the deprecated type: `SHOW USERS;` then filter for `type = 'LEGACY_SERVICE'` and convert each one with the same `ALTER USER ... SET TYPE = 'SERVICE'` statement.
3. Confirm no automation account has an unset type — those silently behave as `PERSON`.

**Step 3: Configure User with Key-Pair** by assigning the public key to the service account and removing its password.

**Step 4: Update Application Connection** to use the private key file instead of a password.

#### Validation & Testing
1. Confirm the user type: `DESCRIBE USER svc_user;` — the `TYPE` property must read `SERVICE`.
2. Confirm no `LEGACY_SERVICE` users remain anywhere in the account.
3. Attempt a password login as the service user — Snowflake must reject it because `TYPE = 'SERVICE'` disallows password authentication.
4. Confirm the application authenticates successfully using the private key.

**Expected result:** Every automation identity is `TYPE = 'SERVICE'` and authenticates only via key pair

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-5 | Authenticator management |
| **PCI DSS** | 8.6.1 | Management of application and system accounts |
| **HIPAA** | 164.312(d) | Person or entity authentication |

{% include pack-code.html vendor="snowflake" section="1.2" %}

---

### 1.3 Implement RBAC with Custom Roles

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Create granular role hierarchy instead of granting broad SYSADMIN or ACCOUNTADMIN access. Implement least privilege for data access.

#### Rationale
**Why This Matters:**
- Snowflake's default ACCOUNTADMIN and SYSADMIN roles grant sweeping access, so handing them out broadly turns any single compromised account into a full-account breach
- Granular functional and object-access roles ensure analysts, engineers, and service accounts can only reach the specific data their job requires
- Separating object-access roles from functional roles lets you change a user's data reach by adjusting role grants instead of rewriting individual privileges
- Restricting ACCOUNTADMIN membership and documenting a break-glass procedure shrinks the population that can alter security settings, create shares, or exfiltrate at scale

**Attack Prevented:** Privilege escalation, lateral movement, insider data theft, blast-radius expansion from a single compromised account

#### ClickOps Implementation

**Step 1: Design Role Hierarchy**
1. Navigate to: **Admin --> Account --> Roles**
2. Create functional roles (data_analyst, data_engineer, security_admin)
3. Create object access roles (sales_data_reader, sales_data_writer, pii_data_reader)
4. Grant object access roles to functional roles
5. Grant functional roles to users

**Step 2: Restrict ACCOUNTADMIN**
1. Navigate to: **Admin --> Account --> Roles --> ACCOUNTADMIN**
2. Review all members with ACCOUNTADMIN access
3. Remove unnecessary ACCOUNTADMIN grants
4. Document break-glass procedure for emergency admin access

---


{% include pack-code.html vendor="snowflake" section="1.3" %}

---

### 1.4 Govern Programmatic Access Tokens (PATs)

**Profile Level:** L1 (Crawl)

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls** | 5.2, 6.3 | Unique credentials, centralized access control |
| **NIST 800-53** | IA-5, IA-5(13) | Authenticator management, credential lifetime |

#### Description
[Programmatic access tokens](https://docs.snowflake.com/en/user-guide/programmatic-access-tokens) (PATs) are scoped, expiring bearer tokens that replace passwords and long-lived keys for API, SQL API, and driver authentication. A PAT inherits the user's role scope and carries an explicit expiry, which makes it far safer than a static password — but only if the account constrains who may mint tokens, how long they live, and from where they may be used.

Ungoverned PATs are simply passwords with a longer name: a token with a multi-year expiry, an unrestricted role, and no network policy is a permanent, exfiltratable credential. The controls below turn PATs into a genuinely bounded credential.

#### Rationale
**Why This Matters:**
- PATs are bearer credentials — anyone holding the string authenticates as that user, with no second factor to intercept
- Without a `PAT_POLICY` expiry cap, users mint tokens with lifetimes measured in years, recreating the long-lived static credential the 2024 breach exploited
- A PAT issued to a service user with no network policy can be replayed from anywhere on the internet, exactly the attacker-controlled-infrastructure pattern seen in the Snowflake credential-stuffing campaign
- Role restriction forces each token to a single scoped role, so a leaked token cannot be swapped onto ACCOUNTADMIN
- Explicitly listing `PROGRAMMATIC_ACCESS_TOKEN` in the authentication policy's allowed methods means token auth is a deliberate decision per identity rather than an ambient capability

**Attack Prevented:** Bearer-token replay, long-lived credential abuse, role escalation via token reuse, exfiltration of automation credentials

#### ClickOps Implementation

**Step 1: Permit Token Authentication Only Where It Is Needed**
1. Navigate to: **Projects → Worksheets** (Snowsight) as ACCOUNTADMIN.
2. Create an authentication policy that names token auth explicitly: `CREATE AUTHENTICATION POLICY svc_pat_policy AUTHENTICATION_METHODS = ('PROGRAMMATIC_ACCESS_TOKEN', 'KEYPAIR');`
3. Attach it to the service identities that need tokens: `ALTER USER svc_user SET AUTHENTICATION POLICY svc_pat_policy;`
4. Leave `PROGRAMMATIC_ACCESS_TOKEN` **out** of the account-wide human policy so interactive users cannot mint tokens by default.

**Step 2: Require a Network Policy Before a Service User Can Use a Token**
1. Add the requirement to the policy: `ALTER AUTHENTICATION POLICY svc_pat_policy SET PAT_POLICY = (NETWORK_POLICY_EVALUATION = 'ENFORCED_REQUIRED');`
2. `ENFORCED_REQUIRED` means a service user with no network policy attached simply cannot authenticate with a PAT — the token is inert until an IP allowlist exists.
3. Attach the network policy built in control 2.1 to each service user: `ALTER USER svc_user SET NETWORK_POLICY = corporate_access;`

**Step 3: Force Role Scoping on Every Token**
1. Require role restriction: `ALTER AUTHENTICATION POLICY svc_pat_policy SET PAT_POLICY = (REQUIRE_ROLE_RESTRICTION_FOR_SERVICE_USERS = 'true');`
2. With this set, a token must be minted against a specific role and cannot be used to assume any other role the user holds.

**Step 4: Cap Token Lifetime**
1. Set a short default and a hard ceiling: `ALTER AUTHENTICATION POLICY svc_pat_policy SET PAT_POLICY = (DEFAULT_EXPIRY_IN_DAYS = 15, MAX_EXPIRY_IN_DAYS = 365);`
2. A 15-day default means the common case rotates fortnightly; the 365-day ceiling caps the worst case so no token outlives an annual access review.
3. Communicate the rotation cadence to integration owners before enforcing — expiring tokens break pipelines that assumed permanence.

**Time to Complete:** ~30 minutes (policy) + integration rotation planning

#### Validation & Testing
1. Inspect the effective policy: `DESCRIBE AUTHENTICATION POLICY svc_pat_policy;` — confirm the `PAT_POLICY` properties read back as configured.
2. Inventory live tokens: `SHOW USER PROGRAMMATIC ACCESS TOKENS;` and confirm no token's expiry exceeds `MAX_EXPIRY_IN_DAYS`.
3. Remove a service user's network policy and attempt PAT authentication — it must fail while `NETWORK_POLICY_EVALUATION = 'ENFORCED_REQUIRED'` is in force.
4. Attempt to mint a token without a role restriction for a service user — it must be rejected.
5. Attempt PAT authentication from an IP outside the attached network policy — it must be rejected.

**Expected result:** Tokens exist only for named service identities, expire within 15 days by default, are bound to one role, and only work from allowlisted networks

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-5(13) | Expiration of cached authenticators |
| **PCI DSS** | 8.6.2 | Application and system account credentials not hard-coded |
| **HIPAA** | 164.312(d) | Person or entity authentication |

---

### 1.5 Use Workload Identity Federation for Cloud-Hosted Workloads

**Profile Level:** L2 (Walk)

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls** | 5.2, 6.3 | Unique credentials, centralized access control |
| **NIST 800-53** | IA-5, IA-9 | Authenticator management, service identification and authentication |

#### Description
[Workload identity federation](https://docs.snowflake.com/en/user-guide/workload-identity-federation) lets a workload running on AWS, Azure, GCP, or any OIDC-compliant platform authenticate to Snowflake using the identity the cloud platform already issues it — an IAM role, a managed identity, a service account, or an OIDC token. No Snowflake-side secret is created, stored, or rotated.

**Prefer workload identity federation over RSA key pairs wherever the workload runs on a supported platform.** A key pair is still a file that must be distributed, stored, and rotated; a federated workload identity is a short-lived, platform-attested credential with nothing to leak.

#### Rationale
**Why This Matters:**
- There is no credential to rotate, back up, or accidentally commit — the class of "leaked service account key" incidents disappears entirely for federated workloads
- The cloud platform attests the workload's identity cryptographically on every call, so an attacker who copies configuration off a host still cannot authenticate from elsewhere
- Federated credentials are short-lived by construction, collapsing the window in which any intercepted token is useful
- Removing key files from CI/CD systems and container images eliminates a supply-chain foothold — the 2024 breach began with credentials harvested from compromised endpoints
- Access is revoked by changing cloud IAM, giving one control plane for both infrastructure and data-platform access

**Attack Prevented:** Service-account key theft, credential exfiltration from CI/CD and container images, long-lived secret reuse, supply-chain credential harvesting

#### ClickOps Implementation

**Step 1: Identify the Workload's Cloud Identity**
1. For AWS, note the IAM role ARN the workload assumes.
2. For Azure, note the managed identity's object or client ID and the issuer URL.
3. For GCP, note the service account's numeric subject and issuer.
4. For any other OIDC platform, note the issuer URL and the subject claim the platform stamps into its tokens.

**Step 2: Bind the Cloud Identity to a Snowflake Service User**
1. Navigate to: **Projects → Worksheets** (Snowsight) as ACCOUNTADMIN.
2. Ensure the user is typed correctly first: `ALTER USER svc_user SET TYPE = 'SERVICE';`
3. Attach the workload identity: `ALTER USER svc_user SET WORKLOAD_IDENTITY = (TYPE = 'AWS', ARN = 'arn:aws:iam::123456789012:role/snowflake-etl');`
4. For an OIDC platform, use the issuer and subject form instead: `ALTER USER svc_user SET WORKLOAD_IDENTITY = (TYPE = 'OIDC', ISSUER = 'https://token.actions.githubusercontent.com', SUBJECT = 'repo:my-org/my-repo:ref:refs/heads/main');`
5. Scope the subject as narrowly as the platform allows — a subject of `repo:my-org/*` grants every repository in the organization access to your warehouse.

**Step 3: Allow the Authentication Method**
1. Permit it in the identity's authentication policy: `ALTER AUTHENTICATION POLICY svc_pat_policy SET AUTHENTICATION_METHODS = ('WORKLOAD_IDENTITY', 'KEYPAIR');`
2. Grant the service user only the scoped role it needs, per control 1.3.

**Step 4: Switch the Connection**
1. Update the driver or connector configuration to use `authenticator='WORKLOAD_IDENTITY'` in place of the private key or password parameters.
2. Deploy, confirm the workload connects, then delete the retired key pair: `ALTER USER svc_user UNSET RSA_PUBLIC_KEY;`
3. Remove the private key file from the secret store, CI/CD variables, and any container image layers that carried it.

**Time to Complete:** ~1 hour per workload, plus deployment

#### Validation & Testing
1. Confirm the binding: `DESCRIBE USER svc_user;` and check the `WORKLOAD_IDENTITY` property reflects the intended issuer and subject.
2. Run the workload and confirm it authenticates without any local key material present.
3. Copy the connection configuration to a host outside the bound cloud identity and attempt a connection — it must fail, because the platform attestation is absent.
4. Confirm the retired `RSA_PUBLIC_KEY` is unset and the corresponding private key is deleted from all secret stores.
5. Confirm `SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY` shows the workload authenticating via workload identity rather than key pair.

**Expected result:** The workload authenticates with zero stored Snowflake credentials, and the old key pair no longer exists

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-5, IA-9 | Authenticator management, service authentication |
| **PCI DSS** | 8.6.2 | Application and system account credentials not hard-coded |
| **HIPAA** | 164.312(d) | Person or entity authentication |

---

## 2. Network Access Controls

### 2.1 Implement Network Policies

**Profile Level:** L1 (Crawl)
**CIS Controls:** 13.3
**NIST 800-53:** AC-3, SC-7

#### Description
Restrict Snowflake access to known IP ranges (corporate network, VPN, approved BI tool IPs). Block access from unauthorized networks.

#### Rationale
**Why This Matters:**
- 2024 attackers accessed accounts from attacker-controlled infrastructure
- IP restrictions would have blocked compromised credential usage
- Network policies are defense-in-depth for credential theft

**Attack Prevented:** Credential stuffing from botnets, unauthorized access from foreign locations

#### ClickOps Implementation

**Step 1: Create Network Policy**
1. Navigate to: **Admin → Security → Network Policies**
2. Click **Add Policy**
3. Configure:
   - **Name:** corporate_access
   - **Allowed IPs:** Corporate ranges, VPN egress
   - **Blocked IPs:** Known bad ranges (optional)

**Step 2: Apply Network Policy**

Apply the network policy at account level or per-user using the SQL commands in the DB Query Code Pack below.

#### Validation & Testing

Verify network policy assignments using the validation queries in the DB Query Code Pack below.

---


{% include pack-code.html vendor="snowflake" section="2.1" %}

### 2.2 Enable Private Connectivity (PrivateLink/Private Service Connect)

**Profile Level:** L2 (Walk)
**NIST 800-53:** SC-7

#### Description
Configure private network connectivity to Snowflake, eliminating exposure to public internet.

#### Rationale
**Why This Matters:**
- Routing Snowflake traffic over PrivateLink or Private Service Connect keeps it on the cloud provider's private backbone, off the public internet entirely
- Eliminating a public endpoint removes the attack surface that credential-stuffing and direct-access attempts depend on
- Private connectivity complements network policies: even valid stolen credentials cannot reach the account from outside the approved private network path
- Traffic that never traverses the public internet reduces exposure to interception, man-in-the-middle attacks, and opportunistic scanning

**Attack Prevented:** Public-internet exposure, credential abuse from external networks, network interception, reconnaissance and scanning

#### ClickOps Implementation

**AWS PrivateLink:**
1. Navigate to: **Admin → Security → Private Connectivity**
2. Enable PrivateLink
3. Configure VPC endpoint in AWS
4. Update DNS for private resolution

**Azure Private Link:**
1. Similar process for Azure environments
2. Configure Private Endpoint in Azure

{% include pack-code.html vendor="snowflake" section="2.2" %}

---

## 3. OAuth & Integration Security

### 3.1 Restrict OAuth Token Scope and Lifetime

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(13)

#### Description
Configure OAuth security integrations with minimum required scopes and short token lifetimes for BI tool connections.

#### Rationale
**Why This Matters:**
- OAuth tokens for Tableau, Looker, Power BI access data
- Long-lived tokens create persistent risk
- Stolen OAuth tokens enabled downstream access in 2024 breach

**Attack Prevented:** Persistent downstream data access via stolen long-lived OAuth tokens (2024 breach pattern)

#### ClickOps Implementation

**Step 1: Audit Existing Security Integrations**

List and inspect all security integrations using the audit queries in the DB Query Code Pack below.

**Step 2: Configure OAuth Integration**
1. Create a new OAuth security integration for your BI tool
2. Set token refresh validity to 86400 seconds (1 day) instead of the 90-day default
3. Add ACCOUNTADMIN, SECURITYADMIN, and SYSADMIN to the blocked roles list

**Step 3: Block High-Privilege Roles from OAuth**
1. Edit the security integration to ensure ACCOUNTADMIN, SECURITYADMIN, SYSADMIN, and ORGADMIN are all in the blocked roles list
2. Verify no admin roles can authenticate via OAuth tokens

---


{% include pack-code.html vendor="snowflake" section="3.1" %}

### 3.2 Implement External OAuth (IdP Integration)

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-2(1)

#### Description
Configure External OAuth using your identity provider (Okta, Azure AD) for centralized authentication and MFA enforcement.

#### Rationale
**Why This Matters:**
- Delegating authentication to your IdP enforces corporate MFA, conditional access, and session policies on every Snowflake login
- Centralized identity means deprovisioning a user in the IdP immediately cuts their Snowflake access, eliminating orphaned local accounts
- External OAuth removes the need for Snowflake-local passwords, the exact weakness exploited in the 2024 credential-stuffing campaign
- IdP-issued tokens carry short lifetimes and can be revoked centrally, limiting the window a stolen token remains useful

**Attack Prevented:** Credential stuffing, phishing, orphaned-account access, MFA bypass

#### Code Implementation

{% include pack-code.html vendor="snowflake" section="3.2" %}

---

## 4. Data Security

### 4.1 Implement Column-Level Security with Masking Policies

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3, SC-28

#### Description
Apply dynamic data masking to sensitive columns (PII, financial data) to restrict visibility based on user role.

#### Rationale
**Why This Matters:**
- Dynamic masking ensures PII and financial columns render as redacted values for anyone outside an explicitly authorized role, even when they can query the table
- Policy-based masking is enforced at query time by Snowflake, so it cannot be bypassed by changing the client or rewriting the query
- Limiting who sees raw sensitive data shrinks the impact of a compromised analyst account or an over-broad role grant
- Masking supports data minimization and regulatory requirements (PCI DSS, HIPAA) without duplicating data into separate restricted tables

**Attack Prevented:** Unauthorized PII and financial data exposure, insider snooping, over-privileged data access, compliance violations

#### ClickOps Implementation

**Step 1: Create Masking Policies**
1. Navigate to: **Data --> Databases --> [Database] --> Policies**
2. Create masking policy for SSN that returns full value for PII_ADMIN role, masked value (XXX-XX-####) for all others
3. Create masking policy for email that returns full value for PII_ADMIN and CUSTOMER_SERVICE roles, masked value for all others

**Step 2: Apply Masking Policies to Columns**
1. Navigate to the target table and column
2. Set the SSN masking policy on the ssn column
3. Set the email masking policy on the email column

---


{% include pack-code.html vendor="snowflake" section="4.1" %}

### 4.2 Enable Row Access Policies

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3

#### Description
Implement row-level security to restrict data visibility based on user attributes (department, region, customer assignment).

#### Rationale
**Why This Matters:**
- Row-level security restricts each user to only the rows their attributes permit, enforcing data segmentation within shared tables
- Centralized policy logic applies consistently across every query path, preventing accidental cross-tenant or cross-department data leakage
- Row policies limit the blast radius of a compromised account to that user's authorized slice of data rather than the entire table
- Attribute-driven access supports multi-tenant and need-to-know models without maintaining separate physical tables per audience

**Attack Prevented:** Cross-tenant data leakage, unauthorized row access, insider over-reach, data-segregation failures

{% include pack-code.html vendor="snowflake" section="4.2" %}

---

### 4.3 Restrict Data Sharing

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-21

#### Description
Audit and control Snowflake data sharing to external accounts. Prevent accidental data exposure via shares.

#### Rationale
**Why This Matters:**
- Snowflake Secure Data Sharing can expose entire databases to external accounts, so an unreviewed or misconfigured share becomes a silent data-exfiltration channel
- Regularly auditing outbound shares catches accidental exposure before sensitive data reaches an unintended account
- Controlling who can create shares prevents a compromised or careless privileged user from publishing data externally
- Inventorying shares and their consumers is required to demonstrate data-handling controls to auditors and regulators

**Attack Prevented:** Accidental data exposure, unauthorized external sharing, data exfiltration via shares, third-party leakage

{% include pack-code.html vendor="snowflake" section="4.3" %}

---

## 5. Monitoring & Detection

### 5.1 Enable Comprehensive Audit Logging

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3, AU-6

#### Description
Configure access to SNOWFLAKE.ACCOUNT_USAGE schema for security monitoring and anomaly detection.

#### Rationale
**Why This Matters:**
- The ACCOUNT_USAGE schema records logins, queries, grants, and access history; without it a breach is invisible and impossible to investigate
- Failed-login, bulk-export, new-IP, and privilege-escalation queries surface the exact behaviors seen in credential-stuffing and exfiltration attacks
- Retained audit data enables incident investigation, scope determination, and regulatory breach-notification timelines
- Continuous monitoring turns logs into early detection rather than after-the-fact discovery

**Attack Prevented:** Undetected credential stuffing, silent data exfiltration, privilege-escalation abuse, delayed breach detection

#### Detection Use Cases

Key anomaly detection queries are provided in the code pack below. These cover:

- **Anomaly 1: Failed Login Spike** -- Detect credential stuffing by identifying users/IPs with 10+ failed logins per hour
- **Anomaly 2: Bulk Data Export** -- Flag SELECT queries returning 1M+ rows (potential exfiltration)
- **Anomaly 3: New IP Address Access** -- Identify successful logins from IPs not seen in the prior 7 days
- **Anomaly 4: Privilege Escalation** -- Monitor for GRANT or ALTER statements targeting ACCOUNTADMIN

---


{% include pack-code.html vendor="snowflake" section="5.1" %}

### 5.2 Forward Logs to SIEM

**Profile Level:** L1 (Crawl)

#### Description
Export Snowflake audit logs to SIEM (Splunk, Datadog, Sumo Logic) for real-time alerting and correlation.

#### Rationale
**Why This Matters:**
- Exporting audit logs to a SIEM enables real-time alerting and correlation that querying ACCOUNT_USAGE on demand cannot provide
- Centralizing Snowflake events with the rest of your telemetry lets analysts spot multi-system attack patterns and lateral movement
- Logs held outside Snowflake survive tampering or deletion by an attacker who gains account access
- SIEM retention and alerting support compliance requirements for continuous monitoring and timely incident response

**Attack Prevented:** Delayed detection, log tampering, missed cross-system attack patterns, slow incident response

{% include pack-code.html vendor="snowflake" section="5.2" %}

---

### 5.3 Enable Trust Center Scanner Packages

**Profile Level:** L1 (Crawl)

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Controls** | 7.1, 7.5 | Vulnerability management process, automated scanning |
| **NIST 800-53** | CA-7, RA-5 | Continuous monitoring, vulnerability monitoring and scanning |

#### Description
[Trust Center](https://docs.snowflake.com/en/user-guide/trust-center/overview) is Snowflake's built-in security posture scanner, reached at **Snowsight → Monitoring → Trust Center**. It evaluates your account against packaged scanner definitions and returns scored findings with remediation guidance, so misconfiguration is surfaced continuously rather than discovered during an audit or an incident.

Three packages matter here. **Security Essentials** is enabled by default and free — it covers the baseline checks including MFA coverage and network policy presence. **CIS Benchmarks** maps findings directly to the numbered controls of the CIS Snowflake Foundations Benchmark. **Threat Intelligence** flags account activity matching known threat patterns. Enable the CIS and Threat Intelligence packages explicitly; only Security Essentials runs on its own.

#### Rationale
**Why This Matters:**
- Every control in this guide can drift — a network policy detached, an MFA exemption granted, a share created — and Trust Center detects the drift without any custom query engineering
- The CIS Benchmarks package auto-maps live account state to numbered benchmark controls, turning a manual evidence-gathering exercise into a dashboard an auditor can be walked through
- Findings arrive scored and with remediation guidance attached, so the security team triages by severity rather than reading raw configuration
- Trust Center is first-party and reads account state directly, so it sees configuration a log-based SIEM rule would miss entirely
- Threat Intelligence findings catch account behaviour matching known attack patterns, complementing the anomaly queries in 5.1

**Attack Prevented:** Undetected security-control drift, silent misconfiguration, unnoticed privilege and share sprawl, delayed detection of known threat patterns

#### ClickOps Implementation

**Step 1: Open Trust Center**
1. Navigate to: **Monitoring → Trust Center** (Snowsight).
2. Open the **Findings** tab to view results from the default Security Essentials scanner package.
3. Note that viewing and managing Trust Center requires a role with the `TRUST_CENTER_VIEWER` or `TRUST_CENTER_ADMIN` application role — grant these deliberately rather than routing everyone through ACCOUNTADMIN.

**Step 2: Enable the CIS Benchmarks Package**
1. Open the **Scanner Packages** tab.
2. Locate **CIS Benchmarks** and set it to **Enabled**.
3. Set the scanner schedule to run at least daily so findings track configuration changes closely.

**Step 3: Enable the Threat Intelligence Package**
1. In the same **Scanner Packages** tab, enable **Threat Intelligence**.
2. Review its findings alongside the anomaly detection queries in control 5.1 — they cover different signals and neither replaces the other.

**Step 4: Work the Findings**
1. Return to **Findings** and sort by severity.
2. For each finding, follow the attached remediation guidance; most map directly onto controls in this guide.
3. Assign an owner and a review cadence — Trust Center only helps if findings are triaged rather than accumulated.

**Time to Complete:** ~20 minutes to enable, ongoing triage thereafter

#### Validation & Testing
1. Confirm all three packages show as enabled in the **Scanner Packages** tab.
2. Confirm the **Findings** tab is populated and shows a recent scan timestamp.
3. Introduce a deliberate, reversible misconfiguration in a non-production account — for example, detach a network policy from a test user — and confirm the next scan raises a corresponding finding.
4. Confirm CIS package findings display the benchmark control numbers they map to.
5. Confirm the Trust Center application roles are granted only to intended reviewers.

**Expected result:** Security Essentials, CIS Benchmarks, and Threat Intelligence all scan on a daily-or-better schedule, with findings owned and triaged

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.1 | Detection of configuration changes and vulnerabilities |
| **NIST 800-53** | CA-7, RA-5 | Continuous monitoring, vulnerability scanning |
| **PCI DSS** | 11.3.1 | Internal vulnerability scanning |
| **ISO 27001:2022** | A.8.8 | Management of technical vulnerabilities |

---

## 6. Third-Party Integration Security

### 6.1 Integration Risk Assessment Matrix

| Integration | Risk Level | OAuth Scopes | Recommended Controls |
|------------|------------|--------------|---------------------|
| **Tableau** | High | Full data access | IP restriction, role blocking, token rotation |
| **Power BI** | High | Full data access | Gateway IP allowlist, limited roles |
| **Looker** | High | Full data access | Service account, IP restriction |
| **dbt Cloud** | High | Write access | Service account, key-pair auth |
| **Fivetran** | Medium | Specific schemas | Limited role, source restrictions |

### 6.2 Tableau Integration Hardening

**Controls:**
- ✅ Create dedicated service account with key-pair auth
- ✅ Restrict to Tableau Server IPs only
- ✅ Block admin roles from OAuth
- ✅ Limit to specific databases/schemas
- ✅ Enable query tagging for monitoring

{% include pack-code.html vendor="snowflake" section="6.2" %}

---

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Snowflake Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA enforcement | 1.1 |
| CC6.1 | Service account typing and key-pair auth | 1.2 |
| CC6.1 | Programmatic access token governance | 1.4 |
| CC6.1 | Workload identity federation | 1.5 |
| CC6.2 | RBAC with custom roles | 1.3 |
| CC6.6 | Network policies | 2.1 |
| CC7.1 | Trust Center scanner packages | 5.3 |
| CC7.2 | Login/query history monitoring | 5.1 |

### PCI DSS Mapping

| Control | Snowflake Control | Guide Section |
|---------|------------------|---------------|
| 8.3.1 | MFA for all access | 1.1 |
| 8.6.1 | Application and system account management | 1.2 |
| 8.6.2 | Credentials not hard-coded | 1.4, 1.5 |
| 7.1 | Role-based access | 1.3 |
| 10.2 | Audit logging | 5.1 |
| 11.3.1 | Internal vulnerability scanning | 5.3 |
| 3.4 | Column masking | 4.1 |

### CIS Snowflake Foundations Benchmark

The authoritative external baseline for Snowflake is the [CIS Snowflake Foundations Benchmark](https://www.cisecurity.org/benchmark/snowflake), now at **v2.0.0**. Use it as the reference numbering when reporting Snowflake posture to auditors.

You do not have to map your account against it by hand. The **CIS Benchmarks scanner package in Trust Center** (control 5.3) reads live account state and returns findings already tagged with the benchmark's numbered controls, which makes the benchmark a continuously-evaluated dashboard rather than a periodic manual assessment.

---

## Appendix A: Edition Compatibility

| Control | Standard | Enterprise | Business Critical | VPS |
|---------|----------|------------|-------------------|-----|
| MFA | ✅ | ✅ | ✅ | ✅ |
| Network Policies | ✅ | ✅ | ✅ | ✅ |
| Dynamic Masking | ❌ | ✅ | ✅ | ✅ |
| Row Access Policies | ❌ | ✅ | ✅ | ✅ |
| PrivateLink | ❌ | ❌ | ✅ | ✅ |
| Tri-Secret Secure | ❌ | ❌ | ✅ | ✅ |
| Customer-Managed Keys | ❌ | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official Snowflake Documentation:**
- [Trust Center](https://trust.snowflake.com/)
- [Snowflake Documentation](https://docs.snowflake.com/)
- [Securing Snowflake](https://docs.snowflake.com/en/guides-overview-secure)
- [Security Overview and Best Practices](https://community.snowflake.com/s/article/Snowflake-Security-Overview-and-Best-Practices)
- [Network Policies](https://docs.snowflake.com/en/user-guide/network-policies)
- [Authentication Policies](https://docs.snowflake.com/en/user-guide/authentication-policies)
- [Mandatory MFA Rollout](https://docs.snowflake.com/en/user-guide/security-mfa-rollout)
- [MFA Migration Best Practices](https://docs.snowflake.com/en/user-guide/security-mfa-migration-best-practices)
- [Leaked Password Protection](https://docs.snowflake.com/en/user-guide/leaked-password-protection)
- [CREATE USER (user TYPE property)](https://docs.snowflake.com/en/sql-reference/sql/create-user)
- [Programmatic Access Tokens](https://docs.snowflake.com/en/user-guide/programmatic-access-tokens)
- [Workload Identity Federation](https://docs.snowflake.com/en/user-guide/workload-identity-federation)
- [Trust Center Overview](https://docs.snowflake.com/en/user-guide/trust-center/overview)
- [OAuth Overview](https://docs.snowflake.com/en/user-guide/oauth-snowflake-overview)
- [CIS Snowflake Foundations Benchmark v2.0.0](https://www.cisecurity.org/benchmark/snowflake)

**API & Developer Tools:**
- [REST API Reference](https://docs.snowflake.com/en/developer-guide/snowflake-rest-api/reference)
- [Python Connector](https://docs.snowflake.com/en/developer-guide/python-connector/python-connector)
- [Native SDK for Connectors](https://docs.snowflake.com/en/developer-guide/native-apps/connector-sdk/about-connector-sdk)

**Compliance Frameworks:**
- SOC 1 Type II, SOC 2 Type II, ISO 27001:2022, ISO 27017, ISO 27018, FedRAMP Moderate (SnowGov), FedRAMP High (by request), PCI DSS, HITRUST CSF, IRAP, C5, DoD IL5 -- via [Regulatory Compliance Docs](https://docs.snowflake.com/en/user-guide/intro-compliance)
- [Security & Compliance Reports](https://www.snowflake.com/en/legal/snowflakes-security-and-compliance-reports/)

**Security Incidents:**
- (2024) UNC5537 threat actor campaign used credential stuffing against Snowflake customer accounts lacking MFA. 165+ organizations affected including AT&T, Ticketmaster, Santander, and LendingTree. Over 500 million individuals had data exposed. AT&T paid $370,000 ransom. Root cause: customer accounts without MFA -- not a Snowflake platform breach.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.4.1 | ai-drafted | Cheat-sheet cell repair: added missing Attack Prevented line(s) to §3.1 (no content-facts changed) | Claude Code (Fable 5) |
| 2026-08-03 | 0.4.0 | ai-drafted | Replace 1.1 Snowsight MFA toggle with authentication policy enforcement; note mandatory MFA rollout Phase 3 and always-on leaked password protection; require TYPE = 'SERVICE' in 1.2; add 1.4 Programmatic Access Tokens, 1.5 Workload Identity Federation, 5.3 Trust Center scanner packages; reference CIS Snowflake Foundations Benchmark v2.0.0 | Claude Code (Sonnet 5) |
| 2026-06-29 | 0.3.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2026-02-19 | 0.3.0 | ai-drafted | Migrate all remaining inline code to Code Packs (sections 1.1, 2.1, 2.2, 3.1, 4.3); zero inline code blocks remain | Claude Code (Opus 4.6) |
| 2026-02-19 | 0.2.0 | ai-drafted | Migrate inline code to Code Packs (sections 1.2, 3.2, 4.2, 5.2, 6.2) | Claude Code (Opus 4.6) |
| 2025-12-14 | 0.1.0 | ai-drafted | Initial Snowflake hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
