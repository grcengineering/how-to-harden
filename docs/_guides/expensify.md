---
layout: guide
title: "Expensify Hardening Guide"
vendor: "Expensify"
slug: "expensify"
tier: "2"
category: "HR/Finance"
description: "Harden Expensify administrative access and verify scoped control evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

New Expensify domain and workspace controls; Classic differs. Integration Server calls work on classic-named policies and are not evidence of all new workspace settings.

### Intended Audience

- Tenant and identity administrators responsible for access and configuration
- Security or assurance reviewers responsible for control evidence

### How to Use This Guide

L1 (Crawl) is the supported baseline here. Confirm the exact tenant, plan, and responsible administrator before testing with synthetic evidence or an approved nonproduction account.

### Scope

No SAML or approval-policy setter is packaged. OAuth access does not imply Domain Admin rights or the ability to enforce login policy. The pack performs a narrow read-only or local evidence check; no live tenant validation or configuration writes were performed.

## Table of Contents

1. [Security Configuration](#1-security-configuration)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Security Configuration

### 1.1 Verify controlled domains and require SAML

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-2

#### Description

Confirm organizational ownership and place matching workforce accounts under centrally managed login.

#### Rationale

- Managed authentication reduces exposure when local credentials or identity assignments survive ordinary personnel changes.

#### ClickOps Implementation

Open Domains → domain → SAML as Domain Admin after completing DNS verification; use the vendor SAML configuration and decide if password login should be disallowed wherever that option is supported. Test local/nonmatching email access separately.

Source: [Expensify documentation](https://help.expensify.com/articles/new-expensify/domains/Set-Up-SAML-SSO) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Validate managed sign-in in a new browser session and test the recovery path before production enforcement. Review password fallback rather than treating configured SSO as required SSO.

---

### 1.2 Prevent self-approvals before payment

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-5

#### Description

Require an independent expense reviewer and limit exceptions to the approved financial process.

#### Rationale

- Independent review reduces the chance that one person can make and release an unauthorized financial change.

#### ClickOps Implementation

In Workspaces → workspace → More features, enable Workflows on eligible workspaces. Under Workflows → Approvals and Advanced, set an independent approver and enable Prevent self-approvals. Reconcile over-limit approval, auto-approval and auto-pay settings with Finance.

Source: [Expensify documentation](https://help.expensify.com/articles/new-expensify/workspaces/Workspace-Workflows) (checked 2026-11-27).

**Automation:** Review and change this control in the documented admin interface; no policy mutation is packaged.

#### Validation & Testing

Check with a synthetic report that self-approval is blocked, over-limit reports reach the extra approver, and no payment is triggered by test submission.

---

### 1.3 Verify integration credential workspace scope

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-6

#### Description

Identify the role the read endpoint returns for a known workspace without sharing the entire policy inventory.

#### Rationale

- Constrain effective entitlement to the minimum needed and review privileged claims rather than assuming UI and API access are identical.

#### ClickOps Implementation

Under the target workspace Members settings, review the credential principal and scoped administrative assignments. Prefer narrower product roles for human tasks and review authorized payer separately. Compare the selected workspace against the integration credential scope.

Source: [Expensify documentation](https://integrations.expensify.com/Integration-Server/doc/index.html) (checked 2026-11-27).

**Automation:** Integration Server POST submits a fixed `type=get` job, not an update. Use an already-issued OAuth access token. The API response can contain workspace owner email addresses; the pack returns only the selected policy ID and legacy role, and does not print the underlying inventory.

#### Code Implementation

{% include pack-code.html vendor="expensify" section="1.3" %}

#### Validation & Testing

The pack selects just the expected policy ID and documented role from policyList. Compare with the expected legacy API role and reconcile separately with New Expensify granular roles; lack of visibility is not proof the policy is absent.

## 2. Compliance Quick Reference

These mappings describe control objectives, not certification.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Verify controlled domains and require SAML | IA-2 |
| 1.2 | Prevent self-approvals before payment | AC-5 |
| 1.3 | Verify integration credential workspace scope | AC-6 |

### References

- [Pack source and coverage boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-business-source-coverage.md)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial control guide and offline-tested evidence pack. |
