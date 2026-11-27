---
layout: guide
title: "Microsoft 365 Copilot Hardening Guide"
vendor: "Microsoft 365 Copilot"
slug: "microsoft-365-copilot"
tier: "1"
category: "AI/ML Platform"
description: "Microsoft 365 Copilot and Copilot Chat use tenant data and tools under product-specific policies."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
platform: "Microsoft"
platform_slug: "microsoft-365"
product: "Microsoft 365 Copilot"
---

## Overview

Microsoft 365 Copilot and Copilot Chat use tenant data and tools under product-specific policies. Apply shared identity, consent, and storage protections from the [Microsoft 365 platform guide](/guides/microsoft-365/) first; use the [Copilot Studio guide](/guides/copilot-studio/) for building and publishing Studio agents.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Grounding and tool boundaries](#1-grounding-and-tool-boundaries)
2. [Content policy and audit](#2-content-policy-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Grounding and tool boundaries

### 1.1 Decide whether Copilot may search the public web

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-4, SC-7 |

#### Description

Use the Microsoft 365 Cloud Policy setting **Allow web search in Copilot** to control public web grounding. Set it explicitly for sensitive populations rather than relying on its unset fallback behavior.

#### Rationale

**Why This Matters:**

- Copilot may derive terms from prompts for external search. A grounding boundary limits that class of outbound data processing.

#### Prerequisites

Cloud Policy management rights, scoped pilot group, and approved business requirements for web-grounded answers.

#### ClickOps Implementation

1. In the Microsoft 365 admin center go to **Copilot > Settings** and follow the web search shortcut to the Microsoft 365 Apps admin center Cloud Policy service.
2. Locate **Allow web search in Copilot** and assign **Disabled** for users that must not use public web grounding.
3. Check overlapping assigned policies and applicable subscription and client behavior.

**Automation:** Use Cloud Policy. No first-party CLI or API for writing this specific setting was verified.

#### Validation & Testing

After policy propagation, use a fresh authorized test session and a benign question whose answer requires new public web content. Confirm the web-grounding behavior matches the scoped policy and pilot population.

#### Monitoring & Maintenance

Recheck after licensing or policy group changes. Audit evidence may supplement, not replace, testing an expected policy result.

#### Operational Impact & Rollback

Disabling web grounding can reduce response completeness. Restore the documented prior setting for an approved group only if the business exception is accepted.

**Sources:** [Web search policy and behavior](https://learn.microsoft.com/en-us/copilot/plan/manage-public-web-access). [Copilot admin settings](https://learn.microsoft.com/en-us/copilot/implement/configure-copilot-admin-center).

### 1.2 Restrict advanced agent and plugin package uploads

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, CM-3, CM-7 |

#### Description

Restrict uploading of advanced agent and plugin packages to the minimum approved builders. Manage use and deployment of existing agents or plugins separately from who can upload them.

#### Rationale

**Why This Matters:**

- Without independent package and deployment gates, an unauthorized package can add tools or change data connections.

#### Prerequisites

Named pilot authors, application owners, and the role required to edit Copilot settings.

#### ClickOps Implementation

1. Open **Copilot > Settings > Advanced package uploads** in the Microsoft 365 admin center and choose the narrowest approved population.
2. Review applicable published agents and deployments under **Settings > Integrated apps** and remove unapproved assignments after reviewing dependencies.
3. Evaluate agent permissions and connector access before approving deployment.

**Automation:** Direct automation of this setting was not verified; do not substitute Copilot Studio publishing controls.

#### Validation & Testing

Check that an authorized test builder can reach the upload workflow while an out-of-scope test user cannot. Independently verify deployed-agent access with a pilot user.

#### Monitoring & Maintenance

Review uploader assignments and agent inventory on publisher, connector or permission changes.

#### Operational Impact & Rollback

A restrictive deployment adjustment can break an approved workflow. Restore only the specific approved role or assignment rather than reverting to tenant-wide author access.

**Sources:** [Copilot admin settings](https://learn.microsoft.com/en-us/copilot/implement/configure-copilot-admin-center).

## 2. Content policy and audit

### 2.1 Prevent processing of approved sensitive content classes

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-4, AC-6 |

#### Description

Use a Purview DLP policy at the documented Microsoft Copilot, Copilot Chat and Copilot Cowork policy location. Select the sensitivity labels and workload conditions appropriate to your data policy.

#### Rationale

**Why This Matters:**

- Existing permission to read a file is not automatically permission to use it to generate summaries or AI responses.

#### Prerequisites

Appropriate Purview subscription, administrator permissions and published sensitivity labels with fully synthetic test fixtures.

#### ClickOps Implementation

1. In Purview Data Loss Prevention policy setup, select the **Microsoft Copilot, Copilot Chat, and Copilot Cowork** location where available.
2. For the rule, choose **Content contains > Sensitivity labels** and the approved labels, and use the documented **Prevent Copilot from processing content** action.
3. Validate with a targeted population before widening enforcement. Track supporting client, indexed file and label limitations.

**Automation:** Exact direct API for this Copilot-specific DLP action was not verified.

#### Validation & Testing

Use a matched pair of labeled and unlabeled synthetic files with the same access permissions. Check the covered experience handles the labeled case as expected; this does not prove uploaded content or every Copilot surface is covered.

#### Monitoring & Maintenance

Review data classification changes, licensing, and coverage for direct uploads, source workloads and Copilot clients.

#### Operational Impact & Rollback

Incorrect targeting can block legitimate work. Narrow policy scope or restore the previous rule during a documented change window.

**Sources:** [Purview Copilot DLP conditions and coverage](https://learn.microsoft.com/en-us/purview/dlp-microsoft365-copilot-location-learn-about).

### 2.2 Verify Copilot audit activity without exporting content

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-2, AU-6, AU-9 |

#### Description

Query the unified audit log for the test account and time window, then compare records to the pilot’s expected activity. Limit output to counts or non-content metadata.

#### Rationale

**Why This Matters:**

- Without tested logs, a missing signal can be misread as an absence of usage. Prompt and response evidence may be sensitive and access must be controlled.

#### Prerequisites

Purview audit access, Exchange Online PowerShell for the pack, test user and a known benign event in UTC.

#### ClickOps Implementation

1. Open **Microsoft Purview > Audit**. Search for the pilot account and relevant interval with **Copilot activities > Interacted with Copilot**.
2. Compare evidence to the intended application and event, allowing for ingestion delay.
3. Minimize written evidence; do not export prompt, response or accessed-file details by default.

#### Code Implementation

{% include pack-code.html vendor="microsoft-365-copilot" section="2.2" %}

#### Validation & Testing

Confirm a known test interaction is present in the intended application. A 0-row sample or limited search is not proof of no interactions or trustworthy tenant-wide logs.

#### Monitoring & Maintenance

Check audit access, retention and expected-event coverage by Copilot surface.

#### Operational Impact & Rollback

Read only. Stop or correct a mis-scoped search and preserve audit logging.

**Sources:** [Copilot audit schema and search](https://learn.microsoft.com/en-us/office/office-365-management-api/copilot-schema). [PowerShell audit query](https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/search-unifiedauditlog).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Decide whether Copilot may search the public web | AC-4, SC-7 |
| 1.2 Restrict advanced agent and plugin package uploads | AC-6, CM-3, CM-7 |
| 2.1 Prevent processing of approved sensitive content classes | AC-4, AC-6 |
| 2.2 Verify Copilot audit activity without exporting content | AU-2, AU-6, AU-9 |

## Appendix A: Automation and applicability

Exchange Online PowerShell is a documented read surface for audit evidence. Cloud Policy and Purview management are separate console paths; exact REST, GraphQL, Terraform, SDK, and environment-specific SIEM controls for those settings were not verified. SharePoint Restricted Content Discovery is covered in the Microsoft 365 hub; Restricted SharePoint Search is retiring and is not recommended for new enablement. Microsoft 365 identity, SharePoint permissions and Copilot Studio environment controls are not replaced here. CIS Microsoft 365 and CISA SCuBA foundational baselines are adjacent; no Copilot-specific prescription was verified.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.
