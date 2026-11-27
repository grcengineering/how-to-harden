---
layout: guide
title: "Gainsight PX Hardening Guide"
vendor: "Gainsight PX"
slug: "gainsight-px"
tier: "2"
category: "Data"
description: "Harden Gainsight Product Experience login, publication access and analytics tracking boundaries."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Gainsight Product Experience has its own subscription administration and tracking SDK. The [Gainsight CS guide](/guides/gainsight/) does not configure this control plane.

**Validation status:** Documentation review and offline pack checks only; no live PX tenant was accessed.

### Intended Audience

PX administrators, product release operators and web teams who manage the PX SDK.

### How to Use This Guide

First reduce administrative and publication access, then adjust tracking in a synthetic pilot. Record what is not observed before rollout.

### Scope

PX administration and customer-configured tracking. Not Gainsight CS, Salesforce, or an audit of the vendor's infrastructure.

## Table of Contents

1. [Access and Publishing](#1-access-and-publishing)
2. [Analytics and Preferences](#2-analytics-and-preferences)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and Publishing

### 1.1 Require SAML for Product Administrators

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2 |

#### Description

Select the SAML-only sign-in mode and require the identity provider to enforce MFA. Check access exceptions before disabling password sign-in.

#### Rationale

**Why This Matters:**

- An exception in the PX allowlist can retain an alternate sign-in path even while the subscription is set to SAML Only.

#### ClickOps Implementation

1. In **Administration → SSO / SAML**, configure the trusted IdP metadata and validate the SAML setup from a second session.
2. Select **SAML Only**, verify IdP MFA, and review the PX allowlist. The vendor recommends no exceptions for general use. Document recovery procedures before changing the setting. [Configure SAML](https://support.gainsight.com/PX/Administration/Security/Configure_SAML_Authentication).

**Automation:** ClickOps. No documented customer API or first-party CLI to set the PX SAML mode was verified.

#### Validation & Testing

Verify approved pilot sign-in and failure of direct password sign-in for an unexcepted account. Preserve a reviewed recovery procedure.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2 |

### 1.2 Separate Editing from Production Launch

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Grant production launch privileges only to approved release operators. Use product-specific permissions where duties differ by application.

#### Rationale

**Why This Matters:**

- An administrator or Production Launcher can affect end users through production engagements. An Editor can prepare changes without launching them.

#### ClickOps Implementation

1. Open **Administration → User Management**. Review **Users** and **Role Groups**, including subscription administrators and Global Administrators where workspace membership supports them.
2. Use **Editor** for authoring without release rights and **Manager** only for nonproduction launches. Restrict **Production Launcher** to named release operators. Export role assignments in the same screen and store evidence privately. [PX user management](https://support.gainsight.com/docs/user-management).

**Automation:** Vendor-documented export, no supported API to set subscription operators verified. The tracked-user REST API is a different subject and must not be used as an operator inventory.

#### Validation & Testing

Use an approved synthetic engagement. Confirm an Editor can preview but cannot launch, and that a Manager lacks the production release control.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

## 2. Analytics and Preferences

### 2.1 Exclude Sensitive Routes from Tracking

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | SI-12 |

#### Description

Exclude pages that carry sensitive information from the PX SDK's automatic tracking. Prefer exclusions over attempting to redact an unpredictable set of data.

#### Rationale

**Why This Matters:**

- Analytics events can contain paths or query parameters. Do not rely on a secret-bearing URL or assume downstream processing will redact it.

#### ClickOps Implementation

1. Inventory sensitive routes and select exact product-specific exclusions in **Administration → SDK Settings → Tracking**. Test with non-sensitive synthetic data. [SDK tracking settings](https://support.gainsight.com/docs/exclude-and-mask-tracked-data).
2. If controlling a versioned browser integration, pass the verified `filterUrls` and `filterType` settings as part of the PX SDK configuration. Retain the rest of the existing configuration. [Native filter example](https://support.gainsight.com/v1/docs/security-tracking-filters).

**Automation:** The config pack emits a PX-native configuration fragment for review and integration. Printing the fragment does not change a tenant or activate the PX SDK.

#### Code Implementation

{% include pack-code.html vendor="gainsight-px" section="2.1" %}

#### Validation & Testing

Observe authorized pilot events for the excluded and allowed synthetic routes. Confirm the excluded route and its parameters do not appear in tracking payloads; this does not verify independently instrumented events.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | SI-12 |

### 2.2 Check Tracking Opt-Out for an Authorized Test User

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | PT-4 |

#### Description

Use an approved synthetic user to verify recorded usage and email analytics preferences. Avoid treating a missing value as consent or as proof of opt-out.

#### Rationale

**Why This Matters:**

- Preference fields control specific data paths; opting out of email analytics does not suppress operational delivery or unsubscribe processing.

#### ClickOps Implementation

1. Open **Administration → REST API** and review key ownership and scope. The [documented preference read](https://support.gainsight.com/PX/Security_and_Compliance/Enablement/User_Preferences_for_Tracking_and_Engagement) requires **User Read/Write**, even to make a GET call. Use a narrowly scoped test tenant credential and do not deploy broader ongoing access solely for this check.
2. Apply the test user's preference through the authorized consent workflow; independently run the code pack for the same opaque test identity.

**Automation:** The pack performs a single GET against the documented US HTTPS origin and emits only the two preference values. It does not update consent. EU and other regional behavior is not tested by this pack.

#### Code Implementation

{% include pack-code.html vendor="gainsight-px" section="2.2" %}

#### Validation & Testing

Confirm both returned values are explicitly false for a test user who opted out of both. Independently verify event behavior and record missing fields as unknown.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | PT-4 |

## 3. Compliance Quick Reference

| Area | NIST SP 800-53 Rev. 5 | Evidence |
|------|----------------------|----------|
| Authentication | IA-2 | Pilot IdP and sign-in evidence |
| Release roles | AC-6 | Reviewed subscription roster and pilot outcome |
| Tracked data | SI-12 | Approved exclusions and synthetic event comparison |
| Opt-out handling | PT-4 | Redacted pilot preference assessment and observed events |

The vendor also documents a [strict CSP path](https://support.gainsight.com/v1/docs/using-px-with-content-security-policy-csp) for customer applications. Do not weaken an existing CSP to make a release work; test the documented integration under your approved policy.

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial PX-specific roles, SAML and tracking controls | Jai |
