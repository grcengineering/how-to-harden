---
layout: guide
title: "1Password Business Hardening Guide"
vendor: "1Password"
slug: "1password"
tier: "2"
category: "Security"
description: "Enterprise password manager hardening for 1Password Business SSO, policies, and vault security"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
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
1. Navigate to: **Admin Console** → **Security** → **Policies**
2. Click **Account Password**

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
Configure IP-based access restrictions for 1Password access.

#### Rationale
**Why This Matters:**
- Restricts 1Password access to expected corporate networks and geographies, shrinking the attack surface exposed to the public internet
- Blocks sign-in attempts from countries and IP ranges where the organization has no legitimate users, defeating large classes of automated attacks
- Adds a network-layer control that helps contain stolen credentials even when an attacker holds a valid username and password
- IP allowlisting at L3 ensures vault access only originates from trusted, managed egress points

**Attack Prevented:** Credential stuffing from foreign IPs, unauthorized remote access, automated login attacks

#### ClickOps Implementation

**Step 1: Access Firewall Settings**
1. Navigate to: **Admin Console** → **Security** → **Firewall**

**Step 2: Configure Rules**
1. Configure allowed/denied access:
   - **Allow countries:** Specify allowed countries
   - **Deny countries:** Block specific countries
   - **Allow IPs:** Whitelist corporate IPs (L3)
   - **Deny IPs:** Block known bad IPs
2. Configure rule priority

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
1. Navigate to: **Admin Console** → **Policies**

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

**Recovery:**
- Configure account recovery options
- Enable/disable recovery group

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
1. Navigate to: **Admin Console** → **Policies** → **Sharing**
2. Configure:
   - **Allow item sharing:** Yes/No
   - **Allow sharing with guests:** Control external sharing
   - **Require approval:** For sensitive sharing

**Step 2: Configure Link Sharing (L3)**
1. Enable/disable share links
2. Configure link expiration defaults
3. Require view limits

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
- [Trust Center](https://trust.1password.io/) (powered by SafeBase)
- [1Password Support](https://support.1password.com)
- [Business Security Practices](https://support.1password.com/business-security-practices/)
- [Team Policies](https://support.1password.com/team-policies/)
- [Admin Policies Guide](https://blog.1password.com/admin-policies-introduction-guide/)
- [Security Audits & Assessments](https://support.1password.com/security-assessments/)
- [Legal Center](https://1password.com/legal-center)

**API & Developer Tools:**
- [1Password Developer Portal](https://developer.1password.com/)
- [1Password CLI](https://developer.1password.com/docs/cli/)
- [1Password SDKs (Go, JavaScript, Python)](https://developer.1password.com/docs/sdks/)
- [Events API](https://developer.1password.com/docs/events-api/)
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
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, policies, and vault security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
