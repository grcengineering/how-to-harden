---
layout: guide
title: "Sourcegraph Cody Hardening Guide"
vendor: "Sourcegraph Cody"
slug: "sourcegraph-cody"
tier: "3"
category: "AI/ML Platform"
description: "Sourcegraph announced Cody reaches end of life on January 31, 2027"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

**Product Editions Covered:** Existing Sourcegraph Enterprise Cody deployments on Sourcegraph Cloud and self-hosted

## Overview

Sourcegraph announced Cody reaches end of life on January 31, 2027. This is transition and retirement guidance for existing Enterprise users, not a recommendation to enable Cody in a new deployment.

### Intended Audience

Platform administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Baseline controls for the documented deployment.
- **L2 (Walk):** Add verified controls where the workload needs stronger isolation.
- **L3 (Run):** Add controls warranted by higher-risk workflows and contractual requirements.

### Scope

Cody Free, Pro and Enterprise Starter access ended July 23, 2025. Sourcegraph Code Search, Deep Search, the Sourcegraph MCP integration and Amp are distinct products or capabilities; none is a drop-in replacement in this guide.

---

## Table of Contents

1. [Transition and Retirement](#1-transition-and-retirement)
2. [Credential Exposure](#2-credential-exposure)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

---

## 1. Transition and Retirement

### 1.1 Plan migration and retire Cody

**Profile Level:** L1 (Crawl)

#### Description

Inventory active Cody clients and API workflows, set retirement before the vendor end-of-life date, migrate approved workflows, then disable Cody.

#### Rationale

- Deployments and IDE integrations can outlive a subscription or migration unless owners explicitly retire them.

#### Prerequisites

An approved migration owner, inventory of clients/providers, validated alternatives and a rollback window within the vendor support period.

#### ClickOps Implementation

1. Inventory IDE, Web and API usage and validate replacements in a pilot. Approve code- and repository-data boundaries independently for each replacement.
2. **Self-hosted:** Open **Administration → Advanced configuration** and set `cody.enabled` to false. **Sourcegraph Cloud:** Have the authorized account owner request disablement through their account team.
3. Retire Cody clients and verify other Sourcegraph features still function before rotating or removing any Cody-specific credentials. Do not revoke a shared credential without identifying its consumers.

Source: [Vendor configuration reference](https://sourcegraph.com/docs/cody/clients/enable-cody-enterprise).

#### Code Implementation

This native JSON configuration fragment sets the vendor-documented property. Merge the single setting into the supported Advanced configuration editor; do not replace the instance configuration with this snippet.

{% include pack-code.html vendor="sourcegraph-cody" section="1.1" %}

#### Validation & Testing

Read back disabled status on the intended instance; for Cloud retain support confirmation. Check a former Cody client reports unavailability and critical non-Cody workflow smoke tests pass.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Disabling Cody interrupts existing Cody workflows. Other Sourcegraph features may share credentials or providers; inventory those dependencies first.

#### Rollback Procedure

Before end of life only, restore an approved temporary prior setting or ask the account team about reverting the Cloud change. Do not assume reactivation is available after end of life.

---
### 1.2 Restrict Cody access during transition

**Profile Level:** L1 (Crawl)

#### Description

Limit Cody to approved short-term users who still have a transition need.

#### Rationale

- Sourcegraph documents that all users have Cody access by default while enabled; instance-wide availability is not a per-role approval.

#### Prerequisites

Site administrator and pilot users; approved owners and removal date.

#### ClickOps Implementation

1. In **Administration → Advanced configuration**, verify the legacy `cody.restrictUsersFeatureFlag` setting is absent for the current documented roles workflow.
2. In **Administration → Users & Auth → Roles**, review **User [System] → Cody → Access** and turn off baseline access. Assign a dedicated transition role with Cody access to authorized users only.

Source: [Vendor configuration reference](https://sourcegraph.com/docs/cody/clients/enable-cody-enterprise).

#### Code Implementation

Role verification remains administrative; the retirement fragment does not assess effective assignments.

#### Validation & Testing

Confirm a pilot user retains access while a regular user without the approved role cannot use Cody. Record users, intended retirement date and public/external group grants requiring review.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Users removed from Cody access will lose Cody features before the retirement date.

#### Rollback Procedure

Restore only the approved user’s Cody role while support is still available; do not reopen the baseline role broadly.

---

## 2. Credential Exposure

### 2.1 Shorten interim IDE token lifetime

**Profile Level:** L2 (Walk)

#### Description

Use the shortest supported Cody IDE token lifetime workable for the transition cohort.

#### Rationale

- Short-lived IDE sessions limit future credential exposure while keeping retirement distinct from token expiry.

#### Prerequisites

Site admin, planned reauthentication and access recovery.

#### ClickOps Implementation

1. Open the Sourcegraph Enterprise **Administration** page and locate the Cody IDE token expiry setting.
2. Select the shortest approved value among the documented 7, 14, 30, 60 or 90-day options. Verify existing tokens separately; do not assume policy changes immediately revoke them.

Source: [Vendor configuration reference](https://sourcegraph.com/docs/cody/enterprise/features).

#### Code Implementation

The IDE runtime/token setting has no supported CLI policy management verified for this guide.

#### Validation & Testing

Reopen the setting and use a newly authenticated test IDE. Record observed settings and any residual credentials separately.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Users may need more frequent reauthentication; a transition role must still be authorized.

#### Rollback Procedure

Restore the prior documented lifetime only for a bounded, approved transition.

---

## 3. Compliance Quick Reference

These mappings indicate how settings can contribute to a control objective; they do not establish conformity or operation over a period.

| HTH control | NIST SP 800-53 Rev. 5 | Evidence to retain |
| --- | --- | --- |
| 1.1 | CM-8, CM-3 | Scope, migration test and verified Cody disablement |
| 1.2 | AC-6 | Approved role members and positive/negative eligibility tests |
| 2.1 | AC-12 | Recorded lifetime and approved credential retirement |

## Appendix A: Automation and Evidence

The native fragment is a configuration-as-code example, not a tenant write script. Sourcegraph Cloud enablement/disablement is account-team managed. Public-code Guardrails are deprecated and are not used as a substitute for verified transition controls. No live deployment verification was performed.

## Appendix B: References

- [Official Cody end-of-life announcement](https://sourcegraph.com/blog/sunsetting-cody-future-of-code-intelligence)
- [Earlier tier changes](https://sourcegraph.com/blog/changes-to-cody-free-pro-and-enterprise-starter-plans)
- [Sourcegraph advanced configuration](https://sourcegraph.com/docs/admin/config/site-config)

## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial platform controls and documented verification packs | How to Harden Community |

## Contributing

Report inaccurate or outdated guidance through the [issue tracker](https://github.com/grcengineering/how-to-harden/issues).
