---
layout: guide
title: "Salesforce Marketing Cloud Engagement Hardening Guide"
vendor: "Salesforce Marketing Cloud Engagement"
slug: "salesforce-marketing-cloud"
platform: "Salesforce"
platform_slug: "salesforce"
product: "Marketing Cloud Engagement"
tier: "2"
category: "Marketing"
description: "Protect Marketing Cloud Engagement login, integration scope and security evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

This is a product guide in the [Salesforce platform](/guides/salesforce/). The CRM guide does not configure the Engagement tenant.

## Overview

Marketing Cloud Engagement has its own Setup, business units, installed packages, tenant endpoints and Audit Trail. Its configuration is not inherited from Salesforce CRM, even when the products are integrated.

### Intended Audience

- Tenant administrators and owners of the affected integrations
- Security engineers and assurance reviewers collecting configuration evidence

### How to Use This Guide

L1 (Crawl) covers foundational configuration and evidence. Review current controls and owners first, then pilot changes using nonproduction accounts and synthetic records.

### Scope

This starter guide covers the control areas below. Edition, release, tenant and authorization conditions can affect exact availability. Documentation-derived console paths have not been tested in a live customer tenant. Read-only packs collect narrow evidence; they do not score tenant compliance or apply remediation.

## Table of Contents

1. [Security Configuration](#1-security-configuration)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Security Configuration

### 1.1 Pilot and enforce the login IP allowlist

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-3

#### Description

Put human and integration logins behind approved, stable egress before using blocking mode.

#### Rationale

- Source IP restrictions limit where newly authenticated sessions can originate. A permissive entry can defeat the boundary; an incomplete list can lock out users and break business integrations.

#### ClickOps Implementation

In **Setup → Quick Find → Login IP Allowlist**, add approved ranges and mark each as **API**, **User Interface**, or **Any** only when both paths need it. Confirm business-unit inheritance or separate lists. In **Security Settings → Edit**, select **Log Allowlist Violations** while validating paths, then **Log Violations and Deny Access** after acceptance. Salesforce announced a phased mandatory rollout through January 2027; check tenant notice rather than assuming the old default.

Source: [Salesforce Marketing Cloud Engagement documentation](https://help.salesforce.com/s/articleView?id=sf.mc_overview_enable_allowlisting.htm&language=en_US&type=5) (checked 2026-11-27).

**Automation:** No documented REST write handle for this setting was established in the reviewed API scope index.

#### Validation & Testing

Verify new sessions from approved and unapproved test egress for each login type; existing sessions are not a valid test. Keep a tested administrator recovery route and review the Access Log. Do not depend on monitoring mode remaining available after vendor enforcement.

---

### 1.2 Scope Installed Packages

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-6

#### Description

Limit a server-to-server package to one approved workload and the minimum API scopes.

#### Rationale

- The installed package uses client credentials without an end-user context. Its allowed scopes and business-unit access define its effective reach.

#### ClickOps Implementation

In **Setup → Installed Packages**, use a dedicated server-to-server API Integration for the workload. Remove scopes it does not need after reviewing dependencies. Record the business-unit MID and owner. Store the client secret in an approved secret store and use the package Authorization Base URI for token issuance.

Source: [Salesforce Marketing Cloud Engagement documentation](https://developer.salesforce.com/docs/marketing/marketing-cloud/guide/integration-s2s-client-credentials.html) (checked 2026-11-27).

**Automation:** Token issuance is documented, but it does not change package scopes.

#### Validation & Testing

Compare the token response scope to the approved inventory; verify required benign calls still succeed after propagation. Rotate by following the package lifecycle and testing consumers before revocation.

---

### 1.3 Collect and verify Security Events

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AU-6

#### Description

Enable Audit Trail and collect a bounded sample of security events using an audit-only integration.

#### Rationale

- Without log collection, identity misuse and unexpected integration authentication are difficult to investigate. An empty page alone does not establish either successful coverage or absence of activity.

#### ClickOps Implementation

In **Setup → Security Settings**, select **Enable Audit Trail Data Collection**. Set up a dedicated installed package with **Audit Logging → API Access** and issue a token with `tracking_events_read`. Use Automation Studio extracts or an approved protected evidence sink for ongoing collection.

Source: [Salesforce Marketing Cloud Engagement documentation](https://help.salesforce.com/s/articleView?id=sf.mc_overview_security_settings.htm&language=en_US&type=5) (checked 2026-11-27).

**Automation:** REST GET verifies accessible event records; it does not enable collection.

#### Code Implementation

{% include pack-code.html vendor="salesforce-marketing-cloud" section="1.3" %}

#### Validation & Testing

Generate an approved benign test login, confirm its event arrives after expected ingestion delay, and compare tenant and source fields against the change window. The pack retrieves one page, not a complete export.

---

### 1.4 Require MFA on each supported human sign-in path

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-2

#### Description

Verify that native sign-ins use Marketing Cloud Engagement MFA and that federated users satisfy MFA at the identity provider. Treat API-only identities as a separate credential flow.

#### Rationale

- A federated sign-in without MFA leaves the session dependent on one factor. Legacy and alternate access paths require separate validation instead of an assumption that SSO covers all users.

#### ClickOps Implementation

In **Setup → Security Settings**, inspect the Engagement authentication settings for native users. For SSO accounts, apply MFA through the approved identity provider and review Salesforce's announced enforcement requirements for the tenant. In **Security Settings**, set a short interactive session timeout; Salesforce recommends 20 minutes. Before setting account-wide inactivity expiry, inventory any legacy API users to avoid expiring a required integration unexpectedly.

Source: [Security settings and tools](https://help.salesforce.com/s/articleView?id=sf.mc_overview_security_settings.htm&language=en_US&type=5) and [current and upcoming authentication requirements](https://help.salesforce.com/s/articleView?id=release-notes.rn_mce_upcoming_security_requirements.htm&language=en_US&type=5) (checked 2026-11-27).

**Automation:** No documented REST setting or supported tenant CLI for these controls was verified.

#### Validation & Testing

From a fresh session, verify the approved MFA sequence for both applicable login paths. Separately confirm that required workload credentials still function and that the configured timeout ends an inactive browser session.

## 2. Compliance Quick Reference

These mappings support control objectives; they are not claims of certification or compliance.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Pilot and enforce the login IP allowlist | AC-3 |
| 1.2 | Scope Installed Packages | AC-6 |
| 1.3 | Collect and verify Security Events | AU-6 |
| 1.4 | Require MFA on each supported human sign-in path | IA-2 |

### References

- [Coverage and validation boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-data-platform-source-coverage.md)
- [REST permission scopes](https://developer.salesforce.com/docs/marketing/marketing-cloud/references/mc_rest_rest_permission_scopes/rest-permissions-and-scopes.html)
- [Official REST Security Events request example](https://www.postman.com/salesforce-developers/salesforce-developers/documentation/yzxd2wj/salesforce-marketing-cloud-apis?entity=request-14448118-b338e983-e712-4264-9594-d1b4a19c2bc4)
- [IP allowlist rollout notice](https://help.salesforce.com/s/articleView?id=005387198&language=en_US&type=1)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial controls and evidence pack; no live tenant verification. |
