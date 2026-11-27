---
layout: guide
title: "Aqua Security Hardening Guide"
vendor: "Aqua Security"
slug: "aqua-security"
tier: "1"
category: "Security"
description: "Harden the Aqua Platform SaaS control plane with a scoped focus on the Wave/CSPM management surface."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden the Aqua Platform SaaS control plane with a scoped focus on the Wave/CSPM management surface. This does not cover self-hosted Aqua Enterprise, the preview image scanning API, or Trivy.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Tenant identity and automation](#1-tenant-identity-and-automation)
2. [Cloud posture coverage](#2-cloud-posture-coverage)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Tenant identity and automation

### 1.1 Verify approved interactive sign-in and recovery

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | IA-2, AC-2 |

#### Description

Review available Aqua SaaS authentication routes and confirm the authorized tenant sign-in method is used by administrators.

#### Rationale

**Why This Matters:**

- A federated route does not by itself disable alternate sign-ins or enforce the IdP’s MFA policy.

#### Prerequisites

Aqua tenant and IdP administrators plus the current plan-specific setup and recovery procedure.

#### ClickOps Implementation

1. Open the sanctioned Aqua SaaS tenant and review the current SSO/interactive authentication setup with the tenant admin.
2. Validate IdP MFA and the pilot group assignment while retaining independently tested recovery.
3. Review remaining alternate routes and enforce restrictions only when documented and supported for the tenant.

#### Validation & Testing

Appropriate pilot users authenticate using the expected route and no unintended permissions result; separately test the approved recovery channel.

#### Monitoring & Maintenance

Review tenant and IdP entitlements when onboarding or retiring administrators.

#### Operational Impact & Rollback

Restore the prior pilot mapping through the authorized recovery channel; do not disable MFA tenant-wide.

**Sources:** [Aqua sign-in](https://cloud.aquasec.com/signin). [Aqua SSO sign-in](https://cloud.aquasec.com/sso).

### 1.2 Keep API credentials dedicated and narrow

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

#### Description

Use a separate API-only identity and minimal rights for Aqua SaaS automation where the tenant supports it.

#### Rationale

**Why This Matters:**

- Broad credentials can operate outside the purpose of the posture collector.

#### Prerequisites

Authorized Aqua API credential owner, approved automation role and secure credential storage.

#### ClickOps Implementation

1. Review API keys in the correct Aqua account and identify owner and integration purpose.
2. For audit automation select the minimal documented endpoint permissions rather than a default admin credential.
3. Store the API key and signing secret in a secret manager; rotate in stages and retire the previous pair after validating read access.

#### Validation & Testing

Verify the intended read works and review configured privileges without exercising a write.

#### Monitoring & Maintenance

Review abandoned keys and access grants on integration change and during quarterly access review.

#### Operational Impact & Rollback

Use credential rotation recovery to restore the affected integration only.

**Sources:** [Aqua SaaS API key and secret setup](https://github.com/aquasecurity/saas-api-samples/tree/master/sample-python). [Aqua Terraform provider documentation](https://registry.terraform.io/providers/aquasecurity/aquasec/latest/docs).

## 2. Cloud posture coverage

### 2.1 Reconcile connected cloud accounts against approved scope

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-8, CA-7 |

#### Description

Review the hosted CSPM cloud accounts exposed to the credential and compare against the approved tenant scope.

#### Rationale

**Why This Matters:**

- A credential-scoped inventory can omit required accounts or include unexpected sources.

#### Prerequisites

Aqua SaaS Wave/CSPM account, expected cloud account inventory, and a dedicated approved read credential.

#### ClickOps Implementation

1. Open CSPM and compare configured cloud sources to the expected cloud accounts, subscriptions or projects.
2. Review onboarding ownership and source permission requirements before changing a connection.
3. Investigate partial or unexpected scope rather than expanding permissions solely to make counts match.

#### Code Implementation

{% include pack-code.html vendor="aqua-security" section="2.1" %}

#### Validation & Testing

Check the cloud account inventory from Aqua against known approved connections. The code pack returns only provider-category counts within the selected credential’s returned collection.

#### Monitoring & Maintenance

Repeat after account onboarding or retirement and track unexpected changes in collector coverage.

#### Operational Impact & Rollback

Restore only the previously approved connector permissions/configuration after owner review.

**Sources:** [Aqua Developer Center SaaS platform and CSPM](https://cloud.aquasec.com/developers). [Aqua SaaS account listing source](https://github.com/aquasecurity/saas-api-samples/blob/master/sample-python/helpers/aqua.py).

### 2.2 Verify scan freshness and review gated remediation

**Profile Level:** L2

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CA-7, CM-3 |

#### Description

Verify that CSPM results for critical accounts are recent and route findings to the appropriate owner before changing source controls.

#### Rationale

**Why This Matters:**

- Old scans can produce false confidence; an unreviewed change to source access or network configuration can cause disruption.

#### Prerequisites

Approved cloud source, expected scan cadence, named source owner and change process.

#### ClickOps Implementation

1. In CSPM, review recent scan evidence for an approved account and compare its timing with the monitoring baseline.
2. Inspect an applicable compliance or posture finding and assign a source owner.
3. Keep corrective cloud actions in the authorized change workflow; check entitlement and recovery before enabling any automatic action.

#### Validation & Testing

Check a recent successful scan against an approved historical or staging configuration and do not equate a reported percentage with certification.

#### Monitoring & Maintenance

Review gaps in scans and data age after IAM or collector changes.

#### Operational Impact & Rollback

Revert the affected source change through its approved provider runbook and verify collection still succeeds.

**Sources:** [Aqua SaaS API key and secret setup](https://github.com/aquasecurity/saas-api-samples/tree/master/sample-python). [Aqua SaaS account listing source](https://github.com/aquasecurity/saas-api-samples/blob/master/sample-python/helpers/aqua.py).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Verify approved interactive sign-in and recovery | IA-2, AC-2 |
| 1.2 Keep API credentials dedicated and narrow | AC-6, IA-5 |
| 2.1 Reconcile connected cloud accounts against approved scope | CM-8, CA-7 |
| 2.2 Verify scan freshness and review gated remediation | CA-7, CM-3 |

## Appendix A: Automation and applicability

The SaaS pack implements the vendor sample’s read-only Wave/CSPM cloud-account request at the published default host. The separate SaaS token API, non-default regions, self-hosted routes and write APIs are out of scope; verify any different tenant endpoint independently. The vendor’s sample calls its cloud accounts “keys”; the pack does not list API credentials.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.
