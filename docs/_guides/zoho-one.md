---
layout: guide
title: "Zoho One Hardening Guide"
vendor: "Zoho One"
slug: "zoho-one"
platform: "Zoho"
platform_slug: "zoho"
product: "Common Controls"
tier: "2"
category: "Productivity"
description: "Secure the organization directory, SAML configuration, workload access to directory records, and audit review."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Zoho One’s Directory is a shared administrative plane. App-local controls still matter: the [Zoho WorkDrive Hardening Guide](/guides/zoho-workdrive/) covers external file sharing, team roles and file audit evidence separately.

**Validation status:** Source-backed guidance and offline pack checks. No live tenant was accessed.

### Intended Audience

Organization owners, directory administrators, identity engineers and control reviewers.

### How to Use This Guide

Start with L1 (Crawl), pilot with approved users, and then collect L2 (Walk) evidence. Record configuration and observed behavior separately.

### Scope

The Zoho One shared Directory and organization audit surface, not unrelated per-app admin consoles.

### Products

| Product | Scope |
|---------|-------|
| [Zoho WorkDrive](/guides/zoho-workdrive/) | Team file sharing, delegated roles and file activity reports. |

## Table of Contents

1. [Access and Assurance](#1-access-and-assurance)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Access and Assurance

### 1.1 Pilot External SAML and Enforce MFA

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2 |

#### Description

Configure a trusted IdP for the assigned organization groups. Require approved MFA at that IdP, and independently protect any Zoho-native recovery accounts.

#### Rationale

**Why This Matters:**

- SAML integration settings are not proof that the right groups are assigned or fallback accounts are covered.

#### ClickOps Implementation

1. Open **Directory → Security → Identity Providers** in the Unified UI; use **Directory Settings → Security → Identity Providers** in Spaces. Add the approved SAML IdP and bind the assertions to Zoho One’s issued ACS and issuer.
2. Configure pilot users in the IdP and verify its authentication rules. Review [Zoho One’s Entra configuration example](https://help.zoho.com/portal/en/kb/one/admin-guide/security/custom-authentication/articles/zohoone-customauthentication-azure).
3. For native sign-ins, use the applicable Zoho Security Policies workflow. The [documented MFA path](https://help.zoho.com/portal/en/kb/one/admin-guide/security/security-1-0/articles/zohoone-configure-mfa) is specifically Security 1.0; confirm your current rollout before applying it.

**Automation:** No supported policy-write handle for this control was verified. Do not repurpose the directory users API.

#### Validation & Testing

Test sign-in for assigned and unassigned pilot users and the protected recovery login separately.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2 |

### 1.2 Reconcile Directory Role and Account Status

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Review the membership and role of each approved organization administrator and remove stale access through change control. Separate delayed invitations, deactivated accounts and licensed application access from directory-wide privilege.

#### Rationale

**Why This Matters:**

- A single account can have cross-suite impact through the organization directory. A role or status number from an API alone is not an authorization decision.

#### ClickOps Implementation

1. Open the Zoho One Directory and inspect Users and organization roles. Reconcile against approved role assignments. Check application grants separately.
2. For a preapproved synthetic account, compare the API sample against the current directory record. [Zoho Directory Users API](https://www.zoho.com/directory/api/v2/users/).

**Automation:** The pack performs the documented user-by-ID GET with the Users read scope, on the US API origin, and returns only numeric role and status fields. It does not interpret the codes or enumerate every user.

#### Code Implementation

{% include pack-code.html vendor="zoho-one" section="1.2" %}

#### Validation & Testing

Compare the account, role and status to the admin console. An error or missing field is inconclusive.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

### 1.3 Review Directory Audit Evidence

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6 |

#### Description

Correlate security-relevant directory changes with approved actor, time and target. Do not infer WorkDrive or other application activity from the Directory audit surface.

#### Rationale

**Why This Matters:**

- Directory review is more useful when the expected event and source are known before the audit query.

#### ClickOps Implementation

1. Open **Audit → Audit Logs** in the One Experience admin panel or Spaces Directory settings. In Unified UI use **Directory → Reports → Audit Logs**.
2. Filter by date range, activity and actor for the reviewed change. Compare with the approved record and document any gap. [Zoho One audit filter help](https://help.zoho.com/portal/en/kb/one/admin-guide/reports/audit-logs/articles/filter-audit-logs-zo).

**Automation:** ClickOps on this scope. A documented organization audit-log API was not verified in this pass.

#### Validation & Testing

Make an approved change to a synthetic user and verify the expected record appears before counting this as operational evidence.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6 |

## 2. Compliance Quick Reference

| Control | NIST SP 800-53 Rev. 5 |
|---------|----------------------|
| Pilot External SAML and Enforce MFA | IA-2 |
| Reconcile Directory Role and Account Status | AC-6 |
| Review Directory Audit Evidence | AU-6 |

These are implementation mappings, not certification claims.

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial guide and read-only Code Pack | Jai |
