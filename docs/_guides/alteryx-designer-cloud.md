---
layout: guide
title: "Alteryx Designer Cloud Hardening Guide"
vendor: "Alteryx Designer Cloud"
slug: "alteryx-designer-cloud"
tier: "2"
category: "Data"
description: "Harden Designer Cloud workspaces with centralized sign-in, token hygiene and audit retention."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Scope: Alteryx Designer Cloud in a hosted Alteryx One Platform workspace. The pack covers only the documented US1 region; Designer Desktop, Alteryx Server, Dataprep, or self-managed Trifacta are out of scope.

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

### 1.1 Federate Workspace Authentication

**Profile Level:** L1 (Crawl)

#### Description

Enable workspace SSO and route MFA and assignment through the organization's IdP.

#### Rationale

**Why This Matters:**

- A common identity lifecycle makes workspace access revocation and assurance more reliable.

#### Prerequisites

Workspace Admin, supported SSO entitlement, approved IdP integration and a documented recovery operator.

#### ClickOps Implementation

1. Go to **Workspace Admin > Single Sign-On** and select the appropriate supported protocol. Configure the approved IdP using the vendor setup steps.
2. Pilot workspaces and users individually; confirm the intended IdP enforcement and MFA before rolling out.
3. Have an Account Admin review **Workspaces** for the recorded Authentication Method. Keep approved administrative recovery separate.

**Source:** [Vendor administration documentation](https://help.alteryx.com/platform/en/admin/admin-reference/admin-console/single-sign-on.html).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Test ordinary and approved emergency access in fresh sessions. Account Admin page or new-device OTP prompts can still occur; those do not prove IdP MFA.

#### Operational Impact

Incorrect settings can lock out a workspace. Save configuration evidence with approval, without copying signing secrets.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | IA-2 | Supports this objective; configuration alone does not establish compliance. |

### 1.2 Review and Retire Personal API Tokens

**Profile Level:** L1 (Crawl)

#### Description

Inventory the authenticated person's tokens and retire stale or overlong integrations after identifying their dependencies.

#### Rationale

**Why This Matters:**

- Personal API tokens can retain the originating user's effective permissions and live outside normal interactive sessions.

#### Prerequisites

API Access entitlement, authorized user token and an approved workspace. Use a minimally privileged user.

#### ClickOps Implementation

1. In **Profile > User Preferences > OAuth 2.0 API Tokens**, inventory your tokens and identify their owner, use and expected lifetime.
2. Rotate necessary tokens according to your organization's credential policy; revoke unused ones after validating migration.
3. Have a Workspace Admin review broader token usage if the workspace has the appropriate capability.

**Source:** [Vendor administration documentation](https://docs.trifacta.com/aac/en/platform/profile/preferences-page/oauth-2-0-api-tokens-page-for-users.html).

#### Code Implementation

{% include pack-code.html vendor="alteryx-designer-cloud" section="1.2" %}

#### Validation & Testing

Compare token counts and timestamps in the scoped evidence with the UI. The optional last-use value is informational because the GET may refresh the requesting token's last-used time.

#### Operational Impact

This pack is not organization-wide. Revocation can break schedules or automations; switch them to an approved replacement first.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AC-2, IA-5 | Supports this objective; configuration alone does not establish compliance. |

### 1.3 Preserve Account Audit Evidence

**Profile Level:** L2 (Walk)

#### Description

Review account audit events and retain approved copies outside the default 90-day window.

#### Rationale

**Why This Matters:**

- Native retention alone can leave a gap in investigations and compliance evidence.

#### Prerequisites

Account Admin, required Audit Log entitlement, and a restricted customer-owned destination if using automated export.

#### ClickOps Implementation

1. In the **Admin Console**, open **Audit Logs** and filter by workspace and type (for example membership and configuration changes).
2. Download authorized records before the native 90-day purge or configure vendor-supported S3 audit persistence where entitled.
3. Restrict and monitor destination access and validate that retention follows policy.

**Source:** [Vendor administration documentation](https://help.alteryx.com/aac/en/platform/admin/admin-reference/account-management/audit-logs-page.html).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Trace a known authorized event to the intended workspace, timestamp, category and destination. Alert on missing scheduled exports when export is enabled.

#### Operational Impact

Audit records can contain identifiers and metadata. Grant retrieval only to approved reviewers and limit retained scope.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AU-6, AU-11 | Supports this objective; configuration alone does not establish compliance. |

## 2. Compliance Quick Reference

| Control | Profile | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 Federate Workspace Authentication | L1 | IA-2 |
| 1.2 Review and Retire Personal API Tokens | L1 | AC-2, IA-5 |
| 1.3 Preserve Account Audit Evidence | L2 | AU-6, AU-11 |

## References

- [Source and validation notes](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-third-dev-source-coverage.md)

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-11-27 | Initial documentation-derived guide and verification packs |
