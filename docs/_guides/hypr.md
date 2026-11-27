---
layout: guide
title: "HYPR Hardening Guide"
vendor: "HYPR"
slug: "hypr"
tier: "1"
category: "Security"
description: "HYPR Cloud runs the Control Center for passwordless identity."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

HYPR Cloud runs the Control Center for passwordless identity. Limit who can manage relying parties, policy and integrations; a workstation enrollment does not confer an administration role.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Control Center access](#1-control-center-access)
2. [Integrations and evidence](#2-integrations-and-evidence)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Control Center access

### 1.1 Use task-based administrator roles

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6 |

#### Description

Reserve Admin for full-plane operations. Assign App Manager, User Manager, or Viewer according to the actual responsibilities, and treat optional Audit Trail permission as independent access.

#### Rationale

**Why This Matters:**

- An overprivileged application operator can alter authentication policy for relying parties outside their job.

#### Prerequisites

A Control Center Admin plus an approved roster and a separate tested Admin recovery path.

#### ClickOps Implementation

1. In Standard mode open **Control Center Settings > Control Center Users**. In Advanced mode use **Global Settings > Control Center Users** for the selected application.
2. Review the Role column against ownership. Change local assignments from the user detail pane. If the entry is marked **IdP Assigned**, correct its OIDC role claim in the IdP instead.
3. In Advanced mode use **Roles > Access Level for Role-less IdP Assigned Users > Edit**; select **Deny Control Center Access** where every approved operator receives an explicit claim.

**Automation:** Direct role-setting automation was not verified for this guide.

#### Validation & Testing

Test sign-in in a fresh session as an approved Viewer, an approved Admin and an assigned test account with no mapped role. Confirm read-only or denied behavior as appropriate.

#### Monitoring & Maintenance

Review role and Audit Trail assignments quarterly and after personnel or IdP group changes.

#### Operational Impact & Rollback

Role changes can affect active sessions or apply on next sign-in. Preserve a verified Admin session and correct the individual claim or role if a legitimate user loses access.

**Sources:** [Control Center users and roles](https://docs.hypr.com/docs/cc/ccInstallCfg/ccInstallCfgUserMgmt/cc-install-cfg-user-mgmt-user-roles/).

### 1.2 Constrain Control Center FIDO2 trust

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | IA-2, IA-5 |

#### Description

Where FIDO2 is enabled for Control Center Admin, accept only the authenticator types and attestation behavior your organization supports. Configure the selected RP, not the corresponding end-user integration by mistake.

#### Rationale

**Why This Matters:**

- A broad authenticator policy can accept credentials outside the intended device-trust model.

#### Prerequisites

Admin or delegated App Manager as supported; approved authenticators and a working separate administrator recovery path.

#### ClickOps Implementation

1. For the administration plane, open **Control Center Settings > FIDO2 Settings** and verify the application is **Control Center Admin**.
2. Verify the Client Origin URL and FIDO2 allowed methods. Leave **Allow Untrusted Attestation** disabled. Pilot any changes to No Attestation, Self Attestation, synced passkeys or the AAGUID policy against the authenticator fleet before rollout.
3. If enforcing an AAGUID list, verify every required authenticator in a staged policy first. Do not treat an AAGUID ID alone as proof of attestation trust.

**Automation:** Vendor documents REST operations, but exact write contracts were not verified here; no speculative pack.

#### Validation & Testing

Enroll and sign in with an approved pilot security key and confirm intended enrollment behavior for a non-approved authenticator using test accounts. Verify an administrator can recover before broad activation.

#### Monitoring & Maintenance

Review new authenticator models, client origin changes, certificate trust and device recovery plans.

#### Operational Impact & Rollback

Overly strict settings can lock out administrators. Use the previously tested management path to restore the recorded settings while investigating.

**Sources:** [Control Center FIDO2 settings](https://docs.hypr.com/docs/auth/authInstallCfg/authInstallCfgAppMgmt/auth-install-cfg-app-mgmt-fido2-settings/).

## 2. Integrations and evidence

### 2.1 Issue narrow per-purpose API tokens

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

#### Description

Create service-specific tokens in the correct application scope. Give log collection the Reporting permission rather than broadly granting configuration or recovery permissions.

#### Rationale

**Why This Matters:**

- A compromised collector should not have power to change FIDO2 policy, issue recoveries, or administer unrelated applications.

#### Prerequisites

Named token owner, secret manager, approved application inventory and configured HYPR edition.

#### ClickOps Implementation

1. Open **Access Tokens** in the Control Center for the intended application; review which permissions each integration actually needs.
2. Give the collector only **Reporting** where its operations work with that permission. Treat application configuration and user-recovery access as separate jobs.
3. Record the intended RP, owner, token lifetime and permissions; store the secret outside source or evidence records.

**Automation:** No exact token policy API was verified; the audit pack does not enumerate token privileges.

#### Validation & Testing

Use the read-only pack in section 2.2 for the reporting path and review the token’s permissions in the console. A working read proves access, not absence of extra permissions.

#### Monitoring & Maintenance

Reconcile token owners, scopes and recent use during access review.

#### Operational Impact & Rollback

A wrongly scoped replacement can stop reporting. Use the prior approved scoped integration while correcting the job configuration; never publish raw token values.

**Sources:** [HYPR access tokens](https://docs.hypr.com/docs/auth/authInstallCfg/authInstallCfgAppMgmt/auth-install-cfg-app-mgmt-access-tokens/).

### 2.2 Verify scoped audit event collection

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-2, AU-6 |

#### Description

Retrieve a bounded sample from the selected relying party and compare with the Control Center Audit Trail. Export only needed event metadata.

#### Rationale

**Why This Matters:**

- Missing authentication and administrative signals conceal drift and make incident investigation unreliable.

#### Prerequisites

HTTPS URL for the approved HYPR tenant, correct RP application ID, scoped token, curl and jq.

#### ClickOps Implementation

1. In Control Center open the relevant application’s **Audit Trail**.
2. Review a known pilot authentication or administrative event, limiting collection to approved time windows and relying parties.
3. Store a minimized result in the approved evidence location; never assume client diagnostics and structured audit events are interchangeable.

#### Code Implementation

{% include pack-code.html vendor="hypr" section="2.2" %}

#### Validation & Testing

Generate a normal test sign-in, use a window that includes its UTC time, and compare event identity and timestamp to the console. A zero-row sample does not prove collection works.

#### Monitoring & Maintenance

Alert on missing expected events, authorization errors and permission changes.

#### Operational Impact & Rollback

Read only. If the collector is mis-scoped, roll back its collection configuration or disable collection while preserving source evidence.

**Sources:** [Audit Trail](https://docs.hypr.com/docs/cc/ccAnalytics/ccAnalyticsLogs/cc-analytics-logs-server-logs/). [Vendor event query example](https://docs.hypr.com/docs/11.3.0/cc/ccAnalytics/ccAnalyticsLogs/cc-analytics-logs-event-logs-power-shell/).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Use task-based administrator roles | AC-2, AC-6 |
| 1.2 Constrain Control Center FIDO2 trust | IA-2, IA-5 |
| 2.1 Issue narrow per-purpose API tokens | AC-6, IA-5 |
| 2.2 Verify scoped audit event collection | AU-2, AU-6 |

## Appendix A: Automation and applicability

The REST verification pack covers a single bounded page of audit records; it does not certify complete coverage. The HYPR public REST documentation describes other management operations. Terraform, GraphQL, SDK and standalone admin CLI coverage for these settings remain unverified; the cited PowerShell feed example uses the REST API, not HYPR cmdlets. HYPR Adapt, Affirm workflow policy, and workstation operating-system deployment policy are separate planes. No HYPR-specific CIS, STIG or SCuBA benchmark was verified.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.
