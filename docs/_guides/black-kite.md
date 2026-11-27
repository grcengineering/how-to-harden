---
layout: guide
title: "Black Kite Hardening Guide"
vendor: "Black Kite"
slug: "black-kite"
tier: "1"
category: "Security"
description: "Harden the customer side of the Black Kite third-party cyber risk portal."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden the customer side of the Black Kite third-party cyber risk portal. This guide covers tenant role scoping, integrations and controlled vendor outreach, not the vendor’s own SaaS infrastructure or scanning of third parties.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Role and ecosystem access](#1-role-and-ecosystem-access)
2. [External collaboration](#2-external-collaboration)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Role and ecosystem access

### 1.1 Review privileged and ecosystem-scoped roles

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6 |

#### Description

Keep cross-instance and tenant administrator access to named personnel and choose ecosystem-scoped access for narrower tasks.

#### Rationale

**Why This Matters:**

- A broad role can expose vendor risk information outside the assigned ecosystem.

#### Prerequisites

Tenant role administration and a reviewed role-to-job matrix.

#### ClickOps Implementation

1. In the authorized tenant review users, assigned role names and the associated instance or ecosystem. Check current labels against your tenant help.
2. Compare cross-instance or write roles with approved duties; where appropriate reduce routine reviewers to read-only scope.
3. Remove access after offboarding and validate a representative reviewer assignment.

**Automation:** No verified native Code Pack for this control; the publicly reachable documentation did not expose the customer role-audit schema. Verify the role in the documented product surface.

#### Validation & Testing

Compare two approved example users with expected scope and record an aggregate attestation.

#### Monitoring & Maintenance

Review stale identities, elevated roles and contractors on a recurring schedule.

#### Operational Impact & Rollback

Restore only a previously approved scoped assignment for a user who loses required access.

**Sources:** [Black Kite vendor response on scoped RBAC](https://blackkite.com/wp-content/uploads/2021/04/CISOs-Investigate-TPRM-Black-Kite.pdf).

### 1.2 Constrain integration credentials and output

**Profile Level:** L2

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-4, IA-5 |

#### Description

Separate approved integration identities by purpose and control where Black Kite risk data is sent.

#### Rationale

**Why This Matters:**

- Ratings, findings or third-party records may be sensitive and have contractual output restrictions.

#### Prerequisites

Authorized tenant integration administrator, contract and downstream data owner.

#### ClickOps Implementation

1. Reconcile enabled connectors and API usage by application owner, destination and approved scope using current tenant docs.
2. Use the least access available to the integration and store credential material only in the approved secret store.
3. Check report or widget licensing requirements before exposing outputs beyond the internal risk team.

#### Validation & Testing

Validate approved destinations with redacted sample output and check downstream permissions. Do not assume portal RBAC is applied to exports.

#### Monitoring & Maintenance

Review credentials and downstream recipients at rotation or contract renewal.

#### Operational Impact & Rollback

Stop the specific connector and rotate its approved credentials if unintended export occurs.

**Sources:** [Black Kite API and connector programme](https://blackkite.com/integrate). [Black Kite partner API and attribution](https://blackkite.com/brandguidelines).

## 2. External collaboration

### 2.1 Review external Bridge outreach before sending

**Profile Level:** L2

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-4, CM-3 |

#### Description

Limit Bridge outreach to verified vendor recipients and only the approved findings or reports.

#### Rationale

**Why This Matters:**

- A sent message can reveal information about vendors, vulnerabilities or procurement priorities.

#### Prerequisites

Bridge entitlement, verified recipient, approved report and external disclosure policy.

#### ClickOps Implementation

1. Open the relevant Bridge activity or vendor outreach workflow and check the intended vendor and contact.
2. Select only the approved findings or reports and preview the message.
3. Require documented approval before sending; use authorized internal/non-delivery validation for a dry run.

#### Validation & Testing

Check the draft contains only permitted material. Confirm an approved historical send is attached to the intended vendor in Bridge Activities.

#### Monitoring & Maintenance

Review accessibility of shared reports and open outreach with the vendor manager.

#### Operational Impact & Rollback

For a send error stop follow-on communications and follow approved incident handling; do not assume a delivered email can be recalled.

**Sources:** [Black Kite Bridge workflow](https://blackkite.com/blog/introducing-black-kite-bridge-to-reduce-supply-chain-risk).

### 2.2 Preserve an auditable vendor remediation trail

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-6, AU-9 |

#### Description

Track recipient-approved outreach and follow-up decisions in Bridge Activities; treat closed items as risk disposition, not automatic proof of technical remediation.

#### Rationale

**Why This Matters:**

- A resolved discussion can be mistaken for a verified control fix without independent evidence.

#### Prerequisites

Authorized Bridge reviewer and a record of review and retention requirements.

#### ClickOps Implementation

1. Review the vendor record in Bridge Activities for the relevant communications and actions.
2. Associate the outreach history with the internal risk record, evidence owner and follow-up date.
3. Require independent remediation evidence before closing the underlying risk item.

#### Validation & Testing

A known outreach record shows the expected status and ownership; verify related evidence in the approved system without exporting the entire portfolio.

#### Monitoring & Maintenance

Review overdue follow-up and handle access to any stored attachments separately.

#### Operational Impact & Rollback

Correct the affected evidence link or status and retain the original history.

**Sources:** [Black Kite Bridge workflow](https://blackkite.com/blog/introducing-black-kite-bridge-to-reduce-supply-chain-risk).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Review privileged and ecosystem-scoped roles | AC-2, AC-6 |
| 1.2 Constrain integration credentials and output | AC-4, IA-5 |
| 2.1 Review external Bridge outreach before sending | AC-4, CM-3 |
| 2.2 Preserve an auditable vendor remediation trail | AU-6, AU-9 |

## Appendix A: Automation and applicability

The public Swagger UI did not expose a readable customer role/credential audit schema in this review. No native Black Kite export or REST API pack is supplied. No API auth routes, settings menus, SSO policies or tenant controls are inferred from Black Kite’s supplier Trust Center.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and verification guidance | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.
