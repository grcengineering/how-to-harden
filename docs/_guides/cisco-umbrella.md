---
layout: guide
title: "Cisco Umbrella Hardening Guide"
vendor: "Cisco Umbrella"
slug: "cisco-umbrella"
tier: "1"
category: "Security"
description: "Cisco Umbrella provides cloud DNS and secure internet policy."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Cisco Umbrella provides cloud DNS and secure internet policy. This guide focuses on the customer dashboard, API integrations, and DNS deployment evidence, not Cisco Secure Access migration or a Meraki organization.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Administrative access and tokens](#1-administrative-access-and-tokens)
2. [DNS coverage evidence](#2-dns-coverage-evidence)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Administrative access and tokens

### 1.1 Centralize administrative sign-in with SAML

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | IA-2, IA-8 |

#### Description

Use SAML for approved Umbrella dashboard administrators and enforce MFA through the identity provider. Stage the identity migration and keep recovery arrangements separate.

#### Rationale

**Why This Matters:**

- Operators with standalone credentials fall outside the organization’s sign-in and offboarding policy.

#### Prerequisites

Full Admin, assigned IdP accounts, and documented recovery. Before proceeding, follow Cisco’s applicable authentication conversion guidance for existing accounts.

#### ClickOps Implementation

1. Go to **Admin > Authentication** in the Umbrella dashboard.
2. Configure the SAML connection with the approved IdP. If choosing Cisco Security Cloud Sign On, ensure every existing account already has the Umbrella app assigned there.
3. Review **Admin > Accounts** and **Admin > User Roles** so only approved operators hold Full Admin access.

**Automation:** SAML configuration and administrator account changes are documented in the dashboard; direct automation was not verified.

#### Validation & Testing

Test a fresh session for each required administrator role and check that the IdP produces the expected MFA event. Confirm helpdesk and recovery access before enabling wider use.

#### Monitoring & Maintenance

Reconcile the IdP assignments and dashboard roles; track certificate expiry and exceptions.

#### Operational Impact & Rollback

Changing login methods can remove existing dashboard passwords. Do not assume rollback restores them; confirm Cisco’s applicable recovery procedure before rollout.

**Sources:** [Cisco authentication migration guidance](https://www.cisco.com/c/en/us/support/docs/security/secure-access/225388-configure-umbrella-for-migration-to.pdf). [Cisco Umbrella Design Guide](https://www.cisco.com/c/dam/en/us/solutions/collateral/enterprise/design-zone-security/umbrella-design-guide.pdf).

### 1.2 Restrict integration API keys to their job

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

#### Description

Create separate OAuth client credentials for deployment reads and granular reporting. A verifier does not need write permission.

#### Rationale

**Why This Matters:**

- A stolen credential should not be able to change identity deployment or policy when its operational purpose is only inventory.

#### Prerequisites

Dashboard Full Admin to configure key scopes; approved secret storage for the issued secret.

#### ClickOps Implementation

1. Open **Admin > API Keys**. Use a recognizable workload-specific key name and choose scopes appropriate to the key’s job.
2. Use the network read scope for inventory and granular events read for activity evidence. Do not grant management scopes to a collector.
3. Assign an owner and approved expiration; have a controlled workload obtain its short-lived token rather than pasting secrets into shell command history.

**Automation:** The packs consume an externally acquired OAuth token. Key issuance and a complete key inventory were not verified as REST operations.

#### Validation & Testing

Compare configured scopes with the documented endpoint scope and the consumer’s job. An authorized GET alone is not proof that the token lacks write scopes.

#### Monitoring & Maintenance

Review owner, expiry and intended scopes quarterly and after integration changes.

#### Operational Impact & Rollback

A scope correction can interrupt a collector. Test replacements separately and restore the approved prior collector configuration if needed.

**Sources:** [Umbrella API authentication](https://developer.cisco.com/docs/cloud-security/umbrella-api-authentication/). [Umbrella OAuth scopes](https://developer.cisco.com/docs/cloud-security/umbrella-api-oauth-scopes/).

## 2. DNS coverage evidence

### 2.1 Reconcile trusted network identities to actual egress

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-8, SC-7 |

#### Description

Register only expected public egress networks and make sure designated sites receive the intended DNS policy. A listed identity alone does not demonstrate that its resolvers send traffic through Umbrella.

#### Rationale

**Why This Matters:**

- A missing DNS identity or unexpectedly changing public IP can leave endpoints outside the expected per-site policy.

#### Prerequisites

Approved egress inventory, destination sites, and an already issued token with `deployments.networks:read` for the optional inventory.

#### ClickOps Implementation

1. In **Deployments > Core Identities > Networks**, compare configured identities to approved network names and egress addresses.
2. For a new approved identity use the documented dashboard setup and test the resolver path from a pilot endpoint, then apply the intended DNS policy in the policy wizard.
3. Treat dynamic addresses explicitly; Cisco documents a different update flow for dynamic networks.

#### Code Implementation

{% include pack-code.html vendor="cisco-umbrella" section="2.1" %}

#### Validation & Testing

Verify known pilot traffic is attributed to the intended identity and DNS policy. The pack fetches one bounded page; continue reviewing pages until the inventory is complete.

#### Monitoring & Maintenance

Review site cutovers and dynamic egress changes; investigate missing expected activity.

#### Operational Impact & Rollback

Resolver or policy changes can interrupt client DNS. Revert the affected pilot resolver/policy to the previously approved configuration and test before widening rollout.

**Sources:** [Umbrella trial dashboard setup](https://umbrella.cisco.com/free-trial-quick-start-guide). [List Networks](https://developer.cisco.com/docs/cloud-security/umbrella-api-api-reference-deployments-networks-api-networks-list-networks/). [Dynamic egress guidance](https://www.cisco.com/c/en/us/support/docs/security/umbrella/224730-maintain-networks-with-dynamic-ip.html).

### 2.2 Confirm security telemetry reaches review workflows

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-2, AU-6 |

#### Description

Use activity reporting to sample the DNS/proxy/firewall records for the intended policy. Keep an admin-policy-change review separately; traffic telemetry does not replace the administrative audit log.

#### Rationale

**Why This Matters:**

- Without evidence from expected sites, missing or bypassed enforcement can be mistaken for clean results.

#### Prerequisites

Valid token with Reports > Granular Events > Read-Only; access to dashboard reporting for comparison.

#### ClickOps Implementation

1. In Umbrella reporting open the activity view and narrow it to an approved pilot identity and time period.
2. Generate known benign pilot traffic and check that the record’s identity and verdict match expectations.
3. Configure periodic comparisons to expected traffic sources and restrict access to raw reporting data.

#### Code Implementation

{% include pack-code.html vendor="cisco-umbrella" section="2.2" %}

#### Validation & Testing

Confirm a recently observed pilot event is available. The pack provides a bounded sample count, not coverage for the entire window and not proof of enforcement where no expected activity was supplied.

#### Monitoring & Maintenance

Alert on collection failures or unexpectedly missing expected pilot activity; periodically audit evidence-scope permissions.

#### Operational Impact & Rollback

Read-only request. Stop a wrongly scoped collector without tampering with the original evidence source.

**Sources:** [Granular activity reference](https://developer.cisco.com/docs/cloud-security/umbrella-api-api-reference-reports-reporting-api-activity-get-activities-all/).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Centralize administrative sign-in with SAML | IA-2, IA-8 |
| 1.2 Restrict integration API keys to their job | AC-6, IA-5 |
| 2.1 Reconcile trusted network identities to actual egress | CM-8, SC-7 |
| 2.2 Confirm security telemetry reaches review workflows | AU-2, AU-6 |

## Appendix A: Automation and applicability

Umbrella documents REST deploy/read and reporting endpoints. Reporting data scope depends on the deployed service. These packs perform bounded reads and no writes. Terraform, first-party admin CLI, SDK, GraphQL and SIEM schema coverage for the specific controls were not verified. Legacy key authentication is not substituted for v2 OAuth. No Umbrella-specific CIS, STIG or SCuBA control prescription was verified.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.
