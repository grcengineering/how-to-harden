---
layout: guide
title: "1Password Business Hardening Guide"
vendor: "1Password"
slug: "1password"
tier: "2"
category: "Security"
description: "Enterprise password manager hardening for 1Password Business SSO, policies, and vault security"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

1Password is a leading enterprise password manager protecting credentials for **millions of users** across businesses worldwide. As a central repository for sensitive credentials, API keys, and secrets, 1Password security configurations directly impact organizational security posture. Proper hardening ensures credentials remain protected with zero-knowledge architecture while enabling secure sharing.

### Intended Audience
- Security engineers managing password management
- IT administrators configuring 1Password Business
- GRC professionals assessing credential security
- Third-party risk managers evaluating password managers

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers 1Password Business admin controls, SSO configuration, team policies, and vault security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Admin & Team Policies](#2-admin--team-policies)
3. [Vault Security](#3-vault-security)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SSO with Identity Provider

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML-based SSO to authenticate 1Password users through your corporate identity provider.

#### Rationale
**Why This Matters:**
- Centralizes authentication management
- Enables MFA enforcement through IdP
- Supports automatic provisioning/deprovisioning
- Provides consistent access policies

**Attack Prevented:** Credential theft and password reuse against local logins, phishing of standalone 1Password credentials, orphaned-account access after offboarding

#### Prerequisites
- 1Password Business plan
- SAML 2.0 compatible identity provider
- Admin access to 1Password

#### ClickOps Implementation

**Step 1: Enable SSO**
1. Navigate to: **1Password Admin Console** → **Security** → **Sign-in**
2. Click **Set up Single Sign-On**
3. Select **SAML** authentication

**Step 2: Configure SAML**
1. Download 1Password metadata or note:
   - ACS URL
   - Entity ID
2. Configure IdP application:
   - Upload metadata or enter manually
   - Configure attribute mappings (email, name)
   - Assign users/groups
3. Enter IdP details in 1Password:
   - IdP SSO URL
   - Certificate
4. Test SSO authentication

**Step 3: Configure Unlock Options**
1. Navigate to: **Security** → **Unlock with SSO**
2. Configure how users unlock after SSO:
   - **Biometrics:** Allow Touch ID, Face ID, Windows Hello
   - **Master Password:** Require master password
3. Balance security and usability

**Time to Complete:** ~1 hour

---

### 1.2 Configure SCIM Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure SCIM for automatic user provisioning and deprovisioning synced with your identity provider.

#### Rationale
**Why This Matters:**
- Automatically deprovisions departed employees, eliminating orphaned accounts that retain access to stored credentials and secrets
- Removes manual offboarding steps that are routinely forgotten or delayed, closing the window where former staff keep vault access
- Group sync keeps team and vault membership aligned with IdP roles, preventing privilege drift as people change jobs
- A password manager holds the keys to every other system, so a single stale account is a high-value foothold for attackers

**Attack Prevented:** Orphaned-account access, insider threat from departed employees, privilege creep, manual offboarding gaps

#### ClickOps Implementation

**Step 1: Enable SCIM**
1. Navigate to: **Admin Console** → **Integrations**
2. Click **Directory**
3. Select your identity provider
4. Generate SCIM token

**Step 2: Configure IdP SCIM**
1. In your IdP, configure SCIM provisioning
2. Enter 1Password SCIM endpoint
3. Enter SCIM token
4. Configure provisioning:
   - Create users
   - Update users
   - Deactivate users
   - Sync groups

**Step 3: Verify Sync**
1. Test user creation from IdP
2. Verify user appears in 1Password
3. Test deactivation removes 1Password access

---

### 1.3 Set an Automatic Deletion Policy for Suspended Members

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2(3) |

#### Description
1Password Business supports a team policy that automatically deletes suspended team members after a configurable retention window of 1 to 180 days, so suspension is not a permanent holding state.

#### Rationale
**Why This Matters:**
- Suspension alone leaves the account object and its group and vault associations in place, so an offboarding that stalls at "suspended" leaves reinstatable access sitting in the tenant indefinitely
- A bounded, automatic deletion window turns cleanup into a guaranteed background process instead of a manual task that depends on someone remembering it
- Setting the window explicitly forces a deliberate decision about how long the organization keeps recoverable ex-employee accounts, which auditors ask about directly
- Changes to this policy take effect within one hour, so the retention decision is enforced immediately rather than at the next review cycle

**Attack Prevented:** Reinstatement of dormant ex-employee accounts, offboarding drift, accumulation of stale identities in the tenant

#### Prerequisites
- 1Password Business or Enterprise
- Owner, Administrator, or membership in a group with the Manage Settings permission

#### ClickOps Implementation

**Step 1: Open Policies**
1. Sign in to your account on **1Password.com**
2. Select **Policies** in the sidebar, then **Manage**

**Step 2: Set the Deletion Window**
1. Locate the policy governing deletion of suspended team members
2. Set the retention window (1–180 days) to match your offboarding and legal-hold requirements
3. Save — the change executes within one hour

**Step 3: Reconcile With Offboarding**
1. Confirm SCIM deprovisioning (1.2) suspends rather than orphans departing users
2. Verify that legal-hold cases are handled before the window elapses, since deletion is irreversible

**Time to Complete:** ~10 minutes

---

## 2. Admin & Team Policies

### 2.1 Configure Account Password Policy

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2 |
| NIST 800-53 | IA-5 |

#### Description
Configure master password requirements for 1Password accounts.

#### Rationale
**Why This Matters:**
- The master password, combined with the Secret Key, is the root of 1Password's zero-knowledge encryption — its strength determines how resistant vaults are to offline cracking
- Enforcing a minimum length and complexity prevents users from choosing weak, guessable passphrases that brute-force and dictionary attacks can defeat
- Consistent organization-wide requirements remove the weakest-link accounts that attackers probe first

**Attack Prevented:** Brute-force cracking, dictionary attacks, weak-password compromise

#### ClickOps Implementation

**Step 1: Access Password Policy**
1. Sign in to your account on **1Password.com**
2. Select **Policies** in the sidebar, then **Manage**
3. Open the account password policy

**Step 2: Configure Requirements**
1. Select policy strength:
   - **Minimum:** 10+ characters
   - **Medium:** 12+ characters
   - **Strict:** 14+ characters (recommended)
   - **Custom:** Define specific requirements
2. Configure additional requirements if custom:
   - Uppercase letters
   - Lowercase letters
   - Numbers
   - Symbols

**Time to Complete:** ~10 minutes

---

### 2.2 Configure Firewall Rules

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Configure 1Password firewall rules to restrict where accounts can be accessed from, by country or continent, by IP address or CIDR range, and by anonymizing-network category.

#### Rationale
**Why This Matters:**
- Restricts 1Password access to expected corporate networks and geographies, shrinking the attack surface exposed to the public internet
- Blocks sign-in attempts from countries and IP ranges where the organization has no legitimate users, defeating large classes of automated attacks
- The Anonymous IP rule type covers Tor exit nodes, public VPNs, public proxies, and cloud-provider ranges — the infrastructure most credential-stuffing and account-takeover traffic arrives from
- Adds a network-layer control that helps contain stolen credentials even when an attacker holds a valid username and password
- IP allowlisting at L3 ensures vault access only originates from trusted, managed egress points

**Attack Prevented:** Credential stuffing from foreign IPs, unauthorized remote access via anonymizing infrastructure, automated login attacks

#### Prerequisites
- Owner, Administrator, or membership in a group with the Manage Settings permission

#### ClickOps Implementation

**Step 1: Access Firewall Settings**
1. Sign in to your account on **1Password.com**
2. Select **Policies** in the sidebar, then **Firewall**
3. Select **Manage policies**

**Step 2: Set the Default Action**
1. Choose the default action applied when no rule matches: **Allow**, **Report**, or **Deny**
2. Use **Report** first to observe what a rule would have blocked before enforcing it

**Step 3: Add Rules**
1. Add rules of the types you need:
   - **Country or continent:** allow or deny by geography
   - **IP address or CIDR range:** allowlist corporate egress (L3), or deny known-bad ranges
   - **Anonymous IP:** Tor, public VPNs, public proxies, and cloud-provider ranges
2. Assign each rule an action: **Allow**, **Report**, or **Deny**
3. Order the rules deliberately — they are evaluated in order and the **first match wins**; anything not matched falls through to the default action
4. Add explicit allow exceptions above a broad deny for legitimate travellers, contractors, and automation egress points

**Changed behavior / limitation:** **Firewall rules govern new access, not existing sessions — a device that is already signed in retains access to data stored locally even when a rule would now block it.** Firewall rules are therefore a perimeter control, not a session-revocation mechanism; deauthorize or suspend the account to cut off a device that is already signed in. ([Firewall rules](https://support.1password.com/firewall-rules/))

---

### 2.3 Configure Team Member Policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure policies for team member permissions and capabilities.

#### Rationale
**Why This Matters:**
- Restricting who can create vaults and share items prevents uncontrolled sprawl of credentials into unmanaged or externally shared locations
- Requiring approval for external sharing stops sensitive secrets from leaving the organization without oversight
- Setting Travel Mode and recovery policies centrally means security posture does not depend on each user making the right choice
- Default-permissive capabilities give every account a wider blast radius if it is compromised

**Attack Prevented:** Data exfiltration via uncontrolled sharing, credential sprawl, accidental exposure, shadow vaults

#### ClickOps Implementation

**Step 1: Access Team Policies**
1. Sign in to your account on **1Password.com**
2. Select **Policies** in the sidebar, then **Manage**

**Step 2: Configure Key Policies**

**Vault Creation:**
- Control who can create vaults
- Restrict to admins for controlled environments

**Sharing:**
- Configure external sharing restrictions
- Require approval for external sharing (L2)

**Travel Mode:**
- Enable/disable Travel Mode capability
- Configure vault visibility during travel

**Step 3: Govern Account Recovery**

Recovery is not a tenant-wide on/off switch — it is the **Recover Accounts** permission, held by Owners, Administrators, and any custom group you grant it to. Configure it deliberately:

1. Review which groups hold **Recover Accounts** and grant it only to roles that are expected to perform recoveries
2. Keep **at least two** people or groups able to recover accounts, so a single unavailable admin cannot strand users
3. Scope who receives recovery notifications so recovery events land with people who will actually notice an illegitimate one
4. Understand the flow before relying on it: the recoverer starts recovery, the user confirms via email, and the user then generates a **new Secret Key and account password** — the old credentials are invalidated
5. For mass events (such as a suspected compromise), use the 1Password CLI, which is the documented path for bulk recovery

**Time to Complete:** ~30 minutes

---

### 2.4 Implement Role-Based Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Configure role-based access for team administration.

#### Rationale
**Why This Matters:**
- Limiting Owner and Admin roles to essential personnel enforces least privilege and reduces the number of accounts that can alter security policy or reach every vault
- Fewer privileged accounts means fewer high-value targets for phishing and account takeover
- Tiered roles ensure standard users and guests cannot reconfigure the tenant or escalate their own access
- A compromised admin account can disable controls, export data, or grant attacker persistence, so minimizing them is critical

**Attack Prevented:** Privilege escalation, admin account takeover, insider abuse, lateral movement

#### ClickOps Implementation

**Step 1: Review Default Roles**
1. Navigate to: **Admin Console** → **Team Members**
2. Review roles:
   - **Owner:** Full access (1-2 people)
   - **Admin:** Team management
   - **Team Member:** Standard user
   - **Guest:** Limited external access

**Step 2: Assign Roles Appropriately**
1. Limit Owner role to essential personnel
2. Assign Admin role for IT administrators
3. Use custom roles for specific needs (Enterprise)

**Step 3: Consider the Two-Person Rule for the Owner Account**

1Password documents a **Two-Person Rule** option in which the owner account's credentials are split so that no single person holds full control of the account — one person holds the account password and another holds the Secret Key, and both are required to sign in. Pair it with the minimum-two-owners guidance above:

1. Keep at least two owners so no single departure or lockout strands the tenant
2. For the highest-privilege owner account, split its credentials between two custodians and store each half separately (for example, in separate sealed break-glass envelopes or separate PAM records)
3. Document the joint-recovery procedure and rehearse it, since the whole point is that neither custodian can act alone

---

### 2.5 Govern Agentic Autofill for AI Agents

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.8 |
| NIST 800-53 | AC-3, AC-4 |

#### Description
1Password provides a tenant-level policy governing Secure Agentic Autofill — the capability that allows AI agents to have credentials filled on the user's behalf. Decide explicitly whether agents may receive credentials from your vaults, rather than inheriting whatever the default is.

#### Rationale
**Why This Matters:**
- An AI agent that can trigger autofill is a new consumer of your credential store, and one that acts without a human watching each individual fill
- Agents follow instructions from pages and content they process, so credential access granted to an agent can be redirected by prompt injection in a way a human user would notice and a policy engine would not
- Making the decision at tenant level means the answer does not depend on each user's local configuration or on which client build they happen to run
- The capability is new, so the safe default for regulated or high-sensitivity tenants is to disable it until the organization has evaluated the agent surface it exposes

**Attack Prevented:** Credential disclosure to a compromised or manipulated AI agent, prompt-injection-driven credential use, unreviewed automated authentication

#### Prerequisites
- Owner, Administrator, or a group with the Manage Settings permission
- **Early access:** Secure Agentic Autofill and its governing policy are early-access functionality — confirm current availability and behavior in your own tenant before relying on this control

#### ClickOps Implementation

**Step 1: Locate the Policy**
1. Sign in to your account on **1Password.com**
2. Select **Policies** in the sidebar, then **Manage**
3. Locate the policy governing agentic autofill

**Step 2: Decide and Enforce**
1. Default to disabling agent autofill for regulated, executive, and infrastructure populations (L2/L3)
2. If enabling it, scope which vaults agents may draw from using vault permissions (3.1) rather than relying on the policy alone
3. Record the decision and its owner — early-access features change, and the decision needs re-review

---

### 2.6 Restrict Application Access and Enforce a Release Channel

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5, 2.7 |
| NIST 800-53 | CM-7, SI-2 |

#### Description
Use App Access Management to control which 1Password applications and integrations can reach a vault, and use release-channel enforcement to keep clients on the Production channel.

#### Rationale
**Why This Matters:**
- **All applications are enabled by default**, so a vault is reachable from every 1Password client and integration until an administrator narrows it — the tightening is opt-in, not inherited
- Limiting the applications that can open a vault reduces the number of distinct client surfaces that must be trusted and patched for that vault's contents
- Beta and nightly builds carry code that has not completed the vendor's release validation; restricting to Production keeps the fleet on reviewed builds
- **Restricting users to the Production release channel enforces automatic updates, and that enforcement overrides update settings configured separately through MDM** — so an MDM policy that defers or disables 1Password updates will not take effect for those users

**Attack Prevented:** Exposure of vault contents through unmanaged clients and integrations, exploitation of unpatched or pre-release client builds, shadow integrations reaching sensitive vaults

#### Prerequisites
- 1Password Business or Enterprise
- Owner, Administrator, or a group with the Manage Settings permission

#### ClickOps Implementation

**Step 1: Inventory What Can Reach Each Vault**
1. Sign in to your account on **1Password.com**
2. For each sensitive vault, review the applications currently permitted to access it — assume all are enabled until you verify otherwise

**Step 2: Narrow Application Access**
1. Disable applications and integrations that no one in scope actually uses for that vault
2. Apply the tightest restrictions to infrastructure, executive, and secrets vaults first

**Step 3: Enforce the Release Channel**
1. Select **Policies** in the sidebar, then **Manage**
2. Restrict users to the **Production** release channel
3. Reconcile with MDM: remove or align any MDM-managed 1Password update deferral, since release-channel enforcement overrides it and the two will otherwise appear to conflict

---

## 3. Vault Security

### 3.1 Configure Vault Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Configure vault access permissions following least privilege principles.

#### Rationale
**Why This Matters:**
- Scoping vault access to only the users and groups that need it limits how much a single compromised account can reach
- Group-based permissions keep access aligned with job function and make audits and revocation straightforward
- Separating private, team, infrastructure, and executive vaults contains the blast radius if any one vault or account is breached
- Over-broad vault membership turns one stolen credential into access to the organization's entire secret store

**Attack Prevented:** Lateral movement, excessive data exposure, insider access abuse, blast-radius expansion

#### ClickOps Implementation

**Step 1: Review Vault Structure**
1. Navigate to: **Admin Console** → **Vaults**
2. Review existing vaults and permissions

**Step 2: Configure Vault Permissions**
1. For each vault, configure:
   - **Users:** Individual access
   - **Groups:** Group-based access
   - **Permission level:** View, Edit, Manage
2. Use groups for scalable management

**Best Practice Vault Structure:**

| Vault | Purpose | Access |
|-------|---------|--------|
| Employee Private | Personal items | Individual only |
| Team Shared | Team credentials | Team group |
| Infrastructure | Server/API credentials | IT group |
| Executive | Sensitive business | Executives only |

---

### 3.2 Configure Item Sharing Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Configure how items can be shared within and outside the organization.

#### Rationale
**Why This Matters:**
- Controlling item and guest sharing prevents secrets from being copied into unmanaged hands or external parties without oversight
- Setting share-link expiration and view limits ensures shared credentials cannot be replayed indefinitely if a link is intercepted or forwarded
- Requiring approval for sensitive sharing inserts a deliberate checkpoint before high-value credentials leave their vault
- Unrestricted sharing is a common path for credentials to leak outside the zero-knowledge boundary

**Attack Prevented:** Credential leakage, unauthorized external sharing, share-link replay, data exfiltration

#### ClickOps Implementation

**Step 1: Configure Sharing Settings**
1. Sign in to your account on **1Password.com**
2. Select **Policies** in the sidebar, then **Manage**, and open the sharing policies
3. Configure:
   - **Allow item sharing:** Yes/No
   - **Allow sharing with guests:** Control external sharing
   - **Require approval:** For sensitive sharing

**Step 2: Configure Link Sharing (L3)**
1. Enable/disable share links
2. Configure link expiration defaults
3. Require view limits

---

### 3.3 Enable Local Scanning for Plaintext Developer Secrets

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.14 |
| NIST 800-53 | SI-4, SC-28 |

#### Description
1Password can scan a device's local disk for plaintext developer secrets — credentials sitting in config files, dotfiles, and environment files outside any vault — and surface what it finds in Business Watchtower.

#### Rationale
**Why This Matters:**
- The secrets that leak in real incidents are usually the ones that were never in the password manager: API keys in `.env` files, cloud credentials in shell profiles, tokens pasted into local config
- Endpoint compromise or a stolen laptop turns every plaintext secret on disk into an immediate credential, with no vault, no MFA, and no audit trail in the way
- Surfacing findings centrally in Business Watchtower converts an invisible, per-developer problem into a tracked remediation queue owned by security
- Finding the sprawl is the prerequisite to fixing it — each discovered secret is a candidate for migration into a vault or a service account (3.4)

**Attack Prevented:** Credential harvesting from compromised or stolen developer endpoints, secret sprawl outside the zero-knowledge boundary, exposure of long-lived cloud and API credentials

#### Prerequisites
- 1Password Business
- **Early access:** local secret scanning is early-access functionality — confirm availability, platform coverage, and current behavior in your own tenant before depending on it as a control

#### ClickOps Implementation

**Step 1: Enable the Capability**
1. Sign in to your account on **1Password.com**
2. Select **Policies** in the sidebar, then **Manage**
3. Locate the policy governing local scanning for plaintext secrets and enable it for the developer population

**Step 2: Set Expectations Before Turning It On**
1. Tell developers what is scanned and what is reported, since disk scanning on personal-feeling devices is a trust question as much as a technical one
2. Confirm what leaves the device — findings surface centrally, so define who may see them

**Step 3: Work the Findings**
1. Review discovered plaintext secrets in **Business Watchtower**
2. For each finding, move the secret into a vault or replace it with a scoped service account (3.4), then rotate the exposed value
3. Track remediation rather than treating the report as a one-time inventory

---

### 3.4 Scope and Inventory Service Accounts

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-6, AC-2 |

#### Description
Use 1Password Service Accounts for automation instead of sharing a human account or a broad CLI credential, and scope each one to only the vaults and actions its workload needs.

#### Rationale
**Why This Matters:**
- Service accounts are scoped to specific vaults or Environments and carry per-action permissions, so an automation credential can be limited to reading exactly the items its pipeline needs
- Reusing a human account for automation puts a credential with full human access into CI systems and scripts, where it is copied, logged, and rarely rotated
- Admin usage reports make service-account activity reviewable, turning silent machine access into something an owner can actually audit
- A tenant is limited to **100 service accounts**, which is a natural forcing function for keeping an inventory rather than creating one per script and forgetting them

**Attack Prevented:** Over-privileged automation credentials, credential sharing between humans and pipelines, unaudited machine access, blast-radius expansion from a leaked CI secret

#### Prerequisites
- 1Password Business or Enterprise
- Owner or Administrator to create and review service accounts

#### ClickOps Implementation

**Step 1: Replace Shared Human Credentials**
1. Identify every automation, CI job, and script currently authenticating as a person or with a broadly scoped CLI credential
2. Create a dedicated service account for each workload

**Step 2: Scope Each Service Account**
1. Grant access only to the specific vaults (or Environments) the workload requires
2. Set per-action permissions — read-only wherever the workload does not need to write
3. Never grant a service account access to a vault simply because it was convenient at setup time

**Step 3: Inventory and Review**
1. Review admin usage reports for service-account activity on a set cadence
2. Retire accounts whose workloads no longer exist — the 100-account ceiling means dead entries consume real capacity
3. Re-scope any account whose permissions have drifted beyond its current job

---

## 4. Monitoring & Compliance

### 4.1 Enable Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable audit logging for security monitoring and compliance.

#### Rationale
**Why This Matters:**
- Activity logs capture sign-ins, vault access, item changes, and admin actions — the evidence needed to detect misuse and investigate incidents
- Streaming events to a SIEM enables real-time alerting on suspicious behavior such as mass item access or anomalous sign-ins
- Durable records support compliance audits and forensic reconstruction after a breach
- Without logging, credential theft and insider abuse can occur silently and remain undetected for long periods

**Attack Prevented:** Undetected credential theft, insider abuse, delayed breach detection, audit gaps

#### ClickOps Implementation

**Step 1: Access Activity Log**
1. Navigate to: **Admin Console** → **Reports** → **Activity Log**
2. Review logged activities:
   - Sign-in events
   - Vault access
   - Item changes
   - Admin actions

**Step 2: Configure SIEM Integration**
1. Navigate to: **Integrations** → **Events**
2. Configure event streaming to SIEM:
   - Splunk
   - Azure Sentinel
   - Generic webhook
3. Select events to stream

**Step 3: Cover All Three Event Classes**

The Events API exposes three distinct classes — collect all three, because each answers a different question and any one alone leaves a blind spot:

| Event class | What it contains | What it detects |
|-------------|------------------|-----------------|
| Account activity | Audit events for administrative and account changes | Policy tampering, group and permission changes, provisioning abuse |
| Item usage | Items viewed, copied, or edited in shared vaults | Mass credential access, staging before exfiltration, insider misuse |
| Sign-in attempts | Successful and failed sign-ins, including failure detail | Credential stuffing, password spraying, anomalous access patterns |

---

### 4.2 Monitor Security Dashboard

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Monitor the security dashboard for insights and recommendations.

#### Rationale
**Why This Matters:**
- Watchtower surfaces compromised, weak, and reused passwords so they can be rotated before attackers exploit them
- Tracking 2FA adoption identifies accounts still protected by a single factor and most exposed to takeover
- Continuous review turns the stored credential inventory into an active risk-reduction program rather than a static vault
- Known-breached and reused passwords are a primary vector for credential-stuffing attacks across connected systems

**Attack Prevented:** Credential stuffing, reused-password compromise, account takeover, exploitation of known-breached secrets

#### ClickOps Implementation

**Step 1: Review Security Dashboard**
1. Navigate to: **Admin Console** → **Security**
2. Review:
   - Watchtower alerts (compromised passwords)
   - Weak password detection
   - Reused passwords
   - 2FA adoption

**Step 2: Address Findings**
1. Notify users of compromised passwords
2. Enforce password updates for weak items
3. Track 2FA adoption progress

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | 1Password Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | SSO authentication | [1.1](#11-configure-sso-with-identity-provider) |
| CC6.1 | Password policy | [2.1](#21-configure-account-password-policy) |
| CC6.2 | Role-based access | [2.4](#24-implement-role-based-access) |
| CC6.6 | Firewall rules | [2.2](#22-configure-firewall-rules) |
| CC7.2 | Audit logging | [4.1](#41-enable-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | 1Password Control | Guide Section |
|---------|-------------------|---------------|
| IA-2 | SSO/MFA | [1.1](#11-configure-sso-with-identity-provider) |
| IA-5 | Password policy | [2.1](#21-configure-account-password-policy) |
| AC-2 | SCIM provisioning | [1.2](#12-configure-scim-provisioning) |
| AC-6(1) | Least privilege | [2.4](#24-implement-role-based-access) |
| AU-2 | Audit logging | [4.1](#41-enable-audit-logging) |

---

## Appendix A: Plan Compatibility

| Feature | Teams | Business | Enterprise |
|---------|-------|----------|------------|
| SSO | ❌ | ✅ | ✅ |
| SCIM | ❌ | Basic | Full |
| Custom Policies | ❌ | ✅ | ✅ |
| Custom Roles | ❌ | ❌ | ✅ |
| Activity Log | Basic | Full | Full |
| SIEM Integration | ❌ | ✅ | ✅ |
| Firewall Rules | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official 1Password Documentation:**
- [1Password Support](https://support.1password.com)
- [Business Security Practices](https://support.1password.com/business-security-practices/)
- [Team Policies](https://support.1password.com/team-policies/)
- [Firewall Rules](https://support.1password.com/firewall-rules/)
- [Recover Accounts](https://support.1password.com/recovery/)
- [Admin Policies Guide](https://blog.1password.com/admin-policies-introduction-guide/)
- [Security Audits & Assessments](https://support.1password.com/security-assessments/)
- [Legal Center](https://1password.com/legal-center)

**API & Developer Tools:**
- [1Password Developer Portal](https://www.1password.dev/)
- [1Password CLI](https://www.1password.dev/cli/)
- [1Password SDKs](https://www.1password.dev/sdks/)
- [Events API](https://www.1password.dev/events-api/)
- [Service Accounts](https://www.1password.dev/service-accounts/)
- [GitHub Organization](https://github.com/1Password)

**Compliance Frameworks:**
- SOC 2 Type II (unqualified opinions since 2018) — via [SOC 2 Certification Page](https://1password.com/soc/)
- ISO 27001:2022, ISO 27017:2015, ISO 27018:2019, ISO 27701:2019 — via [ISO Certification Announcement](https://blog.1password.com/1password-iso-27001-certified/)
- HIPAA, GDPR, DORA compliance — via [Compliance Overview](https://1password.com/solutions/cybersecurity-compliance)

**Security Incidents:**
- **October 2023 — Okta Support System Breach:** An attacker accessed 1Password's Okta tenant using a compromised Okta support session. Activity was immediately detected and terminated; no 1Password user data or vault data was compromised. ([1Password Incident Report](https://blog.1password.com/okta-incident/))
- **2024 — macOS Vulnerability (Patched):** Researchers disclosed a vulnerability in the 1Password macOS app ahead of DEF CON 2024; 1Password patched it before public disclosure with no evidence of exploitation.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass: corrected Policies console paths (2.1/2.3/3.2), rewrote 2.2 firewall rules (rule types, Allow/Report/Deny, first-match ordering, already-signed-in-device limitation), corrected 2.3 recovery model to the Recover Accounts permission, added Two-Person Rule to 2.4, named the three Events API classes in 4.1, added controls 1.3 (suspended-member auto-deletion), 2.5 (agentic autofill policy, early access), 2.6 (app access management + release channel), 3.3 (local plaintext-secret scanning, early access), 3.4 (service-account scoping); repointed developer docs to 1password.dev and removed the Trust Center reference. Tier 3/4 research sweep out of scope this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, policies, and vault security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
