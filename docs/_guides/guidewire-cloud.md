---
layout: guide
title: "Guidewire Cloud Platform Hardening Guide"
vendor: "Guidewire Cloud Platform"
slug: "guidewire-cloud"
tier: "2"
category: "IaC"
description: "Harden Guidewire Cloud Platform administrative access and verify scoped control evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Scope Guidewire Cloud Platform for insurers, and the managed repository and InsuranceSuite service boundaries. Do not apply these instructions to unrelated Guidewire products or self-managed deployments.

### Intended Audience

- Tenant and identity administrators responsible for access and configuration
- Security or assurance reviewers responsible for control evidence

### How to Use This Guide

L1 (Crawl) is the supported baseline here. Confirm the exact tenant, plan, and responsible administrator before testing with synthetic evidence or an approved nonproduction account.

### Scope

Repository Settings and InsuranceSuite Cloud API are separate control planes. Repository Settings API applies only to supported active repositories. The pack performs a narrow read-only or local evidence check; no live tenant validation or configuration writes were performed.

## Table of Contents

1. [Security Configuration](#1-security-configuration)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Security Configuration

### 1.1 Restrict Cloud Platform access to the intended star system

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-6

#### Description

Limit operations access to approved cloud applications and deployment scopes.

#### Rationale

- Constrain effective entitlement to the minimum needed and review privileged claims rather than assuming UI and API access are identical.

#### ClickOps Implementation

Within Guidewire Home, select the intended star system. Review entitlement to Repository Settings and environment access through Guidewire Hub or Access Management as applicable. Do not treat development access or an InsuranceSuite business role as proof that Cloud Platform administration is authorized.

Source: [Guidewire Cloud Platform documentation](https://docs.guidewire.com/cloud/gcc-guide/insurer-developer/latest/repository-settings/) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Use approved read-only test identities in different scopes. Confirm the operator can review the assigned development system but not assume unrelated environments or administrative changes.

---

### 1.2 Restrict InsuranceSuite integration roles by operation

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-3

#### Description

Use distinct role files to restrict each caller to authorized REST methods and fields.

#### Rationale

- Access must be enforced at the actual caller or request boundary, not inferred from a role label.

#### ClickOps Implementation

In the appropriate InsuranceSuite Studio project, review Integration → roles. Define caller-specific role YAML for allowed endpoints, methods, fields and applicable environment classes. Keep Guidewire-reserved roles intact and scope the registered standalone service separately from human and external user roles.

Source: [Guidewire Cloud Platform documentation](https://docs.guidewire.com/cloud/is/202607/cloudapica/cloudAPI/AuthImplement/endpoint-access/c_API-role-files.html) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Use a nonproduction test service to verify approved business operations and non-destructive access checks on other objects. Review the proxy service user when domain-level system permissions apply.

---

### 1.3 Require merge review for managed application repositories

**Profile Level:** L1 (Crawl)

**NIST 800-53:** CM-3

#### Description

Require the expected approval and build checks before merging changes to managed repositories.

#### Rationale

- Require independent approval and an expected build outcome before a software change can be released.

#### ClickOps Implementation

In Guidewire Home, choose the approved star system → Repository Settings → Merge checks and select the repository. Set minimum approvals and successful builds to your change policy. Review whether settings are explicit or inherited and whether branch restrictions block non-PR paths.

Source: [Guidewire Cloud Platform documentation](https://docs.guidewire.com/cloud/gcc-guide/insurer-developer/latest/merge-checks/) (checked 2026-11-27).

**Automation:** Uses a Guidewire Hub access token restricted to scms.mergechecks.read and the expected tenant/project. The request is bound to one regional service, star system and supported repository. The result shows only approval and build check settings, not whether your required counts are adequate.

#### Code Implementation

{% include pack-code.html vendor="guidewire-cloud" section="1.3" %}

#### Validation & Testing

Assess the selected repository’s minimum approvals and build checks from the read-only response, then confirm effective enforcement with a release exercise. The pack does not review branch restrictions or pull request state.

## 2. Compliance Quick Reference

These mappings describe control objectives, not certification.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Restrict Cloud Platform access to the intended star system | AC-6 |
| 1.2 | Restrict InsuranceSuite integration roles by operation | AC-3 |
| 1.3 | Require merge review for managed application repositories | CM-3 |

### References

- [Pack source and coverage boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-people-infrastructure-source-coverage.md)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial control guide and offline-tested evidence pack. |
