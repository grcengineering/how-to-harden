---
layout: guide
title: "Domo Hardening Guide"
vendor: "Domo"
slug: "domo"
tier: "2"
category: "Data"
description: "Control Domo analytics roles, personalized data permissions, API clients and audit evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Domo tenant governance, SAML separation, API clients, and connected DataSet access have different owners. This guide covers the standard Domo instance and does not assume an embedded deployment uses these identical settings.

### Intended Audience

- Tenant administrators, business system owners and integration operators
- Security engineers and reviewers who need traceable configuration evidence

### How to Use This Guide

L1 (Crawl) is the initial baseline. Inventory the current behavior, confirm plan requirements, and pilot changes with approved nonproduction identities and synthetic data before changing production settings.

### Scope

This guide covers the controls below, with offline-tested evidence only. No live tenant or credentials were used. Code Packs do not perform remediation, assert complete audit coverage, or inspect tenant configuration beyond their named read.

## Table of Contents

1. [Security Configuration](#1-security-configuration)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Security Configuration

### 1.1 Review Domo security roles

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-6

#### Description

Keep the system Admin role narrowly assigned; use targeted custom grants for delegated tasks.

#### Rationale

- A broad security role can reach unrelated people, DataSets and governance settings. A role assigned to one profile is not a complete accounting of access.

#### ClickOps Implementation

Open **More → Admin → Governance → People**, select one user, and compare the **Domo security role** to approved responsibility. Review group-derived and custom grants separately. Coordinate user/email changes with the SAML sign-in owner because a mismatched account may lose access.

Source: [Domo documentation](https://domo-support.domo.com/minasan/s/article/360043438933?language=en_US) (checked 2026-11-27).

**Automation:** The official Users API supports single-user lookup. This pack exposes only a returned ID and role; it does not remediate or prove all effective grants.

#### Code Implementation

{% include pack-code.html vendor="domo" section="1.1" %}

#### Validation & Testing

Check an approved test user can perform an authorized task without unrelated administrative access. Retrieve one recorded user ID when the existing connector is approved to read it; compare the role against the UI.

---

### 1.2 Preserve PDP on output datasets

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-3

#### Description

Restrict row-level access to sensitive DataSets and reapply policies after transformations.

#### Rationale

- Domo does not permit an input DataSet to restrict a DataFlow using PDP. Unprotected outputs can expose rows even if the source is restricted for ordinary users.

#### ClickOps Implementation

Inventory sensitive DataSets, DataFlow outputs and all-row exceptions. In Data Center, set reviewed PDP policies on affected output DataSets, minimize all-row grants, and examine Publication Group policies separately; Domo says those policies supersede PDP.

Source: [Domo documentation](https://domo-support.domo.com/minasan/s/article/360055259234?language=en_US) (checked 2026-11-27).

**Automation:** The Domo API/SDK documents PDP operations; this starter does not configure DataSets in code.

#### Validation & Testing

Verify two synthetic users with different allowed rows see the expected output in the dashboard and any approved downstream sharing flow. An exported file contains what its exporter saw and does not keep the original security policy.

---

### 1.3 Minimize OAuth client scope

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-9

#### Description

Scope each API client to its workload, record its owner and revoke obsolete clients only after checking dependencies.

#### Rationale

- The OAuth token may authorize multiple data and governance scopes. It remains a separate access path from ordinary SAML controls.

#### ClickOps Implementation

In Domo Admin Settings, open **API Clients** and review owners and exact scopes. Restrict who holds **Create API OAuth Clients** and the admin grant **Manage All Access Tokens and API Clients**. Revoke obsolete clients after consumers have moved; preserve incident evidence where required.

Source: [Domo documentation](https://domo-support.domo.com/minasan/s/article/000005240?language=en_US) (checked 2026-11-27).

**Automation:** No matching API-client policy write handle was verified in the reviewed public developer materials.

#### Validation & Testing

Compare the owner and scope inventory to the integration approval. Test a harmless permitted operation under the new client and verify old integrations are inactive before revocation.

---

### 1.4 Review activity evidence independently

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AU-6

#### Description

Delegate log viewing narrowly and export evidence using scoped filters.

#### Rationale

- Log exports reflect the selected filters. Absence of a record in a narrow export does not demonstrate absence of a change.

#### ClickOps Implementation

In **More → Admin → Governance → Activity Log**, use a narrow time and event scope. Delegate **View Activity Logs** instead of Administrator when feasible. Review CSV export and data protection controls; DomoStats logs and the beta webhook are distinct mechanisms.

Source: [Domo documentation](https://domo-support.domo.com/minasan/s/article/360042934574?language=en_US) (checked 2026-11-27).

**Automation:** The existing read pack is a role lookup, not a collection of activity log records.

#### Validation & Testing

Reconcile an approved test event to the displayed date, actor, type and object. Recheck filters if it is missing, and verify a separate schedule if using DomoStats.

## 2. Compliance Quick Reference

These relationships support the named control objectives. They are not certification or compliance claims.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Review Domo security roles | AC-6 |
| 1.2 | Preserve PDP on output datasets | AC-3 |
| 1.3 | Minimize OAuth client scope | IA-9 |
| 1.4 | Review activity evidence independently | AU-6 |

### References

- [Publication Groups precedence](https://domo-support.domo.com/minasan/s/article/360043438993?language=en_US)
- [Domo client and scopes](https://developer.beta.domo.com/explorer)
- [Domo SDK transport and authentication](https://github.com/domoinc/domo-python-sdk/blob/master/pydomo/Transport.py)
- [Coverage and validation boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-data-platform-next-source-coverage.md)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial customer controls and a read-only evidence pack; no live tenant validation. |
