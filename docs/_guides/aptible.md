---
layout: guide
title: "Aptible Hardening Guide"
vendor: "Aptible"
slug: "aptible"
tier: "2"
category: "DevOps"
description: "Secure Aptible organization access, application endpoints, and activity evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Scope: hosted Aptible deployment management. This does not cover application-level authentication, customer application code, or provider-operated host controls.

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

### 1.1 Require Mediated Sign-In

**Profile Level:** L1 (Crawl)

#### Description

Use the organization SAML provider, enforce MFA there, and tightly govern exempt owners and non-human access.

#### Rationale

**Why This Matters:**

- Local sign-in exceptions otherwise sit outside the central access lifecycle.

#### Prerequisites

An Aptible Account Owner, a SAML IdP, and a tested emergency owner.

#### ClickOps Implementation

1. Open the organization's **Single Sign On** settings and exchange metadata with the approved IdP. Pilot access first.
2. Enable **Require SSO for Access** after verifying the pilot. Enable MFA in the IdP; configure native 2FA for exempt owners in **Settings > Security Settings**.
3. Remove unnecessary SSO Bypass Allowlist entries and review owners, SSH keys, and approved automation users separately.

**Source:** [Vendor administration documentation](https://www.aptible.com/docs/how-to-guides/platform-guides/setup-sso).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Record eligible roles and exception rationale. Verify authorized access and recovery in a new session before closing existing sessions. SSH-key-authenticated Git deployment is not gated by Aptible 2FA.

#### Operational Impact

Enforcement can disrupt users with old sessions and CLI credentials. Keep a verified emergency operator available.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | IA-2 | Supports this objective; configuration alone does not establish compliance. |

### 1.2 Restrict Application Endpoints

**Profile Level:** L1 (Crawl)

#### Description

Enable per-endpoint filtering for restricted services; prefer internal-only exposure where the use case permits.

#### Rationale

**Why This Matters:**

- An internet-facing internal tool can be exposed even if the underlying app is otherwise isolated.

#### Prerequisites

Authorized access to the app endpoint and an approved list of client and workload IPv4 source addresses.

#### ClickOps Implementation

1. In the dashboard, navigate to the intended application and edit its endpoint.
2. Under **IP Filtering**, enable filtering and enter the approved IPv4 IPs/CIDRs. Preserve documented stack egress IPs when same-stack callers must continue accessing the endpoint.
3. Save the configuration. Repeat for every endpoint on the application, including secondary endpoints.

**Source:** [Vendor administration documentation](https://www.aptible.com/docs/core-concepts/apps/connecting-to-apps/app-endpoints/ip-filtering).

#### Code Implementation

{% include pack-code.html vendor="aptible" section="1.2" %}

#### Validation & Testing

Compare endpoint status, Internal, and IP Whitelist values in the official CLI inventory to the approved list. This control does not restrict backend CLI access such as SSH or log reads.

#### Operational Impact

Treat a CLI listing as configuration evidence only. Stage changes and verify expected clients and upstream dependencies can reach the service.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | SC-7 | Supports this objective; configuration alone does not establish compliance. |

### 1.3 Review Operational Activity

**Profile Level:** L2 (Walk)

#### Description

Review organization and resource activity for high-risk deploys and security changes; retain a policy-approved record.

#### Rationale

**Why This Matters:**

- Attribution and timestamps help tie production actions back to authorized changes.

#### Prerequisites

An operator who can view available activity, with separate approval for export or retention of sensitive log data.

#### ClickOps Implementation

1. Open **Activity** and confirm the organization and environment. Inspect qualifying deploys, authentication and sensitive access events where available.
2. Use the resource Activity tab to inspect the operation when needed. Tie high-risk events to a ticket or disposition and retain only required evidence.
3. Set review cadence to match retention; do not rely on the short Activity dashboard window to preserve evidence.

**Source:** [Vendor administration documentation](https://www.aptible.com/docs/core-concepts/observability/activity/activity-details).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Confirm a known, authorized operation appears with the expected actor, timestamp, and resource. Document what activity types your plan makes visible.

#### Operational Impact

Operation logs may include sensitive data. Restrict access, minimize export, and avoid attaching raw logs to broad-access tickets.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AU-6 | Supports this objective; configuration alone does not establish compliance. |

## 2. Compliance Quick Reference

| Control | Profile | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 Require Mediated Sign-In | L1 | IA-2 |
| 1.2 Restrict Application Endpoints | L1 | SC-7 |
| 1.3 Review Operational Activity | L2 | AU-6 |

## References

- [Source and validation notes](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-third-dev-source-coverage.md)

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-11-27 | Initial documentation-derived guide and verification packs |
