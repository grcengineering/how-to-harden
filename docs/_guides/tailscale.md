---
layout: guide
title: "Tailscale Hardening Guide"
vendor: "Tailscale"
slug: "tailscale"
tier: "2"
category: "Security"
description: "Harden Tailscale tailnet identity, grants, enrollment, workload credentials, SSH, posture, routes, sharing, Funnel and audit evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-04"
---

## Overview

Tailscale connects identities, devices and routed services through a managed tailnet. A compromised employee device, CI worker or third-party integration can use every path its identity is permitted to reach. This guide reduces that authority through the tailnet’s administrative and integration controls. Tailscale is a standalone platform; its [terms](https://tailscale.com/terms) identify Tailscale Inc. and Tailscale US Inc. as the contracting entities for the specified account populations.

**Validation status:** no tenants declared — Tier 0+1 only. Public interfaces and documentation were checked on 2026-11-04; offline tests exercise our handling of those contracts. No live tailnet, IdP, node, policy engine, SIEM or credentialed API was exercised. The guide remains exactly `ai-drafted`; see the [maturity matrix](https://github.com/grcengineering/how-to-harden/blob/main/VERSIONS.md#maturity-statuses--the-matrix).

### Intended Audience

- Network and identity administrators managing workforce and workload access
- Security engineers governing CI, SaaS and external-service integrations
- Endpoint administrators managing enrolled devices and posture
- GRC teams collecting access and configuration evidence

### How to Use This Guide

- **L1 (Crawl):** Govern identity, enrollment, narrow service access and configuration evidence.
- **L2 (Walk):** Add posture and privileged-access checks, route/external-access governance and log delivery.
- **L3 (Run):** Evaluate Tailnet Lock with independent signing and recovery operations.

### Scope

Eighteen controls cover the core Tailscale tailnet control plane and its client/integration boundaries. Tailscale PAM and Aperture have separate administration surfaces and are not covered by this guide. Generic operating-system, router, cloud-network and Kubernetes hardening, secret rotation, and downstream application authorization are outside scope. Tailnet policy does not protect a service exposed directly on its LAN or public interface.

**Deploy complete policies deliberately.** Grants and ACLs are additive; restrictive new rules cannot cancel broad existing allows. The generator creates a minimal complete candidate, while JSONC examples are fragments. Adapt them into the existing policy, preserve required unrelated fields, remove conflicting permits, run server tests and stage actual application checks. Never overwrite a production policy with an isolated fragment. The Terraform `tailscale_acl` resource owns the whole policy, including fields unrelated to network ACLs.

**Safe pack defaults:** REST/CLI/SDK collectors are read-only. The validation endpoint uses POST but does not apply the candidate. Terraform manages no resources by default, with inventory also opt-in. Native fragments have no runtime gate; their profile is a review label. No pack creates credentials, signs nodes, starts a public Funnel, or applies changes automatically. Read the [pack README](https://github.com/grcengineering/how-to-harden/blob/main/packs/tailscale/README.md) before use. Keep all evidence and Terraform state outside source control.

## Table of Contents

1. [Identity and Device Lifecycle](#1-identity-and-device-lifecycle)
2. [Policy and Privileged Access](#2-policy-and-privileged-access)
3. [Automation and Routed Integrations](#3-automation-and-routed-integrations)
4. [External Exposure and Client Governance](#4-external-exposure-and-client-governance)
5. [Monitoring and Evidence](#5-monitoring-and-evidence)
6. [Integration Risk Reference](#6-integration-risk-reference)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Identity and Device Lifecycle

### 1.1 Require Phishing-Resistant MFA at the IdP

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Access Control Management (family mapping) |
| NIST 800-53 Rev. 5 | IA-2, IA-8 |
| SOC 2 | CC6.1 |

#### Description

Require phishing-resistant MFA and appropriate sign-in conditions in the identity provider used for Tailscale. Tailscale delegates authentication to that provider; there is no separate tailnet MFA toggle to substitute for the IdP policy.

#### Rationale

**Why This Matters:**

- A stolen password must not be enough to enroll a device or administer the tailnet.
- A persistent authenticated node is a separate access path; a later IdP policy change does not immediately revoke existing node keys.

**Attack Prevented:** Account takeover through weak upstream authentication and unmanaged sign-in paths.

#### Prerequisites

An IdP administrator, the tailnet Owner, a pilot account, and an independently tested recovery sign-in path.

#### ClickOps Implementation

1. Identify the sign-in provider used by the tailnet before changing any authentication policy. Follow the corresponding [IdP integration instructions](https://tailscale.com/docs/integrations/identity/entra) and the provider’s current MFA guidance.
2. In the IdP, scope the Tailscale application to approved users and require a hardware-backed or equivalent phishing-resistant factor. For Entra, review application assignment as well as Conditional Access.
3. Pilot fresh user and administrator sign-ins, then review already enrolled devices under controls 1.2–1.4. Test recovery before enforcement.

Sources: [Security best practices](https://tailscale.com/docs/reference/best-practices/security), [Entra provisioning and application assignment](https://tailscale.com/docs/integrations/identity/entra/entra-id-scim); verified 2026-11-04.

**Automation:** ClickOps/IdP administration for MFA — the Tailscale API and provider do not expose an upstream MFA enforcement setting. Configure the actual IdP rather than inventing a Tailscale MFA endpoint. ([API reference](https://tailscale.com/docs/reference/tailscale-api), verified 2026-11-04.)

#### Validation & Testing

1. Perform a fresh authorized pilot sign-in and confirm the required factor and application-assignment decision.
2. Check an existing node separately; do not treat an IdP challenge as proof that old node access was revoked.

**Expected result:** New authentication follows the approved IdP policy; existing access has its own lifecycle review.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

An incorrect IdP condition can block new sign-ins and reauthentication. Keep recovery access working and restore the prior IdP assignment/policy if the pilot fails.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Access Control Management; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | IA-2, IA-8 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC6.1 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

### 1.2 Govern Membership, Roles and Offboarding

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Account Management (family mapping) |
| NIST 800-53 Rev. 5 | AC-2, AC-6 |
| SOC 2 | CC6.2 |

#### Description

Reconcile users, console roles and access groups with approved membership. Use SCIM where available and test the provider-specific offboarding event. Admin-console roles govern administration; grants govern network access.

#### Rationale

**Why This Matters:**

- An admin role and a policy group grant different powers and require separate review.
- OAuth clients remain usable after their creator leaves; offboarding must include automation credentials.

**Attack Prevented:** Residual employee access, excessive administration and orphaned integration access.

#### Prerequisites

Owner/Admin or an authorized IT administrator. Advanced roles and SCIM require Standard, Premium or Enterprise according to the current feature documentation.

#### ClickOps Implementation

1. Open **Users** in the admin console and review each person’s role and status. Keep one accountable Owner; use Member for ordinary users and narrower advanced roles where entitled.
2. Open **User management** and review the selected provisioning model. User approval and SCIM provisioning cannot both be enabled. The general provisioning overview currently recommends user approval with separate SSO/SCIM apps, while the specific user-approval reference says they are mutually exclusive; do not attempt that combination. Use scoped IdP application assignments and test provisioning instead.
3. For SCIM, verify the event that actually suspends the Tailscale user. Okta deactivation is different from suspension; Entra disable/delete and Google suspension have their own documented behavior. Review **Users** after the event.
4. On departure, review user-owned devices, group membership, keys, and **Trust credentials**. Do not assume removing the IdP session removes every credential or tagged workload.

Sources: [User roles](https://tailscale.com/docs/reference/user-roles), [User approval](https://tailscale.com/docs/features/access-control/user-approval), [Provisioning behavior](https://tailscale.com/docs/features/user-group-provisioning), [OAuth lifecycle](https://tailscale.com/docs/features/oauth-clients); verified 2026-11-04.

#### Code Implementation

The REST and Terraform read packs collect current users. Compare them with approved membership and actual IdP state; they do not change roles or establish that provisioning works.

{% include pack-code.html vendor="tailscale" section="1.2" %}

#### Validation & Testing

1. Compare all returned user IDs, roles and statuses with the approved roster.
2. Use a separately authorized test user to prove offboarding and check loss of resource access. Check OAuth/federated credentials independently.

**Expected result:** Console privileges and live membership match approvals, with observed offboarding behavior.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

Suspension interrupts access. Synced users can be recreated by the next IdP push if the upstream assignment remains. Restore the correct upstream state through the approved workflow.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Account Management; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-2, AC-6 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC6.2 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

### 1.3 Review New Device Enrollment

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Access Control Management (family mapping) |
| NIST 800-53 Rev. 5 | IA-3, AC-3 |
| SOC 2 | CC6.1 |

#### Description

Use device approval to review new devices before they exchange tailnet traffic, unless a reviewed Tailnet Lock design is used instead. Reconcile exceptions for pre-approved auth keys and devices already admitted.

#### Rationale

**Why This Matters:**

- Valid user authentication does not establish that a device is managed or trustworthy.
- A pre-approved auth key can bypass the manual review step, so key governance belongs in the enrollment boundary.

**Attack Prevented:** Unauthorized device enrollment using stolen identity or workload credentials.

#### Prerequisites

Owner, Admin or IT admin; a known enrollment inventory and a tested recovery path. Confirm Tailnet Lock is disabled before choosing device approval.

#### ClickOps Implementation

1. Open **Device management** and enable **Device approval** after reviewing the enrollment model. Device approval and Tailnet Lock are mutually exclusive; do not enable both.
2. Open **Machines**, find a device with **Needs approval**, verify its identity against the trusted device register, then use its ellipsis menu → **Approve** only when authorized.
3. Review **Keys → Auth keys** for **Pre-approved** exceptions. Review existing approved devices separately; enabling the feature is not a retroactive integrity assessment.

Sources: [Device approval](https://tailscale.com/docs/features/access-control/device-management/device-approval), [Tailnet Lock limitations](https://tailscale.com/docs/features/tailnet-lock); verified 2026-11-04.

#### Code Implementation

The API pack records enrollment defaults. Terraform has one optional owner for tailnet settings, including reviewed expiry, update and external-membership defaults used later in this guide. Import existing settings and inspect the plan. The module refuses to enable device approval without an explicit Tailnet Lock check acknowledgment.

{% include pack-code.html vendor="tailscale" section="1.3" %}

#### Validation & Testing

1. In an authorized test, confirm a non-preapproved new device cannot exchange tailnet traffic before approval.
2. Check the intended preapproval exception and verify an unrecognized device is not accidentally admitted.

**Expected result:** The chosen enrollment workflow admits only independently verified devices.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

New-device access waits for an administrator or approved automation. Device approval applies to a physical device rather than independently checking each user/node on a shared device; posture and endpoint policy remain necessary.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Access Control Management; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | IA-3, AC-3 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC6.1 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

### 1.4 Review Node Key Expiry and Exceptions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Account Management (family mapping) |
| NIST 800-53 Rev. 5 | IA-5, IA-3 |
| SOC 2 | CC6.2 |

#### Description

Set a reviewed node-key authentication period and inventory per-device exceptions. Node-key expiry, enrollment auth-key expiry and API-token lifetime are different controls. Avoid disabling expiry for ordinary employee devices.

#### Rationale

**Why This Matters:**

- A long-lived node can retain access after the user’s original sign-in context changes.
- Tagged devices initially authenticate with key expiry disabled by default, making workload exceptions easy to overlook.

**Attack Prevented:** Persistent network access through forgotten devices and unmanaged authentication lifetimes.

#### Prerequisites

Device-management authority, a workload exception register, and independent access to remotely managed hosts before changing expiry.

#### ClickOps Implementation

1. Open **Device management → Key Expiry**, choose an organization-approved period from **1 to 180 days**, and save. This change affects devices when they next log in; currently logged-in devices retain their existing expiration until then.
2. Open **Machines**, inspect each device’s key-expiry setting and its tags. Enable expiry for reviewed user devices; document justified service-device exceptions and their compensating controls.
3. Check again after tagged reauthentication: Tailscale disables key expiry on initial tagged authentication and again after reauthentication. Do not force remote reauthentication over the only SSH/RDP path.

Sources: [Key expiry](https://tailscale.com/docs/features/access-control/key-expiry), [Tag/key behavior](https://tailscale.com/docs/features/tags); verified 2026-11-04.

#### Code Implementation

REST, Terraform data sources and the maintained official Go SDK inventory device state. The optional Terraform resource enables expiry only for explicitly supplied node IDs; it does not expire keys immediately. The tailnet-wide period is managed by the single settings resource in 1.3.

{% include pack-code.html vendor="tailscale" section="1.4" %}

#### Validation & Testing

1. Compare disabled-expiry flags, current expiration timestamps, tags and owners with approved exceptions.
2. Use a pilot device to verify reauthentication and recovery, then recheck its actual expiration.

**Expected result:** Every nonexpiring device is justified and the selected node-key lifecycle is observed.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

Expiry can interrupt unattended services or lock out remote management. Stage the change, preserve independent recovery access, and restore only the reviewed exception when necessary.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Account Management; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | IA-5, IA-3 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC6.2 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

### 1.5 Evaluate Tailnet Lock with a Recovery Plan

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Access Control Management (family mapping) |
| NIST 800-53 Rev. 5 | SC-12, SC-23 |
| SOC 2 | CC6.1 |

#### Description

For high-assurance environments, evaluate Tailnet Lock so trusted signing nodes authorize node keys. Deploy it as a separately reviewed enrollment model with recovery material and signing-node lifecycle controls.

#### Rationale

**Why This Matters:**

- Node-key signatures add a boundary against unauthorized public keys distributed through the coordination plane.
- Compromised signers and lost disablement secrets can undermine security or recovery.

**Attack Prevented:** Unauthorized node-key introduction through the coordination plane.

#### Prerequisites

At least two suitable signing nodes, supported clients, securely stored disablement secrets, independent recovery access, and a change plan replacing device approval.

#### ClickOps Implementation

1. Review the complete **Tailnet Lock** documentation and limitations. Open **Device management → Enable Tailnet Lock** only as part of an authorized rollout; choose at least two signing nodes.
2. Store disablement secrets in approved independent storage when displayed. Confirm signing-node custody, backup and recovery before completing rollout.
3. Review trusted keys on each pilot node, compare them through an independent channel, and document the process for signing additional nodes and handling compromised signers.

Sources: [Tailnet Lock](https://tailscale.com/docs/features/tailnet-lock); verified 2026-11-04.

#### Code Implementation

The CLI pack collects local lock status only. It never initializes Lock, signs a node, revokes a signing key or changes device approval. There is no Terraform Tailnet Lock resource in the fetched provider index.

{% include pack-code.html vendor="tailscale" section="1.5" %}

#### Validation & Testing

1. Compare the trusted signer list and node status with the approved inventory.
2. Plan and separately authorize enrollment/recovery exercises; offline status collection alone cannot prove them.

**Expected result:** Signing authority, node acceptance and recovery have independent evidence before rollout.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

Tailnet Lock cannot coexist with device approval. Loss of disablement material may make the tailnet unrecoverable; a compromised signing node exposes its signing key. Do not trial this on a production tailnet without a recovery design.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Access Control Management; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | SC-12, SC-23 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC6.1 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

---

## 2. Policy and Privileged Access

### 2.1 Replace Broad Allows with Least-Privilege Grants

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Access Control Management (family mapping) |
| NIST 800-53 Rev. 5 | AC-3, AC-4 |
| SOC 2 | CC6.1 |

#### Description

Model required identity-to-service paths with grants specifying approved destinations, protocols and ports. Review and remove obsolete broad allows across the entire policy; grants and legacy ACLs allow traffic additively.

#### Rationale

**Why This Matters:**

- A restrictive grant does not negate another grant or legacy ACL that already permits the connection.
- New tailnets can begin with allow-all policy; deny-by-default semantics do not make that initial policy restrictive.

**Attack Prevented:** Lateral movement from compromised users, endpoints and integration workloads.

#### Prerequisites

A complete application dependency inventory, network-policy administration, a saved original policy and ETag, and tested recovery access.

#### ClickOps Implementation

1. Open **Access controls → JSON editor** and save a private copy of the complete policy. Review both **grants** and **acls**, plus tags, SSH, routes, attributes and tests.
2. Replace required paths with narrow grants. Remove the overlapping default allow-all rule and other unintended broad allows through a reviewed complete-policy change. Do not simply paste a restrictive fragment beside existing permissions.
3. Keep explicit empty legacy **acls** when using this pack’s grants-only candidate. Omitting the legacy section in a policy with no effective access rules can invoke the default allow-all behavior; never use an empty object as a deny-all recipe.
4. Adapt and validate the complete policy in 2.2 before saving. Preserve necessary unrelated policy sections and stage application tests.

Sources: [Grants versus ACLs](https://tailscale.com/docs/reference/grants-vs-acls), [Grants syntax](https://tailscale.com/docs/reference/syntax/grants), [ACL defaults](https://tailscale.com/docs/features/access-control/acls); verified 2026-11-04.

#### Code Implementation

The API pack preserves raw HuJSON and ETag. The local generator emits a complete minimal candidate using explicit approved admin/staff identities and allow/deny tests. It is neither a merge tool nor a drop-in production policy. Terraform’s optional tailscale_acl resource owns the whole policy and requires import; destruction cannot reset it to a permissive default through this module.

{% include pack-code.html vendor="tailscale" section="2.1" %}

#### Validation & Testing

1. Validate permitted application paths and denied adjacent services, reverse directions, employee-to-admin ports and CI-to-production paths.
2. Confirm there is no remaining broad allow that satisfies the negative cases. Test local-network exposure separately: tailnet policy does not govern ordinary LAN traffic.

**Expected result:** Only reviewed identity-to-service paths are reachable through Tailscale.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

A replacement policy can disrupt every service at once. Pilot a complete tested candidate and retain the prior version. Review concurrent changes; a future direct API write should use the saved ETag with If-Match rather than silently overwriting someone else’s update.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Access Control Management; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-3, AC-4 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC6.1 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

### 2.2 Test Policy Changes Before Deployment

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Secure Configuration of Enterprise Assets and Software (family mapping) |
| NIST 800-53 Rev. 5 | CM-3, CM-5 |
| SOC 2 | CC8.1 |

#### Description

Keep positive and negative network tests, and SSH tests where applicable, in the complete tailnet policy. Validate a candidate against Tailscale without applying it, then deploy through a reviewed change process.

#### Rationale

**Why This Matters:**

- Syntax validity does not prove that a sensitive path stays denied.
- Tests are evaluated on policy changes and catch accidental exposure or lost required access.

**Attack Prevented:** Unauthorized policy broadening and unnoticed access regressions.

#### Prerequisites

The complete candidate, real reviewed identities/tags, test cases, and policy_file:read with its documented dependent read scopes.

#### ClickOps Implementation

1. Open **Access controls → JSON editor** and review **tests**. Include intended allows and critical denials for actual identities, destinations and ports; use **proto** explicitly when protocol matters.
2. For posture-conditioned grants, supply the documented **srcPostureAttrs** in positive and negative tests. Add **sshTests** for allowed, check-mode and prohibited OS accounts when using Tailscale SSH.
3. Run the validation pack or the editor’s validation workflow before saving. Use repository branch protection and required review for GitOps; do not enable external-policy management until the independent deployment/recovery workflow works.

Sources: [Policy tests and SSH tests](https://tailscale.com/docs/reference/syntax/policy-file), [Read-only validation scope](https://tailscale.com/docs/reference/trust-credentials); verified 2026-11-04.

#### Code Implementation

The pack posts only to /acl/validate. It accepts the documented empty HTTP 200 success and rejects nonempty error content even when the HTTP status is 200. No /acl apply request exists in the transport. A successful validation is a candidate result, not observed enforcement.

{% include pack-code.html vendor="tailscale" section="2.2" %}

#### Validation & Testing

1. In a disposable local candidate, broaden a sensitive grant and confirm a negative test fails server validation.
2. Restore the candidate and rerun; independently verify intended behavior after a separately authorized deployment.

**Expected result:** Candidate tests pass and critical broadening is rejected before deployment.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

Synthetic attributes in policy tests model conditions; they do not prove a real device reports those attributes. Preserve tests during edits and treat a plan or validation result separately from live connectivity proof.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Secure Configuration of Enterprise Assets and Software; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | CM-3, CM-5 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC8.1 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

### 2.3 Constrain Tag Ownership and Workload Identity

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Access Control Management (family mapping) |
| NIST 800-53 Rev. 5 | AC-6, AC-3 |
| SOC 2 | CC6.1 |

#### Description

Use purpose-specific tags for non-user workloads and tightly restrict who can assign them. Keep employee endpoints user-authenticated, and assess the combined permissions of every tag applied to a workload.

#### Rationale

**Why This Matters:**

- Tag authentication replaces user identity; user-based rules no longer describe the tagged node’s access.
- Multiple tags combine access. A low-trust workload given a production tag can inherit production permissions.

**Attack Prevented:** Privilege escalation through tag assignment and overly broad workload identity.

#### Prerequisites

An approved tag taxonomy, controlled administrators and an inventory of node tags and trust-credential tag permissions.

#### ClickOps Implementation

1. Open **Access controls → JSON editor → tagOwners** and restrict production and CI tags to reviewed owners. Avoid granting routine members ownership of privileged tags.
2. Review nested ownership and automation credentials that can assign tags. Owners, Admins and Network admins have broad tag-use authority even when not listed as tag owners.
3. Open **Machines**, inspect assigned tags and compare their union of grants with the intended workload purpose. Remove inappropriate user-device tagging through the approved reauthentication workflow.

Sources: [Tags, identity and ownership](https://tailscale.com/docs/features/tags), [Administrative role permissions](https://tailscale.com/docs/reference/user-roles); verified 2026-11-04.

#### Code Implementation

The native fragment constrains the three candidate-policy tags to group:admins. Merge into the full tag map without discarding legitimate tags, and remove alternate ownership paths. Use the device inventory in 1.4 to reconcile actual tags; use 3.1 for credential tag authority.

{% include pack-code.html vendor="tailscale" section="2.3" %}

#### Validation & Testing

1. Check that an ordinary approved user cannot assign a privileged tag in a separately authorized pilot.
2. Evaluate access for each tag combination actually deployed, including unintended additional tags.

**Expected result:** Only approved administrators or scoped automation can assign workload identities.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

Changing a tag changes authorization identity and can interrupt access. Do not tag employee laptops to avoid expiry; retain a reviewed device and workload lifecycle.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Access Control Management; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-6, AC-3 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC6.1 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

### 2.4 Restrict Tailscale SSH and Require Reauthentication

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Access Control Management (family mapping) |
| NIST 800-53 Rev. 5 | AC-17, IA-2 |
| SOC 2 | CC6.1 |

#### Description

Authorize both TCP 22 reachability and Tailscale SSH policy, require check mode for human administration, and allow only reviewed OS accounts. Avoid broad nonroot access to tagged production devices.

#### Rationale

**Why This Matters:**

- Network reachability and SSH authorization are separate gates.
- autogroup:nonroot on a tagged destination permits any existing nonroot account; a named administration account is narrower.

**Attack Prevented:** Unauthorized shell access and use of excessive local privileges.

#### Prerequisites

Supported SSH server platform, an existing approved OS account, IdP reauthentication, and independent management access before changing the server mode.

#### ClickOps Implementation

1. Open **Access controls → JSON editor**. Restrict network grants for port 22 to the administrator group and approved tagged hosts.
2. Replace broad **ssh** permissions with **action: check**, reviewed source/destination identities, a named existing OS account, and a justified check period. Check mode applies to human identities; tagged-to-tagged automation cannot use check mode.
3. Review **sshTests**, verify the destination is intentionally running Tailscale SSH, and test an allowed and denied identity. Enabling the SSH server is a separate host action that can interrupt an existing SSH session.

Sources: [Tailscale SSH](https://tailscale.com/docs/features/tailscale-ssh), [SSH tests](https://tailscale.com/docs/reference/syntax/policy-file); verified 2026-11-04.

#### Code Implementation

The fragment uses a one-hour check period and the illustrative existing account ops, plus root/staff denials. Adapt that account and merge the complete policy before validation. It does not enable SSH on any host or govern ordinary OpenSSH on non-Tailscale interfaces.

{% include pack-code.html vendor="tailscale" section="2.4" %}

#### Validation & Testing

1. Confirm an administrator reaches only the approved OS account and reauthenticates at the intended interval.
2. Confirm staff and root access fail; verify conventional SSH and local-network entry paths independently.

**Expected result:** Human Tailscale SSH administration is narrow and periodically reauthenticated.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

SSH changes may interrupt management. Keep an independently tested recovery path, and revert the reviewed policy/server configuration if the pilot fails.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Access Control Management; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-17, IA-2 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC6.1 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

### 2.5 Require Posture on Sensitive Access Rules

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Continuous Vulnerability Management (family mapping) |
| NIST 800-53 Rev. 5 | AC-3, CA-7 |
| SOC 2 | CC6.1 |

#### Description

Attach device posture requirements to sensitive human access grants and verify the actual attributes reported by pilot devices. Use the current object-based posture syntax with assertions; a defined posture alone enforces nothing.

#### Rationale

**Why This Matters:**

- A separate unconditioned allow can bypass the intended posture gate.
- Source posture is evaluated for nodes in the same tailnet; external sharing and devices behind subnet routers have important gaps.

**Attack Prevented:** Sensitive-resource access from endpoints that fail the approved device conditions.

#### Prerequisites

Known supported clients and attribute availability. Built-in attributes are available on all plans; MDM/EDR and geolocation need Standard/Premium/Enterprise, and custom attributes need Premium/Enterprise.

#### ClickOps Implementation

1. Open **Access controls → JSON editor** and define **postures** with **assertions**. Use built-in signals or a separately configured, tested MDM/EDR integration.
2. Replace the matching unconditioned grant with a posture-conditioned grant using **srcPosture**. Multiple named postures are alternatives, while assertions inside one posture must all hold. An explicit source posture replaces the default posture for that rule.
3. Open **Machines → selected machine → Device Postures** to inspect real status. Test missing attributes and a failing client. Do not assert that a stable/auto-updating client is managed, encrypted or uncompromised.

Sources: [Posture syntax and attributes](https://tailscale.com/docs/features/device-posture/postures-and-attributes), [Postures in rules](https://tailscale.com/docs/features/device-posture/postures-in-access-rules), [Plan availability](https://tailscale.com/docs/features/device-posture), [Monitoring posture](https://tailscale.com/docs/features/device-posture/monitoring-postures); verified 2026-11-04.

#### Code Implementation

The example requires the stable release track and enabled auto-update for one human HTTPS grant. Replace the original grant rather than adding a parallel permission; preserve unrelated grants and tests. Workload, shared-node and subnet-origin traffic need their own access design.

{% include pack-code.html vendor="tailscale" section="2.5" %}

#### Validation & Testing

1. Validate modeled positive, false-attribute and missing-attribute cases, then observe the same conditions on pilot devices.
2. Explicitly test external/shared and subnet-origin paths rather than assuming posture blocks them.

**Expected result:** Sensitive in-tailnet human access depends on the intended reported posture.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

Missing attributes fail posture matches for applicable nodes. Posture rules do not restrict external users’ devices accessing shared nodes; default posture also does not gate subnet-origin traffic. Do not extend the result beyond its actual scope.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Continuous Vulnerability Management; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-3, CA-7 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC6.1 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

---

## 3. Automation and Routed Integrations

### 3.1 Scope Automation Trust Credentials

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Access Control Management (family mapping) |
| NIST 800-53 Rev. 5 | IA-5, AC-6 |
| SOC 2 | CC6.1 |

#### Description

Give each automation a distinct trust credential with narrowly scoped API authority and, where relevant, restricted tags or federation claims. Prefer supported workload identity federation over distributing a reusable secret where the integration supports it.

#### Rationale

**Why This Matters:**

- A broad integration token can change policy or enroll privileged nodes even if its intended job only reads inventory.
- Trust credentials are associated with the tailnet and survive the departure of their creator.

**Attack Prevented:** Supply-chain compromise escalating through overprivileged OAuth or federated automation.

#### Prerequisites

An approved automation inventory, credential administrator, reviewed tag ownership, and an out-of-band credential injection mechanism.

#### ClickOps Implementation

1. Open **Trust credentials** and review each credential’s purpose, allowed operations, Read/Write selections, tags and owner/runbook.
2. For federated identities, restrict issuer, audience, subject and any claim rules to the actual workflow. For OAuth, keep client secrets outside repositories and inject access tokens at runtime. Separate read-only collection from approved deployment.
3. Remove unused credentials through a separately authorized lifecycle process. Reconcile the complete console inventory; knowing some credential IDs is not evidence that no other credentials exist.

Sources: [Trust credentials and scopes](https://tailscale.com/docs/reference/trust-credentials), [OAuth lifecycle](https://tailscale.com/docs/features/oauth-clients), [Terraform identity federation](https://tailscale.com/docs/integrations/terraform-provider); verified 2026-11-04.

#### Code Implementation

The read pack reviews explicitly supplied OAuth/federated credential IDs, projects metadata without key material, and names its coverage limit. Use only the required read scopes. No pack creates a credential, exchanges a client secret, or adds a broad all-scope principal.

{% include pack-code.html vendor="tailscale" section="3.1" %}

#### Validation & Testing

1. Compare returned scopes/tags and federation claims with the approved operation and workflow identity.
2. In a separately authorized integration test, confirm the identity cannot invoke an unnecessary write operation.

**Expected result:** Every integration has documented, limited authority and an independent lifecycle.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

Removing a credential can interrupt automation even after its original creator has left. Inventory dependencies first and use a staged replacement process; secret rotation is outside this guide’s scope.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Access Control Management; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | IA-5, AC-6 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC6.1 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

### 3.2 Limit CI and Third-Party Workload Enrollment

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Access Control Management (family mapping) |
| NIST 800-53 Rev. 5 | AC-6, AC-4 |
| SOC 2 | CC6.1 |

#### Description

Use narrowly tagged, short-lived enrollment for CI jobs and third-party workers, with only the service paths each job needs. Review auth-key reuse, ephemeral-node behavior, preapproval and tag capabilities as distinct choices.

#### Rationale

**Why This Matters:**

- Reusable enrollment keys can add multiple nodes after a runner or integration is compromised.
- Ephemeral enrollment limits lingering nodes but does not reduce the permissions of a connected compromised job.

**Attack Prevented:** Compromised CI runners enrolling persistent nodes or reaching production administration.

#### Prerequisites

An inventory of CI integrations, restricted workload tags, an approved credential source and a supported first-party enrollment integration.

#### ClickOps Implementation

1. Open **Keys → Auth keys** and review expiry, reuse, ephemeral and pre-approved settings for existing approved integrations. Choose one-time enrollment where practical and use a justified short expiration.
2. Open **Trust credentials** for integrations that create enrollment keys. Limit their device/tag authority to the intended workload; preapproval is an explicit exception to manual device approval.
3. Open **Access controls** and constrain the workload tag to required services/ports. Pin third-party workflow code and protect the repository’s workflow/credential boundary through the source-control platform’s own controls.

Sources: [Auth keys](https://tailscale.com/docs/features/access-control/auth-keys), [Device preapproval](https://tailscale.com/docs/features/access-control/device-management/device-approval), [Grants](https://tailscale.com/docs/reference/syntax/grants); verified 2026-11-04.

#### Code Implementation

The API pack follows the documented ID list with individual metadata reads for credential-visible auth keys. It reports that limit explicitly. The native policy fragment grants CI only build-service HTTPS and includes production denials; it does not create keys or join a runner.

{% include pack-code.html vendor="tailscale" section="3.2" %}

#### Validation & Testing

1. Reconcile capabilities and current tagged nodes with the integration inventory, including keys owned by other principals.
2. Confirm the job reaches its approved service and cannot reach production SSH/HTTPS. Observe node cleanup after an authorized ephemeral pilot rather than assuming immediate deletion.

**Expected result:** Integration compromise is bounded by reviewed enrollment and network permissions.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

An auth key’s expiration prevents future enrollment; it does not revoke already enrolled nodes. Ephemeral cleanup follows the product lifecycle, not an instantaneous logout guarantee. Reconcile existing nodes separately.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Access Control Management; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-6, AC-4 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC6.1 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

### 3.3 Review Subnet and Exit-Node Routes

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Network Infrastructure Management (family mapping) |
| NIST 800-53 Rev. 5 | SC-7, AC-4 |
| SOC 2 | CC6.6 |

#### Description

Approve only intended subnet routes and exit nodes, constrain autoApprovers, and grant only required routed destinations. Advertisement, approval and permission to use a route are distinct gates.

#### Rationale

**Why This Matters:**

- A compromised connector can advertise routes that expose resources without a client installed.
- Default routes grant an exit-node capability and require separate internet-traffic and privacy review.

**Attack Prevented:** Network pivoting through an unreviewed subnet router or exit node.

#### Prerequisites

Network administrator, approved routing inventory, downstream service owners and independent recovery access before route changes.

#### ClickOps Implementation

1. Open **Machines**, select each router’s ellipsis menu → **Edit route settings**, and compare advertised/enabled routes and exit-node approval with the approved topology.
2. Open **Access controls → JSON editor → autoApprovers**. Review every CIDR and exit-node approver, plus who can assign the referenced tags. Do not add a broad autoapproval merely to avoid manual review.
3. Review routed-destination grants and exit-node access separately. Check subnet resources’ application authentication and local-network controls; approving a route does not secure the service.

Sources: [Subnet routers](https://tailscale.com/docs/features/subnet-routers), [Exit nodes](https://tailscale.com/docs/features/exit-nodes), [Auto approvers](https://tailscale.com/docs/reference/syntax/policy-file); verified 2026-11-04.

#### Code Implementation

The API pack reads each device’s advertised/enabled routes and fails the whole export if any read fails. Terraform manages an explicit complete route set per reviewed node, defaults to no changes, and deliberately refuses /0 exit routes. Its resource cannot advertise routes; do not interpret enabled routes as a packet-path test.

{% include pack-code.html vendor="tailscale" section="3.3" %}

#### Validation & Testing

1. Compare all advertised and enabled CIDRs, including IPv4/IPv6 defaults, with the inventory.
2. Prove approved clients can reach required routed services and denied clients cannot. Validate exit-node egress and LAN-access behavior separately.

**Expected result:** Only approved routes and egress paths are usable by authorized identities.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

Managing a complete route set can remove other enabled routes; enumerate them first. Do not remove the operator’s only recovery route. Restore the previous complete set through the approved management path if a pilot fails.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Network Infrastructure Management; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | SC-7, AC-4 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC6.6 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

---

## 4. External Exposure and Client Governance

### 4.1 Govern External Sharing and Tailnet Membership

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Access Control Management (family mapping) |
| NIST 800-53 Rev. 5 | AC-20, AC-4 |
| SOC 2 | CC6.6 |

#### Description

Review outbound machine shares and reusable invitations, inbound shared nodes, and whether users may join external tailnets. Treat these as separate controls rather than a single sharing switch.

#### Rationale

**Why This Matters:**

- A share link grants a path to a machine outside the organization’s device boundary.
- The recipient’s device posture is not enforced by posture rules on the shared node.

**Attack Prevented:** Unreviewed external resource access and bypass of assumed endpoint conditions.

#### Prerequisites

An Owner/Admin/IT admin for sharing review, a network-policy administrator and an external-collaboration register.

#### ClickOps Implementation

1. Open **Machines → machine → Share**. Review accepted recipients and outstanding links. Prefer approved named, time-bounded collaboration; treat invite links as secrets.
2. For an unauthorized share or invite, use **Share → ellipsis → Revoke invite** through the approved access-removal process. Review reusable links as well as accepted recipients.
3. Open **User management → Join external tailnets** and select only the approved roles, or **Deny** when external membership is unnecessary. Review the full access policy separately. This setting does not revoke outbound shares. Invite an external user into the tailnet when you need in-tailnet device posture, then apply normal lifecycle controls.

Sources: [Sharing and revocation](https://tailscale.com/docs/features/sharing), [External-tailnet joining](https://tailscale.com/docs/features/sharing/how-to/invite-any-user), [Posture limitations](https://tailscale.com/docs/features/device-posture/postures-and-attributes), [Settings API schema](https://github.com/tailscale/tailscale-client-go-v2/blob/main/tailnet_settings.go); verified 2026-11-04.

#### Code Implementation

The read pack inventories inbound devices marked isExternal. It cannot list outbound recipients or prove sharing is disabled. Reconcile those in the console. External-tailnet joining is optionally managed by the single settings resource in 1.3.

{% include pack-code.html vendor="tailscale" section="4.1" %}

#### Validation & Testing

1. Compare outbound recipients, invites and inbound external nodes with the register.
2. After separately authorized removal, verify the former recipient loses the expected path. Test posture assumptions explicitly for any remaining shared access.

**Expected result:** Every external path has an approved owner, purpose and lifecycle.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

Revoking a share requires a new accepted invite to restore access. Joining restrictions and node sharing have different scopes. Preserve legitimate collaborator access through a reviewed replacement rather than assuming a settings flag covers every path.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Access Control Management; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AC-20, AC-4 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC6.6 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

### 4.2 Prevent Unapproved Public Funnel Exposure

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Secure Configuration of Enterprise Assets and Software (family mapping) |
| NIST 800-53 Rev. 5 | SC-7, CM-7 |
| SOC 2 | CC6.6 |

#### Description

Keep unapproved services off the public internet by controlling the funnel node attribute and reviewing active Funnel configuration on managed nodes. Use Serve for intended tailnet-only publication.

#### Rationale

**Why This Matters:**

- Funnel exposes the selected service to public internet users; tailnet membership is not required.
- The enablement workflow can add a broad member Funnel capability to the policy.

**Attack Prevented:** Public disclosure of internal applications, files or unauthenticated administrative interfaces.

#### Prerequisites

Policy administration, supported local CLI access to each managed service host and an approved publication inventory.

#### ClickOps Implementation

1. Open **Access controls → JSON editor → nodeAttrs** and remove unapproved **funnel** assignments from the reviewed complete policy. If Funnel is approved, scope it to explicitly reviewed publishers instead of all members.
2. Inspect active Funnel configuration on each managed host. Stop unapproved publishers through the host’s approved management procedure and confirm the public URL no longer serves them.
3. Use **Serve** where publication is intended only inside the tailnet. Do not run the Funnel enablement wizard as a verification step: it can provision HTTPS and modify policy.

Sources: [Funnel exposure and policy changes](https://tailscale.com/docs/features/tailscale-funnel), [Funnel status CLI](https://tailscale.com/docs/reference/tailscale-cli/funnel); verified 2026-11-04.

#### Code Implementation

The CLI pack calls only funnel status --json and records the response privately. It does not enable, reset or stop publication. Combine local configuration review with the complete nodeAttrs policy review; a single host snapshot is not a tailnet-wide scan.

{% include pack-code.html vendor="tailscale" section="4.2" %}

#### Validation & Testing

1. Inspect every intended publisher and compare its public service/path with the register.
2. From an authorized external test client, confirm an unapproved URL is unreachable and approved services still require their intended application authentication.

**Expected result:** Public exposure exists only for explicitly approved services and publishers.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

Stopping publication interrupts its external users. Existing background Funnel configuration may resume after reboot; review persistent configuration and policy. Tailnet encryption does not make a public application access-controlled.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Secure Configuration of Enterprise Assets and Software; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | SC-7, CM-7 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC6.6 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

### 4.3 Maintain Supported Clients and Security Contacts

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Continuous Vulnerability Management (family mapping) |
| NIST 800-53 Rev. 5 | SI-2, CM-8 |
| SOC 2 | CC7.1 |

#### Description

Maintain an approved supported client release across devices and ensure security notices reach a monitored team. Configure auto-updates where supported and verify existing devices individually.

#### Rationale

**Why This Matters:**

- Client security fixes and policy support depend on the installed release and platform.
- Enabling auto-update for new devices is not proof that every existing device has updated.

**Attack Prevented:** Exploitation of patched client weaknesses and silent drift to unsupported enforcement behavior.

#### Prerequisites

Endpoint-management owners, a tested rollout/recovery process and a monitored security email address.

#### ClickOps Implementation

1. Open **Device management → Auto-update Tailscale → Auto-update new devices** and enable the reviewed policy where supported. Review existing devices in **Machines** and their supported update mechanism.
2. Open **Contact preferences** and configure an approved monitored security-issue email contact. Subscribe to the vendor’s security bulletins and assign a remediation owner.
3. Compare actual installed versions and platform support with the approved release and relevant bulletins. Use staged rollout and independently verify security-critical features after upgrades.

Sources: [Client updates](https://tailscale.com/docs/features/client/update), [Security best practices](https://tailscale.com/docs/reference/best-practices/security), [Security bulletins](https://tailscale.com/security-bulletins); verified 2026-11-04.

#### Code Implementation

The CLI pack inventories the installed local version. The device API in 1.4 collects clientVersion/updateAvailable where returned; the settings resource in 1.3 can manage the reviewed default. No script installs or updates a client.

{% include pack-code.html vendor="tailscale" section="4.3" %}

#### Validation & Testing

1. Compare managed fleet coverage and actual versions with the release policy, including offline or unsupported devices.
2. Confirm notices reach the monitored owner and verify auto-update behavior on a pilot client.

**Expected result:** Supported clients and reachable notification owners cover the intended fleet.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

Platform variants and packaging affect auto-update support. Maintain an approved fallback deployment and verify application connectivity during staged rollout; do not assume a version inventory proves that patching occurred.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Continuous Vulnerability Management; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | SI-2, CM-8 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC7.1 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

---

## 5. Monitoring and Evidence

### 5.1 Retain and Review Configuration Audit Logs

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Audit Log Management (family mapping) |
| NIST 800-53 Rev. 5 | AU-2, AU-6, AU-9 |
| SOC 2 | CC7.2 |

#### Description

Review configuration audit events and export them to an access-controlled evidence store before vendor retention expires. Investigate policy, identity, key, tag, route and logging changes against approved change records.

#### Rationale

**Why This Matters:**

- Configuration events identify actors and affected resources, helping explain how access boundaries changed.
- A local export or successful request does not establish long-term retention, alerting or complete activity coverage.

**Attack Prevented:** Undetected unauthorized administration and loss of change evidence.

#### Prerequisites

Console log access or logs:configuration:read, a privacy-reviewed evidence store and approved collection windows.

#### ClickOps Implementation

1. Open **Configuration logs** and filter by time, action and actor. Compare access-policy and administrative changes with approvals.
2. Export overlapping bounded time windows through the API and retain them under the evidence policy. Built-in configuration history is enabled by default, retained for 90 days, and has no documented pagination.
3. For SIEM review, ingest individual JSON events from the logs array, map local index/sourcetype names, and test the supplied investigation query. Correlate eventGroupID for multi-event actions without treating it as a unique event ID.

Sources: [Configuration audit structure and limitations](https://tailscale.com/docs/features/logging/audit-logging), [Log scopes](https://tailscale.com/docs/reference/trust-credentials); verified 2026-11-04.

#### Code Implementation

The collector requires an explicit past UTC window within retention, limits each request to one day and refuses partial/oversized responses. The SPL uses documented action/actor/target fields and local ingestion names. It is a change-review query, not an automatic maliciousness verdict.

{% include pack-code.html vendor="tailscale" section="5.1" %}

#### Validation & Testing

1. In an approved test, locate a harmless known configuration change and trace it from console to retained evidence.
2. Account for delivery delay, overlapping windows and all events in a grouped operation; verify permissions and evidence-store retention.

**Expected result:** Administrative changes can be attributed and investigated using retained evidence.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

Configuration logs exclude read-only activity and some support-initiated changes; suspension/deletion side effects also have gaps. They do not contain network flow history. Protect exports, which may contain identities, policy diffs and sensitive historical content.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Audit Log Management; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AU-2, AU-6, AU-9 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC7.2 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

### 5.2 Export Flow Logs and Verify Delivery

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | Audit Log Management (family mapping) |
| NIST 800-53 Rev. 5 | AU-12, AU-6 |
| SOC 2 | CC7.2 |

#### Description

Enable entitled network flow logging and export required configuration/network streams to approved storage or SIEM destinations. Verify receipt and freshness at the destination; settings and status responses are supporting evidence only.

#### Rationale

**Why This Matters:**

- Flow metadata supports investigation of connections and routed/exit-node use without packet contents.
- A disabled logger, unsupported client or failed stream can leave an unnoticed monitoring gap.

**Attack Prevented:** Unobserved lateral movement, unauthorized egress paths and suppression of monitoring.

#### Prerequisites

Premium or Enterprise for flow logs/streaming, supported reporting clients, an authorized logging administrator and a privacy-approved destination with controlled retention.

#### ClickOps Implementation

1. Open **Network flow logs → Start logging** and confirm the dialog. Check supported client coverage and nodes using the documented no-logs mode; enabled logging alone does not guarantee every node reports.
2. Open **Configuration logs** or **Network flow logs → Start streaming**, choose the approved destination and supply its reviewed settings. Prefer role-based S3 authentication over embedded access keys when using S3.
3. Check fresh events at the actual destination and monitor failed delivery. Network history is retained for 30 days; make longer retention an explicit destination policy. Review destination logging separately before collecting more detailed exit traffic.

Sources: [Flow logs](https://tailscale.com/docs/features/logging/network-flow-logs), [Log streaming](https://tailscale.com/docs/features/logging/log-streaming), [Streaming status scope](https://tailscale.com/docs/reference/trust-credentials); verified 2026-11-04.

#### Code Implementation

The API pack collects both stream status responses without assuming a particular success schema. Terraform configures an explicitly supplied existing S3 role/bucket/external ID and creates no credentials or cloud infrastructure. Enable the reviewed flow-logging default through the settings resource in 1.3; stream configuration alone does not enable flow collection.

{% include pack-code.html vendor="tailscale" section="5.2" %}

#### Validation & Testing

1. Generate an authorized harmless test connection and trace its metadata to the approved destination.
2. Confirm freshness monitoring, destination permissions and retention, then test an approved delivery-failure scenario.

**Expected result:** The required streams arrive with verified freshness and controlled retention.

#### Monitoring & Maintenance

Review this control after identity, policy, integration or client changes and in the quarterly access review. Record the actual tenant/client scope, evidence date and exceptions. Repeat applicable negative tests after material changes.

#### Operational Impact

Flow and identity metadata are sensitive and may be incomplete or delayed; packet payloads are not recorded. Destination changes can interrupt evidence collection. Preserve the known-good configuration and verify receipt before retiring the old destination.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| CIS Controls v8 | By family name | Audit Log Management; no Tailscale-specific benchmark recommendation is asserted. |
| NIST 800-53 Rev. 5 | AU-12, AU-6 | Supports the specific access, lifecycle, configuration or evidence objective described in this control. |
| SOC 2 | CC7.2 | Supporting logical-access/change-monitoring evidence; implementation alone does not establish compliance. |

---

## 6. Integration Risk Reference

This reference table does not add leveled controls.

| Integration | Authority or information at risk | Apply |
|-------------|----------------------------------|-------|
| Corporate IdP / SCIM | Membership, upstream authentication and group-based reachability | 1.1–1.2; verify provider-specific disable/deactivation behavior |
| OAuth / federated automation | API writes, policy changes and tagged enrollment | 2.3, 3.1; narrow scopes, tags and workflow claims |
| CI / third-party runner | Enrolled node identity and reachable services | 2.1–2.3, 3.2; repository workflow and dependency controls |
| Subnet router / exit node / app connector | Routed resources and egress paths | 3.3; review tag owners, approvals, grants and downstream authentication |
| Shared node / external collaborator | Resource access across a tailnet boundary | 2.1, 2.5, 4.1; external-device posture is not enforced by sharing |
| Funnel publisher | Public internet service exposure | 4.2; application authentication and approved publishing scope |
| MDM / EDR posture integration | Attribute collection, device identifiers and conditional access | 2.5; verify source freshness, availability and integration authority |
| Log destination / SIEM | Identity, policy diffs and connection metadata | 5.1–5.2; private storage, retention, freshness and access review |

## 7. Compliance Quick Reference

Mappings describe supporting objectives. They are not a certification, product benchmark, or substitute for an organization-specific assessment. The source sweep did not identify a Tailscale-specific CIS, SCuBA, NSA or ACSC configuration baseline. DISA coverage could not be established from the public index; no absence claim is made. The [source ledger](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/tailscale-source-evidence.md) records those limits and the automation census.

| Objective | Guide controls | NIST SP 800-53 Rev. 5 examples |
|-----------|----------------|------------------------------|
| Workforce / device identity lifecycle | 1.1–1.5 | AC-2, AC-6, IA-2, IA-3, IA-5, SC-12 |
| Narrow network and privileged access | 2.1–2.5 | AC-3, AC-4, AC-17, CM-3, CA-7 |
| Integration and routed-network authority | 3.1–3.3, 4.1–4.2 | AC-4, AC-6, AC-20, SC-7 |
| Fleet currency and evidence | 4.3, 5.1–5.2 | SI-2, CM-8, AU-2, AU-6, AU-9, AU-12 |

Use the current [NIST SP 800-53 Rev. 5 catalog](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final) and [CIS Controls v8](https://www.cisecurity.org/controls/v8) for assessment context. CIS mappings here use family names rather than unverified safeguard numbers. No ISO, PCI DSS or STIG recommendation number is asserted without a fetched applicable source.

## Appendix A: Availability and Automation

| Capability | Availability / limitation |
|------------|---------------------------|
| Grants, ACLs, tests, tags and basic console roles | All plans in the current feature documentation. Deny-by-default rules can coexist with an initial allow-all policy. |
| Device approval, custom node-key period and Tailscale SSH | All plans; supported client/server platforms still matter. Device approval and Tailnet Lock cannot coexist. |
| Advanced console roles and SCIM | Standard, Premium, Enterprise. User approval and SCIM are mutually exclusive according to the specific user-approval reference; see the documented conflict in 1.2. |
| Device posture | Built-in attributes: all plans. Integration/geolocation: Standard, Premium, Enterprise. Custom attributes: Premium, Enterprise. Validate feature-specific entitlement. |
| Configuration audit logs | All plans; enabled by default; 90-day vendor retention, with documented event-coverage gaps. |
| Network flow logs / log streaming | Premium and Enterprise; flow history 30 days; client/platform support affects coverage. |
| REST | Official fixed-origin API; candidate validation is separate from applying policy. Scope dependencies are explicit in pack headers. |
| CLI | First-party tailscale client; packs collect local status/version only and cannot inventory an entire tenant by inference. |
| Terraform | Official tailscale/tailscale provider pinned to 0.29.3; resources and data sources are both used. Settings and policy have single owners. |
| SDK | Official maintained tailscale.com/client/tailscale/v2 pinned to 2.12.0; older tailscale-client-go is unmaintained. Raw policy handling is used instead of reserializing it through an incomplete typed schema. |
| SIEM | SPL runs in Splunk against operator-configured ingestion of documented configuration JSON, not a Tailscale SQL database. |

## Appendix B: References

- [Security configuration best practices](https://tailscale.com/docs/reference/best-practices/security)
- [Tailnet policy syntax](https://tailscale.com/docs/reference/syntax/policy-file)
- [Trust credentials and scopes](https://tailscale.com/docs/reference/trust-credentials)
- [Tailscale API](https://tailscale.com/api)
- [First-party CLI](https://tailscale.com/docs/reference/tailscale-cli)
- [Official Terraform provider documentation](https://github.com/tailscale/terraform-provider-tailscale/tree/v0.29.3/docs)
- [Official maintained Go SDK](https://github.com/tailscale/tailscale-client-go-v2)
- [Source and surface evidence](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/tailscale-source-evidence.md)
- [Local verification report](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/tailscale-validation.md)

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-04 | 0.1.0 | ai-drafted | Initial eighteen-control tailnet guide with REST, CLI, native policy, Terraform, official Go SDK and SIEM packs; documentation/offline evidence only. | Codex (GPT-6) |

## Contributing

Follow the [contribution guidelines](/contributing/). Report exact client/plan context, tested behavior and supporting first-party sources. Live tenant validation and practitioner review are still needed; documentation checks and mocked tests do not establish either.
