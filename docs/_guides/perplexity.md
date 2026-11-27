---
layout: guide
title: "Perplexity Enterprise Hardening Guide"
vendor: "Perplexity Enterprise"
slug: "perplexity"
tier: "3"
category: "AI/ML Platform"
description: "Perplexity Enterprise connects organization members, Projects, search, and Computer to enterprise content and third-party tools"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

**Product Editions Covered:** Perplexity Enterprise Pro and Enterprise Max, where feature entitlements are assigned

## Overview

Perplexity Enterprise connects organization members, Projects, search, and Computer to enterprise content and third-party tools. Configure roles, connector access, retention and evidence separately; an Enterprise workspace is not the separately billed API Platform.

### Intended Audience

Platform administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Baseline controls for the documented deployment.
- **L2 (Walk):** Add verified controls where the workload needs stronger isolation.
- **L3 (Run):** Add controls warranted by higher-risk workflows and contractual requirements.

### Scope

Covers the Perplexity Enterprise organization control plane. Comet device/MDM configuration, public developer inference APIs, and source app permissions are separate. Confirm the contract: custom roles and connector RBAC require sales-assisted Enterprise; Audit Logs and custom session retention generally require at least 50 seats or at least one Enterprise Max seat.

---

## Table of Contents

1. [Identity and Privilege](#1-identity-and-privilege)
2. [Connector Isolation](#2-connector-isolation)
3. [Retention and Evidence](#3-retention-and-evidence)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Identity and Privilege

### 1.1 Assign only necessary roles and scoped groups

**Profile Level:** L1 (Crawl)

#### Description

Keep protected Admin privileges with approved administrators. Remove unnecessary permissions from broad roles and use narrower custom roles with just the permissions necessary for Computer, API access, and organization management.

#### Rationale

- Perplexity grants the union of all direct and group-assigned roles. A restrictive role does not deny access already granted elsewhere, including the default Member role.

#### Prerequisites

Authorized Enterprise administrator, identity/group ownership inventory, and at least one verified recovery admin. Custom roles and SCIM group sync require the relevant sales-assisted entitlement.

#### ClickOps Implementation

1. Open **Organization Settings → Roles & Permissions**. Review built-in roles and previously migrated access.
2. Where entitled, create a narrow custom role and assign only approved users or SCIM groups. Edit SCIM-synced membership in the identity provider, not Perplexity.
3. Verify the organization-wide master switch before relying on role-based Computer access.

Source: [Vendor configuration reference](https://www.perplexity.ai/help-center/en/articles/11187754-enterprise-roles-and-permissions).

#### Code Implementation

ClickOps and the IdP’s documented provisioning flow. The Audit API provides historical evidence, not a role or SCIM policy read/write API.

#### Validation & Testing

Test a pilot member with and without the role, accounting for additional groups. Verify an approved IdP deprovisioning exercise removes access and review the associated role/group events; not all bulk/SCIM seat changes appear in the audit feed.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Removing role privileges may break jobs or connector usage. Check every role assignment that would be affected.

#### Rollback Procedure

Restore the specific approved role assignment from a verified administrator. Do not broaden the Member role to fix one pilot failure.

---

## 2. Connector Isolation

### 2.1 Disable new connectors by default and scope existing connectors

**Profile Level:** L1 (Crawl)

#### Description

Set New connectors to Disabled, inventory currently enabled integrations and grant access only to the approved roles. Restrict individual tool permissions independently.

#### Rationale

- Connector access does not revoke existing third-party OAuth grants. Enabling a connector with All Members defeats the intended custom-role boundary.

#### Prerequisites

Sales-assisted Enterprise connector RBAC entitlement, approved integration inventory, and test identities with distinct authorized role memberships.

#### ClickOps Implementation

1. Open **Organization Settings → Connectors** and set **New connectors → Disabled**. Review **Allow members to add custom connectors** separately.
2. Open each approved connector and use **Access → General access → Selected roles**. Remove All Members and grant the intended custom roles.
3. Review **Base tool permissions** and disallow actions that are not needed. For offboarded integrations, separately remove the OAuth grants through the source provider or Perplexity Plugins.

Source: [Vendor configuration reference](https://www.perplexity.ai/help-center/en/articles/2026100201-role-based-access-control-for-connectors).

#### Code Implementation

The current public administrative references document the connector control through the UI. No tenant policy setter for these fields was verified.

#### Validation & Testing

Confirm role and tool lists. Use two synthetic users to test the permitted read path and rejection of the unassigned user; the source data permissions should also be verified in the source app.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Existing connectors can retain broad access after feature migration. Disabling a connector affects all its current users and preserves its roster for future re-enable.

#### Rollback Procedure

Restore only the approved role/tool combination. Never re-enable without checking the saved role list and stale OAuth grants.

---

## 3. Retention and Evidence

### 3.1 Set an approved session retention policy

**Profile Level:** L2 (Walk)

#### Description

Use session retention settings and consider forced Incognito where required and operationally suitable. Set different retention for independently governed Files, Projects and exported audit data.

#### Rationale

- Aging sessions creates a retained data surface. Session retention can delete older conversations on configuration change and does not define retention for separate copies, such as exported audit logs.

#### Prerequisites

Eligible seats and organization settings access. Obtain recorded policy, legal hold guidance and authorization before shortening retention.

#### ClickOps Implementation

1. Open **Organization Settings → Data and privacy → Data Retention**. Review **Enforce Incognito Mode** and **Set data retention for sessions**.
2. Confirm the session population and existing legal-hold obligations, then select the approved retention period.
3. Verify independent Project/My Files retention and the export destination retention policy.

Source: [Vendor configuration reference](https://www.perplexity.ai/help-center/en/articles/11652701-data-retention-for-enterprise).

#### Code Implementation

ClickOps only in the reviewed admin references. No safe automatic policy writer is supplied.

#### Validation & Testing

Inspect the setting and test with synthetic sessions. Retention is based on last activity; recurring follow-ups reset it. Pre-membership sessions and separate file stores are not equivalent coverage.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Shortening makes older sessions immediately inaccessible and deletes them within the vendor window; it is not recoverable.

#### Rollback Procedure

Restore the approved duration to govern future activity, but do not expect deleted sessions to return. Pause rather than shorten if preservation scope is uncertain.

---
### 3.2 Enable audit logging and sample stored admin events

**Profile Level:** L2 (Walk)

#### Description

Enable organization audit logging and issue a separate, org-scoped Audit API key for the collector. Use a protected destination and log only approved fields.

#### Rationale

- Audit records establish evidence of covered administrative changes, not complete visibility into every action. Metadata may contain captured content and personal data even after specific credential redactions.

#### Prerequisites

Eligible organization; administrator to enable logging; key-management role with View audit logs and Perplexity API permissions; protected evidence workflow.

#### ClickOps Implementation

1. Open **Organization Settings → Data and privacy → Audit Log Settings** and enable Audit Logging.
2. Open **Enterprise APIs → Audit API**, create a uniquely named key and secure it. No webhook is required for pull-only use.
3. If using a webhook, authenticate it and monitor timely acknowledgments; failed deliveries are not automatically retried.

Source: [Vendor configuration reference](https://www.perplexity.ai/help-center/en/articles/11652747-audit-logs).

#### Code Implementation

Read-only Audit API sample, with metadata withheld. The scope cannot call model APIs or write workspace settings. Use explicit pagination for a complete collector; this sample is deliberately bounded.

{% include pack-code.html vendor="perplexity" section="3.2" %}

#### Validation & Testing

Use a known approved synthetic setting change and confirm the corresponding event appears. The sample returns one page of only setting-change event identifiers, timestamps and types; no records is not proof of compliance. A successful read itself produces an audited event.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

History starts only after enabling and API freshness is not guaranteed. Webhook and API payloads differ; filter and retain output separately from product retention.

#### Rollback Procedure

Revoke the dedicated key when retiring a collector. Disabling audit logging does not revoke keys, and surviving keys can work again after re-enabling.

---

## 4. Compliance Quick Reference

These mappings indicate how settings can contribute to a control objective; they do not establish conformity or operation over a period.

| HTH control | NIST SP 800-53 Rev. 5 | Evidence to retain |
| --- | --- | --- |
| 1.1 | AC-2, AC-6 | Role/group review and synthetic entitlement checks |
| 2.1 | AC-3, AC-6 | Connector policy, tool scopes and separately verified OAuth grants |
| 3.1 | SI-12 | Approved retention and synthetic retention observation |
| 3.2 | AU-2, AU-6, AU-9 | Known event and collector scope |

## Appendix A: Automation and Evidence

The documented Enterprise Audit API has a dedicated key and is not the Sonar or Agent API. The Perplexity CLI documentation was reviewed separately; no Enterprise audit or tenant policy CLI operation was verified. No Terraform provider, SDK audit method or native organization-policy configuration format was verified in the reviewed references. No Perplexity-specific CIS, STIG or SCuBA benchmark equivalence claimed; no tenant authorization or live verification performed.

## Appendix B: References

- [Perplexity enterprise plan gates](https://www.perplexity.ai/help-center/en/articles/12310544-what-is-enterprise-max)
- [Perplexity Audit API](https://docs.perplexity.ai/docs/admin/audit-api)
- [Perplexity CLI documentation](https://docs.perplexity.ai/docs/cli/overview)

## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial platform controls and documented verification packs | How to Harden Community |

## Contributing

Report inaccurate or outdated guidance through the [issue tracker](https://github.com/grcengineering/how-to-harden/issues).
