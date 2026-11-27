---
layout: guide
title: "UiPath Automation Cloud Hardening Guide"
vendor: "UiPath Automation Cloud"
slug: "uipath-automation-cloud"
tier: "2"
category: "DevOps"
description: "Restrict Automation Cloud identity and network access, and verify audit visibility."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Scope: commercial UiPath Automation Cloud organization at cloud.uipath.com, not Automation Suite, Public Sector, or Dedicated. The API evidence pack covers the Unified Audit experience at organization level.

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

### 1.1 Federate Workforce and Govern Robot Access

**Profile Level:** L1 (Crawl)

#### Description

Use approved organization federation for humans and separate robot or application credentials and role assignments.

#### Rationale

**Why This Matters:**

- Sharing human administrative credentials with automations defeats individual accountability and lifecycle controls.

#### Prerequisites

An organization admin and supported enterprise IdP. Identify workforce, robot and connection dependencies before rollout.

#### ClickOps Implementation

1. Select the organization in **Admin > Security > Authentication Settings**, configure **SAML SSO**, and assign approved pilot users and groups.
2. Configure provisioning rules that grant only the necessary access; check the identity provider claim used to match accounts.
3. Require MFA in the IdP and document recovery access. Review non-human credentials separately rather than assuming SAML protections extend to robot accounts.

**Source:** [Vendor administration documentation](https://docs.uipath.com/automation-cloud/automation-cloud/latest/admin-guide/configuring-the-saml-integration).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Test authorized sign-in and denied unassigned access, plus a representative robot job that uses its own approved credentials.

#### Operational Impact

Bad claim mappings can deny automation operators access or grant an unintended role. Pilot before broad rollout.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | IA-2, AC-6 | Supports this objective; configuration alone does not establish compliance. |

### 1.2 Restrict Organization Access by IP

**Profile Level:** L2 (Walk)

#### Description

On entitled Enterprise plans, enforce the trusted network policy for users, robots and APIs.

#### Rationale

**Why This Matters:**

- An independently enforced network boundary reduces risk from a leaked access token or credential.

#### Prerequisites

Enterprise entitlement, approved egress list including recovery access, and separate testing organization.

#### ClickOps Implementation

1. Go to **Admin > organization > Security Settings > IP Restriction** and stage approved ranges for staff, workloads and recovery operators.
2. In nonproduction confirm allowed ranges cover all necessary clients. In **Enforcement type**, choose **Allow only trusted IPs** and confirm once ready.
3. Verify ordinary and machine access before applying to production.

**Source:** [Vendor administration documentation](https://docs.uipath.com/automation-cloud/automation-cloud/latest/admin-guide/restricting-access-by-ip).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Check both the range inventory and enforcement mode. A populated list with **Allow all IPs** does not restrict traffic.

#### Operational Impact

The setting affects organization APIs, all tenant services and robots. Keep a known-good egress path and documented support procedure.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | SC-7 | Supports this objective; configuration alone does not establish compliance. |

### 1.3 Verify Unified Audit Collection

**Profile Level:** L2 (Walk)

#### Description

Review organization-level events and verify independent retention for sources onboarded to Unified Audit.

#### Rationale

**Why This Matters:**

- Protected records let operators corroborate high-risk changes and investigate access.

#### Prerequisites

Commercial cloud organization, new audit experience, and an approved short-lived token with only the required PM.Audit.Read scope and applicable organization permissions.

#### ClickOps Implementation

1. Open **Admin > Audit logs** and confirm which experience is active. Evaluate the new experience and retain an approved history before migration.
2. Confirm the selected sources include required high-risk organization and tenant events.
3. Correlate a known, authorized event with API and export evidence in an independently protected location.

**Source:** [Vendor administration documentation](https://docs.uipath.com/automation-cloud/automation-cloud/latest/api-guide/audit-logs).

#### Code Implementation

{% include pack-code.html vendor="uipath-automation-cloud" section="1.3" %}

#### Validation & Testing

The sample shows the event source, type, result and timestamp, without actors or full details. Confirm expected events in the console and monitor the real export path separately.

#### Operational Impact

The sample is not a complete audit export, and the coverage of classic and unified audit experiences differs.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AU-6, AU-12 | Supports this objective; configuration alone does not establish compliance. |

## 2. Compliance Quick Reference

| Control | Profile | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 Federate Workforce and Govern Robot Access | L1 | IA-2, AC-6 |
| 1.2 Restrict Organization Access by IP | L2 | SC-7 |
| 1.3 Verify Unified Audit Collection | L2 | AU-6, AU-12 |

## References

- [Source and validation notes](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-fourth-dev-source-coverage.md)

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-11-27 | Initial documentation-derived guide and verification packs |
