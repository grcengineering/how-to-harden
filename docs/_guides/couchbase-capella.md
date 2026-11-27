---
layout: guide
title: "Couchbase Capella Hardening Guide"
vendor: "Couchbase Capella"
slug: "couchbase-capella"
tier: "2"
category: "Data"
description: "Restrict Capella Operational public access, federate console sign-in, and audit cluster changes."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Scope: Couchbase Capella Operational, not self-managed Couchbase Server, Capella App Services, or Operational Insights.

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

### 1.1 Restrict Cluster Public IP Access

**Profile Level:** L1 (Crawl)

#### Description

Allow only approved IPv4 addresses and add expiration for temporary access.

#### Rationale

**Why This Matters:**

- An open ingress list unnecessarily exposes the service to public network clients.

#### Prerequisites

Authorized project/cluster access and a validated list of approved client egress ranges. For packs, use a short-lived, IP-restricted Project Viewer management key scoped to this project and inject only its token.

#### ClickOps Implementation

1. Navigate to **Operational**, select the cluster, then **Settings > Allowed IP Addresses**.
2. Add the approved IPv4 addresses/CIDRs and expiration suitable for each use case. Do not choose **Allow Access from Anywhere**.
3. Wait for new entries to become Active and validate connectivity before removing broad or stale entries.

**Source:** [Vendor administration documentation](https://production.docs.couchbase.com/cloud/clusters/allow-ip-address.html).

#### Code Implementation

{% include pack-code.html vendor="couchbase-capella" section="1.1" %}

#### Validation & Testing

Review CDN/VPN/egress translations, CIDR width, expiry, owner and state. Pending, failed and expired entries are not equivalent to an active allowlist entry.

#### Operational Impact

Private connectivity has separate controls. Limit or remove public routes only after reviewing all clients, including backups and observability.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | SC-7 | Supports this objective; configuration alone does not establish compliance. |

### 1.2 Federate Capella UI Sign-In

**Profile Level:** L1 (Crawl)

#### Description

Use SAML or OIDC with IdP-managed MFA for authorized staff; keep programmatic credentials separately governed.

#### Rationale

**Why This Matters:**

- Enforcing workforce authentication independently of cluster credentials makes access changes reviewable.

#### Prerequisites

Paid Capella support plan, a supported IdP, and an organization owner.

#### ClickOps Implementation

1. In the organization's UI authentication settings, configure the intended SAML or OIDC integration using Capella's vendor instructions for the IdP.
2. Assign pilot users and MFA in the IdP; confirm only the expected users/roles gain access.
3. Review remaining local accounts. Govern management API keys and cluster credentials independently of UI federation.

**Source:** [Vendor administration documentation](https://docs.couchbase.com/cloud/organizations/ui-auth/capella-ui-auth.html).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Verify the assigned user can sign in through the IdP in a fresh session, that an unassigned user cannot use it, and separately test the authorized recovery process.

#### Operational Impact

SSO users use IdP MFA, not Capella native MFA. Changing SSO does not rotate workloads' keys or database credentials.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | IA-2 | Supports this objective; configuration alone does not establish compliance. |

### 1.3 Enable Cluster Audit Logging

**Profile Level:** L2 (Walk)

#### Description

Enable Capella Operational cluster audit logging and document required filterable events and exemptions.

#### Rationale

**Why This Matters:**

- Management and data activity must leave evidence for accountable review and investigations.

#### Prerequisites

Cluster with an Enterprise Service Plan, an owner authorized to configure auditing, and an event/retention decision.

#### ClickOps Implementation

1. Identify the intended cluster in Capella and its required audit events from vendor event documentation.
2. An authorized owner should use the vendor's **Update Cluster Audit Log Configuration** instructions to enable logging and explicitly select required filterable events. Approve any excluded users individually.
3. Verify the resulting configuration, then perform a benign approved administrative operation in a nonproduction cluster and review the resulting record.

**Source:** [Vendor administration documentation](https://docs.couchbase.com/cloud/security/audit-management.html).

#### Code Implementation

{% include pack-code.html vendor="couchbase-capella" section="1.3" %}

#### Validation & Testing

Check the audit-enabled flag, configured event IDs and exclusion count. Separately verify event capture and access-controlled retention.

#### Operational Impact

Data event volume and content can be sensitive. Stage toward the approved logging level and protect exported logs.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AU-2, AU-12 | Supports this objective; configuration alone does not establish compliance. |

## 2. Compliance Quick Reference

| Control | Profile | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 Restrict Cluster Public IP Access | L1 | SC-7 |
| 1.2 Federate Capella UI Sign-In | L1 | IA-2 |
| 1.3 Enable Cluster Audit Logging | L2 | AU-2, AU-12 |

## References

- [Source and validation notes](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-third-dev-source-coverage.md)

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-11-27 | Initial documentation-derived guide and verification packs |
