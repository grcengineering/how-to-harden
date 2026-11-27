---
layout: guide
title: "HackerOne Hardening Guide"
vendor: "HackerOne"
slug: "hackerone"
tier: "1"
category: "Security"
description: "Harden the HackerOne customer organization and its bug bounty or vulnerability disclosure program administration."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden the HackerOne customer organization and its bug bounty or vulnerability disclosure program administration. This guide covers organization controls and program membership, not researcher accounts, pentest-specific permissions, asset scanning, vulnerability reproduction or report contents.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Organization access](#1-organization-access)
2. [Integration and audit hygiene](#2-integration-and-audit-hygiene)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Organization access

### 1.1 Enforce verified-domain SAML authentication

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | IA-2, AC-2 |

#### Description

For covered employees, verify the domain, stage SAML and enforce MFA in the identity provider.

#### Rationale

**Why This Matters:**

- SAML shifts the authentication boundary to the IdP; incorrect mappings or expired certificates can lock out members.

#### Prerequisites

Organization administrator, domain verification, IdP administrator and documented recovery.

#### ClickOps Implementation

1. Review Verified Domains under Organization Settings > Authentication.
2. In Authentication > SAML (SSO), add or review the provider for the intended verified domain.
3. Validate a pilot login and group assignment before migrating users; track signing certificate expiry and test replacement before removing the old certificate.

#### Validation & Testing

Verify the pilot can authenticate with the intended factor and has only the expected program permissions.

#### Monitoring & Maintenance

Review domains, mappings and certificate lifecycle after IdP changes.

#### Operational Impact & Rollback

Use the retained approved recovery access and previously recorded provider settings; do not remove the previous certificate early.

**Sources:** [HackerOne SAML SSO setup](https://docs.hackerone.com/en/articles/8487039-single-sign-on-sso-via-saml). [Domain verification](https://docs.hackerone.com/en/articles/8490190-domain-verification).

### 1.2 Review program membership and group grants

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6 |

#### Description

Review organization groups, program permissions, and the membership induced by those assignments.

#### Rationale

**Why This Matters:**

- Organization membership and engagement permissions are separate; broad assignments can expose sensitive report data.

#### Prerequisites

Program owner, group and user administration, approved access matrix and optional program-scoped API token.

#### ClickOps Implementation

1. In Organization Settings, review Users and Groups and the program permissions granted to each group.
2. Compare effective program membership to an approved roster and verify privileged grants separately.
3. Remove stale memberships with the program owner and confirm retained triage users can do their jobs.

#### Code Implementation

{% include pack-code.html vendor="hackerone" section="1.2" %}

#### Validation & Testing

Check the pilot member can reach only the intended resources. Run the pack to corroborate the first-page human membership and organization-admin counts, then verify identities privately in the UI.

#### Monitoring & Maintenance

Review role changes, JIT assignments and contractor removals on a recurring schedule.

#### Operational Impact & Rollback

Restore only the previously approved scoped grant for the affected member.

**Sources:** [HackerOne group and role permissions](https://docs.hackerone.com/en/articles/9095492-permissions). [HackerOne program membership API](https://api.hackerone.com/customer-resources/#programs-get-program-members).

## 2. Integration and audit hygiene

### 2.1 Separate and review API tokens

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

#### Description

Restrict token groups and program reach and use separate owners and tokens for distinct integrations.

#### Rationale

**Why This Matters:**

- An organization token with broad group permissions can reach multiple programs or manipulate report workflows.

#### Prerequisites

Organization API access entitlement and approved secret storage.

#### ClickOps Implementation

1. Open Organization Settings > API Tokens and review token purpose, assigned groups and program scope.
2. Assign only the necessary permission for each automation and separate evidence collectors from integrations that write.
3. Move approved integrations to new tokens in stages and revoke obsolete credentials after verification.

#### Validation & Testing

Confirm the intended read succeeds with the replacement key without invoking any write. Investigate 403 responses as permission or plan issues rather than expanding scope blindly.

#### Monitoring & Maintenance

Review token ownership and usage on integration and staff changes.

#### Operational Impact & Rollback

Replace the affected key through an approved cutover and keep exposure limited to the original scope.

**Sources:** [HackerOne group and role permissions](https://docs.hackerone.com/en/articles/9095492-permissions). [HackerOne API plan and permission guidance](https://api.hackerone.com/getting-started/).

### 2.2 Monitor organization and program audit changes

**Profile Level:** L2

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-2, AU-6, AU-9 |

#### Description

Review both audit levels so group and integration changes can be attributed without exporting raw submissions.

#### Rationale

**Why This Matters:**

- Program-specific evidence does not replace organization-wide oversight.

#### Prerequisites

Authorized organization/program auditors and approved evidence handling.

#### ClickOps Implementation

1. Open Organization Settings > Audit log and the relevant program Security page > General settings > Audit log.
2. Review approved intervals for group, invitation and integration changes.
3. Record only necessary event identifiers, timestamps and owning teams in restricted evidence storage.

#### Validation & Testing

Correlate a known approved membership change with a corresponding available audit record.

#### Monitoring & Maintenance

Review events after significant changes and investigate unexplained records.

#### Operational Impact & Rollback

Correct only the affected evidence export or reviewer grant and preserve required evidence.

**Sources:** [HackerOne organization and program audit logs](https://docs.hackerone.com/en/articles/8524901-audit-logs).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Enforce verified-domain SAML authentication | IA-2, AC-2 |
| 1.2 Review program membership and group grants | AC-2, AC-6 |
| 2.1 Separate and review API tokens | AC-6, IA-5 |
| 2.2 Monitor organization and program audit changes | AU-2, AU-6, AU-9 |

## Appendix A: Automation and applicability

The pack uses the documented program member endpoint, excludes system users, returns aggregate evidence for one page and does not fetch vulnerability reports or trigger scans. Entitlement and permissions remain account-specific.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.
