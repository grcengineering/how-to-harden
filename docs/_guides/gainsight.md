---
layout: guide
title: "Gainsight CS Hardening Guide"
vendor: "Gainsight CS"
slug: "gainsight"
tier: "2"
category: "Marketing"
description: "Harden Gainsight CS (NXT) authentication, privileged users, network restrictions and integration credentials."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Gainsight CS centralizes customer-success records and integrations. This guide covers the customer-administered **Gainsight CS (NXT)** tenant, not Gainsight PX, Customer Communities, or the receiving tenant of an outbound integration. [Gainsight product scope](https://support.gainsight.com/v1/docs/gainsight-user-management).

**Validation status:** Source-verified administration paths. The assessment pack is read-only. No customer tenant, network policy, identity provider or connector was modified.

### Intended Audience

Gainsight administrators, identity administrators and owners of CRM and API integrations.

### How to Use This Guide

- **L1 (Crawl):** Establish SAML and recovery access; confirm Super Admin accounts and restrict network access.
- **L2 (Walk):** Scope credentials, verify rotation and retain independent user-change evidence.

### Scope

Check the plan and region when a setting is unavailable. Gainsight organization settings and connector settings are distinct. Maintain external controls on the application that actually authorizes each integration.

For Gainsight Product Experience, use the [Gainsight PX Hardening Guide](/guides/gainsight-px/); CS configuration does not apply there.

## Table of Contents

1. [Identity and Access](#1-identity-and-access)
2. [Network and Integrations](#2-network-and-integrations)
3. [Monitoring and Evidence](#3-monitoring-and-evidence)
4. [Compliance Quick Reference](#4-compliance-quick-reference)
5. [Sources](#5-sources)
6. [Changelog](#changelog)

## 1. Identity and Access

### 1.1 Enable and Validate Enterprise SAML

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2 |

#### Description

Configure Gainsight NXT to use an organization-managed SAML identity provider for supported users. Apply strong MFA at that provider. SAML support is not evidence that direct login is disabled.

#### Rationale

**Why This Matters:**

- Centralized sign-in lets administrators apply the same access and offboarding policy used by the rest of the organization.
- Removing the only working login path before the pilot can lock out administrators.

**Attack Prevented:** Reduces the risk of uncontrolled access on the boundary above; it does not prove complete prevention.

#### ClickOps Implementation

1. Review the [Gainsight authentication setup](https://support.gainsight.com/gainsight_nxt/01Onboarding_and_Implementation/Onboarding_for_Gainsight_NXT/Login_and_Permissions/03Gainsight_Authentication). In the Gainsight administration security configuration, set up SAML with the configured identity provider and verify the login mapping with a delegated pilot user.
2. Enforce MFA on the Gainsight application assignment in the identity provider. Document which direct or recovery login paths are still available; keep an approved recovery path until the SAML rollout is verified.

**Automation:** ClickOps only for this setting in the reviewed sources. The published user-record APIs do not set tenant SAML policy.

#### Validation & Testing

Use separate browser sessions to validate a pilot sign-in, MFA enforcement, and access removal after unassignment. Record the status of alternate sign-in paths rather than assuming they inherit SAML policy.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2 |

### 1.2 Review Privileged Users

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Maintain a named roster of authorized Super Admins and reconcile it with Gainsight User Management. Review service identities independently.

#### Rationale

**Why This Matters:**

- Super Admin and permission-bundle access should not be granted simply to allow ordinary operations.
- A licensed user, active record, and Super Admin designation are distinct signals.

**Attack Prevented:** Reduces the risk of uncontrolled access on the boundary above; it does not prove complete prevention.

#### ClickOps Implementation

1. Open **Administration → Users and Permission → User Management** and review administrators against the approved roster. Use the [user-management reference](https://support.gainsight.com/v1/docs/gainsight-user-management) for the account source and license assignment.
2. Retain audited emergency access. For changes to active status or privileges, review downstream workflows and record the approver before applying.

**Automation:** The [Fetch User Details endpoint](https://support.gainsight.com/docs/user-management-apis-1#fetch-user-details) uses POST to query user records without modifying them. The pack pages through the reported result and emits only totals; it does not determine who is authorized. The vendor lists update operations but does not support changing the Super Admin flag via the user-management API.

#### Code Implementation

{% include pack-code.html vendor="gainsight" section="1.2" %}

#### Validation & Testing

Compare the count with the approved roster, then reconcile individual identities in the admin console. A failed or inconsistent query is not a clean result.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

## 2. Network and Integrations

### 2.1 Restrict Application and Connector IP Ranges

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | SC-7 |

#### Description

Constrain access to the Gainsight tenant and individual API connections using the appropriate allowlists. Review both scopes: Gainsight documents that the application-level list can admit traffic not on the connector-specific list.

#### Rationale

**Why This Matters:**

- A legitimate credential should not by itself grant access from an unapproved network.
- A broad application range or an unchecked mobile exception can nullify an expected restriction.

**Attack Prevented:** Reduces the risk of uncontrolled access on the boundary above; it does not prove complete prevention.

#### ClickOps Implementation

1. Inventory corporate egress, administrators, mobile use and each integration’s source addresses. In **Administration → Security → Trusted IP Ranges**, configure **Application IPs**, starting with confirmed recovery and integration egress.
2. In **Connectors IPs**, review each connection. Do not treat optional OAuth allowlisting as enabled just because Access Key connections require it. Review the documented **Bypass Mobile** behavior before rollout. [Trusted IP range configuration and examples](https://support.gainsight.com/gainsight_nxt/01Onboarding_and_Implementation/Onboarding_for_Gainsight_NXT/Login_and_Permissions/Allow_List_Trusted_IP_Addresses).

**Automation:** ClickOps only for the two policy settings in the reviewed sources; the published connector authentication flows do not prove those policies can be set or read by customer API.

#### Validation & Testing

From designated test networks, verify an allowed and disallowed sign-in and a harmless authorized connector request. Verify mobile behavior separately. If access breaks, restore the approved previous list from the retained admin session.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | SC-7 |

### 2.2 Scope and Rotate Integration Credentials

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-5 |

#### Description

Use separate OAuth clients or access keys for integrations and prefer the narrowest documented API scope that meets each job. Keep an inventory of owners, expected egress and retirement dates.

#### Rationale

**Why This Matters:**

- An orphaned connector can leave a valid credential after a workflow is removed.
- The 2025 Salesforce incident described by Gainsight involved reuse of older OAuth tokens accepted by Salesforce. A restriction on inbound Gainsight access does not govern Salesforce's own token acceptance.

**Attack Prevented:** Reduces the risk of uncontrolled access on the boundary above; it does not prove complete prevention.

#### ClickOps Implementation

1. In **Administration → Connectors 2.0**, identify each Gainsight API connection. Use the documented [REST API credential workflow](https://support.gainsight.com/docs/generate-rest-api-key-1) or [OAuth setup](https://support.gainsight.com/v1/docs/oauth-for-gainsight-apis); verify the required permissions and that the connection is needed.
2. Plan client-secret rotation with the integration owner. For supported M2M connections use the documented **Re-Generate Secret** function and verify the job resumes; use the connector's last-authentication evidence when available. [Release notes](https://support.gainsight.com/v1/docs/gainsight-cs-release-notes-q4-january-2026).
3. For Salesforce-bound access, separately review Salesforce-side scopes, authorization and network/session policy using the [Salesforce Hardening Guide](/guides/salesforce/).

**Automation:** Token acquisition is documented; it is not an API for modifying the tenant credential policy. No rotation pack: the reviewed sources document the admin UI, not a programmatic secret-regeneration contract.

#### Validation & Testing

Exercise a read-only operation in the approved integration after rotation. Confirm the retired credential is no longer accepted if the provider supports doing so safely. Never capture full tokens in evidence.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-5 |

## 3. Monitoring and Evidence

### 3.1 Review User-Record Activity Logs

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6 |

#### Description

Review Gainsight user-record activity for unexpected provisioning and authorization changes. Do not mistake these records for tenant-wide audit coverage.

#### Rationale

**Why This Matters:**

- User-record evidence helps tie membership changes to the originating workflow.
- User-record activity excludes many other administrative and integration events.

**Attack Prevented:** Reduces the risk of uncontrolled access on the boundary above; it does not prove complete prevention.

#### ClickOps Implementation

1. In **Administration → Users and Permission → User Management**, open a relevant record's **Activity Logs** from its action menu. Review the change history and source attribution as documented in the [Activity Logs article](https://support.gainsight.com/gainsight_nxt/01Onboarding_and_Implementation/Onboarding_for_Gainsight_NXT/Login_and_Permissions/Activity_Logs).
2. Reconcile against approved IdP and administrative changes. Preserve only necessary evidence in access-restricted storage.

**Automation:** ClickOps for the user-record change history in the reviewed sources. The current-state user-list endpoint is not a historical audit feed.

#### Validation & Testing

Use a preapproved change on a synthetic user to verify the event is recorded. Confirm identity, time and action; do not infer coverage for unrelated activity.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6 |

## 4. Compliance Quick Reference

| Control | NIST SP 800-53 Rev. 5 | Evidence |
|---------|----------------------|----------|
| SAML authentication | IA-2 | IdP policy and approved pilot sign-in results |
| Privileged users | AC-6 | Approved roster, user inventory and review record |
| Trusted IP ranges | SC-7 | Authorized range lists and positive/negative test results |
| Integration credentials | IA-5 | Connector inventory and rotation records without credentials |
| User activity | AU-6 | Correlated sample events and reviewer record |

These are implementation mappings, not a certification claim.

## 5. Sources

- [Gainsight API and Developer Docs](https://support.gainsight.com/gainsight_nxt/API_and_Developer_Docs)
- [Gainsight post-incident analysis](https://www.gainsight.com/blog/how-we-accelerated-a-year-of-security-work-in-weeks/)

## Changelog

| Date | Version | Maturity | Change |
|------|---------|----------|--------|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial source-backed Gainsight CS guide and read-only assessment pack |
