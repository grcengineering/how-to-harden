---
layout: guide
title: "iManage Work Cloud Hardening Guide"
vendor: "iManage Work Cloud"
slug: "imanage-work"
tier: "2"
category: "Productivity"
description: "Harden iManage Work Cloud administrative access and verify scoped control evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

iManage Work at cloudimanage.com and its Control Center, not on-premises Work Server or separately licensed SPM and Audit Hub.

### Intended Audience

- Tenant and identity administrators responsible for access and configuration
- Security or assurance reviewers responsible for control evidence

### How to Use This Guide

L1 (Crawl) is the supported baseline here. Confirm the exact tenant, plan, and responsible administrator before testing with synthetic evidence or an approved nonproduction account.

### Scope

No native Work Universal API administrative calls were verified in public first-party docs for these controls; the independent metadata retrieval below uses the documented tenant route. The pack performs a narrow read-only or local evidence check; no live tenant validation or configuration writes were performed.

## Table of Contents

1. [Security Configuration](#1-security-configuration)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Security Configuration

### 1.1 Configure an IdP-backed sign-in policy with tested recovery

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-2

#### Description

Use managed workforce authentication while retaining the supported emergency pathway.

#### Rationale

- Managed authentication reduces exposure when local credentials or identity assignments survive ordinary personnel changes.

#### ClickOps Implementation

In Control Center → Network & Security → Single Sign-On (SSO), configure the entitled SAML or OIDC connection with the approved IdP. Retain protected emergency virtual-user access where required by your configuration; do not assume the normal sign-in URL works when Seamless Sign-In is enabled.

Source: [iManage Work Cloud documentation](https://docs.imanage.com/cloud/cc-help/en-US/SAML_Single_Sign-On_%28SSO%29.html) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Test workforce and emergency recovery identities without disrupting production. Review signing certificate expiration, and verify SP metadata again after a tenant custom-subdomain change.

---

### 1.2 Reduce library public-content and registered-app scope

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-6

#### Description

Limit library access and app token authority to the smallest useful group.

#### Rationale

- Constrain effective entitlement to the minimum needed and review privileged claims rather than assuming UI and API access are identical.

#### ClickOps Implementation

Open Access → Roles → Library-level Management and review Allow public content access per role where the Public Content Access rollout is active. Do not rely on the external-user label after rollout. Under Settings → Applications, review OAuth refresh and access restrictions; grant apps to approved users/groups only.

Source: [iManage Work Cloud documentation](https://docs.imanage.com/cloud/cc-help/en-US/Public_Content_Access_feature_rollout.html) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Use authorized test accounts against synthetic documents marked Public or View. Verify access independently for each library and review how long setting updates take to apply.

---

### 1.3 Verify the SAML metadata matches the approved cutover

**Profile Level:** L1 (Crawl)

**NIST 800-53:** CM-3

#### Description

Detect a change to the service-provider metadata used for the approved identity cutover.

#### Rationale

- Require independent approval and an expected build outcome before a software change can be released.

#### ClickOps Implementation

Under Network & Security → Network Settings, record the approved custom subdomain and obtain the documented SAML service-provider metadata file for your customer ID. Capture its trusted SHA-256 and reapprove it only after independently reviewing a legitimate identity change.

Source: [iManage Work Cloud documentation](https://docs.imanage.com/cloud/cc-help/en-US/Network_Settings.html) (checked 2026-11-27).

**Automation:** One unauthenticated HTTPS GET to the explicitly approved custom subdomain and customer metadata path. The script recognizes UTF-8 SAML 2.0 SP metadata and compares SHA-256 of the exact response bytes against a separately approved digest. It does not verify XML signatures, live federation, tenant policy, or Work API authorization.

#### Code Implementation

{% include pack-code.html vendor="imanage-work" section="1.3" %}

#### Validation & Testing

Fetch only the documented metadata URL and compare the returned SAML service-provider metadata digest. An unchanged digest does not test the IdP assignment, authentication or library permissions.

## 2. Compliance Quick Reference

These mappings describe control objectives, not certification.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Configure an IdP-backed sign-in policy with tested recovery | IA-2 |
| 1.2 | Reduce library public-content and registered-app scope | AC-6 |
| 1.3 | Verify the SAML metadata matches the approved cutover | CM-3 |

### References

- [Pack source and coverage boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-enterprise-data-source-coverage.md)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial control guide and offline-tested evidence pack. |
