---
layout: guide
title: "Google Analytics 360 Hardening Guide"
vendor: "Google Analytics 360"
slug: "google-analytics-360"
tier: "2"
category: "Marketing"
description: "Harden Analytics 360 GA4 property access, event-data retention and web stream redaction."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers GA4 in an Analytics 360 account, not Universal Analytics or Google Ads. Verify whether each control is evaluated at the account, property or web data stream. [Palo Alto’s SSPM connector](https://docs.paloaltonetworks.com/saas-security/sspm/onboard-saas-apps-supported-by-sspm/onboard-a-google-analytics-app-to-sspm) specifies Analytics 360; that is scope evidence, not a recommendation to grant its full OAuth permissions.

**Validation status:** Vendor documentation and local mocks. No Analytics tenant was accessed.

### Intended Audience

Analytics 360 property owners, security administrators and privacy engineers.

### How to Use This Guide

Establish access scope before shortening retention or editing active data streams. Use synthetic test data, compare results against policy, and document release impact.

### Scope

Property access, property data retention and web-stream redaction. Google Workspace account sign-in is a separate control plane. Connected Ads, BigQuery exports and first-party collection systems are not automatically covered by a property setting.

## Table of Contents

1. [Property and Collection Controls](#1-property-and-collection-controls)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Property and Collection Controls

### 1.1 Reduce Inherited and Direct Administrative Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Limit account-level and property-level grants to the minimum needed. A more restrictive direct role does not erase a broader inherited role.

#### Rationale

**Why This Matters:**

- A high-level analytics account grant can extend to multiple properties or undermine a least-privilege property design.

#### ClickOps Implementation

1. In **Admin → Account access management** and **Property access management**, review both direct and inherited access. Separate Administrator, Editor and read roles. [Roles and data restrictions](https://support.google.com/analytics/answer/9305587?hl=en).
2. Review broad groups and unneeded access with the corresponding owner. Before removal, preserve an authorized administrator and verify required integration jobs.

**Automation:** Google publishes [access-binding APIs](https://developers.google.com/analytics/devguides/config/admin/v1/rest/v1alpha/accounts.accessBindings), marked alpha. No role-write pack is shipped; account and property inheritance must be evaluated together.

#### Validation & Testing

Verify a pilot user has the intended property access and cannot manage sensitive settings without the required role.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

### 1.2 Minimize Event and User Data Retention

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | SI-12 |

#### Description

Use the shortest approved user and event data windows. Decide whether user lifetime should refresh on new activity rather than inheriting the default.

#### Rationale

**Why This Matters:**

- Long retention keeps raw user- and event-level data available longer. Shortening a window leads to deletion in Google’s monthly processing and does not erase every export or standard aggregated report.

#### ClickOps Implementation

1. Open **Admin → Data collection and modification → Data retention** for the property. Review both event and user windows and the reset-on-activity setting. [Google Analytics data retention](https://support.google.com/analytics/answer/7667196?hl=en).
2. Review downstream report and investigation requirements before shortening retention. Analytics 360 may offer longer event windows; user data and large properties have different limits.

**Automation:** The [beta retention read](https://developers.google.com/analytics/devguides/config/admin/v1/rest/v1beta/properties/getDataRetentionSettings) reports one property’s fields through the Analytics read-only OAuth scope. The vendor documents a separate change method; the pack does not change retention or delete data.

#### Code Implementation

{% include pack-code.html vendor="google-analytics-360" section="1.2" %}

#### Validation & Testing

Compare the returned selectors against your approved policy, including any unknown field; reconcile separately with BigQuery dataset and downstream retention.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | SI-12 |

### 1.3 Redact Sensitive Fields at the Web Data Stream

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | PT-4 |

#### Description

Configure email and approved query-parameter redaction where applicable. Prevent sensitive data at source rather than relying on text pattern matching.

#### Rationale

**Why This Matters:**

- The vendor says web redaction is client-side and best effort; server-side Measurement Protocol and Data Import are not protected by it.

#### ClickOps Implementation

1. Open **Admin → Data collection and modification → Data streams** and select the web stream. Under **Events**, open **Redact data**.
2. Review both email and URL query parameters and use **Test data redaction** with synthetic values. [GA4 data redaction](https://support.google.com/analytics/answer/13544947?hl=en).

**Automation:** ClickOps for this exact setting. No documented Admin API handle for this redaction switch was verified in the reviewed reference.

#### Validation & Testing

Verify the preview and a nonproduction DebugView or telemetry capture. Independently review Measurement Protocol and Data Import mappings.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | PT-4 |

## 2. Compliance Quick Reference

| Control | NIST SP 800-53 Rev. 5 |
|---------|----------------------|
| Analytics access scoping | AC-6 |
| Data retention | SI-12 |
| Data stream redaction | PT-4 |

Control mappings are not a certification claim.

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-27 | 0.1.0 | ai-drafted | Analytics 360 access, retention and redaction baseline | Jai |
