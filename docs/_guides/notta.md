---
layout: guide
title: "Notta Hardening Guide"
vendor: "Notta"
slug: "notta"
tier: "3"
category: "AI/ML Platform"
description: "Notta workspaces contain recording and transcription data"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

**Product Editions Covered:** Notta Business and Enterprise workspaces, with tier gates per control

## Overview

Notta workspaces contain recording and transcription data. Apply separate controls for identity, public and internal sharing, and the lifespan of stored records.

### Intended Audience

Platform administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Baseline controls for the documented deployment.
- **L2 (Walk):** Add verified controls where the workload needs stronger isolation.
- **L3 (Run):** Add controls warranted by higher-risk workflows and contractual requirements.

### Scope

Covers workspace controls in Notta Web, not smart recorder device controls, Showcase or Notta Brain model administration.

---

## Table of Contents

1. [Identity and Access](#1-identity-and-access)
2. [Sharing and Retention](#2-sharing-and-retention)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

---

## 1. Identity and Access

### 1.1 Require SAML for Enterprise members

**Profile Level:** L1 (Crawl)

#### Description

Use owner-coordinated SAML with an approved IdP and verified domain.

#### Rationale

- SAML centralizes access, but activation signs out members and users outside the verified domain can lose access.

#### Prerequisites

Enterprise owner, IdP admin, verified domain, vendor recovery contact and change window.

#### ClickOps Implementation

1. Obtain the workspace SAML configuration from Notta and follow its official IdP setup.
2. Assign a tested pilot cohort and confirm there are no active transcription or editing tasks at activation.

Source: [Vendor configuration reference](https://support.notta.ai/hc/en-us/articles/19844526077211-How-to-configure-SAML-SSO).

#### Code Implementation

Support-coordinated configuration; no public policy writer is asserted.

#### Validation & Testing

Test fresh owner and pilot sessions. Verify handling of unverified-domain accounts.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

All users can be signed out. Notta documents one domain per workspace and support-dependent reconfiguration.

#### Rollback Procedure

Use the prearranged Notta support recovery path. Do not rely on parallel password login.

---
### 1.2 Review privileged workspace roles

**Profile Level:** L1 (Crawl)

#### Description

Limit the Owner and Admin roles to approved maintainers and compare them against the authorized roster.

#### Rationale

- Owners control workspace settings and admins can manage privileged roles. A role count alone cannot establish authorization.

#### Prerequisites

Enterprise owner or admin; secure approved storage for the download.

#### ClickOps Implementation

1. In Notta Web, choose **Invite members → Bulk Invite Members → Sync Full Member List** and download **Current Member List**.
2. Compare Owner and Admin entries against approved assignments. Review the UI preview before confirming any separately approved change.

Source: [Vendor configuration reference](https://support.notta.ai/hc/en-us/articles/41864234547099-Unified-management-based-on-member-list-Invite-Remove-and-Update).

#### Code Implementation

Download the English Current Member List and pass its path as the only argument. The pack validates the vendor CSV and emits role counts only. It never uploads or writes data.

{% include pack-code.html vendor="notta" section="1.2" %}

#### Validation & Testing

Verify owners and admins without putting emails into review reports. Use local role counts for sanity checking and reconcile in Notta Members.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Never re-upload a filtered roster for review: omitted users can be removed, with records reassigned to the Owner.

#### Rollback Procedure

Revert a particular role with approval. Re-adding a removed user does not automatically restore their record ownership.

---

## 2. Sharing and Retention

### 2.1 Disable public transcript sharing

**Profile Level:** L1 (Crawl)

#### Description

Disable public sharing on Business and Enterprise workspaces with sensitive transcripts.

#### Rationale

- Existing public links may expose recordings and transcripts. Disabling public sharing invalidates previous links.

#### Prerequisites

Workspace owner, reviewed external-sharing dependencies and a benign pilot transcript.

#### ClickOps Implementation

1. Open **Settings → Security → Features Restriction**.
2. Set Public sharing configuration to **Public sharing disabled** and confirm.

Source: [Vendor configuration reference](https://support.notta.ai/hc/en-us/articles/21585484873499-How-to-restrict-sharing-with-external-users).

#### Code Implementation

Console-only baseline for public sharing.

#### Validation & Testing

Confirm the public option is unavailable and a former synthetic public link no longer works for a signed-out viewer.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Intentional public shares will stop. Move legitimate files to a controlled sharing channel.

#### Rollback Procedure

Re-enable only with approval and separately verify which links need recreation.

---
### 2.2 Limit internal transcript visibility by default

**Profile Level:** L2 (Walk)

#### Description

Do not share new transcripts with the entire workspace by default. Disable whole-workspace sharing entirely where not required.

#### Rationale

- Workspace-wide sharing can expose transcripts without business need. Historical records and folder access need separate review.

#### Prerequisites

Business or Enterprise owner/admin and pilot folders.

#### ClickOps Implementation

1. Open **Settings → Workspace settings → Preferences → Workspace sharing settings**.
2. Disable **Allow sharing with entire workspace** if unneeded. Otherwise set the default to **Accessible only to the creator** and review folder permissions.

Source: [Vendor configuration reference](https://support.notta.ai/hc/en-us/articles/38455626843931-Workspace-level-internal-sharing-settings).

#### Code Implementation

Console-only baseline for internal sharing.

#### Validation & Testing

Verify creator and unassigned-member behavior using synthetic transcripts inside and outside a representative folder. Audit historical sharing separately.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Collaboration may need individual or group shares. Changing default visibility does not change prior transcripts.

#### Rollback Procedure

Restore only explicitly approved folder or new-transcript scope.

---
### 2.3 Apply approved automatic-deletion settings

**Profile Level:** L2 (Walk)

#### Description

Set an approved workspace file lifecycle after checking retention requirements, holds and exports.

#### Rationale

- Recordings are sensitive. Auto deletion is not an access control or straightforward rollback.

#### Prerequisites

Enterprise owner, privacy and records approval, necessary exports and a synthetic pilot.

#### ClickOps Implementation

1. In **Settings → Security → Deletion Settings**, review **Automatically delete files**.
2. Verify scope, file/folder storage rules and independent Trash treatment before enabling.

Source: [Vendor configuration reference](https://support.notta.ai/hc/en-us/articles/23725420144667-Automatic-file-deletion-settings).

#### Code Implementation

No automated deletion or backend policy inference is included.

#### Validation & Testing

Observe synthetic records over the actual retention interval. Account for Trash’s independent 30-day behavior and the age of folder contents.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Records can be irreversibly lost; obtain explicit approval and respect holds and contracts.

#### Rollback Procedure

Restore prior settings only to stop future effects; consult the documented retention and recovery procedure for affected records.

---

## 3. Compliance Quick Reference

These mappings indicate how settings can contribute to a control objective; they do not establish conformity or operation over a period.

| HTH control | NIST SP 800-53 Rev. 5 | Evidence to retain |
| --- | --- | --- |
| 1.1 | IA-2 | SSO pilot and owner recovery |
| 1.2 | AC-2, AC-6 | Approved privileged identities and redacted roster counts |
| 2.1 | AC-3 | Public-sharing policy and pilot |
| 2.2 | AC-6 | Default visibility and folder review |
| 2.3 | SI-12 | Approved retention and synthetic outcomes |

## Appendix A: Automation and Evidence

The local roster verifier is not a live account check. The Enterprise operation log covers login, record, download and membership activity, with a documented 180-day view. No public workspace hardening API or admin CLI was verified and no live tenant test was performed.

## Appendix B: References

- [Security and privacy](https://support.notta.ai/hc/en-us/articles/18548578499355-Security-Privacy)
- [Manage user roles](https://support.notta.ai/hc/en-us/articles/18546710593051-Manage-user-roles)
- [Usage Analytics and Operation Log](https://support.notta.ai/hc/en-us/articles/18673005601179-Usage-Analytics-Operation-Log)
- [Plan capabilities](https://support.notta.ai/hc/en-us/articles/45649026891419-What-is-included-in-each-Notta-plan)

## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial platform controls and documented verification packs | How to Harden Community |

## Contributing

Report inaccurate or outdated guidance through the [issue tracker](https://github.com/grcengineering/how-to-harden/issues).
