---
layout: guide
title: "Coralogix Hardening Guide"
vendor: "Coralogix"
slug: "coralogix"
tier: "2"
category: "Security"
description: "Harden team login policies, network restrictions, and team-scoped access in Coralogix."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Scope: commercial Coralogix teams. Login policy controls human and applicable OAuth login paths; teams, service-to-service keys and data ingestion are separate permission boundaries. Do not assume one team's settings apply to another or that commercial endpoints apply in government or BYOC deployments.

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

### 1.1 Scope Network Access to Approved Egress

**Profile Level:** L2 (Walk)

#### Description

Apply the team IP login allowlist where stable managed IPv4 egress exists. Scope support access separately.

#### Rationale

**Why This Matters:**

- Team data can expose operational secrets or security telemetry; network access policy limits where interactive logins may originate.

#### Prerequisites

Permission TEAM-IP-ACCESS:MANAGE, matching pilot network ranges and a working administrator session. Inventory uses TEAM-IP-ACCESS:READCONFIG.

#### ClickOps Implementation

1. Open **Settings → Login access policy → IP access → Add IP address**. Enter the IPv4 address or canonical CIDR and descriptive name.
2. Stage disabled entries where useful. Enable approved entries only after documenting current office, VPN and recovery egress. Review the separate support VPN row.
3. Validate both permitted and disallowed origin paths before removing the prior recovery range.

**Source:** [Vendor administration documentation](https://coralogix.com/docs/user-guides/account-management/user-management/login-access-policy/).

#### Code Implementation

{% include pack-code.html vendor="coralogix" section="1.1" %}

#### Validation & Testing

The CLI pack reads IP settings for the reviewed profile's team, but does not infer effective access. Compare settings with approved ranges, test actual allowed and disallowed logins, and verify onboarding for a newly provisioned user.

#### Operational Impact

IP restrictions can lock out users, while removing the last entry can re-open access. Add and verify replacement ranges before removing required entries.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AC-17 | Supports this objective; configuration alone does not establish compliance. |

### 1.2 Require Centralized Authentication and MFA

**Profile Level:** L1 (Crawl)

#### Description

Enforce approved SSO and require MFA at the relevant identity layer. Separately review fallback logins and per-user methods.

#### Rationale

**Why This Matters:**

- Without centrally controlled identity, a lingering password or reseller identity can bypass offboarding and MFA.

#### Prerequisites

SECURE-LOGIN:MANAGE permission, working IdP configuration, and one tested recovery administrator.

#### ClickOps Implementation

1. Open **Settings → Login access policy → Login policy**. Validate the SAML IdP setup and enrolled pilot accounts.
2. Enable the applicable SSO enforcement and two-factor policies under the documented team options. View allowed login methods on pilot and privileged users; at the IdP require the organization's MFA policy.
3. Verify and document any break-glass exceptions rather than assuming settings affect every account or API key.

**Source:** [Vendor administration documentation](https://coralogix.com/docs/user-guides/account-management/user-management/login-access-policy/).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Observe a matching IdP authentication and successful MFA for a normal user. Confirm a disallowed authentication path cannot sign in. Verify service-to-service keys independently.

#### Operational Impact

Lockout risk exists if the IdP or enrollment mapping is incorrect; preserve the proven emergency path through the rollout.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | IA-2 | Supports this objective; configuration alone does not establish compliance. |

### 1.3 Review Groups and Limit API Key Permissions

**Profile Level:** L1 (Crawl)

#### Description

Limit group access and issue purpose-specific API keys; distinguish key-management visibility from effective authorization when a key is used.

#### Rationale

**Why This Matters:**

- A shared high-privilege key can bypass user-level access policies that individual users would otherwise have to satisfy.

#### Prerequisites

An administrator with the necessary role/key management permissions and an approved group and automation roster.

#### ClickOps Implementation

1. In **Settings → Users and Teams**, review relevant groups and roles against the approved access map.
2. On **API Keys**, use dedicated personal or team keys only when required and restrict presets and allowed operations. Keep telemetry ingestion keys separate from management keys.
3. Rotate integrations one by one. Verify the replacement works before revoking its predecessor.

**Source:** [Vendor administration documentation](https://coralogix.com/docs/user-guides/account-management/api-keys/api-keys/).

#### Code Implementation

{% include pack-code.html vendor="coralogix" section="1.3" %}

#### Validation & Testing

Use the CLI pack to list groups for the intended profile, not to infer per-user privileges or key policy. Review exact key scopes and a lower-privilege test identity separately.

#### Operational Impact

Revoking access can break telemetry. Switch consumers to a verified replacement before revocation and never restore a suspected compromised key.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AC-6 | Supports this objective; configuration alone does not establish compliance. |

## 2. Compliance Quick Reference

| Control | Profile | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 Scope Network Access to Approved Egress | L2 | AC-17 |
| 1.2 Require Centralized Authentication and MFA | L1 | IA-2 |
| 1.3 Review Groups and Limit API Key Permissions | L1 | AC-6 |

## References

- [Source and validation notes](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-next-dev-source-coverage.md)

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-11-27 | Initial documentation-derived guide and verification packs |
