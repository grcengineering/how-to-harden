---
layout: guide
title: "Bitwarden Password Manager Hardening Guide"
vendor: "Bitwarden Password Manager"
slug: "bitwarden"
tier: "2"
category: "Security"
description: "Harden organization policies, shared collections, SSO and event monitoring in Bitwarden Password Manager."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Bitwarden organization vaults contain credentials usable across other services. This guide applies to Bitwarden-hosted Teams and Enterprise Password Manager organizations; policies and SSO are Enterprise. It does not cover Secrets Manager, consumer vault hardening or self-hosting.

### Intended Audience

- SaaS administrators and security engineers
- GRC practitioners collecting configuration and access evidence

### How to Use This Guide

- **L1 (Crawl):** Establish identity, least privilege and review basics.
- **L2 (Walk):** Add controls that require staged deployment or split administration.

### Scope

ClickOps and code are documentation-derived; no tenant was accessed. Run inventories only on authorized accounts. They attest the visible configuration, not overall compliance.

## Table of Contents

1. [Control Checklist](#1-control-checklist)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Control Checklist

### 1.1 Require Two-Step Login or Enforced SSO

**Profile Level:** L1 (Crawl)

#### Description

Require a second factor on every relevant sign-in path. For Enterprise use either the native policy or a verified IdP MFA path, following Bitwarden's guidance not to apply the native policy to an organization already using SSO or Duo for all members.

#### Rationale

**Why This Matters:**

- Without MFA, a single stolen credential may expose an account with access to a shared vault.

#### Prerequisites

Enterprise owner or admin; protected recovery codes for emergency administrators; inventory active sign-in paths.

#### ClickOps Implementation

Go to **Admin Console → Settings → Policies → Require two-step login**. Arrange enrollment with a test group first, then use **Turn on** and **Save**. For an SSO-first organization, use the separate **Require single sign-on authentication** policy after successful pilot and require MFA at the IdP. Independently require MFA for exempt administrators and owners.

**Source:** [Vendor administration documentation](https://bitwarden.com/help/policies/).

#### Code Implementation

{% include pack-code.html vendor="bitwarden" section="1.1" %}

#### Validation & Testing

Review all effective sign-in paths. The API pack inventories configured policies only; if a continuation token is returned, run again with that token until there is no next page. It cannot prove that IdP MFA is enforced or each exempt account is protected.

#### Operational Impact

Noncompliant members can lose organization access; onboarding also differs after enforcement. Keep a working owner session and roll back the policy in the admin console if an enrollment issue causes unexpected revocations.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | IA-2 | Supports this objective; configuration alone does not establish compliance. |

### 1.2 Limit Shared Collection Permissions

**Profile Level:** L1 (Crawl)

#### Description

Separate shared credentials by operational purpose, grant access to narrow groups, and review direct grants separately.

#### Rationale

**Why This Matters:**

- A broad or forgotten collection grant extends one compromised identity into unrelated credentials.

#### Prerequisites

An organization owner or collection manager and an approved roster of collection owners and groups.

#### ClickOps Implementation

Open **Admin Console → Collections**, open the target collection's settings and review its **Access**. For each person or group, grant only the required view, edit, or manage permissions. Review collection-wide settings under **Settings → Organization info → Collection management**, especially the option giving owners and admins management of all collections.

**Source:** [Vendor administration documentation](https://bitwarden.com/help/collection-management/).

#### Code Implementation

{% include pack-code.html vendor="bitwarden" section="1.2" %}

#### Validation & Testing

Compare the scoped CLI collection-metadata inventory against the expected collection IDs and inspect effective access with a non-admin test identity. Never count hidden passwords as prevention of credential use. Disabling blanket collection management is not a restriction on all administrator export capabilities; review export policy separately.

#### Operational Impact

Removing a grant may disrupt a dependent workflow. Record the specific prior grant and restore only that grant if needed.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AC-6 | Supports this objective; configuration alone does not establish compliance. |

### 1.3 Configure Enterprise SSO Before Requiring It

**Profile Level:** L2 (Walk)

#### Description

Set up and test an enterprise IdP before requiring centralized sign-in. Keep Bitwarden sign-in and vault decryption as distinct decisions.

#### Rationale

**Why This Matters:**

- Mismatched identity or decryption settings can cause lockouts even if IdP authentication succeeds.

#### Prerequisites

Enterprise and access to both the Bitwarden organization and IdP; working owner account outside the pilot.

#### ClickOps Implementation

Use **Admin Console → Settings → Single sign-on** to configure the documented SAML or OIDC provider values. Exercise sign-in and vault unlock for a pilot member before requiring SSO in **Settings → Policies**. Do not assume the owner or administrator paths are covered by the member-only policy.

**Sources:** [SSO capabilities and decryption options](https://bitwarden.com/help/about-sso/), [Bitwarden's SAML setup path](https://bitwarden.com/help/configure-sso-saml/).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Confirm pilot IdP MFA, correct identity association, vault access, failed access for an unassigned identity, and independent owner recovery.

#### Operational Impact

An IdP outage can interrupt sign-in; document the emergency administrator path and retain the last known-good IdP configuration.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | IA-8 | Supports this objective; configuration alone does not establish compliance. |

### 1.4 Review and Reconcile Organization Event Logs

**Profile Level:** L1 (Crawl)

#### Description

Use organization event logs to review policy changes, access lifecycle and shared vault activity. Protect raw event evidence because it can contain identity and network data.

#### Rationale

**Why This Matters:**

- Without a review trail, a policy regression or unexpected membership change may go unnoticed.

#### Prerequisites

Teams or Enterprise; authorized report reviewers; approved storage and retention policy.

#### ClickOps Implementation

Open **Admin Console → Reporting → Event logs**. Set the review window, select **Update**, and examine policy, member and administrative activity against authorized changes. If exporting, restrict access, record the time window and set retention.

**Source:** [Vendor administration documentation](https://bitwarden.com/help/event-logs/).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Generate an approved low-risk test event and observe it alongside its related change ticket. Allow for event delivery delay; client-generated events may be missing.

#### Operational Impact

Log export exposes administrative data. No rollback is needed for the review; delete any accidentally over-shared export under incident procedures.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AU-6 | Supports this objective; configuration alone does not establish compliance. |

## 2. Compliance Quick Reference

| Control | Profile | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 Require Two-Step Login or Enforced SSO | L1 | IA-2 |
| 1.2 Limit Shared Collection Permissions | L1 | AC-6 |
| 1.3 Configure Enterprise SSO Before Requiring It | L2 | IA-8 |
| 1.4 Review and Reconcile Organization Event Logs | L1 | AU-6 |

## References

- [Source and validation notes](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-dev-source-coverage.md)

## Contributing

Use the repository contribution guide. Include the tested edition, source and validation results with corrections.

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-11-27 | Initial documentation-derived guide and verification packs |
