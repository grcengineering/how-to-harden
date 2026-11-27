---
layout: guide
title: "Informatica Address Verification Cloud Hardening Guide"
vendor: "Informatica Address Verification Cloud"
slug: "informatica-address-verification"
tier: "2"
category: "Productivity"
description: "Harden Informatica Address Verification Cloud administrative access and verify scoped control evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

The AddressDoctor row refers to the Informatica Address Verification Cloud service and its AddressDoctor Data Quality Center (DQC) portal. This is not IDMC Cloud Data Quality, unrelated connectors, or the on-premises address engine.

### Intended Audience

- Tenant and identity administrators responsible for access and configuration
- Security or assurance reviewers responsible for control evidence

### How to Use This Guide

L1 (Crawl) is the supported baseline here. Confirm the exact tenant, plan, and responsible administrator before testing with synthetic evidence or an approved nonproduction account.

### Scope

Only Address Verification Cloud 6.x service behavior and the documented EU reporting endpoint are assumed. No unsupported DQC admin settings, credential rotation APIs, or other regional reporting paths are inferred. The pack performs a narrow read-only or local evidence check; no live tenant validation or configuration writes were performed.

## Table of Contents

1. [Security Configuration](#1-security-configuration)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Security Configuration

### 1.1 Keep DQC portal and API credentials separate

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-5

#### Description

Separate administrator identity from the credentials embedded in address verification calls.

#### Rationale

- Credential separation and overlapping rotation prevent hidden integrations from retaining unrestricted or expired access.

#### ClickOps Implementation

Sign in to the Data Quality Center using Informatica Passport, then locate the service account ID and password for the approved integration. Use a secret manager and avoid including API credentials in HTTP captures. Verify the credential rotation process with your tenant owner, not a guessed administration endpoint.

Source: [Informatica Address Verification Cloud documentation](https://docs.informatica.com/data-as-a-service/address-verification-%28cloud%29/6-8-0/developer-guide/part-1--cloud-operations/rest-call-creation/web-service-credentials.html) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

With an approved integration, confirm the secret owner, vault reference and handling rather than recording the credential. Confirm newly issued credentials function before removing old ones where supported.

---

### 1.2 Keep address processing region and transaction pool explicit

**Profile Level:** L1 (Crawl)

**NIST 800-53:** SC-8

#### Description

Keep personal address processing in the authorized region and the approved transaction pool.

#### Rationale

- Keep address transfer confidential and prevent processing from reaching an unapproved region.

#### ClickOps Implementation

Review the endpoint URL in your deployed connector or service configuration and use its authorized Informatica HTTPS region. Explicitly select the TEST or PRODUCTION transaction pool where supported. Minimize personal address fields and prevent them from reaching debug logs.

Source: [Informatica Address Verification Cloud documentation](https://docs.informatica.com/content/dam/source/GUID-E/GUID-E5B8922B-C1A0-400D-9126-8758BDAEA0BC/5/en/IAV_640_DeveloperGuide_en.pdf) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Inspect redacted connector configuration for region, pool choice and validated TLS. Use synthetic address data only if a separate processing test is approved; processing can consume transactions.

---

### 1.3 Review one DQC account’s available transaction pools

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AU-6

#### Description

Review the approved account’s available report entries without triggering personal address processing.

#### Rationale

- Review source records and minimize the confidential information written into evidence systems.

#### ClickOps Implementation

Compare Data Quality Center transaction reporting with the approved pool inventory. Match the service account to the intended DQC environment without copying the password into evidence. Review unexpected consumption with the account owner.

Source: [Informatica Address Verification Cloud documentation](https://docs.informatica.com/data-as-a-service/address-verification-%28cloud%29/6-8-0/developer-guide/part-1--cloud-operations/rest-call-creation/transaction-reporting.html) (checked 2026-11-27).

**Automation:** One fixed transaction-reporting POST to the documented EU endpoint, not an address job. The request contains only DQC service credentials. Output is reduced to aggregate pool presence; no address content, prices, balances or passwords are printed. If the service response differs from the documented transaction array, the pack rejects it.

#### Code Implementation

{% include pack-code.html vendor="informatica-address-verification" section="1.3" %}

#### Validation & Testing

Use the transaction report read to verify TEST and PRODUCTION pool presence as applicable; reconciliation with actual job selection requires independent configuration review. Do not use an address-processing call to verify credentials.

## 2. Compliance Quick Reference

These mappings describe control objectives, not certification.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Keep DQC portal and API credentials separate | IA-5 |
| 1.2 | Keep address processing region and transaction pool explicit | SC-8 |
| 1.3 | Review one DQC account’s available transaction pools | AU-6 |

### References

- [Pack source and coverage boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-enterprise-data-source-coverage.md)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial control guide and offline-tested evidence pack. |
