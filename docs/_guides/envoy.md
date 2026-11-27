---
layout: guide
title: "Envoy Hardening Guide"
vendor: "Envoy"
slug: "envoy"
tier: "1"
category: "IT Operations"
description: "Harden the Envoy workplace tenant supporting Envoy Visitors."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden the Envoy workplace tenant supporting Envoy Visitors. Scope covers tenant roles, authentication, visitor retention and location inventory. It does not cover the Envoy Proxy project, on-premises physical access devices, or regulation-specific retention requirements.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Directory and access](#1-directory-and-access)
2. [Privacy and inventory](#2-privacy-and-inventory)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Directory and access

### 1.1 Require SAML after testing recovery and the global-admin exception

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | IA-2, AC-2 |

#### Description

Stage SAML for administrators and employees, with phishing-resistant MFA in the IdP where possible. Treat the global admin local-password path as a separately protected recovery exception.

#### Rationale

**Why This Matters:**

- Envoy’s Required setting does not remove global administrator password sign-in.

#### Prerequisites

Global admin, IdP administrator, pilot identities and tested recovery access.

#### ClickOps Implementation

1. Go to Apps > Directory and SSO > Directory Settings and configure SAML with the expected IdP metadata.
2. Verify that SAML NameID matches the intended employee directory email. Pilot optional federation before enabling Required.
3. Identify global admins who retain a password sign-in path. Protect those credentials separately and minimize and review their holders.

#### Validation & Testing

Verify employee and location-admin sign-ins use the intended IdP, and separately verify the known approved global-admin recovery path.

#### Monitoring & Maintenance

Review IdP mappings, SAML certificates and global-admin local access.

#### Operational Impact & Rollback

Revert only the failed pilot mapping or required toggle through approved recovery, and re-establish the intended policy after repair.

**Sources:** [Envoy SAML setup](https://envoy.help/en/articles/3450163-setting-up-saml).

### 1.2 Minimize global and sensitive visitor access

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, AC-3 |

#### Description

Assign location or narrowly scoped custom roles for daily visitor operations; separate access to sensitive fields.

#### Rationale

**Why This Matters:**

- A global grant can expose visitor records at every site. Some front-desk walk-up interactions also have a documented access exception.

#### Prerequisites

Authorized global admin and approved location/role reviewers.

#### ClickOps Implementation

1. Open Manage > Roles, review global roles and where local or custom roles can replace them.
2. Review the Access sensitive fields permission for applicable custom roles and validate the expected walk-up exception.
3. Review actual admin assignments and remove unnecessary global or multi-site grants.

#### Validation & Testing

With synthetic or authorized test data, verify a pilot user sees only the intended locations and data outside any approved walk-up exception.

#### Monitoring & Maintenance

Review role changes, sensitive access and offboarding monthly or quarterly as appropriate.

#### Operational Impact & Rollback

Restore only the narrow previous authorized role in the affected location.

**Sources:** [Envoy admin roles and permissions](https://envoy.help/en/articles/6778712-admin-roles-permissions).

## 2. Privacy and inventory

### 2.1 Review visitor retention per flow and location

**Profile Level:** L2

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | SI-12, AC-4 |

#### Description

Set the minimum legally and operationally necessary retention across site and sign-in flow while respecting holds and Workplace data side effects.

#### Rationale

**Why This Matters:**

- Shortening retention may delete data immediately; deleted data cannot be recovered. Omitting sensitive fields from a field-level policy can leave them accessible.

#### Prerequisites

Privacy, legal and data owner approval, documented holds and plan-specific impact review.

#### ClickOps Implementation

1. Go to Manage > Location settings > Data and privacy > Visitor data retention policy and review current retention.
2. Review each intended sign-in flow and eligible fields, including employee registration or Workplace effects under your plan.
3. If shortening would purge records, stop before confirmation until legal holds, scope and irreversible effect are approved.

#### Validation & Testing

Review saved settings and check permitted historical/staging samples for intended retention; avoid exporting production visitor data simply to test configuration.

#### Monitoring & Maintenance

Review data collection and retention after new flows and location changes.

#### Operational Impact & Rollback

Restore future policy settings if authorized. Already discarded data cannot be recovered.

**Sources:** [Envoy visitor data retention](https://envoy.help/en/articles/12356182-data-retention-policy).

### 2.2 Reconcile locations exposed to audit automation

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-8, AC-6 |

#### Description

Use a dedicated scoped OAuth app to inventory configured locations without requesting visitor or employee data.

#### Rationale

**Why This Matters:**

- A stale site or broad OAuth grant can expose location metadata or lead to gaps in site hardening.

#### Prerequisites

Approved site inventory and existing OAuth access restricted to locations.read for this read.

#### ClickOps Implementation

1. Review approved locations in the Envoy dashboard and reconcile open, inactive and retired sites.
2. In Dev Dashboard review the OAuth app scopes and ensure the inventory client requests only locations.read for this task.
3. Compare the returned sample with expected coverage and review unexplained changes with the site owner.

#### Code Implementation

{% include pack-code.html vendor="envoy" section="2.2" %}

#### Validation & Testing

Verify counts separately from location identity and confirm that authorized sites are reviewed in the UI. The pack discards address and visitor metadata.

#### Monitoring & Maintenance

Repeat after location lifecycle events or new OAuth app installations.

#### Operational Impact & Rollback

Revoke or replace the affected integration access and restore intended location coverage; do not expand scopes just to fix an apparent count mismatch.

**Sources:** [Envoy locations API](https://developers.envoy.com/hub/reference/locations-1). [Envoy access scopes](https://developers.envoy.com/hub/docs/scopes). [Envoy JSON:API location example](https://developers.envoy.com/hub/docs/make-your-first-api-request).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Require SAML after testing recovery and the global-admin exception | IA-2, AC-2 |
| 1.2 Minimize global and sensitive visitor access | AC-6, AC-3 |
| 2.1 Review visitor retention per flow and location | SI-12, AC-4 |
| 2.2 Reconcile locations exposed to audit automation | CM-8, AC-6 |

## Appendix A: Automation and applicability

Read-only location evidence is sampled from the v1 endpoint using a preissued scoped OAuth bearer token. The pack does not require visitor, entry, document or employee scopes; it does not auto-change SSO, retention or physical access.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.
