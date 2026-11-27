---
layout: guide
title: "Celonis Hardening Guide"
vendor: "Celonis"
slug: "celonis"
tier: "3"
category: "Data"
description: "Celonis Platform teams process organizational data and expose distinct permissions for people, provisioning, and monitoring clients"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

**Product Editions Covered:** Celonis Platform cloud team administration and Platform Usage APIs

## Overview

Celonis Platform teams process organizational data and expose distinct permissions for people, provisioning, and monitoring clients. Review grants separately instead of treating access to a team as approval for every API.

### Intended Audience

Platform administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Baseline controls for the documented deployment.
- **L2 (Walk):** Add verified controls where the workload needs stronger isolation.
- **L3 (Run):** Add controls warranted by higher-risk workflows and contractual requirements.

### Scope

Covers team-scoped enterprise provisioning, OAuth application grants and Audit Log API v2. Does not cover Celonis 4 on-premises, Make, individual Studio asset authorization, or source-system secrets.

---

## Table of Contents

1. [Identity Lifecycle](#1-identity-lifecycle)
2. [Application Credentials and Audit](#2-application-credentials-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

---

## 1. Identity Lifecycle

### 1.1 Scope and test SCIM identity provisioning

**Profile Level:** L1 (Crawl)

#### Description

Use approved IdP assignments and the official SCIM API for controlled user and group provisioning and deprovisioning.

#### Rationale

- A broad provisioning scope can create unauthorized users or remove active accounts at scale. SCIM does not replace independently verified authentication policy.

#### Prerequisites

Celonis team admin, IdP provisioning admin, documented selected groups, and synthetic pilots.

#### ClickOps Implementation

1. Select the intended Celonis Platform team. Open **Admin & Settings → Settings** and review **Enable SCIM**.
2. Connect an approved IdP using the documented vendor OAuth scope and actual team URL. Limit assignments; verify roles resulting from group mappings.

Source: [Vendor configuration reference](https://developer.celonis.com/celonis-apis/scim-api/configuring-scim-api).

#### Code Implementation

The published SCIM API can write identities; this pack does not perform those writes or claim SSO is enforced.

#### Validation & Testing

Test creation, authorized group membership change, and access removal for a pilot. Check effective permissions, not only IdP provisioning status.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Faulty mapping can disable access or alter team roles. Pilot with a small group.

#### Rollback Procedure

Pause the provisioning job, restore the last approved mapping and reconcile unintended assignments. Keep recovery access available.

---

## 2. Application Credentials and Audit

### 2.1 Use dedicated least-privilege OAuth clients

**Profile Level:** L1 (Crawl)

#### Description

Use dedicated per-team OAuth clients and grant both the minimum relevant OAuth scope and the corresponding application permission.

#### Rationale

- Broad client access combines unrelated data and operation permissions. A scope in a token does not grant a missing application permission.

#### Prerequisites

Team admin, service owner, approved secret store and supported OAuth client grant.

#### ClickOps Implementation

1. Go to **Admin & Settings → Applications → Add New Application → OAuth Client**. Select only relevant scopes.
2. On the new Application, open **Admin & Settings**, select the needed permission and save. Audit clients should use **Audit logs → Use API** and scope `audit.log:read`, not audit log manage privileges.
3. Store the client secret in the approved secret store, test least privilege, and retire unused legacy API or AppKey authentication where supported.

Source: [Vendor configuration reference](https://developer.celonis.com/celonis-apis/connecting-to-celonis-platform).

#### Code Implementation

The vendor supports OAuth client setup through the console. No provisioning or audit application write is included.

#### Validation & Testing

Check the client permission and token scope; demonstrate a known permitted test call with no unintended service scopes.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Changing client grants or authentication methods can break jobs. Parallel-test replacements before rotation.

#### Rollback Procedure

Restore required service using a new short-lived scoped configuration; never reuse an exposed credential.

---
### 2.2 Read a bounded team audit sample

**Profile Level:** L2 (Walk)

#### Description

Confirm audit monitoring reaches the intended team using a dedicated read-only client and protect the details recorded in audit events.

#### Rationale

- Events can contain users, IP addresses and before/after settings. Exporting full records to a poorly secured destination creates a new sensitive dataset.

#### Prerequisites

Authorized team host from the real tenant, a short-lived OAuth access token with `audit.log:read`, and **Use Audit Logs API** permission.

#### ClickOps Implementation

1. In **Admin & Settings**, inspect team audit events and confirm an approved benign change appears.
2. Verify the intended team in the tenant Swagger UI. For sustained collection, bound date intervals and use the documented v2 cursor rather than persisting uncontrolled event copies.

Source: [Vendor configuration reference](https://developer.celonis.com/celonis-apis/audit-log-api/openapi/openapi-external-v2/audit-log-api).

#### Code Implementation

Set the tenant hostname (not a URL or path) and the authorized short-lived OAuth token. The script reads one record at most, prints only count and cursor presence, and recognizes documented 204 no-content. It uses the live endpoint form with /log described in the vendor overview.

{% include pack-code.html vendor="celonis" section="2.2" %}

#### Validation & Testing

A successful sample confirms response shape and reports whether more results exist; an empty sample is not a pass for logging coverage. Confirm specific controls using Portal evidence.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Protect audit metadata and token use; audit client changes can interrupt monitoring.

#### Rollback Procedure

Restore the approved collector settings or revoke an unused collector credential. Handle collected records under policy.

---

## 3. Compliance Quick Reference

These mappings indicate how settings can contribute to a control objective; they do not establish conformity or operation over a period.

| HTH control | NIST SP 800-53 Rev. 5 | Evidence to retain |
| --- | --- | --- |
| 1.1 | AC-2 | Pilot lifecycle and role evidence |
| 2.1 | AC-6, IA-5 | Approved client scope and application permission |
| 2.2 | AU-2, AU-9 | Team-specific monitoring evidence |

## Appendix A: Automation and Evidence

Vendor v2 OpenAPI shows the service path without /log in the mock server example; the production overview instructions and tenant Swagger use /log. This implementation targets that production form, rejects unrelated domains, and does not fetch subsequent cursor pages. No live Celonis account was used.

## Appendix B: References

- [Audit API production route](https://developer.celonis.com/celonis-apis/audit-log-api/overview)
- [OAuth migration and team Swagger URL](https://developer.celonis.com/celonis-apis/migrating-to-oauth)
- [Scope catalog](https://docs.celonis.com/en/available-oauth-scopes.html)

## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial platform controls and documented verification packs | How to Harden Community |

## Contributing

Report inaccurate or outdated guidance through the [issue tracker](https://github.com/grcengineering/how-to-harden/issues).
