---
layout: guide
title: "Adobe Workfront Hardening Guide"
vendor: "Adobe Workfront"
slug: "adobe-workfront"
platform: "Adobe"
platform_slug: "adobe"
product: "Workfront"
tier: "2"
category: "Productivity"
description: "Secure Adobe Workfront product profiles, access levels, technical accounts and audit events."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

For organization-wide identity and entitlements, start with the [Adobe Admin Console common controls](/guides/adobe-admin-console/). Workfront has additional product controls below.

## Overview

Workfront's Adobe Admin Console entitled identities and Workfront-native access levels and per-object sharing are separate. This starter does not stand in for tenant hardening of Creative Cloud, Workfront Fusion, or Workfront Planning.

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

### 1.1 Review Workfront administrator assignments

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-6

#### Description

Use the Adobe Admin Console to separate Workfront product-profile administration from ordinary membership.

#### Rationale

- Product Profile Administrator is a high-impact entitlement. Workfront's in-product access display alone is not the governing source for creating or removing those administrators.

#### ClickOps Implementation

In **Adobe Admin Console**, select the correct Workfront product and instance and review its product profile administrators separately from member access. Remove only out-of-policy assignments with change approval and a tested backup administrator; Workfront documents Admin Console as the configuration authority for this role.

Source: [Adobe Workfront documentation](https://experienceleague.adobe.com/en/docs/workfront/using/administration-and-setup/add-users/create-manage-users/admin-console) (checked 2026-11-27).

**Automation:** Adobe User Management API reads one Adobe identity's group and admin-role indicators; use the matching Workfront product profile in the reviewed policy, not an inferred role name.

#### Code Implementation

{% include pack-code.html vendor="adobe-workfront" section="1.1" %}

#### Validation & Testing

For a known approved test identity, compare Admin Console group/role evidence with its current effective capabilities in the intended Workfront instance. Adobe UMAPI evidence is organization scoped and does not establish per-project rights.

---

### 1.2 Limit access levels and object sharing

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-3

#### Description

Assign the narrowest Workfront access level and grant object-level permissions only where required.

#### Rationale

- A user must have an access level, and the combination of that level and object permissions determines effective access. Reviewing just one layer can miss inappropriate capabilities.

#### ClickOps Implementation

In Workfront, review the assigned access level and its permitted access to relevant object types. Prefer a suitable built-in level or copy a built-in level and narrow the custom copy. Check the affected project or document sharing setting and its recipient groups separately.

Source: [Adobe Workfront documentation](https://experienceleague.adobe.com/en/docs/workfront/using/administration-and-setup/add-users/access-levels/access-level-overview) (checked 2026-11-27).

**Automation:** The Adobe Admin Console evidence pack does not verify the full set of Workfront object ACLs.

#### Validation & Testing

Verify a restricted test user can view an approved object but cannot edit or access a different object outside policy. Retest after changes to groups or templates.

---

### 1.3 Migrate and scope integration identities

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-9

#### Description

Use Adobe Developer Console credentials with one reviewed technical account per integration or workload boundary.

#### Rationale

- Technical accounts have a Workfront user and can gain access independently from human users. Legacy OAuth registrations are being retired, and migrating without rechecking Workfront grants can break or overprivilege the integration.

#### ClickOps Implementation

In **Adobe Developer Console**, use an approved Workfront API project for the correct instance and configure the appropriate documented authentication flow. In Workfront, find the matching technical account and assign the narrowest approved access. Do not make the account a product-profile administrator to work around unsupported access. Adobe states new legacy OAuth2 registrations ended November 1, 2026 and existing legacy apps stop working February 1, 2027.

Source: [Adobe Workfront documentation](https://experienceleague.adobe.com/en/docs/workfront/using/administration-and-setup/configure-integrations/migrate-oauth2-to-developer-console) (checked 2026-11-27).

**Automation:** Adobe Developer Console credential issuance is documented; no Workfront tenant policy change is automated.

#### Validation & Testing

Validate a benign permitted read and an out-of-scope check in nonproduction, then verify the workload uses the new approved credential before removing the old integration.

---

### 1.4 Reconcile changes through Audit Logs

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AU-6

#### Description

Collect administrator audit records for changes to users and access levels.

#### Rationale

- A role change that is not reconciled to the approved workflow can go unnoticed until the next access review.

#### ClickOps Implementation

In Workfront **Setup → Change Tracking → Audit Logs**, filter relevant log types and time period. Review user and access-level change records and export approved evidence before the documented 90-day window elapses.

Source: [Adobe Workfront documentation](https://experienceleague.adobe.com/en/docs/workfront/using/administration-and-setup/add-users/create-manage-users/audit-logs) (checked 2026-11-27).

**Automation:** No public Workfront admin-audit export API matched to these exact UI fields was verified.

#### Validation & Testing

Compare a benign change in a test instance to its actor, time and log type. Verify filters before treating an empty result as evidence.

## 2. Compliance Quick Reference

These relationships support the named control objectives. They are not certification or compliance claims.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Review Workfront administrator assignments | AC-6 |
| 1.2 | Limit access levels and object sharing | AC-3 |
| 1.3 | Migrate and scope integration identities | IA-9 |
| 1.4 | Reconcile changes through Audit Logs | AU-6 |

### References

- [View and export Workfront audit logs](https://experienceleague.adobe.com/en/docs/workfront/using/administration-and-setup/add-users/create-manage-users/view-and-export-audit-logs)
- [Provision access for Workfront API technical accounts](https://developer.adobe.com/workfront-apis/guides/gaining-access/)
- [UMAPI authentication](https://adobe-apiplatform.github.io/umapi-documentation/en/UM_Authentication.html)
- [Coverage and validation boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-data-platform-next-source-coverage.md)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial customer controls and a read-only evidence pack; no live tenant validation. |
