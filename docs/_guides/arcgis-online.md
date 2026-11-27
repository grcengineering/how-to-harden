---
layout: guide
title: "ArcGIS Online Hardening Guide"
vendor: "ArcGIS Online"
slug: "arcgis-online"
tier: "2"
category: "Data"
description: "Harden ArcGIS Online authentication, access boundaries, and security evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers Esri-managed ArcGIS Online organizational subscriptions. ArcGIS Enterprise, ArcGIS Pro and ArcGIS Location Platform do not inherit this guide.

### Intended Audience

Tenant administrators, identity engineers, and reviewers who need defensible evidence of configuration.

### How to Use This Guide

- **L1 (Crawl):** Close basic access and disclosure gaps.
- **L2 (Walk):** Add targeted reviews and scoped evidence.
- Treat documented but untested settings as guidance, not a statement about your tenant.

### Scope

These controls cover only the stated product plane. No procedure was exercised in a live tenant.

## Table of Contents

1. [Authentication](#1-authentication)
2. [Organization visibility](#2-organization-visibility)
3. [Compliance Quick Reference](#compliance-quick-reference)

## 1. Authentication

### 1.1 Require phishing-resistant MFA through the organization IdP

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Use organization-specific SAML or OpenID Connect with strong IdP policy. ArcGIS-native MFA and external IdP MFA are independent; the portal mfaEnabled flag is not evidence of enforcement.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow password-only access to gis data.
- Test separately for lockout during federation rollout; do not assume related controls inherit the same policy.

**Attack Prevented:** Password-only access to GIS data; Lockout during federation rollout.

#### Prerequisites

Default or authorized custom ArcGIS Online administrator and an IdP administrator, with a tested recovery route.

#### ClickOps Implementation

1. Open **Organization → Settings → Security → Logins** and configure SAML or OpenID Connect using the vendor procedure.
2. Pilot IdP login, MFA, and recovery before restricting unintended alternatives.
3. For any remaining ArcGIS-native accounts, follow Esri’s separately documented MFA requirement and recovery steps.

[Vendor instructions](https://doc.arcgis.com/en/arcgis-online/administer/manage-logins.htm)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Test an assigned user, an unassigned user, and approved emergency recovery in fresh sessions. Check the separate MFA enforcement status for native sign-in.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Keep tested recovery access during rollout. Roll back only the specific failing federation change under change control.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## 2. Organization visibility

### 2.1 Restrict anonymous organization access and non-admin public sharing

**Profile Level:** L2 (Walk)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

For an internal, non-Verified Organization, assess portal access and non-admin public sharing as separate settings. Default admins or specially privileged roles may still publish; disabling portal access does not remove public item URLs.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow accidental public gis publication.
- Test separately for false assurance from the organization home page; do not assume related controls inherit the same policy.

**Attack Prevented:** Accidental public GIS publication; False assurance from the organization home page.

#### Prerequisites

ArcGIS Online administrator, exact tenant and organization IDs, and a review of public items and Verified Organization requirements.

#### ClickOps Implementation

1. In **Organization → Settings → Security → Access and permissions**, turn off **Allow anonymous access to your organization** only if the organization does not rely on Verified Organization status or intended public entry.
2. Turn off the option allowing non-admins to make their content, groups, and profiles public where approved.
3. Review existing public items and the roles permitted to share publicly. Use the Code Pack to compare both organization settings.

[Vendor instructions](https://doc.esri.com/en/arcgis-online/latest/administer/configure-security.html)

#### Code Implementation

The pack is read-only and limited to the documented evidence scope, not enforcement. See the [vendor implementation reference](https://developers.arcgis.com/rest/users-groups-and-items/portal-self/).

{% include pack-code.html vendor="arcgis-online" section="2.1" %}

#### Validation & Testing

Verify the portal login boundary and test access to a representative synthetic item through its direct standard ArcGIS Online URL. Pass of the pack is not a check of item sharing.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Use owner-approved exceptions for intentional public datasets and verify their dependencies. Do not broadly restore sharing to recover one public map.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## Compliance Quick Reference

Use the NIST IDs in each control to trace evidence to the applicable policy. These mappings are recommendations, not certification.

## Appendix A: Edition and Tier Compatibility

The prerequisites in each control identify the validated documentation scope. Confirm entitlement in the tenant before scheduling an enforcement action; unsupported or untested editions are not asserted here.

## Appendix B: References

- [Product documentation](https://doc.arcgis.com/en/arcgis-online/get-started/what-is-agol.htm)
- [Technical documentation](https://developers.arcgis.com/rest/users-groups-and-items/portal-self/)
- [Require phishing-resistant MFA through the organization IdP](https://doc.arcgis.com/en/arcgis-online/administer/manage-logins.htm)
- [Restrict anonymous organization access and non-admin public sharing](https://doc.esri.com/en/arcgis-online/latest/administer/configure-security.html)


## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial guide and evidence packs | Codex |

## Contributing

Report corrections or propose a control in the [project issue tracker](https://github.com/grcengineering/how-to-harden/issues).
