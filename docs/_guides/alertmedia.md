---
layout: guide
title: "AlertMedia Hardening Guide"
vendor: "AlertMedia"
slug: "alertmedia"
tier: "2"
category: "Security"
description: "Harden AlertMedia administrative access and verify scoped control evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Scope workforce SAML, user provisioning, and Incident Management delegation for emergency communications. Tenant-only documentation may show additional settings and edition-specific permissions.

### Intended Audience

- Tenant and identity administrators responsible for access and configuration
- Security or assurance reviewers responsible for control evidence

### How to Use This Guide

L1 (Crawl) is the supported baseline here. Confirm the exact tenant, plan, and responsible administrator before testing with synthetic evidence or an approved nonproduction account.

### Scope

No AlertMedia-native administrative REST contract was independently verified. No emergency broadcast or other notification tests are automated. The pack performs a narrow read-only or local evidence check; no live tenant validation or configuration writes were performed.

## Table of Contents

1. [Security Configuration](#1-security-configuration)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Security Configuration

### 1.1 Validate enterprise SAML with an approved recovery path

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-2

#### Description

Use the organization’s identity provider for verified workforce sign-in while preserving emergency operator access.

#### Rationale

- Managed authentication reduces exposure when local credentials or identity assignments survive ordinary personnel changes.

#### ClickOps Implementation

Use the AlertMedia enterprise application in Entra or the supported setup for your IdP. Obtain the exact Identifier and Reply URL from AlertMedia, configure SAML and required mappings, and pilot MFA conditional access for selected workforce groups before rollout. Preserve tested recovery for emergency operators.

Source: [AlertMedia documentation](https://learn.microsoft.com/en-us/entra/identity/saas-apps/alertmedia-tutorial) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Test intended assigned users, a test user who lacks assignment, and the documented fallback without sending an alert. Do not assume local login is disabled from directory configuration alone.

---

### 1.2 Separate incident operator rights from directory changes

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-6

#### Description

Limit who can manage incident response and ensure provisioning does not grant sending authority by accident.

#### Rationale

- Constrain effective entitlement to the minimum needed and review privileged claims rather than assuming UI and API access are identical.

#### ClickOps Implementation

In the AlertMedia dashboard, review incident permissions and communication group scope. Delegate incident responsibilities only where needed, review recipients separately from senders, and reconcile provisioning ownership with the live admin roster. Use approved SCIM provisioning where supported and tested; avoid two provisioning paths updating the same roster.

Source: [AlertMedia documentation](https://www.alertmedia.com/products/incident-management/) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Use a tabletop exercise and test groups to confirm operators cannot change unrelated permissions or reach unintended recipients. Verify that revoking a test user in the IdP removes its effective permissions.

---

### 1.3 Check the assigned Entra enterprise app binding

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-3

#### Description

Verify the exact Entra service principal has the expected AlertMedia SAML binding and requires assignment.

#### Rationale

- Access must be enforced at the actual caller or request boundary, not inferred from a role label.

#### ClickOps Implementation

Open Entra ID → Enterprise apps → AlertMedia. Review the object ID, application ID, required assignment setting, and SAML Identifier and Reply URL. The check below uses operator-confirmed standard AlertMedia values; nonstandard values require a separate manual comparison.

Source: [AlertMedia documentation](https://learn.microsoft.com/graph/api/serviceprincipal-get) (checked 2026-11-27).

**Automation:** This is an identity-provider-side read, not an AlertMedia API call. Use an authorized Microsoft Graph read token from the intended Entra directory and resolve the expected service principal object ID and application ID independently. It does not verify AlertMedia tenant roles, policies, SCIM, or effective provisioning. Graph Application.Read.All can read across the directory; prefer an existing approved auditor credential or manual review to creating a broad new grant. The check only covers the standard setup.

#### Code Implementation

{% include pack-code.html vendor="alertmedia" section="1.3" %}

#### Validation & Testing

Use the configured AlertMedia slug and expected Entra object and application IDs. Verify the two SAML values and assignment flag. Independently review actual role assignments and tenant-side login requirements.

## 2. Compliance Quick Reference

These mappings describe control objectives, not certification.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Validate enterprise SAML with an approved recovery path | IA-2 |
| 1.2 | Separate incident operator rights from directory changes | AC-6 |
| 1.3 | Check the assigned Entra enterprise app binding | AC-3 |

### References

- [Pack source and coverage boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-people-infrastructure-source-coverage.md)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial control guide and offline-tested evidence pack. |
