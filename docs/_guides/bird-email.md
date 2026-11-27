---
layout: guide
title: "Bird Email Hardening Guide"
vendor: "Bird Email"
slug: "bird-email"
tier: "2"
category: "Marketing"
description: "Harden Bird Email authentication, access boundaries, and security evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers Bird Email, the current successor to SparkPost. The vendor also documents a separate migration from existing SparkPost accounts; their IDs and credentials do not work in the new Bird API.

### Intended Audience

Tenant administrators, identity engineers, and reviewers who need defensible evidence of configuration.

### How to Use This Guide

- **L1 (Crawl):** Close basic access and disclosure gaps.
- **L2 (Walk):** Add targeted reviews and scoped evidence.
- Treat documented but untested settings as guidance, not a statement about your tenant.

### Scope

These controls cover only the stated product plane. No procedure was exercised in a live tenant.

## Table of Contents

1. [API credential boundaries](#1-api-credential-boundaries)
2. [Sending domain evidence](#2-sending-domain-evidence)
3. [Compliance Quick Reference](#compliance-quick-reference)

## 1. API credential boundaries

### 1.1 Scope production API keys to one workload and restrict their origin

**Profile Level:** L1 (Crawl)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Assign only necessary scope-level pairs and isolate key use by workspace, workload and region. Bird key allowlists are distinct from workspace-level settings and protect token use, not human sign-in.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow overbroad stolen api credentials.
- Test separately for unplanned sending outages after restriction; do not assume related controls inherit the same policy.

**Attack Prevented:** Overbroad stolen API credentials; Unplanned sending outages after restriction.

#### Prerequisites

Authorized Bird workspace administrator, approved workloads and stable egress where allowlisting is practical.

#### ClickOps Implementation

1. In the Bird workspace, use the documented key controls to create a replacement key with only required read or write scopes.
2. Attach an approved key IP allowlist where stable egress and redundancy have been tested.
3. Roll workloads gradually to the replacement key and revoke the old key on the approved schedule.

[Vendor instructions](https://bird.com/docs/guides/authentication)

**Automation:** Unverified for this exact policy operation. Use the documented console action; do not substitute an unrelated API or a private endpoint.

#### Validation & Testing

Use a synthetic workload to confirm authorized operations and expected denial of excess permissions or unapproved egress. Do not send to real customer lists for a test.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Replace compromised keys immediately; a grace period is for planned rotations, not incident recovery.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## 2. Sending domain evidence

### 2.1 Verify sending domain ownership and authorization in the correct workspace

**Profile Level:** L2 (Walk)

| Framework | Control |
| --- | --- |
| NIST 800-53 Rev. 5 | AC-3 |

#### Description

Keep the sending domain verified, prove authorization separately from tracking, and independently enforce a suitable DMARC policy. Bird readiness can pass with monitoring-only p=none.

#### Rationale

**Why This Matters:**
- Reduce the conditions that allow unauthorized sending-domain use.
- Test separately for mistaking delivery readiness for dmarc enforcement; do not assume related controls inherit the same policy.

**Attack Prevented:** Unauthorized sending-domain use; Mistaking delivery readiness for DMARC enforcement.

#### Prerequisites

Bird workspace with an approved domains:read key, correct region, exact workspace, domain resource IDs and DNS administrator.

#### ClickOps Implementation

1. Open **Email → Domains** and select the scope-approved sender.
2. Publish only vendor-provided required records and review DNS alignment. Test DMARC enforcement rollout separately with all legitimate senders accounted for.
3. Run the Code Pack in each active region to verify Bird’s last recorded health without triggering re-verification.

[Vendor instructions](https://bird.com/docs/guides/email/sending-domains)

#### Code Implementation

The pack is read-only and limited to the documented evidence scope, not enforcement. See the [vendor implementation reference](https://bird.com/en-gb/docs/api/reference/get-domain).

{% include pack-code.html vendor="bird-email" section="2.1" %}

#### Validation & Testing

Verify the resource and workspace IDs, expected DNS domain, ownership verified and sending verified. Observe DNS or authenticated test mail separately to verify policy enforcement.

#### Monitoring & Maintenance

Repeat after a configuration or ownership change and during quarterly access review. Store scope, date, result, and any exceptions with the evidence.

#### Operational Impact

Do not delete DNS entries still used by traffic. During migration, keep legacy SparkPost resources protected until approved retirement.

#### Compliance Mappings

| Framework | Control ID | Control Description |
| --- | --- | --- |
| NIST 800-53 Rev. 5 | AC-3 | Contributes to the named control; does not assert compliance. |

## Compliance Quick Reference

Use the NIST IDs in each control to trace evidence to the applicable policy. These mappings are recommendations, not certification.

## Appendix A: Edition and Tier Compatibility

The prerequisites in each control identify the validated documentation scope. Confirm entitlement in the tenant before scheduling an enforcement action; unsupported or untested editions are not asserted here.

## Appendix B: References

- [Product documentation](https://bird.com/products/email/sparkpost)
- [Technical documentation](https://bird.com/docs/api)
- [Scope production API keys to one workload and restrict their origin](https://bird.com/docs/guides/authentication)
- [Verify sending domain ownership and authorization in the correct workspace](https://bird.com/docs/guides/email/sending-domains)
- [Migration from SparkPost](https://bird.com/en-nl/docs/guides/email/migrate/sparkpost)


## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial guide and evidence packs | Codex |

## Contributing

Report corrections or propose a control in the [project issue tracker](https://github.com/grcengineering/how-to-harden/issues).
