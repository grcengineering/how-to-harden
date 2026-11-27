---
layout: guide
title: "Krisp Hardening Guide"
vendor: "Krisp"
slug: "krisp"
tier: "3"
category: "AI/ML Platform"
description: "Krisp exposes distinct voice, Call Center AI and meeting administration planes"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

**Product Editions Covered:** Call Center AI Admin Portal and AI Meeting Assistant meeting-owner sharing

## Overview

Krisp exposes distinct voice, Call Center AI and meeting administration planes. Policies and credentials for one product surface do not automatically apply to the others.

### Intended Audience

Platform administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Baseline controls for the documented deployment.
- **L2 (Walk):** Add verified controls where the workload needs stronger isolation.
- **L3 (Run):** Add controls warranted by higher-risk workflows and contractual requirements.

### Scope

Covers Call Center AI team domain verification, content capture and audit telemetry, plus owner-controlled sharing of sensitive AI Meeting Assistant records. Does not cover the developer realtime voice API or device-based enrollment material.

---

## Table of Contents

1. [Identity and Administrative Access](#1-identity-and-administrative-access)
2. [Content and Sharing](#2-content-and-sharing)
3. [Audit and API Credentials](#3-audit-and-api-credentials)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Identity and Administrative Access

### 1.1 Verify only approved corporate domains

**Profile Level:** L1 (Crawl)

#### Description

Verify centrally owned domains in the specific Krisp Call Center AI team where domain discovery is needed.

#### Rationale

- Domain verification helps team admins find users; multiple teams can verify the same domain. It does not establish SSO or prove exclusive domain ownership inside Krisp.

#### Prerequisites

Call Center AI team Admin and DNS owner with an approved change.

#### ClickOps Implementation

1. In the Admin Portal choose the intended team and go to **Security → Domain**. Add the corporate domain and copy the supplied TXT value.
2. Have the DNS owner publish that value and select **Verify**. Reconcile eligible identities and review team invitations and roles separately.

Source: [Vendor configuration reference](https://help.krisp.ai/hc/en-us/articles/6104366488220-Verify-your-domain).

#### Code Implementation

No documented Portal API operation was verified for changing domain policy.

#### Validation & Testing

Capture the **Verified** status and corresponding team and domain; explicitly check member join and login controls separately.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Propagating DNS can take time and verification enables user discovery.

#### Rollback Procedure

Document and coordinate any change with both the DNS owner and team admin; verify the resulting team state rather than assuming removal of a DNS record instantly revokes it.

---

## 2. Content and Sharing

### 2.1 Minimize capture and retention for contact center calls

**Profile Level:** L2 (Walk)

#### Description

Configure separate retention for transcripts, screen recordings, and full call data. Disable capture for applicable classes of sensitive calls after legal and business review.

#### Rationale

- Redaction and retention are not equivalent to preventing capture. Krisp redaction does not apply when Voice Translation is used.

#### Prerequisites

Call Center AI team Admin, documented retention and consent policy, sandbox and compatible app version. Exclusion by Skill requires CX Bridge; exclusion by Client requires the corresponding client-information setting.

#### ClickOps Implementation

1. Open **Team Settings → Call Content → Content Management**. Review the three retention fields against approved record classes.
2. Where approved and supported, configure **Do not retain data of certain calls** with selected Skill or Client conditions. Krisp documents app version 2.81.5 or later for this setting.

Source: [Vendor configuration reference](https://help.krisp.ai/hc/en-us/articles/29322678567068-Manage-call-data-and-content-for-your-team).

#### Code Implementation

Call capture policy is verified in the Admin Portal; the separate developer and Meeting Assistant APIs are not substitutes.

#### Validation & Testing

Verify settings on the target team. Use benign synthetic calls matching and not matching conditions and confirm whether content is created; audit preference updates.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Matching calls can retain metadata but no recording, transcript, or evaluation is created. Missing or already deleted content cannot be restored simply by changing policy.

#### Rollback Procedure

Revert only future behavior with approval and document irrecoverable or expired records.

---
### 2.2 Limit meeting shares to named invitees

**Profile Level:** L1 (Crawl)

#### Description

For sensitive meetings, choose Invite only and grant the least access necessary to individually authorized recipients.

#### Rationale

- A public meeting link can work without a Krisp sign-in. Work-domain or team access can also be broader than the meeting owner expects.

#### Prerequisites

AI Meeting Assistant record owner and a synthetic meeting for testing.

#### ClickOps Implementation

1. Open **My Meetings → select meeting → Share**. Set **General access** to **Invite only**.
2. Review explicit email grants and remove unneeded recipients separately. Review calendar Auto-Share separately; do not assume the single-meeting setting rewrites prior shares.

Source: [Vendor configuration reference](https://help.krisp.ai/hc/en-us/articles/30666838645660-Share-your-meetings).

#### Code Implementation

Console-based meeting-owner action; no workspace-wide share lock or policy writer is claimed.

#### Validation & Testing

Verify a named pilot recipient can view only the intended content and an uninvited or signed-out pilot cannot. Review historical domain links individually.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Links distributed earlier may stop working. Clicking Copy link on a never-shared meeting can itself enable Anyone with the link; set Invite only before sharing.

#### Rollback Procedure

Grant access to approved named recipients; do not restore public sharing as a workaround.

---

## 3. Audit and API Credentials

### 3.1 Verify team audit access without exporting details

**Profile Level:** L2 (Walk)

#### Description

Review team audit events in the Portal and keep the API key pair in an approved secret store when programmatic checks are needed.

#### Rationale

- The documented key pair is team-specific and Portal API capabilities also include administrative operations. A read-only script is not proof the key is read-only.

#### Prerequisites

Call Center AI team Admin, approved team-specific Portal API credentials, and control owner.

#### ClickOps Implementation

1. Open **Team Settings → Security → Audit Logs**. Verify a benign approved change appears and can be attributed to the correct team.
2. If automation is authorized, generate or rotate a dedicated team key in **Integrations → API** and restrict the key to the approved runner and secret store.

Source: [Vendor configuration reference](https://help.krisp.ai/hc/en-us/articles/26372960857244-Audit-Logs).

#### Code Implementation

The pack makes one GET for one audit record and discards the body. It reports HTTP 200 reachability only. The Portal API uses Basic authentication and is not the Meeting Assistant or Developer Portal API.

{% include pack-code.html vendor="krisp" section="3.1" %}

#### Validation & Testing

Confirm latest expected synthetic action in the Portal after ingestion delay. A successful bounded API response only proves access, not completeness.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

New API automation exposes a sensitive administrative credential. Deleting a key immediately breaks dependencies.

#### Rollback Procedure

Revoke an unnecessary or compromised key after coordinating approved replacement. Never restore an exposed secret.

---

## 4. Compliance Quick Reference

These mappings indicate how settings can contribute to a control objective; they do not establish conformity or operation over a period.

| HTH control | NIST SP 800-53 Rev. 5 | Evidence to retain |
| --- | --- | --- |
| 1.1 | IA-4 | Verified domain and intended team |
| 2.1 | SI-12 | Approved capture/retention and synthetic observation |
| 2.2 | AC-3, AC-6 | Named recipient and denied viewer checks |
| 3.1 | AU-2, IA-5 | Redacted event evidence and bounded endpoint test |

## Appendix A: Automation and Evidence

Do not reuse Call Center AI Portal credentials in the other Krisp APIs. Call Content settings and meeting-owner sharing require separate validation; their scope is not transferable. No live account was used.

## Appendix B: References

- [Call Center AI Portal](https://help.krisp.ai/hc/en-us/articles/28598422184604-Getting-started-with-the-Krisp-Admin-Portal)
- [Krisp Portal API](https://help.krisp.ai/hc/en-us/articles/26610680024604-Krisp-Portal-API)
- [Meeting Assistant API](https://meeting-api-docs.krisp.ai/docs/getting-started)

## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial platform controls and documented verification packs | How to Harden Community |

## Contributing

Report inaccurate or outdated guidance through the [issue tracker](https://github.com/grcengineering/how-to-harden/issues).
