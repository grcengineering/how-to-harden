---
layout: guide
title: "Dynatrace SaaS Hardening Guide"
vendor: "Dynatrace SaaS"
slug: "dynatrace"
tier: "2"
category: "Security"
description: "Harden Dynatrace account SAML, IAM groups, OAuth clients and administrative evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Scope: Dynatrace SaaS account management. Tenant-level Environment API tokens and Grail security are separate, as are Dynatrace Managed and customer-hosted deployment settings.

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

### 1.1 Stage SAML on a Verified Domain

**Profile Level:** L1 (Crawl)

#### Description

Verify the organization's domain and pilot corporate SAML authentication before relying on it for Dynatrace SaaS users.

#### Rationale

**Why This Matters:**

- An unverified domain or incorrect assertion mapping can cause sign-in failures and leave alternate sign-in paths ungoverned.

#### Prerequisites

Access to Account Management IAM and the corporate DNS and IdP administration teams; emergency recovery identity.

#### ClickOps Implementation

1. In **Account Management → Identity & access management → Domain verification**, verify the required domain using the displayed DNS instruction.
2. In **SAML configuration**, complete the IdP integration and pilot permitted identities through it. Enforce MFA in the IdP and document retained emergency access.
3. Record configured domains and approved rollback information in the operating runbook.

**Source:** [Vendor administration documentation](https://docs.dynatrace.com/docs/manage/account-management).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Validate verified-domain status, one real pilot sign-in, applicable MFA and the documented recovery path. Domain verification is not evidence that all users use SAML.

#### Operational Impact

Keep a tested administrator during changes and roll back only the affected federation configuration if the pilot fails.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | IA-8 | Supports this objective; configuration alone does not establish compliance. |

### 1.2 Limit Account and Environment Role Grants

**Profile Level:** L1 (Crawl)

#### Description

Use defined groups for the narrowest role and policy grants. Check account versus environment scope, policy boundaries, and groups that are inherited by all users.

#### Rationale

**Why This Matters:**

- Overbroad group bindings can allow unrelated operators to administer environments or view telemetry beyond their duties.

#### Prerequisites

View and manage users and groups permission, approved role ownership map and account UUID. API inventory requires account-idm-read.

#### ClickOps Implementation

1. Go to **Account Management → Identity & access management → Group management**. Review each group's origin, members and assigned permissions.
2. Limit grants to the required scope and boundaries. For SAML- and SCIM-managed groups, apply membership corrections at the respective identity source.
3. Review **Effective policies** for pilot users; verify that default groups do not inherit unintended policies.

**Source:** [Vendor administration documentation](https://docs.dynatrace.com/docs/manage/identity-access-management/user-and-group-management/access-group-management).

#### Code Implementation

{% include pack-code.html vendor="dynatrace" section="1.2" %}

#### Validation & Testing

The pack inventories group identity and source, not effective permissions. Compare with approved groups and separately read the exact subject's effective policies.

#### Operational Impact

Removing an inherited grant can disrupt incident response. Stage the smallest changes first and restore only the prior authorized grant if necessary.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AC-6 | Supports this objective; configuration alone does not establish compliance. |

### 1.3 Scope OAuth Clients and Review Account Audits

**Profile Level:** L1 (Crawl)

#### Description

Separate each Account Management integration into a purpose-specific OAuth client and correlate administrative changes with audit records.

#### Rationale

**Why This Matters:**

- Shared client credentials hide ownership and allow one application's leak to affect multiple integrations.

#### Prerequisites

Account IAM administrator and dedicated service users; account-company-info to review Account Management audit logs in the UI.

#### ClickOps Implementation

1. In **Account Management → Identity & access management → OAuth clients**, use **Create client** and choose the grant type that matches the caller. For machine access, use a dedicated subject and restrict token scopes. Capture the one-time secret directly to controlled storage.
2. Confirm the expected settings in **Account Management → Settings → Audit log**. Keep account evidence separate from environment and Grail logs.
3. Document owners and rotate clients after verifying a replacement token and its narrower permission boundary.

**Sources:** [OAuth clients](https://docs.dynatrace.com/docs/manage/identity-access-management/access-tokens-and-oauth-clients/oauth-clients) and [Account Management audit logs](https://docs.dynatrace.com/docs/manage/account-management/audit-logs).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Verify only intended API calls are allowed, and correlate the actual account IAM audit record to approved work. Do not assume that every environment operation is recorded in the account log.

#### Operational Impact

Rotation may interrupt integrations. Stage replacement credentials before deleting an old client.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | IA-5 | Supports this objective; configuration alone does not establish compliance. |

## 2. Compliance Quick Reference

| Control | Profile | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 Stage SAML on a Verified Domain | L1 | IA-8 |
| 1.2 Limit Account and Environment Role Grants | L1 | AC-6 |
| 1.3 Scope OAuth Clients and Review Account Audits | L1 | IA-5 |

## References

- [Source and validation notes](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-next-dev-source-coverage.md)

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-11-27 | Initial documentation-derived guide and verification packs |
