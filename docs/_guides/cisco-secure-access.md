---
layout: guide
title: "Cisco Secure Access Hardening Guide"
vendor: "Cisco Secure Access"
slug: "cisco-secure-access"
tier: "1"
category: "Security"
description: "Harden the current Cisco Secure Access Security Service Edge tenant."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden the current Cisco Secure Access Security Service Edge tenant. This is a different API and policy plane from existing Cisco Umbrella deployments, Meraki Dashboard, and Cisco AI Defense Runtime.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Policy coverage](#1-policy-coverage)
2. [Private access and logs](#2-private-access-and-logs)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Policy coverage

### 1.1 Inventory security profiles and rule assignments

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-8, CM-6 |

#### Description

Review profile defaults, profile reporting state, and assignment to Internet and private access rules.

#### Rationale

**Why This Matters:**

- A reusable profile provides no protection to traffic that does not match an attached rule.

#### Prerequisites

Secure Access organization access and current rule inventory; optional read-only policies.securityProfiles:read token.

#### ClickOps Implementation

1. Open Secure > Security Profiles and identify Internet and private profiles and their configured defaults.
2. Compare each active access rule to the approved profile inventory; resolve unused, stale or overly broad profile assignments.
3. Record rule owner, approved exception, and known-good staged validation evidence.

#### Code Implementation

{% include pack-code.html vendor="cisco-secure-access" section="1.1" %}

#### Validation & Testing

Compare the API profile sample with the UI for the expected organization. Verify actual rule matches in Activity Search; a profile count cannot prove enforcement.

#### Monitoring & Maintenance

Review changes to defaults and disabled reporting with the access policy owner.

#### Operational Impact & Rollback

Restore the previously approved profile assignment in the affected rule and retest.

**Sources:** [Internet access Security Profiles](https://www.cisco.com/c/en/us/td/docs/security/secure-access/secure-access-help/CiscoSecureAccessHelp/security-profiles-intro/security_profiles_for_internet_access.html). [Cisco Secure Access List Security Profiles](https://developer.cisco.com/docs/cloud-security/list-security-profiles/). [Cisco Secure Access Activity Search](https://www.cisco.com/c/en/us/td/docs/security/secure-access/secure-access-help/CiscoSecureAccessHelp/activity-reports-intro/activity-search-report.html).

### 1.2 Stage Internet access security controls

**Profile Level:** L2

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | SC-7, SI-3 |

#### Description

Review applicable Web protection, acceptable use, and TLS inspection settings in the Internet access profile.

#### Rationale

**Why This Matters:**

- Defaults and regular exceptions may not satisfy organizational policy; careless decryption changes can break applications or violate privacy requirements.

#### Prerequisites

Approved staged cohort, certificate deployment if decrypting, explicit exception and privacy review.

#### ClickOps Implementation

1. Go to Secure > Security Profiles and expand the pilot Internet access profile.
2. Review security and acceptable use controls and any decryption bypass exceptions with security and privacy owners.
3. Assign the approved profile to a pilot Internet access rule and expand only after compatibility and reporting checks.

#### Validation & Testing

Check approved ordinary Internet test traffic from the pilot and verify the matching rule and allowed or blocked outcomes in Activity Search.

#### Monitoring & Maintenance

Track false positives, bypass exceptions, and exception expiration dates.

#### Operational Impact & Rollback

Reassign the prior profile to the pilot rule; do not broaden bypasses for all users.

**Sources:** [Internet access Security Profiles](https://www.cisco.com/c/en/us/td/docs/security/secure-access/secure-access-help/CiscoSecureAccessHelp/security-profiles-intro/security_profiles_for_internet_access.html). [Cisco Secure Access Activity Search](https://www.cisco.com/c/en/us/td/docs/security/secure-access/secure-access-help/CiscoSecureAccessHelp/activity-reports-intro/activity-search-report.html).

## 2. Private access and logs

### 2.1 Narrow private access rules and posture requirements

**Profile Level:** L2

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-3, AC-6, SC-7 |

#### Description

Scope private access by authorized identities and resources, adding applicable posture and private security profiles.

#### Rationale

**Why This Matters:**

- Overlapping resources and broad policies can allow unnecessary private access or obscure application dependencies.

#### Prerequisites

Private resources and application dependencies, approved test users and devices, known route and recovery owner.

#### ClickOps Implementation

1. Open the Access Policy page and review the relevant private access rule action, identities and resources.
2. Check for overlapping private address ranges and ensure necessary application dependencies have explicit, scoped grants.
3. Review applicable posture and security controls before piloting with representative authorized identities and managed devices.

#### Validation & Testing

Verify expected access and expected denial with designated pilot users; confirm the matching rule in reporting. Do not test unrelated private resources.

#### Monitoring & Maintenance

Reconcile resources, owners, users and exceptions on every policy change.

#### Operational Impact & Rollback

Reinstate the previously approved scoped rule; avoid creating a broad catch-all allow.

**Sources:** [Troubleshoot private access rules](https://www.cisco.com/c/en/us/td/docs/security/secure-access/secure-access-help/CiscoSecureAccessHelp/private-access-rules-intro/troubleshoot_private_access_rules.html). [Cisco Secure Access Activity Search](https://www.cisco.com/c/en/us/td/docs/security/secure-access/secure-access-help/CiscoSecureAccessHelp/activity-reports-intro/activity-search-report.html).

### 2.2 Reconcile administrative changes and reporting

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-2, AU-6 |

#### Description

Review administrative settings changes alongside activity evidence.

#### Rationale

**Why This Matters:**

- A policy change with no attributable owner or logging gap can go undetected.

#### Prerequisites

At least a Read-only reporting role and access to approved evidence storage.

#### ClickOps Implementation

1. Go to Monitor > Management > Admin Audit Log and select the applicable time window.
2. Compare changes to approved change records; follow up on unexplained edits and verify policy effects in Monitor > Reports > Activity Search.
3. If exporting to S3, validate the approved bucket boundary and access before making the change.

#### Validation & Testing

A known change appears in Admin Audit Log with timing and actor, and expected traffic appears in Activity Search. Investigate partial results instead of treating them as complete evidence.

#### Monitoring & Maintenance

Review report publication and the search window separately from configured retention.

#### Operational Impact & Rollback

Correct access to the affected evidence export and preserve the audit history.

**Sources:** [Cisco Secure Access Admin Audit Log](https://team-development.cisco.com/c/en/us/td/docs/security/secure-access/secure-access-help/CiscoSecureAccessHelp/admin-audit-log-intro/admin_audit_log_report.html). [Cisco Secure Access Activity Search](https://www.cisco.com/c/en/us/td/docs/security/secure-access/secure-access-help/CiscoSecureAccessHelp/activity-reports-intro/activity-search-report.html). [Report search window and retention](https://www.cisco.com/c/en/us/td/docs/security/secure-access/secure-access-help/CiscoSecureAccessHelp/monitor-with-reports-intro/report_search_window_and_retention.html).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Inventory security profiles and rule assignments | CM-8, CM-6 |
| 1.2 Stage Internet access security controls | SC-7, SI-3 |
| 2.1 Narrow private access rules and posture requirements | AC-3, AC-6, SC-7 |
| 2.2 Reconcile administrative changes and reporting | AU-2, AU-6 |

## Appendix A: Automation and applicability

Use Secure Access API scopes and the Secure Access OAuth endpoint, not Umbrella API credentials. Cisco has announced an Umbrella SIG/DNS transition; confirm your exact package and migration timing independently from this guide. [Cisco Umbrella transition notice](https://www.cisco.com/c/en/us/products/collateral/security/security-cloud/umbrella-sig-dns-eol.html).

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.
