---
layout: guide
title: "Fastly Hardening Guide"
vendor: "Fastly"
slug: "fastly"
tier: "2"
category: "DevOps"
description: "Harden Fastly control-panel access, customer account permissions and automation credentials."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Fastly account changes can affect production delivery and customer-facing TLS. This guide covers the Fastly control panel organization and customer-account models and API credential scope. An unlinked Signal Sciences control panel and the WAF data plane are out of scope.

### Intended Audience

- SaaS administrators and security engineers
- GRC practitioners collecting configuration and access evidence

### How to Use This Guide

- **L1 (Crawl):** Establish identity, least privilege and review basics.
- **L2 (Walk):** Add controls that require staged deployment or split administration.

### Scope

ClickOps and code are documentation-derived; no tenant was accessed. Run inventories only on authorized accounts. They attest the visible configuration, not overall compliance.

## Table of Contents

1. [Control Checklist](#1-control-checklist)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Control Checklist

### 1.1 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

#### Description

Enforce two-factor authentication on the Fastly organization. Separately inspect the underlying customer-account settings and identity provider rather than interpreting one flag as the state of every control plane.

#### Rationale

**Why This Matters:**

- MFA reduces account takeover risk for administrators with production privileges.

#### Prerequisites

Organization Admin and tested recovery paths. Account-level API reads require an authorized token and the exact customer ID.

#### ClickOps Implementation

Open **Organization → Organization security**. Enable **Enforce 2FA** and confirm. Verify both organization-tier and affected customer-account sign-in paths separately. If federated, verify the IdP's policy too.

**Source:** [Vendor administration documentation](https://www.fastly.com/documentation/guides/organizations-and-accounts/organization-settings/enabling-organization-wide-two-factor-authentication/).

#### Code Implementation

{% include pack-code.html vendor="fastly" section="1.1" %}

#### Validation & Testing

Use a pilot account and check the organization control panel. The API pack reads the separate customer object's force flags and must not be reported as evidence that organization enforcement was enabled.

#### Operational Impact

Signed-in organization users without 2FA can be logged out. Enroll authorized responders before enforcing and keep a tested recovery path.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | IA-2 | Supports this objective; configuration alone does not establish compliance. |

### 1.2 Review Account Members and Roles

**Profile Level:** L1 (Crawl)

#### Description

Compare approved operators with customer-account membership, roles and service access; review organization-tier roles separately.

#### Rationale

**Why This Matters:**

- Unnecessary superusers or broad service assignments can turn a single account failure into a production-wide incident.

#### Prerequisites

Authorized operator and current roster with role and service ownership approval.

#### ClickOps Implementation

1. Open **Account → User management** and review pending and active users.
2. For an existing user, select **Options → Access controls**. Review roles and continue to service and workspace restrictions. Make least-privilege corrections one user at a time, with a tested administrator path intact. For IdP-managed accounts, change membership at the IdP to avoid drift.
3. Review **Organization → User management** separately; organization admins inherit Superuser rights on linked accounts.

**Sources:** [Account access control workflow](https://www.fastly.com/documentation/guides/organizations-and-accounts/account-members-and-permissions/configuring-user-roles-and-access-for-existing-users/), [organization user management](https://www.fastly.com/documentation/guides/organizations-and-accounts/organization-settings/managing-organization-users/), [role scope](https://www.fastly.com/documentation/guides/organizations-and-accounts/account-members-and-permissions/about-user-roles-and-permissions/).

#### Code Implementation

{% include pack-code.html vendor="fastly" section="1.2" %}

#### Validation & Testing

Use the CLI pack to retrieve the target customer's visible members, then validate role/service boundaries with an approved lower-privilege account. Customer membership is not an organization-wide RBAC census.

#### Operational Impact

Removing service access can affect on-call response or automation. Restore the previous documented grant only after review if a required role was removed.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AC-6 | Supports this objective; configuration alone does not establish compliance. |

### 1.3 Limit Account-Level Automation Tokens

**Profile Level:** L1 (Crawl)

#### Description

Give each integration a distinct automation token with short lifetime, required service assignments and only necessary scope. Use read-only scopes for inventories.

#### Rationale

**Why This Matters:**

- Sharing broad credentials lets any holder perform unnecessary production or TLS administration.

#### Prerequisites

Authorized account administrator; integration owner and secret-manager path.

#### ClickOps Implementation

Use the **API tokens** page for the account to review intended owner, service restrictions, scopes, and expiry. Create a separate replacement token restricted to the required tasks. Enable TLS management only for workloads that actually manage it. Rotate dependencies before deleting the old token.

**Source:** [Vendor administration documentation](https://www.fastly.com/documentation/guides/organizations-and-accounts/account-members-and-permissions/managing-account-level-api-tokens/).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Verify the collector can read intended metadata and cannot perform a write. Confirm replaced credentials are revoked after migration.

#### Operational Impact

Revocation can break a deployment or purge workflow. Test the replacement before revoking; issue a new restricted token rather than restoring a compromised one.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | IA-5 | Supports this objective; configuration alone does not establish compliance. |

### 1.4 Stage SAML Single Sign-On

**Profile Level:** L2 (Walk)

#### Description

Configure organization SAML against the workforce IdP and pilot before enforcing.

#### Rationale

**Why This Matters:**

- Centralized identity can apply consistent MFA and timely deprovisioning, but email mismatches can lock out users.

#### Prerequisites

Organization Admin, approved SAML IdP and protected recovery plan.

#### ClickOps Implementation

1. Open **Organization → Organization security → Add SAML Configuration**. Choose the identity provider and use the displayed details to configure the SAML application in the IdP. Match Fastly and IdP email values.
2. Upload the IdP metadata and select **Save and Enable SSO**. Pilot a viewer account before enabling **Immediately enforce SSO** and confirming **Start enforcing SSO**.
3. Organization Admins are exempt from SSO enforcement. Keep their native 2FA and documented emergency recovery independently protected.

**Source:** [Vendor administration documentation](https://www.fastly.com/documentation/guides/organizations-and-accounts/organization-settings/setting-up-single-sign-on-for-organizations/).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Verify approved and unassigned test identities behave as expected, including IdP MFA; document any permitted alternates.

#### Operational Impact

SSO enforcement can interrupt account access when a mapping or certificate is wrong. Retain a working admin session and the previously working configuration.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | IA-8 | Supports this objective; configuration alone does not establish compliance. |

## 2. Compliance Quick Reference

| Control | Profile | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 Enforce Two-Factor Authentication | L1 | IA-2 |
| 1.2 Review Account Members and Roles | L1 | AC-6 |
| 1.3 Limit Account-Level Automation Tokens | L1 | IA-5 |
| 1.4 Stage SAML Single Sign-On | L2 | IA-8 |

## References

- [Source and validation notes](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-dev-source-coverage.md)

## Contributing

Use the repository contribution guide. Include the tested edition, source and validation results with corrections.

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-11-27 | Initial documentation-derived guide and verification packs |
