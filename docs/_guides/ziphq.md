---
layout: guide
title: "ZipHQ Hardening Guide"
vendor: "ZipHQ"
slug: "ziphq"
tier: "5"
category: "HR/Finance"
description: "Zip procurement identity, permissions, network restrictions, integrations, approval integrity, AI governance, and audit hardening"
version: "0.3.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-08"
---

## Overview

Zip, operated by **ZipHQ, Inc.**, coordinates procurement requests, supplier information, approvals, and purchasing workflows. This guide covers the procurement product, not similarly named consumer credit or file-compression products. Ownership is corroborated by Zip's [current privacy notice](https://zip.com/zip-privacy-notice).

**Coverage boundary:** this is a source-backed baseline, not a tenant certification. The authenticated API reference, all 159 current operations, 51 implementation guides, three changelog entries, and linked OpenAPI specification were reviewed on 2026-11-08. The authenticated Help Center's 17-category navigation was enumerated, with full or security-focused article-body review across administration, integrations, approvals, payments, supplier workflows, AI, reporting, sourcing, and legal disclosures. Catalog enumeration does not mean every article body, attachment, or embedded video was read. The Security Resource Center catalog remains incomplete. The [source and candidate ledger](/research/ziphq-source-coverage/) records coverage, conflicts, edition boundaries, and remaining gaps. No live tenant configuration was validated.

### Intended Audience

- Procurement-system administrators and identity engineers
- Security and GRC teams assessing purchasing workflows
- Supplier administrators using the separate Zip Vendor App

### How to Use This Guide

- **L1 (Crawl):** Workforce SSO, assigned access, lifecycle controls, and named supplier accounts
- **L2 (Walk):** Phishing-resistant workforce authentication, restricted integration credentials, reviewed permission groups/delegations, and native audit evidence
- **L3 (Run):** Optional customer-managed encryption and carefully scoped advanced controls. Levels describe the recommendation, not proof of live implementation. No L4 claim is made.
- Implement in an isolated test environment first. Keep an independently tested recovery route before authentication changes. **A workflow “Test request” can execute integration subtasks, notifications, and webhooks**; verify safe destinations before testing. Synthetic data alone does not prevent external side effects.

### Scope

Controls distinguish **buyer workforce identity**, **native Zip access and integrations**, and **supplier Vendor App accounts**. Supplier MFA does not establish buyer MFA. Entra assignments are not native permission-group assignments. Zip hierarchical roles govern approval routing and amount limits; they are not permission groups. Documentation access was authorized, but no tenant API records were requested and no product settings were changed or tested live.

**Code Pack boundary:** three read-only Microsoft Graph collectors inspect the Entra application; five native read-only collectors inspect Zip users, permission-group memberships, delegations, queue visibility, and bounded audit-event counts. All return evidence for human review, not a control PASS. Native packs pin **Zip-Api-Version: 2024-06-06** with an existing restricted API key. This is documented legacy mode, not a claim that it is the newest version: the Versioning guide still names 2024-06-06, while the OpenAPI security description requires OAuth bearer authentication for 2026-07-01 and later. Verify the version remains supported for your tenant before deployment; do not switch headers or authentication silently. See the [pack README](https://github.com/grcengineering/how-to-harden/tree/main/packs/ziphq).

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Integration Data Exposure](#2-integration-data-exposure)
3. [Supplier Account Security](#3-supplier-account-security)
4. [Monitoring & Detection](#4-monitoring--detection)
5. [Workflow and Payment Safety](#5-workflow-and-payment-safety)
6. [AI Governance](#6-ai-governance)
7. [Compliance Quick Reference](#7-compliance-quick-reference)
8. [Appendices](#appendix-a-applicability-and-documentation-gaps)

## 1. Authentication & Access Controls

### 1.1 Configure Workforce SAML SSO

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2, AC-3 |

#### Description

Federate buyer workforce access with the approved identity provider, using the tenant-specific metadata and independently tested recovery plan. Zip now documents native SSO configuration and enforcement; SAML availability alone still does not prove all accounts or environments are covered.

#### Rationale

**Why This Matters:**
- Central identity policy reduces unmanaged login paths.
- Incorrect tenant identifiers can lock out users or connect the wrong application.

**Attack Prevented:** Unmanaged workforce authentication and misdirected federation.

#### Prerequisites

An SSO-enabled Zip subscription, Zip administrator/support contact, and Entra Cloud Application Administrator or equivalent Okta authority. Verify a backup access route before cutover.

#### ClickOps Implementation

1. In Entra, open **Entra ID → Enterprise apps → New application**, select **Zip** from the gallery, then **Zip → Single sign-on → SAML**. Use the tenant identifiers confirmed for your production or sandbox application, not example URLs.
2. In Zip, open the gear menu → **Company settings → Security → Sign In → + Add Provider**. Select **SSO Type**, enter the approved **Metadata URL**, and set **Display name**. **Individual metadata fields** can be expanded where applicable. Follow the current provider-specific implementation guide and coordinate certificate exchange with your Zip contact.
3. For Okta, verify **General → subdomain** and **Sign On → Edit → Default Relay State** against the actual tenant. Complete the documented federation setup before assigning production users.
4. Test IdP-initiated and tenant-initiated sign-in. Review **Enforce SSO for all users** and the individual **SSO enforced** column as described in §1.5. Configure each sandbox separately (§1.10).

**Default:** global SSO enforcement starts off, but turns on automatically when the first SSO provider is connected. Turning one user's enforcement off also turns the global toggle off. Test rather than infer the effective boundary.

**Sources:** [Security Page](https://docs.ziphq.com/hc/en-us/articles/25604138623899-Security-Page), [Microsoft Zip SSO](https://learn.microsoft.com/en-us/entra/identity/saas-apps/zip-tutorial), and [Okta Zip SAML](https://saml-doc.okta.com/SAML_Docs/How-to-Configure-SAML-2.0-for-Zip.html). Provider documents and tenant enablement can differ; use the established support channel rather than a legacy support address.

#### Code Implementation

The collector reports Entra service-principal settings only. A configured SAML mode is not evidence of Zip-side enforcement or an end-to-end login test.

{% include pack-code.html vendor="ziphq" section="1.1" %}

#### Validation & Testing

Use a nonprivileged assigned pilot account in a fresh browser session. Confirm the expected tenant, user identity, and IdP policy. Test documented alternate login routes with your own test account and record exceptions. Rotate certificates through a staged overlap agreed with Zip, not an untested replacement.

**Expected result:** The positive and negative cases above match the intended access boundary, with documented exceptions. An unavailable test remains unverified.

#### Monitoring & Maintenance

Monitor certificate expiry and SSO errors monthly. If the pilot fails, retain the previous federation configuration and stop rollout; do not remove the final working administrator.

#### Operational Impact

Pilot first: changes can delay login, provisioning, notifications, or supplier onboarding. Capture the prior configuration and restore only the affected setting after review. No pack in this guide performs that change.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2, AC-3 |
| SOC 2 | Logical access and monitoring objectives; assess the applicable Trust Services Criteria with the auditor |
| ISO/IEC 27001:2022 | Access control, identity management, and access-rights objectives; confirm applicability in the statement of applicability |

---

### 1.2 Require Assignment and Review Zip Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-3, AC-6 |

#### Description

Require explicit Entra application assignment for Zip and review the assigned population. This gates the federated entry point, not Zip-native role permissions, existing sessions, or API credentials.

#### Rationale

**Why This Matters:**
- A visible app tile is not an access restriction.
- Unreviewed group membership can preserve access after a role change.

**Attack Prevented:** Unapproved federated access and stale entitlements.

#### Prerequisites

Application administrator access. Entra P1/P2 is required for group-based assignment. Capture the enterprise application Object ID, not its application/client ID, for the collectors.

#### ClickOps Implementation

1. Open **Entra ID → Enterprise apps → Zip → Properties**. Set **Assignment required?** to **Yes** and save after checking the pilot assignments.
2. Open **Users and groups**. Assign only approved users or tightly managed groups; remove stale entries after assessing business impact.
3. Review group membership and privileged exceptions separately. Assigning **Default Access** is not evidence that the user has a least-privilege role inside Zip.

**Sources:** [Application properties](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/application-properties), [configure properties](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/configure-application-properties), and [assign users/groups](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/assign-user-or-group-access-portal).

#### Code Implementation

Run the §1.1 collector to inspect `appRoleAssignmentRequired`, then use this collector to count assigned principal types across all returned pages. Counts do not identify inappropriate members or expand nested groups; perform the identity review in the console.

{% include pack-code.html vendor="ziphq" section="1.2" %}

#### Validation & Testing

Verify an approved non-admin pilot can authenticate and an unassigned non-admin pilot cannot obtain federated access. Confirm the correct Zip enterprise application was selected. Allow for documented replication delay after assignment changes. Separately check Zip-local accounts and existing sessions.

**Expected result:** The positive and negative cases above match the intended access boundary, with documented exceptions. An unavailable test remains unverified.

#### Monitoring & Maintenance

Review assignments monthly and after transfers. If an intended user is blocked, restore only that reviewed assignment; do not broadly disable assignment requirements.

#### Operational Impact

Pilot first: changes can delay login, provisioning, notifications, or supplier onboarding. Capture the prior configuration and restore only the affected setting after review. No pack in this guide performs that change.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-3, AC-6 |
| SOC 2 | Logical access and monitoring objectives; assess the applicable Trust Services Criteria with the auditor |
| ISO/IEC 27001:2022 | Access control, identity management, and access-rights objectives; confirm applicability in the statement of applicability |

---

### 1.3 Apply Phishing-Resistant MFA at the Identity Provider

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2(1), IA-2(8) |

#### Description

Ensure federated Zip sign-ins are covered by the workforce MFA policy. For higher assurance, require the built-in phishing-resistant authentication strength. This applies to buyer SSO, not the supplier Vendor App or Zip API keys.

#### Rationale

**Why This Matters:**
- A federation connection can still accept password-only authentication.
- An unrestricted MFA requirement may allow weaker methods than the organization intends.

**Attack Prevented:** Password-only compromise and phishing of weaker authentication factors.

#### Prerequisites

Entra P1 or higher for Conditional Access, appropriate administrator role, registered compatible methods, and tested emergency access. Do not turn off existing baseline protection just to deploy this policy.

#### ClickOps Implementation

1. In **Entra ID → Conditional Access → Policies**, inspect the existing all-users/all-resources MFA baseline and verify Zip is not excluded.
2. If a stronger policy is needed, select **New policy** and scope the pilot users and the Zip enterprise application under **Target resources**.
3. Under **Access controls → Grant**, require an **authentication strength**, selecting **Phishing-resistant MFA**. Retain separately governed emergency-access exclusions.
4. Begin in **Report-only**, inspect pilot sign-ins and compatibility, then change to **On** after a successful test. Do not count Report-only as enforcement.

**Sources:** [Microsoft MFA policy guidance](https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-mfa-strength) and [authentication strengths](https://learn.microsoft.com/en-us/azure/active-directory/authentication/concept-authentication-strengths). The stricter strength is an HTH recommendation; the baseline article recommends the less restrictive MFA strength.

**Automation:** IdP-managed, not a Zip API. Microsoft documents Graph/PowerShell and Terraform policy management; use the [Entra authentication-strength and Conditional Access controls](/guides/microsoft-entra-id/) rather than mistaking a Zip SAML collector for an MFA evaluator. No Zip-specific effective-policy evaluator is supplied.

#### Validation & Testing

Test a permitted passkey/security key and a password-only or disallowed method using pilot accounts. Check **Sign-in logs → Conditional Access** for the effective result, exclusions, and report-only policies. A successful browser session alone does not prove a fresh challenge. Test alternate Zip login paths separately.

**Expected result:** The positive and negative cases above match the intended access boundary, with documented exceptions. An unavailable test remains unverified.

#### Monitoring & Maintenance

Review policy exclusions and authentication-method registration quarterly. If needed, revert the new pilot policy while keeping the pre-existing MFA baseline; never disable all MFA as rollback.

#### Operational Impact

Pilot first: changes can delay login, provisioning, notifications, or supplier onboarding. Capture the prior configuration and restore only the affected setting after review. No pack in this guide performs that change.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2(1), IA-2(8) |
| SOC 2 | Logical access and monitoring objectives; assess the applicable Trust Services Criteria with the auditor |
| ISO/IEC 27001:2022 | Access control, identity management, and access-rights objectives; confirm applicability in the statement of applicability |

---

### 1.4 Scope and Test SCIM Provisioning

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6 |

#### Description

Use the documented Zip provisioning integration to manage workforce lifecycle, with a narrowly assigned pilot population and tested deprovisioning. Do not infer immediate session or API-token revocation from a directory sync.

#### Rationale

**Why This Matters:**
- Dormant accounts accumulate when offboarding depends on memory.
- An overly broad synchronization scope can remove or create unintended accounts.

**Attack Prevented:** Orphaned workforce access and uncontrolled provisioning changes.

#### Prerequisites

Zip administrator or appropriate **Access all security settings** authority; an approved identity-provider integration and narrowly scoped pilot. Handle SCIM credentials only in the approved secret system. The documented OAuth2 option must be enabled by Zip and requires a new Okta app; an existing Okta SCIM app cannot simply be switched to OAuth2.

#### ClickOps Implementation

1. Open **Company settings → Security → User Management (SCIM)**. Review the supported integration authentication with your Zip contact. Basic credentials remain valid until regenerated; **Generate new credentials** invalidates the old credentials immediately, so coordinate the provider update.
2. Configure the provider using its current Zip guide. In Entra, review **Provisioning**, **Attribute mapping**, assigned population, notification email, and accidental-deletion protection. Pilot **Test Connection** and **Provision on-demand** before broad synchronization.
3. **Do not sync passwords** from Okta or any SCIM provider. Review **Security → User field mapping (SCIM) → Edit** for necessary attributes only. Prefer exact identifiers over fuzzy matches for routing-relevant fields. A failed transformation falls back to the original field value, not a blocked sync.
4. For advanced permission groups, pre-create uniquely named least-privilege Zip groups and use the exact IdP group prefix **[Zip Permission Group]** followed by a space and the Zip group name. **Default** is reserved. An unmatched name creates a new group with default permissions; duplicate Zip names match the oldest group. Do not merge two populated groups blindly: follow the documented new-to-existing or existing-to-new procedure.
5. Avoid enabling JIT alongside SCIM: the SSO/SCIM implementation guide recommends against the combination, and JIT-created users receive Default permissions. SCIM deactivation disables login but retains inactive-user information; it is not data deletion. Verify **SCIM group linked** on **Users and permissions → Permission groups**, then test addition and removal. Membership is one-way from the IdP and asynchronous. CSV permission-group imports are additive and do not remove old grants; API `group_ids` updates replace the entire set.
6. In **Users and permissions → … → Manage reassignment settings**, choose an approved offboarding process. **Manual reassignment is the default.** Automatic reassignment sends responsibilities to the manager; a deactivated manager can leave tasks unassigned, and outbound delegations are not reassigned. Review unresolved banners and the reassignment audit trail.

**Documentation conflict:** October 2026 release notes describe provider-isolated multi-IdP SCIM for advanced permissions, but the Security Page still warns to use only one SCIM provider. Confirm tenant enablement and provider-specific credentials before multi-provider rollout. Do not reuse a single provider's credentials across IdPs.

**Sources:** [Security Page](https://docs.ziphq.com/hc/en-us/articles/25604138623899-Security-Page), [SCIM groups](https://docs.ziphq.com/hc/en-us/articles/43537045547931-Syncing-SCIM-Permission-Groups), [field mapping](https://docs.ziphq.com/hc/en-us/articles/54272655042075-SCIM-Custom-Field-Mapping), [user transitions](https://docs.ziphq.com/hc/en-us/articles/19897886535707-Manage-User-Transitions), [October updates](https://docs.ziphq.com/hc/en-us/articles/55974890840731-October-2026-Product-Updates), and [Entra provisioning](https://learn.microsoft.com/en-us/entra/identity/saas-apps/zip-provisioning-tutorial), and the [SSO/SCIM implementation PDF](https://docs.ziphq.com/hc/en-us/article_attachments/52061657892379) (document revision October 17, 2025).

#### Code Implementation

This collector reads Entra synchronization-job state. It does not retrieve the provisioning secret, verify the mapping, enforce scope, or prove that a specific Zip user was removed.

{% include pack-code.html vendor="ziphq" section="1.4" %}

#### Validation & Testing

Provision a dedicated pilot, change a harmless mapped attribute, then remove the pilot from scope and verify the resulting account state in Zip. Test a fresh login and an existing session separately. Keep timestamps to measure actual deprovisioning delay. Review skipped/quarantined events rather than treating a running job as success.

**Expected result:** The positive and negative cases above match the intended access boundary, with documented exceptions. An unavailable test remains unverified.

#### Monitoring & Maintenance

Check synchronization failures and quarantine daily; review mappings, scope, secret expiry, and deletion thresholds quarterly. Pause the provisioning job to investigate unexpected changes before restoring affected users through the approved recovery process.

#### Operational Impact

Pilot first: changes can delay login, provisioning, notifications, or supplier onboarding. Capture the prior configuration and restore only the affected setting after review. No pack in this guide performs that change.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6 |
| SOC 2 | Logical access and monitoring objectives; assess the applicable Trust Services Criteria with the auditor |
| ISO/IEC 27001:2022 | Access control, identity management, and access-rights objectives; confirm applicability in the statement of applicability |

---

### 1.5 Review Native SSO Exceptions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2, AC-2, AC-3 |

#### Description

Reconcile the native user inventory with the workforce identity policy. The User response exposes `is_active` and `sso_enforced`; neither an Entra SAML setting nor a successfully read flag proves every interactive authentication route is protected.

#### Rationale

**Why This Matters:**
- Native users and IdP assignments can drift independently.
- Missing or false SSO flags require investigation, not an automatic compliance result.

**Attack Prevented:** Unnoticed local-authentication exceptions and stale native user access.

#### Prerequisites

An approved native user roster, exception owner, and an existing restricted API key with only the read access needed for users. The exact read-scope identifier is not enumerated in the reviewed key UI guide.

#### ClickOps Implementation

1. Open **Company settings → Security**. After testing federation and recovery, turn on **Enforce SSO for all users**. This sets every user's individual SSO enforcement on, including previously excluded users.
2. Open **Company settings → Users and permissions → Users** and review **SSO enforced** alongside **Active** and assigned groups. Turning off one user's **SSO enforced** also turns off the global toggle; every exception therefore needs an owner, expiry, compensating MFA, and a retest.
3. Use **Security → View users** in elevated-access alerts to inspect flagged users. Selected users can be remediated with **Enforce SSO**. Do not treat the monthly SSO-or-MFA safeguard as phishing-resistant MFA enforcement: either SSO alone or native MFA satisfies it.
4. Reconcile native collector counts privately against the approved roster. On the first of the month, Zip notifies administrators of elevated users without SSO/MFA; unresolved users lose extra groups on the 26th and retain **Default**, their data, and login access. Verify the Default group's grants rather than assuming downgrade means deactivation.

**Sources:** [Security Page](https://docs.ziphq.com/hc/en-us/articles/25604138623899-Security-Page), [Securing Elevated Users](https://docs.ziphq.com/hc/en-us/articles/54131008985883-Securing-Elevated-Users-with-SSO-or-MFA), [Search users](https://developers.ziphq.com/zipapidocs/reference/searchusers), and [update-user contract](https://developers.ziphq.com/zipapidocs/reference/updateuserbyid). The REST PATCH schema still does not expose `sso_enforced`; the collector remains read-only.

#### Code Implementation

This GET-only collector classifies returned flag values. Optional or absent properties remain unknown. It does not modify users, attempt sign-in, or certify local-login/recovery behavior.

{% include pack-code.html vendor="ziphq" section="1.5" %}

#### Validation & Testing

**Expected result:** every in-scope active workforce user has reviewed SSO evidence or an explicitly approved, time-bounded exception. With authorized test accounts, confirm IdP sign-in works and unintended local-login routes are blocked. Missing fields, unavailable tests, and zero users are not passes.

#### Monitoring & Maintenance

Review after identity changes and at least monthly. Investigate newly unknown or false values against an approved roster before taking action.

#### Operational Impact

Review is read-only. Remediation can lock out users; test the exact tenant-supported change and recovery path before rollout.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2, AC-2, AC-3 |
| SOC 2 | Logical access, change management, and monitoring objectives; assess applicable criteria with the auditor |
| ISO/IEC 27001:2022 | Identity, access-rights, information-transfer, and logging objectives; confirm applicability in the statement of applicability |

---

### 1.6 Review Permission Group Memberships

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-5, AC-6 |

#### Description

Review native permission-group membership against a business-approved access matrix. Zip combines permissions additively: a grant in any assigned group remains effective even if another group does not grant it. Hierarchical roles are a different approval-routing construct.

#### Rationale

**Why This Matters:**
- Adding a restrictive group does not remove access granted elsewhere.
- Group names and hierarchical-role titles do not prove actual permissions or separation of duties.

**Attack Prevented:** Accumulated privileges and mistaken least-privilege assumptions.

#### Prerequisites

An administrator-approved group-to-job-function matrix, user roster, and documented underlying group grants. Read-only Users access is sufficient for the membership collector; do not grant write access merely to inspect memberships.

#### ClickOps Implementation

1. Open **Company settings → Users and permissions → Permission groups**. Identify whether the tenant uses **basic** or **advanced** permissions. Review each group's **Edit** settings, not just its name; include the Default group and all groups assigned to a user.
2. With advanced permissions, set **Permission Group Detail → Subsidiary and department access** to the approved scope and review each permission page. Restrict user/permission administration, security settings, API/webhook management, workflow editing and approval reassignment, vendor payment/tax data, exports, integration testing, AI configuration, and transcript access.
3. Review record-involvement exceptions: requester, approver, follower/@mention, owner, budget/project owner, and eligible queue membership can grant access independently of central-list permissions. Department scopes do not constrain payout groups; bill/invoice scope uses the header department, not line-item departments. **Reassign responsibilities for workflows and approvals** can supersede related queue restrictions.
4. On **Users → Groups**, add approved groups and remove obsolete ones with **X**. Changes save immediately. Advanced permissions documentation permits replacing Default with a more restrictive group, but requires another group before removing the last one. The older API assignment guide says Default cannot be removed in the UI: verify the tenant's framework rather than treating that as universal.
5. Review **… → View permissions audit trail** and, where entitled, **Export permissions audit package**. Restrict the exported permission/user data to approved reviewers. Review **Company settings → Hierarchical roles** separately for approval limits; these roles are not RBAC.
6. Review newly expanded integration privileges after upgrades. [October 2026 updates](https://docs.ziphq.com/hc/en-us/articles/55974890840731-October-2026-Product-Updates) rename **Access integration field mapping in workflow** to **Configure integration apps** and expand it to marketplace installation/update, subtask configuration, and connection creation. Other grants can overlap; do not assume revoking one switch blocks all installation paths.
7. If using a separate authorized API remediation, `group_ids` replaces all memberships; preserve the intended complete set. CSV imports instead add groups and cannot clear them with a blank or `--NULL--`. Neither workflow substitutes for a least-privilege review.

**Sources:** [Users and Permissions](https://docs.ziphq.com/hc/en-us/articles/17459091719451-Users-and-Permissions), [advanced permissions](https://docs.ziphq.com/hc/en-us/articles/18921746955035-Permission-Settings-and-Groups), [basic permissions](https://docs.ziphq.com/hc/en-us/articles/17459160359195-Permission-Groups), [audit readiness](https://docs.ziphq.com/hc/en-us/articles/17459193825435-Audit-Readiness), and [API group assignment](https://developers.ziphq.com/zipapidocs/docs/use-case-assign-permission-groups-to-users).

#### Code Implementation

The collector aggregates memberships from GET /users. It does not disclose identities, infer privileges from names, or certify actual group grants. The group read endpoints expose identifiers, names and descriptions, not the full permission policy. The documented group PATCH changes its description only; it is not an access-policy editor.

{% include pack-code.html vendor="ziphq" section="1.6" %}

#### Validation & Testing

**Expected result:** every membership is justified by the approved access matrix, and a representative least-privileged account can perform its intended task but cannot perform an unrelated privileged action. Aggregates alone cannot establish this. An unknown membership field remains an evidence gap.

#### Monitoring & Maintenance

Review monthly and during joiner/mover/leaver changes. Re-review all grants whenever a group is modified, because every assigned user may be affected.

#### Operational Impact

The pack is read-only. Membership replacement can remove essential access or add privilege; capture the intended complete set and recovery process before any separate approved remediation.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-5, AC-6 |
| SOC 2 | Logical access, change management, and monitoring objectives; assess applicable criteria with the auditor |
| ISO/IEC 27001:2022 | Identity, access-rights, information-transfer, and logging objectives; confirm applicability in the statement of applicability |

---

### 1.7 Bound Interactive Session Duration

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-12, SC-23 |

#### Description

Set an explicit absolute session lifetime and idle timeout in Zip, separately from IdP policy. Shorter sessions reduce the usable lifetime of a lost browser session but do not replace MFA or endpoint security.

#### Rationale

**Why This Matters:**
- IdP reauthentication policy does not prove an existing Zip session expires.
- An unattended authenticated browser can expose procurement and payment functions.

**Attack Prevented:** Extended reuse of unattended or stolen interactive sessions.

#### Prerequisites

Administrator or Edit access to **Access all security settings**; an agreed session policy and pilot accounts.

#### ClickOps Implementation

1. Open **Company settings → Security → Session Settings**.
2. Set **Session length** to an approved value. Zip recommends **two weeks or less**; use the shorter duration required by your risk policy and the choices actually offered by the tenant. This is a vendor recommendation, not an asserted default.
3. Set **Idle timeout duration** to the approved inactivity window. The documentation does not enumerate every choice or state a universal default; record the actual selection.
4. Both changes save automatically. Review **Security → … → View audit trail** and test before broad rollout.

**Sources:** [Security Page](https://docs.ziphq.com/hc/en-us/articles/25604138623899-Security-Page).

**Automation:** The authenticated OpenAPI specification (102 paths, 159 operations) reviewed on 2026-11-08 does not expose this administrative setting. No first-party CLI, SDK, or native policy-file contract was verified. Use the documented UI and retain protected review evidence; do not invent a settings endpoint.

#### Validation & Testing

**Expected result:** a pilot is forced to sign in after both the selected idle period and absolute lifetime, tested separately. Verify active versus inactive behavior and IdP login requirements. Do not infer API-key expiry from browser logout.

#### Monitoring & Maintenance

Review settings and audit history quarterly and after authentication changes. Investigate sessions surviving the configured period.

#### Operational Impact

Shorter timeouts interrupt long approvals or drafting. Capture prior selections and coordinate any rollback without disabling the approved authentication boundary.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-12, SC-23 |
| SOC 2 | Logical access, change management, confidentiality, and monitoring objectives; assess applicable criteria with the auditor |
| ISO/IEC 27001:2022 | Access control, information transfer, and operations-security objectives; confirm applicability in the statement of applicability |

---

### 1.8 Restrict Web and API Network Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, SC-7 |

#### Description

Allow access only through approved corporate or secure-access egress where the business can support that restriction. Configure browser and per-key API allowlists independently.

#### Rationale

**Why This Matters:**
- Authentication credentials can be used outside approved networks.
- An IP group existing in the catalog does not mean it is enforced on the UI or a key.

**Attack Prevented:** Use of compromised credentials from unapproved network locations.

#### Prerequisites

Edit security-settings authority, approved stable egress addresses/CIDRs, and recovery access. Coordinate API-key management separately. Do not deploy before remote-worker and integration egress are known.

#### ClickOps Implementation

1. Open **Company settings → Security → IP settings → + Add IP group**. Enter a descriptive name and approved addresses/CIDRs. Avoid overly broad ranges.
2. Edit **Web UI IP allowlist** using its pencil icon. Select **Restrict access to selected IP groups**, choose the approved groups, then **Save**.
3. Open **Company settings → Apps and integrations → API**. Edit each key, select **Restrict access to selected IP groups**, and choose only the integration's approved egress groups. Both Standard and Restricted keys support this.
4. **Fail-open deletion warning:** deleting the final group assigned to a key changes it to **Allow access from any IP address**. Replace restrictions before retiring groups, then recheck every affected key.
5. The Security Page says 20 entries per group while the dedicated IP article says 150. Do not rely on either limit without checking the tenant; split reviewed groups if necessary.

**Sources:** [IP Allowlists](https://docs.ziphq.com/hc/en-us/articles/46225974720795-IP-Allowlists) and [Security Page](https://docs.ziphq.com/hc/en-us/articles/25604138623899-Security-Page).

**Automation:** The authenticated OpenAPI specification (102 paths, 159 operations) reviewed on 2026-11-08 does not expose this administrative setting. No first-party CLI, SDK, or native policy-file contract was verified. Use the documented UI and retain protected review evidence; do not invent a settings endpoint.

#### Validation & Testing

**Expected result:** an approved browser and read-only integration request work from the allowed egress; equivalent authorized tests from an unlisted address are denied. Test IPv4/IPv6 and the actual secure-access path. Re-test after group removal. A successful API read from one network alone is not proof of restriction.

#### Monitoring & Maintenance

Review groups, every key assignment, and egress changes quarterly. Include group deletion and VPN/secure-access changes in change control.

#### Operational Impact

Incorrect ranges can lock out administrators and break integrations. Maintain a reviewed recovery route; do not widen to all addresses as an unapproved troubleshooting shortcut.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, SC-7 |
| SOC 2 | Logical access, change management, confidentiality, and monitoring objectives; assess applicable criteria with the auditor |
| ISO/IEC 27001:2022 | Access control, information transfer, and operations-security objectives; confirm applicability in the statement of applicability |

---

### 1.9 Limit Zip Support Administrative Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6, MA-4 |

#### Description

Explicitly decide whether Zip Support should retain administrator access. For organizations requiring time-bounded third-party access, disable standing access and re-enable it only for an approved support window.

#### Rationale

**Why This Matters:**
- A support permission is separate from your own workforce permission groups.
- Third-party access should have a documented purpose, owner, and end time.

**Attack Prevented:** Unreviewed standing third-party administrative access.

#### Prerequisites

Edit **Access all security settings**, support-process owner, and a support plan that can tolerate approval delays.

#### ClickOps Implementation

1. Open **Company settings → Security → Governance**.
2. Review **Grant admin access to Zip Support**, which is **on by default** and permits Zip employees to change the instance and data.
3. If standing access is not approved, turn it off and review the **Remove Zip Admin access?** warning before choosing **Remove**. Zip advises that disabling access can delay support; document that tradeoff rather than claiming it is universally risk-free.
4. For an approved support incident, record the authorized purpose and window, restore access only when needed, and remove it afterward. Review the Security settings audit trail. No automatic expiry or full support-access activity log is established by this source.

**Sources:** [Security Page](https://docs.ziphq.com/hc/en-us/articles/25604138623899-Security-Page).

**Automation:** The authenticated OpenAPI specification (102 paths, 159 operations) reviewed on 2026-11-08 does not expose this administrative setting. No first-party CLI, SDK, or native policy-file contract was verified. Use the documented UI and retain protected review evidence; do not invent a settings endpoint.

#### Validation & Testing

**Expected result:** the saved toggle matches the approved policy and its audit history records the change. Coordinate a support case to verify the operational boundary without asking staff to access unrelated sensitive records.

#### Monitoring & Maintenance

Review open support windows and close stale grants. Recheck after support and administrator changes.

#### Operational Impact

Disabling access can slow diagnosis and increase work for customer administrators. This control is a risk-based restriction, not a claim that Zip recommends turning it off in every tenant.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6, MA-4 |
| SOC 2 | Logical access, change management, confidentiality, and monitoring objectives; assess applicable criteria with the auditor |
| ISO/IEC 27001:2022 | Access control, information transfer, and operations-security objectives; confirm applicability in the statement of applicability |

---

### 1.10 Harden Sandbox Identity and Connections

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-3, CM-4 |

#### Description

Apply identity and data-boundary controls independently to every Zip environment. A production copy does not inherit a complete production login policy or automatically remain disconnected after future changes.

#### Rationale

**Why This Matters:**
- New environments copy users and permissions but initially disable SSO enforcement.
- Refreshes can retain organization-level connections and overwrite test configuration.

**Attack Prevented:** Weak sandbox authentication and accidental disclosure or mutation through test integrations.

#### Prerequisites

Zip Premier, **Access all environments**, environment administrator, separate IdP application and non-production integration endpoints. Do not create or refresh an environment merely to run a collector.

#### ClickOps Implementation

1. Open **Company settings → Environments** and review every environment's purpose, owner, parent, refresh schedule, and **Users and permissions** access. **Sandbox access** grants are separate from production assignments.
2. In each environment, configure **Company settings → Security** and enforce SSO after testing its own IdP application assignment. **New environments start with global and per-user SSO enforcement off.** Local passwords are shared across production and other environments.
3. If any environment permits password login, enable **Enable MFA for sandbox environments** on the Environments page. It does not affect production or SSO-enforced users. Review local exceptions under §1.11.
4. Before refresh, preserve needed test data and review **Reset users & permissions**. Refresh overwrites environment data; existing SSO enforcement and notification settings are restored afterward, and new users follow the environment's global SSO setting.
5. Inventory external connections after creation and each refresh. Organization-level App Studio connections can survive refresh; personal connections must be reconnected, and scheduled jobs stop. Notifications start disabled in new environments but existing settings survive refresh. Do not connect production payment/ERP destinations for tests.
6. Treat the article's generic isolation assurances cautiously: its detailed sections and summary conflict over copied integration secrets. Verify actual connections and outbound destinations. Production workflow **+ Test request** can still run integration tasks, webhooks, and notifications (§5.5).

**Sources:** [Setting Up an Environment](https://docs.ziphq.com/hc/en-us/articles/27197993336859-Setting-Up-an-Environment), [Security Page](https://docs.ziphq.com/hc/en-us/articles/25604138623899-Security-Page), and [Workflow Versioning](https://docs.ziphq.com/hc/en-us/articles/44969980445595-Workflow-Versioning).

**Automation:** The authenticated OpenAPI specification (102 paths, 159 operations) reviewed on 2026-11-08 does not expose this administrative setting. No first-party CLI, SDK, or native policy-file contract was verified. Use the documented UI and retain protected review evidence; do not invent a settings endpoint.

#### Validation & Testing

**Expected result:** only approved sandbox users can sign in, required SSO/MFA is enforced, and synthetic tests reach only approved non-production destinations. Repeat after refresh; verify production identity assignment alone is insufficient for sandbox access.

#### Monitoring & Maintenance

Review environment access and retained connections after every refresh and quarterly. Retire unused environments through the approved data-retention process.

#### Operational Impact

Refresh destroys existing environment data and may alter permissions or stop jobs. Separate SSO setup can lock out users; retain a controlled onboarding/recovery procedure.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-3, CM-4 |
| SOC 2 | Logical access, change management, confidentiality, and monitoring objectives; assess applicable criteria with the auditor |
| ISO/IEC 27001:2022 | Access control, information transfer, and operations-security objectives; confirm applicability in the statement of applicability |

---

### 1.11 Verify Native MFA Recovery Requests

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2, IA-5, AC-2 |

#### Description

For explicitly approved non-SSO accounts, use native MFA and verify reset requests out of band. Prefer workforce SSO with phishing-resistant MFA; native SMS/phone/TOTP is not equivalent.

#### Rationale

**Why This Matters:**
- An attacker can target account recovery instead of the normal MFA prompt.
- An approved reset lets the next login enroll a new factor.

**Attack Prevented:** Social-engineered MFA reset and unmanaged local-login exceptions.

#### Prerequisites

Approved local-login exceptions, authorized user administrator, and established contact details for identity verification.

#### ClickOps Implementation

1. Review non-SSO users under **Company settings → Users and permissions** and Security alerts. Native sign-in offers phone/SMS or an authenticator app. Use individually controlled TOTP where native MFA is necessary; do not share enrollment secrets.
2. Review the **Has MFA reset request** alert/filter. Verify the request with the person using an established communication route, especially for administrators and payment users, before approving or rejecting it.
3. Use the user's row **… → Reset MFA** only for an authorized, independently verified reset. Zip prompts enrollment on the next login and sends reset-related notifications; record the approval without copying recovery codes.
4. Handle SSO-enforced users' factor recovery at the IdP. Zip's native reset is for email/password login, not the IdP's factor enrollment.

**Sources:** [Users and Permissions](https://docs.ziphq.com/hc/en-us/articles/17459091719451-Users-and-Permissions), [Signing In to Zip](https://docs.ziphq.com/hc/en-us/articles/42249526512923-Signing-In-to-Zip), and [Security Page](https://docs.ziphq.com/hc/en-us/articles/25604138623899-Security-Page).

**Automation:** The authenticated OpenAPI specification (102 paths, 159 operations) reviewed on 2026-11-08 does not expose this administrative setting. No first-party CLI, SDK, or native policy-file contract was verified. Use the documented UI and retain protected review evidence; do not invent a settings endpoint.

#### Validation & Testing

**Expected result:** approved local accounts require the enrolled factor and reset requests receive documented verification before any factor changes. Use a controlled test account only if a reset test is approved; otherwise record recovery testing as unverified.

#### Monitoring & Maintenance

Review pending resets promptly, investigate unexpected requests, and periodically eliminate unnecessary local exceptions.

#### Operational Impact

Resets invalidate a working factor and can block the user. Do not reset real credentials just to collect evidence or downgrade an SSO account as a workaround.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2, IA-5, AC-2 |
| SOC 2 | Logical access, change management, confidentiality, and monitoring objectives; assess applicable criteria with the auditor |
| ISO/IEC 27001:2022 | Access control, information transfer, and operations-security objectives; confirm applicability in the statement of applicability |

---

## 2. Integration Data Exposure

### 2.1 Minimize Slack Notification Exposure

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-4, AC-6 |

#### Description

Constrain Zip notification destinations and fields to the intended Slack audience, including workflow-level overrides. This is a data-exposure control, not a guarantee that a private Slack channel remains selectable only by its members.

#### Rationale

**Why This Matters:**
- Procurement notifications can expose contract or supplier details outside the request team.
- Per-approval overrides can bypass a carefully selected company default.

**Attack Prevented:** Unintended disclosure through notification routing.

#### Prerequisites

Zip integration/workflow administrator and Slack channel owner. Review the installed application permissions before reconnecting or adding it to a channel.

#### ClickOps Implementation

1. Open **Company settings → Notifications** and review **Channel notifications**, email, and direct-chat delivery. The current integrations menu is **Company settings → Apps and integrations → Native integrations**; older guides call it **Integrations → Communications**.
2. Inspect workflow, approval, and action notification overrides. Per-approval **Include fields in email** and **Include fields in Slack notifications** are on by default; **Include attachments in approval emails and Slack notifications** is off. Remove unnecessary attributes and attachments from the destination audience.
3. Review Zip bot memberships. Zip documents that private Slack channels can become selectable by all Zip users after the bot joins; private-channel membership is not a Zip destination-selection boundary.
4. Disable no-login approvals for sensitive decisions using §5.1; hiding notification fields does not enforce login. Inspect **Notifications → … → Notification settings audit trail** for routing changes.

**Related Teams deployment:** the current [Teams guide](https://docs.ziphq.com/hc/en-us/article_attachments/56591748348827) does not support private channels. If channel notifications are not used, it documents removing **Team.ReadBasic.All** and **Channel.ReadBasic.All** after connection while retaining the required user-matching and app-installation permissions. Review that permission reduction with the integration owner; do not remove grants needed for a chosen channel feature. The [Slack guide](https://docs.ziphq.com/hc/en-us/article_attachments/57229098509851) requires a Workspace Owner for installation, not merely an administrator.

**Sources:** [Notifications Settings](https://docs.ziphq.com/hc/en-us/articles/17459091797531-Notifications-Settings), [Approvals](https://docs.ziphq.com/hc/en-us/articles/17459136461851-Approvals), and [Zip Slack setup](https://zip.com/integration/slack).

**Automation:** the [reviewed OpenAPI](https://developers.ziphq.com/zipapidocs/openapi/openapi.yaml) has no notification-policy settings operation. Other native automation surfaces remain unverified; use the documented UI.

#### Validation & Testing

Send a synthetic request containing a recognizable non-sensitive marker. Confirm actual recipients, channel overrides, thread replies, and displayed fields. Have a non-member test whether the private destination is selectable without sending sensitive content. Recheck after the documented synchronization delay of up to 24 hours.

**Expected result:** The positive and negative cases above match the intended access boundary, with documented exceptions. An unavailable test remains unverified.

#### Monitoring & Maintenance

Review notification fields and bot memberships after every workflow change. Restore the previously reviewed destination or remove the new override if the test exposes unintended information; preserve approval routing.

#### Operational Impact

Pilot first: changes can delay login, provisioning, notifications, or supplier onboarding. Capture the prior configuration and restore only the affected setting after review. No pack in this guide performs that change.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-4, AC-6 |
| SOC 2 | Logical access and monitoring objectives; assess the applicable Trust Services Criteria with the auditor |
| ISO/IEC 27001:2022 | Access control, identity management, and access-rights objectives; confirm applicability in the statement of applicability |

---

### 2.2 Restrict and Expire API Keys

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

#### Description

Use a separate, named restricted API key for each integration, grant only the necessary record types and access levels, and set an expiry consistent with organizational policy. Standard keys grant read/write access to all API endpoints.

#### Rationale

**Why This Matters:**
- A compromised unrestricted key can change purchasing and identity data.
- Purpose-specific credentials reduce exposure and make ownership and replacement reviewable.

**Attack Prevented:** Excessive integration privilege and indefinite credential reuse.

#### Prerequisites

Administrator or **Manage company API keys** permission; an inventory of credential consumers and a secure secret store. Creating credentials and modifying persistent access require the operator’s separate authorization.

#### ClickOps Implementation

1. Open the gear menu → **Company settings → Apps and integrations → API → API keys**. Inventory Standard and Restricted keys with their owners, purpose, consumers, and expiry. Do not capture token values in review evidence.
2. For an approved new integration, select **+ Create API key → Restricted**. Set a descriptive **Name** and an **Expiration date**; expiration is optional in Zip but recommended by this baseline.
3. For each required record type, choose **Read only** unless an approved write use case requires **Read and write**. Leave unrelated record types blank: blank grants no access. Save the token directly to the approved secret store when the one-time token dialog appears.
4. Set **Restrict access to selected IP groups** using the approved egress groups from §1.8. **Any IP address is the default.** Review this on every Standard and Restricted key; deleting its last IP group reverts the key to any-IP access.
5. Use the key’s edit control to review or adjust its permissions and expiry. Migrate dependent jobs and verify the replacement before deleting an old key. Deletion is immediate and permanent and causes dependent calls to fail with 401.

**Sources:** [API Page](https://docs.ziphq.com/hc/en-us/articles/20210802709275-API-Page), [IP Allowlists](https://docs.ziphq.com/hc/en-us/articles/46225974720795-IP-Allowlists), [API authentication and key administration](https://developers.ziphq.com/zipapidocs/docs/rest-api-info-authentication-api-key-creation-and-webhooks), [Getting Started](https://developers.ziphq.com/zipapidocs/docs/getting-started), and [Versioning](https://developers.ziphq.com/zipapidocs/docs/versioning).

**Automation:** ClickOps is documented. The reviewed OpenAPI exposes no API-key inventory, restriction, expiry, or revocation operation. The native collectors consume an existing restricted key; a successful GET does not prove its permission scope or expiration. Other administrative automation surfaces remain unverified.

#### Validation & Testing

**Expected result:** each integration has a reviewed restricted credential, justified read/write grants, owner, expiry, and tested replacement procedure. In an authorized non-production test, confirm the required read succeeds and an unrelated operation is denied without altering business records. Never use a real purchase/payment mutation as a permission probe.

#### Monitoring & Maintenance

Review credential ownership, scope, IP restrictions and expiry regularly and before integrations change. Alert before expiration; revoke exposed credentials through the documented UI after dependent systems are safely migrated.

#### Operational Impact

Expiry or deletion interrupts jobs. Do not recreate Standard keys to work around a permission failure. API version/authentication compatibility must be verified; these packs intentionally use the documented legacy API-key mode.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |
| SOC 2 | Logical access, change management, and monitoring objectives; assess applicable criteria with the auditor |
| ISO/IEC 27001:2022 | Identity, access-rights, information-transfer, and logging objectives; confirm applicability in the statement of applicability |

---

### 2.3 Limit Webhook Destinations and Events

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-4, AC-6, SC-8 |

#### Description

Keep webhook destinations on an approved HTTPS endpoint list and subscribe only to necessary events. Documented webhook payloads can contain entire procurement objects; subscribing to fewer events is not field-level redaction.

#### Rationale

**Why This Matters:**
- A mistyped or compromised destination can disclose request, vendor or invoice information.
- Webhook payloads are not sufficient authority for mission-critical actions.

**Attack Prevented:** Unapproved procurement-data disclosure and actions based solely on unverified event payloads.

#### Prerequisites

Administrator or **Manage company webhook settings** permission, approved destination owner and data handling, and an incident-response contact for the receiver.

#### ClickOps Implementation

1. Open the gear menu → **Company settings → Apps and integrations → API → Webhooks**. Review every **Target URL** and subscribed event against the approved destination list.
2. When adding an authorized integration, use **+ Create webhook**, an approved HTTPS URL, and only the required **Select events** choices. An event such as request.submitted sends the entire request object; approve that data transfer before configuration.
3. Use each row’s edit control to correct the target or event selection. Delete only approved retired configurations; deletion is immediate and permanent.
4. At the receiving application, authenticate/reconcile mission-critical information by reading the current object through an independently authenticated, least-privileged Zip API request. Zip explicitly recommends API re-fetching rather than relying solely on webhooks. No signing-header or HMAC contract was established in the reviewed guides; do not invent one or describe unverified payloads as authenticated.

**Sources:** [API Page](https://docs.ziphq.com/hc/en-us/articles/20210802709275-API-Page) and [Webhook configuration](https://developers.ziphq.com/zipapidocs/docs/rest-api-info-authentication-api-key-creation-and-webhooks) and [Webhook Events](https://developers.ziphq.com/zipapidocs/docs/webhooks).

**Automation:** ClickOps is documented for webhook settings. No webhook-management or signature-verification operation appears in the reviewed OpenAPI. Receiver implementation, retention and alerting are deployment-specific; no invented signature validator or generic configuration file is supplied.

#### Validation & Testing

**Expected result:** a harmless, approved test event reaches only the intended receiver; unused event types are not subscribed. Verify the receiver rejects untrusted inputs and re-fetches current records before consequential processing. Do not send real payment or supplier data to an unapproved test endpoint.

#### Monitoring & Maintenance

Repeated delivery failures can automatically disable a webhook endpoint. Alert on receiver failures and reconcile endpoint status; updating the Target URL can re-enable it, so do not treat a cosmetic URL edit as inert.

Review after destination ownership, integration, or event-catalog changes. Monitor failed deliveries through the actual receiver tooling; delivery retry/retention guarantees are not established here.

#### Operational Impact

Changing URLs or deleting subscriptions can disrupt business automations. Restore only the approved destination and events if rollback is required.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-4, AC-6, SC-8 |
| SOC 2 | Logical access, change management, and monitoring objectives; assess applicable criteria with the auditor |
| ISO/IEC 27001:2022 | Identity, access-rights, information-transfer, and logging objectives; confirm applicability in the statement of applicability |

---

### 2.4 Review Approval Delegations

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-5, AC-6 |

#### Description

Reconcile active and upcoming approval delegations with approved leave dates and substitute approvers. Delegations transfer approval responsibilities; the API’s current-state filter includes future delegations as well as active ones.

#### Rationale

**Why This Matters:**
- An unreviewed delegate can inherit consequential approval work.
- Organization-scoped API keys have no implicit current-user boundary for delegation changes.

**Attack Prevented:** Unexpected approval reassignment and stale delegation authority.

#### Prerequisites

The delegation feature enabled for the organization, read-only access for delegation records, and an approved leave/delegation register. The documented 405 response means the feature is not enabled, not a passing empty inventory.

#### ClickOps Implementation

1. Open **Company settings → Out of office delegations** using the applicable administration permission (**Manage company out of office delegations**, or the corresponding advanced **Access all out of office delegations** setting).
2. **Allow users to set personal out of office delegations is on by default.** Turn it off where central approval is required. **Only allow delegating to users of the same or higher level is off by default**; enable it where the approved hierarchy governs substitutes.
3. Verify hierarchical roles first. Users without a role can still delegate to any active user. When roles contain multiple levels or users hold multiple roles, Zip uses the highest level. The toggle alone is not proof of separation of duties.
4. Reconcile **All delegations → Current** (active and future) and **Past** with the approved register. Review the delegate, dates, timezone, creator, and notes. Use **… → Delegation settings audit trail** for configuration changes.
5. Plan remediation carefully. **+ Add delegation** and **Remove delegation** affect tasks, approvals, and three-way-match receiving obligations. Creating a current delegation can reassign pending work and notify the delegate; removing one takes effect immediately. Do not automatically delete records based on aggregate findings.

**Sources:** [Out of Office Delegations Page](https://docs.ziphq.com/hc/en-us/articles/21484342605211-Out-of-Office-Delegations-Page), [advanced permissions](https://docs.ziphq.com/hc/en-us/articles/18921746955035-Permission-Settings-and-Groups), [delegation API guide](https://developers.ziphq.com/zipapidocs/docs/ooo-delegation-api-developer-guide), and [search delegations](https://developers.ziphq.com/zipapidocs/reference/searchdelegations).

#### Code Implementation

This collector requests current delegations with `is_active=true`, summarizes ACTIVE/UPCOMING and date-quality evidence, and never creates, updates or deletes a delegation. Expired records are outside this query’s scope. Review delegation duration against organizational policy; the pack does not impose a vendor maximum.

{% include pack-code.html vendor="ziphq" section="2.4" %}

#### Validation & Testing

**Expected result:** every current or upcoming delegation matches a documented business approval and dates. Use an approved non-production delegation test to verify the actual routing, hierarchy policy and expiry behavior. Counts, a 405 response, or no returned records do not certify separation of duties.

#### Monitoring & Maintenance

Review before leave begins, after end dates, and after changes to approval ownership. Investigate unexpected statuses or missing dates without automatically deleting delegations.

#### Operational Impact

Review is read-only. Delegation changes can reassign in-flight approvals and trigger notifications; preserve the prior routing and have the approval owner approve any remediation.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-5, AC-6 |
| SOC 2 | Logical access, change management, and monitoring objectives; assess applicable criteria with the auditor |
| ISO/IEC 27001:2022 | Identity, access-rights, information-transfer, and logging objectives; confirm applicability in the statement of applicability |

---

### 2.5 Review Queue Approval Visibility

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-4, AC-6 |

#### Description

Review queue owners, members, approval visibility and notification scope against the intended approval audience. Limit access and notifications to the people who need them, while preserving the workflow's approved operating model.

#### Rationale

**Why This Matters:**
- Broad queue membership can expose procurement approvals beyond their intended audience.
- Visibility and notification flags are separate settings; one does not establish the other.

**Attack Prevented:** Unintended disclosure and completion of approvals by excess queue participants.

#### Prerequisites

An approved queue inventory and audience, read-only access to the requested queue, and its exact UUID. There is no global queue-list GET in the reviewed API; IDs discovered through user or approval records do not guarantee complete coverage.

#### ClickOps Implementation

1. Open **Company settings → Queues**, then the intended **Queue details** page. Older developer navigation groups it under **Departments & Queues**. Review owners, members, default assignee, and group email.
2. **All queue members can view approvals is on by default.** It also allows any member to complete any approval in the queue, even if assigned to another person. Disable it for queues requiring individual assignment boundaries, and test the resulting review process.
3. **All queue members will receive approval notifications is off by default.** Review it separately from visibility. A configured group email is copied on new requests; validate the external alias membership, not just Zip members.
4. Queue owners can edit properties and membership. Restrict ownership, review subqueues because their settings override the parent, and preserve intended first-match versus every-matching-subqueue routing.
5. Open **… → View audit trail**. When a different member completes an approval, Zip reassigns it to that person and logs the change; bill audit detail is less complete. Do not infer the original assignee was the completing actor from a static API record.

**Sources:** [Queues](https://docs.ziphq.com/hc/en-us/articles/19202122220315-Queues), [queue event logs](https://developers.ziphq.com/zipapidocs/docs/queue-record-event-logs), [get queue](https://developers.ziphq.com/zipapidocs/reference/getqueuebyid), and [update queue](https://developers.ziphq.com/zipapidocs/reference/updatequeuebyid).

#### Code Implementation

The collector reads one explicit queue UUID and reports scoped owner/member counts and visibility/notification flags. Null or missing flags are unknown. It verifies the returned ID matches the requested queue and does not claim global discovery or disclose identities or group email addresses. The documented PATCH supports both flags and memberships, but this review pack does not choose the organization's intended audience or write policy. Remediation needs a reviewed tenant-specific target and rollback plan.

{% include pack-code.html vendor="ziphq" section="2.5" %}

#### Validation & Testing

**Expected result:** the requested queue's owner/member population and each flag agree with the approved audience and notification policy. With authorized non-production accounts, verify the intended assignee can review and complete the expected approval while a non-assigned member cannot do so when individual assignment is required. Also test an unrelated person cannot see it. Counts cannot prove which people are members; reconcile identities privately in the console. Zero members, missing fields or a 404 are not a passing control.

#### Monitoring & Maintenance

Review after queue ownership, membership and workflow changes. Reconcile the complete administrator-maintained queue inventory separately; a successful single-queue query does not establish tenant-wide coverage.

#### Operational Impact

The collector is read-only. Removing members or narrowing visibility/notifications can interrupt approvals, so coordinate any change with the workflow owner. The documentation contains inconsistent assignment-logic descriptions; this pack does not reinterpret or change that setting.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-4, AC-6 |
| SOC 2 | Logical access and information-transfer objectives; assess applicable criteria with the auditor |
| ISO/IEC 27001:2022 | Access-rights and information-transfer objectives; confirm applicability in the statement of applicability |

---

### 2.6 Restrict Scheduled Exports and SFTP

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-4, AC-6, SC-8, SC-28 |

#### Description

Review export recipients and editor rights independently from source-record permissions. Encrypt sensitive flat-file transfers and verify the intended server identity.

#### Rationale

**Why This Matters:**
- Scheduled exports can be delivered to users who cannot view the underlying records in Zip.
- Sharing an export profile grants editing, not merely viewing.

**Attack Prevented:** Bulk data disclosure through scheduled reports, unapproved recipients, or an unverified transfer destination.

#### Prerequisites

Export administrator with **View Insights dashboard** and relevant data access; **Access all saved exports** for organization-wide review. SFTP requires applicable Premier/contract entitlement. The **Import and export settings** tab requires Edit **View or edit all data imports** and Edit **Access general settings**.

#### ClickOps Implementation

1. Open **Insights → Exports** and review saved schedules, recipients, selected fields, and **Share with** editors. Use **All saved exports** where entitled, including exports owned by deactivated users. Do not assume recipient permissions filter delivery: **any selected user may receive a scheduled export regardless of permissions**.
2. Remove unnecessary fields and recipients. Email delivery provides a link to an **unencrypted CSV**, so approve its audience and handling explicitly.
3. Open **Company settings → Imports and exports → Import and export settings**. Configure approved recipient defaults, but remember each export can override them. For SFTP, use approved key-based authentication, verify the server fingerprint when supported, and configure **PGP** using the recipient's public key. Never upload private decryption keys as the encryption key.
4. Distinguish alert paths: **SFTP alert settings** subscribers also need **Personal settings → Notifications → SFTP error alert** for scheduled **import** failure notices. External **export** failure notices instead go to the user who saved the export. Keep that owner active and test each applicable delivery path separately.
5. Coordinate PGP with **imports as well as exports**. Once enabled, import files must be encrypted for both Zip’s public key and your public key; existing plaintext-import jobs need an approved migration. Exports use your public key. Treat PGP rotation as a data-lifecycle change: changing/disabling PGP affects future files only; old files require the old private key. Protect historical decryption access according to retention policy.
6. Review **Apps and integrations → Native integrations → Data warehouse sharing** separately. It transfers full object/custom-field datasets to Snowflake or Databricks, on a documented twelve-hour refresh. Restrict downstream access; do not assume Zip UI permissions become warehouse row-level policies.

**Sources:** [Creating Custom/Saved Reports](https://docs.ziphq.com/hc/en-us/articles/17441961704091-Creating-Custom-Saved-Reports), [Imports and Exports](https://docs.ziphq.com/hc/en-us/articles/49955438054299-Imports-and-Exports-Page), and [Data Warehouse Sharing](https://docs.ziphq.com/hc/en-us/articles/31336577028123-Data-Warehouse-Sharing).

**Automation:** The authenticated OpenAPI specification (102 paths, 159 operations) reviewed on 2026-11-08 does not expose this administrative setting. No first-party CLI, SDK, or native policy-file contract was verified. Use the documented UI and retain protected review evidence; do not invent a settings endpoint.

#### Validation & Testing

**Expected result:** a synthetic export contains only approved columns and reaches only approved recipients/server. Verify encryption with the intended recipient key, failure alerts, and an unauthorized user’s inability to edit schedules. Review downstream warehouse grants separately; do not export real sensitive data as a test.

#### Monitoring & Maintenance

Review schedules, editors, recipients, departed owners, SFTP trust/fingerprints, PGP key lifecycle, and warehouse access quarterly.

#### Operational Impact

Removing a server breaks dependent exports; enabling PGP also changes inbound-import handling, and rotating it without preserving old keys can make historical data unreadable. Coordinate approved delivery changes with report consumers.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-4, AC-6, SC-8, SC-28 |
| SOC 2 | Logical access, change management, confidentiality, and monitoring objectives; assess applicable criteria with the auditor |
| ISO/IEC 27001:2022 | Access control, information transfer, and operations-security objectives; confirm applicability in the statement of applicability |

---

### 2.7 Review Enterprise Key Management

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | SC-12, SC-13, SC-28, AU-9 |

#### Description

Where contracted and justified, use Zip Enterprise Key Management with customer-controlled AWS KMS keys and independently retained CloudTrail evidence. This is optional key custody, not an assertion that every Zip data field uses customer-managed encryption.

#### Rationale

**Why This Matters:**
- Default AWS-generated cross-account key policies may grant more than Zip requires.
- Replica policies and availability are separate responsibilities; key rotation does not revoke overly broad access.

**Attack Prevented:** Overbroad encryption-key access and loss of independent key-use visibility.

#### Prerequisites

Zip EKM entitlement, support-led enrollment and required legal acknowledgments, an AWS owner, regionality/availability plan, and a designated onboarder with Edit **Access all security settings**. Account creation, grants, agreements, and activation require their applicable approvals.

#### ClickOps Implementation

1. Begin enrollment with Zip and confirm the **designated onboarder**, deployment region, and data coverage. Do not activate from an unsolicited account or change key custody without legal/security approval.
2. In AWS KMS, prepare a **Symmetric**, **Encrypt and decrypt**, **KMS-origin**, **Multi-Region** key. Use its immutable key ARN, not an alias. The guide recommends us-east-2 for North America and eu-central-1 for Europe.
3. Review the key policy against the vendor's published principal and minimum cryptographic permissions: Zip EKM account **242230929264**, with **kms:Encrypt**, **kms:Decrypt**, **kms:ReEncrypt***, **kms:GenerateDataKey***, and **kms:DescribeKey**. Preserve approved customer administration separately. Do not copy the documentation's illustrative JSON comments/trailing commas as valid JSON, or add blanket cross-account kms:*.
4. Ensure the primary key and its replicas together cover the required regions: North America **us-east-1, us-east-2, us-west-1, us-west-2**; EMEA **eu-central-1, eu-west-3**. Confirm the tenant's agreed geography first. AWS does not synchronize replica policies, aliases, descriptions, or tags automatically.
5. After support confirms the onboarder, use **Company settings → Security → Enterprise key management → Add key**. Review the ARN and risks, **Connect**, verify checks, then **Activate key** only with explicit approval and a recovery plan.
6. Configure CloudTrail retention and alerting for KMS management events. Include **All** or **Read-only** management events and ensure KMS events are not excluded. Review grants and IAM/organization policies as well as the key policy; one policy document cannot prove effective access.
7. Enable appropriate KMS rotation and monitor key state. Rotation changes key material but does not fix an overbroad grant or compromised principal. Contact Zip to replace the logical key; do not disable/delete a production key as a test.

**Sources:** [Enterprise Key Management Onboarding](https://docs.ziphq.com/hc/en-us/articles/53342372030491-Enterprise-Key-Management-Onboarding).

**Automation:** The reviewed Zip API exposes no EKM enrollment/settings operation. AWS KMS APIs can collect supporting evidence, but AWS CLI is not a first-party Zip CLI and a key policy alone cannot prove effective access. No mislabeled Zip CLI pack or automated production key grant is supplied.

#### Validation & Testing

**Expected result:** the designated key and each required replica have the intended state, policy and approved access; Zip onboarding verification succeeds; CloudTrail records expected KMS use in protected retention. Record the covered data types and exclusions with Zip. Test key-loss/revocation procedures only in an approved non-production exercise.

#### Monitoring & Maintenance

Monitor key disablement/deletion scheduling, policy/grant changes, regional availability, rotation, and CloudTrail delivery. Reconcile designated onboarder changes with Zip.

#### Operational Impact

Key unavailability can prevent decryption and interrupt service. Legal commitments and key activation are consequential; retain recovery materials and do not assume rotation is rollback.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | SC-12, SC-13, SC-28, AU-9 |
| SOC 2 | Logical access, change management, confidentiality, and monitoring objectives; assess applicable criteria with the auditor |
| ISO/IEC 27001:2022 | Access control, information transfer, and operations-security objectives; confirm applicability in the statement of applicability |

---

## 3. Supplier Account Security

### 3.1 Use Named Supplier Accounts with Authenticator MFA

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2, IA-5 |

#### Description

For the separate Zip Vendor App, register individual work addresses and select authenticator-app MFA where appropriate. Zip requires supplier MFA; this control improves account ownership and recovery rather than claiming a buyer-tenant MFA setting.

#### Rationale

**Why This Matters:**
- Shared accounts weaken attribution and can make recovery impossible when a colleague leaves.
- A personally controlled authenticator avoids dependence on a shared telephone number.

**Attack Prevented:** Shared-login abuse and loss of accountable supplier access.

#### Prerequisites

A legitimate supplier invitation addressed to an individual, not a shared mailbox, and a supported TOTP app. Zip documents that shared-mailbox MFA cannot be reset even by support. TOTP is not phishing-resistant; do not describe it as equivalent to FIDO2.

#### ClickOps Implementation

1. Use an invitation addressed to the individual's work email, select **Get started**, and complete **Create a password**.
2. Choose **Use authenticator app instead**, enroll the authenticator, then complete **Enter code**. Keep enrollment secrets out of screenshots and tickets.
3. Test returning access at the Vendor App using that individual's account. Existing users changing methods must use the documented authenticator-reset process.

**Source:** [Zip Vendor App sign-in](https://docs.ziphq.com/hc/en-us/articles/17459154258715-Signing-In-to-the-Zip-Vendor-App).

**Automation:** ClickOps is the verified implementation surface. The [authenticated OpenAPI specification](https://developers.ziphq.com/zipapidocs/openapi/openapi.yaml), checked 2026-11-08, documents no operation for this setting. Other native automation surfaces remain unverified; no endpoint, CLI, or configuration file is invented.

#### Validation & Testing

Confirm the test account cannot authenticate with only a password. Confirm a legitimate returning login requires the password, registered MFA method, and emailed sign-in link. Do not initiate real recovery just to test it: review the documented identity verification and administrator notification/cancellation process with the supplier administrator.

**Expected result:** The positive and negative cases above match the intended access boundary, with documented exceptions. An unavailable test remains unverified.

#### Monitoring & Maintenance

Review access ownership when supplier staff change. Keep another authorized individual available for continuity. Do not promise an exact recovery SLA because the source gives differing timing descriptions.

#### Operational Impact

Pilot first: changes can delay login, provisioning, notifications, or supplier onboarding. Capture the prior configuration and restore only the affected setting after review. No pack in this guide performs that change.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2, IA-5 |
| SOC 2 | Logical access and monitoring objectives; assess the applicable Trust Services Criteria with the auditor |
| ISO/IEC 27001:2022 | Access control, identity management, and access-rights objectives; confirm applicability in the statement of applicability |

---

### 3.2 Restrict Automatic Supplier Organization Joining

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-3 |

#### Description

At supplier organization onboarding, require direct invitations instead of allowing any matching-domain colleague invited by a customer to join automatically. This setting belongs to the supplier organization, not the buyer procurement tenant.

#### Rationale

**Why This Matters:**
- A matching email domain does not prove the person should see all supplier organization information.
- Independent customer invitations can create unexpected membership paths.

**Attack Prevented:** Unreviewed supplier organization membership.

#### Prerequisites

Supplier organization administrator or **Manage organization email domains and join settings** permission. This is the supplier organization, not the buyer tenant.

#### ClickOps Implementation

1. During supplier organization creation, leave **Let people with (your email domain) email immediately join this organization when invited by a customer** unselected and choose direct invitations.
2. For an existing organization, open the gear menu → **Company settings → Domain permissions**. Turn off **Allow teammates with a matching email domain to join automatically** where direct invitations are required. When enabled, matching-domain users can choose the organization and become Collaborators.
3. Enable **Restrict users with mismatched email domains**, and review **Approved domains for full access**. Use **+ Add domain** only for an explicitly approved exception; a domain match is not independent proof of business need.
4. **Restriction is not a hard block:** a buyer can proceed after the mismatch warning, creating a **Limited collaborator** scoped to that portal and a review banner. Review those exceptions promptly.
5. Existing-customer invitations are a separate joining path. The articles differ on whether the auto-join toggle stops that path, so test both new-customer and existing-customer invitations rather than promising universal denial. Review new members' permission groups under §3.3.

**Sources:** [Vendor App Domain Permissions](https://docs.ziphq.com/hc/en-us/articles/22420879034779-Vendor-App-Domain-Permissions), [Control Who Can Sign Up](https://docs.ziphq.com/hc/en-us/articles/22551265529883-How-Do-I-Control-Who-Can-Sign-Up-to-My-Vendor-Organization), and [Vendor App sign-in](https://docs.ziphq.com/hc/en-us/articles/17459154258715-Signing-In-to-the-Zip-Vendor-App).

**Automation:** the reviewed buyer [OpenAPI specification](https://developers.ziphq.com/zipapidocs/openapi/openapi.yaml) does not expose supplier organization joining settings. No verified native supplier CLI/SDK/policy contract was found; use documented ClickOps.

#### Validation & Testing

With approved non-sensitive test accounts, compare a direct organization invitation with a separate customer invitation. Check the resulting organization and portal-specific permissions. Zip describes a special path for the original customer inviting colleagues to a portal; test that case instead of assuming the setting blocks every invitation.

**Expected result:** The positive and negative cases above match the intended access boundary, with documented exceptions. An unavailable test remains unverified.

#### Monitoring & Maintenance

Reassess domain-based membership after mergers or new subsidiaries. Invite approved members individually if the restriction interrupts onboarding; do not broaden joining merely to bypass a failed test.

#### Operational Impact

Pilot first: changes can delay login, provisioning, notifications, or supplier onboarding. Capture the prior configuration and restore only the affected setting after review. No pack in this guide performs that change.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-3 |
| SOC 2 | Logical access and monitoring objectives; assess the applicable Trust Services Criteria with the auditor |
| ISO/IEC 27001:2022 | Access control, identity management, and access-rights objectives; confirm applicability in the statement of applicability |

---

### 3.3 Restrict Supplier Profile Sharing

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-3, AC-4, AC-6 |

#### Description

Review supplier-administrator grants, profile audiences, private-document inclusion, and access expiry in the Vendor App. Invitations and NDA prompts are not substitutes for minimizing the data shared.

#### Rationale

**Why This Matters:**
- Initial invited users can become organization administrators, and grants combine additively.
- A profile invitation may include General and ESG private documents beyond the apparent public profile.

**Attack Prevented:** Excess supplier administration and unintended external disclosure of profile documents.

#### Prerequisites

Supplier organization administrator; **Share profile with customers** and **Manage shareable profile settings** as appropriate. Inventory approved customer recipients and document classifications. Buyers cannot directly manage the supplier organization's permissions.

#### ClickOps Implementation

1. Review **Company settings → Users and permissions**. First customer-invited/signup teammates can be organization administrators; later invites may receive portal-scoped Collaborator access. Review actual group grants, because broader permission wins across multiple groups. Retain only necessary administrators and individual accounts.
2. Open **Company profile → Share profile** and explicitly select the approved audience: **Anyone with Link**, **Only Customers Who Use Zip**, or **Only People Invited to Profile**. Use **Only People Invited to Profile** for this baseline; document broader public/customer visibility as an explicit disclosure exception. The sharing article contradicts itself about the initial default; do not rely on an assumed default.
3. Review every included document before an explicit invitation. **General and ESG** documents accompany those invites, including **Private until shared** content; **Internal only** documents are excluded. Separate truly internal material rather than assuming a private label blocks an explicit share.
4. Open **Company settings → Company profile** and configure **Profile access expiration** and the responsible **Approval notification group** (initially Org admin). If approved terms are required, use **Add NDA → Save**, enable the NDA toggle (initially off), and require the NDA for the applicable share/request.
5. **Batch NDA limitation:** acceptance by one recipient in a batch satisfies the NDA gate for all recipients in that batch. Do not represent it as individual signature evidence; use separately reviewed invitations or another approved contracting process when individual acceptance is required.
6. Open **Home → Profile shares → All** to review existing shares. For an approved revocation, open the row → **… → Revoke access**. Use **View activity** to inspect profile views/document downloads, and review expired or obsolete customer relationships.

**Sources:** [Vendor Users and Permissions](https://docs.ziphq.com/hc/en-us/articles/17459177145755-Vendor-App-Users-and-Permissions), [sharing a profile](https://docs.ziphq.com/hc/en-us/articles/22448769849883-How-Do-I-Share-a-Vendor-Profile), [profile settings](https://docs.ziphq.com/hc/en-us/articles/24191948992667-Vendor-App-Company-Profile-Settings), and [Vendor Home](https://docs.ziphq.com/hc/en-us/articles/22417672571547-Vendor-App-Home-Page).

**Automation:** The authenticated OpenAPI specification (102 paths, 159 operations) reviewed on 2026-11-08 does not expose this administrative setting. No first-party CLI, SDK, or native policy-file contract was verified. Use the documented UI and retain protected review evidence; do not invent a settings endpoint.

#### Validation & Testing

**Expected result:** a synthetic profile/document share reaches the intended test recipient only, obeys the chosen visibility/expiry, and excludes Internal only content. For invitation-only visibility, verify an uninvited account and revoked recipient cannot access the profile. If broader visibility is an approved exception, separately test those public/customer paths: revoking an individual share does not prove all access is removed. Record batch-NDA behavior rather than asserting separate signatures. Do not test with real restricted documents.

#### Monitoring & Maintenance

Review administrator groups, domain exceptions, active shares, expiry and download activity quarterly and when supplier/customer contacts change. An already downloaded file cannot be recalled by revoking a link.

#### Operational Impact

Narrower sharing and expiry can interrupt customer due diligence. Coordinate approved recipients and renewal of access without expanding to Anyone with Link as a workaround.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-3, AC-4, AC-6 |
| SOC 2 | Logical access, change management, confidentiality, and monitoring objectives; assess applicable criteria with the auditor |
| ISO/IEC 27001:2022 | Access control, information transfer, and operations-security objectives; confirm applicability in the statement of applicability |

---

## 4. Monitoring & Detection

### 4.1 Monitor Provisioning Failures and Access Changes

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6, CA-7 |

#### Description

Monitor the Entra provisioning integration and assigned population for drift. Identity-provider telemetry supplements, but does not replace, Zip buyer audit logs or procurement approval evidence.

#### Rationale

**Why This Matters:**
- A disconnected provisioning job can leave departed users active.
- A healthy connection test does not establish successful lifecycle processing.

**Attack Prevented:** Persistent stale access after unnoticed synchronization failures.

#### Prerequisites

Access to the Zip enterprise application provisioning status/logs and an operational owner for alerts. Native Zip audit evidence is covered separately in §4.2.

#### ClickOps Implementation

1. Open **Entra ID → Enterprise apps → Zip → Provisioning**, then **Provisioning logs** to examine failed and skipped events.
2. Confirm notification email and accidental-deletion protection remain configured in the provisioning properties.
3. Review provisioning progress/status alongside the access-assignment review in §1.2. Investigate unexpected changes, quarantine, or paused jobs.

**Source:** [Zip provisioning monitoring](https://learn.microsoft.com/en-us/entra/identity/saas-apps/zip-provisioning-tutorial).

**Automation:** The read-only §1.4 job collector supplies Entra job state, not Zip audit events or alert delivery. Use §4.2 for the documented native audit API. Retention guarantees and a deployed SIEM mapping remain unverified.

#### Validation & Testing

Use a planned test-account lifecycle change and confirm it appears in the provisioning logs with the expected outcome. Verify the responsible team can see the failure path without breaking production synchronization. Reconcile the observed Zip account state with the event, not just the job status.

**Expected result:** The positive and negative cases above match the intended access boundary, with documented exceptions. An unavailable test remains unverified.

#### Monitoring & Maintenance

Review each provider’s **Security → Identity providers → View SCIM logs** promptly: current Help/release notes describe only the latest 2,000 syncs over three days. Preserve approved evidence elsewhere when longer retention is required. **Security Notifications** accepts up to five addresses, but the Security Page says those addresses are not currently used; do not claim this config delivers alerts.

Investigate failures daily; retain evidence under the organization's retention policy. Use §4.2's documented event catalog and export boundary; verify retention, entitlement, and downstream schema before deploying a SIEM rule.

#### Operational Impact

Pilot first: changes can delay login, provisioning, notifications, or supplier onboarding. Capture the prior configuration and restore only the affected setting after review. No pack in this guide performs that change.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6, CA-7 |
| SOC 2 | Logical access and monitoring objectives; assess the applicable Trust Services Criteria with the auditor |
| ISO/IEC 27001:2022 | Access control, identity management, and access-rights objectives; confirm applicability in the statement of applicability |

---

### 4.2 Collect Native Audit Evidence

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-2, AU-6, AU-9, CA-7 |

#### Description

Use the documented native event-log API to review a bounded period of authentication, user-access, approval/workflow, integration, and payment-configuration activity. The pack returns privacy-minimized counts, not a complete forensic export or deployed SIEM pipeline.

#### Rationale

**Why This Matters:**
- IdP provisioning logs cannot show all native procurement changes.
- Audit payloads can contain personal data, arbitrary record details, and an ambiguously described api_key field that should not be echoed.

**Attack Prevented:** Undetected native access, workflow and integration changes, and over-disclosure of collected evidence.

#### Prerequisites

Zip Premier is required for audit-event export. Use an existing restricted API credential with the necessary read-only record access, an approved review period, and an authorized evidence owner. Retention and downstream SIEM mappings must be verified separately.

#### ClickOps Implementation

1. To review workflow changes in the UI, open the gear menu → **Company settings → Workflows**, open the workflow editor and select **Change history**.
2. For a supported connector, open **Company settings → Integrations → relevant type → connector → Configure** and use the triple-dot menu beside the master sync button → **View audit trail**. The exact connector layout varies; the documented example is NetSuite.
3. Review native authentication events (LOGIN_SUCCESS, LOGIN_FAILURE, LOGIN_RESULT_UNKNOWN, LOGOUT_SUCCESS), user status changes, approval/condition/dependency changes, and relevant bank/payment-method events against expected activity. The API event catalog documents these events; it does not promise every failed operation or all historical data is retained.
4. Store any separately authorized raw investigation evidence in a restricted system. Do not put response bodies, api_key, actor names, IPs, free-text descriptions, or data objects into public issues or CI logs.

**Sources:** [Audit extraction](https://developers.ziphq.com/zipapidocs/docs/use-case-extract-audit-trail-events), [audit endpoint](https://developers.ziphq.com/zipapidocs/reference/queryauditlogs), [authentication events](https://developers.ziphq.com/zipapidocs/docs/user-authentication-record-event-logs), [workflow history](https://developers.ziphq.com/zipapidocs/docs/workflow-config-record-event-logs), and [integration history](https://developers.ziphq.com/zipapidocs/docs/integration-configuration-record-event-logs).

#### Code Implementation

Require an explicit finite epoch-second start and end. The collector follows opaque pagination tokens while retaining the same time filters. It does not use `total` as an exact count: Zip documents that audit `total=10000` means at least 10,000. Missing actor data remains unknown; an MCP-channel event with a visible human creator resolves as USER, so MCP counts are not a complete count of MCP-channel activity.

{% include pack-code.html vendor="ziphq" section="4.2" %}

#### Validation & Testing

**Expected result:** a known harmless test event appears in the reviewed time range and the operator can reconcile the relevant event counts with the source audit trail. Unknown fields and zero events remain unverified. Demonstrate pagination and failure handling with offline fixtures before any authorized live rollout; an interrupted or capped collection must not be reported as complete.

#### Monitoring & Maintenance

Use **Users and permissions → … → View permissions audit trail** and **Export permissions audit package** to review both grants and membership changes. The latter is described as Premier in user administration and as requiring optional Advanced Controls & Auditability for some features in Audit Readiness: verify the actual entitlement. Export formats and default selections can include broad user/permission/document data; minimize recipients and fields. Request audit packages default to all items selected and cover purchase requests, not every request type. See [Audit Readiness](https://docs.ziphq.com/hc/en-us/articles/17459193825435-Audit-Readiness).

Review high-risk native changes at an organizationally appropriate cadence. Check for new event types and API-version changes, and separately verify retention, ingestion completeness and incident-response ownership.

#### Operational Impact

GET requests do not change records but consume API quota and process potentially sensitive responses. The documented rate limit is 150,000 requests per day per API key. On 429, stop and retry later under an approved schedule rather than collecting unbounded data.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-2, AU-6, AU-9, CA-7 |
| SOC 2 | Logical access, change management, and monitoring objectives; assess applicable criteria with the auditor |
| ISO/IEC 27001:2022 | Identity, access-rights, information-transfer, and logging objectives; confirm applicability in the statement of applicability |

---

## 5. Workflow and Payment Safety

These controls are based on authenticated product documentation, not live tenant testing. Configure only the workflows and modules your organization uses. The stricter settings below are HTH recommendations; optional products, backend-enabled behavior, and existing requests require separate validation.

### 5.1 Enforce Independent Sequential Approvals

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-5, AC-6, CM-3 |

#### Description

Make sensitive approvals independent of the requester and complete them in the intended order. Require authenticated, manual decisions for financial and access-sensitive gates, and prevent approval-group optimizations or delegation from silently removing the required separation of duties.

#### Rationale

**Why This Matters:**
- Diagram order alone does not prevent an assigned user from starting a later approval.
- Self-approval, shared queue completion, approval collapsing, and automatic completion can defeat an apparently multi-person chain.
- No-login notifications weaken the assurance provided by workforce sign-in controls.

**Attack Prevented:** Self-authorized procurement, premature approval, and misuse of delegated or notification-based approval authority.

#### Prerequisites

A workflow editor with **Access workflows** edit access or the applicable **View or edit all workflows** permission, an approved separation-of-duties matrix, independent reviewers, and isolated test destinations. Review queue and out-of-office permissions in §§2.4–2.5 before changing routing.

#### ClickOps Implementation

1. Open the gear menu → **Company settings → Workflows**, select the relevant workflow, and open each sensitive approval's **Edit approval** panel. Under **Assignment**, enable **Assign to manager if requester and approver are the same** where offered. For hierarchical roles that must always receive an independent decision, enable **Assign to manager if requester’s approval limit is not exceeded**. Verify an actual manager and appropriate approval limit exist.
2. In the approval settings, enable **Require prior steps to be completed before this approval can be initiated**. Select **Require manual approval** for sensitive gates. Mark mandatory subtasks **Required**, and document the administrator override as an exception path, not an enforced two-person boundary.
3. Under notification settings, turn **Allow no-login approval/rejection via notifications** off, save the change, and **Publish** the workflow. Where reviewers must inspect request context in Zip, enable **Disable approve and reject buttons on notifications**. Review included fields and attachment recipients before distributing sensitive request data.
4. Inspect the containing approval group and workflow diagram. Add the approval to a group and connect it to the intended chain. Do not use **Collapse same person** or **Highest priority only** for approvals that must remain independent. Multiple IF conditions are OR conditions; express and test the intended combined condition rather than assuming AND.
5. Keep rejection from proceeding through a critical gate. Review rejection/finalization choices and test newly created as well as existing steps: these choices are captured when a step is created. Preserve the finalization action/group required by the workflow.
6. In **Company settings → Queues**, review the queue's members, owners, subqueues and completion policy. **All queue members can view approvals** also lets a member complete an approval assigned to a colleague. Restrict that behavior where distinct named approvers are required, and use §2.5 for the detailed queue review.

**Documented defaults:** the two manager-routing options and prior-step requirement are off. **November 2026 change:** [release notes](https://docs.ziphq.com/hc/en-us/articles/57263347793947-November-2026-Product-Updates) enable no-login email/Slack approval and rejection by default for new and existing approvals, superseding older articles that say off. Microsoft Teams organizations are excluded from that change. Disable the option in a workflow draft, save, and **Publish**; only the assigned approver can use the no-login action, but this is not equivalent to requiring a current authenticated Zip session. Manual approval is selected by default. Required subtasks are off until enabled. Queue-wide viewing/completion is on by default. A request above the highest hierarchical limit can become unassigned; that is not a working escalation route.

**Sources:** [Approvals](https://docs.ziphq.com/hc/en-us/articles/17459136461851-Approvals), [Approval Groups](https://docs.ziphq.com/hc/en-us/articles/17459136581019-Approval-Groups), [Approval Flexibility](https://docs.ziphq.com/hc/en-us/articles/34155083912859-Approval-Flexibility), [Updating Approvals and Actions](https://docs.ziphq.com/hc/en-us/articles/17459142629403-Updating-Approvals-and-Actions), [Queues](https://docs.ziphq.com/hc/en-us/articles/19202122220315-Queues), and [Approvals Via Email](https://docs.ziphq.com/hc/en-us/articles/17459178849563-Approvals-Via-Email).

**Automation:** Manual UI configuration for approval routing, sequencing and notification approval policy. The [authenticated OpenAPI specification](https://developers.ziphq.com/zipapidocs/openapi/openapi.yaml), reviewed 2026-11-08, documents no operation for configuring these policy settings. Record transitions and evidence collectors are not policy enforcement. Other native automation surfaces remain unverified; see the [source and automation census](/research/ziphq-source-coverage/).

#### Validation & Testing

Use approved non-production examples for requester-equals-approver, below-limit, above-highest-limit, multi-condition, queue-member, delegated-user and rejected-step cases. Attempt to start the later approval before its prerequisite, and verify that the intended independent person must decide. Check both notification and in-app routes. Record actual assignment and completion actors rather than treating current assignee as proof of who approved.

**Test-request warning:** the Workflow Versioning **Test request** feature can send notifications, execute integration subtasks and trigger webhooks. It is not an inert sandbox. Isolate recipients and integration destinations before any authorized test. No such test was performed for this guide.

**Expected result:** legitimate requests reach the intended independent reviewers; self-approval, premature initiation and unauthenticated notification approval fail where prohibited. Unassigned requests, administrative overrides and unsupported combinations remain explicit exceptions, not passes.

#### Monitoring & Maintenance

Review workflow history, queue membership, delegation changes and manual reassignment monthly and after organizational changes. Investigate skipped/collapsed approvals and any required-subtask override. Re-test sensitive routes after editing approval groups or hierarchy limits.

#### Operational Impact

Stricter sequencing increases review time and can expose missing managers or empty queues. Stage changes with an available independent reviewer. If routing stalls, repair the assignment or restore the reviewed prior workflow configuration; do not globally enable self-approval or no-login decisions as a workaround. Existing steps may retain earlier rejection behavior.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-5, AC-6, CM-3 |
| SOC 2 | Authorization, separation of duties and change-management objectives; assess applicable Trust Services Criteria with the auditor |
| ISO/IEC 27001:2022 | Access-rights, information-transfer, change-management and logging objectives; confirm applicability in the statement of applicability |

---

### 5.2 Protect Payment Method Changes

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-5, AC-6, SI-10 |

#### Description

Require an independent review before a new vendor payment method can be used, route that review to an owned queue, and verify bank changes through an established contact. Govern payment methods separately from ordinary vendor-update workflows.

#### Rationale

**Why This Matters:**
- Internal payment-method approval is off by default, and an enabled switch without a queue creates unassigned approvals without notifications.
- Vendor Update workflows exclude payment methods, so a generic vendor-change approval does not protect bank details.
- Bank verification is advisory and cannot replace approval or trusted-contact confirmation.

**Attack Prevented:** Business-email-compromise payment diversion, self-approved bank changes, and unauthorized use of new payee details.

#### Prerequisites

The applicable payment-management entitlement; authorized access to **Access all vendor payment methods and tax information**; an independently staffed payment-method queue; and an approved process for confirming changes through previously established contact information. Bank Account Verification and its coverage are optional paid capabilities, not prerequisites for the core approval control.

#### ClickOps Implementation

1. Open **Company settings → Vendor management → Payment method settings**. Enable **Internal payment method approval**, which is off by default. Select an active **Payment method approval queue** and verify its members, owners, notification coverage and independence from the people entering bank details.
2. Separate bank-detail editing from payout approval through permission groups and queue membership. Review who can access the payment-method page and invoice-level payment-method controls; a queue label alone does not establish exclusive approval authority.
3. Review **Supporting documentation**. Require the evidence your policy needs, accounting for the documented internal-user ability to provide a comment instead of an uploaded document. Do not assume paper-check evidence is mandatory: its requirement is off by default.
4. If using a **Payment method collection** workflow, open it under **Company settings → Workflows**. Keep its required vendor-portal profile and configure its dedicated review chain. Only one such workflow can be active; its approvals do not simply inherit the global queue. If both a bank letter and voided check are required, add both portal requirements and assign the **Confirm vendor payment method** approval.
5. For each new or changed bank instruction, confirm it with a previously established vendor contact through a trusted channel. Do not use a phone number supplied only in the change request. Review any available bank-verification result but maintain the independent gate when verification returns no data, is unavailable or is still pending.
6. Review the vendor record's **Payment methods** history for edits, reactivation, vendor deletion and draft changes. Document these separately from the Vendor Update workflow, which also excludes internal-owner and vendor-contact changes.

**Boundary:** with internal approval enabled, newly added methods are pending and cannot be selected for Procure-to-Pay bills; the person who added the method cannot approve it. Confirm behavior for edits/reactivation and each collection route rather than extrapolating the new-method rule. Bank verification is business-account-only, can take up to five days, has coverage limits and is nonblocking.

**Sources:** [Payment Method Settings Page](https://docs.ziphq.com/hc/en-us/articles/17459152993179-Payment-Method-Settings-Page), [Creating a Payment Method Collection Workflow](https://docs.ziphq.com/hc/en-us/articles/17459125521563-Creating-a-Payment-Method-Collection-Workflow), [Vendor Record - Payment Methods Page](https://docs.ziphq.com/hc/en-us/articles/17459123695387-Vendor-Record-Payment-Methods-Page), [Vendor Bank Account Verification](https://docs.ziphq.com/hc/en-us/articles/33746052691867-Vendor-Bank-Account-Verification), [Vendor Updates Overview](https://docs.ziphq.com/hc/en-us/articles/41345981636635-Vendor-Updates-Overview), and [Fraud Prevention Best Practices](https://docs.ziphq.com/hc/en-us/articles/34741056886427-Fraud-Prevention-Best-Practices).

**Automation:** Manual UI configuration for payment-method approval policy and required supporting evidence. The [authenticated OpenAPI specification](https://developers.ziphq.com/zipapidocs/openapi/openapi.yaml), reviewed 2026-11-08, documents no operation for configuring these policy settings. Record transitions and evidence collectors are not policy enforcement. Other native automation surfaces remain unverified; see the [source and automation census](/research/ziphq-source-coverage/).

#### Validation & Testing

In an explicitly approved isolated setup, test an internal new method, vendor-entered method, invoice-level entry, edit and reactivation. Verify the actual queue receives the task, the maker cannot perform the prohibited approval, and the method remains unavailable until the required independent decision. Use approved test data; do not supply real bank details or initiate a payment merely to test the workflow.

**Expected result:** legitimate reviewed methods become usable only after their required review; unauthorized makers and unapproved methods are blocked on the tested paths. Missing queue notifications, a no-data bank check or an uncovered edit path are failures/gaps, not evidence of safe payment routing.

#### Monitoring & Maintenance

Review payment-method and bank-configuration changes, queue membership and unassigned/pending tasks daily or at the organization's payment-run cadence. Reconcile approved changes with the ERP because some Zip payment-method edits do not automatically sync there.

#### Operational Impact

Independent review can delay invoice processing. Keep a documented reviewer backup without allowing the maker to become the checker. **Deactivation is not payment cancellation:** already scheduled or started payouts can continue. Investigate those separately through the approved incident process. Restoring an earlier method or queue configuration is not proof that outstanding payments were stopped.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-5, AC-6, SI-10 |
| SOC 2 | Authorization, separation of duties and input-validation objectives; assess applicable Trust Services Criteria with the auditor |
| ISO/IEC 27001:2022 | Access-rights, information-transfer, change-management and logging objectives; confirm applicability in the statement of applicability |

---

### 5.3 Enforce Bill and Payout Segregation

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-5, AC-6, SI-10 |

#### Description

Require independent bill and payout approvals across the ingestion paths the organization actually uses. Configure receiving and matching exceptions to reach a blocking review rather than relying on nonblocking warnings or a single Inbox-specific switch.

#### Rationale

**Why This Matters:**
- A coded bill with no assigned approver can be automatically approved.
- CSV/API source conditions can deliberately omit bill approvals, and missing requester data can skip hierarchical routing.
- Duplicate and match indicators do not all block processing, and bill approval is separate from payout approval.

**Attack Prevented:** Unreviewed invoice-to-payment progression, invoice-coder self-approval, and fraudulent or mismatched invoices bypassing the intended review chain.

#### Prerequisites

An active Payments workflow, authorized workflow-edit access, separate invoice-coder/bill-approver/payout-approver responsibilities, and an inventory of Inbox, CSV, XML and API ingestion routes. Restrict **Edit fields after bills are coded** and related bill-edit permissions to reviewed exception users.

#### ClickOps Implementation

1. Open **Company settings → Workflows** and select the active **Payments workflow**. Only one can be active. In **Bill approvals → Settings**, enable **Require bill approver(s)** and **Enforce invoice coder is not an approver**. Consider **Require comment when rejecting a bill, credit, or deposit** for an accountable rejection process. Do not infer these switches are already enabled.
2. Review each **Bill approvals** condition, approval and approval group. Remove unintended **Source (Bill)** exclusions for CSV imports or API records. **Require bill approver(s)** applies to Inbox-created/submitted invoices, not CSV imports; it is not a universal ingestion gate.
3. For hierarchical routing, verify requester population and active identity mappings, including NetSuite employee-email mapping where used. Ask the Zip contact which missing-requester behavior is enabled: skipping the approval or creating an unassigned approval. Adopt an explicit exception route rather than accepting a silent skip.
4. Configure the separate **Payout approvals** section with independent reviewers and amount/organizational conditions. Review both the approval definitions and their groups. Do not assume a completed bill review automatically establishes the required payout segregation.
5. Configure the Payments workflow's three-way-match and tolerance rules for the relevant goods/services. The three-way-match policy defaults to **Never**, and **Limit over-receiving** is off. If enabled, a limit of zero blocks all excess. Route defined mismatch/tolerance exceptions to an approval; a tolerance alert alone is not a blocking rule.
6. In **Company settings → Pay → Invoicing**, review any **Skip Inbox coding** configuration and its match prerequisites. Then review duplicate handling and post-coding edit permissions. Same-vendor/same-number duplicates are blocking, but several amount/date comparisons are warnings that can be ignored. Changes to permitted fields after coding can immediately resync to the ERP.

**Boundaries:** standard bill approvals do not apply to vendor credit memos; the article separately identifies an optional vendor-credit-approval beta, whose behavior must be checked if enabled. An approved PO change recalculates an uncoded/rejected invoice's chain, not an already coded bill. An integration record or “approved” status is not proof that every required control executed.

**Sources:** [Setting Up a Payments Workflow](https://docs.ziphq.com/hc/en-us/articles/17442001430171-Setting-Up-a-Payments-Workflow), [Invoicing Page](https://docs.ziphq.com/hc/en-us/articles/44994548789019-Invoicing-Page), [Duplicate Invoice and Credit Handling](https://docs.ziphq.com/hc/en-us/articles/38765920035995-Duplicate-Invoice-and-Credit-Handling), and [Editing Bill Details After They Are Coded](https://docs.ziphq.com/hc/en-us/articles/17459164048667-Editing-Bill-Details-After-They-Are-Coded).

**Automation:** Manual UI configuration for bill/payout approval policy, coder segregation and match-exception rules. The [authenticated OpenAPI specification](https://developers.ziphq.com/zipapidocs/openapi/openapi.yaml), reviewed 2026-11-08, documents no operation for configuring these policy settings. Record transitions and evidence collectors are not policy enforcement. Other native automation surfaces remain unverified; see the [source and automation census](/research/ziphq-source-coverage/).

#### Validation & Testing

Use authorized nonpayable test records and isolated destinations. Test the coder as approver at creation, reassignment and approval; test CSV/API ingestion and every active source condition; and test blank, inactive or unmatched requesters. Test exact duplicate and warning-only duplicate cases, over-receipt and threshold boundaries, and a permitted post-coding edit. Review the resulting bill and payout chains without scheduling or transmitting money.

**Expected result:** valid records reach distinct intended reviewers. Prohibited coder approval fails; each used ingestion path retains the required independent review or is documented as a gap with a separate enforced payout gate. Missing requester, yellow warning and unchanged coded-bill chain cases must not be reported as successful enforcement.

#### Monitoring & Maintenance

Review source-based approval exclusions, automatic coding, manual approver changes, unassigned bills, credits, warning overrides and post-coding edits at each payment-run cadence. Re-test after ERP mapping, ingestion or workflow changes. Reconcile payment authorization with audit evidence, not only final invoice status.

#### Operational Impact

Tighter matching can increase AP exceptions and delay legitimate payments. Assign a named exception owner and preserve the independent payout review during remediation. Roll back only the reviewed routing/tolerance change after assessing affected in-flight records; do not disable segregation globally to clear a queue.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-5, AC-6, SI-10 |
| SOC 2 | Authorization, separation of duties and transaction-integrity objectives; assess applicable Trust Services Criteria with the auditor |
| ISO/IEC 27001:2022 | Access-rights, information-transfer, change-management and logging objectives; confirm applicability in the statement of applicability |

---

### 5.4 Restrict Contract and Document Sharing

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-4, AC-6 |

#### Description

Limit who can view, edit, email and export contracts, and review the separate access granted by connected Google Docs. Treat request membership, Zip document permissions, private-comment recipients and Google Drive ACLs as distinct boundaries.

#### Rationale

**Why This Matters:**
- Basic permissions allow any attachment viewer to email the document to vendors.
- Google Docs editing grants are additive; removing a person from a Zip request does not revoke their Drive access.
- Comments default to Everyone, and private-comment access can expand through queue membership or an override permission.

**Attack Prevented:** Unauthorized contract disclosure, persistent cross-platform access after removal, and sensitive discussion leakage.

#### Prerequisites

The appropriate document/permission administrator and, for optional Contract Orchestration or Google Docs integration, the relevant module and authorized Workspace administrator. Identify document owners, approved external recipients and an owner for Drive-side revocation. Private Comments requires the applicable Premier feature.

#### ClickOps Implementation

1. In **Company settings → Users and permissions → Permission groups**, review the effective groups granting **Access documents**, **Access central list of documents in any subsidiary and department**, and **Send document for execution**. Restrict central-document editing/export access to people who need it, including the relevant subsidiary/department scope.
2. For advanced permissions, restrict **Send document for execution** together with the applicable document-edit grant. Under basic permissions, treat attachment viewing as potential vendor-email capability; narrow the attachment audience or adopt an appropriately scoped advanced-permission model. Do not claim “view-only” prevents email disclosure.
3. In each request's document workflow, review the **Email** action's To/CC contacts and additional attachments before sending. The action can add new external contacts and sends the latest version. Do not assume the recipient is limited to the original vendor contact.
4. On a document or request comment, change **Everyone** to the approved specific users/queues for sensitive discussions where private comments are available. Restrict **Start private comment threads** and **View all private comments** appropriately. Queue recipients still require request access, but later queue members with that access can see the thread.
5. For **Review in Google Docs**, review the connected account and generated document's Drive sharing. Zip automatically grants writer access to documented buyer-side request participants, including followers, active assignees/reviewers and relevant queue members. When someone leaves the request or role, remove their unneeded Drive access separately; Zip removal is not revocation.
6. Review the central **Documents** page and bulk-export audience. Exported files are delivered through an emailed link valid for seven days. Treat the exported copy as a new disclosure boundary rather than assuming later Zip ACL changes retract it.

**Boundary:** finalizing or cancelling a Google Docs review disables the relevant Zip editing action, but the reviewed documentation does not promise Drive ACL revocation. Do not follow the Word integration article's suggestion to disable all Office Protected View options as a security baseline; any compatibility exception requires a separate IT risk review.

**Sources:** [Contract Orchestration: How to Email Vendors from Zip](https://docs.ziphq.com/hc/en-us/articles/47943247989403-Contract-Orchestration-How-to-Email-Vendors-from-Zip), [Contract Orchestration: Reviewing with Google Docs](https://docs.ziphq.com/hc/en-us/articles/55686126397339-Contract-Orchestration-Reviewing-with-Google-Docs), [Private Comments](https://docs.ziphq.com/hc/en-us/articles/35991724424347-Private-Comments), [Document Details](https://docs.ziphq.com/hc/en-us/articles/27542311229723-Document-Details), [Documents Overview](https://docs.ziphq.com/hc/en-us/articles/17441983376027-Documents-Overview), and [Contract Orchestration: Redlining in Word](https://docs.ziphq.com/hc/en-us/articles/49074702656667-Contract-Orchestration-Redlining-in-Word).

**Automation:** Manual UI configuration for Zip contract-email, document-access and private-comment policy. The [authenticated OpenAPI specification](https://developers.ziphq.com/zipapidocs/openapi/openapi.yaml), reviewed 2026-11-08, documents no operation for configuring these policy settings. Record transitions and evidence collectors are not policy enforcement. Other native automation surfaces remain unverified; see the [source and automation census](/research/ziphq-source-coverage/). Google Drive administration is a separate platform control; no invented Zip-to-Drive revocation API is supplied.

#### Validation & Testing

With a synthetic document and approved pilot identities, verify intended viewing/editing and denied access for an unrelated user. Inspect email recipients/attachments without sending unless separately authorized. Test private-comment access using a queue member, nonmember and authorized override role. Remove a pilot participant from the request and inspect the document's actual Drive ACL; then perform and verify separately authorized Drive revocation.

**Expected result:** legitimate reviewers retain only required access; unrelated users cannot access the document or private thread. Zip removal alone must not be marked as a successful Google revocation. A queued export or emailed copy remains outside the original access boundary.

#### Monitoring & Maintenance

Review central-document permissions, email recipients, follower/queue changes and connected Google sharing monthly and on offboarding. Include **View all private comments** in privileged-access review. Do not rely on comments alone for a complete email archive: the article notes that replies without attachments are not recorded there.

#### Operational Impact

Narrower access may interrupt legal collaboration and review notifications. Use named reviewers and an approved sharing route rather than broadening central access. Revoke the separate Drive permission during rollback/offboarding as required. Deleting a Zip document permanently removes all versions and is not a safe substitute for permission repair.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-4, AC-6 |
| SOC 2 | Logical-access and information-transfer objectives; assess applicable Trust Services Criteria with the auditor |
| ISO/IEC 27001:2022 | Access-rights, information-transfer, change-management and logging objectives; confirm applicability in the statement of applicability |

---

### 5.5 Review Workflow Changes and Vendor Portals

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-6, CM-3, CM-5, AU-6 |

#### Description

Restrict workflow editing, review the effective approval graph before publication, and control who can invite vendors or change completed portals. Keep required supplier checks and finalization steps intact while accounting for data-driven review-chain changes.

#### Rationale

**Why This Matters:**
- Workflow version locking does not freeze data-driven approval recalculation and is unavailable for several workflow types.
- Editing, restoring or publishing a workflow can change sensitive approval routes or discard draft work.
- Portal tasks can be made optional after invitation, and unlocking approved portals affects existing requests.

**Attack Prevented:** Approval-policy tampering, unnoticed removal of supplier checks, and unauthorized post-approval portal changes.

#### Prerequisites

A named workflow owner and independent change reviewer, restricted workflow-edit permissions, approved vendor contact/invitation ownership, and an isolated validation plan. Workflow Versioning is an opt-in feature; Supplier Assessment and Contract Orchestration have separate availability requirements.

#### ClickOps Implementation

1. Open **Company settings → Workflows** and restrict editors to approved owners. For each proposed change, compare conditions, assignments, approval groups, diagram connections, actions and finalization steps. Review **Change history** against the approved change record. The [November 2026 release](https://docs.ziphq.com/hc/en-us/articles/57263347793947-November-2026-Product-Updates) adds **Sensitive approval** classification for purchase-request and bill/credit approvals: mark protected steps, save and publish, then narrowly grant **All, including sensitive** edit/reassignment access. Existing steps remain non-sensitive; existing editors receive **General only**, and no one receives the broader grant by default. General-only users may still view sensitive steps, so this is change protection, not confidentiality.
2. On the workflow's **Settings** tab, evaluate **Version lock** where available. It is off by default, applies to new requests after the change, and is absent for Payments, PO Change Order and Vendor Onboarding workflows. Document which in-flight requests are and are not protected.
3. If the opt-in **Workflow Versioning** feature is enabled, make edits in the draft, review the before/after differences, then publish through the approved change process. Review any selected in-flight locking explicitly. Restoring a version overwrites unpublished draft changes. Do not assume this feature is enabled merely because its documentation exists.
4. On **Settings → Vendor Portal**, enable **Lock Vendor Portals on Approved Requests** where completed portal tasks must not change. It affects existing and future requests; turning it off unlocks previously approval-locked portals. Review **Who Can Send the Vendor Portal**. The default permits users with **Manage Purchase Flow** permission; allow requesters only where that workflow needs them to send invitations.
5. For **Vendor Onboarding** and **Vendor Update** workflows, confirm the single active workflow, required fields/tasks and finalization actions. Preserve **Finalize request details / Finalize vendor** where applicable and place explicit ERP-push approvals after the information/finalization they depend on. Do not assume the ERP receives a completed review automatically.
6. Where Supplier Assessment is enabled, edit the external-check approval's subtasks and mark required TIN/OFAC/VAT/D&B checks **Required**. Set automatic execution only when intended, and position the group after vendor-portal completion. Both required and automatic execution options start off. Review users allowed to run checks or manually mark failures as passed.
7. Review vendor contacts and the portal's assigned documents. Initial vendor contacts can become vendor administrators; the buyer cannot manage that separate vendor-side permission model. Remove stale contacts through the approved vendor-contact process, and review any change making an already invited portal task optional.

**Boundaries:** automatic review-chain updates can still add/remove/reassign conditional approvals when request data changes, even under version lock. They preserve several cases, including manual or approved steps and tasks in progress/completed, so the effective chain may differ from a freshly created request. Payment methods, vendor contacts and internal owners are not governed by Vendor Update workflows.

**Sources:** [Workflow Settings](https://docs.ziphq.com/hc/en-us/articles/17459136745243-Workflow-Settings), [Workflow Versioning](https://docs.ziphq.com/hc/en-us/articles/44969980445595-Workflow-Versioning), [Automatic Review Chain Updates](https://docs.ziphq.com/hc/en-us/articles/44608439142427-Automatic-Review-Chain-Updates), [Vendor Onboarding Workflow](https://docs.ziphq.com/hc/en-us/articles/39864006109979-Vendor-Onboarding-Workflow), [Vendor Update Workflows](https://docs.ziphq.com/hc/en-us/articles/41468301419675-Vendor-Update-Workflows), [Vendor External Checks Approval Step](https://docs.ziphq.com/hc/en-us/articles/39904821743003-Vendor-External-Checks-Approval-Step), and [Vendor Portal](https://docs.ziphq.com/hc/en-us/articles/17459074033307-Vendor-Portal).

**Automation:** Manual UI configuration for workflow publication/version policy, approved-portal locking and required supplier-check routing. The [authenticated OpenAPI specification](https://developers.ziphq.com/zipapidocs/openapi/openapi.yaml), reviewed 2026-11-08, documents no operation for configuring these policy settings. Record transitions and evidence collectors are not policy enforcement. Other native automation surfaces remain unverified; see the [source and automation census](/research/ziphq-source-coverage/).

#### Validation & Testing

Review a synthetic request before and after a condition-changing field edit; include a manual/approved step and a task in progress. Compare a locked request, an unlocked request and a workflow type without locking. Check an approved portal's read-only behavior and the authorized invitation population. Where applicable, inspect a failing external-check result and the permission needed to override it.

**Do not assume Test request is isolated:** it can execute integrations, notifications and webhooks, is excluded from automatic review-chain updates, and therefore cannot prove every in-flight recalculation behavior. Arrange an explicitly approved, isolated test plan before creating any request.

**Expected result:** reviewed changes reach only the intended workflow population; restricted editors and unauthorized invitations are denied, approved portals remain locked, and mandatory checks cannot be silently omitted through the tested route. Record manual overrides, preserved steps and unsupported locking as explicit boundaries.

#### Monitoring & Maintenance

Review workflow change history and portal exceptions after every release and at least monthly. Reconcile editor access, active workflows, ERP-push ordering, changed vendor contacts and external-check overrides with the approved process. Re-test after enabling Workflow Versioning or changing review-chain logic.

#### Operational Impact

Locking portals can delay legitimate vendor corrections, and version restore can discard draft work. Keep a reviewed correction route and snapshot the prior workflow before editing. Roll back narrowly after checking in-flight requests; disabling portal locking globally reopens previously locked portals and should not be a routine troubleshooting step.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-6, CM-3, CM-5, AU-6 |
| SOC 2 | Logical-access, change-management and monitoring objectives; assess applicable Trust Services Criteria with the auditor |
| ISO/IEC 27001:2022 | Access-rights, information-transfer, change-management and logging objectives; confirm applicability in the statement of applicability |

---

## 6. AI Governance

This section distinguishes traditional workflow AI Agents, Intake AI, Superagents, and the separate outbound Zip MCP service. Settings for one are not a universal AI kill switch. The Help articles were read through an authorized authenticated browser on 2026-11-08; the implementation steps below are documentation-backed, not live-tenant validated.

**Feature and pricing boundary:** [Superagents](https://docs.ziphq.com/hc/en-us/articles/55584746062107-Superagents-Overview) are a beta offering, free to participating customers through **December 31, 2026**; advanced capabilities may subsequently require payment. Procurement requires Intake-to-Procure, contract/risk capabilities require the corresponding module or Intake-to-Procure, and accounts-payable capabilities require Procure-to-Pay. Confirm current entitlement and pricing before enabling a capability. Traditional agent entitlement differs: SOC 2 and DORA agents require Risk, while MSA review includes ten standard clauses without the additional CLM capabilities. These are feature boundaries, not assertions that every customer has each control.

### 6.1 Scope Agent Access and Activity Permissions

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-3, AC-6 |

#### Description

Limit agent use, configuration, context editing, connector administration, and transcript access to separately approved populations. Review both organization permission groups and individual Superagent access, including automatic permission migration and workflow-assignment exceptions.

#### Rationale

**Why This Matters:**
- A user who can run an agent does not necessarily need to change its instructions or read other users' transcripts.
- Superagents execute with the session owner's permissions; overprivileged owners increase the effect of mistaken or manipulated actions.
- Permission groups are additive. Removing a grant from one group does not cancel a grant from another or eliminate documented record-assignment exceptions.

**Attack Prevented:** Unapproved agent invocation, unauthorized instruction changes, and cross-user disclosure through broad activity access.

#### Prerequisites

- Administrator or delegated permission-group management access, plus authority to configure the enabled AI product.
- An inventory of permission-group memberships, intended agent users/editors, and users assigned to sensitive workflow approvals or tasks.
- Identify whether the organization uses basic or advanced permissions. Basic permissions bundle AI administration more broadly; do not represent them as the granular advanced model.

#### ClickOps Implementation

1. Click the **gear icon → Company settings → Users and permissions → Permission groups**. For each relevant group, select **Edit**, open its **AI** permission page, and review the grants below. Save the edited group. Review the **Users** tab's **Groups** column for overlapping assignments; membership changes save immediately. See [Permission Settings and Groups](https://docs.ziphq.com/hc/en-us/articles/18921746955035-Permission-Settings-and-Groups).
2. For traditional AI Agents under advanced permissions, grant **Access AI agents** as **Run**, **View**, or **None** according to the user's job. Restrict **View or edit Zip AI settings**, **Access AI context library** (**Edit/View/None**), **Access chat configuration** (**Edit/View/None**), and AI activity/usage visibility separately. Grant configuration and context editing only to maintainers, and activity access only to reviewers with a business need.
3. Review traditional App Studio agent builders separately. The [AI permissions article](https://docs.ziphq.com/hc/en-us/articles/46519428893595-Zip-AI-Permissions) identifies additional integration-platform access and app/connection permissions for building or modifying agents. Do not grant broad integration administration merely to allow ordinary agent execution. With basic permissions, review the bundled **View or edit Zip AI settings** grant and related integration/task grants rather than assuming advanced permission choices are available.
4. For Superagents, review the advanced permissions for configuration, action management, activity, context, and integration settings. The [configuration guide](https://docs.ziphq.com/hc/en-us/articles/56539139834139-Superagent-Configuration-Guide) documents the names **Access agents** and **View agent activity** replacing older AI-agent names. Treat activity access as privileged: it exposes organization-wide full session transcripts across supported channels, not merely usage totals. Basic-permission organizations use the broader **View or edit Zip AI settings** grant for these functions.
5. After Superagents onboarding, inspect the resulting grants rather than assuming new privileges were denied: Zip automatically derives new permissions from existing AI permissions and documents an opt-out through the Zip contact. Obtain the actual migration mapping for the organization's permission model; the reviewed migration wording is not sufficiently precise to encode a universal Boolean rule.
6. Open **Superagents → Agents → [agent] → Access → Manage → General user access**, and select **Only specific people** for each enabled business agent. Add only its approved population and review its editors. Organization configuration administrators can also edit agents; the per-agent editor list is not the only edit path.
7. Keep unused business agents disabled. **Documented default:** prebuilt agents other than Chat are disabled initially, but enabling one gives **everyone** access until narrowed. **Exception:** Chat is always enabled for all users and cannot be disabled through this mechanism. Restrict the data, context, and actions available to Chat through §§6.2–6.3 rather than promising a Chat disable switch.

**Scope exception:** users can run traditional AI Agents and view their outputs on tasks or approval steps assigned to them even without the explicit general AI-agent permission. Review those assignments as part of access governance. Superagent sessions use the session owner's permissions; an agent's audience setting does not substitute for reviewing that owner's native record access.

**Automation:** ClickOps only for these AI settings in the reviewed documentation. The [agent-session API](https://developers.ziphq.com/zipapidocs/reference/listagentsessions) supplies session metadata, and the [audit API](https://developers.ziphq.com/zipapidocs/reference/queryauditlogs) supplies events; neither establishes a supported endpoint to read or change this permission policy (reviewed 2026-11-08). Other native automation surfaces remain unverified in the [source ledger](/research/ziphq-source-coverage/); no configuration API or synthetic policy file is assumed.

#### Validation & Testing

1. Use approved test accounts representing an allowed runner, excluded user, maintainer, and activity reviewer. Verify the runner can use the selected business agent and the excluded user cannot.
2. Verify a runner cannot edit configuration/context or inspect another user's session through organization activity, while the designated reviewer can access the intended activity view.
3. Test a traditional-agent task with an assigned test approver who lacks the general agent grant. Document the expected assignment exception; do not report this as a failed permission setting or as proof the grant is universal.
4. Review all groups on a deliberately excluded test account before diagnosing an unexpected allow. Confirm Chat remains available as documented and its native data/action boundaries still apply.

**Expected result:** agent-specific access and administrative separation match the approved matrix, with the Chat, assignment, organization-administrator, and additive-group exceptions recorded explicitly. Tests not performed remain unverified.

#### Monitoring & Maintenance

Review access and agent editors monthly and after role changes. Recheck permissions after Superagents onboarding, migration, feature enablement, and new connector/channel introduction. Restrict access to exported test evidence because transcripts can contain business information. Use session and item audit evidence for investigation, not as a substitute for a current permission review.

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|---------|
| User Experience | Medium | Narrowing audiences can interrupt existing agent-assisted work. |
| System Performance | None | No documented performance penalty for smaller audiences. |
| Maintenance Burden | Medium | Group, agent, editor, and workflow-assignment reviews are separate. |
| Rollback Difficulty | Moderate | Restore only a reviewed prior grant or audience, not access for everyone. |

**Rollback Procedure:** retain an approved before-state. Restore the specific required membership, permission, or agent access entry, then repeat the negative test. Do not delete a permission group as a rollback mechanism; group deletion is permanent.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-3, AC-6 |
| SOC 2 | Logical access, authorization, and privileged-access objectives |
| ISO/IEC 27001:2022 | Access control, identity management, and access-rights objectives |
| PCI DSS v4.0 | Restrict access by business need to know, where the environment is in scope |

---

### 6.2 Require Human Approval for Agent Actions

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-5, AC-6, CM-3 |

#### Description

Require human approval before consequential Superagent changes and prevent workflow automation from silently replacing required review. Govern Zip actions and external connector tools separately, with deny rules for actions the organization does not permit.

#### Rationale

**Why This Matters:**
- AI output can be incorrect or influenced by untrusted documents, messages, and vendor content.
- Completing an agent task, completing an approval, and approving a plan are different operations with different controls.
- Connectors, channels, and action policy configured from an individual agent can have organization-wide effect.

**Attack Prevented:** Unreviewed procurement changes or approvals caused by erroneous or adversarial agent instructions.

#### Prerequisites

- Superagent action-management/configuration authority and workflow-editing authority for the workflows being changed.
- A test workflow with synthetic requests, documents, and approvers. Do not perform negative tests on real purchases or payments.
- A written decision identifying prohibited actions and those that require explicit human approval.

#### ClickOps Implementation

1. Open **gear icon → Company settings → Superagent actions → Zip Actions**. For **Update request fields** and **Add document**, select **Always ask for approval**, or block the action if it is unnecessary. Do not select automatic allowance for this L3 baseline.
2. For **Complete request approval**, keep **Always ask for approval** or block the action. If using the documented custom-per-approval option, inspect every affected workflow approval and set its agent assistance to ask or block. Per-approval automatic allowance is an exception requiring explicit risk acceptance, not an equivalent implementation of this control.
3. Turn on **Ask user to review plan before agent execution**. **Documented defaults:** all Zip actions initially use **Always ask for approval**, while plan review defaults **off**. Plan review supplements action approval; it does not replace it. The settings apply to assigned agents and an approver using Chat. Approval subtasks are not supported by this Superagent mechanism in the reviewed release.
4. In the [Superagent configuration guide's inbound connector settings](https://docs.ziphq.com/hc/en-us/articles/56539139834139-Superagent-Configuration-Guide), review the organization's allow/ask/block policy for each connector tool. Block unnecessary tools and require approval for the others. A personal connection is made through **Personal settings → Apps → Inbound apps**; users can narrow, but cannot loosen, the organization policy, and blocked tools are hidden. Personal connection itself does not require a separate Zip permission in the documented model. Do not equate this with authorization to connect every external account.
5. Treat connector, channel, and action changes as organization-wide even when initiated from a particular agent's details. Review which other enabled agents and channels will inherit the policy before changing it.
6. For traditional AI Agents, open the applicable workflow's agent task configuration and review **Required**, automatic triggering, and automatic completion individually using [How to Use AI Agents](https://docs.ziphq.com/hc/en-us/articles/46543139314459-How-to-Use-AI-Agents). Keep automatic completion off wherever a human must inspect the output, and retain a separately assigned human approval. Automatic triggering may assist the reviewer; it is not permission to complete the review automatically. The documented recommended-agent configuration has **Required off**, **automatic triggering on**, and **automatic completion off**; review recommendations and publish workflow changes explicitly.
7. Inspect any following auto-approve behavior. A traditional agent that automatically completes can let a chained auto-approval advance the workflow without the intended human review. A screenshot showing all toggles off is not evidence that every manually created task has those defaults.

**Outbound MCP is different:** [Zip MCP](https://docs.ziphq.com/hc/en-us/articles/51721321856539-Zip-MCP) is a read-only service for external AI clients. The reviewed version does not support approving, rejecting, or submitting requests. It uses per-user OAuth with Zip permissions, not an API key; authorization-code PKCE and Streaming HTTP are documented, and leaving requested OAuth scopes blank is intentional in this service. Do not turn a generic client example into an agent-action enforcement API. Read-only still permits data disclosure to the authorized external client, so assess that data boundary under §6.3.

**Automation:** ClickOps only for action, plan-review, and workflow-agent policy in the reviewed source set ([Superagent configuration](https://docs.ziphq.com/hc/en-us/articles/56539139834139-Superagent-Configuration-Guide), [traditional task configuration](https://docs.ziphq.com/hc/en-us/articles/46543139314459-How-to-Use-AI-Agents), 2026-11-08). Native agent metadata and audit events do not read or enforce these settings. No supported settings API, CLI, provider, or configuration-file contract was established; unverified surfaces remain recorded in the source ledger.

#### Validation & Testing

1. In the test workflow, ask the agent to change a harmless synthetic field. Confirm the plan-review step appears and an action-specific approval is still required. Decline the action and confirm the field remains unchanged.
2. Ask for a blocked action and confirm it cannot execute. For a permitted inbound connector, verify a user cannot override organization block/ask policy in personal settings.
3. Ask the agent to complete the test approval. Verify the human decision remains necessary and the next workflow step does not advance on an unapproved action.
4. Run the traditional task and confirm output generation alone does not complete the task or the surrounding approval. Confirm an automatically recommended task did not silently change the configured human-review boundary.
5. Inspect the item audit record for the agent and session owner, and use **View session** only with authorized activity access. Test evidence should show both the attempted action and its result, not only the agent's narrative.

**Expected result:** denied actions produce no state change, approved actions occur only after the required human decision, and a generated result does not bypass the intended approval chain. Do not claim these tests passed without execution.

#### Monitoring & Maintenance

Review action policy and per-approval exceptions monthly, after publishing skills/workflows, and after adding connector tools. Recheck defaults after beta updates. Investigate unexpected field updates, added documents, completed approvals, or session-owner changes. AI recommendations and Payment Risk Insights are advisory; [Payment Risk Insights](https://docs.ziphq.com/hc/en-us/articles/37496797971483-Payment-Risk-Insights) does not block approvals.

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|---------|
| User Experience | High | Human approval and plan review add deliberate friction. |
| System Performance | Low | Workflow elapsed time depends on reviewer availability. |
| Maintenance Burden | Medium | Review both organization policy and per-approval exceptions. |
| Rollback Difficulty | Moderate | Policy restoration and reversal of already completed business actions are separate. |

**Rollback Procedure:** restore only a documented, approved prior policy after assessing the reason for the block. Disabling plan review or changing to automatic allowance weakens this control. A policy rollback does not undo prior request changes or approvals; use the normal business correction process for those records.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-5, AC-6, CM-3 |
| SOC 2 | Authorized processing, change management, and segregation-of-duties objectives |
| ISO/IEC 27001:2022 | Segregation of duties, access rights, and change-management objectives |
| PCI DSS v4.0 | Business-need access and controlled changes, where applicable |

---

### 6.3 Govern AI Context and Data Use

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-6, CM-3, SA-9 |

#### Description

Publish only approved AI context, separate drafts from active policy, and make an explicit decision about cross-customer model improvements. Treat external clients, organization-wide transcripts, and connector data as distinct disclosure boundaries; do not infer retention or universal opt-out guarantees from an individual feature toggle.

#### Rationale

**Why This Matters:**
- Published context can affect users and agents beyond the team that uploaded it.
- Default or example policy is not the organization's approved procurement, legal, or risk policy.
- Disabling display of AI-enriched data does not necessarily stop processing, and withdrawing a sharing setting does not establish retroactive deletion.

**Attack Prevented:** Excessive data exposure, unauthorized policy substitution, and reliance on unapproved AI-generated decisions.

#### Prerequisites

- **Access AI context library** editing authority, appropriate Superagent/Chat configuration authority, and **View or edit Zip AI settings** for organization AI settings.
- Named owners for approved policy documents, allowed data categories, legal/privacy decisions, and periodic review dates.
- Confirm feature entitlement. The policy controls do not establish a particular data-residency, retention, or contractual training arrangement.

#### ClickOps Implementation

1. Open **gear icon → Company settings → Zip AI → Documents**. Review **Subscribe to AI Improvements** and turn it off unless the organization has expressly approved the described use. The [Zip AI article](https://docs.ziphq.com/hc/en-us/articles/33848666918939-Zip-AI) says enabling it permits anonymized and aggregated organizational data to improve models for all Zip customers; it does not state a default. Record the observed setting and decision rather than labeling it opt-in or opt-out by default.
2. On the same page, review **Enable Order Form Extraction** against the approved document-processing use case. Under **Vendor**, recognize that **Enable AI Vendor Descriptions** controls whether enriched descriptions/logos are displayed; it does **not** turn off the underlying enrichment process. Do not present either toggle as a global AI-disable or data-deletion control.
3. Open the **Context library** described in [Context Library](https://docs.ziphq.com/hc/en-us/articles/43700687283099-Context-Library). Inventory active/published assets, their owners, approved audience, and current versions. Keep proposed policy in draft until reviewed, publish only approved revisions, and archive superseded assets. Restrict who can edit the library through §6.1.
4. For Superagents, review context and skill configuration through **Superagents → Agents → [agent]**. Changes to skills remain drafts until published. When replacing a template skill, use the documented custom-copy path and archive the superseded original rather than leaving two conflicting policies active. System instructions are hidden/read-only and cannot be treated as a customer-editable enforcement layer.
5. Review Chat separately: the [prebuilt-agent documentation](https://docs.ziphq.com/hc/en-us/articles/56595533147291-Pre-Built-Superagents-Details) says Chat automatically has access to every active published context asset, including template assets published by Zip. Do not publish sensitive material based on an assumption that attaching it to one agent confines it to that agent. Older Intake AI documentation describes a narrower global-policy behavior; verify the enabled product and test audience before applying that older statement to Superagents.
6. Replace example policies with approved organizational content before using specialist agents. Contract review uses its selected playbook, not the entire library, and an empty triage policy causes all contracts to be reviewed. The Risk Superagent's default rules are not an internal security policy: the documented default has no internal policy document, and customer-user-entity controls cannot be mapped to one that was never supplied. Keep AI output advisory until the responsible reviewer verifies source material and applicability.
7. Review the [Responsible AI Governance Policy](https://docs.ziphq.com/hc/en-us/articles/29661889053723-Responsible-AI-Governance-Policy) and the [AI Generated Content Advisory](https://docs.ziphq.com/hc/en-us/articles/17441975439643-AI-Generated-Content-Advisory) with the organization's data owner. The reviewed pages do not establish a numerical AI retention duration or a zero-retention guarantee. Resolve retention, deletion, residency, and permitted training use contractually with Zip before placing restricted data in AI workflows.
8. For outbound Zip MCP, approve each external client's data use independently. The documented per-user permission boundary does not prevent authorized data from leaving Zip for that client. Attachment links are single-use and expire after one hour, but that limit is not a deletion guarantee for a downloaded copy. Do not store signed attachment links, client secrets, or transcripts in audit scripts or public evidence.

**Risk-review continuity:** where AI findings inform scheduled vendor reviews, keep a human owner and a separate escalation process. [Scheduled reviews](https://docs.ziphq.com/hc/en-us/articles/17459120089371-Vendor-Record-Scheduled-Reviews) recur from the preceding review's **completion date**, not a fixed original deadline; a start-date notification still requires the requester to start the review. Changing a vendor to **Inactive**, **Banned**, or **Deleted** cancels scheduled **and in-progress** reviews. Track these transitions so deactivating a risky vendor does not silently remove a review obligation. AI risk-tier recommendations do not themselves guarantee an executed review.

**Automation:** ClickOps only for the context-publication, AI-improvement, and skill policy settings in the reviewed documentation ([Zip AI](https://docs.ziphq.com/hc/en-us/articles/33848666918939-Zip-AI), [Context Library](https://docs.ziphq.com/hc/en-us/articles/43700687283099-Context-Library), [Superagent configuration](https://docs.ziphq.com/hc/en-us/articles/56539139834139-Superagent-Configuration-Guide), 2026-11-08). The current native API review established agent metadata/events, not a supported settings endpoint. No invented API, model-retention switch, or offline policy file substitutes for these UI and contractual checks.

#### Validation & Testing

1. Use synthetic, non-sensitive context containing a unique test fact. Confirm drafts are not treated as published policy, publish only after review, then verify the documented consumers can use it.
2. Test Chat with an ordinary account to check the actual published-context boundary. Do not infer document confidentiality from an agent association or from lack of a citation in one response.
3. Archive the test asset and start a new session to check future retrieval. Archiving is not proof that earlier session history or external copies were deleted.
4. Reopen Zip AI and confirm the recorded AI-improvements decision persisted. Do not use disappearance of a vendor description as proof enrichment stopped.
5. If MCP is enabled, use an authorized restricted test account and confirm an inaccessible synthetic record cannot be retrieved. Test only the approved client's account and service; do not expose real confidential content for a negative test.
6. Review the schedule and current vendor status for a test scheduled review. Verify the completion-based recurrence and cancellation behavior before relying on the feature for a fixed compliance deadline.

**Expected result:** only reviewed context is active, the cross-customer model-use decision is recorded and persisted, and data/retention boundaries are documented without claiming unsupported guarantees.

#### Monitoring & Maintenance

Review published context, stale versions, template changes, and data-use approvals monthly and after policy revisions. Reassess AI beta terms and pricing before December 31, 2026. Check scheduled-review due dates and vendor status changes independently of agent recommendations. Reconfirm external-client data handling and contract terms when clients or subprocessors change.

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|---------|
| User Experience | Medium | Narrowed or archived context may reduce answer completeness. |
| System Performance | Low | No documented performance guarantee; smaller context is not a security proof. |
| Maintenance Burden | Medium | Policy ownership, publication, contractual review, and retention decisions remain human tasks. |
| Rollback Difficulty | Moderate | Re-publishing policy is possible, but already disclosed data cannot be recalled by a toggle. |

**Rollback Procedure:** restore only an approved prior context version or skill, publish deliberately, and test in a new session. Re-enabling AI improvements requires the same data-owner approval as initial enablement. Treat prior disclosures and retained conversations separately; do not promise erasure through rollback.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-6, CM-3, SA-9 |
| SOC 2 | Confidentiality, change management, and external-service risk objectives |
| ISO/IEC 27001:2022 | Information classification, access rights, supplier relationships, and cloud-service use objectives |
| PCI DSS v4.0 | Minimize and restrict account-data access; confirm AI processing scope before use |

---

### 6.4 Restrict Inbox AI Recipients

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-6, AC-21 |

#### Description

Limit Inbox AI's **Whitelisted emails** to approved organizational forwarding inboxes whose members may receive invoice details. Treat each entry as a disclosure permission, not merely a mail-delivery convenience.

#### Rationale

**Why This Matters:**
- Zip documents that the Inbox response agent can include invoice information in a reply to a whitelisted sender even when that sender lacks invoice-view permission in Zip.
- The whitelist does not grant access to the invoice page, so a successful page-access denial does not prove the email disclosure is blocked.
- A shared mailbox can expose replies to every person, forwarding rule, or connected application with access to that mailbox.

**Attack Prevented:** Invoice-detail disclosure to unauthorized senders or overbroad shared-mailbox audiences.

#### Prerequisites

- Procure-to-Pay invoicing/Inbox AI availability and authority to change invoicing settings.
- An approved inventory of internal forwarding inboxes, their mailbox owners/members, and the invoice information each may receive.
- Administrators can manage these settings; the [Inbox AI Agent article](https://docs.ziphq.com/hc/en-us/articles/53717456493467-Inbox-AI-Agent) also documents invoicing settings access for non-admin users with **Create or edit bills and credits**. Review that delegated ability, not only administrator membership.

#### ClickOps Implementation

1. Open **gear icon → Company settings → Pay → Invoicing → Invoice creation and email responses → Inbox response agent → Whitelisted emails**.
2. Record the existing entries and their business owners. Retain only approved organizational inboxes used to forward invoices and remove entries without a current need. Zip specifically recommends using organizational forwarding inboxes rather than vendor email addresses.
3. Review the recipients of each retained mailbox in the email service, including delegates, forwarding, and third-party integrations. The Zip whitelist alone does not govern that downstream audience.
4. If no such disclosure is approved, leave no approved forwarding recipients and disable the Inbox response agent through its invoicing settings as appropriate for the organization's process. Verify the actual persisted state; the reviewed article does not establish a universal initial whitelist or response-agent default.
5. Review users with **Create or edit bills and credits** and assess their ability to change invoicing/agent settings. Use the permission-group review in §6.1 to remove unnecessary delegated authority; do not assume this is an administrator-only boundary.

**Source:** [Inbox AI Agent](https://docs.ziphq.com/hc/en-us/articles/53717456493467-Inbox-AI-Agent), authenticated article read 2026-11-08. The invoice-access exception is explicitly documented and must remain visible in the configuration decision.

**Automation:** ClickOps only for Inbox response-agent settings and whitelist in the reviewed documentation. No supported native settings read/write endpoint was established by the [API/source review](/research/ziphq-source-coverage/) (2026-11-08); invoice record endpoints do not prove this disclosure policy. No email-sending or invoice-creation pack is supplied for testing it.

#### Validation & Testing

1. Use a synthetic invoice and organization-controlled test mailboxes in an approved test process. Confirm an approved forwarding inbox receives only the expected response information.
2. Repeat from a controlled non-whitelisted sender lacking invoice access. Confirm the sensitive invoice details are not included in the agent's reply. Inspect the actual response, not just the sender's inability to open the invoice page.
3. Remove a temporary test whitelist entry, repeat the test, and confirm the recipient no longer receives the privileged detail. Check delivery and mailbox forwarding separately.
4. Verify an ordinary unauthorized user cannot edit the whitelist, and explicitly test any delegated invoicing-settings role included in the approved matrix.

**Expected result:** only approved forwarding mailboxes receive the documented invoice-detail exception, and ordinary invoice-page denial is not mistaken for protection of the email channel. Tests involving email must be separately authorized and use synthetic data.

#### Monitoring & Maintenance

Review whitelist entries and mailbox membership monthly, after finance staffing changes, and after mail-integration changes. Record the owner and justification for each entry. Recheck delegated invoicing-settings privileges and investigate unexpected AI responses or additions to the whitelist.

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|---------|
| User Experience | Medium | Some forwarding workflows lose automated invoice responses. |
| System Performance | None | No documented throughput penalty from a narrower whitelist. |
| Maintenance Burden | Medium | Both Zip settings and mailbox access need review. |
| Rollback Difficulty | Easy | Restore a specifically approved address; already sent email cannot be recalled reliably. |

**Rollback Procedure:** restore only the documented forwarding address after confirming its audience and repeat the negative test. Do not add a vendor address as a temporary workaround. Disabling the agent or removing an entry does not delete prior email copies.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-6, AC-21 |
| SOC 2 | Confidentiality and authorized-disclosure objectives |
| ISO/IEC 27001:2022 | Information transfer and access-rights objectives |
| PCI DSS v4.0 | Restrict account-data access and transmission, if invoice content is in scope |

---

## 7. Compliance Quick Reference

Mappings are implementation aids, not attestations. No Zip-specific CIS Benchmark, DISA STIG, CISA SCuBA baseline, or NSA/ACSC configuration baseline was identified in the bounded public search. SOC 2 and ISO rows intentionally name objectives rather than asserting unverified clause-level equivalence. PCI DSS applicability depends on the organization's actual cardholder-data environment and is not inferred from use of procurement software.

| NIST SP 800-53 Rev. 5 | Implementation evidence | Sections |
|----------------------|-------------------------|----------|
| AC-2 | Approved population, lifecycle, native flags/memberships and delegation review | 1.2, 1.4, 1.5, 1.6, 2.4, 3.2, 4.1 |
| AC-3, AC-5, AC-6 | Assigned access, additive grants, restricted credentials and approval delegation | 1.1, 1.2, 1.4, 1.5, 1.6, 2.2, 2.4, 3.2 |
| AC-4, SC-8 | Approved notifications, webhooks, queues, exports and document/AI data paths | 2.1, 2.3, 2.5, 2.6, 5.4, 6.3, 6.4 |
| SC-7, SC-12, SC-13, SC-28 | Network restrictions and customer-managed key custody | 1.8, 2.7 |
| AC-5, CM-3, CM-4 | Approval separation, workflow change control and sandbox boundaries | 1.10, 5.1–5.5, 6.2 |
| IA-2, IA-5 | Federated sign-in, MFA, native SSO evidence and credential lifecycle | 1.1, 1.3, 1.5, 2.2, 3.1 |
| AU-2, AU-6, AU-9, CA-7 | Reviewed lifecycle failures and minimized native event evidence | 4.1, 4.2 |

Framework source: [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final).

## Appendix A: Applicability and Documentation Gaps

| Area | Applicability and conditions | Remaining limit or conflict |
|------|------------------------------|-----------------------------|
| Workforce SSO, sessions, IP restrictions | Native Security page; required administrator/security-setting grants | Actual policy, login/recovery behavior and timeout tests remain unverified; IP-group capacity differs between articles |
| Phishing-resistant MFA | Appropriate IdP license and enrolled factors | Native SMS/phone/TOTP is not phishing-resistant; SSO alone satisfies Zip's elevated-user monthly safeguard |
| Provisioning | Single approved source of truth; advanced permissions for group sync; OAuth2 enablement/new Okta app | Multi-provider SCIM release notes conflict with Security Page; immediate session/API revocation not established |
| Permissions | Basic versus advanced frameworks; additive grants and record-involvement exceptions | API membership/group inventories do not expose the full permission policy; Default-group removal guidance differs by document generation |
| Delegations and queues | Feature entitlement, proper hierarchy and approved queue inventory | No-role delegation exception; queue visibility also confers completion ability; no global queue-list GET |
| Supplier accounts | Separately administered Vendor App and invited contacts | Buyer cannot inspect/manage supplier-admin permissions as if they were workforce grants |
| Native API | 102 paths/159 operations; existing restricted legacy key mode explicitly pinned | Modern OAuth provisioning/scopes and ongoing legacy-version support require confirmation |
| Audit and exports | API audit requires Premier; certain audit packages require Premier/add-on; SFTP contracted entitlement | Retention/SLA, SIEM parser, complete MCP attribution and every export recipient's need-to-know need independent review |
| Workflow and payment controls | Relevant procurement/P2P modules and workflow editing rights | Defaults and import paths can bypass approvals; advisory bank/risk results are not transaction blocks |
| AI, Superagents, MCP | Product-specific permissions, beta/module gates and current contract | Teams/context-attachment documentation conflicts, exact third-party retention and rollout configuration remain unverified |
| Enterprise key management | Support/legal onboarding, designated onboarder, AWS multi-region key | Exact tenant data coverage, regional deployment, total effective key access and recovery must be confirmed |
| Environments | Premier; separate sandbox access/SSO/MFA and integration review | Detailed connection-retention behavior conflicts with blanket isolation assurances; no live configuration test |
| Trust Center and training | Verified official entry points | Full restricted resource catalog, every attachment/video and external Academy course not reviewed |

No fabricated edition grid is supplied. Verify contracted SKU, enabled feature generation, tenant-specific labels and rollout state with Zip. Vendor assurances and certifications are not proof that tenant controls are configured. Documentation conflicts are retained in the [source ledger](/research/ziphq-source-coverage/) rather than silently resolved.

## Appendix B: References

- [Zip Help Center](https://docs.ziphq.com/hc/en-us), [Security Page](https://docs.ziphq.com/hc/en-us/articles/25604138623899-Security-Page), [advanced permissions](https://docs.ziphq.com/hc/en-us/articles/18921746955035-Permission-Settings-and-Groups), and [API Page](https://docs.ziphq.com/hc/en-us/articles/20210802709275-API-Page)
- [Microsoft Zip SAML](https://learn.microsoft.com/en-us/entra/identity/saas-apps/zip-tutorial) and [Zip provisioning](https://learn.microsoft.com/en-us/entra/identity/saas-apps/zip-provisioning-tutorial)
- [Okta Zip SAML setup](https://saml-doc.okta.com/SAML_Docs/How-to-Configure-SAML-2.0-for-Zip.html)
- [Zip Slack configuration](https://zip.com/integration/slack)
- [Zip supplier sign-in and organization choices](https://docs.ziphq.com/hc/en-us/articles/17459154258715-Signing-In-to-the-Zip-Vendor-App)
- [Zip API documentation access](https://docs.ziphq.com/hc/en-us/articles/49398321531675-How-to-Access-API-Documentation)
- [Authenticated API reference](https://developers.ziphq.com/zipapidocs/reference/createaddress), [OpenAPI download](https://developers.ziphq.com/zipapidocs/openapi/openapi.yaml), [Getting Started](https://developers.ziphq.com/zipapidocs/docs/getting-started), and [API key/webhook administration](https://developers.ziphq.com/zipapidocs/docs/rest-api-info-authentication-api-key-creation-and-webhooks)
- [Trust Center discovery entry point](https://zip.com/trust), used for discovery and assurance only
- [Source-first reconciliation and automation census](/research/ziphq-source-coverage/)

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-08 | 0.3.0 | ai-drafted | Added authenticated Help-based native security, sandbox, export, EKM, workflow/payment and AI controls; corrected default and permission-boundary gaps. Eight read-only evidence packs; no live tenant validation. | Codex |
| 2026-11-08 | 0.2.0 | ai-drafted | Added seven controls and five native read collectors after authenticated review of all current API operations/guides; retained Help/Trust, UI, version and live-validation gaps. | Codex |
| 2026-11-08 | 0.1.0 | ai-drafted | Initial bounded public-source guide: eight controls, three Entra-only read collectors, supplier/buyer separation, and explicit gated-documentation gaps. No live tenant validation. | Codex |

## Contributing

Report inaccuracies or contribute tenant-verified configuration evidence through [GitHub issues](https://github.com/grcengineering/how-to-harden/issues) and the [contribution guide](/contributing/). Do not submit API keys, supplier banking details, private audit logs, or restricted Trust Center documents in public issues.
