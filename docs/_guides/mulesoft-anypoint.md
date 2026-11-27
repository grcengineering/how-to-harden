---
layout: guide
title: "MuleSoft Anypoint Platform Hardening Guide"
vendor: "MuleSoft Anypoint Platform"
slug: "mulesoft-anypoint"
platform: "Salesforce"
platform_slug: "salesforce"
product: "MuleSoft Anypoint Platform"
tier: "3"
category: "DevOps"
description: "Harden Anypoint federated access, connected apps and audit coverage."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden Anypoint federated access, connected apps and audit coverage.

[Salesforce completed its acquisition of MuleSoft](https://www.salesforce.com/news/press-releases/2018/05/02/salesforce-completes-acquisition-of-mulesoft/). The [Salesforce CRM guide](/guides/salesforce/) does not configure the Anypoint control plane.

**Validation status:** Documented control paths and offline Code Pack behavior; no live tenant, credentials, or production changes. License and effective permissions may limit visibility.

### Intended Audience

Platform owners, identity administrators, and security reviewers.

### How to Use This Guide

- **L1 (Crawl):** Establish accountable identities and least privilege.
- **L2 (Walk):** Add narrower access boundaries and independent monitoring.

### Scope

Anypoint Platform Access Management and organization/business-group controls. Runtime configuration, API gateways and Private Cloud Edition require separate review.

## Table of Contents

1. [Access and Administration](#1-access-and-administration)
2. [Network, Integrations and Audit](#2-network-integrations-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and Administration

### 1.1 Constrain federation and environment authority

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, IA-2(1) |

#### Description

Configure external identity at the root and scope users and automation to appropriate business groups and environments.

#### Rationale

**Why This Matters:**

- Business-group roles or local users may survive an IdP-side change, and role inheritance can expose production resources.

#### ClickOps Implementation

1. Confirm the available plan and effective administrative permissions in the [vendor documentation](https://docs.mulesoft.com/access-management/sso-prerequisites-about).
2. Open Access Management. Configure the organization identity provider and enforce MFA at the IdP, then assign only needed permissions through Teams and verify business-group and environment boundaries. Inventory older local users and explicitly offboard them; removing a user from the IdP alone does not remove the Anypoint organization user.

**Automation:** The first-party CLI pack uses existing Connected App authentication and lists caller-visible environments. It does not validate SSO enforcement or enumerate effective permissions.

#### Code Implementation

{% include pack-code.html vendor="mulesoft-anypoint" section="1.1" %}

#### Validation & Testing

Verify an IdP test user can access only the approved environment, and reconcile the CLI environment inventory with the caller’s assigned scope. Verify ordinary user permissions separately.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, IA-2(1) |

## 2. Network, Integrations and Audit

### 2.1 Review integration clients and Connected App scopes

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Assign each approved integration its own client, scoped to the minimum permissions and environment.

#### Rationale

**Why This Matters:**

- Unowned client credentials can continue accessing integration infrastructure after personnel or service changes.

#### ClickOps Implementation

1. Confirm the available plan and effective administrative permissions in the [vendor documentation](https://docs.mulesoft.com/access-management/creating-connected-apps-dev).
2. As a root organization administrator, review Connected Apps in Access Management; document owner, grant type, allowed redirect URIs and scopes. Remove unused scope only after impact review and set credential expiry or schedule rotation where supported.

**Automation:** The Terraform pack creates a new internal Connected App for the single documented Read Applications permission in an explicitly approved environment. Review the plan; do not use it as a generic integration template or apply it over an existing app. Protect state because it contains the created credential.

#### Code Implementation

{% include pack-code.html vendor="mulesoft-anypoint" section="2.1" %}

#### Validation & Testing

Compare approved integration records to what the root administrator sees in the Connected Apps UI, checking business group and environment scope. Treat the REST client count as separate coverage because not all clients are Connected Apps.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

### 2.2 Protect access-management audit evidence

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-12 |

#### Description

Review log visibility in each business group and export records before retention expires.

#### Rationale

**Why This Matters:**

- A viewer limited to a business group cannot attest to organization-level activity. Certain external login failure modes are not logged here.

#### ClickOps Implementation

1. Confirm the available plan and effective administrative permissions in the [vendor documentation](https://docs.mulesoft.com/access-management/audit-logging).
2. In Access Management → Audit Logs, assign the Audit Log Viewer permission to a designated reviewer and confirm the covered groups. Review retention settings and export using the supported integration when available. Use IdP logs for complementary authentication coverage.

**Automation:** The vendor documents the Audit Log Query API and Telemetry Exporter. No query or write pack is claimed for tenant-specific log export.

#### Validation & Testing

Reconcile an approved test Access Management event with the appropriate scope, actor, target and timestamp. Confirm retention and verify centralized delivery where configured.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-12 |

## 3. Compliance Quick Reference

These mappings support control design; they are not evidence of certification or operating effectiveness.

| Section | Control | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 | Constrain federation and environment authority | AC-6, IA-2(1) |
| 2.1 | Review integration clients and Connected App scopes | AC-6 |
| 2.2 | Protect access-management audit evidence | AU-12 |

## References

- [Access Management overview](https://docs.mulesoft.com/access-management/)
- [Terraform access management resources](https://docs.mulesoft.com/mulesoft-terraform-provider/access-management-resources)

## Changelog

- **0.1.0 (2026-11-27):** Initial guide and documented automation examples.
