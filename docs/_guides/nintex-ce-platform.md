---
layout: guide
title: "Nintex CE Platform Hardening Guide"
vendor: "Nintex CE Platform"
slug: "nintex-ce-platform"
tier: "2"
category: "DevOps"
description: "Govern production workflows, external connections, and component workflow tokens."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Scope: commercial Nintex CE Platform Workflow, formerly Nintex Workflow Cloud, Nintex Automation Cloud and Nintex Workflow. Not Nintex K2, Nintex GE, or legacy SharePoint/Office 365 products.

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

### 1.1 Gate Production Workflow Publishing

**Profile Level:** L1 (Crawl)

#### Description

Require review by a limited group and separately govern unreviewed publishing rights.

#### Rationale

**Why This Matters:**

- An unrestricted production publisher can deploy workflows that use sensitive connections or bypass change approval.

#### Prerequisites

An authorized Automation administrator and approved publisher/approver groups.

#### ClickOps Implementation

1. Go to **Settings > Environment > Workflow settings**. Under **Workflow publishing**, choose the **Groups** model for production publishing.
2. Assign a narrowly scoped approver group and separately minimize the groups allowed to publish without approval.
3. Review administrator-level publishing privileges and handle previously submitted requests separately.

**Source:** [Vendor administration documentation](https://help.nintex.com/en-us/nwc/content/Settings/Workflow%20settings.htm).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Use an approved nonproduction workflow to verify the designer requests approval and the designated approver receives it. Confirm default-role users cannot independently publish to production.

#### Operational Impact

New approval groups may not be able to act on already-submitted requests. Coordinate rollout with owners and track pending requests.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | CM-3, AC-5 | Supports this objective; configuration alone does not establish compliance. |

### 1.2 Restrict Creation and Reuse of Connections

**Profile Level:** L1 (Crawl)

#### Description

Limit roles that create external connections and scope the use of each connection to named groups.

#### Rationale

**Why This Matters:**

- A broadly reusable connection can grant higher privileges in a downstream service than a workflow designer should have.

#### Prerequisites

An administrator with a current list of connections, workflows and intended groups.

#### ClickOps Implementation

1. In **Settings > Environment > Connection settings**, restrict connection permissions by role.
2. In **Integrations > Workflow**, use each connection's permissions settings to restrict reuse to authorized groups.
3. Review dormant connections and downstream scopes; coordinate planned changes with workflow owners.

**Source:** [Vendor administration documentation](https://help.nintex.com/en-us/nwc/Content/Settings/ConnectionSettings.htm).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Review permitted groups and prove intended service use in an approved workflow test. Check downstream permissions independently.

#### Operational Impact

A connection may be shared by multiple workflows. Include all known callers in any rotation or access update.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AC-6 | Supports this objective; configuration alone does not establish compliance. |

### 1.3 Protect Component Workflow Start Tokens

**Profile Level:** L2 (Walk)

#### Description

Keep externally callable component workflow token-bearing URLs out of shared API definitions and protect their credentials.

#### Rationale

**Why This Matters:**

- Component start tokens travel in a query parameter. A URL in a shared file, log, or ticket may therefore contain the credential itself.

#### Prerequisites

Workflow owner or authorized administrator, approved sharing workflow, and inventory of external callers.

#### ClickOps Implementation

1. Open **Settings > Environment > Component workflow tokens** and identify workflows that need external starts.
2. Keep active URL tokens in the approved secret manager and send only redacted endpoint/OAS material for review. Scan local exported definitions before sharing.
3. Revoke unused component tokens and rotate exposed ones with caller owners. Review the separate Apps and tokens list for service applications and personal access tokens.

**Source:** [Vendor administration documentation](https://help.nintex.com/en-us/nwc/content/designer/Startevents/ComponentWorkflow.htm).

#### Code Implementation

{% include pack-code.html vendor="nintex-ce-platform" section="1.3" %}

#### Validation & Testing

The offline pack checks JSON OAS or saved endpoint text for literal token query parameters. It never contacts Nintex or starts a workflow. Inspect derived artifacts separately for other secret formats.

#### Operational Impact

Regeneration can invalidate the previous token within the documented transition window. Do not rotate in this pack; schedule external caller updates with their owners.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | IA-5 | Supports this objective; configuration alone does not establish compliance. |

## 2. Compliance Quick Reference

| Control | Profile | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 Gate Production Workflow Publishing | L1 | CM-3, AC-5 |
| 1.2 Restrict Creation and Reuse of Connections | L1 | AC-6 |
| 1.3 Protect Component Workflow Start Tokens | L2 | IA-5 |

## References

- [Source and validation notes](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-fourth-dev-source-coverage.md)

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-11-27 | Initial documentation-derived guide and verification packs |
