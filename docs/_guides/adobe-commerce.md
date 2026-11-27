---
layout: guide
title: "Adobe Commerce Hardening Guide"
vendor: "Adobe Commerce"
slug: "adobe-commerce"
platform: "Adobe"
platform_slug: "adobe"
product: "Commerce"
tier: "2"
category: "Marketing"
description: "Separate Commerce SaaS, Cloud Infrastructure project privileges, and application Admin controls."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

This is a product guide in the [Adobe platform](/guides/adobe-admin-console/). Shared identity controls do not configure each product’s separate security settings.

## Overview

Adobe Commerce as a Cloud Service (SaaS) uses IMS and a distinct API surface. Adobe Commerce on cloud infrastructure (PaaS) includes separate Cloud Console project roles and the application Admin. The Cloud CLI pack applies only to PaaS projects, not SaaS tenants or customer storefront users.

### Intended Audience

- Organization and product administrators who own the relevant management plane
- Security engineers and reviewers who need traceable configuration evidence

### How to Use This Guide

L1 (Crawl) is the initial baseline. Record the relevant organization, product, tenant or project before testing with approved nonproduction identities and synthetic data.

### Scope

This guide covers the controls below, with offline-tested evidence only. No live tenant or credentials were used. Packs collect narrow read-only evidence, not whole-tenant assurance or remediation.

## Table of Contents

1. [Security Configuration](#1-security-configuration)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Security Configuration

### 1.1 Separate storefront Admin sign-in controls

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-2

#### Description

Require MFA at the active administrative authentication boundary.

#### Rationale

- An IMS-integrated Commerce Admin does not use native Commerce 2FA. Treating the native UI setting as proof of IMS MFA leaves a separate sign-in plane unverified.

#### ClickOps Implementation

For an IMS-enabled or SaaS deployment, assign access through the correct Adobe organization product profile and enforce organizational MFA at the appropriate Adobe-managed or federated identity system. For a PaaS or self-managed installation with native Admin sign-in, use **Stores → Settings → Configuration → Security → 2FA** to configure approved providers; do not disable the module to avoid account enrollment.

Source: [Adobe documentation](https://experienceleague.adobe.com/en/docs/commerce-admin/systems/security/tfa/security-two-factor-authentication) (checked 2026-11-27).

**Automation:** No configuration write is shipped; determine which identity boundary is active first.

#### Validation & Testing

Verify fresh login to the exact Admin instance with an approved administrator and deny a test identity absent from the required profile or role. Verify recovery before removing a legacy sign-in path.

---

### 1.2 Review Cloud Infrastructure project roles

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-6

#### Description

Separate Project Admin from narrower environment access for Adobe Commerce on cloud infrastructure.

#### Rationale

- Cloud project access can reach source code and runtime environments independently of application access. Storefront Admin membership is not an SSH or project role inventory.

#### ClickOps Implementation

For PaaS, open the project in **Cloud Console → Project Settings → Access**. Confirm Project Admins and environment roles against approved owners; enforce available project-level MFA requirements for SSH after piloting the required access paths.

Source: [Adobe documentation](https://experienceleague.adobe.com/en/docs/commerce-on-cloud/user-guide/project/user-access?lang=en) (checked 2026-11-27).

**Automation:** First-party Cloud CLI lists users for an explicit PaaS project. No role change is performed.

#### Code Implementation

{% include pack-code.html vendor="adobe-commerce" section="1.2" %}

#### Validation & Testing

Compare the known project’s user inventory with current approved roles and independently check that nonproduction environment access does not grant production or project administration.

---

### 1.3 Minimize Commerce integration identities and API access

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-9

#### Description

Use the deployment's supported auth mechanism and authorize only needed integration permissions.

#### Rationale

- SaaS IMS tokens and PaaS integration tokens are not interchangeable. A long-lived or overprivileged integration can bypass intended human-role boundaries.

#### ClickOps Implementation

For SaaS, use an approved Adobe Developer Console OAuth credential assigned to the intended Commerce tenant and integration role. For PaaS, review integrations in **System → Extensions → Integrations** using narrow API resource permissions; do not enable standalone integration bearer-token compatibility merely to make a script work.

Source: [Adobe documentation](https://experienceleague.adobe.com/en/docs/commerce/cloud-service/security/access-control) (checked 2026-11-27).

**Automation:** The PaaS Cloud CLI membership pack does not check SaaS IMS or store integration settings.

#### Validation & Testing

From the proper tenant and identity, verify a permitted read and an out-of-scope control check using synthetic data. Inventory old credentials before scheduled revocation.

## 2. Compliance Quick Reference

These mappings support control objectives. They are not claims of certification.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Separate storefront Admin sign-in controls | IA-2 |
| 1.2 | Review Cloud Infrastructure project roles | AC-6 |
| 1.3 | Minimize Commerce integration identities and API access | IA-9 |

### References

- [Store and infrastructure security practices](https://experienceleague.adobe.com/en/docs/commerce-operations/implementation-playbook/best-practices/launch/security-best-practices)
- [Commerce REST deployment differences](https://developer.adobe.com/commerce/webapi/rest/)
- [PaaS token limitations](https://developer.adobe.com/commerce/webapi/get-started/authentication/gs-authentication-token)
- [Coverage and validation boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-adobe-source-coverage.md)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial customer configuration and read-only evidence pack. No live tenant verification. |
