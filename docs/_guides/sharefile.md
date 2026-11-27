---
layout: guide
title: "ShareFile Hardening Guide"
vendor: "ShareFile"
slug: "sharefile"
tier: "3"
category: "Productivity"
description: "Harden ShareFile sign-in policy, employee privilege and document delivery."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden ShareFile sign-in policy, employee privilege and document delivery.

**Validation status:** Documented control paths and offline Code Pack behavior; no live tenant, credentials, or production changes. License and effective permissions may limit visibility.

### Intended Audience

Platform owners, identity administrators, and security reviewers.

### How to Use This Guide

- **L1 (Crawl):** Establish accountable identities and least privilege.
- **L2 (Walk):** Add narrower access boundaries and independent monitoring.

### Scope

Progress [completed its acquisition of ShareFile](https://investors.progress.com/news-releases/news-release-details/progress-completes-acquisition-sharefile) in October 2024. Scope: hosted account settings and customer-managed sharing. Storage Zones Controller and mobile-device policy deserve separate validation.

## Table of Contents

1. [Access and Administration](#1-access-and-administration)
2. [Sharing, Integrations and Audit](#2-sharing-integrations-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and Administration

### 1.1 Require MFA for both user populations

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2(1) |

#### Description

Require appropriate MFA methods for employees and client contacts; distinguish SAML and application-specific passwords.

#### Rationale

**Why This Matters:**

- Vendor-enabled MFA is not the same as required MFA. Legacy clients and custom scripts can use separate application-specific credentials.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://docs.sharefile.com/en-us/sharefile/account_settings/security/multi_factor_authentication).
2. Open Account settings → Security → Sign in policy → Multi-Factor authentication → Edit. Review the permitted methods and verify Required for each applicable user type. Confirm the IdP policy and account-owner recovery process separately.

**Automation:** No documented MFA policy write handle was verified in the public REST reference; use the administration UI.

#### Validation & Testing

Test employee and client sign-in using benign accounts. Record remaining app-specific credentials, scope and owners, and verify MFA is not claimed for unsupported clients.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2(1) |

### 1.2 Inventory employee privileges

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Verify elevated employee permissions and reconcile them to duties.

#### Rationale

**Why This Matters:**

- Employee access has different capabilities than a client contact; report scope must not mix the populations.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://docs.sharefile.com/en-us/sharefile/get-started/sharefile-admin-guide).
2. Open People → Browse Employees. Review management permissions, verify they match the role assignment, and keep a separate review of client contacts. Review applicable policy-based administration group mappings.

**Automation:** The REST pack reports IDs and pagination status from one employee feed page on a documented .com tenant; EU is not covered in this example. The vendor PowerShell SDK pack provides a second read path for employee IDs; confirm whether the module returned all pages before treating either output as complete.

#### Code Implementation

{% include pack-code.html vendor="sharefile" section="1.2" %}

#### Validation & Testing

Use an administrator-reviewed roster, ensure the employee population is complete and compare each privileged assignment to approved access.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

## 2. Sharing, Integrations and Audit

### 2.1 Require sign-in for sensitive document links

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3 |

#### Description

Restrict share links to signed-in intended audiences and set a finite maximum validity.

#### Rationale

**Why This Matters:**

- A name-and-email prompt on a public link is not the same as authenticated access. Defaults alone do not inventory existing links.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://docs.sharefile.com/en-us/sharefile/account_settings/file_settings/share_setting).
2. Open Account settings → Advanced Preferences → File Settings → Share settings. Disable public access options where policy requires, choose a signed-in default and set the maximum access duration. For stricter exchanges use Send to specific people.

**Automation:** The public Accounts listing and user SDK examples do not establish a supported account-wide sharing policy write contract.

#### Validation & Testing

Confirm an expected signed-in test recipient can open a benign document link and an anonymous browser session cannot. Review existing links separately.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3 |

### 2.2 Review native Security Center remediation

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6 |

#### Description

On Enterprise or VDR, review enabled threat scenarios, their automatic effects, owners and response procedures.

#### Rationale

**Why This Matters:**

- Detection, remediation and operator review are different activities. Automatic changes can disrupt access when conditions match.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://docs.sharefile.com/en-us/sharefile/account_settings/security/security-center).
2. Under Account settings → Security → Security Policy, review the Auto-remediation settings and confirm expected effects for each enabled scenario. Review incidents in Security Center and record who owns overrides, validation and recovery.

**Automation:** No public write API for Security Center policy was verified in this guide. No auto-remediation pack is included.

#### Validation & Testing

Validate expected event visibility and tracking on an authorized benign sandbox event; do not trigger detections by testing abusive behavior. Verify configured policy separately from any remediation result.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6 |

## 3. Compliance Quick Reference

These mappings support control design; they are not evidence of certification or operating effectiveness.

| Section | Control | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 | Require MFA for both user populations | IA-2(1) |
| 1.2 | Inventory employee privileges | AC-6 |
| 2.1 | Require sign-in for sensitive document links | AC-3 |
| 2.2 | Review native Security Center remediation | AU-6 |

## References

- [OData REST feeds](https://api.sharefile.com/gettingstarted/odata)

## Changelog

- **0.1.0 (2026-11-27):** Initial guide and documented automation examples.
