---
layout: guide
title: "Anaplan Hardening Guide"
vendor: "Anaplan"
slug: "anaplan"
tier: "2"
category: "HR/Finance"
description: "Restrict Anaplan authentication origins and model grants and preserve audit evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Anaplan's tenant security settings, workspace administration and model-level access are distinct. This guide applies to Anaplan Connected Planning. Audit availability and retention depend on entitlement; authenticate only to the correct tenant.

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

### 1.1 Stage tenant IP allowlisting

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-17

#### Description

Restrict authentication to approved stable network paths for supported users and clients.

#### Rationale

- IP rules reduce exposure of credentialed access paths, but do not replace MFA and do not cover all visitors or clients.

#### ClickOps Implementation

In **Administration**, use the **IP Allowlist** security setting as a tenant security administrator. Add the approved public egress address or ranges before enabling it, and record recovery routing. Check Anaplan's supported-client matrix before assuming mobile, OAuth, integrations or add-ins inherit the policy.

Source: [Anaplan documentation](https://help.anaplan.com/ip-allowlist-90adad3e-aa57-44c1-8ec4-71ca1a25a563) (checked 2026-11-27).

**Automation:** No approved setter for the tenant allowlist was established; check the configured state in Administration.

#### Validation & Testing

Test new sessions for each required supported login and connector from approved egress and separately test disallowed egress. The allowlist is for the default tenant and does not block visiting users; record those paths separately.

---

### 1.2 Review model role and data access

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-6

#### Description

Grant model roles, workspace administration and selective access separately.

#### Rationale

- Workspace administration and Full Access are broader than a normal financial operator needs. List and cell access can introduce further exposure even when model roles appear reasonable.

#### ClickOps Implementation

Under **Administration → Access Control → Roles**, review broad tenant assignments. In the model's **Users** pane, review workspace administrators and map users to narrowly defined model roles. Set permissions for modules, versions, lists and actions. Use Selective Access for applicable list items and separately review Dynamic Cell Access where required.

Source: [Anaplan documentation](https://help.anaplan.com/control-user-access-within-models-8c495688-216e-49c4-aa56-a4b70487e5d7) (checked 2026-11-27).

**Automation:** Anaplan Connect can run preconfigured integration actions. It is not a general-purpose tenant policy setter.

#### Validation & Testing

Test a synthetic operator against one permitted and one outside-scope module and list item. Check access to imports and exports independently. Do not use a workspace administrator as the restricted test identity.

---

### 1.3 Collect tenant audit evidence

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AU-6

#### Description

Use the dedicated tenant auditor role on a licensed tenant and collect a short audit sample.

#### Rationale

- Anaplan Audit retains only the documented edition-dependent history window; untreated expiry can eliminate useful evidence.

#### ClickOps Implementation

Have a tenant administrator verify Audit is enabled and assign the collector **Tenant Auditor** instead of general administration. Review events in **Administration → Audit** and scope continuing collection to relevant events and time windows.

Source: [Anaplan documentation](https://help.anaplan.com/audit-034cf52f-8ccf-49e0-a545-96861b12a645) (checked 2026-11-27).

**Automation:** Documented Audit API GET retrieves a bounded sample; it does not enable log collection.

#### Code Implementation

{% include pack-code.html vendor="anaplan" section="1.3" %}

#### Validation & Testing

Make an approved benign change in nonproduction and reconcile actor, event, timestamp and tenant. Review pagination and retention in a sustained ingestion workflow; one evidence page does not establish complete logging.

## 2. Compliance Quick Reference

These relationships support the named control objectives. They are not certification or compliance claims.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Stage tenant IP allowlisting | AC-17 |
| 1.2 | Review model role and data access | AC-6 |
| 1.3 | Collect tenant audit evidence | AU-6 |

### References

- [Client coverage of IP allowlisting](https://help.anaplan.com/anaplan-tools-covered-by-the-ip-allowlist-c39707d0-ab62-407e-896f-b41519ba76e9)
- [Administration roles](https://help.anaplan.com/administration-roles-84718424-a9ea-4d55-a25b-a1ee2e73e7f4)
- [Anaplan Connect](https://help.anaplan.com/anaplan-connect-e3a9f00c-3924-4cfb-aed0-1ec14233821b)
- [Coverage and validation boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-data-platform-next-source-coverage.md)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial customer controls and a read-only evidence pack; no live tenant validation. |
