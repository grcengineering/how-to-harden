---
layout: guide
title: "Cisco Meraki Hardening Guide"
vendor: "Cisco Meraki"
slug: "cisco-meraki"
tier: "1"
category: "IT Operations"
description: "Cisco Meraki Dashboard is the hosted network management plane."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Cisco Meraki Dashboard is the hosted network management plane. This guide covers its organization access and audit policy, not on-device forwarding, wireless settings, switch firmware or Cisco Umbrella administration.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Dashboard identity](#1-dashboard-identity)
2. [Administrative boundaries](#2-administrative-boundaries)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Dashboard identity

### 1.1 Require two-factor authentication for direct dashboard sign-in

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | IA-2, IA-5 |

#### Description

Require Dashboard two-factor authentication for direct login and apply identity provider MFA separately to SAML accounts. Audit administrator enrollment as well as the organization setting.

#### Rationale

**Why This Matters:**

- A stolen dashboard password can otherwise grant access across managed networks.

#### Prerequisites

Two verified full-privilege administrators and a documented recovery process. Retain access to backup keys under your emergency access policy.

#### ClickOps Implementation

1. Open **Organization > Configure > Settings > Security** and turn on **Two-factor authentication**.
2. Check administrators in **Organization > Configure > Administrators**. Resolve any unenrolled direct sign-in account through the approved enrollment workflow.
3. Check IdP enforcement independently; a Dashboard toggle does not prove SAML account MFA.

#### Code Implementation

{% include pack-code.html vendor="cisco-meraki" section="1.1" %}

#### Validation & Testing

Start a fresh direct test sign-in to verify the second factor. Use the pack to confirm the organization boolean; this does not prove authentication for every account.

#### Monitoring & Maintenance

Review enrollment and elevated roles after onboarding, offboarding or directory changes.

#### Operational Impact & Rollback

Failure to enroll can block administrators. Use the second verified full admin to resolve enrollment, not to disable MFA globally for routine issues.

**Sources:** [Cisco Meraki organization settings](https://documentation.meraki.com/Platform_Management/Dashboard_Administration/Design_and_Configure/Organizations_and_Networks/Organization_Settings). [Login Security API](https://developer.cisco.com/meraki/api-v1/get-organization-login-security/).

### 1.2 Separate SAML role mappings from direct emergency administrators

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6, IA-8 |

#### Description

Map users to task-specific SAML roles through approved IdP groups. Use network-level grants when organization-wide access is unnecessary.

#### Rationale

**Why This Matters:**

- Overbroad assertions enlarge the network and device blast radius of a compromised identity.

#### Prerequisites

A tested IdP application, planned role mapping, and two usable direct emergency administrator paths under the approved design.

#### ClickOps Implementation

1. In **Organization > Configure > Settings** enable and configure **SAML Configuration** using the signing certificate information from the intended IdP.
2. In **Organization > Configure > Administrators** create the intended SAML roles. Map exact role names from IdP groups and limit their organization, network or tag grants.
3. Keep a tested direct recovery path separate from normal SAML operators.

#### Code Implementation

{% include pack-code.html vendor="cisco-meraki" section="1.2" %}

#### Validation & Testing

Test each distinct role with separate authorized users. Compare the enabled flag to the dashboard and review IdP group membership and MFA separately.

#### Monitoring & Maintenance

Review role mappings, certificate expiry dates and emergency access each quarter.

#### Operational Impact & Rollback

Certificate or ACS misconfiguration can block federated sessions. Use the tested direct recovery path to restore the previous trusted configuration.

**Sources:** [Configuring SAML for Dashboard](https://documentation.meraki.com/Platform_Management/Dashboard_Administration/Operate_and_Maintain/Managing_Dashboard_Access/Configuring_SAML_Single_Sign-on_for_Dashboard). [SAML settings API](https://developer.cisco.com/meraki/api-v1/get-organization-saml/).

### 1.3 Restrict organization administrator privileges

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6 |

#### Description

Limit full organization access to named operators. Report API credential presence and review which users or jobs depend on those credentials.

#### Rationale

**Why This Matters:**

- An integration or network-only operator should not have permission to change authentication for every managed network.

#### Prerequisites

Organization administrator access; reconciled roster of direct, SAML and machine access.

#### ClickOps Implementation

1. Under **Organization > Configure > Administrators**, review each direct user’s organization, network and tag grants.
2. Apply read-only access for review roles and grant network-only tasks at network scope. Remove stale access only after confirming integration dependencies.
3. Review SAML role definitions separately; the direct administrator endpoint is not an IdP roster.

#### Code Implementation

{% include pack-code.html vendor="cisco-meraki" section="1.3" %}

#### Validation & Testing

Check a network-only pilot operator cannot modify organization settings, and compare the pack’s organization grants to the approved roster.

#### Monitoring & Maintenance

Review stale invitations, full access, direct accounts and machine credentials quarterly or after role changes.

#### Operational Impact & Rollback

Removing a machine identity can break automations. Establish ownership and verify a scoped replacement before changing permissions.

**Sources:** [Managing Dashboard administrators](https://documentation.meraki.com/Platform_Management/Dashboard_Administration/Operate_and_Maintain/Managing_Dashboard_Access/Managing_Dashboard_Administrators_and_Permissions). [Administrators API](https://developer.cisco.com/meraki/api-v1/get-organization-admins/).

## 2. Administrative boundaries

### 2.1 Restrict dashboard and API source networks after testing

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-17, SC-7 |

#### Description

Apply organization Login IP ranges only after validating administrator and automation egress addresses. Do not treat this setting as coverage for services outside this Dashboard organization.

#### Rationale

**Why This Matters:**

- A stolen administrative API key or password is less useful outside the approved paths where the restriction applies.

#### Prerequisites

Approved administrative egress, tested recovery site, inventory of roaming operators, service runners and SAML cases.

#### ClickOps Implementation

1. Review **Organization > Configure > Settings > Security > Login IP ranges**.
2. Capture the current allowed addresses securely. Set the intended addresses during a change window after separately testing operator VPN and integration egress.
3. Test Dashboard and Dashboard API independently from each authorized operational path.

#### Code Implementation

{% include pack-code.html vendor="cisco-meraki" section="2.1" %}

#### Validation & Testing

Verify `enforceLoginIpRanges` and compare the reported range count and review the actual approved addresses in the protected dashboard. Verify valid approved clients are still working.

#### Monitoring & Maintenance

Review changes to network and integration egress before rollout and audit quarterly.

#### Operational Impact & Rollback

Bad ranges can lock out operators and automation. Keep a tested administrative path on an allowed address to restore the previously approved ranges.

**Sources:** [Cisco Meraki organization settings](https://documentation.meraki.com/Platform_Management/Dashboard_Administration/Design_and_Configure/Organizations_and_Networks/Organization_Settings). [Login Security API](https://developer.cisco.com/meraki/api-v1/get-organization-login-security/).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Require two-factor authentication for direct dashboard sign-in | IA-2, IA-5 |
| 1.2 Separate SAML role mappings from direct emergency administrators | AC-2, AC-6, IA-8 |
| 1.3 Restrict organization administrator privileges | AC-2, AC-6 |
| 2.1 Restrict dashboard and API source networks after testing | AC-17, SC-7 |

## Appendix A: Automation and applicability

The Cisco REST API and official Python SDK can read these administrator settings. The API also documents mutation endpoints; this starter pack does not apply tenant changes or output network allowlist values. Cisco Network as Code documents a configuration model, but Terraform resource/data-source coverage, standalone admin CLI, GraphQL, and SIEM fidelity for this exact set were not verified. Meraki cloud management is separate from Cisco Duo, Cisco Umbrella and device hardening. No Dashboard-specific CIS, STIG or SCuBA requirement was verified.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.
